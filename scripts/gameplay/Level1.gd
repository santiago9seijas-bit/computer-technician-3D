extends Node3D

const LevelCountdown = preload("res://scripts/ui/LevelCountdown.gd")
const INTRO_SCENE: PackedScene = preload("res://scenes/ui/LevelIntroModal.tscn")
const DELIVERED_CABINET_SCENE: PackedScene = preload("res://scenes/components/DeliveredCabinet.tscn")
const DELIVERY_WALL_POS: Vector3 = Vector3(4.5, 0.0, 1.2)

@onready var player: CharacterBody3D = $Player
@onready var hud: Control = $CanvasLayerHUD/HUD

func _ready() -> void:
	GameManager.order_accepted.connect(_on_order_accepted)
	GameManager.order_completed.connect(_on_order_completed)
	if player and hud:
		player.hud_node = hud
		
	var btn_reintentar = hud.get_node_or_null("GameOverPanel/VBox/BtnReiniciarGO") as Button
	if btn_reintentar:
		btn_reintentar.pressed.connect(_on_reintentar)
		
	var btn_siguiente = hud.get_node_or_null("WinPanel/VBox/BtnSiguiente") as Button
	if btn_siguiente:
		btn_siguiente.pressed.connect(_on_siguiente)

	# Pre-inicializar el nivel con el tiempo según la dificultad seleccionada
	GameManager.start_level(GameManager.get_difficulty_time())
	GameManager.timer_active = false

	# Iniciar música de fondo en bucle para los niveles normales de reparación (círculo rojo)
	if has_node("/root/MusicManager"):
		get_node("/root/MusicManager").play_reparacion()

	# Iniciar cinemática de entrada orbital vistosa
	if player and player.has_method("play_intro_cinematic"):
		player.play_intro_cinematic(func():
			_show_mission_briefing()
		)
	else:
		_show_mission_briefing()

func _show_mission_briefing() -> void:
	# Asegurar que el temporizador permanezca en pausa
	GameManager.timer_active = false
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var lvl_num = 1
	var gm = get_node_or_null("/root/GameManager")
	if gm and "current_level_number" in gm and gm.current_level_number > 0:
		lvl_num = gm.current_level_number
		
	var modal = INTRO_SCENE.instantiate()
	var hud_layer = get_node_or_null("CanvasLayerHUD")
	if hud_layer:
		hud_layer.add_child(modal)
	else:
		add_child(modal)

	var titles = {
		1: ["NIVEL 1 · MONTAJE FAN COOLER", "// DISIPACIÓN TÉRMICA ACTIVA PWM //", "OBJETIVO: Reemplaza los Fan Coolers dañados en las estaciones de trabajo antes de que los procesadores superen la temperatura máxima."],
		2: ["NIVEL 2 · DIAGNÓSTICO BANCO RAM", "// DETECCIÓN DE MÓDULOS DDR DEFECTUOSOS //", "OBJETIVO: Identifica zócalos sulfatados y sustituye memorias RAM incompatibles con trabas alineadas."],
		3: ["NIVEL 3 · UNIDAD SATA Y TORNILLOS (HDD / SSD)", "// BAHÍAS DE ALMACENAMIENTO MASIVO //", "OBJETIVO: Retira los 4 tornillos de retención, desconecta el cable SATA e instala un nuevo disco HDD o SSD."],
		4: ["NIVEL 4 · PASTA TÉRMICA Y CONTACTO", "// RENOVACIÓN DE DISIPACIÓN TÉRMICA //", "OBJETIVO: Limpia y equilibra el anclaje del disipador de CPU para disipar el calor."],
		5: ["NIVEL 5 · TARJETA GRÁFICA PCIE", "// DESACELERACIÓN PCIE & SALIDA HDMI //", "OBJETIVO: Desconecta la alimentación PCIe para frenar ventiladores, retira tornillos HDMI y sustituye por GPU operativa."],
		6: ["NIVEL 6 · FUENTE DE PODER ATX", "// ALIMENTACIÓN ELÉCTRICA Y RIELES 12V //", "OBJETIVO: Desconecta conector ATX 24 pines y CPU auxiliar, sustituyendo por fuente 80 Plus."],
		7: ["NIVEL 7 · ZÓCALO DE PROCESADOR (CPU)", "// MATRIZ DE PINES LGA Y PALANCA //", "OBJETIVO: Desbloquea la compuerta de carga del socket y monta el procesador alineando muescas."]
	}
	if titles.has(lvl_num) and modal.has_method("set_mission_data"):
		var t_info = titles[lvl_num]
		modal.set_mission_data(t_info[0], t_info[1], t_info[2])

	modal.started.connect(func():
		_start_countdown()
	)

func _start_countdown() -> void:
	GameManager.timer_active = false
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	LevelCountdown.start_countdown(get_tree(), self, "reparacion", func():
		GameManager.timer_active = true
		if player and player.has_method("set_movement_enabled"):
			player.set_movement_enabled(true)
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	)

func _on_reintentar() -> void:
	get_tree().reload_current_scene()

func _on_siguiente() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var sm = get_node_or_null("/root/SaveManager")
	var lvl_num = GameManager.current_level_number if "current_level_number" in GameManager else 1
	var current_node_idx = 6 + lvl_num # Nivel 1 es nodo 7
	
	if sm and sm.has_method("mark_node_completed"):
		sm.mark_node_completed("reparacion", current_node_idx)
		var next_node = current_node_idx + 1
		if next_node <= 18:
			sm.unlock_node("reparacion", next_node)
		
		# Desbloqueos de micro-talleres morados derivados según el nivel superado
		match lvl_num:
			1:
				sm.unlock_node("reparacion", 26) # Limpieza RAM
				sm.unlock_node("reparacion", 27) # Estática RAM
				if "just_unlocked_node" in sm:
					sm.just_unlocked_node = 26
			4:
				sm.unlock_node("reparacion", 28) # Pasta Térmica CPU
				if "just_unlocked_node" in sm:
					sm.just_unlocked_node = 28
			6:
				sm.unlock_node("reparacion", 30) # Voltaje / Multímetro
				sm.unlock_node("reparacion", 31) # Limpieza PSU
				if "just_unlocked_node" in sm:
					sm.just_unlocked_node = 30
			7:
				sm.unlock_node("reparacion", 29) # Pines CPU
				if "just_unlocked_node" in sm:
					sm.just_unlocked_node = 29
	CyberPlayTransition.play_exit(get_tree(), "reparacion")

func _on_order_accepted(order_data: Dictionary) -> void:
	if not DELIVERED_CABINET_SCENE:
		return
	var cabinet = DELIVERED_CABINET_SCENE.instantiate()
	cabinet.order_data = order_data
	add_child(cabinet)
	cabinet.spawn_animation(DELIVERY_WALL_POS)
	if hud and hud.has_method("set_interaction_prompt"):
		hud.set_interaction_prompt("📦 ¡Gabinete entregado junto a la pared! Recógelo con [F]")

func _on_order_completed(order_data: Dictionary) -> void:
	var cabinets = get_tree().get_nodes_in_group("delivered_cabinets")
	if cabinets.is_empty():
		for child in find_children("*", "DeliveredCabinet", true, false):
			cabinets.append(child)
			
	for cab in cabinets:
		if cab is DeliveredCabinet and is_instance_valid(cab):
			cab.disappear_animation()
			break
			
	if hud and hud.has_method("set_interaction_prompt"):
		hud.set_interaction_prompt("🎉 ¡Pedido completado y retirado con éxito!")
