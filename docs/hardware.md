# Hardware

What one unit reports about itself, plus what the seller listings claim. Check yours under **Settings → About
tablet** before running anything from this repo.

## Confirmed on our unit

| | |
|---|---|
| SoC | Rockchip **RK3126** (Settings shows "rk312x"), quad Cortex-A7 |
| Android | **6.0.1**, security patch **2016-07-05** |
| Build | `RK30_ANDROID6.0.1-SDK-v2.08.00 FYD_RK3126_20220406_V2.0`, kernel 3.10.0 (built 2022-03-04) |
| Fingerprint | `rockchip/rk312x/rk312x:6.0.1/MXC89K/…:userdebug/test-keys` |
| Display | 600 × 1024, **natively portrait**, 58 Hz, 160 dpi, touch |
| Storage | about 5.3 GB free for user data (`/sdcard` and `/data` share it) |
| Wi-Fi | **2.4 GHz only**, single stream (72 Mbps link rate). Real-world `adb push` speed is about **0.9 MB/s**. |
| Audio | built-in speaker in the base (RK312X codec), quiet. Media volume 0–15, 11 by default. |
| Launcher | stock AOSP Launcher3, plus Rockchip's Browser, Explorer, Gallery and Video apps. No Google Play. |

## Outside

- **One screen.** The 835S has a single 7" touchscreen on one face. The other face is a clear slot holding a printed
  paper card (ours came with a coffee ad), which is what listings mean by "dual-sided". The FYD-835SD is the version
  with a screen on both faces.
- **Power in:** DC barrel jack, 12 V / 2 A.
- **USB-A ×2** (one has a 3-LED battery gauge) and a **multi-head lead** (micro-USB, Lightning, USB-C) for
  charging phones. These come from the battery board and are **charge-only**. We found no USB data or OTG port, so
  ADB has to go over Wi-Fi (see the guide).
- **Underside:** a QR label with the Wi-Fi MAC address, and a "Registration Code" QR that pairs the unit with the
  maker's cloud. You don't need either. There's also a speaker grille, a lock slot for the base, a round button and a pinhole.

## From seller listings (not verified by us)

- Battery: 20,800 or 23,200 mAh of 18650 lithium cells, charged in about 5 h, with a claimed 27–33 h of screen time.
- RAM 1 GB, flash 8 GB.
- Two-screen units (835SD) probably mirror one picture to both panels. Ours has only one screen, so we couldn't check.
- A presence sensor: the firmware ships `com.tunkey.radardormancy` ("RadarDormancy"), a settings screen for
  sleeping the screen when nobody is near. We haven't tested the sensor itself.

## Notes for using it outdoors

It's an indoor unit and not weatherproof. Lithium cells and the LCD both dislike heat and direct sun, and you
shouldn't charge it below 0 °C / 32 °F. The LCD washes out in daylight and looks best from dusk on.
