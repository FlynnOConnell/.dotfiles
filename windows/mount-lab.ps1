# Mounts the lab-research server at X: over SSHFS, with no visible console window.
#
# Launched at logon by the Startup-folder shortcut "Mount lab-research (X).lnk",
# which runs mount-lab.vbs -- that wrapper is what keeps the sshfs.exe console
# hidden. Can also be run by hand. Delete the shortcut to stop auto-mounting.
#
# Note: net use \sshfs.kr\... is the tidier route, but the WinFsp launcher on
# this machine is an SxS instance that does not see the SSHFS-Win service
# registrations, so it fails with system error 67. Driving sshfs.exe directly
# sidesteps the launcher entirely.

$ErrorActionPreference = 'Stop'

$drive  = 'X'
$sshfs  = 'C:\Program Files\SSHFS-Win\bin\sshfs.exe'
$remote = 'flynn@server.memorylongevity.org:/'
$key    = '/cygdrive/c/Users/loson/.ssh/id_ed25519'

if (Test-Path "${drive}:\") { exit 0 }
if (-not (Test-Path $sshfs)) { exit 1 }

# sshfs shells out to plain `ssh`; it must resolve to SSHFS-Win's bundled Cygwin
# build, not C:\Windows\System32\OpenSSH\ssh.exe, which cannot read the
# /cygdrive-style IdentityFile path and fails with "no such identity".
$env:Path = (Split-Path $sshfs) + ';' + $env:Path

$sshfsArgs = @(
    $remote, "${drive}:"
    '-p', '2216'
    '-o', "IdentityFile=$key"
    '-o', 'idmap=user', '-o', 'uid=-1', '-o', 'gid=-1'
    '-o', 'reconnect', '-o', 'ServerAliveInterval=15', '-o', 'ServerAliveCountMax=3'
    '-o', 'StrictHostKeyChecking=no'
    '-o', 'volname=lab-research', '-o', 'cache_timeout=115'
)

Start-Process -FilePath $sshfs -ArgumentList $sshfsArgs -WindowStyle Hidden
