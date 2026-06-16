## Why

Every car renders as plain white (lit, with shadows, but no color) on both the landing-screen previews and in the race. The Kenney car-kit GLBs reference their shared palette atlas as an *external* image (`Textures/colormap.png`), and Godot's `.glb` importer does not bind that external texture to the imported material — so each part's material ends up with a null albedo texture and a white albedo color. The game looks unfinished and all vehicles are visually indistinguishable.

## What Changes

- Apply the shared `colormap.png` palette atlas to every car model so the models show their intended colors instead of white.
- Introduce one shared car material (`colormap.png` as albedo) and apply it to instantiated car meshes at the two render sites: the landing-screen vehicle previews (`landing_screen.gd`) and the race car (`car.gd`).
- No change to model selection, handling, camera, or input behavior — purely visual.

## Capabilities

### New Capabilities
- `vehicle-appearance`: Car models SHALL render with their kit colors (the shared colormap palette) wherever they are shown — the landing-screen previews and the in-race vehicle — rather than appearing untextured white.

### Modified Capabilities
<!-- None. Appearance was not previously specified by landing-screen or vehicle-control. -->

## Impact

- Code: `scripts/car.gd` (race mesh), `scripts/landing_screen.gd` (preview meshes); a shared material resource or small helper applied at both sites.
- Assets: relies on the existing `assets/cars/Textures/colormap.png`; no asset re-export.
- No change to physics, input, selection, or scene flow. Verifiable visually via the windowed screenshot harness and by inspecting that mesh materials carry a non-null albedo texture.
