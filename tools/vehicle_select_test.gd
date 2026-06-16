extends SceneTree
## Headless test for the landing-screen vehicle picker. Rendering isn't available
## headless, so this validates the selection LOGIC: three distinct eligible models
## are picked, the leftmost starts selected, left/right navigation clamps at the
## ends, and accept records the highlighted model in the Selection autoload.
## Run: godot --headless -s tools/vehicle_select_test.gd

var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: Control = load("res://scenes/LandingScreen.tscn").instantiate()
	get_root().add_child(scene)
	await process_frame
	await process_frame

	var picked: Array = scene._picked
	_check("Three vehicles picked", picked.size() == 3)
	_check("Picked vehicles are distinct", _distinct(picked))
	var all_eligible := true
	for p in picked:
		if not scene.VEHICLE_MODELS.has(p):
			all_eligible = false
	_check("All picked models are from the eligible vehicle list", all_eligible)

	_check("Leftmost preview selected on entry", scene._selected == 0)

	# Left at the left end clamps.
	_press("ui_left")
	await process_frame
	_check("Left at the left end stays put", scene._selected == 0)

	# Right moves one, then again to the last, then clamps.
	_press("ui_right")
	await process_frame
	_check("Right moves to the middle", scene._selected == 1)
	_press("ui_right")
	await process_frame
	_check("Right moves to the last", scene._selected == 2)
	_press("ui_right")
	await process_frame
	_check("Right at the right end stays put", scene._selected == 2)

	# A/D aliases (steer actions) also navigate.
	_press("steer_left")
	await process_frame
	_check("steer_left (A) moves back to the middle", scene._selected == 1)

	# Accept records the highlighted model.
	var expected: String = picked[scene._selected]
	scene._unhandled_input(_action("ui_accept"))
	var selection := get_root().get_node("Selection")
	_check("Accept records the highlighted vehicle in Selection",
		selection.selected_model_path == expected)

	print("\n==== RESULT ====")
	if failures.is_empty():
		print("ALL CHECKS PASSED")
	else:
		print("FAILURES: ", failures.size())
		for f in failures:
			print("  - ", f)
	quit(0 if failures.is_empty() else 1)


func _distinct(arr: Array) -> bool:
	var seen := {}
	for v in arr:
		if seen.has(v):
			return false
		seen[v] = true
	return true


func _action(name: String) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = name
	ev.pressed = true
	return ev


func _press(name: String) -> void:
	Input.parse_input_event(_action(name))


func _check(label: String, cond: bool) -> void:
	print("[%s] %s" % ["PASS" if cond else "FAIL", label])
	if not cond:
		failures.append(label)
