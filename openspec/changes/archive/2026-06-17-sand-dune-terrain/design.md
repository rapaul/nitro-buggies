## Context

The world is a flat `PlaneMesh` ground with a slab `BoxShape3D` collision (`scenes/Main.tscn`), and the car (`scripts/car.gd`, a `CharacterBody3D`) integrates motion purely in the XZ plane — every tick ends with `velocity = forward * forward_speed + right * lateral_speed`, discarding any Y component. There is no gravity and no concept of being airborne. To deliver "sand dunes you can jump off," we need (a) an undulating surface with conforming collision and (b) vertical physics so the car follows slopes and launches at crests.

Constraints: Godot 4.6 / GDScript; Kenney assets only for vehicles; everything must stay headlessly verifiable per `CLAUDE.md`. Physics must remain deterministic on the fixed tick (existing `vehicle-control` requirement) so the drive-test harness can make assertions.

## Goals / Non-Goals

**Goals:**
- Replace the flat plane with a rolling sand-dune surface that has matching collision.
- Give the car gravity, slope-following while grounded, a speed-dependent launch off crests, ballistic flight, and landing.
- Keep the terrain shape deterministic so headless tests can target known crests/troughs.
- Preserve existing grounded handling (accel/brake/steer/drift) unchanged when on the ground.

**Non-Goals:**
- No suspension model, per-wheel raycasts, or `VehicleBody3D` rewrite — keep the `CharacterBody3D` arcade approach.
- No mid-air control (air-steering thrust, flips) beyond heading rotation already produced by `rotate_y`.
- No terrain editor, biomes, textures beyond a sandy material, or runtime regeneration.
- No camera rewrite (verify it still frames the car over varying height; only change if it visibly breaks).

## Decisions

### Terrain: procedural heightfield generated in code
Generate the dune surface from a deterministic height function `h(x, z)` rather than hand-authoring a mesh. A tool script builds an `ArrayMesh` (a grid of vertices sampled from `h`) for the visual `MeshInstance3D` and a `HeightMapShape3D` from the **same** function for collision, guaranteeing the collision matches what's drawn.

- **Height function:** a sum of a few sine/cosine terms (e.g. `A1*sin(x*f1)*cos(z*f1) + A2*sin(...)`), not random noise. Sinusoids give smooth, rounded, repeating dunes with crest positions we can compute analytically — essential for writing a deterministic "this crest launches the car" test. (`FastNoiseLite` was considered but rejected for v1: its crest locations are opaque, making targeted tests fragile.)
- **Why `HeightMapShape3D`:** native, cheap, conforms exactly to a grid heightfield, and is the natural collision for a heightmap. (`ConcavePolygonShape3D` from the mesh triangles also works but is heavier and redundant when the data is already a grid.)
- **Generation location:** decide at apply time between baking the mesh/shape once via a tool script into resources referenced by `Main.tscn`, versus generating in `Main`'s `_ready()`. Leaning toward generating in `_ready()` from a small shared `dune_height.gd` helper so the height function is the single source of truth shared by terrain, collision, and tests.

### Car: branch handling on grounded vs airborne, integrate Y with gravity
Keep the existing forward/lateral handling but make `velocity.y` meaningful:

- Apply `gravity * delta` to `velocity.y` every tick.
- Use `is_on_floor()` to branch: **grounded** runs the existing accel/brake/steer/grip logic and writes `velocity = forward*forward_speed + right*lateral_speed` but **preserves the gravity-affected Y** (and lets floor snapping hold the car to slopes); **airborne** skips throttle and grip entirely so the horizontal velocity is frozen and only gravity acts — yielding a ballistic arc. Heading (`rotate_y`) may still apply.
- **Launching off crests** comes from momentum + a limited `floor_snap_length`: while climbing, the car's velocity has an up-slope (positive-Y) component; at a convex crest the surface drops away faster than a modest snap length can re-attach the car, so a fast car keeps its upward momentum and leaves the ground, while a slow car stays snapped. This makes launch speed-dependent and emergent rather than a scripted "if at crest, jump" hack. Tuning knobs: `gravity`, `floor_snap_length`, and how up-slope velocity is preserved.
- Set `up_direction = Vector3.UP` and `floor_max_angle` so steep dune faces still count as floor.

### Tests: extend `tools/drive_test.gd`
Add assertions using the shared height function: car settles to surface height under gravity (rests, doesn't sink/float); driving up a slope raises Y in step with the contour; accelerating into a known crest produces an airborne interval (Y rises above the surface height for several ticks) then lands. Determinism of `h(x,z)` makes these reproducible.

## Risks / Trade-offs

- **Floor-snap tuning is finicky** → too-long snap glues the car to crests (no jumps); too-short causes jitter/bouncing on bumps. Mitigation: expose `floor_snap_length` and gravity as `@export`s, tune against the drive-test crest case, pick the smallest snap that keeps the car stable in troughs.
- **Re-snapping kills small jumps** → CharacterBody3D may immediately re-detect floor after a gentle crest. Mitigation: gate snapping while moving upward (disable snap when `velocity.y > 0`), a common arcade pattern.
- **Steering on slopes is yaw-only** → the car's heading stays in the world XZ plane while the body sits on a tilted surface, so the mesh may visually intersect/hover slightly on steep faces. Acceptable for arcade v1; full surface-alignment of the body is a non-goal.
- **Camera over dunes** → rapid height changes during a jump could make the chase camera bob. Mitigation: verify with a screenshot/the camera-follow test; only smooth Y if it visibly breaks (out of scope unless needed).
- **Collision cost** → a fine heightfield grid over 200×200 could be large. Mitigation: choose a moderate grid resolution (coverage/visual smoothness vs. vertex count) and confirm import + drive-test stay clean.

## Open Questions

- Exact dune amplitude/wavelength and play-area size (must keep crests jumpable but faces climbable) — settle empirically during apply.
- Bake terrain to a resource via tool script vs. generate in `_ready()` — lean generate-in-`_ready()` for a single source of truth; revisit if import/startup cost matters.
- Whether the world stays a fixed bounded patch or needs invisible walls at the edges to keep the car in-bounds — likely add simple boundary handling, confirm during apply.
