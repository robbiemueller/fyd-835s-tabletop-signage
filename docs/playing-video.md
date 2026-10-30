# Playing your own video

## Encoding for this panel

| | |
|---|---|
| Resolution | **600 × 1024**, portrait (the panel's native size, so nothing gets scaled) |
| Video | H.264 **Main** profile, level 3.1, yuv420p, 24–30 fps, a keyframe every 2 s |
| Audio | AAC 128–160 kbps, stereo |
| Container | MP4 with `faststart` |

```sh
ffmpeg -i input.mp4 -vf "scale=600:1024:force_original_aspect_ratio=decrease,pad=600:1024:(ow-iw)/2:(oh-ih)/2" \
  -c:v libx264 -profile:v main -level 3.1 -preset slow -crf 19 -pix_fmt yuv420p -g 48 \
  -c:a aac -b:a 160k -movflags +faststart sign.mp4
```

The RK3126 decodes 1080p H.264 in hardware, but there's no point sending more than the panel's 600 × 1024. Copying
over Wi-Fi runs at about **1 MB/s**, so a 90-second loop at the settings above (about 30 MB) takes half a minute.

## Sound

The speaker is small and quiet: at default volume, a soft test tone was barely audible across a table. If your loop
has sound:
- **Roll off the lows.** Below about 140 Hz the speaker can't play anything; it only eats headroom.
- **Compress and master loud,** to around **-13 LUFS** integrated with peaks at -1 dBFS (louder than the usual -14
  to -16 for phones).
- **Favor mid and high sounds** (bells, voices, creaks); bass-heavy music disappears.
- **Raise the media volume** (0–15, 11 by default): swipe up from the bottom edge to bring back the nav bar and its
  volume buttons, or from a computer run `adb shell service call audio 3 i32 3 i32 15 i32 1 s16 com.android.shell`
  (`setStreamVolume`, music stream, 15).

## Players

- **[Loop Player](https://github.com/robbiemueller/loop-player)** (recommended): full screen, seamless loop, no
  controls, starts at boot, double-tap mute, and a hold-3-seconds menu for fit/fill and kiosk mode. Videos go in
  `/sdcard/Movies/loop/`. On Windows, `scripts/windows/push-video.ps1 video.mp4` encodes, copies and reloads in one step.
  ```sh
  adb install -r LoopPlayer.apk
  adb shell pm grant io.github.robbiemueller.loopplayer android.permission.READ_EXTERNAL_STORAGE
  adb shell mkdir -p /sdcard/Movies/loop
  ```
  The `pm grant` line saves tapping **Allow** on the storage prompt at first launch.
- **Stock RockVideoPlayer** (`android.rk.RockVideoPlayer/.VideoPlayActivity`): set **⋯ → Play mode → Repeat one**
  once and it loops, but it **flashes its controls every time the file restarts**. A workaround is to repeat the loop
  many times inside one file (`ffmpeg -f concat … -c copy`), but that file gets big and slow to copy.
  ```sh
  adb shell am start -a android.intent.action.VIEW -d file:///sdcard/Movies/video.mp4 -t video/mp4 \
    -n android.rk.RockVideoPlayer/.VideoPlayActivity
  ```

## Making loops seamless

Start and end the video on the same frame (black is easiest) with the sound faded out, so the seam is invisible no
matter which player you use.
