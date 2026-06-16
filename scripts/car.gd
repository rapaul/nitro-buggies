extends CharacterBody3D
## Arcade car handling for the top-down prototype.
##
## Reads device-agnostic InputMap actions (never raw device codes) and
## integrates all motion in _physics_process for frame-rate independence.

# --- Longitudinal tuning ---
@export var max_forward_speed := 22.0   ## m/s cap when driving forward
@export var max_reverse_speed := 7.0    ## m/s cap in reverse (below forward cap)
@export var acceleration := 18.0        ## m/s^2 from full throttle
@export var brake_strength := 32.0      ## m/s^2 when braking while moving forward
@export var engine_drag := 6.0          ## m/s^2 coast-down when no throttle

# --- Steering tuning ---
@export var max_steer_rate := 2.2       ## rad/s turn rate at full steering effectiveness
@export var steer_speed_ref := 7.0      ## speed (m/s) at which steering is fully effective

# --- Grip / drift tuning ---
@export var grip := 9.0                 ## lateral grip rate (higher = tracks heading)
@export var handbrake_grip := 1.5       ## reduced grip while handbraking (produces drift)

const FALLBACK_MODEL := "res://assets/race.glb"


func _ready() -> void:
	# Swap the visual mesh to the vehicle chosen on the landing screen. The
	# collision shape is intentionally left as-is for v1. Falls back to the
	# default model if the selected one fails to load.
	var packed: PackedScene = load(Selection.selected_model_path)
	if packed == null:
		packed = load(FALLBACK_MODEL)
	if packed == null:
		return
	var old := get_node_or_null("Mesh")
	if old:
		remove_child(old)
		old.queue_free()
	var mesh := packed.instantiate()
	mesh.name = "Mesh"
	add_child(mesh)


func _physics_process(delta: float) -> void:
	# Device-agnostic analog input. Keyboard keys report full magnitude,
	# gamepad axes report proportional magnitude — both for free via get_axis.
	var throttle := Input.get_axis("brake", "accelerate")
	var steer_input := Input.get_axis("steer_left", "steer_right")
	var handbraking := Input.is_action_pressed("handbrake")

	var forward := -global_transform.basis.z
	var forward_speed := velocity.dot(forward)

	# --- Longitudinal: accelerate / coast / brake / reverse ---
	if throttle > 0.0:
		forward_speed += acceleration * throttle * delta
	elif throttle < 0.0:
		if forward_speed > 0.1:
			# Brake: scale with how hard the brake is applied (throttle is negative).
			forward_speed += brake_strength * throttle * delta
		else:
			# Reverse once effectively stopped.
			forward_speed += acceleration * throttle * delta
	else:
		# No input: engine drag pulls speed toward zero.
		forward_speed = move_toward(forward_speed, 0.0, engine_drag * delta)

	forward_speed = clampf(forward_speed, -max_reverse_speed, max_forward_speed)

	# --- Steering: effectiveness scales with speed, so no pivot at standstill ---
	var speed_factor := clampf(absf(forward_speed) / steer_speed_ref, 0.0, 1.0)
	var turn := -steer_input * max_steer_rate * speed_factor * delta
	if forward_speed < 0.0:
		# Steer naturally while reversing.
		turn = -turn
	rotate_y(turn)

	# --- Grip / drift: split velocity into forward and lateral, bleed off slide ---
	forward = -global_transform.basis.z
	var right := global_transform.basis.x
	var lateral_speed := velocity.dot(right)

	var current_grip := handbrake_grip if handbraking else grip
	lateral_speed = lerpf(lateral_speed, 0.0, clampf(current_grip * delta, 0.0, 1.0))

	velocity = forward * forward_speed + right * lateral_speed
	move_and_slide()
