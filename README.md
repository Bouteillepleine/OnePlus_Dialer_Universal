# OnePlus Dialer & Messages (Android 16)

OxygenOS 16 ships the OnePlus **Phone** and **Dialer** but switches them off, has no **Messages** app, and blocks **call recording** outside a few regions. This module undoes all three.

Tested on OnePlus 15 (CPH2747) and OnePlus 11 (CPH2449).

## What it does

- Turns the ROM's own Phone, Dialer and BlackList apps back on, by stripping their `<disable>` lines from `app_v2.xml` at boot.
- Adds Messages (`com.android.mms`), the one app the ROM genuinely does not ship, with the privileged permissions it needs.
- Unlocks call recording, in the OnePlus dialer and in Google Phone, and silences both of their "this call is being recorded" prompts.
- Points the system's default phone, SMS and contacts apps at the OnePlus ones instead of Google's.

## Install

Flash in KernelSU or Magisk, reboot. If an app misbehaves, tap the module's Action button once and reboot — it clears the dalvik/app caches and re-applies the configs.

## Notes

- Works with or without NoMount. Under **NoMount Suite** it is served hooklessly with zero mounts; under **Magisk / plain KernelSU** it bind-mounts, registered with SuSFS where available.
- **v2.0 bundles no Phone/Contacts APKs.** The ROM's copies are enabled instead — on older OxygenOS 16 builds those are simply older versions. Shipping our own stopped being safe once the ROM caught up to the same versionCodes: two builds of one version collide over the ROM's overlay and the app crash-loops. **v1.9** is the last release with them bundled, for a ROM that ships neither.
- **Boot guard**: three failed boots and the module disables its own overlay. Delete `skip_mount` and `.guard_tripped` to re-arm.
- The card shows ✅ once live, ⛔ if the boot guard tripped. No update check — flash releases manually.
- OnePlus has its own path to the same two apps, `*#*#677776#*#*`, which force-installs Contacts and InCallUI and nothing else. It is region-gated and does not cover Messages, recording or the defaults.

## Credits

Module by **XxxY**. OnePlus / OxygenOS components are property of OPlus / OnePlus, redistributed for interoperability on owned devices. No warranty.
