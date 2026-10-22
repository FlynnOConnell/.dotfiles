"""One-glance summary of a value, for ,v while the debugger is paused.

nvim (lua/plugins/python-envs.lua) evaluates
`runpy.run_path(<this file>)["summarize"](<expression>)` in the paused frame.
Statistics are only computed for numpy arrays and torch tensors: anything
else array-like (masknmf's lazy arrays, h5py datasets) would load or compute
the whole movie just to be summarized, so those get type/shape/dtype only.
"""

import sys


def _numpy_stats(np, values) -> list[str]:
    if values.size == 0:
        return ["empty"]
    lines = []
    if values.dtype.kind == "f":
        nan = np.isnan(values)
        if nan.any():
            lines.append(f"nan    {int(nan.sum())} of {values.size}")
            values = values[~nan]
            if values.size == 0:
                return lines
    values = values.astype(np.float64)
    return lines + _format(values.min(), values.max(), values.mean(), values.std())


def _torch_stats(torch, values) -> list[str]:
    if values.numel() == 0:
        return ["empty"]
    lines = []
    if values.is_floating_point():
        nan = values.isnan()
        if nan.any():
            lines.append(f"nan    {int(nan.sum())} of {values.numel()}")
            values = values[~nan]
            if values.numel() == 0:
                return lines
    values = values.double()
    return lines + _format(values.min(), values.max(), values.mean(), values.std(unbiased=False))


def _format(low, high, mean, std) -> list[str]:
    return [
        f"min    {float(low):.6g}",
        f"max    {float(high):.6g}",
        f"mean   {float(mean):.6g}",
        f"std    {float(std):.6g}",
    ]


def summarize(value) -> str:
    kind = type(value)
    lines = [f"type   {kind.__module__}.{kind.__qualname__}"]
    if hasattr(value, "shape"):
        lines.append(f"shape  {tuple(value.shape)}")
    elif hasattr(value, "__len__"):
        lines.append(f"len    {len(value)}")
    if hasattr(value, "dtype"):
        lines.append(f"dtype  {value.dtype}")

    np = sys.modules.get("numpy")
    torch = sys.modules.get("torch")
    if np is not None and isinstance(value, np.ndarray):
        if value.dtype.kind in "biuf":
            lines += _numpy_stats(np, value)
    elif torch is not None and isinstance(value, torch.Tensor):
        lines.append(f"device {value.device}")
        if not value.is_complex() and value.dtype != torch.bool:
            lines += _torch_stats(torch, value.detach())
    elif hasattr(value, "shape"):
        lines.append("stats  not computed: lazy array, would load all of it")
    else:
        text = repr(value)
        lines.append(f"value  {text if len(text) <= 200 else text[:200] + '...'}")
    return "\n".join(lines)


def brief(value) -> str:
    """One line per variable for the ,V popup: arrays as type, shape, dtype."""
    kind = type(value).__qualname__
    if hasattr(value, "shape") and hasattr(value, "dtype"):
        dtype = str(value.dtype).removeprefix("torch.")
        device = f" {value.device}" if type(value).__module__.startswith("torch") and str(value.device) != "cpu" else ""
        return f"{kind} {tuple(value.shape)} {dtype}{device}"
    if isinstance(value, (list, tuple, dict, set)):
        return f"{kind} len {len(value)}"
    text = repr(value).replace("\n", " ")
    if text.startswith("<") and " object at 0x" in text:
        return kind  # the default repr is just the class path and an address
    return text if len(text) <= 80 else text[:80] + "..."


def briefs(namespace: dict) -> str:
    return "\n".join(f"{name}\t{brief(value)}" for name, value in namespace.items())
