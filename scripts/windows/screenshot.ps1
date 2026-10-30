# Saves a screenshot from the sign to screenshots\ in the repo.
. "$PSScriptRoot\common.ps1"

$dir = Join-Path $RepoRoot 'screenshots'
New-Item -ItemType Directory -Force $dir | Out-Null
$file = Join-Path $dir "$(Get-Date -Format 'yyyy-MM-dd_HHmmss').png"

Invoke-Shell 'screencap -p /sdcard/_shot.png' | Out-Null
Invoke-Adb pull /sdcard/_shot.png $file | Out-Null
Invoke-Shell 'rm /sdcard/_shot.png' | Out-Null
Write-Host $file
