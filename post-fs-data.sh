#!/system/bin/sh
MODDIR=${0%/*}
. "$MODDIR/mounter.sh"

nomount_active && exit 0

for part in product system_ext vendor odm; do
  [ -L "$MODDIR/system/$part" ] || continue
  [ -L "$MODDIR/$part" ] && continue
  [ -d "$MODDIR/$part" ] || continue
  rm -f "$MODDIR/system/$part" || continue
  mv -f "$MODDIR/$part" "$MODDIR/system/$part" || continue
done

hide_mount() {
  target="$1"
  ksu_susfs add_sus_mount "$target" 2>/dev/null || true
  ksu_susfs add_try_umount "$target" 1 2>/dev/null || true
  ksud kernel umount add "$target" --flags 2 2>/dev/null || true
}

for base in my_product my_region my_bigball my_stock my_carrier my_heytap my_preload; do
  [ -d "$MODDIR/$base" ] || continue
  find "$MODDIR/$base" -type f | while read -r src; do
    dst="${src#$MODDIR}"
    [ -e "$dst" ] || continue
    mount -o ro,bind "$src" "$dst" 2>/dev/null || continue
    hide_mount "$dst"
    hide_mount "/mnt/vendor$dst"
  done
done

if [ -d "$MODDIR/system" ]; then
  find "$MODDIR/system" -type f | while read -r file; do
    rel="${file#$MODDIR/system}"
    part="${rel#/}"; part="${part%%/*}"
    if [ -L "/system/$part" ]; then
      hide_mount "$rel"
    else
      hide_mount "/system$rel"
    fi
  done
fi
exit 0
