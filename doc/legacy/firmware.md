# Firmware

## Configure
* https://www.makenprint.uk/3d-printing/3d-printing-guides/skr-v1-4-marlin-2-setup-part-1/
* https://www.makenprint.uk/3d-printing/3d-printing-guides/skr-v1-4-configuration-h-marlin-2-setup-part-2/

## Generate
* `cd marlin`
* `direnv allow`
* `platformio run`

## Update
* copy `.pio/build/LPC1769/firmware.bin` to an SD card
* plug in the SD card to the printer and power off/on it
