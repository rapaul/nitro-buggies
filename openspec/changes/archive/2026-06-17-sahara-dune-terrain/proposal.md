## Why

The current dunes are short-wavelength "egg-carton" bumps — they read as a regular field of rounded hills, and at 40 m spacing with 4 m amplitude the faces are steep, so the car crests them almost immediately. We want the landscape to feel like a real sand sea (à la the Sahara reference photo): long, elongated ridges that are spaced further apart, with gentle faces that take a sustained climb to ascend, in a warm golden-sand palette rather than the current pale yellow.

## What Changes

- Reshape the dune height field from near-isotropic bumps into **elongated ridges**: the crest lines run long in one direction instead of forming discrete hills.
- **Increase the spacing between ridges** so successive crests are further apart across the play area.
- **Gentle the dune faces** so climbing a face takes noticeably longer (lower slope per metre travelled), while keeping crests jumpable at high speed.
- Preserve the **flat spawn corridor invariant**: the `x=0` and `z=0` axes stay at height 0 so the planar handling/jump tests still run on level ground.
- Retune the **colour palette** toward the warm golden tones of the Sahara reference image — terrain sand colour and the sky/horizon/ambient environment colours.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `dune-terrain`: the surface-shape requirement changes from generic undulation to elongated, wider-spaced ridges with gentle faces that require a sustained climb; the sandy-appearance requirement changes to specify the warm golden Sahara palette.

## Impact

- `scripts/dune_height.gd` — the shared height function (single source of truth for mesh, collision, and tests); constants and possibly the formula change.
- `scripts/main.gd` — `SAND` albedo colour.
- `scenes/Main.tscn` — sky / horizon / ground / ambient environment colours.
- `tools/drive_test.gd`, `tools/jump_shot.gd`, `tools/inspect_dunes.gd` — reference ramp/crest coordinates are tied to the old wavelength and must be re-derived for the new geometry.
- No API or dependency changes; no save/runtime data affected.
