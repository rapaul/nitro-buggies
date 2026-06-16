## Why

The landing screen is currently a passive title gate: the player presses ENTER and always drives the same hardcoded `race.glb` car. Players should pick the buggy they race in, and the title screen is the natural place to do it. Adding a vehicle picker turns the front door into a real menu and gives the Kenney car kit a reason to ship more than one model.

## What Changes

- Add a vehicle picker to the bottom two-thirds of the landing screen (below the title): three vehicle previews, equally spaced with margins all around.
- On each visit, pick **3 distinct vehicle models at random** (no duplicates) from the Kenney car kit (`kenney_car-kit.zip`).
- Each preview shows its 3D model **rotating once per second** (360°/s).
- The **left preview starts selected**, marked by a chunky square outline drawn so the car sits entirely inside it.
- The player moves the selection left/right via **arrow keys, A/D, gamepad d-pad, or the gamepad left stick**. Selection **stops at the ends** (no wrap).
- Pressing **accept** (ENTER / gamepad confirm) confirms the highlighted vehicle and starts the race. The chosen model is **carried into gameplay** — the in-game car renders the selected vehicle (visual mesh swap; the collision shape is unchanged for v1).
- Extract a curated set of drivable vehicle models from `kenney_car-kit.zip` into the project so they are importable at runtime.

## Capabilities

### New Capabilities
- `vehicle-selection`: Choosing a vehicle on the landing screen — random no-duplicate pick of three models, equally-spaced bottom-two-thirds layout, once-per-second rotation, the chunky selection highlight starting on the left, left/right navigation that clamps at the ends across keyboard and gamepad, and carrying the confirmed choice into the race so the in-game car uses the selected model.

### Modified Capabilities
- `landing-screen`: The "ENTER starts the game" requirement changes — ENTER now **confirms the currently selected vehicle** and then starts the game, rather than just starting it. The bottom two-thirds of the screen is now occupied by the vehicle picker.

## Impact

- **Assets**: extract a curated set of vehicle GLBs from `kenney_car-kit.zip` into `assets/` (e.g. `assets/cars/`) and import them headlessly.
- **Landing screen**: `scripts/landing_screen.gd` + `scenes/LandingScreen.tscn` gain the 3-cell preview selector (SubViewport-based 3D previews over the existing Control), navigation handling, and the selection highlight.
- **Cross-scene state**: a small mechanism to pass the chosen model from the landing screen into the race (e.g. an autoload singleton); `project.godot` autoload registration.
- **Gameplay car**: `scenes/Main.tscn` / `scripts/main.gd` (or the Car scene) swap the visual mesh to the selected model on load; collision shape unchanged.
- **Input**: gamepad d-pad bindings for menu left/right may be added to `project.godot`.
- **Tests/tools**: a new headless test for selection behavior (random distinct pick, initial left highlight, navigation clamping, accept carries choice) plus a windowed screenshot tool for the selector; existing `tools/landing_test.gd` updated for the new ENTER-confirms-selection behavior.
