## Context

The car (`scripts/car.gd`, `class_name Car`, a `CharacterBody3D`) reads its controls every physics tick from the InputMap, namespaced by `input_prefix` (`""` for P1, `"p2_"` for P2):

```gdscript
var throttle := Input.get_axis(input_prefix + "brake", input_prefix + "accelerate")
var steer_input := Input.get_axis(input_prefix + "steer_left", input_prefix + "steer_right")
var handbraking := Input.is_action_pressed(input_prefix + "handbrake")
```

It already exposes everything an opponent needs: `collect()`, `use_item()`, `take_damage()`, `respawn()`, the `held_item` enum (`NONE/NITRO/FIREBALL`), and the `fired_fireball`/`eliminated` signals. `main.gd` owns the shared world: it spawns cars, the eight `PICKUP_SPOTS`, the pickups, wires HUDs and `eliminated`, spawns fireballs on `fired_fireball`, and runs the off-edge fall-respawn loop over a `_cars` array.

So the opponent is "just another `Car`" with two differences: (1) its control inputs come from code, not the InputMap, and (2) something has to decide those inputs each tick. Everything else (physics, pickups, fireballs, damage, elimination, respawn) is reused unchanged.

The AI only exists in single-player. In 2P both cars are human. The existing headless tests launch `Main.tscn` directly with `Selection` defaults (player_count == 1) and assert a single-car scene, so the AI must not appear in that path.

## Goals / Non-Goals

**Goals:**
- One AI opponent car in 1P that drives itself via the three rules: seek pickup when empty → hunt player while armed (weaving, never straight > ~0.5 s) → fire fireball with a 50% miss chance.
- Reuse the existing `Car` for the opponent (pickups, fireball, damage, elimination, fall-respawn) with no behavioural changes to the player car.
- Keep the existing single-player headless tests deterministic and unchanged (AI off when `Main.tscn` is launched directly).
- A headless `tools/ai_test.gd` that verifies seek-pickup, weave, and the fireball aim/miss mechanism.

**Non-Goals:**
- No pathfinding, obstacle avoidance, or terrain awareness — straight-line steering toward a target on the flat-ish dunes is enough for a "basic" AI.
- No difficulty tiers, no tuning UI, no opponent HUD (health bar / item box) in 1P.
- No AI in 2P, and no change to 2P.
- No analog/gamepad concerns for the AI (it writes control values directly).

## Decisions

### 1. The car reads controls through an overridable hook, not the InputMap directly
Add three control fields to `Car` that default to "read the InputMap" and a flag the AI sets:

- `var ai_controlled := false`
- `var ai_throttle := 0.0`, `var ai_steer := 0.0`, `var ai_handbrake := false`

In `_physics_process`, replace the three `Input.*` reads with:

```gdscript
var throttle: float
var steer_input: float
var handbraking: bool
if ai_controlled:
    throttle = ai_throttle
    steer_input = ai_steer
    handbraking = ai_handbrake
else:
    throttle = Input.get_axis(input_prefix + "brake", input_prefix + "accelerate")
    steer_input = Input.get_axis(input_prefix + "steer_left", input_prefix + "steer_right")
    handbraking = Input.is_action_pressed(input_prefix + "handbrake")
```

`ai_steer`/`ai_throttle` use the **same sign and magnitude convention** as `get_axis` so the downstream physics is untouched: `steer_input` positive = steer right (matches `get_axis(steer_left, steer_right)`), `throttle` in [-1, 1]. The AI also skips the InputMap `use_item` path — it calls `car.use_item()` directly — so `_unhandled_input` is left alone.

*Alternative considered:* feed synthetic input via `Input.action_press(...)`. Rejected — input actions are global, so the AI's presses would also be seen by the player car (and any test), and magnitudes/sign would be awkward. A per-car field is local and explicit.

### 2. The AI brain is a separate `Node` (`scripts/ai_driver.gd`), one per opponent car
A small `Node` holding references to its `car`, the `player` car, and the pickup spots, run from its own `_physics_process`. Each tick it:

1. Picks a **target** by rule:
   - `car.held_item == Item.NONE` → nearest **available** pickup position (a pickup spot whose node is currently `visible`). Steer toward it; full throttle; no weave (it needs to actually arrive).
   - else (holding an item) → the **player** car's position. Steer toward it **plus the weave offset** (Decision 3). Then act on the held item (Decision 4).
2. Computes steering from the horizontal angle between the car's forward (`-car.global_transform.basis.z`) and the direction to the target. Sign via the cross product's Y component; magnitude `clampf(angle / k, -1, 1)`. The weave bias is added on top and re-clamped.
3. Writes `car.ai_throttle`, `car.ai_steer`, `car.ai_handbrake` (handbrake stays false for v1).

`main.gd` constructs the driver in `_setup_single_player`, sets `car.ai_controlled = true`, and passes it the player car and the `PICKUP_SPOTS`/pickup nodes. The driver reads pickup availability from the pickup nodes `main` already created (it spawns pickups before/after wiring — order the setup so the driver gets the live nodes, or have the driver look them up by group). Simplest: `main` keeps the spawned pickup `Area3D`s in a list and hands that list to the driver; the driver treats `visible == true` as available (matching `pickup.gd`'s `_set_available`).

### 3. Weave: a sign that flips on a ≤0.5 s timer, added to the steering toward the player
Keep a `_weave_dir` (∈ {-1, +1}) and a `_weave_timer`. Each tick `_weave_timer -= delta`; when it hits zero, flip `_weave_dir` and reset the timer to the weave period (≤ 0.5 s, e.g. 0.4 s so the requirement's "no longer than ~0.5 s" holds with margin). The final steer is `clamp(steer_to_player + WEAVE_STRENGTH * _weave_dir, -1, 1)`. Because the weave term is always non-zero and reverses every period, the net steering is never a sustained straight line — satisfying "never drive straight for more than 0.5 s." Weave is applied only in the hunt-the-player phase.

*Why add a bias rather than ignore the target:* the AI still generally closes on the player (the steer-to-player term pulls it in) while visibly weaving, which both reads as "basic AI" and makes its fireballs harder to line up — consistent with the playful 50% miss.

### 4. Fireball with a 50% miss: decide hit/miss once per fireball, aim accordingly
When the AI is holding a fireball and hunting:
- On acquiring the fireball, roll once: `_fireball_will_miss = rng.randf() < 0.5`.
- Choose an **aim point**: the player's position for a hit, or the player's position offset sideways by a fixed lateral distance (e.g. ±12 m perpendicular to the line of sight) for a miss.
- Steer toward the aim point (with weave still applied). When the car's heading is within a small tolerance of the aim point, call `car.use_item()`. Because the fireball launches straight along the car's heading (`car.gd`'s `use_item`), aiming at the offset point makes the shot fly wide → a miss; aiming at the player makes it a hit.

This implements "50% chance to miss" as a per-shot commitment rather than a coin flip at the physics of impact, which keeps it deterministic to aim and easy to test. The RNG is a `RandomNumberGenerator` owned by the driver; the test can set its `seed` (or call a seam) to force hit/miss and assert the resulting aim/outcome.

Nitro (Decision: AI uses a held nitro immediately while hunting) just calls `car.use_item()` on the next tick, clearing the item so the AI returns to seeking pickups.

### 5. Enablement flag keeps existing tests deterministic
Add `var ai_opponent := false` to `Selection`. `landing_screen.gd`, where it already sets `Selection.player_count = _mode_selected + 1` on mode confirm, also sets `Selection.ai_opponent = (Selection.player_count == 1)`. `main.gd`'s `_setup_single_player` spawns the AI car only when `Selection.ai_opponent` is true. Launched directly (the headless tests), the flag is false → single-car scene, unchanged. `tools/ai_test.gd` sets it true explicitly.

### 6. Opponent wired into fall-respawn and elimination, but no HUD
`main` appends the AI car to `_cars`/`_fall_times` so the off-edge respawn covers it. For elimination, the AI car's `eliminated` is connected so that when the AI dies the player sees WINNER, and when the player dies the player sees WASTED — reusing `_on_car_eliminated`. The player keeps the only HUD (full screen); the AI gets no HUD/health-bar overlay (out of scope). The match-over freeze (`set_physics_process(false)`) must also stop the AI driver, so the driver either checks a paused/over flag or `main` disables it alongside the cars.

## Risks / Trade-offs

- **AI car perturbs the existing 1P tests** → Mitigated by the `ai_opponent` flag defaulting off; `drive_test`/`ground_test`/`respawn_test`/`pickup_test` load `Main.tscn` directly and never set it, so they stay single-car and deterministic.
- **Steering sign wrong (AI drives away from target)** → The cross-product sign must match `car.gd`'s `get_axis`/`rotate_y` convention. `ai_test.gd` asserts the AI closes distance on its target, which fails loudly if the sign is inverted; pin the sign during implementation against that test.
- **Weave overwhelms or never reaches the target** → `WEAVE_STRENGTH` is partial (e.g. ~0.5) so the steer-to-player term still dominates when badly misaligned; tune so the AI both weaves and converges. The test asserts both "steer reverses within ~0.5 s" and "distance to player trends down."
- **50% miss is probabilistic and flaky to test** → The per-shot decision uses a seedable RNG and an observable aim point, so the test forces miss/hit deterministically and checks the aim offset (and optionally a fired fireball's outcome) rather than relying on statistical sampling.
- **Match-over doesn't freeze the AI** → Disable the driver when the match ends (same place the cars' processing is disabled), or the AI keeps driving under the WASTED/WINNER overlay.

## Open Questions

- Should the opponent's health be shown somewhere in 1P (a small enemy bar) so the player can gauge progress? Out of scope for this change; the player can still eliminate it, ending the match — revisit if playtesting wants feedback.
- Weave period and strength, fireball aim tolerance, and miss-offset distance are tuning values; start from the suggested figures and adjust against feel during `/opsx:apply`.
