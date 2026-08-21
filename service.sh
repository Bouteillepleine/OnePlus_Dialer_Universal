#!/system/bin/sh
MODDIR=${0%/*}
i=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ "$i" -lt 120 ]; do
  sleep 2
  i=$((i + 1))
done
[ "$(getprop sys.boot_completed)" = "1" ] || exit 0
rm -f "$MODDIR/.bootcount"

if [ -s "$MODDIR/.dataapp.list" ]; then
  while read -r apk; do
    [ -f "$apk" ] || continue
    case "$apk" in
      */Mms/*)      pkg=com.android.mms ;;
      */Contacts/*) pkg=com.android.contacts ;;
      */InCallUI/*) pkg=com.android.incallui ;;
      */BlackListApp/*) pkg=com.oplus.blacklistapp ;;
      *)            continue ;;
    esac
    case "$(pm path $pkg 2>/dev/null)" in
      *"/data/app/"*) continue ;;
    esac
    n=0
    while [ "$n" -lt 3 ]; do
      pm install -r -d "$apk" >/dev/null 2>&1 && break
      n=$((n + 1))
      sleep 10
    done
  done < "$MODDIR/.dataapp.list"
fi

if [ -s "$MODDIR/.kstat.list" ]; then
  while read -r live; do
    [ -n "$live" ] || continue
    ksu_susfs update_sus_kstat "$live" 2>/dev/null || true
  done < "$MODDIR/.kstat.list"
  rm -f "$MODDIR/.kstat.list"
fi
