#!/system/bin/sh
MODDIR=${0%/*}
i=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ "$i" -lt 120 ]; do
  sleep 2
  i=$((i + 1))
done
[ "$(getprop sys.boot_completed)" = "1" ] || exit 0
rm -f "$MODDIR/.bootcount"

if [ -s "$MODDIR/.kstat.list" ]; then
  while read -r live; do
    [ -n "$live" ] || continue
    ksu_susfs update_sus_kstat "$live" 2>/dev/null || true
  done < "$MODDIR/.kstat.list"
  rm -f "$MODDIR/.kstat.list"
fi
