extends Node3D
## Top-level scene controller: builds the dune terrain, then handles pause toggle
## and controller hotplug. Runs with PROCESS_MODE_ALWAYS so pause keeps working
## while paused.

const Dune := preload("res://scripts/dune_height.gd")

const HALF := 100.0       ## play area extends +/- this on X and Z (200x200)
const MESH_STEP := 2.0    ## visual grid spacing (m); collision is finer (1m)
const SAND := Color(0.85, 0.72, 0.46)


func _ready() -> void:
	_build_terrain()
	# Wire the follow camera to the car. Done in code because node-reference
	# exports don't resolve reliably from a hand-authored .tscn NodePath.
	$Camera3D.target = $Car
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _build_terrain() -> void:
	# Visual surface and collision are both sampled from DuneHeight so they can
	# never drift apart. The mesh uses a coarser grid (plenty smooth at this
	# wavelength); collision uses a 1m heightmap so the car hugs the contour.
	$Ground/GroundMesh.mesh = _build_mesh()

	var mat := StandardMaterial3D.new()
	mat.albedo_color = SAND
	mat.roughness = 1.0
	$Ground/GroundMesh.material_override = mat

	$Ground/GroundCollision.shape = _build_collision()


func _build_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cells := int(2.0 * HALF / MESH_STEP)
	for j in cells:
		var z0 := -HALF + j * MESH_STEP
		var z1 := z0 + MESH_STEP
		for i in cells:
			var x0 := -HALF + i * MESH_STEP
			var x1 := x0 + MESH_STEP
			_add_vertex(st, x0, z0)
			_add_vertex(st, x1, z0)
			_add_vertex(st, x1, z1)
			_add_vertex(st, x0, z0)
			_add_vertex(st, x1, z1)
			_add_vertex(st, x0, z1)
	return st.commit()


func _add_vertex(st: SurfaceTool, x: float, z: float) -> void:
	# Analytic-ish normal via central differences keeps it pointing up regardless
	# of triangle winding (DuneHeight stays the only source of the shape).
	var e := MESH_STEP * 0.5
	var nx := Dune.height(x - e, z) - Dune.height(x + e, z)
	var nz := Dune.height(x, z - e) - Dune.height(x, z + e)
	st.set_normal(Vector3(nx, 2.0 * e, nz).normalized())
	st.add_vertex(Vector3(x, Dune.height(x, z), z))


func _build_collision() -> HeightMapShape3D:
	# 1m grid: (2*HALF + 1) points per side, centered on the origin by the shape.
	var n := int(2.0 * HALF) + 1
	var data := PackedFloat32Array()
	data.resize(n * n)
	for d in n:
		var z := float(d) - HALF
		for w in n:
			var x := float(w) - HALF
			data[d * n + w] = Dune.height(x, z)
	var shape := HeightMapShape3D.new()
	shape.map_width = n
	shape.map_depth = n
	shape.map_data = data
	return shape


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	# Input still flows through the InputMap regardless; this just surfaces the
	# connect/disconnect so a controller plugged in after launch is recognized.
	if connected:
		print("Gamepad connected: ", Input.get_joy_name(device))
	else:
		print("Gamepad disconnected: device ", device)
