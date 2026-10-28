extends Control

signal minigame_finished(success: bool)
signal old_part_extracted()

enum State {
	UNSCREW_4,
	DISCONNECT_SATA,
	EXTRACT_HDD,
	EMPTY_BAY,
	INSERT_HDD_DOWN,
	CONNECT_SATA_NEW,
	SCREW_4,
	COMPLETED
}

var current_state: State = State.UNSCREW_4
var start_as_empty_slot: bool = false

var screws_left: int = 4
var screws_tightened: int = 0
var sata_connected: bool = true

# Tipo de tornillos: "cruz" (Tecla 1) o "pala" (Tecla 2)
var screw_type: String = "cruz"
var required_tool_id: int = 1

# Arrastre del disco
var is_dragging_hdd: bool = false
var drag_start_y: float = 0.0
var base_disk_y: float = 0.0
var initialized_disk_y: bool = false

# Arrastre desde la mochila
var is_dragging_backpack_hdd: bool = false
var backpack_drag_start_x: float = 0.0

@onready var status_label: Label = $Panel/VBox/Header/StatusLabel
@onready var btn_sata: Button = $Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/BtnSATA
@onready var disk_panel: Panel = $Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/DiskPanel
@onready var disk_drag_label: Label = $Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/DiskPanel/DragHint
@onready var empty_bay_label: Label = $Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/BayBase/EmptyBayLabel

@onready var backpack_items_box: VBoxContainer = $Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/ItemsContainer
@onready var backpack_hint: Label = $Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/BackpackHint
@onready var btn_cancel: Button = $Panel/VBox/Footer/BtnCancel

@onready var screws: Array[Button] = [
	$Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/Screw1,
	$Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/Screw2,
	$Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/Screw3,
	$Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/Screw4
]

func _ready() -> void:
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	btn_sata.pressed.connect(_on_sata_pressed)
	empty_bay_label.visible = false
	
	disk_panel.gui_input.connect(_on_disk_gui_input)
	GameManager.backpack_updated.connect(_on_backpack_changed)
	
	if screw_type == "" or (not start_as_empty_slot and screw_type == "cruz"):
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		screw_type = "pala" if rng.randf() > 0.5 else "cruz"
		
	required_tool_id = 1 if screw_type == "cruz" else 2
	var icon = "✚" if screw_type == "cruz" else "▬"
	
	for s in screws:
		s.text = icon
		s.pressed.connect(func(): _on_screw_pressed(s))
		
	# Si la bahía ya estaba vacía (pieza retirada previamente)
	if start_as_empty_slot:
		screws_left = 0
		sata_connected = false
		disk_panel.visible = false
		empty_bay_label.visible = true
		for s in screws:
			s.visible = false
		btn_sata.text = "Cable SATA: [DESCONECTADO]"
		btn_sata.modulate = Color(1, 0.3, 0.3, 1)
		current_state = State.EMPTY_BAY
		
	_update_ui_state()
	_refresh_backpack_ui()

func _process(_delta: float) -> void:
	if not initialized_disk_y and disk_panel.position.y != 0:
		base_disk_y = disk_panel.position.y
		initialized_disk_y = true

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
		
	var found_hdd = false
	for i in range(GameManager.backpack.size()):
		var item = GameManager.backpack[i]
		var item_btn = Button.new()
		
		if item.get("name") == "Disco Duro":
			if item.get("broken", true):
				item_btn.text = "%d. HDD (Dañado)" % (i + 1)
				item_btn.modulate = Color(1, 0.3, 0.4, 0.85)
				item_btn.disabled = true
			else:
				found_hdd = true
				item_btn.text = "⇪ SATA SSD 1TB (NUEVO)\n[Arrastra o Clic]"
				item_btn.modulate = Color(0.0, 1.0, 0.6, 1.0)
				
				# Permitir clic directo o arrastre hacia la bahía
				item_btn.pressed.connect(func(): _insert_hdd_from_backpack(i))
				
				item_btn.gui_input.connect(func(event: InputEvent):
					if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
						if event.pressed:
							is_dragging_backpack_hdd = true
							backpack_drag_start_x = event.global_position.x
						else:
							if is_dragging_backpack_hdd:
								is_dragging_backpack_hdd = false
								var diff_x = backpack_drag_start_x - event.global_position.x
								if diff_x > 35.0:
									_insert_hdd_from_backpack(i)
				)
		else:
			item_btn.text = "%d. %s" % [i + 1, item.get("name", "Pieza")]
			item_btn.modulate = Color(0.6, 0.7, 0.8, 0.7)
			item_btn.disabled = true
			
		backpack_items_box.add_child(item_btn)
		
	if current_state == State.EMPTY_BAY:
		if found_hdd:
			backpack_hint.text = "¡Arrastra el Disco Duro nuevo a la bahía o haz clic!"
			backpack_hint.modulate = Color(0.0, 1.0, 0.5, 1.0)
		else:
			backpack_hint.text = "No tienes Disco Duro nuevo en la mochila.\nSal de la PC y ve a la caja de repuestos."
			backpack_hint.modulate = Color(1.0, 0.4, 0.4, 1.0)

func _update_ui_state() -> void:
	match current_state:
		State.UNSCREW_4:
			var tool_name = "Tecla 1 (Destornillador Estrella / Cruz)" if screw_type == "cruz" else "Tecla 2 (Destornillador Pala / Plano)"
			status_label.text = "Paso 1: Equipa %s para quitar los 4 tornillos." % tool_name
			status_label.modulate = Color(1.0, 0.85, 0.2, 1)
			disk_drag_label.text = "SATA SSD 1TB [DAÑADO]\n(Desatornilla primero)"
			disk_drag_label.modulate = Color(1, 0.4, 0.4, 1)
		State.DISCONNECT_SATA:
			status_label.text = "Paso 2: Haz clic para desconectar el cable SATA."
			status_label.modulate = Color(0.0, 0.9, 1.0, 1)
		State.EXTRACT_HDD:
			status_label.text = "Paso 3: Haz clic sobre el Disco Duro y arrástralo hacia ARRIBA para sacarlo."
			status_label.modulate = Color(0.0, 1.0, 0.5, 1)
			disk_drag_label.text = "▲ HAZ CLIC Y ARRASTRA\nHACIA ARRIBA ▲"
			disk_drag_label.modulate = Color(0, 1, 0.6, 1)
		State.EMPTY_BAY:
			status_label.text = "Bahía vacía. Arrastra el Disco Duro nuevo desde tu mochila hacia la bahía."
			status_label.modulate = Color(1.0, 0.85, 0.2, 1)
			_refresh_backpack_ui()
		State.INSERT_HDD_DOWN:
			status_label.text = "Paso 4 (A la inversa): Arrastra el Disco Duro hacia ABAJO para encajarlo."
			status_label.modulate = Color(0.0, 0.9, 1.0, 1)
			disk_drag_label.text = "▼ ARRASTRA HACIA ABAJO\nPARA CALZAR EN BAHÍA ▼"
			disk_drag_label.modulate = Color(0, 0.95, 1, 1)
		State.CONNECT_SATA_NEW:
			status_label.text = "Paso 5: Haz clic en el botón SATA para volver a conectar el cable."
			status_label.modulate = Color(0.0, 0.9, 1.0, 1)
		State.SCREW_4:
			var tool_name = "Tecla 1 (Cruz)" if screw_type == "cruz" else "Tecla 2 (Pala)"
			status_label.text = "Paso 6: Con %s, vuelve a ajustar los 4 tornillos de seguridad." % tool_name
			status_label.modulate = Color(1.0, 0.85, 0.2, 1)
		State.COMPLETED:
			status_label.text = "¡Disco Duro reemplazado, conectado y ajustado con éxito!"
			status_label.modulate = Color(0.0, 1.0, 0.4, 1)

func _on_screw_pressed(btn: Button) -> void:
	if GameManager.equipped_tool != required_tool_id:
		GameManager.register_error(2.0)
		var expected = "CRUZ / ESTRELLA (Tecla 1)" if screw_type == "cruz" else "PALA / PLANO (Tecla 2)"
		status_label.text = "¡Herramienta incorrecta! Este tornillo es de %s." % expected
		status_label.modulate = Color(1, 0.2, 0.3, 1)
		return
		
	if current_state == State.UNSCREW_4:
		btn.visible = false
		screws_left -= 1
		if screws_left <= 0:
			current_state = State.DISCONNECT_SATA
			_update_ui_state()
	elif current_state == State.SCREW_4:
		btn.modulate = Color(0, 1, 0.5, 1)
		btn.disabled = true
		screws_tightened += 1
		if screws_tightened >= 4:
			current_state = State.COMPLETED
			_update_ui_state()
			var tween = create_tween()
			tween.tween_interval(0.25)
			tween.tween_callback(func():
				minigame_finished.emit(true)
			)

func _on_sata_pressed() -> void:
	if current_state == State.DISCONNECT_SATA:
		sata_connected = false
		btn_sata.text = "Cable SATA: [DESCONECTADO]"
		btn_sata.modulate = Color(1, 0.3, 0.3, 1)
		current_state = State.EXTRACT_HDD
		_update_ui_state()
	elif current_state == State.CONNECT_SATA_NEW:
		sata_connected = true
		btn_sata.text = "Cable SATA: [CONECTADO]"
		btn_sata.modulate = Color(0, 1, 0.5, 1)
		for s in screws:
			s.visible = true
			s.disabled = false
			s.modulate = Color(1, 1, 1, 1)
		current_state = State.SCREW_4
		_update_ui_state()

func _on_disk_gui_input(event: InputEvent) -> void:
	# FASE EXTRACCIÓN (Hacia arriba)
	if current_state == State.EXTRACT_HDD:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging_hdd = true
				drag_start_y = event.global_position.y
			else:
				if is_dragging_hdd:
					is_dragging_hdd = false
					var diff_y = drag_start_y - event.global_position.y
					if diff_y >= 35.0:
						_complete_hdd_removal()
					else:
						# Regresar a posición normal si no arrastró lo suficiente
						var tween = create_tween()
						tween.tween_property(disk_panel, "position:y", base_disk_y, 0.2)
		elif event is InputEventMouseMotion and is_dragging_hdd:
			var pull = clamp(drag_start_y - event.global_position.y, 0.0, 70.0)
			disk_panel.position.y = base_disk_y - pull
			
	# FASE INSERCIÓN A LA INVERSA (Hacia abajo)
	elif current_state == State.INSERT_HDD_DOWN:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging_hdd = true
				drag_start_y = event.global_position.y
			else:
				if is_dragging_hdd:
					is_dragging_hdd = false
					var diff_y = event.global_position.y - drag_start_y
					if diff_y >= 30.0:
						_seat_new_hdd()
					else:
						var tween = create_tween()
						tween.tween_property(disk_panel, "position:y", -50.0, 0.2)
		elif event is InputEventMouseMotion and is_dragging_hdd:
			var push = clamp(event.global_position.y - drag_start_y, 0.0, 70.0)
			disk_panel.position.y = -50.0 + push

func _complete_hdd_removal() -> void:
	var tween = create_tween()
	tween.tween_property(disk_panel, "position:y", -180.0, 0.3)
	tween.parallel().tween_property(disk_panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		disk_panel.visible = false
		empty_bay_label.visible = true
		GameManager.add_item_to_backpack({"name": "Disco Duro", "broken": true})
		current_state = State.EMPTY_BAY
		old_part_extracted.emit()
		_update_ui_state()
		_refresh_backpack_ui()
	)

func _insert_hdd_from_backpack(index: int) -> void:
	if current_state != State.EMPTY_BAY:
		return
		
	if index < 0 or index >= GameManager.backpack.size():
		return
		
	var item = GameManager.backpack[index]
	if item.get("name") != "Disco Duro" or item.get("broken", true):
		return
		
	GameManager.remove_item_from_backpack(index)
	empty_bay_label.visible = false
	
	# Mostrar disco nuevo suspendido arriba de la bahía
	disk_panel.visible = true
	disk_panel.modulate = Color(0, 0.95, 1, 1)
	disk_panel.position.y = -50.0
	
	current_state = State.INSERT_HDD_DOWN
	_update_ui_state()
	_refresh_backpack_ui()

func _seat_new_hdd() -> void:
	var tween = create_tween()
	tween.tween_property(disk_panel, "position:y", base_disk_y, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		disk_drag_label.text = "SATA SSD 1TB [CALZADO]"
		disk_drag_label.modulate = Color(0, 1, 0.6, 1)
		current_state = State.CONNECT_SATA_NEW
		_update_ui_state()
	)
