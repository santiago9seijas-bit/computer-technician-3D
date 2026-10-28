@tool
extends Button

@export var slant: float = 22.0
@export var border_color: Color = Color(1.0, 0.08, 0.45, 1.0)
@export var hover_border_color: Color = Color(0.0, 0.95, 1.0, 1.0)
@export var fill_color: Color = Color(0.08, 0.02, 0.15, 0.92)
@export var hover_fill_color: Color = Color(0.18, 0.04, 0.32, 0.98)
@export var pressed_fill_color: Color = Color(1.0, 0.08, 0.45, 0.85)
@export var glow_color: Color = Color(1.0, 0.08, 0.45, 0.4)
@export var custom_font_size: int = 17

var is_hovered: bool = false
var hover_t: float = 0.0
var base_x: float = 0.0
var initialized_base: bool = false
var font: Font = null

func _ready() -> void:
	flat = true
	# Ocultar el renderizado de texto por defecto de Button para dibujarlo nosotros con alineación óptica
	add_theme_color_override("font_color", Color(0, 0, 0, 0))
	add_theme_color_override("font_hover_color", Color(0, 0, 0, 0))
	add_theme_color_override("font_pressed_color", Color(0, 0, 0, 0))
	add_theme_color_override("font_focus_color", Color(0, 0, 0, 0))
	
	if ResourceLoader.exists("res://assets/fonts/JetBrainsMono-Bold.ttf"):
		font = load("res://assets/fonts/JetBrainsMono-Bold.ttf")
	else:
		font = ThemeDB.fallback_font
		
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_mouse_entered)
	focus_exited.connect(_on_mouse_exited)

func _process(delta: float) -> void:
	if not initialized_base and position.x != 0:
		base_x = position.x
		initialized_base = true

	var target_t = 1.0 if (is_hovered or has_focus()) else 0.0
	if abs(hover_t - target_t) > 0.001:
		hover_t = lerp(hover_t, target_t, delta * 15.0)
		if initialized_base:
			position.x = base_x + hover_t * 8.0 # Desplazamiento táctil fluido al hover
		queue_redraw()

func _on_mouse_entered() -> void:
	is_hovered = true
	queue_redraw()

func _on_mouse_exited() -> void:
	is_hovered = false
	queue_redraw()

func _draw() -> void:
	var w = size.x
	var h = size.y
	
	if font == null:
		if ResourceLoader.exists("res://assets/fonts/JetBrainsMono-Bold.ttf"):
			font = load("res://assets/fonts/JetBrainsMono-Bold.ttf")
		else:
			font = ThemeDB.fallback_font
			
	# Geometría trapezoidal con corte en el extremo derecho
	var effective_slant = min(slant, w * 0.35)
	var pts: PackedVector2Array = [
		Vector2(0, 0),
		Vector2(w - effective_slant, 0),
		Vector2(w, h),
		Vector2(0, h)
	]
	
	# Color de relleno interpolado
	var current_fill = fill_color.lerp(hover_fill_color, hover_t)
	if button_pressed:
		current_fill = pressed_fill_color
		
	draw_colored_polygon(pts, current_fill)
	
	# Borde cerrado con Glow de neón
	var current_border = border_color.lerp(hover_border_color, hover_t)
	var current_glow = glow_color.lerp(Color(0.0, 0.95, 1.0, 0.6), hover_t)
	current_glow.a *= lerp(0.3, 0.85, hover_t)
	
	var border_pts = pts.duplicate()
	border_pts.append(pts[0])
	
	# Glow exterior
	draw_polyline(border_pts, current_glow, 7.0)
	# Línea principal nítida
	draw_polyline(border_pts, current_border, 2.5)
	
	# Doble acento de luz en el corte biselado (borde derecho)
	var slant_line = PackedVector2Array([Vector2(w - effective_slant, 0), Vector2(w, h)])
	draw_polyline(slant_line, Color(1, 1, 1, 0.4 + hover_t * 0.6), 2.0)
	
	# Indicador de selección lateral (barra de luz en el margen izquierdo al hover)
	if hover_t > 0.05:
		var bar_color = Color(0.0, 0.95, 1.0, hover_t)
		draw_rect(Rect2(3, 4, 3.5, h - 8), bar_color, true)
		draw_rect(Rect2(1, 2, 7, h - 4), Color(0.0, 0.95, 1.0, hover_t * 0.35), false, 1.5)
	
	# RENDERIZADO DEL TEXTO CON MÁXIMA LEGIBILIDAD
	if text != "" and font != null:
		var f_size = custom_font_size
		# Centro óptico del área utilizable (descontando el corte diagonal derecho)
		var usable_width = w - effective_slant
		var string_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, f_size)
		var text_x = (usable_width - string_size.x) * 0.5
		var text_y = (h + string_size.y * 0.65) * 0.5 - 1.0
		
		if button_pressed:
			text_x += 1.0
			text_y += 1.0
			
		var text_pos = Vector2(text_x, text_y)
		
		# 1. Sombra / Contorno negro para contraste absoluto contra cualquier fondo
		draw_string_outline(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, f_size, 4, Color(0.02, 0.01, 0.05, 0.95))
		
		# 2. Resplandor / Drop shadow de neón
		var shadow_col = Color(1.0, 0.08, 0.45, 0.7).lerp(Color(0.0, 0.8, 1.0, 0.8), hover_t)
		draw_string(font, text_pos + Vector2(1.5, 1.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, f_size, shadow_col)
		
		# 3. Texto frontal nítido (blanco puro en normal -> blanco/cian brillante en hover)
		var text_col = Color(1.0, 1.0, 1.0, 1.0).lerp(Color(0.9, 1.0, 1.0, 1.0), hover_t)
		draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, f_size, text_col)
