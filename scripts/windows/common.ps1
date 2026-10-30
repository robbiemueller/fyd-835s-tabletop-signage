# Shared helpers for the Windows scripts: finds adb and remembers which sign we're talking to.
# Dot-source it:  . "$PSScriptRoot\common.ps1"

$SerialFile = Join-Path $PSScriptRoot '.serial'
$RepoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))

function Find-Adb {
    $cmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    # winget's scrcpy package ships its own adb but doesn't put it on PATH
    $pkg = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Directory -Filter 'Genymobile.scrcpy*' -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($pkg) {
        $exe = Get-ChildItem $pkg.FullName -Recurse -Filter adb.exe | Select-Object -First 1
        if ($exe) { return $exe.FullName }
    }
    throw 'adb not found. Install it with: winget install Genymobile.scrcpy (or Google.PlatformTools)'
}

$Adb = Find-Adb

function Get-Serial {
    if (Test-Path $SerialFile) { return (Get-Content $SerialFile -Raw).Trim() }
    throw 'No sign remembered yet. Run connect.ps1 first.'
}

# Runs adb against the remembered sign.
function Invoke-Adb {
    & $Adb -s (Get-Serial) @args
}

# Runs a shell command on the sign and returns its output lines. Android 6's adb shell ends lines with \r,
# so that gets stripped. Avoid double quotes in $Command; use single quotes instead.
function Invoke-Shell([string]$Command) {
    & $Adb -s (Get-Serial) shell $Command | ForEach-Object { $_.TrimEnd("`r") }
}
