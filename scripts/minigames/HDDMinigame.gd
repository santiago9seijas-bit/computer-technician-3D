extends Control

signal minigame_finished(success: bool)
signal old_part_extracted()

enum State {
	UNSCREW_4,
	DISCONNECT_SATA,
	DRAG_REMOVE_HDD,
	INSERT_NEW_HDD,
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

@onready var status_label: Label = $Panel/StatusLabel
@onready var btn_sata: Button = $Panel/DiskArea/BtnSATA
@onready var disk_panel: Panel = $Panel/DiskArea/DiskPanel
@onready var disk_drag_label: Label = $Panel/DiskArea/DiskPanel/DragHint
@onready var btn_cancel: Button = $Panel/BtnCancel
@onready var btn_insert_spare: Button = $Panel/BtnInsertSpare

@onready var screws: Array[Button] = [
	$Panel/DiskArea/Screw1,
	$Panel/DiskArea/Screw2,
	$Panel/DiskArea/Screw3,
	$Panel/DiskArea/Screw4
]

func _ready() -> void:
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	btn_sata.pressed.connect(_on_sata_pressed)
	btn_insert_spare.pressed.connect(_on_insert_spare_pressed)
	btn_insert_spare.visible = false
	
	disk_panel.gui_input.connect(_on_disk_gui_input)
	
	# Si no se pasó un tipo persistente, elegir aleatoriamente
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
		for s in screws:
			s.visible = false
		btn_sata.text = "Cable SATA: [DESCONECTADO]"
		btn_sata.modulate = Color(1, 0.3, 0.3, 1)
		current_state = State.INSERT_NEW_HDD
		
	_update_ui_state()

func _update_ui_state() -> void:
	match current_state:
		State.UNSCREW_4:
			var tool_name = "Tecla 1 (Destornillador Estrella / Cruz)" if screw_type == "cruz" else "Tecla 2 (Destornillador Pala / Plano)"
			status_label.text = "Paso 1: Equipa %s para quitar los 4 tornillos." % tool_name
			status_label.modulate = Color(1.0, 0.85, 0.2, 1)
			disk_drag_label.text = "SATA SSD 1TB [DAÑADO]\n(Desatornilla primero)"
		State.DISCONNECT_SATA:
			status_label.text = "Paso 2: Haz clic para desconectar el cable SATA."
			status_label.modulate = Color(0.0, 0.9, 1.0, 1)
		State.DRAG_REMOVE_HDD:
			status_label.text = "Paso 3: Haz clic sobre el Disco Duro y arrástralo hacia ARRIBA para sacarlo."
			status_label.modulate = Color(0.0, 1.0, 0.5, 1)
			disk_drag_label.text = "▲ HAZ CLIC Y ARRASTRA\nHACIA ARRIBA ▲"
			disk_drag_label.modulate = Color(0, 1, 0.6, 1)
		State.INSERT_NEW_HDD:
			status_label.text = "Bahía vacía. Inserta el Disco Duro nuevo desde tu mochila."
			status_label.modulate = Color(1.0, 0.85, 0.2, 1)
			_check_spare_in_backpack()
		State.CONNECT_SATA_NEW:
			status_label.text = "Paso 5: Vuelve a conectar el cable SATA."
			status_label.modulate = Color(0.0, 0.9, 1.0, 1)
		State.SCREW_4:
			var tool_name = "Tecla 1 (Cruz)" if screw_type == "cruz" else "Tecla 2 (Pala)"
			status_label.text = "Paso 6: Con %s, vuelve a ajustar los 4 tornillos de seguridad." % tool_name
			status_label.modulate = Color(1.0, 0.85, 0.2, 1)
		State.COMPLETED:
			status_label.text = "¡Disco Duro reemplazado, conectado y ajustado con éxito!"
			status_label.modulate = Color(0.0, 1.0, 0.4, 1)

func _check_spare_in_backpack() -> void:
	var has_new = false
	for item in GameManager.backpack:
		if item.get("name") == "Disco Duro" and not item.get("broken", true):
			has_new = true
			break
			
	btn_insert_spare.visible = true
	if has_new:
		btn_insert_spare.text = "Insertar Disco Duro nuevo de Mochila"
		btn_insert_spare.modulate = Color(0, 1, 0.5, 1)
	else:
		btn_insert_spare.text = "¡Sin Disco Duro nuevo en mochila! (Busca en Repuestos)"
		btn_insert_spare.modulate = Color(1, 0.4, 0.4, 1)

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
			await get_tree().create_timer(0.9).timeout
			minigame_finished.emit(true)

func _on_sata_pressed() -> void:
	if current_state == State.DISCONNECT_SATA:
		sata_connected = false
		btn_sata.text = "Cable SATA: [DESCONECTADO]"
		btn_sata.modulate = Color(1, 0.3, 0.3, 1)
		current_state = State.DRAG_REMOVE_HDD
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
	if current_state != State.DRAG_REMOVE_HDD:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging_hdd = true
			drag_start_y = event.global_position.y
		else:
			if is_dragging_hdd:
				is_dragging_hdd = false
				var diff_y = drag_start_y - event.global_position.y
				if diff_y >= 45.0:
					_complete_hdd_removal()
				else:
					disk_panel.position.y = (size.y - disk_panel.size.y) * 0.5

func _complete_hdd_removal() -> void:
	var tween = create_tween()
	tween.tween_property(disk_panel, "position:y", -180.0, 0.35)
	tween.parallel().tween_property(disk_panel, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func():
		disk_panel.visible = false
		GameManager.add_item_to_backpack({"name": "Disco Duro", "broken": true})
		current_state = State.INSERT_NEW_HDD
		old_part_extracted.emit() # Notificar a la PC que la bahía quedó vacía
		_update_ui_state()
	)

func _on_insert_spare_pressed() -> void:
	if current_state != State.INSERT_NEW_HDD:
		return
		
	var idx = -1
	for i in range(GameManager.backpack.size()):
		var item = GameManager.backpack[i]
		if item.get("name") == "Disco Duro" and not item.get("broken", true):
			idx = i
			break
			
	if idx == -1:
		GameManager.register_error(3.0)
		status_label.text = "¡No tienes un Disco Duro nuevo en la mochila! Ve a repuestos."
		return
		
	GameManager.remove_item_from_backpack(idx)
	btn_insert_spare.visible = false
	
	disk_panel.visible = true
	disk_panel.modulate = Color(0, 0.95, 1, 1)
	disk_panel.position.y = -120.0
	disk_drag_label.text = "SATA SSD 1TB [NUEVO]"
	disk_drag_label.modulate = Color(0, 1, 0.6, 1)
	
	var tween = create_tween()
	tween.tween_property(disk_panel, "position:y", 35.0, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		current_state = State.CONNECT_SATA_NEW
		_update_ui_state()
	)
