#!/system/bin/sh
# service.sh — late_start service. Installs the bundled OnePlus InCallUI
# variant (Notes/Remarques + extra features) to /data. This APK only works as
# a data install; mounted as a /system priv-app it crashes (GraphicsEnvironment
# null-Resources at bind), so we overlay the factory copy via /data. It is
# Oplus-signed (same platform key as the factory), so the reinstall is accepted
# for the android.uid.phone shared UID.
MODDIR=${0%/*}
APK="$MODDIR/incallui/InCallUI.apk"
[ -f "$APK" ] || exit 0

# Wait for a fully-booted system — PackageInstaller isn't ready at late_start.
i=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ $i -lt 60 ]; do
  sleep 3; i=$((i + 1))
done
sleep 25

# Already running our /data variant? nothing to do.
case "$(pm path com.android.incallui 2>/dev/null)" in
  *"/data/app/"*) exit 0 ;;
esac

# Install, retrying a few times in case the installer is still coming up.
n=0
while [ $n -lt 5 ]; do
  pm install -r "$APK" >/dev/null 2>&1
  case "$(pm path com.android.incallui 2>/dev/null)" in
    *"/data/app/"*) exit 0 ;;
  esac
  n=$((n + 1)); sleep 10
done
exit 0
