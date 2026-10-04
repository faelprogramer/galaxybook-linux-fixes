# Bluetooth — Samsung 767XCL

## What this fix addresses

Two separate problems were observed and validated on the same machine.

### 1. Intel CcP controller support

The Galaxy Book exposes the Bluetooth controller through Intel CcP / ACPI `INT33E4`, using `hci_uart` rather than a conventional USB `btusb` path.

The installer builds a narrowly-scoped DKMS `hci_uart` module for the validated Linux 7.0.0 Ubuntu kernel series.

### 2. Intel firmware missing from initramfs

The machine then reached `hci0`, but failed with:

```text
Direct firmware load for intel/ibt-20-1-3.sfi failed with error -2
Bluetooth: hci0: Failed to load Intel firmware file (-2)
```

The installed firmware package contained compressed firmware, but `hci_uart`/`btintel` were being loaded from initramfs without the requested firmware being available there.

The installer therefore:

1. ensures the Intel wireless firmware package is installed;
2. materializes exact uncompressed `ibt-20-1-3.sfi` and `ibt-20-1-3.ddc` files when only compressed versions exist;
3. creates `/etc/dracut.conf.d/99-intel-bluetooth.conf`;
4. explicitly includes both files in dracut `install_items`;
5. rebuilds the current kernel initramfs;
6. verifies the firmware is present in the rebuilt initramfs.

## Validated result

After reboot, the controller appeared normally and logs included:

```text
Found device firmware: intel/ibt-20-1-3.sfi
Firmware loaded
Found Intel DDC parameters: intel/ibt-20-1-3.ddc
Applying Intel DDC parameters completed
Setup complete
```

## Install

```bash
chmod +x install.sh
sudo ./install.sh --instalar
```

The script intentionally stops if its hardware/kernel checks do not match the validated target.

## Remove

```bash
sudo ./install.sh --remover
```

The removal path removes the DKMS module and the dracut configuration, and removes uncompressed firmware files only when this installer recorded that it created them.

## Secure Boot

The installer does not disable Secure Boot. If Secure Boot is enabled, it stops because the custom DKMS module would require an authorized signing key.

## Warning

This is low-level kernel/firmware work. Read the script before executing it.
