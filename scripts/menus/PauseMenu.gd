extends Control

@onready var lbl_tiempo: Label = $Modal/VBox/LblTiempo
@onready var btn_reanudar: Button = $Modal/VBox/BtnReanudar
@onready var btn_configuracion: Button = $Modal/VBox/BtnConfiguracion
@onready var btn_reiniciar: Button = $Modal/VBox/BtnReiniciar
@onready var btn_volver: Button = $Modal/VBox/BtnVolver

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	GameManager.pause_state_changed.connect(_on_pause_changed)
	GameManager.time_updated.connect(_on_time_updated)
	
	btn_reanudar.pressed.connect(func(): GameManager.toggle_pause())
	btn_reiniciar.pressed.connect(_on_reiniciar)
	btn_volver.pressed.connect(_on_volver_menu)
	btn_configuracion.pressed.connect(func(): pass)

func _unhandled_input(event: InputEvent) -> void:
	if (event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE)) and not event.is_echo():
		if not visible and _is_any_modal_or_minigame_active():
			return
		get_viewport().set_input_as_handled()
		GameManager.toggle_pause()

func _is_any_modal_or_minigame_active() -> bool:
	var root_node = get_tree().root
	
	# Verificar si hay HUD con pantalla de victoria o fin de juego abierta
	var hud = root_node.find_child("HUD", true, false)
	if is_instance_valid(hud):
		var win_panel = hud.get_node_or_null("WinPanel")
		if is_instance_valid(win_panel) and win_panel.visible:
			return true
		var game_over_panel = hud.get_node_or_null("GameOverPanel")
		if is_instance_valid(game_over_panel) and game_over_panel.visible:
			return true

	# Verificar si hay modales interactivos de inspección o introducción abiertos
	for modal_name in ["PCInspectionModal", "ServerInspectionModal", "PCSystemsModal", "LevelIntroModal", "LevelSystemsIntroModal", "LevelServerIntroModal"]:
		var found = root_node.find_child(modal_name, true, false)
		if is_instance_valid(found) and (not ("visible" in found) or found.visible):
			return true

	# Verificar si hay minijuegos abiertos en la raíz
	for child in root_node.get_children():
		if child != self and (child.name.ends_with("Minigame") or child.is_in_group("minigames")):
			return true

	return false

func _on_pause_changed(is_paused: bool) -> void:
	visible = is_paused
	if is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_update_time_display(GameManager.time_left)
	else:
		_restore_mouse_mode()

func _restore_mouse_mode() -> void:
	if _is_any_modal_or_minigame_active():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_time_updated(t: float, _delta: float) -> void:
	if visible:
		_update_time_display(t)

func _update_time_display(t: float) -> void:
	var mins = int(t) / 60
	var secs = int(t) % 60
	lbl_tiempo.text = "Tiempo restante: %02d:%02d" % [mins, secs]

func _on_reiniciar() -> void:
	if GameManager.is_game_paused:
		GameManager.is_game_paused = false
		get_tree().paused = false
		GameManager.pause_state_changed.emit(false)
	GameManager.start_level(120.0)
	get_tree().reload_current_scene.call_deferred()

func _on_volver_menu() -> void:
	if GameManager.is_game_paused:
		GameManager.is_game_paused = false
		get_tree().paused = false
		GameManager.pause_state_changed.emit(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file.call_deferred("res://scenes/menus/MainMenu.tscn")
