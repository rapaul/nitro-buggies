extends SceneTree
## Renders LandingScreen.tscn and saves a screenshot for visual verification.
## Output path is passed via --shot=<path>.
## Run: godot -s tools/landing_shot.gd -- --shot=/tmp/landing.png

var _path := "/tmp/landing.png"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_path = arg.substr(7)
	var scene: Control = load("res://scenes/LandingScreen.tscn").instantiate()
	get_root().add_child(scene)
	_capture.call_deferred()


func _capture() -> void:
	# Let the window present a few frames before grabbing it.
	for i in 6:
		await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png(_path)
	print("saved ", _path, " (", img.get_width(), "x", img.get_height(), ")")
	quit(0)
