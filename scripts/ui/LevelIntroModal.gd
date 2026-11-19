extends Control

signal started()

@onready var card_modal: PanelContainer = find_child("CardModal", true, false) as PanelContainer
@onready var btn_close: Button = find_child("BtnClose", true, false) as Button
@onready var btn_iniciar: Button = find_child("BtnIniciar", true, false) as Button

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
		
	# Centrado dinámico del pivote para animación suave
	modulate.a = 0.0
	if card_modal:
		card_modal.scale = Vector2(0.88, 0.88)
		call_deferred("_setup_pivot")
		
		var tw = create_tween().set_parallel(true)
		tw.tween_property(self, "modulate:a", 1.0, 0.22)
		tw.tween_property(card_modal, "scale", Vector2.ONE, 0.22)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		var tw = create_tween()
		tw.tween_property(self, "modulate:a", 1.0, 0.22)

func _setup_pivot() -> void:
	if card_modal and is_instance_valid(card_modal):
		card_modal.pivot_offset = card_modal.size * 0.5

func set_mission_data(title: String, badge: String, objective: String, diagnostic: String = "", tools: String = "") -> void:
	var lbl_title = find_child("Title", true, false) as Label
	if lbl_title and title != "":
		lbl_title.text = title
	var lbl_badge = find_child("Badge", true, false) as Label
	if lbl_badge and badge != "":
		lbl_badge.text = badge
	var obj_box = find_child("ObjBox", true, false)
	if obj_box and objective != "":
		var obj_lbl = obj_box.get_node_or_null("Text") as Label
		if obj_lbl:
			obj_lbl.text = objective
	var diag_box = find_child("DiagBox", true, false)
	if diag_box and diagnostic != "":
		var diag_lbl = diag_box.get_node_or_null("Text") as Label
		if diag_lbl:
			diag_lbl.text = diagnostic
	var tools_box = find_child("ToolsBox", true, false)
	if tools_box and tools != "":
		var tools_lbl = tools_box.get_node_or_null("Text") as Label
		if tools_lbl:
			tools_lbl.text = tools

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
	if card_modal:
		tw.tween_property(card_modal, "scale", Vector2(0.88, 0.88), 0.18)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func():
		visible = false
		started.emit()
		queue_free()
	)
