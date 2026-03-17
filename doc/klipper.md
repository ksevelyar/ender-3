# Klipper
* Ender 3 Pro
* SKR 1.4 Turbo
* TMC2209
* BMG clone
* 3DTouch

## Config refs
* https://github.com/Klipper3d/klipper/blob/master/config/generic-bigtreetech-skr-v1.4.cfg
* https://github.com/Klipper3d/klipper/blob/master/config/printer-creality-ender3pro-2020.cfg

## Build
```
nix build .#sdImage --max-jobs 2 --cores 2
```

## Calibration
PROBE_CALIBRATE
SAVE_CONFIG
PID_CALIBRATE HEATER=extruder TARGET=200
PID_CALIBRATE HEATER=heater_bed TARGET=60
SAVE_CONFIG
BED_MESH_CALIBRATE
SAVE_CONFIG
rotation_distance tuning
PRESSURE_ADVANCE
