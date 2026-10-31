extends Node3D

const INTRO_SCENE: PackedScene = preload("res://scenes/ui/LevelIntroModal.tscn")

@onready var player: CharacterBody3D = $Player
@onready var hud: Control = $CanvasLayerHUD/HUD
@onready var pause_menu: Control = $CanvasLayerPause/PauseMenu

func _ready() -> void:
	if player and hud:
		player.hud_node = hud
		
	var btn_reintentar = hud.get_node_or_null("GameOverPanel/VBox/BtnReiniciarGO") as Button
	if btn_reintentar:
		btn_reintentar.pressed.connect(_on_reintentar)
		
	var btn_siguiente = hud.get_node_or_null("WinPanel/VBox/BtnSiguiente") as Button
	if btn_siguiente:
		btn_siguiente.pressed.connect(_on_siguiente)

	# Pre-inicializar el nivel con tiempo suficiente (900s) para probar todos los minijuegos
	GameManager.start_level(900.0)
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
	
	var modal = INTRO_SCENE.instantiate()
	add_child(modal)
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
	get_tree().change_scene_to_file("res://scenes/menus/LevelSelect.tscn")
