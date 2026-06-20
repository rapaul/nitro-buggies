extends SceneTree
## Headless behavioral test of the pickup / combat loop. Loads Main.tscn and
## asserts: drive-over collection sets the held item and a second pickup does not
## replace it; nitro doubles the effective top speed for ~5 s then reverts; a fired
## fireball spawns into the world, rides the dune surface, and despawns ~10 m past
## the edge; a fireball removes one enemy health bar; and losing all bars emits the
## elimination signal (clamped at zero). Run: godot --headless -s tools/pickup_test.gd
##
## Car/Fireball types and the item enum are resolved at runtime (after the scene
## loads), not via top-level preload/`Car.*` references: a `-s` tool is compiled
## before the Selection autoload is available, so statically pulling in car.gd
## (which references Selection) would fail to compile it. dune_height has no such
## dependency, so it is safe to preload.

const Dune := preload("res://scripts/dune_height.gd")

var main: Node3D
var car: CharacterBody3D
var failures: Array[String] = []

# Resolved at runtime in _initialize.
var FireballType: GDScript
var PickupType: GDScript
var NONE: int
var NITRO: int
var FIREBALL: int


func _initialize() -> void:
	main = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(main)
	car = main.get_node("Car")
	var car_type: GDScript = car.get_script()
	NONE = car_type.Item.NONE
	NITRO = car_type.Item.NITRO
	FIREBALL = car_type.Item.FIREBALL
	FireballType = load("res://scripts/fireball.gd")
	PickupType = load("res://scripts/pickup.gd")
	_run.call_deferred()


func _run() -> void:
	await _steps(4)  # let the scene and pickups settle
	await _test_collect_and_no_replace()
	await _test_drive_over_grants()
	await _test_nitro_boost()
	await _test_fireball_spawns_on_use()
	await _test_fireball_terrain_follow_and_despawn()
	await _test_fireball_damages_enemy()
	await _test_use_item_input_routing()
	await _test_damage_and_elimination()  # destructive (freezes the match): keep last

	print("\n==== RESULT ====")
	if failures.is_empty():
		print("ALL CHECKS PASSED")
	else:
		print("FAILURES: ", failures.size())
		for f in failures:
			print("  - ", f)
	quit(0 if failures.is_empty() else 1)


# --- Tests ---

func _test_collect_and_no_replace() -> void:
	car.held_item = NONE
	var first: bool = car.collect(NITRO)
	_check("Collect: empty car takes the item", first and car.held_item == NITRO,
		"ok=%s held=%d" % [first, car.held_item])
	var second: bool = car.collect(FIREBALL)
	_check("No-replace: already-held car rejects a second pickup",
		not second and car.held_item == NITRO, "ok=%s held=%d" % [second, car.held_item])


func _test_drive_over_grants() -> void:
	# Drop a pickup onto the car and step physics: the Area3D should grant it.
	car.held_item = NONE
	_reset()
	var pickup: Area3D = PickupType.new()
	pickup.item = FIREBALL
	main.add_child(pickup)
	pickup.global_position = car.global_position
	await _steps(6)
	_check("Drive-over: overlapping an available pickup grants its item",
		car.held_item == FIREBALL, "held=%d" % car.held_item)
	pickup.queue_free()
	car.held_item = NONE


func _test_nitro_boost() -> void:
	_reset()
	Input.action_press("accelerate", 1.0)
	await _steps(150)  # reach the normal cap (~22)
	var base := car.velocity.length()
	car.held_item = NITRO
	car.use_item()
	await _steps(72)  # ~1.2 s into the boost
	var boosted := car.velocity.length()
	_check("Nitro: top speed exceeds the normal cap while boosting",
		boosted > 30.0 and boosted > base + 5.0, "base=%.1f boosted=%.1f" % [base, boosted])
	await _steps(360)  # let the 5 s boost lapse (still full throttle)
	var after := car.velocity.length()
	_check("Nitro: top speed returns to normal after 5 s", after <= 22.6,
		"after=%.1f" % after)
	Input.action_release("accelerate")


func _test_fireball_spawns_on_use() -> void:
	_reset()
	car.held_item = FIREBALL
	car.use_item()  # synchronous: fired_fireball -> main spawns the projectile
	var balls := _find_fireballs()
	_check("Fireball: using one spawns a projectile in the world", balls.size() == 1,
		"count=%d" % balls.size())
	_check("Fireball: held item cleared after use", car.held_item == NONE,
		"held=%d" % car.held_item)
	for b in balls:
		b.queue_free()
	await _steps(2)


func _test_fireball_terrain_follow_and_despawn() -> void:
	# A fireball heading toward the +X edge from a duney spot: it should ride the
	# surface, then disappear ~10 m past the edge (HALF=100, OFF_EDGE=10 -> ~110).
	var ball: Area3D = FireballType.new()
	ball.heading = Vector3(1, 0, 0)
	main.add_child(ball)
	ball.global_position = Vector3(90.0, 0.0, 30.0)
	await _steps(4)
	var p: Vector3 = ball.global_position
	var surf: float = Dune.height(p.x, p.z) + FireballType.SURFACE_OFFSET
	_check("Fireball: advances along its heading (+X)", p.x > 90.0, "x=%.2f" % p.x)
	_check("Fireball: rides the dune surface", absf(p.y - surf) < 0.05,
		"y=%.3f surf=%.3f" % [p.y, surf])
	await _steps(60)  # carry it past HALF + OFF_EDGE
	_check("Fireball: disappears ~10 m past the edge", not is_instance_valid(ball),
		"valid=%s" % is_instance_valid(ball))


func _test_fireball_damages_enemy() -> void:
	# A second car downrange; a fireball (fired by the player car) should remove one
	# of its bars and be consumed on contact.
	var enemy: CharacterBody3D = main.CarScene.instantiate()
	main.add_child(enemy)
	enemy.global_position = Vector3(30.0, Dune.height(30.0, 0.0) + 0.2, 0.0)
	enemy.velocity = Vector3.ZERO
	await _steps(10)  # let it settle
	var start_health: int = enemy.health
	var ball: Area3D = FireballType.new()
	ball.owner_car = car
	ball.heading = Vector3(1, 0, 0)
	main.add_child(ball)
	ball.global_position = Vector3(24.0, Dune.height(24.0, 0.0) + 0.2, 0.0)
	await _steps(30)
	_check("Fireball hit: enemy loses exactly one bar", enemy.health == start_health - 1,
		"before=%d after=%d" % [start_health, enemy.health])
	_check("Fireball hit: the projectile is consumed", not is_instance_valid(ball),
		"valid=%s" % is_instance_valid(ball))
	enemy.queue_free()
	await _steps(2)


func _test_use_item_input_routing() -> void:
	# The Player 1 "use_item" action (via the input system) must trigger only car 1.
	_reset()
	car.held_item = NITRO
	var ev := InputEventAction.new()
	ev.action = "use_item"
	ev.pressed = true
	Input.parse_input_event(ev)
	await _steps(3)
	_check("Input: 'use_item' action consumes the held item", car.held_item == NONE,
		"held=%d" % car.held_item)
	for b in _find_fireballs():
		b.queue_free()
	await _steps(2)


func _test_damage_and_elimination() -> void:
	car.health = 3
	var eliminated := [false]
	car.eliminated.connect(func(): eliminated[0] = true)
	car.take_damage(1)
	_check("Damage: one hit removes one bar", car.health == 2, "health=%d" % car.health)
	car.take_damage(1)
	car.take_damage(1)
	_check("Elimination: losing the last bar fires 'eliminated'",
		car.health == 0 and eliminated[0], "health=%d elim=%s" % [car.health, eliminated[0]])
	car.take_damage(1)
	_check("Damage: clamps at zero", car.health == 0, "health=%d" % car.health)


# --- Helpers ---

func _find_fireballs() -> Array:
	var out: Array = []
	for c in main.get_children():
		if c is Area3D and c.get_script() == FireballType:
			out.append(c)
	return out


func _steps(n: int) -> void:
	for i in n:
		await physics_frame


func _reset(pos: Vector3 = Vector3.ZERO) -> void:
	pos.y = Dune.height(pos.x, pos.z) + 0.2
	car.global_transform = Transform3D(Basis(), pos)
	car.velocity = Vector3.ZERO


func _check(label: String, cond: bool, extra: String = "") -> void:
	var tag := "PASS" if cond else "FAIL"
	if not cond:
		failures.append(label + (("  (" + extra + ")") if extra != "" else ""))
	print("[%s] %s  %s" % [tag, label, extra])
