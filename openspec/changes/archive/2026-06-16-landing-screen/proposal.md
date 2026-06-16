## Why

The game currently boots straight into the playable race (`Main.tscn`) with no front door — there is no title, no sense of "the game starting", and no clear moment of player intent before driving begins. A landing screen gives the prototype an identity ("Nitro Buggies"), an 80s arcade tone, and a deliberate "press to start" gate before gameplay.

## What Changes

- Add a landing screen as the new entry scene; the project boots into it instead of jumping straight to `Main.tscn`.
- Display the title **"Nitro Buggies"** in the top third of the screen, set in an 80s block font, sandy yellow, with comfortable top/left/right margins.
- Render a sandy-orange block drop-shadow behind the title, offset to the lower-right, for the classic chunky 80s look.
- Use a very dark grey background for the whole screen.
- Produce **three visual style variants** of the title treatment (font choice, shadow offset/weight, layout) so the user can review and pick one; the chosen variant becomes the kept implementation.
- Pressing **ENTER** on the landing screen transitions into the main game (`Main.tscn`).
- Enable proportional 2D canvas scaling (project stretch mode) so the title holds the same fraction of the screen at any window size or resolution instead of looking small when maximized.

Out of scope: settings/options menus, car selection, animated/transition effects beyond the basic screen swap, and audio.

## Capabilities

### New Capabilities
- `landing-screen`: A title/start screen shown before gameplay — branded "Nitro Buggies" title styling, very dark grey background, and an ENTER-to-start gate that loads the main game scene.

### Modified Capabilities
<!-- None — gameplay scenes and input behavior are unchanged; this adds a screen in front of them. -->

## Impact

- **Entry point**: `project.godot` `run/main_scene` changes from `res://scenes/Main.tscn` to the new landing scene.
- **Display**: a new `project.godot` `[display]` section sets a base resolution and `canvas_items` / `expand` stretch. This is global, so it also affects how the 3D race fills the window (a wider window shows slightly more track rather than zooming).
- **New scene/script**: a `LandingScreen.tscn` (Control-based UI) plus a small GDScript controller that listens for ENTER and changes scene to `Main.tscn`.
- **Input**: needs a "start/confirm" trigger on ENTER. Either a new `InputMap` action (e.g. `ui_accept` is already built in) or direct key handling — decided in design.
- **Assets**: may add one or more 80s block display fonts (with license/attribution) under `assets/`, depending on which variant is chosen. Sandy-yellow / sandy-orange colors are defined in-scene.
- **Dependencies**: Godot 4.6.x only; no third-party libraries.
