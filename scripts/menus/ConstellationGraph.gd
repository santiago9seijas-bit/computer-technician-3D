@tool
extends Control

@export var line_color: Color = Color(0.25, 0.45, 0.75, 0.35)
@export var laser_active_color: Color = Color(1.0, 0.15, 0.55, 0.85)
@export var trajectory_line_color: Color = Color(0.4, 0.15, 0.5, 0.25)

var anim_offset: float = 0.0

# Sistema de Lluvia Binaria Cyberpunk (Ceros y Unos)
class BinaryColumn:
	var x: float = 0.0
	var y: float = 0.0
	var speed: float = 70.0
	var length: int = 10
	var chars: Array[String] = []

var binary_cols: Array = []
var initialized_cols: bool = false
var char_flip_timer: float = 0.0

func _ready() -> void:
	_init_binary_rain()

func _init_binary_rain() -> void:
	binary_cols.clear()
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var total_cols = 32
	var w = size.x if size.x > 100 else 1080.0
	var col_width = w / float(total_cols)
	
	for i in range(total_cols):
		var col = BinaryColumn.new()
		col.x = i * col_width + rng.randf_range(2.0, col_width - 2.0)
		col.length = rng.randi_range(6, 14)
		col.speed = rng.randf_range(40.0, 95.0)
		col.y = rng.randf_range(-200.0, 350.0)
		
		for j in range(col.length):
			col.chars.append("1" if rng.randf() > 0.5 else "0")
			
		binary_cols.append(col)
	initialized_cols = true

func _process(delta: float) -> void:
	anim_offset += delta * 2.0
	
	if not initialized_cols:
		_init_binary_rain()
		
	# Actualizar posición de la lluvia binaria
	var h = size.y if size.y > 50 else 400.0
	char_flip_timer += delta
	var should_flip = false
	if char_flip_timer > 0.08:
		should_flip = true
		char_flip_timer = 0.0
		
	var rng = RandomNumberGenerator.new()
	for col in binary_cols:
		col.y += col.speed * delta
		var col_total_h = col.length * 15.0
		if col.y - col_total_h > h:
			col.y = -rng.randf_range(10.0, 100.0)
			col.speed = rng.randf_range(40.0, 95.0)
			
		# Mutación sutil de caracteres aleatorios (efecto data stream)
		if should_flip and rng.randf() < 0.2:
			var rand_idx = rng.randi_range(0, col.length - 1)
			col.chars[rand_idx] = "1" if col.chars[rand_idx] == "0" else "0"
			
	queue_redraw()

func _draw() -> void:
	var w = size.x
	var h = size.y
	var font = ThemeDB.fallback_font
	
	# 1. DIBUJAR LLUVIA BINARIA DE FONDO (Sutil y estilizada)
	for col in binary_cols:
		for i in range(col.length):
			var char_y = col.y - i * 15.0
			if char_y >= 0 and char_y <= h:
				var t = float(i) / float(col.length)
				var alpha: float
				var col_color: Color
				
				if i == 0:
					# Cabeza del stream binario (más brillante)
					alpha = 0.38
					col_color = Color(0.1, 1.0, 0.85, alpha)
				else:
					# Cola del stream binario con degradado hacia el fondo
					alpha = lerp(0.22, 0.03, t)
					col_color = Color(0.0, 0.7, 0.9, alpha)
				
				draw_string(font, Vector2(col.x, char_y), col.chars[i], HORIZONTAL_ALIGNMENT_CENTER, -1, 11, col_color)
	
	# Coordenadas relativas de los nodos (escala normalizada con el área)
	var nodes: Array[Vector2] = [
		Vector2(120, 240), # Nodo 1 (Básicos)
		Vector2(260, 140), # Nodo 2
		Vector2(260, 340), # Nodo 3
		Vector2(450, 160), # Nodo 4
		Vector2(450, 320), # Nodo 5
		Vector2(650, 240), # Nodo 6
		Vector2(780, 140), # Nodo 7
		Vector2(780, 320), # Nodo 8
		Vector2(950, 220)  # Nodo 9
	]
	
	# 2. Banda de trayectoria horizontal que cruza el mapa
	var track_y = 240.0
	draw_line(Vector2(50, track_y), Vector2(w - 50, track_y), Color(1.0, 0.1, 0.5, 0.15), 18.0)
	draw_line(Vector2(50, track_y), Vector2(w - 50, track_y), trajectory_line_color, 2.0)
	
	# 3. Conexiones fijas entre nodos
	var connections: Array[Vector2i] = [
		Vector2i(0, 1), Vector2i(0, 2),
		Vector2i(1, 3), Vector2i(2, 4),
		Vector2i(3, 5), Vector2i(4, 5),
		Vector2i(5, 6), Vector2i(5, 7),
		Vector2i(6, 8), Vector2i(7, 8)
	]
	
	for conn in connections:
		var p1 = nodes[conn.x]
		var p2 = nodes[conn.y]
		if conn.x == 0:
			# Láser activo pulsante desde el nodo 1
			var pulse = 0.7 + sin(anim_offset) * 0.3
			var c = laser_active_color
			c.a = pulse
			draw_line(p1, p2, Color(laser_active_color.r, laser_active_color.g, laser_active_color.b, 0.25 * pulse), 6.0)
			draw_line(p1, p2, c, 2.0)
		else:
			draw_line(p1, p2, line_color, 1.5)
	
	# 4. Halo pulsante en el Nodo 1 (activo)
	var n1_pos = nodes[0]
	var ring_r = 26.0 + sin(anim_offset * 1.5) * 4.0
	draw_circle(n1_pos, ring_r, Color(1.0, 0.1, 0.5, 0.25))
	draw_circle(n1_pos, 16.0, Color(1.0, 0.1, 0.5, 0.7))
	draw_circle(n1_pos, 8.0, Color(1.0, 1.0, 1.0, 0.95))
	
	# 5. Círculos cerrados en los otros nodos
	for i in range(1, nodes.size()):
		var np = nodes[i]
		draw_circle(np, 14.0, Color(0.12, 0.14, 0.22, 0.9))
		draw_circle(np, 14.0, Color(0.4, 0.5, 0.7, 0.4))
