# Komorebi Configuration Script
# This script is deprecated in favor of komorebi.json
# It's kept for backwards compatibility and additional runtime configurations

# Note: Most configuration is now handled by komorebi.json
# This script can be used for dynamic configurations that can't be expressed in JSON

# Example: Set workspace-specific rules at runtime
# komorebic workspace-rule exe "firefox.exe" 0 0

Write-Host "Loading komorebi configuration from komorebi.json..." -ForegroundColor Cyan
Write-Host "For customization, edit:" -ForegroundColor Yellow
Write-Host "  - $env:USERPROFILE\.config\komorebi\komorebi.json (main config)" -ForegroundColor Gray
Write-Host "  - $env:USERPROFILE\.config\whkd\whkdrc (keybindings)" -ForegroundColor Gray
Write-Host "  - $env:USERPROFILE\.config\komorebi\applications.json (app rules)" -ForegroundColor Gray
