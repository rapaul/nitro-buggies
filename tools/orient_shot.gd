extends SceneTree
## Verify in-game car orientation: build each car through Car.tscn (so car.gd's
## mesh swap + facing correction runs), view from the game camera angle, and draw
## a red arrow in the actual travel direction (-Z, the car's forward). After the
## fix every car's nose should sit along its arrow. Run:
##   godot --rendering-driver opengl3 -s tools/orient_shot.gd -- --shot=/tmp/orient.png

const MODELS := [
	"res://assets/cars/race.glb",
	"res://assets/cars/sedan.glb",
	"res://assets/cars/truck.glb",
]

func _initialize() -> void:
	var root := get_root()
	var world := Node3D.new()
	root.add_child(world)

	var car_scene: PackedScene = load("res://scenes/Car.tscn")
	var sel := root.get_node_or_null("Selection")

	var x := -4.0
	for path in MODELS:
		sel.selected_model_path = path  # each Car reads this in its _ready
		var car := car_scene.instantiate()
		car.position = Vector3(x, 0, 0)
		world.add_child(car)

		# Red arrow toward -Z = the direction this car travels under throttle.
		var arrow := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.12, 0.12, 2.2)
		arrow.mesh = box
		var am := StandardMaterial3D.new()
		am.albedo_color = Color(1, 0, 0)
		am.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		arrow.material_override = am
		arrow.position = Vector3(x, 0.6, -1.8)
		world.add_child(arrow)
		x += 4.0

	# Game camera angle (Main.tscn / camera.gd: high, behind at +Z, looking down).
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.look_at_from_position(Vector3(0, 6, 7), Vector3(0, 0.3, -0.5), Vector3.UP)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-60, -25, 0)
	world.add_child(light)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.3, 0.3, 0.3)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.5)
	env.ambient_light_energy = 0.5
	cam.environment = env

	var path := "/tmp/orient.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			path = a.substr("--shot=".length())
	_shot(root, path)

func _shot(root, path: String) -> void:
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	var img: Image = root.get_texture().get_image()
	img.save_png(path)
	print("saved ", path, "  (each red arrow = -Z travel direction; nose should lead)")
	quit()
