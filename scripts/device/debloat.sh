#!/system/bin/sh
# Hides (does not delete) the FYD-835S vendor packages. Run as root, then reboot.
# Every package it hides is appended to /sdcard/debloat-log.txt; restore.sh puts them back.
#   adb push debloat.sh /sdcard/ && adb shell su -c sh /sdcard/debloat.sh

LOG=/sdcard/debloat-log.txt

# The first three must go together: com.sinkservice reboots the sign if the signage app stops answering.
PACKAGES="
com.example.lty.ad
com.myg.startadsapp
com.sinkservice
android.rockchip.update.service
com.cghs.stresstest
com.DeviceTest
com.brcm.nfcutil
com.google.android.inputmethod.pinyin
"

for pkg in $PACKAGES; do
  if ! pm list packages -u | grep -qxF "package:$pkg"; then
    echo "skip       $pkg (not on this unit)"
  elif ! pm list packages | grep -qxF "package:$pkg"; then
    echo "already    $pkg"
  else
    am force-stop "$pkg"
    if pm hide "$pkg" | grep -q 'hidden state: true'; then
      echo "$pkg" >> "$LOG"
      echo "hidden     $pkg"
    else
      echo "FAILED     $pkg"
    fi
  fi
done
echo "Done. Reboot to finish: reboot"
