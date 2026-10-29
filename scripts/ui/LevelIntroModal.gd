extends Control

signal started()

@onready var btn_close: Button = $CardModal/Margin/VBox/Header/BtnClose
@onready var btn_iniciar: Button = $CardModal/Margin/VBox/BottomHBox/BtnIniciar
@onready var card_modal: PanelContainer = $CardModal

var is_dismissed: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true
	is_dismissed = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if btn_close:
		btn_close.pressed.connect(_on_close_pressed)
	if btn_iniciar:
		btn_iniciar.pressed.connect(_on_close_pressed)
		
	# Animación suave de apertura en el centro
	modulate.a = 0.0
	card_modal.scale = Vector2(0.88, 0.88)
	card_modal.pivot_offset = Vector2(310, 195)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.22)
	tw.tween_property(card_modal, "scale", Vector2.ONE, 0.22)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _unhandled_input(event: InputEvent) -> void:
	if visible and not is_dismissed:
		if event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
			_on_close_pressed()
			get_viewport().set_input_as_handled()

func _on_close_pressed() -> void:
	if is_dismissed:
		return
	is_dismissed = true
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	tw.tween_property(card_modal, "scale", Vector2(0.88, 0.88), 0.18)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func():
		visible = false
		started.emit()
		queue_free()
	)
