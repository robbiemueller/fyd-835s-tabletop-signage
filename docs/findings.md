# What's on it

From a read-only inventory of one unit (`scripts/windows/inventory.ps1` collects the same data) and static analysis
of the vendor APKs. **Nothing here comes from captured network traffic.** Hostnames and IPs are strings found inside
the apps, and our unit couldn't resolve DNS on our network, so we never saw it phone home. Treat the endpoint list
as "what the code is built to contact".

## Security posture

| Property | Value | Meaning |
|---|---|---|
| `ro.build.type` | `userdebug` | developer build, so `adb root` works |
| build keys | `test-keys` | signed with the public AOSP test keys |
| `ro.adb.secure` | `0` | ADB accepts any computer with no "Allow USB debugging?" prompt |
| `ro.debuggable` | `1` | |
| SELinux | `Permissive` | Android's app sandbox isn't enforced |
| `su` | `/system/xbin/su` (SuperSU, `daemonsu` started at boot) | **any app gets root without a prompt** (a terminal app's `su` just works) |
| `persist.sys.timezone` | `Asia/Shanghai` | |
| `ro.product.ota.host` | `www.rockchip.com:2300` | generic Rockchip SDK OTA host |
| Network ADB | off out of the box | no TCP ports listening at all, which is good |

`/system/bin/install-recovery.sh` only starts the SuperSU daemon, then runs `/system/etc/install-recovery-2.sh`
if that exists (it didn't). We found no `init.d` and no other persistence.

## Vendor packages

| Package | Label | Where | What it does |
|---|---|---|---|
| `com.example.lty.ad` (v4.6) | ADSV | `/data/app` | The cloud signage player. Its code references `https://adapi.cnszfyd.cn` (API, `/ipconfig/index`), `https://fydoss.cnszfyd.cn/upload/…` (content storage) and `47.90.203.47` (Alibaba Cloud). It uses Netty for a persistent connection, Tencent Bugly (`android.bugly.qq.com`, `astat.bugly.qcloud.com`, `h.trace.qq.com`) for crash and usage reporting, and asks for `REQUEST_INSTALL_PACKAGES` plus a boot receiver. Combined with open root, the maker can push content and apps. |
| `com.myg.startadsapp` (v2.1.5) | StartAdsApp | `/data/app` | Launches ADSV (`MainActivityNew` / `StartActivity`) after boot. Requests no permissions of its own. |
| `com.sinkservice` | (none) | `/system/app`, runs as **system** (uid 1000) | A watchdog: sends `android.zx.intent.action.handshake.*` to ADSV and **reboots** if ADSV doesn't answer. Also does scheduled power on/off (`AUTOPOWERONOFF`) and has a `SILENT_INSTALL_PACKAGE` receiver. |
| `android.rockchip.update.service` (v1.8.1) | | `/system/app` | Rockchip OTA updater: can reboot into recovery and flash firmware. The built-in host is a dev IP (`192.168.1.143:2300`). |
| `com.cghs.stresstest` | StressTest | `/system/priv-app` | Factory stress test, with a reboot receiver that runs at boot |
| `com.DeviceTest` | | `/system/priv-app` | Factory hardware test |
| `com.brcm.nfcutil` | NfcUtil | `/system/app` | Broadcom NFC utility. The board has no NFC. |
| `com.google.android.inputmethod.pinyin` | | `/system/app` | Chinese keyboard (the AOSP English keyboard is also present) |
| `com.tunkey.radardormancy` | RadarDormancy | `/system/app`, runs as **system** | Settings screen for presence-sensor screen sleep. **We kept it.** |
| `android.rk.RockVideoPlayer` | Video | `/system/app` | Rockchip's video player. Harmless, and it has a Repeat mode. |
| `com.svox.pico` | | `/system/app` | Text-to-speech. Harmless. |

Boot receivers that run at startup: ADSV (`BootBroadcastReceiver`, `UnlockActionReceiver`), StartAdsApp
(`AdvBroadcastReceiver`), SinkService (`SinkReceiver`), StressTest (`RebootReceiver`, `BoardidSwitchReceiver`) and
the Rockchip updater (`RKUpdateReceiver`).

## Removing them

`scripts/device/debloat.sh` hides (it doesn't delete) the first eight packages in the table above. Hidden packages
can't run, can't receive broadcasts and don't show in the launcher. `scripts/device/restore.sh` brings any of them
back. On this build, `pm disable-user` is refused from a plain ADB shell but `pm hide` works.

After hiding them and rebooting, our unit came up on the stock launcher with none of their processes running, and
no reboot loop over 10 minutes.
