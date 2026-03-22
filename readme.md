# Ender 3

## release 1.0
* [x] add doc/calibration.md
* [x] migrate from armbian to NixOS
* [ ] migrate from marlin to klipper
* [ ] print belt tensioner for Y axis

## firmware
```
nix build .#klipper-firmware
```

## sd image
```
nix build .#nixosConfigurations.printer.config.system.build.sdImage --show-trace --impure
```

```
sudo dd if=result/sd-image/nixos-sd-image-24.05.20241230.b134951-armv7l-linux.img of=/dev/sdx bs=4M status=progress oflag=sync
```
