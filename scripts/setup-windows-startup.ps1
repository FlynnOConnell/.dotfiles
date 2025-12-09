# Setup script to configure Windows startup for komorebi
# Run this script once on Windows to set up automatic startup

$ErrorActionPreference = "Stop"

# Get the startup folder path
$StartupFolder = [System.IO.Path]::Combine($env:APPDATA, "Microsoft", "Windows", "Start Menu", "Programs", "Startup")

# Path to the start script
$StartScriptPath = [System.IO.Path]::Combine($env:USERPROFILE, ".config", "komorebi", "start-komorebi.ps1")

# Create a shortcut in the Startup folder
$WshShell = New-Object -ComObject WScript.Shell
$ShortcutPath = [System.IO.Path]::Combine($StartupFolder, "Komorebi.lnk")
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$StartScriptPath`""
$Shortcut.WorkingDirectory = $env:USERPROFILE
$Shortcut.WindowStyle = 7  # Minimized
$Shortcut.Description = "Start Komorebi Window Manager"
$Shortcut.Save()

Write-Host "✓ Created startup shortcut at: $ShortcutPath" -ForegroundColor Green
Write-Host ""
Write-Host "Komorebi will now start automatically when you log in to Windows." -ForegroundColor Cyan
Write-Host ""
Write-Host "Additional setup steps:" -ForegroundColor Yellow
Write-Host "1. Enable long path support (run as Administrator):" -ForegroundColor White
Write-Host "   Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Disable Win+L lock screen (optional, run as Administrator):" -ForegroundColor White
Write-Host "   New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'DisableLockWorkstation' -Value 1 -PropertyType DWORD -Force" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Disable unnecessary animations:" -ForegroundColor White
Write-Host "   Control Panel > Ease of Access > Make the computer easier to see" -ForegroundColor Gray
Write-Host "   Enable: 'Turn off all unnecessary animations (when possible)'" -ForegroundColor Gray
Write-Host ""
Write-Host "To start komorebi now without rebooting, run:" -ForegroundColor Yellow
Write-Host "   komorebic start --whkd --bar" -ForegroundColor Gray
