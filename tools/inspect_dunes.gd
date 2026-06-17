extends SceneTree
## Samples the dune height field and reports the reference ramp/crest used by the
## jump tests, to sanity-check the terrain shape. Run:
##   godot --headless -s tools/inspect_dunes.gd

const Dune := preload("res://scripts/dune_height.gd")


func _initialize() -> void:
	print("Dune field: AMPLITUDE=%.1f  WAVELENGTH=%.1f" % [Dune.AMPLITUDE, Dune.WAVELENGTH])
	print("Origin (0,0): h=%.3f   (flat spawn)" % Dune.height(0.0, 0.0))
	print("Flat axis check  x=0: h(0,17)=%.3f   z=0: h(17,0)=%.3f" % [Dune.height(0.0, 17.0), Dune.height(17.0, 0.0)])
	print("\nJump ramp along x=10, driving -Z (trough z=30 -> crest z=10):")
	for zi in range(30, 8, -2):
		var z := float(zi)
		print("  z=%d  h=%.3f" % [zi, Dune.height(10.0, z)])
	print("\nReference crest (10,10): h=%.3f  (local maximum)" % Dune.height(10.0, 10.0))
	print("Reference trough (10,30): h=%.3f" % Dune.height(10.0, 30.0))
	quit(0)
