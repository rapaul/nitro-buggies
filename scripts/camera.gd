extends Camera3D
## Third-person chase camera that smoothly follows behind a target car's heading.

@export var target: Node3D              ## the car to follow
@export var offset := Vector3(0, 3.2, 6) ## car-local chase offset (up Y, behind +Z)
@export var smoothing := 5.0            ## position follow rate (higher = snappier)
@export var heading_smoothing := 4.0    ## rate the trailed heading eases to the car's yaw
@export var aim_smoothing := 6.0        ## rate the look-at point eases to the car

var _yaw := 0.0                         ## damped heading the camera trails behind
var _aim := Vector3.ZERO                ## damped point the camera looks at
var _following := false                 ## seeded once the target exists


func _physics_process(delta: float) -> void:
	if target == null:
		return
	if not _following:
		# Seed from the car's current state so the first frame doesn't lurch.
		_yaw = target.rotation.y
		_aim = target.global_position
		_following = true
	# Damp the trailed heading so a sharp turn eases the camera around instead of
	# whipping it instantly behind the car.
	_yaw = lerp_angle(_yaw, target.rotation.y, clampf(heading_smoothing * delta, 0.0, 1.0))
	var desired := target.global_position + Basis(Vector3.UP, _yaw) * offset
	global_position = global_position.lerp(desired, clampf(smoothing * delta, 0.0, 1.0))
	# Damp the look-at point so bobbing over dune crests doesn't jerk the pitch.
	_aim = _aim.lerp(target.global_position, clampf(aim_smoothing * delta, 0.0, 1.0))
	look_at(_aim, Vector3.UP)
