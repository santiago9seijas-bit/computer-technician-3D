extends Control

# =============================================================================
# CABLEADO CIBERNÉTICO INTERCONECTADO (OVERLAY DE PAUSA)
# Sustituye motivos tipo telaraña por cables de red, líneas de bus y arneses
# de fibra óptica que interconectan terminales y bahías técnicas en tiempo real.
# =============================================================================

@export var web_alpha: float = 1.0

var anim_time: float = 0.0

# Pulsos de corriente / datos viajando por los cables
class CablePulse:
	var cable_index: int = 0
	var progress: float = 0.0
	var speed: float = 0.4
	var size: float = 2.0

var pulses: Array[CablePulse] = []

# Terminales normalizados (0.0 a 1.0)
const TERMINALS: Array[Vector2] = [
	Vector2(0.12, 0.02),  # 0: Puerto superior izquierdo
	Vector2(0.38, 0.02),  # 1: Puerto superior medio
	Vector2(0.68, 0.02),  # 2: Puerto superior derecho
	Vector2(0.02, 0.22),  # 3: Lateral izquierdo alto
	Vector2(0.02, 0.52),  # 4: Lateral izquierdo medio
	Vector2(0.02, 0.78),  # 5: Lateral izquierdo bajo
	Vector2(0.24, 0.32),  # 6: Nodo Junction Alpha
	Vector2(0.48, 0.22),  # 7: Nodo Junction Beta
	Vector2(0.35, 0.62),  # 8: Nodo Junction Gamma
	Vector2(0.62, 0.48),  # 9: Nodo Junction Delta
	Vector2(0.74, 0.32),  # 10: Nodo Junction Epsilon
	Vector2(0.52, 0.82),  # 11: Nodo Junction Zeta
	Vector2(0.22, 0.98),  # 12: Puerto inferior izquierdo
	Vector2(0.58, 0.98),  # 13: Puerto inferior medio
	Vector2(0.85, 0.98),  # 14: Puerto inferior derecho
	Vector2(0.98, 0.18),  # 15: Lateral derecho alto
	Vector2(0.98, 0.72)   # 16: Lateral derecho bajo
]

# Definición de conexiones entre terminales: [idx_from, idx_to, tipo (0=curved, 1=bus_45, 2=bus_ortho), sag_factor]
const CONNECTIONS: Array = [
	[0, 6, 0, 32.0],     # Cable colgante puerto sup -> Alpha
	[1, 7, 0, 42.0],     # Cable colgante puerto sup -> Beta
	[3, 6, 1, 0.0],      # Bus a 45° lateral -> Alpha
	[4, 8, 0, 28.0],     # Cable patch lateral -> Gamma
	[5, 12, 1, 0.0],     # Bus esquinero inferior
	[6, 7, 0, 36.0],     # Cable troncal Alpha -> Beta
	[6, 8, 2, 0.0],      # Bus vertical Alpha -> Gamma
	[7, 9, 0, 55.0],     # Cable largo colgante Beta -> Delta
	[8, 9, 0, 40.0],     # Cable intermedio Gamma -> Delta
	[8, 11, 0, 30.0],    # Cable descendente Gamma -> Zeta
	[9, 10, 0, 24.0],    # Cable patch Delta -> Epsilon
	[10, 2, 1, 0.0],     # Bus de retorno Epsilon -> Sup
	[10, 15, 0, 25.0],   # Cable patch Epsilon -> Lateral derecho
	[9, 13, 0, 48.0],    # Cable vertical Delta -> Inferior
	[11, 13, 1, 0.0],    # Bus 45° Zeta -> Inferior
	[13, 14, 0, 20.0],   # Puente inferior
	[14, 16, 0, 35.0],   # Cable curvado inferior -> Derecho
	[3, 8, 1, 0.0],      # Bus secundario de cruce
	[7, 10, 0, 38.0]     # Cable superior Beta -> Epsilon
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_init_pulses()

func _init_pulses() -> void:
	pulses.clear()
	for i in range(10):
		var p = CablePulse.new()
		p.cable_index = i % CONNECTIONS.size()
		p.progress = randf()
		p.speed = randf_range(0.28, 0.65)
		p.size = randf_range(1.6, 2.4)
		pulses.append(p)

func _process(delta: float) -> void:
	if not visible or web_alpha <= 0.001:
		return
	anim_time += delta
	queue_redraw()

func _draw() -> void:
	if web_alpha <= 0.001:
		return

	var rect_size = size
	if rect_size.x <= 10.0 or rect_size.y <= 10.0:
		rect_size = get_viewport_rect().size

	var col_glow = Color(1.0, 0.12, 0.28, web_alpha * 0.22)
	var col_cable = Color(1.0, 0.18, 0.32, web_alpha * 0.60)
	var col_bus = Color(0.95, 0.14, 0.26, web_alpha * 0.45)
	var col_terminal = Color(1.0, 0.22, 0.38, web_alpha * 0.85)
	var col_core = Color(1.0, 0.92, 0.95, web_alpha * 0.95)
	var col_clip = Color(0.3, 0.03, 0.08, web_alpha * 0.8)

	# Calcular posiciones absolutas de los terminales en pantalla
	var term_points: Array[Vector2] = []
	for i in range(TERMINALS.size()):
		var norm = TERMINALS[i]
		var pt = Vector2(norm.x * rect_size.x, norm.y * rect_size.y)
		# Leve vibración física / corriente en los terminales internos
		if i >= 6 and i <= 11:
			var vib = sin(anim_time * 2.2 + i * 1.5) * 1.8
			pt += Vector2(cos(anim_time * 1.4 + i), vib)
		term_points.append(pt)

	# 1. Dibujar los cables y buses de conexión
	for conn_idx in range(CONNECTIONS.size()):
		var conn = CONNECTIONS[conn_idx]
		var idx_a = conn[0]
		var idx_b = conn[1]
		var conn_type = conn[2]
		var base_sag = conn[3]

		var p_a = term_points[idx_a]
		var p_b = term_points[idx_b]

		if conn_type == 0:
			# Cable colgante curvado (Catenaria con oscilación sutil)
			var sway = sin(anim_time * 1.8 + conn_idx * 0.8) * 3.5
			var sag = base_sag + sway
			_draw_catenary_cable(p_a, p_b, sag, col_glow, col_cable, col_clip, 1.6)
		elif conn_type == 1:
			# Bus de circuito a 45°
			_draw_bus_trace_45(p_a, p_b, col_bus, 1.2)
		else:
			# Bus ortogonal recto
			_draw_bus_trace_ortho(p_a, p_b, col_bus, 1.2)

	# 2. Dibujar pulsos de datos / corriente viajando por los cables
	for p in pulses:
		p.progress += delta_speed(p.cable_index)
		if p.progress > 1.0:
			p.progress = 0.0
			p.cable_index = (p.cable_index + 3) % CONNECTIONS.size()

		var conn = CONNECTIONS[p.cable_index]
		var p_start = term_points[conn[0]]
		var p_end = term_points[conn[1]]
		var p_type = conn[2]
		var sag = conn[3]

		var current_pos: Vector2
		if p_type == 0:
			var sway = sin(anim_time * 1.8 + p.cable_index * 0.8) * 3.5
			var t = p.progress
			var pt = p_start.lerp(p_end, t)
			pt.y += sin(t * PI) * (sag + sway)
			current_pos = pt
		else:
			current_pos = p_start.lerp(p_end, p.progress)

		draw_circle(current_pos, p.size * 2.2, Color(1.0, 0.2, 0.35, web_alpha * 0.35))
		draw_circle(current_pos, p.size, col_core)

	# 3. Dibujar terminales técnicos / conectores en cada nodo
	for i in range(term_points.size()):
		var pt = term_points[i]
		_draw_terminal_block(pt, i, col_terminal, col_core)

func delta_speed(idx: int) -> float:
	return 0.007 + (idx % 4) * 0.003

func _draw_catenary_cable(p0: Vector2, p1: Vector2, sag: float, col_glow: Color, col_core: Color, col_clip: Color, line_w: float) -> void:
	var segments = 16
	var prev_pt = p0
	var clip_t1 = 0.35
	var clip_t2 = 0.65
	
	for i in range(1, segments + 1):
		var t = float(i) / float(segments)
		var pt = p0.lerp(p1, t)
		pt.y += sin(t * PI) * sag
		
		# Línea de brillo exterior
		draw_line(prev_pt, pt, col_glow, line_w + 2.2, true)
		# Cable principal
		draw_line(prev_pt, pt, col_core, line_w, true)
		
		# Abrazadera / cincho de cable en tercios
		if abs(t - clip_t1) < 0.035 or abs(t - clip_t2) < 0.035:
			var tangent = (pt - prev_pt).normalized()
			var normal = Vector2(-tangent.y, tangent.x) * 3.5
			draw_line(pt - normal, pt + normal, col_clip, 2.2, true)
			draw_line(pt - normal, pt + normal, Color(1.0, 0.5, 0.6, web_alpha * 0.7), 1.0, true)
			
		prev_pt = pt

func _draw_bus_trace_45(p0: Vector2, p1: Vector2, col: Color, line_w: float) -> void:
	var dx = p1.x - p0.x
	var dy = p1.y - p0.y
	var mid_x = p0.x + dx * 0.5
	var bevel = min(abs(dx) * 0.3, abs(dy) * 0.3)
	
	var p_mid1 = Vector2(mid_x - sign(dx) * bevel, p0.y)
	var p_mid2 = Vector2(mid_x + sign(dx) * bevel, p1.y)
	
	draw_line(p0, p_mid1, col, line_w, true)
	draw_line(p_mid1, p_mid2, col, line_w, true)
	draw_line(p_mid2, p1, col, line_w, true)

func _draw_bus_trace_ortho(p0: Vector2, p1: Vector2, col: Color, line_w: float) -> void:
	var p_mid = Vector2(p0.x, p1.y)
	draw_line(p0, p_mid, col, line_w, true)
	draw_line(p_mid, p1, col, line_w, true)

func _draw_terminal_block(pt: Vector2, id: int, col_terminal: Color, col_core: Color) -> void:
	# Carcasa rectangular de conector
	var box_sz = 8.0 if (id >= 6 and id <= 11) else 6.0
	var rect = Rect2(pt.x - box_sz * 0.5, pt.y - box_sz * 0.5, box_sz, box_sz)
	
	draw_rect(rect, Color(0.10, 0.015, 0.04, web_alpha * 0.95), true)
	draw_rect(rect, col_terminal, false, 1.2)
	
	# Pin interior de contacto
	draw_circle(pt, box_sz * 0.25, col_core)
	
	# Halo neón en terminales centrales
	if id >= 6 and id <= 11:
		draw_circle(pt, box_sz * 0.8, Color(col_terminal.r, col_terminal.g, col_terminal.b, web_alpha * 0.2))
