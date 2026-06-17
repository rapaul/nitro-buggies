## 1. Car terrain-slope orientation (scripts/car.gd)

- [x] 1.1 Add a `tilt_smoothing` export (grounded per-tick ease rate) and an `air_righting` export (airborne self-righting strength).
- [x] 1.2 Keep a reference to the `Mesh` child after it is built in `_ready`, and preserve its existing `rotate_y(PI)` flip as the heading-flip applied on top of the tilt.
- [x] 1.3 In `_physics_process`, after `move_and_slide()` resolves, compute the target surface normal: `get_floor_normal()` while grounded, `Vector3.UP` while airborne.
- [x] 1.4 Build the target world basis with up = surface normal and forward = car heading projected onto the plane perpendicular to that normal (orthonormalized).
- [x] 1.5 Convert the target basis into the mesh's local space (divide out the body's yaw basis) and re-apply the 180° heading flip.
- [x] 1.6 While grounded, ease the mesh's current basis toward the target via quaternion `slerp` at `tilt_smoothing * delta` (clamped 0..1), so it never snaps between facets.
- [x] 1.7 At takeoff (crest-launch branch / first airborne tick), capture the mesh's current angular velocity as carried airborne angular momentum.
- [x] 1.8 While airborne, advance the mesh orientation by the retained angular momentum plus an `air_righting` bias toward level that grows over the flight, and apply a firm align-to-surface on the landing tick so the car is always wheels-down when it touches down.

## 2. Steady chase camera (scripts/camera.gd)

- [x] 2.1 Add a smoothed yaw that `lerp_angle`s toward `target.rotation.y`, and use it (instead of raw `target.rotation.y`) to rotate the chase offset.
- [x] 2.2 Add a smoothed aim point that lerps toward `target.global_position`, and `look_at` that point instead of the raw car position.
- [x] 2.3 Expose separate heading/aim smoothing constants (exports) alongside the existing position `smoothing`.

## 3. Behavioral verification (tools/drive_test.gd)

- [x] 3.1 Assert that after driving up a dune face while grounded, the mesh's up-axis is tilted away from world-up (pitched into the slope), not level.
- [x] 3.2 Assert that handling is unchanged: re-run an existing accel/steer sequence and confirm body position and heading match the pre-change result within tolerance (tilt is mesh-only).
- [x] 3.3 Assert that the airborne car carries rotation: launched while tilted, the mesh orientation keeps changing in the air rather than snapping instantly to level.
- [x] 3.4 Assert that the car always lands wheels-down: regardless of takeoff tilt, on the landing tick the mesh up-axis is approximately aligned with world-up / the surface normal.
- [x] 3.5 Assert the camera tracks without whipping: through a sharp turn the camera's heading change per tick stays bounded (eased), and the car stays within frame.

## 4. Validate

- [x] 4.1 Run `godot --headless --import` — finishes with no error/warning.
- [x] 4.2 Run `godot --headless -s tools/drive_test.gd` — all assertions PASS, exit 0.
- [x] 4.3 Render a windowed screenshot of the car on a dune face and confirm visually that it sits tilted on the slope with the camera trailing steadily.
