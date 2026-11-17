extends CanvasLayer

# =============================================================================
# MINIJUEGO: DESMONTAJE Y MONTAJE DE DISCO HDD
# Enseña:
# 1. Quitar los 4 tornillos de retención (uno en cada esquina) con destornillador.
# 2. Desconectar el cable SATA de datos y energía (clic en el conector).
# 3. Arrastrar el disco HDD hacia la DERECHA para extraerlo de la bahía/placa.
# =============================================================================

signal minigame_finished(success: bool)
signal old_part_extracted()

enum State {
	UNSCREW_4_CORNERS,   # 1. Quitar los 4 tornillos de las esquinas
	DISCONNECT_SATA,     # 2. Clic en cable SATA para desconectar
	EXTRACT_DRAG_RIGHT,  # 3. Arrastrar hacia la derecha para extraer
	EMPTY_BAY,           # Bahía vacía
	INSERT_DRAG_LEFT,    # 1. Arrastrar nuevo disco hacia la izquierda
	CONNECT_SATA,        # 2. Clic en cable SATA para conectar
	FASTEN_4_SCREWS,     # 3. Atornillar los 4 tornillos
	COMPLETED
}

var current_state: State = State.UNSCREW_4_CORNERS
var start_as_empty_slot: bool = false
var is_tutorial_mode: bool = false
@export var target_hdd_count: int = 1
@export var initial_installed_count: int = 0
var current_hdd_index: int = 0

func get_installed_count() -> int:
	var cnt = 0
	for s in hdd_installed_states:
		if s: cnt += 1
	return cnt

func is_ssd_correctly_seated_in_pins() -> bool:
	return current_state in [State.CONNECT_SATA, State.FASTEN_4_SCREWS, State.COMPLETED]

# Tornillos: 0: Top-Left, 1: Top-Right, 2: Bottom-Left, 3: Bottom-Right
var screw_types: Array[String] = ["cruz", "cruz", "cruz", "cruz"]
var screws_removed: Array[bool] = [false, false, false, false]
var screw_type: String = "cruz" # Compatibilidad con PCInspectionModal

var is_sata_disconnected: bool = false
var is_extracted: bool = false

# Dragging
var is_dragging_hdd: bool = false
var drag_start_x: float = 0.0

# Texturas oficiales
const TEX_PLACA = preload("res://pixel art minijuegos/memoriastipos/hdd/placa de disco hdd.png")
const TEX_HDD_CONNECTED = preload("res://pixel art minijuegos/memoriastipos/hdd/disco hdd.png")
const TEX_HDD_DISCONNECTED = preload("res://pixel art minijuegos/memoriastipos/hdd/desconectado disco hdd.png")
const TEX_SCREW_CRUZ = preload("res://pixel art minijuegos/tornillos/tornillo de cruz.png")
const TEX_SCREW_PALA = preload("res://pixel art minijuegos/tornillos/tornillo de pala.png")

# Nodos UI
@onready var modal_control: Control = $ModalControl
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var btn_tool_1: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool1
@onready var btn_tool_2: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool2
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel

# Área de trabajo HDD
@onready var hdd_work_area: Control = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/HDDWorkArea
@onready var placa_sprite: TextureRect = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/HDDWorkArea/PlacaSprite
@onready var drive_container: Control = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/HDDWorkArea/DriveContainer
@onready var hdd_sprite: TextureRect = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/HDDWorkArea/DriveContainer/HDDSprite

# Conector SATA
@onready var btn_sata_cable: Button = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/HDDWorkArea/DriveContainer/BtnSataCable
@onready var sata_highlight: Panel = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/HDDWorkArea/DriveContainer/BtnSataCable/SataHighlight
@onready var sata_hint_label: Label = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/HDDWorkArea/DriveContainer/BtnSataCable/SataHintLabel

# Tornillos (4 esquinas)
@onready var screws_container: Control = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/HDDWorkArea/ScrewsContainer
@onready var btn_screw_tl: Button = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/HDDWorkArea/ScrewsContainer/ScrewTL
@onready var btn_screw_tr: Button = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/HDDWorkArea/ScrewsContainer/ScrewTR
@onready var btn_screw_bl: Button = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/HDDWorkArea/ScrewsContainer/ScrewBL
@onready var btn_screw_br: Button = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/HDDWorkArea/ScrewsContainer/ScrewBR
@onready var icon_screw_tl: TextureRect = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/HDDWorkArea/ScrewsContainer/ScrewTL/Icon
@onready var icon_screw_tr: TextureRect = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/HDDWorkArea/ScrewsContainer/ScrewTR/Icon
@onready var icon_screw_bl: TextureRect = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/HDDWorkArea/ScrewsContainer/ScrewBL/Icon
@onready var icon_screw_br: TextureRect = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/HDDWorkArea/ScrewsContainer/ScrewBR/Icon

# Indicadores visuales
@onready var drag_arrow_indicator: PanelContainer = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/HDDWorkArea/DragArrowIndicator
@onready var arrow_label: Label = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/HDDWorkArea/DragArrowIndicator/ArrowLabel
@onready var warning_label: Label = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/HDDWorkArea/WarningLabel

# Panel Lateral / Guía
@onready var btn_tab_quitar: Button = $ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/TabsBox/BtnTabQuitar
@onready var btn_tab_poner: Button = $ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/TabsBox/BtnTabPoner
@onready var guide_text: Label = $ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/GuideText
@onready var chk_screws: Label = $ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/Checklist/ChkScrews
@onready var chk_sata: Label = $ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/Checklist/ChkSata
@onready var chk_extract: Label = $ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/Checklist/ChkExtract
@onready var backpack_items_box: VBoxContainer = $ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/ItemsContainer
@onready var backpack_hint: Label = $ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/BackpackHint

# Servidor / Multi-slot
@onready var slots_container: VBoxContainer = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/SlotsContainer")
@onready var btn_slot_0: Button = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/SlotsContainer/BtnSlot0")
@onready var btn_slot_1: Button = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/SlotsContainer/BtnSlot1")
@onready var btn_slot_2: Button = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/SlotsContainer/BtnSlot2")

var hdd_installed_states: Array[bool] = [false, false, false]
var screw_buttons: Array[Button] = []
var screw_icons: Array[TextureRect] = []

var arrow_tween: Tween = null
var sata_pulse_tween: Tween = null

func _ready() -> void:
	layer = 12
	screw_buttons = [btn_screw_tl, btn_screw_tr, btn_screw_bl, btn_screw_br]
	screw_icons = [icon_screw_tl, icon_screw_tr, icon_screw_bl, icon_screw_br]
	
	_setup_screw_types()
	_setup_ui()
	_update_tool_buttons()
	
	GameManager.backpack_updated.connect(_on_backpack_changed)
	
	if btn_slot_0: btn_slot_0.pressed.connect(func(): _on_slot_button_clicked(0))
	if btn_slot_1: btn_slot_1.pressed.connect(func(): _on_slot_button_clicked(1))
	if btn_slot_2: btn_slot_2.pressed.connect(func(): _on_slot_button_clicked(2))
	
	if target_hdd_count > 1 and is_instance_valid(slots_container):
		slots_container.visible = true
		_update_slots_ui()
		
	if initial_installed_count > 0:
		for k in range(min(initial_installed_count, hdd_installed_states.size())):
			hdd_installed_states[k] = true
		current_hdd_index = initial_installed_count
		if current_hdd_index < target_hdd_count:
			_prepare_next_hdd_slot()
			_select_guide_tab(1)
		_update_slots_ui()
	elif start_as_empty_slot:
		_setup_empty_bay_phase()
		_select_guide_tab(1)
		_refresh_backpack_ui()
	else:
		_setup_removal_phase()
		_select_guide_tab(0)
		_refresh_backpack_ui()
		
	_update_status()

func _setup_screw_types() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in range(4):
		screw_types[i] = "pala" if rng.randf() > 0.6 else "cruz"
		screws_removed[i] = false
		if is_instance_valid(screw_icons[i]):
			screw_icons[i].texture = TEX_SCREW_CRUZ if screw_types[i] == "cruz" else TEX_SCREW_PALA

func _setup_ui() -> void:
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	btn_tool_1.pressed.connect(func(): GameManager.select_tool(1))
	btn_tool_2.pressed.connect(func(): GameManager.select_tool(2))
	GameManager.tool_selected.connect(_on_tool_selected)
	
	if is_instance_valid(btn_tab_quitar):
		btn_tab_quitar.pressed.connect(func(): _select_guide_tab(0))
	if is_instance_valid(btn_tab_poner):
		btn_tab_poner.pressed.connect(func(): _select_guide_tab(1))
		
	# Conectar botones de los 4 tornillos
	for i in range(screw_buttons.size()):
		var idx = i
		screw_buttons[i].pressed.connect(func(): _on_screw_pressed(idx))
		
	# Conectar cable SATA
	btn_sata_cable.pressed.connect(_on_sata_cable_pressed)
	
	# Eventos de arrastre en el contenedor del disco
	drive_container.gui_input.connect(_on_drive_container_gui_input)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		minigame_finished.emit(false)
		return
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_1:
			GameManager.select_tool(1)
		elif event.keycode == KEY_2:
			GameManager.select_tool(2)

func _on_tool_selected(_tool_id: int) -> void:
	_update_tool_buttons()

func _update_tool_buttons() -> void:
	var active = GameManager.equipped_tool
	btn_tool_1.modulate = Color(1.2, 1.2, 0.4) if active == 1 else Color(0.8, 0.8, 0.8)
	btn_tool_2.modulate = Color(1.2, 1.2, 0.4) if active == 2 else Color(0.8, 0.8, 0.8)

func _select_guide_tab(_idx: int = 0) -> void:
	_auto_detect_operation_mode()

func _auto_detect_operation_mode() -> void:
	var is_install = is_install_phase()
	if is_instance_valid(btn_tab_quitar) and is_instance_valid(btn_tab_quitar.get_parent()):
		btn_tab_quitar.get_parent().visible = false
	if is_instance_valid(btn_tab_quitar):
		btn_tab_quitar.visible = false
	if is_instance_valid(btn_tab_poner):
		btn_tab_poner.visible = false
		
	if is_install:
		if is_instance_valid(guide_text):
			var has_hdd = false
			for it in GameManager.backpack:
				if it.get("name") == "Disco Duro" and not it.get("broken", true):
					has_hdd = true
					break
			var spare_msg = "✓ Disco HDD detectado en inventario.\n\n" if has_hdd else "⚠️ Preparado para colocar repuesto.\n\n"
			guide_text.text = spare_msg + "1. Arrastra el disco nuevo hacia la IZQUIERDA sobre la placa.\n2. Conecta el cable SATA (clic en conector).\n3. Ajusta los 4 tornillos en las esquinas del disco con el destornillador."
	else:
		if is_instance_valid(guide_text):
			guide_text.text = "1. Quita los 4 tornillos en las esquinas del disco con tu destornillador ([1] Cruz o [2] Pala).\n2. Clic en el conector SATA para desconectarlo.\n3. Arrastra el Disco HDD hacia la DERECHA para extraerlo."

func _setup_removal_phase() -> void:
	current_state = State.UNSCREW_4_CORNERS
	is_sata_disconnected = false
	is_extracted = false
	
	# Placa base (capa inferior)
	placa_sprite.visible = true
	placa_sprite.texture = TEX_PLACA
	
	# Disco montado encima
	drive_container.visible = true
	drive_container.position = Vector2.ZERO
	drive_container.modulate = Color(1, 1, 1, 1)
	hdd_sprite.texture = TEX_HDD_CONNECTED
	
	# Tornillos visibles
	screws_container.visible = true
	for i in range(4):
		screws_removed[i] = false
		screw_buttons[i].visible = true
		screw_buttons[i].disabled = false
		screw_buttons[i].modulate = Color(1, 1, 1, 1)
		screw_buttons[i].rotation_degrees = 0.0
		screw_icons[i].scale = Vector2(1, 1)
		
	_stop_sata_pulse()
	_stop_arrow_pulse()
	_update_status()

func _setup_empty_bay_phase() -> void:
	current_state = State.INSERT_DRAG_LEFT
	is_sata_disconnected = true
	
	placa_sprite.visible = true
	placa_sprite.texture = TEX_PLACA
	
	# Disco listo para colocar (desplazado a la derecha)
	drive_container.visible = true
	drive_container.position = Vector2(90.0, 0.0)
	drive_container.modulate = Color(0.4, 0.95, 1.0, 0.75)
	hdd_sprite.texture = TEX_HDD_DISCONNECTED
	
	# Ocultar tornillos hasta asentar
	screws_container.visible = false
	for i in range(4):
		screws_removed[i] = true
		screw_buttons[i].visible = false
		
	_stop_sata_pulse()
	_start_arrow_pulse(false)
	_update_status()

func is_install_phase() -> bool:
	return current_state in [State.INSERT_DRAG_LEFT, State.CONNECT_SATA, State.FASTEN_4_SCREWS]

# =============================================================================
# PASO 1: QUITAR LOS 4 TORNILLOS (UNO POR ESQUINA)
# =============================================================================
func _on_screw_pressed(idx: int) -> void:
	if is_install_phase():
		_on_screw_pressed_install(idx)
		return
		
	if screws_removed[idx]:
		return
		
	var req_tool = 1 if screw_types[idx] == "cruz" else 2
	var tool_name = "Cruz (+)" if req_tool == 1 else "Pala (-)"
	
	if GameManager.equipped_tool != req_tool:
		GameManager.register_error(2.0)
		_show_warning("Herramienta incorrecta: Este tornillo requiere Destornillador " + tool_name + " [Tecla " + str(req_tool) + "]", Color(1.0, 0.3, 0.3))
		_shake_node(screw_buttons[idx])
		return
		
	screws_removed[idx] = true
	screw_buttons[idx].disabled = true
	
	var icon = screw_icons[idx]
	var btn = screw_buttons[idx]
	var tw = create_tween().set_parallel(true)
	tw.tween_property(icon, "rotation_degrees", icon.rotation_degrees + 720.0, 0.35)
	tw.tween_property(icon, "scale", Vector2(0.1, 0.1), 0.35)
	tw.tween_property(btn, "modulate:a", 0.0, 0.35)
	
	GameManager.register_repair(15, 1.5)
	var remaining = 0
	for r in screws_removed:
		if not r: remaining += 1
		
	if remaining > 0:
		_show_warning("✓ Tornillo retirado. Faltan %d tornillo(s)." % remaining, Color(0.4, 1.0, 0.4))
	else:
		_show_warning("✓ ¡Los 4 tornillos han sido retirados! Ahora desconecta el cable SATA.", Color(0.2, 1.0, 0.5))
		current_state = State.DISCONNECT_SATA
		_start_sata_pulse()
		
	_update_status()

# =============================================================================
# PASO 2: DESCONECTAR CABLE SATA
# =============================================================================
func _on_sata_cable_pressed() -> void:
	if is_install_phase():
		_on_sata_cable_pressed_install()
		return
		
	if current_state == State.UNSCREW_4_CORNERS:
		var remaining = 0
		for r in screws_removed:
			if not r: remaining += 1
		GameManager.register_error(1.5)
		_show_warning("¡ALERTA! Primero debes retirar los 4 tornillos de las esquinas (%d restantes)." % remaining, Color(1.0, 0.3, 0.3))
		_shake_node(btn_sata_cable)
		return
		
	if is_sata_disconnected:
		return
		
	is_sata_disconnected = true
	_stop_sata_pulse()
	
	# Cambiar textura a desconectado
	hdd_sprite.texture = TEX_HDD_DISCONNECTED
	
	# Efecto visual
	var tw = create_tween()
	tw.tween_property(btn_sata_cable, "modulate", Color(1.5, 1.5, 0.2, 1.0), 0.1)
	tw.tween_property(btn_sata_cable, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
	
	_show_warning("✓ Cable SATA desconectado. Arrastra el disco a la DERECHA para retirarlo.", Color(0.2, 1.0, 0.5))
	current_state = State.EXTRACT_DRAG_RIGHT
	_start_arrow_pulse(true)
	_update_status()

# =============================================================================
# PASO 3: ARRASTRAR HACIA LA DERECHA
# =============================================================================
func _on_drive_container_gui_input(event: InputEvent) -> void:
	if current_state == State.EXTRACT_DRAG_RIGHT:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging_hdd = true
				drag_start_x = event.global_position.x
			else:
				if is_dragging_hdd:
					is_dragging_hdd = false
					var diff_x = event.global_position.x - drag_start_x
					if diff_x >= 45.0:
						_complete_hdd_extraction()
					else:
						var tw = create_tween()
						tw.tween_property(drive_container, "position:x", 0.0, 0.18)
		elif event is InputEventMouseMotion and is_dragging_hdd:
			var pull = clamp(event.global_position.x - drag_start_x, 0.0, 140.0)
			drive_container.position.x = pull
			
	elif current_state == State.INSERT_DRAG_LEFT:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging_hdd = true
				drag_start_x = event.global_position.x
			else:
				if is_dragging_hdd:
					is_dragging_hdd = false
					var diff_x = drag_start_x - event.global_position.x
					if diff_x >= 35.0 or abs(event.global_position.x - drag_start_x) < 6.0:
						_seat_new_hdd()
					else:
						var tw = create_tween()
						tw.tween_property(drive_container, "position:x", 90.0, 0.18)
		elif event is InputEventMouseMotion and is_dragging_hdd:
			var push = clamp(drag_start_x - event.global_position.x, 0.0, 90.0)
			drive_container.position.x = 90.0 - push

func _complete_hdd_extraction() -> void:
	if is_extracted: return
	is_extracted = true
	_stop_arrow_pulse()
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(drive_container, "position:x", 320.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(drive_container, "modulate:a", 0.0, 0.28)
	
	await tw.finished
	drive_container.visible = false
	
	GameManager.add_item_to_backpack({"name": "Disco Duro", "broken": true, "type": "Disco Duro"})
	old_part_extracted.emit()
	
	_show_warning("✓ Disco averiado extraído con éxito. Ve a la caja de repuestos en el taller a buscar el nuevo.", Color(0.2, 1.0, 0.5))
	await get_tree().create_timer(1.0).timeout
	minigame_finished.emit(true)

# =============================================================================
# MONTAJE DEL REPUESTO
# =============================================================================
func _seat_new_hdd() -> void:
	var found_idx = -1
	for i in range(GameManager.backpack.size()):
		var it = GameManager.backpack[i]
		if (it.get("name") == "Disco Duro" or it.get("type") == "Disco Duro") and not it.get("broken", true):
			found_idx = i
			break
			
	if found_idx == -1:
		_show_warning("⚠️ No tienes Disco HDD de repuesto en la mochila. Sal [ESC] para recogerlo en la caja.", Color(1.0, 0.4, 0.4))
		status_label.text = "⚠️ FALTA DISCO HDD EN MOCHILA · SAL [ESC] PARA BUSCARLO"
		status_label.modulate = Color(1.0, 0.4, 0.4)
		return
		
	if found_idx != -1:
		GameManager.remove_item_from_backpack(found_idx)
		
	_stop_arrow_pulse()
	var tw = create_tween().set_parallel(true)
	tw.tween_property(drive_container, "position:x", 0.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(drive_container, "modulate", Color(1, 1, 1, 1), 0.22)
	
	current_state = State.CONNECT_SATA
	is_sata_disconnected = true
	hdd_sprite.texture = TEX_HDD_DISCONNECTED
	_start_sata_pulse()
	_show_warning("✓ Disco HDD calzado sobre la placa. Conecta el cable SATA.", Color(0.2, 1.0, 0.4))
	_update_status()

func _on_sata_cable_pressed_install() -> void:
	if current_state != State.CONNECT_SATA:
		return
		
	is_sata_disconnected = false
	_stop_sata_pulse()
	hdd_sprite.texture = TEX_HDD_CONNECTED
	
	var tw = create_tween()
	tw.tween_property(btn_sata_cable, "modulate", Color(0.2, 1.4, 0.5, 1.0), 0.15)
	tw.tween_property(btn_sata_cable, "modulate", Color(1, 1, 1, 1), 0.15)
	
	current_state = State.FASTEN_4_SCREWS
	screws_container.visible = true
	for i in range(4):
		screws_removed[i] = true # Faltan por colocar
		screw_buttons[i].visible = true
		screw_buttons[i].disabled = false
		screw_buttons[i].modulate.a = 0.45
		screw_icons[i].scale = Vector2(0.5, 0.5)
		screw_icons[i].rotation_degrees = 0.0
		
	_show_warning("✓ Cable SATA conectado. Ajusta los 4 tornillos de las esquinas.", Color(0.2, 1.0, 0.4))
	_update_status()

func _on_screw_pressed_install(idx: int) -> void:
	if not screws_removed[idx]:
		return # Ya ajustado
		
	var req_tool = 1 if screw_types[idx] == "cruz" else 2
	var tool_name = "Cruz (+)" if req_tool == 1 else "Pala (-)"
	
	if GameManager.equipped_tool != req_tool:
		GameManager.register_error(2.0)
		_show_warning("Herramienta incorrecta: Este tornillo requiere Destornillador " + tool_name + " [Tecla " + str(req_tool) + "]", Color(1.0, 0.3, 0.3))
		_shake_node(screw_buttons[idx])
		return
		
	screws_removed[idx] = false # Atornillado
	screw_buttons[idx].disabled = true
	
	var icon = screw_icons[idx]
	var btn = screw_buttons[idx]
	var tw = create_tween().set_parallel(true)
	tw.tween_property(icon, "rotation_degrees", icon.rotation_degrees - 720.0, 0.35)
	tw.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.35)
	tw.tween_property(btn, "modulate:a", 1.0, 0.35)
	
	GameManager.register_repair(15, 1.5)
	var remaining = 0
	for r in screws_removed:
		if r: remaining += 1
		
	if remaining > 0:
		_show_warning("✓ Tornillo colocado y apretado (%d restantes)." % remaining, Color(0.4, 1.0, 0.4))
		_update_status()
	else:
		_check_hdd_install_completed()

func _check_hdd_install_completed() -> void:
	if current_hdd_index < hdd_installed_states.size():
		hdd_installed_states[current_hdd_index] = true
	current_hdd_index += 1
	_update_slots_ui()
	
	if current_hdd_index < target_hdd_count:
		_show_warning("✓ ¡DISCO HDD #%d MONTADO!" % current_hdd_index, Color(0.2, 1.0, 0.4))
		status_label.text = "✓ DISCO #%d INSTALADO · HAZ CLIC EN 'BAHÍA SAS #%d' A LA DERECHA PARA CONTINUAR" % [current_hdd_index, current_hdd_index + 1]
		status_label.modulate = Color(0.0, 0.95, 1.0)
	else:
		current_state = State.COMPLETED
		_update_status()
		_show_warning("✓ ¡OPERACIÓN COMPLETADA! Disco HDD instalado y asegurado al 100%.", Color(0.2, 1.0, 0.4))
		await get_tree().create_timer(0.6).timeout
		minigame_finished.emit(true)

# =============================================================================
# MULTI-SLOT & BACKPACK
# =============================================================================
func _on_slot_button_clicked(idx: int) -> void:
	if idx == current_hdd_index and current_hdd_index < target_hdd_count and not hdd_installed_states[idx]:
		_prepare_next_hdd_slot()

func _update_slots_ui() -> void:
	if target_hdd_count <= 1 or not is_instance_valid(slots_container):
		return
	var buttons = [btn_slot_0, btn_slot_1, btn_slot_2]
	for i in range(buttons.size()):
		var btn = buttons[i]
		if not is_instance_valid(btn): continue
		if i >= target_hdd_count:
			btn.visible = false
			continue
		btn.visible = true
		if hdd_installed_states[i]:
			btn.text = "✓ BAHÍA SAS #%d [MONTADA]" % (i + 1)
			btn.modulate = Color(0.2, 1.0, 0.45)
			btn.disabled = false
		elif i == current_hdd_index:
			btn.text = "➔ CLIC PARA MONTAR DISCO #%d" % (i + 1)
			btn.modulate = Color(1.0, 0.85, 0.2)
			btn.disabled = false
		else:
			btn.text = "🔒 BAHÍA SAS #%d [PENDIENTE]" % (i + 1)
			btn.modulate = Color(0.55, 0.6, 0.7, 0.6)
			btn.disabled = true

func _prepare_next_hdd_slot() -> void:
	_setup_screw_types()
	_setup_empty_bay_phase()
	_update_status()

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
		backpack_hint.text = "No tienes repuestos en la mochila."
		return
		
	var found_spare = false
	for it in GameManager.backpack:
		if it.get("name") == "Disco Duro" and not it.get("broken", true):
			found_spare = true
			var btn = Button.new()
			btn.text = "💾 Disco HDD Nuevo (Listo)"
			btn.modulate = Color(0.2, 1.0, 0.5)
			btn.pressed.connect(func():
				if current_state == State.INSERT_DRAG_LEFT:
					_seat_new_hdd()
			)
			backpack_items_box.add_child(btn)
			
	if not found_spare:
		var empty_lbl = Label.new()
		empty_lbl.text = "[ Sin Disco HDD de repuesto ]"
		empty_lbl.modulate = Color(1.0, 0.5, 0.4, 0.8)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		backpack_items_box.add_child(empty_lbl)
		backpack_hint.text = "Sal con [ESC] y busca un Disco Duro en la caja de repuestos."
	else:
		backpack_hint.text = "¡Arrastra el Disco HDD a la bahía o haz clic en el botón!"

# =============================================================================
# INDICADORES VISUALES Y ESTADO
# =============================================================================
func _update_status() -> void:
	_auto_detect_operation_mode()
	var prefix = ("BAHÍA SAS #%d DE %d · " % [current_hdd_index + 1, target_hdd_count]) if target_hdd_count > 1 else ""
	match current_state:
		State.UNSCREW_4_CORNERS:
			var remaining = 0
			for r in screws_removed:
				if not r: remaining += 1
			status_label.text = prefix + "PASO 1: Quita los 4 tornillos de las esquinas del disco con [1] Cruz o [2] Pala (%d restantes)." % remaining
			status_label.modulate = Color(1.0, 0.85, 0.2)
		State.DISCONNECT_SATA:
			status_label.text = prefix + "PASO 2: Haz clic en el CABLE SATA (conector resaltado) para desconectarlo."
			status_label.modulate = Color(0.0, 0.95, 1.0)
		State.EXTRACT_DRAG_RIGHT:
			status_label.text = prefix + "PASO 3: Arrastra el Disco HDD hacia la DERECHA para extraerlo de la placa."
			status_label.modulate = Color(0.2, 1.0, 0.5)
		State.INSERT_DRAG_LEFT:
			status_label.text = prefix + "PASO 1: Arrastra el Disco HDD nuevo hacia la IZQUIERDA sobre la placa."
			status_label.modulate = Color(0.0, 0.95, 1.0)
		State.CONNECT_SATA:
			status_label.text = prefix + "PASO 2: Haz clic en el conector SATA para conectar los datos y energía."
			status_label.modulate = Color(1.0, 0.85, 0.2)
		State.FASTEN_4_SCREWS:
			var remaining = 0
			for r in screws_removed:
				if r: remaining += 1
			status_label.text = prefix + "PASO 3: Ajusta los 4 tornillos en las esquinas del disco con destornillador (%d restantes)." % remaining
			status_label.modulate = Color(0.2, 1.0, 0.5)
		State.COMPLETED:
			status_label.text = "✓ ¡Disco HDD instalado y asegurado con éxito al 100%!"
			status_label.modulate = Color(0.2, 1.0, 0.4)
			
	_update_checklist()

func _update_checklist() -> void:
	if not is_instance_valid(chk_screws) or not is_instance_valid(chk_sata) or not is_instance_valid(chk_extract):
		return
	var is_install = is_install_phase()
	if not is_install:
		var s_rem = 0
		for r in screws_removed:
			if not r: s_rem += 1
		_format_check_item(chk_screws, s_rem == 0, "1. Retirar 4 tornillos de esquinas (%d/4)" % (4 - s_rem), current_state == State.UNSCREW_4_CORNERS)
		_format_check_item(chk_sata, is_sata_disconnected, "2. Desconectar Cable SATA", current_state == State.DISCONNECT_SATA)
		_format_check_item(chk_extract, is_extracted, "3. Arrastrar hacia la derecha", current_state == State.EXTRACT_DRAG_RIGHT)
	else:
		_format_check_item(chk_extract, current_state != State.INSERT_DRAG_LEFT, "1. Colocar Disco HDD sobre placa", current_state == State.INSERT_DRAG_LEFT)
		_format_check_item(chk_sata, not is_sata_disconnected, "2. Conectar Cable SATA", current_state == State.CONNECT_SATA)
		var s_fast = 0
		for r in screws_removed:
			if not r: s_fast += 1
		_format_check_item(chk_screws, s_fast == 4, "3. Ajustar 4 tornillos de esquinas (%d/4)" % s_fast, current_state == State.FASTEN_4_SCREWS)

func _format_check_item(lbl: Label, done: bool, text: String, active: bool = false) -> void:
	if done:
		lbl.text = "✓ " + text
		lbl.modulate = Color(0.2, 1.0, 0.5, 0.95)
	elif active:
		lbl.text = "➔ " + text
		lbl.modulate = Color(1.0, 0.85, 0.2, 1.0)
	else:
		lbl.text = "○ " + text
		lbl.modulate = Color(0.7, 0.75, 0.85, 0.6)

func _start_sata_pulse() -> void:
	if not is_instance_valid(sata_highlight): return
	if is_instance_valid(sata_pulse_tween): sata_pulse_tween.kill()
	sata_highlight.visible = true
	sata_hint_label.visible = true
	sata_pulse_tween = create_tween().set_loops()
	sata_pulse_tween.tween_property(sata_highlight, "modulate", Color(1.5, 1.5, 0.2, 1.0), 0.4).set_trans(Tween.TRANS_SINE)
	sata_pulse_tween.tween_property(sata_highlight, "modulate", Color(0.1, 1.0, 0.85, 0.5), 0.4).set_trans(Tween.TRANS_SINE)

func _stop_sata_pulse() -> void:
	if is_instance_valid(sata_pulse_tween):
		sata_pulse_tween.kill()
		sata_pulse_tween = null
	if is_instance_valid(sata_highlight):
		sata_highlight.visible = false
	if is_instance_valid(sata_hint_label):
		sata_hint_label.visible = false

func _start_arrow_pulse(to_right: bool) -> void:
	if not is_instance_valid(drag_arrow_indicator): return
	if is_instance_valid(arrow_tween): arrow_tween.kill()
	drag_arrow_indicator.visible = true
	if to_right:
		arrow_label.text = "➔ ➔ ARRASTRA EL DISCO A LA DERECHA PARA EXTRAER ➔ ➔"
		arrow_label.modulate = Color(1.0, 0.9, 0.1, 1.0)
	else:
		arrow_label.text = "◀ ◀ ARRASTRA EL DISCO A LA IZQUIERDA PARA COLOCAR ◀ ◀"
		arrow_label.modulate = Color(0.1, 1.0, 0.85, 1.0)
		
	var base_x = (hdd_work_area.size.x - drag_arrow_indicator.size.x) * 0.5 if hdd_work_area.size.x > 0 else 47.0
	var offset_x = 18.0 if to_right else -18.0
	arrow_tween = create_tween().set_loops()
	arrow_tween.tween_property(drag_arrow_indicator, "position:x", base_x + offset_x, 0.45).set_trans(Tween.TRANS_SINE)
	arrow_tween.tween_property(drag_arrow_indicator, "position:x", base_x, 0.45).set_trans(Tween.TRANS_SINE)

func _stop_arrow_pulse() -> void:
	if is_instance_valid(arrow_tween):
		arrow_tween.kill()
		arrow_tween = null
	if is_instance_valid(drag_arrow_indicator):
		drag_arrow_indicator.visible = false

func _show_warning(msg: String, col: Color) -> void:
	if not is_instance_valid(warning_label): return
	warning_label.text = msg
	warning_label.modulate = col
	var tw = create_tween()
	tw.tween_property(warning_label, "scale", Vector2(1.08, 1.08), 0.1)
	tw.tween_property(warning_label, "scale", Vector2(1.0, 1.0), 0.15)

func _shake_node(node: Control) -> void:
	if not is_instance_valid(node): return
	var orig = node.position
	var tw = create_tween()
	tw.tween_property(node, "position:x", orig.x - 5.0, 0.05)
	tw.tween_property(node, "position:x", orig.x + 5.0, 0.05)
	tw.tween_property(node, "position:x", orig.x, 0.05)
