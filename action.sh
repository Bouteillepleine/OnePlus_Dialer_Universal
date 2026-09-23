#!/system/bin/sh
MODDIR=${0%/*}
CONFIG_DIR="$MODDIR/config"

echo " OnePlus Dialer & Messages - maintenance action"
[ -f "$MODDIR/.guard_tripped" ] && echo " [!] boot guard tripped - overlay skipped (rm $MODDIR/skip_mount $MODDIR/.guard_tripped to re-enable)"

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

GD_AUDIO=/data/data/com.google.android.dialer/files/audioinjector
silence_disclosure() {
  f="$1"
  sz="$(stat -c %s "$f" 2>/dev/null)" || return 0
  case "$sz" in ''|*[!0-9]*) return 0 ;; esac
  [ "$sz" -gt 44 ] || return 0
  [ "$(tail -c +45 "$f" 2>/dev/null | tr -d '\0' | wc -c)" = 0 ] && return 0
  t="$MODDIR/.silence.tmp"
  head -c 44 "$f" > "$t" 2>/dev/null || return 0
  head -c "$((sz - 44))" /dev/zero >> "$t" 2>/dev/null
  [ "$(stat -c %s "$t" 2>/dev/null)" = "$sz" ] && cat "$t" > "$f" && echo " [+] silenced $(basename "$f")"
  rm -f "$t"
}
if [ -d "$GD_AUDIO" ]; then
  for w in "$GD_AUDIO"/call_recording_*.wav; do
    [ -f "$w" ] && silence_disclosure "$w"
  done
  echo " [+] Google Phone recording announcement silenced"
else
  echo " [-] Google Phone recording announcement: nothing to silence"
fi

echo " Restarting services..."
am force-stop com.coloros.accessibilityassistant 2>/dev/null
am force-stop com.oplus.aicall 2>/dev/null
am force-stop com.android.systemui 2>/dev/null

echo " Done. Reboot normally. If an app is still stuck: tap this action"
echo " once more, then uninstall the module, reboot, and reinstall it."
