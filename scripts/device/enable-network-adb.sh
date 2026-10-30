#!/system/bin/sh
# Turns on ADB over Wi-Fi (port 5555) and keeps it on across reboots. Run as root:
#   su
#   sh /sdcard/Download/enable-network-adb.sh
setprop persist.adb.tcp.port 5555
setprop service.adb.tcp.port 5555
stop adbd
start adbd
echo "ADB is listening on port $(getprop service.adb.tcp.port)"
