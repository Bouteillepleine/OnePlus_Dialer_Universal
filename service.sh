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

GD_AUDIO=/data/data/com.google.android.dialer/files/audioinjector

silence_disclosure() {
  f="$1"
  sz="$(stat -c %s "$f" 2>/dev/null)" || return 0
  case "$sz" in ''|*[!0-9]*) return 0 ;; esac
  [ "$sz" -gt 44 ] || return 0
  [ "$(tail -c +45 "$f" 2>/dev/null | tr -d '\0' | wc -c)" = 0 ] && return 0
  t="$MODDIR/.silence.tmp"
  head -c 44 "$f" > "$t" 2>/dev/null || return 0
  head -c "$((sz - 44))" /dev/zero >> "$t" 2>/dev/null
  [ "$(stat -c %s "$t" 2>/dev/null)" = "$sz" ] && cat "$t" > "$f"
  rm -f "$t"
}

n=0
while [ "$n" -lt 12 ] && [ ! -d "$GD_AUDIO" ]; do
  sleep 10
  n=$((n + 1))
done
for w in "$GD_AUDIO"/call_recording_*.wav; do
  [ -f "$w" ] && silence_disclosure "$w"
done

if [ -f "$MODDIR/.guard_tripped" ]; then
  DESC="⛔ overlay skipped, boot guard tripped · Action: clear caches"
else
  DESC="✅ Call recording for OxygenOS · Action: clear caches"
fi
sed -i "s|^description=.*|description=$DESC|" "$MODDIR/module.prop"
