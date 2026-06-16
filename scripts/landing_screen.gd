extends Control
## Title/landing screen shown before gameplay. The "Nitro Buggies" title is a
## sandy-yellow face over a sandy-orange block shadow, built in code so no .tscn
## NodePath exports are relied on. Pressing ENTER starts the main game.

const MAIN_SCENE := "res://scenes/Main.tscn"

const SANDY_YELLOW := Color("e8c76a")  # title face
const SANDY_ORANGE := Color("c8761e")  # block shadow

const TITLE_FONT := "res://assets/fonts/Kenney Blocks.ttf"
const TITLE_SIZE := 96
const TITLE_SPACING := 4
const SHADOW_OFFSET := Vector2(12, 12)  # lower-right block shadow

const MARGIN_TOP := 56.0
const MARGIN_X := 72.0


func _ready() -> void:
	_build_title()


func _unhandled_input(event: InputEvent) -> void:
	# ui_accept covers ENTER (and KP-Enter) by default.
	if event.is_action_pressed("ui_accept"):
		get_tree().change_scene_to_file(MAIN_SCENE)


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
