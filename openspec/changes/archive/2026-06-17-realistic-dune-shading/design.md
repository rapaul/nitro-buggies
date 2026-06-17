## Context

The dune geometry (elongated X-running ridges, ~70 m Z spacing, 5 m amplitude, flat x=0/z=0 spawn corridor) is already good. This change is purely about how the existing surface is lit and shaded. All edits are confined to `scenes/Main.tscn` (light + environment) and `scripts/main.gd` (`_build_terrain` material). `scripts/dune_height.gd`, the collision heightmap, and the physics/handling tests are deliberately untouched.

Findings below come from throwaway spikes rendered with `--rendering-driver opengl3` against `Main.tscn` (the same technique as `tools/dunes_shot.gd`).

## Decisions

### Lighting: low warm sun + dim cool ambient + SSAO
- Lower the `DirectionalLight3D` from its current ~45° elevation to a shallow golden-hour angle (spike used a travel direction of roughly `(0.18, -0.24, -0.95)`, i.e. ~14° elevation). Final elevation tuned by eye; the constraint is that it rakes **across** the ridges (horizontal travel dominated by ±Z, since crests run along X). Light traveling along X would run down the ridges and flatten them.
- Warm the sun (`light_color` ≈ `(1.0, 0.86, 0.62)`) and raise `light_energy` (≈ 1.3).
- Switch ambient from sky-sourced energy 0.5 to a **color** source, dimmer (≈ 0.28–0.45) and **cooler** (≈ `(0.55, 0.62, 0.78)`), so leeward faces read as sky-lit shadow. Ambient energy is the readability lever — tune it up if the car/valley get too dark, down for more drama.
- Enable `ssao_enabled` on the environment for trough contact darkening. The spike's SSAO was a touch heavy; tune radius/intensity.
- Keep `shadow_enabled` on the directional light (already on). At low sun this casts long ridge→trough shadows; verify they don't crush the play valley.

### Texture: large-scale albedo tonal variation, triplanar, procedural
- Use `FastNoiseLite` → `NoiseTexture2D` assigned as the material's `albedo_texture` with `uv1_triplanar = true` (no UVs are authored on the SurfaceTool mesh; triplanar samples world position). This fits the project's all-procedural, deterministic ethos — no sand photo to source or license.
- The noise must vary tone **around** the sand color, not multiply it toward black. The naive spike (raw 0..1 noise as albedo_texture multiplying albedo_color) darkened the base; the implementation should bias/scale the noise so mean ≈ 1.0 (e.g. via the shader, or a remapped texture), or apply it as a subtle multiply centered on white.
- **Dropped:** fine grain normal maps. Two spikes confirmed they are invisible past a few meters at this camera distance. Not worth the cost.

### Wind ripples: gated on a banding spike
- Two normal-map ripple attempts (isotropic, then anisotropic stretched triplanar noise pushed to extreme bump strength) **failed to read** at gameplay distance — they produced smooth surfaces or broad blotches, never clean ripple lines.
- Therefore, if ripples are pursued, they must be a small custom `.gdshader` that draws clean parallel **albedo** banding (albedo reads at distance; normals do not), oriented across the slope. This means replacing the `StandardMaterial3D` with a `ShaderMaterial`.
- This tier is **explicitly gated**: prototype the banding shader and screenshot it from the chase camera first. Keep it only if the banding visibly reads; otherwise drop it and document why. Do not ship an invisible ripple effect.

## Risks / Trade-offs

- **Mood commitment.** Golden-hour commits the game to a warm evening feel. Accepted per the explore discussion.
- **Readability vs. drama.** Lower ambient = more relief but darker shadows. Mitigation: ambient energy is a single dial; tune against a chase-cam screenshot with the car present.
- **Shader scope creep.** The ripple tier introduces a custom shader and replaces the material type. Mitigation: gate it behind a spike and keep Tier 1 (lighting + tone) independently shippable.

## Outcome (resolved during apply)

- **Final lighting:** sun ~14° elevation raking across the ridges, `light_energy` 1.5, warm `light_color` (1, 0.86, 0.62); ambient color source (0.55, 0.62, 0.78) at energy 0.7; SSAO on. Plus triplanar albedo tonal variation color-ramped around SAND.
- **Sun oriented in code, not the .tscn.** Godot reads the 12-float `Transform3D` row-major, so a hand-authored basis written as axis-columns comes out transposed — here that pointed the sun upward and the terrain was lit only by ambient (flat/dark). Fixed by `main.gd._orient_sun()` using `look_at`. Keep sun/camera orientation in code for this project.
- **Tier 2 (wind ripples) deferred by user decision** — not attempted. The optional ripple requirement is satisfied as "not pursued for now." If revisited, prototype the albedo-banding shader first and keep only if it reads at chase distance (normal-map ripples were already shown not to read in exploration).
