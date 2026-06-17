extends SceneTree
## Drives the car up a dune face at moderate throttle and captures it while
## grounded and tilted to the slope, to confirm the mesh sits on the terrain
## angle with the chase camera trailing steadily.
## Output path via --shot=<path>. Run:
##   godot --rendering-driver opengl3 -s tools/tilt_shot.gd -- --shot=/tmp/tilt.png

const Dune := preload("res://scripts/dune_height.gd")

var _path := "/tmp/tilt.png"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_path = arg.substr(7)
	var scene: Node3D = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(scene)
	_capture.call_deferred()


func _capture() -> void:
	var car: CharacterBody3D = get_root().get_node("Main/Car")
	car.global_transform = Transform3D(Basis(), Vector3(10, Dune.height(10, 26) + 0.2, 26))
	car.velocity = Vector3.ZERO
	Input.action_press("accelerate", 0.5)
	# Climb the face and stop mid-slope (still grounded, clearly tilted) before
	# the crest where the surface levels back out.
	var mesh: Node3D = car.get_node("Mesh")
	for i in 120:
		await physics_frame
		var tilt := mesh.global_transform.basis.y.normalized().angle_to(Vector3.UP)
		if car.is_on_floor() and tilt > 0.35 and car.global_position.z < 18.0:
			break
	for i in 4:
		await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png(_path)
	var tilt := mesh.global_transform.basis.y.normalized().angle_to(Vector3.UP)
	print("saved ", _path, "  on_floor=%s mesh_tilt=%.3f rad z=%.1f" % [car.is_on_floor(), tilt, car.global_position.z])
	quit(0)
