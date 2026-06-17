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

# --- Vertical / airborne tuning ---
@export var gravity := 22.0             ## m/s^2 downward pull
@export var snap_length := 0.5          ## floor-snap distance that hugs slopes
@export var launch_min_speed := 14.0    ## horizontal speed above which cresting launches the car
@export var launch_lift := 0.45         ## fraction of horizontal speed converted to lift at the crest

# --- Body / wheel orientation (visual only; physics body stays yaw-only) ---
@export var tilt_smoothing := 8.0       ## how fast the mesh eases to the terrain slope while grounded
@export var air_righting := 2.5         ## airborne self-righting strength (grows over the flight)

var _prev_climb := false                ## was the car ascending a slope last tick?

# Visual mesh orientation state. The CharacterBody3D rotates on Y only; the mesh
# child is tilted to approximate the terrain slope, retains some angular momentum
# in the air, and rights itself to land wheels-down. All presentation — none of
# this feeds back into the planar handling integrated below.
var _mesh: Node3D
var _mesh_scale := Vector3.ONE          ## preserved so re-setting the basis never rescales the model
var _mesh_q := Quaternion.IDENTITY      ## mesh rotation this tick
var _mesh_q_prev := Quaternion.IDENTITY ## mesh rotation last tick (for takeoff angular momentum)
var _air_angvel := Vector3.ZERO         ## tumble carried into the air at takeoff
var _air_time := 0.0                    ## seconds since takeoff
var _was_airborne := false

const FALLBACK_MODEL := "res://assets/race.glb"


func _ready() -> void:
	# Dune terrain has slopes, so configure floor handling: keep "up" world-up,
	# and treat fairly steep dune faces as drivable floor rather than walls.
	up_direction = Vector3.UP
	floor_max_angle = deg_to_rad(55.0)
	floor_snap_length = snap_length
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
	# The Kenney car-kit models are authored facing +Z, but the car's forward is
	# -Z (see _physics_process). Without this the car drives tail-first. Flip the
	# visual mesh 180° so its nose points along the direction of travel.
	mesh.rotate_y(PI)
	add_child(mesh)
	CarSkin.apply(mesh)
	# Track the mesh so _physics_process can tilt it to the terrain. Capture its
	# scale and starting rotation (the rotate_y(PI) flip above) as the baseline.
	_mesh = mesh
	_mesh_scale = _mesh.transform.basis.get_scale()
	_mesh_q = _mesh.transform.basis.get_rotation_quaternion()
	_mesh_q_prev = _mesh_q


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		# Airborne: pure ballistic arc. Throttle, steering, and grip are all
		# ignored — horizontal velocity is frozen and only gravity acts. Re-grounds
		# automatically via is_on_floor() on landing.
		velocity.y -= gravity * delta
		floor_snap_length = 0.0
		move_and_slide()
		_update_orientation(delta)
		return

	# Crest launch: floor snapping keeps the car glued to even the steepest dune
	# face, so a jump has to be triggered explicitly. The floor normal tilts back
	# while climbing (dot with forward < 0) and forward once over the crest; the
	# sign flip at speed is the crest. Convert forward momentum into lift and break
	# contact so the car arcs off. Speed-gated: a slow crossing just rolls over.
	# Threshold ~8.5deg of back-tilt: enough to ignore the minor contact wobble from
	# the car's width straddling gentle valley flanks, but well below a real dune face.
	var heading := -global_transform.basis.z
	var climbing := get_floor_normal().dot(heading) < -0.15
	var hspeed := Vector2(velocity.x, velocity.z).length()
	if _prev_climb and not climbing and hspeed > launch_min_speed:
		velocity.y = hspeed * launch_lift
		floor_snap_length = 0.0
		_prev_climb = false
		move_and_slide()
		_update_orientation(delta)
		return
	_prev_climb = climbing

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

	# Drive in the horizontal plane; leave Y to the floor/slope handling. Gravity
	# is applied only while airborne (above). Floor snapping (length = snap_length)
	# keeps the car hugging dune faces up and down at ordinary speed; a fast crest
	# crossing moves further than snap can reach, so the car breaks contact and the
	# takeoff boost above launches it.
	var planar := forward * forward_speed + right * lateral_speed
	velocity.x = planar.x
	velocity.z = planar.z
	floor_snap_length = snap_length
	move_and_slide()
	_update_orientation(delta)


func _update_orientation(delta: float) -> void:
	# Orient the visual mesh. Grounded: ease toward the terrain slope. Airborne:
	# carry the takeoff tumble but right toward wheels-down so it always lands flat.
	if _mesh == null:
		return
	var q: Quaternion
	if is_on_floor():
		var target := _ground_target_local().get_rotation_quaternion()
		if _was_airborne:
			# Landing tick: firm-align to the surface so the car is on its wheels
			# however it was tumbling, then resume eased slope-following.
			q = target
		else:
			q = _mesh_q.slerp(target, clampf(tilt_smoothing * delta, 0.0, 1.0))
		_was_airborne = false
		_air_time = 0.0
	else:
		if not _was_airborne:
			# Just took off: keep the rate the mesh was tilting as angular momentum.
			_air_angvel = _angvel_between(_mesh_q_prev, _mesh_q, delta)
			_was_airborne = true
			_air_time = 0.0
		_air_time += delta
		q = _mesh_q
		var ang := _air_angvel.length() * delta
		if ang > 1e-6:
			q = Quaternion(_air_angvel.normalized(), ang) * q
		# Right toward level (wheels-down = the rotate_y(PI) flip), more firmly the
		# longer it has been airborne, so even long jumps land flat.
		var strength := clampf(air_righting * (0.5 + _air_time) * delta, 0.0, 1.0)
		q = q.slerp(Quaternion(Vector3.UP, PI), strength)
	_set_mesh_rotation(q)
	_mesh_q_prev = _mesh_q
	_mesh_q = q


func _ground_target_local() -> Basis:
	# World target: up = surface normal, nose (+Z; the model faces +Z) along the
	# car's heading projected onto the slope. Returned in the body's local space
	# so easing affects pitch/roll while yaw still tracks the body instantly.
	var n := get_floor_normal()
	if n.length_squared() < 0.01:
		n = Vector3.UP
	var fwd := -global_transform.basis.z
	var f := fwd - n * fwd.dot(n)
	if f.length_squared() < 1e-6:
		f = fwd
	f = f.normalized()
	var x := n.cross(f).normalized()
	var world_basis := Basis(x, n, x.cross(n))
	return global_transform.basis.inverse() * world_basis


func _angvel_between(prev_q: Quaternion, cur_q: Quaternion, delta: float) -> Vector3:
	# Angular velocity (axis * rad/s) of the rotation from prev_q to cur_q.
	if delta <= 0.0:
		return Vector3.ZERO
	var dq := cur_q * prev_q.inverse()
	if dq.w < 0.0:
		dq = Quaternion(-dq.x, -dq.y, -dq.z, -dq.w)  # shortest arc
	dq = dq.normalized()
	var s := sqrt(maxf(0.0, 1.0 - dq.w * dq.w))
	if s < 1e-5:
		return Vector3.ZERO
	var axis := Vector3(dq.x, dq.y, dq.z) / s
	return axis * (2.0 * acos(clampf(dq.w, -1.0, 1.0)) / delta)


func _set_mesh_rotation(q: Quaternion) -> void:
	_mesh.transform.basis = Basis(q).scaled(_mesh_scale)
