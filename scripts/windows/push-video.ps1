# Puts a video on the sign for Loop Player: re-encodes it for the RK3126 decoder (H.264 Main 3.1, AAC),
# copies it into /sdcard/Movies/loop/ and tells the player to reload. Needs ffmpeg (winget install ffmpeg).
#   .\push-video.ps1 C:\path\video.mp4                     replace the playlist with this one video
#   .\push-video.ps1 C:\path\video.mp4 -Add -Name 02-menu  add it to the playlist as 02-menu.mp4
#   .\push-video.ps1 C:\path\video.mp4 -Mute               strip the sound
param([Parameter(Mandatory)][string]$Video, [string]$Name, [switch]$Add, [switch]$Mute)
. "$PSScriptRoot\common.ps1"

if (-not $Name) { $Name = '01-' + [IO.Path]::GetFileNameWithoutExtension($Video) }
$dir = '/sdcard/Movies/loop'
$tmp = Join-Path $env:TEMP "$Name.mp4"

$audio = if ($Mute) { @('-an') } else { @('-c:a', 'aac', '-b:a', '160k') }
ffmpeg -hide_banner -loglevel error -y -i $Video -c:v libx264 -profile:v main -level 3.1 -preset slow -crf 19 `
    -pix_fmt yuv420p -g 48 @audio -movflags +faststart $tmp
Write-Host ("Encoded {0:N1} MB (the sign copies at about 1 MB/s)" -f ((Get-Item $tmp).Length / 1MB))

Invoke-Shell "mkdir -p $dir" | Out-Null
# Copy under a temporary name so the player never sees a half-written file
Invoke-Adb push $tmp "/sdcard/Movies/$Name.partial"
if (-not $Add) { Invoke-Shell "rm -f $dir/*" | Out-Null }
Invoke-Shell "mv /sdcard/Movies/$Name.partial $dir/$Name.mp4" | Out-Null
Invoke-Shell 'am start -n io.github.robbiemueller.loopplayer/.PlayerActivity --ez reload true' | Out-Null
Remove-Item $tmp
Write-Host "Playing. Playlist: $((Invoke-Shell "ls $dir") -join ', ')"
