extends Control

signal minigame_finished(success: bool)
signal old_part_extracted()

enum State {
	EXTRACT_SIDES,
	EXTRACT_CENTER,
	EMPTY_SLOT,
	INSERT_CENTER,
	LOCK_SIDES,
	COMPLETED
}

var current_state: State = State.EXTRACT_SIDES
var start_as_empty_slot: bool = false

# Estados de extracción de la RAM vieja
var left_unseated: bool = false
var right_unseated: bool = false

# Estados de inserción de la RAM nueva
var center_inserted: bool = false
var new_left_locked: bool = false
var new_right_locked: bool = false

# Arrastre interactivo en el módulo
var dragging_part: String = "" # "left", "right", "center"
var drag_start_pos: Vector2 = Vector2.ZERO

# Arrastre desde la mochila
var dragging_backpack_item: bool = false
var backpack_drag_start_pos: Vector2 = Vector2.ZERO

@onready var status_label: Label = $Panel/VBox/Header/StatusLabel
@onready var socket_area: Control = $Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea
@onready var socket_base: Panel = $Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/SocketBase
@onready var empty_slot_label: Label = $Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/SocketBase/EmptySlotLabel
@onready var ram_stick: Panel = $Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/RAMStick

@onready var zone_left: Control = $Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/RAMStick/ZoneLeft
@onready var zone_right: Control = $Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/RAMStick/ZoneRight
@onready var zone_center: Control = $Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/RAMStick/ZoneCenter

@onready var lbl_left: Label = $Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/RAMStick/ZoneLeft/LblLeft
@onready var lbl_right: Label = $Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/RAMStick/ZoneRight/LblRight
@onready var lbl_center: Label = $Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/RAMStick/ZoneCenter/LblCenter

@onready var backpack_items_box: VBoxContainer = $Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/ItemsContainer
@onready var backpack_hint: Label = $Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/BackpackHint
@onready var btn_cancel: Button = $Panel/VBox/Footer/BtnCancel

func _ready() -> void:
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	empty_slot_label.visible = false
	
	zone_left.gui_input.connect(func(event): _handle_zone_input("left", event))
	zone_right.gui_input.connect(func(event): _handle_zone_input("right", event))
	zone_center.gui_input.connect(func(event): _handle_zone_input("center", event))
	
	GameManager.backpack_updated.connect(_on_backpack_changed)
	
	# Si el slot ya estaba vacío al interactuar
	if start_as_empty_slot:
		ram_stick.visible = false
		empty_slot_label.visible = true
		current_state = State.EMPTY_SLOT
		
	_update_ui_state()
	_refresh_backpack_ui()

func _on_backpack_changed(_items: Array) -> void:
	_refresh_backpack_ui()

func _refresh_backpack_ui() -> void:
	for child in backpack_items_box.get_children():
		child.queue_free()
		
	if GameManager.backpack.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "[ Mochila Vacía ]\nBusca repuestos en el taller"
		empty_lbl.modulate = Color(0.6, 0.6, 0.7, 0.8)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		backpack_items_box.add_child(empty_lbl)
		backpack_hint.text = "Sin piezas disponibles"
		return
		
	var found_ram = false
	for i in range(GameManager.backpack.size()):
		var item = GameManager.backpack[i]
		var item_btn = Button.new()
		
		if item.get("name") == "RAM":
			if item.get("broken", true):
				item_btn.text = "%d. RAM (Quemada/Rota)" % (i + 1)
				item_btn.modulate = Color(1, 0.3, 0.4, 0.85)
				item_btn.disabled = true
			else:
				found_ram = true
				item_btn.text = "⇪ RAM DDR5 (NUEVA)\n[Arrastra o Clic]"
				item_btn.modulate = Color(0.0, 1.0, 0.6, 1.0)
				
				# Permitir clic directo para colocar
				item_btn.pressed.connect(func(): _insert_ram_from_backpack(i))
				
				# Permitir arrastre desde el botón hacia el zócalo
				item_btn.gui_input.connect(func(event: InputEvent):
					if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
						if event.pressed:
							dragging_backpack_item = true
							backpack_drag_start_pos = event.global_position
						else:
							if dragging_backpack_item:
								dragging_backpack_item = false
								# Si arrastró hacia la izquierda (hacia el zócalo)
								var diff_x = backpack_drag_start_pos.x - event.global_position.x
								if diff_x > 40.0:
									_insert_ram_from_backpack(i)
				)
		else:
			item_btn.text = "%d. %s" % [i + 1, item.get("name", "Pieza")]
			item_btn.modulate = Color(0.6, 0.7, 0.8, 0.7)
			item_btn.disabled = true
			
		backpack_items_box.add_child(item_btn)
		
	if current_state == State.EMPTY_SLOT:
		if found_ram:
			backpack_hint.text = "¡Arrastra la RAM nueva hacia el zócalo o haz clic!"
			backpack_hint.modulate = Color(0.0, 1.0, 0.5, 1.0)
		else:
			backpack_hint.text = "No tienes RAM nueva en la mochila.\nSal de la PC y ve a la caja de repuestos."
			backpack_hint.modulate = Color(1.0, 0.4, 0.4, 1.0)

func _update_ui_state() -> void:
	match current_state:
		State.EXTRACT_SIDES:
			if not left_unseated and not right_unseated:
				status_label.text = "Paso 1: Arrastra hacia ARRIBA el lado IZQUIERDO y DERECHO de la RAM."
				status_label.modulate = Color(1.0, 0.85, 0.2, 1)
			elif left_unseated and not right_unseated:
				status_label.text = "¡Lado izquierdo liberado! Ahora arrastra el lado DERECHO hacia ARRIBA."
				status_label.modulate = Color(0.0, 0.9, 1.0, 1)
			elif right_unseated and not left_unseated:
				status_label.text = "¡Lado derecho liberado! Ahora arrastra el lado IZQUIERDO hacia ARRIBA."
				status_label.modulate = Color(0.0, 0.9, 1.0, 1)
			else:
				current_state = State.EXTRACT_CENTER
				_update_ui_state()
		State.EXTRACT_CENTER:
			status_label.text = "¡Ambos lados liberados! Arrastra el CENTRO hacia ARRIBA para sacarla."
			status_label.modulate = Color(0.0, 1.0, 0.5, 1)
			lbl_center.text = "▲ ARRASTRA EL CENTRO\nHACIA ARRIBA ▲"
			lbl_center.modulate = Color(0.0, 1.0, 0.6, 1)
		State.EMPTY_SLOT:
			status_label.text = "Zócalo vacío. Arrastra la RAM nueva desde tu mochila hacia el zócalo."
			status_label.modulate = Color(1.0, 0.85, 0.2, 1)
			_refresh_backpack_ui()
		State.INSERT_CENTER:
			status_label.text = "Paso 2 (A la inversa): Arrastra el CENTRO hacia ABAJO para encajarla."
			status_label.modulate = Color(0.0, 0.9, 1.0, 1)
			lbl_center.text = "▼ ARRASTRA EL CENTRO\nHACIA ABAJO ▼"
			lbl_center.modulate = Color(0.0, 0.95, 1.0, 1)
			lbl_left.text = "PENDIENTE"
			lbl_right.text = "PENDIENTE"
			lbl_left.modulate = Color(0.7, 0.7, 0.7, 1)
			lbl_right.modulate = Color(0.7, 0.7, 0.7, 1)
		State.LOCK_SIDES:
			if not new_left_locked and not new_right_locked:
				status_label.text = "Paso 3: Arrastra hacia ABAJO el lado izquierdo y derecho (cualquier orden)."
				status_label.modulate = Color(1.0, 0.85, 0.2, 1)
			elif new_left_locked and not new_right_locked:
				status_label.text = "¡Izquierda trabada! Ahora arrastra hacia ABAJO el lado DERECHO."
				status_label.modulate = Color(0.0, 0.9, 1.0, 1)
			elif new_right_locked and not new_left_locked:
				status_label.text = "¡Derecha trabada! Ahora arrastra hacia ABAJO el lado IZQUIERDO."
				status_label.modulate = Color(0.0, 0.9, 1.0, 1)
			else:
				current_state = State.COMPLETED
				_update_ui_state()
		State.COMPLETED:
			status_label.text = "¡RAM completamente asegurada y trabada en el zócalo!"
			status_label.modulate = Color(0.0, 1.0, 0.4, 1)

func _handle_zone_input(part: String, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging_part = part
			drag_start_pos = event.global_position
		else:
			if dragging_part == part:
				var delta_y = event.global_position.y - drag_start_pos.y
				_process_drag_release(part, delta_y)
				dragging_part = ""

func _process_drag_release(part: String, delta_y: float) -> void:
	var threshold = 30.0
	
	# FASE 1: EXTRACCIÓN (Hacia ARRIBA -> delta_y negativo)
	if current_state == State.EXTRACT_SIDES or current_state == State.EXTRACT_CENTER:
		var pulled_up = -delta_y >= threshold
		
		if part == "left":
			if pulled_up:
				left_unseated = true
				lbl_left.text = "LIBERADO ✓"
				lbl_left.modulate = Color(0, 1, 0.5, 1)
				_animate_stick_tilt_up()
				_update_ui_state()
		elif part == "right":
			if pulled_up:
				right_unseated = true
				lbl_right.text = "LIBERADO ✓"
				lbl_right.modulate = Color(0, 1, 0.5, 1)
				_animate_stick_tilt_up()
				_update_ui_state()
		elif part == "center":
			if current_state == State.EXTRACT_CENTER:
				if pulled_up:
					_complete_ram_removal()
			else:
				GameManager.register_error(2.0)
				status_label.text = "¡Atascado! Primero descalza el lado izquierdo y el derecho hacia arriba."
				status_label.modulate = Color(1, 0.2, 0.3, 1)
				
	# FASE 2: INSERCIÓN A LA INVERSA (Hacia ABAJO -> delta_y positivo)
	elif current_state == State.INSERT_CENTER:
		var pushed_down = delta_y >= threshold
		if part == "center":
			if pushed_down:
				center_inserted = true
				var tween = create_tween()
				tween.tween_property(ram_stick, "position:y", 0.0, 0.25).set_trans(Tween.TRANS_QUAD)
				tween.tween_callback(func():
					current_state = State.LOCK_SIDES
					lbl_center.text = "DDR5 - 16GB [ENCAJADA]"
					lbl_left.text = "▼ TRABAR IZQ ▼"
					lbl_right.text = "▼ TRABAR DER ▼"
					lbl_left.modulate = Color(1.0, 0.85, 0.2, 1)
					lbl_right.modulate = Color(1.0, 0.85, 0.2, 1)
					_update_ui_state()
				)
		else:
			status_label.text = "¡Primero arrastra el CENTRO hacia abajo para encajar la memoria!"
			status_label.modulate = Color(1, 0.2, 0.3, 1)
			
	elif current_state == State.LOCK_SIDES:
		var pushed_down = delta_y >= threshold or abs(delta_y) < 15.0
		
		if part == "left":
			if pushed_down and not new_left_locked:
				new_left_locked = true
				lbl_left.text = "TRABADO ✓"
				lbl_left.modulate = Color(0, 1, 0.5, 1)
				_animate_stick_tilt_down()
				_check_both_locked()
		elif part == "right":
			if pushed_down and not new_right_locked:
				new_right_locked = true
				lbl_right.text = "TRABADO ✓"
				lbl_right.modulate = Color(0, 1, 0.5, 1)
				_animate_stick_tilt_down()
				_check_both_locked()

func _animate_stick_tilt_up() -> void:
	var tween = create_tween()
	if left_unseated and not right_unseated:
		tween.tween_property(ram_stick, "rotation_degrees", -3.5, 0.2)
		tween.parallel().tween_property(ram_stick, "position:y", -10.0, 0.2)
	elif right_unseated and not left_unseated:
		tween.tween_property(ram_stick, "rotation_degrees", 3.5, 0.2)
		tween.parallel().tween_property(ram_stick, "position:y", -10.0, 0.2)
	elif left_unseated and right_unseated:
		tween.tween_property(ram_stick, "rotation_degrees", 0.0, 0.2)
		tween.parallel().tween_property(ram_stick, "position:y", -20.0, 0.2)

func _animate_stick_tilt_down() -> void:
	var tween = create_tween()
	if new_left_locked and not new_right_locked:
		tween.tween_property(ram_stick, "rotation_degrees", -2.5, 0.15)
		tween.parallel().tween_property(ram_stick, "position:y", 10.0, 0.15)
	elif new_right_locked and not new_left_locked:
		tween.tween_property(ram_stick, "rotation_degrees", 2.5, 0.15)
		tween.parallel().tween_property(ram_stick, "position:y", 10.0, 0.15)
	elif new_left_locked and new_right_locked:
		tween.tween_property(ram_stick, "rotation_degrees", 0.0, 0.15)
		tween.parallel().tween_property(ram_stick, "position:y", 20.0, 0.15)

func _check_both_locked() -> void:
	_update_ui_state()
	if new_left_locked and new_right_locked:
		var tween = create_tween()
		tween.tween_property(ram_stick, "position:y", 25.0, 0.12)
		tween.tween_callback(func():
			lbl_center.text = "DDR5 - 16GB [ASEGURADA]"
			lbl_center.modulate = Color(0, 1, 0.5, 1)
			await get_tree().create_timer(0.9).timeout
			minigame_finished.emit(true)
		)

func _complete_ram_removal() -> void:
	var tween = create_tween()
	tween.tween_property(ram_stick, "position:y", -160.0, 0.35)
	tween.parallel().tween_property(ram_stick, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func():
		ram_stick.visible = false
		empty_slot_label.visible = true
		GameManager.add_item_to_backpack({"name": "RAM", "broken": true})
		current_state = State.EMPTY_SLOT
		old_part_extracted.emit()
		_update_ui_state()
		_refresh_backpack_ui()
	)

func _insert_ram_from_backpack(index: int) -> void:
	if current_state != State.EMPTY_SLOT:
		return
		
	if index < 0 or index >= GameManager.backpack.size():
		return
		
	var item = GameManager.backpack[index]
	if item.get("name") != "RAM" or item.get("broken", true):
		return
		
	GameManager.remove_item_from_backpack(index)
	empty_slot_label.visible = false
	
	# Colocar la RAM suspendida sobre el zócalo
	ram_stick.visible = true
	ram_stick.modulate = Color(0, 0.95, 1, 1)
	ram_stick.position.y = -65.0
	ram_stick.rotation_degrees = 0.0
	
	current_state = State.INSERT_CENTER
	_update_ui_state()
	_refresh_backpack_ui()
