#!/system/bin/sh
# Backup autostart for Loop Player. This firmware's /system/bin/install-recovery.sh (the SuperSU boot hook)
# runs /system/etc/install-recovery-2.sh at every boot; this script creates that file so it opens the player
# once boot finishes. The app's own boot receiver normally does this already; this covers the case where the
# app was force-stopped. Run as root. Delete /system/etc/install-recovery-2.sh to undo.

grep -q install-recovery-2.sh /system/bin/install-recovery.sh || {
  echo "This firmware's install-recovery.sh doesn't call install-recovery-2.sh; nothing to do."
  exit 1
}
mount -o remount,rw /system || exit 1
cat > /system/etc/install-recovery-2.sh <<'EOF'
#!/system/bin/sh
(
  while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 2; done
  sleep 10
  am start -n io.github.robbiemueller.loopplayer/.PlayerActivity
) &
EOF
chmod 755 /system/etc/install-recovery-2.sh
mount -o remount,ro /system
echo "Installed /system/etc/install-recovery-2.sh"
