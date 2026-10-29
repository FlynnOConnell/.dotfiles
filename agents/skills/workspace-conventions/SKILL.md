---
name: workspace-conventions
description: Workspace layout, artifact storage, and behavior rules shared by every agent (managers and subagents alike).
---

# Workspace conventions

## Workspace layout

All agent files live under `<root>/<A>/<B>/`:

- `<root>`: the assets root, set in `references.md`.
- `<A>`: what the work belongs to, i.e. the pipeline, project or dataset that produced it
  (e.g. `masknmf-toolbox`, `pml_utilities`), not whichever directory you were launched in.
- `<B>`: one piece of work, named as below.

Inside `<B>`: `MEMORIES.md`, `code/` (agent scripts), `artifacts/` (outputs, logs, plots, etc. — organize with subdirs).

## Naming `<A>` and `<B>` directories

Run `ls -1 <root>/` and reuse an existing `<A>` if one fits.

Name `<B>` `YYYYMMDD_<slug>`, where the date is the day the work started
and the slug is two to four lowercase words joined by hyphens. Example:
`<root>/talks/20260811_janelia-talk-description/`.

If two topics start on the same day, append `_NN` starting at `_02`:
`20260811_janelia-talk-description_02`.

Before creating `<B>`, run `ls -1 <root>/<A>/` and read the names. If a
directory already covers this work, use it. Do not create a new one per session, per
subagent, or per attempt. The date records when the work started, not when you looked
at it.

Do not rename or delete an existing `<A>` or `<B>` directory unless the user asks.

## `<root>`

Point `<root>` at permanent storage so `$HOME` doesn't fill up. It may be a symlink: traverse
with `find -L`, and don't delete or replace it. If missing: `mkdir -p <root>`.

## Behavior

- Don't change settings, install packages, or modify the environment unless explicitly asked.
- Write and run small test scripts in `<root>/<A>/<B>/code/`.
- Store lightweight artifacts in `artifacts/`; large files (`.npy`, models, checkpoints) go to `<temp_data_dir>` (see `references.md`).

## The results page

Every `<B>` shows up on the lab results page. The `runhub` skill says what the page needs
(`MEMORIES.md` abstract, `artifacts/REPORT.md`, figure depth) and the check to run before finishing.
