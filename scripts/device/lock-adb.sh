#!/system/bin/sh
# Makes ADB require a trusted key: adds your computer's public key to /data/misc/adb/adb_keys and sets
# ro.adb.secure=1 in /system/build.prop. Run as root, then reboot. Safe to run again with another key.
#   adb push ~/.android/adbkey.pub /sdcard/adbkey.pub
#   adb shell su -c sh /sdcard/lock-adb.sh /sdcard/adbkey.pub
# Keep a terminal app installed: it's the way back in if you lose the key (see docs/cleanup-guide.md).

KEY=${1:?usage: lock-adb.sh /sdcard/adbkey.pub}
[ -s "$KEY" ] || { echo "No key at $KEY"; exit 1; }
KEYS=/data/misc/adb/adb_keys

mkdir -p /data/misc/adb
touch $KEYS
# Make sure the existing file ends with a newline before appending.
[ -s $KEYS ] && [ -n "$(tail -c 1 $KEYS)" ] && echo >> $KEYS
grep -qxF "$(cat "$KEY")" $KEYS || printf '%s\n' "$(cat "$KEY")" >> $KEYS
chown system:shell $KEYS
chmod 640 $KEYS

mount -o remount,rw /system || exit 1
[ -f /system/build.prop.orig ] || cp /system/build.prop /system/build.prop.orig
# Rewrite the ro.adb.secure line (stock: "ro.adb.secure =0", with a space) with a plain shell loop: the
# toybox sed on this firmware mangles '^'-anchored substitutions.
found=0
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    ro.adb.secure*) echo 'ro.adb.secure=1'; found=1 ;;
    *) printf '%s\n' "$line" ;;
  esac
done < /system/build.prop > /system/build.prop.new
[ $found = 1 ] || echo 'ro.adb.secure=1' >> /system/build.prop.new
mv /system/build.prop.new /system/build.prop
chmod 644 /system/build.prop
restorecon /system/build.prop 2>/dev/null
mount -o remount,ro /system
echo "Trusted keys: $(wc -l < $KEYS). ADB will require one of them after: reboot"
