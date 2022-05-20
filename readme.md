## Ender 3

* Raspbian on [banana pi m2 zero](https://wiki.banana-pi.org/Banana_Pi_BPI-M2_ZERO)
* OctoPrint via wi-fi
* SKR 1.4 Turbo + TMC2209
* Auto bed leveling with 3DTouch

* [Filament guide](https://www.thingiverse.com/thing:3052488/files)
* [Spool roller](https://www.thingiverse.com/thing:3290358/files)
* [BlTouch mount (3mm lower version)](https://www.thingiverse.com/thing:3003725/files)

[Bill of materials with links to Aliexpress](/doc/bill-of-materials.md)

## To Do

* [External case for electronics](/case)
* replace Raspbian with Nixos

## Firmware

* https://www.makenprint.uk/3d-printing/3d-printing-guides/skr-v1-4-marlin-2-setup-part-1/
* https://www.makenprint.uk/3d-printing/3d-printing-guides/skr-v1-4-configuration-h-marlin-2-setup-part-2/

1. `platformio run`
2. copy `.pio/build/LPC1769/firmware.bin` to SD card
