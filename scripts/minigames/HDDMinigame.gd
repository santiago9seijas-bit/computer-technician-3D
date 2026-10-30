extends CanvasLayer

signal minigame_finished(success: bool)
signal old_part_extracted()

enum State {
	UNSCREW,
	EXTRACT_DRAG_UP,
	EMPTY_BAY,
	INSERT_DRAG_DOWN,
	SCREW_BACK,
	COMPLETED
}

var current_state: State = State.UNSCREW
var start_as_empty_slot: bool = false
var is_tutorial_mode: bool = false

var screw_type: String = "cruz"
var required_tool_id: int = 1

var is_dragging_disk: bool = false
var drag_start_y: float = 0.0

var is_dragging_backpack_hdd: bool = false
var backpack_drag_start_x: float = 0.0

@onready var modal_control: Control = $ModalControl
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel

# Barra de herramientas interna del minijuego
@onready var btn_tool_1: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool1
@onready var btn_tool_2: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool2

@onready var disk_panel: Panel = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/DiskPanel
@onready var disk_drag_label: Label = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/DiskPanel/DragHint
@onready var empty_bay_label: Label = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/BayBase/EmptyBayLabel

@onready var screw_container: Control = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/DiskPanel/ScrewContainer
@onready var btn_screw: Button = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/DiskPanel/ScrewContainer/BtnScrew
@onready var lbl_screw_type: Label = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/DiskPanel/ScrewContainer/LblScrewType

@onready var backpack_items_box: VBoxContainer = $ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/ItemsContainer
@onready var backpack_hint: Label = $ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/BackpackHint
@onready var btn_tab_quitar: Button = $ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/TabsBox/BtnTabQuitar
@onready var btn_tab_poner: Button = $ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/TabsBox/BtnTabPoner
@onready var guide_text: Label = $ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/GuideText
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel

func _ready() -> void:
	layer = 12
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	btn_screw.pressed.connect(_on_screw_pressed)
	empty_bay_label.visible = false
	
	btn_tool_1.pressed.connect(func(): GameManager.select_tool(1))
	btn_tool_2.pressed.connect(func(): GameManager.select_tool(2))
	GameManager.tool_selected.connect(_on_tool_selected)
	
	disk_panel.gui_input.connect(_on_disk_gui_input)
	GameManager.backpack_updated.connect(_on_backpack_changed)
	
	if is_tutorial_mode:
		btn_tab_quitar.pressed.connect(func(): _select_guide_tab(0))
		btn_tab_poner.pressed.connect(func(): _select_guide_tab(1))
	else:
		var tabs = btn_tab_quitar.get_parent()
		if tabs:
			tabs.queue_free()
	
	# Si no se pasó un tipo persistente, elegir aleatoriamente
	if screw_type == "" or (not start_as_empty_slot and screw_type == "cruz"):
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		screw_type = "pala" if rng.randf() > 0.5 else "cruz"
		
	required_tool_id = 1 if screw_type == "cruz" else 2
	var icon = "✚" if screw_type == "cruz" else "▬"
	var desc = "Tornillo de Cruz (Tecla 1)" if screw_type == "cruz" else "Tornillo de Pala (Tecla 2)"
	btn_screw.text = icon
	lbl_screw_type.text = desc
	
	if start_as_empty_slot:
		disk_panel.visible = false
		empty_bay_label.visible = true
		current_state = State.EMPTY_BAY
		_select_guide_tab(1)
	else:
		_select_guide_tab(0)
		
	_update_tool_buttons(GameManager.equipped_tool)
	_update_ui_state()
	_refresh_backpack_ui()

func _select_guide_tab(idx: int) -> void:
	if is_instance_valid(btn_tab_quitar) and is_instance_valid(btn_tab_poner):
		if idx == 0:
			btn_tab_quitar.modulate = Color(1.2, 1.2, 0.4, 1.0)
			btn_tab_poner.modulate = Color(0.7, 0.7, 0.7, 0.7)
		else:
			btn_tab_quitar.modulate = Color(0.7, 0.7, 0.7, 0.7)
			btn_tab_poner.modulate = Color(0.2, 1.0, 0.5, 1.0)
			
	if idx == 0:
		guide_text.text = "FASE 1 (QUITAR): Retira el tornillo de bahía con [1] Cruz o [2] Pala y arrastra el disco hacia arriba."
		if is_tutorial_mode and (current_state == State.EMPTY_BAY or current_state == State.INSERT_DRAG_DOWN or current_state == State.SCREW_BACK):
			_setup_quitar_phase()
	else:
		guide_text.text = "FASE 2 (PONER AL REVÉS): Coloca el disco nuevo en la bahía, arrástralo hacia abajo y ajusta el tornillo."
		if is_tutorial_mode and (current_state == State.UNSCREW or current_state == State.EXTRACT_DRAG_UP):
			_setup_empty_bay_phase()

func _setup_quitar_phase() -> void:
	current_state = State.UNSCREW
	disk_panel.visible = true
	disk_panel.position.y = 0.0
	disk_panel.modulate = Color(1, 1, 1, 1)
	empty_bay_label.visible = false
	screw_container.visible = true
	btn_screw.visible = true
	btn_screw.disabled = false
	btn_screw.modulate = Color(1, 1, 1, 1)
	_update_ui_state()

func _setup_empty_bay_phase() -> void:
	current_state = State.INSERT_DRAG_DOWN
	disk_panel.visible = true
	disk_panel.position.y = -50.0
	disk_panel.modulate = Color(0, 0.95, 1, 0.8)
	empty_bay_label.visible = false
	screw_container.visible = false
	_update_ui_state()
	_refresh_backpack_ui()

func _on_tool_selected(tool_id: int) -> void:
	_update_tool_buttons(tool_id)

func _update_tool_buttons(active_id: int) -> void:
	if btn_tool_1:
		btn_tool_1.modulate = Color(0, 1, 0.8, 1) if active_id == 1 else Color(0.7, 0.7, 0.7, 0.7)
	if btn_tool_2:
		btn_tool_2.modulate = Color(0, 1, 0.8, 1) if active_id == 2 else Color(0.7, 0.7, 0.7, 0.7)

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
		State.UNSCREW:
			var tool_name = "Tecla 1 (Cruz ★)" if screw_type == "cruz" else "Tecla 2 (Pala ▬)"
			status_label.text = "Paso 1: Equipa %s y haz clic en el tornillo para quitarlo." % tool_name
			status_label.modulate = Color(1.0, 0.85, 0.2, 1)
			disk_drag_label.text = "SATA SSD 1TB [DAÑADO]\n(Quita el tornillo primero)"
			disk_drag_label.modulate = Color(1, 0.4, 0.4, 1)
			screw_container.visible = true
			btn_screw.visible = true
			btn_screw.disabled = false
			btn_screw.modulate = Color(1, 1, 1, 1)
		State.EXTRACT_DRAG_UP:
			status_label.text = "Paso 2: Haz clic sobre el Disco Duro y arrástralo hacia ARRIBA para sacarlo."
			status_label.modulate = Color(0.0, 1.0, 0.5, 1)
			disk_drag_label.text = "▲ HAZ CLIC Y ARRASTRA\nHACIA ARRIBA ▲"
			disk_drag_label.modulate = Color(0, 1, 0.6, 1)
			screw_container.visible = false
		State.EMPTY_BAY:
			status_label.text = "Bahía vacía. Arrastra el Disco Duro nuevo desde tu mochila hacia la bahía."
			status_label.modulate = Color(1.0, 0.85, 0.2, 1)
			_refresh_backpack_ui()
		State.INSERT_DRAG_DOWN:
			status_label.text = "Paso 3 (A la inversa): Arrastra el Disco Duro hacia ABAJO para encajarlo."
			status_label.modulate = Color(0.0, 0.9, 1.0, 1)
			disk_drag_label.text = "▼ ARRASTRA HACIA ABAJO\nPARA CALZAR EN BAHÍA ▼"
			disk_drag_label.modulate = Color(0, 0.95, 1, 1)
			screw_container.visible = false
		State.SCREW_BACK:
			var tool_name = "Tecla 1 (Cruz ★)" if screw_type == "cruz" else "Tecla 2 (Pala ▬)"
			status_label.text = "Paso 4: Con %s, haz clic en el tornillo para ajustar el seguro." % tool_name
			status_label.modulate = Color(1.0, 0.85, 0.2, 1)
			disk_drag_label.text = "SATA SSD 1TB [CALZADO]\n(Ajusta el tornillo de seguridad)"
			disk_drag_label.modulate = Color(0, 1, 0.6, 1)
			screw_container.visible = true
			btn_screw.visible = true
			btn_screw.disabled = false
			btn_screw.modulate = Color(1, 1, 1, 1)
		State.COMPLETED:
			status_label.text = "¡Disco Duro reemplazado y asegurado con éxito!"
			status_label.modulate = Color(0.0, 1.0, 0.4, 1)

func _on_screw_pressed() -> void:
	# Si no tenía herramienta equipada, auto-equipamos la correcta para no frustrar al jugador
	if GameManager.equipped_tool == 0:
		GameManager.select_tool(required_tool_id)
		
	# Si tiene la herramienta opuesta incorrecta equipada:
	if GameManager.equipped_tool != required_tool_id:
		GameManager.register_error(2.0)
		var expected = "CRUZ / ESTRELLA (Tecla 1)" if screw_type == "cruz" else "PALA / PLANO (Tecla 2)"
		status_label.text = "¡Herramienta incorrecta! Este tornillo es de %s." % expected
		status_label.modulate = Color(1, 0.2, 0.3, 1)
		return
		
	# Herramienta correcta: DESATORNILLAR
	if current_state == State.UNSCREW:
		var tween = create_tween()
		tween.tween_property(btn_screw, "rotation_degrees", 360.0, 0.2)
		tween.parallel().tween_property(btn_screw, "modulate:a", 0.0, 0.2)
		tween.tween_callback(func():
			btn_screw.visible = false
			screw_container.visible = false
			current_state = State.EXTRACT_DRAG_UP
			_update_ui_state()
		)
	elif current_state == State.SCREW_BACK:
		btn_screw.modulate = Color(0, 1, 0.5, 1)
		btn_screw.disabled = true
		current_state = State.COMPLETED
		_update_ui_state()
		var tween = create_tween()
		tween.tween_interval(0.25)
		tween.tween_callback(func():
			minigame_finished.emit(true)
		)

func _on_disk_gui_input(event: InputEvent) -> void:
	if current_state == State.EXTRACT_DRAG_UP:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging_disk = true
				drag_start_y = event.global_position.y
			else:
				if is_dragging_disk:
					is_dragging_disk = false
					var diff_y = drag_start_y - event.global_position.y
					if diff_y >= 30.0:
						_complete_hdd_removal()
					else:
						var tween = create_tween()
						tween.tween_property(disk_panel, "position:y", 0.0, 0.2)
		elif event is InputEventMouseMotion and is_dragging_disk:
			var pull = clamp(drag_start_y - event.global_position.y, 0.0, 75.0)
			disk_panel.position.y = -pull
			
	elif current_state == State.INSERT_DRAG_DOWN:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging_disk = true
				drag_start_y = event.global_position.y
			else:
				if is_dragging_disk:
					is_dragging_disk = false
					var diff_y = event.global_position.y - drag_start_y
					if diff_y >= 30.0:
						_seat_new_hdd()
					else:
						var tween = create_tween()
						tween.tween_property(disk_panel, "position:y", -50.0, 0.2)
		elif event is InputEventMouseMotion and is_dragging_disk:
			var push = clamp(event.global_position.y - drag_start_y, 0.0, 60.0)
			disk_panel.position.y = -50.0 + push

func _complete_hdd_removal() -> void:
	var tween = create_tween()
	tween.tween_property(disk_panel, "position:y", -180.0, 0.3)
	tween.parallel().tween_property(disk_panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		disk_panel.visible = false
		empty_bay_label.visible = true
		GameManager.add_item_to_backpack({"name": "Disco Duro", "broken": true})
		old_part_extracted.emit()
		
		if not is_tutorial_mode:
			status_label.text = "✓ Disco Duro averiado extraído. Busca el repuesto en el taller."
			status_label.modulate = Color(0.2, 1.0, 0.5, 1)
			await get_tree().create_timer(1.2).timeout
			minigame_finished.emit(true)
			return
		
		# Modo tutorial:
		var has_new = false
		for it in GameManager.backpack:
			if it.get("name") == "Disco Duro" and not it.get("broken", true):
				has_new = true
				break
		if not has_new:
			GameManager.add_item_to_backpack({"name": "Disco Duro", "broken": false})
			
		current_state = State.EMPTY_BAY
		_select_guide_tab(1)
		status_label.text = "✓ FASE 1 (QUITAR) SUPERADA ➔ AHORA FASE 2: MONTAJE DEL REPUESTO (INVERSO)"
		status_label.modulate = Color(0.2, 1.0, 0.5, 1)
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
	
	disk_panel.visible = true
	disk_panel.modulate = Color(0, 0.95, 1, 1)
	disk_panel.position.y = -50.0
	
	current_state = State.INSERT_DRAG_DOWN
	_update_ui_state()
	_refresh_backpack_ui()

func _seat_new_hdd() -> void:
	var tween = create_tween()
	tween.tween_property(disk_panel, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		current_state = State.SCREW_BACK
		_update_ui_state()
	)
