## Why

The gameplay world is currently a flat 200×200 plane, so driving has no terrain interest and the car physics is purely planar (vertical velocity is overwritten every tick). A sand-dune landscape gives the game its desert-racing identity and unlocks the core thrill the player asked for: building up speed and launching off a dune crest into the air.

## What Changes

- Replace the flat ground plane with rolling **sand-dune terrain** — a sculpted, undulating heightfield with matching collision and a sandy material.
- Extend vehicle physics with a **vertical/airborne dimension**: the car follows the terrain surface while grounded, becomes **airborne** when it leaves a crest with enough speed, follows a ballistic arc under gravity, and lands.
- Tune dune geometry and car launch behavior so that reaching high speed up a dune face produces a satisfying **jump off the crest** rather than the car clinging to the surface.
- **BREAKING** (internal): the vehicle's `_physics_process` no longer assumes motion is confined to the XZ plane; `velocity.y` becomes meaningful (gravity + ballistic flight).

## Capabilities

### New Capabilities
- `dune-terrain`: A rolling sand-dune landscape that replaces the flat ground — undulating heightfield surface with collision the car drives over, a sandy appearance, and crests shaped to be jumpable.

### Modified Capabilities
- `vehicle-control`: Add grounded-vs-airborne handling — gravity, following terrain slopes while grounded, launching into the air off a crest at speed, ballistic flight with no thrust/steering grip, and landing back onto the terrain.

## Impact

- `scenes/Main.tscn`: replace the `PlaneMesh` ground + flat `BoxShape3D` collision with dune terrain mesh and collision.
- `scripts/car.gd`: integrate gravity and an airborne state into `_physics_process`; preserve `velocity.y` instead of overwriting it.
- New terrain generation asset/script (heightfield mesh + `HeightMapShape3D`/`ConcavePolygonShape3D` collision).
- `tools/drive_test.gd`: extend headless assertions to cover gravity (rests on surface), slope following, and a jump (airborne) case.
- Camera (`scripts/camera.gd`) is expected to work unchanged (it follows the car's full position including height), and is verified, not modified.
