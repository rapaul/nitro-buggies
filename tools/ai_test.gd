extends SceneTree
## Headless behavioural test of the single-player AI opponent. Sets
## Selection.player_count = 1 and ai_opponent = true, loads Main.tscn, and asserts:
## a second, AI-controlled car plus an AIDriver are spawned; an empty AI closes
## distance on the nearest available pickup (steering sign correct); a hunting AI
## weaves so its steering reverses at least every ~0.5 s (never straight longer);
## and the fireball aim is on-target for a "hit" decision (damaging the player) and
## offset wide for a "miss" decision.
## Run: godot --headless -s tools/ai_test.gd
##
## Types and the item enum are resolved at runtime (after the scene loads), like
## pickup_test.gd, because a `-s` tool compiles before the Selection autoload exists.

const Dune := preload("res://scripts/dune_height.gd")

var main: Node3D
var player: CharacterBody3D
var ai: CharacterBody3D
var driver: Node
var failures: Array[String] = []

var NONE: int
var NITRO: int
var FIREBALL: int

var _half_second_frames: int


func _initialize() -> void:
	var sel := get_root().get_node("Selection")
	sel.player_count = 1
	sel.ai_opponent = true
	main = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(main)
	_half_second_frames = int(Engine.physics_ticks_per_second * 0.5)
	var car_type: GDScript = main.get_node("Car").get_script()
	NONE = car_type.Item.NONE
	NITRO = car_type.Item.NITRO
	FIREBALL = car_type.Item.FIREBALL
	_run.call_deferred()


func _run() -> void:
	await _steps(10)  # let both cars settle on the surface

	if not _test_spawned():
		_finish()
		return
	await _test_real_spawn_stable()  # must run before any test that repositions cars
	await _test_seek_pickup()
	await _test_weave()
	_test_fireball_aim()
	await _test_fireball_hit_damages_player()

	_finish()


# --- Tests ---

func _test_spawned() -> bool:
	var cars: Array = main._cars
	_check("AI opponent spawned alongside the player (two cars)", cars.size() == 2,
		"count=%d" % cars.size())
	if cars.size() != 2:
		return false
	player = cars[0]
	ai = cars[1]
	driver = main._ai_driver
	_check("Opponent car is AI-controlled", ai.ai_controlled == true,
		"ai_controlled=%s" % ai.ai_controlled)
	_check("Player car is not AI-controlled", player.ai_controlled == false,
		"ai_controlled=%s" % player.ai_controlled)
	_check("An AIDriver was created and wired to the AI car",
		driver != null and driver.car == ai and driver.player == player,
		"driver=%s" % driver)
	return driver != null


func _test_real_spawn_stable() -> void:
	# Regression for the real 1P spawn (no manual repositioning): the player and AI
	# must spawn at distinct, non-overlapping spots and stay there. Two same-scene
	# CharacterBody3D bodies that start co-located in the physics server snap onto
	# each other / depenetrate explosively on the first move_and_slide — which made
	# the cars overlap and get stuck. The earlier tests teleported the cars apart,
	# so they masked this; this one drives the untouched spawn.
	var p0 := player.global_position
	var a0 := ai.global_position
	_check("Spawn: player and AI start apart, not overlapping",
		_planar_dist(p0, a0) > 10.0, "dist=%.1f" % _planar_dist(p0, a0))

	# Let the scene run under its own control (no input) for ~1.5 s and watch the
	# idle player: if it were flung or snapped onto the AI it would move tens of m.
	var p_drift_max := 0.0
	for i in 90:
		await _steps(1)
		p_drift_max = maxf(p_drift_max, _planar_dist(player.global_position, p0))
	_check("Spawn: idle player stays put (no physics explosion or teleport)",
		p_drift_max < 3.0, "max_drift=%.1f" % p_drift_max)
	_check("Spawn: cars never overlap after settling",
		_planar_dist(player.global_position, ai.global_position) > 5.0,
		"dist=%.1f" % _planar_dist(player.global_position, ai.global_position))
	# And the AI actually drives itself (seeks a pickup) rather than sitting stuck.
	_check("Spawn: AI drives away from its spawn (not stuck)",
		_planar_dist(ai.global_position, a0) > 5.0,
		"moved=%.1f" % _planar_dist(ai.global_position, a0))


func _test_seek_pickup() -> void:
	# Empty AI placed facing the nearest pickup should close distance on it.
	ai.held_item = NONE
	_place(ai, Vector3(40.0, 0.0, 60.0))  # nearest pickup is the spot at (40, 40)
	await _steps(2)
	var target := _nearest_pickup_pos(ai.global_position)
	var start := _planar_dist(ai.global_position, target)
	await _steps(60)  # ~1 s under full throttle, before it reaches/collects
	var ended := _planar_dist(ai.global_position, target)
	_check("Seek: empty AI closes distance on the nearest pickup",
		ended < start - 5.0, "start=%.1f end=%.1f" % [start, ended])


func _test_weave() -> void:
	# Holding an item, the AI hunts and weaves. Freeze the car and put the player to
	# the side (so it never lines up to fire) and sample the applied steer: its sign
	# must reverse at least every ~0.5 s, i.e. it is never straight longer than that.
	_place(ai, Vector3(0.0, 0.0, 0.0))
	ai.held_item = FIREBALL
	ai.set_physics_process(false)  # hold heading; the driver still computes ai_steer
	_place(player, Vector3(30.0, 0.0, 0.0))  # 90deg to the side: aim never aligns

	var max_run := 0
	var run := 0
	var flips := 0
	var prev_sign := 0
	for i in 120:  # 2 s
		await _steps(1)
		var s: int = signi(int(signf(ai.ai_steer)))
		if s == 0:
			s = prev_sign  # never expected (weave dominates), treat as no change
		if s == prev_sign or prev_sign == 0:
			run += 1
		else:
			flips += 1
			run = 1
		max_run = maxi(max_run, run)
		prev_sign = s

	ai.set_physics_process(true)
	ai.held_item = NONE
	_check("Weave: steering reverses, never straight for more than ~0.5 s",
		flips >= 2 and max_run <= _half_second_frames + 2,
		"flips=%d max_run=%d limit=%d" % [flips, max_run, _half_second_frames + 2])


func _test_fireball_aim() -> void:
	# Unit-check the aim point for the two committed decisions. The AI fires straight
	# ahead, so aiming at the player hits and aiming at an offset point flies wide.
	_place(ai, Vector3(0.0, 0.0, 0.0))
	_place(player, Vector3(0.0, 0.0, -15.0))  # straight ahead of the AI (-Z)
	driver._fireball_decided = true

	driver._fireball_will_miss = false
	var hit_aim: Vector3 = driver._fireball_aim_point()
	_check("Fireball hit: aim point is the player", hit_aim == player.global_position,
		"aim=%v player=%v" % [hit_aim, player.global_position])

	driver._fireball_will_miss = true
	var miss_aim: Vector3 = driver._fireball_aim_point()
	var lateral := _planar_dist(miss_aim, player.global_position)
	var los := (player.global_position - ai.global_position)
	los.y = 0.0
	var off := miss_aim - player.global_position
	off.y = 0.0
	_check("Fireball miss: aim point is offset ~12 m to the side of the player",
		absf(lateral - 12.0) < 0.5 and absf(off.normalized().dot(los.normalized())) < 0.01,
		"lateral=%.2f dot=%.3f" % [lateral, off.normalized().dot(los.normalized())])

	driver._fireball_decided = false


func _test_fireball_hit_damages_player() -> void:
	# End-to-end "hit": AI facing the player fires and removes one of its bars.
	_place(ai, Vector3(0.0, 0.0, 0.0))            # identity basis -> forward is -Z
	_place(player, Vector3(0.0, 0.0, -15.0))      # 15 m straight ahead
	ai.set_physics_process(false)
	player.set_physics_process(false)
	var before: int = player.health
	ai.held_item = FIREBALL
	driver._fireball_decided = true
	driver._fireball_will_miss = false
	await _steps(45)  # let the driver fire and the projectile reach the player
	_check("Fireball hit: a forced on-target shot removes one of the player's bars",
		player.health == before - 1, "before=%d after=%d" % [before, player.health])
	ai.set_physics_process(true)
	player.set_physics_process(true)


# --- Helpers ---

func _nearest_pickup_pos(from: Vector3) -> Vector3:
	var best := Vector3.ZERO
	var best_d := INF
	for pk in main._pickups:
		if not is_instance_valid(pk) or not pk.visible:
			continue
		var d: float = from.distance_squared_to(pk.global_position)
		if d < best_d:
			best_d = d
			best = pk.global_position
	return best


func _place(car: CharacterBody3D, pos: Vector3) -> void:
	pos.y = Dune.height(pos.x, pos.z) + 0.5
	car.global_transform = Transform3D(Basis(), pos)
	car.velocity = Vector3.ZERO


func _planar_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _steps(n: int) -> void:
	for i in n:
		await physics_frame


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
