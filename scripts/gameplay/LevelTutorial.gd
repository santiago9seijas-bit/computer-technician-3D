extends Node3D

# =============================================================================
# NIVEL TUTORIAL 3D - SALA DE ENTRENAMIENTO ESPACIOSA CON "PARTE DE TUTORIAL.GLB"
# PISO, PAREDES Y TECHO CONSTRUIDOS ÍNTEGRAMENTE CON EL MODELO MODULAR
# COLISIONES AMPLIAS PARA MÁXIMA MOVILIDAD Y SISTEMA DE DIÁLOGO AL INICIO
# =============================================================================

const INTRO_SCENE: PackedScene = preload("res://scenes/ui/LevelIntroModal.tscn")
const DIALOG_SCENE: PackedScene = preload("res://scenes/ui/DialogBox.tscn")

@onready var player: CharacterBody3D = $Player
@onready var hud: Control = $CanvasLayerHUD/HUD

var dialog_box: Control = null

func _ready() -> void:
	if player and hud:
		player.hud_node = hud
		
	var btn_reintentar = hud.get_node_or_null("GameOverPanel/VBox/BtnReiniciarGO") as Button
	if btn_reintentar:
		btn_reintentar.pressed.connect(_on_reintentar)
		
	var btn_siguiente = hud.get_node_or_null("WinPanel/VBox/BtnSiguiente") as Button
	if btn_siguiente:
		btn_siguiente.pressed.connect(_on_siguiente)

	# Inicializar el tutorial con tiempo amplio para práctica libre y sin presión
	GameManager.start_level(999.0)
	GameManager.timer_active = false

	# Crear el diálogo inicial de inducción
	dialog_box = DIALOG_SCENE.instantiate()
	$CanvasLayerHUD.add_child(dialog_box)

	# Iniciar cinemática y mostrar el diálogo "hola lidel :)"
	if player and player.has_method("play_intro_cinematic"):
		player.play_intro_cinematic(func():
			_show_initial_dialog()
		)
	else:
		_show_initial_dialog()

func _show_initial_dialog() -> void:
	GameManager.timer_active = false
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if dialog_box and dialog_box.has_method("show_message"):
		dialog_box.show_message("[SISTEMA // TUTORIAL]", "hola lidel :)", func():
			# Al presionar [E] se cierra el diálogo y se despliega la inducción técnica
			_show_tutorial_briefing()
		)
	else:
		_show_tutorial_briefing()

func _show_tutorial_briefing() -> void:
	GameManager.timer_active = false
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var modal = INTRO_SCENE.instantiate()
	add_child(modal)
	
	# Personalizar títulos del modal para la sala de entrenamiento
	var title_lbl = modal.get_node_or_null("Margin/Panel/VBox/TitleVBox/Title") as Label
	if title_lbl:
		title_lbl.text = "SALA DE ENTRENAMIENTO 3D"
	var sub_lbl = modal.get_node_or_null("Margin/Panel/VBox/TitleVBox/Subtitle") as Label
	if sub_lbl:
		sub_lbl.text = "// INDUCCIÓN AL TALLER Y MANTENIMIENTO //"
		
	var desc_lbl = modal.get_node_or_null("Margin/Panel/VBox/Content/DescVBox/LblDesc") as Label
	if desc_lbl:
		desc_lbl.text = "¡Bienvenido al taller de entrenamiento!\nCamina hacia la mesa central y presiona la tecla [E] para abrir la PC de prueba.\nUsa las herramientas holográficas circulares (Cruz [1], Pala [2], etc.) para desacoplar tornillos y sustituir componentes averiados."
		
	modal.started.connect(func():
		GameManager.timer_active = false # En el tutorial el tiempo no presiona
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
