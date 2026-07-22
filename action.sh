#!/system/bin/sh
# action.sh — KernelSU "Action" button. Runs as root from the module dir.
# Recovers stuck/misbehaving dialer & messages after (re)install by clearing
# caches and reapplying the OPlus media + auto-recording configs.
MODDIR=${0%/*}
CONFIG_DIR="$MODDIR/config"

echo " OnePlus Dialer & Messages - maintenance action"

# --- Cache purge (forces a clean re-odex / re-init of the mounted apps) ------
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

# --- Reapply bundled configs -------------------------------------------------
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

echo " Done. Reboot normally. If an app is still stuck: tap this action"
echo " once more, then uninstall the module, reboot, and reinstall it."
