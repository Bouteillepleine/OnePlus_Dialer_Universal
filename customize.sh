SKIPMOUNT=false
PROPFILE=true
POSTFSDATA=true
LATESTARTSERVICE=false

ui_print " "
ui_print "  OnePlus Phone, Contacts & Messages (Android 16)"
ui_print "  - Full-feature Phone/Contacts, InCallUI & Messages"
ui_print "  - Overlaid in-place onto the detected partition"
ui_print " "

if [ "$API" -lt 35 ]; then
  ui_print "  ! Detected Android API $API (< 35)."
  ui_print "  ! This build targets Android 16 (API 36); older ROMs may"
  ui_print "  ! reject the OPlus privileged-permission set. Continuing anyway."
  ui_print " "
fi

detect_incallui_part() {
  live="$(pm path com.android.incallui 2>/dev/null | grep -oE '/[a-z_]+/priv-app/InCallUI' | head -1)"
  if [ -n "$live" ]; then
    echo "$live" | cut -d/ -f2
    return
  fi
  for p in product system_ext my_stock my_product system; do
    [ -d "/$p/priv-app/InCallUI" ] && { echo "$p"; return; }
  done
  echo product
}
. "$MODPATH/mounter.sh"

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

ui_print "  $(sh "$MODPATH/stage_overrides.sh" "$MODPATH")"
ui_print "  Active mounter: $(active_mounter)"
if nomount_active; then
  ui_print "  NoMount serves the whole tree hooklessly (no mounts to detect)"
else
  ui_print "  /my_* will be bound at boot (post-fs-data fallback);"
  ui_print "  the priv-app overlay is served from system/product"
fi

set_perm_recursive "$MODPATH" 0 0 0755 0644

for s in post-fs-data.sh service.sh action.sh uninstall.sh stage_overrides.sh mounter.sh; do
  [ -f "$MODPATH/$s" ] && set_perm "$MODPATH/$s" 0 0 0755
done

ui_print "  Install complete. Reboot to apply."
ui_print "  If an app misbehaves after boot, run the module's"
ui_print "  Action button once, then reboot."
ui_print " "
