---
name: environments
description: Which Python environment to run code in and how to get a checkout or branch into it, on this machine or another. Apply before running Python, before installing anything, and before telling the user how to run something. Always on.
---

# Environments

There is already a `.venv` to activate. I work across many repos at once, not inside one `pyproject.toml`, so
making an environment per repo is never the answer.

## Finding the environment

- Use the one the project's own instructions name (`CLAUDE.md`, `AGENTS.md`, a README), if any.
- Otherwise look for an existing `.venv`: `ls -d ~/envs/*/.venv ~/code/*/.venv ~/projects/*/.venv ~/repos/*/.venv`.
  A shared one under `~/envs/<name>/` comes before a repo's own.
- Several candidates and nothing to choose by: ask which, once, and keep using it.
- None found: ask. Do not create one.

## Rules

- Activate it: `source <env>/.venv/bin/activate`. In a one-liner: `<env>/.venv/bin/python script.py`.
- Never run `uv sync`, `uv venv`, `uv run` or `python -m venv`. Each of those makes or rewrites an environment.
- No `PYTHONPATH` to point at a checkout. Install the checkout instead, so the same command works everywhere.

## Getting code into the environment

With the environment active, in this order:

1. A checkout on this machine: `uv pip install -e <path to repo>`. Editable, so later edits and branch switches
   need no reinstall.
2. A branch that is pushed: `uv pip install "git+ssh://git@<host>/<group>/<repo>.git@<branch>"`. Take the URL
   from `git -C <repo> remote get-url origin`. This is the way onto another machine: push here, install there.
   It always works.
3. A missing third-party package: `uv pip install <package>`, after asking.

Afterwards check what is imported: `python -c "import pkg; print(pkg.__file__)"`. An editable install prints the
checkout path; an install from a remote prints `site-packages`.

A shared environment may be running other work. Before replacing a package in it with another branch, say which
package and branch, and say it again in the report.

## Telling the user how to run something

The instructions are three lines, for any machine:

```bash
source <env>/.venv/bin/activate
uv pip install "git+ssh://git@<host>/<group>/<repo>.git@<branch>"   # or: uv pip install -e <path to repo>
python <script> <arguments>
```

- If the code is not pushed, say so and offer to push, instead of describing a clone, a checkout and a sync.
- A standalone script travels by `scp` or as a file in the pushed repo; say which.
- Do not assume the other machine has the repo cloned, the data, or the same paths. Name what has to be copied.

## Recording the environment

Any script left for the user to run gets the environment that ran it recorded beside it: `uv pip freeze` as
`requirements.txt`, the python version, the GPU driver, and a `README.md` with the three lines above filled in:
the environment, each installed checkout with its branch and commit, and the run line.
