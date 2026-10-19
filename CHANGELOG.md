# Changelog

## 2026-10-18

- Add experimental Samsung 767XCL / Lakefield 8086:9840 graphics acceleration with i915 and Mesa source patches.
- Validate hardware rendering, GNOME GPU submission, OpenGL, Vulkan and persistence after reboot on Linux 7.0.0-38-generic.
- Include source build, guarded installation, read-only verification, first-boot confirmation/recovery and removal scripts.
- Preserve firmware display and distro graphics files; document pinned-kernel and unvalidated features.
- Add per-user Sober Flatpak Vulkan extension integration and rollback; validate Intel GPU rendering, normal Roblox startup and user-reported gameplay.

## 0.1.0 — 2026-10-04

- Initial public repository structure.
- Added validated Samsung 767XCL Bluetooth fix.
- Added Intel CcP / `hci_uart` DKMS fix.
- Added Intel `ibt-20-1-3.sfi/.ddc` initramfs workaround using dracut.
- Added diagnostics and compatibility documentation.
