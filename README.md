# OnePlus Dialer & Messages (Android 16)

[![Build module](https://github.com/Bouteillepleine/OnePlus_Dialer_Universal/actions/workflows/build.yml/badge.svg)](https://github.com/Bouteillepleine/OnePlus_Dialer_Universal/actions/workflows/build.yml)
[![Latest release](https://img.shields.io/github/v/release/Bouteillepleine/OnePlus_Dialer_Universal)](https://github.com/Bouteillepleine/OnePlus_Dialer_Universal/releases/latest)

A KernelSU / Magisk module that re-enables the **OnePlus Phone (Contacts), Dialer (InCallUI) and Messages (Mms)** apps — with **call recording** — on OxygenOS 16 builds where the region firmware ships them disabled.

Tested on the **OnePlus 15 (CPH2747)**, OxygenOS 16 (Android 16). Should work on other OnePlus / OPPO / Realme devices that use the same `my_stock` / `my_region` app-platform layout.

---

## What it does

OxygenOS ships the ColorOS Contacts / InCallUI / Mms on the firmware but marks them `<disable>` in `/my_stock/etc/config/app_v2.xml` (and the other extension partitions) on global/EU/carrier builds, so the phone falls back to Google Phone/Messages and the OnePlus call-recording dialer is unavailable.

This module:

1. **Re-enables the built-in apps** by reading the real `app_v2.xml` at boot and surgically stripping only the three `<disable>` lines for `com.android.contacts`, `com.android.incallui` and `com.android.mms` — every other stock entry is preserved. Done dynamically across `my_stock`, `my_region`, `my_product`, `my_carrier`, `my_heytap`, `my_preload`, `my_bigball`, so it stays correct across regions and firmware versions.
2. **Enables call recording** by stripping the recording-restriction flags (`no_display_record`, `not_support_record`, `support_record_prompt`, `disable_ted_function`) from the vendor extension configs and bind-mounting the result back.
3. **Overlays the full-feature Phone/Contacts, InCallUI and Messages** onto their `/product/priv-app` locations (in-place), with the matching privapp-permission files. Overlaying in place keeps a single codePath so the apps stay privileged and don't hit the `GraphicsEnvironment` null-Resources crash that a second `/system` copy triggers, and it's a SuSFS-hideable mount (no detector-visible `/data` install).
4. Applies the OPlus media-controller and auto-recording preference configs, and disables the safe-media-volume cap.

**Native libs:** the Contacts/InCallUI builds use `extractNativeLibs=false` (libs mmap'd from inside the APK, no `lib/` dir needed); Messages (16.60.10) uses `extractNativeLibs=true`, so its 25 `.so` are shipped extracted in `lib/arm64/`.

The **Notes/Remarques** tab needs the genuine **`com.oneplus.note`** app installed (not the look-alike `com.coloros.note`); it is a separate install, not bundled here.

All bind mounts are registered with **SuSFS** (`add_sus_mount` / `add_try_umount`) and KernelSU `ksud kernel umount` so the overlay is hidden.

---

## Install

1. Flash the zip in the **KernelSU** or **Magisk** manager (or `ksud module install <zip>`).
2. Reboot.
3. If an app still shows a stale icon or misbehaves on first boot, run the module's **Action** button once, then reboot.

Requires root (KernelSU recommended; Magisk works). SuSFS is optional — the module degrades gracefully without it.

### Alternative: install the APKs manually

The bundled APKs (`system/product/priv-app/*/*.apk`) are self-contained and can also just be **sideloaded to `/data`** instead of flashing the module — e.g. via a package installer, `adb install -r <apk>`, or App Manager. Notes:

- All are **Oplus platform-signed**, so they install cleanly over the ROM's copies (same signature).
- You still need the module (or a manual `app_v2.xml` edit) to **un-disable** `com.android.contacts` / `incallui` / `mms` and to enable **call recording** — the APKs alone don't do that.
- A `/data` install is **visible to root/integrity detectors** (Holmes etc.), whereas the module's `/product` overlay is SuSFS-hideable. If you run an auto-updater (APKUpdater/App Manager auto-install), it tends to install these to `/data` anyway and will shadow the module overlay.
- The **Notes/Remarques** tab needs the genuine **`com.oneplus.note`** app installed alongside (it is not bundled in this module).

---

## The Action button

Tapping the module's Action in the KernelSU manager clears dalvik/oat/app caches, clears the ported apps' data (your SMS/MMS are kept), reapplies the media + auto-recording configs, and restarts the relevant services. Use it to recover a stuck app after (re)install.

---

## Credits

- Module by **YxxX**.
- OnePlus / OxygenOS system apps and configs are property of **OPlus / OnePlus** and are redistributed here for interoperability on owned devices.

## Disclaimer

For personal use on your own device. The bundled APKs are proprietary OnePlus components; you are responsible for your own use. No warranty — flashing system modules can cause boot issues; keep a backup.
