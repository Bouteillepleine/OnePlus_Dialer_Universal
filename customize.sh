SKIPMOUNT=false
PROPFILE=true
POSTFSDATA=true
# No service.sh is shipped.
LATESTARTSERVICE=false

ui_print " "
ui_print "  OnePlus Phone, Dialer & Messages (Android 16)"
ui_print "  - Enables the ROM's built-in Phone/Contacts + InCallUI"
ui_print "  - Ships Messages (com.android.mms), with call recording"
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
