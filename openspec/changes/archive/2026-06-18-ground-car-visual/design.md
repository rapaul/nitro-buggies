## Context

The car is a `CharacterBody3D` with a flat, axis-aligned `BoxShape3D` collision (1.3 × 0.73 × 2.56 m, bottom at the body origin). The body only yaws; the visual mesh child is tilted/tumbled separately as pure presentation (`car.gd:_update_orientation`). Terrain comes from `DuneHeight` (`scripts/dune_height.gd`), the single source of truth shared by the visual mesh, the collision heightmap, and tests.

Measured root cause (headless probe, settling the car at several spots):

| spot | body gap above terrain | mesh-bottom gap |
|------|------|------|
| valley floor (40, 52.5) | 0.04 m | ~0.00 m |
| slope (20, 35) | 0.42 m | 0.04 m |
| slope (35, 60) | 0.40 m | 0.09 m |

On a slope the horizontal flat box bottom touches the heightmap only at its uphill edge, lifting the body (and the anchored mesh) ~0.4 m above the surface beneath the car's center. The shadow, cast from the real geometry, lands on the true surface — so the car hovers over its shadow.

## Goals / Non-Goals

**Goals:**
- Close the visible gap so the grounded car rests on the sand and meets its shadow, including on slopes.
- Keep the fix purely visual; leave the tuned, frame-rate-independent handling and the drive_test untouched.
- Source the grounding height from `DuneHeight` so visual, collision, and grounding stay locked together.

**Non-Goals:**
- Changing the collision shape, floor snapping, jump/launch, or `is_on_floor()` behavior.
- Per-wheel suspension or making the box conform to the terrain.
- Touching the sand-spray emitters' tuning (note: they hang off the same body and float by the same amount — see Risks).

## Decisions

### Decision: Lower the visual mesh to the sampled terrain, not the physics body
Apply a vertical offset to the mesh's local position so its base (mesh AABB min-y = 0 at the body origin) sits on `DuneHeight.height(x, z)` sampled under the car. Offset = `terrain_y - body_global_y` while grounded.

- **Why:** The codebase already treats the mesh as presentation and the body as yaw-only physics. A visual offset closes the gap with zero risk to handling, and naturally rides the existing slope tilt (the mesh is already tilted to the slope, so dropping its center onto the surface seats the wheels). `_set_mesh_rotation` writes only the basis, so mesh `position.y` is ours to control independently.
- **Alternative — snap the physics body Y to terrain:** grounds everything (mesh, emitters, shadow) at once, but perturbs `is_on_floor()`, floor snapping, and the crest-launch logic that the handling and drive_test depend on. Rejected as too risky for a visual bug.
- **Alternative — fake blob/contact shadow under the car:** a decal grounds it visually, but the scene already has a real cast shadow; adding a blob would conflict and doesn't actually place the car on the ground as requested. Rejected.

### Decision: Apply only while grounded, and ease the offset
Compute the target offset only when `is_on_floor()`; airborne, the target is 0 so the mesh follows the body's ballistic height (and the shadow rises with it). Ease the offset toward its target using the existing `tilt_smoothing` cadence (the same `clampf(tilt_smoothing * delta, 0, 1)` lerp used for tilt), so the small frame-to-frame variation in `body_global_y` doesn't make the mesh jitter, and landing blends rather than pops.

- **Why:** Mirrors how mesh *rotation* is already eased/blended on the ground-vs-air boundary; keeps one consistent presentation model.

### Decision: Verify with a headless grounding probe plus a screenshot
Add `tools/ground_test.gd`: settle the car at flat, sloped, and valley spots and assert `mesh_bottom - DuneHeight ≈ 0` within a tight tolerance (e.g. ≤ 0.05 m), and assert it is not pinned mid-air after a launch. Re-run `tools/drive_test.gd` (must stay PASS) and a `main_shot` windowed screenshot to confirm the car meets its shadow.

## Risks / Trade-offs

- **Downhill wheels still hover slightly on steep slopes** (seating the center can't seat all four corners of a rigid tilted box) → acceptable for an arcade look; the visible center-gap and shadow detachment are what the fix targets, and the mesh tilt already matches the slope.
- **Sand-spray emitters remain at the floated body height** (~0.4 m up on slopes) → out of scope here; spray only shows while driving and lives in world space. If it reads as floating later, apply the same offset to the emitter Y. Noted, not done, to keep the change surgical.
- **Offset easing lag during fast elevation changes** could momentarily show a thin gap or slight sink → bounded by `tilt_smoothing`; tune if visible. No handling impact since it's visual-only.
