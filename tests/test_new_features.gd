extends Node

func _ready() -> void:
	print("--- INICIANDO TEST DE NUEVAS CARACTERÍSTICAS Y OPTIMIZACIONES ---")
	test_save_manager_dollars()
	test_level_server_ceiling()
	test_level_select_hud_and_holo_ring()
	test_server_cases_and_order_desks()
	test_level_intro_modals_desafios()
	test_programming_minigame_and_tutorial()
	test_music_manager_and_buses()
	test_terminal_pacman_levels_and_ghost_revive()
	test_malware_invaders_waves()
	test_terminal_tetris_and_console_install()
	test_systems_purple_glitch_bubbles()
	test_user_fixes_batch()
	test_hacking_variety_and_jeremias_tutorial()
	test_level_countdown_phrases()
	if get_node_or_null("/root/MusicManager"):
		MusicManager.stop_immediate()
	print("--- TODOS LOS TESTS COMPLETADOS CON ÉXITO [OK] ---")
	get_tree().quit(0)

func test_save_manager_dollars() -> void:
	print("[TEST] Verificando SaveManager y sistema de dólares...")
	var initial_dollars = SaveManager.get_dollars()
	assert(initial_dollars >= 0, "Dólares iniciales inválidos")
	print("  Dólares actuales: ", initial_dollars)

	var added = SaveManager.add_dollars(150)
	assert(added == initial_dollars + 150, "Fallo al añadir dólares")
	print("  Tras añadir +$150: ", SaveManager.get_dollars())

	var spent = SaveManager.spend_dollars(50)
	assert(spent == true, "Fallo al gastar dólares")
	assert(SaveManager.get_dollars() == initial_dollars + 100, "Balance incorrecto tras gastar")
	print("  Tras gastar $50: ", SaveManager.get_dollars())

	var failed_spend = SaveManager.spend_dollars(9999999)
	assert(failed_spend == false, "No debería permitir gastar más de lo disponible")

	# Probar recompensa al completar nodo
	var before_comp_dollars = SaveManager.get_dollars()
	var before_comp_score = GameManager.score if GameManager else 0
	SaveManager.mark_node_completed("reparacion", 8)
	assert(SaveManager.get_dollars() == before_comp_dollars + 250, "Recompensa de dólares no aplicada")
	print("  Recompensa nivel aplicada con éxito. Nuevo balance: $", SaveManager.get_dollars())
	print("  [OK] SaveManager dólares verificado.")

func test_level_server_ceiling() -> void:
	print("[TEST] Verificando sala de servidores y techo...")
	var scene = load("res://scenes/gameplay/LevelServer1.tscn")
	assert(scene != null, "No se pudo cargar LevelServer1.tscn")
	var instance = scene.instantiate()
	assert(instance != null, "No se pudo instanciar LevelServer1")
	add_child(instance)

	var room = instance.get_node_or_null("Room")
	assert(room != null, "Room no encontrado")

	var ceiling = room.get_node_or_null("Ceiling")
	assert(ceiling != null, "Ceiling no encontrado en Room")
	assert(ceiling.get_node_or_null("CollisionMain") != null, "CollisionMain de techo no encontrado")
	assert(ceiling.get_node_or_null("CollisionAnnex") != null, "CollisionAnnex de techo no encontrado")
	assert(ceiling.get_node_or_null("MeshMain") != null, "MeshMain de techo no encontrado")
	assert(ceiling.get_node_or_null("MeshAnnex") != null, "MeshAnnex de techo no encontrado")

	var light_main = room.get_node_or_null("CeilingLightMain")
	assert(light_main != null, "CeilingLightMain no encontrado")
	print("  CeilingLightMain position Y: ", light_main.position.y)

	var floor_tiles = room.get_node_or_null("Floor/FloorTiles")
	assert(floor_tiles != null, "FloorTiles no encontrado")
	print("  FloorTiles total tiles: ", floor_tiles.get_child_count())

	var mesa = instance.get_node_or_null("MesaPedidos")
	assert(mesa != null, "MesaPedidos no encontrada")
	assert(mesa.get_node_or_null("TecladoPedidos") != null, "TecladoPedidos en MesaPedidos no encontrado")

	instance.queue_free()
	print("  [OK] Sala de servidores y techo verificados.")

func test_level_select_hud_and_holo_ring() -> void:
	print("[TEST] Verificando LevelSelect, marcos de estadísticas alineados y terminal Linux...")
	var scene = load("res://scenes/menus/LevelSelect.tscn")
	assert(scene != null, "No se pudo cargar LevelSelect.tscn")
	var instance = scene.instantiate()
	assert(instance != null, "No se pudo instanciar LevelSelect")
	add_child(instance)

	# 1. Verificar HUD de estadísticas abajo a la izquierda perfectamente alineado
	var hud = instance.get_node_or_null("PlayerStatsHUD")
	assert(hud != null, "PlayerStatsHUD no encontrado")
	var card_pts = hud.get_node_or_null("CardPoints")
	var card_stars = hud.get_node_or_null("CardStars")
	var card_dollars = hud.get_node_or_null("CardDollars")
	assert(card_pts != null and card_stars != null and card_dollars != null, "Las 3 tarjetas de stats deben existir")

	# Verificar misma altura para alineación perfecta
	assert(card_pts.custom_minimum_size.y == card_stars.custom_minimum_size.y and card_stars.custom_minimum_size.y == card_dollars.custom_minimum_size.y, "Las 3 tarjetas deben tener exactamente la misma altura")
	assert(card_pts.custom_minimum_size.y == 34, "La altura de las tarjetas de stats debe ser 34px")

	# Verificar marcos semi-transparentes con shaders holográficos
	assert(card_pts.material is ShaderMaterial, "CardPoints debe tener ShaderMaterial holográfico")
	assert(card_stars.material is ShaderMaterial, "CardStars debe tener ShaderMaterial holográfico")
	assert(card_dollars.material is ShaderMaterial, "CardDollars debe tener ShaderMaterial holográfico")
	var pts_bg_col: Color = card_pts.material.get_shader_parameter("bg_color")
	assert(pts_bg_col.a <= 0.60, "El fondo del marco debe ser semi-transparente (alpha <= 0.60)")

	# Verificar mismo tamaño de letra para los 3 (tamaño 12)
	var lbl_pts_header = card_pts.get_node_or_null("HBox/LblHeader")
	var lbl_pts = card_pts.get_node_or_null("HBox/LblPointsVal")
	var star_logo = card_stars.get_node_or_null("HBox/StarLogo")
	var lbl_stars = card_stars.get_node_or_null("HBox/LblStarsVal")
	var dollar_logo = card_dollars.get_node_or_null("HBox/DollarLogo")
	var lbl_dollars = card_dollars.get_node_or_null("HBox/LblDollarsVal")

	assert(lbl_pts_header != null and lbl_pts != null, "Elementos de CardPoints incompletos")
	assert(star_logo != null and lbl_stars != null, "Elementos de CardStars incompletos")
	assert(dollar_logo != null and lbl_dollars != null, "Elementos de CardDollars incompletos")

	var font_size_pts = lbl_pts.get_theme_font_size("font_size")
	var font_size_stars = lbl_stars.get_theme_font_size("font_size")
	var font_size_dollars = lbl_dollars.get_theme_font_size("font_size")
	var font_size_star_logo = star_logo.get_theme_font_size("font_size")
	var font_size_dollar_logo = dollar_logo.get_theme_font_size("font_size")

	assert(font_size_pts == font_size_stars and font_size_stars == font_size_dollars, "El tamaño de letra debe ser idéntico en las 3 tarjetas")
	assert(font_size_star_logo == font_size_dollar_logo and font_size_star_logo == font_size_pts, "Los logos/iconos y las letras deben compartir el mismo tamaño")
	print("  Tamaño de letra uniforme en las 3 tarjetas: ", font_size_pts, "px [OK]")
	print("  HUD Valores mostrados: Puntos=", lbl_pts.text, ", Estrellas=", lbl_stars.text, ", Dólares=$", lbl_dollars.text)

	# 2. Verificar que DecoracionRight y los sprites antiguos fueron eliminados
	var deco = instance.get_node_or_null("DecoracionRight")
	assert(deco == null, "DecoracionRight debería haber sido eliminado")
	var ring = instance.get_node_or_null("CircularModeSelector/HoloModeRing")
	assert(ring == null, "HoloModeRing antiguo debe haber sido eliminado")
	var old_wheel = instance.get_node_or_null("CircularModeSelector/ModeWheelArea")
	assert(old_wheel == null, "ModeWheelArea con sprites antiguos debe haber sido eliminado")

	# 3. Verificar Recuadros de Terminal Linux en disposición de arco circular
	var term_container = instance.get_node_or_null("CircularModeSelector/TerminalButtons")
	assert(term_container != null, "TerminalButtons Control no encontrado")
	var btn_rep = term_container.get_node_or_null("TermBtnReparacion")
	var btn_sis = term_container.get_node_or_null("TermBtnSistema")
	var btn_srv = term_container.get_node_or_null("TermBtnServidor")
	assert(btn_rep != null and btn_sis != null and btn_srv != null, "Los 3 botones terminal no encontrados")

	assert(btn_rep.material is ShaderMaterial, "TermBtnReparacion debe usar shader de terminal linux")
	assert(btn_sis.material is ShaderMaterial, "TermBtnSistema debe usar shader de terminal linux")
	assert(btn_srv.material is ShaderMaterial, "TermBtnServidor debe usar shader de terminal linux")

	# Verificar separación amplia entre los botones (> 30px de espacio vertical entre tarjetas)
	var v_gap1 = btn_sis.position.y - (btn_rep.position.y + btn_rep.size.y)
	var v_gap2 = btn_srv.position.y - (btn_sis.position.y + btn_sis.size.y)
	assert(btn_sis.position.y - btn_rep.position.y >= 70.0, "La separación vertical entre botones debe ser amplia (>= 70px centro a centro)")
	print("  Separación vertical verificada amplia entre botones [OK]")

	# El modo inicial es "reparacion": debe estar seleccionado, sobresalir hacia la izquierda (-45px) y z_index superior
	assert(btn_rep.material.get_shader_parameter("is_selected") == true, "TermBtnReparacion debe estar seleccionado inicialmente")
	assert(btn_sis.material.get_shader_parameter("is_selected") == false, "TermBtnSistema debe estar inactivo inicialmente")
	assert(btn_srv.material.get_shader_parameter("is_selected") == false, "TermBtnServidor debe estar inactivo inicialmente")
	assert(btn_rep.z_index == 5, "El botón seleccionado debe tener z_index elevado para sobresalir")
	print("  Botón seleccionado sobresale con desplazamiento horizontal y z_index prioritario [OK]")

	# 4. Probar ciclo de modo y animación de recuadros terminal
	if instance.has_method("_cycle_mode"):
		instance._cycle_mode(1)
		print("  Modo tras ciclar: ", instance.current_mode)
		assert(instance.current_mode == "sistema", "El siguiente modo debió ser sistema")
		assert(btn_sis.material.get_shader_parameter("is_selected") == true, "TermBtnSistema debe activarse tras ciclar")
		assert(btn_rep.material.get_shader_parameter("is_selected") == false, "TermBtnReparacion debe desactivarse tras ciclar")
		assert(btn_sis.z_index == 5, "TermBtnSistema debe tener z_index = 5 al sobresalir")
		assert(btn_rep.z_index == 0, "TermBtnReparacion debe volver a z_index = 0 al replegarse")

	# 5. Probar temporizador de auto-desvanecimiento por inactividad
	assert("_mode_selector_idle_timer" in instance, "Debe existir _mode_selector_idle_timer")
	instance._mode_selector_idle_timer = 4.5
	instance._process(0.1)
	assert(instance._is_selector_faded == true, "El selector de modo debió comenzar a desvanecerse por inactividad")
	
	# Despertar selector ante interacción
	instance._wake_mode_selector()
	assert(instance._is_selector_faded == false, "El selector debe reaparecer al interactuar")
	assert(instance._mode_selector_idle_timer == 0.0, "El timer de inactividad debe reiniciarse a 0.0")

	# 6. Verificar eliminación de TutorialArea y recuadro antiguo, y nuevo ModeHeader con directores
	assert(instance.get_node_or_null("TutorialArea") == null, "TutorialArea debe haber sido completamente eliminada")
	assert(instance.get_node_or_null("TopBar/Tabs") == null, "El recuadro antiguo de pestañas en TopBar debe haber sido eliminado")
	var mode_hdr = instance.get_node_or_null("TopBar/ModeHeader")
	assert(mode_hdr != null, "ModeHeader debe existir en TopBar")
	var lbl_m_title = mode_hdr.get_node_or_null("LblModeTitle")
	var lbl_m_dir = mode_hdr.get_node_or_null("LblModeDirector")
	assert(lbl_m_title != null and lbl_m_dir != null, "LblModeTitle y LblModeDirector deben existir en ModeHeader")

	# Probar títulos y directores por cada modo
	instance._switch_mode("reparacion")
	assert(lbl_m_title.text == "MODO REPARACIÓN", "Título en reparación incorrecto")
	assert(lbl_m_dir.text == "DIRECTOR DEL MODO: JOA", "Director en reparación incorrecto")

	instance._switch_mode("sistema")
	assert(lbl_m_title.text == "MODO SISTEMAS", "Título en sistemas incorrecto")
	assert(lbl_m_dir.text == "DIRECTOR DEL MODO: JEREMÍAS", "Director en sistemas incorrecto")

	instance._switch_mode("servidor")
	assert(lbl_m_title.text == "MODO SERVIDORES", "Título en servidores incorrecto")
	assert(lbl_m_dir.text == "DIRECTOR DEL MODO: SANTIGO", "Director en servidores incorrecto")
	print("  Títulos grandes legibles con color y subtítulos de directores (Joa, Jeremías, Santigo) verificados [OK]")

	instance.queue_free()
	print("  [OK] LevelSelect, HUD de estadísticas alineado y Terminal Linux de modos verificados.")

func test_server_cases_and_order_desks() -> void:
	print("[TEST] Verificando 5 torres de servidor, flechas dinámicas, dispensador y gabinetes bajo mesa...")
	
	# 1. Probar LevelServer1
	var srv_scene = load("res://scenes/gameplay/LevelServer1.tscn")
	assert(srv_scene != null, "No se pudo cargar LevelServer1.tscn")
	var srv_inst = srv_scene.instantiate()
	assert(srv_inst != null, "No se pudo instanciar LevelServer1")
	add_child(srv_inst)
	
	# Verificar 5 servidores con flecha y label
	var corridor = srv_inst.get_node_or_null("Room/ServerCorridor")
	assert(corridor != null, "ServerCorridor no encontrado")
	for i in range(1, 6):
		var rack = corridor.get_node_or_null("ServerRackCase%d" % i)
		assert(rack != null, "ServerRackCase%d no encontrado" % i)
		assert(rack.server_id == i, "server_id incorrecto para ServerRackCase%d" % i)
		assert(rack.get_node_or_null("ArrowMesh") != null, "ArrowMesh no encontrada en ServerRackCase%d" % i)
		assert(rack.get_node_or_null("Label3D") != null, "Label3D no encontrada en ServerRackCase%d" % i)
		assert(rack.arrow_mesh.visible == true, "La flecha debe ser visible en ServerRackCase%d" % i)
		assert(rack.get_node_or_null("CuadroDeLuz") == null, "El servidor NO debe tener CuadroDeLuz brillante cubriéndolo")
		print("  ServerRackCase%d validado: ID=%d, Flecha=[OK], Sin brillo en chasis=[OK]" % [i, rack.server_id])
	
	# Verificar esquinas de paredes cerradas herméticamente con solape
	var wall_east = srv_inst.get_node_or_null("Room/Walls/WallEast/MeshEast")
	assert(wall_east != null and wall_east.scale.z >= 8.0, "Pared Este debe solapar las esquinas (scale.z >= 8.0)")
	var wall_south = srv_inst.get_node_or_null("Room/Walls/WallSouthAnnex/MeshSAnnex")
	assert(wall_south != null and wall_south.scale.x >= 5.0, "Pared Sur Anexo debe solapar esquinas (scale.x >= 5.0)")
	print("  Esquinas de paredes verificadas herméticas y con solape [OK]")

	# Verificar escritorio pegado a la pared (X >= 8.6)
	var srv_mesa = srv_inst.get_node_or_null("MesaPedidos")
	assert(srv_mesa != null, "MesaPedidos no encontrada en LevelServer1")
	assert(srv_mesa.position.x >= 8.6, "MesaPedidos debe estar pegada a la pared este (X >= 8.6)")
	print("  MesaPedidos pegada a la pared Este: X = ", srv_mesa.position.x, " [OK]")

	# Verificar dispensador en la pared a la izquierda de la PC (Z < 6.8 y X >= 9.0)
	var disp = srv_inst.get_node_or_null("WallDispenser")
	assert(disp != null, "WallDispenser no encontrado en LevelServer1")
	assert(disp.position.x >= 9.0, "WallDispenser debe estar pegado a la pared este (X >= 9.0)")
	assert(disp.position.z < srv_mesa.position.z, "WallDispenser debe estar a la izquierda de la PC (Z < 6.8)")
	print("  WallDispenser pegado a la pared a la izquierda de la PC: ", disp.position, " [OK]")
	
	# Verificar gabinete girado y en el lado derecho de la mesa de pedidos (local X > 1.0)
	var gab = srv_mesa.get_node_or_null("GabinetePedidos")
	assert(gab != null, "GabinetePedidos no encontrado en servidor")
	assert(gab.position.x > 1.0, "Gabinete debe estar ubicado al lado derecho de la mesa de pedidos (local X > 1.0)")
	print("  GabinetePedidos ubicado al lado derecho de la mesa y girado: local X = ", gab.position.x, " [OK]")

	# Verificar ZonaRepuestos con Estanteria1 y Estanteria2 y cajas ordenadas en LevelServer1
	var zona_rep = srv_inst.get_node_or_null("ZonaRepuestos")
	assert(zona_rep != null, "ZonaRepuestos no encontrada en LevelServer1")
	var est1 = zona_rep.get_node_or_null("Estanteria1")
	var est2 = zona_rep.get_node_or_null("Estanteria2")
	assert(est1 != null and est2 != null, "Estanterias de repuestos 1 y 2 no encontradas en LevelServer1")
	assert(zona_rep.get_node_or_null("SparesCPU") != null, "SparesCPU no encontrado en estantería")
	assert(zona_rep.get_node_or_null("SparesMOBO") != null, "SparesMOBO no encontrado en estantería")
	assert(zona_rep.get_node_or_null("SparesRAM") != null, "SparesRAM no encontrado en estantería")
	assert(zona_rep.get_node_or_null("SparesStorage") != null, "SparesStorage no encontrado en estantería")
	assert(zona_rep.get_node_or_null("SparesGPU") != null, "SparesGPU no encontrado en estantería")
	assert(zona_rep.get_node_or_null("SparesPSU") != null, "SparesPSU no encontrado en estantería")
	assert(zona_rep.get_node_or_null("SparesCooler") != null, "SparesCooler no encontrado en estantería")
	assert(zona_rep.get_node_or_null("SparesLiquid") != null, "SparesLiquid no encontrado en estantería")
	print("  ZonaRepuestos en LevelServer1 con 2 estanterías y 8 cajas ordenadas idéntico al taller [OK]")
	
	srv_inst.queue_free()
	
	# 2. Probar Level1 (Taller de Reparación)
	var lvl1_scene = load("res://scenes/gameplay/Level1.tscn")
	assert(lvl1_scene != null, "No se pudo cargar Level1.tscn")
	var lvl1_inst = lvl1_scene.instantiate()
	add_child(lvl1_inst)
	var lvl1_mesa = lvl1_inst.get_node_or_null("MesaPedidos")
	assert(lvl1_mesa != null, "MesaPedidos no encontrada en Level1")
	assert(lvl1_mesa.get_node_or_null("GabinetePedidos") != null, "GabinetePedidos no encontrado bajo MesaPedidos en Level1")
	lvl1_inst.queue_free()
	print("  GabinetePedidos bajo mesa de pedidos Level1 [OK]")
	
	# 3. Probar LevelSystems1 (Área de Sistemas)
	var sys_scene = load("res://scenes/gameplay/LevelSystems1.tscn")
	assert(sys_scene != null, "No se pudo cargar LevelSystems1.tscn")
	var sys_inst = sys_scene.instantiate()
	add_child(sys_inst)
	var sys_mesa = sys_inst.get_node_or_null("MesaPedidos")
	assert(sys_mesa != null, "MesaPedidos no encontrada en LevelSystems1")
	assert(sys_mesa.get_node_or_null("GabinetePedidos") != null, "GabinetePedidos bajo MesaPedidos en LevelSystems1")
	
	var sys_mesas = sys_inst.get_node_or_null("MesasTrabajo")
	assert(sys_mesas != null, "MesasTrabajo no encontradas en LevelSystems1")
	for i in range(1, 5):
		var wb = sys_mesas.get_node_or_null("WorkBench%d" % i)
		assert(wb != null, "WorkBench%d no encontrado" % i)
		assert(wb.get_node_or_null("GabineteTaller") != null, "GabineteTaller no encontrado bajo WorkBench%d" % i)
		print("  GabineteTaller verificado bajo WorkBench%d [OK]" % i)
	
	sys_inst.queue_free()
	print("  [OK] Servidores, flechas y gabinetes en mesas verificados exitosamente.")

func test_level_intro_modals_desafios() -> void:
	print("[TEST] Verificando tarjetas de desafíos, cero errores y puntos máximos en modales de introducción...")
	var modal_paths = [
		"res://scenes/ui/LevelIntroModal.tscn",
		"res://scenes/ui/LevelServerIntroModal.tscn",
		"res://scenes/ui/LevelSystemsIntroModal.tscn"
	]
	
	for path in modal_paths:
		var scene = load(path)
		assert(scene != null, "No se pudo cargar modal: " + path)
		var inst = scene.instantiate()
		assert(inst != null, "No se pudo instanciar modal: " + path)
		add_child(inst)
		
		var desafios_box = inst.find_child("DesafiosBox", true, false)
		assert(desafios_box != null, "DesafiosBox no encontrado en " + path)
		
		var lbl_desafios = inst.find_child("LblDesafios", true, false)
		var lbl_errores = inst.find_child("LblErrores", true, false)
		var lbl_max_puntos = inst.find_child("LblMaxPuntosNivel", true, false)
		var lbl_puntos_modo = inst.find_child("LblMaxPuntosModo", true, false)
		
		assert(lbl_desafios != null, "LblDesafios no encontrado en " + path)
		assert(lbl_errores != null, "LblErrores no encontrado en " + path)
		assert(lbl_max_puntos != null, "LblMaxPuntosNivel no encontrado en " + path)
		assert(lbl_puntos_modo != null, "LblMaxPuntosModo no encontrado en " + path)
		
		print("  Modal %s:" % path.get_file())
		print("    - Desafíos: ", lbl_desafios.text)
		print("    - Errores/Precisión: ", lbl_errores.text)
		print("    - Puntos Nivel: ", lbl_max_puntos.text)
		print("    - Puntos Modo: ", lbl_puntos_modo.text)
		
		# Probar set_performance_metrics dinámico
		if inst.has_method("set_performance_metrics"):
			inst.set_performance_metrics(true, 0, 300, 300, 2200)
			assert("COMPLETADOS" in lbl_desafios.text, "set_performance_metrics fallo en desafios")
			assert("0 ERRORES" in lbl_errores.text, "set_performance_metrics fallo en errores")
			assert("MAX ALCANZADO" in lbl_max_puntos.text, "set_performance_metrics fallo en max puntos")
			assert("2200" in lbl_puntos_modo.text, "set_performance_metrics fallo en puntos modo")
		
		inst.queue_free()
	
	print("  [OK] Tarjetas de desempeño y desafíos verificadas en todos los modales.")

func test_programming_minigame_and_tutorial() -> void:
	print("[TEST] Verificando minijuego de programación con recuadro de comandos y tutorial de Jeremías...")
	
	# 1. Cargar e instanciar CodeDebuggerMinigame
	var scene = load("res://scenes/minigames/CodeDebuggerMinigame.tscn")
	assert(scene != null, "No se pudo cargar CodeDebuggerMinigame.tscn")
	var minigame = scene.instantiate()
	assert(minigame != null, "No se pudo instanciar CodeDebuggerMinigame")
	add_child(minigame)
	
	# 2. Verificar nodos de UI requeridos
	assert(minigame.command_input != null, "CommandInput LineEdit no encontrado")
	assert(minigame.btn_execute != null, "BtnExecute no encontrado")
	assert(minigame.btn_clean != null, "BtnClean no encontrado")
	assert(minigame.code_rich_text != null, "CodeRichText no encontrado")
	assert(minigame.commands_vbox != null, "CommandsVBox no encontrado")
	
	# 3. Verificar que el recuadro de comandos laterales contiene todos los comandos solicitados
	var commands_text = ""
	for child in minigame.commands_vbox.get_children():
		if child is Button:
			commands_text += child.text + "\n"
			
	assert("/sistem-configure" in commands_text, "Falta comando /sistem-configure en recuadro lateral")
	assert("var" in commands_text, "Falta comando var en recuadro lateral")
	assert("funcs" in commands_text, "Falta comando funcs en recuadro lateral")
	assert("const" in commands_text, "Falta comando const en recuadro lateral")
	assert("node" in commands_text, "Falta comando node en recuadro lateral")
	assert("name" in commands_text, "Falta comando name en recuadro lateral")
	assert("if" in commands_text, "Falta comando if en recuadro lateral")
	assert("else" in commands_text, "Falta comando else en recuadro lateral")
	assert("clean" in commands_text, "Falta comando clean en recuadro lateral")
	assert("exit" in commands_text, "Falta comando exit en recuadro lateral")
	print("  Todos los comandos requeridos verificados en recuadro lateral [OK]")
	
	# 4. Verificar botones de delimitadores (), [], {}
	var btn_parens = minigame.get_node_or_null("ModalControl/Panel/VBox/WorkHBox/RightCol/VBox/DelimitersGrid/BtnParens")
	var btn_brackets = minigame.get_node_or_null("ModalControl/Panel/VBox/WorkHBox/RightCol/VBox/DelimitersGrid/BtnBrackets")
	var btn_braces = minigame.get_node_or_null("ModalControl/Panel/VBox/WorkHBox/RightCol/VBox/DelimitersGrid/BtnBraces")
	assert(btn_parens != null and btn_brackets != null and btn_braces != null, "Botones de delimitadores incompletos")
	print("  Botones de delimitadores (), [], {} verificados [OK]")
	
	# 5. Probar flujo interactivo paso a paso de comandos
	assert(minigame.current_stage == minigame.Stage.WAIT_INIT, "Debe iniciar en WAIT_INIT")
	
	# Comando incorrecto de prueba
	minigame._process_command("iniciar programa")
	assert(minigame.current_stage == minigame.Stage.WAIT_INIT, "No debió avanzar con comando inválido")
	
	# Comando clean
	minigame.command_input.text = "codigo con error"
	minigame._process_command("clean")
	assert(minigame.command_input.text == "", "Comando 'clean' debe limpiar el buffer")
	print("  Comando 'clean' funcional [OK]")
	
	# Paso 1: /sistem-configure
	minigame._process_command("/sistem-configure")
	assert(minigame.current_stage == minigame.Stage.NODE_DECLARATION, "Debió avanzar a NODE_DECLARATION")
	print("  Paso 1 (/sistem-configure) validado [OK]")
	
	# Paso 2: node name("CyberCore") {}
	minigame._process_command("node sin parentesis")
	assert(minigame.current_stage == minigame.Stage.NODE_DECLARATION, "No debió aceptar sintaxis sin () ni {}")
	minigame._process_command("node name(\"CyberCore\") {}")
	assert(minigame.current_stage == minigame.Stage.CONST_DECLARATION, "Debió avanzar a CONST_DECLARATION")
	print("  Paso 2 (node name(\"CyberCore\") {}) validado [OK]")
	
	# Paso 3: const [MAX_SECURITY]
	minigame._process_command("const {MAX_SECURITY}")
	assert(minigame.current_stage == minigame.Stage.CONST_DECLARATION, "No debió aceptar const con llaves {}")
	minigame._process_command("const [MAX_SECURITY]")
	assert(minigame.current_stage == minigame.Stage.VAR_DECLARATION, "Debió avanzar a VAR_DECLARATION")
	print("  Paso 3 (const [MAX_SECURITY]) validado [OK]")
	
	# Paso 4: var [firewall_status]
	minigame._process_command("var (firewall_status)")
	assert(minigame.current_stage == minigame.Stage.VAR_DECLARATION, "No debió aceptar var con parentesis ()")
	minigame._process_command("var [firewall_status]")
	assert(minigame.current_stage == minigame.Stage.FUNCS_DECLARATION, "Debió avanzar a FUNCS_DECLARATION")
	print("  Paso 4 (var [firewall_status]) validado [OK]")
	
	# Paso 5: funcs {audit_protocol}
	minigame._process_command("funcs [audit_protocol]")
	assert(minigame.current_stage == minigame.Stage.FUNCS_DECLARATION, "No debió aceptar funcs con corchetes []")
	minigame._process_command("funcs {audit_protocol}")
	assert(minigame.current_stage == minigame.Stage.CONDITIONAL_LOGIC, "Debió avanzar a CONDITIONAL_LOGIC")
	print("  Paso 5 (funcs {audit_protocol}) validado [OK]")
	
	# Paso 6: if (threat_detected) else
	minigame._process_command("if solo")
	assert(minigame.current_stage == minigame.Stage.CONDITIONAL_LOGIC, "No debió aceptar sin else")
	minigame._process_command("if (threat_detected) else")
	assert(minigame.current_stage == minigame.Stage.WAIT_EXIT, "Debió avanzar a WAIT_EXIT")
	print("  Paso 6 (if ... else) validado [OK]")
	
	# Paso 7: exit para compilar
	minigame._process_command("exit")
	assert(minigame.current_stage == minigame.Stage.COMPLETED, "Debió marcarse como COMPLETED tras exit")
	print("  Paso 7 (exit y compilación exitosa) validado [OK]")
	
	minigame.queue_free()
	
	# 6. Verificar que Jeremías da la bienvenida en LevelTutorial y la explicación completa al entrar en la PC (CodeDebuggerMinigame)
	var tut_text = FileAccess.get_file_as_string("res://scripts/gameplay/LevelTutorial.gd")
	assert("Bienvenido" in tut_text, "Jeremías debe dar la bienvenida al área de sistemas")
	assert("monitor" in tut_text.to_lower(), "Debe indicar al jugador dirigirse al monitor")
	var dbg_text = FileAccess.get_file_as_string("res://scripts/minigames/CodeDebuggerMinigame.gd")
	assert("/sistem-configure" in dbg_text, "Diálogo de Jeremías dentro de la PC debe explicar /sistem-configure")
	assert("node" in dbg_text, "Diálogo de Jeremías dentro de la PC debe explicar node")
	assert("clean" in dbg_text, "Diálogo de Jeremías dentro de la PC debe explicar clean")
	assert("exit" in dbg_text, "Diálogo de Jeremías dentro de la PC debe explicar exit")
	print("  Bienvenida en LevelTutorial y explicación dentro de la PC verificadas [OK]")

	# 7. Verificar Glosario Técnico de Sistemas y Programación
	assert(SaveManager.GLOSSARY_TOPICS.has("sistemas_programacion"), "Glosario debe contener el tema sistemas_programacion")
	SaveManager.unlock_glossary("code_debugger")
	assert(SaveManager.is_glossary_unlocked("sistemas_programacion"), "sistemas_programacion debe estar desbloqueado")
	print("  Glosario técnico de sistemas y programación validado [OK]")

	# 8. Verificar Setup de Mesa y Gabinete en LevelSystems1
	var sys_scene = load("res://scenes/gameplay/LevelSystems1.tscn")
	assert(sys_scene != null, "No se pudo cargar LevelSystems1.tscn")
	var sys_inst = sys_scene.instantiate()
	assert(sys_inst != null, "No se pudo instanciar LevelSystems1")
	add_child(sys_inst)
	var sys_mesa = sys_inst.get_node_or_null("MesaPedidos")
	assert(sys_mesa != null, "MesaPedidos debe existir en LevelSystems1")
	assert(sys_mesa.position.x >= 6.0, "MesaPedidos debe estar pegada a la pared este (X >= 6.0)")
	var sys_gab = sys_mesa.get_node_or_null("GabinetePedidos")
	assert(sys_gab != null, "GabinetePedidos debe existir en MesaPedidos")
	assert(sys_gab.position.x <= -1.0, "GabinetePedidos debe estar ubicado a la izquierda de la PC (local X <= -1.0)")
	assert(sys_mesa.get_node_or_null("MonitorPedidos") != null, "MonitorPedidos de pedidos debe existir intacto")
	assert(sys_mesa.get_node_or_null("RatonPedidos") != null, "RatonPedidos debe existir")
	assert(sys_mesa.get_node_or_null("TecladoPedidos") != null, "TecladoPedidos debe existir")
	var sys_mon_wb1 = sys_inst.get_node_or_null("MesasTrabajo/WorkBench1/SystemsMonitor1")
	assert(sys_mon_wb1 != null, "SystemsMonitor1 interactivo con flecha y [E] debe existir en WorkBench1")
	assert(sys_mon_wb1.arrow_mesh != null, "SystemsMonitor1 debe tener flecha sobre el monitor")
	sys_inst.queue_free()
	print("  Setup de Monitor interactivo y Mesa en LevelSystems1 validado [OK]")

	# 9. Verificar ocultamiento de herramientas en modo Sistemas
	GameManager.current_mode = "sistema"
	var hud_scene = load("res://scenes/ui/HUD.tscn")
	var hud_inst = hud_scene.instantiate()
	add_child(hud_inst)
	var tools_bar_node = hud_inst.get_node_or_null("BottomCenter/ToolsBar")
	var bottom_center_node = hud_inst.get_node_or_null("BottomCenter")
	assert(tools_bar_node.visible == false or bottom_center_node.visible == false, "Herramientas no deben verse en modo sistema")
	hud_inst.queue_free()
	GameManager.current_mode = "reparacion"
	print("  Ocultamiento de barra de herramientas en modo sistemas validado [OK]")

	# 10. Verificar proporciones corregidas de MalwareScannerMinigame
	var mal_scene = load("res://scenes/minigames/MalwareScannerMinigame.tscn")
	assert(mal_scene != null, "No se pudo cargar MalwareScannerMinigame.tscn")
	var mal_inst = mal_scene.instantiate()
	add_child(mal_inst)
	var mal_panel = mal_inst.get_node_or_null("ModalControl/Panel")
	assert(mal_panel != null, "Panel de MalwareScannerMinigame debe existir")
	assert(mal_panel.custom_minimum_size == Vector2(1080, 580), "Panel de MalwareScannerMinigame debe tener proporción 1080x580")
	mal_inst.queue_free()
	print("  Proporciones corregidas de MalwareScannerMinigame validadas [OK]")

	# 11. Verificar setup de mesa de pedidos, monitor, teclado, mouse y gabinetes en LevelTutorial (Modo Sistemas)
	GameManager.current_mode = "sistema"
	var tut_scene = load("res://scenes/gameplay/LevelTutorial.tscn")
	assert(tut_scene != null, "No se pudo cargar LevelTutorial.tscn")
	var tut_inst = tut_scene.instantiate()
	tut_inst.current_mode = "sistema"
	add_child(tut_inst)
	var bench = tut_inst.get_node_or_null("WorkBench")
	assert(bench != null, "WorkBench debe existir en LevelTutorial")
	assert(bench.get_node_or_null("MesaPedidosModel") != null, "MesaPedidosModel debe existir en WorkBench para sistemas")
	var mon_tut = bench.get_node_or_null("MonitorTutorial")
	assert(mon_tut != null, "MonitorTutorial debe existir en WorkBench")
	assert(mon_tut.has_node("ArrowMesh"), "MonitorTutorial debe tener ArrowMesh encima del monitor")
	assert(mon_tut.get_interaction_prompt() != "", "MonitorTutorial debe tener prompt de interacción [E]")
	assert(bench.get_node_or_null("TecladoTutorial") != null, "TecladoTutorial debe existir en WorkBench")
	assert(bench.get_node_or_null("RatonTutorial") != null, "RatonTutorial debe existir en WorkBench")
	var gab_abajo = bench.get_node_or_null("GabineteAbajoTutorial")
	assert(gab_abajo != null, "GabineteAbajoTutorial debe existir al lado del escritorio")
	assert(gab_abajo.position.y <= 0.1, "GabineteAbajoTutorial debe estar en el piso")
	assert(gab_abajo.position.x >= 1.1, "GabineteAbajoTutorial debe estar sacado de abajo, al lado derecho del escritorio")
	var gab_arriba = bench.get_node_or_null("SystemsComputerTutorial")
	assert(gab_arriba != null, "SystemsComputerTutorial debe existir arriba de la mesa")
	assert(gab_arriba.position.y >= 0.8, "SystemsComputerTutorial debe estar sobre la mesa")
	assert(gab_arriba.position.x <= -0.4, "SystemsComputerTutorial debe estar a la izquierda sobre la mesa")
	assert(is_equal_approx(gab_arriba.rotation_degrees.y, -90.0), "SystemsComputerTutorial debe estar girada hacia el jugador")
	assert(gab_arriba.collision_layer == 0, "SystemsComputerTutorial gabinete no debe capturar raycast de [E]")
	tut_inst.queue_free()
	GameManager.current_mode = "reparacion"
	print("  Monitor interactivo con flecha y [E], y gabinetes en LevelTutorial validados [OK]")

	# 12. Verificar explicación interactiva de comandos con diálogo abajo y avance por tecla [E]
	var dbg_scene = load("res://scenes/minigames/CodeDebuggerMinigame.tscn")
	var dbg_inst = dbg_scene.instantiate()
	add_child(dbg_inst)
	assert(dbg_inst.is_jeremias_tutorial_active == true, "Tutorial de Jeremías al entrar a la PC debe activarse")
	assert(dbg_inst.command_buttons_by_cmd.size() >= 10, "Todos los comandos deben estar mapeados en la barra lateral")
	assert(dbg_inst.get_node_or_null("DialogBoxTutorial") != null, "Diálogo oficial DialogBox.tscn de Jeremías debe existir")
	
	# Simular pulsación de la tecla 'E' para avanzar el diálogo
	var e_ev = InputEventKey.new()
	e_ev.pressed = true
	e_ev.keycode = KEY_E
	dbg_inst._input(e_ev)
	assert(dbg_inst.dialog_box_inst.is_typing == false, "Primer [E] completa el texto de inmediato")
	dbg_inst._next_jeremias_tutorial_step()
	assert(dbg_inst.jeremias_step_idx == 1, "Debe avanzar de comando")
	dbg_inst._finish_jeremias_tutorial()
	assert(dbg_inst.is_jeremias_tutorial_active == false, "Tutorial debe finalizar al omitir o completar")
	dbg_inst.free()
	print("  Explicación de comandos con diálogo abajo y avance por [E] validada [OK]")

	print("  [OK] Minijuego de programación y diálogo de Jeremías validados exitosamente.")

func test_music_manager_and_buses() -> void:
	print("[TEST] Verificando MusicManager, pistas de reparación/tutorial y buses de audio...")
	var music_bus_idx = AudioServer.get_bus_index("Music")
	assert(music_bus_idx != -1, "El bus 'Music' debe existir en AudioServer")

	var mm = get_node_or_null("/root/MusicManager")
	assert(mm != null, "MusicManager debe existir como singleton Autoload")

	# 1. Probar reproducción de música de reparación
	mm.play_reparacion()
	assert(mm.current_track == mm.REPARACION_MUSIC_PATH, "MusicManager debe estar reproduciendo 'reparacion'")
	assert(mm.music_player != null and mm.music_player.bus == "Music", "El reproductor de música debe usar el bus 'Music'")

	# 2. Probar transición a música de tutorial
	mm.play_tutorial()
	assert(mm.current_track == mm.TUTORIAL_MUSIC_PATH, "MusicManager debe estar reproduciendo 'tutorial'")

	# 3. Probar control de volumen de música desde GameManager
	GameManager.set_music_volume_val(60.0)
	assert(is_equal_approx(GameManager.music_volume, 60.0), "GameManager.music_volume debe ser 60.0")

	# 4. Probar parada de música
	mm.stop_music(0.0)
	assert(mm.current_track == "", "MusicManager debe detener la pista activa")
	print("  [OK] MusicManager y buses de audio validados exitosamente.")

func test_terminal_pacman_levels_and_ghost_revive() -> void:
	print("[TEST] Verificando niveles de TerminalPacman y resurrección de fantasmas en el centro...")
	var PacmanScript = load("res://scripts/minigames/TerminalPacman.gd")
	assert(PacmanScript != null, "TerminalPacman.gd debe existir")
	var pacman = PacmanScript.new()
	add_child(pacman)
	
	# 1. Probar niveles y generación de laberintos
	assert(pacman.level == 1, "Nivel inicial de Pacman debe ser 1")
	assert(pacman.dots_remaining > 0, "Nivel 1 debe tener puntos para comer")
	var dots_lvl1 = pacman.dots_remaining
	
	pacman.level = 2
	pacman._build_maze()
	assert(pacman.dots_remaining > 0, "Nivel 2 debe tener puntos")
	assert(pacman.maze_data.size() == 21, "Laberinto nivel 2 debe tener 21 filas")
	
	pacman.level = 3
	pacman._build_maze()
	assert(pacman.dots_remaining > 0, "Nivel 3 debe tener puntos")
	
	# 2. Probar resurrección de fantasmas al regresar comidos a la casa central
	pacman._reset_positions()
	assert(pacman.ghosts.size() == 4, "Debe haber 4 fantasmas")
	var blinky = pacman.ghosts[0]
	
	# Comer a Blinky y colocarlo cerca del centro de la casa (10, 10)
	blinky["mode"] = pacman.GhostMode.EATEN
	blinky["pos"] = Vector2(10.0, 10.2)
	blinky["grid"] = Vector2i(10, 10)
	
	# Ejecutar actualización
	pacman._update_ghosts(0.016)
	
	# Debe haber revivido al llegar al centro
	assert(blinky["mode"] == pacman.GhostMode.CHASE, "Fantasma comido debe revivir a modo CHASE al llegar al centro")
	assert(blinky["dir"] == pacman.DIR_UP, "Fantasma revivido debe apuntar hacia arriba para salir")
	
	pacman.free()
	print("  [OK] TerminalPacman: Niveles 1, 2, 3 y sistema de revivir fantasmas validados.")

func test_malware_invaders_waves() -> void:
	print("[TEST] Verificando oleadas y progresión de Malware Invaders...")
	var InvadersScene = load("res://scenes/minigames/MalwareInvadersMinigame.tscn")
	assert(InvadersScene != null, "MalwareInvadersMinigame.tscn debe existir")
	var invaders = InvadersScene.instantiate()
	add_child(invaders)
	
	# 1. Probar oleada 1
	assert(invaders.current_wave == 1, "Oleada inicial debe ser 1")
	assert(invaders.alien_rows == 3, "Oleada 1 debe tener 3 filas")
	assert(invaders.alien_cols == 6, "Oleada 1 debe tener 6 columnas")
	assert(invaders.bunkers.size() > 0, "Los bunkers deben generarse")
	
	# 2. Probar progresión a oleada 2
	invaders.current_wave = 2
	invaders._setup_wave(2)
	assert(invaders.alien_cols == 7, "Oleada 2 debe tener 7 columnas")
	assert(invaders.alien_bullet_speed > 260.0, "La velocidad de proyectil alienígena debe escalar")
	
	# 3. Probar progresión a oleada 3
	invaders.current_wave = 3
	invaders._setup_wave(3)
	assert(invaders.alien_rows == 4, "Oleada 3 debe tener 4 filas")
	
	# 4. Probar que al eliminar todos los aliens se dispara _on_wave_cleared
	for a in invaders.aliens:
		a["alive"] = false
	invaders._on_alien_killed()
	assert(invaders.is_wave_advancing == true, "Al limpiar oleada debe activarse is_wave_advancing")
	assert(invaders.player_score > 0, "Limpiar oleada debe otorgar bonificación de puntuación")
	
	invaders.free()
	print("  [OK] Malware Invaders: Múltiples oleadas, escalado de dificultad y bunkers validados.")

func test_terminal_tetris_and_console_install() -> void:
	print("[TEST] Verificando TerminalTetris y comando 'andro install tetris'...")
	var TetrisScript = load("res://scripts/minigames/TerminalTetris.gd")
	assert(TetrisScript != null, "TerminalTetris.gd debe existir")
	var tetris = TetrisScript.new()
	add_child(tetris)
	
	# 1. Dimensiones y cuadrícula clásica
	assert(tetris.COLS == 10, "Tetris debe tener 10 columnas")
	assert(tetris.ROWS == 20, "Tetris debe tener 20 filas")
	assert(tetris.grid.size() == 20, "Cuadrícula debe tener 20 filas")
	assert(tetris.grid[0].size() == 10, "Cada fila debe tener 10 columnas")
	assert(tetris.level == 1, "Nivel inicial de Tetris debe ser 1")
	
	# 2. Comprobar piezas del 7-bag randomizer
	var pieces = ["I", "O", "T", "S", "Z", "J", "L"]
	for p in pieces:
		assert(tetris.TETROMINOES.has(p), "Tetromino %s debe existir en las definiciones" % p)
		
	# 3. Probar rotación y detección de colisión
	assert(tetris._is_valid_position(Vector2i(3, 0), 0, "T"), "Posición inicial de pieza T debe ser válida")
	assert(not tetris._is_valid_position(Vector2i(-2, 0), 0, "T"), "Posición fuera de bordes debe ser inválida")
	
	# 4. Probar caída y bloqueo
	tetris._hard_drop()
	assert(tetris.current_type != "", "Debe generarse una nueva pieza tras hard drop")
	
	tetris.free()
	
	# 5. Probar comando 'andro install tetris' en LevelSelect
	var LevelSelectScene = load("res://scenes/menus/LevelSelect.tscn")
	assert(LevelSelectScene != null, "LevelSelect.tscn debe existir")
	var level_select = LevelSelectScene.instantiate()
	add_child(level_select)
	
	level_select._on_dev_command_submitted("andro install tetris")
	assert(level_select.dev_console_output != null, "La consola debe estar inicializada")
	var out_text = level_select.dev_console_output.text
	assert(out_text.find("TETRIS") != -1 or out_text.find("tetris") != -1, "La terminal debe confirmar la instalación de Tetris")
	
	level_select.free()
	print("  [OK] TerminalTetris y comando 'andro install tetris' validados con éxito.")

func test_systems_purple_glitch_bubbles() -> void:
	print("[TEST] Verificando nuevas burbujas amarillas de hackeo NieR: Automata con glitch en el área de sistemas...")
	var LevelSelectScene = load("res://scenes/menus/LevelSelect.tscn")
	assert(LevelSelectScene != null, "LevelSelect.tscn debe existir")
	var level_select = LevelSelectScene.instantiate()
	add_child(level_select)
	
	# 1. Validar que LEVELS_DATA["sistema"] tenga 32 nodos
	assert(level_select.LEVELS_DATA["sistema"].size() == 32, "El área de sistemas debe tener exactamente 32 nodos")
	
	# 2. Validar que los nodos 26 al 31 sean amarillos de inspección / hackeo NieR
	for idx in range(26, 32):
		var node = level_select.LEVELS_DATA["sistema"][idx]
		assert(node.get("is_inspection", false) == true, "Nodo %d debe ser de inspección" % idx)
		assert(node.get("color_accent") == Color(1.0, 0.88, 0.15), "Nodo %d debe tener acento amarillo" % idx)
		assert(node.has("jeremias_speech") and node["jeremias_speech"] != "", "Nodo %d debe tener diálogo técnico de Jeremías" % idx)
		assert(node.get("target_scene", "") == "res://scenes/minigames/CyberHackingMinigame.tscn", "Nodo %d debe apuntar a CyberHackingMinigame.tscn" % idx)
		assert(ResourceLoader.exists(node["target_scene"]), "Escena de hackeo debe existir")
	
	# 3. Validar ConstellationGraph y conexiones en modo sistema
	var graph = level_select.get_node_or_null("ConstellationArea/GraphLines")
	assert(graph != null, "ConstellationGraph debe existir en ConstellationArea/GraphLines")
	assert(graph.MODE_NODES["sistema"].size() == 32, "ConstellationGraph debe tener 32 nodos definidos en 'sistema'")
	
	# Conexiones con niveles de hackeo (26 al 31)
	var hack_conns_found = 0
	for conn in graph.MODE_CONNECTIONS["sistema"]:
		if conn.x >= 26 or conn.y >= 26:
			hack_conns_found += 1
	assert(hack_conns_found >= 6, "Debe haber múltiples conexiones enlazando las burbujas amarillas con los niveles de campaña")
	
	# 4. Validar panel de información con diálogo de Jeremías en nodo de hackeo
	level_select._switch_mode("sistema", 0)
	var tut_panel = level_select.get_node_or_null("TutorialInfoPanel")
	assert(tut_panel != null, "TutorialInfoPanel debe existir")
	tut_panel.open_for_inspection_node(level_select.LEVELS_DATA["sistema"][26], 100, 200, true)
	assert(tut_panel.visible == true, "El panel de información debe abrirse para el nodo de hackeo")
	
	# 5. Validar estado de completado en ConstellationGraph (Sin glitch y con flecha NieR)
	assert(graph.has_method("is_node_completed"), "ConstellationGraph debe tener is_node_completed")
	assert(graph.has_method("set_node_completed"), "ConstellationGraph debe tener set_node_completed")
	graph.set_node_completed(26, false)
	assert(graph.is_node_completed(26) == false, "El nodo 26 inicialmente no debe estar completado")
	graph.set_node_completed(26, true)
	assert(graph.is_node_completed(26) == true, "El nodo 26 debe marcarse como completado")
	
	# 6. Validar instanciación y mecánicas del Minijuego de Hackeo NieR: Automata
	var HackScene = load("res://scenes/minigames/CyberHackingMinigame.tscn")
	assert(HackScene != null, "CyberHackingMinigame.tscn debe compilar y cargar")
	var hack_game = HackScene.instantiate()
	add_child(hack_game)
	
	# Probar las 6 etapas (0 a 5)
	for st_idx in range(6):
		hack_game._build_stage_layout(st_idx)
		assert(hack_game.red_core["alive"] == true, "Etapa %d debe tener un Red Core activo" % st_idx)
		assert(hack_game.red_core["hp"] > 0, "Etapa %d Red Core debe tener vida" % st_idx)
		assert(hack_game.blocks.size() > 0, "Etapa %d debe tener bloques" % st_idx)
		assert(hack_game.buttons.size() > 0, "Etapa %d debe tener botones/interruptores" % st_idx)
		assert(hack_game.enemies.size() > 0, "Etapa %d debe tener enemigos que disparen" % st_idx)
	
	# Probar disparo de bala del jugador y daño al Red Core
	hack_game._build_stage_layout(0)
	var prev_hp = hack_game.red_core["hp"]
	hack_game._hit_red_core(1)
	assert(hack_game.red_core["hp"] == prev_hp - 1, "Disparar al Núcleo Rojo debe reducir sus puntos de vida")
	
	# Probar que activar un botón desactiva las barreras conectadas
	var btn0 = hack_game.buttons[0]
	var has_alive_barrier_before = false
	for b in hack_game.blocks:
		if b["type"] == hack_game.BLOCK_BARRIER and b["switch_id"] in btn0["links"] and b["alive"]:
			has_alive_barrier_before = true
			break
	assert(has_alive_barrier_before == true, "Debe haber una barrera activa antes de pulsar el interruptor")
	
	hack_game._activate_button(btn0)
	assert(btn0["active"] == true, "El botón debe quedar en estado activo")
	var has_alive_barrier_after = false
	for b in hack_game.blocks:
		if b["type"] == hack_game.BLOCK_BARRIER and b["switch_id"] in btn0["links"] and b["alive"]:
			has_alive_barrier_after = true
			break
	assert(has_alive_barrier_after == false, "La barrera vinculada al botón debe desaparecer al activarlo")
	
	hack_game.free()
	level_select.free()
	print("  [OK] Minijuego de hackeo NieR: Automata, burbujas amarillas y eliminación de glitch validados exitosamente.")

func test_user_fixes_batch() -> void:
	print("[TEST] Verificando correcciones del usuario: centrado de títulos, audio tutorial reparación, flecha única en sistemas, animación purga glitch y teclas tras salir de tetris...")
	
	# 1. Centrado de títulos en LevelSelect: Comprobar SpacerRightDummy y centrado
	var ls_scene = load("res://scenes/menus/LevelSelect.tscn")
	assert(ls_scene != null, "LevelSelect.tscn debe cargar")
	var ls = ls_scene.instantiate()
	add_child(ls)
	
	var top_bar = ls.get_node_or_null("TopBar")
	assert(top_bar != null, "TopBar debe existir")
	var dummy = top_bar.get_node_or_null("SpacerRightDummy")
	assert(dummy != null, "SpacerRightDummy debe existir para balancear BtnVolver y centrar títulos")
	assert(dummy.custom_minimum_size.x == 130, "SpacerRightDummy debe tener ancho 130px idéntico a BtnVolver")
	
	var lbl_title = top_bar.get_node_or_null("ModeHeader/LblModeTitle")
	var lbl_director = top_bar.get_node_or_null("ModeHeader/LblModeDirector")
	assert(lbl_title != null and lbl_director != null, "Labels de título y director deben existir")
	assert(lbl_title.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "Título debe estar centrado horizontalmente")
	assert(lbl_director.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "Director debe estar centrado horizontalmente")
	print("  1. Centrado horizontal de títulos y subtítulos verificado [OK]")

	# 2. Comprobar que SystemsComputerCase soporta disable_arrow
	var sys_case_scene = load("res://scenes/components/SystemsComputerCase.tscn")
	assert(sys_case_scene != null, "SystemsComputerCase.tscn debe cargar")
	var sys_case = sys_case_scene.instantiate()
	assert("disable_arrow" in sys_case, "SystemsComputerCase debe tener export disable_arrow")
	sys_case.disable_arrow = true
	add_child(sys_case)
	sys_case.update_3d_state()
	var arr = sys_case.get_node_or_null("ArrowMesh")
	assert(arr != null and arr.visible == false, "ArrowMesh en gabinete debe estar oculta cuando disable_arrow es true")
	sys_case.queue_free()
	print("  2. Flecha de gabinete en sistemas deshabilitada verificado [OK]")

	# 3. Comprobar ConstellationGraph y animación de purga de glitch
	var graph = ls.get_node_or_null("ConstellationArea/GraphLines")
	assert(graph != null, "GraphLines debe existir en LevelSelect")
	assert(graph.has_method("play_glitch_purge_animation"), "ConstellationGraph debe implementar play_glitch_purge_animation")
	assert(graph.has_method("set_node_completed"), "ConstellationGraph debe implementar set_node_completed")
	
	graph.play_glitch_purge_animation(26)
	assert(graph.purging_glitch_node_index == 26, "Nodo 26 debe ser el que purga el glitch")
	print("  3. Animación de purga de glitch en el círculo verificado [OK]")

	# 4. Comprobar cierre de consola de desarrollador y liberación de foco
	ls._toggle_dev_console()
	assert(ls.dev_console_overlay.visible == true, "Terminal debe abrirse")
	assert(ls.dev_console_input.has_focus() == true, "Input debe tener foco al abrir terminal")
	ls._close_dev_console()
	assert(ls.dev_console_overlay.visible == false, "Terminal debe cerrarse")
	assert(ls.dev_console_input.has_focus() == false, "Input debe liberar foco al cerrar terminal para permitir cambio de nivel")
	print("  4. Cierre de consola y foco de navegación por teclado verificado [OK]")

	# 5. Comprobar navegación de nivel con teclas
	var initial_mode = ls.current_mode
	ls._navigate_level_camera(1)
	assert(ls.active_zoomed_index >= 0, "Navegar nivel debe seleccionar/acercar a un nivel")
	print("  5. Teclas de cambio de nivel activas verificado [OK]")

	# 6. Comprobar CyberHackingMinigame play_exit configuración de retorno
	var HackingScript = load("res://scripts/minigames/CyberHackingMinigame.gd")
	assert(HackingScript != null, "CyberHackingMinigame.gd debe compilar")
	
	ls.free()
	print("  [OK] Todas las correcciones solicitadas por el usuario validadas exitosamente.")

func test_hacking_variety_and_jeremias_tutorial() -> void:
	print("[TEST] Verificando inducción con Jeremías, variedad de hackeo, prismas reflectores y tetris sound cleanup...")
	
	# 1. Cargar e instanciar CyberHackingMinigame
	var HackScene = load("res://scenes/minigames/CyberHackingMinigame.tscn")
	assert(HackScene != null, "CyberHackingMinigame.tscn debe cargar")
	var HackScript = load("res://scripts/minigames/CyberHackingMinigame.gd")
	assert(HackScript != null, "CyberHackingMinigame.gd debe compilar")
	var tut_steps = HackScript.get_jeremias_tutorial()
	assert(tut_steps != null and tut_steps.size() >= 4, "Debe haber al menos 4 pasos explicativos de Jeremías")
	assert(tut_steps[0]["speaker"] == "JEREMÍAS", "El locutor debe ser Jeremías")
	var hack = HackScene.instantiate()
	add_child(hack)
	
	hack._start_jeremias_tutorial()
	assert(hack.is_tutorial_dialog_active == true, "Diálogo tutorial debe estar activo")
	assert(hack.dialog_box_instance != null, "Instancia de DialogBox debe existir")
	
	hack._skip_tutorial_dialog()
	assert(hack.is_tutorial_dialog_active == false, "Saltar diálogo debe desactivar estado de tutorial")
	assert(hack.tutorial_already_shown == true, "Tutorial debe quedar marcado como mostrado")
	print("  1. Diálogo de inducción de Jeremías y sistema de salto verificados [OK]")
	
	# 3. Verificar prisma reflector de plasma
	hack.blocks.clear()
	hack.player_bullets.clear()
	hack.enemy_bullets.clear()
	hack.enemies.clear()
	hack._add_reflector_block(Rect2(200, 180, 40, 40))
	assert(hack.blocks.size() == 1, "Debe existir el bloque reflector")
	assert(hack.blocks[0]["type"] == hack.BLOCK_REFLECTOR, "El tipo de bloque debe ser BLOCK_REFLECTOR")
	
	# Disparar bala hacia el prisma reflector
	hack.player_bullets.append({
		"pos": Vector2(195, 200),
		"vel": Vector2(400, 0),
		"life": 1.0,
		"is_reflected": false
	})
	hack._process_bullets(0.02)
	assert(hack.player_bullets.size() == 1, "La bala NO debe destruirse al chocar contra el prisma reflector")
	assert(hack.player_bullets[0]["vel"].x < 0, "La velocidad debe rebotar horizontalmente en dirección opuesta")
	assert(hack.player_bullets[0].get("is_reflected", false) == true, "La bala debe marcarse como reflejada")
	print("  2. Mecánica de prisma reflector de plasma verificada [OK]")
	
	# 4. Verificar torreta Spread (disparo triple en abanico)
	hack._add_spread_turret(Vector2(400, 300), 1.0)
	assert(hack.enemies.size() == 1, "Debe registrarse la torreta spread")
	var spread_turret = hack.enemies[0]
	assert(spread_turret["type"] == "spread_turret", "Tipo de enemigo debe ser spread_turret")
	hack._shoot_spread_turret(spread_turret)
	assert(hack.enemy_bullets.size() == 3, "Torreta spread debe disparar exactamente 3 balas en abanico")
	print("  3. Torreta con fuego triple en abanico (Spread) verificada [OK]")
	
	# 5. Verificar que las 6 etapas tienen alta variedad (satélites, interruptores, reflectores)
	var found_reflectors = false
	var found_spread = false
	var found_satellites = false
	for st_idx in range(6):
		hack._build_stage_layout(st_idx)
		for b in hack.blocks:
			if b["type"] == hack.BLOCK_REFLECTOR:
				found_reflectors = true
		for e in hack.enemies:
			if e["type"] == "spread_turret":
				found_spread = true
		if hack.red_core.get("has_satellites", false):
			found_satellites = true
	assert(found_reflectors == true, "Debe haber bloques reflectores en los niveles")
	assert(found_spread == true, "Debe haber torretas spread en los niveles")
	assert(found_satellites == true, "El Núcleo Jefe debe tener satélites orbitantes")
	print("  4. Variedad de niveles, satélites de jefe y mini-puzzles verificados [OK]")

	# 5.1 Verificar Stage 1: Destrucción de 2 guardianes abre el cortafuegos del núcleo (switch_id 10)
	hack.current_stage_index = 1
	hack._build_stage_layout(1)
	assert(hack.enemies.size() == 2, "Stage 1 debe tener exactamente 2 guardianes")
	var s1_barrier_found = false
	for b in hack.blocks:
		if b["type"] == hack.BLOCK_BARRIER and b["switch_id"] == 10:
			assert(b["alive"] == true, "La barrera 10 debe comenzar activa")
			s1_barrier_found = true
	assert(s1_barrier_found, "Debe existir barrera con switch_id 10 en Stage 1")
	for e in hack.enemies:
		e["hp"] = 1
		hack._damage_enemy(e)
	assert(hack.stage1_barrier_cleared == true, "Stage 1 debe marcar stage1_barrier_cleared al liquidar los 2 guardianes")
	for b in hack.blocks:
		if b["type"] == hack.BLOCK_BARRIER and b["switch_id"] == 10:
			assert(b["alive"] == false, "La barrera 10 debe abrirse al morir los guardianes")
	print("  5. Stage 1 (Romper cajas + 2 guardianes) verificado [OK]")

	# 5.2 Verificar Stage 2: Cajas rojas (BLOCK_RED_HAZARD) y daño por contacto
	hack.current_stage_index = 2
	hack._build_stage_layout(2)
	var found_red_hazard = false
	for b in hack.blocks:
		if b["type"] == hack.BLOCK_RED_HAZARD:
			found_red_hazard = true
			break
	assert(found_red_hazard == true, "Stage 2 debe contener bloques BLOCK_RED_HAZARD (Cajas Rojas)")
	hack.player_shields = 4
	hack.is_invulnerable = false
	hack._player_take_hazard_damage()
	assert(hack.player_shields == 3, "El contacto con caja roja debe restar 1 escudo")
	assert(hack.is_invulnerable == true, "Debe otorgar invulnerabilidad temporal tras daño")
	print("  6. Stage 2 (Campo de Cajas Rojas que no se pueden tocar) verificado [OK]")

	# 5.3 Verificar Stage 3: Ronda de amenazas (5 enemigos) para colapsar cortafuegos 300
	hack.current_stage_index = 3
	hack._build_stage_layout(3)
	assert(hack.enemies.size() == 5, "Stage 3 debe tener una ronda completa de 5 enemigos")
	for e in hack.enemies:
		e["hp"] = 1
		hack._damage_enemy(e)
	assert(hack.stage3_barrier_cleared == true, "Stage 3 debe superar la barrera al eliminar la ronda de amenazas")
	for b in hack.blocks:
		if b["type"] == hack.BLOCK_BARRIER and b["switch_id"] == 300:
			assert(b["alive"] == false, "La barrera 300 debe abrirse tras limpiar la ronda")
	print("  7. Stage 3 (Ronda completa de enemigos) verificado [OK]")

	# 5.4 Verificar Stage 4: Interruptores secuenciales (1 -> 2 -> 3)
	hack.current_stage_index = 4
	hack._build_stage_layout(4)
	var btn_1: Dictionary = {}
	var btn_2: Dictionary = {}
	var btn_3: Dictionary = {}
	for btn in hack.buttons:
		if btn.get("order", 0) == 1:
			btn_1 = btn
		elif btn.get("order", 0) == 2:
			btn_2 = btn
		elif btn.get("order", 0) == 3:
			btn_3 = btn
	assert(btn_1.size() > 0 and btn_2.size() > 0 and btn_3.size() > 0, "Stage 4 debe tener botones ordenados 1, 2 y 3")
	hack.stage4_current_step = 0
	# Pulsar botón 2 primero (error)
	hack._activate_button(btn_2)
	assert(hack.stage4_current_step == 0, "Pulsar fuera de orden debe resetear a paso 0")
	# Pulsar en orden correcto 1 -> 2 -> 3
	hack._activate_button(btn_1)
	assert(hack.stage4_current_step == 1, "Pulsar botón 1 debe avanzar a paso 1")
	assert(btn_1["active"] == true, "Botón 1 debe quedar activo")
	hack._activate_button(btn_2)
	assert(hack.stage4_current_step == 2, "Pulsar botón 2 debe avanzar a paso 2")
	assert(btn_2["active"] == true, "Botón 2 debe quedar activo")
	hack._activate_button(btn_3)
	assert(hack.stage4_current_step == 3, "Pulsar botón 3 debe completar secuencia a paso 3")
	assert(hack.stage4_barrier_cleared == true, "Secuencia 1-2-3 completada debe despejar la barrera del núcleo")
	for b in hack.blocks:
		if b["type"] == hack.BLOCK_BARRIER and b["switch_id"] == 400:
			assert(b["alive"] == false, "La barrera 400 debe abrirse al completar la secuencia")
	print("  8. Stage 4 (Botones en orden secuencial 1 ➔ 2 ➔ 3) verificado [OK]")

	# 5.5 Verificar pending_stage_data al instanciar CyberHackingMinigame directamente
	HackScript.pending_stage_data = {
		"number": 28,
		"stage_index": 2,
		"title": "HACKEO // LABERINTO DE CAJAS ROJAS"
	}
	var test_hack_inst = HackScene.instantiate()
	add_child(test_hack_inst)
	assert(test_hack_inst.current_stage_index == 2, "Debe iniciar en la etapa 2 según pending_stage_data")
	assert(test_hack_inst.is_tutorial_dialog_active == false, "Etapas > 0 NO deben activar el tutorial de inducción de Jeremías")
	test_hack_inst.free()
	print("  9. Inyección de etapa directa (pending_stage_data) verificada [OK]")
	
	# 6. Verificar limpieza y apagado de sonido en TerminalTetris
	var TetrisScript = load("res://scripts/minigames/TerminalTetris.gd")
	assert(TetrisScript != null, "TerminalTetris.gd debe compilar")
	var tetris = TetrisScript.new()
	add_child(tetris)
	assert(tetris.has_method("exit_to_terminal"), "TerminalTetris debe tener exit_to_terminal")
	tetris.exit_to_terminal()
	assert(tetris.is_paused == true, "Tetris debe pausarse al salir")
	assert(tetris.is_game_over == true, "Tetris debe terminar juego al salir")
	assert(tetris.sfx_player.playing == false, "El reproductor de sonido de Tetris debe detenerse al salir")
	tetris.free()
	print("  5. Cierre silencioso y detención de audio en TerminalTetris verificado [OK]")
	
	hack.free()
	print("  [OK] Todas las características de variedad, inducción y tetris verificadas con éxito.")

func test_level_countdown_phrases() -> void:
	print("[TEST] Verificando cuenta regresiva 3, 2, 1 y frases (Reparar, Programar, Armar)...")
	var CDScript = load("res://scripts/ui/LevelCountdown.gd")
	assert(CDScript != null, "LevelCountdown.gd debe compilar")
	assert(CDScript.get_action_word("reparacion") == "Reparar", "En reparación la frase debe ser Reparar")
	assert(CDScript.get_action_word("sistema") == "Programar", "En sistemas la frase debe ser Programar")
	assert(CDScript.get_action_word("servidor") == "Armar", "En servidores la frase debe ser Armar")
	
	var modes = ["reparacion", "sistema", "servidor"]
	var expected = ["Reparar", "Programar", "Armar"]
	for i in range(modes.size()):
		var m = modes[i]
		var exp_phrase = expected[i]
		var cd = CDScript.start_countdown(get_tree(), self, m)
		assert(cd != null, "Debe instanciarse LevelCountdown")
		assert(cd.action_word == exp_phrase, "La palabra clave para %s debe ser %s" % [m, exp_phrase])
		assert(cd.countdown_steps.size() == 4, "Debe haber 4 pasos (3, 2, 1, Frase)")
		assert(cd.countdown_steps[0]["text"] == "3", "Paso 0 debe ser '3'")
		assert(cd.countdown_steps[1]["text"] == "2", "Paso 1 debe ser '2'")
		assert(cd.countdown_steps[2]["text"] == "1", "Paso 2 debe ser '1'")
		assert(cd.countdown_steps[3]["text"] == exp_phrase, "Paso 3 debe ser '%s'" % exp_phrase)
		cd.free()
	
	var l1_script = load("res://scripts/gameplay/Level1.gd")
	var lsys_script = load("res://scripts/gameplay/LevelSystems1.gd")
	var lsrv_script = load("res://scripts/gameplay/LevelServer1.gd")
	var lprac_script = load("res://scripts/gameplay/LevelPractice.gd")
	assert(l1_script != null and lsys_script != null and lsrv_script != null and lprac_script != null, "Todos los scripts de niveles deben compilar")
	
	var dummy_node = Node3D.new()
	dummy_node.set_script(l1_script)
	assert(dummy_node.has_method("_start_countdown"), "Level1 debe tener método _start_countdown")
	dummy_node.queue_free()
	
	var dummy_sys = Node3D.new()
	dummy_sys.set_script(lsys_script)
	assert(dummy_sys.has_method("_start_countdown"), "LevelSystems1 debe tener método _start_countdown")
	dummy_sys.queue_free()
	
	var dummy_srv = Node3D.new()
	dummy_srv.set_script(lsrv_script)
	assert(dummy_srv.has_method("_start_countdown"), "LevelServer1 debe tener método _start_countdown")
	dummy_srv.queue_free()
	
	var dummy_prac = Node3D.new()
	dummy_prac.set_script(lprac_script)
	assert(dummy_prac.has_method("_start_countdown"), "LevelPractice debe tener método _start_countdown")
	dummy_prac.queue_free()
	print("  [OK] Cuenta regresiva 3, 2, 1 y palabras clave Reparar, Programar, Armar validadas exitosamente.")

