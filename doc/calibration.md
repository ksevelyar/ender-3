# Printer calibration

## 1. Extruder steps
1) heat hotend to 210C
2) retract 100mm
3) remove bowden

extrude 100mm at 1mm speed, measure delta, adjust extruder.rotation_distance:

```
[extruder]
rotation_distance: 22.939
```

## 2. Check BLTouch
Ensure the BLTouch is mounted vertically and has no wobble.

## 3. Preload silicone spacers
Tighten the bed knobs so the bed is firm.
Silicone spacers should be compressed to ~1/3.

Too tight -> bed corners bend down.
Too loose -> calibration shifts after printing.

## 4. Adjust the bed
Run a 7×7 probe.

Adjust the highest corner, find the highest corner and lower it slightly by tightening the knob.

Repeat probing and adjustment until bed variation is <0.15 mm.

Always lower the highest point (compress spacers).
Do not adjust multiple corners at once.

## PID

```
PID_CALIBRATE HEATER=extruder TARGET=200
```
