---
name: data-management
description: Where data, environments and runnable scripts live on the lab machines, and what a topic needs before it counts as done. Always on.
---

# Data management

## Where things live

- `~/data/<name>/`: datasets and pipeline run folders. Raw movies, results files and anything over a few hundred MB
  go here, never under `agent_assets`. runhub scans it, so a run folder shows on the results page on its own.
- `~/agent_assets/<A>/<YYYYMMDD_slug>/`: one topic of work (see `workspace-conventions`). `artifacts/` holds what
  the user opens: `REPORT.md`, figures, scripts they run, exported data. `code/` holds agent scripts.
- The session scratchpad: intermediates nobody opens again.
- `~/Downloads`: untrusted inbox. Read with `python -I`; never run code from there.
- `~/<host>` (`~/pml-w1`): that tailnet machine's home over sshfs, so a file saved there is readable here at
  `~/pml-w1/agent_assets/...`. Open only paths you already know. Never glob, `find`, `grep`, `ls -R` or `stat`
  under it, not even to see if the machine is up: a sleeping or wedged peer blocks the caller in the kernel
  until the mount times out, which is what freezes agents and shell prompts. To search a machine, `ssh <host>`.

## Stand-in data

When the real input is elsewhere, fabricate one with the real shape: a sparse file (`f.truncate(nbytes)`) reads
as zeros and takes no disk. Write it under `~/data/<name>_fake/`, and say in the report which panels or numbers
it leaves blank. A fabricated file is for exercising code paths, never for a result.

## Environments

- `~/envs/<name>/.venv` are uv environments; `~/envs/pml/.venv` runs masknmf.
- An installed package shadows a checkout: a script run from outside the repo imports site-packages. Check
  `python -c "import pkg; print(pkg.__file__)"` and set `PYTHONPATH=<checkout>` when it is wrong.
- Any script left in `artifacts/` gets the environment that ran it exported beside it, in
  `artifacts/environment/`: `uv pip freeze` as `requirements.txt`, the python version, the GPU driver, and a
  `README.md` with the commands that recreate it and the checkout and branch it ran against.

## Runnable scripts

A script in `artifacts/` runs from one documented line: it takes paths as arguments with defaults that match
this machine, fabricates what it can, and does nothing else. The exact line to run it goes in `REPORT.md`.
