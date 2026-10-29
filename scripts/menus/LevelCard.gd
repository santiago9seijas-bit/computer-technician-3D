extends PanelContainer

signal closed()

@onready var btn_close: Button = get_node_or_null("VBox/HeaderHBox/BtnClose")

var current_level_data: Dictionary = {}
var is_closing: bool = false

func _ready() -> void:
	visible = false
	if btn_close:
		btn_close.pressed.connect(close_card)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close_card()
		get_viewport().set_input_as_handled()

func setup_level(data: Dictionary) -> void:
	current_level_data = data
	visible = false

func open_card(data: Dictionary) -> void:
	visible = false

func close_card() -> void:
	visible = false
	closed.emit()
