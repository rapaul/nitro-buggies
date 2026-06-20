## 1. Input actions

- [x] 1.1 Add `use_item` (P1 keyboard key + gamepad button) and `p2_use_item` (P2 keyboard key) actions to `project.godot`, picking keys that don't clash with WASD/Space (P1) or arrows/Right-Shift/Enter (P2).

## 2. Vehicle held item, health, and effects (`car.gd`)

- [x] 2.1 Add a held-item enum (`NONE/NITRO/FIREBALL`) and `held_item` state, plus `collect(type) -> bool` that sets the item only when currently `NONE` (returns false otherwise — enforces no-replace). Emit a `held_item_changed` signal.
- [x] 2.2 Add `health := 3`, `take_damage(n)` clamping at 0, and an `eliminated` signal fired when health reaches 0; emit `health_changed` on any change.
- [x] 2.3 Read `input_prefix + "use_item"` and, when pressed with a held item, dispatch on type and clear the item (box goes empty); do nothing when empty.
- [x] 2.4 Implement nitro: a 5 s timer that multiplies the effective `max_forward_speed` (and acceleration) by 2 while active, reverting when it lapses.
- [x] 2.5 Implement the fireball request: on use of a fireball, emit a signal (e.g. `fired_fireball(origin, heading)`) for `main.gd` to spawn into the shared world; record the firing car as the projectile owner.

## 3. Pickup world item (`scripts/pickup.gd`)

- [x] 3.1 Create a `Pickup` `Area3D` with a type field, a code-built colour-coded emissive mesh, and a sphere collision shape, with `collision_mask` set to detect the cars' physics layer.
- [x] 3.2 On `body_entered` by a car, call `car.collect(type)`; if accepted, hide/disable the pickup and start a respawn timer that re-enables it after the delay.

## 4. Fireball projectile (`scripts/fireball.gd`)

- [x] 4.1 Create a `Fireball` `Area3D` with `owner_car`, a heading, a speed, and a code-built mesh; each `_physics_process` advance along the heading and set `y = DuneHeight.height(x, z) + offset` to hug the terrain.
- [x] 4.2 Despawn (free) once it passes ~10 m beyond the `±HALF` play-area edge on X or Z.
- [x] 4.3 On `body_entered` by a car that is not `owner_car`, call `car.take_damage(1)` and free the fireball.

## 5. Spawning and orchestration (`main.gd`)

- [x] 5.1 Define the eight fixed pickup spots (`{x, z, type}` clear of the spawn points) and instantiate a `Pickup` at each, seated on the dune surface.
- [x] 5.2 Connect each car's `fired_fireball` signal and spawn a `Fireball` into the shared world (sibling of the cars) at the requested origin/heading.
- [x] 5.3 Ensure a `CanvasLayer` exists for HUD/overlays in both 1P (new) and 2P (existing), and compute the per-player view rects once for both the views and the HUDs.

## 6. Per-player HUD (`scripts/hud.gd`)

- [x] 6.1 Create a `HUD` `Control` bound to one car and one screen rect: a 3-segment health bar (top-left) and a held-item box (lower-right), updating from the car's `held_item_changed` / `health_changed` signals.
- [x] 6.2 Mount one HUD per player on the HUD `CanvasLayer` — full-screen rect in 1P, each split half in 2P.

## 7. Match outcome overlays (`main.gd` + HUD layer)

- [x] 7.1 On a car's `eliminated` signal, mark the match over and freeze gameplay (stop the cars' processing / terminal state).
- [x] 7.2 Draw a fade + "WASTED" (red/orange, Kenney Blocks title font) over the eliminated player's rect, and "WINNER" (gold, same font) over each surviving player's rect.

## 8. Tests and verification

- [x] 8.1 Write `tools/pickup_test.gd` (headless): assert collect-sets-item, second pickup does not replace, nitro doubles the effective top speed for ~5 s then reverts, a fired fireball advances along the heading and rides `DuneHeight`, despawns ~10 m past the edge, and that `take_damage` removes one bar and emits `eliminated` at zero.
- [x] 8.2 Add a screenshot tool (in the style of `tools/landing_shot.gd`) that renders the HUD and a WASTED/WINNER frame for visual verification; read the PNGs to confirm.
- [x] 8.3 Run `godot --headless --import`, the new `pickup_test.gd`, and the existing `drive_test.gd` / `two_player_test.gd` to confirm nothing regressed; document the new test in `CLAUDE.md`.
