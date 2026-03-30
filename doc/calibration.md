# Printer calibration

## Extruder steps
1) heat hotend to 210C
2) retract 100mm
3) remove bowden

extrude 100mm at 1mm speed

## 1. Check BLTouch
Ensure the BLTouch is mounted vertically and has no wobble.

## 2. Preload silicone spacers
Tighten the bed knobs so the bed is firm.

- Silicone spacers: compress ~1/3.
- Bed screws must not be loose.

Too tight -> bed corners bend down.
Too loose -> calibration shifts after printing.

## 3. Probe the bed
Run a 5×5 probe (25 points).
Measurements are relative to the bed center.

## 4. Adjust the highest corner
Find the highest corner and lower it slightly by tightening the knob.

Repeat probing and adjustment until bed variation is ≤0.1 mm.

Always lower the highest point (compress spacers).
Do not adjust multiple corners at once.
