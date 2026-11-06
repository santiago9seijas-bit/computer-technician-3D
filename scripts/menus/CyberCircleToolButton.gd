@tool
extends Button
class_name CyberCircleToolButton

@export var tool_id: int = 1:
	set(val):
		tool_id = val
		_update_visuals()

@export var tool_name: String = "Cruz ★":
	set(val):
		tool_name = val
		_update_visuals()

@export var key_shortcut: String = "[ 1 ]":
	set(val):
		key_shortcut = val
		_update_visuals()

@export var icon_texture: Texture2D = null:
	set(val):
		icon_texture = val
		_update_visuals()

@export var icon_modulate: Color = Color(1, 1, 1, 1):
	set(val):
		icon_modulate = val
		_update_visuals()

@export var icon_flip_h: bool = false:
	set(val):
		icon_flip_h = val
		_update_visuals()

@export var circle_texture: Texture2D = null:
	set(val):
		circle_texture = val
		_update_visuals()

var circle_rect: TextureRect = null
var icon_rect: TextureRect = null
var key_label: Label = null
var name_label: Label = null
var circle_material: ShaderMaterial = null
var is_active: bool = false
var is_hovered: bool = false
var _scale_tween: Tween = null

func _ready() -> void:
	flat = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = Vector2(104, 118)
	pivot_offset = Vector2(52, 59)
	
	# Ocultar texto nativo del botón
	text = ""
	add_theme_color_override("font_color", Color(0, 0, 0, 0))
	add_theme_color_override("font_hover_color", Color(0, 0, 0, 0))
	add_theme_color_override("font_pressed_color", Color(0, 0, 0, 0))
	add_theme_color_override("font_focus_color", Color(0, 0, 0, 0))
	
	_build_nodes()
	_update_visuals()
	
	if not Engine.is_editor_hint():
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
		focus_entered.connect(_on_mouse_entered)
		focus_exited.connect(_on_mouse_exited)

func _build_nodes() -> void:
	custom_minimum_size = Vector2(104, 118)
	pivot_offset = Vector2(52, 59)
	
	# 1. NÚMEROS / TECLA ARRIBA Y CENTRADOS
	key_label = get_node_or_null("KeyBadge") as Label
	if key_label == null:
		key_label = Label.new()
		key_label.name = "KeyBadge"
		key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(key_label)
	key_label.offset_left = 0.0
	key_label.offset_top = 0.0
	key_label.offset_right = 104.0
	key_label.offset_bottom = 20.0
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key_label.add_theme_font_size_override("font_size", 13)
	key_label.add_theme_color_override("font_color", Color(1.0, 0.28, 0.48, 0.95))
	key_label.add_theme_color_override("font_shadow_color", Color(0.12, 0.0, 0.06, 0.95))
	key_label.add_theme_constant_override("shadow_offset_x", 1)
	key_label.add_theme_constant_override("shadow_offset_y", 1)
	key_label.add_theme_constant_override("shadow_outline_size", 4)
	if ResourceLoader.exists("res://assets/fonts/JetBrainsMono-Bold.ttf"):
		key_label.add_theme_font_override("font", load("res://assets/fonts/JetBrainsMono-Bold.ttf"))

	# 2. CÍRCULO DE OBJETO GRANDE Y BIEN PROPORCIONADO (98x78 px, aspecto 259:205)
	circle_rect = get_node_or_null("CircleRect") as TextureRect
	if circle_rect == null:
		circle_rect = TextureRect.new()
		circle_rect.name = "CircleRect"
		circle_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		circle_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		circle_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		circle_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(circle_rect)
	circle_rect.offset_left = 3.0
	circle_rect.offset_top = 20.0
	circle_rect.offset_right = 101.0
	circle_rect.offset_bottom = 98.0
	
	# Material shader holográfico rojizo único para este slot
	var base_mat = load("res://styles/cyber_circle_hologram.tres")
	if base_mat and not Engine.is_editor_hint():
		if circle_material == null:
			circle_material = base_mat.duplicate()
		circle_rect.material = circle_material
	elif base_mat and circle_rect.material == null:
		circle_rect.material = base_mat
	
	# 3. ICONO INTERNO GRANDE Y CENTRADO EN EL CÍRCULO (40x40 px)
	icon_rect = get_node_or_null("IconRect") as TextureRect
	if icon_rect == null:
		icon_rect = TextureRect.new()
		icon_rect.name = "IconRect"
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(icon_rect)
	icon_rect.offset_left = 32.0
	icon_rect.offset_top = 39.0
	icon_rect.offset_right = 72.0
	icon_rect.offset_bottom = 79.0
		
	# 4. NOMBRE DE LA HERRAMIENTA ABAJO Y CENTRADO
	name_label = get_node_or_null("NameLabel") as Label
	if name_label == null:
		name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(name_label)
	name_label.offset_left = 0.0
	name_label.offset_top = 98.0
	name_label.offset_right = 104.0
	name_label.offset_bottom = 116.0
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.92, 0.85))
	name_label.add_theme_color_override("font_shadow_color", Color(0.6, 0.05, 0.2, 0.8))
	name_label.add_theme_constant_override("shadow_outline_size", 4)
	if ResourceLoader.exists("res://assets/fonts/JetBrainsMono-Bold.ttf"):
		name_label.add_theme_font_override("font", load("res://assets/fonts/JetBrainsMono-Bold.ttf"))

func _update_visuals() -> void:
	if circle_rect:
		if circle_texture:
			circle_rect.texture = circle_texture
		elif ResourceLoader.exists("res://pixel art menus/pantalla/circulo de objeto .png"):
			circle_rect.texture = load("res://pixel art menus/pantalla/circulo de objeto .png")
			
	if icon_rect:
		icon_rect.texture = icon_texture
		icon_rect.modulate = icon_modulate
		icon_rect.flip_h = icon_flip_h
		icon_rect.visible = (icon_texture != null)
		
	if key_label:
		key_label.text = key_shortcut
		
	if name_label:
		name_label.text = tool_name

func _on_mouse_entered() -> void:
	is_hovered = true
	if circle_material:
		circle_material.set_shader_parameter("is_hover", 1.0)
	_animate_scale(Vector2(1.06, 1.06))

func _on_mouse_exited() -> void:
	is_hovered = false
	if circle_material:
		circle_material.set_shader_parameter("is_hover", 0.0)
	_animate_scale(Vector2(1.0, 1.0))

func _animate_scale(target_scale: Vector2) -> void:
	if _scale_tween and _scale_tween.is_valid():
		_scale_tween.kill()
	_scale_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(self, "scale", target_scale, 0.15)

func set_active_tool(active: bool) -> void:
	is_active = active
	if circle_material:
		circle_material.set_shader_parameter("is_active", 1.0 if active else 0.0)
		
	if active:
		modulate = Color(1.0, 1.0, 1.0, 1.0)
		if key_label:
			key_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.95, 1.0))
		if name_label:
			name_label.add_theme_color_override("font_color", Color(1.0, 0.28, 0.45, 1.0))
			name_label.add_theme_constant_override("shadow_outline_size", 6)
		if not Engine.is_editor_hint():
			_animate_punch()
	else:
		modulate = Color(0.85, 0.85, 0.9, 0.85)
		if key_label:
			key_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.45, 0.85))
		if name_label:
			name_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.92, 0.85))
			name_label.add_theme_constant_override("shadow_outline_size", 3)
		if not is_hovered:
			scale = Vector2(1.0, 1.0)

func _animate_punch() -> void:
	if _scale_tween and _scale_tween.is_valid():
		_scale_tween.kill()
	_scale_tween = create_tween()
	_scale_tween.tween_property(self, "scale", Vector2(1.12, 1.12), 0.08).set_trans(Tween.TRANS_SINE)
	_scale_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
