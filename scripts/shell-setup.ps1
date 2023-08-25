<# A script to setup powershell, pwsh, git, winget chocolatey and scoop. #>

$VerbosePreference = "Continue"

function Install-ScoopApp {
    param (
        [string]$Package
    )
    Write-Verbose -Message "Preparing to install $Package"
    if (! (scoop info $Package).Installed ) {
        Write-Verbose -Message "Installing $Package"
        scoop install $Package
    } else {
        Write-Verbose -Message "Package $Package already installed! Skipping..."
    }
}

function Install-WinGetApp {
    param (
        [string]$PackageID
    )
    Write-Verbose -Message "Preparing to install $PackageID"
    # Added accept options based on this issue - https://github.com/microsoft/winget-cli/issues/1559
    #$listApp = winget list --exact -q $PackageID --accept-source-agreements
    #if (winget list --exact --id "$PackageID" --accept-source-agreements) {
    #    Write-Verbose -Message "Package $PackageID already installed! Skipping..."
    #} else {
    #    Write-Verbose -Message "Installing $Package"
    #    winget install --silent --id "$PackageID" --accept-source-agreements --accept-package-agreements
    #}
    Write-Verbose -Message "Installing $Package"
    winget install --silent --id "$PackageID" --accept-source-agreements --accept-package-agreements
}

function Install-ChocoApp {
    param (
        [string]$Package
    )
    Write-Verbose -Message "Preparing to install $Package"
    $listApp = choco list --local $Package
    if ($listApp -like "0 packages installed.") {
        Write-Verbose -Message "Installing $Package"
        Start-Process -FilePath "PowerShell" -ArgumentList "choco","install","$Package","-y" -Verb RunAs -Wait
    } else {
        Write-Verbose -Message "Package $Package already installed! Skipping..."
    }
}

function Extract-Download {
    param (
        [string]$Folder,
        [string]$File
    )
    if (!(Test-Path -Path "$Folder" -PathType Container)) {
        Write-Error "$Folder does not exist!!!"
        Break
    }
    if (Test-Path -Path "$File" -PathType Leaf) {
        switch ($File.Split(".") | Select-Object -Last 1) {
            "rar" { Start-Process -FilePath "UnRar.exe" -ArgumentList "x","-op'$Folder'","-y","$File" -WorkingDirectory "$Env:ProgramFiles\WinRAR\" -Wait | Out-Null }
            "zip" { 7z x -o"$Folder" -y "$File" | Out-Null }
            "7z" { 7z x -o"$Folder" -y "$File" | Out-Null }
            "exe" { 7z x -o"$Folder" -y "$File" | Out-Null }
            Default { Write-Error "No way to Extract $File !!!"; Break }
        }
    }
}

function Download-CustomApp {
    param (
        [string]$Link,
        [string]$Folder
    )
    if ((curl -sIL "$Link" | Select-String -Pattern "Content-Disposition") -ne $Null) {
        $Package = $(curl -sIL "$Link" | Select-String -Pattern "filename=" | Split-String -Separator "=" | Select-Object -Last 1).Trim('"')
    } else {
        $Package = $Link.split("/") | Select-Object -Last 1
    }
    Write-Verbose -Message "Preparing to download $Package"
    aria2c --quiet --dir="$Folder" "$Link"
    Return $Package
}

function Install-CustomApp {
    param (
        [string]$URL,
        [string]$Folder
    )
    $Package = Download-CustomApp -Link $URL -Folder "$Env:UserProfile\Downloads\"
    if (Test-Path -Path "$Env:UserProfile\Downloads\$Package" -PathType Leaf) {
        if (Test-Path Variable:Folder) {
            if (!(Test-Path -Path "$Env:UserProfile\bin\$Folder")) {
                New-Item -Path "$Env:UserProfile\bin\$Folder" -ItemType Directory | Out-Null
            }
            Extract-Download -Folder "$Env:UserProfile\bin\$Folder" -File "$Env:UserProfile\Downloads\$Package"
        } else {
            Extract-Download -Folder "$Env:UserProfile\bin\" -File "$Env:UserProfile\Downloads\$Package"
        }
        Remove-Item -Path "$Env:UserProfile\Downloads\$Package"
    }
}

function Install-CustomPackage {
    param (
        [string]$URL
    )
    $Package = Download-CustomApp -Link $URL
    if (Test-Path -Path "$Env:UserProfile\Downloads\$Package" -PathType Leaf) {
        Start-Process -FilePath ".\$Package" -ArgumentList "/S" -WorkingDirectory "${Env:UserProfile}\Downloads\" -Verb RunAs -Wait #-WindowStyle Hidden
        Remove-Item -Path "$Env:UserProfile\Downloads\$Package"
    }
}

function Remove-InstalledApp {
    param (
        [string]$Package
    )
    Write-Verbose -Message "Uninstalling: $Package"
    Start-Process -FilePath "PowerShell" -ArgumentList "Get-AppxPackage","-AllUsers","-Name","'$Package'" -Verb RunAs -WindowStyle Hidden
}

function Enable-Bucket {
    param (
        [string]$Bucket
    )
    if (!($(scoop bucket list).Name -eq "$Bucket")) {
        Write-Verbose -Message "Adding Bucket $Bucket to scoop..."
        scoop bucket add $Bucket
    } else {
        Write-Verbose -Message "Bucket $Bucket already added! Skipping..."
    }
}

# Configure ExecutionPolicy to Unrestricted for CurrentUser Scope
if ((Get-ExecutionPolicy -Scope CurrentUser) -notcontains "Unrestricted") {
    Write-Verbose -Message "Setting Execution Policy for Current User..."
    Start-Process -FilePath "PowerShell" -ArgumentList "Set-ExecutionPolicy","-Scope","CurrentUser","-ExecutionPolicy","Unrestricted","-Force" -Verb RunAs -Wait
    Write-Output "Restart/Re-Run script!!!"
    Start-Sleep -Seconds 10
    Break
}

# Install Scoop, if not already installed
#$scoopInstalled = Get-Command "scoop"
if ( !(Get-Command -Name "scoop" -CommandType Application -ErrorAction SilentlyContinue | Out-Null) ) {
    Write-Verbose -Message "Installing Scoop..."
    iex ((New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh'))
}

# Install Chocolatey, if not already installed
#$chocoInstalled = Get-Command -Name "choco" -CommandType Application -ErrorAction SilentlyContinue | Out-Null
if (! (Get-Command -Name "choco" -CommandType Application -ErrorAction SilentlyContinue | Out-Null) ) {
    Write-Verbose -Message "Installing Chocolatey..."
@'
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
'@ > $Env:Temp\choco.ps1
    Start-Process -FilePath "PowerShell" -ArgumentList "$Env:Temp\choco.ps1" -Verb RunAs -Wait
    Remove-Item -Path $Env:Temp\choco.ps1 -Force
}

# Install WinGet, if not already installed
# From crutkas's gist - https://gist.github.com/crutkas/6c2096eae387e544bd05cde246f23901
#$hasPackageManager = Get-AppPackage -name "Microsoft.DesktopAppInstaller"
if (!(Get-AppPackage -name "Microsoft.DesktopAppInstaller")) {
    Write-Verbose -Message "Installing WinGet..."
@'
# Set URL and Enable TLSv12
$releases_url = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Dont Think We Need This!!!
#Install-PackageProvider -Name NuGet
# Install Nuget as Package Source Provider
Register-PackageSource -Name Nuget -Location "http://www.nuget.org/api/v2" -ProviderName Nuget -Trusted
# Install Microsoft.UI.Xaml (This is not currently working!!!)
Install-Package Microsoft.UI.Xaml -RequiredVersion 2.7.1
# Grab "Latest" release
$releases = Invoke-RestMethod -uri $releases_url
$latestRelease = $releases.assets | Where { $_.browser_download_url.EndsWith('msixbundle') } | Select -First 1
# Install Microsoft.DesktopAppInstaller Package
Add-AppxPackage -Path $latestRelease.browser_download_url
'@ > $Env:Temp\winget.ps1
    Start-Process -FilePath "PowerShell" -ArgumentList "$Env:Temp\winget.ps1" -Verb RunAs -Wait
    Remove-Item -Path $Env:Temp\winget.ps1 -Force
}

# Only install OpenSSH Package, if not on Windows 10
if ([Environment]::OSVersion.Version.Major -lt 10) {
    Install-ScoopApp -Package "openssh"
}

# Install OpenSSH.Client on Windows 10+
@'
if ((Get-WindowsCapability -Online -Name OpenSSH.Client*).State -ne "Installed") {
    Add-WindowsCapability -Online -Name OpenSSH.Client*
}
'@ > "${Env:Temp}\openssh.ps1"
Start-Process -FilePath "PowerShell" -ArgumentList "${Env:Temp}\openssh.ps1" -Verb RunAs -Wait -WindowStyle Hidden
Remove-Item -Path "${Env:Temp}\openssh.ps1" -Force

# Configure git
Install-WinGetApp -PackageID "Git.Git"
Start-Sleep -Seconds 5
refreshenv
Start-Sleep -Seconds 5
if (!$(git config --global credential.helper) -eq "manager-core") {
    git config --global credential.helper manager-core
}
if (!($Env:GIT_SSH)) {
    Write-Verbose -Message "Setting GIT_SSH User Environment Variable"
    [System.Environment]::SetEnvironmentVariable('GIT_SSH', (Resolve-Path (scoop which ssh)), 'USER')
}
if ((Get-Service -Name ssh-agent).Status -ne "Running") {
    Start-Process -FilePath "PowerShell" -ArgumentList "Set-Service","ssh-agent","-StartupType","Manual" -Verb RunAs -Wait -WindowStyle Hidden
}

# Configure Aria2 Download Manager
Install-ScoopApp -Package "aria2"
if (!$(scoop config aria2-enabled) -eq $True) {
    scoop config aria2-enabled true
}
if (!$(scoop config aria2-warning-enabled) -eq $False) {
    scoop config aria2-warning-enabled false
}
if (!(Get-ScheduledTaskInfo -TaskName "Aria2RPC" -ErrorAction Ignore)) {
@'
$Action = New-ScheduledTaskAction -Execute $Env:UserProfile\scoop\apps\aria2\current\aria2c.exe -Argument "--enable-rpc --rpc-listen-all" -WorkingDirectory $Env:UserProfile\Downloads
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Principal = New-ScheduledTaskPrincipal -UserID "$Env:ComputerName\$Env:Username" -LogonType S4U
$Settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName "Aria2RPC" -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings
'@ > $Env:Temp\aria2.ps1
    Start-Process -FilePath "PowerShell" -ArgumentList "$Env:Temp\aria2.ps1" -Verb RunAs -Wait #-WindowStyle Hidden
    Remove-Item -Path $Env:Temp\aria2.ps1 -Force
}

## Add Buckets
Enable-Bucket -Bucket "extras"
Enable-Bucket -Bucket "java"
Enable-Bucket -Bucket "nirsoft"
scoop bucket add foosel https://github.com/foosel/scoop-bucket

# UNIX Tools
Write-Verbose -Message "Removing curl Alias..."
if (Get-Alias -Name curl -ErrorAction SilentlyContinue) {
    Remove-Item alias:curl
}

if (!($Env:TERM)) {
    Write-Verbose -Message "Setting TERM User Environment Variable"
    [System.Environment]::SetEnvironmentVariable("TERM", "xterm-256color", "USER")
}

if ($(Read-Host -Prompt "Is this a workstation for Home use (y/n)?") -eq "y") {
    $HomeWorkstation = $True
} else {
    $HomeWorkstation = $False
}

# Home Workstation Configurations
if ($HomeWorkstation) {
    # Adding games bucket
    Enable-Bucket -Bucket "games"
    # Create $Env:UserProfile\bin, if not exist
    if (!(Test-Path -Path $Env:UserProfile\bin)) {
        Write-Verbose -Message "Creating bin directory in $Env:UserProfile"
        New-Item -Path $Env:UserProfile\bin -ItemType Directory | Out-Null
    }
}

# Install Scoop Packages
$Scoop = @(
    "scoop-tray",
    "concfg",
    "curl",
    "fzf",
    "neovim",
    "sudo",
    "python",
    "sysinternals")#,"rktools2k3")
foreach ($item in $Scoop) {
    Install-ScoopApp -Package "$item"
}

# Install Scoop Packages, if Home Workstation
if ($HomeWorkstation) {
    Remove-Variable -Name "Scoop"
    $Scoop = @(
        "ffmpeg",
)
    foreach ($item in $Scoop) {
        Install-ScoopApp -Package "$item"
    }
}

# Install WinGet Packages
$WinGet = @(
    "Microsoft.DotNet.DesktopRuntime.3_1",
    "Microsoft.DotNet.DesktopRuntime.5",
    "Microsoft.DotNet.DesktopRuntime.6",
    "Microsoft.DotNet.DesktopRuntime.7",
    "Microsoft.WindowsTerminal",
    "Microsoft.PowerToys",
    "Obsidian.Obsidian",
    "GoLang.Go.1.19",
    "CPUID.HWMonitor",
    "Google.Chrome",
    "RARLab.WinRAR",
    )
foreach ($item in $WinGet) {
    Install-WinGetApp -PackageID "$item"
}

# Install WinGet Packages, if Home Workstation
if ($HomeWorkstation) {
    Remove-Variable -Name "WinGet"
    $WinGet = @(
        "Discord.Discord",
        "Plex.Plex",
        "CPUID.CPU-Z",
        "TechPowerUp.GPU-Z",
        "Valve.Steam"
    )
    foreach ($item in $WinGet) {
        Install-WinGetApp -PackageID "$item"
    }
}

# Custom WinGet install for VSCode
winget install Microsoft.VisualStudioCode --override '/SILENT /mergetasks="!runcode,addcontextmenufiles,addcontextmenufolders"'


# Create scoop-tray shortcut in shell:startup
if (!(Test-Path -Path "$Env:AppData\Microsoft\Windows\Start Menu\Programs\Startup\scoop-tray.lnk" -PathType Leaf)) {
    Write-Verbose -Message "Create scoop-tray shortcut in shell:startup..."
    $WSHShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WSHShell.CreateShortcut("$Env:AppData\Microsoft\Windows\Start Menu\Programs\Startup\scoop-tray.lnk")
    $Shortcut.TargetPath = "$Env:UserProfile\scoop\apps\scoop-tray\current\scoop-tray.bat"
    $Shortcut.WindowStyle = 7
    $Shortcut.IconLocation = "%USERPROFILE%\scoop\apps\scoop-tray\current\updates-available.ico"
    $Shortcut.Description = "scoop-tray.bat"
    $Shortcut.WorkingDirectory = Split-Path "$Env:UserProfile\scoop\apps\scoop-tray\current\scoop-tray.bat" -Resolve
    $Shortcut.Save()
}

# Configure GO Environment
if (!(Test-Path -Path "$Env:UserProfile\go\" -PathType Container)) {
    Write-Verbose -Message "Configuring GO Environment..."
    New-Item -Path "${Env:UserProfile}\go" -ItemType Directory | Out-Null
    [System.Environment]::SetEnvironmentVariable('GOPATH', "${Env:UserProfile}\go", 'USER')
}

# Install PowerShell 7
$PS7 = winget list --exact -q Microsoft.PowerShell
if (!$PS7) {
    Write-Verbose -Message "Installing PowerShell 7..."
@'
iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI -Quiet"
'@ > $Env:Temp\ps7.ps1
    Start-Process -FilePath "PowerShell" -ArgumentList "$Env:Temp\ps7.ps1" -Verb RunAs -Wait -WindowStyle Hidden
    Remove-Item -Path $Env:Temp\ps7.ps1 -Force
}
# Pin PowerShell 7 to Taskbar
Write-Verbose -Message "Pin PowerShell 7 to Taskbar..."
Start-Process -FilePath "PowerShell" -ArgumentList "syspin","'$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\PowerShell\PowerShell 7 (x64).lnk'","c:5386" -Wait -NoNewWindow

# Remove unused Packages/Applications
Write-Verbose -Message "Removing Unused Applications..."
$RemoveApps = @(
    "*3DPrint*",
    "Microsoft.MixedReality.Portal")
foreach ($item in $RemoveApps) {
    Remove-InstalledApp -Package $item
}

# Install Windows SubSystems for Linux
$wslInstalled = Get-Command "wsl" -CommandType Application -ErrorAction Ignore
if (!$wslInstalled) {
    Write-Verbose -Message "Installing Windows SubSystems for Linux..."
    Start-Process -FilePath "PowerShell" -ArgumentList "wsl","--install" -Verb RunAs -Wait -WindowStyle Hidden
}
Install-WinGetApp -PackageID Canonical.Ubuntu.2004
Write-Output "Install complete! Please reboot your machine/worksation!"
Start-Sleep -Seconds 10
