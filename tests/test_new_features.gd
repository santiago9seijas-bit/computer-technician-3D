extends Node

func _ready() -> void:
	print("--- INICIANDO TEST DE NUEVAS CARACTERÍSTICAS Y OPTIMIZACIONES ---")
	test_save_manager_dollars()
	test_level_server_ceiling()
	test_level_select_hud_and_holo_ring()
	test_server_cases_and_order_desks()
	test_level_intro_modals_desafios()
	test_programming_minigame_and_tutorial()
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
	dbg_inst.queue_free()
	print("  Explicación de comandos con diálogo abajo y avance por [E] validada [OK]")

	print("  [OK] Minijuego de programación y diálogo de Jeremías validados exitosamente.")
