## Why

The PRD calls for a top-down 3D car racing game, but nothing playable exists yet. Milestone 1 (Prototype) de-risks the riskiest open question first — how the car *feels* to drive — by getting a single Kenney car model moving under gamepad and keyboard control with a following camera. Everything later (tracks, lap timing, menus) depends on car handling feeling good, so we build and validate that slice before anything else.

## What Changes

- Bootstrap a Godot 4.6.x project (GDScript) targeting Linux/Windows, with a single playable scene.
- Import one Kenney car model (glTF) as the player vehicle with a visible 3D mesh.
- Implement arcade car physics: acceleration, braking/reverse, steering, and drift/grip behavior on a flat ground plane.
- Define device-agnostic `InputMap` actions and read analog steering/throttle (gamepad) with a keyboard fallback; auto-detect controller connect/disconnect.
- Add a high-angle top-down camera that smoothly follows the player car.
- Run car handling on a fixed physics tick for deterministic, frame-rate-independent control.

Out of scope for this change (deferred to later milestones): tracks/collision walls, lap detection/timing, menus, and export build pipelines.

## Capabilities

### New Capabilities
- `vehicle-control`: Arcade car physics on the player vehicle — acceleration, braking/reverse, steering, and drift/grip — driven on a fixed physics tick.
- `player-input`: Device-agnostic input via Godot `InputMap` — analog gamepad steering/throttle, keyboard fallback, and controller hotplug detection.
- `top-down-camera`: High-angle camera that smoothly follows the player car to produce the top-down presentation over a 3D scene.

### Modified Capabilities
<!-- None — greenfield project, no existing specs. -->

## Impact

- **New project scaffold**: Godot 4.6.x project files (`project.godot`, input map, export presets stubs), `.gitignore` for Godot.
- **Assets**: One imported car model (glTF) from Kenney's Car Kit (https://kenney.nl/assets/car-kit), plus license attribution.
- **New scenes/scripts**: player car scene + GDScript controller, camera rig, a flat test ground scene that wires them together.
- **Dependencies**: Godot 4.6.x engine; no third-party libraries.
- **No existing code affected** — this is the first code in the repo.
