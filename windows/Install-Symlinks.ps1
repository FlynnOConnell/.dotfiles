$sourceDir = Resolve-Path "$PSScriptRoot\.."
$symlinkName = "$Env:USERPROFILE\.dotfiles"

if (Test-Path $symlinkName) {
    # Remove the existing directory or symlink
    Remove-Item $symlinkName -Force
    Write-Output "Existing symbolic link found. Overwriting..."
} else {
    Write-Output "No existing symbolic link found. Creating a new one..."
}

# Create a symbolic link at the target path that points to the source directory
New-Item -Path $symlinkName -ItemType SymbolicLink -Value $sourceDir | Out-Null

# NVIM to Appdata
$sourceDir = "$HOME/.config/nvim"
$targetDir = "$env:LOCALAPPDATA/nvim"

# Create a symbolic link
New-Item -Path $targetDir -ItemType SymbolicLink -Target $sourceDir


Write-Output "Symbolic links successfully completed."

