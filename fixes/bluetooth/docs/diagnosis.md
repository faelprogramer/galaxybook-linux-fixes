# Bluetooth diagnosis

## Failure state

Observed:

```text
bluetoothctl show
No default controller available
```

while:

```text
rfkill list
0: hci0: Bluetooth
    Soft blocked: no
    Hard blocked: no
```

The BlueZ service itself was active.

Kernel logs then identified the firmware failure:

```text
Bluetooth: hci0: Bootloader revision 0.3 build 0 week 24 2017
Bluetooth: hci0: Device revision is 1
bluetooth hci0: Direct firmware load for intel/ibt-20-1-3.sfi failed with error -2
Bluetooth: hci0: Failed to load Intel firmware file (-2)
```

The firmware package supplied compressed/symlinked firmware, while the exact uncompressed filename requested by the driver was not available inside initramfs.

## Evidence for initramfs ordering

`hci_uart.ko` and `btintel.ko` were present in initramfs, while `ibt-20-1-3.sfi/.ddc` were not.

After explicitly adding the firmware files to dracut and rebuilding initramfs, Bluetooth initialized successfully on the next boot.

## Useful commands

See [../../docs/collecting-logs.md](../../docs/collecting-logs.md).
