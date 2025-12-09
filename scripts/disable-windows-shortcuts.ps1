# Disable Windows Default Shortcuts
# This script disables Windows shortcuts that interfere with komorebi
# Run this as Administrator

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then run this script again." -ForegroundColor Yellow
    exit 1
}

Write-Host "Disabling Windows default shortcuts that interfere with komorebi..." -ForegroundColor Cyan
Write-Host ""

# Create registry key if it doesn't exist
$explorerAdvancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
if (-not (Test-Path $explorerAdvancedPath)) {
    New-Item -Path $explorerAdvancedPath -Force | Out-Null
}

# Disable Windows key hotkeys
Write-Host "[1/6] Disabling Windows key shortcuts..." -ForegroundColor Yellow
Set-ItemProperty -Path $explorerAdvancedPath -Name "DisabledHotkeys" -Value "HKLIJPXAVDTRS" -Type String

# Disable Win+H (Voice typing/Dictation)
Write-Host "[2/6] Disabling Win+H (Voice Typing)..." -ForegroundColor Yellow
$keyboardPath = "HKCU:\Software\Microsoft\Input\Settings"
if (-not (Test-Path $keyboardPath)) {
    New-Item -Path $keyboardPath -Force | Out-Null
}
Set-ItemProperty -Path $keyboardPath -Name "EnableHwkbTextPrediction" -Value 0 -Type DWord
Set-ItemProperty -Path $keyboardPath -Name "IsVoiceTypingKeyEnabled" -Value 0 -Type DWord

# Disable Win+K (Connect/Cast)
Write-Host "[3/6] Disabling Win+K (Connect/Cast)..." -ForegroundColor Yellow
$castPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Set-ItemProperty -Path $castPath -Name "EnableXamlStartMenu" -Value 0 -Type DWord -ErrorAction SilentlyContinue

# Disable Win+I (Settings shortcut)
Write-Host "[4/6] Disabling Win+I (Settings)..." -ForegroundColor Yellow
$policiesPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
if (-not (Test-Path $policiesPath)) {
    New-Item -Path $policiesPath -Force | Out-Null
}
Set-ItemProperty -Path $policiesPath -Name "NoWinKeys" -Value 0 -Type DWord

# Disable Win+X (Power user menu)
Write-Host "[5/6] Disabling Win+X (Power User Menu)..." -ForegroundColor Yellow
Set-ItemProperty -Path $policiesPath -Name "NoStartMenuMFUprogramsList" -Value 0 -Type DWord -ErrorAction SilentlyContinue

# Disable Game Bar (Win+G)
Write-Host "[6/6] Disabling Win+G (Game Bar)..." -ForegroundColor Yellow
$gameBarPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
if (-not (Test-Path $gameBarPath)) {
    New-Item -Path $gameBarPath -Force | Out-Null
}
Set-ItemProperty -Path $gameBarPath -Name "AppCaptureEnabled" -Value 0 -Type DWord

$gameBarPath2 = "HKCU:\System\GameConfigStore"
if (-not (Test-Path $gameBarPath2)) {
    New-Item -Path $gameBarPath2 -Force | Out-Null
}
Set-ItemProperty -Path $gameBarPath2 -Name "GameDVR_Enabled" -Value 0 -Type DWord

Write-Host ""
Write-Host "✓ Windows shortcuts have been disabled!" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT: You must restart Windows (or at least restart explorer.exe) for changes to take effect." -ForegroundColor Yellow
Write-Host ""
Write-Host "To restart explorer.exe now, run:" -ForegroundColor Cyan
Write-Host "  Stop-Process -Name explorer -Force" -ForegroundColor Gray
Write-Host ""
Write-Host "Some shortcuts that remain active (by design):" -ForegroundColor Yellow
Write-Host "  - Win+L (Lock screen) - Can be disabled separately if needed" -ForegroundColor Gray
Write-Host "  - Win+D (Show desktop) - Generally useful to keep" -ForegroundColor Gray
Write-Host "  - Win+E (Explorer) - Can be overridden in whkdrc if desired" -ForegroundColor Gray
Write-Host ""

# Ask if user wants to restart explorer now
$restart = Read-Host "Restart explorer.exe now? (y/n)"
if ($restart -eq "y" -or $restart -eq "Y") {
    Write-Host "Restarting explorer.exe..." -ForegroundColor Cyan
    Stop-Process -Name explorer -Force
    Start-Sleep -Seconds 2
    Write-Host "✓ Explorer restarted!" -ForegroundColor Green
}
