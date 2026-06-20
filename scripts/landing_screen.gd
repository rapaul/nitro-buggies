extends Control
## Title/landing screen shown before gameplay. The "Nitro Buggies" title is a
## sandy-yellow face over a sandy-orange block shadow, built in code so no .tscn
## NodePath exports are relied on.
##
## The screen runs in two stages. STAGE_MODE offers a 1P/2P choice — two labels
## in the title font, the selected one wrapped in the same chunky square box the
## vehicle picker uses. Confirming records the player count. STAGE_PICK then runs
## the vehicle picker: a single full-screen picker in 1P, or two split-screen
## pickers in 2P (Player 1 top, Player 2 bottom) navigated independently, with the
## race starting once both players confirm.

const MAIN_SCENE := "res://scenes/Main.tscn"

const SANDY_YELLOW := Color("e8c76a")  # title face
const SANDY_ORANGE := Color("c8761e")  # block shadow

const TITLE_FONT := "res://assets/fonts/Kenney Blocks.ttf"
const TITLE_SIZE := 96
const TITLE_SPACING := 4
const SHADOW_OFFSET := Vector2(12, 12)  # lower-right block shadow

const MARGIN_TOP := 56.0
const MARGIN_X := 72.0

# --- Mode selection (1P / 2P) ---

const MODE_LABELS := ["1P", "2P"]
const MODE_BOX := 0.20        ## selection box side, as a fraction of viewport height
const MODE_GAP := 0.12        ## gap between the two boxes, as a fraction of viewport height
const MODE_FONT_SIZE := 72
const MODE_BOX_Y := 0.52      ## top of the boxes, as a fraction of viewport height

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

## Square preview side, as a fraction of the picker area's height. Chosen so a
## full-screen 1P picker (area = bottom two-thirds) yields the same on-screen cell
## as before: (2/3) * 0.63 == 0.42 of the viewport height.
const CELL_FRAC_OF_AREA := 0.63
## Fraction of the cell that each vehicle's bounding sphere fills. The sphere is
## rotation-invariant, so framing by it keeps the whole car inside the square at
## every angle; 0.9 leaves a margin inside the chunky border.
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
## In split (2P) pickers, the band reserved at the top of each half for the
## "Player N" label, as a fraction of viewport height. 0 for a full-screen picker.
const PICK_LABEL_BAND := 0.12
const PICK_LABEL_FONT_SIZE := 40

## Chunky selection border.
const HIGHLIGHT_BORDER := 8
const HIGHLIGHT_COLOR := Color("e8c76a")   # sandy yellow, matching the title
const CONFIRM_COLOR := Color("8ed24a")     # green, shown once a player has locked in


## One vehicle picker: its own trio of models, on-screen cells, selection, and
## confirm latch, plus the input actions that drive it. A full-screen 1P picker
## uses one of these; a 2P screen uses two.
class Picker:
	var nav_left: Array       # action names that move the selection left
	var nav_right: Array      # action names that move the selection right
	var accept: Array         # action names that confirm the selection
	var models: Array[Node3D] = []      # rotating spinner nodes, left to right
	var cameras: Array[Camera3D] = []   # one per preview, framed together
	var cell_rects: Array[Rect2] = []   # on-screen rect of each preview cell
	var picked: Array[String] = []      # chosen model paths, left to right
	var selected := 0                   # index of the highlighted preview
	var highlight: Panel
	var confirmed := false

	func selected_path() -> String:
		return picked[selected]


enum { STAGE_MODE, STAGE_PICK }

var _stage := STAGE_MODE
var _stage_root: Control          # holds the current stage's nodes; freed on transition

# Mode stage state.
var _mode_selected := 0
var _mode_rects: Array[Rect2] = []
var _mode_highlight: Panel

# Pick stage state.
var _pickers: Array = []          # Array[Picker]


func _ready() -> void:
	_build_mode_stage()


func _process(delta: float) -> void:
	# One revolution every ROT_PERIOD seconds, frame-rate independent.
	for p in _pickers:
		for m in p.models:
			m.rotate_y(TAU / ROT_PERIOD * delta)


func _unhandled_input(event: InputEvent) -> void:
	if _stage == STAGE_MODE:
		_mode_input(event)
	else:
		_pick_input(event)


# --- Mode selection stage ---

func _build_mode_stage() -> void:
	_stage = STAGE_MODE
	_stage_root = _new_stage_root()
	_build_title(_stage_root)

	var vp := get_viewport_rect().size
	var box := vp.y * MODE_BOX
	var gap := vp.y * MODE_GAP
	var total_w := 2.0 * box + gap
	var x0 := (vp.x - total_w) / 2.0
	var y := vp.y * MODE_BOX_Y
	_mode_rects.clear()
	for i in 2:
		var rect := Rect2(x0 + i * (box + gap), y, box, box)
		_mode_rects.append(rect)
		_add_centered_label(_stage_root, MODE_LABELS[i], rect, MODE_FONT_SIZE)

	_mode_highlight = _make_highlight()
	_stage_root.add_child(_mode_highlight)
	_update_mode_highlight()


func _mode_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		Selection.player_count = _mode_selected + 1
		_transition_to_pick()
	elif event.is_action_pressed("ui_left"):
		_move_mode(-1)
	elif event.is_action_pressed("ui_right"):
		_move_mode(1)


func _move_mode(step: int) -> void:
	var next := clampi(_mode_selected + step, 0, MODE_LABELS.size() - 1)
	if next != _mode_selected:
		_mode_selected = next
		_update_mode_highlight()


func _update_mode_highlight() -> void:
	var rect: Rect2 = _mode_rects[_mode_selected]
	_mode_highlight.position = rect.position
	_mode_highlight.size = rect.size


func _transition_to_pick() -> void:
	_stage_root.queue_free()
	_mode_rects.clear()
	_build_pick_stage()


# --- Vehicle picking stage ---

func _build_pick_stage() -> void:
	_stage = STAGE_PICK
	_stage_root = _new_stage_root()
	var vp := get_viewport_rect().size
	if Selection.player_count == 2:
		var top := Rect2(0.0, 0.0, vp.x, vp.y * 0.5)
		var bot := Rect2(0.0, vp.y * 0.5, vp.x, vp.y * 0.5)
		_pickers.append(_build_picker(top, ["steer_left"], ["steer_right"], ["p1_accept"], "Player 1"))
		_pickers.append(_build_picker(bot, ["p2_steer_left"], ["p2_steer_right"], ["p2_accept"], "Player 2"))
	else:
		# Single picker over the bottom two-thirds, with the title above it.
		_build_title(_stage_root)
		var area_top := vp.y / 3.0
		var rect := Rect2(0.0, area_top, vp.x, vp.y - area_top)
		_pickers.append(_build_picker(rect, ["ui_left", "steer_left"], ["ui_right", "steer_right"], ["ui_accept"], ""))


func _pick_input(event: InputEvent) -> void:
	for p in _pickers:
		if p.confirmed:
			continue
		for a in p.nav_left:
			if event.is_action_pressed(a):
				_move_picker(p, -1)
				return
		for a in p.nav_right:
			if event.is_action_pressed(a):
				_move_picker(p, 1)
				return
		for a in p.accept:
			if event.is_action_pressed(a):
				_confirm_picker(p)
				return


func _move_picker(p: Picker, step: int) -> void:
	# Clamp at the ends — no wrap-around.
	var next := clampi(p.selected + step, 0, p.picked.size() - 1)
	if next != p.selected:
		p.selected = next
		_update_picker_highlight(p)


func _confirm_picker(p: Picker) -> void:
	if Selection.player_count == 1:
		Selection.selected_model_path = p.selected_path()
		get_tree().change_scene_to_file(MAIN_SCENE)
		return

	# 2P: latch this player's pick (recolour its box to show it's locked) and start
	# the race only once both players have confirmed.
	p.confirmed = true
	_recolor_highlight(p.highlight, CONFIRM_COLOR)
	for q in _pickers:
		if not q.confirmed:
			return
	Selection.selected_model_path = _pickers[0].selected_path()
	Selection.player2_model_path = _pickers[1].selected_path()
	get_tree().change_scene_to_file(MAIN_SCENE)


## Builds one picker laid out inside `area`, with the given navigation/confirm
## actions and an optional "Player N" label band at the top of the area.
func _build_picker(area: Rect2, nav_left: Array, nav_right: Array, accept: Array, label_text: String) -> Picker:
	var p := Picker.new()
	p.nav_left = nav_left
	p.nav_right = nav_right
	p.accept = accept
	p.picked = _pick_models()

	# Reserve a top band for the label (split pickers); none for full-screen.
	var band := 0.0
	if label_text != "":
		var vp := get_viewport_rect().size
		band = vp.y * PICK_LABEL_BAND
		var label_rect := Rect2(area.position.x, area.position.y, area.size.x, band)
		_add_centered_label(_stage_root, label_text, label_rect, PICK_LABEL_FONT_SIZE)

	var cells_top := area.position.y + band
	var cells_h := area.size.y - band
	var cell := cells_h * CELL_FRAC_OF_AREA
	var cell_y := cells_top + (cells_h - cell) / 2.0
	# Equal horizontal gaps: PREVIEW_COUNT cells with a gap on each side.
	var gap := (area.size.x - PREVIEW_COUNT * cell) / float(PREVIEW_COUNT + 1)

	var max_diameter := 0.0
	for i in PREVIEW_COUNT:
		var cell_x := area.position.x + gap + i * (cell + gap)
		var rect := Rect2(cell_x, cell_y, cell, cell)
		p.cell_rects.append(rect)
		max_diameter = maxf(max_diameter, _build_preview(p, p.picked[i], rect))

	# Frame every preview with the same scale (driven by the largest of the trio)
	# so the shared ground line — each model's bottom, parked at the world origin —
	# lands at the same screen height in every cell.
	var ortho := max_diameter / FILL
	var look_y := ortho * GROUND_OFFSET
	var pitch := deg_to_rad(CAM_PITCH_DEG)
	var dist := 10.0
	for cam in p.cameras:
		cam.size = ortho
		cam.position = Vector3(0.0, look_y + sin(pitch) * dist, cos(pitch) * dist)
		cam.rotation = Vector3(-pitch, 0.0, 0.0)

	p.highlight = _make_highlight()
	_stage_root.add_child(p.highlight)
	_update_picker_highlight(p)
	return p


func _pick_models() -> Array[String]:
	var pool := VEHICLE_MODELS.duplicate()
	pool.shuffle()
	return pool.slice(0, PREVIEW_COUNT)


## Builds one preview cell and returns the model's bounding-sphere diameter so
## the caller can frame all previews to a shared scale.
func _build_preview(p: Picker, model_path: String, rect: Rect2) -> float:
	var container := SubViewportContainer.new()
	container.position = rect.position
	container.size = rect.size
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage_root.add_child(container)

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
	CarSkin.apply(model)
	var aabb := _merged_aabb(model)
	var center := aabb.get_center()
	# Park the model's bottom-centre at the origin (the shared ground point).
	model.position = Vector3(-center.x, -aabb.position.y, -center.z)
	p.models.append(spinner)

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
	p.cameras.append(cam)

	return aabb.size.length()


func _update_picker_highlight(p: Picker) -> void:
	if p.highlight == null or p.cell_rects.is_empty():
		return
	var rect: Rect2 = p.cell_rects[p.selected]
	p.highlight.position = rect.position
	p.highlight.size = rect.size


# --- Shared UI helpers ---

func _new_stage_root() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	return root


func _make_highlight() -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)  # transparent fill — just a chunky frame
	style.set_border_width_all(HIGHLIGHT_BORDER)
	style.border_color = HIGHLIGHT_COLOR
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _recolor_highlight(panel: Panel, color: Color) -> void:
	var style: StyleBoxFlat = panel.get_theme_stylebox("panel")
	style.border_color = color


func _build_title(parent: Control) -> void:
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
	parent.add_child(area)

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


## A label centered in `rect`, set in the title font — used for the 1P/2P choices
## and the "Player N" headings, so all picker chrome shares the heading typeface.
func _add_centered_label(parent: Control, text: String, rect: Rect2, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = rect.position
	label.size = rect.size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var font := FontVariation.new()
	font.base_font = load(TITLE_FONT)
	font.spacing_glyph = TITLE_SPACING
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", SANDY_YELLOW)
	parent.add_child(label)


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
