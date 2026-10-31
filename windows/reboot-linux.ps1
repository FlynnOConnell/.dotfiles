# Reboots into Linux once, without the firmware boot menu: points the firmware's
# one-time boot entry (BootNext) at the "Omarchy" UEFI entry, then restarts. The
# boot after that follows the normal boot order again. The Linux side is
# omarchy/.local/bin/reboot-windows.
#
# Writing firmware boot variables needs admin, so this relaunches itself
# elevated (one UAC prompt). bcdedit's field names are localized; this matches
# the English "identifier" and "description".

$ErrorActionPreference = 'Stop'

$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`""
    exit
}

# bcdedit lists one block per firmware entry, identifier line before description.
$linuxId = $null
foreach ($line in bcdedit /enum firmware) {
    if ($line -match '^identifier\s+(\{\S+\})') { $blockId = $Matches[1] }
    if ($line -match '^description\s+Omarchy\s*$') { $linuxId = $blockId; break }
}
if (-not $linuxId) { throw 'no "Omarchy" entry in bcdedit /enum firmware' }

bcdedit /set '{fwbootmgr}' bootsequence $linuxId | Out-Null
if ($LASTEXITCODE) { throw "bcdedit /set bootsequence $linuxId failed ($LASTEXITCODE)" }

shutdown.exe /r /t 0
