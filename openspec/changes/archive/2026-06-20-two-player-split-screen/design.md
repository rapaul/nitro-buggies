## Context

The game is single-player throughout. `LandingScreen.tscn` shows the title and a single vehicle picker, writes the chosen model to the `Selection` autoload, and changes to `Main.tscn`. `Main.tscn` holds the 3D world (terrain, light, one `Car`, one `Camera3D`) directly in the root viewport. `car.gd` reads global `InputMap` actions (`accelerate`, `brake`, `steer_left`, `steer_right`, `handbrake`) via `Input.get_axis`, where each action is bound to WASD **and** arrow keys **and** gamepad. `main.gd` handles off-edge respawn for the single `$Car`.

Headless harnesses (`drive_test`, `ground_test`, `respawn_test`) load `Main.tscn` directly and assume one `$Car` plus the existing global action names. The renderer is `gl_compatibility` (WebGL2-compatible), which supports multiple viewports.

This change adds a local two-player mode: a 1P/2P choice on the landing screen, simultaneous split-screen vehicle picking, then a horizontally split race with one car and chase camera per player and an independent keyboard control set per player.

## Goals / Non-Goals

**Goals:**
- A 1P/2P selection on launch, in the title font, with the vehicle picker's chunky square highlight.
- 2P vehicle picking shown simultaneously in split halves (P1 top, P2 bottom), each driven by its player's keys; race starts when both confirm.
- 2P race split horizontally (P1 top, P2 bottom), each a chase camera following its own car.
- 2P keyboard split: P1 = WASD, P2 = arrow keys, each driving only its own car.
- Single-player path (and all existing headless tests) unchanged in behavior.

**Non-Goals:**
- Per-player gamepads / device assignment (keyboard split is the 2P scheme; gamepad stays on the single-player car). Splitting analog gamepad input across two players is out of scope.
- Vertical or >2 player splits, scoring/laps/finish logic, or networked play.
- Changing car handling, terrain, or camera feel.

## Decisions

### Selection state
Extend the `Selection` autoload with `player_count := 1` and a second model path. Keep `selected_model_path` as Player 1's model (preserves the `car.gd` default and `drive_test`), and add `player2_model_path := "res://assets/race.glb"`. `main.gd` reads `player_count` to choose the single- vs split-screen build. Defaulting to 1 keeps `Main.tscn`-direct and headless launches single-player.

### Per-player input actions
Add a second keyboard control set rather than reusing the shared actions. Concretely:
- Player 1 keeps the existing actions (`accelerate`, `brake`, `steer_left`, `steer_right`, `handbrake`) but the **arrow-key events are removed** from them, leaving WASD + Space + gamepad. This keeps `drive_test` (which presses the existing actions) and 1P unchanged.
- Player 2 gets new actions `p2_accelerate`, `p2_brake`, `p2_steer_left`, `p2_steer_right`, `p2_handbrake` bound to the arrow keys (+ a handbrake key, e.g. Right Shift).
- Picker confirm needs to be independent per player: add `p1_accept` (e.g. Space) and `p2_accept` (e.g. Enter / Right Shift). The mode-select stage and 1P picker keep using the global `ui_accept`.

`car.gd` gains an exported `input_prefix := ""`. It builds action names as `input_prefix + "accelerate"`, etc. Player 1's car uses `""` (existing names); Player 2's car uses `"p2_"`. This is the smallest change that gives each car its own action set without renaming existing actions.

*Alternative considered:* renaming all actions to `p1_*`/`p2_*` for symmetry — rejected because it breaks `drive_test` and the established 1P bindings for no functional gain.

### Split-screen rendering
Use two `SubViewportContainer` → `SubViewport` nodes stacked vertically (each anchored to its half), sharing one `World3D` so terrain, lights, and both cars exist once. The 3D world stays under `Main`; each `SubViewport` is set to render that same world via `world_3d = <shared world>` (built in code, like the camera wiring already is). Each `SubViewport` holds its own `Camera3D` running `camera.gd`, targeting that player's car.

In **single-player** `main.gd` keeps today's setup verbatim — the world in the root viewport with the existing `$Camera3D` — so nothing about the 1P render path or tests changes. The split-viewport setup is built only when `player_count == 2`.

*Alternative considered:* always routing through SubViewports (even for 1P) for uniformity — rejected to keep the 1P path and its tests untouched and avoid a needless render indirection.

### Landing screen staging
`landing_screen.gd` becomes a small state machine: `STAGE_MODE` → `STAGE_PICK`. 
- `STAGE_MODE`: build two labels "1P"/"2P" in the title font (`Kenney Blocks.ttf`) with a reused chunky-square `Panel` highlight; navigate with `ui_left`/`ui_right`; `ui_accept` records `Selection.player_count` and enters `STAGE_PICK`.
- `STAGE_PICK`, 1P: the existing single full-screen picker, confirmed with `ui_accept`, writes `selected_model_path`, changes scene.
- `STAGE_PICK`, 2P: build **two** pickers — Player 1's in the top half, Player 2's in the bottom half — each with its own three models, highlight, and confirm latch. P1 navigates with `steer_left`/`steer_right` (A/D) and confirms with `p1_accept`; P2 navigates with `p2_steer_left`/`p2_steer_right` (arrows) and confirms with `p2_accept`. When both latches are set, write both model paths and change scene.

The existing picker build (`_build_picker`, `_build_preview`, framing) is generalized to lay out within a given rectangle (full screen, top half, or bottom half) so the same code serves all three cases.

### Respawn for each car
`main.gd`'s off-edge respawn loop generalizes from `$Car` to iterate the active cars (one or two), tracking a fall timer per car, so either car respawns independently.

## Risks / Trade-offs

- **Shared-world SubViewport wiring** → If a SubViewport isn't pointed at the shared `World3D`, a half renders empty. Mitigate by setting `world_3d` in code (the project already wires nodes in code for this reason) and visually verifying with a windowed screenshot of the 2P race.
- **Headless tests assume one `$Car`** → Keep `player_count` defaulting to 1 and keep the 1P build path byte-for-byte equivalent so `drive_test`/`ground_test`/`respawn_test` still find `$Car`. Add 2P coverage as new tests, not by changing the 1P assumptions.
- **Two halves cost ~2x 3D draw** → Acceptable for two cars on this terrain; `gl_compatibility` handles multiple viewports. Watch frame rate in the windowed check.
- **Key reachability** → Arrow-key player needs a handbrake/confirm key near the arrows (e.g. Right Shift / Enter); pick keys that don't collide with WASD or Space.
- **Stretch mode** → The project uses `canvas_items` stretch; the split containers must anchor to true half-height so the divide stays at 50% across resolutions.

## Migration Plan

Additive; no data migration. Default `player_count = 1` preserves current behavior. Verify with `godot --headless --import`, the existing headless harnesses (must stay green), and a windowed screenshot of both the 2P split picker and the 2P split race. Rollback is reverting the change set.

## Open Questions

- Exact Player 2 handbrake and per-player confirm keys (proposed: P2 handbrake = Right Shift, P1 confirm = Space, P2 confirm = Enter) — finalize during implementation against key collisions.
- Whether to show a small "Player 1 / Player 2" label above each split picker half for clarity (minor; default to including a lightweight label in the title font).
