# Parameters

## Variables
- `<temp_data_dir>`: /n/netscratch/bsabatini_lab/Lab/rhakim/temp
- `<root>`: `$AGENT_ASSETS_ROOT`, or `~/agent_assets` when unset (`echo "${AGENT_ASSETS_ROOT:-$HOME/agent_assets}"`)

Cluster/partition details: load `job-dispatch`.

## Access
- Internet, file editing, terminal: enabled. 
- Git: no commit/push/PR unless user asks (resets after each).

## Compute
Don't run on login nodes — `ssh <compute_node_name>` first (changes; recheck). For batch and/or heavy compute work load `job-dispatch`.
