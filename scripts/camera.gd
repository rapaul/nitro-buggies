extends Camera3D
## High-angle top-down camera that smoothly follows a target car.

@export var target: Node3D              ## the car to follow
@export var offset := Vector3(0, 18, 11) ## high-angle position offset from the target
@export var smoothing := 5.0            ## higher = snappier follow, lower = looser


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var desired := target.global_position + offset
	global_position = global_position.lerp(desired, clampf(smoothing * delta, 0.0, 1.0))
	look_at(target.global_position, Vector3.UP)
