# Contributing

Contributions are welcome, especially reports from other Galaxy Book models.

## Before proposing a fix

Please include:

```bash
cat /sys/class/dmi/id/product_name
cat /sys/class/dmi/id/product_version 2>/dev/null || true
uname -a
lspci -nnk
lsusb
rfkill list
systemctl status bluetooth --no-pager -l
bluetoothctl show
sudo dmesg | grep -Ei 'bluetooth|hci|firmware|snd|sof|acpi|battery|suspend'
```

Remove serial numbers or other identifiers you do not want to publish.

## Status labels

A fix should be described as one of:

- **Validated** — reproduced and confirmed on stated hardware/kernel.
- **Reported working** — another user confirmed it.
- **Experimental** — plausible but not yet confirmed.
- **Diagnostic only** — gathers information; does not modify the system.

Please do not broaden model/kernel compatibility claims without evidence.
