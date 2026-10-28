extends Control

signal minigame_finished(success: bool)

enum State {
	UNLOCK_LATCHES,
	REMOVE_BROKEN_RAM,
	INSERT_NEW_RAM,
	COMPLETED
}

var current_state: State = State.UNLOCK_LATCHES
var left_latch_open: bool = false
var right_latch_open: bool = false
var broken_ram_removed: bool = false
var new_ram_inserted: bool = false

# Arrastre de RAM (Swipe)
var is_dragging: bool = false
var drag_start_y: float = 0.0

@onready var btn_left_latch: Button = $Panel/SocketArea/BtnLeftLatch
@onready var btn_right_latch: Button = $Panel/SocketArea/BtnRightLatch
@onready var ram_stick: Panel = $Panel/SocketArea/RAMStick
@onready var status_label: Label = $Panel/StatusLabel
@onready var btn_cancel: Button = $Panel/BtnCancel
@onready var btn_use_spare: Button = $Panel/BtnUseSpare

func _ready() -> void:
	btn_left_latch.pressed.connect(_on_left_latch_pressed)
	btn_right_latch.pressed.connect(_on_right_latch_pressed)
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	btn_use_spare.pressed.connect(_on_use_spare_pressed)
	btn_use_spare.visible = false
	
	_update_ui_state()

func _update_ui_state() -> void:
	match current_state:
		State.UNLOCK_LATCHES:
			status_label.text = "Paso 1: Abre los dos seguros laterales del zócalo."
		State.REMOVE_BROKEN_RAM:
			status_label.text = "Paso 2: Haz clic y arrastra (swipe) hacia arriba para extraer la RAM quemada."
		State.INSERT_NEW_RAM:
			status_label.text = "Paso 3: Selecciona una RAM nueva de tu mochila para insertarla."
			_check_spare_in_backpack()
		State.COMPLETED:
			status_label.text = "¡RAM instalada y bloqueada correctamente!"
			status_label.modulate = Color(0, 1, 0.4, 1)

func _check_spare_in_backpack() -> void:
	var has_new_ram = false
	for item in GameManager.backpack:
		if item.get("name") == "RAM" and not item.get("broken", true):
			has_new_ram = true
			break
	
	if has_new_ram:
		btn_use_spare.visible = true
		btn_use_spare.text = "Insertar RAM nueva desde Mochila"
		btn_use_spare.modulate = Color(0, 1, 0.5, 1)
	else:
		btn_use_spare.visible = true
		btn_use_spare.text = "¡Sin RAM nueva en mochila! (Busca en Repuestos)"
		btn_use_spare.modulate = Color(1, 0.4, 0.4, 1)

func _on_left_latch_pressed() -> void:
	left_latch_open = !left_latch_open
	btn_left_latch.text = "ABIERTO" if left_latch_open else "CERRADO"
	btn_left_latch.modulate = Color(0, 1, 0.5, 1) if left_latch_open else Color(1, 0.2, 0.4, 1)
	_check_latches()

func _on_right_latch_pressed() -> void:
	right_latch_open = !right_latch_open
	btn_right_latch.text = "ABIERTO" if right_latch_open else "CERRADO"
	btn_right_latch.modulate = Color(0, 1, 0.5, 1) if right_latch_open else Color(1, 0.2, 0.4, 1)
	_check_latches()

func _check_latches() -> void:
	if left_latch_open and right_latch_open and current_state == State.UNLOCK_LATCHES:
		current_state = State.REMOVE_BROKEN_RAM
		_update_ui_state()

func _gui_input(event: InputEvent) -> void:
	if current_state == State.REMOVE_BROKEN_RAM:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var local_pos = ram_stick.get_local_mouse_position()
				if ram_stick.get_rect().has_point(ram_stick.position + local_pos):
					is_dragging = true
					drag_start_y = event.position.y
			else:
				if is_dragging:
					is_dragging = false
					var diff = drag_start_y - event.position.y
					if diff > 50: # Gesto de swipe hacia arriba completado
						_complete_ram_removal()
					else:
						# No tiró lo suficiente
						ram_stick.position.y = 80

func _complete_ram_removal() -> void:
	broken_ram_removed = true
	var tween = create_tween()
	tween.tween_property(ram_stick, "position:y", -120.0, 0.3)
	tween.tween_callback(func():
		ram_stick.visible = false
		# Guardar RAM dañada en mochila
		GameManager.add_item_to_backpack({"name": "RAM", "broken": true})
		current_state = State.INSERT_NEW_RAM
		_update_ui_state()
	)

func _on_use_spare_pressed() -> void:
	if current_state != State.INSERT_NEW_RAM:
		return
		
	# Buscar índice de RAM nueva
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
		
	# Remover repuesto de la mochila
	GameManager.remove_item_from_backpack(spare_idx)
	
	# Insertar y cerrar seguros
	btn_use_spare.visible = false
	ram_stick.visible = true
	ram_stick.modulate = Color(0, 0.9, 1, 1) # RAM nueva color cian
	ram_stick.position.y = -80.0
	
	var tween = create_tween()
	tween.tween_property(ram_stick, "position:y", 80.0, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		# Cerrar seguros
		left_latch_open = false
		right_latch_open = false
		btn_left_latch.text = "CERRADO"
		btn_right_latch.text = "CERRADO"
		btn_left_latch.modulate = Color(0, 1, 0.5, 1)
		btn_right_latch.modulate = Color(0, 1, 0.5, 1)
		
		current_state = State.COMPLETED
		_update_ui_state()
		
		# Esperar medio segundo y cerrar exitosamente
		await get_tree().create_timer(0.8).timeout
		minigame_finished.emit(true)
	)
