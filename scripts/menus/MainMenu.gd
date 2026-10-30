extends Control

# =============================================================================
# MENÚ PRINCIPAL CON CINEMÁTICA DE TRANSICIÓN SUAVE Y MODALES DEDICADOS
# AL PULSAR CONFIGURACIÓN O CONTROLES, LOS BOTONES Y TÍTULO SE DESLIZAN A LA IZQUIERDA,
# EL FONDO SE OSCURECE Y EL PANEL SE DESLIZA DE DERECHA A IZQUIERDA.
# =============================================================================

@onready var btn_jugar: TextureButton = $VBoxContainer/BtnJugar
@onready var btn_configuracion: TextureButton = $VBoxContainer/BtnConfiguracion
@onready var btn_controles: TextureButton = $VBoxContainer/BtnControles
@onready var btn_tutoriales: TextureButton = $VBoxContainer/BtnTutoriales
@onready var btn_salir: TextureButton = $VBoxContainer/BtnSalir

@onready var header_container: HBoxContainer = $HeaderContainer
@onready var vbox_container: VBoxContainer = $VBoxContainer
@onready var decoracion: TextureRect = $Decoracion
@onready var bottom_right_info: VBoxContainer = $BottomRightInfo
@onready var version_label: Label = $BottomRightInfo/VersionLabel

# Fondos y modales
@onready var darken_overlay: ColorRect = $DarkenOverlay
@onready var controls_panel: PanelContainer = $ControlsPanel
@onready var btn_volver_controles: Button = $ControlsPanel/Margin/VBox/Footer/BtnVolverControles

@onready var config_panel: PanelContainer = $ConfigPanel
@onready var btn_volver_config: Button = $ConfigPanel/Margin/VBox/Footer/BtnVolverConfig

# Componentes interactivos de Configuración
@onready var slider_master: HSlider = $ConfigPanel/Margin/VBox/OptionsVBox/MasterVolRow/SliderMaster
@onready var lbl_master_val: Label = $ConfigPanel/Margin/VBox/OptionsVBox/MasterVolRow/LblVal
@onready var slider_sfx: HSlider = $ConfigPanel/Margin/VBox/OptionsVBox/SFXVolRow/SliderSFX
@onready var lbl_sfx_val: Label = $ConfigPanel/Margin/VBox/OptionsVBox/SFXVolRow/LblVal
@onready var btn_fullscreen: Button = $ConfigPanel/Margin/VBox/OptionsVBox/FullscreenRow/BtnFullscreen
@onready var slider_sens: HSlider = $ConfigPanel/Margin/VBox/OptionsVBox/MouseSensRow/SliderSens
@onready var lbl_sens_val: Label = $ConfigPanel/Margin/VBox/OptionsVBox/MouseSensRow/LblVal
@onready var btn_holo: Button = $ConfigPanel/Margin/VBox/OptionsVBox/HoloRow/BtnHolo

var LevelSelectScript = preload("res://scripts/menus/LevelSelect.gd")
var arcade_scene: PackedScene = preload("res://scenes/minigames/MalwareInvadersMinigame.tscn")

const KONAMI_CODE: Array[String] = ["up", "up", "down", "down", "left", "right", "left", "right", "b", "a"]
var konami_buffer: Array[String] = []

var is_transitioning: bool = false
var active_panel: Control = null
var current_tween: Tween = null

# Coordenadas base
var header_orig_x: float = 60.0
var buttons_orig_x: float = 60.0
var deco_orig_x: float = 15.0
var panel_target_x: float = 240.0 # (1280 - 800) / 2 = 240.0

func _ready() -> void:
	modulate = Color.WHITE
	if version_label:
		version_label.text = "Version 0.0.2 Alpha"
	header_orig_x = header_container.position.x
	buttons_orig_x = vbox_container.position.x
	deco_orig_x = decoracion.position.x
	panel_target_x = (size.x - 800.0) * 0.5 if size.x > 0 else 240.0
	
	darken_overlay.modulate.a = 0.0
	darken_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controls_panel.visible = false
	config_panel.visible = false
	
	btn_jugar.pressed.connect(_on_jugar_pressed)
	btn_tutoriales.pressed.connect(_on_tutoriales_pressed)
	btn_controles.pressed.connect(_on_controles_pressed)
	btn_configuracion.pressed.connect(_on_configuracion_pressed)
	btn_salir.pressed.connect(_on_salir_pressed)
	
	btn_volver_controles.pressed.connect(func(): _close_active_subview())
	btn_volver_config.pressed.connect(func(): _close_active_subview())
	
	# Cierre por clic en el fondo oscuro
	darken_overlay.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if active_panel != null:
				_close_active_subview()
	)
	
	_setup_configuration_controls()

func _input(event: InputEvent) -> void:
	if active_panel != null or is_transitioning or get_tree().root.has_node("MalwareInvadersMinigame"):
		return
		
	var input_key = ""
	if event is InputEventKey and event.pressed and not event.echo:
		var k = event.keycode if event.keycode != 0 else event.physical_keycode
		match k:
			KEY_UP:
				input_key = "up"
			KEY_DOWN:
				input_key = "down"
			KEY_LEFT:
				input_key = "left"
			KEY_RIGHT:
				input_key = "right"
			KEY_B:
				input_key = "b"
			KEY_A:
				input_key = "a"
	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_UP:
				input_key = "up"
			JOY_BUTTON_DPAD_DOWN:
				input_key = "down"
			JOY_BUTTON_DPAD_LEFT:
				input_key = "left"
			JOY_BUTTON_DPAD_RIGHT:
				input_key = "right"
			JOY_BUTTON_B:
				input_key = "b"
			JOY_BUTTON_A:
				input_key = "a"
				
	if input_key != "":
		konami_buffer.append(input_key)
		if konami_buffer.size() > KONAMI_CODE.size():
			konami_buffer.pop_front()
			
		if konami_buffer == KONAMI_CODE:
			konami_buffer.clear()
			get_viewport().set_input_as_handled()
			_launch_arcade_easter_egg()

func _launch_arcade_easter_egg() -> void:
	if get_tree().root.has_node("MalwareInvadersMinigame"):
		return
		
	# Destello cian retro confirmando el código secreto
	var flash = ColorRect.new()
	flash.color = Color(0.0, 0.95, 1.0, 0.45)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	
	var tw = create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, 0.4)
	tw.tween_callback(flash.queue_free)
	
	var arcade = arcade_scene.instantiate()
	arcade.name = "MalwareInvadersMinigame"
	arcade.set("is_tutorial_mode", false)
	get_tree().root.add_child(arcade)
	
	arcade.connect("minigame_finished", func(_success: bool):
		arcade.queue_free()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	)

func _unhandled_input(event: InputEvent) -> void:
	if active_panel != null and event.is_action_pressed("ui_cancel"):
		_close_active_subview()
		get_viewport().set_input_as_handled()

func _on_jugar_pressed() -> void:
	if is_transitioning or active_panel != null: return
	is_transitioning = true
	LevelSelectScript.initial_tab = "niveles"
	get_tree().change_scene_to_file("res://scenes/menus/LevelSelect.tscn")

func _on_tutoriales_pressed() -> void:
	if is_transitioning or active_panel != null: return
	is_transitioning = true
	LevelSelectScript.initial_tab = "tutoriales"
	get_tree().change_scene_to_file("res://scenes/menus/LevelSelect.tscn")

func _on_controles_pressed() -> void:
	if is_transitioning: return
	_open_subview(controls_panel)

func _on_configuracion_pressed() -> void:
	if is_transitioning: return
	_open_subview(config_panel)

func _on_salir_pressed() -> void:
	if is_transitioning: return
	get_tree().quit()

# =============================================================================
# CINEMÁTICA DE ENTRADA Y SALIDA DE SUBMENÚS
# =============================================================================
func _open_subview(target_panel: Control) -> void:
	if is_transitioning or active_panel != null:
		return
	is_transitioning = true
	active_panel = target_panel
	
	# Calcular centrado dinámico según el ancho del panel (Controles compacto vs Config)
	var panel_w = target_panel.custom_minimum_size.x if target_panel.custom_minimum_size.x > 0 else target_panel.size.x
	var target_center_x = (size.x - panel_w) * 0.5 if size.x > 0 else (1280.0 - panel_w) * 0.5
	
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		
	darken_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	target_panel.visible = true
	target_panel.position.x = 1320.0 # Fuera de pantalla a la derecha
	target_panel.modulate.a = 0.0
	target_panel.scale = Vector2(0.92, 0.92)
	
	current_tween = create_tween().set_parallel(true)
	
	# 1. El título y los botones del menú principal se deslizan a la izquierda
	current_tween.tween_property(header_container, "position:x", header_orig_x - 700.0, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	current_tween.tween_property(header_container, "modulate:a", 0.0, 0.25)
	
	current_tween.tween_property(vbox_container, "position:x", buttons_orig_x - 600.0, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	current_tween.tween_property(vbox_container, "modulate:a", 0.0, 0.25)
	
	current_tween.tween_property(decoracion, "position:x", deco_orig_x - 500.0, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	current_tween.tween_property(decoracion, "modulate:a", 0.0, 0.25)
	
	current_tween.tween_property(bottom_right_info, "modulate:a", 0.0, 0.22)
	
	# 2. Los colores se hacen más oscuros (overlay de oscurecimiento holográfico)
	current_tween.tween_property(darken_overlay, "modulate:a", 1.0, 0.38).set_trans(Tween.TRANS_QUAD)
	
	# 3. El panel con su marco holográfico se desliza de derecha a izquierda centrado
	current_tween.tween_property(target_panel, "position:x", target_center_x, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	current_tween.tween_property(target_panel, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	current_tween.tween_property(target_panel, "modulate:a", 1.0, 0.30)
	
	current_tween.chain().tween_callback(func():
		is_transitioning = false
	)

func _close_active_subview() -> void:
	if is_transitioning or active_panel == null:
		return
	is_transitioning = true
	var panel = active_panel
	
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		
	current_tween = create_tween().set_parallel(true)
	
	# 1. El panel activo se desliza hacia la derecha y sale
	current_tween.tween_property(panel, "position:x", 1320.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	current_tween.tween_property(panel, "scale", Vector2(0.92, 0.92), 0.32).set_trans(Tween.TRANS_CUBIC)
	current_tween.tween_property(panel, "modulate:a", 0.0, 0.25)
	
	# 2. El oscurecimiento se aclara
	current_tween.tween_property(darken_overlay, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD)
	
	# 3. El título y los botones del menú regresan desde la izquierda a sus posiciones originales
	current_tween.tween_property(header_container, "position:x", header_orig_x, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	current_tween.tween_property(header_container, "modulate:a", 1.0, 0.35)
	
	current_tween.tween_property(vbox_container, "position:x", buttons_orig_x, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	current_tween.tween_property(vbox_container, "modulate:a", 1.0, 0.35)
	
	current_tween.tween_property(decoracion, "position:x", deco_orig_x, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	current_tween.tween_property(decoracion, "modulate:a", 1.0, 0.35)
	
	current_tween.tween_property(bottom_right_info, "modulate:a", 1.0, 0.35)
	
	current_tween.chain().tween_callback(func():
		panel.visible = false
		darken_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		active_panel = null
		is_transitioning = false
	)

# =============================================================================
# INTERACTIVIDAD DEL PANEL DE CONFIGURACIÓN
# =============================================================================
func _setup_configuration_controls() -> void:
	if slider_master:
		slider_master.value = 100.0
		lbl_master_val.text = "100%"
		slider_master.value_changed.connect(func(val: float):
			lbl_master_val.text = "%d%%" % int(val)
			var bus = AudioServer.get_bus_index("Master")
			if bus >= 0:
				AudioServer.set_bus_volume_db(bus, linear_to_db(max(val / 100.0, 0.0001)))
		)
		
	if slider_sfx:
		slider_sfx.value = 100.0
		lbl_sfx_val.text = "100%"
		slider_sfx.value_changed.connect(func(val: float):
			lbl_sfx_val.text = "%d%%" % int(val)
		)
		
	if btn_fullscreen:
		_refresh_fullscreen_button()
		btn_fullscreen.pressed.connect(func():
			var mode = DisplayServer.window_get_mode()
			if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			_refresh_fullscreen_button()
		)
		
	if slider_sens:
		slider_sens.value = 100.0
		lbl_sens_val.text = "1.0x"
		slider_sens.value_changed.connect(func(val: float):
			var factor = val / 100.0
			lbl_sens_val.text = "%.1fx" % factor
		)
		
	if btn_holo:
		btn_holo.pressed.connect(func():
			if "ALTA" in btn_holo.text:
				btn_holo.text = "ESTADO: [ SUAVE / RENDIMIENTO ]"
			else:
				btn_holo.text = "ESTADO: [ ALTA DEFINICIÓN ]"
		)

func _refresh_fullscreen_button() -> void:
	if not btn_fullscreen: return
	var mode = DisplayServer.window_get_mode()
	var is_fs = (mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	btn_fullscreen.text = "PANTALLA: [ COMPLETA ]" if is_fs else "PANTALLA: [ MODO VENTANA ]"
