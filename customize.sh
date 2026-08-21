SKIPMOUNT=false
PROPFILE=true
POSTFSDATA=true
LATESTARTSERVICE=true

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
PART="$(detect_incallui_part)"
ui_print "  InCallUI partition: /$PART"
if [ "$PART" != "product" ] && [ -d "$MODPATH/system/product" ]; then
  mkdir -p "$MODPATH/system/$PART"
  cp -a "$MODPATH/system/product/." "$MODPATH/system/$PART/" && rm -rf "$MODPATH/system/product"
  ui_print "  Relocated overlay: /product -> /$PART"
fi

set_perm_recursive "$MODPATH" 0 0 0755 0644

for s in post-fs-data.sh service.sh action.sh uninstall.sh; do
  [ -f "$MODPATH/$s" ] && set_perm "$MODPATH/$s" 0 0 0755 0755
done

rm -f "$MODPATH/.bootcount" "$MODPATH/.guard_tripped" "$MODPATH/skip_mount"

ui_print "  Install complete. Reboot to apply."
ui_print "  If an app misbehaves after boot, run the module's"
ui_print "  Action button once, then reboot."
ui_print " "
