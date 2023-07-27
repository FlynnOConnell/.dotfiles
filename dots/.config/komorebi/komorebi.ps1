if (!(Get-Process whkd -ErrorAction SilentlyContinue))
{
    Start-Process whkd -WindowStyle hidden
}

. $PSScriptRoot\komorebi.generated.ps1
. $PSScriptRoot\komorebi.workspaces.ps1

# Send the ALT key whenever changing focus to force focus changes
komorebic alt-focus-hack enable
# Default to minimizing windows when switching workspaces
komorebic window-hiding-behaviour cloak
# Set cross-monitor move behaviour to insert instead of swap
komorebic cross-monitor-move-behaviour insert
# Enable hot reloading of changes to this file
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
