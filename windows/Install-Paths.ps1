$directoriesToAdd = @(
    "/mingw64/bin",
    "$Env:USERPROFILE\.local\share\nvim\site\pack\packer\start"
)

$existingPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$newPath = $existingPath -split ";" | Select-Object -Unique
$addedDirectories = @()

foreach ($directory in $directoriesToAdd) {
    if ($newPath -notcontains $directory) {
        $newPath += $directory
        $addedDirectories += $directory
    }
}

if ($addedDirectories.Count -gt 0) {
    # Update the PATH variable
    [Environment]::SetEnvironmentVariable("Path", ($newPath -join ";"), "Machine")
    Write-Output "The following directories have been added to the PATH:"
    $addedDirectories | ForEach-Object { Write-Output "- $_" }
} else {
    Write-Output "No new directories to add to the PATH."
}
