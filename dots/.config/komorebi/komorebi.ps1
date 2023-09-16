. $PSScriptRoot\komorebi.generated.ps1

komorebic ensure-named-workspaces 0 I II III IV V VI
komorebic ensure-named-workspaces 1 A B

komorebic named-workspace-layout I bsp
komorebic named-workspace-layout A horizontal-stack
komorebic named-workspace-layout B horizontal-stack

komorebic initial-workspace-rule exe "firefox.exe" 0 0

komorebic initial-workspace-rule exe "WindowsTerminal.exe" 0 1
komorebic initial-workspace-rule exe "OpenConsole.exe" 0 1
komorebic initial-workspace-rule exe "OpenConsole.exe" 0 1
komorebic initial-workspace-rule exe "pwsh.exe" 0 1
komorebic initial-workspace-rule exe "wsl.exe" 0 1

komorebic initial-workspace-rule exe "pycharm64.exe" 0 3
komorebic initial-workspace-rule exe "pycharm64.exe" 0 3

komorebic initial-workspace-rule exe "POWERPNT.exe" 0 4

komorebic initial-workspace-rule exe "Discord.exe" 1 0

# Send the ALT key whenever changing focus to force focus changes
komorebic alt-focus-hack enable
komorebic window-hiding-behaviour cloak
komorebic cross-monitor-move-behaviour insert
komorebic watch-configuration enable

# Configure the invisible border dimensions
komorebic invisible-borders 7 0 10 7
komorebic active-window-border enable
komorebic active-window-border-colour 180 190 254 --window-kind single
komorebic active-window-border-colour 238 75 43 --window-kind stack
komorebic active-window-border-colour 255 255 50 --window-kind monocle

# enable focus following the mouse
komorebic toggle-focus-follows-mouse --implementation komorebi

komorebic complete-configuration
