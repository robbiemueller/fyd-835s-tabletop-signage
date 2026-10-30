# FYD-835S tabletop signage: get in, clean it up, reuse it

Notes, scripts and a replacement video player for the **FYD-835S / FYD-835SD** 7" tabletop "advertising player +
power bank" sold to restaurants and bars. It's made by Shenzhen Friday Originality Technology (FYD) and resold under
other names, for example **RXFSP RFSP1018** on Wayfair. Ours is the **835S: one touchscreen on one side** and a slot
for a printed card on the other (it shipped with a coffee ad). Listings call this "dual-sided". The **835SD** is the
sibling model with a screen on both sides.

Out of the box it runs a cloud signage app that the maker can control remotely, on a rooted Android 6 build with
the security switched off. This repo documents what we found, how we got a shell on it **with no USB data port**,
how we removed the vendor software, and how we turned it into a clean, offline video loop.

> Tested on one unit (build `FYD_RK3126_20220406_V2.0`). Other batches ship different boards and Android
> versions (4.4, 6.0, 7.1 and 11 all appear in listings), so check yours against [docs/hardware.md](docs/hardware.md)
> before running anything. Everything here is reversible, but it's your device and your risk.

## What we found

- **Wide-open root.** SuperSU's `su` grants root to *any* app without a prompt, SELinux is permissive, and the
  firmware is a `userdebug` build signed with AOSP test keys.
- **ADB needs no authorization** (`ro.adb.secure=0`), so once network ADB is on, anything on the Wi-Fi can take over the sign.
- **The signage app (`com.example.lty.ad`, "ADSV")** talks to `adapi.cnszfyd.cn` and `fydoss.cnszfyd.cn`
  plus an Alibaba Cloud IP. It keeps a persistent remote-command connection (Netty), can install apps, and embeds
  Tencent Bugly crash and usage reporting.
- **A system-privileged watchdog (`com.sinkservice`)** handshakes with the signage app and **reboots the sign** if it stops
  answering. It also has a silent-install broadcast receiver. Remove it in the same pass as the signage app, or the
  sign can get stuck rebooting over and over.
- **No USB data port.** The USB-A ports and the built-in phone leads are charge-only, from the battery board.

Details: [docs/findings.md](docs/findings.md).

## Quick start

1. **Wi-Fi:** join a 2.4 GHz WPA2 network, ideally a guest network.
2. **Root shell on the device:** install a terminal app, run `su`, then run
   [`scripts/device/enable-network-adb.sh`](scripts/device/enable-network-adb.sh). This turns on ADB over Wi-Fi
   permanently, with no cable needed. Full walkthrough: [docs/cleanup-guide.md](docs/cleanup-guide.md).
3. **From your computer:** `adb connect <sign-ip>:5555`
4. **Remove the vendor software:** `adb push scripts/device/debloat.sh /sdcard/ && adb shell su -c sh /sdcard/debloat.sh`
5. **Block its servers, fix the clock and lock ADB down:** see the guide, step 8.
6. **Play your own videos:** install the [Loop Player](player/) app (full screen, seamless loop, no controls,
   starts at boot, double-tap to mute). See [docs/playing-video.md](docs/playing-video.md).

## Repo layout

| Path | What |
|---|---|
| [docs/](docs/) | Hardware, findings, step-by-step cleanup, playing video, troubleshooting |
| [scripts/device/](scripts/device/) | `sh` scripts that run **on the sign** as root (from a terminal app or `adb shell su -c`). Platform-independent. |
| [scripts/windows/](scripts/windows/) | PowerShell helpers for Windows: find and connect, read-only inventory, debloat/restore, screenshots, push a video |
| [player/](player/) | Loop Player: a tiny Android app (no Gradle) that loops the videos in a folder full screen |

## License

MIT. See [LICENSE](LICENSE). Not affiliated with FYD, Wayfair or anyone who sells these.
