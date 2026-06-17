extends SceneTree
## Drives the car up a dune ramp at full throttle and captures the moment it is
## airborne off the crest, to confirm the chase camera frames a jump acceptably.
## Output path via --shot=<path>. Run:
##   godot --rendering-driver opengl3 -s tools/jump_shot.gd -- --shot=/tmp/jump.png

const Dune := preload("res://scripts/dune_height.gd")

var _path := "/tmp/jump.png"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_path = arg.substr(7)
	var scene: Node3D = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(scene)
	_capture.call_deferred()


func _capture() -> void:
	var car: CharacterBody3D = get_root().get_node("Main/Car")
	car.global_transform = Transform3D(Basis(), Vector3(40, Dune.height(40, 52.5) + 0.2, 52.5))
	car.velocity = Vector3.ZERO
	Input.action_press("accelerate", 1.0)
	# Drive up the ramp and stop once well off the crest, so the shot catches the
	# car mid-air rather than already landed.
	for i in 200:
		await physics_frame
		var p := car.global_position
		if p.y - Dune.height(p.x, p.z) > 3.0:
			break
	for i in 4:
		await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png(_path)
	var p := car.global_position
	print("saved ", _path, "  clearance=%.2f" % (p.y - Dune.height(p.x, p.z)))
	quit(0)
