#!/system/bin/sh
# post-fs-data.sh — runs at boot (busybox ash, already root).
# NOTE: installer helpers like set_perm_recursive are NOT available here;
# file permissions are set at install time by customize.sh.
MODDIR=${0%/*}

# Register a path with SuSFS + KernelSU umount so the overlay is hidden.
# All calls are best-effort: absent tools are silently ignored.
hide_mount() {
  target="$1"
  ksu_susfs add_sus_mount "$target" 2>/dev/null || true
  ksu_susfs add_try_umount "$target" 1 2>/dev/null || true
  ksud kernel umount add "$target" --flags 2 2>/dev/null || true
}

# Bind-mount src over dst (read-only) and hide it, if dst exists.
bind_hide() {
  src="$1"; dst="$2"
  [ -f "$src" ] || return 0
  [ -e "$dst" ] || return 0
  mount -o ro,bind "$src" "$dst" 2>/dev/null || return 0
  hide_mount "$dst"
  hide_mount "/mnt/vendor$dst"
}

# --- Hide the module's own /system overlay ----------------------------------
if [ -d "$MODDIR/system" ]; then
  find "$MODDIR/system" -type f | while read -r file; do
    hide_mount "/system${file#$MODDIR/system}"
  done
fi

# --- Enable call recording ---------------------------------------------------
# OPlus gates recording via feature flags in vendor extension configs. Strip
# the blocking flags from a private copy and bind it back over the original.
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

# --- Re-enable the ported apps via app_v2.xml --------------------------------
# OxygenOS ships the OnePlus/ColorOS Contacts, Dialer (InCallUI) and Messages
# but marks them <disable> in .../etc/config/app_v2.xml on this firmware, so the
# app-platform service turns them off at boot. We surgically strip ONLY those
# three <disable> lines from the real file (preserving every other stock entry)
# and bind the result back. Done dynamically so it stays correct across regions
# and firmware versions instead of shipping a static, region-specific file.
strip_app_v2() {
  real="$1"
  [ -f "$real" ] || return 0
  out="$MODDIR/tmp/${real#/}"
  mkdir -p "$(dirname "$out")" || return 0
  sed -e '/<disable[^>]*"com\.android\.contacts"/d' \
      -e '/<disable[^>]*"com\.android\.incallui"/d' \
      -e '/<disable[^>]*"com\.android\.mms"/d' \
      "$real" > "$out" 2>/dev/null || return 0
  # Only bind if we actually changed something (avoids a pointless overlay).
  if ! cmp -s "$real" "$out"; then
    bind_hide "$out" "$real"
  fi
}
# Cover every OPlus extension partition that may carry app_v2.xml; the
# function no-ops on absent files and on files that don't disable our apps,
# so listing extras is safe across regions/carriers.
for p in my_stock my_region my_product my_carrier my_heytap my_preload my_bigball; do
  strip_app_v2 "/$p/etc/config/app_v2.xml"
done

exit 0
