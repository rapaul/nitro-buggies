extends SceneTree
## Headless check that the visual car mesh rests on the sand instead of floating.
## Settles the car on flat, sloped, and valley terrain and asserts its lowest
## point sits on the DuneHeight surface; also confirms an airborne car is not
## pinned down to the terrain. Prints PASS/FAIL, exits 1 on failure.
##   godot --headless -s tools/ground_test.gd

const Dune := preload("res://scripts/dune_height.gd")
const TOL := 0.10   ## max allowed gap (m) between mesh bottom and the surface.
                    ## Catches the ~0.4 m float this change fixes; the slack absorbs
                    ## the few cm a flat underside can't conform to on curved sand.

var _failures := 0

func _initialize() -> void:
	var scene: Node3D = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(scene)
	_run.call_deferred(scene)

func _run(scene: Node3D) -> void:
	var car: CharacterBody3D = scene.get_node("Car")

	# Grounded: flat origin, two slopes, and a valley floor. After settling, the
	# mesh's lowest point must rest on the surface beneath it (no upward float
	# beyond tolerance, and no sinking below the sand).
	for spot in [Vector2(0, 0), Vector2(20, 35), Vector2(35, 60), Vector2(40, 52.5)]:
		car.global_position = Vector3(spot.x, 8.0, spot.y)
		car.velocity = Vector3.ZERO
		for i in 120:
			await physics_frame
		var low := _mesh_low_point(car)
		# Sample terrain directly beneath the lowest point, not the car centre: on a
		# slope the lowest point sits at the downhill end where the surface is lower.
		var gap := low.y - Dune.height(low.x, low.z)
		_check("grounded %s gap=%.3f within %.2f" % [spot, gap, TOL], absf(gap) <= TOL)

	# Airborne: hold the car high above the surface. It must not be on the floor and
	# the mesh must ride the body height (clearly above terrain), not be snapped down.
	var base := Dune.height(50.0, 50.0)
	car.global_position = Vector3(50.0, base + 30.0, 50.0)
	car.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame
	var low_air := _mesh_low_point(car)
	var air_gap := low_air.y - Dune.height(low_air.x, low_air.z)
	_check("airborne not pinned (mesh %.1f m above surface)" % air_gap, not car.is_on_floor() and air_gap > 1.0)

	print("RESULT: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(1 if _failures > 0 else 0)

func _check(label: String, ok: bool) -> void:
	print(("  ok  " if ok else " FAIL ") + label)
	if not ok:
		_failures += 1

func _mesh_low_point(car: Node3D) -> Vector3:
	# World-space lowest corner of the visual mesh's geometry (checks all 8 corners
	# of each mesh's AABB so the returned point's XZ is where the low Y actually is).
	var low := Vector3(0, INF, 0)
	for mi in _meshes(car.get_node("Mesh")):
		var m: MeshInstance3D = mi
		var aabb: AABB = m.get_aabb()
		for c in 8:
			var corner: Vector3 = m.global_transform * aabb.get_endpoint(c)
			if corner.y < low.y:
				low = corner
	return low

func _meshes(n: Node, acc: Array = []) -> Array:
	if n is MeshInstance3D:
		acc.append(n)
	for c in n.get_children():
		_meshes(c, acc)
	return acc
