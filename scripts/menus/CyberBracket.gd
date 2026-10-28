@tool
extends Control

@export var bracket_color: Color = Color(1.0, 0.15, 0.55, 1.0)
@export var glow_color: Color = Color(1.0, 0.1, 0.5, 0.4)
@export var fill_color: Color = Color(0.85, 0.05, 0.4, 0.12)
@export var pulse_speed: float = 2.0

var pulse_t: float = 0.0

func _process(delta: float) -> void:
	pulse_t += delta * pulse_speed
	queue_redraw()

func _draw() -> void:
	var w = size.x
	var h = size.y
	
	# El pulso sutil de neón
	var pulse = 0.85 + sin(pulse_t) * 0.15
	var active_glow = glow_color
	active_glow.a *= pulse
	
	# Polígono en forma de chevron cyberpunk envolvente (según captura 6.27.02 PM)
	# Envuelve la escalera de botones con cortes angulares agudos
	var pts: PackedVector2Array = [
		Vector2(10, 0),
		Vector2(w * 0.72, 0),
		Vector2(w * 0.98, h * 0.22), # Vértice superior derecho con chevron
		Vector2(w * 0.76, h * 0.44), # Quiebre hacia adentro
		Vector2(w * 0.92, h * 0.65), # Segundo quiebre
		Vector2(w * 0.68, h * 0.85), # Tercer quiebre
		Vector2(w * 0.45, h),        # Base inferior
		Vector2(10, h)
	]
	
	# Relleno traslúcido
	draw_colored_polygon(pts, fill_color)
	
	# Contorno del bracket
	var outline: PackedVector2Array = [
		Vector2(10, 0),
		Vector2(w * 0.72, 0),
		Vector2(w * 0.98, h * 0.22),
		Vector2(w * 0.76, h * 0.44),
		Vector2(w * 0.92, h * 0.65),
		Vector2(w * 0.68, h * 0.85),
		Vector2(w * 0.45, h),
		Vector2(10, h)
	]
	
	# Glow exterior amplio
	draw_polyline(outline, active_glow, 12.0)
	# Glow medio
	draw_polyline(outline, Color(bracket_color.r, bracket_color.g, bracket_color.b, 0.7), 5.0)
	# Línea principal fina brillante
	draw_polyline(outline, bracket_color, 2.5)
	
	# Nodo circular brillante en el vértice principal (como en la foto original)
	var vertex_pos = Vector2(w * 0.98, h * 0.22)
	draw_circle(vertex_pos, 8.0, Color(1, 1, 1, 0.4 * pulse))
	draw_circle(vertex_pos, 4.0, Color(1, 1, 1, 1.0))
	draw_circle(vertex_pos, 2.0, Color(0, 0.9, 1, 1.0))
