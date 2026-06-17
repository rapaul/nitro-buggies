extends SceneTree
## Renders the gameplay scene (Main.tscn) and saves a screenshot for visual
## verification of the third-person chase camera. Output path via --shot=<path>.
## Optionally turns the car first with --turn to confirm the camera swings to
## stay behind the car's heading.
## Run: godot --rendering-driver opengl3 -s tools/main_shot.gd -- --shot=/tmp/cam.png [--turn]

var _path := "/tmp/cam.png"
var _turn := false


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_path = arg.substr(7)
		elif arg == "--turn":
			_turn = true
	var scene: Node3D = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(scene)
	_capture.call_deferred()


func _capture() -> void:
	var car: Node3D = get_root().get_node("Main/Car")
	if _turn:
		car.rotation.y = deg_to_rad(60)
	# Let physics tick so the chase camera eases to its pose, then present.
	for i in 90:
		await physics_frame
	for i in 4:
		await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png(_path)
	print("saved ", _path, " (", img.get_width(), "x", img.get_height(), ")")
	quit(0)
