# Troubleshooting

**"WiFi Connection Failure" under the network name.** On Android 6 that label means the router *refused the
association*; a wrong password shows "Authentication problem" instead. Check that the router offers WPA2 on 2.4 GHz:
this radio can't do 5 GHz or WPA3. Our router sometimes refused all new devices for a while (phones too) while
existing ones stayed connected. Waiting, or restarting the router's Wi-Fi unit, fixed it.

**Web pages won't load, but Wi-Fi says connected.** On our unit, pinging an IP worked (`ping 8.8.8.8`) but DNS lookups
failed (`ping google.com` gave "unknown host"), so the Browser couldn't load anything by name. We never found out why.
It doesn't matter for anything in this repo: install apps from your computer over ADB or a local web server
(cleanup guide, step 4).

**`adb connect` works but `adb devices` later says offline / not found.** The sign dropped off Wi-Fi or got a new
IP address. Run `adb connect <ip>:5555` again, and reserve the sign's IP in your router (its MAC address is on the QR
label underneath).

**Copies are slow.** About 1 MB/s is normal: single-stream 2.4 GHz Wi-Fi, a slow storage layer and ADB's small
transfer chunks all add up.

**After `lock-adb.sh`, a new computer can't connect.** Copy `adbkey` and `adbkey.pub` from the old computer's
`~/.android/`, or watch the sign's screen for "Allow USB debugging?" and tap Allow. Locked out completely? Use the
terminal app as root and reset the setting (cleanup guide, step 8).

**Editing a system file with `sed` corrupted it.** The firmware's toybox `sed` mishandles `^`-anchored
substitutions. Use `busybox sed`, or a `while read` loop like `scripts/device/lock-adb.sh` does.

**Something we hid is needed after all.** `sh /sdcard/restore.sh <package>` as root, then reboot. Restore the
signage app and `com.sinkservice` together, or neither.

**The player shows "No videos in /storage/emulated/0/Movies/loop".** Put files in `/sdcard/Movies/loop/`
(`/sdcard` is the same place), then reload it, or restart the sign.
