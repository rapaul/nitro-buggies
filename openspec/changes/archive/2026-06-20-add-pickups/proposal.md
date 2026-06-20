## Why

The race is currently pure driving — there is no way to gain an edge over an opponent or to win or lose. Adding collectible pickups (a speed boost and an offensive fireball), vehicle health, and win/lose end states turns the split-screen race into an actual contest with a goal.

## What Changes

- **Pickups in the world.** A handful of fixed spots on the dune surface each hold a pickup (nitro or fireball). Driving a car over a pickup grants its item. Each spot respawns its pickup a short time after it is taken.
- **Hold one item, no replacement.** A car holds at most one pickup. Driving over another pickup while already holding one does nothing (the held item is not replaced).
- **Pickup box HUD.** The car's currently held pickup is shown in a box in the lower-right of that player's view (full screen in 1P, that player's half in 2P).
- **Use action.** A per-player "use item" input activates the held pickup, consuming it. (Holding the item until the player fires it is implied by showing it persistently and by the no-replace rule — so a trigger is required.)
- **Nitro effect.** Using a nitro applies a 2× top-speed boost for 5 seconds, then reverts.
- **Fireball effect.** Using a fireball launches a projectile straight ahead of the car that hugs the terrain surface, travelling until it passes ~10 m beyond the play-area edge, where it disappears. If it strikes an enemy vehicle it removes one of that vehicle's health bars and is consumed.
- **Vehicle health.** Every vehicle has a 3-bar health bar, shown on that player's view. A fireball hit removes one bar. Losing all three bars eliminates that vehicle.
- **Win / lose end states.** When a vehicle loses all its health bars, that player loses: their portion of the screen fades and shows **"WASTED"** in the title font, coloured red/orange. The remaining player's view shows **"WINNER"** in the title font, coloured gold.
- The combat loop (health, fireball damage, win/lose) is wired for both 1P and 2P. 1P has no enemy car yet, so no damage occurs there until a later change adds an AI opponent; the infrastructure is shared.

## Capabilities

### New Capabilities
- `pickups`: Pickup items in the world (fixed respawning spots), drive-over collection, the hold-one/no-replace rule, the lower-right pickup box HUD, the per-player use action, and the two item effects (nitro 2× boost for 5 s; fireball terrain-following projectile that despawns past the edge and removes one enemy health bar on hit).
- `vehicle-health`: A 3-bar health value per vehicle, the on-screen health bar, taking damage (a fireball hit removes one bar), and elimination when all bars are gone.
- `match-outcome`: The per-player win/lose end states — the loser's view fades with "WASTED" (red/orange, title font) and the surviving player's view shows "WINNER" (gold, title font).

### Modified Capabilities
- `player-input`: Adds a per-player "use item" action (Player 1 and Player 2 each get one, keyboard with gamepad fallback) so the held pickup can be triggered.

## Impact

- **Scripts:** `scripts/car.gd` (held pickup, use action, nitro boost, health, take-damage/elimination hooks), `scripts/main.gd` (spawn pickup spots, mount per-player HUD and outcome overlays, route fireball spawning into the shared world). New: `scripts/pickup.gd` (the world item), `scripts/fireball.gd` (the projectile), `scripts/hud.gd` (per-player pickup box + health bar + outcome overlay).
- **Input:** `project.godot` gains `use_item` and `p2_use_item` actions.
- **Specs:** new `pickups`, `vehicle-health`, `match-outcome`; modified `player-input`.
- **Reused:** `DuneHeight.height()` for seating pickups and for the fireball's terrain-following; the `±HALF` play bounds for the fireball's off-edge despawn; the title font (Kenney Blocks) for WASTED/WINNER; the existing per-player view rects from split-screen for HUD placement; the car collision layer for fireball hit detection.
- **Tests:** new `tools/pickup_test.gd` (collect/hold-one/nitro/fireball/damage/elimination, headless) and a screenshot tool for the HUD and WASTED/WINNER overlays.
