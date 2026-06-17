## Context

`scripts/dune_height.gd` is the single source of truth for the terrain shape — `DuneHeight.height(x, z)` feeds the visual mesh, the collision heightmap, and the test harness. Today it is a product of two equal-wavelength sines:

```
height = AMPLITUDE * sin(x * k) * sin(z * k)   # AMPLITUDE=4, WAVELENGTH=40, k=TAU/40
```

This produces a regular grid of square cells → near-round bumps ("egg-carton"). Two properties of this formula are load-bearing and must survive the change:

1. **Flat spawn corridor.** Both `x=0` and `z=0` axes are exactly height 0 (because each contains a `sin(0)=0` factor). The planar handling tests in `tools/drive_test.gd` drive forward along `x=0` (accelerate/reverse in the z direction) and depend on level ground; the frame-rate test swaps in a flat box, but accelerate/reverse/steer/drift run on the real field along `x=0`.
2. **Reference ramp at `x=10`.** The slope-follow and jump tests, plus `tools/jump_shot.gd`, climb a fixed column at `x=10` from trough `z=30` to crest `z=10`. These coordinates are derived from `WAVELENGTH=40`.

The colour palette (`SAND` in `main.gd`, sky/ground/ambient in `Main.tscn`) is a pale yellow that the reference photo shows should be a warmer, richer golden under a pale hazy sky.

## Goals / Non-Goals

**Goals:**
- Elongated ridges (long crest lines) instead of discrete bumps.
- Wider spacing between successive crests.
- Gentler faces so a trough→crest climb takes a longer, sustained ascent.
- Keep at least one crest jumpable at full throttle.
- Preserve the flat-axis invariant so existing planar tests stay valid.
- Warm golden-sand palette and hazy desert sky matching the reference.

**Non-Goals:**
- No procedural noise / non-deterministic terrain — the field stays a closed-form, deterministic function (keeps mesh, collision, and tests in lockstep).
- No new textures/normal maps — colour only, via existing materials/environment.
- No change to car handling constants (`car.gd`); we adapt geometry and test reference points instead.
- No change to play-area size (`HALF=100`) or mesh/collision resolution.

## Decisions

### Decision 1: Anisotropic product-of-sines (long axis vs spacing axis)
Keep the product-of-sines form but give the two axes **different wavelengths**:

```
height = AMPLITUDE * sin(x * kx) * sin(z * kz)
kx = TAU / WAVELENGTH_X   (long → ridges elongated along x)
kz = TAU / WAVELENGTH_Z   (the trough→crest driving direction; sets spacing & slope)
```

A long `WAVELENGTH_X` stretches each cell along x, turning round bumps into ridge lines that run in the x direction; the car driving in z then meets ridge after ridge. Crucially `sin(0)=0` is still a factor on **both** axes, so `x=0` and `z=0` stay flat — the invariant is preserved for free.

**Starting constants (to be tuned by screenshot/inspect):**
- `AMPLITUDE ≈ 5.0` (m) — slightly taller so gentle dunes still read as substantial.
- `WAVELENGTH_X ≈ 160` (m) — long ridges; full play area (200 m) spans ~1.25 ridge periods.
- `WAVELENGTH_Z ≈ 70` (m) — crest-to-crest spacing along the driving direction (was 40), so ~35 m of climb per face.

Slope check (steepest point of a face, at a full-amplitude ridge): `AMPLITUDE * kz = 5 * (TAU/70) ≈ 0.45` (~24°), versus the old `4 * TAU/40 ≈ 0.63` (~32°), over a 35 m face instead of 20 m → the climb is both shallower and longer, satisfying "takes longer to drive up."

**Alternatives considered:**
- *Pure 1-D ridges* `height = A*sin(z*kz)` (no x factor): cleanest ridges, but breaks the flat corridor (the `x=0` driving line would now undulate). Rejected — would force rewriting the planar tests.
- *Asymmetric (windward/leeward) dune profile* via a skewed/sawtooth function: more physically realistic barchan look, but more complex, harder to keep both axes flat, and harder for the analytic central-difference normals in `main.gd`. Deferred as a possible follow-up; the gentle sine face already meets the "takes longer to climb" goal.

### Decision 2: Re-derive the test/inspection reference column
With `WAVELENGTH_X≈160`, the full-amplitude ridge sits at `x = WAVELENGTH_X/4 ≈ 40` (where `sin(x*kx)=1`), not `x=10`. Move the slope/jump reference column to that ridge and recompute its trough/crest z-values from `WAVELENGTH_Z` (crest at `z=WAVELENGTH_Z/4`, trough at `z=3*WAVELENGTH_Z/4`). Update `tools/drive_test.gd`, `tools/jump_shot.gd`, and `tools/inspect_dunes.gd` together so they all sample the same true ridge.

This keeps a **strong, full-amplitude crest** for the jump test even though faces are gentler — the launch happens on the tallest ridge, where the sign-flip-at-crest lift in `car.gd` is strongest.

### Decision 3: Warm palette via existing material + environment
No new assets. Adjust colours only:
- `main.gd` `SAND` albedo → warmer golden, starting `Color(0.80, 0.60, 0.34)` (richer orange-tan than the current `0.85,0.72,0.46`).
- `Main.tscn` `ProceduralSkyMaterial`: pale hazy sky — `sky_horizon_color`/`ground_horizon_color ≈ (0.86, 0.82, 0.74)`, a pale near-white `sky_top_color ≈ (0.82, 0.83, 0.84)`, `ground_bottom_color` a muted warm tan.
- Keep ambient source = sky; nudge `ambient_light_energy` only if the dunes read too dark/flat after the albedo change.

Final values are a visual judgement — tune by rendering `tools/dunes_shot.gd` and comparing against the reference photo.

## Risks / Trade-offs

- **Gentler faces weaken the jump** → Mitigation: launch off the full-amplitude ridge (Decision 2) and verify `tools/drive_test.gd`'s fast-crest test still goes airborne at full throttle; if not, modestly raise `AMPLITUDE` or lower `WAVELENGTH_Z` rather than touching `car.gd`. The slow-crest "stays grounded" test must also still pass (don't make crests so sharp that slow approaches launch).
- **Existing tests assume `x=10` geometry** → Mitigation: update all three tool scripts in the same change; run `drive_test.gd` to confirm PASS.
- **Coarse 2 m mesh on long ridges** could look facetted along the gentle x ridge → low risk (longer wavelength is smoother per cell, not rougher); confirm visually via `dunes_shot.gd`.
- **Colour subjectivity** → Mitigation: screenshot-and-compare loop against the reference; values in this doc are starting points, not final.
- **`--headless --import` must stay clean** and `drive_test.gd` must stay PASS — both are the acceptance gate.

## Migration Plan

Pure code/scene edit; no data or runtime migration. Rollback = revert the commit. Validate with `godot --headless --import`, `drive_test.gd` (PASS), `inspect_dunes.gd` (sane crest/trough), and a `dunes_shot.gd` render compared to the reference photo.

## Open Questions

- Should ridges run along **x** (player meets them while driving the default −Z course) or be rotated? Defaulting to ridges-along-x so the spawn-direction drive crosses them; revisit if the camera/course makes the other axis more interesting.
- Final amplitude/wavelength and exact colours are tuning targets, resolved during apply via the screenshot loop — not blocking for the plan.
