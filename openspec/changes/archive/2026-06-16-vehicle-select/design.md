## Context

The landing screen (`scenes/LandingScreen.tscn` + `scripts/landing_screen.gd`) is a 2D `Control` that draws the "Nitro Buggies" title in the top third and, on ENTER, calls `change_scene_to_file("res://scenes/Main.tscn")`. The race always uses a hardcoded car: `scenes/Car.tscn` instances `assets/race.glb` as a child node named `Mesh`, with a fixed `BoxShape3D` collision sized for that model.

We need to show three rotating 3D vehicle previews on what is otherwise a 2D screen, let the player pick one, and carry that pick into the race. Only `race.glb` is currently extracted from `kenney_car-kit.zip`; the other models live unimported inside the zip.

Constraints from the project:
- Godot 4.6, GDScript. Headless validation is the norm (`tools/*.gd`), but `--headless` cannot render 3D — visual checks use the windowed `opengl3` screenshot pattern.
- `.tscn` NodePath exports don't resolve reliably (see memory `godot-tscn-node-export-gotcha`); node wiring is done in code.
- Kenney models face `-Z` and are longer along `Z` (per `tools/inspect_car.gd`).
- `tools/drive_test.gd` loads `Main.tscn` directly without going through the landing screen, so gameplay must work with no selection made.

## Goals / Non-Goals

**Goals:**
- Three distinct, randomly-chosen drivable vehicle previews in the bottom two-thirds, equally spaced with margins.
- Each preview rotates at exactly one revolution per second, frame-rate independent.
- A chunky square highlight, starting on the left preview, movable left/right and clamped at the ends, across keyboard (arrows, A/D) and gamepad (d-pad, left stick).
- The confirmed model is rendered by the in-game car when the race starts.
- Logic verifiable headless; appearance verifiable via the screenshot tool.

**Non-Goals:**
- Resizing or regenerating the in-game collision shape to match each model (collision stays as the existing box for v1).
- Per-vehicle handling/stats differences — selection is cosmetic in gameplay for now.
- Wrap-around navigation, vehicle names/labels, or scrolling beyond three previews.

## Decisions

### Per-cell SubViewport previews
Each preview is a `SubViewportContainer` → `SubViewport` (with `own_world_3d = true`, transparent background) containing a `Camera3D`, a `DirectionalLight3D`, and one instanced vehicle GLB. The container's on-screen rect defines the cell; the 3D content renders into it.

- *Why:* Three independent worlds keep each model framed and lit consistently, and the cell rects map 1:1 to screen positions — which the highlight and layout math need.
- *Alternative considered:* one shared 3D scene with three cars and a single camera. Rejected: projecting three world positions back to screen rects (for the highlight and equal spacing) is fiddler than just laying out three Controls.

### Cross-scene selection via an autoload singleton
Add an autoload `Selection` (e.g. `scripts/selection.gd`, a plain `Node`) holding `selected_model_path: String`, defaulting to `res://assets/race.glb`. The landing screen writes the chosen path on accept; the car reads it on load.

- *Why:* Survives the `change_scene_to_file` boundary, and the default keeps `Main.tscn` / `drive_test.gd` working when launched directly with no landing screen.
- *Alternatives:* a `static var` on a class (works but less discoverable, no default-init hook); passing data through the scene change (Godot has no first-class param passing across `change_scene_to_file`). Autoload is the idiomatic Godot choice.

### Mesh swap on the car, collision unchanged
On load, the car replaces its `Mesh` child with an instance of `Selection.selected_model_path` (freeing the default). The `BoxShape3D` collision is left as-is.

- *Why:* Minimal, surgical, and matches the v1 non-goal. The previews and the in-game mesh come from the same GLBs, so visuals stay consistent.
- *Trade-off:* see Risks — larger/smaller models won't exactly match the collision box.

### Curated eligible-model list, GLB extracted into the project
Extract the *GLB format* vehicle models from `kenney_car-kit.zip` into `assets/cars/` and keep a hardcoded `const` array of eligible vehicle paths. Eligible = drivable vehicles only (ambulance, delivery(-flat), firetruck, garbage-truck, hatchback-sports, kart-oo*, police, race(-future), sedan(-sports), suv(-luxury), taxi, tractor(-police/-shovel), truck(-flat), van). Excluded: box, cone(-flat), `debris-*`, `wheel-*`.

- *Why GLB:* `.glb` is self-contained (embeds its texture), so each file imports standalone — no FBX-plus-shared-`colormap.png` wrangling. `race.glb` already proves this path works.
- *Why a hardcoded list:* the kit mixes vehicles with props; scanning a folder would risk picking a cone. An explicit list is the simplest correct filter and is trivial to test. The three are chosen by shuffling this list and taking the first three (guarantees distinct).

### Navigation reuses existing actions — no InputMap edits
Handle navigation in `_unhandled_input`. Left = `is_action_pressed("ui_left") or is_action_pressed("steer_left")`; right = the `ui_right`/`steer_right` pair. Confirm = `ui_accept`.

- *Why:* Godot's built-in `ui_left`/`ui_right` already bind arrow keys, gamepad d-pad, and the left stick; the project's `steer_left`/`steer_right` already bind A/D (plus arrows/stick). Their union covers every requested control — arrows, A/D, d-pad, and stick — with **zero `project.godot` changes**. `ui_accept` already includes ENTER and the gamepad confirm button.
- *Discrete stepping:* `_unhandled_input` + `is_action_pressed` fires once per press (echoes filtered; an axis crossing its deadzone counts as one press), giving one-cell-per-press movement rather than continuous scroll.

### Chunky highlight as a repositioned bordered Panel
One `Panel` with a `StyleBoxFlat` (thick `border_width_*`, transparent fill) is moved to frame the selected cell. Each cell is sized so the car's rotation footprint (its longest dimension as it spins) fits inside with margin; the highlight frames that cell, so the car is always fully enclosed.

- *Why a single moved Panel:* one node, and "move the box" is the whole selection-change visual.

### Frame-rate-independent rotation
Each preview's model does `rotate_y(TAU * delta)` in `_process` → exactly one revolution per second regardless of FPS.

## Risks / Trade-offs

- **Collision box vs. model size mismatch** → For v1 the collision stays sized for `race.glb`; larger models (trucks/karts) will visually over/underhang the collider. Accepted per non-goal; revisit if it affects driving feel.
- **Rotating car clipping the highlight** → A car spinning presents its diagonal at 45°. Mitigation: size each preview camera/cell to the model's longest dimension (with margin) so the diagonal still fits inside the square.
- **GLB texture not embedded** → If a kit `.glb` references rather than embeds `colormap.png`, it would import untextured. Mitigation: verify via `--headless --import` and the screenshot tool; if needed, also copy `colormap.png` next to the models. (`race.glb` already imports textured, so this is unlikely.)
- **3D not renderable headless** → Random-distinct selection, initial-left index, clamping, and the chosen path written to `Selection` are all testable headless; visual layout/rotation/highlight are verified with the `opengl3` screenshot tool. Split the test harness accordingly.
- **drive_test.gd bypasses the landing screen** → The `Selection` default (`race.glb`) preserves current behavior, so existing tests keep passing.

## Open Questions

- None blocking. Collision-per-model and per-vehicle handling are deferred to a later change.
