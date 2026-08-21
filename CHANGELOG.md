# Changelog

## v1.6.6
- **Boot guard.** `post-fs-data.sh` counts boots and `service.sh` clears the counter once `sys.boot_completed` is set. Three boots in a row without reaching that point and the module writes its own `skip_mount` — the overlay is dropped so the device boots, instead of leaving the user in a bootloop with no way in. The Action button reports when the guard has tripped; delete `skip_mount` and `.guard_tripped` in the module directory to re-arm.

## v1.6.5
- **Fix: the module did nothing on a non-NoMount metamodule.** `post-fs-data.sh` and `stage_overrides.sh` decided "NoMount is serving this tree" from `[ -d /data/adb/modules/meta-nomount ]`. Switching the active metamodule (to `magic_mount` / `magic_mount_rs`) or disabling NoMount leaves that directory installed and enabled, so the test still passed, the `/my_*` fallback binds were skipped — and nothing served the overrides. The `app_v2.xml` `<disable>` lines then survived and OPlus' app-platform turned the apps off at boot: **the APKs were mounted in `/product` but Contacts/Messages were not installed**. Detection now reads the authoritative `/data/adb/metamodule` link (plus `disable`/`remove`/`skip_mount`) via the new `mounter.sh`.
- **Fix: the overlay was invisible to magic mount after a metamodule switch.** `ksud`'s installer moves `system/product` to the module root and leaves `system/product -> ../product`; `magic_mount_rs` keeps the real tree under `system/` instead. A module installed under one and then served by the other is in the wrong shape — magic mount collects that symlink as a symlink node and never walks it, so the APKs are never served. `post-fs-data.sh` now reconciles the layout at boot, before the metamodule mount pass runs.
- **Fix:** the magic-mount fallback registered the SuSFS/umount hides against `/system/product/...`, which is not where the files end up. It now hides the hoisted path (`/product/...`) whenever `/system/<partition>` is a symlink.
- The Action button reports the active mounter, where each of the three packages is installed from, and whether an `app_v2.xml` still disables them.

## v1.6.4
- Installer no longer prints `chcon: invalid context: 0755`. `set_perm` takes the SELinux context as its 5th argument and `customize.sh` was passing the mode again, so the `chcon` for every boot script failed (harmless — the root manager sets `u:object_r:system_file:s0` itself — but it looked like a failed install).

## v1.6.3
- **Fix: v1.6.2 staged nothing when installed over an older build, silently re-disabling Messages.** `customize.sh` generated the stripped `app_v2.xml` by reading `/my_stock/etc/config/app_v2.xml` through the live filesystem — but when a previous version of the module was already serving its override at that path, the read came back *pre-stripped*, `cmp` reported "no change", and the staged file was deleted. On reboot the new module had no override, so OxygenOS re-applied `<disable pkg="com.android.mms">` and PMS ignored the injected priv-app copy (`OplusAppConfigManager: package com.android.mms locate /product/priv-app/Mms/Mms.apk ignored.`). Only the unprivileged `/data` copy survived, so `READ_PRIVILEGED_PHONE_STATE` was never granted and **Messages died the moment it was opened** — `SecurityException` from `TelephonyManager.getUiccCardsInfo()` on the smart-decoration init thread. The call-recording extension configs had the same flaw (the flag `grep` found nothing once an override was live).
- Staging no longer decides by diffing against the live file. A path is staged when the ROM still carries the `<disable>` lines **or** when the previously installed module already staged it — the second rule is what covers the upgrade case, since the live override is precisely what hides those lines. The strip is idempotent, so re-running it over an already-stripped source is a no-op that yields the same bytes.
- Note for anyone trying to read the "real" partition file: **re-mounting the block device does not bypass a NoMount injection.** The hookless engine hijacks the inode ops vtable and the superblock is shared, so a second `mount` of the same `dm-*` device serves the injected content too (unlike a bind mount, which that trick does escape).
- Writes go through a temp file + `mv`. Under NoMount the live path *is* this module's staged file, so writing straight to the destination would truncate the very file being read.
- Staging moved into a shared `stage_overrides.sh`, and the **Action button now regenerates the overrides** — so a broken install is repaired by tapping Action + rebooting, without reinstalling.
- `update.json` bumped (it was left at v1.6.1, so the in-manager updater never offered v1.6.2).

## v1.6.2
- **Detection fix: `/my_*` overrides are no longer bind-mounted.** Previous versions bind-mounted the stripped call-recording configs and `app_v2.xml` from `post-fs-data.sh`; those binds have a `/adb/modules/...` source that Duck Detector / Reveny NativeCheck flag as a root-managed mount token (and SUSFS hiding is a no-op on a NoMount, SUSFS-free kernel). The stripped configs are now **staged into the module's own partition tree at install** (`customize.sh`) so the active mounter serves them: **hooklessly under the NoMount Suite — zero mounts, nothing for a mount scanner to see**. On NoMount, `customize.sh` also enables hookless `/my_*` (`/data/adb/nomount/my_hookless`).
- `post-fs-data.sh` now **no-ops under NoMount** (the metamodule mount pass serves the tree); the old bind-mount + SUSFS/umount hide is kept only as a **fallback for non-NoMount (Magisk/magic-mount)** setups, binding from the staged tree.
- Generation is done at install so it adapts to the device's region/firmware — re-run the **Action** button (or reinstall) after a firmware OTA to regenerate.

## v1.6.1
- `customize.sh` now **detects the partition InCallUI lives on** (via `pm path`, falling back to a priv-app dir scan) and relocates the shipped `/product` overlay to match — so the in-place overlay lands correctly on models where the dialer apps sit on `/system_ext`, `/my_stock`, etc. instead of `/product`.

## v1.6
- Ships the **full-feature** OnePlus `com.android.contacts` (74.6 MB), `com.android.incallui`, and `com.android.mms` (16.60.10) as **`/product` priv-app overlays** (in-place, privileged, SuSFS-hidden — the detection-clean method proven in earlier testing; a `/system` mount hits a `GraphicsEnvironment` crash, a `/data` install is detector-visible).
- Contacts/InCallUI use `extractNativeLibs=false` (libs in-place); Messages 16.60.10 ships its 25 extracted `.so` in `lib/arm64/`.
- Includes the matching privapp-permission files for the feature builds.
- The genuine Notes app (`com.oneplus.note`) is a separate install, not bundled.

## v1.5.1
- **Stealth:** dropped the bundled InCallUI "Notes" variant and its `service.sh` auto-install. The variant only runs as a `/data` install (it crashes mounted as a `/system` priv-app), and a `/data` package install of a phone-UID system app is visible to root/integrity detectors (Holmes "Narcissus" flagged it). Reverting to the ROM's factory InCallUI 16.21.0 is detection-clean and keeps call recording + the voicemail (Messagerie vocale) tab. Trade-off: no Notes/Remarques.

## v1.5
- **Fix:** no longer mounts an InCallUI APK in `/system`. Earlier builds shipped an older 16.20.1 that shadowed the ROM's factory 16.21.0 and failed to render the in-call screen.
- **New:** the OnePlus InCallUI **16.21.0 variant** (adds the **Notes/Remarques** call feature) is now bundled and installed to `/data` at first boot by `service.sh`. This variant is Oplus-signed but crashes when mounted as a `/system` priv-app (`GraphicsEnvironment` null-Resources at bind), so it must be a data install; if the install fails, the working factory 16.21.0 remains. Both provide call recording and the Messagerie vocale (voicemail) tab.
- `Mms` (`com.android.mms`) is still shipped — the ROM ships Google Messages, not `com.android.mms`, so it has no factory equivalent.

## v1.4
- **Fix:** removed the bundled Contacts APK. It shipped an older `com.android.contacts` 16.71.0 (from `/data/app`) that shadowed and downgraded the ROM's factory 16.80.0, causing a startup crash loop (`GraphicsEnvironment` null-Resources NPE). The `app_v2.xml` strip now enables the ROM's own firmware-matched Contacts instead.
- Trimmed the `module.prop` description.

## v1.3
- `app_v2.xml` strip extended to cover `my_stock`, `my_region`, `my_product`, `my_carrier`, `my_heytap`, `my_preload`, `my_bigball`.

## v1.2
- Added OnePlus Phone/Contacts to the module (later reverted in v1.4 — see above).

## v1.1
- `app_v2.xml` handling rewritten: instead of a static empty override, the real file is read at boot and only the three target `<disable>` lines are stripped, preserving all other stock entries.
- Refreshed InCallUI (16.21.0) and Mms (16.60.10).
- Fixed `action.sh` shebang / stray `su -c`, removed the invalid boot-time `set_perm_recursive`, guarded bind mounts, disabled `LATESTARTSERVICE` (no `service.sh`), and bundled the media/auto-recording config files the Action button expects.

## v1.0
- Initial release.
