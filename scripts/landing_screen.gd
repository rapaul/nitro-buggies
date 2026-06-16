extends Control
## Title/landing screen shown before gameplay. The "Nitro Buggies" title is a
## sandy-yellow face over a sandy-orange block shadow, built in code so no .tscn
## NodePath exports are relied on. Below the title sits a vehicle picker: three
## random, distinct car-kit models rotating in their own little 3D previews. The
## leftmost starts selected (chunky square around it); left/right moves the
## selection. Pressing accept records the chosen vehicle and starts the game.

const MAIN_SCENE := "res://scenes/Main.tscn"

const SANDY_YELLOW := Color("e8c76a")  # title face
const SANDY_ORANGE := Color("c8761e")  # block shadow

const TITLE_FONT := "res://assets/fonts/Kenney Blocks.ttf"
const TITLE_SIZE := 96
const TITLE_SPACING := 4
const SHADOW_OFFSET := Vector2(12, 12)  # lower-right block shadow

const MARGIN_TOP := 56.0
const MARGIN_X := 72.0

# --- Vehicle picker ---

## Drivable vehicle models from the Kenney car kit (props/debris/wheels excluded).
const VEHICLE_MODELS: Array[String] = [
	"res://assets/cars/ambulance.glb",
	"res://assets/cars/delivery.glb",
	"res://assets/cars/delivery-flat.glb",
	"res://assets/cars/firetruck.glb",
	"res://assets/cars/garbage-truck.glb",
	"res://assets/cars/hatchback-sports.glb",
	"res://assets/cars/kart-oobi.glb",
	"res://assets/cars/kart-oodi.glb",
	"res://assets/cars/kart-ooli.glb",
	"res://assets/cars/kart-oopi.glb",
	"res://assets/cars/kart-oozi.glb",
	"res://assets/cars/police.glb",
	"res://assets/cars/race-future.glb",
	"res://assets/cars/race.glb",
	"res://assets/cars/sedan.glb",
	"res://assets/cars/sedan-sports.glb",
	"res://assets/cars/suv.glb",
	"res://assets/cars/suv-luxury.glb",
	"res://assets/cars/taxi.glb",
	"res://assets/cars/tractor.glb",
	"res://assets/cars/tractor-police.glb",
	"res://assets/cars/tractor-shovel.glb",
	"res://assets/cars/truck.glb",
	"res://assets/cars/truck-flat.glb",
	"res://assets/cars/van.glb",
]

const PREVIEW_COUNT := 3

## Square preview side, as a fraction of viewport height.
const CELL_FRAC := 0.42
## Fraction of the cell that each vehicle's bounding sphere fills. The sphere is
## rotation-invariant, so framing by it keeps the whole car inside the square at
## every angle; 0.8 leaves a margin inside the chunky border. With CELL_FRAC the
## car reads at roughly one third of the viewport height.
const FILL := 0.9
## Camera pitch below horizontal. Low/near-horizontal so the car is seen upright
## with its underside toward the bottom of the screen (not top-down).
const CAM_PITCH_DEG := 12.0
## The car is tilted so its back rides up by this angle, for a dynamic stance.
const BACK_TILT_DEG := 15.0
## Seconds for one full revolution.
const ROT_PERIOD := 3.0
## Where the shared ground line sits, as a fraction of the cell below its centre.
const GROUND_OFFSET := 0.18

## Chunky selection border.
const HIGHLIGHT_BORDER := 8
const HIGHLIGHT_COLOR := Color("e8c76a")  # sandy yellow, matching the title

var _models: Array[Node3D] = []          # rotating spinner nodes, left to right
var _cameras: Array[Camera3D] = []       # one per preview, framed together
var _cell_rects: Array[Rect2] = []       # on-screen rect of each preview cell
var _picked: Array[String] = []          # chosen model paths, left to right
var _selected := 0                       # index of the highlighted preview
var _highlight: Panel


func _ready() -> void:
	_build_title()
	_build_picker()


func _process(delta: float) -> void:
	# One revolution every ROT_PERIOD seconds, frame-rate independent.
	for m in _models:
		m.rotate_y(TAU / ROT_PERIOD * delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if not _picked.is_empty():
			Selection.selected_model_path = _picked[_selected]
		get_tree().change_scene_to_file(MAIN_SCENE)
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("steer_left"):
		_move_selection(-1)
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("steer_right"):
		_move_selection(1)


func _move_selection(step: int) -> void:
	# Clamp at the ends — no wrap-around.
	var next := clampi(_selected + step, 0, _picked.size() - 1)
	if next != _selected:
		_selected = next
		_update_highlight()


func _build_title() -> void:
	# Title area: full width minus side margins, sitting in the top third.
	var area := Control.new()
	area.set_anchor(SIDE_LEFT, 0.0)
	area.set_anchor(SIDE_RIGHT, 1.0)
	area.set_anchor(SIDE_TOP, 0.0)
	area.set_anchor(SIDE_BOTTOM, 1.0 / 3.0)
	area.offset_left = MARGIN_X
	area.offset_right = -MARGIN_X
	area.offset_top = MARGIN_TOP
	area.offset_bottom = 0.0
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(area)

	# Shadow first so it draws behind the face.
	_add_title_label(area, SANDY_ORANGE, SHADOW_OFFSET)
	_add_title_label(area, SANDY_YELLOW, Vector2.ZERO)


func _add_title_label(area: Control, color: Color, pos: Vector2) -> void:
	var label := Label.new()
	label.text = "Nitro Buggies"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	# Fill the title area, then nudge by the shadow offset.
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = pos.x
	label.offset_right = pos.x
	label.offset_top = pos.y
	label.offset_bottom = pos.y

	var font := FontVariation.new()
	font.base_font = load(TITLE_FONT)
	font.spacing_glyph = TITLE_SPACING
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", TITLE_SIZE)
	label.add_theme_color_override("font_color", color)
	area.add_child(label)


func _build_picker() -> void:
	_picked = _pick_models()

	var vp := get_viewport_rect().size
	var cell := vp.y * CELL_FRAC
	# The picker occupies the bottom two-thirds (below the top-third title).
	var area_top := vp.y / 3.0
	var area_h := vp.y - area_top
	var cell_y := area_top + (area_h - cell) / 2.0
	# Equal horizontal gaps: PREVIEW_COUNT cells with a gap on each side.
	var gap := (vp.x - PREVIEW_COUNT * cell) / float(PREVIEW_COUNT + 1)

	var max_diameter := 0.0
	for i in PREVIEW_COUNT:
		var cell_x := gap + i * (cell + gap)
		var rect := Rect2(cell_x, cell_y, cell, cell)
		_cell_rects.append(rect)
		max_diameter = maxf(max_diameter, _build_preview(_picked[i], rect))

	# Frame every preview with the same scale (driven by the largest of the trio)
	# so the shared ground line — each model's bottom, parked at the world origin —
	# lands at the same screen height in every cell.
	var ortho := max_diameter / FILL
	var look_y := ortho * GROUND_OFFSET
	var pitch := deg_to_rad(CAM_PITCH_DEG)
	var dist := 10.0
	for cam in _cameras:
		cam.size = ortho
		cam.position = Vector3(0.0, look_y + sin(pitch) * dist, cos(pitch) * dist)
		cam.rotation = Vector3(-pitch, 0.0, 0.0)

	_highlight = Panel.new()
	_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)  # transparent fill — just a chunky frame
	style.set_border_width_all(HIGHLIGHT_BORDER)
	style.border_color = HIGHLIGHT_COLOR
	_highlight.add_theme_stylebox_override("panel", style)
	add_child(_highlight)
	_update_highlight()


func _pick_models() -> Array[String]:
	var pool := VEHICLE_MODELS.duplicate()
	pool.shuffle()
	return pool.slice(0, PREVIEW_COUNT)


## Builds one preview cell and returns the model's bounding-sphere diameter so
## the caller can frame all previews to a shared scale.
func _build_preview(model_path: String, rect: Rect2) -> float:
	var container := SubViewportContainer.new()
	container.position = rect.position
	container.size = rect.size
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)

	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.size = rect.size
	container.add_child(viewport)

	# Tilt platform raises the car's back (+Z) by BACK_TILT_DEG; the spinner yaws
	# beneath it, so the whole thing reads as a slightly back-tilted turntable.
	# Both pivot at the origin, where each model's bottom-centre is parked — so
	# the bottom stays put through tilt and spin and the cars share a ground line.
	var platform := Node3D.new()
	platform.rotation = Vector3(-deg_to_rad(BACK_TILT_DEG), 0.0, 0.0)
	viewport.add_child(platform)

	var spinner := Node3D.new()
	platform.add_child(spinner)

	var model: Node3D = (load(model_path) as PackedScene).instantiate()
	spinner.add_child(model)
	var aabb := _merged_aabb(model)
	var center := aabb.get_center()
	# Park the model's bottom-centre at the origin (the shared ground point).
	model.position = Vector3(-center.x, -aabb.position.y, -center.z)
	_models.append(spinner)

	var light := DirectionalLight3D.new()
	light.rotation = Vector3(deg_to_rad(-50.0), deg_to_rad(-40.0), 0.0)
	viewport.add_child(light)

	# Modest ambient so the unlit sides aren't pure black.
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.4
	var we := WorldEnvironment.new()
	we.environment = env
	viewport.add_child(we)

	# Camera framing (size, position) is set by the caller once the shared scale
	# is known; here we just create it.
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	viewport.add_child(cam)
	_cameras.append(cam)

	return aabb.size.length()


func _update_highlight() -> void:
	if _highlight == null or _cell_rects.is_empty():
		return
	var rect: Rect2 = _cell_rects[_selected]
	_highlight.position = rect.position
	_highlight.size = rect.size


func _merged_aabb(node: Node3D) -> AABB:
	# AABB in node-local space; node must be in the tree (uses global_transform).
	var inv := node.global_transform.affine_inverse()
	var out := AABB()
	var first := true
	for mi in _find_meshes(node):
		var m: MeshInstance3D = mi
		var box: AABB = (inv * m.global_transform) * m.get_aabb()
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
