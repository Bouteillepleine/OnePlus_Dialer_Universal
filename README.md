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
3. **Ships InCallUI + Mms** as system priv-apps for firmwares that don't already include them, with the matching `privapp-permissions-oplus.xml` and `package-shareduid-allowlist.xml` (InCallUI joins `android.uid.phone`).
4. Applies the OPlus media-controller and auto-recording preference configs, and disables the safe-media-volume cap.

> **Note:** the module does **not** ship a Contacts APK. The ROM's own factory Contacts is the correct, firmware-matched build — the module only un-disables it. (Shipping a mismatched Contacts copy is what caused the crash fixed in v1.4.)

All bind mounts are registered with **SuSFS** (`add_sus_mount` / `add_try_umount`) and KernelSU `ksud kernel umount` so the overlay is hidden.

---

## Install

1. Flash the zip in the **KernelSU** or **Magisk** manager (or `ksud module install <zip>`).
2. Reboot.
3. If an app still shows a stale icon or misbehaves on first boot, run the module's **Action** button once, then reboot.

Requires root (KernelSU recommended; Magisk works). SuSFS is optional — the module degrades gracefully without it.

---

## The Action button

Tapping the module's Action in the KernelSU manager clears dalvik/oat/app caches, clears the ported apps' data (your SMS/MMS are kept), reapplies the media + auto-recording configs, and restarts the relevant services. Use it to recover a stuck app after (re)install.

---

## Credits

- Module by **YxxX**.
- OnePlus / OxygenOS system apps and configs are property of **OPlus / OnePlus** and are redistributed here for interoperability on owned devices.

## Disclaimer

For personal use on your own device. The bundled APKs are proprietary OnePlus components; you are responsible for your own use. No warranty — flashing system modules can cause boot issues; keep a backup.
