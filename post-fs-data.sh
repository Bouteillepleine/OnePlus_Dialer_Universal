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

hide_mount() {
  target="$1"
  ksu_susfs add_sus_mount "$target" 2>/dev/null || true
  ksu_susfs add_try_umount "$target" 1 2>/dev/null || true
  ksud kernel umount add "$target" --flags 2 2>/dev/null || true
}

bind_hide() {
  src="$1"; dst="$2"
  [ -f "$src" ] || return 0
  [ -e "$dst" ] || return 0
  mount -o ro,bind "$src" "$dst" 2>/dev/null || return 0
  hide_mount "$dst"
  hide_mount "/mnt/vendor$dst"
}

if [ -d "$MODDIR/system" ]; then
  find "$MODDIR/system" -type f | while read -r file; do
    hide_mount "/system${file#$MODDIR/system}"
  done
fi

for dir in /my_product/etc/extension /my_region/etc/extension /my_bigball/etc/extension; do
  [ -d "$dir" ] || continue
  grep -rl -e 'no_display_record' -e 'support_record_prompt' \
           -e 'not_support_record' -e 'disable_ted_function' "$dir" 2>/dev/null |
  while read -r disrec; do
    mod_target="$MODDIR/tmp/${disrec#/}"
    mkdir -p "$(dirname "$mod_target")" || continue
    cp -f "$disrec" "$mod_target" || continue
    sed -i -e '/no_display_record/d; /not_support_record/d; /support_record_prompt/d; /disable_ted_function/d' "$mod_target"
    bind_hide "$mod_target" "$disrec"
    bind_hide "$mod_target" "/mnt/vendor$disrec"
  done
done

strip_app_v2() {
  real="$1"
  [ -f "$real" ] || return 0
  out="$MODDIR/tmp/${real#/}"
  mkdir -p "$(dirname "$out")" || return 0
  sed -e '/<disable[^>]*"com\.android\.contacts"/d' \
      -e '/<disable[^>]*"com\.android\.incallui"/d' \
      -e '/<disable[^>]*"com\.android\.mms"/d' \
      "$real" > "$out" 2>/dev/null || return 0
  if ! cmp -s "$real" "$out"; then
    bind_hide "$out" "$real"
  fi
}
for p in my_stock my_region my_product my_carrier my_heytap my_preload my_bigball; do
  strip_app_v2 "/$p/etc/config/app_v2.xml"
done

exit 0
