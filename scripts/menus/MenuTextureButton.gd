class_name MenuTextureButton
extends TextureButton

@export var normal_text_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var hover_text_color: Color = Color(0.08, 0.02, 0.15, 1.0)
@export var hover_shift_x: float = 8.0

var label: Label = null
var base_x: float = 0.0
var initialized_base: bool = false
var hover_t: float = 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	if material == null and ResourceLoader.exists("res://styles/cyber_button_hologram.tres"):
		material = load("res://styles/cyber_button_hologram.tres")
		
	label = get_node_or_null("Label")
	
	mouse_entered.connect(_on_hover_changed.bind(true))
	mouse_exited.connect(_on_hover_changed.bind(false))
	focus_entered.connect(_on_hover_changed.bind(true))
	focus_exited.connect(_on_hover_changed.bind(false))
	
	_update_text_visuals(false)

func _process(delta: float) -> void:
	if not initialized_base and position.x != 0:
		base_x = position.x
		initialized_base = true

	var is_hovered = is_hovered() or has_focus()
	var target_t = 1.0 if is_hovered else 0.0
	if abs(hover_t - target_t) > 0.001:
		hover_t = lerp(hover_t, target_t, delta * 15.0)
		if initialized_base:
			position.x = base_x + hover_t * hover_shift_x

func _on_hover_changed(hovered: bool) -> void:
	_update_text_visuals(hovered)

func _update_text_visuals(hovered: bool) -> void:
	if not label:
		label = get_node_or_null("Label")
	if label:
		if hovered:
			label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
			label.add_theme_color_override("font_shadow_color", Color(0.1, 0.0, 0.25, 0.95))
			label.add_theme_constant_override("shadow_offset_x", 0)
			label.add_theme_constant_override("shadow_offset_y", 1)
			label.add_theme_constant_override("shadow_outline_size", 4)
		else:
			label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0, 1.0))
			label.add_theme_color_override("font_shadow_color", Color(0.04, 0.01, 0.08, 0.95))
			label.add_theme_constant_override("shadow_offset_x", 1)
			label.add_theme_constant_override("shadow_offset_y", 2)
			label.add_theme_constant_override("shadow_outline_size", 3)
