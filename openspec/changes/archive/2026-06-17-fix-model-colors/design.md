## Context

The Kenney car-kit GLBs (`assets/cars/*.glb`) each reference a single shared palette atlas as an **external** image (`"uri": "Textures/colormap.png"`) and assign one material (`colormap`, `metallicFactor: 0`, double-sided) to all parts; the parts' UVs sample colored regions of that atlas. The atlas exists at `assets/cars/Textures/colormap.png` and imports cleanly as a `CompressedTexture2D`.

Confirmed root cause (verified at runtime): after import, each mesh surface's `StandardMaterial3D` has `albedo_color = (1,1,1,1)` and `albedo_texture = null`. Godot 4.6's `.glb` importer is not binding the external-URI image to the material, so every part renders as lit white. The geometry is fine; only the texture binding is missing.

Verified fix (rendered a sedan windowed): assigning a `StandardMaterial3D` whose `albedo_texture` is `colormap.png` as a `material_override` on each `MeshInstance3D` produces the correct colors (red body, dark windows, headlights, dark wheels). Because every part shares the same atlas and UV layout, one material colors the whole car correctly.

Models are instantiated at two sites:
- `scripts/car.gd` `_ready()` — swaps in the selected vehicle mesh for the race.
- `scripts/landing_screen.gd` — instantiates each rotating preview model into a SubViewport.

(`scenes/Car.tscn`'s static `Mesh` node is always replaced by `car.gd._ready()`, so it needs no separate handling.)

## Goals / Non-Goals

**Goals:**
- Car models display their colormap colors at every render site (race + landing previews).
- Minimal, deterministic fix that covers all 24+ models uniformly without editing each `.glb.import` file.
- Machine-verifiable: a test can assert the rendered mesh's albedo texture is non-null.

**Non-Goals:**
- Re-exporting or repackaging the GLB assets.
- Changing handling, selection, camera, input, or scene flow.
- Per-vehicle color customization or recoloring beyond the kit's palette.

## Decisions

### Decision: Apply a shared colormap material via `material_override` at runtime
Build one `StandardMaterial3D` with `albedo_texture = load("res://assets/cars/Textures/colormap.png")` and assign it as the `material_override` on every `MeshInstance3D` of an instantiated model. A small shared helper walks the model's mesh nodes and sets the override; both `car.gd` and `landing_screen.gd` call it right after instantiating a model.

Rationale:
- All parts share one atlas + UVs, so a single material is correct for the entire car; `material_override` cleanly replaces the broken per-surface material on each `MeshInstance3D`.
- Sidesteps the importer bug entirely — works regardless of why the external image isn't bound.
- One code path covers all current and future kit models; no need to touch 24 `.import` files.
- The texture/material can be loaded once and shared across every mesh and preview (it is read-only), which is cheap.

Match the kit material intent (`metallicFactor: 0`); keep defaults otherwise. Whether to set `cull_mode` to match the GLB's double-sided flag is a minor detail — the kit models are closed solids, so the default (back-cull) is fine and is what the verification render used.

### Decision: Shared helper rather than duplicated walk code
`landing_screen.gd` already has a `_find_meshes(node)` recursion; `car.gd` does not. Provide a single reusable function (e.g. a tiny `CarSkin` autoload/util, or a static helper) that returns/sets the override, so the mesh-walk and material creation live in one place and both sites stay in sync.

Alternatives considered:
- **Fix at import (`_subresources` material override, or `materials/extract`)**: declarative but requires editing every `.glb.import` and the extracted materials would still start textureless; more files touched, same texture work. Rejected as higher-touch.
- **Re-export GLBs with embedded textures**: removes the runtime step but needs external tooling and re-commits 24 binaries. Rejected; out of scope.
- **Set the texture on the existing per-surface material instead of `material_override`**: the imported material is shared across surfaces/instances; mutating it risks surprising aliasing and is no simpler than an override. Override is more explicit.

## Risks / Trade-offs

- [The override replaces all surfaces with one material] → Correct here because every Kenney part uses the same atlas material; if a future asset used multiple distinct materials this would flatten them. Mitigation: scope the helper to the car-kit models we ship; revisit if multi-material assets are added.
- [Importer behavior could change in a future Godot version and bind the texture itself] → The override would simply become redundant, not harmful. Low risk.
- [Loading the texture per-instance] → Avoid by loading the texture/material once and reusing the shared resource across meshes and previews.

## Open Questions

- None blocking. Optional polish (roughness/specular tuning to better match the kit look) can follow once colors are restored.
