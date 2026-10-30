#!/system/bin/sh
# Un-hides packages that debloat.sh hid. Run as root, then reboot.
#   sh restore.sh                       everything listed in /sdcard/debloat-log.txt
#   sh restore.sh com.brcm.nfcutil      just the ones you name
# Restoring the signage app without com.sinkservice (or the reverse) can put the sign in a reboot loop.

LOG=/sdcard/debloat-log.txt
if [ $# -gt 0 ]; then
  PACKAGES="$*"
else
  PACKAGES=$(sort -u "$LOG" 2>/dev/null)
fi
if [ -z "$PACKAGES" ]; then
  echo "Nothing to restore."
  exit 0
fi

for pkg in $PACKAGES; do
  if pm unhide "$pkg" | grep -q 'hidden state: false'; then
    echo "restored   $pkg"
  else
    echo "FAILED     $pkg"
  fi
done
echo "Reboot so restored apps start again: reboot"
