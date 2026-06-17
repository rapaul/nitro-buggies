## 1. Dune height function

- [x] 1.1 Add a shared `scripts/dune_height.gd` helper exposing a deterministic `height(x, z)` (sum of sine/cosine terms) plus tuning constants (amplitude, wavelength) — the single source of truth for terrain, collision, and tests.
- [x] 1.2 Add a `tools/inspect_dunes.gd` tool script that prints sampled heights across the play area and the location/height of a known crest, to sanity-check shape and pick a jump target for tests.

## 2. Terrain in the scene

- [x] 2.1 Generate the dune visual surface: build an `ArrayMesh` grid sampled from `dune_height` and apply a sandy `StandardMaterial3D`, replacing the `PlaneMesh` ground in `scenes/Main.tscn`.
- [x] 2.2 Generate matching collision from the same height function as a `HeightMapShape3D` on the ground `StaticBody3D`, replacing the flat `BoxShape3D`.
- [x] 2.3 Wire generation (mesh + collision) in `Main`'s `_ready()` so terrain and collision derive from one source; confirm `godot --headless --import` is clean (no errors/warnings). Added a `WorldEnvironment` (procedural sky + ambient) since the Compatibility renderer shows unlit surfaces as black without it.
- [x] 2.4 Visually verify with `tools/dunes_shot.gd` screenshot of `Main.tscn`: dunes read as sand and undulate.

## 3. Vehicle vertical physics

- [x] 3.1 Add `gravity` and `floor_snap_length` `@export`s to `scripts/car.gd`; set `up_direction = Vector3.UP` and a `floor_max_angle` permissive enough for dune faces.
- [x] 3.2 Integrate gravity into `velocity.y` each tick and preserve it through the velocity assignment (stop discarding Y) so the car rests on and follows the surface while grounded. Gravity is applied only while airborne (textbook CharacterBody3D pattern); floor snapping holds the car to slopes while grounded.
- [x] 3.3 Branch on `is_on_floor()`: run existing accel/brake/steer/grip only while grounded; while airborne, freeze horizontal velocity (no throttle, no grip) and let only gravity act, producing a ballistic arc.
- [x] 3.4 Make crest launches speed-dependent. Floor snapping glues the car to even the steepest *smooth* dune face (curvature far too low to "outrun" snap), so a jump is triggered explicitly: detect the crest via the floor-normal back-tilt flipping forward, and at speeds above `launch_min_speed` convert forward momentum to lift. Tuned against the crest test (≈8m clearance at full throttle, stays grounded when slow).

## 4. Verification

- [x] 4.1 Extend `tools/drive_test.gd`: assert the car settles to surface height under gravity (rests, no sink/float) and that Y rises in step with the contour when driving up a slope.
- [x] 4.2 Extend `tools/drive_test.gd`: assert accelerating into a known crest produces an airborne interval (Y above surface height for several ticks) followed by a landing; assert a slow approach stays grounded.
- [x] 4.3 Confirmed the camera-follow assertion still passes over varying terrain height; `tools/jump_shot.gd` shows the chase camera frames a mid-air jump (~4m clearance) acceptably — no camera change needed. Frame-rate-independence check now isolates the controller on a temporary flat collision, since absolute position over undulating dunes is coupled to discrete contact resolution (terrain noise, not a handling property).
- [x] 4.4 Run the full headless suite (`--import`, `drive_test.gd`, `landing_test.gd`) and confirm all PASS / exit 0.
