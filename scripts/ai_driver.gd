extends Node
## A basic computer driver for a single AI opponent car in single-player. Each
## physics tick it decides the car's controls and writes them onto the car's
## ai_throttle/ai_steer fields (the car must have ai_controlled = true). It never
## reads the InputMap, so it cannot be moved by the player's keys.
##
## Behaviour, in priority order:
##   1. Holding no item   -> drive straight at the nearest available pickup.
##   2. Holding an item   -> hunt the player, weaving so it never drives straight
##                           for more than WEAVE_PERIOD seconds. A nitro is used
##                           at once (freeing it to seek again); a fireball is
##                           aimed and fired, with a 50% chance of being aimed
##                           wide so it misses.

## Misalignment (rad) at which the steer-toward-target term saturates to full.
const STEER_ANGLE_REF := deg_to_rad(35.0)
## Seconds between weave reversals — below 0.5 s so the car is never straight that long.
const WEAVE_PERIOD := 0.4
## Weave magnitude. Dominant over the (capped) approach term so the applied steer
## sign always follows the weave and therefore reverses every WEAVE_PERIOD.
const WEAVE_STRENGTH := 0.7
## The approach-the-player steer is capped this small so the weave stays dominant.
const HUNT_APPROACH_CAP := 0.4
## Fire the fireball once the heading is within this of the aim point.
const FIRE_AIM_TOLERANCE := deg_to_rad(8.0)
## Lateral distance a "miss" aims to the side of the player.
const MISS_OFFSET := 12.0

var car: Car = null
var player: Car = null
var pickups: Array = []          ## the world's pickup Area3D nodes (visible == available)
var active := true               ## main clears this when the match is over

var rng := RandomNumberGenerator.new()

var _weave_dir := 1.0
var _weave_timer := WEAVE_PERIOD
var _fireball_decided := false   ## has the hit/miss for the held fireball been rolled?
var _fireball_will_miss := false


func _physics_process(delta: float) -> void:
	if not active or car == null or not is_instance_valid(car):
		return

	# Weave clock runs continuously; it only feeds the steer in the hunt phase.
	_weave_timer -= delta
	if _weave_timer <= 0.0:
		_weave_dir = -_weave_dir
		_weave_timer = WEAVE_PERIOD

	if car.held_item == Car.Item.NONE:
		_seek_pickup()
	else:
		_hunt_player()


func _seek_pickup() -> void:
	# Drive straight at the nearest available pickup (no weave — it needs to arrive).
	_fireball_decided = false
	car.ai_throttle = 1.0
	var target = _nearest_pickup_pos()
	car.ai_steer = _steer_toward(target) if target != null else 0.0


func _hunt_player() -> void:
	if player == null or not is_instance_valid(player):
		car.ai_throttle = 1.0
		car.ai_steer = WEAVE_STRENGTH * _weave_dir
		return

	# Use a held nitro immediately, then resume seeking the next pickup next tick.
	if car.held_item == Car.Item.NITRO:
		car.use_item()
		return

	# Fireball: commit to hit-or-miss once, then aim accordingly and fire when lined up.
	if not _fireball_decided:
		_fireball_will_miss = rng.randf() < 0.5
		_fireball_decided = true
	var aim := _fireball_aim_point()
	var approach := clampf(_steer_toward(aim), -HUNT_APPROACH_CAP, HUNT_APPROACH_CAP)
	car.ai_throttle = 1.0
	car.ai_steer = clampf(approach + WEAVE_STRENGTH * _weave_dir, -1.0, 1.0)
	if _aim_error(aim) < FIRE_AIM_TOLERANCE:
		car.use_item()      # launches along the car's heading -> hits or flies wide
		_fireball_decided = false


# --- Geometry helpers (all in the horizontal plane) ---

func _steer_toward(target) -> float:
	# Signed steer in [-1, 1] toward a world point: magnitude from the heading
	# error, sign positive = the target is to the car's right (matches the car's
	# get_axis(steer_left, steer_right) convention).
	if target == null:
		return 0.0
	var f := -car.global_transform.basis.z
	f.y = 0.0
	var to: Vector3 = target - car.global_position
	to.y = 0.0
	if f.length_squared() < 1e-6 or to.length_squared() < 1e-6:
		return 0.0
	f = f.normalized()
	to = to.normalized()
	var ang := acos(clampf(f.dot(to), -1.0, 1.0))
	var side := signf(to.dot(car.global_transform.basis.x))
	return clampf(ang / STEER_ANGLE_REF, 0.0, 1.0) * side


func _aim_error(target: Vector3) -> float:
	# Unsigned angle (rad) between the car's heading and the direction to target.
	var f := -car.global_transform.basis.z
	f.y = 0.0
	var to: Vector3 = target - car.global_position
	to.y = 0.0
	if f.length_squared() < 1e-6 or to.length_squared() < 1e-6:
		return 0.0
	return acos(clampf(f.normalized().dot(to.normalized()), -1.0, 1.0))


func _fireball_aim_point() -> Vector3:
	var p := player.global_position
	if not _fireball_will_miss:
		return p
	# Aim to the side, perpendicular to the line of sight, so the shot flies wide.
	var los: Vector3 = p - car.global_position
	los.y = 0.0
	if los.length_squared() < 1e-6:
		return p
	los = los.normalized()
	var perp := Vector3(-los.z, 0.0, los.x)  # horizontal perpendicular
	return p + perp * MISS_OFFSET


func _nearest_pickup_pos():
	# World position of the closest currently-available pickup, or null if none.
	var best = null
	var best_d := INF
	for pk in pickups:
		if not is_instance_valid(pk) or not pk.visible:
			continue
		var d: float = car.global_position.distance_squared_to(pk.global_position)
		if d < best_d:
			best_d = d
			best = pk.global_position
	return best
