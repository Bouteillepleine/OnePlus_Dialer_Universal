#!/system/bin/sh
# post-fs-data.sh — serve the module's /my_* overrides.
#
# The overrides (call-recording configs, app_v2.xml) are staged into this
# module's OWN partition tree at install time (customize.sh), plus the priv-app
# overlay under /system(/product). Under the NoMount Suite the metamodule mount
# pass serves that whole tree HOOKLESSLY (zero mounts — nothing for a mount
# scanner like Duck Detector / NativeCheck to flag), so there is nothing to do
# here. On a non-NoMount setup (Magisk / magic-mount) the module-root my_* dirs
# are NOT auto-served, so we bind them from the tree and best-effort hide them,
# preserving the previous behaviour.
MODDIR=${0%/*}

# NoMount present -> the metamodule mount pass already serves the whole tree
# hooklessly (VFS injection, no mounts). Do nothing.
[ -d /data/adb/modules/meta-nomount ] && exit 0

# ---- Fallback path (no NoMount): bind from the staged tree + best-effort hide ----
hide_mount() {
  target="$1"
  ksu_susfs add_sus_mount "$target" 2>/dev/null || true
  ksu_susfs add_try_umount "$target" 1 2>/dev/null || true
  ksud kernel umount add "$target" --flags 2 2>/dev/null || true
}

# Bind every staged my_* file over its real target (only if the target exists).
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

# Hide the /system priv-app overlay too (magic-mount fallback only).
if [ -d "$MODDIR/system" ]; then
  find "$MODDIR/system" -type f | while read -r file; do
    hide_mount "/system${file#$MODDIR/system}"
  done
fi
exit 0
