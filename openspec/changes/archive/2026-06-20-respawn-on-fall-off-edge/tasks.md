## 1. Car respawn method

- [x] 1.1 Add `respawn(pos: Vector3)` to `scripts/car.gd`: set `global_position = pos`, `velocity = Vector3.ZERO`, and reset airborne/orientation state (`_was_airborne = false`, `_air_time = 0.0`, `_air_angvel = Vector3.ZERO`).

## 2. Fall detection and respawn trigger

- [x] 2.1 Add `FALL_LIMIT := 1.0` and `RESPAWN_HEIGHT := 20.0` constants and a `_fall_time := 0.0` field to `scripts/main.gd`.
- [x] 2.2 In `main.gd._process(delta)`, accumulate `_fall_time` while the car is beyond `±HALF` on X or Z, and reset it to 0 while in bounds.
- [x] 2.3 When `_fall_time >= FALL_LIMIT`, call `$Car.respawn(Vector3(0, DuneHeight.height(0, 0) + RESPAWN_HEIGHT, 0))` and reset `_fall_time` to 0.

## 3. Test

- [x] 3.1 Add `tools/respawn_test.gd`: load `Main.tscn`, move the car beyond the edge, advance ~1 s of frames, and assert it respawns near `(0, 20, 0)` with cleared velocity; assert a sub-1 s excursion that returns in-bounds does NOT respawn. Print PASS/FAIL, exit 1 on failure.
- [x] 3.2 Run `godot --headless --import` and `godot --headless -s tools/respawn_test.gd`; confirm both pass with no errors/warnings.
- [x] 3.3 Run the existing `tools/drive_test.gd` and `tools/ground_test.gd` to confirm no regression.

## 4. Documentation

- [x] 4.1 Add `tools/respawn_test.gd` to the "Verifying changes" list in `CLAUDE.md`.
