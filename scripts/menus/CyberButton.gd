@tool
extends Button

@export var slant: float = 24.0
@export var border_color: Color = Color(1.0, 0.08, 0.45, 1.0)
@export var hover_border_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var fill_color: Color = Color(0.10, 0.02, 0.18, 0.90)
@export var hover_fill_color: Color = Color(0.24, 0.04, 0.38, 0.95)
@export var pressed_fill_color: Color = Color(1.0, 0.08, 0.45, 0.8)
@export var glow_color: Color = Color(1.0, 0.08, 0.45, 0.35)

var is_hovered: bool = false
var hover_t: float = 0.0
var base_x: float = 0.0
var initialized_base: bool = false

func _ready() -> void:
	flat = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_mouse_entered)
	focus_exited.connect(_on_mouse_exited)

func _process(delta: float) -> void:
	if not initialized_base and position.x != 0:
		base_x = position.x
		initialized_base = true

	var target_t = 1.0 if (is_hovered or has_focus()) else 0.0
	if abs(hover_t - target_t) > 0.001:
		hover_t = lerp(hover_t, target_t, delta * 14.0)
		if initialized_base:
			position.x = base_x + hover_t * 10.0 # Desplazamiento sutil hacia la derecha al hover
		queue_redraw()

func _on_mouse_entered() -> void:
	is_hovered = true
	queue_redraw()

func _on_mouse_exited() -> void:
	is_hovered = false
	queue_redraw()

func _draw() -> void:
	var w = size.x
	var h = size.y
	
	# Puntos trapezoidales estilo cyberpunk (corte en diagonal en el borde derecho)
	# (0,0) -> (w - slant, 0) -> (w, h) -> (0, h)
	var pts: PackedVector2Array = [
		Vector2(0, 0),
		Vector2(w - slant, 0),
		Vector2(w, h),
		Vector2(0, h)
	]
	
	var current_fill = fill_color.lerp(hover_fill_color, hover_t)
	if button_pressed:
		current_fill = pressed_fill_color
		
	var current_border = border_color.lerp(hover_border_color, hover_t)
	var current_glow = glow_color
	current_glow.a = lerp(0.2, 0.7, hover_t)
	
	# Relleno del polígono
	draw_colored_polygon(pts, current_fill)
	
	# Borde cerrado con glow
	var border_pts = pts.duplicate()
	border_pts.append(pts[0])
	
	# Glow exterior
	draw_polyline(border_pts, current_glow, 6.0)
	# Línea de borde nítida
	draw_polyline(border_pts, current_border, 2.5)
	
	# Micro-acento tecnológico: pequeño recuadro blanco/cian en la esquina superior izquierda al hover
	if hover_t > 0.2:
		var accent_col = Color(0.0, 0.9, 1.0, hover_t)
		draw_rect(Rect2(4, 4, 3, h - 8), accent_col, true)
