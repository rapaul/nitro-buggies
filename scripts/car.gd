class_name Car
extends CharacterBody3D
## Arcade car handling for the top-down prototype.
##
## Reads device-agnostic InputMap actions (never raw device codes) and
## integrates all motion in _physics_process for frame-rate independence.

# --- Pickups / combat ---
## The item a car can be holding. NONE means empty (nothing to use).
enum Item { NONE, NITRO, FIREBALL }

signal held_item_changed(item: int)  ## fires whenever the held item changes
signal health_changed(health: int)   ## fires whenever the health bar count changes
signal eliminated                     ## fires once when health reaches zero
signal fired_fireball(origin: Vector3, heading: Vector3)  ## main.gd spawns the projectile

const MAX_HEALTH := 3
const NITRO_DURATION := 5.0   ## seconds a nitro boost lasts
const NITRO_MULTIPLIER := 2.0 ## top-speed/acceleration factor while boosting
const FIREBALL_SPAWN_AHEAD := 2.5  ## metres ahead of the body to spawn a fireball (clears the nose)

var held_item := Item.NONE
var health := MAX_HEALTH
var _nitro_time := 0.0   ## seconds of nitro boost remaining

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

# --- Sand spray (visual only) ---
@export var spray_speed_floor := 3.5    ## m/s below which driving raises no spray
@export var spray_drift_threshold := 2.0 ## lateral m/s that triggers spray even when slow
@export var spray_drift_ref := 8.0      ## lateral m/s that counts as a full-intensity drift

# --- Vertical / airborne tuning ---
@export var gravity := 22.0             ## m/s^2 downward pull
@export var snap_length := 0.5          ## floor-snap distance that hugs slopes
@export var launch_min_speed := 14.0    ## horizontal speed above which cresting launches the car
@export var launch_lift := 0.45         ## fraction of horizontal speed converted to lift at the crest

# --- Body / wheel orientation (visual only; physics body stays yaw-only) ---
@export var tilt_smoothing := 8.0       ## how fast the mesh eases to the terrain slope while grounded
@export var air_righting := 2.5         ## airborne self-righting strength (grows over the flight)

# --- Controls ---
## Prefix prepended to the InputMap action names this car reads. Empty for
## Player 1 (the existing accelerate/brake/steer_left/steer_right/handbrake
## actions); "p2_" for Player 2's arrow-key set in split-screen.
@export var input_prefix := ""

## Vehicle model to render. Empty means use the landing-screen selection
## (Selection.selected_model_path) — the default and single-player path. Set
## per-car (e.g. Player 2's pick) before the node enters the tree to override it.
@export var model_path := ""

var _prev_climb := false                ## was the car ascending a slope last tick?

# Visual mesh orientation state. The CharacterBody3D rotates on Y only; the mesh
# child is tilted to approximate the terrain slope, retains some angular momentum
# in the air, and rights itself to land wheels-down. All presentation — none of
# this feeds back into the planar handling integrated below.
var _mesh: Node3D
var _mesh_scale := Vector3.ONE          ## preserved so re-setting the basis never rescales the model
var _mesh_q := Quaternion.IDENTITY      ## mesh rotation this tick
var _mesh_q_prev := Quaternion.IDENTITY ## mesh rotation last tick (for takeoff angular momentum)
var _mesh_y_offset := 0.0               ## eased local-Y drop that seats the mesh on the terrain
var _air_angvel := Vector3.ZERO         ## tumble carried into the air at takeoff
var _air_time := 0.0                    ## seconds since takeoff
var _was_airborne := false

# Sand-spray emitters, one behind each rear wheel. Children of this body (which
# only yaws), never of the visual mesh (whose basis is rewritten every tick for
# tilt/tumble), so they stay put behind the wheels through slopes and jumps.
var _spray_l: GPUParticles3D
var _spray_r: GPUParticles3D

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
	var path := model_path if model_path != "" else Selection.selected_model_path
	var packed: PackedScene = load(path)
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
	_setup_spray()


func respawn(pos: Vector3) -> void:
	# Return the car to a safe spawn point (see main.gd's fall-off-edge handling).
	# Clear velocity so it doesn't keep the fall's momentum, and reset the airborne
	# bookkeeping so it doesn't land carrying a stale takeoff tumble.
	global_position = pos
	velocity = Vector3.ZERO
	_was_airborne = false
	_air_time = 0.0
	_air_angvel = Vector3.ZERO


# --- Pickups / combat ---

func collect(item: int) -> bool:
	# Grant a pickup only if the car isn't already holding one (no replacement).
	# Returns whether the item was taken, so the pickup knows to disappear.
	if held_item != Item.NONE:
		return false
	held_item = item
	held_item_changed.emit(held_item)
	return true


func take_damage(amount: int) -> void:
	# Remove health bars (clamped at zero). Reaching zero eliminates the car once.
	if health <= 0:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health)
	if health == 0:
		eliminated.emit()


func use_item() -> void:
	# Activate the held pickup and clear it (the box goes empty). No-op when empty.
	if held_item == Item.NONE:
		return
	var item := held_item
	held_item = Item.NONE
	held_item_changed.emit(held_item)
	match item:
		Item.NITRO:
			_nitro_time = NITRO_DURATION
		Item.FIREBALL:
			# main.gd owns the shared world, so it spawns the projectile there (so
			# the fireball can hit the other car). Launch from just ahead of the nose.
			var heading := -global_transform.basis.z
			heading.y = 0.0
			heading = heading.normalized()
			fired_fireball.emit(global_position + heading * FIREBALL_SPAWN_AHEAD, heading)


func _unhandled_input(event: InputEvent) -> void:
	# Per-player use action (input_prefix keeps Player 1 / Player 2 independent).
	if event.is_action_pressed(input_prefix + "use_item"):
		use_item()


func _physics_process(delta: float) -> void:
	# Tick down any active nitro boost regardless of grounded/airborne state.
	if _nitro_time > 0.0:
		_nitro_time = maxf(_nitro_time - delta, 0.0)

	if not is_on_floor():
		# Airborne: pure ballistic arc. Throttle, steering, and grip are all
		# ignored — horizontal velocity is frozen and only gravity acts. Re-grounds
		# automatically via is_on_floor() on landing.
		velocity.y -= gravity * delta
		floor_snap_length = 0.0
		_set_spray(false)  # no wheels on sand
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
		_set_spray(false)  # leaving the ground
		move_and_slide()
		_update_orientation(delta)
		return
	_prev_climb = climbing

	# Device-agnostic analog input. Keyboard keys report full magnitude,
	# gamepad axes report proportional magnitude — both for free via get_axis.
	var throttle := Input.get_axis(input_prefix + "brake", input_prefix + "accelerate")
	var steer_input := Input.get_axis(input_prefix + "steer_left", input_prefix + "steer_right")
	var handbraking := Input.is_action_pressed(input_prefix + "handbrake")

	var forward := -global_transform.basis.z
	var forward_speed := velocity.dot(forward)

	# Nitro: while active, the forward cap and forward acceleration are doubled so
	# the car can both reach and hold the higher top speed. Reverse is unaffected.
	var boost := NITRO_MULTIPLIER if _nitro_time > 0.0 else 1.0

	# --- Longitudinal: accelerate / coast / brake / reverse ---
	if throttle > 0.0:
		forward_speed += acceleration * boost * throttle * delta
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

	forward_speed = clampf(forward_speed, -max_reverse_speed, max_forward_speed * boost)

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

	# Grounded sand spray: emit while driving fast enough or sliding sideways.
	# Intensity follows the harder of the two (max, not sum) so a hard drift fans
	# out without a straight-line blowout when both are high.
	var spray_speed := Vector2(velocity.x, velocity.z).length()
	var sliding := absf(lateral_speed) > spray_drift_threshold
	var active := spray_speed > spray_speed_floor or sliding
	var intensity := maxf(spray_speed / max_forward_speed, absf(lateral_speed) / spray_drift_ref)
	_set_spray(active, intensity)

	_update_orientation(delta)


func _update_orientation(delta: float) -> void:
	# Orient the visual mesh. Grounded: ease toward the terrain slope. Airborne:
	# carry the takeoff tumble but right toward wheels-down so it always lands flat.
	if _mesh == null:
		return
	# Read the air->ground transition before the rotation block resets it, so the
	# vertical grounding offset can firm-seat on the landing tick the same way the
	# rotation does (rather than easing through a transient gap).
	var landing := is_on_floor() and _was_airborne
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

	# Seat the mesh on the sand. The flat box collision rests on its uphill edge on
	# a slope, propping the body (and this mesh) up to ~0.4 m above the surface
	# beneath the car, so it floats off its shadow. Sample the surface from the same
	# DuneHeight source the terrain and collision use and drop the mesh's local Y so
	# its base meets the ground. Visual only — the physics body keeps yaw-only,
	# floor-snapped handling. Grounded only; airborne the offset eases back to 0 so
	# the mesh rides the body's ballistic height, then firm-seats on landing.
	var off_target := 0.0
	if is_on_floor():
		off_target = DuneHeight.height(global_position.x, global_position.z) - global_position.y
	if landing:
		_mesh_y_offset = off_target
	else:
		_mesh_y_offset = lerpf(_mesh_y_offset, off_target, clampf(tilt_smoothing * delta, 0.0, 1.0))
	_mesh.position.y = _mesh_y_offset


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


func _setup_spray() -> void:
	# Place two emitters at the rear wheels, derived from the loaded model's AABB
	# (sizes differ across the kit and the model is swapped per selection, so this
	# can't be a per-model constant). Forward is -Z, so the rear is +Z; wheels sit
	# inboard of the bounding-box edges and near the ground (AABB min Y).
	var aabb := _mesh_aabb()
	var center := aabb.position + aabb.size * 0.5
	var wheel_x := aabb.size.x * 0.35
	var rear_z := center.z + aabb.size.z * 0.35
	var ground_y := aabb.position.y + 0.05
	_spray_l = _make_emitter()
	_spray_r = _make_emitter()
	_spray_l.position = Vector3(center.x - wheel_x, ground_y, rear_z)
	_spray_r.position = Vector3(center.x + wheel_x, ground_y, rear_z)
	add_child(_spray_l)
	add_child(_spray_r)


func _mesh_aabb() -> AABB:
	# Combined AABB of the model's meshes, expressed in this body's local space.
	var out := AABB()
	var first := true
	for node in _find_meshes(_mesh):
		var mi: MeshInstance3D = node
		var local_xform: Transform3D = global_transform.affine_inverse() * mi.global_transform
		var box: AABB = local_xform * mi.get_aabb()
		if first:
			out = box
			first = false
		else:
			out = out.merge(box)
	return out


func _find_meshes(n: Node, acc: Array = []) -> Array:
	if n is MeshInstance3D:
		acc.append(n)
	for c in n.get_children():
		_find_meshes(c, acc)
	return acc


func _make_emitter() -> GPUParticles3D:
	# A short-lived burst of sand grains thrown backward and up. Built entirely in
	# code: process material + draw pass, no editor resources.
	var p := GPUParticles3D.new()
	p.amount = 192
	p.lifetime = 0.18  # short life keeps the trail tight behind the wheels
	p.local_coords = false  # leave grains in world space so the trail lags behind
	p.emitting = false

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	# Long along the travel axis (+Z, rearward): at full speed the emitter jumps
	# ~0.37 m/frame, so a point emitter leaves gaps between per-frame batches. A
	# streak longer than that gap makes consecutive frames overlap into a
	# continuous plume without needing a longer (and thus longer-tailed) lifetime.
	mat.emission_box_extents = Vector3(0.1, 0.04, 0.3)
	# Direction is in the emitter's frame (it inherits the body's yaw): +Z is
	# rearward, +Y up, so the spray always fans out behind the car.
	mat.direction = Vector3(0.0, 0.6, 1.0)
	mat.spread = 25.0
	mat.initial_velocity_min = 2.5
	mat.initial_velocity_max = 4.5
	mat.gravity = Vector3(0.0, -9.8, 0.0)
	mat.damping_min = 1.0
	mat.damping_max = 2.0
	mat.scale_min = 0.3
	mat.scale_max = 0.8
	mat.angle_min = -180.0
	mat.angle_max = 180.0
	# Warm sand that fades to nothing over the grain's life.
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.85, 0.72, 0.48, 0.9))
	ramp.set_color(1, Color(0.80, 0.66, 0.42, 0.0))
	var ramp_tex := GradientTexture1D.new()
	ramp_tex.gradient = ramp
	mat.color_ramp = ramp_tex
	p.process_material = mat

	var quad := QuadMesh.new()
	quad.size = Vector2(0.12, 0.12)
	var qmat := StandardMaterial3D.new()
	qmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qmat.billboard_keep_scale = true  # without this, billboarding discards scale_min/max
	# A soft round grain, not a hard square: a radial alpha falloff sprite.
	qmat.albedo_texture = _grain_texture()
	qmat.vertex_color_use_as_albedo = true  # let the per-particle ramp tint/fade it
	quad.material = qmat
	p.draw_pass_1 = quad
	return p


func _grain_texture() -> ImageTexture:
	# Small white sprite with a soft radial alpha falloff, so each particle reads
	# as a soft round grain of sand rather than a flat square.
	var n := 32
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := (n - 1) * 0.5
	for y in n:
		for x in n:
			var d := Vector2(x - c, y - c).length() / c
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a * a))
	return ImageTexture.create_from_image(img)


func _set_spray(active: bool, intensity: float = 0.0) -> void:
	if _spray_l == null:
		return
	_spray_l.emitting = active
	_spray_r.emitting = active
	if active:
		var r := clampf(intensity, 0.2, 1.0)
		_spray_l.amount_ratio = r
		_spray_r.amount_ratio = r
