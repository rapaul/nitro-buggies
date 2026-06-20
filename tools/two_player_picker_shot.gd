extends SceneTree
## Renders the two-player split vehicle picker and saves a screenshot. Boots the
## landing screen, selects 2P (ui_right + ui_accept), and captures the resulting
## top/bottom split pickers. Output path is passed via --shot=<path>.
## Run: godot --rendering-driver opengl3 -s tools/two_player_picker_shot.gd -- --shot=/tmp/x.png

var _path := "/tmp/two_player_picker.png"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_path = arg.substr(7)
	var scene: Control = load("res://scenes/LandingScreen.tscn").instantiate()
	get_root().add_child(scene)
	_drive.call_deferred()


func _drive() -> void:
	await process_frame  # mode stage built
	_press("ui_right")   # move selection to 2P
	await process_frame
	_press("ui_accept")  # confirm 2P -> split pickers
	# Let the previews instantiate and present a few frames.
	for i in 10:
		await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png(_path)
	print("saved ", _path, " (", img.get_width(), "x", img.get_height(), ")")
	quit(0)


func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
