## Context

The race today is `Main.tscn` driven by `main.gd`, which builds the dune terrain and spawns one car (1P) or two (2P). Each `Car` is a `CharacterBody3D` (`car.gd`) reading per-player `InputMap` actions via an `input_prefix` ("" / "p2_"). In 2P, `main.gd` mounts each player's view as a `SubViewportContainer` (anchored to a screen half) on a `CanvasLayer`, each holding a chase `Camera3D` on a shared `world_3d`. `DuneHeight.height(x, z)` is the single source of truth for the surface (used by the mesh, the collision heightmap, and tests); the play area is `±HALF` (100 m) on X and Z. The landing screen draws UI in code using the Kenney Blocks title font.

This change layers a pickup/combat loop on top: world items, a held-item HUD, two item effects, vehicle health, and win/lose overlays — reusing those existing seams (per-car `input_prefix`, `DuneHeight`, the per-player view rects, the title font) rather than introducing new infrastructure.

## Goals / Non-Goals

**Goals:**
- Pickups as world items at fixed, respawning spots; drive-over collection; hold-one/no-replace.
- A per-player HUD (held-pickup box lower-right, 3-bar health bar) that works in both the full-screen 1P view and each 2P split half.
- Nitro (2× top speed, 5 s) and fireball (terrain-following forward projectile, off-edge despawn, removes one enemy health bar) effects.
- Health + elimination + WASTED/WINNER overlays, wired identically for 1P and 2P.
- Headless-testable behaviour (collection, hold-one, nitro timing, fireball travel/despawn/damage, elimination) per the project's test convention.

**Non-Goals:**
- No AI opponent — 1P has no enemy to damage yet (a later change adds one). The combat code is shared so it lights up automatically when an opponent exists.
- No restart/return-to-menu flow after WASTED/WINNER (the overlay is terminal for this change).
- No changes to driving physics beyond the transient nitro top-speed multiplier.
- No new art assets — pickups and the fireball are code-built primitives, consistent with the existing in-code sand spray and UI.

## Decisions

### Pickup as `Area3D` at fixed spots, owned by `main.gd`
A `Pickup` (`scripts/pickup.gd`) is an `Area3D` with a sphere collision shape and a simple code-built emissive mesh (colour-coded per type: e.g. blue-ish nitro, red-ish fireball), seated at `Vector3(x, DuneHeight.height(x, z) + offset, z)`. `main.gd` holds a constant list of eight `{x, z, type}` spots (away from the car spawn points) and instantiates one pickup per spot. On `body_entered`, the pickup asks the entering car to collect it; if the car accepts (was empty), the pickup hides/disables and starts a respawn `Timer`, re-enabling after the delay.

- *Why fixed + respawn:* the user chose it; it is deterministic, which the headless test can rely on (drive a car to a known spot).
- *Alternative — random/timed spawns:* rejected (harder to test, not requested).
- *Detection:* cars already have a `CollisionShape3D` on the default physics layer, so an `Area3D` with `monitoring = true` picks them up with no car-side changes. The pickup reads the type the car will hold from its own `type` field.

### Held item + use action live on `car.gd`
`car.gd` gains `held_item` (enum `NONE/NITRO/FIREBALL`), `collect(type) -> bool` (sets and returns true only if currently `NONE`, enforcing no-replace), and reads a `input_prefix + "use_item"` action in `_physics_process` / `_unhandled_input`. On use it dispatches on `held_item`, clears it, and either starts the nitro timer or spawns a fireball. The car exposes a signal (e.g. `held_item_changed`, `health_changed`, `eliminated`) so the HUD can update without polling internals.

- *Why on the car:* held item and effects are per-vehicle state, parallel to the existing per-car `input_prefix`/`model_path`. Keeps `main.gd` as the world/HUD orchestrator.
- *Use trigger required:* persistently showing the held item + the no-replace rule imply you keep an item until you fire it, so a use action is needed. New actions `use_item` / `p2_use_item` go in `project.godot` (P1 keyboard key + gamepad button; P2 keyboard key), mirroring the existing `p2_` action set.

### Nitro as a top-speed multiplier with a timer
On use, set `_nitro_time = 5.0`; while `> 0`, multiply the effective `max_forward_speed` (and acceleration, so it can reach the higher cap) by 2 in `_physics_process`, decrementing by `delta`. No change to steering/grip.

- *Why multiply the cap rather than add an impulse:* "2× speed boost for 5 seconds" is a sustained higher cap, not a one-shot shove. Reverts cleanly by letting the timer lapse; engine drag brings speed back under the normal cap naturally.

### Fireball as a self-driving `Area3D` projectile
`scripts/fireball.gd` is an `Area3D` added to the shared world by `main.gd` (so it exists once and can hit any car), spawned at the firing car's front along `-basis.z`. Each `_physics_process` it advances by `speed * delta` along its fixed heading and sets `y = DuneHeight.height(x, z) + offset` to hug the surface. It despawns once `absf(x) > HALF + 10` or `absf(z) > HALF + 10`. On `body_entered` with a car that is not its owner, it calls `car.take_damage(1)` and frees itself. It records the firing car as `owner_car` to skip self-hits.

- *Why route spawning through `main.gd`:* in 2P both cars share one `world_3d`; the projectile must be a sibling in that world to collide with the other car. The car emits a "fire fireball" request (signal or direct call) that `main.gd` fulfils by instantiating into the world. In 1P it simply has nothing to hit yet.
- *Terrain follow via `DuneHeight`:* same source as everything else, so the fireball rides the exact visible surface; no raycasts needed.
- *Off-edge 10 m:* matches `main.gd`'s existing `±HALF` bound, extended by 10 m, consistent with the respawn system's notion of "off the edge".

### Per-player HUD as a `Control` over each view rect (`scripts/hud.gd`)
A `HUD` `Control` is built per player and bound to one car. It draws the 3-segment health bar (top-left) and the held-item box (lower-right), updating from the car's signals. In 2P it is anchored to that player's half (reusing the same top/bottom rects `main.gd` already computes for the split views); in 1P it covers the full screen. HUDs and the outcome overlays live on a `CanvasLayer` (2P already has one; 1P gets one).

- *Why reuse the split rects:* the HUD must sit inside each player's screen area, which is exactly the rect `main.gd` already uses for `_add_player_view`. One rect → one view + one HUD.
- *Why a `CanvasLayer` over the world:* HUD must draw on top of the 3D viewports and isn't itself a 3D object; this matches how the split views are already mounted.

### WASTED / WINNER as outcome overlays on the same HUD layer
When a car emits `eliminated`, `main.gd` flags the match over: it shows a fade + "WASTED" (red/orange) over the eliminated player's rect and "WINNER" (gold) over every surviving player's rect, both in the Kenney Blocks title font (the constant already lives in `landing_screen.gd`; promote the font path/colours to a shared spot or duplicate the small constant). Gameplay is frozen at that point (stop processing the cars / set the match to a terminal state).

- *Why per-rect overlays:* the requirement is explicitly "your part of the screen" — so it is drawn over a player's view rect, not the whole window. The same rect list drives it.

### Test surface
`tools/pickup_test.gd` (headless, `SceneTree`, sets `Selection.player_count` as needed, loads `Main.tscn`): asserts collect-sets-item, second-pickup-no-replace, nitro doubles the effective top speed for ~5 s then reverts, a fired fireball advances along the heading and hugs `DuneHeight`, despawns ~10 m past the edge, and removes one bar from an enemy car on contact / eliminates at zero. A screenshot tool (in the style of `landing_shot.gd`) renders the HUD and a WASTED/WINNER frame for visual verification (the words/colours/font can't be asserted headless).

## Risks / Trade-offs

- **Area3D vs CharacterBody3D detection** → cars are `CharacterBody3D` on the default layer; verify the pickup/fireball `Area3D` `collision_mask` includes that layer during implementation, and confirm `body_entered` fires for a kinematic body (it does for `move_and_slide`-driven bodies). Covered by the headless test.
- **Self-hit on fireball spawn** → spawning at the car's front could overlap the firing car on frame 1; mitigate by recording `owner_car` and skipping it, and spawning slightly ahead of the nose.
- **1P has no damage source** → WASTED/WINNER can't actually trigger in 1P until the AI change. Accepted: the elimination path is still unit-tested by directly calling `take_damage` in the harness, so the wiring is verified now.
- **Nitro overshoot** → doubling only the cap (not current velocity) means the car must accelerate into the higher cap; if that feels weak, the acceleration multiplier covers it. Tunable constant, low risk.
- **Font constant duplication** → the title font path/colours currently live in `landing_screen.gd`; reusing them for WASTED/WINNER means either a tiny shared constants script or a duplicated constant. Prefer a small shared script to avoid drift, but a local constant is acceptable for three values.

## Open Questions

- Exact keybindings for `use_item` / `p2_use_item` (e.g. P1 = `E` or `Left Ctrl`, P2 = `Right Ctrl` / numpad) and the gamepad button — chosen during implementation to avoid clashing with existing WASD/Space and arrows/Right-Shift bindings.
- Placement of the eight fixed pickup spots (clear of the centre spawn) and the nitro/fireball split across them — a tuning detail finalised in code.
