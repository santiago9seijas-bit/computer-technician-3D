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
@onready var background: Control = get_node_or_null("Background")
@onready var darken_overlay: ColorRect = $DarkenOverlay
@onready var controls_panel: PanelContainer = $ControlsPanel
@onready var btn_volver_controles: Button = $ControlsPanel/Margin/VBox/Footer/BtnVolverControles

const SYNTHWAVE_GRID_COLOR: Color = Color(0.9, 0.15, 0.55, 0.45)
const SYNTHWAVE_TOP_COLOR: Color = Color(0.06, 0.02, 0.13, 1.0)
const SYNTHWAVE_HORIZON_COLOR: Color = Color(0.24, 0.05, 0.38, 1.0)
const SYNTHWAVE_BOTTOM_COLOR: Color = Color(0.08, 0.02, 0.16, 1.0)
const SYNTHWAVE_LINE_COLOR: Color = Color(1.0, 0.2, 0.6, 1.0)

const EXTRAS_GRID_COLOR: Color = Color(0.0, 0.92, 0.65, 0.48)
const EXTRAS_TOP_COLOR: Color = Color(0.02, 0.05, 0.12, 1.0)
const EXTRAS_HORIZON_COLOR: Color = Color(0.05, 0.22, 0.26, 1.0)
const EXTRAS_BOTTOM_COLOR: Color = Color(0.03, 0.07, 0.09, 1.0)
const EXTRAS_LINE_COLOR: Color = Color(0.0, 0.95, 0.75, 1.0)

var bg_tween: Tween = null

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
@onready var btn_consumo: Button = $ConfigPanel/Margin/VBox/OptionsVBox/ConsumoRow/BtnConsumo
@onready var btn_fotosensible: Button = get_node_or_null("ConfigPanel/Margin/VBox/OptionsVBox/FotosensibleRow/BtnFotosensible")
@onready var btn_prev_lang: Button = get_node_or_null("ConfigPanel/Margin/VBox/OptionsVBox/LanguageRow/ControlsHBox/BtnPrevLang")
@onready var btn_lang: Button = get_node_or_null("ConfigPanel/Margin/VBox/OptionsVBox/LanguageRow/ControlsHBox/BtnLang")
@onready var btn_next_lang: Button = get_node_or_null("ConfigPanel/Margin/VBox/OptionsVBox/LanguageRow/ControlsHBox/BtnNextLang")

var LevelSelectScript = preload("res://scripts/menus/LevelSelect.gd")
var arcade_scene: PackedScene = preload("res://scenes/minigames/MalwareInvadersMinigame.tscn")
var extras_modal_scene: PackedScene = preload("res://scenes/ui/ExtrasModal.tscn")
const WARNING_MODAL_SCENE: PackedScene = preload("res://scenes/ui/PhotosensitiveWarningModal.tscn")
static var warning_shown_this_boot: bool = false

const KONAMI_CODE: Array[String] = ["up", "up", "down", "down", "left", "right", "left", "right", "b", "a"]
var konami_buffer: Array[String] = []
var secret_click_count: int = 0
var konami_feedback_label: Label = null

var is_transitioning: bool = false
var active_panel: Node = null
var current_tween: Tween = null

# Coordenadas base
var header_orig_x: float = 60.0
var buttons_orig_x: float = 60.0
var deco_orig_x: float = 15.0
var panel_target_x: float = 240.0 # (1280 - 800) / 2 = 240.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	modulate = Color.WHITE
	if version_label:
		var cfg_ver = ProjectSettings.get_setting("application/config/version", "0.0.9")
		version_label.text = "Version %s Alpha" % cfg_ver
		version_label.mouse_filter = Control.MOUSE_FILTER_STOP
		version_label.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				secret_click_count += 1
				_show_konami_step("👾 EASTER EGG: %d/5 CLICS" % secret_click_count)
				if secret_click_count >= 5:
					secret_click_count = 0
					_launch_arcade_easter_egg()
		)
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
	_refresh_all_ui_texts()
	
	if not warning_shown_this_boot:
		warning_shown_this_boot = true
		_show_photosensitive_warning()

func _input(event: InputEvent) -> void:
	if active_panel != null or is_transitioning or get_tree().root.has_node("MalwareInvadersMinigame"):
		return
		
	var input_key = ""
	if event is InputEventKey and event.pressed and not event.echo:
		var k = event.keycode if event.keycode != 0 else event.physical_keycode
		if k == KEY_UP or k == KEY_W or k == KEY_KP_8:
			input_key = "up"
		elif k == KEY_DOWN or k == KEY_S or k == KEY_KP_2:
			input_key = "down"
		elif k == KEY_LEFT or k == KEY_KP_4:
			input_key = "left"
		elif k == KEY_RIGHT or k == KEY_D or k == KEY_KP_6:
			input_key = "right"
		elif k == KEY_B:
			input_key = "b"
		elif k == KEY_A:
			# Si en el buffer toca "left" (WASD), reconocerlo como tal
			var next_idx = konami_buffer.size()
			if next_idx < KONAMI_CODE.size() and KONAMI_CODE[next_idx] == "left":
				input_key = "left"
			else:
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
		var next_idx = konami_buffer.size()
		if next_idx < KONAMI_CODE.size() and input_key == KONAMI_CODE[next_idx]:
			konami_buffer.append(input_key)
			_show_konami_step(_get_konami_display())
			if konami_buffer.size() == KONAMI_CODE.size():
				konami_buffer.clear()
				get_viewport().set_input_as_handled()
				_launch_arcade_easter_egg()
		elif input_key == "up":
			# Reiniciar secuencia comenzando con este "up"
			konami_buffer = ["up"]
			_show_konami_step(_get_konami_display())
		else:
			konami_buffer.clear()

func _get_konami_display() -> String:
	var icons = {
		"up": "▲",
		"down": "▼",
		"left": "◄",
		"right": "►",
		"b": "B",
		"a": "A"
	}
	var out = "[ "
	for i in range(KONAMI_CODE.size()):
		var key = KONAMI_CODE[i]
		var sym = icons.get(key, key)
		if i < konami_buffer.size():
			out += sym + " "
		else:
			out += "· "
	out += "]"
	return out

func _show_konami_step(msg: String) -> void:
	if not is_instance_valid(konami_feedback_label):
		konami_feedback_label = Label.new()
		konami_feedback_label.name = "KonamiFeedbackLabel"
		konami_feedback_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		konami_feedback_label.offset_top = -65.0
		konami_feedback_label.offset_bottom = -25.0
		konami_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		konami_feedback_label.add_theme_font_size_override("font_size", 16)
		konami_feedback_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.85, 1.0))
		konami_feedback_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		konami_feedback_label.add_theme_constant_override("outline_size", 6)
		konami_feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(konami_feedback_label)
		
	konami_feedback_label.text = msg
	konami_feedback_label.modulate.a = 1.0
	var tw = create_tween()
	tw.tween_interval(1.8)
	tw.tween_property(konami_feedback_label, "modulate:a", 0.0, 0.4)

func _launch_arcade_easter_egg() -> void:
	if is_transitioning or active_panel != null or get_tree().root.has_node("MalwareInvadersMinigame"):
		return
	is_transitioning = true
	
	# Desactivar interacción y foco de todos los botones del menú principal para no filtrar clicks o teclas
	if vbox_container:
		vbox_container.visible = false
		vbox_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if header_container:
		header_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if btn_jugar:
		btn_jugar.release_focus()
		
	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		var unlocked = sm.unlock_achievement("aliens")
		if not unlocked:
			# Notificación forzada por si ya estaba desbloqueado previamente en este archivo de guardado
			sm.show_toast_notification(
				"¡NUEVO LOGRO DESBLOQUEADO!",
				"Aliens",
				"achievement",
				func(): sm.open_extras_modal("logros")
			)
		
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
	active_panel = arcade
	get_tree().root.add_child(arcade)
	
	arcade.connect("minigame_finished", func(_success: bool):
		arcade.queue_free()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if vbox_container:
			vbox_container.visible = true
			vbox_container.modulate.a = 1.0
			vbox_container.mouse_filter = Control.MOUSE_FILTER_STOP
		if header_container:
			header_container.mouse_filter = Control.MOUSE_FILTER_STOP
		active_panel = null
		is_transitioning = false
	)

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().root.has_node("MalwareInvadersMinigame"):
		return
	if active_panel != null and event.is_action_pressed("ui_cancel"):
		_close_active_subview()
		get_viewport().set_input_as_handled()

func _on_jugar_pressed() -> void:
	if is_transitioning or active_panel != null or get_tree().root.has_node("MalwareInvadersMinigame"): return
	is_transitioning = true
	
	# Efecto visual y de escala en el botón
	if btn_jugar:
		btn_jugar.pivot_offset = btn_jugar.size * 0.5
		var punch_tw = create_tween()
		punch_tw.tween_property(btn_jugar, "scale", Vector2(1.08, 1.08), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		punch_tw.parallel().tween_property(btn_jugar, "modulate", Color(1.8, 1.8, 2.2, 1.0), 0.12)
		
	# Desvanecer botones adyacentes y cabecera hacia la izquierda
	var fade_tw = create_tween()
	fade_tw.set_parallel(true)
	for child in vbox_container.get_children():
		if child != btn_jugar and child is Control:
			fade_tw.tween_property(child, "position:x", child.position.x - 35.0, 0.22).set_trans(Tween.TRANS_QUAD)
			fade_tw.tween_property(child, "modulate:a", 0.0, 0.22)
	if header_container:
		fade_tw.tween_property(header_container, "position:x", header_container.position.x - 45.0, 0.25).set_trans(Tween.TRANS_QUAD)
		fade_tw.tween_property(header_container, "modulate:a", 0.0, 0.25)
	if decoracion:
		fade_tw.tween_property(decoracion, "modulate:a", 0.0, 0.22)
	if bottom_right_info:
		fade_tw.tween_property(bottom_right_info, "modulate:a", 0.0, 0.22)
		
	CyberPlayTransition.play_error_glitch(
		get_tree(),
		"res://scenes/menus/SaveSlotsMenu.tscn"
	)

func _on_tutoriales_pressed() -> void:
	if is_transitioning or active_panel != null or get_tree().root.has_node("MalwareInvadersMinigame"): return
	_open_extras_modal()

func _open_extras_modal() -> void:
	if is_transitioning or active_panel != null or has_node("ExtrasModal") or get_tree().root.has_node("MalwareInvadersMinigame"):
		return
	is_transitioning = true
	
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		
	# 1. Deslizar fluidamente cabecera, botones y decoración a la izquierda (misma cinemática suave)
	current_tween = create_tween().set_parallel(true)
	current_tween.tween_property(header_container, "position:x", header_orig_x - 700.0, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	current_tween.tween_property(vbox_container, "position:x", buttons_orig_x - 700.0, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if decoracion:
		current_tween.tween_property(decoracion, "position:x", deco_orig_x - 700.0, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if bottom_right_info:
		current_tween.tween_property(bottom_right_info, "modulate:a", 0.0, 0.25)
	current_tween.tween_property(darken_overlay, "modulate:a", 1.0, 0.35)
	
	_animate_background_to_extras()
	
	var modal = extras_modal_scene.instantiate()
	active_panel = modal
	add_child(modal)
	
	current_tween.chain().tween_callback(func():
		is_transitioning = false
	)
	
	modal.modal_closed.connect(func():
		is_transitioning = true
		_animate_background_from_extras()
		
		var restore_tw = create_tween().set_parallel(true)
		restore_tw.tween_property(header_container, "position:x", header_orig_x, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		restore_tw.tween_property(vbox_container, "position:x", buttons_orig_x, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if decoracion:
			restore_tw.tween_property(decoracion, "position:x", deco_orig_x, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if bottom_right_info:
			restore_tw.tween_property(bottom_right_info, "modulate:a", 1.0, 0.3)
		restore_tw.tween_property(darken_overlay, "modulate:a", 0.0, 0.3)
		
		restore_tw.chain().tween_callback(func():
			active_panel = null
			is_transitioning = false
		)
	)

func _animate_background_to_extras() -> void:
	if not background: return
	if bg_tween and bg_tween.is_valid():
		bg_tween.kill()
	bg_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	bg_tween.tween_property(background, "grid_color", EXTRAS_GRID_COLOR, 0.45)
	bg_tween.tween_property(background, "bg_top_color", EXTRAS_TOP_COLOR, 0.45)
	bg_tween.tween_property(background, "bg_horizon_color", EXTRAS_HORIZON_COLOR, 0.45)
	bg_tween.tween_property(background, "bg_bottom_color", EXTRAS_BOTTOM_COLOR, 0.45)
	if "horizon_line_color" in background:
		bg_tween.tween_property(background, "horizon_line_color", EXTRAS_LINE_COLOR, 0.45)

func _animate_background_from_extras() -> void:
	if not background: return
	if bg_tween and bg_tween.is_valid():
		bg_tween.kill()
	bg_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	bg_tween.tween_property(background, "grid_color", SYNTHWAVE_GRID_COLOR, 0.45)
	bg_tween.tween_property(background, "bg_top_color", SYNTHWAVE_TOP_COLOR, 0.45)
	bg_tween.tween_property(background, "bg_horizon_color", SYNTHWAVE_HORIZON_COLOR, 0.45)
	bg_tween.tween_property(background, "bg_bottom_color", SYNTHWAVE_BOTTOM_COLOR, 0.45)
	if "horizon_line_color" in background:
		bg_tween.tween_property(background, "horizon_line_color", SYNTHWAVE_LINE_COLOR, 0.45)

func _on_controles_pressed() -> void:
	if is_transitioning or active_panel != null or get_tree().root.has_node("MalwareInvadersMinigame"): return
	_open_subview(controls_panel)

func _on_configuracion_pressed() -> void:
	if is_transitioning or active_panel != null or get_tree().root.has_node("MalwareInvadersMinigame"): return
	_open_subview(config_panel)

func _on_salir_pressed() -> void:
	if is_transitioning or active_panel != null or get_tree().root.has_node("MalwareInvadersMinigame"): return
	get_tree().quit()

# =============================================================================
# CINEMÁTICA DE ENTRADA Y SALIDA DE SUBMENÚS
# =============================================================================
func _open_subview(target_panel: Control) -> void:
	if is_transitioning or active_panel != null:
		return
	is_transitioning = true
	active_panel = target_panel
	
	_refresh_all_ui_texts()
	
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
		_refresh_all_ui_texts()
	)

func _get_game_manager() -> Node:
	return get_node_or_null("/root/GameManager")

# =============================================================================
# INTERACTIVIDAD DEL PANEL DE CONFIGURACIÓN
# =============================================================================
func _setup_configuration_controls() -> void:
	var gm = _get_game_manager()
	if slider_master:
		var m_vol = gm.master_volume if gm and "master_volume" in gm else 100.0
		slider_master.value = m_vol
		lbl_master_val.text = "%d%%" % int(m_vol)
		slider_master.value_changed.connect(func(val: float):
			lbl_master_val.text = "%d%%" % int(val)
			var g = _get_game_manager()
			if g and g.has_method("set_master_volume_val"):
				g.set_master_volume_val(val)
		)
		
	if slider_sfx:
		var s_vol = gm.sfx_volume if gm and "sfx_volume" in gm else 100.0
		slider_sfx.value = s_vol
		lbl_sfx_val.text = "%d%%" % int(s_vol)
		slider_sfx.value_changed.connect(func(val: float):
			lbl_sfx_val.text = "%d%%" % int(val)
			var g = _get_game_manager()
			if g and g.has_method("set_sfx_volume_val"):
				g.set_sfx_volume_val(val)
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
		var sens = gm.mouse_sensitivity_multiplier if gm and "mouse_sensitivity_multiplier" in gm else 1.0
		slider_sens.value = sens * 100.0
		lbl_sens_val.text = "%.1fx" % sens
		slider_sens.value_changed.connect(func(val: float):
			var factor = val / 100.0
			lbl_sens_val.text = "%.1fx" % factor
			var g = _get_game_manager()
			if g and g.has_method("set_mouse_sensitivity"):
				g.set_mouse_sensitivity(factor)
		)
		
	if btn_holo:
		_refresh_holo_button()
		btn_holo.pressed.connect(func():
			var g = _get_game_manager()
			if g and "performance_mode" in g and g.has_method("set_performance_mode"):
				g.set_performance_mode(!g.performance_mode)
			_refresh_holo_button()
		)

	if btn_consumo:
		_refresh_consumo_button()
		btn_consumo.pressed.connect(func():
			var g = _get_game_manager()
			if g and g.has_method("toggle_hardware_monitor"):
				g.toggle_hardware_monitor()
			_refresh_consumo_button()
		)

	if btn_fotosensible:
		_refresh_fotosensible_button()
		btn_fotosensible.pressed.connect(func():
			var g = _get_game_manager()
			if g and g.has_method("toggle_photosensitive_mode"):
				g.toggle_photosensitive_mode()
			_refresh_fotosensible_button()
		)

	_refresh_language_button()
	if btn_prev_lang:
		btn_prev_lang.pressed.connect(func():
			if has_node("/root/LocalizationManager"):
				get_node("/root/LocalizationManager").prev_locale()
		)
	if btn_next_lang:
		btn_next_lang.pressed.connect(func():
			if has_node("/root/LocalizationManager"):
				get_node("/root/LocalizationManager").next_locale()
		)
	if btn_lang:
		btn_lang.pressed.connect(func():
			if has_node("/root/LocalizationManager"):
				get_node("/root/LocalizationManager").next_locale()
		)

	if has_node("/root/LocalizationManager"):
		get_node("/root/LocalizationManager").locale_changed.connect(func(_new_loc: String):
			_on_locale_changed()
		)

func _on_locale_changed() -> void:
	_refresh_all_ui_texts()

func _refresh_all_ui_texts() -> void:
	var loc = get_node_or_null("/root/LocalizationManager")
	if not loc:
		return

	# 1. Botones principales del menú de inicio
	if btn_jugar:
		var lbl = btn_jugar.get_node_or_null("Label")
		if lbl:
			lbl.text = loc.translate_text("JUGAR")
	if btn_configuracion:
		var lbl = btn_configuracion.get_node_or_null("Label")
		if lbl:
			lbl.text = loc.translate_text("CONFIGURACIÓN")
	if btn_controles:
		var lbl = btn_controles.get_node_or_null("Label")
		if lbl:
			lbl.text = loc.translate_text("CONTROLES")
	if btn_tutoriales:
		var lbl = btn_tutoriales.get_node_or_null("Label")
		if lbl:
			lbl.text = "EXTRAS"
	if btn_salir:
		var lbl = btn_salir.get_node_or_null("Label")
		if lbl:
			lbl.text = loc.translate_text("SALIR")

	# 2. Cuadro de Configuración (ConfigPanel) - TODO EN EL IDIOMA ACTIVO
	var cfg_nodes = {
		"ConfigPanel/Margin/VBox/HeaderVBox/Badge": "[ SISTEMA // PANEL DE CONFIGURACIÓN ]",
		"ConfigPanel/Margin/VBox/HeaderVBox/Title": "CONFIGURACIÓN DEL SISTEMA",
		"ConfigPanel/Margin/VBox/HeaderVBox/Sub": "Ajustes de audio, pantalla completa y calibración de periféricos",
		"ConfigPanel/Margin/VBox/OptionsVBox/MasterVolRow/Lbl": "VOLUMEN MAESTRO",
		"ConfigPanel/Margin/VBox/OptionsVBox/SFXVolRow/Lbl": "EFECTOS DE SONIDO (SFX)",
		"ConfigPanel/Margin/VBox/OptionsVBox/FullscreenRow/Lbl": "MODO DE PANTALLA",
		"ConfigPanel/Margin/VBox/OptionsVBox/LanguageRow/Lbl": "IDIOMA",
		"ConfigPanel/Margin/VBox/OptionsVBox/MouseSensRow/Lbl": "SENSIBILIDAD DE CÁMARA",
		"ConfigPanel/Margin/VBox/OptionsVBox/HoloRow/Lbl": "SHADERS HOLOGRÁFICOS",
		"ConfigPanel/Margin/VBox/OptionsVBox/ConsumoRow/Lbl": "CONSUMO",
		"ConfigPanel/Margin/VBox/OptionsVBox/FotosensibleRow/Lbl": "FOTOSENSIBILIDAD",
		"ConfigPanel/Margin/VBox/Footer/BtnVolverConfig": "VOLVER"
	}
	for path in cfg_nodes:
		var n = get_node_or_null(path)
		if n:
			n.text = loc.translate_text(cfg_nodes[path])
			if n.has_method("queue_redraw"):
				n.queue_redraw()

	_refresh_language_button()
	_refresh_fullscreen_button()
	_refresh_holo_button()
	_refresh_consumo_button()
	_refresh_fotosensible_button()

	# 3. Cuadro de Controles (ControlsPanel) - TODO EN EL IDIOMA ACTIVO
	var ctrl_nodes = {
		"ControlsPanel/Margin/VBox/HeaderVBox/Badge": "[ SISTEMA // GUÍA RÁPIDA ]",
		"ControlsPanel/Margin/VBox/HeaderVBox/Title": "MAPA DE CONTROLES",
		"ControlsPanel/Margin/VBox/HeaderVBox/Sub": "Comandos esenciales para el taller y minijuegos",
		"ControlsPanel/Margin/VBox/ContentHBox/LeftCol/ColTitle": "── MOVIMIENTO ──",
		"ControlsPanel/Margin/VBox/ContentHBox/LeftCol/Item1/Desc": "Desplazarse",
		"ControlsPanel/Margin/VBox/ContentHBox/LeftCol/Item2/Desc": "Mirar / Cursor",
		"ControlsPanel/Margin/VBox/ContentHBox/LeftCol/Item3/Desc": "Correr / Sprint",
		"ControlsPanel/Margin/VBox/ContentHBox/LeftCol/ItemJump/Desc": "Saltar",
		"ControlsPanel/Margin/VBox/ContentHBox/LeftCol/Item4/Desc": "Pausa / Ajustes",
		"ControlsPanel/Margin/VBox/ContentHBox/RightCol/ColTitle": "── HERRAMIENTAS ──",
		"ControlsPanel/Margin/VBox/ContentHBox/RightCol/Item1/Desc": "Interactuar / Usar",
		"ControlsPanel/Margin/VBox/ContentHBox/RightCol/Item2/Desc": "Destornillador Cruz (+)",
		"ControlsPanel/Margin/VBox/ContentHBox/RightCol/Item3/Desc": "Destornillador Pala (-)",
		"ControlsPanel/Margin/VBox/ContentHBox/RightCol/Item4/Desc": "Cautín, Pinzas, Tester",
		"ControlsPanel/Margin/VBox/HintBox/Margin/HintLabel": "💡 TIP: Pulsa [1] o [2] para alternar destornilladores en minijuegos.",
		"ControlsPanel/Margin/VBox/Footer/BtnVolverControles": "VOLVER"
	}
	for path in ctrl_nodes:
		var n = get_node_or_null(path)
		if n:
			n.text = loc.translate_text(ctrl_nodes[path])
			if n.has_method("queue_redraw"):
				n.queue_redraw()

	# 4. Textos de barra inferior
	var os_lbl = get_node_or_null("BottomRightInfo/BadgeHBox/BadgeText")
	if os_lbl:
		os_lbl.text = loc.translate_text("HARDWARE WORKSHOP // REPAIR OS v2.0")
	if version_label:
		var cfg_ver = ProjectSettings.get_setting("application/config/version", "0.0.9")
		var v_prefix = "Versión" if loc.get_locale() == "es" else loc.translate_text("Version")
		version_label.text = "%s %s Alpha" % [v_prefix, cfg_ver]

func _refresh_language_button() -> void:
	if not btn_lang: return
	var lang_name = "ESPAÑOL"
	if has_node("/root/LocalizationManager"):
		lang_name = get_node("/root/LocalizationManager").get_locale_name()
	btn_lang.text = "[ %s ]" % lang_name
	if btn_lang.has_method("queue_redraw"):
		btn_lang.queue_redraw()

func _show_photosensitive_warning() -> void:
	var modal = WARNING_MODAL_SCENE.instantiate()
	modal.name = "PhotosensitiveWarningModal"
	modal.modal_closed.connect(func():
		_refresh_fotosensible_button()
	)
	add_child(modal)

func _refresh_fotosensible_button() -> void:
	if not btn_fotosensible: return
	var gm = _get_game_manager()
	var is_on = gm.is_photosensitive_mode_enabled() if gm and gm.has_method("is_photosensitive_mode_enabled") else false
	var txt = "ESTADO: [ ON ]" if is_on else "ESTADO: [ OFF ]"
	if has_node("/root/LocalizationManager"):
		txt = get_node("/root/LocalizationManager").translate_text(txt)
	btn_fotosensible.text = txt
	if btn_fotosensible.has_method("queue_redraw"):
		btn_fotosensible.queue_redraw()

func _refresh_holo_button() -> void:
	if not btn_holo: return
	var gm = _get_game_manager()
	var perf = gm.performance_mode if gm and "performance_mode" in gm else false
	var txt = "ESTADO: [ SUAVE / RENDIMIENTO ]" if perf else "ESTADO: [ ALTA DEFINICIÓN ]"
	if has_node("/root/LocalizationManager"):
		txt = get_node("/root/LocalizationManager").translate_text(txt)
	btn_holo.text = txt
	if btn_holo.has_method("queue_redraw"):
		btn_holo.queue_redraw()

func _refresh_consumo_button() -> void:
	if not btn_consumo: return
	var gm = _get_game_manager()
	var is_on = gm.is_hardware_monitor_enabled() if gm and gm.has_method("is_hardware_monitor_enabled") else false
	var txt = "ESTADO: [ ON ]" if is_on else "ESTADO: [ OFF ]"
	if has_node("/root/LocalizationManager"):
		txt = get_node("/root/LocalizationManager").translate_text(txt)
	btn_consumo.text = txt
	if btn_consumo.has_method("queue_redraw"):
		btn_consumo.queue_redraw()

func _refresh_fullscreen_button() -> void:
	if not btn_fullscreen: return
	var mode = DisplayServer.window_get_mode()
	var is_fs = (mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	var txt = "PANTALLA: [ COMPLETA ]" if is_fs else "PANTALLA: [ MODO VENTANA ]"
	if has_node("/root/LocalizationManager"):
		txt = get_node("/root/LocalizationManager").translate_text(txt)
	btn_fullscreen.text = txt
	if btn_fullscreen.has_method("queue_redraw"):
		btn_fullscreen.queue_redraw()
