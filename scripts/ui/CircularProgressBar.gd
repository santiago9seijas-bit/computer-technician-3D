@tool
class_name CircularProgressBar
extends Control

# =============================================================================
# WIDGET CIRCULAR DE PROGRESO CYBERPUNK (ANILLO NEÓN CON NÚMERO CENTRAL)
# =============================================================================

@export_range(0.0, 100.0) var value: float = 0.0:
	set(v):
		value = clampf(v, 0.0, 100.0)
		queue_redraw()

@export var ring_width: float = 14.0:
	set(w):
		ring_width = max(2.0, w)
		queue_redraw()

@export var bg_ring_color: Color = Color(0.08, 0.04, 0.16, 0.85):
	set(c):
		bg_ring_color = c
		queue_redraw()

@export var progress_color: Color = Color(0.0, 0.95, 1.0, 1.0):
	set(c):
		progress_color = c
		queue_redraw()

@export var glow_color: Color = Color(0.0, 0.95, 1.0, 0.45):
	set(c):
		glow_color = c
		queue_redraw()

@export var label_color: Color = Color(1.0, 1.0, 1.0, 1.0):
	set(c):
		label_color = c
		queue_redraw()

var display_value: float = 0.0
var _anim_tween: Tween = null
var font_bold: Font = null

func _ready() -> void:
	if ResourceLoader.exists("res://assets/fonts/Bungee-Regular.ttf"):
		font_bold = load("res://assets/fonts/Bungee-Regular.ttf")
	elif ResourceLoader.exists("res://assets/fonts/JetBrainsMono-Bold.ttf"):
		font_bold = load("res://assets/fonts/JetBrainsMono-Bold.ttf")
	display_value = value

func set_progress(target_val: float, animate: bool = true) -> void:
	target_val = clampf(target_val, 0.0, 100.0)
	value = target_val
	if not animate or not is_inside_tree():
		display_value = target_val
		queue_redraw()
		return

	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()

	_anim_tween = create_tween()
	_anim_tween.tween_method(func(v: float):
		display_value = v
		queue_redraw()
	, display_value, target_val, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _draw() -> void:
	var center = size * 0.5
	var radius = min(center.x, center.y) - (ring_width * 0.5) - 4.0
	if radius <= 4.0:
		return

	# 1. Relleno de fondo interior oscuro
	draw_circle(center, radius - ring_width * 0.5, Color(0.03, 0.01, 0.07, 0.75))

	# 2. Anillo de fondo completo
	draw_arc(center, radius, 0.0, TAU, 64, bg_ring_color, ring_width, true)

	# 3. Anillo de progreso
	var pct = clampf(display_value / 100.0, 0.0, 1.0)
	if pct > 0.001:
		var start_angle = -PI * 0.5
		var sweep_angle = pct * TAU
		var end_angle = start_angle + sweep_angle
		
		# Glow exterior
		draw_arc(center, radius, start_angle, end_angle, 64, glow_color, ring_width + 6.0, true)
		# Arco principal
		draw_arc(center, radius, start_angle, end_angle, 64, progress_color, ring_width, true)
		
		# Punto brillante en la punta del arco
		var tip_pos = center + Vector2(cos(end_angle), sin(end_angle)) * radius
		draw_circle(tip_pos, ring_width * 0.65, Color(1.0, 1.0, 1.0, 0.95))
		draw_circle(tip_pos, ring_width * 0.95, progress_color * Color(1, 1, 1, 0.6))

	# 4. Renderizado del texto en el centro
	var font = font_bold
	if font == null:
		font = ThemeDB.fallback_font

	var pct_text = "%d%%" % int(round(display_value))
	var font_size = int(radius * 0.62)
	font_size = max(12, min(font_size, 38))

	var str_size = font.get_string_size(pct_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos = center + Vector2(-str_size.x * 0.5, str_size.y * 0.32)

	# Sombra / Contorno
	draw_string_outline(font, text_pos, pct_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, Color(0.0, 0.0, 0.0, 0.9))
	draw_string(font, text_pos + Vector2(2, 2), pct_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.0, 0.0, 0.0, 0.6))
	# Texto brillante
	draw_string(font, text_pos, pct_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label_color)

	# Subtítulo "COMPLETO" debajo del porcentaje si cabe
	if radius > 35.0:
		var sub_font_size = max(8, int(font_size * 0.34))
		var sub_text = "COMPLETO"
		if Engine.has_singleton("LocalizationManager") or (get_tree() and get_tree().root and get_tree().root.has_node("LocalizationManager")):
			var lm = get_tree().root.get_node("LocalizationManager")
			sub_text = lm.translate_text("COMPLETO")
		var sub_size = font.get_string_size(sub_text, HORIZONTAL_ALIGNMENT_CENTER, -1, sub_font_size)
		var sub_pos = center + Vector2(-sub_size.x * 0.5, str_size.y * 0.32 + sub_size.y + 4.0)
		draw_string(font, sub_pos, sub_text, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_font_size, Color(0.2, 0.85, 1.0, 0.75))
