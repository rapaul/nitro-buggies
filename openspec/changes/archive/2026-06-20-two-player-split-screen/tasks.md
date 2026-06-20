## 1. Input map & selection state

- [x] 1.1 In `project.godot`, remove the arrow-key events from `accelerate`/`brake`/`steer_left`/`steer_right` so they are Player 1 (WASD + Space + gamepad) only
- [x] 1.2 Add Player 2 driving actions `p2_accelerate`, `p2_brake`, `p2_steer_left`, `p2_steer_right`, `p2_handbrake` bound to the arrow keys and a P2 handbrake key (e.g. Right Shift)
- [x] 1.3 Add per-player confirm actions `p1_accept` (e.g. Space) and `p2_accept` (e.g. Enter / Right Shift) for the split picker
- [x] 1.4 Extend `scripts/selection.gd` with `player_count := 1` and `player2_model_path := "res://assets/race.glb"`

## 2. Per-player car input

- [x] 2.1 Add `@export var input_prefix := ""` to `scripts/car.gd` and read all driving actions as `input_prefix + "<action>"`
- [x] 2.2 Verify Player 1 (prefix `""`) still drives via the existing actions and `drive_test` passes

## 3. Landing screen: mode selection stage

- [x] 3.1 Refactor `scripts/landing_screen.gd` into a stage machine (`STAGE_MODE` → `STAGE_PICK`)
- [x] 3.2 Build the `STAGE_MODE` UI: "1P" and "2P" labels in the title font (`Kenney Blocks.ttf`), "1P" selected on entry
- [x] 3.3 Reuse the chunky square highlight (`StyleBoxFlat` border `Panel`) around the selected label
- [x] 3.4 Navigate with `ui_left`/`ui_right`; on `ui_accept` record `Selection.player_count` and enter `STAGE_PICK`

## 4. Landing screen: vehicle picking stage

- [x] 4.1 Generalize the picker build (`_build_picker`/`_build_preview`/framing) to lay out within a given rectangle
- [x] 4.2 1P: show a single full-screen picker; `ui_accept` writes `selected_model_path` and changes scene (unchanged behavior)
- [x] 4.3 2P: build two pickers — P1 in the top half, P2 in the bottom half — each with its own three random models and highlight
- [x] 4.4 2P: P1 navigates with `steer_left`/`steer_right` + `p1_accept`; P2 with `p2_steer_left`/`p2_steer_right` + `p2_accept`; each confirm latches independently
- [x] 4.5 2P: when both players have confirmed, write `selected_model_path` and `player2_model_path` and change scene

## 5. Race: split-screen rendering

- [x] 5.1 In `scripts/main.gd`, branch on `Selection.player_count`; keep the existing single-player build (root viewport, `$Car`, `$Camera3D`) for 1P
- [x] 5.2 For 2P, spawn a second car, applying each player's selected model and `input_prefix` (`""` and `"p2_"`)
- [x] 5.3 Build two stacked `SubViewportContainer`/`SubViewport` halves (P1 top, P2 bottom) sharing one `World3D`
- [x] 5.4 Add a `camera.gd` `Camera3D` in each half, targeting that player's car
- [x] 5.5 Generalize the off-edge respawn loop to track and respawn each active car independently

## 6. Verification

- [x] 6.1 `godot --headless --import` finishes with no error/warning
- [x] 6.2 Existing harnesses pass on the 1P path: `drive_test`, `ground_test`, `respawn_test`, `landing_test`
- [x] 6.3 Add a headless test that sets `Selection.player_count = 2` and asserts two cars exist and each responds only to its own action set
- [x] 6.4 Windowed screenshot (opengl3) of the 2P split picker — top/bottom halves each show a picker with its highlight
- [x] 6.5 Windowed screenshot (opengl3) of the 2P race — horizontal split, each half chasing its own car
- [x] 6.6 Update `CLAUDE.md` verification notes and `project.godot` input docs as needed
