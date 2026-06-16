## Why

Every selectable car drives nose-backwards: when the player accelerates, the car travels tail-first. The physics treats `-Z` as forward (correct and well-tested by `drive_test.gd`), but every Kenney car-kit GLB is authored facing `+Z`, so each car's nose points opposite the travel direction.

## What Changes

- Flip the swapped-in **visual mesh** 180° about Y in `car.gd`'s mesh swap, so every car's nose points along the vehicle's forward direction (`-Z`).
- Vehicle physics/handling is **unchanged** — `-Z` stays forward; this is a purely visual orientation fix.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `vehicle-appearance`: Add a requirement that a displayed car model's nose faces the vehicle's forward/travel direction. This extends the appearance capability (which already governs how the car looks "wherever a car model is displayed") from color-only to also covering facing, without touching handling.

## Impact

- `scripts/car.gd` — the `_ready()` mesh swap gains `mesh.rotate_y(PI)`.
- No change to `vehicle-control` (physics), `vehicle-selection`, collision, camera, or scene flow.
- Verification: `tools/orient_shot.gd` (orientation render via the GL driver) plus existing `tools/drive_test.gd` (handling) both pass.
