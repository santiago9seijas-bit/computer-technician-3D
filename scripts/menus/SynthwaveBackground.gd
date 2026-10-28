@tool
extends Control

@export var horizon_y: float = 0.55
@export var grid_color: Color = Color(0.8, 0.1, 0.4, 0.35)
@export var bg_top_color: Color = Color(0.08, 0.02, 0.15, 1.0)
@export var bg_bottom_color: Color = Color(0.18, 0.04, 0.28, 1.0)
@export var line_speed: float = 0.5

var offset: float = 0.0

func _process(delta: float) -> void:
	offset += delta * line_speed
	if offset > 1.0:
		offset -= 1.0
	queue_redraw()

func _draw() -> void:
	var w = size.x
	var h = size.y
	var hy = h * horizon_y
	
	# Fondo degradado
	draw_rect(Rect2(0, 0, w, hy), bg_top_color, true)
	draw_rect(Rect2(0, hy, w, h - hy), bg_bottom_color, true)
	
	# Línea de horizonte de neón
	draw_line(Vector2(0, hy), Vector2(w, hy), Color(1.0, 0.2, 0.5, 0.8), 2.0)
	
	# Líneas de perspectiva (verticales que convergen en el centro del horizonte)
	var center = Vector2(w * 0.5, hy)
	var num_perspective_lines = 24
	for i in range(-num_perspective_lines, num_perspective_lines + 1):
		var bottom_x = center.x + i * (w / 14.0)
		draw_line(center, Vector2(bottom_x, h), grid_color, 1.5)
	
	# Líneas horizontales con escala exponencial hacia el espectador
	var num_horiz = 12
	for j in range(num_horiz):
		var t = float(j + offset) / float(num_horiz)
		var exp_t = t * t # Perspectiva cuadrática
		var line_y = hy + exp_t * (h - hy)
		var alpha = lerp(0.1, 0.7, exp_t)
		var c = grid_color
		c.a = alpha
		draw_line(Vector2(0, line_y), Vector2(w, line_y), c, 1.5)
