## Context

`car.gd` is a `CharacterBody3D` whose visual model is a `Mesh` child swapped in at `_ready` from the landing-screen selection. The mesh's basis is overwritten every physics tick by `_update_orientation` (slope tilt while grounded, tumble + self-righting while airborne), so it is the wrong parent for anything that must stay rigidly "behind the rear wheels." The physics body itself rotates on Y only.

All the state the spray needs is already produced each tick in `_physics_process`:
- `is_on_floor()` — grounded gate (the function early-returns into a ballistic branch when airborne).
- `hspeed` = `Vector2(velocity.x, velocity.z).length()` — horizontal speed.
- `lateral_speed` = `velocity.dot(right)` — sideways slide; large under handbrake drift (this is exactly the quantity the grip code bleeds toward zero).

Models differ in size across the selectable kit, and the model faces +Z visually while physics forward is `-basis.z` (so the car's **rear is +Z** in body-local space, wheels at ±X). The emitter placement must therefore be derived from the loaded mesh, not hard-coded per model.

Visual particle quality is **not** headless-verifiable; the gating logic **is**. The design splits verification accordingly.

## Decisions

### Two emitters, parented to the body root, created in code
- Create two `GPUParticles3D` nodes in `_ready` (after the mesh swap, so the AABB is available) and `add_child` them to `self` (the `CharacterBody3D`), not to `_mesh`. The root only yaws, so the emitters stay behind the rear wheels through slope tilt, jumps, and tumble.
- No `Car.tscn` edits and no `.tres`/editor resources — the node, its `ParticleProcessMaterial`, and the draw-pass mesh/material are all built in GDScript. Consistent with the project's "wire in code" convention (see the .tscn node-export and Transform3D row-major gotchas).

### Emitter placement from the mesh AABB
- Compute the model's combined AABB (as `tools/inspect_car.gd` does) once in `_ready`. Place the two emitters at the **rear** (+Z local, since forward is −Z) corners near the ground: local `(±k·half_width, aabb_min_y + small, +k·half_depth)`. Tune the `k` fractions so the emitters sit roughly at the rear wheels rather than the bounding-box corners. Deriving from the AABB keeps placement sane across every selectable model instead of being correct for only one.
- Keep the two offsets mirrored on X (left/right wheel).

### Process material (built in code)
- **Emission shape:** small box at the wheel (a few cm), so spray has a little width, not a point.
- **Direction / velocity:** backward and up in the emitter's local frame (the car drags sand up and rearward); modest initial speed with some spread and angular/scale randomness so it reads as a burst of grains, not a jet.
- **Gravity:** downward (≈ the scene's feel), so grains arc back to the surface in a short throw rather than floating.
- **Lifetime:** short (~0.4–0.7 s) and a small damping, so the trail stays near the car and doesn't carpet the world.
- **World-space emission:** particles should be left in world space once spawned (not rigidly following the emitter) so the spray **trails behind** the moving car. (Exact API — the GPUParticles `local_coords` / process flag — resolved during apply against 4.6.)
- **Draw pass:** a small `QuadMesh` with a `StandardMaterial3D` set to billboard + transparent, warm sand albedo, fading alpha over life. A tiny soft sand sprite could be generated in code if a flat quad reads too hard; start with the flat billboard and only add a generated texture if needed.

### Driving the emitters from existing state
- Define a small **speed floor** (e.g. ~3–4 m/s) and a **drift threshold** on `|lateral_speed|` (e.g. ~2 m/s).
- Each grounded tick: `emitting = hspeed > speed_floor or abs(lateral_speed) > drift_threshold`. Set it on both emitters.
- **Intensity** scales with the stronger of normalized speed and normalized slide, applied via `amount_ratio` (and/or initial-velocity scale) so a fast straight-line gives a steady plume and a hard drift throws a bigger fan. Final mapping tuned by eye against the screenshot harness.
- In the **airborne** branch (the `if not is_on_floor(): … return` at the top) and the **crest-launch** branch, set `emitting = false` before returning — no wheels on sand, no spray. A small helper called from each exit path keeps this from drifting out of sync as the function has several `return`s.

### Verification split
- **Headless (machine-checkable):** extend `tools/drive_test.gd` to assert (a) two emitter nodes exist as children of the car, (b) `emitting` is false at spawn/stationary and while airborne, and (c) `emitting` becomes true after driving forward on the ground. Physics assertions must still PASS unchanged (the effect must not touch handling).
- **Visual (human/screenshot):** new `tools/spray_shot.gd` renders a windowed frame mid-drive via `--rendering-driver opengl3`, per CLAUDE.md, for sign-off on the look. `--headless` cannot see particles, so this is the only way to check appearance.

## Risks / Trade-offs

- **Placement across models.** AABB-derived offsets approximate wheel positions; some kit models may spray slightly off. Mitigation: tune the `k` fractions against a couple of representative models in the screenshot harness; the spray is forgiving since it's behind/under the car.
- **Look isn't headless-verifiable.** Mitigated by the screenshot harness + isolating all machine-checkable behavior (existence + gating) into `drive_test.gd`.
- **Particle cost.** Two continuous emitters add draw cost. Mitigation: short lifetime, modest counts, `emitting` off whenever not moving — the common stationary/menu states cost nothing.
- **Drift double-counting.** A hard drift has both high `hspeed` and high `|lateral_speed|`; taking the max (not the sum) for intensity avoids an unnatural blowout.

## Outcome (resolved during apply)

<!-- filled in during /opsx:apply: final emitter offsets, material params, speed/drift thresholds, intensity mapping, the world-space flag actually used, and any generated sand sprite -->
