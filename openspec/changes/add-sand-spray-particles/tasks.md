## 1. Emitters created in code

- [x] 1.1 In `scripts/car.gd` `_ready` (after the mesh swap), compute the loaded model's combined AABB and create two `GPUParticles3D` nodes added to the `CharacterBody3D` root (not `_mesh`); store references on the script → `_setup_spray()` builds `_spray_l`/`_spray_r` and `add_child`s them to the body; clean import, car loads in `drive_test.gd`
- [x] 1.2 Place the two emitters at the rear (+Z local, since forward is −Z) near the ground, mirrored on ±X to sit roughly at the rear wheels, with offsets derived from the AABB → offsets from `_mesh_aabb()`: `wheel_x = size.x*0.35`, `rear_z = center.z + size.z*0.35`, `y = min_y + 0.05`. Default model AABB (1.3, 0.73, 2.56) → wheels ≈ (±0.46, 0.05, +0.90)

## 2. Particle look (built in code)

- [x] 2.1 Build the `ParticleProcessMaterial` in code: small box emission at the wheel, velocity directed backward+up with spread, downward gravity, short lifetime, mild damping → box extents (0.1,0.04,0.3) — elongated along the travel axis so each frame emits a streak longer than the ~0.37 m/frame spawn gap, giving a continuous plume without a longer tail; `direction (0,0.6,1)` spread 25°, vel 2.5–4.5, gravity −9.8, lifetime 0.18, damping 1–2
- [x] 2.2 Build the draw pass in code: billboarded transparent `QuadMesh` with warm sand albedo fading over life; emit particles in world space so the trail stays behind the moving car → `local_coords = false`; QuadMesh 0.12² + unshaded alpha `BILLBOARD_PARTICLES` material with `vertex_color_use_as_albedo`; sand `color_ramp` (0.85,0.72,0.48,0.9) → alpha 0; soft round grain via code-generated radial-falloff sprite (`_grain_texture`). **Gotcha:** billboard mode discards `scale_min/max` unless `billboard_keep_scale = true` — without it grains rendered at the full quad size ("big squares") regardless of scale.
- [x] 2.3 Tune counts/lifetime/size so two trails read clearly at chase-camera distance without carpeting the world → amount 192/emitter, scale 0.3–0.8 (now effective via keep_scale), lifetime 0.18 (short = tight trail, ~1/3 length; trail length ≈ speed × lifetime). Judged at full speed mid-turn via `tools/spray_shot.gd`: dense fine soft grains, no hard squares, compact puff behind the wheels

## 3. Drive the emitters from existing state

- [x] 3.1 In `_physics_process`, set both emitters `emitting = hspeed > speed_floor or abs(lateral_speed) > drift_threshold` on the grounded path → done; `spray_speed_floor 3.5`, `spray_drift_threshold 2.0`
- [x] 3.2 Stop the spray on the airborne and crest-launch early-return paths (a small helper called from each exit) → `_set_spray(false)` added before the airborne `return` and the crest-launch `return`; `_set_spray()` guards null. Headless asserts `emitting` false while airborne
- [x] 3.3 Scale intensity (via `amount_ratio` and/or initial velocity) from the **max** of normalized `hspeed` and normalized `|lateral_speed|`, so hard drifts throw a bigger fan than a cruise → `amount_ratio = clamp(max(speed/max_forward_speed, |lateral|/spray_drift_ref), 0.2, 1.0)`, `spray_drift_ref 8.0`

## 4. Verification

- [x] 4.1 Extend `tools/drive_test.gd`: assert two emitter children exist; `emitting` false at spawn and while airborne; `emitting` true after driving forward on the ground → `_test_sand_spray` added; all 4 spray checks PASS
- [x] 4.2 Add `tools/spray_shot.gd` (windowed `--rendering-driver opengl3`, `--shot=<path>`) that drives the car briefly then saves a PNG → added (accelerate then handbrake-drift); produces a frame showing the spray
- [x] 4.3 `godot --headless --import` completes with no errors/warnings → clean (EXIT 0)
- [x] 4.4 Confirm handling is unchanged: all pre-existing accel/reverse/steer/drift/frame-rate/camera/pause checks in `drive_test.gd` still PASS → ALL CHECKS PASSED (28/28, physics unchanged)
- [x] 4.5 Capture a before/after-style chase-cam render for sign-off on the spray look → `/tmp/spray.png`: two sand puffs trail behind the drifting car, readable at chase distance and not obscuring gameplay
