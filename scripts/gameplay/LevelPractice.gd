extends Node3D

# =============================================================================
# NIVEL DE PRÁCTICA 3D - SALA DE ENTRENAMIENTO LIBRE (COPIA DEL TUTORIAL)
# MESA DE REPARACIÓN, LUCES, BANCO DE TRABAJO, CAJAS DE REPUESTOS Y TIEMPO INFINITO
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

	# Inicializar la práctica con tiempo infinito sin cuenta regresiva
	GameManager.start_level(999.0)
	GameManager.timer_active = false
	if hud and hud.has_method("set_infinite_time"):
		hud.set_infinite_time(true)

	# Configurar la PC de práctica con RAM, Fuente y Memorias SSD/HDD para practicar libremente
	var pc = get_node_or_null("WorkBench/Computer1")
	if pc:
		pc.set_meta("is_tutorial_pc", true)
		pc.diagnostic_question = "SALA DE PRÁCTICA: Entrena la extracción, sustitución e inspección de piezas clave:\n• Memoria RAM · • Fuente de Poder (PSU) · • Almacenamiento SSD / HDD"
		pc.diagnostic_faulty_parts.assign(["RAM", "Fuente", "Disco Duro"])
		pc.components = {
			"RAM": "broken",
			"Fuente": "broken",
			"Disco Duro": "broken",
			"Grafica": "empty",
			"Placa Madre": "ok",
			"Fan Cooler": "empty",
			"CPU": "empty"
		}
		if pc.has_method("update_3d_state"):
			pc.update_3d_state()

	# Diálogo de bienvenida al modo de práctica
	dialog_box = DIALOG_SCENE.instantiate()
	$CanvasLayerHUD.add_child(dialog_box)

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
		dialog_box.show_message("[ENTRENAMIENTO // PRÁCTICA]", "¡Bienvenido a la Sala de Práctica! Aquí puedes probar tus habilidades sin presión de tiempo.", func():
			_show_practice_briefing()
		)
	else:
		_show_practice_briefing()

func _show_practice_briefing() -> void:
	GameManager.timer_active = false
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var modal = INTRO_SCENE.instantiate()
	add_child(modal)
	
	var title_lbl = modal.get_node_or_null("Margin/Panel/VBox/TitleVBox/Title") as Label
	if title_lbl:
		title_lbl.text = "SALA DE PRÁCTICA 3D"
	var sub_lbl = modal.get_node_or_null("Margin/Panel/VBox/TitleVBox/Subtitle") as Label
	if sub_lbl:
		sub_lbl.text = "// ENTRENAMIENTO LIBRE · BANCO DE TRABAJO //"
		
	var desc_lbl = modal.get_node_or_null("Margin/Panel/VBox/Content/DescVBox/LblDesc") as Label
	if desc_lbl:
		desc_lbl.text = "¡Estación de práctica técnica lista!\n\nInteractúa con la mesa de reparación y la PC de prueba usando la tecla [E].\nPractica la extracción de Memoria RAM, Fuente de Poder y unidades SSD/HDD tomando repuestos de las cajas laterales.\n\nTiempo: Ilimitado. Entrena tantas veces como desees."
		
	modal.started.connect(func():
		GameManager.timer_active = false
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
