extends Area3D
## A fireball projectile launched straight ahead of a car. It hugs the dune
## surface as it travels and continues until it has gone ~10 m past the play-area
## edge, where it disappears. Striking any car other than the one that fired it
## removes one of that car's health bars and consumes the fireball.

const SPEED := 30.0          ## m/s forward travel
const SURFACE_OFFSET := 0.5  ## metres above the dune surface it rides at
const HALF := 100.0          ## play-area half-extent — must match main.gd's HALF
const OFF_EDGE := 10.0       ## metres past the edge before it disappears
const SHAPE_RADIUS := 0.6

## The car that fired this projectile; skipped so it can't hit its own shooter.
var owner_car: Node = null
## Horizontal unit heading the fireball travels along (set before adding to tree).
var heading := Vector3.FORWARD

var _mesh: MeshInstance3D


func _ready() -> void:
	monitoring = true
	collision_mask = 1  # the cars sit on the default physics layer
	heading.y = 0.0
	heading = heading.normalized()
	_build_visual()
	_build_shape()
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var p := global_position + heading * SPEED * delta
	# Follow the terrain via the same height source the ground mesh/collision use.
	p.y = DuneHeight.height(p.x, p.z) + SURFACE_OFFSET
	global_position = p
	if absf(p.x) > HALF + OFF_EDGE or absf(p.z) > HALF + OFF_EDGE:
		queue_free()


func _build_visual() -> void:
	_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	_mesh.mesh = sphere
	var col := Color(1.0, 0.45, 0.1)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 2.5
	_mesh.material_override = mat
	add_child(_mesh)


func _build_shape() -> void:
	var shape := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = SHAPE_RADIUS
	shape.shape = s
	add_child(shape)


func _on_body_entered(body: Node) -> void:
	if body == owner_car:
		return
	if body is Car:
		body.take_damage(1)
		queue_free()
