# Cleanup guide

This takes the sign from stock to a clean, offline, locked-down Android box. Steps 1–6 get you a root shell and ADB
over Wi-Fi. Everything after that is optional, but recommended.

**You need:**
- **The sign**, plugged in.
- **A computer with `adb`.** On Windows, `winget install Genymobile.scrcpy` (bundles adb and scrcpy) or
  `winget install Google.PlatformTools`. On macOS, `brew install --cask android-platform-tools` (and
  `brew install scrcpy` to see the screen). On Linux, your distro's `adb` package.
- **Both on the same network.**

Scripts in [`scripts/device/`](../scripts/device/) run **on the sign**, as root. You can type or download them into
the terminal app (step 5), or run them from your computer once ADB works:
```sh
adb push scripts/device/<script>.sh /sdcard/
adb shell su -c sh /sdcard/<script>.sh
```

---

## 1. Get to Android

On our unit, the Home button in the on-screen bottom bar went to the stock launcher, and **Settings** was in the
app drawer. If yours is locked inside the signage app, check the paper manual for an exit gesture or password.

## 2. Join Wi-Fi

- The radio is **2.4 GHz only**, and Android 6 has **no WPA3**. Use a 2.4 GHz network on WPA2 or WPA2/WPA3 mixed mode.
- A **guest network** is a good idea until step 8 is done.
- If the network list says **"WiFi Connection Failure"**, the router refused the association. That isn't a wrong
  password, which shows as "Authentication problem". See [troubleshooting](troubleshooting.md).

## 3. Developer options

**Settings → About tablet → tap Build number 7 times**, then go back to **Developer options**. USB debugging was
already on in ours. There is **no "ADB over network" switch**, and no USB data port, so the next two steps turn on
network ADB from the device itself.

## 4. Install a terminal app

We used **Terminal Emulator for Android** (`jackpal.androidterm`, open source, from F-Droid).

1. **Allow the install:** turn on **Settings → Security → Unknown sources**.
2. **Get the APK onto the sign,** either way:
   - **Directly:** in the sign's **Browser**, open `f-droid.org/repo/jackpal.androidterm_72.apk`. Android 6's
     certificate store is from 2016, so expect a warning. Our unit couldn't resolve DNS at all, so this didn't work for us.
   - **From your computer:** download that APK on the computer, then serve the folder on your network:
     ```sh
     python -m http.server 8000
     ```
     Then on the sign, open `http://<computer-ip>:8000` in the Browser and tap the APK. Your firewall may ask
     you to allow it. Put `scripts/device/enable-network-adb.sh` in the same folder to fetch it too.
3. **Install it:** open the download and install.

## 5. Root, then ADB over Wi-Fi

Open **Terminal Emulator** and type `su`. The prompt should change to `#`; SuperSU grants root without asking.
Then either run the script you downloaded:
```sh
sh /sdcard/Download/enable-network-adb.sh
```
or type its four lines:
```sh
setprop persist.adb.tcp.port 5555
setprop service.adb.tcp.port 5555
stop adbd
start adbd
```
The `persist.` property makes it survive reboots.

## 6. Connect

Find the sign's IP under **Settings → Wi-Fi → (your network)**, or in your router's client list. Then:
```sh
adb connect <sign-ip>:5555
adb shell getprop ro.product.model      # rk312x
```
You won't see an "Allow USB debugging?" prompt, because the firmware sets `ro.adb.secure=0`. Step 8 fixes that.
On Windows, `scripts/windows/connect.ps1` scans your subnet for the sign and remembers it. `scrcpy` mirrors and
controls the screen from your computer.

**Optional, before changing anything:** `scripts/windows/inventory.ps1` saves a read-only snapshot (props,
packages, boot receivers, network sockets, vendor APKs) for comparison.

## 7. Remove the vendor software

```sh
adb push scripts/device/debloat.sh /sdcard/
adb shell su -c sh /sdcard/debloat.sh
adb reboot
```
This **hides** the eight vendor packages listed in [findings](findings.md). It doesn't uninstall them, and it logs
what it changed to `/sdcard/debloat-log.txt`. `scripts/device/restore.sh` brings them back.

Hide the signage app (`com.example.lty.ad`), its launcher (`com.myg.startadsapp`) and the watchdog
(`com.sinkservice`) **together**: the watchdog reboots the sign when the signage app stops answering.

The home screen is the stock Launcher3, so nothing breaks. After the reboot you should land on the plain launcher.

## 8. Lock it down

Each of these is a separate script, so pick what you want.

| Script | Does |
|---|---|
| `block-vendor-hosts.sh` | Points the vendor and Tencent telemetry domains at `0.0.0.0` in `/system/etc/hosts`, and backs up the original to `hosts.orig`. |
| `set-time.sh <Region/City>` | Sets the timezone (it ships as Asia/Shanghai) and points NTP at an IP (216.239.35.0, Google), in case DNS fails. |
| `lock-adb.sh /sdcard/adbkey.pub` | Trusts your computer's ADB key and sets `ro.adb.secure=1`. After a reboot, only that computer (or someone tapping **Allow** on the sign) can connect. |

Then turn installs from unknown sources back off. `adb install` still works afterwards.
```sh
adb shell settings put secure install_non_market_apps 0
```

**Before running `lock-adb.sh`:** copy your public key over first (`~/.android/adbkey.pub` on macOS/Linux,
`%USERPROFILE%\.android\adbkey.pub` on Windows):
```sh
adb push ~/.android/adbkey.pub /sdcard/adbkey.pub
adb shell su -c sh /sdcard/lock-adb.sh /sdcard/adbkey.pub
adb reboot
```
To use a new computer later, copy `adbkey` and `adbkey.pub` into its `~/.android/`, or approve it on the sign. Keep
the terminal app installed as the way back in. From it, as root:
```sh
mount -o remount,rw /system
busybox sed -i 's/^ro.adb.secure=1/ro.adb.secure=0/' /system/build.prop
reboot
```
Use `busybox sed`, not plain `sed`. The firmware's toybox `sed` mangles `^`-anchored substitutions: it inserts the
replacement at the start of the line instead of replacing the match, which would leave a corrupted `build.prop`.

## 9. Make it do something useful

See [playing-video.md](playing-video.md): the Loop Player app, encoding settings that suit this panel, and
autostart.
