extends SceneTree
## Renders Main.tscn while driving so the sand spray is visible, and saves a
## screenshot for visual verification (--headless cannot render particles).
## Output path is passed via --shot=<path>.
## Run: godot --rendering-driver opengl3 -s tools/spray_shot.gd -- --shot=/tmp/spray.png

var _path := "/tmp/spray.png"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_path = arg.substr(7)
	var main: Node3D = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(main)
	_capture.call_deferred()


func _capture() -> void:
	for i in 4:
		await process_frame
	# Reach full speed on the straight, then turn hard while still flat-out and
	# capture mid-turn — the trail at top speed in a turn is the case to judge.
	Input.action_press("accelerate", 1.0)
	for i in 150:
		await physics_frame
	Input.action_press("steer_right", 1.0)
	for i in 35:
		await physics_frame
	for i in 4:
		await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png(_path)
	print("saved ", _path, " (", img.get_width(), "x", img.get_height(), ")")
	quit(0)
