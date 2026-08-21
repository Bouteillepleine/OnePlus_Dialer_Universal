#!/system/bin/sh
# mounter.sh — which mounter is going to serve this module's tree?
# Sourced (not executed) by customize.sh, post-fs-data.sh and stage_overrides.sh.
#
# KernelSU/APatch let exactly ONE "metamodule" own module mounting, and
# /data/adb/metamodule points at whichever it is. Which one is active decides how
# much work this module has to do itself:
#
#   NoMount Suite — serves EVERY top-level partition dir of a module tree, /my_*
#                   included, so there is nothing to bind at boot.
#   anything else — magic_mount, magic_mount_rs, the built-in ksud mounter and
#                   Magisk all walk <module>/system ONLY (system/product &co are
#                   then hoisted onto the real partition through the SAR
#                   symlinks). /my_* is not a partition they know about, so this
#                   module must bind those overrides itself.
#
# Testing merely for /data/adb/modules/meta-nomount is wrong: switching the
# active metamodule leaves that directory installed and enabled, so the test
# still passes, the module skips its own fallback — and nothing at all serves the
# /my_* overrides. The app_v2.xml <disable> lines then survive and the apps stay
# uninstalled even though their APKs are mounted in /product.

nomount_active() {
  _meta=/data/adb/modules/meta-nomount
  [ -d "$_meta" ] || return 1
  [ -f "$_meta/disable" ] && return 1
  [ -f "$_meta/remove" ] && return 1
  [ -f "$_meta/skip_mount" ] && return 1
  # When the root manager has the metamodule framework, its link is the only
  # authoritative answer to "who mounts modules".
  if [ -L /data/adb/metamodule ]; then
    _act=$(readlink -f /data/adb/metamodule 2>/dev/null)
    [ -n "$_act" ] || _act=$(readlink /data/adb/metamodule 2>/dev/null)
    case "${_act%/}" in
      */meta-nomount) return 0 ;;
      *)              return 1 ;;
    esac
  fi
  # No metamodule framework (Magisk, older KernelSU): installed + enabled is as
  # good an answer as there is.
  return 0
}

# Human-readable name of the active mounter, for install/action output.
active_mounter() {
  if nomount_active; then
    echo "NoMount Suite"
    return
  fi
  if [ -L /data/adb/metamodule ]; then
    _act=$(readlink -f /data/adb/metamodule 2>/dev/null)
    [ -n "$_act" ] || _act=$(readlink /data/adb/metamodule 2>/dev/null)
    case "${_act%/}" in
      # Linked but not usable: whatever mounts modules now, it is not NoMount.
      */meta-nomount) echo "meta-nomount (disabled) - built-in mounter"; return ;;
      ?*)             basename "${_act%/}"; return ;;
    esac
  fi
  echo "magic mount"
}
