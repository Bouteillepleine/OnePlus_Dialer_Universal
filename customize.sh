SKIPMOUNT=false
PROPFILE=true
POSTFSDATA=true
LATESTARTSERVICE=true

ui_print " "
ui_print "  OnePlus Phone, Contacts & Messages (Android 16)"
ui_print "  - Enables the ROM's own Phone, Contacts and Dialer"
ui_print "  - Adds Messages, which the ROM does not ship"
ui_print " "

if [ "$API" -lt 35 ]; then
  ui_print "  ! Detected Android API $API (< 35)."
  ui_print "  ! This build targets Android 16 (API 36); older ROMs may"
  ui_print "  ! reject the OPlus privileged-permission set. Continuing anyway."
  ui_print " "
fi

FOUND=""
for p in product my_stock my_product system_ext system; do
  if [ -f "/$p/priv-app/InCallUI/InCallUI.apk" ] || [ -f "/$p/priv-app/Contacts/Contacts.apk" ]; then
    FOUND="$p"
    break
  fi
done

if [ -n "$FOUND" ]; then
  ui_print "  ROM ships Phone/Contacts on /$FOUND - enabling those"
else
  ui_print " "
  ui_print "  ! This ROM does not ship Contacts or InCallUI on any"
  ui_print "  ! partition, so there is nothing for this build to enable."
  ui_print "  ! Messages, call recording and the rest still install."
  ui_print "  ! For the bundled Phone/Contacts builds, flash v1.9."
  ui_print " "
fi

set_perm_recursive "$MODPATH" 0 0 0755 0644

for s in post-fs-data.sh service.sh action.sh uninstall.sh; do
  [ -f "$MODPATH/$s" ] && chmod 0755 "$MODPATH/$s"
done

rm -f "$MODPATH/.bootcount" "$MODPATH/.guard_tripped" "$MODPATH/skip_mount"

ui_print "  Install complete. Reboot to apply."
ui_print "  If an app misbehaves after boot, run the module's"
ui_print "  Action button once, then reboot."
ui_print " "
