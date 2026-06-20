extends Control
## Per-player HUD, bound to one car and sized to that player's screen rect (the
## full screen in single-player, a split half in two-player). Draws a three-bar
## health meter (top-left) and the held-pickup box (lower-right), and hosts the
## terminal WASTED / WINNER overlay. All built in code, no .tscn.

const TITLE_FONT := "res://assets/fonts/Kenney Blocks.ttf"

# Health bar
const SEG_SIZE := Vector2(44, 18)
const SEG_GAP := 6.0
const BAR_MARGIN := Vector2(20, 18)
const BAR_FULL := Color("8ed24a")          # green, like the picker confirm colour
const BAR_EMPTY := Color(0.15, 0.15, 0.15, 0.7)

# Held-item box
const BOX_SIZE := 96.0
const BOX_MARGIN := 20.0
const BOX_BORDER := 6
const BOX_BORDER_COLOR := Color("e8c76a")   # sandy yellow, matching the title chrome
const NITRO_COLOR := Color(0.3, 0.6, 1.0)
const FIREBALL_COLOR := Color(1.0, 0.4, 0.15)

# Outcome overlay
const MSG_FONT_SIZE := 84
const MSG_SHADOW := Vector2(6, 6)
const WASTED_FACE := Color("e0241a")        # red
const WASTED_SHADOW := Color("e0801e")      # orange
const WINNER_FACE := Color("ffd24a")        # gold
const WINNER_SHADOW := Color("8a6510")      # dark gold

var _car: Node
var _segments: Array[ColorRect] = []
var _item_fill: ColorRect
var _overlay: Control


func setup(car: Node, rect: Rect2) -> void:
	_car = car
	position = rect.position
	size = rect.size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_health()
	_build_item_box()
	_build_overlay()
	car.health_changed.connect(_on_health_changed)
	car.held_item_changed.connect(_on_held_item_changed)
	_on_health_changed(car.health)
	_on_held_item_changed(car.held_item)


func show_wasted() -> void:
	_show_message("WASTED", WASTED_FACE, WASTED_SHADOW)


func show_winner() -> void:
	_show_message("WINNER", WINNER_FACE, WINNER_SHADOW)


# --- Build ---

func _build_health() -> void:
	for i in Car.MAX_HEALTH:
		var seg := ColorRect.new()
		seg.size = SEG_SIZE
		seg.position = BAR_MARGIN + Vector2(i * (SEG_SIZE.x + SEG_GAP), 0.0)
		seg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(seg)
		_segments.append(seg)


func _build_item_box() -> void:
	var box := Panel.new()
	box.size = Vector2(BOX_SIZE, BOX_SIZE)
	box.position = size - Vector2(BOX_SIZE + BOX_MARGIN, BOX_SIZE + BOX_MARGIN)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.35)
	style.set_border_width_all(BOX_BORDER)
	style.border_color = BOX_BORDER_COLOR
	box.add_theme_stylebox_override("panel", style)
	add_child(box)

	_item_fill = ColorRect.new()
	_item_fill.size = Vector2(BOX_SIZE, BOX_SIZE) * 0.6
	_item_fill.position = (Vector2(BOX_SIZE, BOX_SIZE) - _item_fill.size) * 0.5
	_item_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_item_fill)


func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false
	add_child(_overlay)

	var fade := ColorRect.new()
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 0.6)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(fade)


# --- Updates ---

func _on_health_changed(health: int) -> void:
	for i in _segments.size():
		_segments[i].color = BAR_FULL if i < health else BAR_EMPTY


func _on_held_item_changed(item: int) -> void:
	match item:
		Car.Item.NITRO:
			_item_fill.color = NITRO_COLOR
			_item_fill.visible = true
		Car.Item.FIREBALL:
			_item_fill.color = FIREBALL_COLOR
			_item_fill.visible = true
		_:
			_item_fill.visible = false


func _show_message(text: String, face: Color, shadow: Color) -> void:
	_overlay.visible = true
	# Shadow first so it draws behind the face, mirroring the landing-screen title.
	_add_message_label(text, shadow, MSG_SHADOW)
	_add_message_label(text, face, Vector2.ZERO)


func _add_message_label(text: String, color: Color, offset: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.offset_left = offset.x
	label.offset_right = offset.x
	label.offset_top = offset.y
	label.offset_bottom = offset.y
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font := FontVariation.new()
	font.base_font = load(TITLE_FONT)
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", MSG_FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	_overlay.add_child(label)
