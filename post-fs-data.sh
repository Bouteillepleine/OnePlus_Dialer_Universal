#!/system/bin/sh
MODDIR=${0%/*}

COUNT=$(cat "$MODDIR/.bootcount" 2>/dev/null || echo 0)
case "$COUNT" in ''|*[!0-9]*) COUNT=0 ;; esac
COUNT=$((COUNT + 1))
echo "$COUNT" > "$MODDIR/.bootcount"
if [ "$COUNT" -ge 3 ]; then
  : > "$MODDIR/skip_mount"
  : > "$MODDIR/.guard_tripped"
  echo "OnePlus_Dialer_Universal: boot guard tripped (count=$COUNT), overlay skipped" > /dev/kmsg 2>/dev/null
  exit 0
fi

MY_PARTS="my_product my_region my_bigball my_stock my_carrier my_heytap my_preload"

nomount_active() {
  _meta=/data/adb/modules/meta-nomount
  [ -d "$_meta" ] || return 1
  [ -f "$_meta/disable" ] && return 1
  [ -f "$_meta/remove" ] && return 1
  [ -f "$_meta/skip_mount" ] && return 1
  if [ -L /data/adb/metamodule ]; then
    _act=$(readlink -f /data/adb/metamodule 2>/dev/null)
    [ -n "$_act" ] || _act=$(readlink /data/adb/metamodule 2>/dev/null)
    case "${_act%/}" in
      */meta-nomount) return 0 ;;
      *)              return 1 ;;
    esac
  fi
  return 0
}

if nomount_active; then
  STAGE="$MODDIR"
  DO_BIND=0
  mkdir -p /data/adb/nomount 2>/dev/null
  touch /data/adb/nomount/my_hookless 2>/dev/null
else
  STAGE="$MODDIR/tmp"
  DO_BIND=1
  for b in $MY_PARTS; do
    rm -rf "$MODDIR/$b"
  done
fi

KSTAT_LIST="$MODDIR/.kstat.list"

hide_mount() {
  target="$1"
  ksu_susfs add_sus_mount "$target" 2>/dev/null || true
  case "$target" in
    */priv-app/*|*/app/*|*/overlay/*) return 0 ;;
  esac
  ksu_susfs add_try_umount "$target" 1 2>/dev/null || true
  ksud kernel umount add "$target" --flags 2 2>/dev/null || true
}

kstat_pre() {
  ksu_susfs add_sus_kstat "$1" 2>/dev/null || true
}

kstat_post() {
  ksu_susfs update_sus_kstat "$1" 2>/dev/null || true
}

bind_hide() {
  src="$1"; dst="$2"
  [ "$DO_BIND" = 1 ] || return 0
  [ -f "$src" ] || return 0
  [ -e "$dst" ] || return 0
  kstat_pre "$dst"
  mount -o ro,bind "$src" "$dst" 2>/dev/null || return 0
  hide_mount "$dst"
  case "$dst" in /mnt/vendor/*) ;; *) hide_mount "/mnt/vendor$dst" ;; esac
  kstat_post "$dst"
}

strip_to() {
  _src="$1"; _dst="$2"; shift 2
  mkdir -p "${_dst%/*}" 2>/dev/null || return 1
  sed "$@" "$_src" > "$_dst.new" 2>/dev/null || { rm -f "$_dst.new"; return 1; }
  [ -s "$_dst.new" ] || { rm -f "$_dst.new"; return 1; }
  mv -f "$_dst.new" "$_dst"
}

rm -rf "$MODDIR/dataapp"
rm -f "$KSTAT_LIST" "$MODDIR/.dataapp.list"
if [ "$DO_BIND" = 1 ] && [ -d "$MODDIR/system" ]; then
  find "$MODDIR/system" -name '*.apk' | while read -r apk; do
    rel="${apk#$MODDIR/system}"
    part="${rel#/}"; part="${part%%/*}"
    [ -L "/system/$part" ] && live="$rel" || live="/system$rel"
    [ -f "$live" ] || echo "$apk" >> "$MODDIR/.dataapp.list"
  done
fi

if [ "$DO_BIND" = 1 ] && [ -d "$MODDIR/system" ]; then
  find "$MODDIR/system" -type f | while read -r file; do
    rel="${file#$MODDIR/system}"
    part="${rel#/}"; part="${part%%/*}"
    [ -L "/system/$part" ] && live="$rel" || live="/system$rel"
    hide_mount "$live"
    [ -e "$live" ] || continue
    kstat_pre "$live"
    echo "$live" >> "$KSTAT_LIST"
  done
fi

for dir in /my_product/etc/extension /my_region/etc/extension /my_bigball/etc/extension; do
  [ -d "$dir" ] || continue
  list=$(grep -rl -e 'no_display_record' -e 'support_record_prompt' \
                  -e 'not_support_record' -e 'disable_ted_function' "$dir" 2>/dev/null)
  [ "$DO_BIND" = 0 ] && [ -d "$STAGE$dir" ] && list="$list
$(find "$STAGE$dir" -type f 2>/dev/null | sed "s|^$STAGE||")"
  for disrec in $(echo "$list" | sort -u); do
    [ -f "$disrec" ] || continue
    strip_to "$disrec" "$STAGE$disrec" \
      -e '/no_display_record/d; /not_support_record/d; /support_record_prompt/d; /disable_ted_function/d' || continue
    bind_hide "$STAGE$disrec" "$disrec"
    bind_hide "$STAGE$disrec" "/mnt/vendor$disrec"
  done
done

for p in $MY_PARTS; do
  real="/$p/etc/config/app_v2.xml"
  [ -f "$real" ] || continue
  grep -qE '<disable[^>]*"(com\.android\.(contacts|incallui|mms)|com\.oplus\.blacklistapp)"' "$real" 2>/dev/null \
    || { [ "$DO_BIND" = 0 ] && [ -f "$STAGE$real" ]; } || continue
  strip_to "$real" "$STAGE$real" \
    -e '/<disable[^>]*"com\.android\.contacts"/d' \
    -e '/<disable[^>]*"com\.android\.incallui"/d' \
    -e '/<disable[^>]*"com\.android\.mms"/d' \
    -e '/<disable[^>]*"com\.oplus\.blacklistapp"/d' || continue
  cmp -s "$real" "$STAGE$real" || bind_hide "$STAGE$real" "$real"
done

exit 0
