@tool
extends Control

@export var line_color: Color = Color(0.25, 0.45, 0.75, 0.35)
@export var laser_active_color: Color = Color(1.0, 0.15, 0.55, 0.85)
@export var trajectory_line_color: Color = Color(0.4, 0.15, 0.5, 0.25)

var anim_offset: float = 0.0

func _process(delta: float) -> void:
	anim_offset += delta * 2.0
	queue_redraw()

func _draw() -> void:
	var w = size.x
	var h = size.y
	
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
	
	# Banda de trayectoria horizontal que cruza el mapa (como en captura 6.26.48)
	var track_y = 240.0
	draw_line(Vector2(50, track_y), Vector2(w - 50, track_y), Color(1.0, 0.1, 0.5, 0.15), 18.0)
	draw_line(Vector2(50, track_y), Vector2(w - 50, track_y), trajectory_line_color, 2.0)
	
	# Conexiones fijas entre nodos
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
	
	# Halo pulsante en el Nodo 1 (activo)
	var n1_pos = nodes[0]
	var ring_r = 26.0 + sin(anim_offset * 1.5) * 4.0
	draw_circle(n1_pos, ring_r, Color(1.0, 0.1, 0.5, 0.25))
	draw_circle(n1_pos, 16.0, Color(1.0, 0.1, 0.5, 0.7))
	draw_circle(n1_pos, 8.0, Color(1.0, 1.0, 1.0, 0.95))
	
	# Dibujar círculos cerrados en los otros nodos
	for i in range(1, nodes.size()):
		var np = nodes[i]
		draw_circle(np, 14.0, Color(0.12, 0.14, 0.22, 0.9))
		draw_circle(np, 14.0, Color(0.4, 0.5, 0.7, 0.4))
