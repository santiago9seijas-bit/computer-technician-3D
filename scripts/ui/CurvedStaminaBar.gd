class_name CurvedStaminaBar
extends Control

@export var radius: float = 52.0
@export var bar_width: float = 4.5
@export var start_angle_deg: float = -65.0
@export var total_angle_deg: float = 130.0

var stamina_ratio: float = 1.0
var is_exhausted: bool = false
var _target_alpha: float = 0.0
var _current_alpha: float = 0.0
var _fade_delay_timer: float = 0.0

const COLOR_TRACK_BG: Color = Color(0.04, 0.06, 0.12, 0.45)
const COLOR_TRACK_BORDER: Color = Color(0.0, 0.6, 0.8, 0.3)
const COLOR_NORMAL: Color = Color(0.0, 0.95, 1.0, 0.95)   # Cian cyberpunk
const COLOR_LOW: Color = Color(1.0, 0.75, 0.1, 0.95)       # Ámbar
const COLOR_EXHAUSTED: Color = Color(1.0, 0.15, 0.35, 1.0) # Magenta / Rojo neón

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_current_alpha = 0.0
	_target_alpha = 0.0
	_fade_delay_timer = 0.0

func _process(delta: float) -> void:
	# Se desvanece suavemente cuando está al 100% de estamina tras un breve retardo
	if stamina_ratio >= 0.999 and not is_exhausted:
		if _fade_delay_timer > 0.0:
			_fade_delay_timer -= delta
			_target_alpha = 1.0
		else:
			_target_alpha = 0.0
	else:
		_fade_delay_timer = 0.7
		_target_alpha = 1.0

	if not is_equal_approx(_current_alpha, _target_alpha):
		_current_alpha = move_toward(_current_alpha, _target_alpha, delta * 3.5)
		queue_redraw()

func set_stamina(current: float, max_val: float, exhausted: bool = false) -> void:
	var new_ratio: float = clampf(current / max_val if max_val > 0.0 else 0.0, 0.0, 1.0)
	if not is_equal_approx(new_ratio, stamina_ratio) or is_exhausted != exhausted:
		stamina_ratio = new_ratio
		is_exhausted = exhausted
		queue_redraw()

func _draw() -> void:
	if _current_alpha <= 0.01:
		return

	var center: Vector2 = Vector2.ZERO
	var start_rad: float = deg_to_rad(start_angle_deg)
	var end_rad: float = start_rad + deg_to_rad(total_angle_deg)

	# 1. Arco de pista / fondo
	var bg_col: Color = COLOR_TRACK_BG
	bg_col.a *= _current_alpha
	draw_arc(center, radius, start_rad, end_rad, 40, bg_col, bar_width + 2.0, true)

	# 2. Borde exterior de guía
	var border_col: Color = COLOR_TRACK_BORDER
	border_col.a *= _current_alpha
	draw_arc(center, radius, start_rad, end_rad, 40, border_col, 1.0, true)

	# 3. Arco de estamina activa
	if stamina_ratio > 0.002:
		var fill_span: float = deg_to_rad(total_angle_deg) * stamina_ratio
		var fill_end_rad: float = start_rad + fill_span
		var active_col: Color = COLOR_NORMAL
		if is_exhausted or stamina_ratio < 0.2:
			active_col = COLOR_EXHAUSTED
		elif stamina_ratio < 0.45:
			active_col = COLOR_LOW
		active_col.a *= _current_alpha

		draw_arc(center, radius, start_rad, fill_end_rad, 40, active_col, bar_width, true)

		# Remate / cabeza brillante del arco
		var tip: Vector2 = center + Vector2(cos(fill_end_rad), sin(fill_end_rad)) * radius
		draw_circle(tip, bar_width * 0.55, active_col)
