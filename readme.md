# Ender 3

## release 1.0
* [x] add doc/calibration.md
* [ ] print belt tensioner for Y axis
* [ ] migrate from armbian to NixOS
* [ ] migrate from marlin to klipper

## NixOS
```
nix build .#sdImage
```

## Build firmware
```
cd marlin-2.1.2.5
direnv allow
pio run
```
