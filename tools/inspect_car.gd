extends SceneTree
## Headless check of the imported car mesh: combined AABB (scale) and which
## axis is the car's length (orientation). Run:
##   godot --headless -s tools/inspect_car.gd

var _car: Node3D
var _done := false

func _initialize() -> void:
	_car = load("res://scenes/Car.tscn").instantiate()
	get_root().add_child(_car)

func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true

	var meshes := _find_meshes(_car)
	print("MeshInstance3D count: ", meshes.size())

	var aabb := AABB()
	var first := true
	for mi in meshes:
		var m: MeshInstance3D = mi
		# AABB in the car root's local space.
		var local_xform: Transform3D = _car.global_transform.affine_inverse() * m.global_transform
		var world: AABB = local_xform * m.get_aabb()
		if first:
			aabb = world
			first = false
		else:
			aabb = aabb.merge(world)

	var s := aabb.size
	print("Combined AABB size (x,y,z): ", s)
	print("AABB min y (relative to car origin): %.3f" % aabb.position.y)
	print("Length(Z): %.3f  Width(X): %.3f  Height(Y): %.3f" % [s.z, s.x, s.y])
	print("Orientation: ", "OK — longer along Z (faces -Z)" if s.z >= s.x else "ROTATED — longer along X")
	return true

func _find_meshes(n: Node, acc: Array = []) -> Array:
	if n is MeshInstance3D:
		acc.append(n)
	for c in n.get_children():
		_find_meshes(c, acc)
	return acc
