extends SceneTree
## Renders the landing screen (title + vehicle picker) for visual verification.
## --seed=N picks a deterministic trio; --shot=<path> sets the output. Advances a
## fraction of a second first so the previews have rotated off their start pose.
## --headless can't render 3D; run windowed with the GL driver:
##   godot --rendering-driver opengl3 -s tools/picker_shot.gd -- --seed=2 --shot=/tmp/picker.png

var _seed := 0
var _path := "/tmp/picker.png"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			_seed = int(a.substr(7))
		elif a.begins_with("--shot="):
			_path = a.substr(7)
	if _seed != 0:
		seed(_seed)
	var scene: Control = load("res://scenes/LandingScreen.tscn").instantiate()
	get_root().add_child(scene)
	_capture.call_deferred()


func _capture() -> void:
	for i in 30:
		await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png(_path)
	print("saved ", _path, " (", img.get_width(), "x", img.get_height(), ")")
	quit(0)
