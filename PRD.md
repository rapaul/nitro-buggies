# PRD: Top-Down 3D Car Racing Game

**Status:** Draft
**Last updated:** 2026-06-15

---

## 1. Overview

A top-down car racing game rendered with 3D model assets, running natively on desktop platforms with gamepad support. The game uses a high-angle/orthographic camera over a fully 3D scene, giving a "top-down" presentation while retaining real 3D physics and lighting.

## 2. Goals

- Smooth **60 fps** gameplay on target platforms.
- Native **controller (gamepad)** support as a first-class input method.
- Use **free, non-commercial** tooling end to end.
- Built with a stack that **works well with AI-assisted code generation**.
- Use **off-the-shelf 3D assets** (Kenney.nl) rather than custom art for v1.

## 3. Non-Goals (v1)

- No online/multiplayer networking.
- No mobile or web builds.
- No custom 3D art pipeline — Kenney assets only.
- No in-game level editor.

## 4. Target Platforms

| Platform | Priority | Notes |
|---|---|---|
| Linux (x86_64) | Primary | Primary development target |
| Windows (x86_64) | Primary | |
| macOS | Stretch | Best-effort; "maybe" per scope |

## 5. Technical Stack

### Engine: Godot 4.6.x

- MIT licensed.
- Native glTF/OBJ import.
- One-click export to Linux, Windows, and macOS from a single project.
- Built-in gamepad support via `InputMap` + SDL-based controller mappings.

### Language: GDScript

- GDScript for v1.

### Assets: Kenney.nl

- Source car models, track pieces, and props from Kenney's 3D asset packs (e.g. *Car Kit*, *Racing Kit*).
- Import as **glTF** where available.

## 6. Core Functional Requirements

| ID | Requirement |
|---|---|
| FR-1 | Player controls a car viewed from a top-down (high-angle/orthographic) camera. |
| FR-2 | Car physics: acceleration, braking/reverse, steering, and drift/grip behavior. |
| FR-3 | Camera follows the player car smoothly. |
| FR-4 | At least one drivable track built from Kenney track pieces, with collision. |
| FR-5 | Lap detection and timing (start/finish line, lap counter, lap times). |
| FR-6 | Gamepad input: analog steering + throttle, with keyboard fallback. |
| FR-7 | Main menu and pause menu (start, restart, quit). |

## 7. Input Mapping

Use Godot's `InputMap` actions so bindings are device-agnostic.

| Action | Gamepad | Keyboard fallback |
|---|---|---|
| Accelerate | Right trigger (R2) | W / Up |
| Brake / Reverse | Left trigger (L2) | S / Down |
| Steer | Left stick X | A / D or Left / Right |
| Handbrake | A / Cross | Space |
| Pause | Start | Esc |

- Read steering/throttle via analog axes (`Input.get_axis` / `get_vector`) for smooth control.
- Auto-detect controller connect/disconnect.

## 8. Performance Requirements

- **Target:** locked 60 fps on a mid-range desktop GPU at 1080p.
- Use a fixed physics tick for deterministic car handling.
- Keep draw calls low.
- Profile with Godot's built-in profiler; budget frame time < 16.6 ms.

## 9. Open Questions

- macOS: confirmed target or drop to "best-effort"? (Affects signing/notarization effort.)
- Physics approach: Godot `VehicleBody3D` (arcade-realistic) vs. custom `RigidBody3D` arcade handling — to be prototyped.
- Single-player only for v1, or design data structures to allow split-screen later?

## 10. Suggested Milestones

1. **Prototype** → verify: a Kenney car model drives top-down with gamepad input.
2. **Track + collision** → verify: car drives a closed loop on a Kenney track with walls.
3. **Lap timing** → verify: laps and times recorded correctly across a full lap.
4. **Menus + polish** → verify: start/pause/restart flow works on all primary platforms.
5. **Export builds** → verify: 60 fps confirmed on Linux and Windows builds.
