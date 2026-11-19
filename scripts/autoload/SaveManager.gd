extends Node

# =============================================================================
# SAVE MANAGER - SISTEMA DE 5 RANURAS DE GUARDADO (SETS DE PARTIDA)
# Administra persistencia, estadísticas, desbloqueos y cálculo de porcentaje
# =============================================================================

signal slot_selected(slot_index: int, slot_data: Dictionary)
signal slot_saved(slot_index: int)
signal save_loaded(slot_index: int, slot_data: Dictionary)
signal achievement_unlocked(achievement_id: String, achievement_data: Dictionary)
signal glossary_unlocked(topic_id: String, topic_data: Dictionary)

const ACHIEVEMENTS_CONFIG: Dictionary = {
	"first_repair": {
		"title": "Primer Diagnóstico",
		"desc": "Repara tu primera computadora con éxito en el taller.",
		"secret": false,
		"icon": "🔧"
	},
	"repair_5": {
		"title": "Técnico en Ascenso",
		"desc": "Repara 5 computadoras defectuosas en el taller.",
		"secret": false,
		"icon": "⚡"
	},
	"repair_20": {
		"title": "Maestro del Hardware",
		"desc": "Repara 20 computadoras en el taller técnico.",
		"secret": false,
		"icon": "👑"
	},
	"zero_errors": {
		"title": "Precisión Quirúrgica",
		"desc": "Completa un nivel o desafío con cero errores cometidos.",
		"secret": false,
		"icon": "🎯"
	},
	"speed_demon": {
		"title": "Velocista Térmico",
		"desc": "Supera un reto de práctica con más del 50% de tiempo restante.",
		"secret": false,
		"icon": "⏱️"
	},
	"multitasker": {
		"title": "Estación Triple",
		"desc": "Repara las 3 computadoras de un banco de práctica en una sola sesión.",
		"secret": false,
		"icon": "🛠️"
	},
	"clean_workshop": {
		"title": "Taller Ecológico",
		"desc": "Desecha piezas averiadas en la papelera de reciclaje.",
		"secret": false,
		"icon": "🗑️"
	},
	"cpu_expert": {
		"title": "Cirujano de Silicio",
		"desc": "Sustituye un procesador CPU respetando la alineación del socket LGA.",
		"secret": false,
		"icon": "💎"
	},
	"cyber_shield": {
		"title": "Ciberdefensa Total",
		"desc": "Desinfecta una estación eliminando malware y adware.",
		"secret": false,
		"icon": "🛡️"
	},
	"terminal": {
		"title": "Terminal",
		"desc": "Accede a la consola de comandos de desarrollador con [Ctrl + Shift + R].",
		"secret": true,
		"icon": "💻"
	},
	"aliens": {
		"title": "Aliens",
		"desc": "Descubre y activa el juego arcade retro secreto en el menú principal.",
		"secret": true,
		"icon": "👾"
	},
	"throw_master": {
		"title": "Lanzador de Gabinetes",
		"desc": "Carga la barra de fuerza y arroja un gabinete por el aire con la tecla [F].",
		"secret": true,
		"icon": "🚀"
	}
}

const TOTAL_SLOTS: int = 5
const SAVE_DIR: String = "user://saves"

var current_slot: int = 1
var slots_cache: Array[Dictionary] = []
static var just_unlocked_node: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_save_directory()
	load_all_slots()

func _ensure_save_directory() -> void:
	var da = DirAccess.open("user://")
	if da:
		if not da.dir_exists("saves"):
			da.make_dir_recursive("saves")
	elif not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func _get_slot_file_path(slot_index: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot_index]

func load_all_slots() -> void:
	slots_cache.clear()
	for i in range(1, TOTAL_SLOTS + 1):
		var data = _load_slot_file(i)
		slots_cache.append(data)

func _load_slot_file(slot_index: int) -> Dictionary:
	var path = _get_slot_file_path(slot_index)
	if FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.READ)
		if f:
			var json_str = f.get_as_text()
			f.close()
			var test_json = JSON.new()
			var parse_err = test_json.parse(json_str)
			if parse_err == OK and typeof(test_json.data) == TYPE_DICTIONARY:
				var d = test_json.data as Dictionary
				d["completion_percentage"] = calculate_completion_percentage(d)
				return d
	# Si no existe archivo en disco, creamos el slot predeterminado
	return _create_default_slot_data(slot_index)

func _create_default_slot_data(slot_index: int) -> Dictionary:
	# El slot 1 incluye progreso inicial de bienvenida si es nuevo
	var is_first_slot = (slot_index == 1)
	return {
		"slot_index": slot_index,
		"slot_name": "Partida %d" % slot_index,
		"is_empty": not is_first_slot,
		"last_played": "13/11/2026 - 18:00" if is_first_slot else "--/--/----",
		"score": 1720 if is_first_slot else 0,
		"stars": 3 if is_first_slot else 0,
		# 5 herramientas: Cruz (+), Pala (-), Cautín, Multímetro, Limpiador
		"tools": [
			{"id": 1, "name": "Destornillador Cruz (+)", "unlocked": true},
			{"id": 2, "name": "Destornillador Pala (-)", "unlocked": true},
			{"id": 3, "name": "Cautín Térmico", "unlocked": is_first_slot},
			{"id": 4, "name": "Multímetro Digital", "unlocked": is_first_slot},
			{"id": 5, "name": "Limpiador Antiestático", "unlocked": is_first_slot}
		],
		# Medallas de los 3 modos
		"medals": {
			"reparacion": is_first_slot,
			"sistema": false,
			"servidor": false
		},
		# Niveles y entrenamiento
		"tutorials_completed": 0,
		"tutorials_total": 7,
		"levels_completed": 0,
		"levels_total": 36,
		"practice_completed": 0,
		"practice_total": 7,
		# Nodos desbloqueados y completados por modo (Solo Tutorial 0 desbloqueado al inicio)
		"unlocked_nodes": {
			"reparacion": [0],
			"sistema": [0],
			"servidor": [0]
		},
		"completed_nodes": {
			"reparacion": [],
			"sistema": [],
			"servidor": []
		},
		# Secretos y personajes
		"secrets_unlocked": 1 if is_first_slot else 0,
		"secrets_total": 3,
		"characters_unlocked": 1 if is_first_slot else 0,
		"characters_total": 3,
		"achievements": {},
		"glossary_unlocked": {"intro": true},
		"completion_percentage": 25.0 if is_first_slot else 0.0
	}

func calculate_completion_percentage(data: Dictionary) -> float:
	if data.get("is_empty", true):
		return 0.0

	var total_points: float = 0.0
	var max_points: float = 100.0

	# 1. Herramientas (5 en total = 20 pts)
	var tools = data.get("tools", [])
	var unlocked_tools = 0
	for t in tools:
		if t.get("unlocked", false):
			unlocked_tools += 1
	total_points += (float(unlocked_tools) / 5.0) * 20.0

	# 2. Medallas de los 3 modos (3 en total = 20 pts)
	var medals = data.get("medals", {})
	var unlocked_medals = 0
	for m_key in ["reparacion", "sistema", "servidor"]:
		if medals.get(m_key, false):
			unlocked_medals += 1
	total_points += (float(unlocked_medals) / 3.0) * 20.0

	# 3. Niveles completados (36 en total = 30 pts)
	var lvl_comp = float(data.get("levels_completed", 0))
	var lvl_tot = float(data.get("levels_total", 36))
	if lvl_tot > 0:
		total_points += (lvl_comp / lvl_tot) * 30.0

	# 4. Tutoriales y Prácticas (4 + 3 = 7 = 15 pts)
	var tut_comp = float(data.get("tutorials_completed", 0))
	var prac_comp = float(data.get("practice_completed", 0))
	total_points += clampf((tut_comp + prac_comp) / 7.0, 0.0, 1.0) * 15.0

	# 5. Secretos y Personajes (3 + 3 = 6 = 15 pts)
	var sec_comp = float(data.get("secrets_unlocked", 0))
	var char_comp = float(data.get("characters_unlocked", 0))
	total_points += clampf((sec_comp + char_comp) / 6.0, 0.0, 1.0) * 15.0

	return clampf(snappedf(total_points, 0.1), 0.0, 100.0)

func get_slot(slot_index: int) -> Dictionary:
	var idx = slot_index - 1
	if idx >= 0 and idx < slots_cache.size():
		return slots_cache[idx]
	return _create_default_slot_data(slot_index)

func save_slot(slot_index: int, data: Dictionary) -> bool:
	_ensure_save_directory()
	data["slot_index"] = slot_index
	data["completion_percentage"] = calculate_completion_percentage(data)
	data["is_empty"] = false
	
	var time_dict = Time.get_datetime_dict_from_system()
	data["last_played"] = "%02d/%02d/%04d - %02d:%02d" % [
		time_dict.day, time_dict.month, time_dict.year, time_dict.hour, time_dict.minute
	]

	var idx = slot_index - 1
	if idx >= 0 and idx < slots_cache.size():
		slots_cache[idx] = data
	elif idx >= slots_cache.size():
		slots_cache.append(data)

	var path = _get_slot_file_path(slot_index)
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f:
		var json_str = JSON.stringify(data, "\t")
		f.store_string(json_str)
		f.close()
		slot_saved.emit(slot_index)
		return true
	return false

func select_and_apply_slot(slot_index: int) -> Dictionary:
	current_slot = slot_index
	var data = get_slot(slot_index)
	if data.get("is_empty", true):
		data["is_empty"] = false
		data["last_played"] = "Recién iniciada"
		save_slot(slot_index, data)

	# Aplicar datos a GameManager
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.score = data.get("score", 0)
		if gm.has_signal("score_updated"):
			gm.score_updated.emit(gm.score, 0)
		
	save_loaded.emit(slot_index, data)
	return data

func reset_slot(slot_index: int) -> Dictionary:
	var fresh_data = _create_default_slot_data(slot_index)
	fresh_data["is_empty"] = true
	fresh_data["score"] = 0
	fresh_data["stars"] = 0
	fresh_data["last_played"] = "--/--/----"
	fresh_data["completion_percentage"] = 0.0
	for t in fresh_data["tools"]:
		t["unlocked"] = (t["id"] <= 2) # Solo las dos primeras por defecto
	fresh_data["medals"] = {"reparacion": false, "sistema": false, "servidor": false}
	fresh_data["tutorials_completed"] = 0
	fresh_data["levels_completed"] = 0
	fresh_data["practice_completed"] = 0
	fresh_data["secrets_unlocked"] = 0
	fresh_data["characters_unlocked"] = 0

	var idx = slot_index - 1
	if idx >= 0 and idx < slots_cache.size():
		slots_cache[idx] = fresh_data

	var path = _get_slot_file_path(slot_index)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

	slot_saved.emit(slot_index)
	return fresh_data

func is_node_unlocked(mode: String, node_idx: int) -> bool:
	# El nivel de introducción (nodo 0) de reparación, sistemas y servidor siempre está desbloqueado
	if node_idx == 0:
		return true
	# Los niveles morados de inspección se desbloquean al completar sus niveles de campaña padre
	if mode == "reparacion":
		if (node_idx == 26 or node_idx == 27) and is_node_completed("reparacion", 7):
			return true
		if node_idx == 28 and is_node_completed("reparacion", 10):
			return true
		if node_idx == 29 and is_node_completed("reparacion", 13):
			return true
		if (node_idx == 30 or node_idx == 31) and is_node_completed("reparacion", 12):
			return true
	var data = get_slot(current_slot)
	var unl_dict = data.get("unlocked_nodes", {})
	var list = unl_dict.get(mode, [0])
	return (node_idx in list)

func unlock_node(mode: String, node_idx: int) -> void:
	var data = get_slot(current_slot)
	if not data.has("unlocked_nodes"):
		data["unlocked_nodes"] = {"reparacion": [0], "sistema": [0], "servidor": [0]}
	var unl_dict = data["unlocked_nodes"]
	if not unl_dict.has(mode):
		unl_dict[mode] = [0]
	var list: Array = unl_dict[mode]
	if not (node_idx in list):
		list.append(node_idx)
		save_slot(current_slot, data)

func is_node_completed(mode: String, node_idx: int) -> bool:
	var data = get_slot(current_slot)
	var comp_dict = data.get("completed_nodes", {})
	var list = comp_dict.get(mode, [])
	return (node_idx in list)

func mark_node_completed(mode: String, node_idx: int) -> void:
	var data = get_slot(current_slot)
	if not data.has("completed_nodes"):
		data["completed_nodes"] = {"reparacion": [], "sistema": [], "servidor": []}
	var comp_dict = data["completed_nodes"]
	if not comp_dict.has(mode):
		comp_dict[mode] = []
	var list: Array = comp_dict[mode]
	if not (node_idx in list):
		list.append(node_idx)
		if mode == "reparacion":
			if node_idx in [0, 1, 2, 3, 4, 5, 6]:
				data["tutorials_completed"] = int(data.get("tutorials_completed", 0)) + 1
			elif node_idx in [25, 19, 20, 21, 22, 23, 24]:
				data["practice_completed"] = int(data.get("practice_completed", 0)) + 1
			elif node_idx in range(7, 19):
				data["levels_completed"] = int(data.get("levels_completed", 0)) + 1
		save_slot(current_slot, data)

func unlock_all_levels() -> void:
	var data = get_slot(current_slot)
	var all_rep: Array = []
	for i in range(26):
		all_rep.append(i)
	var all_sis: Array = []
	for i in range(26):
		all_sis.append(i)
	var all_srv: Array = []
	for i in range(14):
		all_srv.append(i)
	data["unlocked_nodes"] = {
		"reparacion": all_rep,
		"sistema": all_sis,
		"servidor": all_srv
	}
	save_slot(current_slot, data)

func reset_progression_lock() -> void:
	var data = get_slot(current_slot)
	data["unlocked_nodes"] = {
		"reparacion": [0],
		"sistema": [0],
		"servidor": [0]
	}
	data["completed_nodes"] = {
		"reparacion": [],
		"sistema": [],
		"servidor": []
	}
	save_slot(current_slot, data)

const GLOSSARY_TOPICS: Dictionary = {
	"intro": {
		"id": "intro",
		"title": "Fundamentos de Taller & Electricidad Estática (ESD)",
		"category": "HARDWARE",
		"tutorial_node": 0,
		"component_key": "general",
		"icon": "⚡",
		"summary": "Seguridad eléctrica, herramientas de precisión y banco de pruebas.",
		"content": """• Protocolo de Descarga Electrostática (ESD):
El cuerpo humano puede acumular más de 3.000 voltios de energía estática sin que lo percibamos; una sola descarga de 100V es suficiente para destruir las pistas microscópicas de un chip de silicio. Antes de tocar cualquier componente interno, debes descargar tu potencial tocando el chasis metálico o utilizando una pulsera antiestática conectada a tierra.

• Clasificación de Herramientas del Taller:
1. Destornillador Phillips / Cruz (#1 y #2): Diseñado con ranura en cruz que centra la fuerza y previene el deslizamiento (cam-out). Se utiliza en la fijación de placas madre, fuentes de poder, tarjetas gráficas y chasis.
2. Destornillador de Pala / Plano: Utilizado para desatornillar brackets específicos, apalancar trabas plásticas y ajustes mecánicos finos.
3. Cautín Térmico de Soldadura: Para reemplazar condensadores electrolíticos hinchados o resoldar pistas superficiales dañadas.
4. Multímetro Digital (True-RMS): Medición de voltajes de rieles (+12V, +5V, +3.3V) y prueba de continuidad acústica en pistas cortadas.
5. Soplador / Limpiador Antiestático: Disolución de grasa y polvo con alcohol isopropílico de alta pureza (99.8%) sin dejar residuos conductores."""
	},
	"cooler": {
		"id": "cooler",
		"title": "Disipación Térmica & Fan Coolers PWM",
		"category": "HARDWARE",
		"tutorial_node": 1,
		"component_key": "cooler",
		"icon": "❄️",
		"summary": "Transferencia de calor, control PWM de 4 pines y pastas térmicas.",
		"content": """• Principios de Transferencia Térmica:
El microprocesador moderno concentra más de 150 vatios de calor en un die de silicio de menos de 3 cm². La disipación depende del contacto directo del IHS (Integrated Heat Spreader) de cobre niquelado con la base del disipador a través de una interfaz térmica (TIM).

• Compuestos y Pastas Térmicas:
La pasta térmica rellena las micro-imperfecciones microscópicas del metal que de otro modo quedarían ocupadas por aire (un pésimo conductor térmico con solo 0.026 W/mK). Las pastas cerámicas y de óxido metálico de alto rendimiento ofrecen conductividades entre 8.5 y 14 W/mK. Nunca utilices metal líquido sobre disipadores de aluminio, ya que el galio corroe químicamente el aluminio en minutos.

• Conexión PWM de 4 Pines (CPU_FAN):
A diferencia de los ventiladores antiguos de 3 pines regulados por voltaje, el conector PWM de 4 pines utiliza modulación por ancho de pulsos:
- Pin 1: Tierra (GND - Negro)
- Pin 2: Alimentación (+12V - Amarillo)
- Pin 3: Sensor de Tacómetro / Hall (Sensor de RPM - Verde)
- Pin 4: Señal de Control PWM (25 kHz - Azul), permitiendo que la placa madre module la velocidad de 0% a 100% sin caídas de torque.

• Procedimiento de Ajuste en Cruz (X):
Al fijar los 4 tornillos con resorte del disipador, aprieta siempre en patrón diagonal en cruz (1 vuelta a cada tornillo alternado). Esto evita presiones asimétricas que podrían astillar el silicio o deformar los pines del zócalo."""
	},
	"ram": {
		"id": "ram",
		"title": "Bancos de Memoria RAM DDR & Buses",
		"category": "HARDWARE",
		"tutorial_node": 2,
		"component_key": "ram",
		"icon": "🗂️",
		"summary": "Módulos DIMM, arquitectura Dual Channel, frecuencias y latencias CAS.",
		"content": """• Arquitectura de la Memoria Volátil (DRAM):
La memoria RAM almacena las instrucciones activas que la CPU ejecuta en tiempo real. Cada bit se almacena en una celda compuesta por un minúsculo transistor y un condensador que debe refrescarse eléctricamente miles de veces por segundo.

• Comparativa Generacional:
- DDR4: 288 pines, voltaje estándar de 1.2V, frecuencias de 2133 MHz a 3600+ MHz.
- DDR5: 288 pines (muesca central reposicionada para evitar incompatibilidad física), voltaje de 1.1V, frecuencias de 4800 MHz a 7200+ MHz. Incorpora gestión de energía interna (PMIC) en el propio módulo y circuito On-Die ECC para autocorrección de errores de bit.

• Arquitectura Dual Channel (Doble Canal):
Al colocar dos módulos idénticos en ranuras alternadas (típicamente A2 y B2, ranuras 2 y 4), el controlador de memoria integrado en la CPU (IMC) duplica el bus de datos de 64 bits a 128 bits, incrementando hasta un 40% el rendimiento en procesamiento gráfico y juegos.

• Latencia CAS (Column Address Strobe):
El valor CL indica el número de ciclos de reloj que transcurren entre el envío de una petición de columna y la disponibilidad del dato en los pines de salida. Una memoria DDR4-3200 CL16 tiene un tiempo de respuesta efectivo menor que una DDR4-3200 CL22.

• Diagnóstico y Mantenimiento:
Los códigos de error POST con 3 pitidos largos o pantallas azules 'MEMORY_MANAGEMENT' y 'PFN_LIST_CORRUPT' suelen deberse a suciedad en los contactos dorados. Retira el módulo abriendo las palancas laterales y limpia los contactos con alcohol isopropílico o goma antiestática."""
	},
	"hdd": {
		"id": "hdd",
		"title": "Almacenamiento NVMe M.2 & Discos SATA III",
		"category": "HARDWARE",
		"tutorial_node": 3,
		"component_key": "hdd",
		"icon": "💾",
		"summary": "Protocolo NVMe PCIe x4, SSDs NAND Flash y discos magnéticos SATA.",
		"content": """• SSD NVMe M.2 (Non-Volatile Memory Express):
Los SSDs modernos en factor de forma 2280 (22 mm de ancho por 80 mm de largo) se comunican directamente con el bus PCIe de la CPU sin intermediarios de chipset. Un SSD NVMe PCIe 4.0 x4 alcanza velocidades de lectura secuencial de hasta 7.500 MB/s con tiempos de acceso inferiores a 0.03 milisegundos.
- Regla de oro de desensamble: Tras retirar el tornillo del standoff, el módulo se eleva automáticamente a 30 grados. Nunca tires hacia arriba; deslícelo suavemente en diagonal respetando la ranura M-Key.

• Discos Duros Mecánicos (HDD SATA III):
Almacenamiento magnético compuesto por platos de aluminio o vidrio recubiertos de aleación ferromagnética que giran a 5.400 o 7.200 RPM, sobre los cuales flotan cabezales de lectura/escritura a menos de 5 nanómetros de la superficie.
- Limitaciones: Conectados por bus SATA III (máximo teórico 600 MB/s, velocidad real 180-220 MB/s). Susceptibles a golpes que causan el destructivo 'head crash' (el cabezal impacta el plato rayando la superficie magnética).

• Sistema SMART y Detección de Averías:
El sistema S.M.A.R.T. (Self-Monitoring, Analysis and Reporting Technology) monitoriza atributos críticos como 'Reallocated Sectors Count' y 'Pending Sector Count'. Si estos valores aumentan, el disco está al borde del colapso mecánico y debe sustituirse de inmediato."""
	},
	"gpu": {
		"id": "gpu",
		"title": "Tarjetas Gráficas PCIe & Procesamiento 3D",
		"category": "HARDWARE",
		"tutorial_node": 4,
		"component_key": "gpu",
		"icon": "🎮",
		"summary": "Ranuras PCIe x16, memoria VRAM GDDR6, brackets y rieles de potencia.",
		"content": """• El Procesador Gráfico (GPU):
Un chip masivamente paralelo diseñado con miles de unidades de sombreado (Shaders/Cores) optimizadas para operaciones matriciales simultáneas, renderizado poligonal e inferencia de redes neuronales.

• Memoria de Video Dedicada (VRAM):
La memoria GDDR6 y GDDR6X opera con anchos de bus de 128 a 384 bits, alcanzando anchos de banda superiores a 900 GB/s. Si un módulo VRAM se sobrecalienta o sus bolas de soldadura BGA se fracturan, aparecen en pantalla artefactos visuales característicos (líneas punteadas, matrices de cuadros verdes y glitches de renderizado).

• Ranura PCIe x16 y Alimentación Auxiliar:
- La ranura física PCIe x16 suministra un máximo de 75W a través de los pines de la placa madre.
- Tarjetas gaming de gama media y alta requieren conectores suplementarios PCIe de 8 pines (150W cada uno) o el nuevo conector 12VHPWR (hasta 600W).
- Desmontaje seguro: Afloja los tornillos del bracket metálico en el chasis, desconecta los arneses de energía y presiona firmemente la pestaña plástica de retención al final del zócalo PCIe antes de tirar verticalmente."""
	},
	"psu": {
		"id": "psu",
		"title": "Fuentes de Poder ATX & Rieles de Voltaje",
		"category": "HARDWARE",
		"tutorial_node": 5,
		"component_key": "psu",
		"icon": "🔋",
		"summary": "Conversión AC-DC, rieles de 12V/5V/3.3V, arneses EPS y certificación 80 Plus.",
		"content": """• Función Crítica de la Fuente de Alimentación:
Transforma la corriente alterna de alto voltaje de la pared (110V/220V AC a 50/60 Hz) en voltajes continuos estables y de bajo rizado (DC) que los componentes digitales requieren para operar.

• Distribución de los Rieles de Potencia:
- Riel +12V: El riel primordial en PCs modernas. Suministra entre el 85% y 95% de la potencia total del equipo para alimentar la CPU (mediante conector EPS 8 pines) y la GPU (conectores PCIe).
- Rieles +5V y +3.3V: Alimentan los chips controladores de la placa madre, circuitos lógicos de almacenamiento SATA y puertos USB.
- Riel +5VSB (Standby): Suministra corriente continua aun cuando la PC esté apagada, permitiendo que el botón frontal de encendido envíe la señal de arranque (PS_ON#) a tierra.

• Certificaciones de Eficiencia 80 Plus:
Indican el porcentaje de energía que la fuente convierte en corriente útil sin disiparla en calor:
- 80 Plus White: 80% de eficiencia al 50% de carga.
- 80 Plus Bronze: 85% de eficiencia.
- 80 Plus Gold: 90% de eficiencia.
- 80 Plus Platinum: 92% de eficiencia.
- 80 Plus Titanium: 94% de eficiencia.

• Protocolo de Diagnóstico de Fallas:
Si la computadora se apaga bruscamente bajo carga 3D, revisa con un voltímetro que el riel de +12V no caiga por debajo de 11.40V (tolerancia ±5%). Olores a plástico quemado o capacitores abombados indican daño severo en los transistores MOSFET del primario."""
	},
	"cpu": {
		"id": "cpu",
		"title": "Microprocesadores & Socket LGA",
		"category": "HARDWARE",
		"tutorial_node": 6,
		"component_key": "cpu",
		"icon": "🧠",
		"summary": "Arquitectura x86, zócalo LGA, palanca de retención y pines dorados.",
		"content": """• La Unidad Central de Procesamiento (CPU):
El cerebro lógico de la computadora. En su interior alberga miles de millones de transistores FinFET o GAA de pocos nanómetros que ejecutan el ciclo continuo de 'Fetch, Decode, Execute y Writeback'.

• Zócalo LGA (Land Grid Array):
A diferencia de los zócalos PGA donde los pines están soldados al procesador, en la arquitectura LGA los delicados pines de contacto están integrados en la placa madre, mientras que el procesador cuenta con almohadillas doradas lisas.
- Advertencia crítica: Un solo pin doblado en el zócalo puede cortar la comunicación con un canal de memoria RAM o provocar pantallas azules de bus WHEA. Nunca toques los pines con los dedos ni con paños de tela.

• Mecanismo de Palanca y Triángulo Orientador:
Para instalar un CPU LGA, libera la palanca metálica lateral empujándola hacia afuera y hacia arriba. Alinea la esquina marcada con un triángulo dorado impreso con la flecha grabada en el zócalo de la placa madre. El procesador debe encajar por gravedad sin necesidad de aplicar presión física."""
	},
	"sistemas_os": {
		"id": "sistemas_os",
		"title": "Tablas de Particiones GPT & Despliegue Andromeda OS",
		"category": "SISTEMAS",
		"tutorial_node": 101,
		"component_key": "os_install",
		"icon": "💻",
		"summary": "Esquema GPT, particiones EFI de arranque y montaje de sistemas operativos.",
		"content": """• Evolución de MBR a GPT:
- MBR (Master Boot Record): Esquema heredado con sector de arranque en el LBA 0. Limitado a 4 particiones primarias y unidades de hasta 2.2 Terabytes.
- GPT (GUID Partition Table): Estándar moderno basado en identificadores globales únicos de 128 bits. Soporta hasta 128 particiones primarias y discos de hasta 9.4 Zettabytes. Incluye una copia de respaldo de la tabla al final del disco para recuperación automática.

• La Partición del Sistema EFI (ESP):
Partición especial formateada en FAT32 que almacena los cargadores de arranque (.efi), controladores de dispositivo de firmware y utilidades del sistema. El firmware UEFI lee esta partición directamente en el inicio sin depender del código binario del sector cero.

• Despliegue de Andromeda OS:
1. Limpieza de tablas corruptas mediante comando sgdisk / gdisk.
2. Creación de la partición EFI de 512 MB tipo ef00.
3. Creación de la partición raíz tipo 8300 formateada con Ext4 o Btrfs.
4. Desempaquetado de la imagen del kernel y sincronización de UUIDs en /etc/fstab."""
	},
	"sistemas_malware": {
		"id": "sistemas_malware",
		"title": "Ciberdefensa Heurística & Purga de Malware",
		"category": "SISTEMAS",
		"tutorial_node": 102,
		"component_key": "malware_scan",
		"icon": "🛡️",
		"summary": "Análisis heurístico, aislamiento de troyanos, adware y sanitización de memoria.",
		"content": """• Vectores de Ataque en Sistemas Técnicos:
- Troyanos de Acceso Remoto (RAT): Programas que aparentan ser software legítimo pero abren puertos de escucha para control externo y robo de credenciales.
- Ransomware: Criptovirus que secuestra el sistema de archivos cifrando bloques con algoritmos asimétricos RSA/AES.
- Mineros Ocultos (Cryptojackers): Procesos camuflados que consumen el 100% de los hilos de CPU y GPU elevando la temperatura de los ventiladores al límite.
- Adware y Hijackers: Inyección de código malicioso en navegadores que satura la pantalla con pop-ups fraudulentos y desvía peticiones DNS.

• Metodología de Purga y Desinfección:
1. Aislamiento de Red: Desconecta interfaces Ethernet / WiFi para frenar la exfiltración de paquetes y sincronización de claves de comando.
2. Análisis de Procesos: Identificación de binarios con nombres engañosos (ej. svch0st.exe o system_updater) ejecutándose desde carpetas temporales (%APPDATA% o /tmp).
3. Terminación de Procesos e Hilos Hijos: Uso de herramientas de análisis para forzar el cierre del árbol de procesos.
4. Limpieza del Registro y Tareas Programadas: Eliminación de persistencias en Run/RunOnce y servicios no firmados."""
	},
	"sistemas_drivers": {
		"id": "sistemas_drivers",
		"title": "Controladores WHQL & Conflictos de Bus DMA",
		"category": "SISTEMAS",
		"tutorial_node": 103,
		"component_key": "driver_install",
		"icon": "⚙️",
		"summary": "Certificación de drivers WHQL, transferencias DMA y prevención de BSODs.",
		"content": """• ¿Qué es un Controlador de Dispositivo (Driver)?:
Un puente de software que permite al kernel del sistema operativo comunicarse con las instrucciones físicas de un microchip. Los drivers operan en el nivel de privilegios más alto del procesador (Ring 0).

• Riesgo de Pantallas Azules (BSOD):
Un error en una aplicación común (Ring 3) solo cierra la ventana. Sin embargo, si un controlador en Ring 0 intenta acceder a una dirección de memoria inválida o sufre un bloqueo de interrupción IRQ, el procesador dispara un Kernel Panic / BSOD (como DRIVER_IRQL_NOT_LESS_OR_EQUAL) para proteger la integridad del hardware.

• Certificación WHQL (Windows Hardware Quality Labs):
Garantiza que el paquete de controladores ha superado pruebas exhaustivas de estrés computacional, gestión de energía (estados ACPI S3/S4) y estabilidad de renderizado.

• Protocolo de Actualización Segura:
1. Purgar controladores obsoletos utilizando utilidades de limpieza en modo a prueba de fallos.
2. Validar que la firma digital del nuevo paquete coincida con la autoridad de certificación oficial.
3. Reiniciar el subsistema gráfico para calibrar resoluciones nativas y frecuencias de refresco."""
	}
}

var _toast_canvas: CanvasLayer = null
var pending_glossary_toast_topic: String = ""

func unlock_achievement(achievement_id: String) -> bool:
	if not ACHIEVEMENTS_CONFIG.has(achievement_id):
		return false
	var data = get_slot(current_slot)
	if not data.has("achievements") or typeof(data["achievements"]) != TYPE_DICTIONARY:
		data["achievements"] = {}
	var ach_dict = data["achievements"]
	if ach_dict.get(achievement_id, false):
		return false # Ya desbloqueado previamente
	
	ach_dict[achievement_id] = true
	save_slot(current_slot, data)
	
	var ach_info = ACHIEVEMENTS_CONFIG[achievement_id]
	achievement_unlocked.emit(achievement_id, ach_info)
	
	# Mostrar notificación llamativa abajo a la derecha de la pantalla (5 segundos, clickeable)
	show_toast_notification(
		"¡NUEVO LOGRO DESBLOQUEADO!",
		ach_info["title"],
		"achievement",
		func(): open_extras_modal("logros")
	)
	return true

func is_achievement_unlocked(achievement_id: String) -> bool:
	var data = get_slot(current_slot)
	var ach_dict = data.get("achievements", {})
	if typeof(ach_dict) != TYPE_DICTIONARY:
		return false
	return ach_dict.get(achievement_id, false)

func get_unlocked_achievements_count() -> int:
	var count = 0
	for k in ACHIEVEMENTS_CONFIG.keys():
		if is_achievement_unlocked(k):
			count += 1
	return count

func get_total_achievements_count() -> int:
	return ACHIEVEMENTS_CONFIG.size()

func unlock_glossary(topic_id: String) -> bool:
	# Normalizar ID de tema
	var norm_id = topic_id.to_lower()
	if norm_id == "general":
		norm_id = "intro"
	elif norm_id == "os_install":
		norm_id = "sistemas_os"
	elif norm_id == "malware_scan":
		norm_id = "sistemas_malware"
	elif norm_id == "driver_install":
		norm_id = "sistemas_drivers"
		
	if not GLOSSARY_TOPICS.has(norm_id):
		return false
		
	var data = get_slot(current_slot)
	if not data.has("glossary_unlocked") or typeof(data["glossary_unlocked"]) != TYPE_DICTIONARY:
		data["glossary_unlocked"] = {"intro": true}
	var gl_dict = data["glossary_unlocked"]
	if gl_dict.get(norm_id, false):
		return false
		
	gl_dict[norm_id] = true
	save_slot(current_slot, data)
	
	var topic_info = GLOSSARY_TOPICS[norm_id]
	glossary_unlocked.emit(norm_id, topic_info)
	
	# Mostrar notificación llamativa abajo a la derecha de la pantalla (5 segundos, clickeable)
	show_toast_notification(
		"¡GLOSARIO TÉCNICO ACTUALIZADO!",
		topic_info["title"],
		"glossary",
		func(): open_extras_modal("explicaciones")
	)
	return true

func is_glossary_unlocked(topic_id: String) -> bool:
	var norm_id = topic_id.to_lower()
	if norm_id in ["general", "intro"]:
		return true # Siempre disponible al inicio
	var data = get_slot(current_slot)
	var gl_dict = data.get("glossary_unlocked", {})
	if typeof(gl_dict) != TYPE_DICTIONARY:
		return false
	return gl_dict.get(norm_id, false)

func trigger_pending_glossary_notification() -> void:
	if pending_glossary_toast_topic != "":
		var t_id = pending_glossary_toast_topic
		pending_glossary_toast_topic = ""
		unlock_glossary(t_id)

func show_toast_notification(header: String, title: String, type: String = "achievement", callback: Callable = Callable()) -> void:
	if not _toast_canvas or not is_instance_valid(_toast_canvas):
		_toast_canvas = CanvasLayer.new()
		_toast_canvas.layer = 250
		_toast_canvas.name = "CyberToastCanvas"
		get_tree().root.add_child(_toast_canvas)
		
	var toast_scene = load("res://scenes/ui/CyberNotificationToast.tscn")
	if not toast_scene:
		return
	var toast = toast_scene.instantiate()
	_toast_canvas.add_child(toast)
	
	if type == "achievement":
		toast.setup_achievement(title, header, callback)
	else:
		toast.setup_glossary(title, callback)

func open_extras_modal(initial_tab: String = "logros") -> void:
	var existing = get_tree().root.find_child("ExtrasModal", true, false)
	if existing:
		if existing.has_method("_switch_tab"):
			existing._switch_tab(initial_tab)
		return
	var scene = load("res://scenes/ui/ExtrasModal.tscn")
	if scene:
		var modal = scene.instantiate()
		modal.name = "ExtrasModal"
		if modal.has_method("set_initial_tab"):
			modal.set_initial_tab(initial_tab)
		get_tree().root.add_child(modal)



