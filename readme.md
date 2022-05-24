## Ender 3

* Raspbian on [banana pi m2 zero](https://wiki.banana-pi.org/Banana_Pi_BPI-M2_ZERO)
* OctoPrint accessible via wi-fi
* [Marlin 2](/marlin) + SKR 1.4 Turbo + TMC2209
* Auto bed leveling with 3DTouch [[mount]](https://www.thingiverse.com/thing:3003725/files)
* Filament guidance with [filament guide](https://www.thingiverse.com/thing:3052488/files) and [spool roller](https://www.thingiverse.com/thing:3290358/files)

[Bill of materials with links to Aliexpress](/doc/bill-of-materials.md)

## To Do

* [External case for electronics](/case)
* replace Raspbian with Nixos

## Firmware

### Doc
* https://www.makenprint.uk/3d-printing/3d-printing-guides/skr-v1-4-marlin-2-setup-part-1/
* https://www.makenprint.uk/3d-printing/3d-printing-guides/skr-v1-4-configuration-h-marlin-2-setup-part-2/

### Generate 
* `cd marlin`
* `direnv allow`
* `platformio run`

### Update 
* copy `.pio/build/LPC1769/firmware.bin` to SD card
* plug in the sd card to the printer and power off/on it
