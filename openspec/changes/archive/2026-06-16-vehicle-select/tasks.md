## 1. Assets

- [x] 1.1 Extract the GLB-format drivable vehicle models from `kenney_car-kit.zip` into `assets/cars/` (vehicles only: ambulance, delivery, delivery-flat, firetruck, garbage-truck, hatchback-sports, kart-oobi/oodi/ooli/oopi/oozi, police, race-future, race, sedan, sedan-sports, suv, suv-luxury, taxi, tractor, tractor-police, tractor-shovel, truck, truck-flat, van — exclude box, cones, debris-*, wheel-*)
- [x] 1.2 Run `godot --headless --import` and confirm all extracted models import with no errors/warnings (needed `colormap.png` — see 1.3)
- [x] 1.3 The GLBs reference an external `Textures/colormap.png`; extracted it into `assets/cars/Textures/` and re-imported clean. Color can't be verified via the offscreen `opengl3` driver (even `Main.tscn` renders near-black there); models are set up identically to the known-good `race.glb`, so color is verified in-engine on the landing render (6.3).

## 2. Cross-scene selection state

- [x] 2.1 Add `scripts/selection.gd` — a `Node` autoload exposing `selected_model_path: String` defaulting to `res://assets/race.glb`
- [x] 2.2 Register it as an autoload named `Selection` in `project.godot`
- [x] 2.3 Confirm `tools/drive_test.gd` still passes (default keeps `Main.tscn` working with no selection made)

## 3. Carry selection into gameplay

- [x] 3.1 On car load, replace the `Mesh` child with an instance of `Selection.selected_model_path` (free the default), leaving the collision shape unchanged; fall back to `race.glb` if loading fails
- [x] 3.2 Re-run `tools/drive_test.gd` to confirm gameplay is unaffected when the default model is used

## 4. Vehicle picker on the landing screen

- [x] 4.1 Define the curated eligible-vehicle path list as a `const` in `scripts/landing_screen.gd`
- [x] 4.2 On `_ready`, shuffle the list and take the first three (distinct, random per visit)
- [x] 4.3 Build three `SubViewportContainer` → `SubViewport` (own World3D, transparent bg) cells in the bottom two-thirds, equally spaced with margins on all sides
- [x] 4.4 In each cell add a `Camera3D`, a `DirectionalLight3D`, and the instanced model. Framed per-model by the bounding sphere (rotation-invariant → always inside the square) at ~1/3 viewport height; near-horizontal view (car upright, underside toward screen bottom) with the back tilted up ~15°
- [x] 4.5 Rotate each model `rotate_y(TAU / 3 * delta)` in `_process` (one revolution per 3 seconds, frame-rate independent)

## 5. Selection highlight and navigation

- [x] 5.1 Add a chunky bordered `Panel` (thick `StyleBoxFlat` border, transparent fill) and position it to frame the selected cell, starting on the leftmost
- [x] 5.2 In `_unhandled_input`, move the selection on left/right using `ui_left`/`steer_left` and `ui_right`/`steer_right`; clamp at both ends; reposition the highlight
- [x] 5.3 On `ui_accept`, write the selected model path to `Selection.selected_model_path`, then `change_scene_to_file(MAIN_SCENE)`

## 6. Tests and verification

- [x] 6.1 Add a headless test (`tools/vehicle_select_test.gd`): three distinct eligible models picked, leftmost selected initially, left/right navigation clamps at the ends, and accept writes the highlighted model to `Selection`
- [x] 6.2 Update `tools/landing_test.gd` so the ENTER phase still passes with the picker present (ENTER confirms selection and loads `Main.tscn`)
- [x] 6.3 Added `tools/picker_shot.gd` (seeded landing render); visually verified layout, spacing, margins, shared ground line, and each car inside its square
- [x] 6.4 Run the full headless suite (`--import`, `drive_test`, `landing_test`, `vehicle_select_test`) and confirm all PASS
