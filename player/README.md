# Loop Player

A 16 KB Android app that turns the sign into a video loop: full screen (immersive, so no status or nav bar), no
playback controls, and it starts at boot. Android 5.0+ (built for the FYD-835S's Android 6).

- Plays every `.mp4` / `.mkv` / `.webm` in **`/sdcard/Movies/loop/`** in name order, forever. A single file
  loops **seamlessly** inside the media player.
- **Double-tap:** sound off/on. It shows "Sound off" / "Sound on" and remembers the setting.
- **Hold a finger down for 3 seconds:** closes the player, back to the Android launcher for maintenance.
- **From a computer:**
  ```sh
  adb shell am start -n io.github.robbiemueller.loopplayer/.PlayerActivity --ez reload true   # rescan the folder
  adb shell am start -n io.github.robbiemueller.loopplayer/.PlayerActivity --ez mute true     # or false
  ```
- **Starts at boot** through its own `BOOT_COMPLETED` receiver. `scripts/device/install-autostart.sh` adds a backup
  launch through the firmware's boot hook.

Why not the stock Rockchip video player? It has a Repeat mode, but it flashes its play/pause/seek controls every
time the file restarts.

## Install

Download `LoopPlayer.apk` from the [Releases](../../../releases) page, or build it (below), then:
```sh
adb install -r LoopPlayer.apk
adb shell mkdir -p /sdcard/Movies/loop
adb push your-video.mp4 /sdcard/Movies/loop/
adb shell am start -n io.github.robbiemueller.loopplayer/.PlayerActivity
```
`adb install` works even with "Unknown sources" turned off.

## Build

No Gradle and no Android Studio project: just the SDK command-line pieces (`javac`, `d8`, `aapt2`, `zipalign`,
`apksigner`), using the Android SDK and JDK that Android Studio installs.

```sh
./build.sh --install         # macOS / Linux (untested so far)
.\build.ps1 -Install         # Windows (tested)
```

The first build creates `local.keystore` in this folder (git-ignored). Keep it: Android only installs an update
over an app signed with the same key, so a new key means uninstalling the old app first.
