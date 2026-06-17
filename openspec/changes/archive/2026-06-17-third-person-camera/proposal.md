## Why

The current camera frames the car from a high overhead angle that reads as top-down. A lower, behind-the-car third-person chase view is more immersive for a driving game and gives a stronger sense of speed and heading.

## What Changes

- Replace the fixed high-angle world-space camera offset with a third-person chase camera that sits lower and closer behind the car.
- Make the camera follow the car's **heading**: the chase position is computed relative to where the car is facing, so the camera swings around to stay behind the car as it turns.
- Lower the look angle so the horizon is visible rather than looking nearly straight down.
- Keep the existing smoothed follow (no rigid snapping) and stable-when-stationary behavior.
- Update the camera-follow assertions in `tools/drive_test.gd` to account for the new heading-relative offset.
- **BREAKING** (behavioral): camera framing changes from top-down to third-person; the `top-down-camera` capability is repurposed accordingly. Its folder name is retained to avoid spec churn.

## Capabilities

### New Capabilities

(none)

### Modified Capabilities
- `top-down-camera`: framing changes from a high-angle top-down view to a third-person chase view that follows behind the car's heading. Smooth-follow and no-jitter requirements are retained; the high-angle/top-down framing requirement is replaced.

## Impact

- `scripts/camera.gd` — chase-offset computation relative to car heading; lower angle.
- `scenes/Main.tscn` — initial `Camera3D` transform updated to the new third-person pose.
- `tools/drive_test.gd` — `_test_camera_follow` expected-position math updated for heading-relative offset.
- No new dependencies. Frame-rate-independent smoothing approach is unchanged.
