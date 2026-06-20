## Why

The game is single-player only: one car, one full-screen camera, all keyboard and gamepad bindings feeding the same car. Adding a local two-player mode lets two people race head-to-head on one machine — the natural next step for a couch arcade racer — while keeping the existing single-player experience intact.

## What Changes

- The landing screen gains a **player-count selection** step shown first on launch: two labels, **1P** and **2P**, drawn in the title's block display font, with the same chunky square selection box used by the vehicle picker. The player navigates between them and confirms.
- After choosing the mode, vehicle picking happens **per player**. In 1P a single full-screen picker is shown. In 2P the screen **splits horizontally** — Player 1 picks in the top half, Player 2 in the bottom half, **both at the same time**, each navigating with their own keys; once **both** have confirmed, the race starts.
- In **2P** the race renders **split-screen, divided horizontally** — Player 1's view on top, Player 2's on the bottom — each half a third-person chase camera following that player's own car.
- In **2P**, **Player 1 drives with WASD** (+ Space handbrake) and **Player 2 drives with the arrow keys** (+ a dedicated handbrake key). Arrow keys no longer alias the single shared driving actions; they become Player 2's controls.
- **1P** is unchanged in feel: one car, one full-screen camera, driven by WASD and gamepad.

## Capabilities

### New Capabilities
- `player-count-selection`: choosing single- vs two-player on the landing screen, presented as 1P/2P labels in the title font with the chunky square selection box, navigable and confirmable.
- `split-screen`: in two-player mode, the race renders two stacked viewports (P1 top, P2 bottom) of the shared world, each with its own chase camera and its own car.

### Modified Capabilities
- `landing-screen`: the flow becomes staged — mode selection first, then one or two vehicle picks — and confirming advances through the stages rather than starting the race immediately.
- `vehicle-selection`: in two-player mode two pickers are shown at once in split halves (Player 1 top, Player 2 bottom), each navigated by its player's keys, and each player's confirmed model carries into that player's car; the race starts only once both have confirmed.
- `player-input`: two-player mode splits the keyboard into two control sets — Player 1 on WASD, Player 2 on the arrow keys — each driving only its own car.

## Impact

- Code: `scripts/landing_screen.gd` (staged flow + mode UI), `scripts/main.gd` (split-screen setup, two cars, respawn for each car), `scripts/car.gd` (per-player input action set), `scripts/selection.gd` (store player count and per-player models), `scenes/Main.tscn` (viewport/camera restructure), `project.godot` (per-player input actions).
- Tests: existing headless harnesses (`drive_test`, `ground_test`, `respawn_test`, `landing_test`) must keep passing on the default single-player path; new coverage for the mode selection and 2P split.
- Default/headless behavior stays single-player so `Main.tscn` launched directly still has one `$Car`.
