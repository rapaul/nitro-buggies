extends SceneTree
## Headless behavioral test of the car physics. Loads Main.tscn, drives it by
## pressing InputMap actions (device-agnostic, the same path keyboard/gamepad
## feed), steps the fixed physics tick, and asserts the handling requirements.
## Run: godot --headless -s tools/drive_test.gd

const Dune := preload("res://scripts/dune_height.gd")

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
	await _test_gravity_rest()
	await _test_slope_follow()
	await _test_jump_off_crest()
	await _test_slow_stays_grounded()
	await _test_camera_follow()
	await _test_terrain_orientation()
	await _test_handling_unchanged()
	await _test_air_righting()
	await _test_camera_steady()
	await _test_sand_spray()
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
	# Isolate the controller on flat ground: driving over undulating dunes couples
	# absolute position to discrete contact resolution (a coarse 30Hz tick steps
	# over the contour differently than 120Hz). That is terrain-contact noise, not
	# a handling property, so flatten the ground for this dt-invariance check.
	var col: CollisionShape3D = main.get_node("Ground/GroundCollision")
	var orig_shape := col.shape
	var flat := BoxShape3D.new()
	flat.size = Vector3(400, 1, 400)
	col.shape = flat
	col.position = Vector3(0, -0.5, 0)  # flat top at y=0
	await _steps(2)
	var z_low := await _accel_run(30, 2.0)
	var z_high := await _accel_run(120, 2.0)
	Engine.physics_ticks_per_second = 60  # restore
	col.shape = orig_shape
	col.position = Vector3.ZERO
	_check("Frame-rate independence: 30Hz vs 120Hz agree within 1.5m",
		absf(z_low - z_high) < 1.5, "z30=%.3f z120=%.3f diff=%.3f" % [z_low, z_high, absf(z_low - z_high)])


func _test_gravity_rest() -> void:
	# Drop the car from above a flat spot; gravity should bring it to rest on the
	# surface without sinking through or floating.
	car.global_transform = Transform3D(Basis(), Vector3(0, 6, 0))
	car.velocity = Vector3.ZERO
	_release()
	await _steps(120)
	var p := car.global_position
	var surf := Dune.height(p.x, p.z)
	_check("Gravity: car falls and rests on the surface", absf(p.y - surf) < 0.3 and car.is_on_floor(),
		"y=%.2f surf=%.2f on_floor=%s" % [p.y, surf, car.is_on_floor()])
	_check("Gravity: settled, not still sinking/falling", absf(car.velocity.y) < 0.5,
		"vy=%.3f" % car.velocity.y)


func _test_slope_follow() -> void:
	# Climb the x=40 ramp (trough z=52.5 -> crest z=17.5) at moderate speed: height
	# should rise following the contour while the car stays attached to the surface.
	_reset(Vector3(40, 0, 46))
	var y0 := car.global_position.y
	Input.action_press("accelerate", 0.5)
	var max_clear := 0.0
	for i in 60:
		await physics_frame
		var p := car.global_position
		max_clear = maxf(max_clear, p.y - Dune.height(p.x, p.z))
	var dy := car.global_position.y - y0
	_release()
	_check("Slope: car climbs the dune face (Y rises with the contour)", dy > 1.5, "dy=%.2f" % dy)
	_check("Slope: stays attached while climbing (low clearance)", max_clear < 0.8,
		"max_clear=%.2f" % max_clear)


func _test_jump_off_crest() -> void:
	# Full throttle up the ramp: the car should leave the crest and travel through
	# the air (clearance well above the surface for several ticks) then land. The
	# long, gentle face means a longer climb before launch and a bigger arc, so the
	# window matches the air-righting test (240 ticks) to catch the landing.
	_reset(Vector3(40, 0, 52.5))
	Input.action_press("accelerate", 1.0)
	var max_clear := 0.0
	var airborne_ticks := 0
	var landed := false
	for i in 240:
		await physics_frame
		var p := car.global_position
		var clear := p.y - Dune.height(p.x, p.z)
		max_clear = maxf(max_clear, clear)
		if clear > 0.8:
			airborne_ticks += 1
		elif airborne_ticks > 0 and car.is_on_floor():
			landed = true
	_release()
	_check("Jump: fast crest crossing goes airborne", max_clear > 0.8 and airborne_ticks >= 3,
		"max_clear=%.2f airborne_ticks=%d" % [max_clear, airborne_ticks])
	_check("Jump: car lands back on the surface", landed, "max_clear=%.2f" % max_clear)


func _test_slow_stays_grounded() -> void:
	# Approach the same crest gently: low crest speed should hug the contour and
	# never launch.
	_reset(Vector3(40, 0, 24))
	Input.action_press("accelerate", 0.3)
	var max_clear := 0.0
	for i in 90:
		await physics_frame
		var p := car.global_position
		max_clear = maxf(max_clear, p.y - Dune.height(p.x, p.z))
	_release()
	_check("Slow crest: stays grounded (no launch)", max_clear < 0.8, "max_clear=%.2f" % max_clear)


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


func _test_terrain_orientation() -> void:
	# Climb the x=40 dune face; the visual mesh should tilt to the slope rather
	# than staying level with the horizon.
	var mesh := car.get_node("Mesh") as Node3D
	_reset(Vector3(40, 0, 46))
	Input.action_press("accelerate", 0.5)
	var max_tilt := 0.0
	for i in 60:
		await physics_frame
		var up := mesh.global_transform.basis.y.normalized()
		max_tilt = maxf(max_tilt, up.angle_to(Vector3.UP))
	_release()
	_check("Tilt: mesh leans into the slope while grounded (not level)", max_tilt > 0.1,
		"max_tilt=%.3f rad" % max_tilt)


func _test_handling_unchanged() -> void:
	# The slope tilt is mesh-only: the physics body must stay yaw-only (its up
	# axis remains world-up) so acceleration/steering/grip are unaffected.
	_reset(Vector3(40, 0, 46))
	Input.action_press("accelerate", 0.6)
	Input.action_press("steer_right", 0.5)
	var max_body_tilt := 0.0
	for i in 90:
		await physics_frame
		var bu := car.global_transform.basis.y.normalized()
		max_body_tilt = maxf(max_body_tilt, bu.angle_to(Vector3.UP))
	_release()
	_check("Handling unchanged: car body stays yaw-only (up = world up)",
		max_body_tilt < 0.001, "max_body_tilt=%.5f rad" % max_body_tilt)


func _test_air_righting() -> void:
	# Launch off the crest, then verify the mesh keeps rotating in the air
	# (carries momentum, no instant snap) yet lands aligned to the surface.
	var mesh := car.get_node("Mesh") as Node3D
	_reset(Vector3(40, 0, 52.5))
	Input.action_press("accelerate", 1.0)
	var first_air_up := Vector3.ZERO
	var last_air_up := Vector3.ZERO
	var air_ticks := 0
	var landing_tilt := -1.0
	var was_air := false
	for i in 240:
		await physics_frame
		var p := car.global_position
		var clear := p.y - Dune.height(p.x, p.z)
		var up := mesh.global_transform.basis.y.normalized()
		if clear > 0.8 and not car.is_on_floor():
			if air_ticks == 0:
				first_air_up = up
			last_air_up = up
			air_ticks += 1
			was_air = true
		elif was_air and car.is_on_floor():
			landing_tilt = up.angle_to(car.get_floor_normal().normalized())
			was_air = false
	_release()
	var rotated := first_air_up.angle_to(last_air_up)
	_check("Air: mesh keeps rotating in flight (carries momentum, no instant snap)",
		air_ticks >= 3 and rotated > 0.03, "air_ticks=%d rotated=%.3f rad" % [air_ticks, rotated])
	_check("Air: lands wheels-down (mesh up aligns to surface on landing)",
		landing_tilt >= 0.0 and landing_tilt < 0.15, "landing_tilt=%.3f rad" % landing_tilt)


func _test_camera_steady() -> void:
	# Through a sharp turn the camera should ease around, not whip: its per-tick
	# orientation change stays bounded and the car stays in front of it.
	var cam: Camera3D = main.get_node("Camera3D")
	_reset(Vector3.ZERO)
	await _steps(120)  # let the camera converge on the stationary car first
	car.velocity = Vector3(0, 0, -12.0)
	Input.action_press("accelerate", 1.0)
	Input.action_press("steer_right", 1.0)
	var prev_fwd := -cam.global_transform.basis.z
	var max_step := 0.0
	var max_frame_angle := 0.0
	for i in 60:
		await physics_frame
		var fwd := -cam.global_transform.basis.z
		max_step = maxf(max_step, prev_fwd.angle_to(fwd))
		prev_fwd = fwd
		max_frame_angle = maxf(max_frame_angle, fwd.angle_to(car.global_position - cam.global_position))
	_release()
	_check("Camera: eases through a sharp turn without whipping (bounded step)",
		max_step < 0.12, "max_step=%.4f rad/tick" % max_step)
	_check("Camera: keeps the car framed while turning (stays ahead of camera)",
		max_frame_angle < 1.0, "max_frame_angle=%.3f rad" % max_frame_angle)


func _test_sand_spray() -> void:
	# The spray look isn't headless-verifiable, but its gating is: two emitters
	# exist, and they emit only when grounded and moving (off when stopped/airborne).
	var emitters: Array = []
	for c in car.get_children():
		if c is GPUParticles3D:
			emitters.append(c)
	_check("Spray: two rear-wheel emitters exist", emitters.size() == 2, "count=%d" % emitters.size())
	if emitters.size() != 2:
		return

	_reset()
	await _steps(5)
	_check("Spray: off while stationary", not emitters[0].emitting and not emitters[1].emitting,
		"l=%s r=%s" % [emitters[0].emitting, emitters[1].emitting])

	_reset()
	Input.action_press("accelerate", 1.0)
	await _steps(60)
	_check("Spray: on while driving on the ground", emitters[0].emitting and emitters[1].emitting,
		"l=%s r=%s" % [emitters[0].emitting, emitters[1].emitting])
	_release()

	# Launch off the crest and confirm the spray cuts out while airborne.
	_reset(Vector3(40, 0, 52.5))
	Input.action_press("accelerate", 1.0)
	var sprayed_airborne := false
	for i in 240:
		await physics_frame
		var p := car.global_position
		var clear := p.y - Dune.height(p.x, p.z)
		if clear > 0.8 and not car.is_on_floor() and (emitters[0].emitting or emitters[1].emitting):
			sprayed_airborne = true
	_release()
	_check("Spray: off while airborne", not sprayed_airborne, "sprayed_airborne=%s" % sprayed_airborne)


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
	# Snap onto the dune surface (plus a small drop) so the car reliably settles
	# on the floor. The handling tests drive the flat x=0 / z=0 axes (height 0),
	# so this leaves them on level ground.
	pos.y = Dune.height(pos.x, pos.z) + 0.2
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
