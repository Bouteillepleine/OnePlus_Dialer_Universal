SKIPMOUNT=false
PROPFILE=true
POSTFSDATA=true
# No service.sh is shipped.
LATESTARTSERVICE=false

ui_print " "
ui_print "  OnePlus Phone, Contacts & Messages (Android 16)"
ui_print "  - Full-feature Phone/Contacts, InCallUI & Messages"
ui_print "  - Overlaid in-place onto the detected partition"
ui_print " "

# --- Sanity checks -----------------------------------------------------------
# API 36 == Android 16. Warn on mismatch but don't hard-abort; the priv-app
# permission set is authored against Android 16 (OxygenOS 16).
if [ "$API" -lt 35 ]; then
  ui_print "  ! Detected Android API $API (< 35)."
  ui_print "  ! This build targets Android 16 (API 36); older ROMs may"
  ui_print "  ! reject the OPlus privileged-permission set. Continuing anyway."
  ui_print " "
fi

# --- Detect InCallUI's partition and place the overlay in-place --------------
# The apps are overlaid onto the SAME priv-app partition the factory copies
# live on, so there is a single codePath (privileged, and it avoids the
# GraphicsEnvironment null-Resources crash a second /system copy triggers).
# That partition is /product on the OnePlus 15 but can differ (/system_ext,
# /my_stock, ...) on other models — so detect it and relocate the shipped
# /product overlay if needed.
detect_incallui_part() {
  # Prefer the live codePath when the package manager is up (booted install).
  live="$(pm path com.android.incallui 2>/dev/null | grep -oE '/[a-z_]+/priv-app/InCallUI' | head -1)"
  if [ -n "$live" ]; then
    echo "$live" | cut -d/ -f2
    return
  fi
  # Fallback: first partition that physically ships InCallUI as a priv-app.
  for p in product system_ext my_stock my_product system; do
    [ -d "/$p/priv-app/InCallUI" ] && { echo "$p"; return; }
  done
  echo product
}
. "$MODPATH/mounter.sh"

# --- Normalise the tree to the classic system/<partition> layout --------------
# NoMount serves both layouts: the classic one and the "auto_mount" one, where
# real partition dirs sit at the module ROOT and system/product is a symlink that
# converges the two. Magic mount serves NEITHER of those root dirs: it walks
# <module>/system only, and finding `product` there as a SYMLINK it collects a
# symlink node, so the APKs underneath are never mounted (worse, hoisting that
# node can try to replace /product itself with a symlink). So fold everything
# back under system/, which every mounter understands -- NoMount included, it
# maps system/product onto /product through the SAR alias.
for p in product system_ext vendor odm; do
  [ -L "$MODPATH/system/$p" ] && rm -f "$MODPATH/system/$p"
  [ -d "$MODPATH/$p" ] || continue
  [ -L "$MODPATH/$p" ] && { rm -f "$MODPATH/$p"; continue; }
  mkdir -p "$MODPATH/system/$p"
  cp -a "$MODPATH/$p/." "$MODPATH/system/$p/" && rm -rf "$MODPATH/$p"
  ui_print "  Layout: folded /$p overlay into system/$p"
done

PART="$(detect_incallui_part)"
ui_print "  InCallUI partition: /$PART"
if [ "$PART" != "product" ] && [ -d "$MODPATH/system/product" ]; then
  mkdir -p "$MODPATH/system/$PART"
  cp -a "$MODPATH/system/product/." "$MODPATH/system/$PART/" && rm -rf "$MODPATH/system/product"
  ui_print "  Relocated overlay: /product -> /$PART"
fi

# --- Stage /my_* overrides INTO this module's tree (served by the mounter) ----
# The stripped configs live in the module's own partition tree so the active
# mounter serves them: hooklessly under the NoMount Suite (zero mounts), or
# magic-mount elsewhere (fallback bind in post-fs-data.sh). Generated here so it
# adapts to THIS device's region/firmware; the Action button regenerates them.
ui_print "  $(sh "$MODPATH/stage_overrides.sh" "$MODPATH")"
ui_print "  Active mounter: $(active_mounter)"
if nomount_active; then
  ui_print "  NoMount serves the whole tree hooklessly (no mounts to detect)"
else
  ui_print "  /my_* will be bound at boot (post-fs-data fallback);"
  ui_print "  the priv-app overlay is served from system/product"
fi

# --- Permissions -------------------------------------------------------------
# directories 0755, files 0644
set_perm_recursive "$MODPATH" 0 0 0755 0644

# Boot + action scripts must be executable
for s in post-fs-data.sh service.sh action.sh uninstall.sh stage_overrides.sh mounter.sh; do
  [ -f "$MODPATH/$s" ] && set_perm "$MODPATH/$s" 0 0 0755
done

# APKs stay 0644 (default) and are mounted read-only as system priv-app.
ui_print "  Install complete. Reboot to apply."
ui_print "  If an app misbehaves after boot, run the module's"
ui_print "  Action button once, then reboot."
ui_print " "
