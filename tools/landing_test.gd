extends SceneTree
## Headless test for the landing screen. Phase 1 confirms the dark-grey
## background, the two stacked title labels (sandy-orange shadow + sandy-yellow
## face), and the 1P/2P mode labels are built and the font loads. Phase 2 confirms
## the staged flow: the screen boots into the mode selection, the first ENTER
## confirms the mode (1P by default) and advances to the vehicle picker without
## starting the race, and a second ENTER then confirms the vehicle and switches to
## Main.tscn. Rendering isn't available headless, so Phase 1 validates wiring.
## Run: godot --headless -s tools/landing_test.gd

var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# --- Phase 1: structure ---
	var scene: Control = load("res://scenes/LandingScreen.tscn").instantiate()
	get_root().add_child(scene)
	await process_frame  # let _ready build the mode stage

	var bg := scene.get_node_or_null("Background")
	_check("Background ColorRect present and dark grey",
		bg != null and bg is ColorRect and (bg as ColorRect).color.v < 0.2)

	var labels: Array[Label] = []
	_collect_labels(scene, labels)
	var title_labels: Array[Label] = []
	for l in labels:
		if l.text == "Nitro Buggies":
			title_labels.append(l)
	_check("Title built from two stacked Labels", title_labels.size() == 2)
	if title_labels.size() == 2:
		var has_orange := false
		var has_yellow := false
		for l in title_labels:
			var c: Color = l.get_theme_color("font_color")
			if c.is_equal_approx(Color("c8761e")): has_orange = true
			if c.is_equal_approx(Color("e8c76a")): has_yellow = true
		_check("Sandy-orange shadow + sandy-yellow face present", has_orange and has_yellow)

	var texts: Array = []
	for l in labels:
		texts.append(l.text)
	_check("1P and 2P mode labels present", "1P" in texts and "2P" in texts)
	_check("Title font loads", load("res://assets/fonts/Kenney Blocks.ttf") != null)
	scene.free()

	# --- Phase 2: staged ENTER (mode -> picker -> race) ---
	change_scene_to_file("res://scenes/LandingScreen.tscn")
	await process_frame
	await process_frame
	_check("Boots into the landing screen",
		current_scene != null and current_scene.scene_file_path.ends_with("LandingScreen.tscn"))

	# First ENTER confirms the mode (1P default) and advances to the picker.
	_press("ui_accept")
	for i in 3:
		await process_frame
	_check("First ENTER stays on the landing screen (mode confirmed, picker shown)",
		current_scene.scene_file_path.ends_with("LandingScreen.tscn"))
	var selection := get_root().get_node("Selection")
	_check("Mode selection recorded a player count", selection.player_count == 1)

	# Second ENTER confirms the vehicle and starts the race.
	_press("ui_accept")
	for i in 5:
		await process_frame
	_check("Second ENTER starts the main game",
		current_scene != null and current_scene.scene_file_path.ends_with("Main.tscn"))
	_check("ENTER recorded a chosen vehicle",
		selection.selected_model_path.ends_with(".glb"))

	print("\n==== RESULT ====")
	if failures.is_empty():
		print("ALL CHECKS PASSED")
	else:
		print("FAILURES: ", failures.size())
		for f in failures:
			print("  - ", f)
	quit(0 if failures.is_empty() else 1)


func _collect_labels(node: Node, acc: Array[Label]) -> void:
	if node is Label:
		acc.append(node)
	for c in node.get_children():
		_collect_labels(c, acc)


func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)


func _check(label: String, cond: bool) -> void:
	print("[%s] %s" % ["PASS" if cond else "FAIL", label])
	if not cond:
		failures.append(label)
