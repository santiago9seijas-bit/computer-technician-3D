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

# Caché de líneas longitudinales para batcheado draw_multiline O(1)
var _cached_longitudinal_lines: PackedVector2Array = PackedVector2Array()
var _cached_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Generar estrellas fijas
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1337
	stars.clear()
	for i in range(45):
		stars.append(Vector3(rng.randf(), rng.randf() * 0.5, rng.randf_range(0.3, 1.0)))
	_rebuild_perspective_cache()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_rebuild_perspective_cache()

func _rebuild_perspective_cache() -> void:
	var w: float = size.x if size.x > 50.0 else 1280.0
	var h: float = size.y if size.y > 50.0 else 720.0
	var hy: float = h * horizon_y
	var center: Vector2 = Vector2(w * 0.5, hy)
	var num_perspective_lines: int = 22
	
	_cached_longitudinal_lines.clear()
	for i in range(-num_perspective_lines, num_perspective_lines + 1):
		var bottom_x: float = center.x + float(i) * (w / 12.0)
		_cached_longitudinal_lines.append(center)
		_cached_longitudinal_lines.append(Vector2(bottom_x, h))
	_cached_size = Vector2(w, h)

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	offset += delta * line_speed
	if offset > 1.0:
		offset -= 1.0
	queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w <= 1.0 or h <= 1.0:
		return
	var hy: float = h * horizon_y
	
	if _cached_size != Vector2(w, h) or _cached_longitudinal_lines.is_empty():
		_rebuild_perspective_cache()
	
	# 1. Cielo con degradado profundo
	draw_rect(Rect2(0, 0, w, hy), bg_top_color, true)
	
	# Resplandor en el horizonte (banda de degradado suave)
	var glow_height: float = hy * 0.4
	for step in range(8):
		var t: float = float(step) / 8.0
		var band_y: float = hy - glow_height * (1.0 - t)
		var band_h: float = glow_height / 8.0
		var col: Color = bg_top_color.lerp(bg_horizon_color, t * 0.8)
		draw_rect(Rect2(0, band_y, w, band_h + 1.0), col, true)
	
	# 2. Partículas / Estrellas en el cielo
	var t_msec: float = float(Time.get_ticks_msec()) * 0.001
	for star in stars:
		var sx: float = star.x * w
		var sy: float = star.y * hy
		var twinkle: float = star.z * (0.6 + sin(t_msec * 3.0 + star.x * 20.0) * 0.4)
		draw_circle(Vector2(sx, sy), 1.2, Color(1.0, 1.0, 1.0, twinkle * 0.7))
	
	# 3. Suelo base
	draw_rect(Rect2(0, hy, w, h - hy), bg_bottom_color, true)
	
	# 4. Línea de horizonte de neón con glow
	draw_line(Vector2(0, hy), Vector2(w, hy), Color(1.0, 0.1, 0.5, 0.4), 8.0)
	draw_line(Vector2(0, hy), Vector2(w, hy), Color(1.0, 0.3, 0.7, 0.9), 2.5)
	draw_line(Vector2(0, hy), Vector2(w, hy), Color(1.0, 1.0, 1.0, 0.8), 1.0)
	
	# 5. Grilla en perspectiva (Líneas longitudinales batcheadas en una única llamada)
	var p_color: Color = grid_color
	p_color.a = 0.45
	if not _cached_longitudinal_lines.is_empty():
		draw_multiline(_cached_longitudinal_lines, p_color, 1.5)
	
	# 6. Líneas transversales con escala de perspectiva cuadrática
	var num_horiz: int = 14
	for j in range(num_horiz):
		var t: float = float(j + offset) / float(num_horiz)
		var exp_t: float = t * t # Perspectiva cuadrática
		var line_y: float = hy + exp_t * (h - hy)
		var alpha: float = lerp(0.08, 0.85, exp_t)
		var c: Color = grid_color
		c.a = alpha
		var thickness: float = lerp(1.0, 2.5, exp_t)
		draw_line(Vector2(0, line_y), Vector2(w, line_y), c, thickness)
	
	# 7. Detalles Cyberpunk Superiores (Régla tecnológica del HUD)
	var bar_y: float = 75.0
	var bar_start_x: float = w * 0.62
	var bar_end_x: float = w * 0.88
	draw_line(Vector2(bar_start_x, bar_y), Vector2(bar_end_x, bar_y), Color(0.4, 0.5, 0.7, 0.5), 1.5)
	draw_rect(Rect2(bar_start_x + 40.0, bar_y - 3.0, 6.0, 6.0), Color(0.0, 0.9, 1.0, 0.85), true)
	draw_rect(Rect2(bar_end_x - 30.0, bar_y - 3.0, 6.0, 6.0), Color(1.0, 0.1, 0.5, 0.85), true)
	draw_circle(Vector2(bar_end_x + 6.0, bar_y), 3.0, Color(1.0, 1.0, 1.0, 0.8))
