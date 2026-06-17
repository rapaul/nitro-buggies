## 1. Camera script: heading-relative chase

- [x] 1.1 In `scripts/camera.gd`, change the default `offset` to a car-local chase vector (behind + lower, start ~`(0, 5, 9)`).
- [x] 1.2 In `_physics_process`, compute `desired` from a yaw-only rotation of `offset`: `target.global_position + Basis(Vector3.UP, target.rotation.y) * offset`.
- [x] 1.3 Keep the existing frame-rate-independent position `lerp` and `look_at(target.global_position, Vector3.UP)` (add a small upward look offset only if framing needs it).

## 2. Scene initial pose

- [x] 2.1 Update the `Camera3D` transform in `scenes/Main.tscn` to the resting chase pose for the car's initial heading, so frame one matches the script's settled position.

## 3. Update the headless test

- [x] 3.1 In `tools/drive_test.gd._test_camera_follow`, recompute `want` as `car.global_position + Basis(Vector3.UP, car.rotation.y) * cam.offset` so the assertion matches heading-relative follow.
- [x] 3.2 Leave the stationary no-jitter check unchanged.

## 4. Verify

- [x] 4.1 `godot --headless --import` finishes with no errors/warnings.
- [x] 4.2 `godot --headless -s tools/drive_test.gd` prints PASS for all checks (accel/reverse/steer/drift/camera-follow/pause) and exits 0.
- [x] 4.3 Render a windowed screenshot of `Main.tscn` (`godot --rendering-driver opengl3 -s <shot script> -- --shot=/tmp/cam.png`) and visually confirm the third-person framing (low, behind the car, horizon visible). Tune `offset` Y/Z if needed.
