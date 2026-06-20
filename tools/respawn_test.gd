extends SceneTree
## Headless check for fall-off-edge respawn. Drives the car past the play-area
## edge and asserts it respawns at the centre ~20 m up after the fall delay, with
## its fall momentum cleared; also asserts a sub-delay excursion that returns
## in-bounds does NOT respawn. Prints PASS/FAIL, exits 1 on failure.
##   godot --headless -s tools/respawn_test.gd

const HALF := 100.0           ## play-area half-extent (matches main.gd)
const RESPAWN_HEIGHT := 20.0  ## expected respawn height above centre ground

var _failures := 0

func _initialize() -> void:
	var scene: Node3D = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(scene)
	_run.call_deferred(scene)

func _run(scene: Node3D) -> void:
	var car: CharacterBody3D = scene.get_node("Car")

	# 1) Sustained fall off the edge respawns at the centre, ~20 m up, with the
	#    fall's downward momentum cleared.
	car.global_position = Vector3(HALF + 50.0, RESPAWN_HEIGHT, 0.0)
	car.velocity = Vector3(0.0, -40.0, 0.0)
	var respawned := await _wait_for_respawn(car, 5.0)
	_check("respawn fires after falling off the edge", respawned)
	if respawned:
		var p := car.global_position
		_check("respawn at centre (x=%.2f z=%.2f)" % [p.x, p.z], absf(p.x) < 1.0 and absf(p.z) < 1.0)
		_check("respawn ~20 m up (y=%.2f)" % p.y, p.y > RESPAWN_HEIGHT - 5.0)
		_check("fall momentum cleared (vy=%.2f)" % car.velocity.y, car.velocity.y > -10.0)

	# 2) A fall shorter than the delay does not respawn, and returning in-bounds
	#    resets the timer so a second short fall also does not respawn.
	car.global_position = Vector3(HALF + 50.0, 8.0, 0.0)
	car.velocity = Vector3.ZERO
	await _wait(0.5)
	_check("no respawn before the delay elapses", absf(car.global_position.x) > HALF)

	car.global_position = Vector3(0.0, 8.0, 0.0)  # back in-bounds -> timer resets
	car.velocity = Vector3.ZERO
	await _wait(0.2)
	car.global_position = Vector3(HALF + 50.0, 8.0, 0.0)
	car.velocity = Vector3.ZERO
	await _wait(0.7)
	_check("returning in-bounds reset the timer (no respawn)", absf(car.global_position.x) > HALF)

	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(1 if _failures > 0 else 0)

func _wait_for_respawn(car: Node3D, timeout: float) -> bool:
	# Respawn snaps the car from out-of-bounds back to the centre; detect that.
	var start := Time.get_ticks_msec()
	while (Time.get_ticks_msec() - start) / 1000.0 < timeout:
		await process_frame
		var p := car.global_position
		if absf(p.x) < 1.0 and absf(p.z) < 1.0:
			return true
	return false

func _wait(seconds: float) -> void:
	var start := Time.get_ticks_msec()
	while (Time.get_ticks_msec() - start) / 1000.0 < seconds:
		await process_frame

func _check(label: String, ok: bool) -> void:
	print(("  ok  " if ok else " FAIL ") + label)
	if not ok:
		_failures += 1
