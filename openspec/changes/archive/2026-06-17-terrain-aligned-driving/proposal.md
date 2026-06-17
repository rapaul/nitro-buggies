## Why

The car now drives over sculpted dune terrain, but its body stays rigidly level with the horizon — it follows the terrain's *height* yet never pitches or rolls to match the slope under its wheels, so it looks like it's sliding across glass rather than driving on sand. At the same time, the chase camera reads the car's heading and position raw each frame, so sharp steering and cresting dunes make it whip and bob behind the car instead of trailing steadily.

## What Changes

- The car's visual orientation tilts to approximate the terrain slope beneath it, so its wheels sit on the surface and it pitches up climbing a dune face and rolls along a side-slope, instead of staying level with the horizon.
- The tilt eases smoothly between surface angles while grounded, so it never snaps between adjacent terrain facets.
- While airborne the car retains some of its takeoff angular momentum — it keeps rotating in the air — but rights itself like a cat, so it always lands wheels-down regardless of its takeoff angle.
- Vehicle *handling* (acceleration, steering, grip, jump launch, frame-rate independence) is unchanged — physics integration stays in the horizontal plane and the tilt is presentation only.
- The chase camera follows with damped heading and a damped look-at target so it eases behind the car during sharp turns and over dune crests rather than jerking, while still tracking promptly enough to keep the car framed.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `vehicle-control`: adds requirements that the grounded vehicle's orientation approximates the terrain slope (pitch and roll) eased smoothly, and that while airborne the vehicle retains some takeoff angular momentum but self-rights to always land wheels-down — without altering existing handling behavior.
- `top-down-camera`: strengthens the smooth-follow requirement so the camera does not jerk or whip during sharp steering or while the car bobs over dune crests.

## Impact

- `scripts/car.gd` — derive a target orientation from the floor normal and ease the visual mesh toward it each physics tick; relax toward level while airborne.
- `scripts/camera.gd` — damp the heading used for the chase offset and damp the look-at target.
- `tools/drive_test.gd` — extend the behavioral harness to assert terrain-aligned tilt while grounded, relaxation while airborne, and steadier camera tracking.
- No new dependencies; `DuneHeight` remains the single source of terrain shape.
