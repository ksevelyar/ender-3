# Ender 3

## release 1.0
* [x] add doc/calibration.md
* [ ] print belt tensioner for Y axis
* [ ] migrate from armbian to NixOS
* [ ] migrate from marlin to klipper

## NixOS
```
nix build .#sdImage

sudo dd if=result/sd-image/nixos-image-sd-card-25.11.20260304.fabb8c9-armv7l-linux.img of=/dev/sdx bs=4M status=progress conv=fsync
```

## Build firmware
```
cd marlin-2.1.2.5
direnv allow
pio run
```
