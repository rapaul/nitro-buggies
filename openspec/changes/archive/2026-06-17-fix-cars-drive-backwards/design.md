## Context

`car.gd` integrates motion with `-Z` as forward (`var forward := -global_transform.basis.z`). This is correct and covered by `tools/drive_test.gd` (which asserts "Accelerate: car moves forward (-Z)") and `tools/inspect_car.gd`. The chase camera (`Main.tscn` / `camera.gd`) sits behind the car at `+Z` looking toward `-Z`, so on-screen "away/forward" is `-Z`, matching the physics.

The bug is purely visual mesh facing: every Kenney car-kit GLB used by the picker is authored facing `+Z`, the opposite of the car's `-Z` forward, so each car drives tail-first. Confirmed by building cars through the real `Car.tscn` path and rendering from the game camera with a travel-direction (`-Z`) arrow (`tools/orient_shot.gd`): without the flip the cars' fronts point back at the camera (`+Z`); with it their noses lead along the arrow.

`car.gd._ready()` already swaps the visual `Mesh` node based on `Selection.selected_model_path` and then calls `CarSkin.apply(mesh)`. The yaw correction slots into that same swap, after instantiation.

## Goals / Non-Goals

**Goals:**
- Every selectable car drives nose-first.
- Physics/handling untouched; existing tests still pass.

**Non-Goals:**
- Changing the physics forward axis or any handling tuning.
- Re-authoring or re-exporting the GLB assets.

## Decisions

**Decision: Flip the swapped-in visual mesh 180° about Y at swap time.**
After instantiating the mesh in `_ready()`, call `mesh.rotate_y(PI)` so its `+Z`-authored nose points along the car's `-Z` forward. The whole kit shares this facing, so a single unconditional flip fixes every car — no per-model data needed.

**Alternatives considered:**
- *Flip the physics forward to `+Z`*: would invert every test that assumes `-Z` and the camera placement; far more invasive for no benefit. Rejected.
- *Per-model facing table*: unnecessary — the kit is uniform `+Z`. Rejected for simplicity.
- *Re-export the GLBs facing `-Z`*: more asset plumbing and a second source of truth; the mesh-swap code is the natural seam. Rejected.

**Decision: Keep `tools/orient_shot.gd` as the orientation verification tool.**
It builds cars through `Car.tscn` (real path) and renders from the game camera with a `-Z` travel arrow, so a facing regression is visible. Headless can't see pixels; this uses the GL driver per `CLAUDE.md`.

## Risks / Trade-offs

- [The standalone `res://assets/race.glb` (Car.tscn's placeholder Mesh and `FALLBACK_MODEL`) is authored facing `-Z`, so the unconditional flip would render it backwards] → It is only reached on a failed `load()` of the selected model; in normal play the mesh is always swapped to a `+Z` kit model. Acceptable; documented in a code comment. If the fallback path becomes user-visible, switch the fallback to a kit model rather than special-casing the flip.

## Open Questions

None — the entire kit's `+Z` facing is empirically established.
