## Why

The dune play area is finite (±100 m on X and Z); beyond its edge there is no terrain or collision, so a car that drives off the edge free-falls forever with no way to recover short of restarting. Players need to be returned to play automatically after falling off.

## What Changes

- Detect when the player car has left the playable area (fallen off the edge).
- After the car has been falling off the edge for 1 second, automatically respawn it at the centre of the play area, 20 m above the ground, with its motion reset.
- A normal jump or airtime within the play area is unaffected — only a sustained fall past the edge triggers a respawn.

## Capabilities

### New Capabilities
- `vehicle-respawn`: Detecting that the player car has fallen off the edge of the play area and returning it to a safe spawn point after a fixed delay.

### Modified Capabilities
<!-- None: this introduces a new behavior rather than changing existing handling requirements. -->

## Impact

- `scripts/main.gd`: owns the play-area bounds and the `Car` reference; gains the fall detection + timer that triggers a respawn.
- `scripts/car.gd`: gains a `respawn(position)` method that resets the car's position, velocity, and airborne/orientation state.
- New test `tools/respawn_test.gd`: drives the car past the edge, advances physics, and asserts it respawns at the centre 20 m up after ~1 s.
- No changes to input, camera, terrain generation, or existing handling tuning.
