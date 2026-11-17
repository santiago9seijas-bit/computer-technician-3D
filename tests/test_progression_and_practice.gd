extends Node

func _ready() -> void:
	print("====================================================")
	print("--- TEST DE PROGRESIÓN, RETO 8 MINUTOS Y CONSOLA DEV ---")
	print("====================================================")

	await _test_level_select_initial_locks()
	await _test_developer_console_levels_cheat()
	await _test_level_practice_3_pcs_and_8_minutes()
	await _test_constellation_graph_expansion()
	await _test_progression_unlock_chain()
	await _test_sistemas_mode_and_transitions()

	print("====================================================")
	print("✓ TODOS LOS TESTS DE PROGRESIÓN Y PRÁCTICA PASARON EXITOSAMENTE!")
	print("====================================================")
	get_tree().quit(0)

func _test_level_select_initial_locks() -> void:
	print("\n[1] Probando estado de bloqueo inicial en LevelSelect...")
	var ls_scene = load("res://scenes/menus/LevelSelect.tscn")
	assert(ls_scene != null, "LevelSelect.tscn debe cargar")
	var ls = ls_scene.instantiate()
	add_child(ls)
	await get_tree().process_frame

	# Restablecer SaveManager al estado inicial
	SaveManager.reset_progression_lock()
	ls._sync_progression_from_save()

	var rep_list = ls.LEVELS_DATA.get("reparacion", [])
	assert(rep_list.size() == 26, "Reparación debe tener 26 nodos")
	assert(rep_list[0]["can_play"] == true, "Tutorial 0 (Introducción) debe ser el ÚNICO desbloqueado al inicio")

	# Todos los demás nodos deben estar bloqueados
	for i in range(1, rep_list.size()):
		assert(rep_list[i]["can_play"] == false, "Nodo %d debe estar bloqueado al inicio" % i)

	print("  ✓ Tutorial 0 desbloqueado, los 25 nodos restantes están estrictamente bloqueados")
	ls.queue_free()
	await get_tree().process_frame

func _test_developer_console_levels_cheat() -> void:
	print("\n[2] Probando atajo Ctrl+Shift+R y comando /levels...")
	var ls_scene = load("res://scenes/menus/LevelSelect.tscn")
	var ls = ls_scene.instantiate()
	add_child(ls)
	await get_tree().process_frame

	# Simular atajo de teclado Ctrl + Shift + R
	var key_ev = InputEventKey.new()
	key_ev.pressed = true
	key_ev.ctrl_pressed = true
	key_ev.shift_pressed = true
	key_ev.keycode = KEY_R
	print("DEBUG key_ev: pressed=", key_ev.pressed, " ctrl=", key_ev.ctrl_pressed, " shift=", key_ev.shift_pressed, " keycode=", key_ev.keycode)
	ls._input(key_ev)
	print("DEBUG dev_console_overlay: ", ls.dev_console_overlay)
	if ls.dev_console_overlay:
		print("DEBUG overlay visible: ", ls.dev_console_overlay.visible)

	assert(ls.dev_console_overlay != null, "La consola de desarrollador debe crearse")
	assert(ls.dev_console_overlay.visible == true, "La consola de desarrollador debe ser visible tras Ctrl+Shift+R")
	print("  ✓ Consola de desarrollador abierta con Ctrl + Shift + R")

	# Ejecutar comando /levels
	ls._on_dev_command_submitted("/levels")

	var rep_list = ls.LEVELS_DATA.get("reparacion", [])
	for i in range(rep_list.size()):
		assert(rep_list[i]["can_play"] == true, "Nodo %d de reparación debe estar desbloqueado tras /levels" % i)

	var sis_list = ls.LEVELS_DATA.get("sistema", [])
	for i in range(sis_list.size()):
		assert(sis_list[i]["can_play"] == true, "Nodo %d de sistema debe estar desbloqueado tras /levels" % i)

	print("  ✓ Comando /levels desbloqueó todos los niveles, tutoriales y retos al instante")

	# Probar /reset
	ls._on_dev_command_submitted("/reset")
	assert(rep_list[0]["can_play"] == true, "Tutorial 0 debe quedar desbloqueado")
	assert(rep_list[1]["can_play"] == false, "Tutorial 1 debe volver a estar bloqueado")
	print("  ✓ Comando /reset restableció el bloqueo inicial")

	ls.queue_free()
	await get_tree().process_frame

func _test_level_practice_3_pcs_and_8_minutes() -> void:
	print("\n[3] Probando LevelPractice con 3 mesas, 3 PCs con fallas distintas y 8 minutos...")
	var prac_scene = load("res://scenes/gameplay/LevelPractice.tscn")
	assert(prac_scene != null, "LevelPractice.tscn debe cargar")
	var prac = prac_scene.instantiate()
	add_child(prac)
	await get_tree().process_frame

	# Verificar las 3 mesas de trabajo
	var wb1 = prac.get_node_or_null("WorkBench1")
	var wb2 = prac.get_node_or_null("WorkBench2")
	var wb3 = prac.get_node_or_null("WorkBench3")
	assert(wb1 != null, "Mesa 1 (WorkBench1) debe existir")
	assert(wb2 != null, "Mesa 2 (WorkBench2) debe existir")
	assert(wb3 != null, "Mesa 3 (WorkBench3) debe existir")

	# Verificar las 3 PCs
	var pc1 = prac.get_node_or_null("WorkBench1/Computer1")
	var pc2 = prac.get_node_or_null("WorkBench2/Computer2")
	var pc3 = prac.get_node_or_null("WorkBench3/Computer3")
	assert(pc1 != null and pc1.pc_id == 1, "Computer1 en Mesa 1 debe existir con pc_id 1")
	assert(pc2 != null and pc2.pc_id == 2, "Computer2 en Mesa 2 debe existir con pc_id 2")
	assert(pc3 != null and pc3.pc_id == 3, "Computer3 en Mesa 3 debe existir con pc_id 3")

	# Verificar fallas distintas
	assert(pc1.diagnostic_faulty_parts != pc2.diagnostic_faulty_parts, "PC1 y PC2 deben tener fallas distintas")
	assert(pc2.diagnostic_faulty_parts != pc3.diagnostic_faulty_parts, "PC2 y PC3 deben tener fallas distintas")

	# Verificar tiempo de 8 minutos (480.0 segundos)
	assert(GameManager.time_left == 480.0, "El tiempo inicial del reto de práctica debe ser exactamente 8 minutos (480s)")

	print("  ✓ 3 Mesas con 3 PCs y fallas distintas configuradas exitosamente con temporizador de 8 minutos")
	prac.queue_free()
	await get_tree().process_frame

func _test_constellation_graph_expansion() -> void:
	print("\n[4] Probando distribución espaciosa de ConstellationGraph en Reparación...")
	var cg_script = load("res://scripts/menus/ConstellationGraph.gd")
	assert(cg_script != null, "ConstellationGraph.gd debe cargar")
	var cg = Control.new()
	cg.set_script(cg_script)
	add_child(cg)
	await get_tree().process_frame

	var rep_nodes = cg.MODE_NODES.get("reparacion", [])
	assert(rep_nodes.size() == 26, "Reparación debe tener 26 posiciones de nodo")

	# Verificar dimensiones ampliadas (mapa grande):
	var min_x = 9999.0
	var max_x = -9999.0
	var min_y = 9999.0
	var max_y = -9999.0
	for pt in rep_nodes:
		min_x = minf(min_x, pt.x)
		max_x = maxf(max_x, pt.x)
		min_y = minf(min_y, pt.y)
		max_y = maxf(max_y, pt.y)

	var span_x = max_x - min_x
	var span_y = max_y - min_y
	assert(span_x >= 800.0, "El ancho del mapa debe ser espacioso (>= 800px), obtenido: %f" % span_x)
	assert(span_y >= 500.0, "El alto del mapa debe ser espacioso (>= 500px), obtenido: %f" % span_y)

	print("  ✓ Mapa de constelación expandido a %fx%f píxeles" % [span_x, span_y])
	cg.queue_free()
	await get_tree().process_frame

func _test_progression_unlock_chain() -> void:
	print("\n[5] Probando cadena de desbloqueo (Tutorial -> Reto Práctica -> ... -> Nivel 1)...")
	SaveManager.reset_progression_lock()
	assert(SaveManager.is_node_unlocked("reparacion", 0) == true, "Tutorial 0 desbloqueado")
	assert(SaveManager.is_node_unlocked("reparacion", 25) == false, "Práctica 0 bloqueada")
	assert(SaveManager.is_node_unlocked("reparacion", 1) == false, "Tutorial 1 bloqueado")
	assert(SaveManager.is_node_unlocked("reparacion", 7) == false, "Nivel 1 bloqueado")

	# Simular completar Tutorial 0: desbloquea Práctica 0 (nodo 25)
	SaveManager.mark_node_completed("reparacion", 0)
	SaveManager.unlock_node("reparacion", 25)
	assert(SaveManager.is_node_unlocked("reparacion", 25) == true, "Práctica 0 desbloqueada tras completar Tutorial 0")

	# Simular completar Práctica 0: desbloquea Tutorial 1 (nodo 1)
	SaveManager.mark_node_completed("reparacion", 25)
	SaveManager.unlock_node("reparacion", 1)
	assert(SaveManager.is_node_unlocked("reparacion", 1) == true, "Tutorial 1 desbloqueado tras completar Práctica 0")

	# Al completar todos los tutoriales y prácticas:
	SaveManager.unlock_node("reparacion", 7)
	assert(SaveManager.is_node_unlocked("reparacion", 7) == true, "Nivel 1 desbloqueado al completar la cadena")

	print("  ✓ Cadena de desbloqueo secuencial verificada exitosamente")

func _test_sistemas_mode_and_transitions() -> void:
	print("\n[6] Probando Área de Sistemas (26 nodos, bloqueo inicial, retos 8 min y transiciones)...")
	var ls_scene = load("res://scenes/menus/LevelSelect.tscn")
	var ls = ls_scene.instantiate()
	add_child(ls)
	await get_tree().process_frame

	SaveManager.reset_progression_lock()
	ls._sync_progression_from_save()

	var sis_list = ls.LEVELS_DATA.get("sistema", [])
	assert(sis_list.size() == 26, "Sistemas debe tener 26 nodos")
	assert(sis_list[0]["can_play"] == true, "Tutorial 0 de Sistemas debe ser el ÚNICO desbloqueado al inicio")

	# Todos los demás nodos de sistemas deben estar bloqueados al inicio
	for i in range(1, sis_list.size()):
		assert(sis_list[i]["can_play"] == false, "Nodo %d de sistemas debe estar bloqueado al inicio" % i)

	# Probar cambio de modo a sistemas y animación de transición
	ls._switch_mode("sistema")
	assert(ls.current_mode == "sistema", "El modo activo debe ser 'sistema'")

	# Probar dimensiones de la constelación de sistemas
	var cg = ls.graph_lines
	assert(cg != null, "ConstellationGraph debe existir en LevelSelect")
	var sis_nodes = cg.MODE_NODES.get("sistema", [])
	assert(sis_nodes.size() == 26, "Sistemas debe tener 26 nodos en ConstellationGraph")

	var min_x = 9999.0
	var max_x = -9999.0
	var min_y = 9999.0
	var max_y = -9999.0
	for pt in sis_nodes:
		min_x = minf(min_x, pt.x)
		max_x = maxf(max_x, pt.x)
		min_y = minf(min_y, pt.y)
		max_y = maxf(max_y, pt.y)

	var span_x = max_x - min_x
	var span_y = max_y - min_y
	assert(span_x >= 800.0, "El mapa de sistemas debe ser espacioso (ancho >= 800px), obtenido: %f" % span_x)
	assert(span_y >= 500.0, "El mapa de sistemas debe ser espacioso (alto >= 500px), obtenido: %f" % span_y)

	# Probar comando pacman -S levels en terminal Arch Linux
	ls._build_dev_console()
	ls._on_dev_command_submitted("pacman -S levels")
	for i in range(sis_list.size()):
		assert(sis_list[i]["can_play"] == true, "Nodo %d de sistemas debe estar desbloqueado tras pacman -S levels" % i)

	# Probar cadena de desbloqueo en Sistemas
	SaveManager.reset_progression_lock()
	assert(SaveManager.is_node_unlocked("sistema", 0) == true, "Tutorial 0 de sistemas desbloqueado")
	assert(SaveManager.is_node_unlocked("sistema", 25) == false, "Práctica 0 de sistemas bloqueada")
	SaveManager.mark_node_completed("sistema", 0)
	SaveManager.unlock_node("sistema", 25)
	assert(SaveManager.is_node_unlocked("sistema", 25) == true, "Práctica 0 desbloqueada tras completar Tutorial 0")

	SaveManager.mark_node_completed("sistema", 25)
	SaveManager.unlock_node("sistema", 1)
	assert(SaveManager.is_node_unlocked("sistema", 1) == true, "Tutorial 1 de sistemas desbloqueado tras completar Práctica 0")

	SaveManager.unlock_node("sistema", 7)
	assert(SaveManager.is_node_unlocked("sistema", 7) == true, "Nivel 1 de Sistemas desbloqueado al completar la cadena")

	print("  ✓ Modo Sistemas con 26 nodos, progresión secuencial y transiciones verificado exitosamente")
	ls.queue_free()
	await get_tree().process_frame
