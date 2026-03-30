# Ender 3

## firmware
```
nix build .#klipper-firmware
```

The SKR 1.4 Turbo uses an LPC1769 microcontroller and a Smoothieware-style bootloader. This bootloader only looks for a file named exactly firmware.bin on the root of the microSD card at power-up. If it finds it, it flashes the new firmware and renames the file to FIRMWARE.CUR as proof it worked:

```
cp result/klipper.bin /run/media/ksevelyar/3D-PRINT-0/firmware.bin
```

## sd image
```
nix build .#nixosConfigurations.printer.config.system.build.sdImage --show-trace --impure
```

```
sudo dd if=result/sd-image/nixos-sd-image-24.05.20241230.b134951-armv7l-linux.img of=/dev/sdx bs=4M status=progress oflag=sync
```

## update

```
nixos-rebuild switch --flake .#printer --target-host root@printer.local --no-reexec
```
