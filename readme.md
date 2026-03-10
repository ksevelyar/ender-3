# Ender 3

## release 1.0
* [ ] print belt tensioner for Y axis
* [ ] migrate from armbian to NixOS
* [ ] migrate from marlin to klipper
* [ ] add doc/calibration.md

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
