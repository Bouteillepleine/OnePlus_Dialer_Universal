# Changelog

## v1.6.5
- Do not ship a BlackListApp APK; mounting another model's build over the ROM's own bootloops the device. The `app_v2.xml` strip alone enables it.

## v1.6.4
- Install a package the ROM does not ship to `/data` as well, so it survives KernelSU's per-app umount and keeps `PRIVILEGED`.

## v1.6.3
- Never register a served APK for per-app umount.

## v1.6.2
- Boot guard: three failed boots and the module disables its overlay.
- Serve `/my_*` hooklessly under NoMount, bind everywhere else.
- Fixed hide paths (`/product/…`, not `/system/product/…`) and added `add_sus_kstat` spoofing.

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
