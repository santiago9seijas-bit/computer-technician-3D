extends Node3D

const INTRO_SCENE: PackedScene = preload("res://scenes/ui/LevelIntroModal.tscn")

@onready var player: CharacterBody3D = $Player
@onready var hud: Control = $CanvasLayerHUD/HUD

func _ready() -> void:
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
	add_child(modal)

	var titles = {
		1: ["NIVEL 1 · MONTAJE FAN COOLER", "// DISIPACIÓN TÉRMICA ACTIVA PWM //", "Reemplaza los Fan Coolers dañados en las estaciones de trabajo antes de que los procesadores superen la temperatura máxima."],
		2: ["NIVEL 2 · DIAGNÓSTICO BANCO RAM", "// DETECCIÓN DE MÓDULOS DDR DEFECTUOSOS //", "Identifica zócalos sulfatados y sustituye memorias RAM incompatibles con trabas alineadas."],
		3: ["NIVEL 3 · UNIDAD SATA Y TORNILLOS (HDD / SSD)", "// BAHÍAS DE ALMACENAMIENTO MASIVO //", "Retira los 4 tornillos de retención, desconecta el cable SATA e instala un nuevo disco HDD o SSD."],
		4: ["NIVEL 4 · PASTA TÉRMICA Y CONTACTO", "// RENOVACIÓN DE DISIPACIÓN TÉRMICA //", "Limpia y equilibra el anclaje del disipador de CPU para disipar el calor."],
		5: ["NIVEL 5 · TARJETA GRÁFICA PCIE", "// DESACELERACIÓN PCIE & SALIDA HDMI //", "Desconecta la alimentación PCIe para frenar ventiladores, retira tornillos HDMI y sustituye por GPU operativa."],
		6: ["NIVEL 6 · FUENTE DE PODER ATX", "// ALIMENTACIÓN ELÉCTRICA Y RIELES 12V //", "Desconecta conector ATX 24 pines y CPU auxiliar, sustituyendo por fuente 80 Plus."],
		7: ["NIVEL 7 · ZÓCALO DE PROCESADOR (CPU)", "// MATRIZ DE PINES LGA Y PALANCA //", "Desbloquea la compuerta de carga del socket y monta el procesador alineando muescas."]
	}
	if titles.has(lvl_num):
		var t_info = titles[lvl_num]
		var title_lbl = modal.get_node_or_null("Margin/Panel/VBox/TitleVBox/Title") as Label
		if title_lbl: title_lbl.text = t_info[0]
		var sub_lbl = modal.get_node_or_null("Margin/Panel/VBox/TitleVBox/Subtitle") as Label
		if sub_lbl: sub_lbl.text = t_info[1]
		var desc_lbl = modal.get_node_or_null("Margin/Panel/VBox/Content/DescVBox/LblDesc") as Label
		if desc_lbl: desc_lbl.text = t_info[2]

	modal.started.connect(func():
		# Hasta que el jugador no cierre con la 'X' o 'Iniciar', el contador no baja
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
	CyberPlayTransition.play_exit(get_tree(), "reparacion")
