## Why

The dunes currently read as a single flat sand-colored blob (see the prior reshape change). The geometry is good, but the surface has no relief shading, no tonal variation, and no texture, so it looks like a paper cutout rather than a sand sea.

Spikes (throwaway renders against `Main.tscn`) established what actually moves the needle at this game's chase-camera distance:

- **Lighting is ~80% of the win.** A high (~45°) sun plus strong sky ambient (0.5) washes out all relief. Lowering the sun to a golden-hour angle and splitting warm direct light against a dimmer, cooler ambient puts a terminator on the dune faces — sun-facing slopes go warm, leeward slopes fall into ambient-only "diffuse" shading — which is exactly the relief the eye reads as 3-D. Confirmed at both an elevated overlook and a gameplay-height chase view.
- **Large-scale tonal variation reads at distance; micro-detail does not.** A low-frequency albedo color variation breaks the flat plastic color and is visible at speed. Fine grain normal maps were invisible past a few meters in the spikes — not worth doing.
- **The play valley stays readable.** Worry about golden-hour darkening gameplay proved unfounded from a chase cam (you look up sun-facing slopes); even at low ambient the car and valley read fine.

## What Changes

- Retune the scene lighting to a **golden-hour low sun**: lower the `DirectionalLight3D` to a shallow elevation that rakes **across** the ridge lines (ridges run along X, so the sun travels in ±Z), warm the light color, and increase its energy.
- Split light warm vs. shadow cool: switch ambient to a **dimmer, cooler** fill so leeward faces sit in believable sky-lit shadow instead of being washed flat.
- Enable **SSAO** so the troughs between ridges gain contact darkening and depth.
- Add **large-scale tonal variation** to the sand albedo via a procedural triplanar noise texture (no UV authoring, no sourced asset), biased *around* the sand color so it varies tone without darkening the base.
- (Optional, gated) Add **visible wind ripples**. Two normal-map attempts failed to read at gameplay distance, so ripples — if pursued — require a small custom terrain shader drawing clean parallel banding in **albedo** (which reads at distance) oriented across the slope. This is only kept if a banding spike confirms it reads; otherwise it is dropped.

Out of scope: changing the dune **geometry** (`DuneHeight`, collision, heightmap) — all changes here are material + environment only; geometric sand ripples (which would touch the shared height function and the flat-axis test invariant); time-of-day/dynamic lighting; weather; shadows from the car or props beyond what the existing directional light already casts.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `dune-terrain`: the sandy-appearance requirement is strengthened from "warm golden palette" to specify **relief shading from a low raking sun** (warm direct light vs. cooler ambient-only shadow on leeward faces), **trough contact shading (SSAO)**, and **large-scale tonal variation** across the surface. A new optional sub-requirement covers wind-ripple banding contingent on it reading at gameplay distance.

## Impact

- `scenes/Main.tscn` — `DirectionalLight3D` transform/color/energy; `Environment` ambient source/color/energy and `ssao_enabled`.
- `scripts/main.gd` — `_build_terrain` material setup: add a procedural `NoiseTexture2D` (triplanar) for albedo tonal variation; if ripples are kept, swap the `StandardMaterial3D` for a `ShaderMaterial`.
- Possibly a new `.gdshader` under a shaders/ location, only if the optional ripple tier is kept.
- **No change** to `scripts/dune_height.gd`, collision, or the heightmap — geometry and the flat spawn corridor invariant are untouched.
- `tools/drive_test.gd` and the physics tests are unaffected (lighting/material only). `tools/dunes_shot.gd` remains the visual-verification harness; a before/after screenshot is the acceptance check.
- No API or dependency changes; Godot 4.6.x only.
