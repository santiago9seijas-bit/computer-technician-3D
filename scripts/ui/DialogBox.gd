extends Control

signal dialog_closed

@onready var panel: PanelContainer = $BoxMargin/Panel
@onready var speaker_label: Label = $BoxMargin/Panel/Margin/VBox/SpeakerLabel
@onready var message_label: Label = $BoxMargin/Panel/Margin/VBox/MessageLabel
@onready var prompt_label: Label = $BoxMargin/Panel/Margin/VBox/PromptHBox/PromptLabel

var is_active: bool = false
var on_finish_callback: Callable = Callable()
var tween_prompt: Tween
var tween_open: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_start_prompt_blink()

func _start_prompt_blink() -> void:
	if tween_prompt:
		tween_prompt.kill()
	if not prompt_label:
		return
	tween_prompt = create_tween().set_loops()
	tween_prompt.tween_property(prompt_label, "modulate:a", 0.25, 0.5).set_trans(Tween.TRANS_SINE)
	tween_prompt.tween_property(prompt_label, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)

func show_message(speaker: String, text: String, callback: Callable = Callable()) -> void:
	on_finish_callback = callback
	is_active = true
	visible = true
	
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

func _unhandled_input(event: InputEvent) -> void:
	if not is_active or not visible:
		return
		
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_E or event.physical_keycode == KEY_E)):
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
