extends SceneTree
## Headless behavioral test of the car physics. Loads Main.tscn, drives it by
## pressing InputMap actions (device-agnostic, the same path keyboard/gamepad
## feed), steps the fixed physics tick, and asserts the handling requirements.
## Run: godot --headless -s tools/drive_test.gd

var main: Node3D
var car: CharacterBody3D
var failures: Array[String] = []

const ACTIONS := ["accelerate", "brake", "steer_left", "steer_right", "handbrake"]


func _initialize() -> void:
	main = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(main)
	car = main.get_node("Car")
	_run.call_deferred()


func _run() -> void:
	await _steps(2)  # let the scene settle
	await _test_accelerate()
	await _test_reverse()
	await _test_steer_moving()
	await _test_steer_standstill()
	await _test_drift()
	await _test_framerate_independence()
	await _test_camera_follow()
	await _test_pause()

	print("\n==== RESULT ====")
	if failures.is_empty():
		print("ALL CHECKS PASSED")
	else:
		print("FAILURES: ", failures.size())
		for f in failures:
			print("  - ", f)
	quit(0 if failures.is_empty() else 1)


# --- Tests ---

func _test_accelerate() -> void:
	_reset()
	Input.action_press("accelerate", 1.0)
	await _steps(150)  # 2.5s at 60Hz
	var z := car.global_position.z
	var spd := car.velocity.length()
	_check("Accelerate: car moves forward (-Z)", z < -5.0, "z=%.2f" % z)
	_check("Accelerate: speed reaches and respects cap (15<spd<=22.1)",
		spd > 15.0 and spd <= 22.1, "spd=%.2f" % spd)
	_release()


func _test_reverse() -> void:
	_reset()
	Input.action_press("brake", 1.0)
	await _steps(150)
	var z := car.global_position.z
	var spd := car.velocity.length()
	_check("Reverse: brake from rest drives backward (+Z)", z > 2.0, "z=%.2f" % z)
	_check("Reverse: speed capped below forward max (<=7.1)", spd <= 7.1, "spd=%.2f" % spd)
	_release()


func _test_steer_moving() -> void:
	_reset()
	car.velocity = Vector3(0, 0, -12.0)  # rolling forward
	Input.action_press("accelerate", 1.0)
	Input.action_press("steer_right", 1.0)
	var yaw0 := car.rotation.y
	await _steps(60)
	var dyaw: float = absf(wrapf(car.rotation.y - yaw0, -PI, PI))
	_check("Steering: heading changes while moving", dyaw > 0.2, "dyaw=%.3f rad" % dyaw)
	_release()


func _test_steer_standstill() -> void:
	_reset()
	Input.action_press("steer_right", 1.0)
	var yaw0 := car.rotation.y
	await _steps(60)
	var dyaw: float = absf(wrapf(car.rotation.y - yaw0, -PI, PI))
	_check("Steering: no appreciable pivot at standstill", dyaw < 0.05, "dyaw=%.4f rad" % dyaw)
	_release()


func _test_drift() -> void:
	# Pure sideways velocity; measure lateral retained after 30 ticks.
	_reset()
	car.velocity = Vector3(8.0, 0, 0)
	await _steps(30)
	var lat_grip: float = absf(car.velocity.x)

	_reset()
	car.velocity = Vector3(8.0, 0, 0)
	Input.action_press("handbrake", 1.0)
	await _steps(30)
	var lat_drift: float = absf(car.velocity.x)
	_release()

	_check("Grip: lateral slide bleeds off quickly without handbrake", lat_grip < 1.0,
		"residual=%.2f" % lat_grip)
	_check("Drift: handbrake retains far more lateral slide", lat_drift > lat_grip + 1.5,
		"grip=%.2f drift=%.2f" % [lat_grip, lat_drift])


func _test_framerate_independence() -> void:
	var z_low := await _accel_run(30, 2.0)
	var z_high := await _accel_run(120, 2.0)
	Engine.physics_ticks_per_second = 60  # restore
	_check("Frame-rate independence: 30Hz vs 120Hz agree within 1.5m",
		absf(z_low - z_high) < 1.5, "z30=%.3f z120=%.3f diff=%.3f" % [z_low, z_high, absf(z_low - z_high)])


func _test_camera_follow() -> void:
	var cam: Camera3D = main.get_node("Camera3D")
	_reset(Vector3(0, 0, -60))  # teleport car away; camera must catch up
	var want: Vector3 = car.global_position + Basis(Vector3.UP, car.rotation.y) * cam.offset
	await _steps(150)
	var dist := cam.global_position.distance_to(want)
	_check("Camera: eases to follow the car", dist < 1.0, "dist_to_offset=%.3f" % dist)
	var p0 := cam.global_position
	await _steps(30)
	var moved := cam.global_position.distance_to(p0)
	_check("Camera: stable (no jitter) when car is stationary", moved < 0.02, "moved=%.4f" % moved)


func _test_pause() -> void:
	var was_paused := paused
	var ev := InputEventAction.new()
	ev.action = "pause"
	ev.pressed = true
	Input.parse_input_event(ev)
	await _steps(3)
	var toggled := paused
	_check("Pause: 'pause' action toggles SceneTree.paused", toggled != was_paused,
		"before=%s after=%s" % [was_paused, toggled])
	paused = false  # restore


# --- Helpers ---

func _accel_run(hz: int, secs: float) -> float:
	Engine.physics_ticks_per_second = hz
	_reset()
	Input.action_press("accelerate", 1.0)
	await _steps(int(secs * hz))
	var z := car.global_position.z
	_release()
	return z


func _steps(n: int) -> void:
	for i in n:
		await physics_frame


func _reset(pos: Vector3 = Vector3.ZERO) -> void:
	car.global_transform = Transform3D(Basis(), pos)
	car.velocity = Vector3.ZERO
	_release()


func _release() -> void:
	for a in ACTIONS:
		Input.action_release(a)


func _check(label: String, cond: bool, extra: String = "") -> void:
	var tag := "PASS" if cond else "FAIL"
	if not cond:
		failures.append(label + (("  (" + extra + ")") if extra != "" else ""))
	print("[%s] %s  %s" % [tag, label, extra])
