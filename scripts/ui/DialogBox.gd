extends Control

signal dialog_closed

@onready var panel: PanelContainer = $BoxMargin/Panel
@onready var speaker_label: Label = $BoxMargin/Panel/Margin/VBox/SpeakerLabel
@onready var message_label: Label = $BoxMargin/Panel/Margin/VBox/MessageLabel
@onready var btn_continue: Button = $BoxMargin/Panel/Margin/VBox/PromptHBox/BtnContinue
@onready var prompt_hbox: HBoxContainer = $BoxMargin/Panel/Margin/VBox/PromptHBox
@onready var panel_margin: MarginContainer = $BoxMargin/Panel/Margin

@onready var portrait_root: Control = get_node_or_null("PortraitRoot")
@onready var portrait_texture: TextureRect = get_node_or_null("PortraitRoot/PortraitTexture")
@onready var typing_audio: AudioStreamPlayer = get_node_or_null("TypingAudio")

const TEX_JOA_NORMAL = preload("res://sprite de dialogos/joa normal.png")
const TEX_JOA_CRYING = preload("res://sprite de dialogos/joa llorando.png")

var is_active: bool = false
var on_finish_callback: Callable = Callable()
var tween_prompt: Tween
var tween_open: Tween

# Sistema de máquina de escribir (Typewriter)
var is_typing: bool = false
var typing_tween: Tween = null
const TYPING_SPEED: float = 0.022 # segundos por letra

# Sistema de opciones / elección interactiva (ej. interrupción de escape)
var is_choice_mode: bool = false
var on_choice_a_cb: Callable = Callable()
var on_choice_b_cb: Callable = Callable()
var btn_choice_a: Button = null
var btn_choice_b: Button = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if btn_continue:
		btn_continue.focus_mode = Control.FOCUS_NONE
		btn_continue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_start_prompt_pulse()

func _start_prompt_pulse() -> void:
	if tween_prompt:
		tween_prompt.kill()
	if not btn_continue:
		return
	tween_prompt = create_tween().set_loops()
	tween_prompt.tween_property(btn_continue, "scale", Vector2(1.03, 1.03), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_prompt.tween_property(btn_continue, "scale", Vector2(1.0, 1.0), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func set_speaker(speaker: String = "JOA") -> void:
	if speaker_label:
		if "JOA" in speaker.to_upper() or speaker == "" or "SISTEMA" in speaker.to_upper():
			speaker_label.text = "JOA"
		else:
			speaker_label.text = speaker

func show_message(speaker: String, text: String, callback: Callable = Callable()) -> void:
	on_finish_callback = callback
	is_active = true
	is_choice_mode = false
	visible = true
	
	if btn_choice_a: btn_choice_a.visible = false
	if btn_choice_b: btn_choice_b.visible = false
	if btn_continue: btn_continue.visible = true
	
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if speaker_label:
		if "JOA" in speaker.to_upper() or speaker == "" or "SISTEMA" in speaker.to_upper():
			speaker_label.text = "JOA"
		else:
			speaker_label.text = speaker
		
	_update_portrait(speaker, text, false)
	_start_typewriter(text)
		
	# Animación de apertura suave
	if panel:
		panel.scale = Vector2(0.92, 0.92)
		panel.modulate.a = 0.0
		if tween_open:
			tween_open.kill()
		tween_open = create_tween()
		tween_open.parallel().tween_property(panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_open.parallel().tween_property(panel, "modulate:a", 1.0, 0.2)

func show_choice(speaker: String, text: String, option_a_text: String, option_b_text: String, on_a: Callable, on_b: Callable) -> void:
	on_choice_a_cb = on_a
	on_choice_b_cb = on_b
	is_active = true
	is_choice_mode = true
	visible = true
	
	_ensure_choice_buttons()
	if btn_continue:
		btn_continue.visible = false
	if btn_choice_a:
		btn_choice_a.text = option_a_text
		btn_choice_a.visible = true
	if btn_choice_b:
		btn_choice_b.text = option_b_text
		btn_choice_b.visible = true
		
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	if speaker_label:
		if "JOA" in speaker.to_upper() or speaker == "" or "SISTEMA" in speaker.to_upper():
			speaker_label.text = "JOA"
		else:
			speaker_label.text = speaker
		
	# En elección de escape / salida, se muestra a Joa llorando
	_update_portrait(speaker, text, true)
	_start_typewriter(text)
		
	if panel:
		panel.scale = Vector2(0.92, 0.92)
		panel.modulate.a = 0.0
		if tween_open:
			tween_open.kill()
		tween_open = create_tween()
		tween_open.parallel().tween_property(panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_open.parallel().tween_property(panel, "modulate:a", 1.0, 0.2)

func _update_portrait(speaker: String, text: String, is_escape: bool = false) -> void:
	if not is_instance_valid(portrait_root) or not is_instance_valid(portrait_texture):
		return
		
	var sp_upper = speaker.to_upper()
	if "JOA" in sp_upper:
		portrait_root.visible = true
		if is_escape or is_choice_mode or "LLOR" in text.to_upper() or "TRISTE" in text.to_upper() or "SALIR" in sp_upper:
			portrait_texture.texture = TEX_JOA_CRYING
		else:
			portrait_texture.texture = TEX_JOA_NORMAL
			
		# Micro-animación de entrada del retrato (suave elevación)
		portrait_texture.position.y = 12.0
		var tw = create_tween()
		tw.tween_property(portrait_texture, "position:y", 0.0, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		if is_instance_valid(panel_margin):
			panel_margin.add_theme_constant_override("margin_left", 36)
			panel_margin.add_theme_constant_override("margin_right", 32)
	else:
		portrait_root.visible = false
		if is_instance_valid(panel_margin):
			panel_margin.add_theme_constant_override("margin_left", 36)
			panel_margin.add_theme_constant_override("margin_right", 32)

func _start_typewriter(text: String) -> void:
	if not is_instance_valid(message_label):
		return
		
	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()
		
	message_label.text = text
	message_label.visible_characters = 0
	is_typing = true
	
	if is_instance_valid(typing_audio):
		typing_audio.play()
		
	var total_chars = text.length()
	var duration = clamp(total_chars * TYPING_SPEED, 0.35, 3.2)
	
	typing_tween = create_tween()
	typing_tween.tween_method(func(val: int):
		if is_instance_valid(message_label):
			message_label.visible_characters = val
	, 0, total_chars, duration)
	
	typing_tween.finished.connect(func():
		_finish_typing()
	)

func _finish_typing() -> void:
	is_typing = false
	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()
	if is_instance_valid(message_label):
		message_label.visible_characters = -1
	if is_instance_valid(typing_audio) and typing_audio.playing:
		typing_audio.stop()

func _exit_tree() -> void:
	is_typing = false
	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()
	if is_instance_valid(typing_audio):
		if typing_audio.playing:
			typing_audio.stop()
		typing_audio.stream = null

func _ensure_choice_buttons() -> void:
	if btn_choice_a != null and btn_choice_b != null:
		return
		
	if not prompt_hbox:
		prompt_hbox = get_node_or_null("BoxMargin/Panel/Margin/VBox/PromptHBox") as HBoxContainer
	if not prompt_hbox:
		return
		
	var font_res = load("res://assets/fonts/Bungee-Regular.ttf")
	
	# Botón Opción A (Quedarse / Continuar) - Estilo Cyber Verde / Cyan
	btn_choice_a = Button.new()
	btn_choice_a.name = "BtnChoiceA"
	btn_choice_a.custom_minimum_size = Vector2(250, 42)
	btn_choice_a.focus_mode = Control.FOCUS_NONE
	btn_choice_a.mouse_filter = Control.MOUSE_FILTER_STOP
	btn_choice_a.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if font_res:
		btn_choice_a.add_theme_font_override("font", font_res)
	btn_choice_a.add_theme_font_size_override("font_size", 13)
	btn_choice_a.add_theme_color_override("font_color", Color(0.9, 1.0, 0.95))
	btn_choice_a.add_theme_color_override("font_hover_color", Color(0.2, 1.0, 0.6))
	
	var sb_a = StyleBoxFlat.new()
	sb_a.bg_color = Color(0.04, 0.16, 0.12, 0.95)
	sb_a.border_color = Color(0.2, 1.0, 0.55, 1.0)
	sb_a.border_width_left = 2
	sb_a.border_width_top = 2
	sb_a.border_width_right = 2
	sb_a.border_width_bottom = 2
	sb_a.corner_radius_top_left = 8
	sb_a.corner_radius_top_right = 8
	sb_a.corner_radius_bottom_right = 8
	sb_a.corner_radius_bottom_left = 8
	sb_a.content_margin_left = 18.0
	sb_a.content_margin_right = 18.0
	btn_choice_a.add_theme_stylebox_override("normal", sb_a)
	
	var sb_a_hover = sb_a.duplicate() as StyleBoxFlat
	sb_a_hover.bg_color = Color(0.08, 0.28, 0.18, 1.0)
	sb_a_hover.border_color = Color(0.4, 1.0, 0.8, 1.0)
	btn_choice_a.add_theme_stylebox_override("hover", sb_a_hover)
	btn_choice_a.pressed.connect(func(): _trigger_choice(true))
	prompt_hbox.add_child(btn_choice_a)
	
	# Botón Opción B (Salir) - Estilo Cyber Carmesí / Rojo
	btn_choice_b = Button.new()
	btn_choice_b.name = "BtnChoiceB"
	btn_choice_b.custom_minimum_size = Vector2(240, 42)
	btn_choice_b.focus_mode = Control.FOCUS_NONE
	btn_choice_b.mouse_filter = Control.MOUSE_FILTER_STOP
	btn_choice_b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if font_res:
		btn_choice_b.add_theme_font_override("font", font_res)
	btn_choice_b.add_theme_font_size_override("font_size", 13)
	btn_choice_b.add_theme_color_override("font_color", Color(1.0, 0.85, 0.85))
	btn_choice_b.add_theme_color_override("font_hover_color", Color(1.0, 0.3, 0.5))
	
	var sb_b = StyleBoxFlat.new()
	sb_b.bg_color = Color(0.2, 0.04, 0.08, 0.95)
	sb_b.border_color = Color(1.0, 0.25, 0.45, 1.0)
	sb_b.border_width_left = 2
	sb_b.border_width_top = 2
	sb_b.border_width_right = 2
	sb_b.border_width_bottom = 2
	sb_b.corner_radius_top_left = 8
	sb_b.corner_radius_top_right = 8
	sb_b.corner_radius_bottom_right = 8
	sb_b.corner_radius_bottom_left = 8
	sb_b.content_margin_left = 18.0
	sb_b.content_margin_right = 18.0
	btn_choice_b.add_theme_stylebox_override("normal", sb_b)
	
	var sb_b_hover = sb_b.duplicate() as StyleBoxFlat
	sb_b_hover.bg_color = Color(0.35, 0.08, 0.14, 1.0)
	sb_b_hover.border_color = Color(1.0, 0.45, 0.65, 1.0)
	btn_choice_b.add_theme_stylebox_override("hover", sb_b_hover)
	btn_choice_b.pressed.connect(func(): _trigger_choice(false))
	prompt_hbox.add_child(btn_choice_b)

func show_sequence(dialogs: Array, callback: Callable = Callable()) -> void:
	if dialogs.is_empty():
		if callback.is_valid():
			callback.call()
		return
	var current = dialogs[0]
	var remaining: Array = []
	for k in range(1, dialogs.size()):
		remaining.append(dialogs[k])
	show_message(current.get("speaker", ""), current.get("text", ""), func():
		show_sequence(remaining, callback)
	)

func _gui_input(event: InputEvent) -> void:
	if not is_active or not visible:
		return
	if event is InputEventMouseButton:
		accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active or not visible:
		return
		
	if is_choice_mode:
		var is_e_key: bool = (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_E or event.physical_keycode == KEY_E))
		var is_e_action: bool = event.is_action_pressed("interact") and not (event is InputEventMouseButton)
		if is_e_key or is_e_action:
			get_viewport().set_input_as_handled()
			if is_typing:
				_finish_typing()
				return
			_trigger_choice(true)
			return
			
		var is_esc_key: bool = (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE)
		var is_pause_action: bool = event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")
		if is_esc_key or is_pause_action:
			get_viewport().set_input_as_handled()
			if is_typing:
				_finish_typing()
				return
			_trigger_choice(false)
			return
		return
		
	# Solo y únicamente avanzar con la tecla [E]
	var is_e_key: bool = (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_E or event.physical_keycode == KEY_E))
	var is_e_action: bool = event.is_action_pressed("interact") and not (event is InputEventMouseButton)
	if is_e_key or is_e_action:
		get_viewport().set_input_as_handled()
		# Si las letras aún se están escribiendo, el primer [E] completa el texto de inmediato
		if is_typing:
			_finish_typing()
			return
		close_dialog()

func _trigger_choice(is_option_a: bool) -> void:
	if not is_active:
		return
	_finish_typing()
	is_active = false
	is_choice_mode = false
	
	var tw = create_tween()
	tw.parallel().tween_property(panel, "scale", Vector2(0.94, 0.94), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(panel, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func():
		visible = false
		if is_instance_valid(portrait_root):
			portrait_root.visible = false
		if btn_choice_a: btn_choice_a.visible = false
		if btn_choice_b: btn_choice_b.visible = false
		if btn_continue: btn_continue.visible = true
		dialog_closed.emit()
		if is_option_a and on_choice_a_cb.is_valid():
			var cb = on_choice_a_cb
			on_choice_a_cb = Callable()
			on_choice_b_cb = Callable()
			cb.call()
		elif not is_option_a and on_choice_b_cb.is_valid():
			var cb = on_choice_b_cb
			on_choice_a_cb = Callable()
			on_choice_b_cb = Callable()
			cb.call()
	)

func close_dialog() -> void:
	if not is_active:
		return
	_finish_typing()
	is_active = false
	
	var tw = create_tween()
	tw.parallel().tween_property(panel, "scale", Vector2(0.94, 0.94), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(panel, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func():
		visible = false
		if is_instance_valid(portrait_root):
			portrait_root.visible = false
		dialog_closed.emit()
		if on_finish_callback.is_valid():
			var cb = on_finish_callback
			on_finish_callback = Callable()
			cb.call()
	)
