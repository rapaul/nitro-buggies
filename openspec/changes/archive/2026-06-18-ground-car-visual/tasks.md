## 1. Ground the visual mesh

- [x] 1.1 In `scripts/car.gd`, add a mesh vertical-offset field (eased) and a helper that samples `DuneHeight.height(global_position.x, global_position.z)` for the surface beneath the car.
- [x] 1.2 In the grounded branch of `_update_orientation` (or alongside it), compute target offset = `terrain_y - global_position.y` while `is_on_floor()`, else 0; ease it toward target with the existing `tilt_smoothing` cadence.
- [x] 1.3 Apply the eased offset to the mesh's local `position.y` without disturbing the basis written by `_set_mesh_rotation` (rotation and position stay independent).
- [x] 1.4 Confirm airborne behavior: when not on the floor the offset returns to 0 so the mesh rides the body's ballistic height, and re-seats on landing.

## 2. Verify

- [x] 2.1 Add `tools/ground_test.gd`: settle the car at flat, sloped, and valley spots; assert the mesh's lowest point rests within tolerance of `DuneHeight` sampled beneath it (no float/sink), and assert the mesh is not pinned to terrain mid-launch. Print PASS/FAIL, exit 1 on failure.
- [x] 2.2 Run `~/.local/bin/godot --headless --import` (clean) and `~/.local/bin/godot --headless -s tools/ground_test.gd` (PASS).
- [x] 2.3 Run `~/.local/bin/godot --headless -s tools/drive_test.gd` and confirm it still PASSes (handling unchanged).
- [x] 2.4 Capture a windowed screenshot (`tools/main_shot.gd` on a slope) and confirm the car visually meets its shadow with no gap.

## 3. Document

- [x] 3.1 If `tools/ground_test.gd` is added, list it under "Verifying changes" in `CLAUDE.md` alongside the other headless harnesses.
