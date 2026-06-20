extends Node3D
## Top-level scene controller: builds the dune terrain, then handles pause toggle
## and controller hotplug. Runs with PROCESS_MODE_ALWAYS so pause keeps working
## while paused.

const Dune := preload("res://scripts/dune_height.gd")
const CarScene := preload("res://scenes/Car.tscn")
const CameraScript := preload("res://scripts/camera.gd")
const PickupScript := preload("res://scripts/pickup.gd")
const FireballScript := preload("res://scripts/fireball.gd")
const HUDScript := preload("res://scripts/hud.gd")

const HALF := 100.0       ## play area extends +/- this on X and Z (200x200)
const MESH_STEP := 2.0    ## visual grid spacing (m); collision is finer (1m)
const SAND := Color(0.80, 0.60, 0.34)
const FALL_LIMIT := 1.0   ## seconds off the edge before the car respawns
const RESPAWN_HEIGHT := 20.0  ## metres above the centre ground to respawn at
const PLAYER_SPAWN_X := 4.0   ## each 2P car spawns this far either side of centre

# Eight fixed pickup spots — [x, z, item] — scattered clear of the centre spawn,
# each seated on the dune surface. Each spot respawns its own item after a delay.
const PICKUP_SPOTS := [
	[-40.0, -40.0, Car.Item.NITRO],
	[40.0, -40.0, Car.Item.FIREBALL],
	[-40.0, 40.0, Car.Item.FIREBALL],
	[40.0, 40.0, Car.Item.NITRO],
	[0.0, -55.0, Car.Item.FIREBALL],
	[0.0, 55.0, Car.Item.NITRO],
	[-55.0, 0.0, Car.Item.NITRO],
	[55.0, 0.0, Car.Item.FIREBALL],
]

# Active cars and a per-car fall timer (parallel arrays). One entry in
# single-player, two in split-screen, so the off-edge respawn handles each
# independently.
var _cars: Array[CharacterBody3D] = []
var _fall_times: Array[float] = []

# Per-player HUDs (parallel to _cars) on a shared overlay layer, plus the
# one-shot match-over latch that drives the WASTED / WINNER overlays.
var _huds: Array = []
var _hud_layer: CanvasLayer
var _match_over := false


func _ready() -> void:
	_build_terrain()
	_orient_sun()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	if Selection.player_count == 2:
		_setup_two_players()
	else:
		_setup_single_player()
	_spawn_pickups()


func _setup_single_player() -> void:
	# The Car and Camera3D authored in Main.tscn, unchanged. Wire the follow
	# camera in code because node-reference exports don't resolve reliably from a
	# hand-authored .tscn NodePath.
	$Camera3D.target = $Car
	_cars = [$Car]
	_fall_times = [0.0]
	# Full-screen HUD over the single view.
	var vp := get_viewport().get_visible_rect().size
	_setup_huds([$Car], [Rect2(Vector2.ZERO, vp)])


func _setup_two_players() -> void:
	# Player 1 is the Car already in Main.tscn; Player 2 is a second car spawned
	# beside it, driven by the arrow-key action set and rendering its own pick.
	# Both cars share one world; each is shown in its own split-screen half.
	$Camera3D.current = false  # the split viewports drive rendering now

	var car1: CharacterBody3D = $Car
	car1.input_prefix = ""
	var car2: CharacterBody3D = CarScene.instantiate()
	car2.input_prefix = "p2_"
	car2.model_path = Selection.player2_model_path
	add_child(car2)

	_place_car(car1, -PLAYER_SPAWN_X)
	_place_car(car2, PLAYER_SPAWN_X)

	_cars = [car1, car2]
	_fall_times = [0.0, 0.0]

	# Horizontal split: Player 1 on top, Player 2 on the bottom.
	var layer := CanvasLayer.new()
	add_child(layer)
	_add_player_view(layer, car1, 0.0, 0.5)
	_add_player_view(layer, car2, 0.5, 1.0)

	# Per-player HUDs over each half, using the same split rects as the views.
	var vp := get_viewport().get_visible_rect().size
	var top_rect := Rect2(0.0, 0.0, vp.x, vp.y * 0.5)
	var bot_rect := Rect2(0.0, vp.y * 0.5, vp.x, vp.y * 0.5)
	_setup_huds([car1, car2], [top_rect, bot_rect])


func _place_car(car: CharacterBody3D, x: float) -> void:
	car.global_position = Vector3(x, Dune.height(x, 0.0) + 1.0, 0.0)
	car.velocity = Vector3.ZERO


func _add_player_view(parent: CanvasLayer, car: CharacterBody3D, top: float, bottom: float) -> void:
	# A SubViewportContainer anchored to its screen half, holding a SubViewport
	# that shares the main world (so terrain, lights, and both cars exist once),
	# with its own chase camera following this player's car.
	var container := SubViewportContainer.new()
	container.stretch = true
	container.anchor_left = 0.0
	container.anchor_right = 1.0
	container.anchor_top = top
	container.anchor_bottom = bottom
	container.offset_left = 0.0
	container.offset_top = 0.0
	container.offset_right = 0.0
	container.offset_bottom = 0.0
	parent.add_child(container)

	var viewport := SubViewport.new()
	viewport.own_world_3d = false
	viewport.world_3d = get_world_3d()  # share Main's world
	container.add_child(viewport)

	var cam := Camera3D.new()
	cam.set_script(CameraScript)
	cam.target = car
	cam.current = true
	viewport.add_child(cam)


func _setup_huds(cars: Array, rects: Array) -> void:
	# One HUD per player on a shared overlay layer (drawn above the 3D views).
	# Also routes each car's fireball spawn and elimination through main, which
	# owns the shared world and the match-over state.
	_hud_layer = CanvasLayer.new()
	add_child(_hud_layer)
	for i in cars.size():
		var car: Car = cars[i]
		var hud := HUDScript.new()
		_hud_layer.add_child(hud)
		hud.setup(car, rects[i])
		_huds.append(hud)
		car.fired_fireball.connect(_on_fired_fireball.bind(car))
		car.eliminated.connect(_on_car_eliminated.bind(i))


func _spawn_pickups() -> void:
	# One pickup per fixed spot, seated on the dune surface.
	for spot in PICKUP_SPOTS:
		var x: float = spot[0]
		var z: float = spot[1]
		var pickup: Area3D = PickupScript.new()
		pickup.item = spot[2]
		add_child(pickup)
		pickup.global_position = Vector3(x, Dune.height(x, z) + 1.0, z)


func _on_fired_fireball(origin: Vector3, heading: Vector3, shooter: Node) -> void:
	# Spawn the projectile into the shared world (a sibling of the cars) so it can
	# strike the other car. The shooter is recorded so it can't hit itself.
	var fireball: Area3D = FireballScript.new()
	fireball.owner_car = shooter
	fireball.heading = heading
	add_child(fireball)
	fireball.global_position = origin


func _on_car_eliminated(loser: int) -> void:
	# First car to lose all its bars ends the match: WASTED on its view, WINNER on
	# every other, and gameplay freezes.
	if _match_over:
		return
	_match_over = true
	for i in _huds.size():
		if i == loser:
			_huds[i].show_wasted()
		else:
			_huds[i].show_winner()
	for car in _cars:
		car.set_physics_process(false)
		car.set_process(false)


func _process(delta: float) -> void:
	# Recover any car that drives off the edge. Past +/- HALF there is no terrain
	# or collision, so the car free-falls forever. Once it has been out of bounds
	# for FALL_LIMIT seconds, respawn it at the (flat) centre, RESPAWN_HEIGHT up;
	# returning in-bounds beforehand resets that car's timer so normal jumps are
	# untouched. Each car is tracked independently (one or two cars).
	for i in _cars.size():
		var p: Vector3 = _cars[i].global_position
		if absf(p.x) > HALF or absf(p.z) > HALF:
			_fall_times[i] += delta
			if _fall_times[i] >= FALL_LIMIT:
				_cars[i].respawn(Vector3(0.0, Dune.height(0.0, 0.0) + RESPAWN_HEIGHT, 0.0))
				_fall_times[i] = 0.0
		else:
			_fall_times[i] = 0.0


func _orient_sun() -> void:
	# Low (~14°) warm sun raking across the X-running ridges (travels mostly -Z).
	# Set in code via look_at because the .tscn 12-float Transform3D is row-major,
	# which makes a hand-authored rotation easy to transpose by mistake.
	var el := deg_to_rad(14.0)
	var horiz := Vector2(0.186, -0.982).normalized() * cos(el)
	var dir := Vector3(horiz.x, -sin(el), horiz.y)
	$DirectionalLight3D.look_at($DirectionalLight3D.global_position + dir)


func _build_terrain() -> void:
	# Visual surface and collision are both sampled from DuneHeight so they can
	# never drift apart. The mesh uses a coarser grid (plenty smooth at this
	# wavelength); collision uses a 1m heightmap so the car hugs the contour.
	$Ground/GroundMesh.mesh = _build_mesh()

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.roughness = 1.0

	# Large-scale tonal variation so the sand reads as a surface rather than one
	# flat colour. A procedural noise, colour-ramped between a slightly darker and
	# a slightly lighter sand (bracketing SAND so the base tone is preserved, not
	# darkened), sampled triplanar from world position — no UVs on the mesh.
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.5
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.75, 0.56, 0.32))  # a touch below SAND
	ramp.set_color(1, Color(0.83, 0.64, 0.39))  # a touch above SAND
	var ntex := NoiseTexture2D.new()
	ntex.noise = noise
	ntex.color_ramp = ramp
	mat.albedo_texture = ntex
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(0.06, 0.06, 0.06)  # ~16 m features: gentle mottling, not puddles

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
