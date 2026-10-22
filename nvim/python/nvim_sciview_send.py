"""Send a value from the paused program to the sciview viewer (python/nvim_sciview.py).

nvim (lua/config/sciview.lua) evaluates `run_path(<this file>)["show"](label, value)`
in the paused frame. The value becomes a numpy array, written to /dev/shm
(RAM) for the viewer to load, and the viewer is told over a unix socket.
The paused program never draws anything itself; the viewer is its own process.

Size: at most BUDGET bytes are sent. Bigger arrays send their first frames
(axis 0), and lazy arrays (masknmf's, h5py datasets) compute only those
frames, never the whole movie. Torch tensors are trimmed on their device
before the copy to the CPU, so a big CUDA tensor never lands in RAM whole.
"""

import json
import os
import socket
import sys
import time

BUDGET = 1 << 30  # 1 GiB


def socket_path() -> str:
    base = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"
    return os.path.join(base, f"nvim-sciview-{os.getuid()}.sock")


def _itemsize(dtype) -> int:
    """Bytes per element for a numpy dtype, a numpy type (np.float32, as
    some lazy arrays report), or a torch dtype; 4 when unknown."""
    size = getattr(dtype, "itemsize", None)
    if isinstance(size, int):
        return size  # numpy dtype instance, torch dtype
    try:
        return int(__import__("numpy").dtype(dtype).itemsize)
    except TypeError:
        return 4


def _frames_within_budget(shape, itemsize: int) -> int:
    if not shape:
        return 0
    frame_bytes = itemsize
    for n in shape[1:]:
        frame_bytes *= int(n)
    return max(1, min(int(shape[0]), BUDGET // max(frame_bytes, 1)))


def _to_numpy(value, notes: list):
    np = sys.modules.get("numpy") or __import__("numpy")
    torch = sys.modules.get("torch")

    if torch is not None and isinstance(value, torch.Tensor):
        device = str(value.device)
        value = value.detach()
        if value.layout != torch.strided:  # sparse (coo, csr, ...): view it dense
            dense_bytes = value.numel() * value.element_size()
            if dense_bytes > BUDGET:
                raise ValueError(f"sparse {tuple(value.shape)} would be {dense_bytes / 2**30:.1f} GiB dense")
            notes.append(f"sparse ({str(value.layout).removeprefix('torch.')}, {value._nnz()} stored), shown dense")
            value = value.to_dense()
        if value.ndim and value.numel() * value.element_size() > BUDGET:
            n = _frames_within_budget(tuple(value.shape), value.element_size())
            notes.append(f"first {n} of {value.shape[0]} along axis 0")
            value = value[:n]
        if value.is_complex():
            value = value.abs()
            notes.append("magnitude of complex")
        if device != "cpu":
            notes.append(f"copied from {device}")
        return value.cpu().numpy()

    if isinstance(value, np.ndarray):
        if value.ndim and value.nbytes > BUDGET:
            n = _frames_within_budget(value.shape, value.itemsize)
            notes.append(f"first {n} of {value.shape[0]} along axis 0")
            value = value[:n]
        if np.iscomplexobj(value):
            value = np.abs(value)
            notes.append("magnitude of complex")
        return value

    if isinstance(value, np.generic) or np.isscalar(value):
        return np.asarray(value)

    if hasattr(value, "toarray") and hasattr(value, "nnz"):  # scipy.sparse
        dense_bytes = int(np.prod(value.shape)) * value.dtype.itemsize
        if dense_bytes > BUDGET:
            raise ValueError(f"sparse {value.shape} would be {dense_bytes / 2**30:.1f} GiB dense")
        notes.append(f"scipy sparse ({value.nnz} stored), shown dense")
        return np.asarray(value.toarray())

    shape = getattr(value, "shape", None)
    if shape is not None and hasattr(value, "__getitem__"):
        # a lazy array: load only what fits, frame range along axis 0
        shape = tuple(int(n) for n in shape)
        n = _frames_within_budget(shape, _itemsize(getattr(value, "dtype", None)))
        if shape and n < shape[0]:
            notes.append(f"{type(value).__name__}: first {n} of {shape[0]} frames computed")
        else:
            notes.append(f"{type(value).__name__}: all {shape[0] if shape else 1} frames computed")
        return _to_numpy(value[:n] if shape else value[()], [])

    return np.asarray(value)


def show(label: str, value) -> str:
    np = __import__("numpy")
    notes: list = []
    started = time.perf_counter()
    array = np.require(_to_numpy(value, notes), requirements="C")  # keeps 0-d
    if array.dtype == object:
        raise TypeError(f"{label}: not a numeric array ({type(value).__name__})")
    if array.dtype == bool:
        array = array.astype(np.uint8)

    path = f"/dev/shm/nvim-sciview-{os.getpid()}-{time.time_ns()}.npy"
    np.save(path, array)
    message = {
        "label": label,
        "path": path,
        "type": f"{type(value).__module__}.{type(value).__qualname__}",
        "notes": notes,
    }
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
            sock.settimeout(60)
            sock.connect(socket_path())
            sock.sendall((json.dumps(message) + "\n").encode())
            reply = sock.makefile().readline().strip()
    except OSError as error:
        os.unlink(path)
        raise RuntimeError(f"sciview viewer not reachable: {error}") from None
    if reply != "ok":
        raise RuntimeError(f"sciview viewer: {reply}")
    took = time.perf_counter() - started
    extra = f" ({'; '.join(notes)})" if notes else ""
    return f"{label}: {tuple(array.shape)} {array.dtype} sent in {took:.2f}s{extra}"
