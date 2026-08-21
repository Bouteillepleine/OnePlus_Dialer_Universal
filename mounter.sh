#!/system/bin/sh

nomount_active() {
  _meta=/data/adb/modules/meta-nomount
  [ -d "$_meta" ] || return 1
  [ -f "$_meta/disable" ] && return 1
  [ -f "$_meta/remove" ] && return 1
  [ -f "$_meta/skip_mount" ] && return 1
  if [ -L /data/adb/metamodule ]; then
    _act=$(readlink -f /data/adb/metamodule 2>/dev/null)
    [ -n "$_act" ] || _act=$(readlink /data/adb/metamodule 2>/dev/null)
    case "${_act%/}" in
      */meta-nomount) return 0 ;;
      *)              return 1 ;;
    esac
  fi
  return 0
}

active_mounter() {
  if nomount_active; then
    echo "NoMount Suite"
    return
  fi
  if [ -L /data/adb/metamodule ]; then
    _act=$(readlink -f /data/adb/metamodule 2>/dev/null)
    [ -n "$_act" ] || _act=$(readlink /data/adb/metamodule 2>/dev/null)
    case "${_act%/}" in
      */meta-nomount) echo "meta-nomount (disabled) - built-in mounter"; return ;;
      ?*)             basename "${_act%/}"; return ;;
    esac
  fi
  echo "magic mount"
}
