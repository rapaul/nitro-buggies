extends SceneTree
## Headless test for the two-player split-screen race. Sets Selection.player_count
## to 2, loads Main.tscn, and asserts: two cars exist in the shared world; the
## split rendering is wired (two SubViewports, each with a chase camera targeting
## its own car); and the keyboard split is honored — Player 1's actions drive only
## car 1 and Player 2's only car 2. Rendering isn't available headless, so this
## validates wiring and input routing, not pixels.
## Run: godot --headless -s tools/two_player_test.gd

const Dune := preload("res://scripts/dune_height.gd")

var main: Node3D
var failures: Array[String] = []

const P1_ACTIONS := ["accelerate", "brake", "steer_left", "steer_right", "handbrake"]
const P2_ACTIONS := ["p2_accelerate", "p2_brake", "p2_steer_left", "p2_steer_right", "p2_handbrake"]


func _initialize() -> void:
	var sel := get_root().get_node("Selection")
	sel.player_count = 2
	sel.selected_model_path = "res://assets/cars/sedan.glb"
	sel.player2_model_path = "res://assets/cars/police.glb"
	main = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(main)
	_run.call_deferred()


func _run() -> void:
	await _steps(10)  # let both cars settle on the surface

	# --- Two cars in the world ---
	var cars: Array = main._cars
	_check("Two cars spawned", cars.size() == 2, "count=%d" % cars.size())
	if cars.size() != 2:
		_finish()
		return
	var car1: CharacterBody3D = cars[0]
	var car2: CharacterBody3D = cars[1]
	_check("Player 1 car uses the default (empty) input prefix", car1.input_prefix == "",
		"prefix='%s'" % car1.input_prefix)
	_check("Player 2 car uses the 'p2_' input prefix", car2.input_prefix == "p2_",
		"prefix='%s'" % car2.input_prefix)

	# --- Split rendering wiring: two SubViewports, each a chase cam on its car ---
	var viewports: Array = []
	_collect(main, "SubViewport", viewports)
	_check("Two split-screen SubViewports exist", viewports.size() == 2,
		"count=%d" % viewports.size())
	var targets: Array = []
	for vp in viewports:
		for c in vp.get_children():
			if c is Camera3D:
				targets.append(c.target)
	_check("Each half has a chase camera following one of the cars",
		targets.size() == 2 and car1 in targets and car2 in targets,
		"targets=%d" % targets.size())

	# --- Keyboard split: P1 actions drive only car1, P2 actions only car2 ---
	_spawn_reset(car1, car2)
	Input.action_press("accelerate", 1.0)
	await _steps(120)
	var d1: float = _planar_dist(car1, -4.0)
	var d2: float = _planar_dist(car2, 4.0)
	_release()
	_check("Player 1 throttle drives car 1", d1 > 5.0, "d1=%.2f" % d1)
	_check("Player 1 throttle leaves car 2 still", d2 < 0.5, "d2=%.2f" % d2)

	_spawn_reset(car1, car2)
	Input.action_press("p2_accelerate", 1.0)
	await _steps(120)
	var e1: float = _planar_dist(car1, -4.0)
	var e2: float = _planar_dist(car2, 4.0)
	_release()
	_check("Player 2 throttle drives car 2", e2 > 5.0, "e2=%.2f" % e2)
	_check("Player 2 throttle leaves car 1 still", e1 < 0.5, "e1=%.2f" % e1)

	_finish()


# --- Helpers ---

func _spawn_reset(car1: CharacterBody3D, car2: CharacterBody3D) -> void:
	_reset_car(car1, -4.0)
	_reset_car(car2, 4.0)


func _reset_car(car: CharacterBody3D, x: float) -> void:
	car.global_transform = Transform3D(Basis(), Vector3(x, Dune.height(x, 0.0) + 0.2, 0.0))
	car.velocity = Vector3.ZERO


func _planar_dist(car: CharacterBody3D, spawn_x: float) -> float:
	# Horizontal displacement from the car's spawn point (ignoring settle in Y).
	var p := car.global_position
	return Vector2(p.x - spawn_x, p.z).length()


func _collect(node: Node, type_name: String, acc: Array) -> void:
	if node.get_class() == type_name:
		acc.append(node)
	for c in node.get_children():
		_collect(c, type_name, acc)


func _steps(n: int) -> void:
	for i in n:
		await physics_frame


func _release() -> void:
	for a in P1_ACTIONS + P2_ACTIONS:
		Input.action_release(a)


func _check(label: String, cond: bool, extra: String = "") -> void:
	var tag := "PASS" if cond else "FAIL"
	if not cond:
		failures.append(label + (("  (" + extra + ")") if extra != "" else ""))
	print("[%s] %s  %s" % [tag, label, extra])


func _finish() -> void:
	print("\n==== RESULT ====")
	if failures.is_empty():
		print("ALL CHECKS PASSED")
	else:
		print("FAILURES: ", failures.size())
		for f in failures:
			print("  - ", f)
	quit(0 if failures.is_empty() else 1)
