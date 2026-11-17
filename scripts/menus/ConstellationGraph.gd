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
var _mode_tween: Tween = null

# Micro-animación de zoom táctil sobre los círculos de nivel (hasta 32 nodos dinámicos)
var node_zoom_scales: Array[float] = [
	1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
	1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0
]
var node_ripples: Array[float] = [
	0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
]
var node_press_tweens: Dictionary = {}
var node_unlocked_states: Dictionary = {}

var unlocking_node_index: int = -1
var unlock_anim_progress: float = 0.0
var _unlock_tween: Tween = null

func set_node_unlocked(index: int, unlocked: bool) -> void:
	node_unlocked_states[index] = unlocked
	queue_redraw()

func set_all_unlocked(unlocked: bool) -> void:
	for i in range(nodes.size()):
		node_unlocked_states[i] = unlocked
	queue_redraw()

func is_node_unlocked(index: int) -> bool:
	if node_unlocked_states.has(index):
		return node_unlocked_states[index]
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.has_method("is_node_unlocked"):
		return sm.is_node_unlocked(current_mode, index)
	return (index == 0)

func play_unlock_animation(node_idx: int, on_complete: Callable = Callable()) -> void:
	if node_idx < 0 or node_idx >= nodes.size():
		if on_complete.is_valid(): on_complete.call()
		return
	unlocking_node_index = node_idx
	unlock_anim_progress = 0.0
	set_node_unlocked(node_idx, true)
	trigger_node_click_zoom(node_idx)
	
	if _unlock_tween and _unlock_tween.is_valid():
		_unlock_tween.kill()
		
	_unlock_tween = create_tween()
	_unlock_tween.tween_method(func(v: float):
		unlock_anim_progress = v
		queue_redraw()
	, 0.0, 1.0, 1.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	_unlock_tween.chain().tween_callback(func():
		unlocking_node_index = -1
		unlock_anim_progress = 0.0
		queue_redraw()
		if on_complete.is_valid():
			on_complete.call()
	)

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
# NÚCLEO CENTRAL = VECTOR2(580, 395)
# RAÍZ PRINCIPAL AL NIVEL 1 EN EL OESTE/NOROESTE CONECTADA DIRECTA AL NÚCLEO
# =============================================================================
var MODE_NODES: Dictionary = {
	# 1. REPARACIÓN: Telaraña Expandida y Espaciosa (Distribución Secuencial: Tutorial -> Reto de Práctica Cronometrado -> Nivel 1)
	"reparacion": [
		# --- NÚCLEO CENTRAL DE INDUCCIÓN [0] ---
		Vector2(520, 360), # [0] NÚCLEO TUTORIAL: Inducción Central al Hardware

		# --- TUTORIALES GUIADOS 3D [1 - 6] ---
		Vector2(350, 360), # [1] TUTORIAL 3D: Fan Cooler (Oeste)
		Vector2(400, 230), # [2] TUTORIAL 3D: Memoria RAM (Noroeste)
		Vector2(600, 200), # [3] TUTORIAL 3D: Disco HDD / SSD (Norte)
		Vector2(800, 230), # [4] TUTORIAL 3D: Tarjeta Gráfica GPU (Noreste)
		Vector2(850, 360), # [5] TUTORIAL 3D: Fuente de Poder PSU (Este)
		Vector2(800, 490), # [6] TUTORIAL 3D: Procesador CPU (Sureste)

		# --- CAMPAÑA PRINCIPAL: NIVELES 1 AL 12 [7 - 18] (Se desbloquean al completar el entrenamiento) ---
		Vector2(760, 580), # [7] NIVEL 1 · MONTAJE FAN COOLER (Desbloqueo final de inducción)
		Vector2(640, 610), # [8] NIVEL 2 · DIAGNÓSTICO BANCO RAM
		Vector2(520, 620), # [9] NIVEL 3 · UNIDAD SATA Y TORNILLOS (HDD / SSD)
		Vector2(400, 610), # [10] NIVEL 4 · PASTA TÉRMICA Y CONTACTO
		Vector2(290, 570), # [11] NIVEL 5 · TARJETA GRÁFICA PCIE
		Vector2(200, 500), # [12] NIVEL 6 · FUENTE DE PODER ATX
		Vector2(120, 480), # [13] NIVEL 7 · ZÓCALO DE PROCESADOR CPU
		Vector2(80, 360),  # [14] NIVEL 8 · ARQUITECTURA TÉRMICA COMPLETA
		Vector2(90, 240),  # [15] NIVEL 9 · DIAGNÓSTICO INTEGRADO
		Vector2(130, 140), # [16] NIVEL 10 · WORKSTATION GAMING & RENDER
		Vector2(200, 60),  # [17] NIVEL 11 · OVERCLOCKING & CALIBRACIÓN
		Vector2(360, 50),  # [18] NIVEL 12 · CERTIFICACIÓN TÉCNICA MAESTRA

		# --- RETOS DE PRÁCTICA CRONOMETRADOS (3 MESAS / 8 MINUTOS) [19 - 25] ---
		Vector2(180, 360), # [19] RETO PRÁCTICA: Fan Cooler (Exterior Oeste)
		Vector2(260, 120), # [20] RETO PRÁCTICA: Memoria RAM (Exterior Noroeste)
		Vector2(600, 70),  # [21] RETO PRÁCTICA: Discos HDD/SSD (Exterior Norte)
		Vector2(940, 120), # [22] RETO PRÁCTICA: Tarjeta Gráfica GPU (Exterior Noreste)
		Vector2(1020, 360),# [23] RETO PRÁCTICA: Fuente de Poder PSU (Exterior Este)
		Vector2(940, 600), # [24] RETO PRÁCTICA: Procesador CPU (Exterior Sureste)
		Vector2(680, 360)  # [25] RETO PRÁCTICA: Inducción / 3 PCs Inicial (Centro Este)
	],
	# 2. SISTEMA: Telaraña de Diamante Cibernético y Matriz de Kernel Ampliada
	"sistema": [
		Vector2(580, 395), # [0] TUTORIAL: Núcleo Central de Boot & BIOS (AZUL)
		Vector2(420, 235), # [1] NIVEL 1: Cold Boot POST (Raíz Primaria Noroeste, ROJO)
		Vector2(740, 235), # [2] NIVEL 2: Firmware Diagnostics (Raíz Noreste)
		Vector2(740, 555), # [3] NIVEL 3: BIOS Flash (Raíz Sureste)
		Vector2(420, 555), # [4] NIVEL 4: Secure Boot (Raíz Suroeste)
		Vector2(580, 85),  # [5] NIVEL 5: Tabla GPT (Ápice Medio Norte)
		Vector2(960, 395), # [6] NIVEL 6: Cargador GRUB/BCD (Ápice Medio Este)
		Vector2(580, 690), # [7] NIVEL 7: Kernel Ring 0 (Ápice Medio Sur)
		Vector2(200, 395), # [8] NIVEL 8: Sandbox Malware (Ápice Medio Oeste)
		Vector2(180, 85),  # [9] NIVEL 9: Registro HKLM (Vértice Exterior Noroeste)
		Vector2(980, 85),  # [10] NIVEL 10: Protección ASLR (Vértice Exterior Noreste)
		Vector2(980, 690), # [11] NIVEL 11: Rescate BitLocker (Vértice Exterior Sureste)
		Vector2(180, 690), # [12] NIVEL 12: SysAdmin Master (Vértice Exterior Suroeste)
		Vector2(300, 260)  # [13] SALA DE PRÁCTICA: Distanciada del Nivel 1 (NARANJA NEÓN)
	],
	# 3. SERVIDOR: Hiper-Malla Circular de Datacenter y Anillos de Fibra Óptica Ampliada
	"servidor": [
		Vector2(580, 395), # [0] TUTORIAL: Núcleo Central de Infraestructura 1U (AZUL)
		Vector2(370, 395), # [1] NIVEL 1: Bastidor 1U (Raíz Primaria Oeste 9h, ROJO)
		Vector2(475, 215), # [2] NIVEL 2: Servidor Blade 2U (Radio 11h)
		Vector2(685, 215), # [3] NIVEL 3: Cabina 4U SAN (Radio 1h)
		Vector2(790, 395), # [4] NIVEL 4: PDU Redundante (Radio 3h)
		Vector2(685, 575), # [5] NIVEL 5: Fibra SAN Fabric (Radio 5h)
		Vector2(475, 575), # [6] NIVEL 6: SAS Hot-Swap RAID (Radio 7h)
		Vector2(170, 160), # [7] NIVEL 7: Switch ToR 100G (Anillo Exterior 10h)
		Vector2(580, 75),  # [8] NIVEL 8: Trunking VLAN LACP (Anillo Exterior 12h)
		Vector2(990, 160), # [9] NIVEL 9: Pasillo Frío (Anillo Exterior 2h)
		Vector2(1100, 395),# [10] NIVEL 10: Clúster HA (Anillo Exterior 4h)
		Vector2(580, 695), # [11] NIVEL 11: Live Migration (Anillo Exterior 6h)
		Vector2(60, 395),  # [12] NIVEL 12: Centro NOC Datacenter (Anillo Exterior 8h)
		Vector2(280, 280)  # [13] SALA DE PRÁCTICA: Distanciada de Servidores 1U y 2U (NARANJA NEÓN)
	]
}

# Conexiones estructuradas de telaraña: Cadena de Desbloqueo Secuencial y Malla Cibernética
var MODE_CONNECTIONS: Dictionary = {
	"reparacion": [
		# 1. Cadena de progresión principal: Tutorial -> Reto de Práctica -> Siguiente Tutorial
		Vector2i(0, 25), # Tut 0 (Inducción) -> Reto Práctica 0 (3 PCs Inicial)
		Vector2i(25, 1), # Reto Práctica 0 -> Tut 1 (Cooler)
		Vector2i(1, 19), # Tut 1 -> Reto Práctica 1 (Cooler)
		Vector2i(19, 2), # Reto Práctica 1 -> Tut 2 (RAM)
		Vector2i(2, 20), # Tut 2 -> Reto Práctica 2 (RAM)
		Vector2i(20, 3), # Reto Práctica 2 -> Tut 3 (HDD)
		Vector2i(3, 21), # Tut 3 -> Reto Práctica 3 (HDD)
		Vector2i(21, 4), # Reto Práctica 3 -> Tut 4 (GPU)
		Vector2i(4, 22), # Tut 4 -> Reto Práctica 4 (GPU)
		Vector2i(22, 5), # Reto Práctica 4 -> Tut 5 (PSU)
		Vector2i(5, 23), # Tut 5 -> Reto Práctica 5 (PSU)
		Vector2i(23, 6), # Reto Práctica 5 -> Tut 6 (CPU)
		Vector2i(6, 24), # Tut 6 -> Reto Práctica 6 (CPU)
		Vector2i(24, 7), # Reto Práctica 6 -> ¡NIVEL 1! (Desbloqueo de campaña)

		# 2. Vía perimetral de Campaña: Niveles 1 al 12
		Vector2i(7, 8), Vector2i(8, 9), Vector2i(9, 10), Vector2i(10, 11), Vector2i(11, 12), Vector2i(12, 13),
		Vector2i(13, 14), Vector2i(14, 15), Vector2i(15, 16), Vector2i(16, 17), Vector2i(17, 18),

		# 3. Malla secundaria cibernética entre sectores
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4), Vector2i(0, 5), Vector2i(0, 6),
		Vector2i(1, 2), Vector2i(2, 3), Vector2i(3, 4), Vector2i(4, 5), Vector2i(5, 6), Vector2i(6, 25),
		Vector2i(19, 20), Vector2i(20, 21), Vector2i(21, 22), Vector2i(22, 23), Vector2i(23, 24)
	],
	"sistema": [
		# Raíces directas desde el núcleo tutorial (0)
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4),
		# Conexión satélite de práctica (Naranja Neón)
		Vector2i(0, 13), Vector2i(1, 13),
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
		# Conexión satélite de práctica (Naranja Neón)
		Vector2i(0, 13), Vector2i(1, 13),
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
var node_labels: Array[Label] = []
var _cached_grid_lines: PackedVector2Array = PackedVector2Array()
var _cached_grid_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	_update_nodes_for_mode()
	_init_cyber_fx()
	_setup_cached_node_labels()

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
		_setup_cached_node_labels()
		_rebuild_dynamic_traces()
		queue_redraw()
		return
		
	# Iniciar micro-animación de transición fluida y diferenciada de alto impacto
	if _mode_tween and _mode_tween.is_valid():
		_mode_tween.kill()

	is_transitioning = true
	transition_progress = 0.0
	mode_switch_pulse = 1.0
	mode_transition_started.emit()
	
	var hub = Vector2(580, 395)
	_mode_tween = create_tween().set_parallel(true)
	
	_mode_tween.tween_method(func(val: float):
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
		_update_label_positions()
		queue_redraw()
	, 0.0, 1.0, 0.22)
	
	_mode_tween.tween_property(self, "mode_switch_pulse", 0.0, 0.25).set_ease(Tween.EASE_OUT)
	
	_mode_tween.chain().tween_callback(func():
		is_transitioning = false
		_update_nodes_for_mode()
		_rebuild_dynamic_traces()
		_update_label_positions()
		mode_transition_completed.emit()
		queue_redraw()
	)

func _update_nodes_for_mode() -> void:
	nodes.clear()
	var raw_list = MODE_NODES.get(current_mode, [])
	for pt in raw_list:
		nodes.append(pt as Vector2)
	while node_zoom_scales.size() < nodes.size():
		node_zoom_scales.append(1.0)
	while node_ripples.size() < nodes.size():
		node_ripples.append(0.0)
	_update_label_positions()

func _setup_cached_node_labels() -> void:
	for lbl in node_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	node_labels.clear()

	var font = null
	if ResourceLoader.exists("res://assets/fonts/JetBrainsMono-Bold.ttf"):
		font = load("res://assets/fonts/JetBrainsMono-Bold.ttf")
	elif ResourceLoader.exists("res://assets/fonts/Bungee-Regular.ttf"):
		font = load("res://assets/fonts/Bungee-Regular.ttf")

	var total_nodes = nodes.size() if not nodes.is_empty() else MODE_NODES.get(current_mode, []).size()
	for i in range(total_nodes):
		var lbl = Label.new()
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if font:
			lbl.add_theme_font_override("font", font)
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
		lbl.add_theme_constant_override("outline_size", 4)
		
		if current_mode == "reparacion":
			if i == 0:
				lbl.text = "INDUCCIÓN"
				lbl.add_theme_font_size_override("font_size", 9)
				lbl.add_theme_color_override("font_color", Color(0.2, 0.95, 1.0, 1.0))
				lbl.size = Vector2(80, 20)
			elif i in [1, 2, 3, 4, 5, 6]:
				var tut_names = {
					1: "COOLER",
					2: "RAM",
					3: "HDD / SSD",
					4: "GPU",
					5: "PSU",
					6: "CPU"
				}
				lbl.text = "TUT " + tut_names.get(i, str(i))
				lbl.add_theme_font_size_override("font_size", 8)
				lbl.add_theme_color_override("font_color", Color(0.2, 0.95, 1.0, 1.0))
				lbl.size = Vector2(80, 20)
			elif i in range(7, 19):
				var lvl_num = i - 6 # 1 al 12
				lbl.text = str(lvl_num)
				lbl.add_theme_font_size_override("font_size", 11)
				lbl.size = Vector2(30, 20)
				if lvl_num == 1:
					lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.95, 1.0))
				else:
					lbl.add_theme_color_override("font_color", Color(0.55, 0.7, 0.82, 0.75))
			elif i in range(19, 25):
				var prac_names = {
					19: "COOLER",
					20: "RAM",
					21: "HDD",
					22: "GPU",
					23: "PSU",
					24: "CPU"
				}
				lbl.text = "PRÁC " + prac_names.get(i, str(i))
				lbl.add_theme_font_size_override("font_size", 8)
				lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.15, 1.0))
				lbl.size = Vector2(80, 20)
			elif i == 25:
				lbl.text = "PRÁCTICA"
				lbl.add_theme_font_size_override("font_size", 9)
				lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.15, 1.0))
				lbl.size = Vector2(80, 20)
		elif i == 0:
			lbl.text = "TUTORIAL"
			lbl.add_theme_font_size_override("font_size", 10)
			lbl.add_theme_color_override("font_color", Color(0.2, 0.95, 1.0, 1.0))
			lbl.size = Vector2(80, 20)
		elif i == 13:
			lbl.text = "PRÁCTICA"
			lbl.add_theme_font_size_override("font_size", 10)
			lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.15, 1.0))
			lbl.size = Vector2(80, 20)
		else:
			lbl.text = str(i)
			lbl.add_theme_font_size_override("font_size", 11)
			lbl.size = Vector2(30, 20)
			if i == 1:
				lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.95, 1.0))
			else:
				lbl.add_theme_color_override("font_color", Color(0.55, 0.7, 0.82, 0.75))
				
		add_child(lbl)
		node_labels.append(lbl)
	_update_label_positions()

func _update_label_positions() -> void:
	for i in range(min(node_labels.size(), nodes.size())):
		var lbl = node_labels[i]
		if not is_instance_valid(lbl):
			continue
		var np = nodes[i]
		var zoom_scale = node_zoom_scales[i] if i < node_zoom_scales.size() else 1.0
		var is_special = (i <= 6 or i >= 19) if current_mode == "reparacion" else (i == 0 or i == 13)
		if is_special:
			lbl.position = np + Vector2(-40, -40 * zoom_scale)
		else:
			lbl.position = np + Vector2(-15, -34 * zoom_scale)

func _update_label_hover() -> void:
	for i in range(node_labels.size()):
		var lbl = node_labels[i]
		if not is_instance_valid(lbl):
			continue
		if i == hovered_node_index:
			lbl.modulate = Color(1.4, 1.4, 1.4, 1.0)
		else:
			lbl.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _rebuild_dynamic_traces() -> void:
	if nodes.size() < 13:
		return
	var hub = nodes[0]

	# Pistas dinámicas generadas estrictamente desde los filamentos de la telaraña actual
	var raw_traces: Array[PackedVector2Array] = []
	if current_mode == "reparacion":
		if nodes.size() >= 26:
			raw_traces = [
				PackedVector2Array([nodes[0], nodes[25]]),
				PackedVector2Array([nodes[25], nodes[1], nodes[19]]),
				PackedVector2Array([nodes[19], nodes[2], nodes[20]]),
				PackedVector2Array([nodes[20], nodes[3], nodes[21]]),
				PackedVector2Array([nodes[21], nodes[4], nodes[22]]),
				PackedVector2Array([nodes[22], nodes[5], nodes[23]]),
				PackedVector2Array([nodes[23], nodes[6], nodes[24]]),
				PackedVector2Array([nodes[24], nodes[7]]),
				PackedVector2Array([nodes[7], nodes[8], nodes[9], nodes[10], nodes[11], nodes[12]]),
				PackedVector2Array([nodes[12], nodes[13], nodes[14], nodes[15], nodes[16], nodes[17], nodes[18]])
			]
		else:
			raw_traces = [
				PackedVector2Array([hub, nodes[1]]),
				PackedVector2Array([hub, nodes[2]])
			]
	else:
		raw_traces = [
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

	for i in range(10):
		var p = DataPulse.new()
		p.trace_index = i % max(1, circuit_traces.size())
		p.progress = rng.randf()
		p.speed = rng.randf_range(0.18, 0.32)
		p.color = pulse_colors[i % pulse_colors.size()]
		p.size = rng.randf_range(2.6, 3.8)
		p.tail_length = rng.randf_range(25.0, 45.0)
		data_pulses.append(p)

	var w = size.x if size.x > 100 else 1280.0
	var h = size.y if size.y > 50 else 720.0
	for i in range(14):
		var m = CyberMote.new()
		m.pos = Vector2(rng.randf_range(20.0, w - 20.0), rng.randf_range(110.0, h - 60.0))
		m.drift = Vector2(rng.randf_range(-10.0, 10.0), rng.randf_range(-6.0, 6.0))
		m.size = rng.randf_range(1.2, 2.2)
		m.base_alpha = rng.randf_range(0.2, 0.45)
		m.phase = rng.randf_range(0.0, TAU)
		m.pulse_speed = rng.randf_range(1.5, 3.2)
		m.color = pulse_colors[rng.randi_range(0, pulse_colors.size() - 1)]
		cyber_motes.append(m)

	_rebuild_grid_cache(w, h)
	initialized_fx = true

func _rebuild_grid_cache(w: float, h: float) -> void:
	_cached_grid_size = Vector2(w, h)
	_cached_grid_lines.clear()
	var grid_step = 54.0
	var cross_len = 3.0
	var x_steps = int(w / grid_step) + 1
	var y_steps = int(h / grid_step) + 1
	for xi in range(x_steps):
		var gx = xi * grid_step
		for yi in range(y_steps):
			var gy = yi * grid_step
			_cached_grid_lines.append(Vector2(gx - cross_len, gy))
			_cached_grid_lines.append(Vector2(gx + cross_len, gy))
			_cached_grid_lines.append(Vector2(gx, gy - cross_len))
			_cached_grid_lines.append(Vector2(gx, gy + cross_len))

var _redraw_throttle_accum: float = 0.0

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return

	_redraw_throttle_accum += delta
	var min_step = 0.016 if is_transitioning else 0.024
	if _redraw_throttle_accum < min_step:
		return
	var eff_delta = _redraw_throttle_accum
	_redraw_throttle_accum = 0.0

	var gm = get_node_or_null("/root/GameManager")
	var is_photo = gm and gm.has_method("is_photosensitive_mode_enabled") and gm.is_photosensitive_mode_enabled()
	var time_scale = 0.8 if is_photo else 2.2
	anim_offset += eff_delta * time_scale

	if not initialized_fx:
		_init_cyber_fx()

	var w = size.x if size.x > 100 else 1280.0
	var h = size.y if size.y > 50 else 720.0
	if _cached_grid_size != Vector2(w, h):
		_rebuild_grid_cache(w, h)

	# Detección de hover sobre cualquiera de los 14 nodos
	var mouse_pos = get_local_mouse_position()
	var new_hovered: int = -1
	for i in range(nodes.size()):
		if mouse_pos.distance_to(nodes[i]) <= 32.0:
			new_hovered = i
			break

	if new_hovered != hovered_node_index:
		hovered_node_index = new_hovered
		_update_label_hover()

	# Acelerar los paquetes de datos durante la transición de telaraña ("data surge")
	var speed_mult = (1.2 if is_photo else 2.4) if is_transitioning else (0.6 if is_photo else 1.0)
	for p in data_pulses:
		p.progress += p.speed * eff_delta * speed_mult
		if p.progress > 1.0:
			p.progress -= 1.0

	for m in cyber_motes:
		m.pos += m.drift * eff_delta
		if m.pos.x < 0.0: m.pos.x += w
		elif m.pos.x > w: m.pos.x -= w
		if m.pos.y < 90.0: m.pos.y += (h - 110.0)
		elif m.pos.y > h: m.pos.y -= (h - 110.0)

	queue_redraw()

func _draw() -> void:
	var w = size.x if size.x > 100 else 1280.0
	var h = size.y if size.y > 50 else 720.0
	var hub = nodes[0] if not nodes.is_empty() else Vector2(580, 395)

	# =========================================================================
	# 1. FONDO DE TELARAÑA CIBERNÉTICA ARQUITECTÓNICA (BATCHEADA)
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
	var trace_col: Color
	var dot_col: Color
	match current_mode:
		"sistema":
			trace_col = Color(0.12, 0.45, 0.95, 0.40)
			dot_col = Color(0.18, 0.55, 1.0, 0.6)
		"servidor":
			trace_col = Color(1.0, 0.52, 0.08, 0.40)
			dot_col = Color(1.0, 0.6, 0.15, 0.6)
		_:
			trace_col = Color(0.85, 0.08, 0.45, 0.40)
			dot_col = Color(1.0, 0.1, 0.35, 0.5)

	for trace in circuit_traces:
		if trace.points.size() >= 2:
			draw_polyline(trace.points, trace_col, 1.0, false)

	# =========================================================================
	# 4. PULSOS DE DATOS VIAJANDO POR LOS FILAMENTOS DE LA TELARAÑA
	# =========================================================================
	for p in data_pulses:
		if p.trace_index < circuit_traces.size():
			var trace = circuit_traces[p.trace_index]
			if trace.total_length > 0.0:
				var head_dist = p.progress * trace.total_length
				var head_pos = trace.get_point_at_distance(head_dist)
				draw_circle(head_pos, p.size, p.color)

	# =========================================================================
	# 5. ENLACES ESTRUCTURALES ENTRE NODOS (BATCHEADOS EN MULTILINE)
	# =========================================================================
	var conns = MODE_CONNECTIONS.get(current_mode, MODE_CONNECTIONS["reparacion"])
	var std_lines = PackedVector2Array()
	var std_line_color: Color
	if current_mode == "sistema":
		std_line_color = Color(0.12, 0.48, 0.95, 0.40)
	elif current_mode == "servidor":
		std_line_color = Color(1.0, 0.55, 0.1, 0.40)
	else:
		std_line_color = Color(0.85, 0.08, 0.35, 0.40)

	for conn in conns:
		if conn.x < nodes.size() and conn.y < nodes.size():
			var is_primary_root = false
			var is_practice_link = false
			if current_mode == "reparacion":
				var is_tut_conn = (conn.x <= 6 and conn.y <= 6)
				var is_lvl1_conn = (conn.x == 7 or conn.y == 7)
				if is_tut_conn or is_lvl1_conn:
					is_primary_root = true
				elif conn.x >= 19 or conn.y >= 19:
					is_practice_link = true
			else:
				is_primary_root = (conn.x == 0 and conn.y == 1) or (conn.x == 1 and conn.y == 0)
				is_practice_link = (conn.x == 13 or conn.y == 13)

			if is_primary_root or is_practice_link:
				_draw_circuit_line(nodes[conn.x], nodes[conn.y], 0.95, conn.x + conn.y, is_primary_root, is_practice_link)
			else:
				std_lines.append(nodes[conn.x])
				std_lines.append(nodes[conn.y])
				
	if not std_lines.is_empty():
		draw_multiline(std_lines, std_line_color, 1.0)

	# =========================================================================
	# 6. POLVO DIGITAL AMBIENTAL
	# =========================================================================
	for m in cyber_motes:
		draw_circle(m.pos, m.size, m.color)

	# =========================================================================
	# 7. ESTELAS HOLOGRÁFICAS DE MOVIMIENTO EN TRANSICIÓN
	# =========================================================================
	if is_transitioning and transition_start_nodes.size() == nodes.size():
		var trail_factor = sin(transition_progress * PI)
		for i in range(nodes.size()):
			var p_start = transition_start_nodes[i]
			var p_cur = nodes[i]
			var p_mid = p_start.lerp(p_cur, 0.55)
			var trail_col = Color(0.12, 0.45, 0.95, trail_factor * 0.38) if (current_mode == "sistema") else (Color(1.0, 0.15, 0.4, trail_factor * 0.35) if current_mode == "reparacion" else Color(1.0, 0.55, 0.08, trail_factor * 0.38))
			draw_line(p_start, p_cur, Color(trail_col.r, trail_col.g, trail_col.b, trail_factor * 0.22), 2.2)
			draw_circle(p_mid, 8.0 * trail_factor, Color(trail_col.r, trail_col.g, trail_col.b, trail_factor * 0.28))
			draw_circle(p_mid, 3.0 * trail_factor, Color.WHITE)

	# =========================================================================
	# 8. RENDERIZADO OPTIMIZADO DE LOS NODOS DE LA TELARAÑA
	# =========================================================================
	for i in range(nodes.size()):
		var np = nodes[i]
		var is_hovered = (hovered_node_index == i)
		var is_unlocked = is_node_unlocked(i)
		var is_tutorial = false
		var is_practice = false
		var is_campaign = false
		if current_mode == "reparacion":
			is_tutorial = (i >= 0 and i <= 6)
			is_practice = (i >= 19 and i <= 25)
			is_campaign = (i >= 7 and i <= 18)
		else:
			is_tutorial = (i == 0)
			is_practice = (i == 13)
			is_campaign = (i >= 1 and i <= 12)
		var is_active_node = (is_unlocked and (is_tutorial or is_practice or is_campaign)) or is_hovered
		var zoom_scale = node_zoom_scales[i] if i < node_zoom_scales.size() else 1.0
		var ripple = node_ripples[i] if i < node_ripples.size() else 0.0

		var base_radius = (26.0 if is_tutorial else (24.0 if is_practice else 21.0))
		if is_hovered:
			base_radius += 3.5
		var breath_radius = base_radius * zoom_scale

		# --- Onda expansiva (Ripple al hacer click) ---
		if ripple > 0.01:
			var rip_r = lerp(26.0, 72.0, 1.0 - ripple) * zoom_scale
			var rip_a = ripple * 0.85
			var rip_col = Color(0.0, 0.88, 1.0, rip_a) if is_tutorial else (Color(1.0, 0.55, 0.05, rip_a) if is_practice else (Color(1.0, 0.1, 0.3, rip_a) if is_campaign else Color(0.2, 0.85, 1.0, rip_a)))
			draw_arc(np, rip_r, 0, TAU, 24, rip_col, 2.0)

		# --- Zócalo base en la telaraña ---
		var socket_bg: Color
		var socket_arc: Color
		if not is_unlocked:
			socket_bg = Color(0.04, 0.06, 0.12, 0.18)
			socket_arc = Color(0.25, 0.38, 0.52, 0.32)
		elif is_tutorial:
			socket_bg = Color(0.0, 0.35, 0.65, 0.22)
			socket_arc = Color(0.0, 0.88, 1.0, 0.75)
		elif is_practice:
			socket_bg = Color(0.9, 0.45, 0.02, 0.22)
			socket_arc = Color(1.0, 0.55, 0.05, 0.85)
		elif is_campaign:
			if current_mode == "sistema":
				socket_bg = Color(0.03, 0.15, 0.5, 0.25)
				socket_arc = Color(0.18, 0.58, 1.0, 0.85)
			elif current_mode == "servidor":
				socket_bg = Color(0.65, 0.25, 0.02, 0.25)
				socket_arc = Color(1.0, 0.55, 0.08, 0.85)
			else:
				socket_bg = Color(0.8, 0.05, 0.22, 0.18)
				socket_arc = Color(1.0, 0.08, 0.25, 0.75)
		else:
			socket_bg = Color(0.08, 0.12, 0.22, 0.12)
			socket_arc = Color(0.22, 0.35, 0.5, 0.30)

		var socket_sz = (36.0 if is_tutorial else (34.0 if is_practice else 32.0)) * zoom_scale
		draw_circle(np, socket_sz, socket_bg)
		draw_arc(np, socket_sz - 4.0 * zoom_scale, 0, TAU, 20, socket_arc, 1.0)

		# --- Anillos segmentados rotatorios SOLO en nodos activos o hovered ---
		if is_active_node and is_unlocked:
			var rot_cw = anim_offset * (1.2 + float(i % 3) * 0.3)
			var rot_ccw = -anim_offset * (0.9 + float((i + 1) % 3) * 0.25)
			var ring_r1 = (28.0 if is_tutorial else (27.0 if is_practice else 25.5)) * zoom_scale
			var ring_r2 = (25.0 if is_tutorial else (24.0 if is_practice else 23.0)) * zoom_scale
			var arc_col = socket_arc

			draw_arc(np, ring_r1, rot_cw, rot_cw + PI * 0.5, 10, arc_col, 1.2)
			draw_arc(np, ring_r1, rot_cw + PI * 1.1, rot_cw + PI * 1.6, 10, arc_col, 1.2)
			draw_arc(np, ring_r2, rot_ccw, rot_ccw + PI * 0.6, 10, Color(arc_col.r, arc_col.g, arc_col.b, 0.7), 1.0)
			draw_arc(np, ring_r2, rot_ccw + PI * 1.2, rot_ccw + PI * 1.8, 10, Color(arc_col.r, arc_col.g, arc_col.b, 0.7), 1.0)

		# --- Esfera de cristal central ---
		var crystal_col = Color(0.03, 0.04, 0.08, 0.95)
		if not is_unlocked:
			crystal_col = Color(0.02, 0.03, 0.06, 0.94)
		elif is_tutorial:
			crystal_col = Color(0.02, 0.06, 0.14, 0.95)
		elif is_practice:
			crystal_col = Color(0.12, 0.05, 0.01, 0.95)
		elif is_campaign:
			crystal_col = Color(0.10, 0.02, 0.05, 0.95)

		draw_circle(np, breath_radius, crystal_col)
		draw_arc(np, breath_radius, 0, TAU, 18, socket_arc, 1.0)

		# --- Iconografía interior de cada nodo ---
		if not is_unlocked:
			# Candado cibernético de bloqueo 🔒
			var lock_col = Color(0.4, 0.6, 0.75, 0.65) if not is_hovered else Color(0.0, 1.0, 0.75, 0.95)
			var lock_w = 11.0 * zoom_scale
			var lock_h = 8.0 * zoom_scale
			var lock_pos = Vector2(np.x - lock_w * 0.5, np.y - 1.0 * zoom_scale)
			draw_rect(Rect2(lock_pos.x, lock_pos.y, lock_w, lock_h), lock_col, false, 1.0)
			draw_arc(np + Vector2(0, -1.0 * zoom_scale), 3.8 * zoom_scale, PI, TAU, 8, lock_col, 1.0)
		elif is_tutorial:
			# GORRO DE GRADUADO (BIRRETE CIBERNÉTICO)
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
		elif is_practice:
			# FIGURA DE HERRAMIENTAS CRUZADAS DE PRÁCTICA (LLAVE INGLESA + DESTORNILLADOR SCI-FI)
			var tool_col = Color(1.0, 0.82, 0.35, 1.0) if not is_hovered else Color.WHITE
			var tool_glow = Color(1.0, 0.55, 0.05, 0.8)
			var sz = 8.5 * zoom_scale

			# 1. Llave inglesa en diagonal (SO a NE)
			var w_start = np + Vector2(-sz * 0.85, sz * 0.85)
			var w_end = np + Vector2(sz * 0.85, -sz * 0.85)
			draw_line(w_start, w_end, tool_glow, 3.8 * zoom_scale)
			draw_line(w_start, w_end, tool_col, 2.2 * zoom_scale)
			var head_dir = Vector2(0.707, -0.707)
			var head_perp = Vector2(0.707, 0.707)
			var j1 = w_end + head_perp * (sz * 0.45)
			var j2 = w_end - head_perp * (sz * 0.45)
			draw_line(j1, j1 + head_dir * (sz * 0.4), tool_col, 2.0 * zoom_scale)
			draw_line(j2, j2 + head_dir * (sz * 0.4), tool_col, 2.0 * zoom_scale)
			draw_line(j1, j2, tool_col, 1.8 * zoom_scale)
			draw_arc(w_start, sz * 0.32, 0, TAU, 12, tool_col, 1.6 * zoom_scale)

			# 2. Destornillador cruzado (SE a NO)
			var s_start = np + Vector2(sz * 0.85, sz * 0.85)
			var s_end = np + Vector2(-sz * 0.85, -sz * 0.85)
			draw_line(s_start, s_end, tool_glow, 3.4 * zoom_scale)
			draw_line(s_start, s_end, tool_col, 1.8 * zoom_scale)
			var s_dir = Vector2(-0.707, -0.707)
			draw_line(s_end - s_dir * (sz * 0.3), s_end, Color(1.0, 1.0, 1.0, 0.95), 2.4 * zoom_scale)
			var handle_p = s_start - s_dir * (sz * 0.5)
			draw_line(handle_p, s_start, Color(1.0, 0.45, 0.05, 1.0), 3.2 * zoom_scale)

			# 3. Núcleo perno luminoso en la intersección
			draw_circle(np, 2.6 * zoom_scale, Color(1.0, 0.9, 0.4, 1.0))
			draw_circle(np, 1.2 * zoom_scale, Color.WHITE)
		elif is_campaign:
			var tri_sz = 6.5 * zoom_scale
			var p_top = np + Vector2(-tri_sz * 0.6, -tri_sz)
			var p_bot = np + Vector2(-tri_sz * 0.6, tri_sz)
			var p_tip = np + Vector2(tri_sz * 1.1, 0.0)
			draw_colored_polygon([p_top, p_tip, p_bot], Color(1.0, 0.2, 0.35, 0.95) if not is_hovered else Color.WHITE)

		# --- Corchetes tácticos de selección en Hover ---
		if is_hovered:
			var b_dist = (socket_sz + 4.0)
			var b_sz = 8.0 * zoom_scale
			var b_col = socket_arc
			draw_line(np + Vector2(-b_dist, -b_dist), np + Vector2(-b_dist + b_sz, -b_dist), b_col, 1.8)
			draw_line(np + Vector2(-b_dist, -b_dist), np + Vector2(-b_dist, -b_dist + b_sz), b_col, 1.8)
			draw_line(np + Vector2(b_dist, -b_dist), np + Vector2(b_dist - b_sz, -b_dist), b_col, 1.8)
			draw_line(np + Vector2(b_dist, -b_dist), np + Vector2(b_dist, -b_dist + b_sz), b_col, 1.8)
			draw_line(np + Vector2(-b_dist, b_dist), np + Vector2(-b_dist + b_sz, b_dist), b_col, 1.8)
			draw_line(np + Vector2(-b_dist, b_dist), np + Vector2(-b_dist, b_dist - b_sz), b_col, 1.8)
			draw_line(np + Vector2(b_dist, b_dist), np + Vector2(b_dist - b_sz, b_dist), b_col, 1.8)
			draw_line(np + Vector2(b_dist, b_dist), np + Vector2(b_dist, b_dist - b_sz), b_col, 1.8)

	# =========================================================================
	# 9. ANIMACIÓN DE ONDA EXPANSIVA DE DESBLOQUEO (NUEVO NODO DESBLOQUEADO)
	# =========================================================================
	if unlocking_node_index >= 0 and unlocking_node_index < nodes.size():
		var up = nodes[unlocking_node_index]
		var u_rad = lerp(20.0, 160.0, unlock_anim_progress)
		var u_alpha = (1.0 - unlock_anim_progress) * 0.95
		var u_col = Color(0.0, 0.88, 1.0, u_alpha) if (unlocking_node_index <= 6) else (Color(1.0, 0.6, 0.1, u_alpha) if (unlocking_node_index >= 19) else Color(1.0, 0.15, 0.35, u_alpha))
		draw_arc(up, u_rad, 0, TAU, 36, u_col, 3.5)
		draw_arc(up, u_rad * 0.68, 0, TAU, 28, Color(1.0, 1.0, 1.0, u_alpha * 0.85), 2.0)
		draw_circle(up, 24.0 * (1.0 - unlock_anim_progress), Color(1.0, 1.0, 1.0, u_alpha * 0.7))

# =============================================================================
# FONDO DE TELARAÑA GEOMÉTRICA CONCÉNTRICA Y RADIAL SEGÚN EL MODO (BATCHEADO)
# =============================================================================
func _draw_spiderweb_background(w: float, h: float, hub: Vector2) -> void:
	var grid_color: Color
	match current_mode:
		"sistema":
			grid_color = Color(0.05, 0.25, 0.75, 0.06)
		"servidor":
			grid_color = Color(0.85, 0.45, 0.05, 0.06)
		_:
			grid_color = Color(0.85, 0.05, 0.35, 0.04)

	# 1. Cuadrícula precalculada batcheada en 1 sola llamada
	if not _cached_grid_lines.is_empty():
		draw_multiline(_cached_grid_lines, grid_color, 1.0)

	var spoke_count: int
	var spoke_angles: Array[float] = []
	var web_radii: Array[float] = [150.0, 260.0, 380.0, 520.0, 680.0]
	var web_color: Color

	match current_mode:
		"reparacion":
			spoke_count = 8
			web_color = Color(0.85, 0.08, 0.32, 0.16)
			for i in range(spoke_count):
				spoke_angles.append(float(i) * TAU / 8.0)
		"sistema":
			spoke_count = 8
			web_color = Color(0.08, 0.35, 0.88, 0.22)
			for i in range(spoke_count):
				spoke_angles.append(float(i) * TAU / 8.0 + PI * 0.125)
		"servidor":
			spoke_count = 12
			web_color = Color(1.0, 0.52, 0.08, 0.24)
			for i in range(spoke_count):
				spoke_angles.append(float(i) * TAU / 12.0)
		_:
			spoke_count = 8
			web_color = Color(0.85, 0.08, 0.32, 0.16)
			for i in range(spoke_count):
				spoke_angles.append(float(i) * TAU / 8.0)

	# 2. Filamentos radiales batcheados en multiline
	var spoke_lines = PackedVector2Array()
	for ang in spoke_angles:
		var dir = Vector2(cos(ang), sin(ang))
		var end_pt = hub + dir * 680.0
		spoke_lines.append(hub)
		spoke_lines.append(end_pt)
	if not spoke_lines.is_empty():
		draw_multiline(spoke_lines, web_color, 1.0)

	# 3. Anillos concéntricos poligonales de la telaraña con oscilación viva
	for r_idx in range(web_radii.size()):
		var base_r = web_radii[r_idx]
		var wave_osc = sin(anim_offset * 1.6 + float(r_idx) * 1.1) * 2.2
		var cur_r = base_r + wave_osc
		
		var ring_pts: PackedVector2Array = []
		for ang in spoke_angles:
			var dir = Vector2(cos(ang), sin(ang))
			ring_pts.append(hub + dir * cur_r)
		ring_pts.append(ring_pts[0])

		draw_polyline(ring_pts, web_color, 1.0, false)

# =============================================================================
# MICRO-ANIMACIÓN DE TRANSICIÓN ESPECÍFICA POR TELARAÑA AL CAMBIAR DE MODO
# =============================================================================
func _draw_transition_effect(hub: Vector2, w: float, h: float) -> void:
	var font = ThemeDB.fallback_font
	match transition_type:
		"shockwave_burst":
			# ANIMACIÓN 1 (REPARACIÓN): Triple onda de choque carmesí con chispas de hardware
			var p = transition_progress
			var shock_r1 = p * (w * 0.92)
			var shock_r2 = max(0.0, shock_r1 - 65.0)
			var shock_r3 = max(0.0, shock_r1 - 140.0)
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
				var r = frac * (w * 0.72)
				var theta1 = spiral_rot + frac * TAU * 1.1
				var theta2 = -spiral_rot - frac * TAU * 1.1
				var p1 = hub + Vector2(cos(theta1), sin(theta1)) * r
				var p2 = hub + Vector2(cos(theta2), sin(theta2)) * r
				var line_a = a * (1.0 - frac * 0.5)
				draw_line(prev_p1, p1, Color(0.12, 0.45, 0.95, line_a), 2.2)
				draw_line(prev_p2, p2, Color(0.05, 0.25, 0.75, line_a), 2.2)
				
				# Puntos de código digital en la espiral
				if k % 3 == 0:
					draw_circle(p1, 2.4, Color(0.2, 0.65, 1.0, line_a * 1.3))
					draw_circle(p2, 2.4, Color(0.08, 0.35, 0.85, line_a * 1.3))
				prev_p1 = p1
				prev_p2 = p2
				
			# Detallitos: Fragmentos de código digital y rombo de matriz convergente
			var glyphs = ["01", "0x7F", "SYS", "[KERNEL]", "BIOS", "UEFI", "OK", ">_"]
			for g_i in range(glyphs.size()):
				var g_ang = float(g_i) * TAU / float(glyphs.size()) + spiral_rot * 0.4
				var g_dist = lerp(90.0, 320.0, float(g_i % 4) / 3.0)
				var g_pos = hub + Vector2(cos(g_ang), sin(g_ang)) * g_dist
				var g_alpha = a * 0.65
				draw_string(font, g_pos, glyphs[g_i], HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.18, 0.65, 1.0, g_alpha))
				
			# Rombo de matriz en expansión que sincroniza los diamantes de sistema
			var dia_r = sin(transition_progress * PI) * 220.0
			var dia_pts = PackedVector2Array([
				hub + Vector2(0, -dia_r),
				hub + Vector2(dia_r, 0),
				hub + Vector2(0, dia_r),
				hub + Vector2(-dia_r, 0),
				hub + Vector2(0, -dia_r)
			])
			draw_polyline(dia_pts, Color(0.12, 0.5, 0.95, a * 0.55), 1.6)
				
		"quantum_sweep":
			# ANIMACIÓN 3 (SERVIDOR): Barrido radar 360° con encendido óptico de nodos en Naranja Industrial
			var sweep_ang = transition_sweep_angle
			var sweep_dir = Vector2(cos(sweep_ang), sin(sweep_ang))
			var beam_end = hub + sweep_dir * (w * 0.62)
			var beam_alpha = (1.0 - transition_progress * 0.5) * 0.75
			draw_line(hub, beam_end, Color(1.0, 0.55, 0.08, beam_alpha), 3.2)
			draw_line(hub, beam_end, Color(1.0, 1.0, 1.0, beam_alpha * 0.8), 1.2)
			
			# Abanico fosforescente de barrido naranja
			for s in range(14):
				var lag_ang = sweep_ang - float(s) * 0.07
				var lag_dir = Vector2(cos(lag_ang), sin(lag_ang))
				var lag_alpha = beam_alpha * (1.0 - float(s) / 14.0) * 0.35
				draw_line(hub, hub + lag_dir * (w * 0.60), Color(1.0, 0.35, 0.02, lag_alpha), 1.8)

# =============================================================================
# ENLACE CIRCUIT LINE CON SOPORTE PARA RAÍZ PRINCIPAL
# =============================================================================
func _draw_circuit_line(p1: Vector2, p2: Vector2, alpha: float, seed_val: int, is_primary_root: bool = false, is_practice_link: bool = false) -> void:
	if is_primary_root:
		# RAÍZ PRINCIPAL (TUTORIAL -> NIVEL 1): Filamento cian/azul luminoso
		draw_line(p1, p2, Color(0.0, 0.65, 1.0, 0.35 * alpha), 3.5)
		draw_line(p1, p2, Color(0.4, 0.95, 1.0, alpha), 1.2)
		
		var packet_t1 = fmod(anim_offset * 1.2 + float(seed_val) * 0.14, 1.0)
		var packet_pos1 = p1.lerp(p2, packet_t1)
		draw_circle(packet_pos1, 3.5, Color(0.0, 0.9, 1.0, min(1.0, alpha * 1.8)))
		draw_circle(packet_pos1, 1.8, Color.WHITE)
	elif is_practice_link:
		# ENLACE DE PRÁCTICA (TUTORIAL / NIVEL 1 -> SALA DE PRÁCTICA): Naranja Neón brillante
		draw_line(p1, p2, Color(1.0, 0.45, 0.0, 0.30 * alpha), 3.5)
		draw_line(p1, p2, Color(1.0, 0.70, 0.2, alpha), 1.2)
		
		var packet_tp = fmod(anim_offset * 1.0 + float(seed_val) * 0.14, 1.0)
		var packet_posp = p1.lerp(p2, packet_tp)
		draw_circle(packet_posp, 3.5, Color(1.0, 0.55, 0.05, min(1.0, alpha * 1.8)))
		draw_circle(packet_posp, 1.8, Color.WHITE)
	else:
		draw_line(p1, p2, Color(1.0, 1.0, 1.0, 0.4 * alpha), 1.0)
