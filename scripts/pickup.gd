extends Area3D
## A world pickup resting on the dune surface. Driving a car over it grants the
## item (unless the car already holds one), then it disappears and respawns at the
## same spot after a delay. Built entirely in code — a colour-coded emissive orb.

const RESPAWN_DELAY := 5.0   ## seconds before a taken spot offers its item again
const SHAPE_RADIUS := 1.2    ## pickup trigger radius (generous, so driving over it is easy)
const SPIN_RATE := 1.5       ## rad/s idle spin, purely for readability

## Which item this spot hands out (a Car.Item value). Set before the node is added.
var item: int = Car.Item.NITRO

var _mesh: MeshInstance3D
var _shape: CollisionShape3D


func _ready() -> void:
	monitoring = true
	collision_mask = 1  # the cars sit on the default physics layer
	_build_visual()
	_build_shape()
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _mesh:
		_mesh.rotate_y(SPIN_RATE * delta)


func _build_visual() -> void:
	_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.7
	sphere.height = 1.4
	_mesh.mesh = sphere
	var col := _item_color()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 1.6
	_mesh.material_override = mat
	add_child(_mesh)


func _build_shape() -> void:
	_shape = CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = SHAPE_RADIUS
	_shape.shape = s
	add_child(_shape)


func _item_color() -> Color:
	# Cool blue for nitro, hot orange for fireball — matching the HUD item box.
	return Color(0.3, 0.6, 1.0) if item == Car.Item.NITRO else Color(1.0, 0.4, 0.15)


func _on_body_entered(body: Node) -> void:
	if not visible:
		return  # already taken, waiting to respawn
	if body is Car and body.collect(item):
		_set_available(false)
		get_tree().create_timer(RESPAWN_DELAY).timeout.connect(_set_available.bind(true))


func _set_available(available: bool) -> void:
	visible = available
	# Toggling monitoring can happen mid physics-query flush (from body_entered),
	# so defer it to avoid "changing state while flushing queries" errors.
	set_deferred("monitoring", available)
