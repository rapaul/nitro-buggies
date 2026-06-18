## Why

On sloped dune terrain the car visibly floats above the ground, detached from its own shadow (see the reported screenshot). The cause is measured: the car's flat, horizontal box collision shape contacts the heightmap at its **uphill edge**, propping the whole physics body — and the visual mesh anchored to it — up to **~0.4 m** above the surface directly beneath the car. The shadow is cast from the real geometry onto the true surface, so the car appears to hover over its shadow. This breaks the sense that the car is on the sand.

## What Changes

- The visual car mesh is lowered so its wheels rest on the terrain surface directly beneath the car, closing the gap between the car and its shadow on slopes.
- Grounding is sampled from `DuneHeight` (the existing single source of truth for the surface), applied only while grounded, and eased to avoid jitter/pop — consistent with the existing "mesh is presentation, body is yaw-only physics" separation.
- No change to collision, handling, jumps, or floor detection: the physics body keeps behaving exactly as today.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `vehicle-appearance`: Add a requirement that the displayed car visually rests on the terrain surface (no floating gap to its shadow on slopes), as a purely visual adjustment that does not alter handling, collision, or the physics body.

## Impact

- Code: `scripts/car.gd` (visual mesh vertical offset in the orientation/presentation path; references `scripts/dune_height.gd`).
- Behavior: visual only. Handling, collision, jump/launch, camera, and selection are unchanged — `tools/drive_test.gd` must still PASS.
- Verification: a small headless probe asserting the mesh bottom sits within a tight tolerance of the sampled terrain across flat, sloped, and valley spots; plus a windowed screenshot confirming the car meets its shadow.
