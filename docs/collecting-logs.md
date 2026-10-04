# Collecting logs

For a Bluetooth report:

```bash
echo "===== DMI ====="
cat /sys/class/dmi/id/product_name
cat /sys/class/dmi/id/product_version 2>/dev/null || true

echo "===== KERNEL ====="
uname -a

echo "===== RFKILL ====="
rfkill list

echo "===== CONTROLLER ====="
bluetoothctl list
bluetoothctl show

echo "===== MODULES ====="
lsmod | grep -E 'hci_uart|btintel|btusb|bluetooth'

echo "===== INITRAMFS ====="
sudo lsinitramfs /boot/initrd.img-$(uname -r) | grep -E 'hci_uart|btintel|ibt-20-1-3'

echo "===== DMESG ====="
sudo dmesg | grep -Ei 'bluetooth|hci0|ibt-20-1-3|firmware' | tail -120
```

For other areas, include the relevant subsystem logs and describe exactly what works and what does not.
