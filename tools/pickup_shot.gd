extends SceneTree
## Renders the pickup HUD and the WASTED / WINNER overlay for visual verification
## (the words, colours, and font can't be asserted headless). Sets 2P, loads
## Main.tscn, gives each car a held item and damages Player 1, captures the live
## HUD, then eliminates Player 1 and captures the WASTED (top) / WINNER (bottom)
## frame. Output paths: --hud=<path> --wasted=<path>.
## Run: godot --rendering-driver opengl3 -s tools/pickup_shot.gd -- --hud=/tmp/hud.png --wasted=/tmp/wasted.png

var _hud_path := "/tmp/pickup_hud.png"
var _wasted_path := "/tmp/pickup_wasted.png"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--hud="):
			_hud_path = arg.substr(6)
		elif arg.begins_with("--wasted="):
			_wasted_path = arg.substr(9)
	var sel := get_root().get_node("Selection")
	sel.player_count = 2
	sel.selected_model_path = "res://assets/cars/sedan-sports.glb"
	sel.player2_model_path = "res://assets/cars/police.glb"
	change_scene_to_file("res://scenes/Main.tscn")
	_capture.call_deferred()


func _capture() -> void:
	for i in 40:
		await process_frame
	var main := current_scene
	var cars: Array = main._cars
	var car1: CharacterBody3D = cars[0]
	var car2: CharacterBody3D = cars[1]
	var item = car1.get_script().Item

	# Live HUD: both players holding an item, Player 1 down to two bars.
	car1.collect(item.NITRO)
	car2.collect(item.FIREBALL)
	car1.take_damage(1)
	await _settle()
	_save(_hud_path)

	# Eliminate Player 1 -> WASTED on top, WINNER on the bottom.
	car1.take_damage(2)
	await _settle()
	_save(_wasted_path)
	quit(0)


func _settle() -> void:
	for i in 6:
		await process_frame


func _save(path: String) -> void:
	var img := get_root().get_texture().get_image()
	img.save_png(path)
	print("saved ", path, " (", img.get_width(), "x", img.get_height(), ")")
