extends Control

signal dialog_closed

@onready var panel: PanelContainer = $BoxMargin/Panel
@onready var speaker_label: Label = $BoxMargin/Panel/Margin/VBox/SpeakerLabel
@onready var message_label: Label = $BoxMargin/Panel/Margin/VBox/MessageLabel
@onready var btn_continue: Button = $BoxMargin/Panel/Margin/VBox/PromptHBox/BtnContinue

var is_active: bool = false
var on_finish_callback: Callable = Callable()
var tween_prompt: Tween
var tween_open: Tween

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

func show_message(speaker: String, text: String, callback: Callable = Callable()) -> void:
	on_finish_callback = callback
	is_active = true
	visible = true
	
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if speaker_label:
		speaker_label.text = speaker
	if message_label:
		message_label.text = text
		
	# Animación de apertura suave
	if panel:
		panel.scale = Vector2(0.92, 0.92)
		panel.modulate.a = 0.0
		if tween_open:
			tween_open.kill()
		tween_open = create_tween()
		tween_open.parallel().tween_property(panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_open.parallel().tween_property(panel, "modulate:a", 1.0, 0.2)

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
	# Consumir clics sobre la caja para que no traspasen al mundo 3D,
	# pero NO avanzar el diálogo: solo se avanza con la tecla [E].
	if event is InputEventMouseButton:
		accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active or not visible:
		return
		
	# Solo y únicamente avanzar con la tecla [E]
	var is_e_key: bool = (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_E or event.physical_keycode == KEY_E))
	var is_e_action: bool = event.is_action_pressed("interact") and not (event is InputEventMouseButton)
	if is_e_key or is_e_action:
		get_viewport().set_input_as_handled()
		close_dialog()

func close_dialog() -> void:
	if not is_active:
		return
	is_active = false
	
	var tw = create_tween()
	tw.parallel().tween_property(panel, "scale", Vector2(0.94, 0.94), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(panel, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func():
		visible = false
		dialog_closed.emit()
		if on_finish_callback.is_valid():
			var cb = on_finish_callback
			on_finish_callback = Callable()
			cb.call()
	)
