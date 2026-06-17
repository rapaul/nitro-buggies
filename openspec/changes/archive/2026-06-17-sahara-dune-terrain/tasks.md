## 1. Reshape the dune height field

- [x] 1.1 In `scripts/dune_height.gd`, replace the single `WAVELENGTH` with `WAVELENGTH_X` (long, ridges) and `WAVELENGTH_Z` (spacing/slope), bump `AMPLITUDE`, and change `height()` to `AMPLITUDE * sin(x*kx) * sin(z*kz)` with starting values AMPLITUDE≈5, WAVELENGTH_X≈160, WAVELENGTH_Z≈70.
- [x] 1.2 Confirm the flat-axis invariant by inspection: `height(0, z)==0` and `height(x, 0)==0` for any x,z (both sine factors still vanish on the axes).

## 2. Re-derive test & inspection references

- [x] 2.1 Update `tools/inspect_dunes.gd` to print the new constants and sample the full-amplitude ridge at `x = WAVELENGTH_X/4` (≈40), crest at `z = WAVELENGTH_Z/4`, trough at `z = 3*WAVELENGTH_Z/4`.
- [x] 2.2 Update the reference ramp column in `tools/drive_test.gd` (slope-follow, fast-crest, slow-crest, airborne tests) from `x=10`, `z=30→10` to the new full-amplitude ridge coordinates from 2.1.
- [x] 2.3 Update `tools/jump_shot.gd` spawn/crest coordinates to the same new ridge.

## 3. Warm Sahara colour palette

- [x] 3.1 In `scripts/main.gd`, change `SAND` to a warmer golden tone (start `Color(0.80, 0.60, 0.34)`).
- [x] 3.2 In `scenes/Main.tscn`, retune the `ProceduralSkyMaterial` and Environment colours toward a pale hazy desert sky (warm pale horizon, near-white sky top, muted warm ground), adjusting `ambient_light_energy` only if needed.

## 4. Verify

- [x] 4.1 `godot --headless --import` finishes with no error/warning.
- [x] 4.2 `godot --headless -s tools/drive_test.gd` prints ALL CHECKS PASSED (exit 0); in particular the fast-crest jump still goes airborne at full throttle and the slow crest stays grounded. If the jump fails, raise AMPLITUDE / lower WAVELENGTH_Z (not `car.gd`) and re-run.
- [x] 4.3 `godot --headless -s tools/inspect_dunes.gd` shows a flat origin, a strong crest/trough on the reference ridge, and gentler slope than before.
- [x] 4.4 Render `godot --rendering-driver opengl3 -s tools/dunes_shot.gd -- --shot=/tmp/dunes.png`, view it, and confirm long widely-spaced ridges with gentle faces in a warm golden palette resembling the Sahara reference; iterate on constants/colours until it matches.
