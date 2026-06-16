## 1. Shared car material/helper

- [x] 1.1 Add a shared helper that builds one `StandardMaterial3D` with `albedo_texture = load("res://assets/cars/Textures/colormap.png")` and `metallic = 0`, loaded once and reused (e.g. a small `CarSkin` util/autoload, or a static func).
- [x] 1.2 In the helper, expose a function that walks a given model `Node3D`, finds every `MeshInstance3D`, and sets its `material_override` to the shared material.

## 2. Apply at both render sites

- [x] 2.1 In `scripts/car.gd` `_ready()`, after instantiating the selected mesh, call the helper to apply the colormap material.
- [x] 2.2 In `scripts/landing_screen.gd`, after instantiating each preview model, call the helper (reuse/replace the existing `_find_meshes` walk so logic isn't duplicated).

## 3. Verify

- [x] 3.1 `godot --headless --import` finishes with no errors/warnings.
- [x] 3.2 Headless material check: instantiate a car model, apply the helper, assert every `MeshInstance3D` surface material has a non-null `albedo_texture` (no white-albedo fallback).
- [x] 3.3 `godot --headless -s tools/drive_test.gd` still passes (handling/camera/pause unchanged).
- [x] 3.4 Windowed screenshot of the landing screen (`opengl3` render harness) shows the preview cars in color, not white.
- [x] 3.5 Windowed screenshot of the race (Main.tscn) shows the player car in color, not white.
