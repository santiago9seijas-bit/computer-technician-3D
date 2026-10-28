@tool
extends Control

@export var horizon_y: float = 0.54
@export var grid_color: Color = Color(0.9, 0.15, 0.55, 0.45)
@export var bg_top_color: Color = Color(0.06, 0.02, 0.13, 1.0)
@export var bg_horizon_color: Color = Color(0.24, 0.05, 0.38, 1.0)
@export var bg_bottom_color: Color = Color(0.08, 0.02, 0.16, 1.0)
@export var line_speed: float = 0.45

var offset: float = 0.0
var stars: Array[Vector3] = [] # x, y, brightness

func _ready() -> void:
	# Generar estrellas fijas
	var rng = RandomNumberGenerator.new()
	rng.seed = 1337
	stars.clear()
	for i in range(45):
		stars.append(Vector3(rng.randf(), rng.randf() * 0.5, rng.randf_range(0.3, 1.0)))

func _process(delta: float) -> void:
	offset += delta * line_speed
	if offset > 1.0:
		offset -= 1.0
	queue_redraw()

func _draw() -> void:
	var w = size.x
	var h = size.y
	var hy = h * horizon_y
	
	# 1. Cielo con degradado profundo
	# Rectángulo superior
	draw_rect(Rect2(0, 0, w, hy), bg_top_color, true)
	
	# Resplandor en el horizonte (banda de degradado suave)
	var glow_height = hy * 0.4
	for step in range(8):
		var t = float(step) / 8.0
		var band_y = hy - glow_height * (1.0 - t)
		var band_h = glow_height / 8.0
		var col = bg_top_color.lerp(bg_horizon_color, t * 0.8)
		draw_rect(Rect2(0, band_y, w, band_h + 1), col, true)
	
	# 2. Partículas / Estrellas en el cielo
	var t_msec = Time.get_ticks_msec() / 1000.0
	for star in stars:
		var sx = star.x * w
		var sy = star.y * hy
		var twinkle = star.z * (0.6 + sin(t_msec * 3.0 + star.x * 20.0) * 0.4)
		draw_circle(Vector2(sx, sy), 1.2, Color(1, 1, 1, twinkle * 0.7))
	
	# 3. Suelo base
	draw_rect(Rect2(0, hy, w, h - hy), bg_bottom_color, true)
	
	# 4. Línea de horizonte de neón con glow
	draw_line(Vector2(0, hy), Vector2(w, hy), Color(1.0, 0.1, 0.5, 0.4), 8.0)
	draw_line(Vector2(0, hy), Vector2(w, hy), Color(1.0, 0.3, 0.7, 0.9), 2.5)
	draw_line(Vector2(0, hy), Vector2(w, hy), Color(1.0, 1.0, 1.0, 0.8), 1.0)
	
	# 5. Grilla en perspectiva (Líneas longitudinales que convergen en el centro)
	var center = Vector2(w * 0.5, hy)
	var num_perspective_lines = 22
	for i in range(-num_perspective_lines, num_perspective_lines + 1):
		var bottom_x = center.x + i * (w / 12.0)
		# Fade hacia el horizonte
		var p_color = grid_color
		p_color.a = 0.45
		draw_line(center, Vector2(bottom_x, h), p_color, 1.5)
	
	# 6. Líneas transversales con escala de perspectiva cuadrática
	var num_horiz = 14
	for j in range(num_horiz):
		var t = float(j + offset) / float(num_horiz)
		var exp_t = t * t # Perspectiva cuadrática
		var line_y = hy + exp_t * (h - hy)
		var alpha = lerp(0.08, 0.85, exp_t)
		var c = grid_color
		c.a = alpha
		var thickness = lerp(1.0, 2.5, exp_t)
		draw_line(Vector2(0, line_y), Vector2(w, line_y), c, thickness)
	
	# 7. Detalles Cyberpunk Superiores (Régla tecnológica del HUD como en la foto)
	var bar_y = 75.0
	var bar_start_x = w * 0.62
	var bar_end_x = w * 0.88
	draw_line(Vector2(bar_start_x, bar_y), Vector2(bar_end_x, bar_y), Color(0.4, 0.5, 0.7, 0.5), 1.5)
	# Ticks / nodos en la línea
	draw_rect(Rect2(bar_start_x + 40, bar_y - 3, 6, 6), Color(0.0, 0.9, 1.0, 0.85), true)
	draw_rect(Rect2(bar_end_x - 30, bar_y - 3, 6, 6), Color(1.0, 0.1, 0.5, 0.85), true)
	draw_circle(Vector2(bar_end_x + 6, bar_y), 3.0, Color(1, 1, 1, 0.8))
