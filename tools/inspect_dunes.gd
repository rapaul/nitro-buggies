extends SceneTree
## Samples the dune height field and reports the reference ramp/crest used by the
## jump tests, to sanity-check the terrain shape. Run:
##   godot --headless -s tools/inspect_dunes.gd

const Dune := preload("res://scripts/dune_height.gd")


func _initialize() -> void:
	# Full-amplitude ridge runs along x = WAVELENGTH_X/4 (sin = 1 there); along it
	# the crest sits at z = WAVELENGTH_Z/4 and the trough at z = 3*WAVELENGTH_Z/4.
	var ridge_x := Dune.WAVELENGTH_X / 4.0
	var crest_z := Dune.WAVELENGTH_Z / 4.0
	var trough_z := 3.0 * Dune.WAVELENGTH_Z / 4.0
	print("Dune field: AMPLITUDE=%.1f  WAVELENGTH_X=%.1f  WAVELENGTH_Z=%.1f" % [Dune.AMPLITUDE, Dune.WAVELENGTH_X, Dune.WAVELENGTH_Z])
	print("Origin (0,0): h=%.3f   (flat spawn)" % Dune.height(0.0, 0.0))
	print("Flat axis check  x=0: h(0,17)=%.3f   z=0: h(17,0)=%.3f" % [Dune.height(0.0, 17.0), Dune.height(17.0, 0.0)])
	print("\nDune face along x=%.1f, driving -Z (trough z=%.1f -> crest z=%.1f):" % [ridge_x, trough_z, crest_z])
	for zi in range(int(trough_z), int(crest_z) - 2, -3):
		var z := float(zi)
		print("  z=%d  h=%.3f" % [zi, Dune.height(ridge_x, z)])
	print("\nReference crest (%.1f,%.1f): h=%.3f  (local maximum)" % [ridge_x, crest_z, Dune.height(ridge_x, crest_z)])
	print("Reference trough (%.1f,%.1f): h=%.3f" % [ridge_x, trough_z, Dune.height(ridge_x, trough_z)])
	quit(0)
