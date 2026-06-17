extends Camera3D
## Third-person chase camera that smoothly follows behind a target car's heading.

@export var target: Node3D              ## the car to follow
@export var offset := Vector3(0, 3.2, 6) ## car-local chase offset (up Y, behind +Z)
@export var smoothing := 5.0            ## higher = snappier follow, lower = looser


func _physics_process(delta: float) -> void:
	if target == null:
		return
	# Rotate the offset by the car's yaw only, so the camera stays behind the
	# car's heading while remaining level even if the car ever pitches/rolls.
	var desired := target.global_position + Basis(Vector3.UP, target.rotation.y) * offset
	global_position = global_position.lerp(desired, clampf(smoothing * delta, 0.0, 1.0))
	look_at(target.global_position, Vector3.UP)
