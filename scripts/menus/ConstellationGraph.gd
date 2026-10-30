@tool
extends Control

# =============================================================================
# CONSTELLATION GRAPH - MAPA HOLOGRÁFICO CON 12 NODOS DINÁMICOS
# Y LÍNEAS DE FONDO TOTALMENTE SÍNCRONAS AL MAPEO DE PUNTOS
# =============================================================================

signal mode_transition_started()
signal mode_transition_completed()

@export var line_color: Color = Color(0.55, 0.05, 0.70, 0.35)
@export var laser_active_color: Color = Color(1.0, 0.08, 0.25, 0.95)
@export var trajectory_line_color: Color = Color(0.5, 0.05, 0.65, 0.25)

var anim_offset: float = 0.0
var hovered_node_index: int = -1
var boot_progress: float = 1.0
var current_mode: String = "reparacion"
var previous_mode: String = "reparacion"

# Micro-animación de transición de modo (Morphing síncrono de nodos y pistas)
var is_transitioning: bool = false
var transition_progress: float = 1.0 # 0.0 a 1.0
var transition_start_nodes: Array[Vector2] = []
var transition_target_nodes: Array[Vector2] = []
var mode_switch_pulse: float = 0.0

# Micro-animación de zoom táctil sobre los círculos de nivel
var node_zoom_scales: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
var node_ripples: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var node_press_tweens: Dictionary = {}

func trigger_node_click_zoom(index: int) -> void:
	if index < 0 or index >= node_zoom_scales.size():
		return
	if node_press_tweens.has(index) and node_press_tweens[index] != null and node_press_tweens[index].is_valid():
		node_press_tweens[index].kill()
		
	node_ripples[index] = 1.0
	var tw = create_tween()
	node_press_tweens[index] = tw
	
	# Expansión reactiva inmediata de zoom a 1.38x
	tw.tween_method(func(v: float):
		if index < node_zoom_scales.size():
			node_zoom_scales[index] = v
		queue_redraw()
	, node_zoom_scales[index], 1.38, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Rebote elástico regresando a 1.0x
	tw.tween_method(func(v: float):
		if index < node_zoom_scales.size():
			node_zoom_scales[index] = v
		queue_redraw()
	, 1.38, 1.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Onda de choque expansiva (ripple)
	var tw_rip = create_tween()
	tw_rip.tween_method(func(v: float):
		if index < node_ripples.size():
			node_ripples[index] = v
		queue_redraw()
	, 1.0, 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# -----------------------------------------------------------------------------
# CIRCUITOS Y PULSOS
# -----------------------------------------------------------------------------
class CircuitTrace:
	var points: PackedVector2Array
	var total_length: float = 0.0
	var segment_lengths: Array[float] = []

	func _init(pts: PackedVector2Array) -> void:
		points = pts
		total_length = 0.0
		segment_lengths.clear()
		for i in range(pts.size() - 1):
			var d = pts[i].distance_to(pts[i + 1])
			segment_lengths.append(d)
			total_length += d

	func get_point_at_distance(dist: float) -> Vector2:
		if points.is_empty():
			return Vector2.ZERO
		if dist <= 0.0:
			return points[0]
		if dist >= total_length:
			return points[-1]
		var cur_d: float = 0.0
		for i in range(segment_lengths.size()):
			var seg_len = segment_lengths[i]
			if cur_d + seg_len >= dist:
				var t = (dist - cur_d) / seg_len if seg_len > 0.0 else 0.0
				return points[i].lerp(points[i + 1], t)
			cur_d += seg_len
		return points[-1]

class DataPulse:
	var trace_index: int = 0
	var progress: float = 0.0
	var speed: float = 0.20
	var color: Color = Color(1.0, 0.1, 0.3, 0.9)
	var size: float = 3.0
	var tail_length: float = 35.0

class CyberMote:
	var pos: Vector2 = Vector2.ZERO
	var drift: Vector2 = Vector2.ZERO
	var size: float = 1.5
	var base_alpha: float = 0.4
	var phase: float = 0.0
	var pulse_speed: float = 2.0
	var color: Color = Color(0.8, 0.1, 1.0, 1.0)

var circuit_traces: Array[CircuitTrace] = []
var data_pulses: Array[DataPulse] = []
var cyber_motes: Array[CyberMote] = []
var initialized_fx: bool = false

# =============================================================================
# DISTRIBUCIONES VARIADAS Y DINÁMICAS (12 NODOS POR MODO)
# =============================================================================
var MODE_NODES: Dictionary = {
	# 1. REPARACIÓN: Ramificación asimétrica estilo placa base
	"reparacion": [
		Vector2(120, 440), # Nivel 1: Socket Central CPU
		Vector2(230, 290), # Nivel 2: Circuito PWM / Fan
		Vector2(260, 580), # Nivel 3: Panel Frontal & USB
		Vector2(370, 390), # Nivel 4: Bus de Memoria RAM
		Vector2(490, 260), # Nivel 5: Carril PCIe x16 GPU
		Vector2(470, 510), # Nivel 6: Bahía M.2 NVMe / SATA
		Vector2(620, 360), # Nivel 7: Módulos VRM & MOSFETs
		Vector2(640, 590), # Nivel 8: Conector ATX 24 Pines
		Vector2(760, 460), # Nivel 9: Chipset Puente Sur
		Vector2(880, 280), # Nivel 10: Radiador Refrigeración Líquida
		Vector2(930, 530), # Nivel 11: Estación Multi-GPU CAD
		Vector2(1130, 420) # Nivel 12: Jefe de Taller Supreme
	],
	# 2. SISTEMA: Red lógica digital con diamantes y bucles de kernel
	"sistema": [
		Vector2(110, 340), # Nivel 1: Cold Boot POST
		Vector2(150, 540), # Nivel 2: Diagnósticos de Firmware
		Vector2(290, 420), # Nivel 3: BIOS / UEFI Flash
		Vector2(420, 270), # Nivel 4: Claves Secure Boot
		Vector2(440, 580), # Nivel 5: Tabla de Particiones GPT
		Vector2(560, 410), # Nivel 6: Cargador GRUB / BCD
		Vector2(700, 290), # Nivel 7: Kernel Ring 0 & Drivers
		Vector2(720, 530), # Nivel 8: Aislamiento Malware Sandbox
		Vector2(850, 410), # Nivel 9: Registro HKLM & Servicios
		Vector2(970, 270), # Nivel 10: Protección ASLR
		Vector2(1000, 570), # Nivel 11: Rescate Forense BitLocker
		Vector2(1140, 420) # Nivel 12: SysAdmin Cloud Master
	],
	# 3. SERVIDOR: Matriz de alta densidad en racks y enlaces mallados
	"servidor": [
		Vector2(120, 280), # Nivel 1: Bastidor 1U
		Vector2(130, 440), # Nivel 2: Servidor Blade 2U
		Vector2(140, 600), # Nivel 3: Cabina Almacenamiento 4U
		Vector2(290, 440), # Nivel 4: PDU Redundante
		Vector2(440, 310), # Nivel 5: Fibra SAN Fabric
		Vector2(480, 560), # Nivel 6: SAS Hot-Swap RAID
		Vector2(620, 440), # Nivel 7: Switch Top-of-Rack 100G
		Vector2(760, 290), # Nivel 8: Trunking VLAN LACP
		Vector2(790, 580), # Nivel 9: Confinamiento Pasillo Frío
		Vector2(920, 440), # Nivel 10: Clúster Alta Disponibilidad
		Vector2(1040, 310), # Nivel 11: Pool Live Migration
		Vector2(1130, 510) # Nivel 12: Centro NOC Datacenter
	]
}

var MODE_CONNECTIONS: Dictionary = {
	"reparacion": [
		Vector2i(0, 1), Vector2i(0, 2),
		Vector2i(1, 3), Vector2i(2, 3),
		Vector2i(3, 4), Vector2i(3, 5),
		Vector2i(4, 6), Vector2i(5, 7),
		Vector2i(6, 8), Vector2i(7, 8),
		Vector2i(8, 9), Vector2i(8, 10),
		Vector2i(9, 11), Vector2i(10, 11),
		Vector2i(4, 8), Vector2i(6, 9)
	],
	"sistema": [
		Vector2i(0, 2), Vector2i(1, 2),
		Vector2i(2, 3), Vector2i(2, 4),
		Vector2i(3, 5), Vector2i(4, 5),
		Vector2i(5, 6), Vector2i(5, 7),
		Vector2i(6, 8), Vector2i(7, 8),
		Vector2i(8, 9), Vector2i(8, 10),
		Vector2i(9, 11), Vector2i(10, 11),
		Vector2i(6, 9), Vector2i(7, 10)
	],
	"servidor": [
		Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3),
		Vector2i(3, 4), Vector2i(3, 5),
		Vector2i(4, 6), Vector2i(5, 6),
		Vector2i(6, 7), Vector2i(6, 8),
		Vector2i(7, 9), Vector2i(8, 9),
		Vector2i(9, 10), Vector2i(9, 11),
		Vector2i(10, 11)
	]
}

var nodes: Array[Vector2] = []

func _ready() -> void:
	_update_nodes_for_mode()
	_init_cyber_fx()

func set_mode(new_mode: String) -> void:
	transition_to_mode(new_mode)

func transition_to_mode(new_mode: String) -> void:
	if not MODE_NODES.has(new_mode):
		return
	if current_mode == new_mode and nodes.size() == 12:
		return
		
	# Guardar posiciones actuales para el morphing
	previous_mode = current_mode
	transition_start_nodes.clear()
	for pt in nodes:
		transition_start_nodes.append(pt)
		
	current_mode = new_mode
	
	transition_target_nodes.clear()
	var raw_targets = MODE_NODES.get(current_mode, [])
	for pt in raw_targets:
		transition_target_nodes.append(pt as Vector2)
		
	if transition_start_nodes.size() != transition_target_nodes.size():
		transition_start_nodes = transition_target_nodes.duplicate()
		nodes = transition_target_nodes.duplicate()
		_rebuild_dynamic_traces()
		return
		
	# Iniciar micro-animación de transición fluida de nodos
	is_transitioning = true
	transition_progress = 0.0
	mode_switch_pulse = 1.0
	mode_transition_started.emit()
	
	var tw = create_tween().set_parallel(true)
	tw.tween_method(func(val: float):
		transition_progress = val
		for i in range(nodes.size()):
			# Interpolación elástica suave entre constelaciones
			nodes[i] = transition_start_nodes[i].lerp(transition_target_nodes[i], val)
		# Reconstruir las pistas de fondo de forma 100% síncrona en cada frame del morphing
		_rebuild_dynamic_traces()
		queue_redraw()
	, 0.0, 1.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	tw.tween_property(self, "mode_switch_pulse", 0.0, 0.55).set_ease(Tween.EASE_OUT)
	
	tw.chain().tween_callback(func():
		is_transitioning = false
		_update_nodes_for_mode()
		_rebuild_dynamic_traces()
		mode_transition_completed.emit()
		queue_redraw()
	)

func _update_nodes_for_mode() -> void:
	nodes.clear()
	var raw_list = MODE_NODES.get(current_mode, [])
	for pt in raw_list:
		nodes.append(pt as Vector2)

func _rebuild_dynamic_traces() -> void:
	if nodes.size() < 12:
		return
	var w = size.x if size.x > 100 else 1280.0

	# Pistas dinámicas generadas estrictamente desde los puntos de la constelación actual
	var raw_traces: Array[PackedVector2Array] = [
		# 1. Bus superior síncrono que pasa exactamente por los nodos superiores (1, 4, 9)
		PackedVector2Array([
			Vector2(30, nodes[1].y),
			Vector2(nodes[1].x * 0.5, nodes[1].y),
			nodes[1],
			nodes[4],
			nodes[9],
			Vector2(lerp(nodes[9].x, w - 30.0, 0.5), nodes[9].y),
			Vector2(w - 30, nodes[9].y)
		]),
		# 2. Bus inferior síncrono que pasa exactamente por los nodos inferiores (2, 7, 10)
		PackedVector2Array([
			Vector2(30, nodes[2].y),
			Vector2(nodes[2].x * 0.5, nodes[2].y),
			nodes[2],
			nodes[7],
			nodes[10],
			Vector2(lerp(nodes[10].x, w - 30.0, 0.5), nodes[10].y),
			Vector2(w - 30, nodes[10].y)
		]),
		# 3. Troncal central síncrono que cruza los nodos (0, 3, 6, 8, 11)
		PackedVector2Array([
			Vector2(20, nodes[0].y),
			nodes[0],
			nodes[3],
			nodes[6],
			nodes[8],
			nodes[11],
			Vector2(w - 20, nodes[11].y)
		]),
		# 4. Enlace transversal síncrono entre ramas
		PackedVector2Array([
			nodes[1],
			Vector2((nodes[1].x + nodes[5].x) * 0.5, (nodes[1].y + nodes[5].y) * 0.5),
			nodes[5],
			nodes[8],
			nodes[10]
		])
	]

	while circuit_traces.size() < raw_traces.size():
		circuit_traces.append(CircuitTrace.new(PackedVector2Array()))

	for i in range(raw_traces.size()):
		var trace = circuit_traces[i]
		trace.points = raw_traces[i]
		trace.total_length = 0.0
		trace.segment_lengths.clear()
		for j in range(trace.points.size() - 1):
			var d = trace.points[j].distance_to(trace.points[j + 1])
			trace.segment_lengths.append(d)
			trace.total_length += d

func _init_cyber_fx() -> void:
	circuit_traces.clear()
	data_pulses.clear()
	cyber_motes.clear()
	
	_rebuild_dynamic_traces()

	var rng = RandomNumberGenerator.new()
	rng.randomize()

	var pulse_colors: Array[Color] = [
		Color(1.0, 0.08, 0.25, 0.95),  # Neón Rojo Carmesí
		Color(0.85, 0.1, 0.98, 0.95),  # Neón Morado Eléctrico
		Color(1.0, 0.3, 0.65, 0.90)    # Fucsia Neón
	]

	for i in range(16):
		var p = DataPulse.new()
		p.trace_index = i % circuit_traces.size()
		p.progress = rng.randf()
		p.speed = rng.randf_range(0.14, 0.28)
		p.color = pulse_colors[i % pulse_colors.size()]
		p.size = rng.randf_range(2.8, 4.0)
		p.tail_length = rng.randf_range(35.0, 55.0)
		data_pulses.append(p)

	var w = size.x if size.x > 100 else 1280.0
	var h = size.y if size.y > 50 else 720.0
	for i in range(32):
		var m = CyberMote.new()
		m.pos = Vector2(rng.randf_range(20.0, w - 20.0), rng.randf_range(110.0, h - 60.0))
		m.drift = Vector2(rng.randf_range(-14.0, 14.0), rng.randf_range(-8.0, 8.0))
		m.size = rng.randf_range(1.3, 2.6)
		m.base_alpha = rng.randf_range(0.2, 0.55)
		m.phase = rng.randf_range(0.0, TAU)
		m.pulse_speed = rng.randf_range(1.5, 3.2)
		m.color = pulse_colors[rng.randi_range(0, pulse_colors.size() - 1)]
		cyber_motes.append(m)

	initialized_fx = true

func _process(delta: float) -> void:
	anim_offset += delta * 2.2

	if not initialized_fx:
		_init_cyber_fx()

	var w = size.x if size.x > 100 else 1280.0
	var h = size.y if size.y > 50 else 720.0

	# Si no está en transición, asegurar que las pistas dinámicas sigan los nodos
	if not is_transitioning:
		_rebuild_dynamic_traces()

	# Detección de hover sobre cualquiera de los 12 nodos
	var mouse_pos = get_local_mouse_position()
	hovered_node_index = -1
	for i in range(nodes.size()):
		if mouse_pos.distance_to(nodes[i]) <= 30.0:
			hovered_node_index = i
			break

	for p in data_pulses:
		p.progress += p.speed * delta
		if p.progress > 1.0:
			p.progress -= 1.0

	for m in cyber_motes:
		m.pos += m.drift * delta
		if m.pos.x < 0.0: m.pos.x += w
		elif m.pos.x > w: m.pos.x -= w
		if m.pos.y < 90.0: m.pos.y += (h - 110.0)
		elif m.pos.y > h: m.pos.y -= (h - 110.0)

	queue_redraw()

func _draw() -> void:
	var w = size.x if size.x > 100 else 1280.0
	var h = size.y if size.y > 50 else 720.0
	var font = ThemeDB.fallback_font

	# =========================================================================
	# 1. GUÍAS Y RETÍCULA TÉCNICA ANCLADAS A LOS NODOS EN TIEMPO REAL
	# =========================================================================
	var grid_step = 48.0
	var grid_color = Color(0.85, 0.05, 0.35, 0.05)
	var cross_len = 3.0
	var x_steps = int(w / grid_step) + 1
	var y_steps = int(h / grid_step) + 1
	for xi in range(x_steps):
		var gx = xi * grid_step
		for yi in range(y_steps):
			var gy = yi * grid_step
			draw_line(Vector2(gx - cross_len, gy), Vector2(gx + cross_len, gy), grid_color, 1.0)
			draw_line(Vector2(gx, gy - cross_len), Vector2(gx, gy + cross_len), grid_color, 1.0)

	# Líneas de referencia CAD síncronas que se proyectan directamente desde los nodos
	for np in nodes:
		draw_line(Vector2(np.x, np.y - 32), Vector2(np.x, np.y + 32), Color(0.85, 0.1, 0.45, 0.15), 1.0)
		draw_line(Vector2(np.x - 32, np.y), Vector2(np.x + 32, np.y), Color(0.85, 0.1, 0.45, 0.15), 1.0)

	# =========================================================================
	# 2. ONDA DE CHOQUE HOLOGRÁFICA AL CAMBIAR DE MODO
	# =========================================================================
	if mode_switch_pulse > 0.01:
		var wave_center = Vector2(w * 0.5, h * 0.5)
		var wave_radius = (1.0 - mode_switch_pulse) * (w * 0.7)
		var wave_alpha = mode_switch_pulse * 0.4
		draw_arc(wave_center, wave_radius, 0, TAU, 64, Color(1.0, 0.1, 0.4, wave_alpha), 3.0)
		draw_arc(wave_center, wave_radius * 0.85, 0, TAU, 48, Color(0.8, 0.1, 1.0, wave_alpha * 0.7), 2.0)

	# =========================================================================
	# 3. BARRIDO DE ESCÁNER VERTICAL
	# =========================================================================
	var scan_norm = fmod(anim_offset * 0.45, 8.0) / 8.0
	var scan_x = scan_norm * (w + 200.0) - 100.0
	if scan_x >= -80.0 and scan_x <= w + 80.0:
		draw_line(Vector2(scan_x, 100), Vector2(scan_x, h - 50), Color(1.0, 0.1, 0.3, 0.18), 1.5)

	# =========================================================================
	# 4. PISTAS DE CIRCUITO IMPRESO SÍNCRONAS (ATRAVIESAN LOS NODOS EN VIVO)
	# =========================================================================
	for trace in circuit_traces:
		if trace.points.size() >= 2:
			# Glow exterior en púrpura
			draw_polyline(trace.points, Color(0.8, 0.05, 0.3, 0.12), 4.5, false)
			# Pista de neón interna
			draw_polyline(trace.points, Color(0.65, 0.05, 0.85, 0.32), 1.8, false)
			# Vías de interconexión en cada vértice
			for pt in trace.points:
				draw_circle(pt, 2.5, Color(1.0, 0.1, 0.3, 0.4))
				draw_circle(pt, 1.2, Color(0.06, 0.015, 0.12, 0.95))

	# =========================================================================
	# 5. PULSOS DE DATOS VIAJANDO POR LAS PISTAS SÍNCRONAS
	# =========================================================================
	for p in data_pulses:
		if p.trace_index < circuit_traces.size():
			var trace = circuit_traces[p.trace_index]
			if trace.total_length > 0.0:
				var head_dist = p.progress * trace.total_length
				var head_pos = trace.get_point_at_distance(head_dist)
				draw_circle(head_pos, p.size * 2.0, Color(p.color.r, p.color.g, p.color.b, 0.28))
				draw_circle(head_pos, p.size, p.color)

	# =========================================================================
	# 6. ENLACES ENTRE NODOS (SÍNCRONOS Y CON MORPHING FLUIDO)
	# =========================================================================
	if is_transitioning and previous_mode != current_mode:
		var old_conns = MODE_CONNECTIONS.get(previous_mode, [])
		var old_alpha = (1.0 - transition_progress) * 0.45
		for conn in old_conns:
			if conn.x < nodes.size() and conn.y < nodes.size():
				_draw_circuit_line(nodes[conn.x], nodes[conn.y], old_alpha, conn.x + conn.y)

		var new_conns = MODE_CONNECTIONS.get(current_mode, [])
		var new_alpha = transition_progress * 0.55
		for conn in new_conns:
			if conn.x < nodes.size() and conn.y < nodes.size():
				_draw_circuit_line(nodes[conn.x], nodes[conn.y], new_alpha, conn.x + conn.y)
	else:
		var conns = MODE_CONNECTIONS.get(current_mode, MODE_CONNECTIONS["reparacion"])
		for conn in conns:
			if conn.x < nodes.size() and conn.y < nodes.size():
				_draw_circuit_line(nodes[conn.x], nodes[conn.y], 0.55, conn.x + conn.y)

	# =========================================================================
	# 7. POLVO DIGITAL AMBIENTAL
	# =========================================================================
	for m in cyber_motes:
		draw_circle(m.pos, m.size, m.color)

	# =========================================================================
	# 8. RENDERIZADO DE LOS 12 NODOS CON MICRO-ANIMACIONES CIBERNÉTICAS
	# =========================================================================
	for i in range(nodes.size()):
		var np = nodes[i]
		var is_hovered = (hovered_node_index == i)
		# SOLO el nivel de reparación (Nivel 1, índice 0) está en ROJO indicando que está disponible para jugar
		var is_playable = (i == 0 and (current_mode == "reparacion" or current_mode == "sistema"))
		var zoom_scale = node_zoom_scales[i] if i < node_zoom_scales.size() else 1.0
		var ripple = node_ripples[i] if i < node_ripples.size() else 0.0

		# --- MICRO-ANIMACIÓN A: Pulso de Respiración del Núcleo escalado por Zoom ---
		var node_phase = float(i) * 0.52
		var core_breath = sin(anim_offset * 3.0 + node_phase) * 0.5 + 0.5
		var base_radius = (21.0 + core_breath * 2.2) if not is_hovered else 25.0
		var breath_radius = base_radius * zoom_scale

		# --- MICRO-ANIMACIÓN ZOOM ONDA EXPANSIVA (RIPPLE AL PRESIONAR) ---
		if ripple > 0.01:
			var rip_r = lerp(26.0, 68.0, 1.0 - ripple) * zoom_scale
			var rip_a = ripple * 0.85
			var rip_col = Color(1.0, 0.08, 0.25, rip_a) if is_playable else Color(0.2, 0.85, 1.0, rip_a)
			draw_arc(np, rip_r, 0, TAU, 32, rip_col, 2.6)

		# --- Zócalo base en la placa ---
		var socket_bg = Color(0.8, 0.05, 0.22, 0.16) if is_playable else Color(0.12, 0.3, 0.48, 0.08)
		var socket_arc = Color(1.0, 0.08, 0.25, 0.55) if is_playable else Color(0.22, 0.42, 0.6, 0.32)
		draw_circle(np, 32.0 * zoom_scale, socket_bg)
		draw_arc(np, 28.0 * zoom_scale, 0, TAU, 32, socket_arc, 1.5)

		# --- MICRO-ANIMACIÓN B: Marcas cardinales tácticas que oscilan con Zoom ---
		var tick_offset = (32.0 + core_breath * 2.0) * zoom_scale
		var tick_col = Color(1.0, 0.1, 0.28, 0.85) if is_playable else Color(0.25, 0.5, 0.68, 0.38)
		draw_line(np + Vector2(-tick_offset, 0), np + Vector2(-tick_offset + 5 * zoom_scale, 0), tick_col, 1.5)
		draw_line(np + Vector2(tick_offset - 5 * zoom_scale, 0), np + Vector2(tick_offset, 0), tick_col, 1.5)
		draw_line(np + Vector2(0, -tick_offset), np + Vector2(0, -tick_offset + 5 * zoom_scale), tick_col, 1.5)
		draw_line(np + Vector2(0, tick_offset - 5 * zoom_scale), np + Vector2(0, tick_offset), tick_col, 1.5)

		# --- MICRO-ANIMACIÓN C: Anillos segmentados rotatorios escalados con Zoom ---
		var rot_cw = anim_offset * (1.2 + float(i % 3) * 0.3)
		var rot_ccw = -anim_offset * (0.9 + float((i + 1) % 3) * 0.25)
		var ring_r1 = 25.5 * zoom_scale
		var ring_r2 = 23.0 * zoom_scale

		if is_playable:
			# ROJO RADIANTE (ÚNICO DISPONIBLE PARA JUGAR)
			draw_arc(np, ring_r1, rot_cw, rot_cw + PI * 0.45, 12, Color(1.0, 0.08, 0.25, 0.9), 1.8)
			draw_arc(np, ring_r1, rot_cw + PI * 0.7, rot_cw + PI * 1.15, 12, Color(1.0, 0.22, 0.38, 0.9), 1.8)
			draw_arc(np, ring_r1, rot_cw + PI * 1.4, rot_cw + PI * 1.85, 12, Color(1.0, 0.12, 0.28, 0.9), 1.8)

			draw_arc(np, ring_r2, rot_ccw, rot_ccw + PI * 0.6, 12, Color(1.0, 0.18, 0.35, 0.75), 1.4)
			draw_arc(np, ring_r2, rot_ccw + PI, rot_ccw + PI * 1.6, 12, Color(1.0, 0.28, 0.45, 0.75), 1.4)
		else:
			# COOL CYBER / AZUL ACERO OSCURO (BLOQUEADOS)
			draw_arc(np, ring_r1, rot_cw, rot_cw + PI * 0.45, 12, Color(0.25, 0.48, 0.65, 0.4), 1.4)
			draw_arc(np, ring_r1, rot_cw + PI * 0.7, rot_cw + PI * 1.15, 12, Color(0.2, 0.4, 0.58, 0.4), 1.4)
			draw_arc(np, ring_r1, rot_cw + PI * 1.4, rot_cw + PI * 1.85, 12, Color(0.28, 0.52, 0.7, 0.4), 1.4)

			draw_arc(np, ring_r2, rot_ccw, rot_ccw + PI * 0.6, 12, Color(0.18, 0.36, 0.52, 0.35), 1.2)
			draw_arc(np, ring_r2, rot_ccw + PI, rot_ccw + PI * 1.6, 12, Color(0.22, 0.42, 0.58, 0.35), 1.2)

		# --- Esfera de cristal oscuro central ---
		var crystal_col = Color(0.14, 0.015, 0.04, 0.98) if is_playable else Color(0.04, 0.03, 0.08, 0.96)
		draw_circle(np, breath_radius, crystal_col)

		# Borde de neón con colorimetría variable:
		# Si es jugable: ¡ROJO CIBERNÉTICO VIBRANTE!
		# Si está bloqueado: Azul/Cian acero tenue (o cian brillante en hover)
		var base_neon: Color
		if is_playable:
			base_neon = Color(1.0, 0.06, 0.22, 1.0).lerp(Color(1.0, 0.25, 0.4, 1.0), core_breath)
			if is_hovered:
				base_neon = Color(1.0, 0.45, 0.55, 1.0)
		else:
			base_neon = Color(0.22, 0.45, 0.62, 0.65).lerp(Color(0.18, 0.35, 0.52, 0.65), core_breath)
			if is_hovered:
				base_neon = Color(0.0, 1.0, 0.75, 1.0)

		draw_arc(np, breath_radius, 0, TAU, 32, base_neon, 2.5 if is_hovered or is_playable else 1.6)

		# Aura roja de halo exterior para el nivel jugable
		if is_playable:
			var halo_r = breath_radius + (3.2 + core_breath * 2.5) * zoom_scale
			draw_arc(np, halo_r, 0, TAU, 32, Color(1.0, 0.08, 0.25, 0.42 + core_breath * 0.25), 1.5)

		# --- ÍCONO CENTRAL (PLAY ▶ SI ES JUGABLE, CANDADO 🔒 SI ESTÁ BLOQUEADO) ---
		if is_playable:
			# Triángulo de Jugar ▶ en Rojo Neón / Blanco Brillante
			var tri_sz = 6.5 * zoom_scale
			var p_top = np + Vector2(-tri_sz * 0.65, -tri_sz)
			var p_bot = np + Vector2(-tri_sz * 0.65, tri_sz)
			var p_tip = np + Vector2(tri_sz * 1.1, 0.0)
			var tri_col = Color(1.0, 0.12, 0.28, 0.95) if not is_hovered else Color(1.0, 0.35, 0.48, 1.0)
			draw_colored_polygon([p_top, p_tip, p_bot], tri_col)
			draw_polyline([p_top, p_tip, p_bot, p_top], Color(1.0, 0.9, 0.95, 1.0), 1.3)
		else:
			# Candado Tecnológico Vectorial 🔒 en Azul Acero / Cian
			var lock_col = Color(0.4, 0.62, 0.78, 0.75) if not is_hovered else Color(0.0, 1.0, 0.75, 0.95)
			var lock_w = 12.0 * zoom_scale
			var lock_h = 9.0 * zoom_scale
			var lock_pos = Vector2(np.x - lock_w * 0.5, np.y - 1.5 * zoom_scale)
			draw_rect(Rect2(lock_pos.x, lock_pos.y, lock_w, lock_h), lock_col, false, 1.5)
			draw_arc(np + Vector2(0, -1.5 * zoom_scale), 4.2 * zoom_scale, PI, TAU, 14, lock_col, 1.5)

			# Ojo de cerradura
			draw_circle(np + Vector2(0, 2.0 * zoom_scale), 1.3 * zoom_scale, Color(0.04, 0.03, 0.08, 1.0))
			draw_line(np + Vector2(0, 2.0 * zoom_scale), np + Vector2(0, 5.0 * zoom_scale), Color(0.04, 0.03, 0.08, 1.0), 1.3)

		# --- Número de nivel con halo superior ---
		var lvl_str = str(i + 1)
		var num_color: Color
		if is_playable:
			num_color = Color(1.0, 0.92, 0.95, 1.0)
		elif is_hovered:
			num_color = Color.WHITE
		else:
			num_color = Color(0.55, 0.7, 0.82, 0.75)
			
		draw_string(font, np + Vector2(-4, -28 * zoom_scale), lvl_str, HORIZONTAL_ALIGNMENT_CENTER, -1, int(12 * zoom_scale), num_color)

		# --- MICRO-ANIMACIÓN E: Corchetes Tácticos de Selección en Hover ---
		if is_hovered:
			var b_dist = (33.0 + core_breath * 2.0) * zoom_scale
			var b_sz = 9.0 * zoom_scale
			var b_col = Color(1.0, 0.2, 0.35, 0.95) if is_playable else Color(0.0, 1.0, 0.8, 0.95)
			# ⌜
			draw_line(np + Vector2(-b_dist, -b_dist), np + Vector2(-b_dist + b_sz, -b_dist), b_col, 2.2)
			draw_line(np + Vector2(-b_dist, -b_dist), np + Vector2(-b_dist, -b_dist + b_sz), b_col, 2.2)
			# ⌝
			draw_line(np + Vector2(b_dist, -b_dist), np + Vector2(b_dist - b_sz, -b_dist), b_col, 2.2)
			draw_line(np + Vector2(b_dist, -b_dist), np + Vector2(b_dist, -b_dist + b_sz), b_col, 2.2)
			# ⌞
			draw_line(np + Vector2(-b_dist, b_dist), np + Vector2(-b_dist + b_sz, b_dist), b_col, 2.2)
			draw_line(np + Vector2(-b_dist, b_dist), np + Vector2(-b_dist, b_dist - b_sz), b_col, 2.2)
			# ⌟
			draw_line(np + Vector2(b_dist, b_dist), np + Vector2(b_dist - b_sz, b_dist), b_col, 2.2)
			draw_line(np + Vector2(b_dist, b_dist), np + Vector2(b_dist, b_dist - b_sz), b_col, 2.2)

			# Onda expansiva en hover
			var ripple_t = fmod(anim_offset * 1.5, 1.0)
			var ripple_r = lerp(26.0, 48.0, ripple_t) * zoom_scale
			var ripple_a = (1.0 - ripple_t) * 0.4
			draw_arc(np, ripple_r, 0, TAU, 32, b_col, 1.5)

func _draw_circuit_line(p1: Vector2, p2: Vector2, alpha: float, seed_val: int) -> void:
	# Glow exterior amplio en púrpura neón
	draw_line(p1, p2, Color(0.48, 0.05, 0.70, 0.28 * alpha), 4.5)
	# Pista central de cobre iluminado en rojo carmesí
	draw_line(p1, p2, Color(1.0, 0.12, 0.38, alpha), 1.8)
	
	# Micro-paquete de energía que viaja por el enlace
	var packet_t = fmod(anim_offset * 0.75 + float(seed_val) * 0.14, 1.0)
	var packet_pos = p1.lerp(p2, packet_t)
	draw_circle(packet_pos, 2.6, Color(1.0, 0.3, 0.65, min(1.0, alpha * 1.6)))
	draw_circle(packet_pos, 1.2, Color(1.0, 1.0, 1.0, min(1.0, alpha * 1.6)))
