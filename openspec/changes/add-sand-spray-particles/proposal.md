## Why

The car drives over a golden sand sea but leaves no trace — no spray, no wake, nothing to sell the surface as loose sand or to reward drifting. Kicking up sand behind the rear wheels is the cheapest, highest-impact piece of motion feedback we can add: it makes speed legible, makes the handbrake drift feel like it bites, and ties the car visually to the dune material the prior lighting work invested in.

The car already computes everything the effect needs every physics tick — `is_on_floor()`, horizontal speed (`Vector2(velocity.x, velocity.z).length()`), and lateral slide (`velocity.dot(right)`, the same quantity the grip/drift code bleeds off). So the emitters only need to be toggled and scaled from state that exists; no new physics or input.

## What Changes

- Add **two `GPUParticles3D` sand-spray emitters**, one behind each rear wheel, created and configured **entirely in code** in `car.gd` (`_ready`) — no `Car.tscn` edits and no editor-authored `ParticleProcessMaterial` or draw-pass resource. This follows the project convention of wiring nodes in code rather than the scene file.
- Parent the emitters to the **`CharacterBody3D` root, not the `Mesh`**, because the mesh's basis is rewritten every frame for slope tilt and airborne tumble; the root only yaws, so "behind the rear wheels" stays put.
- Build the process material in code: a small emission volume at each rear wheel, spray directed **backward and up**, gravity pulling grains back to the ground in a short arc, a warm sand color, and short particle lifetime so the trail stays close to the car.
- Emit **only while grounded and either moving above a small speed floor or sliding sideways (drifting)**. Spray **intensity scales** with how fast the car is going and how hard it is drifting, using the existing `hspeed`/`lateral_speed` values. No spray while airborne, stopped, or rolling slowly.
- Verify the visible effect with a windowed screenshot harness (`--rendering-driver opengl3`); add **headless assertions** that the two emitters exist and that `emitting` follows grounded/moving/drifting state, so the gating logic is machine-checkable even though pixels are not.

Out of scope: tyre skid decals/marks on the terrain; dust/exhaust unrelated to wheel contact; per-surface particle variation (only one sand surface exists); audio; editor-authored particle resources; any change to handling, collision, input, or the car's physics forward direction.

## Capabilities

### New Capabilities
- `vehicle-effects`: motion-driven visual feedback emitted by the player vehicle. This change establishes it with the sand-spray-from-rear-wheels requirement (two trails, grounded-and-moving/drifting gating, intensity tied to speed and slide, presentation-only).

### Modified Capabilities
<!-- none -->

## Impact

- `scripts/car.gd` — create and configure two `GPUParticles3D` emitters + their `ParticleProcessMaterial` and draw pass in `_ready`; toggle `emitting` and scale intensity in `_physics_process` from existing `is_on_floor()` / `hspeed` / `lateral_speed` state. The airborne early-return path must also stop the spray.
- `tools/drive_test.gd` — extend with assertions that the two emitters exist as children of the car and that `emitting` is false when airborne/stopped and true when grounded-and-moving (gating is headless-verifiable; appearance is not).
- `tools/spray_shot.gd` *(new)* — windowed (`opengl3`) screenshot harness that drives the car briefly and renders a frame, for visual sign-off of the spray look. Follows the `tools/landing_shot.gd` / `tools/dunes_shot.gd` pattern.
- **No change** to `scenes/Car.tscn`, `scenes/Main.tscn`, collision, input, or the physics integration. The effect is purely presentational, like the mesh tilt.
- No new dependencies; Godot 4.6.x only.
