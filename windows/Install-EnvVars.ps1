$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

# Check if running as administrator
if (-NOT $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Not running as administrator, relaunch the script with prompt for elevation
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Output "Setting environment variable CONFIG_DIR..."
[System.Environment]::SetEnvironmentVariable("CONFIG_DIR", "$Env:USERPROFILE\.config", [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable("RUST_LOG", "debug", [System.EnvironmentVariableTarget]::Machine)
Write-Output "Setting environment variable DOTS_DIR..."
[System.Environment]::SetEnvironmentVariable("DOTS_DIR", "$Env:USERPROFILE\.dotfiles", [System.EnvironmentVariableTarget]::Machine)
Write-Output "Setting environment variable DOTS_WINDOWS_DIR..."
[System.Environment]::SetEnvironmentVariable("DOTS_WINDOWS_DIR", "$Env:USERPROFILE\.dotfiles\windows", [System.EnvironmentVariableTarget]::Machine)
Write-Output "Setting environment variable DOTS_PSMODULES_DIR..."
[System.Environment]::SetEnvironmentVariable("DOTS_PSMODULES_DIR", "$Env:USERPROFILE\.dotfiles\windows\modules", [System.EnvironmentVariableTarget]::Machine)

Write-Output "Environment variables set successfully. You may need to restart your computer for changes to take effect."


