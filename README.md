# OnePlus Dialer & Messages (Android 16)

Re-enables the OnePlus **Phone (Contacts)**, **Dialer (InCallUI)** and **Messages (Mms)** apps, with **call recording**, on OxygenOS 16 builds that ship them disabled.

Tested on OnePlus 15 (CPH2747) and OnePlus 11 (CPH2449).

## What it does

- Strips the `<disable>` lines for `com.android.contacts`, `com.android.incallui`, `com.android.mms` and `com.oplus.blacklistapp` from `app_v2.xml`.
- Strips the call-recording restriction flags from the vendor extension configs.
- Overlays the full-feature Contacts (16.85.10), InCallUI (16.23.0) and Messages (16.60.10) onto the partition the ROM keeps them on, with their privapp-permission files.
- Applies the OPlus media-controller and auto-recording configs.
- Installs the OPlus comms RROs (`/product/overlay`) so the framework's default phone, SMS and system-contacts apps point at the OnePlus builds rather than Google's.
- Declares the `com.google.android.apps.dialer.call_recording_audio` feature (`/product/etc/sysconfig`), which ROW/EU/GB/US firmware omits, so Google Phone can record too.
- Mutes Google Phone's spoken recording prompt by zeroing its downloaded prompt WAVs in place, at boot and on the Action button. The OnePlus dialer's own prompt is already handled by the config strip.

## Notes

- Works with or without NoMount. **NoMount Suite**: served hooklessly, zero mounts. **Magisk / plain KernelSU magic mount**: real bind mounts, `/my_*` bound at boot, registered with SuSFS where available.
- With KernelSU *Umount modules* on, an app cannot see module mounts. A package the ROM does not ship is therefore also installed to `/data`, where it stays privileged as an `UPDATED_SYSTEM_APP`.
- Mounts are registered with SuSFS and `ksud kernel umount` where available.
- **Boot guard**: three failed boots in a row and the module writes its own `skip_mount` and stops mounting. Delete `skip_mount` and `.guard_tripped` to re-arm.
- No update check — flash releases manually.
- The module card shows ✅ once the overlay is live, or ⛔ if the boot guard tripped. The Action button clears dalvik/app caches and re-applies the configs.

## Install

Flash the zip in KernelSU or Magisk, reboot. If an app misbehaves, run the module's Action button once and reboot.

## Credits

Module by **XxxY**. OnePlus / OxygenOS components are property of OPlus / OnePlus, redistributed for interoperability on owned devices. No warranty.
