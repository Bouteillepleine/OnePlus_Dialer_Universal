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
PART="$(detect_incallui_part)"
ui_print "  InCallUI partition: /$PART"
if [ "$PART" != "product" ] && [ -d "$MODPATH/system/product" ]; then
  mkdir -p "$MODPATH/system/$PART"
  cp -a "$MODPATH/system/product/." "$MODPATH/system/$PART/" && rm -rf "$MODPATH/system/product"
  ui_print "  Relocated overlay: /product -> /$PART"
fi

# --- Permissions -------------------------------------------------------------
# directories 0755, files 0644
set_perm_recursive "$MODPATH" 0 0 0755 0644

# Boot + action scripts must be executable
for s in post-fs-data.sh service.sh action.sh uninstall.sh; do
  [ -f "$MODPATH/$s" ] && set_perm "$MODPATH/$s" 0 0 0755 0755
done

# APKs stay 0644 (default) and are mounted read-only as system priv-app.
ui_print "  Install complete. Reboot to apply."
ui_print "  If an app misbehaves after boot, run the module's"
ui_print "  Action button once, then reboot."
ui_print " "
