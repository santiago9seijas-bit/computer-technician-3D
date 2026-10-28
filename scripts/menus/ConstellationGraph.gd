@tool
extends Control

@export var line_color: Color = Color(0.2, 0.5, 0.9, 0.45)
@export var laser_active_color: Color = Color(1.0, 0.1, 0.5, 0.8)

func _draw() -> void:
	# Coordenadas relativas de los nodos de la constelación
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
		# Si conecta con el nodo 1 (activo), dibujamos láser activo
		if conn.x == 0:
			draw_line(p1, p2, laser_active_color, 2.5)
		else:
			draw_line(p1, p2, line_color, 1.5)
