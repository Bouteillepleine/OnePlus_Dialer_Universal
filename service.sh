#!/system/bin/sh
MODDIR=${0%/*}
i=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ "$i" -lt 120 ]; do
  sleep 2
  i=$((i + 1))
done
[ "$(getprop sys.boot_completed)" = "1" ] && rm -f "$MODDIR/.bootcount"
