#!/system/bin/sh
# post-fs-data.sh — serve the module's /my_* overrides.
#
# The overrides (call-recording configs, app_v2.xml) are staged into this
# module's OWN tree at install time (customize.sh -> stage_overrides.sh), next to
# the priv-app overlay under system/product. Under the NoMount Suite the
# metamodule mount pass serves that whole tree HOOKLESSLY (zero mounts — nothing
# for a mount scanner like Duck Detector / NativeCheck to flag), so there is
# nothing to do here.
#
# Under ANY other mounter (magic_mount, magic_mount_rs, the built-in ksud
# mounter, Magisk) only <module>/system is served — system/product is hoisted
# onto the real /product through the SAR symlink, so the priv-app overlay lands,
# but /my_* is not a partition those mounters know about. Without the binds below
# the app_v2.xml <disable> lines survive and OPlus' app-platform turns the three
# apps off at boot: the APKs are present in /product, the apps are not installed.
MODDIR=${0%/*}
. "$MODDIR/mounter.sh"

# NoMount is the active mounter -> the whole tree is already served hooklessly.
nomount_active && exit 0

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

# Hide the priv-app overlay the magic mounter puts in place. Its files live under
# <module>/system, but system/product & friends are hoisted onto the REAL
# partition (/system/product is a symlink to /product), so the live path to hide
# is /product/... — hiding /system/product/... hides nothing.
if [ -d "$MODDIR/system" ]; then
  find "$MODDIR/system" -type f | while read -r file; do
    rel="${file#$MODDIR/system}"        # /product/priv-app/Mms/Mms.apk
    part="${rel#/}"; part="${part%%/*}" # product
    if [ -L "/system/$part" ]; then
      hide_mount "$rel"
    else
      hide_mount "/system$rel"
    fi
  done
fi
exit 0
