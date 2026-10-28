extends Control

signal minigame_finished(success: bool)

enum State {
	UNSEAT_RAM,
	INSERT_NEW_RAM,
	COMPLETED
}

var current_state: State = State.UNSEAT_RAM

# Estados de descalce
var left_unseated: bool = false
var right_unseated: bool = false
var broken_ram_removed: bool = false

# Arrastre interactivo
var dragging_part: String = "" # "left", "right", "center"
var drag_start_pos: Vector2 = Vector2.ZERO

@onready var status_label: Label = $Panel/StatusLabel
@onready var ram_stick: Panel = $Panel/SocketArea/RAMStick
@onready var zone_left: Control = $Panel/SocketArea/RAMStick/ZoneLeft
@onready var zone_right: Control = $Panel/SocketArea/RAMStick/ZoneRight
@onready var zone_center: Control = $Panel/SocketArea/RAMStick/ZoneCenter

@onready var lbl_left: Label = $Panel/SocketArea/RAMStick/ZoneLeft/LblLeft
@onready var lbl_right: Label = $Panel/SocketArea/RAMStick/ZoneRight/LblRight
@onready var lbl_center: Label = $Panel/SocketArea/RAMStick/ZoneCenter/LblCenter

@onready var btn_cancel: Button = $Panel/BtnCancel
@onready var btn_use_spare: Button = $Panel/BtnUseSpare

func _ready() -> void:
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	btn_use_spare.pressed.connect(_on_use_spare_pressed)
	btn_use_spare.visible = false
	
	zone_left.gui_input.connect(func(event): _handle_zone_input("left", event))
	zone_right.gui_input.connect(func(event): _handle_zone_input("right", event))
	zone_center.gui_input.connect(func(event): _handle_zone_input("center", event))
	
	_update_ui_state()

func _update_ui_state() -> void:
	match current_state:
		State.UNSEAT_RAM:
			if not left_unseated and not right_unseated:
				status_label.text = "Paso 1: Haz clic y arrastra hacia arriba el lado IZQUIERDO y DERECHO de la RAM."
				status_label.modulate = Color(1.0, 0.85, 0.2, 1)
			elif left_unseated and not right_unseated:
				status_label.text = "¡Lado izquierdo liberado! Ahora arrastra el lado DERECHO hacia arriba."
				status_label.modulate = Color(0.0, 0.9, 1.0, 1)
			elif right_unseated and not left_unseated:
				status_label.text = "¡Lado derecho liberado! Ahora arrastra el lado IZQUIERDO hacia arriba."
				status_label.modulate = Color(0.0, 0.9, 1.0, 1)
			else:
				status_label.text = "¡Ambos lados liberados! Ahora arrastra el CENTRO hacia arriba para sacarla."
				status_label.modulate = Color(0.0, 1.0, 0.5, 1)
				lbl_center.text = "▲ ARRASTRA EL CENTRO PARA EXTRAER ▲"
				lbl_center.modulate = Color(0.0, 1.0, 0.6, 1)
		State.INSERT_NEW_RAM:
			status_label.text = "Paso 2: Inserta la RAM nueva desde tu mochila."
			status_label.modulate = Color(1.0, 0.85, 0.2, 1)
			_check_spare_in_backpack()
		State.COMPLETED:
			status_label.text = "¡RAM asegurada y bloqueada en el zócalo!"
			status_label.modulate = Color(0.0, 1.0, 0.4, 1)

func _check_spare_in_backpack() -> void:
	var has_new_ram = false
	for item in GameManager.backpack:
		if item.get("name") == "RAM" and not item.get("broken", true):
			has_new_ram = true
			break
	
	btn_use_spare.visible = true
	if has_new_ram:
		btn_use_spare.text = "Insertar RAM nueva desde Mochila"
		btn_use_spare.modulate = Color(0, 1, 0.5, 1)
	else:
		btn_use_spare.text = "¡Sin RAM nueva en mochila! (Busca en Repuestos)"
		btn_use_spare.modulate = Color(1, 0.4, 0.4, 1)

func _handle_zone_input(part: String, event: InputEvent) -> void:
	if current_state != State.UNSEAT_RAM:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging_part = part
			drag_start_pos = event.global_position
		else:
			if dragging_part == part:
				var diff_y = drag_start_pos.y - event.global_position.y
				_process_drag_release(part, diff_y)
				dragging_part = ""

func _process_drag_release(part: String, diff_y: float) -> void:
	var threshold = 35.0
	
	if part == "left":
		if diff_y >= threshold:
			left_unseated = true
			lbl_left.text = "LIBERADO ✓"
			lbl_left.modulate = Color(0, 1, 0.5, 1)
			_animate_stick_tilt()
			_update_ui_state()
		else:
			# Arrastre insuficiente
			pass
	elif part == "right":
		if diff_y >= threshold:
			right_unseated = true
			lbl_right.text = "LIBERADO ✓"
			lbl_right.modulate = Color(0, 1, 0.5, 1)
			_animate_stick_tilt()
			_update_ui_state()
	elif part == "center":
		if not (left_unseated and right_unseated):
			GameManager.register_error(2.0)
			status_label.text = "¡Atascado! Debes descalzar primero el lado izquierdo y el derecho."
			status_label.modulate = Color(1, 0.2, 0.3, 1)
		else:
			if diff_y >= threshold:
				_complete_ram_removal()

func _animate_stick_tilt() -> void:
	var tween = create_tween()
	if left_unseated and not right_unseated:
		tween.tween_property(ram_stick, "rotation_degrees", -3.5, 0.2)
		tween.parallel().tween_property(ram_stick, "position:y", ram_stick.position.y - 10.0, 0.2)
	elif right_unseated and not left_unseated:
		tween.tween_property(ram_stick, "rotation_degrees", 3.5, 0.2)
		tween.parallel().tween_property(ram_stick, "position:y", ram_stick.position.y - 10.0, 0.2)
	elif left_unseated and right_unseated:
		tween.tween_property(ram_stick, "rotation_degrees", 0.0, 0.2)
		tween.parallel().tween_property(ram_stick, "position:y", ram_stick.position.y - 15.0, 0.2)

func _complete_ram_removal() -> void:
	broken_ram_removed = true
	var tween = create_tween()
	tween.tween_property(ram_stick, "position:y", -140.0, 0.35)
	tween.parallel().tween_property(ram_stick, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func():
		ram_stick.visible = false
		GameManager.add_item_to_backpack({"name": "RAM", "broken": true})
		current_state = State.INSERT_NEW_RAM
		_update_ui_state()
	)

func _on_use_spare_pressed() -> void:
	if current_state != State.INSERT_NEW_RAM:
		return
		
	var spare_idx = -1
	for i in range(GameManager.backpack.size()):
		var item = GameManager.backpack[i]
		if item.get("name") == "RAM" and not item.get("broken", true):
			spare_idx = i
			break
			
	if spare_idx == -1:
		GameManager.register_error(3.0)
		status_label.text = "¡Error! No tienes un repuesto de RAM nueva. Sal y búscala en repuestos."
		return
		
	GameManager.remove_item_from_backpack(spare_idx)
	
	btn_use_spare.visible = false
	ram_stick.visible = true
	ram_stick.modulate = Color(0, 0.95, 1, 1)
	ram_stick.position.y = -90.0
	ram_stick.rotation_degrees = 0.0
	
	var tween = create_tween()
	tween.tween_property(ram_stick, "position:y", 75.0, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		lbl_left.text = "BLOQUEADO ✓"
		lbl_right.text = "BLOQUEADO ✓"
		lbl_center.text = "DDR5 - 16GB [NUEVA]"
		current_state = State.COMPLETED
		_update_ui_state()
		
		await get_tree().create_timer(0.9).timeout
		minigame_finished.emit(true)
	)
