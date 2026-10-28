@tool
extends Control

@export var bracket_color: Color = Color(1.0, 0.1, 0.5, 0.9)
@export var glow_color: Color = Color(1.0, 0.1, 0.5, 0.3)

func _draw() -> void:
	var w = size.x
	var h = size.y
	
	# Puntos del bracket zigzag estilo cyberpunk
	var points: PackedVector2Array = [
		Vector2(20, 10),
		Vector2(w * 0.75, 10),
		Vector2(w * 0.95, h * 0.28),
		Vector2(w * 0.65, h * 0.48),
		Vector2(w * 0.90, h * 0.68),
		Vector2(w * 0.60, h * 0.88),
		Vector2(20, h * 0.98)
	]
	
	# Glow grueso
	draw_polyline(points, glow_color, 8.0)
	# Línea brillante
	draw_polyline(points, bracket_color, 3.0)
