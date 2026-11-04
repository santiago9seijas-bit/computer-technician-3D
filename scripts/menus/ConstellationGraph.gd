@tool
extends Control

# =============================================================================
# CONSTELLATION GRAPH - TELARAÑA HOLOGRÁFICA CIBERNÉTICA CON NÚCLEO TUTORIAL
# 13 NODOS DINÁMICOS: NODO CENTRAL (TUTORIAL AZUL), RAÍCES Y NIVELES 1-12
# DISTRIBUCIÓN GEOMÉTRICA ARMONIOSA Y ANIMACIONES DIFERENCIADAS DE ALTO IMPACTO
# =============================================================================

signal mode_transition_started()
signal mode_transition_completed()

var anim_offset: float = 0.0
var hovered_node_index: int = -1
var current_mode: String = "reparacion"
var previous_mode: String = "reparacion"

# Micro-animación de transición de modo (Morphing dinámico y único por telaraña)
var is_transitioning: bool = false
var transition_progress: float = 1.0 # 0.0 a 1.0
var transition_type: String = "shockwave_burst"
var transition_start_nodes: Array[Vector2] = []
var transition_target_nodes: Array[Vector2] = []
var mode_switch_pulse: float = 0.0
var transition_sweep_angle: float = 0.0

# Micro-animación de zoom táctil sobre los círculos de nivel (13 nodos)
var node_zoom_scales: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
var node_ripples: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
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
# CIRCUITOS, FILAMENTOS Y PULSOS DE TELARAÑA
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
# DISTRIBUCIONES GEOMÉTRICAS OPTIMIZADAS DE TELARAÑA (13 NODOS POR MODO)
# NÚCLEO CENTRAL = VECTOR2(640, 395)
# RAÍZ PRINCIPAL AL NIVEL 1 EN EL OESTE/NOROESTE CONECTADA DIRECTA AL NÚCLEO
# =============================================================================
var MODE_NODES: Dictionary = {
	# 1. REPARACIÓN: Telaraña Octagonal de Hardware y Placa Madre
	"reparacion": [
		Vector2(640, 395), # [0] TUTORIAL: Núcleo Central de Inducción Técnica (AZUL)
		Vector2(500, 395), # [1] NIVEL 1: Montaje Fan Cooler (Raíz Primaria Oeste, ROJO)
		Vector2(640, 255), # [2] NIVEL 2: Diagnóstico Banco RAM (Spoke Norte)
		Vector2(780, 395), # [3] NIVEL 3: Unidad SATA y Buses (Spoke Este)
		Vector2(640, 535), # [4] NIVEL 4: Pasta Térmica CPU (Spoke Sur)
		Vector2(385, 395), # [5] NIVEL 5: Tarjeta Gráfica PCIe (Anillo Medio Oeste)
		Vector2(820, 215), # [6] NIVEL 6: Bahía M.2 NVMe (Anillo Medio Noreste)
		Vector2(460, 575), # [7] NIVEL 7: Fuente de Poder ATX (Anillo Medio Suroeste)
		Vector2(820, 575), # [8] NIVEL 8: Módulos VRM MOSFETs (Anillo Medio Sureste)
		Vector2(378, 135), # [9] NIVEL 9: Refrigeración Líquida (Anillo Exterior Noroeste)
		Vector2(640, 125), # [10] NIVEL 10: Multímetro y Cortos (Anillo Exterior Norte)
		Vector2(240, 560), # [11] NIVEL 11: Estación Multi-GPU (Anillo Exterior Suroeste)
		Vector2(1040, 395) # [12] NIVEL 12: Jefe de Taller Supreme (Vértice Maestro Este)
	],
	# 2. SISTEMA: Telaraña de Diamante Cibernético y Matriz de Kernel
	"sistema": [
		Vector2(640, 395), # [0] TUTORIAL: Núcleo Central de Boot & BIOS (AZUL)
		Vector2(537, 292), # [1] NIVEL 1: Cold Boot POST (Raíz Primaria Noroeste, ROJO)
		Vector2(743, 292), # [2] NIVEL 2: Firmware Diagnostics (Raíz Noreste)
		Vector2(743, 498), # [3] NIVEL 3: BIOS Flash (Raíz Sureste)
		Vector2(537, 498), # [4] NIVEL 4: Secure Boot (Raíz Suroeste)
		Vector2(640, 145), # [5] NIVEL 5: Tabla GPT (Ápice Medio Norte)
		Vector2(890, 395), # [6] NIVEL 6: Cargador GRUB/BCD (Ápice Medio Este)
		Vector2(640, 645), # [7] NIVEL 7: Kernel Ring 0 (Ápice Medio Sur)
		Vector2(390, 395), # [8] NIVEL 8: Sandbox Malware (Ápice Medio Oeste)
		Vector2(382, 137), # [9] NIVEL 9: Registro HKLM (Vértice Exterior Noroeste)
		Vector2(898, 137), # [10] NIVEL 10: Protección ASLR (Vértice Exterior Noreste)
		Vector2(898, 653), # [11] NIVEL 11: Rescate BitLocker (Vértice Exterior Sureste)
		Vector2(382, 653)  # [12] NIVEL 12: SysAdmin Master (Vértice Exterior Suroeste)
	],
	# 3. SERVIDOR: Hiper-Malla Circular de Datacenter y Anillos de Fibra Óptica
	"servidor": [
		Vector2(640, 395), # [0] TUTORIAL: Núcleo Central de Infraestructura 1U (AZUL)
		Vector2(500, 395), # [1] NIVEL 1: Bastidor 1U (Raíz Primaria Oeste 9h, ROJO)
		Vector2(570, 274), # [2] NIVEL 2: Servidor Blade 2U (Radio 11h)
		Vector2(710, 274), # [3] NIVEL 3: Cabina 4U SAN (Radio 1h)
		Vector2(780, 395), # [4] NIVEL 4: PDU Redundante (Radio 3h)
		Vector2(710, 516), # [5] NIVEL 5: Fibra SAN Fabric (Radio 5h)
		Vector2(570, 516), # [6] NIVEL 6: SAS Hot-Swap RAID (Radio 7h)
		Vector2(345, 225), # [7] NIVEL 7: Switch ToR 100G (Anillo Exterior 10h)
		Vector2(640, 135), # [8] NIVEL 8: Trunking VLAN LACP (Anillo Exterior 12h)
		Vector2(935, 225), # [9] NIVEL 9: Pasillo Frío (Anillo Exterior 2h)
		Vector2(1020, 395),# [10] NIVEL 10: Clúster HA (Anillo Exterior 4h)
		Vector2(640, 655), # [11] NIVEL 11: Live Migration (Anillo Exterior 6h)
		Vector2(260, 395)  # [12] NIVEL 12: Centro NOC Datacenter (Anillo Exterior 8h)
	]
}

# Conexiones estructuradas de telaraña: Núcleo Central -> Raíces -> Anillos -> Vértices
var MODE_CONNECTIONS: Dictionary = {
	"reparacion": [
		# Raíces directas desde el núcleo tutorial (0)
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4),
		# Anillo de telaraña interno
		Vector2i(1, 2), Vector2i(2, 3), Vector2i(3, 4), Vector2i(4, 1),
		# Filamentos radiales de conexión a anillo medio
		Vector2i(1, 5), Vector2i(2, 6), Vector2i(3, 6), Vector2i(3, 8),
		Vector2i(4, 7), Vector2i(4, 8), Vector2i(5, 7),
		# Anillo de telaraña medio
		Vector2i(5, 6), Vector2i(6, 8), Vector2i(8, 7), Vector2i(7, 5),
		# Filamentos hacia anillo exterior
		Vector2i(5, 9), Vector2i(2, 10), Vector2i(6, 10), Vector2i(7, 11),
		Vector2i(6, 12), Vector2i(8, 12),
		# Perímetro de telaraña exterior
		Vector2i(9, 10), Vector2i(9, 11), Vector2i(10, 12), Vector2i(11, 7)
	],
	"sistema": [
		# Raíces directas desde el núcleo tutorial (0)
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4),
		# Diamante de telaraña interno
		Vector2i(1, 2), Vector2i(2, 3), Vector2i(3, 4), Vector2i(4, 1),
		# Filamentos radiales a ápices de diamante medio
		Vector2i(1, 5), Vector2i(2, 5), Vector2i(2, 6), Vector2i(3, 6),
		Vector2i(3, 7), Vector2i(4, 7), Vector2i(4, 8), Vector2i(1, 8),
		# Diamante de telaraña medio
		Vector2i(5, 6), Vector2i(6, 7), Vector2i(7, 8), Vector2i(8, 5),
		# Filamentos hacia matriz exterior
		Vector2i(8, 9), Vector2i(5, 9), Vector2i(5, 10), Vector2i(6, 10),
		Vector2i(6, 11), Vector2i(7, 11), Vector2i(7, 12), Vector2i(8, 12),
		# Perímetro de telaraña exterior
		Vector2i(9, 10), Vector2i(10, 11), Vector2i(11, 12), Vector2i(12, 9)
	],
	"servidor": [
		# Raíces orbitales directas desde el núcleo tutorial (0)
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3),
		Vector2i(0, 4), Vector2i(0, 5), Vector2i(0, 6),
		# Anillo de telaraña circular interno
		Vector2i(1, 2), Vector2i(2, 3), Vector2i(3, 4),
		Vector2i(4, 5), Vector2i(5, 6), Vector2i(6, 1),
		# Radios de fibra hacia anillo exterior
		Vector2i(1, 12), Vector2i(2, 7), Vector2i(2, 8), Vector2i(3, 8),
		Vector2i(3, 9), Vector2i(4, 10), Vector2i(5, 11), Vector2i(6, 11),
		Vector2i(1, 7), Vector2i(6, 12),
		# Malla perimetral exterior
		Vector2i(12, 7), Vector2i(7, 8), Vector2i(8, 9), Vector2i(9, 10),
		Vector2i(10, 11), Vector2i(11, 12), Vector2i(10, 5), Vector2i(11, 6)
	]
}

var nodes: Array[Vector2] = []

func _ready() -> void:
	_update_nodes_for_mode()
	_init_cyber_fx()

func transition_to_mode(new_mode: String) -> void:
	if not MODE_NODES.has(new_mode):
		return
	if current_mode == new_mode and nodes.size() == 13:
		return
		
	previous_mode = current_mode
	transition_start_nodes.clear()
	for pt in nodes:
		transition_start_nodes.append(pt)
		
	current_mode = new_mode
	
	match new_mode:
		"reparacion":
			transition_type = "shockwave_burst" # Onda expansiva elástica con impacto de hardware
		"sistema":
			transition_type = "matrix_spiral"   # Vórtex espiral de código y diamante
		"servidor":
			transition_type = "quantum_sweep"   # Enrutamiento ortogonal y barrido radar 360°
		_:
			transition_type = "shockwave_burst"
	
	transition_target_nodes.clear()
	var raw_targets = MODE_NODES.get(current_mode, [])
	for pt in raw_targets:
		transition_target_nodes.append(pt as Vector2)
		
	if transition_start_nodes.size() != transition_target_nodes.size():
		transition_start_nodes = transition_target_nodes.duplicate()
		nodes = transition_target_nodes.duplicate()
		_rebuild_dynamic_traces()
		return
		
	# Iniciar micro-animación de transición fluida y diferenciada de alto impacto
	is_transitioning = true
	transition_progress = 0.0
	mode_switch_pulse = 1.0
	mode_transition_started.emit()
	
	var hub = Vector2(640, 395)
	var tw = create_tween().set_parallel(true)
	
	tw.tween_method(func(val: float):
		transition_progress = val
		transition_sweep_angle = val * TAU * 1.5
		
		for i in range(nodes.size()):
			var start_pt = transition_start_nodes[i]
			var target_pt = transition_target_nodes[i]
			
			if transition_type == "shockwave_burst":
				# ANIMACIÓN 1 (REPARACIÓN): Onda elástica radial suave en extremos
				var dir = (target_pt - hub).normalized()
				if dir == Vector2.ZERO:
					dir = Vector2.RIGHT
				var eased_t = Tween.interpolate_value(0.0, 1.0, val, 1.0, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
				var spring_rebound = sin(val * PI) * (1.0 - val * 0.6) * 28.0
				nodes[i] = start_pt.lerp(target_pt, eased_t) + dir * spring_rebound
				
			elif transition_type == "matrix_spiral":
				# ANIMACIÓN 2 (SISTEMA): Vórtex espiral polar ultrasuave sin saltos ni tirones
				var eased_t = Tween.interpolate_value(0.0, 1.0, val, 1.0, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
				var base_pos = start_pt.lerp(target_pt, eased_t)
				var rel = base_pos - hub
				# Envolvente seno: empieza en 0.0, describe un arco orbital suave en el centro, y termina en 0.0
				var swirl_angle = sin(val * PI) * 0.42 * (1.0 if (i % 2 == 0) else -1.0)
				nodes[i] = hub + rel.rotated(swirl_angle)
				
			elif transition_type == "quantum_sweep":
				# ANIMACIÓN 3 (SERVIDOR): Enrutamiento ortogonal suave con micro-frecuencia
				var eased_t = Tween.interpolate_value(0.0, 1.0, val, 1.0, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
				var mid_pt = Vector2(target_pt.x, start_pt.y) if (i % 2 == 0) else Vector2(start_pt.x, target_pt.y)
				var t1 = clamp(eased_t * 2.0, 0.0, 1.0)
				var t2 = clamp((eased_t - 0.5) * 2.0, 0.0, 1.0)
				var base_pos = start_pt.lerp(mid_pt, t1).lerp(target_pt, t2)
				var jitter = sin(val * PI) * (1.0 - val) * sin(val * 32.0 + float(i) * 1.5) * 7.0
				nodes[i] = base_pos + Vector2(jitter, -jitter * 0.4)
			else:
				nodes[i] = start_pt.lerp(target_pt, val)
				
		_rebuild_dynamic_traces()
		queue_redraw()
	, 0.0, 1.0, 0.62)
	
	tw.tween_property(self, "mode_switch_pulse", 0.0, 0.65).set_ease(Tween.EASE_OUT)
	
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
	if nodes.size() < 13:
		return
	var hub = nodes[0]

	# Pistas dinámicas generadas estrictamente desde los filamentos de la telaraña actual
	var raw_traces: Array[PackedVector2Array] = [
		# 1. Filamento Raíz Principal (Núcleo Tutorial -> Nivel 1 -> Ramas externas)
		PackedVector2Array([hub, nodes[1], nodes[5], nodes[9]]),
		# 2. Filamento Raíz Norte (Núcleo Tutorial -> Nivel 2 -> Nivel 10)
		PackedVector2Array([hub, nodes[2], nodes[10]]),
		# 3. Filamento Raíz Este (Núcleo Tutorial -> Nivel 3 -> Nivel 6 -> Nivel 12)
		PackedVector2Array([hub, nodes[3], nodes[6], nodes[12]]),
		# 4. Filamento Raíz Sur (Núcleo Tutorial -> Nivel 4 -> Nivel 7 -> Nivel 11)
		PackedVector2Array([hub, nodes[4], nodes[7], nodes[11]]),
		# 5. Anillo de Telaraña Interno cerrado
		PackedVector2Array([nodes[1], nodes[2], nodes[3], nodes[4], nodes[1]]),
		# 6. Anillo de Telaraña Medio cerrado
		PackedVector2Array([nodes[5], nodes[6], nodes[8], nodes[7], nodes[5]])
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
		Color(0.0, 0.9, 1.0, 0.95),    # Neón Azul Eléctrico (Tutorial)
		Color(1.0, 0.08, 0.28, 0.95),  # Neón Rojo Carmesí (Nivel 1)
		Color(0.85, 0.1, 0.98, 0.95),  # Neón Morado Eléctrico
		Color(0.2, 1.0, 0.75, 0.90)    # Turquesa Neón
	]

	for i in range(20):
		var p = DataPulse.new()
		p.trace_index = i % max(1, circuit_traces.size())
		p.progress = rng.randf()
		p.speed = rng.randf_range(0.18, 0.35)
		p.color = pulse_colors[i % pulse_colors.size()]
		p.size = rng.randf_range(2.8, 4.4)
		p.tail_length = rng.randf_range(30.0, 55.0)
		data_pulses.append(p)

	var w = size.x if size.x > 100 else 1280.0
	var h = size.y if size.y > 50 else 720.0
	for i in range(36):
		var m = CyberMote.new()
		m.pos = Vector2(rng.randf_range(20.0, w - 20.0), rng.randf_range(110.0, h - 60.0))
		m.drift = Vector2(rng.randf_range(-14.0, 14.0), rng.randf_range(-8.0, 8.0))
		m.size = rng.randf_range(1.3, 2.8)
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

	if not is_transitioning:
		_rebuild_dynamic_traces()

	# Detección de hover sobre cualquiera de los 13 nodos
	var mouse_pos = get_local_mouse_position()
	hovered_node_index = -1
	for i in range(nodes.size()):
		if mouse_pos.distance_to(nodes[i]) <= 32.0:
			hovered_node_index = i
			break

	# Acelerar los paquetes de datos durante la transición de telaraña ("data surge")
	var speed_mult = 2.4 if is_transitioning else 1.0
	for p in data_pulses:
		p.progress += p.speed * delta * speed_mult
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
	var hub = nodes[0] if not nodes.is_empty() else Vector2(640, 395)

	# =========================================================================
	# 1. FONDO DE TELARAÑA CIBERNÉTICA ARQUITECTÓNICA
	# =========================================================================
	_draw_spiderweb_background(w, h, hub)

	# =========================================================================
	# 2. MICRO-ANIMACIÓN DE TRANSICIÓN DIFERENCIADA POR MODO
	# =========================================================================
	if mode_switch_pulse > 0.01:
		_draw_transition_effect(hub, w, h)

	# =========================================================================
	# 3. PISTAS DE TELARAÑA Y FILAMENTOS DINÁMICOS
	# =========================================================================
	for trace in circuit_traces:
		if trace.points.size() >= 2:
			draw_polyline(trace.points, Color(0.1, 0.4, 0.8, 0.14) if current_mode != "reparacion" else Color(0.8, 0.05, 0.3, 0.12), 4.5, false)
			draw_polyline(trace.points, Color(0.0, 0.75, 0.95, 0.32) if current_mode != "reparacion" else Color(0.65, 0.05, 0.85, 0.32), 1.8, false)
			for pt in trace.points:
				draw_circle(pt, 2.5, Color(0.0, 0.85, 1.0, 0.4) if current_mode != "reparacion" else Color(1.0, 0.1, 0.3, 0.4))
				draw_circle(pt, 1.2, Color(0.02, 0.01, 0.05, 0.95))

	# =========================================================================
	# 4. PULSOS DE DATOS VIAJANDO POR LOS FILAMENTOS DE LA TELARAÑA
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
	# 5. ENLACES ESTRUCTURALES ENTRE NODOS DE LA TELARAÑA
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
				var is_primary_root = (conn.x == 0 and conn.y == 1) or (conn.x == 1 and conn.y == 0)
				var line_alpha = 0.95 if is_primary_root else 0.55
				_draw_circuit_line(nodes[conn.x], nodes[conn.y], line_alpha, conn.x + conn.y, is_primary_root)

	# =========================================================================
	# 6. POLVO DIGITAL AMBIENTAL
	# =========================================================================
	for m in cyber_motes:
		draw_circle(m.pos, m.size, m.color)

	# =========================================================================
	# 7. ESTELAS HOLOGRÁFICAS DE MOVIMIENTO EN TRANSICIÓN (DETALLITOS SCI-FI)
	# =========================================================================
	if is_transitioning and transition_start_nodes.size() == nodes.size():
		var trail_factor = sin(transition_progress * PI)
		for i in range(nodes.size()):
			var p_start = transition_start_nodes[i]
			var p_cur = nodes[i]
			var p_mid = p_start.lerp(p_cur, 0.55)
			var trail_col = Color(0.0, 0.88, 1.0, trail_factor * 0.35) if (current_mode == "sistema") else (Color(1.0, 0.15, 0.4, trail_factor * 0.35) if current_mode == "reparacion" else Color(0.2, 0.65, 1.0, trail_factor * 0.35))
			draw_line(p_start, p_cur, Color(trail_col.r, trail_col.g, trail_col.b, trail_factor * 0.22), 2.2)
			draw_circle(p_mid, 8.0 * trail_factor, Color(trail_col.r, trail_col.g, trail_col.b, trail_factor * 0.28))
			draw_circle(p_mid, 3.0 * trail_factor, Color.WHITE)

	# =========================================================================
	# 8. RENDERIZADO DE LOS 13 NODOS DE LA TELARAÑA
	# =========================================================================
	for i in range(nodes.size()):
		var np = nodes[i]
		var is_hovered = (hovered_node_index == i)
		var is_tutorial = (i == 0)
		var is_playable = (i == 1) # Nivel 1 es jugable en Rojo Carmesí
		var zoom_scale = node_zoom_scales[i] if i < node_zoom_scales.size() else 1.0
		var ripple = node_ripples[i] if i < node_ripples.size() else 0.0

		var node_phase = float(i) * 0.52
		var core_breath = sin(anim_offset * 3.0 + node_phase) * 0.5 + 0.5
		var base_radius = 26.0 if is_tutorial else (21.0 + core_breath * 2.2)
		if is_hovered:
			base_radius += 3.5
		var breath_radius = base_radius * zoom_scale

		# --- Onda expansiva (Ripple al hacer click) ---
		if ripple > 0.01:
			var rip_r = lerp(26.0, 72.0, 1.0 - ripple) * zoom_scale
			var rip_a = ripple * 0.85
			var rip_col: Color
			if is_tutorial:
				rip_col = Color(0.0, 0.88, 1.0, rip_a)
			elif is_playable:
				rip_col = Color(1.0, 0.08, 0.25, rip_a)
			else:
				rip_col = Color(0.2, 0.85, 1.0, rip_a)
			draw_arc(np, rip_r, 0, TAU, 32, rip_col, 2.6)

		# --- Zócalo base en la placa / telaraña ---
		var socket_bg: Color
		var socket_arc: Color
		if is_tutorial:
			socket_bg = Color(0.0, 0.35, 0.65, 0.22)
			socket_arc = Color(0.0, 0.88, 1.0, 0.75)
		elif is_playable:
			socket_bg = Color(0.8, 0.05, 0.22, 0.18)
			socket_arc = Color(1.0, 0.08, 0.25, 0.75)
		else:
			socket_bg = Color(0.12, 0.3, 0.48, 0.08)
			socket_arc = Color(0.22, 0.42, 0.6, 0.32)

		var socket_sz = (36.0 if is_tutorial else 32.0) * zoom_scale
		draw_circle(np, socket_sz, socket_bg)
		draw_arc(np, socket_sz - 4.0 * zoom_scale, 0, TAU, 32, socket_arc, 1.6)

		# --- Marcas cardinales tácticas que oscilan ---
		var tick_offset = (socket_sz + core_breath * 2.0)
		var tick_col: Color
		if is_tutorial:
			tick_col = Color(0.1, 0.95, 1.0, 0.95)
		elif is_playable:
			tick_col = Color(1.0, 0.15, 0.35, 0.9)
		else:
			tick_col = Color(0.25, 0.5, 0.68, 0.38)

		draw_line(np + Vector2(-tick_offset, 0), np + Vector2(-tick_offset + 5 * zoom_scale, 0), tick_col, 1.5)
		draw_line(np + Vector2(tick_offset - 5 * zoom_scale, 0), np + Vector2(tick_offset, 0), tick_col, 1.5)
		draw_line(np + Vector2(0, -tick_offset), np + Vector2(0, -tick_offset + 5 * zoom_scale), tick_col, 1.5)
		draw_line(np + Vector2(0, tick_offset - 5 * zoom_scale), np + Vector2(0, tick_offset), tick_col, 1.5)

		# --- Anillos segmentados rotatorios ---
		var rot_cw = anim_offset * (1.2 + float(i % 3) * 0.3)
		var rot_ccw = -anim_offset * (0.9 + float((i + 1) % 3) * 0.25)
		var ring_r1 = (28.0 if is_tutorial else 25.5) * zoom_scale
		var ring_r2 = (25.0 if is_tutorial else 23.0) * zoom_scale

		if is_tutorial:
			draw_arc(np, ring_r1, rot_cw, rot_cw + PI * 0.5, 14, Color(0.0, 0.9, 1.0, 0.95), 2.2)
			draw_arc(np, ring_r1, rot_cw + PI * 0.75, rot_cw + PI * 1.25, 14, Color(0.2, 0.75, 1.0, 0.95), 2.2)
			draw_arc(np, ring_r1, rot_cw + PI * 1.5, rot_cw + PI * 1.95, 14, Color(0.0, 1.0, 0.9, 0.95), 2.2)

			draw_arc(np, ring_r2, rot_ccw, rot_ccw + PI * 0.65, 14, Color(0.1, 0.85, 1.0, 0.8), 1.6)
			draw_arc(np, ring_r2, rot_ccw + PI * 1.05, rot_ccw + PI * 1.7, 14, Color(0.4, 0.95, 1.0, 0.8), 1.6)
		elif is_playable:
			draw_arc(np, ring_r1, rot_cw, rot_cw + PI * 0.45, 12, Color(1.0, 0.08, 0.25, 0.9), 1.8)
			draw_arc(np, ring_r1, rot_cw + PI * 0.7, rot_cw + PI * 1.15, 12, Color(1.0, 0.22, 0.38, 0.9), 1.8)
			draw_arc(np, ring_r1, rot_cw + PI * 1.4, rot_cw + PI * 1.85, 12, Color(1.0, 0.12, 0.28, 0.9), 1.8)

			draw_arc(np, ring_r2, rot_ccw, rot_ccw + PI * 0.6, 12, Color(1.0, 0.18, 0.35, 0.75), 1.4)
			draw_arc(np, ring_r2, rot_ccw + PI, rot_ccw + PI * 1.6, 12, Color(1.0, 0.28, 0.45, 0.75), 1.4)
		else:
			draw_arc(np, ring_r1, rot_cw, rot_cw + PI * 0.45, 12, Color(0.25, 0.48, 0.65, 0.4), 1.4)
			draw_arc(np, ring_r1, rot_cw + PI * 0.7, rot_cw + PI * 1.15, 12, Color(0.2, 0.4, 0.58, 0.4), 1.4)
			draw_arc(np, ring_r1, rot_cw + PI * 1.4, rot_cw + PI * 1.85, 12, Color(0.28, 0.52, 0.7, 0.4), 1.4)

			draw_arc(np, ring_r2, rot_ccw, rot_ccw + PI * 0.6, 12, Color(0.18, 0.36, 0.52, 0.35), 1.2)
			draw_arc(np, ring_r2, rot_ccw + PI, rot_ccw + PI * 1.6, 12, Color(0.22, 0.42, 0.58, 0.35), 1.2)

		# --- Esfera de cristal oscuro central ---
		var crystal_col: Color
		if is_tutorial:
			crystal_col = Color(0.015, 0.06, 0.15, 0.98)
		elif is_playable:
			crystal_col = Color(0.14, 0.015, 0.04, 0.98)
		else:
			crystal_col = Color(0.04, 0.03, 0.08, 0.96)
		draw_circle(np, breath_radius, crystal_col)

		# --- Borde de neón con halo ---
		var base_neon: Color
		if is_tutorial:
			base_neon = Color(0.0, 0.88, 1.0, 1.0).lerp(Color(0.3, 1.0, 1.0, 1.0), core_breath)
			if is_hovered:
				base_neon = Color(0.6, 1.0, 1.0, 1.0)
		elif is_playable:
			base_neon = Color(1.0, 0.06, 0.22, 1.0).lerp(Color(1.0, 0.25, 0.4, 1.0), core_breath)
			if is_hovered:
				base_neon = Color(1.0, 0.45, 0.55, 1.0)
		else:
			base_neon = Color(0.22, 0.45, 0.62, 0.65).lerp(Color(0.18, 0.35, 0.52, 0.65), core_breath)
			if is_hovered:
				base_neon = Color(0.0, 1.0, 0.75, 1.0)

		draw_arc(np, breath_radius, 0, TAU, 32, base_neon, 2.6 if (is_tutorial or is_playable or is_hovered) else 1.6)

		if is_tutorial:
			var halo_r = breath_radius + (4.0 + core_breath * 3.0) * zoom_scale
			draw_arc(np, halo_r, 0, TAU, 32, Color(0.0, 0.88, 1.0, 0.45 + core_breath * 0.3), 1.8)
		elif is_playable:
			var halo_r = breath_radius + (3.2 + core_breath * 2.5) * zoom_scale
			draw_arc(np, halo_r, 0, TAU, 32, Color(1.0, 0.08, 0.25, 0.42 + core_breath * 0.25), 1.5)

		# --- ÍCONO CENTRAL ---
		if is_tutorial:
			var em_col = Color(0.2, 0.95, 1.0, 0.98) if not is_hovered else Color.WHITE
			var sz = 7.5 * zoom_scale
			var p_top = np + Vector2(0, -sz * 0.9)
			var p_rt = np + Vector2(sz * 1.15, -sz * 0.2)
			var p_bot = np + Vector2(0, sz * 0.45)
			var p_lt = np + Vector2(-sz * 1.15, -sz * 0.2)
			draw_colored_polygon([p_top, p_rt, p_bot, p_lt], Color(0.0, 0.45, 0.75, 0.85))
			draw_polyline([p_top, p_rt, p_bot, p_lt, p_top], em_col, 1.4)
			draw_arc(np + Vector2(0, sz * 0.2), sz * 0.75, 0.15 * PI, 0.85 * PI, 10, em_col, 1.4)
			draw_line(p_rt, p_rt + Vector2(3.0 * zoom_scale, 6.0 * zoom_scale), em_col, 1.2)
			draw_circle(p_rt + Vector2(3.0 * zoom_scale, 6.0 * zoom_scale), 1.5 * zoom_scale, em_col)
		elif is_playable:
			var tri_sz = 6.8 * zoom_scale
			var p_top = np + Vector2(-tri_sz * 0.65, -tri_sz)
			var p_bot = np + Vector2(-tri_sz * 0.65, tri_sz)
			var p_tip = np + Vector2(tri_sz * 1.15, 0.0)
			var tri_col = Color(1.0, 0.12, 0.28, 0.95) if not is_hovered else Color(1.0, 0.35, 0.48, 1.0)
			draw_colored_polygon([p_top, p_tip, p_bot], tri_col)
			draw_polyline([p_top, p_tip, p_bot, p_top], Color(1.0, 0.92, 0.96, 1.0), 1.3)
		else:
			var lock_col = Color(0.4, 0.62, 0.78, 0.75) if not is_hovered else Color(0.0, 1.0, 0.75, 0.95)
			var lock_w = 12.0 * zoom_scale
			var lock_h = 9.0 * zoom_scale
			var lock_pos = Vector2(np.x - lock_w * 0.5, np.y - 1.5 * zoom_scale)
			draw_rect(Rect2(lock_pos.x, lock_pos.y, lock_w, lock_h), lock_col, false, 1.5)
			draw_arc(np + Vector2(0, -1.5 * zoom_scale), 4.2 * zoom_scale, PI, TAU, 14, lock_col, 1.5)
			draw_circle(np + Vector2(0, 2.0 * zoom_scale), 1.3 * zoom_scale, Color(0.04, 0.03, 0.08, 1.0))
			draw_line(np + Vector2(0, 2.0 * zoom_scale), np + Vector2(0, 5.0 * zoom_scale), Color(0.04, 0.03, 0.08, 1.0), 1.3)

		# --- Rótulo / Número de nivel ---
		if is_tutorial:
			var tut_str = "TUTORIAL"
			var tut_col = Color(0.2, 0.95, 1.0, 1.0) if not is_hovered else Color.WHITE
			draw_string(font, np + Vector2(-32 * zoom_scale, -34 * zoom_scale), tut_str, HORIZONTAL_ALIGNMENT_CENTER, int(64 * zoom_scale), int(12 * zoom_scale), tut_col)
		else:
			var lvl_str = str(i)
			var num_color: Color
			if is_playable:
				num_color = Color(1.0, 0.92, 0.95, 1.0)
			elif is_hovered:
				num_color = Color.WHITE
			else:
				num_color = Color(0.55, 0.7, 0.82, 0.75)
			draw_string(font, np + Vector2(-12 * zoom_scale, -28 * zoom_scale), lvl_str, HORIZONTAL_ALIGNMENT_CENTER, int(24 * zoom_scale), int(12 * zoom_scale), num_color)

		# --- Corchetes tácticos de selección en Hover ---
		if is_hovered:
			var b_dist = (socket_sz + 4.0)
			var b_sz = 9.0 * zoom_scale
			var b_col = Color(0.0, 0.95, 1.0, 0.95) if is_tutorial else (Color(1.0, 0.2, 0.35, 0.95) if is_playable else Color(0.0, 1.0, 0.8, 0.95))
			draw_line(np + Vector2(-b_dist, -b_dist), np + Vector2(-b_dist + b_sz, -b_dist), b_col, 2.2)
			draw_line(np + Vector2(-b_dist, -b_dist), np + Vector2(-b_dist, -b_dist + b_sz), b_col, 2.2)
			draw_line(np + Vector2(b_dist, -b_dist), np + Vector2(b_dist - b_sz, -b_dist), b_col, 2.2)
			draw_line(np + Vector2(b_dist, -b_dist), np + Vector2(b_dist, -b_dist + b_sz), b_col, 2.2)
			draw_line(np + Vector2(-b_dist, b_dist), np + Vector2(-b_dist + b_sz, b_dist), b_col, 2.2)
			draw_line(np + Vector2(-b_dist, b_dist), np + Vector2(-b_dist, b_dist - b_sz), b_col, 2.2)
			draw_line(np + Vector2(b_dist, b_dist), np + Vector2(b_dist - b_sz, b_dist), b_col, 2.2)
			draw_line(np + Vector2(b_dist, b_dist), np + Vector2(b_dist, b_dist - b_sz), b_col, 2.2)

			var ripple_t = fmod(anim_offset * 1.5, 1.0)
			var ripple_r = lerp(26.0, 52.0, ripple_t) * zoom_scale
			var ripple_a = (1.0 - ripple_t) * 0.4
			draw_arc(np, ripple_r, 0, TAU, 32, Color(b_col.r, b_col.g, b_col.b, ripple_a), 1.5)

# =============================================================================
# FONDO DE TELARAÑA GEOMÉTRICA CONCÉNTRICA Y RADIAL SEGÚN EL MODO
# =============================================================================
func _draw_spiderweb_background(w: float, h: float, hub: Vector2) -> void:
	var grid_step = 54.0
	var grid_color = Color(0.1, 0.4, 0.8, 0.04) if current_mode != "reparacion" else Color(0.85, 0.05, 0.35, 0.04)
	var cross_len = 3.0
	var x_steps = int(w / grid_step) + 1
	var y_steps = int(h / grid_step) + 1
	for xi in range(x_steps):
		var gx = xi * grid_step
		for yi in range(y_steps):
			var gy = yi * grid_step
			draw_line(Vector2(gx - cross_len, gy), Vector2(gx + cross_len, gy), grid_color, 1.0)
			draw_line(Vector2(gx, gy - cross_len), Vector2(gx, gy + cross_len), grid_color, 1.0)

	var spoke_count: int
	var spoke_angles: Array[float] = []
	var web_radii: Array[float] = [120.0, 210.0, 310.0, 420.0, 540.0]
	var web_color: Color
	var glow_color: Color

	match current_mode:
		"reparacion":
			spoke_count = 8
			web_color = Color(0.85, 0.08, 0.32, 0.16)
			glow_color = Color(0.65, 0.05, 0.45, 0.08)
			for i in range(spoke_count):
				spoke_angles.append(float(i) * TAU / 8.0)
		"sistema":
			spoke_count = 8
			web_color = Color(0.0, 0.75, 0.95, 0.16)
			glow_color = Color(0.5, 0.1, 0.85, 0.08)
			for i in range(spoke_count):
				spoke_angles.append(float(i) * TAU / 8.0 + PI * 0.125)
		"servidor":
			spoke_count = 12
			web_color = Color(0.15, 0.6, 1.0, 0.18)
			glow_color = Color(0.9, 0.15, 0.65, 0.08)
			for i in range(spoke_count):
				spoke_angles.append(float(i) * TAU / 12.0)
		_:
			spoke_count = 8
			web_color = Color(0.85, 0.08, 0.32, 0.16)
			glow_color = Color(0.65, 0.05, 0.45, 0.08)
			for i in range(spoke_count):
				spoke_angles.append(float(i) * TAU / 8.0)

	# 1. Filamentos radiales proyectados desde el núcleo tutorial hacia el perímetro
	for ang in spoke_angles:
		var dir = Vector2(cos(ang), sin(ang))
		var end_pt = hub + dir * 680.0
		draw_line(hub, end_pt, glow_color, 2.5)
		draw_line(hub, end_pt, web_color, 1.0)

	# 2. Anillos concéntricos poligonales de la telaraña con oscilación viva
	for r_idx in range(web_radii.size()):
		var base_r = web_radii[r_idx]
		var wave_osc = sin(anim_offset * 1.6 + float(r_idx) * 1.1) * 2.2
		var cur_r = base_r + wave_osc
		
		var ring_pts: PackedVector2Array = []
		for ang in spoke_angles:
			var dir = Vector2(cos(ang), sin(ang))
			ring_pts.append(hub + dir * cur_r)
		ring_pts.append(ring_pts[0])

		draw_polyline(ring_pts, glow_color, 3.2, false)
		draw_polyline(ring_pts, web_color, 1.2, false)

		for pt in ring_pts:
			draw_circle(pt, 1.8, Color(web_color.r, web_color.g, web_color.b, 0.35))

# =============================================================================
# MICRO-ANIMACIÓN DE TRANSICIÓN ESPECÍFICA POR TELARAÑA AL CAMBIAR DE MODO
# =============================================================================
func _draw_transition_effect(hub: Vector2, w: float, h: float) -> void:
	var font = ThemeDB.fallback_font
	match transition_type:
		"shockwave_burst":
			# ANIMACIÓN 1 (REPARACIÓN): Triple onda de choque carmesí con chispas de hardware
			var p = transition_progress
			var shock_r1 = p * (w * 0.72)
			var shock_r2 = max(0.0, shock_r1 - 50.0)
			var shock_r3 = max(0.0, shock_r1 - 110.0)
			var alpha1 = (1.0 - p) * 0.65
			var alpha2 = (1.0 - p) * 0.45
			var alpha3 = (1.0 - p) * 0.25
			
			draw_arc(hub, shock_r1, 0, TAU, 64, Color(1.0, 0.12, 0.35, alpha1), 3.5)
			if shock_r2 > 0:
				draw_arc(hub, shock_r2, 0, TAU, 48, Color(1.0, 0.35, 0.2, alpha2), 2.4)
			if shock_r3 > 0:
				draw_arc(hub, shock_r3, 0, TAU, 36, Color(0.85, 0.1, 0.7, alpha3), 1.8)
			
			# Chispas de expansión radial que viajan por los 8 radios
			for k in range(8):
				var ang = float(k) * TAU / 8.0
				var spark_pt = hub + Vector2(cos(ang), sin(ang)) * shock_r1
				draw_circle(spark_pt, 4.5 * (1.0 - p), Color(1.0, 0.5, 0.15, alpha1))
				draw_circle(spark_pt, 2.0 * (1.0 - p), Color.WHITE)
				
		"matrix_spiral":
			# ANIMACIÓN 2 (SISTEMA): Vórtex espiral polar de matrices fluido con glifos de kernel
			var spiral_rot = transition_sweep_angle
			var turns = 38
			var prev_p1 = hub
			var prev_p2 = hub
			var a = sin(transition_progress * PI) * 0.75
			
			for k in range(1, turns):
				var frac = float(k) / float(turns)
				var r = frac * (w * 0.58)
				var theta1 = spiral_rot + frac * TAU * 1.1
				var theta2 = -spiral_rot - frac * TAU * 1.1
				var p1 = hub + Vector2(cos(theta1), sin(theta1)) * r
				var p2 = hub + Vector2(cos(theta2), sin(theta2)) * r
				var line_a = a * (1.0 - frac * 0.5)
				draw_line(prev_p1, p1, Color(0.0, 0.95, 1.0, line_a), 2.2)
				draw_line(prev_p2, p2, Color(0.85, 0.15, 0.95, line_a), 2.2)
				
				# Puntos de código digital en la espiral
				if k % 3 == 0:
					draw_circle(p1, 2.4, Color(0.2, 1.0, 0.85, line_a * 1.3))
					draw_circle(p2, 2.4, Color(1.0, 0.35, 0.9, line_a * 1.3))
				prev_p1 = p1
				prev_p2 = p2
				
			# Detallitos: Fragmentos de código digital y rombo de matriz convergente
			var glyphs = ["01", "0x7F", "SYS", "[KERNEL]", "BIOS", "UEFI", "OK", ">_"]
			for g_i in range(glyphs.size()):
				var g_ang = float(g_i) * TAU / float(glyphs.size()) + spiral_rot * 0.4
				var g_dist = lerp(90.0, 320.0, float(g_i % 4) / 3.0)
				var g_pos = hub + Vector2(cos(g_ang), sin(g_ang)) * g_dist
				var g_alpha = a * 0.65
				draw_string(font, g_pos, glyphs[g_i], HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.0, 1.0, 0.85, g_alpha))
				
			# Rombo de matriz en expansión que sincroniza los diamantes de sistema
			var dia_r = sin(transition_progress * PI) * 220.0
			var dia_pts = PackedVector2Array([
				hub + Vector2(0, -dia_r),
				hub + Vector2(dia_r, 0),
				hub + Vector2(0, dia_r),
				hub + Vector2(-dia_r, 0),
				hub + Vector2(0, -dia_r)
			])
			draw_polyline(dia_pts, Color(0.0, 0.9, 1.0, a * 0.55), 1.6)
				
		"quantum_sweep":
			# ANIMACIÓN 3 (SERVIDOR): Barrido radar 360° con encendido óptico de nodos
			var sweep_ang = transition_sweep_angle
			var sweep_dir = Vector2(cos(sweep_ang), sin(sweep_ang))
			var beam_end = hub + sweep_dir * (w * 0.62)
			var beam_alpha = (1.0 - transition_progress * 0.5) * 0.75
			draw_line(hub, beam_end, Color(0.1, 0.65, 1.0, beam_alpha), 3.2)
			draw_line(hub, beam_end, Color(1.0, 1.0, 1.0, beam_alpha * 0.8), 1.2)
			
			# Abanico fosforescente de barrido
			for s in range(14):
				var lag_ang = sweep_ang - float(s) * 0.07
				var lag_dir = Vector2(cos(lag_ang), sin(lag_ang))
				var lag_alpha = beam_alpha * (1.0 - float(s) / 14.0) * 0.35
				draw_line(hub, hub + lag_dir * (w * 0.60), Color(0.9, 0.15, 0.7, lag_alpha), 1.8)

# =============================================================================
# ENLACE CIRCUIT LINE CON SOPORTE PARA RAÍZ PRINCIPAL
# =============================================================================
func _draw_circuit_line(p1: Vector2, p2: Vector2, alpha: float, seed_val: int, is_primary_root: bool = false) -> void:
	if is_primary_root:
		# RAÍZ PRINCIPAL (TUTORIAL -> NIVEL 1): Doble intensidad y filamento dorado/cian
		draw_line(p1, p2, Color(0.0, 0.65, 1.0, 0.4 * alpha), 6.5)
		draw_line(p1, p2, Color(0.2, 0.9, 1.0, alpha), 2.8)
		draw_line(p1, p2, Color(1.0, 1.0, 1.0, alpha * 0.85), 1.2)
		
		var packet_t1 = fmod(anim_offset * 1.2 + float(seed_val) * 0.14, 1.0)
		var packet_pos1 = p1.lerp(p2, packet_t1)
		draw_circle(packet_pos1, 4.0, Color(0.0, 0.9, 1.0, min(1.0, alpha * 1.8)))
		draw_circle(packet_pos1, 2.0, Color.WHITE)
	else:
		# Glow exterior estándar
		draw_line(p1, p2, Color(0.48, 0.05, 0.70, 0.28 * alpha), 4.5)
		# Pista central
		draw_line(p1, p2, Color(1.0, 0.12, 0.38, alpha), 1.8)
		
		var packet_t = fmod(anim_offset * 0.75 + float(seed_val) * 0.14, 1.0)
		var packet_pos = p1.lerp(p2, packet_t)
		draw_circle(packet_pos, 2.6, Color(1.0, 0.3, 0.65, min(1.0, alpha * 1.6)))
		draw_circle(packet_pos, 1.2, Color(1.0, 1.0, 1.0, min(1.0, alpha * 1.6)))
