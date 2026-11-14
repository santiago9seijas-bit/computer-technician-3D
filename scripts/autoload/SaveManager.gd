extends Node

# =============================================================================
# SAVE MANAGER - SISTEMA DE 5 RANURAS DE GUARDADO (SETS DE PARTIDA)
# Administra persistencia, estadísticas, desbloqueos y cálculo de porcentaje
# =============================================================================

signal slot_selected(slot_index: int, slot_data: Dictionary)
signal slot_saved(slot_index: int)
signal save_loaded(slot_index: int, slot_data: Dictionary)

const TOTAL_SLOTS: int = 5
const SAVE_DIR: String = "user://saves"

var current_slot: int = 1
var slots_cache: Array[Dictionary] = []

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
		"tutorials_completed": 1 if is_first_slot else 0,
		"tutorials_total": 4,
		"levels_completed": 1 if is_first_slot else 0,
		"levels_total": 36,
		"practice_completed": 1 if is_first_slot else 0,
		"practice_total": 3,
		# Secretos y personajes
		"secrets_unlocked": 1 if is_first_slot else 0,
		"secrets_total": 3,
		"characters_unlocked": 1 if is_first_slot else 0,
		"characters_total": 3,
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
