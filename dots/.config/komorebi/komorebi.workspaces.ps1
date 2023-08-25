# Create named workspaces I-V on monitor 0
komorebic ensure-named-workspaces 0 I II
komorebic ensure-named-workspaces 1 I II

# Assign layouts to workspaces, possible values: bsp, columns, rows, vertical-stack, horizontal-stack, ultrawide-vertical-stack
komorebic named-workspace-layout 0 bsp
komorebic named-workspace-layout 1 vertical-stack
