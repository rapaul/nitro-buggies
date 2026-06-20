extends SceneTree
## Renders the two-player split-screen race and saves a screenshot. Sets the
## Selection autoload to 2P with two distinct vehicles, loads Main.tscn, lets the
## cars settle and the chase cameras converge, then captures the horizontal split.
## Output path is passed via --shot=<path>.
## Run: godot --rendering-driver opengl3 -s tools/two_player_race_shot.gd -- --shot=/tmp/x.png

var _path := "/tmp/two_player_race.png"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_path = arg.substr(7)
	var sel := get_root().get_node("Selection")
	sel.player_count = 2
	sel.selected_model_path = "res://assets/cars/sedan-sports.glb"
	sel.player2_model_path = "res://assets/cars/police.glb"
	change_scene_to_file("res://scenes/Main.tscn")
	_capture.call_deferred()


func _capture() -> void:
	# Let the cars settle on the surface and the chase cameras ease into place.
	for i in 40:
		await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png(_path)
	print("saved ", _path, " (", img.get_width(), "x", img.get_height(), ")")
	quit(0)
