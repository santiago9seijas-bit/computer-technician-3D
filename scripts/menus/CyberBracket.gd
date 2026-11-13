@tool
extends Control

@export var bracket_color: Color = Color(1.0, 0.15, 0.55, 1.0)
@export var glow_color: Color = Color(1.0, 0.1, 0.5, 0.4)
@export var fill_color: Color = Color(0.85, 0.05, 0.4, 0.12)
@export var pulse_speed: float = 2.0

var pulse_t: float = 0.0
var _cached_pts: PackedVector2Array = PackedVector2Array()
var _cached_size: Vector2 = Vector2.ZERO
var _cached_vertex: Vector2 = Vector2.ZERO

func _ready() -> void:
	_rebuild_polygon()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_rebuild_polygon()

func _rebuild_polygon() -> void:
	var w: float = size.x
	var h: float = size.y
	_cached_pts = PackedVector2Array([
		Vector2(10.0, 0.0),
		Vector2(w * 0.72, 0.0),
		Vector2(w * 0.98, h * 0.22), # Vértice superior derecho con chevron
		Vector2(w * 0.76, h * 0.44), # Quiebre hacia adentro
		Vector2(w * 0.92, h * 0.65), # Segundo quiebre
		Vector2(w * 0.68, h * 0.85), # Tercer quiebre
		Vector2(w * 0.45, h),        # Base inferior
		Vector2(10.0, h)
	])
	_cached_vertex = Vector2(w * 0.98, h * 0.22)
	_cached_size = Vector2(w, h)

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	pulse_t += delta * pulse_speed
	queue_redraw()

func _draw() -> void:
	if size != _cached_size or _cached_pts.is_empty():
		_rebuild_polygon()
	
	# El pulso sutil de neón
	var pulse: float = 0.85 + sin(pulse_t) * 0.15
	var active_glow: Color = glow_color
	active_glow.a *= pulse
	
	# Relleno traslúcido
	draw_colored_polygon(_cached_pts, fill_color)
	
	# Contorno del bracket
	# Glow exterior amplio
	draw_polyline(_cached_pts, active_glow, 12.0)
	# Glow medio
	draw_polyline(_cached_pts, Color(bracket_color.r, bracket_color.g, bracket_color.b, 0.7), 5.0)
	# Línea principal fina brillante
	draw_polyline(_cached_pts, bracket_color, 2.5)
	
	# Nodo circular brillante en el vértice principal
	draw_circle(_cached_vertex, 8.0, Color(1.0, 1.0, 1.0, 0.4 * pulse))
	draw_circle(_cached_vertex, 4.0, Color(1.0, 1.0, 1.0, 1.0))
	draw_circle(_cached_vertex, 2.0, Color(0.0, 0.9, 1.0, 1.0))
