extends SceneTree
## Renders Main.tscn's dune terrain from an elevated overlook so the undulation
## is clearly visible (the in-game chase camera looks down the flat spawn valley).
## Output path via --shot=<path>. Run:
##   godot --rendering-driver opengl3 -s tools/dunes_shot.gd -- --shot=/tmp/dunes.png

var _path := "/tmp/dunes.png"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_path = arg.substr(7)
	var scene: Node3D = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(scene)
	_capture.call_deferred()


func _capture() -> void:
	for i in 8:
		await physics_frame
		await process_frame
	var cam := Camera3D.new()
	get_root().add_child(cam)
	cam.global_position = Vector3(70, 50, 90)
	cam.look_at(Vector3(15, -2, 5), Vector3.UP)
	cam.current = true
	for i in 4:
		await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png(_path)
	print("saved ", _path, " (", img.get_width(), "x", img.get_height(), ")")
	quit(0)
