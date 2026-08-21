# OnePlus Dialer & Messages (Android 16)

[![Build module](https://github.com/Bouteillepleine/OnePlus_Dialer_Universal/actions/workflows/build.yml/badge.svg)](https://github.com/Bouteillepleine/OnePlus_Dialer_Universal/actions/workflows/build.yml)

A KernelSU / Magisk module that re-enables the **OnePlus Phone (Contacts), Dialer (InCallUI) and Messages (Mms)** apps — with **call recording** — on OxygenOS 16 builds where the region firmware ships them disabled.

Tested on the **OnePlus 15 (CPH2747)** with the NoMount Suite, and on the **OnePlus 11 (CPH2449, OOS 16.0.5.1002)** with magic_mount_rs.

---

## What it does

OxygenOS ships the ColorOS Contacts / InCallUI / Mms on the firmware but marks them `<disable>` in `app_v2.xml` on global/EU/carrier builds, so the phone falls back to Google Phone/Messages and the OnePlus call-recording dialer is unavailable.

1. **Re-enables the built-in apps** by reading the real `app_v2.xml` at boot and stripping only four `<disable>` lines: `com.android.contacts`, `com.android.incallui`, `com.android.mms` and `com.oplus.blacklistapp`. Every other stock entry is preserved. The blocklist app is included because the Messages settings screen hard-depends on its `com.oplus.provider.BlackListProvider` — without it, opening Réglages throws. Done across `my_stock`, `my_region`, `my_product`, `my_carrier`, `my_heytap`, `my_preload`, `my_bigball`.
2. **Enables call recording** by stripping the recording-restriction flags (`no_display_record`, `not_support_record`, `support_record_prompt`, `disable_ted_function`) from the vendor extension configs.
3. **Overlays the full-feature Phone/Contacts, InCallUI and Messages** onto their `/product/priv-app` locations, with the matching privapp-permission files.
4. Applies the OPlus media-controller and auto-recording preference configs, and disables the safe-media-volume cap.

It does **not** ship a BlackListApp APK. Both tested ROMs already have one in `priv-app`; mounting another model's build of a privileged app over it bootloops the device, because the `privapp-permissions` allowlist is per-firmware.

---

## How it is served

One mounter owns module mounting, and which one it is changes what the module does. The active metamodule is `/data/adb/metamodule`.

| Setup | Overlay | `/my_*` overrides | Notes |
|---|---|---|---|
| **NoMount Suite** | hookless VFS injection, **zero mounts** | staged into the module tree, served hooklessly | every process sees the module's build, including the apps themselves |
| **magic mount / magic_mount_rs / ksud / Magisk** | real mounts | bound from `tmp/` at boot (v1.6.1 behaviour) | see the umount note below |

**Umount modules.** KernelSU strips *every* module mount from an app's own mount namespace when its App Profile has *Umount modules* on. Two consequences on a magic-mount setup:

- Contacts and InCallUI keep working, but the app runs the **ROM's** APK, not the module's build.
- A package the ROM does **not** ship (`com.android.mms` on some firmware) would have no APK at its own code path at all, and dies at bind with `NullPointerException … GraphicsEnvironment.queryAngleChoice`. For that case the module also installs the APK to `/data` after boot, from its own directory. Because the mounted system copy is still there, PMS records it as an `UPDATED_SYSTEM_APP`, so it keeps `PRIVILEGED` — the app can see its APK *and* hold `READ_PRIVILEGED_PHONE_STATE`, which its settings screen needs. This never runs under NoMount.

**Hiding.** Every mount the module makes is registered with SuSFS (`add_sus_mount`, plus an `add_sus_kstat`/`update_sus_kstat` pair so a bind does not report a foreign `st_dev`) and with `ksud kernel umount`. All of it is best-effort and silently does nothing on a kernel without SuSFS. A served APK is never registered for per-app umount — hiding a package's own code path from that package cannot work.

---

## Boot guard

If the device fails to finish booting **three times in a row**, the module turns itself off: it writes its own `skip_mount`, so the next boot comes up without the overlay instead of looping. `service.sh` clears the counter as soon as `sys.boot_completed` is set, so ordinary reboots never count towards it. The Action button reports a tripped guard; delete `skip_mount` and `.guard_tripped` from the module directory to re-arm it.

---

## Install

1. Flash the zip in the **KernelSU** or **Magisk** manager (or `ksud module install <zip>`).
2. Reboot.
3. If an app still misbehaves on first boot, run the module's **Action** button once, then reboot.

There is **no in-manager update check** — the module ships no `updateJson`, so nothing is ever advertised to users. Updates are manual: download a release and flash it.

---

## The Action button

Clears dalvik/oat/app caches, clears the ported apps' data (your SMS/MMS are kept), reapplies the media + auto-recording configs, and restarts the relevant services.

---

## Credits

- Module by **XxxY**.
- OnePlus / OxygenOS system apps and configs are property of **OPlus / OnePlus** and are redistributed here for interoperability on owned devices.

## Disclaimer

For personal use on your own device. The bundled APKs are proprietary OnePlus components; you are responsible for your own use. No warranty — flashing system modules can cause boot issues; keep a backup.
