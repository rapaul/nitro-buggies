## Context

`scripts/camera.gd` is a `Camera3D` that follows `$Car` (wired in `scripts/main.gd._ready`). Each `_physics_process`, it lerps its position toward `target.global_position + offset` and calls `look_at(target.global_position)`. The current `offset` is a **fixed world-space vector** `(0, 18, 11)` — a high overhead angle — so the camera never rotates relative to the car's heading. The initial pose is also baked into `scenes/Main.tscn`'s `Camera3D` transform.

`tools/drive_test.gd._test_camera_follow` asserts the camera eases to `car.global_position + cam.offset` (world-space) and is jitter-free when stationary.

The user has chosen a **chase camera** that swings around to stay behind the car's heading.

## Goals / Non-Goals

**Goals:**
- Camera reads as third-person: low, close, behind the car, horizon visible.
- Chase position tracks the car's heading (yaw), so the camera stays behind the car as it turns.
- Preserve smoothed, frame-rate-independent follow and no-jitter-when-stationary behavior.
- Keep the headless drive test green by updating its expected-position math.

**Non-Goals:**
- No collision/occlusion handling (camera clipping through walls) — there are no walls.
- No user-configurable camera, FOV changes, or speed-based pull-back.
- No camera pitch following the car on slopes (ground is flat).

## Decisions

**Decision: Heading-relative offset computed each frame.**
Define `offset` as a car-local vector (behind + above, e.g. `(0, ~5, ~9)` in car space). Each frame, rotate it by the car's yaw and add to the car's position:
```
var basis_yaw := Basis(Vector3.UP, target.rotation.y)
var desired := target.global_position + basis_yaw * offset
```
Then `look_at` a point at/slightly above the car. Rotating only by yaw (not full basis) keeps the camera level even if the car pitches/rolls.
- *Alternative considered:* use `target.global_transform.basis * offset` (full orientation). Rejected — couples camera tilt to car tilt, causing roll/sway; yaw-only is steadier.
- *Alternative considered:* fixed world-space offset at a lower angle (no rotation). Rejected per user choice — does not give the chase feel.

**Decision: Smooth both position and the look target.**
Position keeps the existing `lerp(desired, smoothing*delta)`. Because `desired` now rotates with the car, fast turns move it quickly; the existing smoothing softens the swing. Look at the car each frame (optionally a small height offset so the car sits lower in frame).
- *Alternative considered:* also lerp the look-at point separately. Deferred — single-target `look_at` is simpler and reads fine; revisit only if the swing feels abrupt.

**Decision: Lower the angle via the offset's Y/Z ratio.**
Reduce height and keep meaningful distance behind (e.g. from `(0,18,11)` to roughly `(0,5,9)`), tuned by screenshot. Update `Main.tscn`'s baked `Camera3D` transform to a matching starting pose so frame one isn't jarring before smoothing settles.

**Decision: Update the drive test to mirror the new math.**
`_test_camera_follow` recomputes `want` as `car.global_position + Basis(Vector3.UP, car.rotation.y) * cam.offset`. Reuse `cam.offset` (still exported) so the test stays coupled to the script's actual value rather than a hardcoded vector. Stationary jitter check is unchanged.

## Risks / Trade-offs

- **Heading-relative camera can feel disorienting at low speed or when reversing** (the view swings as the car spins in place) → keep `smoothing` modest so swings ease in; tune offset distance; reversing still points camera along heading which is acceptable for this game.
- **Visual tuning is subjective and not headless-verifiable** → use `tools/landing_shot.gd`-style windowed render (`--rendering-driver opengl3`) to screenshot the gameplay scene and eyeball the framing, per CLAUDE.md.
- **Test coupling to `rotation.y`** → if the car's yaw convention differs from expectation, the test catches a mismatch. Verify against `inspect_car.gd`/existing orientation if the follow test fails.
- **Frame-one pop** if `Main.tscn` transform and script offset disagree → set the baked transform to the resting chase pose for the car's initial heading.
