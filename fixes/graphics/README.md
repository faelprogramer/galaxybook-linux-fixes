# Lakefield graphics: confirmed diagnosis and reversible mitigation

**Status: mitigation validated; GPU acceleration and Roblox gameplay unresolved.**

Tested on Samsung 767XCL, Intel Core i5-L16G7, PCI GPU `8086:9840`,
Ubuntu 26.04.1, kernel `7.0.0-38-generic`, GNOME/Wayland, on 2026-10-18.
This is not a GPU driver installer. It does not modify Bluetooth/audio fixes,
kernel modules, GRUB, initramfs or system Flatpak overrides.

## Findings

- PCI sees Intel Lakefield UHD Graphics, but the device has no driver symlink.
- `i915` is installed; its aliases and the installed kernels' `modules.alias`
  have no match for `8086:9840`. This is not evidence of a missing i915 package.
- `/dev/dri/card0` belongs to `simple-framebuffer`; no `renderD128` was present.
- GNOME logs report `Not hardware accelerated`.
- Direct EGL/OpenGL query: Mesa 26.0.8, OpenGL 4.5, renderer
  `llvmpipe (LLVM 21.1.8, 128 bits)`.
- Direct Vulkan enumeration exposes only llvmpipe, device type CPU (4).
  Having Vulkan/OpenGL libraries installed does not imply hardware acceleration.
- Sober 1.8.0 is installed system-wide with DRI device permission. A normal
  launch in the current user session reached onboarding and logged
  `ZINK: failed to choose pdev` and `egl: failed to create dri2 screen`.
- Earlier boot-journal attempts, under a different home path, additionally
  reported `Unable to create Vulkan instance` and
  `Sober couldn't find a supported graphics device`. These historical attempts
  must not be confused with the current account's installation state.
- A separate launch using the software-rendering environment below reached
  onboarding without the Zink/EGL errors during the bounded observation.
  Installation completion, login, and Roblox gameplay were **not tested**.
  This is a diagnostic fallback, not a claim that Roblox works.

The upstream Linux v7.0 PCI list and the Mesa 26.0.8 Iris PCI list consulted
also did not contain `9840`. We have not identified a validated patch or
kernel version supporting this device. `i915.force_probe=9840` only relaxes
probe gating for devices already described by the driver; it does not create
platform support. Do not substitute another GPU's ID or use `new_id` as a fix.

## Script

Run from the logged-in GNOME user's terminal, **without sudo**:

```bash
./fixes/graphics/graphics.sh --diagnosticar
./fixes/graphics/graphics.sh --aplicar
```

The first command only reads information. The second disables GNOME animations
and saves the prior explicit value (including whether it was unset) in
`${XDG_STATE_HOME:-$HOME/.local/state}/galaxybook-linux-fixes/graphics/`.
Repeated application preserves the original backup. Application refuses other
models/GPUs. This reduces animation overhead; it does not accelerate rendering.
It takes effect without rebooting.

Restore the original animation preference:

```bash
./fixes/graphics/graphics.sh --restaurar
```

Optional Sober software-rendering test:

```bash
./fixes/graphics/graphics.sh --sober-software
```

The environment applies only to that process. No persistent Flatpak override is
written. Sober itself may create configuration/cache or show its installation UI.
Close any existing Sober instance first. CPU rendering can be very slow.
The script does not install Roblox or change Sober's JSON configuration.

## Validation performed

- Shell syntax check passed.
- Diagnostic mode ran on the affected machine.
- Apply → apply again → restore recovered the original effective value `true`.
- Applied again and read back `false`; left animations disabled on the machine.
- No root privileges required and no GPU driver changes attempted.
- Subjective desktop responsiveness and gameplay remain unverified.

## What would count as a GPU fix

A compatible driver must bind to `8086:9840`, provide a render node, and produce
an Intel hardware renderer in OpenGL/Vulkan. After that, test desktop effects,
Sober installation and an actual game. A successful software-rendering launch
alone is not sufficient. A future driver experiment needs a reviewed patch,
compatible Mesa support, recovery plan and explicit discussion of screen/boot risk.

## References

- [Linux v7.0 Intel PCI IDs](https://github.com/torvalds/linux/blob/v7.0/include/drm/intel/pciids.h)
- [Linux v7.0 i915 probe logic](https://github.com/torvalds/linux/blob/v7.0/drivers/gpu/drm/i915/i915_pci.c)
- [Mesa 26.0.8 Iris PCI IDs (mirror)](https://github.com/chaotic-cx/mesa-mirror/blob/mesa-26.0.8/include/pci_ids/iris_pci_ids.h)
- [Sober troubleshooting](https://vinegarhq.org/Sober/Troubleshooting.html)
- [Mesa environment variables](https://docs.mesa3d.org/envvars.html)

## Português

O problema confirmado é falta de aceleração da GPU Lakefield `8086:9840`.
O script oferece diagnóstico, desativação reversível das animações e um teste
opcional do Sober pela CPU. **Ainda não há correção validada do driver nem
confirmação de que o Roblox execute jogos.** Não tratar este workaround como
solução completa para gráficos ou jogos.
