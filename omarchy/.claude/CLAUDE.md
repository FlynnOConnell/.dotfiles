# Files you make for me

Anything I'll want to open (plots, reports, notes, exported data, scripts I'll run myself) goes in
`<root>/<A>/<B>/artifacts/`, following the `workspace-conventions` skill. `<root>` is
`$AGENT_ASSETS_ROOT`, or `~/agent_assets` when that's unset. `<A>` is the pipeline or project the
work belongs to, `<B>` the topic folder. When you tell me where something is, give the full path
(e.g. `~/agent_assets/...`).

Keep the session scratchpad for throwaway intermediates I'll never open.

`~/<host>` (e.g. `~/pml-w1`) is that tailnet machine's home mounted over sshfs, so files saved on
pml-w1 are readable here at `~/pml-w1/agent_assets/...`.

# Commits

- One line, lowercase, no body, no trailers, no Co-Authored-By, no "Generated with Claude Code".
- Small atomic changes, one commit each: "updates to the new fpl 0.7 api", "fixes problem where xyz happens".
- PR descriptions get no attribution line either.
