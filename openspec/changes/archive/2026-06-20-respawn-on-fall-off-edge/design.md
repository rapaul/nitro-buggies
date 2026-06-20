## Context

The dune surface (`DuneHeight`) and its collision heightmap are both built only over the play area `±HALF` (100 m) on X and Z — see `scripts/main.gd` (`HALF`, `_build_collision`). Outside that square there is no collision shape, so a `CharacterBody3D` car that crosses the edge is permanently airborne: `car.gd._physics_process` sees `not is_on_floor()`, applies gravity each tick, and the car falls forever.

`main.gd` is the scene controller. It already builds the terrain and holds the `Car` reference (`$Car`, wired to the camera in `_ready`). `car.gd` owns all motion state — `velocity`, plus airborne/orientation bookkeeping (`_was_airborne`, `_air_time`, `_air_angvel`, mesh quaternions, `_mesh_y_offset`).

The middle of the play area is flat by construction: `DuneHeight.height(x, z)` carries `sin(x·kx)·sin(z·kz)`, so height at the origin is exactly 0. "20 m above the ground" at the centre is therefore `y = 20`.

## Goals / Non-Goals

**Goals:**
- Automatically return the car to play after it falls off the edge.
- Trigger only on a *sustained* (1 s) fall past the edge, not on ordinary jumps/airtime.
- Reset the car cleanly on respawn (no retained fall velocity, no stuck airborne tumble state).

**Non-Goals:**
- No walls, fences, or invisible barriers at the edge — the car is allowed to drive off; it just gets recovered.
- No respawn UI, fade, countdown, or sound.
- No camera special-casing — the existing follow camera tracks the car to its new position naturally.
- No checkpoint / last-safe-position system; respawn is always the centre.

## Decisions

### Detection lives in `main.gd`, using horizontal bounds
`main.gd` already owns `HALF` and the `Car` reference, so it is the natural place to know "where the edge is." Each frame it checks whether `abs(car.x) > HALF or abs(car.z) > HALF`.

- **Why bounds, not a Y threshold?** Out-of-bounds is the exact definition of "fell off the edge" and reads directly from the world geometry `main.gd` already owns. A "below some Y" heuristic would couple the trigger to dune amplitude and need a magic margin. Bounds are unambiguous and self-documenting.
- **Alternative considered:** putting detection in `car.gd`. Rejected — the car has no knowledge of the world extent; passing `HALF` into it would just move the coupling. `main.gd` is the world authority.

### Timer accumulates while out of bounds; resets on return
`main.gd` keeps a `_fall_time` float. In `_process(delta)`: if out of bounds, `_fall_time += delta`; otherwise `_fall_time = 0.0`. When `_fall_time >= FALL_LIMIT` (1.0), respawn and reset `_fall_time = 0.0`.

- This makes a brief excursion that returns in-bounds harmless (timer resets), satisfying the "returning before the delay cancels respawn" scenario, and leaves normal in-bounds jumps completely untouched.
- `_process` (per-frame) is fine; the 1 s threshold is coarse and frame-rate exactness is not required here (unlike the handling physics, which stays in `_physics_process`).

### `car.gd` exposes `respawn(pos: Vector3)` that resets its own state
`main.gd` computes the spawn point and calls `car.respawn(spawn)`. The car sets `global_position = pos`, `velocity = Vector3.ZERO`, and resets the airborne/orientation bookkeeping so it doesn't land with a stale tumble (`_was_airborne = false`, `_air_time = 0.0`, `_air_angvel = Vector3.ZERO`).

- **Why a method on the car rather than `main` poking fields?** Encapsulation: the car owns its motion/orientation state and is the only place that knows what must be reset. `main` owns *when/where*, the car owns *how it resets*. Mirrors the existing split (camera wired from `main`, handling internal to the car).
- Spawn point: `Vector3(0, DuneHeight.height(0, 0) + 20.0, 0)`. Written via `DuneHeight.height` rather than the literal `20` so it stays "20 above the ground" if the centre ever stops being flat.

### Constants
`FALL_LIMIT := 1.0` (seconds) and `RESPAWN_HEIGHT := 20.0` (m) as named constants in `main.gd`, matching the project's style of self-documenting tuning constants.

## Risks / Trade-offs

- **Driving back in-bounds within 1 s resets the timer mid-fall** → Intended per the spec; this is the mechanism that spares normal play. Once truly off the edge the car cannot get back in-bounds (no ground to drive on), so in practice the 1 s always completes.
- **`_process` vs `_physics_process` timing** → A respawn could fire up to one render frame late. Negligible for a 1 s gameplay timer; keeps physics integration untouched.
- **Respawn mid-air leaves the car briefly airborne at y=20** → Desired ("respawn 20 m above the ground"); it falls and lands via the existing grounding logic, which already firm-seats the mesh on the landing tick.
