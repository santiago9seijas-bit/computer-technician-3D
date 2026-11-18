extends Node

func _ready() -> void:
	print("====================================================")
	print("--- TEST DE MINIJUEGOS HDD, GPU, DIALOGBOX Y TUTORIAL ---")
	print("====================================================")
	
	await _test_hdd_minigame()
	await _test_gpu_minigame()
	await _test_gpu_selection_modal()
	await _test_dialog_box_joa()
	await _test_tutorial_and_practice_zones()
	await _test_server_tutorial_table_hidden()
	await _test_gpu_tutorial_inspection_modal()
	await _test_hdd_storage_tutorial_2_parts()
	
	print("====================================================")
	print("✓ TODOS LOS TESTS PASARON EXITOSAMENTE!")
	print("====================================================")
	get_tree().quit(0)

func _test_hdd_minigame() -> void:
	print("\n[1] Probando HDDMinigame...")
	var hdd_scene = load("res://scenes/minigames/HDDMinigame.tscn")
	assert(hdd_scene != null, "HDDMinigame.tscn debe cargar")
	var hdd = hdd_scene.instantiate()
	add_child(hdd)
	
	assert(hdd.placa_sprite != null, "Placa base del HDD debe existir")
	assert(hdd.drive_container != null, "DriveContainer debe existir")
	assert(hdd.hdd_sprite != null, "HDDSprite debe existir")
	assert(hdd.btn_sata_cable != null, "BtnSataCable debe existir")
	assert(hdd.screw_buttons.size() == 4, "Debe haber 4 tornillos (uno por esquina)")
	
	# Placa debajo, Disco encima
	assert(hdd.placa_sprite.get_index() < hdd.drive_container.get_index(), "Placa de disco debe ser el primer sprite (debajo del disco)")
	
	assert(hdd.current_state == hdd.State.UNSCREW_4_CORNERS, "Estado inicial debe ser UNSCREW_4_CORNERS")
	assert(hdd.btn_tab_quitar.visible == false, "Botones de pestañas deben estar ocultos (sin títulos)")
	assert(hdd.btn_tab_poner.visible == false, "Botones de pestañas deben estar ocultos en fase de desmontaje")
	assert(not "CÓMO" in hdd.guide_text.text and not "MODO" in hdd.guide_text.text, "Guide text no debe incluir títulos")
	assert("1. Quita los 4 tornillos" in hdd.guide_text.text, "Guide text debe mostrar directamente la explicación")
	
	# Verificar coordenadas de los 4 tornillos ajustados a las esquinas del sprite de HDD
	assert(hdd.btn_screw_tl.offset_left == 180.0 and hdd.btn_screw_tl.offset_top == 72.0, "Tornillo TL en esquina sup-izq")
	assert(hdd.btn_screw_tr.offset_left == 350.0 and hdd.btn_screw_tr.offset_top == 72.0, "Tornillo TR en esquina sup-der")
	assert(hdd.btn_screw_bl.offset_left == 180.0 and hdd.btn_screw_bl.offset_top == 178.0, "Tornillo BL en esquina inf-izq")
	assert(hdd.btn_screw_br.offset_left == 350.0 and hdd.btn_screw_br.offset_top == 178.0, "Tornillo BR en esquina inf-der")
	assert(hdd.get_node("ModalControl/Panel/VBox/Header/Titulo").visible == false, "Título del minijuego HDD oculto para estabilidad y evitar salirse de pantalla")
	print("  ✓ Tornillos ubicados con precisión en las 4 esquinas del sprite de disco HDD")
	print("  ✓ Orden de sprites: Placa debajo, Disco HDD encima")
	print("  ✓ Panel lateral limpio: Sin títulos ni botones redundantes, sólo explicación clara")
	
	# Intentar desconectar SATA antes de tornillos
	hdd._on_sata_cable_pressed()
	assert(not hdd.is_sata_disconnected, "No se debe desconectar SATA si los tornillos no han sido retirados")
	assert(hdd.current_state == hdd.State.UNSCREW_4_CORNERS, "Debe permanecer en UNSCREW_4_CORNERS")
	print("  ✓ Bloqueo de seguridad: No se puede quitar SATA con tornillos colocados")
	
	# Quitar los 4 tornillos
	for i in range(4):
		var req_tool = 1 if hdd.screw_types[i] == "cruz" else 2
		GameManager.select_tool(req_tool)
		hdd._on_screw_pressed(i)
		assert(hdd.screws_removed[i] == true, "Tornillo %d debe estar retirado" % i)
		
	assert(hdd.current_state == hdd.State.DISCONNECT_SATA, "Al quitar 4 tornillos, debe avanzar a DISCONNECT_SATA")
	print("  ✓ Los 4 tornillos de las esquinas retirados correctamente")
	
	# Desconectar cable SATA
	hdd._on_sata_cable_pressed()
	assert(hdd.is_sata_disconnected == true, "Cable SATA debe estar desconectado")
	assert(hdd.hdd_sprite.texture == hdd.TEX_HDD_DISCONNECTED, "La textura del disco debe cambiar a desconectado")
	assert(hdd.current_state == hdd.State.EXTRACT_DRAG_RIGHT, "Debe avanzar a EXTRACT_DRAG_RIGHT")
	print("  ✓ Cable SATA desconectado y textura cambiada a 'desconectado disco hdd.png'")
	
	# Extraer arrastrando a la derecha
	hdd._complete_hdd_extraction()
	await hdd.old_part_extracted
	print("  ✓ Extracción hacia la derecha completada y señal old_part_extracted emitida")
	
	# Probar fase de montaje
	hdd._setup_empty_bay_phase()
	assert(hdd.is_install_phase() == true, "Debe estar en fase de instalación")
	assert(hdd.btn_tab_quitar.visible == false, "Pestañas ocultas en montaje")
	assert(hdd.btn_tab_poner.visible == false, "Pestañas ocultas en montaje")
	assert(not "CÓMO" in hdd.guide_text.text and not "MODO" in hdd.guide_text.text, "Sin títulos en fase de montaje")
	assert("1. Arrastra el disco nuevo" in hdd.guide_text.text, "Muestra pasos de montaje directamente")
	print("  ✓ Auto-detección en fase de montaje: Pasos contextuales sin títulos")
	
	hdd.queue_free()

func _test_gpu_minigame() -> void:
	print("\n[2] Probando GPUMinigame...")
	var gpu_scene = load("res://scenes/minigames/GPUMinigame.tscn")
	assert(gpu_scene != null, "GPUMinigame.tscn debe cargar")
	var gpu = gpu_scene.instantiate()
	add_child(gpu)
	
	# Verificar que el botón de toggle dual/mono ha sido ELIMINADO
	assert(gpu.get_node_or_null("ModalControl/Panel/VBox/WorkArea/BtnToggleModel") == null, "BtnToggleModel debe haber sido eliminado del árbol de nodos")
	print("  ✓ Botón de cambio de cooler eliminado exitosamente como solicitó el usuario")
	
	assert(gpu.base_gpu_sprite != null, "BaseGPUSprite debe existir")
	assert(gpu.soporte_gpu_sprite != null, "SoporteGPUSprite debe existir")
	assert(gpu.btn_cable_power != null, "BtnCablePower debe existir")
	assert(gpu.btn_screw_1 != null and gpu.btn_screw_2 != null, "Los 2 tornillos deben existir")
	assert(gpu.lbl_mode_badge != null, "lbl_mode_badge debe existir para auto-detección")
	
	# Soporte está en WorkArea por encima
	assert(gpu.soporte_gpu_sprite.z_index >= gpu.gpu_container.z_index, "Soporte debe estar por encima de la gráfica")
	
	# Auto-detección inicial
	assert("DESMONTAJE" in gpu.lbl_mode_badge.text, "El badge debe auto-detectar MODO: DESMONTAJE")
	print("  ✓ Auto-detección de modo inicial GPU: 'DESMONTAJE' activo")
	
	# Monocooler
	gpu.current_gpu_type = gpu.GPUType.MONO_COOLER
	gpu._apply_gpu_model_layout()
	assert(gpu.soporte_gpu_sprite.texture == gpu.tex_mono_soporte, "Soporte Monocooler debe aplicarse")
	assert(gpu.gpu_container.size == Vector2(285, 203), "Tamaño Monocooler debe ser 285x203")
	# Posición del soporte movido un poco a la derecha
	assert(gpu.soporte_gpu_sprite.position.x > gpu.gpu_container.position.x, "El soporte debe estar desplazado a la derecha de la gráfica")
	# Posición de los tornillos acomodados sobre el soporte cerca del bracket HDMI (más hacia la derecha, bajado el de arriba y subido el de abajo)
	var rel_x1_mono = gpu.btn_screw_1.position.x - gpu.gpu_container.position.x
	var rel_x2_mono = gpu.btn_screw_2.position.x - gpu.gpu_container.position.x
	var rel_y1_mono = gpu.btn_screw_1.position.y - gpu.gpu_container.position.y
	var rel_y2_mono = gpu.btn_screw_2.position.y - gpu.gpu_container.position.y
	assert(rel_x1_mono >= 55.0 and rel_x1_mono <= 75.0, "Tornillo 1 debe estar desplazado a la derecha sobre el bracket (x=64)")
	assert(rel_x2_mono >= 55.0 and rel_x2_mono <= 75.0, "Tornillo 2 debe estar desplazado a la derecha sobre el bracket (x=64)")
	assert(rel_y1_mono == 34.0, "Tornillo 1 monocooler bajado un poco a y=34")
	assert(rel_y2_mono == 94.0, "Tornillo 2 monocooler subido un poco a y=94")
	print("  ✓ Monocooler: Tornillos alineados en bracket HDMI (x=64, y=34 y y=94)")
	
	# Dual Cooler
	gpu.current_gpu_type = gpu.GPUType.DUAL_COOLER
	gpu._apply_gpu_model_layout()
	assert(gpu.soporte_gpu_sprite.texture == gpu.tex_dual_soporte, "Soporte Dual Cooler debe aplicarse")
	assert(gpu.gpu_container.size == Vector2(500, 231), "Tamaño Dual Cooler debe ser 500x231")
	assert(gpu.soporte_gpu_sprite.position.x > gpu.gpu_container.position.x, "Soporte Dual desplazado a la derecha")
	var rel_x1_dual = gpu.btn_screw_1.position.x - gpu.gpu_container.position.x
	var rel_x2_dual = gpu.btn_screw_2.position.x - gpu.gpu_container.position.x
	var rel_y1_dual = gpu.btn_screw_1.position.y - gpu.gpu_container.position.y
	var rel_y2_dual = gpu.btn_screw_2.position.y - gpu.gpu_container.position.y
	assert(rel_x1_dual >= 55.0 and rel_x1_dual <= 75.0, "Tornillo 1 Dual acomodado a la derecha en bracket HDMI (x=66)")
	assert(rel_x2_dual >= 55.0 and rel_x2_dual <= 75.0, "Tornillo 2 Dual acomodado a la derecha en bracket HDMI (x=66)")
	assert(rel_y1_dual == 44.0 and rel_y2_dual == 108.0, "Tornillos Dual ajustados verticalmente")
	print("  ✓ Dual Cooler: Soporte y tornillos acomodados en el bracket")
	
	# Modo Tutorial y desaceleración rápida a monocooler desconectado
	gpu.is_tutorial_mode = true
	gpu.current_gpu_type = gpu.GPUType.MONO_COOLER
	gpu._apply_gpu_model_layout()
	gpu._setup_removal_phase()
	assert(gpu.current_state == gpu.State.DISCONNECT_POWER, "Estado inicial debe ser DISCONNECT_POWER")
	assert(gpu.is_spinning == true, "Ventiladores deben estar girando")
	
	gpu._on_cable_power_pressed()
	assert(gpu.is_decelerating == true, "Al desconectar debe comenzar desaceleración progresiva rápida")
	
	# Frena rápido en ~0.4s
	gpu._process(0.45)
		
	assert(gpu.is_spinning == false, "Los ventiladores deben detenerse por completo")
	assert(gpu.is_power_disconnected == true, "Cable debe estar desconectado")
	assert(gpu.base_gpu_sprite.texture == gpu.tex_mono_desconectada, "Al detenerse la animación pasa a sprite monocooler desconectado")
	print("  ✓ Desaceleración rápida: termina rápido y pasa a 'grafica desconectada.png' monocooler")
	
	# Retirar tornillos
	for i in range(2):
		var req_tool = 1 if gpu.screw_types[i] == "cruz" else 2
		GameManager.select_tool(req_tool)
		gpu._on_screw_pressed(i)
		assert(gpu.screws_removed[i] == true, "Tornillo %d retirado" % (i + 1))
		
	assert(gpu.current_state == gpu.State.EXTRACT_DRAG_UP, "Debe avanzar a EXTRACT_DRAG_UP")
	
	var initial_soporte_pos = gpu.soporte_gpu_sprite.position
	gpu._complete_gpu_extraction()
	await gpu.old_part_extracted
	
	# Soporte fijo en el sitio
	assert(gpu.soporte_gpu_sprite.position == initial_soporte_pos, "El soporte debe quedarse fijo en su sitio")
	print("  ✓ Soporte fijo en su sitio tras extraer la GPU")
	
	gpu.queue_free()

func _test_gpu_selection_modal() -> void:
	print("\n[3] Probando GPUSelectionModal...")
	var modal_scene = load("res://scenes/ui/GPUSelectionModal.tscn")
	assert(modal_scene != null, "GPUSelectionModal.tscn debe cargar")
	var modal = modal_scene.instantiate()
	add_child(modal)
	
	GameManager.spares_stock["Grafica"] = 5
	GameManager.backpack.clear()
	modal._update_stock_ui()
	
	assert(modal.GPU_CONFIG.has("monocooler") and modal.GPU_CONFIG.has("dual_cooler"))
	modal._toggle_card_flip("monocooler")
	await get_tree().create_timer(0.35).timeout
	assert(modal.card_flipped["monocooler"] == true, "Tarjeta debe voltearse")
	
	modal.selected_capacities["monocooler"] = "12 GB"
	var backpack_before = GameManager.backpack.size()
	modal._select_gpu_spare("monocooler")
	assert(GameManager.backpack.size() == backpack_before + 1, "GPU agregada a la mochila")
	print("  ✓ Selección de modelo y VRAM con volteo de tarjeta confirmado")
	modal.queue_free()
	
	# Probar que SparesBox de Gráfica abre GPUSelectionModal
	var spares_box_scene = load("res://scenes/components/SparesBox.tscn")
	var s_box = spares_box_scene.instantiate()
	s_box.spare_type = "Grafica"
	add_child(s_box)
	s_box.interact(null)
	var opened_gpu_modal = null
	for child in get_tree().root.get_children():
		if "GPUSelectionModal" in child.name:
			opened_gpu_modal = child
			break
	assert(opened_gpu_modal != null, "Al interactuar con SparesBox de Gráficas DEBE abrirse GPUSelectionModal")
	print("  ✓ Caja de gráficas abre GPUSelectionModal con giro de tarjeta y selección de GBs")
	if opened_gpu_modal: opened_gpu_modal.queue_free()
	s_box.queue_free()

func _test_dialog_box_joa() -> void:
	print("\n[4] Probando DialogBox con Retrato de Joa más Grande, más Arriba y Letras a la Derecha...")
	var dlg_scene = load("res://scenes/ui/DialogBox.tscn")
	assert(dlg_scene != null, "DialogBox.tscn debe cargar")
	var dlg = dlg_scene.instantiate()
	add_child(dlg)
	
	# 1. Verificar nodos
	assert(dlg.portrait_root != null, "PortraitRoot debe existir")
	assert(dlg.portrait_texture != null, "PortraitTexture debe existir")
	assert(dlg.typing_audio != null, "TypingAudio debe existir")
	
	# Verificar que el retrato esté posicionado más arriba (offset_top <= -500) y más grande (ancho >= 350)
	assert(dlg.portrait_root.offset_top <= -500.0, "El retrato debe estar posicionado más arriba (offset_top <= -500)")
	assert(dlg.portrait_texture.size.x >= 350.0 or (dlg.portrait_texture.offset_right - dlg.portrait_texture.offset_left) >= 350.0, "El retrato debe ser más grande")
	print("  ✓ Retrato de Joa más grande (380px) y más alto (offset_top: -540px)")
	
	# Verificar orden en el árbol: PortraitRoot ANTES que BoxMargin (el marco está superpuesto a la imagen)
	var portrait_idx = dlg.portrait_root.get_index()
	var box_margin_idx = dlg.get_node("BoxMargin").get_index()
	assert(portrait_idx < box_margin_idx, "PortraitRoot debe estar antes de BoxMargin para que el marco esté superpuesto")
	print("  ✓ El marco del diálogo está superpuesto a la imagen del personaje")
	
	# 2. Probar diálogo normal de Joa con nombre fijo arriba a la izquierda y margen a la izquierda
	dlg.show_message("[JOA // TÉCNICA DE HARDWARE]", "Hola, bienvenido al taller de hardware...")
	assert(dlg.portrait_root.visible == true, "El retrato debe estar visible cuando Joa habla")
	assert(dlg.portrait_texture.texture == dlg.TEX_JOA_NORMAL, "Por defecto debe mostrar 'joa normal.png'")
	assert(dlg.is_typing == true, "La máquina de escribir debe estar activa")
	assert(dlg.typing_audio.playing == true, "El sonido de teclado debe estar sonando mientras se escribe")
	
	# Verificar que el nombre JOA esté fijo arriba a la izquierda
	assert(dlg.speaker_label.text == "JOA", "El nombre de Joa debe estar fijo como 'JOA'")
	# Verificar que las letras estén hacia la izquierda (margin_left <= 60)
	assert(dlg.panel_margin.get_theme_constant("margin_left") <= 60, "Los diálogos deben estar desplazados hacia la izquierda")
	print("  ✓ Nombre 'JOA' fijo arriba a la izquierda del cuadro de diálogo")
	print("  ✓ Diálogos desplazados hacia la izquierda (margin_left: 36px)")
	print("  ✓ Retrato 'joa normal.png' activo por defecto cuando Joa habla")
	print("  ✓ Sonido animado de teclado reproduciéndose mientras las letras aparecen")
	
	# 3. Probar omisión rápida de escritura con [E]
	dlg._finish_typing()
	assert(dlg.is_typing == false, "Typing debe detenerse")
	assert(dlg.typing_audio.playing == false, "El sonido de teclado debe detenerse al terminar de escribir")
	assert(dlg.message_label.visible_characters == -1, "Todas las letras deben ser visibles tras finalizar")
	print("  ✓ El sonido se detiene de inmediato al parar o terminar de escribir las letras")
	
	# 4. Probar interrupción de escape (Joa llorando)
	dlg.show_choice(
		"[JOA // TÉCNICA DE HARDWARE]",
		"¿E-eh...? ¿Te vas tan pronto? *(se le llenan los ojos de lágrimas)*...",
		"QUEDARME",
		"SALIR",
		func(): pass,
		func(): pass
	)
	assert(dlg.portrait_texture.texture == dlg.TEX_JOA_CRYING, "Al querer salir del tutorial debe mostrar 'joa llorando.png'")
	print("  ✓ Retrato 'joa llorando.png' se activa cuando el jugador quiere salir del tutorial")
	
	dlg.queue_free()

func _test_tutorial_and_practice_zones() -> void:
	print("\n[5] Probando Tutoriales de cada pieza (menos placa madre) y Zonas de Práctica...")
	var tut_scene = load("res://scenes/gameplay/LevelTutorial.tscn")
	assert(tut_scene != null, "LevelTutorial.tscn debe cargar")
	var tut = tut_scene.instantiate()
	add_child(tut)
	tut.current_mode = "reparacion"
	tut._setup_reparacion_environment()
	
	# Verificar que el tutorial cubre cada componente (RAM, Disco Duro, GPU, Cooler, CPU, PSU) y excluye Placa Madre
	assert(tut.pc.components.has("RAM"), "Debe incluir RAM")
	assert(tut.pc.components.has("Disco Duro"), "Debe incluir Disco Duro")
	assert(tut.pc.components.has("Grafica"), "Debe incluir Grafica")
	assert(tut.pc.components.has("Fan Cooler"), "Debe incluir Fan Cooler")
	assert(tut.pc.components.has("CPU"), "Debe incluir CPU")
	assert(tut.pc.components.has("Fuente"), "Debe incluir Fuente")
	assert(tut.pc.components.get("Placa Madre") == "ok", "Placa madre debe estar OK / no incluida en reparaciones obligatorias")
	assert(tut.ReparacionStep.has("WAIT_HANDLE_CPU"), "El enum ReparacionStep debe incluir WAIT_HANDLE_CPU")
	
	# Probar tutorial individual enfocado en GPU
	tut.target_component = "gpu"
	tut._setup_reparacion_environment()
	assert(tut.pc.components.get("Grafica") == "broken", "En tutorial de GPU, la gráfica debe estar broken")
	assert(tut.pc.components.get("RAM") == "ok", "En tutorial de GPU, la RAM debe estar ok")
	print("  ✓ Tutorial de Joa configurable por pieza individual (RAM, HDD, GPU, Cooler, CPU, PSU)")
	tut.queue_free()
	
	# Verificar Sala de Práctica 3D
	var prac_scene = load("res://scenes/gameplay/LevelPractice.tscn")
	assert(prac_scene != null, "LevelPractice.tscn debe cargar")
	var prac = prac_scene.instantiate()
	add_child(prac)
	var pc_prac = prac.get_node_or_null("WorkBench1/Computer1")
	if not pc_prac:
		pc_prac = prac.get_node_or_null("WorkBench/Computer1")
	assert(pc_prac != null, "Computer1 de práctica debe existir")
	assert(pc_prac.components.has("RAM") and pc_prac.components.has("Grafica") and pc_prac.components.has("CPU"), "PC de práctica debe contener todas las piezas para entrenamiento libre")
	assert(prac.get_node_or_null("SparesGPU") != null, "Caja de repuestos SparesGPU debe existir en la sala de práctica")
	assert(prac.get_node_or_null("SparesCooler") != null, "Caja de repuestos SparesCooler debe existir en la sala de práctica")
	assert(prac.get_node_or_null("SparesCPU") != null, "Caja de repuestos SparesCPU debe existir en la sala de práctica")
	print("  ✓ Sala de Práctica 3D con cajas de repuestos para cada componente y zonas dedicadas")
	prac.queue_free()
	
	# Verificar LevelSelect nodos de tutoriales azules, niveles 1-12 y práctica naranjas
	var sel_scene = load("res://scenes/menus/LevelSelect.tscn")
	assert(sel_scene != null, "LevelSelect.tscn debe cargar")
	var sel = sel_scene.instantiate()
	add_child(sel)
	var list = sel.LEVELS_DATA["reparacion"]
	assert(list.size() == 26, "La constelación de Reparación debe contener 26 nodos en total")
	
	# Nodos 0 a 6: BURBUJAS AZULES DE TUTORIAL
	for tut_idx in range(7):
		assert(list[tut_idx].get("is_tutorial") == true, "Nodo %d debe ser Burbuja Azul de Tutorial" % tut_idx)
		assert(list[tut_idx].get("target_scene") != "", "Nodo tutorial %d debe tener target_scene" % tut_idx)
		var scn = load(list[tut_idx]["target_scene"])
		assert(scn != null, "Escena de tutorial %s debe existir y cargar" % list[tut_idx]["target_scene"])
	print("  ✓ Todos los 7 Nodos de Tutorial (0 al 6) son burbujas azules y cargan sus salas dedicadas")

	# Nodo 7: NIVEL 1 DEL TALLER
	assert(list[7].get("is_level") == true, "Nodo 7 debe ser un nivel de juego")
	assert(list[7].get("number") == 1 or list[7].get("level_number") == 1, "Nodo 7 debe ser el NIVEL 1")
	print("  ✓ Nodo 7 es el NIVEL 1 del área de reparación (Montaje Fan Cooler)")

	# Nodos 8 al 18: NIVELES 2 AL 12 (BLOQUEADOS 🔒)
	for lvl_idx in range(8, 19):
		assert(list[lvl_idx].get("is_level") == true, "Nodo %d debe ser un nivel de juego" % lvl_idx)
		assert(list[lvl_idx].get("can_play") == false, "Nivel %d debe estar BLOQUEADO (can_play = false)" % lvl_idx)
	print("  ✓ Niveles 2 al 12 están correctamente presentes y BLOQUEADOS con candado")

	# Nodos 19 a 25: BURBUJAS NARANJAS DE PRÁCTICA
	for prac_idx in range(19, 26):
		assert(list[prac_idx].get("is_practice") == true, "Nodo %d debe ser Zona de Práctica" % prac_idx)
		assert(list[prac_idx].get("practice_id") != "", "Nodo de práctica %d debe tener practice_id" % prac_idx)
	print("  ✓ Todos los 7 Nodos de Práctica (19 al 25) son burbujas de entrenamiento libre")
	
	assert(sel.deployed_btn_tutorial_3d != null, "Botón de Tutorial 3D con Joa debe existir en tarjeta de tutorial")
	print("  ✓ Telaraña de reparación expandida: 7 tutoriales, Nivel 1 desbloqueado, Niveles 2-12 bloqueados y 7 zonas de práctica")
	sel.queue_free()

func _test_server_tutorial_table_hidden() -> void:
	print("\n[6] Probando Nivel Tutorial y ocultamiento de mesa en Servidor...")
	GameManager.current_mode = "servidor"
	var tut_scene = load("res://scenes/gameplay/LevelTutorial.tscn")
	assert(tut_scene != null, "LevelTutorial.tscn debe cargar")
	var tut = tut_scene.instantiate()
	add_child(tut)
	
	tut._setup_servidor_environment()
	assert(tut.work_bench.visible == false, "La mesa debe estar oculta en servidor")
	assert(tut.work_bench.collision_layer == 0, "Colisiones de la mesa desactivadas")
	
	for child in tut.work_bench.get_children():
		if child is VisualInstance3D or child is Node3D:
			assert(child.visible == false, "Hijo %s de la mesa oculto" % child.name)
			
	assert(tut.server_rack_inst != null and tut.server_rack_inst.visible == true, "Torre de servidor visible")
	print("  ✓ Mesa removida en servidor y solo queda la torre")
	
	tut.queue_free()

func _test_gpu_tutorial_inspection_modal() -> void:
	print("\n[7] Probando PCInspectionModal en Tutorial de GPU...")
	GameManager.current_mode = "reparacion"
	GameManager.tutorial_target_component = "gpu"
	
	var tut_gpu_scene = load("res://scenes/gameplay/LevelTutorialGPU.tscn")
	assert(tut_gpu_scene != null, "LevelTutorialGPU.tscn debe cargar")
	var tut_gpu = tut_gpu_scene.instantiate()
	add_child(tut_gpu)
	
	var pc_gpu = tut_gpu.get_node_or_null("WorkBench/Computer1")
	assert(pc_gpu != null, "PC de tutorial GPU debe existir")
	assert(pc_gpu.get_meta("tutorial_component", "") == "gpu", "PC debe tener tutorial_component = 'gpu'")
	assert(pc_gpu.components.get("Grafica") == "broken", "Grafica debe estar en estado 'broken'")
	
	var modal_scene = load("res://scenes/ui/PCInspectionModal.tscn")
	assert(modal_scene != null, "PCInspectionModal.tscn debe cargar")
	var modal = modal_scene.instantiate()
	add_child(modal)
	modal.setup_pc(pc_gpu)
	
	assert(modal.card_gpu.visible == true, "Card de GPU DEBE estar visible en el tutorial de GPU")
	assert(modal.card_psu.visible == false, "Card de Fuente PSU DEBE estar oculta en el tutorial de GPU")
	assert(modal.card_cpu.visible == false, "Card de CPU debe estar oculta en el tutorial de GPU")
	assert(modal.btn_sacar_gpu.disabled == false, "Botón sacar GPU debe estar habilitado")
	assert("SACAR" in modal.btn_sacar_gpu.text, "Botón debe decir 'SACAR' y no estar bloqueado")
	print("  ✓ Tutorial de GPU: Card GPU visible, Card PSU oculta, botón SACAR activo sin bloqueos espurios")
	
	modal.queue_free()
	tut_gpu.queue_free()
	
	# Probar persistencia del modelo de GPU escogido
	var minigame_scene = load("res://scenes/minigames/GPUMinigame.tscn")
	var mg = minigame_scene.instantiate()
	add_child(mg)
	mg.set_gpu_type_by_name("monocooler")
	assert(mg.current_gpu_type == mg.GPUType.MONO_COOLER, "Debe configurarse a MONO_COOLER")
	assert(mg.base_gpu_sprite.texture in mg.mono_anim_frames, "Debe mostrar sprite monocooler")
	
	mg.set_gpu_type_by_name("dual_cooler")
	assert(mg.current_gpu_type == mg.GPUType.DUAL_COOLER, "Debe configurarse a DUAL_COOLER")
	assert(mg.base_gpu_sprite.texture in mg.dual_anim_frames, "Debe mostrar sprite dual cooler")
	mg.queue_free()
	print("  ✓ Persistencia de modelo: El sprite de la gráfica elegida (mono o dual) se mantiene consistente")
	
	# Verificar también Tutorial de CPU
	GameManager.tutorial_target_component = "cpu"
	var tut_cpu_scene = load("res://scenes/gameplay/LevelTutorialCPU.tscn")
	var tut_cpu = tut_cpu_scene.instantiate()
	add_child(tut_cpu)
	var pc_cpu = tut_cpu.get_node_or_null("WorkBench/Computer1")
	assert(pc_cpu.get_meta("tutorial_component", "") == "cpu", "PC debe tener tutorial_component = 'cpu'")
	var modal_cpu = modal_scene.instantiate()
	add_child(modal_cpu)
	modal_cpu.setup_pc(pc_cpu)
	assert(modal_cpu.card_cpu.visible == true, "Card de CPU debe estar visible en tutorial de CPU")
	assert(modal_cpu.card_gpu.visible == false, "Card de GPU debe estar oculta en tutorial de CPU")
	assert(modal_cpu.card_psu.visible == false, "Card de PSU debe estar oculta en tutorial de CPU")
	print("  ✓ Tutorial de CPU: Card CPU visible, Card GPU y PSU ocultas")
	modal_cpu.queue_free()
	tut_cpu.queue_free()

func _test_hdd_storage_tutorial_2_parts() -> void:
	print("\n[8] Probando Tutorial de Almacenamiento en 2 Partes (M.2 -> Diálogo Joa -> HDD -> Caja de Repuestos)...")
	GameManager.current_mode = "reparacion"
	GameManager.tutorial_target_component = "hdd"
	GameManager.backpack.clear()
	
	# 1. Verificar el sprite de la caja de HDD en SSDSelectionModal
	var ssd_modal_scene = load("res://scenes/ui/SSDSelectionModal.tscn")
	assert(ssd_modal_scene != null, "SSDSelectionModal.tscn debe cargar")
	var ssd_modal = ssd_modal_scene.instantiate()
	add_child(ssd_modal)
	var card_hdd_tex = ssd_modal.get_node_or_null("CardModal/Margin/VBox/CardsContainer/CardHDD/VBox/Margin/Content/Texture")
	assert(card_hdd_tex != null and card_hdd_tex.texture != null, "TextureRect de CardHDD debe existir")
	assert("disco_hdd_caja.png" in card_hdd_tex.texture.resource_path, "La caja debe mostrar el sprite limpio de disco_hdd_caja.png")
	print("  ✓ Sprite de la caja de HDD actualizado a disco_hdd_caja.png correctamente")
	
	# 2. Cargar Tutorial de HDD
	var tut_hdd_scene = load("res://scenes/gameplay/LevelTutorialHDD.tscn")
	assert(tut_hdd_scene != null, "LevelTutorialHDD.tscn debe cargar")
	var tut_hdd = tut_hdd_scene.instantiate()
	add_child(tut_hdd)
	
	var pc_hdd = tut_hdd.get_node_or_null("WorkBench/Computer1")
	assert(pc_hdd != null, "PC de tutorial HDD debe existir")
	assert(pc_hdd.get_meta("tutorial_component", "") == "hdd", "tutorial_component debe ser 'hdd'")
	assert(pc_hdd.get_meta("storage_part", 1) == 1, "Inicialmente debe estar en Parte 1 (SSD M.2)")
	assert(pc_hdd.drive_type == "m2", "Inicialmente el drive_type debe ser 'm2'")
	assert(pc_hdd.components.get("Disco Duro") == "broken", "Almacenamiento debe estar en estado 'broken'")
	print("  ✓ Inicialización Parte 1: storage_part = 1, drive_type = 'm2'")
	
	# 3. Abrir PCInspectionModal en Parte 1
	var modal_scene = load("res://scenes/ui/PCInspectionModal.tscn")
	var modal = modal_scene.instantiate()
	add_child(modal)
	modal.setup_pc(pc_hdd)
	
	assert(modal.lbl_title_hdd != null, "lbl_title_hdd debe existir")
	assert("PARTE 1" in modal.lbl_title_hdd.text, "El título de la tarjeta debe indicar PARTE 1 (SSD M.2)")
	assert("SACAR" in modal.btn_sacar_hdd.text, "El botón debe decir SACAR")
	
	# 4. Al dar clic en SACAR en Parte 1, debe lanzar M2Minigame
	modal._open_hdd_minigame(false)
	var root_children = get_tree().root.get_children()
	var m2_instance = null
	for child in root_children:
		if "M2Minigame" in child.name:
			m2_instance = child
			break
	assert(m2_instance != null, "Parte 1 debe instanciar M2Minigame en root")
	assert(m2_instance.placa_base != null and m2_instance.placa_base.texture == m2_instance.TEX_PLACA, "Debe usar placa.png de memoriastipos")
	assert(m2_instance.memory_sprite != null and m2_instance.memory_sprite.texture == m2_instance.TEX_M2, "Debe usar memoria M.2.png de memoriastipos")
	assert(m2_instance.pins_sprite != null and m2_instance.pins_sprite.texture == m2_instance.TEX_PINES_CLOSED, "Debe usar pines de memoria.png")
	
	# Verificar centrado perfecto de los 3 elementos en la placa a la MISMA ALTURA (Y ≈ 140px)
	assert(m2_instance.memory_drive.position == Vector2.ZERO, "Memoria SSD debe estar centrada en (0, 0) sobre la placa")
	assert(m2_instance.pins_sprite.offset_top == 61.0, "Sprite de pines alineado verticalmente a la misma altura que el SSD y tornillo")
	assert(m2_instance.btn_pins.offset_top == 95.0 and m2_instance.btn_pins.offset_bottom == 185.0, "Botón de pines a la misma altura (centro Y=140)")
	assert(m2_instance.rear_screw_btn.offset_top == 123.0 and m2_instance.rear_screw_btn.offset_bottom == 157.0, "Tornillo trasero a la misma altura (centro Y=140)")
	print("  ✓ Parte 1: Los 3 elementos (pines, SSD y tornillo) están a la MISMA ALTURA en la placa (centro Y ≈ 140)")
	
	# Ejecutar pasos del minijuego M.2 con los sprites oficiales
	var req_tool_m2 = m2_instance.required_tool_id
	GameManager.select_tool(req_tool_m2)
	m2_instance._on_level_rear_screw_pressed()
	await get_tree().create_timer(0.35).timeout
	assert(m2_instance.level_phase == m2_instance.LevelPhase.OPEN_PINS, "Tornillo retirado, avanza a OPEN_PINS")
	m2_instance._on_level_pins_pressed()
	assert(m2_instance.level_phase == m2_instance.LevelPhase.EXTRACT_DRIVE, "Pines abiertos, avanza a EXTRACT_DRIVE")
	assert(m2_instance.pins_sprite.texture == m2_instance.TEX_PINES_OPEN, "Muestra pines de memoria abiertos.png")
	
	# Extraer unidad averiada -> el minijuego debe cerrarse para que el jugador vaya a buscar el repuesto
	m2_instance._complete_level_drive_extraction()
	await m2_instance.old_part_extracted
	await get_tree().create_timer(0.85).timeout
	
	assert(pc_hdd.components.get("Disco Duro") == "empty", "La bahía queda vacía tras extraer el SSD averiado")
	modal._refresh_ui()
	assert(modal.btn_sacar_hdd.disabled == true, "Botón PONER deshabilitado: el jugador debe ir a la caja de repuestos")
	print("  ✓ Sin repuesto mágico: La ranura queda vacía y el jugador debe ir a la caja de repuestos en la sala")
	
	# Ir a la caja de repuestos y recoger el nuevo SSD
	GameManager.spares_stock["Disco Duro"] = 3
	ssd_modal._choose_storage("m2_nvme")
	var has_ssd_spare = false
	for it in GameManager.backpack:
		if (it.get("name") == "Disco Duro" or it.get("type") == "Disco Duro") and not it.get("broken", true):
			has_ssd_spare = true
			break
	assert(has_ssd_spare == true, "Repuesto de SSD recogido de la caja")
	modal._refresh_ui()
	assert(modal.btn_sacar_hdd.disabled == false, "Botón PONER habilitado tras recoger el SSD de la caja")
	
	# Abrir minijuego para instalar el nuevo SSD recogido de la caja
	modal._on_sacar_pressed("Disco Duro")
	var m2_install_instance = null
	for child in get_tree().root.get_children():
		if "M2Minigame" in child.name:
			m2_install_instance = child
			break
	assert(m2_install_instance != null, "Abre M2Minigame en modo instalación")
	assert(m2_install_instance.level_phase == m2_install_instance.LevelPhase.INSERT_DRAG_LEFT, "Inicia en INSERT_DRAG_LEFT")
	
	# Montar y calzar nuevo SSD
	m2_install_instance._seat_level_drive()
	await get_tree().create_timer(0.25).timeout
	assert(m2_install_instance.level_phase == m2_install_instance.LevelPhase.CLOSE_PINS, "Nuevo SSD calzado, avanza a CLOSE_PINS")
	
	# Cerrar pines
	m2_install_instance._on_level_pins_pressed()
	await get_tree().create_timer(0.25).timeout
	assert(m2_install_instance.level_phase == m2_install_instance.LevelPhase.INSTALL_SCREW, "Pines asegurados, avanza a INSTALL_SCREW")
	
	# Ajustar tornillo trasero para asegurar al 100%
	GameManager.select_tool(m2_install_instance.required_tool_id)
	m2_install_instance._on_level_rear_screw_pressed()
	await get_tree().create_timer(1.2).timeout
	
	assert(pc_hdd.get_meta("storage_part") == 2, "Tras completar M.2 y colocar nuevo SSD, avanza a storage_part = 2")
	assert(pc_hdd.drive_type == "hdd", "Tras completar M.2, drive_type cambia a 'hdd'")
	assert(pc_hdd.components.get("Disco Duro") == "broken", "Disco HDD averiado listo para desmontar en Parte 2")
	assert("PARTE 2" in modal.lbl_title_hdd.text, "El título de la tarjeta ahora indica PARTE 2 (DISCO HDD)")
	
	# Verificar diálogo de transición de Joa
	assert(tut_hdd.dialog_box != null, "DialogBox debe existir en el tutorial")
	assert("explicación" in tut_hdd.dialog_box.message_label.text.to_lower() and "discos mecánicos hdd" in tut_hdd.dialog_box.message_label.text.to_lower(), "Joa debe explicar la existencia de los discos mecánicos HDD")
	print("  ✓ Diálogo de Joa de transición verificado: explica qué son los discos mecánicos HDD")
	
	# 6. Parte 2: Desmontaje de HDD
	modal._open_hdd_minigame(false)
	var hdd_instance = null
	for child in get_tree().root.get_children():
		if "HDDMinigame" in child.name:
			hdd_instance = child
			break
	assert(hdd_instance != null, "Parte 2 debe instanciar HDDMinigame")
	
	# Extraer HDD
	hdd_instance._complete_hdd_extraction()
	await hdd_instance.old_part_extracted
	hdd_instance.minigame_finished.emit(true)
	await get_tree().create_timer(0.05).timeout
	
	assert(pc_hdd.components.get("Disco Duro") == "empty", "La bahía de disco debe quedar vacía")
	
	# 7. Verificar que el repuesto NO apareció mágicamente en la mochila
	var has_functional_hdd = false
	for it in GameManager.backpack:
		if it.get("name") == "Disco Duro" and not it.get("broken", true):
			has_functional_hdd = true
			break
	assert(has_functional_hdd == false, "El repuesto NO debe aparecer automáticamente en la mochila tras la extracción")
	assert(modal.btn_sacar_hdd.disabled == true, "Botón debe estar deshabilitado con zócalo vacío sin repuesto en mochila")
	print("  ✓ Sin repuesto mágico: El jugador debe acudir a la caja de repuestos en la sala 3D")
	
	# 8. Recoger repuesto nuevo de la caja SSDSelectionModal
	GameManager.spares_stock["Disco Duro"] = 3
	var ssd_modal_hdd = ssd_modal_scene.instantiate()
	add_child(ssd_modal_hdd)
	ssd_modal_hdd._choose_storage("hdd")
	
	has_functional_hdd = false
	for it in GameManager.backpack:
		if it.get("name") == "Disco Duro" and not it.get("broken", true):
			has_functional_hdd = true
			break
	assert(has_functional_hdd == true, "Repuesto recogido exitosamente de la caja")
	modal._refresh_ui()
	assert(modal.btn_sacar_hdd.disabled == false, "Botón PONER habilitado tras obtener el repuesto de la caja")
	assert("PONER" in modal.btn_sacar_hdd.text, "Botón debe indicar 'PONER'")
	print("  ✓ Recogida de repuesto en la caja e instalación funcional completada")
	
	modal.queue_free()
	tut_hdd.queue_free()
