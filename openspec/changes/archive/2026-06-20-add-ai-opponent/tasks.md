## 1. Car control hook

- [x] 1.1 Add `ai_controlled`, `ai_throttle`, `ai_steer`, `ai_handbrake` fields to `scripts/car.gd`
- [x] 1.2 In `_physics_process`, source `throttle`/`steer_input`/`handbraking` from the AI fields when `ai_controlled`, else from the InputMap as today (same sign/magnitude convention: `steer_input` positive = right, `throttle` in [-1, 1])
- [x] 1.3 Verify `tools/drive_test.gd` still passes (player car physics unchanged when `ai_controlled` is false)

## 2. Enablement flag

- [x] 2.1 Add `var ai_opponent := false` to `scripts/selection.gd` with a doc comment
- [x] 2.2 In `scripts/landing_screen.gd`, when the mode is confirmed, set `Selection.ai_opponent = (Selection.player_count == 1)` alongside the existing `player_count` assignment

## 3. AI driver

- [x] 3.1 Create `scripts/ai_driver.gd` (extends `Node`) holding references to its `car`, the `player` car, the list of pickup `Area3D`s, and a seedable `RandomNumberGenerator`
- [x] 3.2 Implement target selection in `_physics_process`: nearest available pickup (pickup node `visible == true`) when `car.held_item == NONE`, else the player car's position
- [x] 3.3 Implement steer-toward-target: horizontal angle between car forward (`-car.global_transform.basis.z`) and direction to target; sign from the cross product's Y; magnitude `clampf(angle / k, -1, 1)`; write `car.ai_steer`, full `car.ai_throttle`
- [x] 3.4 Implement weave (hunt phase only): `_weave_dir` flipped on a ≤0.5 s timer (e.g. 0.4 s), added to the steer-to-player term and re-clamped, so steering reverses at least every ~0.5 s
- [x] 3.5 Implement item use while hunting: use a held nitro immediately (`car.use_item()`); for a fireball, decide `_fireball_will_miss` once per fireball via the RNG, aim at the player (hit) or a lateral offset point (miss), and call `car.use_item()` when the heading is within tolerance of the aim point
- [x] 3.6 Add a way to stop the driver when the match is over (check a flag, or expose a method `main` can call), so it stops driving under the WASTED/WINNER overlay

## 4. Spawn and wire the opponent in single-player

- [x] 4.1 In `scripts/main.gd` `_setup_single_player`, when `Selection.ai_opponent`, instantiate a second `Car`, set `ai_controlled = true`, place it away from the player spawn, and add it to the scene
- [x] 4.2 Keep the spawned pickup `Area3D`s in a list (from `_spawn_pickups`) and hand it, the player car, and the AI car to a new `AIDriver` node added under `main`
- [x] 4.3 Append the AI car to `_cars`/`_fall_times` so the off-edge fall-respawn covers it; do NOT give it a HUD
- [x] 4.4 Connect the AI car's `fired_fireball` (to `_on_fired_fireball`) and `eliminated` so player-kills-AI shows WINNER and AI-kills-player shows WASTED; ensure `_on_car_eliminated`/match-over also disables the AI driver
- [x] 4.5 Confirm the single full-screen camera still follows the player car only (`$Camera3D.target = $Car`)

## 5. Headless test

- [x] 5.1 Create `tools/ai_test.gd`: set `Selection.player_count = 1` and `Selection.ai_opponent = true`, load `Main.tscn`, assert exactly two cars exist and the AI car is `ai_controlled` with an `AIDriver`
- [x] 5.2 Assert seek-pickup: with the AI holding no item, stepping the physics reduces its distance to the nearest available pickup (steering sign correct)
- [x] 5.3 Assert weave: with the AI holding an item and hunting, its applied `ai_steer` sign reverses at intervals no longer than ~0.5 s (never straight longer than that)
- [x] 5.4 Assert fireball aim/miss: seed/force the RNG to "hit" and to "miss" and verify the aim point (and/or fired fireball outcome) is on-target vs. offset wide accordingly
- [x] 5.5 Make `tools/ai_test.gd` print PASS/FAIL and exit 1 on failure, matching the other test harnesses

## 6. Verify

- [x] 6.1 `godot --headless --import` finishes with no error/warning
- [x] 6.2 `godot --headless -s tools/ai_test.gd` passes
- [x] 6.3 Existing 1P tests still pass unchanged: `tools/drive_test.gd`, `tools/ground_test.gd`, `tools/respawn_test.gd`, `tools/pickup_test.gd`
- [x] 6.4 `tools/two_player_test.gd` still passes (no AI in 2P)
- [x] 6.5 Visually confirm in the running app that the AI opponent seeks pickups, weaves toward the player, and fires fireballs (roughly half missing); update `CLAUDE.md` to document `tools/ai_test.gd` and the `ai_opponent` flag
