## 1. Implement the facing correction

- [x] 1.1 In `scripts/car.gd` `_ready()`, after instantiating the swapped mesh, call `mesh.rotate_y(PI)` so the kit's `+Z`-authored nose points along the car's `-Z` forward, with a comment explaining why.

## 2. Verify orientation

- [x] 2.1 Run `godot --rendering-driver opengl3 -s tools/orient_shot.gd -- --shot=/tmp/orient.png` and confirm every car's nose leads along the `-Z` travel arrow.

## 3. Regression-check handling

- [x] 3.1 `godot --headless --import` — finishes with no error/warning.
- [x] 3.2 `godot --headless -s tools/drive_test.gd` — ALL CHECKS PASSED (handling unchanged).
