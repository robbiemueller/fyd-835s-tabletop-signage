# Connects to the sign over ADB and remembers it for the other scripts.
#   .\connect.ps1 192.168.1.50    connect to a known IP
#   .\connect.ps1                 scan the local /24 network for anything with ADB (port 5555) open
param([string]$Ip, [int]$Port = 5555)
. "$PSScriptRoot\common.ps1"

if (-not $Ip) {
    $nets = Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq 'Up' } |
        ForEach-Object { (($_.IPv4Address | Select-Object -First 1).IPAddress -split '\.')[0..2] -join '.' } |
        Sort-Object -Unique
    Write-Host "Scanning $(($nets | ForEach-Object { "$_.0/24" }) -join ', ') for port $Port..."
    $probes = foreach ($net in $nets) {
        foreach ($h in 1..254) {
            $client = [System.Net.Sockets.TcpClient]::new()
            [pscustomobject]@{ Ip = "$net.$h"; Client = $client; Task = $client.ConnectAsync("$net.$h", $Port) }
        }
    }
    Start-Sleep -Milliseconds 2500
    $found = @($probes | Where-Object { $_.Task.Status -eq 'RanToCompletion' } | ForEach-Object Ip)
    $probes | ForEach-Object { $_.Client.Dispose() }

    if ($found.Count -eq 0) {
        throw "Nothing on the network answers on port $Port. Turn on network ADB first (docs/cleanup-guide.md, step 5)."
    }
    if ($found.Count -gt 1) {
        # Fire TVs and some smart TVs also listen on 5555, so don't guess
        Write-Host 'More than one device answers:'
        $found | ForEach-Object { Write-Host "  $_" }
        Write-Host 'Run again with the sign''s IP:  .\connect.ps1 <ip>'
        return
    }
    $Ip = $found[0]
}

$serial = "${Ip}:$Port"
& $Adb connect $serial | Write-Host
$state = & $Adb -s $serial get-state 2>$null
if ($state -ne 'device') {
    throw "The sign says '$state'. If it shows 'Allow USB debugging?', tap Allow (tick Always) and run this again."
}
Set-Content $SerialFile $serial
$model = Invoke-Shell 'getprop ro.product.model'
$version = Invoke-Shell 'getprop ro.build.version.release'
Write-Host "Connected: $model, Android $version ($serial)"
