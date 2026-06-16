extends SceneTree
## Headless test for the landing screen. Phase 1 confirms the dark-grey
## background and the two stacked title labels (sandy-orange shadow + sandy-yellow
## face) are built and the font loads. Phase 2 confirms the game stays on the
## landing screen until ENTER (ui_accept) is pressed, then switches to Main.tscn.
## Rendering isn't available headless, so Phase 1 validates wiring, not pixels.
## Run: godot --headless -s tools/landing_test.gd

var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# --- Phase 1: structure ---
	var scene: Control = load("res://scenes/LandingScreen.tscn").instantiate()
	get_root().add_child(scene)

	var bg := scene.get_node_or_null("Background")
	_check("Background ColorRect present and dark grey",
		bg != null and bg is ColorRect and (bg as ColorRect).color.v < 0.2)

	var labels: Array[Label] = []
	for child in scene.get_children():
		if child is Control and child != bg:
			for gc in child.get_children():
				if gc is Label:
					labels.append(gc)
	_check("Title built from two stacked Labels", labels.size() == 2)
	if labels.size() == 2:
		_check("Both labels read 'Nitro Buggies'",
			labels[0].text == "Nitro Buggies" and labels[1].text == "Nitro Buggies")
		var has_orange := false
		var has_yellow := false
		for l in labels:
			var c: Color = l.get_theme_color("font_color")
			if c.is_equal_approx(Color("c8761e")): has_orange = true
			if c.is_equal_approx(Color("e8c76a")): has_yellow = true
		_check("Sandy-orange shadow + sandy-yellow face present", has_orange and has_yellow)

	_check("Title font loads", load("res://assets/fonts/Kenney Blocks.ttf") != null)
	scene.free()

	# --- Phase 2: ENTER starts the game ---
	change_scene_to_file("res://scenes/LandingScreen.tscn")
	await process_frame
	await process_frame
	_check("Boots into the landing screen",
		current_scene != null and current_scene.scene_file_path.ends_with("LandingScreen.tscn"))
	await process_frame
	_check("Main game does not start before ENTER",
		current_scene.scene_file_path.ends_with("LandingScreen.tscn"))

	var ev := InputEventAction.new()
	ev.action = "ui_accept"
	ev.pressed = true
	Input.parse_input_event(ev)
	# change_scene_to_file is deferred; give it a few frames to take effect.
	for i in 5:
		await process_frame
	_check("ENTER (ui_accept) starts the main game",
		current_scene != null and current_scene.scene_file_path.ends_with("Main.tscn"))
	# ENTER also confirms the highlighted vehicle into the Selection autoload.
	var selection := get_root().get_node("Selection")
	_check("ENTER recorded a chosen vehicle",
		selection != null and selection.selected_model_path.ends_with(".glb"))

	print("\n==== RESULT ====")
	if failures.is_empty():
		print("ALL CHECKS PASSED")
	else:
		print("FAILURES: ", failures.size())
		for f in failures:
			print("  - ", f)
	quit(0 if failures.is_empty() else 1)


func _check(label: String, cond: bool) -> void:
	print("[%s] %s" % ["PASS" if cond else "FAIL", label])
	if not cond:
		failures.append(label)
