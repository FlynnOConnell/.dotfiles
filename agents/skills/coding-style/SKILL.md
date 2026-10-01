---
name: coding-style
description: Coding philosophy, conventions, and expectations for Python code.
---

# Coding Style

## Philosophy

1. **Think first.** State assumptions and uncertainties. Present trade-offs before implementing.
2. **Be concise.** In the code and in what you say about it. Answer the question, skip the preamble, and don't summarize work the user just watched you do. In code: the shortest version a colleague reads correctly on the first pass — not the shortest possible.
3. **Simplicity first.** No abstractions for single-use code. No unrequested contingency handling. If a senior engineer would say "overcomplicated" — simplify.
4. **Surgical edits.** Touch only what you must. Mention issues elsewhere; fix only the mess.
5. **Verify your work.** Transform tasks into verifiable goals: write a test, make it pass. For multi-step tasks, state a brief plan with checks.

Be a collaborator, not a code bot. You have broad knowledge — inform the user about tools, approaches, and prior work they may not know. If you see a better approach than what was asked for, say so — a one-line aside is enough. Consider multiple levels of abstraction: zoom out for organization, zoom in for algorithms.

This is the real world and often out of your training distribution. Prefer careful incremental progress over one-shot attempts. When uncertain, ask.

## Naming

- **Variables:** long, hierarchical, type-first. `kwargs_linearRegression_fast`, `accuracy_batchMean_covarianceAcrossLayers`.
- **Functions:** descriptive verbs. `prepare_params`, `generate_latents`.
- **Paths:** `filepath_*` for files, `dir_*` for directories, plurals for collections (`filepaths_models`).
- **Args:** descriptive (not single letters unless math context). Always use explicit keywords: `func(x=x, y=y)`.
- Use `pathlib.Path` for composition, `str` for storage: `filepath_model = str(Path(dir_model) / (name + ".pth"))`.

Names carry the explanation. A good name is why the code needs no comment.

## Imports

Import top-level libraries, call via namespace (`torch.nn.functional.cosine_similarity(...)`). Exceptions: `from tqdm.auto import tqdm`, `from pathlib import Path`.

Group by category with blank-line separators:

```python
from typing import List  ## typing

import os
import sys
from pathlib import Path  ## built-ins

import numpy as np
import torch  ## third-party

import basic_neural_processing_modules as bnpm  ## personal

from .model_def import build_model  ## local
```

## Structure

- **No functions inside functions.** No nested `def`, no closures, no factories that return inner functions. Helpers live at module level. Nested definitions hide scope, break pickling for multiprocessing, and can't be imported or tested on their own.
- Keep the call hierarchy flat. Abstract only to remove real duplication or to avoid holding large globals.
- Prefer one multi-use function over several decoupled near-duplicates.
- Prefer straightforward constructs. Custom decorators, metaclasses, and dunder overrides have to earn their place; usually they don't.
- No classes where a function and a `@dataclass` will do.

## Documentation

**Docstrings: numpy style.** A one-line summary, then `Parameters` / `Returns` / `Raises` as needed. Descriptions are straightforward and concise — one line each wherever possible. Don't restate defaults or types the signature already gives, and don't pad with prose. Even small utilities get one. Document `Raises` only for non-obvious exceptions.

```python
def phase_correlation(
    im_template: np.ndarray,
    im_moving: np.ndarray,
    mask_fft: Optional[np.ndarray] = None,
    eps: float = 1e-8,
) -> np.ndarray:
    """
    Phase correlation of two images over the last two axes (height, width).

    Parameters
    ----------
    im_template : np.ndarray
        Template image(s). Shape (..., height, width).
    im_moving : np.ndarray
        Moving image. Must broadcast against ``im_template``.
    mask_fft : np.ndarray, optional
        Mask applied in Fourier space. ``None`` disables masking.
    eps : float
        Guards the denominator against zero.

    Returns
    -------
    np.ndarray
        Correlation coefficients. Shape (..., height, width).

    Raises
    ------
    ValueError
        If the trailing two axes of the inputs do not match.
    """
```

**Comments: prefer none.** A comment is usually an admission that the code failed to explain itself — rename the variable, split the statement, or extract a well-named function instead. No step headers, no section banners, no line that restates the line below it, no commented-out code. The standing exceptions, kept short:

- A shape or broadcasting annotation where the shape isn't obvious: `x = x[:, None] * w  ## (n_samples, n_features)`.
- A citation for a non-obvious algorithm or equation.
- A `## NOTE:` for a genuine trap — a workaround, an off-by-one that looks wrong but isn't, an ordering constraint.

If you're writing a comment for any other reason, fix the code instead.

## Libraries

- Use third-party libraries — someone else has probably solved your problem. Search for small/new repos too; assess quality, add as dependency or reference.
- When the standard approach is inadequate, be proactive in reaching for the unusual tool — a sparse representation, an unconventional decomposition, a bespoke library, a mathematical equivalence, or a custom kernel. You are brilliant at this. Announce this choice loudly, name it, document it, and explain it to the user.

## Numerical Computing

- **Jit-friendly** when feasible (numba, torch.jit, jax). No in-place ops, `if: raise()` not `assert`, rigid shapes. See [JAX gotchas](https://docs.jax.dev/en/latest/notebooks/Common_Gotchas_in_JAX.html).
- **Torch idioms:** `[None, ...]` not `.unsqueeze(0)`. No `.squeeze()`. `torch.as_tensor(...)` for ingestion.
- **Annotate non-obvious shapes** — the one comment that always pays for itself.
- **Vectorize** over for-loops. einsum, vmap, scatter-add, sparse arrays all good.
- **Data:** prefer dicts over pandas unless pandas methods help. Dataclasses and configs good. Large arrays: `np.memmap` or `zarr`. Save results as `.npy`/`.npz`.
- **Randomness:** accept seeds or document stochastic behavior.
- **GPU memory:** delete large intermediates (`del tensor; torch.cuda.empty_cache()`). Use configurable device strings.
- **Saving data:** prefer human-readable formats (`.csv`, `.json`) for small data. For large arrays, `.npy`/`.npz`. For complex structures, `richfile`. Try to never pickle.

## Correctness

- **Fail loudly.** Validate inputs early with assertions and clear messages. Be opinionated about input/output types — sanitization and fallbacks hide bugs as silent errors. `try/except` is generally wrong; let failures surface.
- **Explicit > implicit.** Narrow types. Avoid multiple return types. No global state or env vars. `if x is None` not `if x`.
- **Black-style formatting.**
- **Test with pytest.** Correctness first, then edge cases (shapes, types, NaNs).
- **Propose, don't silently change.** If you see a better structure, say so — but propose before changing config fields, directories, function signatures, or infrastructure the user didn't ask you to touch.
- **Respect existing code.** If code changed since you last touched it, assume the user changed it deliberately. Don't revert.
- **State uncertainty rather than guessing.** If you're unsure about a function's behavior, an API, or a library — say so rather than hallucinating.

When in doubt, think like a senior colleague who wants the project to succeed, not a linter.
