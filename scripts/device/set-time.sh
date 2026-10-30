#!/system/bin/sh
# Sets the timezone (the firmware ships on Asia/Shanghai) and points NTP at an IP address, so the clock still
# syncs if DNS doesn't work. Run as root.
#   sh set-time.sh America/Los_Angeles

TZ_NAME=${1:?usage: set-time.sh Region/City}
# Transaction 3 on the alarm service is setTimeZone on this Android 6 build.
service call alarm 3 s16 "$TZ_NAME" > /dev/null
settings put global auto_time_zone 0
settings put global auto_time 1
settings put global ntp_server 216.239.35.0
echo "Timezone: $(getprop persist.sys.timezone)   Clock: $(date)"
