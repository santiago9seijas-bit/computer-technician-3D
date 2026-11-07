extends Control

# =============================================================================
# MENÚ DE PAUSA CIBERNÉTICO REDISEÑADO
# - Desenfoque y oscurecimiento en tiempo real (Screen Blur Shader).
# - Malla de cables y buses PCB interconectados con pulsos de datos (PauseWebOverlay).
# - Botones en escalera a la derecha con shader holográfico carmesí táctico.
# - Animación de entrada: los botones se deslizan desde la derecha hacia adentro.
# - Animación inversa de reanudar: se deslizan hacia la izquierda guardándose.
# - Submenú de OPCIONES:
#   * Al pulsar "OPCIONES", los botones se deslizan hacia la derecha.
#   * El cuadro de opciones se desliza desde la derecha a la vista.
#   * Al cerrar opciones (o pulsar ESC), el cuadro se desliza a la derecha
#     para guardarse y reaparecen los botones en escalera con su animación.
# - Botón salir: redirige al Selector de Niveles con la transición y sonido de entrada.
# =============================================================================

@onready var blur_overlay: ColorRect = $BlurOverlay
@onready var web_overlay: Control = $PauseWebOverlay
@onready var info_container: VBoxContainer = $InfoContainer
@onready var lbl_tiempo: Label = $InfoContainer/TimePanel/Margin/VBox/LblTiempo

@onready var buttons_staircase: Control = $ButtonsStaircase
@onready var btn_reanudar: TextureButton = $ButtonsStaircase/BtnReanudar
@onready var btn_configuracion: TextureButton = $ButtonsStaircase/BtnConfiguracion
@onready var btn_reiniciar: TextureButton = $ButtonsStaircase/BtnReiniciar
@onready var btn_volver: TextureButton = $ButtonsStaircase/BtnVolver

# Panel de Opciones
@onready var options_panel: PanelContainer = $OptionsPanel
@onready var slider_volume: HSlider = $OptionsPanel/Margin/VBox/SettingsList/VolumeSection/SliderVolume
@onready var lbl_volume_val: Label = $OptionsPanel/Margin/VBox/SettingsList/VolumeSection/HBox/LblVal
@onready var slider_sens: HSlider = $OptionsPanel/Margin/VBox/SettingsList/SensSection/SliderSens
@onready var lbl_sens_val: Label = $OptionsPanel/Margin/VBox/SettingsList/SensSection/HBox/LblVal
@onready var btn_cerrar_opciones: Button = $OptionsPanel/Margin/VBox/Footer/BtnCerrarOpciones

const BASE_OPTIONS_OFFSET_LEFT: float = -450.0
const BASE_OPTIONS_OFFSET_RIGHT: float = -40.0

var buttons_list: Array[TextureButton] = []
var base_button_x: Array[float] = []
var base_info_x: float = 75.0
var is_animating: bool = false
var is_in_options: bool = false

func _get_game_manager() -> Node:
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/GameManager")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	options_panel.visible = false
	
	buttons_list = [btn_reanudar, btn_configuracion, btn_reiniciar, btn_volver]
	for btn in buttons_list:
		base_button_x.append(btn.position.x)
	base_info_x = info_container.position.x
	
	var gm = _get_game_manager()
	if gm:
		if gm.has_signal("pause_state_changed"):
			gm.pause_state_changed.connect(_on_pause_changed)
		if gm.has_signal("time_updated"):
			gm.time_updated.connect(_on_time_updated)
	
	# Conexiones de botones principales
	btn_reanudar.pressed.connect(_on_reanudar_pressed)
	btn_configuracion.pressed.connect(_on_configuracion_pressed)
	btn_reiniciar.pressed.connect(_on_reiniciar_pressed)
	btn_volver.pressed.connect(_on_volver_selector)
	
	# Conexiones del panel de opciones
	btn_cerrar_opciones.pressed.connect(_close_options)
	slider_volume.value_changed.connect(_on_volume_changed)
	slider_sens.value_changed.connect(_on_sens_changed)

func _unhandled_input(event: InputEvent) -> void:
	if (event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE)) and not event.is_echo():
		if visible:
			if is_animating:
				return
			get_viewport().set_input_as_handled()
			if is_in_options:
				_close_options()
			else:
				_animate_out_and_resume()
			return
		else:
			if _is_any_modal_or_minigame_active():
				return
			get_viewport().set_input_as_handled()
			var gm = _get_game_manager()
			if gm and gm.has_method("toggle_pause"):
				gm.toggle_pause()

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

	# Verificar si hay modales interactivos abiertos
	for modal_name in ["PCInspectionModal", "ServerInspectionModal", "PCSystemsModal", "LevelIntroModal", "LevelSystemsIntroModal", "LevelServerIntroModal"]:
		var found = root_node.find_child(modal_name, true, false)
		if is_instance_valid(found) and (not ("visible" in found) or found.visible):
			return true

	# Verificar si hay minijuegos abiertos
	for child in root_node.get_children():
		if child != self and (child.name.ends_with("Minigame") or child.is_in_group("minigames")):
			return true

	return false

func _on_pause_changed(is_paused: bool) -> void:
	if is_paused:
		_animate_in()
	else:
		if not is_animating:
			visible = false
			options_panel.visible = false
			is_in_options = false
			_restore_mouse_mode()

func _restore_mouse_mode() -> void:
	if _is_any_modal_or_minigame_active():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _animate_in() -> void:
	is_animating = true
	visible = true
	is_in_options = false
	options_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var gm = _get_game_manager()
	var cur_time = gm.time_left if gm and "time_left" in gm else 120.0
	_update_time_display(cur_time)
	
	# Inicializar estados de inicio de animación
	blur_overlay.modulate.a = 0.0
	if web_overlay:
		web_overlay.web_alpha = 0.0
		
	info_container.modulate.a = 0.0
	info_container.position.x = -150.0
	
	for i in range(buttons_list.size()):
		var btn = buttons_list[i]
		btn.position.x = base_button_x[i] + 480.0 # Fuera de pantalla a la derecha
		btn.modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true)
	# 1. Entrada de desenfoque y telaraña de cables
	tw.tween_property(blur_overlay, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_QUAD)
	if web_overlay:
		tw.tween_property(web_overlay, "web_alpha", 1.0, 0.32)
		
	# 2. Entrada del contenedor izquierdo (PAUSA + TIEMPO)
	tw.tween_property(info_container, "position:x", base_info_x, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(info_container, "modulate:a", 1.0, 0.25)
	
	# 3. Entrada en escalera de los botones desde la derecha
	for i in range(buttons_list.size()):
		var btn = buttons_list[i]
		var delay = 0.04 + float(i) * 0.055
		tw.tween_property(btn, "position:x", base_button_x[i], 0.38).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "modulate:a", 1.0, 0.22).set_delay(delay)
		
	tw.chain().tween_callback(func():
		is_animating = false
	)

func _animate_out_and_resume() -> void:
	if is_animating:
		return
	is_animating = true
	
	var tw = create_tween().set_parallel(true)
	
	# 1. Si el panel de opciones estaba visible, deslizarlo a la derecha
	if is_in_options and options_panel.visible:
		tw.tween_property(options_panel, "offset_left", BASE_OPTIONS_OFFSET_LEFT + 500.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(options_panel, "offset_right", BASE_OPTIONS_OFFSET_RIGHT + 500.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(options_panel, "modulate:a", 0.0, 0.18)
	
	# 2. Botones de la escalera se deslizan hacia la izquierda guardándose
	for i in range(buttons_list.size()):
		var btn = buttons_list[i]
		var delay = float(i) * 0.035
		var target_x = base_button_x[i] - 520.0
		tw.tween_property(btn, "position:x", target_x, 0.22).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(btn, "modulate:a", 0.0, 0.18).set_delay(delay)
		
	# 3. Info container se desliza hacia la izquierda
	tw.tween_property(info_container, "position:x", -180.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(info_container, "modulate:a", 0.0, 0.18)
	
	# 4. Desvanecimiento de desenfoque y cables
	tw.tween_property(blur_overlay, "modulate:a", 0.0, 0.20)
	if web_overlay:
		tw.tween_property(web_overlay, "web_alpha", 0.0, 0.20)
		
	tw.chain().tween_callback(func():
		is_animating = false
		visible = false
		options_panel.visible = false
		is_in_options = false
		# Restaurar posiciones base para la próxima apertura
		info_container.position.x = base_info_x
		for i in range(buttons_list.size()):
			buttons_list[i].position.x = base_button_x[i]
			buttons_list[i].modulate.a = 1.0
		var gm = _get_game_manager()
		if gm and gm.has_method("toggle_pause"):
			gm.toggle_pause()
	)

func _on_reanudar_pressed() -> void:
	_animate_out_and_resume()

func _on_configuracion_pressed() -> void:
	_open_options()

# =============================================================================
# APERTURA Y CIERRE DEL PANEL DE OPCIONES
# =============================================================================
func _open_options() -> void:
	if is_animating or is_in_options:
		return
	is_animating = true
	is_in_options = true
	
	_sync_options_controls()
	
	# Posicionar el panel de opciones inicialmente fuera de pantalla a la derecha
	options_panel.offset_left = BASE_OPTIONS_OFFSET_LEFT + 500.0
	options_panel.offset_right = BASE_OPTIONS_OFFSET_RIGHT + 500.0
	options_panel.modulate.a = 0.0
	options_panel.visible = true
	
	var tw = create_tween().set_parallel(true)
	
	# 1. Los botones de la escalera se deslizan hacia la derecha para ocultarse
	for i in range(buttons_list.size()):
		var btn = buttons_list[i]
		var delay = float(i) * 0.03
		var target_x = base_button_x[i] + 480.0
		tw.tween_property(btn, "position:x", target_x, 0.22).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(btn, "modulate:a", 0.0, 0.18).set_delay(delay)
		
	# 2. El cuadro de opciones se desliza desde la derecha a la vista
	tw.tween_property(options_panel, "offset_left", BASE_OPTIONS_OFFSET_LEFT, 0.34).set_delay(0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(options_panel, "offset_right", BASE_OPTIONS_OFFSET_RIGHT, 0.34).set_delay(0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(options_panel, "modulate:a", 1.0, 0.24).set_delay(0.12)
	
	tw.chain().tween_callback(func():
		is_animating = false
	)

func _close_options() -> void:
	if is_animating or not is_in_options:
		return
	is_animating = true
	
	var tw = create_tween().set_parallel(true)
	
	# 1. El cuadro de opciones se desliza hacia la derecha para guardarse
	tw.tween_property(options_panel, "offset_left", BASE_OPTIONS_OFFSET_LEFT + 500.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(options_panel, "offset_right", BASE_OPTIONS_OFFSET_RIGHT + 500.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(options_panel, "modulate:a", 0.0, 0.18)
	
	# 2. Los botones de la escalera vuelven a deslizarse desde la derecha con su animación
	for i in range(buttons_list.size()):
		var btn = buttons_list[i]
		btn.position.x = base_button_x[i] + 480.0
		btn.modulate.a = 0.0
		var delay = 0.08 + float(i) * 0.05
		tw.tween_property(btn, "position:x", base_button_x[i], 0.34).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "modulate:a", 1.0, 0.20).set_delay(delay)
		
	tw.chain().tween_callback(func():
		options_panel.visible = false
		is_in_options = false
		is_animating = false
	)

# =============================================================================
# MANEJO DE CONTROLES DE OPCIONES
# =============================================================================
func _sync_options_controls() -> void:
	# Volumen Master
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx != -1:
		if AudioServer.is_bus_mute(bus_idx):
			slider_volume.value = 0.0
			lbl_volume_val.text = "0%"
		else:
			var db = AudioServer.get_bus_volume_db(bus_idx)
			var vol_linear = db_to_linear(db)
			var pct = clampf(vol_linear * 100.0, 0.0, 100.0)
			slider_volume.value = pct
			lbl_volume_val.text = "%d%%" % int(pct)
			
	# Sensibilidad del mouse
	var gm = _get_game_manager()
	var mult: float = 1.0
	if gm and "mouse_sensitivity_multiplier" in gm:
		mult = gm.mouse_sensitivity_multiplier
	slider_sens.value = mult * 100.0
	lbl_sens_val.text = "%.1fx" % mult

func _on_volume_changed(value: float) -> void:
	lbl_volume_val.text = "%d%%" % int(value)
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx != -1:
		if value <= 0.0:
			AudioServer.set_bus_mute(bus_idx, true)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			var db = linear_to_db(value / 100.0)
			AudioServer.set_bus_volume_db(bus_idx, db)

func _on_sens_changed(value: float) -> void:
	var mult = value / 100.0
	lbl_sens_val.text = "%.1fx" % mult
	var gm = _get_game_manager()
	if gm:
		gm.set("mouse_sensitivity_multiplier", mult)
	# Si el jugador está activo en el árbol, actualizar sensibilidad en vivo
	var player = get_tree().root.find_child("Player", true, false)
	if is_instance_valid(player) and "mouse_sensitivity" in player:
		player.mouse_sensitivity = 0.002 * mult

# =============================================================================
# RESTO DE ACCIONES DEL MENÚ
# =============================================================================
func _on_time_updated(t: float, _delta: float) -> void:
	if visible:
		_update_time_display(t)

func _update_time_display(t: float) -> void:
	var mins = int(t) / 60
	var secs = int(t) % 60
	lbl_tiempo.text = "TIEMPO: %02d:%02d" % [mins, secs]

func _on_reiniciar_pressed() -> void:
	var gm = _get_game_manager()
	if gm and gm.is_game_paused:
		gm.is_game_paused = false
		get_tree().paused = false
		if gm.has_signal("pause_state_changed"):
			gm.pause_state_changed.emit(false)
	if gm and gm.has_method("start_level"):
		gm.start_level(120.0)
	get_tree().reload_current_scene.call_deferred()

func _on_volver_selector() -> void:
	var gm = _get_game_manager()
	if gm and gm.is_game_paused:
		gm.is_game_paused = false
		get_tree().paused = false
		if gm.has_signal("pause_state_changed"):
			gm.pause_state_changed.emit(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	CyberPlayTransition.play(
		get_tree(),
		"res://scenes/menus/LevelSelect.tscn",
		"VOLVIENDO AL SELECTOR DE NIVEL",
		"// DESCONECTANDO SESIÓN DE TALLER //"
	)
