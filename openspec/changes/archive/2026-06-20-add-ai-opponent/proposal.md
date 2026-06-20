## Why

Single-player is currently a solo drive: the pickup/combat loop (fireballs, health, WASTED/WINNER) only matters when there is a second car to fight. Without an opponent, 1P mode has no stakes. A simple computer-driven opponent turns 1P into an actual contest using the systems that already exist.

## What Changes

- Single-player races SHALL spawn one **AI-controlled opponent car** alongside the player's car, sharing the same world. It is a full vehicle: it collects and uses pickups, can be hit by fireballs, loses health, can be eliminated (ending the match with WINNER/WASTED), and respawns if it falls off the edge — all reusing the existing `Car` systems.
- The AI drives itself with a small behaviour controller that supplies throttle/steer/handbrake to its `Car` (instead of the keyboard/gamepad InputMap), following three rules:
  1. **No item held → seek the nearest available pickup.**
  2. **Holding an item → hunt the player**, weaving so it never drives straight for more than ~0.5 s.
  3. **Firing a fireball has a 50% chance to miss** (deliberately aimed wide half the time).
- The single full-screen chase camera keeps following the **player's** car; the opponent is simply visible in the shared world.
- A headless behavioural test (`tools/ai_test.gd`) covers seek-pickup, weave-not-straight, and the fireball aim/miss behaviour.

The AI opponent is enabled for the real 1P launch flow (the landing screen turns it on when "1P" is chosen). It is **off by default** when `Main.tscn` is loaded directly, so the existing headless tests (`drive_test`, `ground_test`, `respawn_test`, `pickup_test`) keep their deterministic single-car scene unchanged.

## Capabilities

### New Capabilities
- `ai-opponent`: A computer-driven opponent car in single-player — its presence in the world, and the seek-pickup / hunt-and-weave / fireball-with-50%-miss behaviour that drives it.

### Modified Capabilities
- `split-screen`: The "single-player remains full screen" requirement is updated — the single full-screen view and lone chase camera follow the player's car as before, but the shared world MAY now also contain the AI opponent car.

## Impact

- **New:** `scripts/ai_driver.gd` (the behaviour controller), `tools/ai_test.gd` (headless test).
- **Modified:** `scripts/car.gd` (allow control inputs to come from an AI controller instead of the InputMap), `scripts/main.gd` (spawn + wire the AI car and its driver in single-player, and include it in fall-respawn and elimination bookkeeping), `scripts/selection.gd` (an `ai_opponent` flag), `scripts/landing_screen.gd` (set the flag when 1P is confirmed).
- **Specs:** new `ai-opponent` spec; delta to `split-screen`.
- Existing single-player headless tests are unaffected because the AI defaults off when `Main.tscn` is launched directly.
