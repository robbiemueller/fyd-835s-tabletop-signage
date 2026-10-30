#!/system/bin/sh
# Points the vendor cloud, Tencent telemetry and Rockchip OTA domains at 0.0.0.0 in /system/etc/hosts.
# Run as root. Safe to run twice. The original file is saved once as /system/etc/hosts.orig.

DOMAINS="
cnszfyd.cn
www.cnszfyd.cn
adapi.cnszfyd.cn
fydoss.cnszfyd.cn
szfyd.net
www.szfyd.net
android.bugly.qq.com
astat.bugly.qq.com
astat.bugly.qcloud.com
h.trace.qq.com
www.rockchip.com
"
HOSTS=/system/etc/hosts

mount -o remount,rw /system || exit 1
[ -f $HOSTS.orig ] || cp $HOSTS $HOSTS.orig
for d in $DOMAINS; do
  grep -qxF "0.0.0.0 $d" $HOSTS || echo "0.0.0.0 $d" >> $HOSTS
done
chmod 644 $HOSTS
mount -o remount,ro /system
echo "Blocked domains in $HOSTS: $(grep -c '^0\.0\.0\.0 ' $HOSTS)"
