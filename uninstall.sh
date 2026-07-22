#!/system/bin/sh
# uninstall.sh — runs when the module is removed. Clears the package cache so
# the framework re-scans without the mounted priv-apps on next boot.
rm -rf /data/system/package_cache/*
