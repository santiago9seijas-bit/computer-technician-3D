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
	if event.is_action_pressed("pause") and not event.is_echo():
		GameManager.toggle_pause()

func _on_pause_changed(is_paused: bool) -> void:
	visible = is_paused
	if is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_update_time_display(GameManager.time_left)

func _on_time_updated(t: float, _delta: float) -> void:
	if visible:
		_update_time_display(t)

func _update_time_display(t: float) -> void:
	var mins = int(t) / 60
	var secs = int(t) % 60
	lbl_tiempo.text = "Tiempo restante: %02d:%02d" % [mins, secs]

func _on_reiniciar() -> void:
	GameManager.toggle_pause()
	GameManager.start_level(120.0)
	get_tree().reload_current_scene()

func _on_volver_menu() -> void:
	if GameManager.is_game_paused:
		GameManager.toggle_pause()
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")
