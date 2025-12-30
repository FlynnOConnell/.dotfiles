# Windows Dotfiles Installer
# Installs configs + optional applications via winget
#
# Usage:
#   .\install-windows.ps1
#   irm https://raw.githubusercontent.com/FlynnOConnell/.dotfiles/master/install-windows.ps1 | iex

$ErrorActionPreference = "Stop"
$DOTFILES_ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path

# If running via irm | iex, clone the repo first
if (-not $DOTFILES_ROOT -or -not (Test-Path (Join-Path $DOTFILES_ROOT "install-windows.conf.yaml"))) {
    $DOTFILES_ROOT = Join-Path $env:USERPROFILE ".dotfiles"
    if (-not (Test-Path $DOTFILES_ROOT)) {
        Write-Host "Cloning dotfiles repository..." -ForegroundColor Cyan
        git clone --recursive https://github.com/FlynnOConnell/.dotfiles.git $DOTFILES_ROOT
    }
    Set-Location $DOTFILES_ROOT
}

function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Blue }
function Write-Success { Write-Host "[OK] $args" -ForegroundColor Green }
function Write-Warn { Write-Host "[WARN] $args" -ForegroundColor Yellow }
function Write-Err { Write-Host "[ERROR] $args" -ForegroundColor Red }

function Show-Banner {
    Write-Host ""
    Write-Host "  ___        _    __ _ _           " -ForegroundColor Cyan
    Write-Host " |   \  ___ | |_ / _(_) | ___  ___ " -ForegroundColor Cyan
    Write-Host " | |) |/ _ \|  _|  _| | |/ -_)(_-< " -ForegroundColor Cyan
    Write-Host " |___/ \___/ \__|_| |_|_|\___|/__/ " -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Windows Dotfiles Installer" -ForegroundColor White
    Write-Host ""
}

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Install-Uv {
    if (Test-CommandExists "uv") {
        $version = uv --version
        Write-Info "uv already installed: $version"
        return
    }
    Write-Info "Installing uv..."
    Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-Success "uv installed"
}

function Install-Dotbot {
    Write-Info "Installing dotbot via uv..."
    uv tool install dotbot 2>&1 | Out-Null
    Write-Success "dotbot installed"
}

function Install-Configs {
    Write-Host ""
    Write-Info "Symlinking configurations..."

    # Initialize submodules
    git -C $DOTFILES_ROOT submodule update --init --recursive 2>&1 | Out-Null

    # Run dotbot
    $configPath = Join-Path $DOTFILES_ROOT "install-windows.conf.yaml"
    dotbot -d $DOTFILES_ROOT -c $configPath 2>&1 | ForEach-Object { Write-Host "  $_" }

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Configurations linked"
    } else {
        Write-Warn "Some configurations may have failed to link"
    }
}

# Available applications
$APPS = @{
    "neovim" = @{
        Name = "Neovim"
        Description = "Hyperextensible Vim-based text editor"
        Winget = "Neovim.Neovim"
    }
    "lazygit" = @{
        Name = "Lazygit"
        Description = "Simple terminal UI for git commands"
        Winget = "JesseDuffield.lazygit"
    }
    "ripgrep" = @{
        Name = "Ripgrep"
        Description = "Fast regex search tool (rg)"
        Winget = "BurntSushi.ripgrep.MSVC"
    }
    "fd" = @{
        Name = "fd"
        Description = "Fast and user-friendly find alternative"
        Winget = "sharkdp.fd"
    }
    "fzf" = @{
        Name = "fzf"
        Description = "Command-line fuzzy finder"
        Winget = "junegunn.fzf"
    }
    "btop" = @{
        Name = "btop"
        Description = "Resource monitor (top/htop alternative)"
        Winget = "aristocratos.btop4win"
    }
    "fastfetch" = @{
        Name = "Fastfetch"
        Description = "System information tool (neofetch alternative)"
        Winget = "Fastfetch-cli.Fastfetch"
    }
    "delta" = @{
        Name = "Delta"
        Description = "Syntax-highlighting pager for git/diff"
        Winget = "dandavison.delta"
    }
    "bat" = @{
        Name = "bat"
        Description = "Cat clone with syntax highlighting"
        Winget = "sharkdp.bat"
    }
    "eza" = @{
        Name = "eza"
        Description = "Modern ls replacement"
        Winget = "eza-community.eza"
    }
    "zoxide" = @{
        Name = "zoxide"
        Description = "Smarter cd command"
        Winget = "ajeetdsouza.zoxide"
    }
    "starship" = @{
        Name = "Starship"
        Description = "Cross-shell prompt"
        Winget = "Starship.Starship"
    }
}

function Show-AppSelection {
    Write-Host ""
    Write-Host "Available Applications" -ForegroundColor White
    Write-Host ""

    $sortedKeys = $APPS.Keys | Sort-Object
    $idx = 1
    $indexMap = @{}

    foreach ($key in $sortedKeys) {
        $app = $APPS[$key]
        $installed = Test-CommandExists $key
        $status = if ($installed) { " (installed)" } else { "" }
        $color = if ($installed) { "Gray" } else { "Cyan" }

        Write-Host "  [$idx] $($app.Name)$status" -ForegroundColor $color
        Write-Host "      $($app.Description)" -ForegroundColor Gray
        $indexMap[$idx] = $key
        $idx++
    }

    Write-Host ""
    Write-Host "  [A] All - Install all applications" -ForegroundColor Yellow
    Write-Host "  [N] None - Skip application installation" -ForegroundColor Yellow
    Write-Host ""

    $input = Read-Host "Select apps (comma-separated numbers, A for all, N for none)"
    $input = $input.Trim().ToUpper()

    if ($input -eq "N" -or $input -eq "") {
        return @()
    }

    if ($input -eq "A") {
        return $sortedKeys
    }

    $selected = @()
    $choices = $input -split ',' | ForEach-Object { $_.Trim() }

    foreach ($choice in $choices) {
        $num = 0
        if ([int]::TryParse($choice, [ref]$num) -and $indexMap.ContainsKey($num)) {
            $selected += $indexMap[$num]
        }
    }

    return $selected
}

function Install-App {
    param(
        [string]$Key,
        [hashtable]$AppInfo
    )

    if (Test-CommandExists $Key) {
        Write-Info "$($AppInfo.Name) already installed, skipping"
        return $true
    }

    Write-Info "Installing $($AppInfo.Name)..."

    if ($AppInfo.Winget) {
        winget install -e --id $AppInfo.Winget --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "$($AppInfo.Name) installed"
            return $true
        }
    }

    Write-Warn "Failed to install $($AppInfo.Name)"
    return $false
}

function Install-Apps {
    param([string[]]$AppKeys)

    if ($AppKeys.Count -eq 0) {
        Write-Info "Skipping application installation"
        return
    }

    # Check winget availability
    if (-not (Test-CommandExists "winget")) {
        Write-Err "winget not found. Install App Installer from Microsoft Store."
        return
    }

    Write-Host ""
    Write-Info "Installing selected applications..."

    foreach ($key in $AppKeys) {
        if ($APPS.ContainsKey($key)) {
            Install-App -Key $key -AppInfo $APPS[$key]
        }
    }
}

function Show-Summary {
    Write-Host ""
    Write-Host "Installation Complete" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Configs installed to:" -ForegroundColor Gray
    Write-Host "    ~/.config/nvim      (Neovim)" -ForegroundColor White
    Write-Host "    ~/.vimrc            (Vim)" -ForegroundColor White
    Write-Host "    ~/.ideavimrc        (JetBrains)" -ForegroundColor White
    Write-Host "    ~/.bashrc           (Bash/Git Bash)" -ForegroundColor White
    Write-Host "    ~/.aliases          (Shell aliases)" -ForegroundColor White
    Write-Host "    ~/.config/lazygit   (Lazygit)" -ForegroundColor White
    Write-Host "    ~/.config/btop      (btop)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Restart your terminal for PATH changes to take effect." -ForegroundColor Yellow
    Write-Host ""
}

function Main {
    Show-Banner

    # Step 1: Install uv
    Install-Uv

    # Step 2: Install dotbot
    Install-Dotbot

    # Step 3: Symlink configs
    Install-Configs

    # Step 4: Select and install apps
    $selectedApps = Show-AppSelection
    Install-Apps -AppKeys $selectedApps

    # Done
    Show-Summary
}

Main
