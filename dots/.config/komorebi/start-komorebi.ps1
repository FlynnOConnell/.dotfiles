# Start Komorebi Window Manager with whkd and komorebi-bar
# This script should be run at Windows startup

# Kill any existing instances
Get-Process | Where-Object { $_.Name -match "komorebi|whkd" } | Stop-Process -Force -ErrorAction SilentlyContinue

# Wait a moment for processes to fully terminate
Start-Sleep -Milliseconds 500

# Start komorebi
Start-Process -WindowStyle Hidden komorebic -- "start" "--whkd" "--bar"

Write-Host "Komorebi, whkd, and komorebi-bar started successfully!"
Write-Host "Use Win+Shift+R to reload configuration"
Write-Host "Use Win+Shift+O to reload whkd hotkey configuration"
