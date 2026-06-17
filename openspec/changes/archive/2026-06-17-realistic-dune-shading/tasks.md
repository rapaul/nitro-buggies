## 1. Tier 1 — Golden-hour lighting (the core win)

- [x] 1.1 In `scenes/Main.tscn`, lower the `DirectionalLight3D` to a shallow golden-hour elevation that rakes across the ridges (horizontal travel dominated by ±Z); warm `light_color` (≈ `1.0, 0.86, 0.62`) and raise `light_energy` (≈ 1.3) → verify: relief is visible on the dune faces in a `tools/dunes_shot.gd` render
- [x] 1.2 Switch the `Environment` ambient to a color source, cooler (≈ `0.55, 0.62, 0.78`) → verify: leeward faces read as cool sky-lit shadow, lit faces stay warm. (Energy ended at 0.55, up from the 0.3 starting guess, to keep shadowed sand readable.)
- [x] 1.3 Enable and tune `ssao_enabled` on the `Environment` → verify: troughs between ridges read as recessed without over-darkening
- [x] 1.4 Confirm the directional shadow at low sun does not crush the play valley → verify: chase-cam-height screenshot with the car present shows car + flat corridor clearly readable (car + valley read fine in the chase render)

## 2. Tier 1 — Albedo tonal variation

- [x] 2.1 In `scripts/main.gd` `_build_terrain`, add a `FastNoiseLite`-backed `NoiseTexture2D` as the material `albedo_texture` with `uv1_triplanar = true`, colour-ramped between a slightly darker and slightly lighter sand bracketing SAND (base tone preserved, not darkened) → done
- [x] 2.2 Tune noise frequency/scale so the variation reads at chase-camera distance (large-scale, not fine grain) → uv1_scale 0.06 (~16 m features); kept subtle to avoid blobby puddles when seen from above. Note: at this subtlety the variation is faint at chase distance — flagged for user sign-off in 3.3.

## 3. Tier 1 — Verification

- [x] 3.1 Run `godot --headless -s tools/drive_test.gd` → PASS (all 12 checks; physics/handling unchanged)
- [x] 3.2 Run `godot --headless --import` → completes, no errors/warnings
- [x] 3.3 Capture before/after renders → clear relief + readable gameplay view confirmed. Final lighting: ~14° sun, `light_energy` 1.5, ambient energy 0.7. Note: while tuning, found the `.tscn` 12-float `Transform3D` is row-major, so the hand-authored sun rotation was transposed (pointing the sun upward → flat/dark). Fixed by orienting the sun in code (`main.gd._orient_sun()` via `look_at`). The earlier "raise the sun to ~22°" idea was chasing that darkness, which was the bug + low ambient, not the elevation — so the keeper is 14° + brighter ambient.

## 4. Tier 2 — Wind ripples (descoped by user decision)

User chose to stop at Tier 1 and ship the lighting + tone win. Tier 2 is **deferred as an optional follow-up**, not attempted. Per the optional ripple requirement (satisfied by "implemented OR intentionally dropped"), this leaves ripples documented as not-pursued for now. See design.md.

- [x] 4.1 (skipped — Tier 2 descoped before the banding spike)
- [x] 4.2 Decision gate — Tier 2 intentionally deferred by the user; documented in design.md. Tier 2 complete (as "not pursued").
- [x] 4.3 N/A — no `ShaderMaterial` swap; `StandardMaterial3D` retained
- [x] 4.4 N/A — no material swap to re-verify
