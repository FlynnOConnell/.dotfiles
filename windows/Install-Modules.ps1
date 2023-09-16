# Array of module names in the order they should be installed
$moduleOrder = @('Message', 'ElevateScript', 'RegistryEntry', 'FileCommands', 'TestCommandExists', 'UserPreferencesMask', 'ConfigMap')

foreach ($moduleName in $moduleOrder) {
    $sourceDir = "$Env:DOTS_PSMODULES_DIR\$moduleName"
    $targetDir = "$Env:Programfiles\powershell\7-preview\Modules\$moduleName"

    if (Test-Path -Path $targetDir) {
        Write-Output "Module $moduleName already installed. Skipping..."
    } else {
        Copy-Item -Path $sourceDir -Destination $targetDir -Recurse
        Write-Output "Installing module $moduleName..."

        # After copying the module, import it
        Import-Module -Name $targetDir -Force
    }
}

