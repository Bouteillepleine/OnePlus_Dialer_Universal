#!/system/bin/sh
# stage_overrides.sh — regenerate the /my_* config overrides in the module tree.
# $1 = tree to write into (MODPATH at install, MODDIR from the Action button).
TREE="${1:-${0%/*}}"
PREV=/data/adb/modules/OnePlus_Dialer_Universal
staged=0

# Read the live path, write via a temp file: under NoMount the live path IS this
# module's own staged file, so writing straight to the destination would truncate
# what we are reading. Re-mounting the partition does not help — the hookless
# injection is per-inode, so a second mount of the same device shows it too.
strip_to() {
  _src=$1; _dst=$2; shift 2
  mkdir -p "${_dst%/*}" 2>/dev/null || return 1
  sed "$@" "$_src" > "$_dst.new" 2>/dev/null || { rm -f "$_dst.new"; return 1; }
  [ -s "$_dst.new" ] || { rm -f "$_dst.new"; return 1; }
  mv -f "$_dst.new" "$_dst"
}

for base in my_product my_region my_bigball; do
  [ -d "/$base/etc/extension" ] || continue
  # Files still carrying a blocking flag, plus anything a previous install staged
  # (its live override is what hides the flag from this grep).
  list=$(grep -rl -e 'no_display_record' -e 'support_record_prompt' \
                  -e 'not_support_record' -e 'disable_ted_function' \
                  "/$base/etc/extension" 2>/dev/null)
  [ -d "$PREV/$base/etc/extension" ] && list="$list
$(find "$PREV/$base/etc/extension" -type f 2>/dev/null | sed "s|^$PREV||")"
  for src in $(echo "$list" | sort -u); do
    [ -f "$src" ] || continue
    strip_to "$src" "$TREE$src" \
      -e '/no_display_record/d; /not_support_record/d; /support_record_prompt/d; /disable_ted_function/d' \
      && staged=$((staged + 1))
  done
done

for base in my_stock my_region my_product my_carrier my_heytap my_preload my_bigball; do
  real="/$base/etc/config/app_v2.xml"
  [ -f "$real" ] || continue
  # Needed when the ROM still disables the three apps, or when a previous install
  # staged this path — our own live override is why the greps come back clean.
  grep -qE '<disable[^>]*"com\.android\.(contacts|incallui|mms)"' "$real" 2>/dev/null \
    || [ -f "$PREV$real" ] || continue
  strip_to "$real" "$TREE$real" \
    -e '/<disable[^>]*"com\.android\.contacts"/d' \
    -e '/<disable[^>]*"com\.android\.incallui"/d' \
    -e '/<disable[^>]*"com\.android\.mms"/d' \
    && staged=$((staged + 1))
done

if [ -d /data/adb/modules/meta-nomount ]; then
  mkdir -p /data/adb/nomount
  touch /data/adb/nomount/my_hookless
fi

echo "Staged $staged /my_* override(s) into the module tree"
