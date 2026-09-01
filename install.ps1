# ============================================================================
# DOTFILES INSTALLER - Windows
# ============================================================================
#
# Usage:
#   .\install.ps1
#   iex (irm https://raw.githubusercontent.com/FlynnOConnell/.dotfiles/master/install.ps1)
#
# ============================================================================
# WHAT THIS INSTALLS
# ============================================================================
#
# CORE (always installed):
#   - uv              Python package manager (astral.sh)
#   - Python 3.12     via uv (not system Python)
#   - dotbot          Symlink manager
#
# PYTHON TOOLS (via uv):
#   - ty              Type checker
#   - ruff            Linter/formatter
#   - debugpy         Python debugger for DAP
#   - pynvim          Neovim Python provider (in dedicated venv)
#
# NODE PACKAGES:
#   - neovim          Neovim Node provider
#
# APPS (optional, via winget - user selects):
#   - neovim          Text editor
#   - lazygit         Git TUI
#   - ripgrep         Fast grep (rg)
#   - fd              Fast find
#   - fzf             Fuzzy finder
#   - bat             Cat with syntax highlighting
#   - delta           Git diff viewer
#   - eza             Modern ls
#   - zoxide          Smart cd
#   - starship        Shell prompt
#   - btop            System monitor
#   - fastfetch       System info
#   - ffmpeg          Media toolkit
#   - rust            Rust toolchain
#   - nodejs          JavaScript runtime
#   - nerd-fonts      JetBrainsMono Nerd Font
#
# ============================================================================
# WHAT THIS CONFIGURES
# ============================================================================
#
# SYMLINKS (via dotbot):
#   ~/.config/nvim      -> ~/repos/kickstart.nvim (standalone Neovim config repo)
#   ~/.vimrc            -> dots/.config/vim/.vimrc
#   ~/.ideavimrc        -> dots/.ideavimrc
#   ~/.bashrc           -> dots/.bashrc
#   ~/.aliases          -> dots/.aliases
#   ~/.config/lazygit   -> dots/.config/lazygit
#   %LOCALAPPDATA%\lazygit\config.yml -> dots/.config/lazygit/config.yml (what lazygit actually reads on Windows)
#   ~/.config/starship.toml -> dots/.config/starship/starship.toml
#   ~/.config/btop      -> dots/.config/btop
#   ~/.config/fastfetch -> dots/.config/fastfetch
#   ~/.config/micro     -> dots/.config/micro
#
# POWERSHELL PROFILE ($PROFILE):
#   - PSReadLine with history search, predictions, tab completion
#   - Aliases: lg, vim, vi, g, lsa, ll, rm (unix-style)
#   - Git shortcuts: gs, ga, gc, gp, gl, gd
#   - Zoxide integration
#   - Starship prompt
#
# WINDOWS TERMINAL:
#   - Default profile: PowerShell 7 (pwsh.exe)
#   - Font: JetBrainsMono Nerd Font
#   - Hidden: Legacy Windows PowerShell 5.1
#
# ============================================================================

$ErrorActionPreference = "Stop"

# Determine dotfiles location
$DOTFILES_ROOT = $null

# Check if running from local file
$scriptPath = $MyInvocation.MyCommand.Path
if ($scriptPath -and $scriptPath -ne "") {
    $DOTFILES_ROOT = Split-Path -Parent $scriptPath
}

# Validate or clone
if (-not $DOTFILES_ROOT -or -not (Test-Path $DOTFILES_ROOT)) {
    $DOTFILES_ROOT = Join-Path $env:USERPROFILE ".dotfiles"
}

if (-not (Test-Path (Join-Path $DOTFILES_ROOT "install.conf.yaml")) -and -not (Test-Path (Join-Path $DOTFILES_ROOT "install-windows.conf.yaml"))) {
    Write-Host "Cloning dotfiles repository to $DOTFILES_ROOT ..." -ForegroundColor Cyan
    if (Test-Path $DOTFILES_ROOT) {
        Remove-Item -Recurse -Force $DOTFILES_ROOT
    }
    git clone --recursive https://github.com/FlynnOConnell/.dotfiles.git $DOTFILES_ROOT
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to clone repository" -ForegroundColor Red
        exit 1
    }
}

Set-Location $DOTFILES_ROOT

function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Blue }
function Write-Success { Write-Host "[OK] $args" -ForegroundColor Green }
function Write-Warn { Write-Host "[WARN] $args" -ForegroundColor Yellow }
function Write-Err { Write-Host "[ERROR] $args" -ForegroundColor Red }

function Test-SymlinkCapability {
    # Check if running as admin
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) { return $true }

    # Check Developer Mode
    try {
        $devMode = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -ErrorAction SilentlyContinue
        if ($devMode.AllowDevelopmentWithoutDevLicense -eq 1) { return $true }
    } catch {}

    return $false
}

function Request-AdminOrDevMode {
    Write-Host ""
    Write-Warn "Symlinks require Administrator privileges or Developer Mode."
    Write-Host ""
    Write-Host "  [1] Re-run entire script as Administrator" -ForegroundColor Cyan
    Write-Host "  [2] Create symlinks only (elevate just for symlinks)" -ForegroundColor Cyan
    Write-Host "  [3] Continue without symlinks (apps only)" -ForegroundColor Cyan
    Write-Host "  [4] Exit" -ForegroundColor Cyan
    Write-Host ""

    $choice = Read-Host "Select option (1-4)"

    switch ($choice) {
        "1" {
            Write-Info "Re-launching as Administrator..."
            $scriptPath = Join-Path $DOTFILES_ROOT "install-windows.ps1"
            Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`""
            exit 0
        }
        "2" {
            # Create symlinks via elevated subprocess
            Install-SymlinksElevated
            return $true  # Continue with apps
        }
        "3" {
            return $true  # Continue without symlinks
        }
        default {
            return $false  # Exit
        }
    }
}

function Install-SymlinksElevated {
    Write-Info "Creating symlinks with elevation..."

    # Build the symlink commands
    $symlinkScript = @"
`$ErrorActionPreference = 'Continue'
`$dotfiles = '$DOTFILES_ROOT'

# Neovim config
`$nvimTarget = Join-Path `$env:USERPROFILE 'repos\kickstart.nvim'
`$nvimLink = Join-Path `$env:LOCALAPPDATA 'nvim'
if (Test-Path `$nvimLink) { Remove-Item -Recurse -Force `$nvimLink }
New-Item -ItemType SymbolicLink -Path `$nvimLink -Target `$nvimTarget -Force | Out-Null
Write-Host "[OK] Neovim config linked" -ForegroundColor Green

# Home directory symlinks
`$links = @{
    '~/.vimrc' = 'dots/.config/vim/.vimrc'
    '~/.ideavimrc' = 'dots/.ideavimrc'
    '~/.bashrc' = 'dots/.bashrc'
    '~/.aliases' = 'dots/.aliases'
}

foreach (`$link in `$links.GetEnumerator()) {
    `$linkPath = `$link.Key -replace '~', `$env:USERPROFILE
    `$targetPath = Join-Path `$dotfiles `$link.Value
    if (Test-Path `$linkPath) { Remove-Item -Force `$linkPath }
    New-Item -ItemType SymbolicLink -Path `$linkPath -Target `$targetPath -Force | Out-Null
    Write-Host "[OK] `$(`$link.Key) linked" -ForegroundColor Green
}

# .config directory symlinks
`$configLinks = @{
    'lazygit' = 'dots/.config/lazygit'
    'btop' = 'dots/.config/btop'
    'micro' = 'dots/.config/micro'
    'cheatsheets' = 'dots/.config/cheatsheets'
    'fastfetch' = 'dots/.config/fastfetch'
    'github-copilot' = 'dots/.config/github-copilot'
    'starship.toml' = 'dots/.config/starship/starship.toml'
}

`$configDir = Join-Path `$env:USERPROFILE '.config'
if (-not (Test-Path `$configDir)) { New-Item -ItemType Directory -Path `$configDir -Force | Out-Null }

foreach (`$link in `$configLinks.GetEnumerator()) {
    `$linkPath = Join-Path `$configDir `$link.Key
    `$targetPath = Join-Path `$dotfiles `$link.Value
    if (Test-Path `$targetPath) {
        if (Test-Path `$linkPath) { Remove-Item -Recurse -Force `$linkPath }
        New-Item -ItemType SymbolicLink -Path `$linkPath -Target `$targetPath -Force | Out-Null
        Write-Host "[OK] ~/.config/`$(`$link.Key) linked" -ForegroundColor Green
    }
}

# lazygit on Windows reads %LOCALAPPDATA%\lazygit\config.yml, NOT ~/.config/lazygit
`$lgDir = Join-Path `$env:LOCALAPPDATA 'lazygit'
if (-not (Test-Path `$lgDir)) { New-Item -ItemType Directory -Path `$lgDir -Force | Out-Null }
`$lgLink = Join-Path `$lgDir 'config.yml'
`$lgTarget = Join-Path `$dotfiles 'dots/.config/lazygit/config.yml'
if (Test-Path `$lgLink) { Remove-Item -Force `$lgLink }
New-Item -ItemType SymbolicLink -Path `$lgLink -Target `$lgTarget -Force | Out-Null
Write-Host "[OK] %LOCALAPPDATA%\lazygit\config.yml linked" -ForegroundColor Green

Write-Host ""
Write-Host "Symlinks created successfully!" -ForegroundColor Green
Start-Sleep -Seconds 2
"@

    # Run elevated
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($symlinkScript)
    $encoded = [Convert]::ToBase64String($bytes)

    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -EncodedCommand $encoded" -Wait
    Write-Success "Symlinks created"
}

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

function Install-PowerShell7 {
    if (Test-CommandExists "pwsh") {
        $version = pwsh --version
        Write-Info "PowerShell 7 already installed: $version"
        return
    }
    if (-not (Test-CommandExists "winget")) {
        Write-Err "winget not found; cannot install PowerShell 7. Install App Installer from Microsoft Store, then re-run."
        return
    }
    Write-Info "Installing PowerShell 7 (required for `$PROFILE and Windows Terminal defaults)..."
    $ErrorActionPreference = "Continue"
    $output = winget install -e --id Microsoft.PowerShell --accept-package-agreements --accept-source-agreements --disable-interactivity 2>&1 | Out-String
    $ErrorActionPreference = "Stop"
    if ($LASTEXITCODE -eq 0 -or $output -match "already installed") {
        Write-Success "PowerShell 7 installed"
    } else {
        Write-Warn "Failed to install PowerShell 7: exit code $LASTEXITCODE"
    }
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Install-Dotbot {
    # Check if dotbot is already installed
    $installed = uv tool list 2>$null | Select-String "dotbot"
    if ($installed) {
        Write-Info "dotbot already installed"
        return
    }
    Write-Info "Installing dotbot via uv..."
    $ErrorActionPreference = "Continue"
    $output = uv tool install dotbot 2>&1
    $ErrorActionPreference = "Stop"
    if ($LASTEXITCODE -eq 0) {
        Write-Success "dotbot installed"
    } else {
        Write-Warn "dotbot install returned: $output"
    }
}

function Install-Configs {
    Write-Host ""
    Write-Info "Symlinking configurations..."

    # Initialize submodules (git outputs to stderr even on success)
    $ErrorActionPreference = "Continue"
    git -C $DOTFILES_ROOT submodule update --init --recursive 2>&1 | Out-Null
    $ErrorActionPreference = "Stop"

    # Run dotbot
    $configPath = Join-Path $DOTFILES_ROOT "install-windows.conf.yaml"
    $ErrorActionPreference = "Continue"
    dotbot -d $DOTFILES_ROOT -c $configPath 2>&1 | ForEach-Object { Write-Host "  $_" }
    $dotbotExit = $LASTEXITCODE
    $ErrorActionPreference = "Stop"

    if ($dotbotExit -eq 0) {
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
    "tree-sitter-cli" = @{
        Name = "tree-sitter CLI"
        Description = "Required by nvim-treesitter (main branch) to compile parsers"
        Winget = "tree-sitter.tree-sitter-cli"
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
    "nerd-fonts" = @{
        Name = "JetBrainsMono Nerd Font"
        Description = "Nerd Font for terminal icons (Starship, eza, etc.)"
        Winget = "DEVCOM.JetBrainsMonoNerdFont"
    }
    "ffmpeg" = @{
        Name = "FFmpeg"
        Description = "Video/audio processing toolkit"
        Winget = "Gyan.FFmpeg"
    }
    "rust" = @{
        Name = "Rust"
        Description = "Rust toolchain (rustc, cargo, rustup)"
        Winget = "Rustlang.Rustup"
    }
    "nodejs" = @{
        Name = "Node.js"
        Description = "JavaScript runtime (needed for some LSPs)"
        Winget = "OpenJS.NodeJS.LTS"
    }
    "git" = @{
        Name = "Git"
        Description = "Version control system"
        Winget = "Git.Git"
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

    $selection = Read-Host "Select apps (comma-separated numbers, A for all, N for none)"
    if (-not $selection) { $selection = "N" }
    $selection = $selection.Trim().ToUpper()

    if ($selection -eq "N" -or $selection -eq "") {
        return @()
    }

    if ($selection -eq "A") {
        return $sortedKeys
    }

    $selected = @()
    $choices = $selection -split ',' | ForEach-Object { $_.Trim() }

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

    # Check if command exists in PATH
    if (Test-CommandExists $Key) {
        Write-Info "$($AppInfo.Name) already installed"
        return $true
    }

    # Also check winget list for installed apps (some don't add to PATH)
    $installed = winget list --id $AppInfo.Winget --accept-source-agreements --disable-interactivity 2>$null | Out-String
    if ($installed -match $AppInfo.Winget) {
        Write-Info "$($AppInfo.Name) already installed (via winget)"
        return $true
    }

    Write-Info "Installing $($AppInfo.Name)..."

    if ($AppInfo.Winget) {
        $ErrorActionPreference = "Continue"
        $output = winget install -e --id $AppInfo.Winget --accept-package-agreements --accept-source-agreements --disable-interactivity 2>&1 | Out-String
        $ErrorActionPreference = "Stop"

        if ($LASTEXITCODE -eq 0) {
            Write-Success "$($AppInfo.Name) installed"
            return $true
        } elseif ($output -match "already installed" -or $output -match "No available upgrade") {
            Write-Info "$($AppInfo.Name) already installed"
            return $true
        } else {
            Write-Warn "Failed to install $($AppInfo.Name): exit code $LASTEXITCODE"
            return $false
        }
    }

    Write-Warn "No winget ID for $($AppInfo.Name)"
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

function Install-CoreDependencies {
    Write-Host ""
    Write-Info "Installing core dependencies..."

    $ErrorActionPreference = "Continue"

    # Install Python via uv (not system Python)
    Write-Info "Installing Python 3.12 via uv..."
    uv python install 3.12 2>&1 | ForEach-Object { if ($_ -match "Installed|already") { Write-Success $_ } }

    # Find uv's python and add to PATH for Mason/Neovim
    $uvPythonDir = uv python find 3.12 2>&1 | Out-String
    $uvPythonDir = $uvPythonDir.Trim()
    if ($uvPythonDir -and (Test-Path $uvPythonDir)) {
        $pythonBinDir = Split-Path $uvPythonDir -Parent
        Write-Info "Found uv Python at: $pythonBinDir"

        # Add to user PATH if not already there
        $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
        if ($userPath -notlike "*$pythonBinDir*") {
            Write-Info "Adding uv Python to PATH..."
            [System.Environment]::SetEnvironmentVariable("Path", "$pythonBinDir;$userPath", "User")
            $env:Path = "$pythonBinDir;$env:Path"
            Write-Success "uv Python added to PATH"
        }
    }

    # Install debugpy for DAP (Python debugging)
    Write-Info "Installing debugpy for Python debugging..."
    uv tool install debugpy 2>&1 | Out-Null

    # Create dedicated Neovim Python provider venv with pynvim
    Write-Info "Setting up Neovim Python provider (uv-managed)..."
    $nvimVenv = Join-Path $env:LOCALAPPDATA "nvim-python"

    if (-not (Test-Path $nvimVenv)) {
        Write-Info "Creating Neovim Python venv at $nvimVenv..."
        uv venv $nvimVenv --python 3.12 2>&1 | Out-Null
    }

    # Install pynvim into the dedicated venv
    Write-Info "Installing pynvim into Neovim venv..."
    uv pip install pynvim --python "$nvimVenv\Scripts\python.exe" 2>&1 | Out-Null

    if (Test-Path "$nvimVenv\Scripts\python.exe") {
        Write-Success "Neovim Python provider ready at $nvimVenv"
    } else {
        Write-Warn "Failed to create Neovim Python venv"
    }

    # Disable Windows Store python alias (creates confusion)
    Write-Info "Tip: Disable Windows Store Python alias in Settings > Apps > App execution aliases"

    $ErrorActionPreference = "Stop"

    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Install-UvTools {
    Write-Host ""
    Write-Info "Installing Python tools via uv..."

    $ErrorActionPreference = "Continue"
    $tools = @("ty", "ruff")

    # Check for malformed tools and fix them
    $toolListOutput = uv tool list 2>&1 | Out-String
    foreach ($tool in $tools) {
        if ($toolListOutput -match "malformed.*$tool") {
            Write-Warn "Fixing malformed $tool installation..."
            uv tool uninstall $tool 2>&1 | Out-Null
        }
    }

    foreach ($tool in $tools) {
        # Check if properly installed
        $toolList = uv tool list 2>&1 | Out-String
        if ($toolList -match "$tool\s+v") {
            Write-Info "$tool already installed"
            continue
        }
        Write-Info "Installing $tool..."
        $output = uv tool install $tool 2>&1 | Out-String
        if ($output -match "Installed" -or $LASTEXITCODE -eq 0) {
            Write-Success "$tool installed"
        } else {
            Write-Warn "Failed to install $tool"
        }
    }

    $ErrorActionPreference = "Stop"

    # Refresh PATH to include uv tools
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    # Also ensure uv tool bin is in PATH
    $uvBin = Join-Path $env:USERPROFILE ".local\bin"
    if ($env:Path -notlike "*$uvBin*") {
        Write-Info "Adding uv tool bin to PATH..."
        [System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";$uvBin", "User")
        $env:Path = $env:Path + ";$uvBin"
    }
}

function Install-NpmPackages {
    Write-Host ""
    Write-Info "Installing npm packages for Neovim..."

    # Check if npm is available
    if (-not (Test-CommandExists "npm")) {
        Write-Warn "npm not found. Install Node.js first for Neovim npm provider."
        return
    }

    $ErrorActionPreference = "Continue"

    # Install neovim npm package globally
    $installed = npm list -g neovim 2>&1 | Out-String
    if ($installed -match "neovim@") {
        Write-Info "neovim npm package already installed"
    } else {
        Write-Info "Installing neovim npm package..."
        npm install -g neovim 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "neovim npm package installed"
        } else {
            Write-Warn "Failed to install neovim npm package"
        }
    }

    $ErrorActionPreference = "Stop"
}

function Install-PowerShellProfile {
    Write-Host ""
    Write-Info "Setting up PowerShell profile..."

    $profileDir = Split-Path $PROFILE -Parent
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }

    # Source path for notes functions
    $notesProfilePath = Join-Path $DOTFILES_ROOT "dots\.config\powershell\profile.ps1"

    $profileContent = @"
# Dotfiles PowerShell Profile
# Generated by install-windows.ps1

# PSReadLine configuration
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
}

# Aliases
Set-Alias -Name lg -Value lazygit -ErrorAction SilentlyContinue
Set-Alias -Name vim -Value nvim -ErrorAction SilentlyContinue
Set-Alias -Name vi -Value nvim -ErrorAction SilentlyContinue
Set-Alias -Name g -Value git -ErrorAction SilentlyContinue

# lsa - Pretty directory listing with eza or fallback
function lsa {
    if (Get-Command eza -ErrorAction SilentlyContinue) {
        eza -la --icons --group-directories-first @args
    } elseif (Get-Command ls -ErrorAction SilentlyContinue) {
        Get-ChildItem -Force @args | Format-Table Mode, LastWriteTime, Length, Name -AutoSize
    }
}

# ll - Long listing
function ll {
    if (Get-Command eza -ErrorAction SilentlyContinue) {
        eza -l --icons --group-directories-first @args
    } else {
        Get-ChildItem @args | Format-Table Mode, LastWriteTime, Length, Name -AutoSize
    }
}

# la - All files
function la { Get-ChildItem -Force @args }

# Unix-style rm (supports -r, -rf, -f flags)
Remove-Item Alias:rm -ErrorAction SilentlyContinue
function rm {
    param(
        [switch]`$r,
        [switch]`$f,
        [switch]`$rf,
        [Parameter(ValueFromRemainingArguments)]
        [string[]]`$paths
    )
    `$recurse = `$r -or `$rf
    `$force = `$f -or `$rf
    foreach (`$path in `$paths) {
        Remove-Item `$path -Recurse:`$recurse -Force:`$force -ErrorAction `$(if(`$force){'SilentlyContinue'}else{'Stop'})
    }
}

# Quick navigation
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

# Git shortcuts (non-conflicting with notes gd/gw)
function gs { git status @args }
function ga { git add @args }
function gc { git commit @args }
function gp { git push @args }
function gl { git pull @args }
function gco { git checkout @args }
function gb { git branch @args }
function glog { git log --oneline --graph --decorate -20 @args }

# zoxide and starship are initialized by the dotfiles profile sourced below.
# Do NOT init them here: zoxide installs its directory-tracking hook by wrapping
# `prompt`, and starship replaces `prompt` outright, so starship must run first.
# Initializing zoxide twice is also a no-op (it guards on $__zoxide_hooked), which
# would leave the hook permanently clobbered and the database empty.

# Source notes functions (gd, gw, gn) from dotfiles
`$notesProfile = "$notesProfilePath"
if (Test-Path `$notesProfile) {
    . `$notesProfile
}
"@

    # Check if profile exists and has content
    if (Test-Path $PROFILE) {
        $existing = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
        if ($existing -and $existing.Trim().Length -gt 0) {
            if ($existing -match "Dotfiles PowerShell Profile") {
                Write-Host ""
                Write-Host "  Existing dotfiles profile found." -ForegroundColor Yellow
                Write-Host "  [1] Overwrite with latest version" -ForegroundColor Cyan
                Write-Host "  [2] Keep existing profile" -ForegroundColor Cyan
                Write-Host ""
                $choice = Read-Host "Select option (1-2)"

                if ($choice -eq "1") {
                    Set-Content -Path $PROFILE -Value $profileContent
                    Write-Success "PowerShell profile updated at $PROFILE"
                } else {
                    Write-Info "Keeping existing profile"
                }
                return
            } else {
                Write-Host ""
                Write-Host "  Existing PowerShell profile found with custom content." -ForegroundColor Yellow
                Write-Host "  [1] Overwrite (backup will be created)" -ForegroundColor Cyan
                Write-Host "  [2] Append dotfiles config to existing" -ForegroundColor Cyan
                Write-Host "  [3] Skip profile setup" -ForegroundColor Cyan
                Write-Host ""
                $choice = Read-Host "Select option (1-3)"

                switch ($choice) {
                    "1" {
                        $backupPath = "$PROFILE.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                        Copy-Item $PROFILE $backupPath
                        Write-Info "Backup created at $backupPath"
                        Set-Content -Path $PROFILE -Value $profileContent
                        Write-Success "PowerShell profile replaced at $PROFILE"
                    }
                    "2" {
                        Add-Content -Path $PROFILE -Value "`n`n$profileContent"
                        Write-Success "Dotfiles config appended to $PROFILE"
                    }
                    default {
                        Write-Info "Skipping profile setup"
                    }
                }
                return
            }
        }
    }

    # No existing profile, create new
    Set-Content -Path $PROFILE -Value $profileContent
    Write-Success "PowerShell profile created at $PROFILE"
}

function Install-WindowsTerminalConfig {
    Write-Host ""
    Write-Info "Configuring Windows Terminal..."

    # Find Windows Terminal settings
    $terminalSettingsPath = Get-ChildItem "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json" -ErrorAction SilentlyContinue | Select-Object -First 1

    if (-not $terminalSettingsPath) {
        Write-Warn "Windows Terminal settings not found. Install Windows Terminal from Microsoft Store."
        return
    }

    try {
        $settings = Get-Content $terminalSettingsPath.FullName -Raw | ConvertFrom-Json

        $modified = $false

        # Set PowerShell 7 as default (GUID for PowershellCore)
        $pwsh7Guid = "{574e775e-4f2a-5b96-ac1e-a2962a402336}"
        if ($settings.defaultProfile -ne $pwsh7Guid) {
            $settings.defaultProfile = $pwsh7Guid
            $modified = $true
            Write-Info "Set PowerShell 7 as default profile"
        }

        # Open a single new window on launch. "persistedWindowLayout" restores every
        # window from the previous session, which reopens a pile of terminals at startup.
        if ($settings.PSObject.Properties.Name -contains "firstWindowPreference") {
            if ($settings.firstWindowPreference -ne "defaultProfile") {
                $settings.firstWindowPreference = "defaultProfile"
                $modified = $true
                Write-Info "Disabled persisted window layout (was reopening multiple windows)"
            }
        } else {
            $settings | Add-Member -NotePropertyName "firstWindowPreference" -NotePropertyValue "defaultProfile" -Force
            $modified = $true
        }

        # Set default font to Nerd Font
        if (-not $settings.profiles.defaults.font) {
            $settings.profiles.defaults | Add-Member -NotePropertyName "font" -NotePropertyValue @{ face = "JetBrainsMono Nerd Font" } -Force
            $modified = $true
        } elseif ($settings.profiles.defaults.font.face -ne "JetBrainsMono Nerd Font") {
            $settings.profiles.defaults.font.face = "JetBrainsMono Nerd Font"
            $modified = $true
            Write-Info "Set default font to JetBrainsMono Nerd Font"
        }

        # Hide legacy Windows PowerShell
        foreach ($profile in $settings.profiles.list) {
            if ($profile.guid -eq "{61c54bbd-c2c6-5271-96e7-009a87ff44bf}" -and -not $profile.hidden) {
                $profile.hidden = $true
                $profile.name = "Windows PowerShell (Legacy)"
                $modified = $true
                Write-Info "Hidden legacy Windows PowerShell 5.1"
            }
        }

        if ($modified) {
            $settings | ConvertTo-Json -Depth 10 | Set-Content $terminalSettingsPath.FullName -Encoding UTF8
            Write-Success "Windows Terminal configured"
        } else {
            Write-Info "Windows Terminal already configured"
        }
    } catch {
        Write-Warn "Failed to configure Windows Terminal: $_"
    }
}

function Show-Summary {
    Write-Host ""
    Write-Host "Installation Complete" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Python (via uv):" -ForegroundColor Gray
    Write-Host "    Python 3.12 (managed by uv, not system)" -ForegroundColor White
    Write-Host "    %LOCALAPPDATA%\nvim-python (dedicated Neovim provider venv)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Python tools (via uv):" -ForegroundColor Gray
    Write-Host "    ty, ruff, debugpy" -ForegroundColor White
    Write-Host ""
    Write-Host "  Node.js packages:" -ForegroundColor Gray
    Write-Host "    neovim (Neovim Node provider)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Configs linked to:" -ForegroundColor Gray
    Write-Host "    %LOCALAPPDATA%\nvim   ~/.vimrc   ~/.ideavimrc" -ForegroundColor White
    Write-Host "    ~/.bashrc   ~/.aliases   ~/.config/lazygit" -ForegroundColor White
    Write-Host ""
    Write-Host "  PowerShell aliases:" -ForegroundColor Gray
    Write-Host "    lg=lazygit  lsa=eza  vim=nvim  gs/ga/gc/gp=git" -ForegroundColor White
    Write-Host ""
    Write-Host "  Windows Terminal:" -ForegroundColor Gray
    Write-Host "    Default: PowerShell 7 (pwsh.exe)" -ForegroundColor White
    Write-Host "    Font: JetBrainsMono Nerd Font" -ForegroundColor White
    Write-Host "    Legacy PowerShell 5.1: Hidden" -ForegroundColor White
    Write-Host ""
    Write-Host "  NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "    1. CLOSE and REOPEN your terminal (required for PATH)" -ForegroundColor White
    Write-Host "    2. Open nvim and run :Lazy sync to install plugins" -ForegroundColor White
    Write-Host "    3. Run :checkhealth to verify setup" -ForegroundColor White
    Write-Host ""
}

function Main {
    Show-Banner

    # Check symlink capability
    $canSymlink = Test-SymlinkCapability
    if (-not $canSymlink) {
        $continue = Request-AdminOrDevMode
        if (-not $continue) {
            Write-Info "Exiting. Re-run as Administrator or enable Developer Mode."
            exit 0
        }
    }

    # Step 1: Install uv
    Install-Uv

    # Step 1.5: Install PowerShell 7 (required by $PROFILE setup and Windows Terminal config below)
    Install-PowerShell7

    # Step 2: Install dotbot
    Install-Dotbot

    # Step 3: Symlink configs
    if ($canSymlink) {
        Install-Configs
    } else {
        Write-Warn "Skipping symlinks (no permission). Configs must be linked manually or re-run as Admin."
    }

    # Step 4: Install core dependencies (Python, Node, pwsh, 7z, make)
    Install-CoreDependencies

    # Step 5: Select and install apps
    $selectedApps = Show-AppSelection
    Install-Apps -AppKeys $selectedApps

    # Step 6: Install uv tools (ty, ruff)
    Install-UvTools

    # Step 7: Install npm packages (neovim provider)
    Install-NpmPackages

    # Step 8: Set up PowerShell profile
    Install-PowerShellProfile

    # Step 9: Configure Windows Terminal
    Install-WindowsTerminalConfig

    # Done
    Show-Summary
}

Main
