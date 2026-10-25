# Files you make for me

Anything I'll want to open (plots, reports, notes, exported data, scripts I'll run myself) goes in
`~/agent_assets/<repo>/<topic>/artifacts/`, following the `workspace-conventions` skill. `<repo>`
is the git repo's directory name, or the working directory's name outside a repo. When you tell me
where something is, give the `~/agent_assets/...` path.

Keep the session scratchpad for throwaway intermediates I'll never open.

`~/<host>` (e.g. `~/pml-w1`) is that tailnet machine's home mounted over sshfs, so files saved on
pml-w1 are readable here at `~/pml-w1/agent_assets/...`.
