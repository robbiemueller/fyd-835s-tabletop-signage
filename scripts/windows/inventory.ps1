# Read-only snapshot of the sign: build info, every package, what runs at boot, what's listening on the
# network, and copies of the non-AOSP APKs for inspection. Output goes to inventory\<timestamp>\ in the repo
# (ignored by git: it contains your unit's serial and MAC address).
param([switch]$SkipApks)
. "$PSScriptRoot\common.ps1"

$out = Join-Path $RepoRoot "inventory\$(Get-Date -Format 'yyyy-MM-dd_HHmm')"
New-Item -ItemType Directory -Force $out | Out-Null

function Save([string]$Name, [string]$Command) {
    Write-Host "  $Name"
    Invoke-Shell "{ $Command; } 2>&1" | Out-File -Encoding utf8 (Join-Path $out $Name)
}

Write-Host "Writing to $out"
Save 'props.txt'             'getprop'
Save 'root.txt'              'id; getenforce; ls -l /system/bin/su /system/xbin/su /sbin/su; getprop ro.debuggable; getprop ro.adb.secure'
Save 'hardware.txt'          'cat /proc/cpuinfo /proc/meminfo; df'
Save 'display.txt'           'wm size; wm density; dumpsys display'
Save 'packages.txt'          'pm list packages -f -i -u'
Save 'packages-system.txt'   'pm list packages -s'
Save 'packages-3rd.txt'      'pm list packages -3'
Save 'packages-disabled.txt' 'pm list packages -d'
Save 'dumpsys-package.txt'   'dumpsys package'
Save 'activities.txt'        'dumpsys activity activities'
Save 'services.txt'          'dumpsys activity services'
Save 'windows.txt'           'dumpsys window windows'
Save 'processes.txt'         'ps'
# Android 8+ ps only lists the shell's own processes unless given -A
if ((Get-Content (Join-Path $out 'processes.txt')).Count -lt 10) { Save 'processes.txt' 'ps -A' }
Save 'network.txt'           'netstat -an; cat /proc/net/tcp /proc/net/tcp6 /proc/net/udp; getprop net.dns1; cat /system/etc/hosts'
Save 'settings.txt'          'for ns in global secure system; do echo == $ns; settings list $ns || content query --uri content://settings/$ns; done'
# install-recovery.sh and init.d are the classic places for persistent junk on cheap Android builds
Save 'persistence.txt'       'ls -la /system/etc/init.d /system/etc/install-recovery.sh /system/bin/install-recovery.sh; cat /system/bin/install-recovery.sh; ls -la /data/local/tmp'
Save 'logcat.txt'            'logcat -d -v time'

Write-Host '  screen.png'
Invoke-Shell 'screencap -p /sdcard/_inv.png' | Out-Null
Invoke-Adb pull /sdcard/_inv.png (Join-Path $out 'screen.png') | Out-Null
Invoke-Shell 'rm /sdcard/_inv.png' | Out-Null

if (-not $SkipApks) {
    $apkDir = Join-Path $out 'apks'
    New-Item -ItemType Directory -Force $apkDir | Out-Null
    $vendor = Invoke-Shell 'pm list packages -f' | ForEach-Object {
        if ($_ -match '^package:(.+)=([^=\s]+)$') { [pscustomobject]@{ Path = $Matches[1]; Package = $Matches[2] } }
    } | Where-Object { $_.Package -notmatch '^(android$|com\.android\.|com\.google\.android\.)' }
    foreach ($p in $vendor) {
        Write-Host "  apks\$($p.Package).apk"
        Invoke-Adb pull $p.Path (Join-Path $apkDir "$($p.Package).apk") | Out-Null
    }
}

$props = Get-Content (Join-Path $out 'props.txt')
function Prop($key) {
    $m = $props | Select-String "^\[$([regex]::Escape($key))\]: \[(.*)\]$" | Select-Object -First 1
    if ($m) { $m.Matches[0].Groups[1].Value }
}
Write-Host ''
Write-Host "Model:    $(Prop 'ro.product.manufacturer') $(Prop 'ro.product.model')"
Write-Host "Android:  $(Prop 'ro.build.version.release') (SDK $(Prop 'ro.build.version.sdk'))"
Write-Host "Build:    $(Prop 'ro.build.display.id')"
Write-Host "Focused:  $("$((Select-String 'mCurrentFocus' (Join-Path $out 'windows.txt') | Select-Object -First 1).Line)".Trim())"
