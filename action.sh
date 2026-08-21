#!/system/bin/sh
MODDIR=${0%/*}
CONFIG_DIR="$MODDIR/config"
. "$MODDIR/mounter.sh"

echo " OnePlus Dialer & Messages - maintenance action"

echo " Mounter: $(active_mounter)"
[ -f "$MODDIR/.guard_tripped" ] && echo " [!] boot guard tripped earlier - overlay is skipped (rm $MODDIR/skip_mount $MODDIR/.guard_tripped to re-enable)"
nomount_active || echo " (non-NoMount: /my_* overrides are bound by post-fs-data.sh)"
for pkg in com.android.contacts com.android.incallui com.android.mms; do
  path=$(pm path "$pkg" 2>/dev/null | head -1 | cut -d: -f2-)
  if [ -n "$path" ]; then
    echo " [+] $pkg <- $path"
  else
    echo " [!] $pkg NOT installed"
  fi
done
for f in /my_stock/etc/config/app_v2.xml /my_region/etc/config/app_v2.xml; do
  [ -f "$f" ] || continue
  if grep -qE '<disable[^>]*"com\.android\.(contacts|incallui|mms)"' "$f" 2>/dev/null; then
    echo " [!] $f still disables the apps - the override is not being served"
  fi
done

echo " Clearing dalvik-cache..."
rm -rf /data/dalvik-cache/arm/* /data/dalvik-cache/arm64/*

echo " Clearing app oat files..."
rm -rf /data/app/*/*/oat/*/*

echo " Clearing app cache and code_cache..."
rm -rf /data/data/*/cache/* /data/data/*/code_cache/*
rm -rf /data/user_de/*/*/cache/* /data/user_de/*/*/code_cache/*
rm -rf /sdcard/Android/data/*/cache/*

echo " Clearing MMS and InCallUI app data (your SMS/MMS stay safe)..."
rm -rf /data/user/0/com.android.mms /data/user/0/com.android.incallui
rm -rf /data/user_de/0/com.android.mms /data/user_de/0/com.android.incallui
rm -rf /data/data/com.android.mms /data/data/com.android.incallui
rm -rf /storage/emulated/0/Android/data/com.android.mms
rm -rf /storage/emulated/0/Android/data/com.android.incallui

echo " Clearing system package cache..."
rm -rf /data/system/package_cache/*

echo " Clearing MMS shortcut_service records..."
for u in 0 999; do
  rm -f "/data/system_ce/$u/shortcut_service/packages/com.android.mms.xml" \
        "/data/system_ce/$u/shortcut_service/packages/com.android.mms.xml.reservecopy"
done

echo " Re-staging /my_* overrides..."
if [ -f "$MODDIR/stage_overrides.sh" ]; then
  echo " [+] $(sh "$MODDIR/stage_overrides.sh" "$MODDIR")"
else
  echo " [!] stage_overrides.sh missing - reinstall the module"
fi

copy_cfg() {
  src="$CONFIG_DIR/$1"; dstdir="$2"; label="$3"
  if [ -f "$src" ]; then
    mkdir -p "$dstdir"
    cp -f "$src" "$dstdir/" && chmod 644 "$dstdir/$1"
    echo " [+] $label applied"
  else
    echo " [!] $label config missing ($src) - skipped"
  fi
}

copy_cfg oplus_media_controller_config_sp.xml \
  /data/user_de/0/com.android.systemui/shared_prefs "Lockscreen media control"
copy_cfg translatePreferences.xml \
  /data/user/0/com.coloros.accessibilityassistant/shared_prefs "Auto call-recording"

echo " Restarting services..."
am force-stop com.coloros.accessibilityassistant 2>/dev/null
am force-stop com.oplus.aicall 2>/dev/null
am force-stop com.android.systemui 2>/dev/null

echo " Done. Reboot to apply the regenerated overrides. If an app is still"
echo " stuck after that: tap this action"
echo " once more, then uninstall the module, reboot, and reinstall it."
