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

enum LevelPhase {
	REMOVE_SCREW,       # 1. Quitar tornillo trasero
	OPEN_PINS,          # 2. Clic al pin para abrirlo
	EXTRACT_DRIVE,      # 3. Arrastrar a la derecha
	EMPTY_SLOT,         # Slot vacío (esperando o instalando)
	INSERT_DRAG_LEFT,   # 1. Arrastrar a la izquierda
	CLOSE_PINS,         # 2. Clic al pin para cerrarlo
	INSTALL_SCREW,      # 3. Colocar y apretar tornillo
	COMPLETED
}

var current_state: State = State.UNSCREW
var level_phase: LevelPhase = LevelPhase.REMOVE_SCREW
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

var screw_type: String = "cruz"
var required_tool_id: int = 1

# Dragging tutorial
var is_dragging_disk: bool = false
var drag_start_y: float = 0.0
var is_dragging_backpack_hdd: bool = false
var backpack_drag_start_x: float = 0.0

# Dragging nivel (M.2 / SSD)
var current_drive_type: String = "m2" # "m2" o "ssd"
var is_dragging_level_drive: bool = false
var drag_level_start_x: float = 0.0
var is_pins_open: bool = false
var is_ssd_in_pins: bool = false # Detecta si el SSD/M.2 está correctamente insertado en sus pines

func is_ssd_correctly_seated_in_pins() -> bool:
	return is_ssd_in_pins

# Texturas oficiales de memoria y soporte
const TEX_PLACA = preload("res://pixel art minijuegos/memoriastipos/soporte para ssd/placa.png")
const TEX_M2 = preload("res://pixel art minijuegos/memoriastipos/m.2/memoria M.2.png")
const TEX_SSD = preload("res://pixel art minijuegos/memoriastipos/ssd/memoria.png")
const TEX_PINES_CLOSED = preload("res://pixel art minijuegos/memoriastipos/soporte para ssd/pines de memoria.png")
const TEX_PINES_OPEN = preload("res://pixel art minijuegos/memoriastipos/soporte para ssd/pines de memoria abiertos.png")
const TEX_SCREW_CRUZ = preload("res://pixel art minijuegos/tornillos/tornillo de cruz.png")
const TEX_SCREW_PALA = preload("res://pixel art minijuegos/tornillos/tornillo de pala.png")

# Nodos generales
@onready var modal_control: Control = $ModalControl
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var btn_tool_1: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool1
@onready var btn_tool_2: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool2
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel

# Nodos modo Tutorial (SATA HDD/SSD clásico)
@onready var bay_base: Panel = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/BayBase
@onready var empty_bay_label: Label = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/BayBase/EmptyBayLabel
@onready var disk_panel: Panel = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/DiskPanel
@onready var disk_drag_label: Label = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/DiskPanel/DragHint
@onready var screw_container: Control = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/DiskPanel/ScrewContainer
@onready var btn_screw: Button = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/DiskPanel/ScrewContainer/BtnScrew
@onready var lbl_screw_type: Label = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/DiskPanel/ScrewContainer/LblScrewType

# Nodos modo Nivel (M.2 / SSD normal con soporte y pines)
@onready var level_drive_area: Control = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/LevelDriveArea
@onready var placa_base: TextureRect = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/LevelDriveArea/PlacaBase
@onready var memory_drive: Control = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/LevelDriveArea/MemoryDrive
@onready var memory_sprite: TextureRect = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/LevelDriveArea/MemoryDrive/MemorySprite
@onready var pins_sprite: TextureRect = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/LevelDriveArea/PinsSprite
@onready var btn_pins: Button = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/LevelDriveArea/BtnPins
@onready var rear_screw_btn: Button = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/LevelDriveArea/RearScrewBtn
@onready var screw_icon: TextureRect = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/LevelDriveArea/RearScrewBtn/ScrewIcon
@onready var drag_arrow_indicator: PanelContainer = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/LevelDriveArea/DragArrowIndicator
@onready var arrow_label: Label = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/LevelDriveArea/DragArrowIndicator/ArrowLabel
@onready var btn_toggle_model: Button = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/LevelDriveArea/BtnToggleModel
@onready var pin_highlight_box: Panel = $ModalControl/Panel/VBox/ContentHBox/DiskAreaContainer/DiskArea/LevelDriveArea/PinHighlightBox

const MEMORY_DRIVE_Y: float = -17.75

var arrow_tween: Tween = null
var pin_pulse_tween: Tween = null

@onready var slots_container: VBoxContainer = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/SlotsContainer")
@onready var btn_slot_0: Button = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/SlotsContainer/BtnSlot0")
@onready var btn_slot_1: Button = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/SlotsContainer/BtnSlot1")
@onready var btn_slot_2: Button = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/SlotsContainer/BtnSlot2")

var hdd_installed_states: Array[bool] = [false, false, false]

# Mochila y guía
@onready var backpack_items_box: VBoxContainer = $ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/ItemsContainer
@onready var backpack_hint: Label = $ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/BackpackHint
@onready var btn_tab_quitar: Button = $ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/TabsBox/BtnTabQuitar
@onready var btn_tab_poner: Button = $ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/TabsBox/BtnTabPoner
@onready var guide_text: Label = $ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/GuideText

func _ready() -> void:
	layer = 12
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	btn_tool_1.pressed.connect(func(): GameManager.select_tool(1))
	btn_tool_2.pressed.connect(func(): GameManager.select_tool(2))
	GameManager.tool_selected.connect(_on_tool_selected)
	GameManager.backpack_updated.connect(_on_backpack_changed)
	
	# Determinar tipo de tornillo (Cruz o Pala)
	if screw_type == "" or (not start_as_empty_slot and screw_type == "cruz"):
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		screw_type = "pala" if rng.randf() > 0.5 else "cruz"
		
	required_tool_id = 1 if screw_type == "cruz" else 2
	var icon = "✚" if screw_type == "cruz" else "▬"
	var desc = "Tornillo de Cruz (Tecla 1)" if screw_type == "cruz" else "Tornillo de Pala (Tecla 2)"
	btn_screw.text = icon
	lbl_screw_type.text = desc
	
	if btn_slot_0: btn_slot_0.pressed.connect(func(): _on_slot_button_clicked(0))
	if btn_slot_1: btn_slot_1.pressed.connect(func(): _on_slot_button_clicked(1))
	if btn_slot_2: btn_slot_2.pressed.connect(func(): _on_slot_button_clicked(2))
	
	if is_instance_valid(btn_tab_quitar) and is_instance_valid(btn_tab_quitar.get_parent()):
		btn_tab_quitar.get_parent().visible = false
		
	if target_hdd_count > 1 and is_instance_valid(slots_container):
		slots_container.visible = true
		_update_slots_ui()
	
	if initial_installed_count > 0:
		for k in range(min(initial_installed_count, hdd_installed_states.size())):
			hdd_installed_states[k] = true
		current_hdd_index = initial_installed_count

	if is_tutorial_mode:
		# MODO TUTORIAL (original)
		bay_base.visible = true
		disk_panel.visible = true
		level_drive_area.visible = false
		empty_bay_label.visible = false
		btn_screw.pressed.connect(_on_screw_pressed)
		disk_panel.gui_input.connect(_on_disk_gui_input)
		btn_tab_quitar.pressed.connect(func(): _select_guide_tab(0))
		btn_tab_poner.pressed.connect(func(): _select_guide_tab(1))
		
		if start_as_empty_slot or current_hdd_index > 0:
			disk_panel.visible = false
			empty_bay_label.visible = true
			current_state = State.EMPTY_BAY
			_select_guide_tab(1)
		else:
			_select_guide_tab(0)
			
		_update_tool_buttons(GameManager.equipped_tool)
		_update_ui_state()
		_refresh_backpack_ui()
	else:
		# MODO NIVEL (Nuevo sistema con sprites de placa, memoria M.2 / SSD y pines superpuestos)
		btn_tab_quitar.pressed.connect(func(): _select_guide_tab(0))
		btn_tab_poner.pressed.connect(func(): _select_guide_tab(1))
		bay_base.visible = false
		disk_panel.visible = false
		level_drive_area.visible = true
		
		# Conectar eventos de nivel
		btn_pins.pressed.connect(_on_level_pins_pressed)
		rear_screw_btn.pressed.connect(_on_level_rear_screw_pressed)
		memory_drive.gui_input.connect(_on_level_drive_gui_input)
		if btn_toggle_model:
			btn_toggle_model.pressed.connect(func():
				var next_type = "ssd" if current_drive_type == "m2" else "m2"
				set_drive_type(next_type)
			)
		
		if current_hdd_index > 0:
			_setup_level_empty_slot_phase()
			_update_level_ui_state()
			_update_slots_ui()
		else:
			_setup_level_drive_mode()

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

# =============================================================================
# MODO NIVEL: NUEVO MINIJUEGO DE MEMORIAS (M.2 / SSD NORMAL)
# =============================================================================
func _setup_level_drive_mode() -> void:
	# Selección inicial de tipo de memoria (50% probabilidad de M.2 o SSD normal solo si no viene predefinido)
	if current_drive_type == "":
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		current_drive_type = "m2" if rng.randf() > 0.5 else "ssd"
	
	_update_level_screw_visuals()
	
	if start_as_empty_slot:
		_setup_level_empty_slot_phase()
		_select_guide_tab(1)
	else:
		_setup_level_removal_phase()
		_select_guide_tab(0)
		
	_update_tool_buttons(GameManager.equipped_tool)
	_refresh_backpack_ui()

func set_drive_type(type_name: String) -> void:
	if type_name == "m2" or type_name.to_lower().contains("m.2") or type_name.to_lower().contains("nvme"):
		current_drive_type = "m2"
		memory_sprite.texture = TEX_M2
	else:
		current_drive_type = "ssd"
		memory_sprite.texture = TEX_SSD
	_update_level_ui_state()

func _update_level_screw_visuals() -> void:
	screw_icon.texture = TEX_SCREW_CRUZ if screw_type == "cruz" else TEX_SCREW_PALA
	required_tool_id = 1 if screw_type == "cruz" else 2

func _setup_level_removal_phase() -> void:
	level_phase = LevelPhase.REMOVE_SCREW
	is_pins_open = false
	
	# 1. Base / Soporte (Capa inferior z_index = 0)
	placa_base.texture = TEX_PLACA
	placa_base.z_index = 0
	
	# 2. Memoria instalada (Capa intermedia z_index = 1, alineada a la par con pines)
	memory_drive.visible = true
	memory_drive.modulate = Color(1, 1, 1, 1)
	memory_drive.position = Vector2(0.0, MEMORY_DRIVE_Y)
	memory_drive.z_index = 1
	memory_sprite.texture = TEX_M2 if current_drive_type == "m2" else TEX_SSD
	
	# 3. Pines cerrados: se ponen POR ENCIMA de la memoria (z_index = 2)
	pins_sprite.texture = TEX_PINES_CLOSED
	pins_sprite.z_index = 2
	
	# 4. Tornillo trasero colocado y visible
	rear_screw_btn.visible = true
	rear_screw_btn.disabled = false
	rear_screw_btn.modulate = Color(1, 1, 1, 1)
	rear_screw_btn.rotation_degrees = 0.0
	
	_update_level_ui_state()

func _setup_level_empty_slot_phase() -> void:
	level_phase = LevelPhase.INSERT_DRAG_LEFT
	is_pins_open = true
	
	# Si hay un repuesto en la mochila, usar su tipo
	var found_type = _get_first_unbroken_drive_type()
	if found_type != "":
		set_drive_type(found_type)
	else:
		memory_sprite.texture = TEX_M2 if current_drive_type == "m2" else TEX_SSD
		
	placa_base.texture = TEX_PLACA
	placa_base.z_index = 0
	
	# Memoria lista para colocarse (aparece a la derecha para arrastrar a la izquierda)
	memory_drive.visible = true
	memory_drive.modulate = Color(1, 1, 1, 1)
	memory_drive.position = Vector2(85.0, MEMORY_DRIVE_Y)
	memory_drive.z_index = 1
	
	# Pines abiertos: su capa pasa a estar POR DEBAJO de la memoria (z_index = 0)
	pins_sprite.texture = TEX_PINES_OPEN
	pins_sprite.z_index = 0
	
	# Sin tornillo aún
	rear_screw_btn.visible = false
	
	_update_level_ui_state()

func _get_first_unbroken_drive_type() -> String:
	for it in GameManager.backpack:
		if it.get("name") == "Disco Duro" and not it.get("broken", true):
			return it.get("drive_type", "m2")
	return ""

func _start_arrow_pulse(to_right: bool) -> void:
	if not is_instance_valid(drag_arrow_indicator):
		return
	if is_instance_valid(arrow_tween):
		arrow_tween.kill()
	drag_arrow_indicator.visible = true
	var base_x = (level_drive_area.size.x - drag_arrow_indicator.size.x) * 0.5 if level_drive_area and level_drive_area.size.x > 0 else 87.0
	var offset_x = 18.0 if to_right else -18.0
	arrow_tween = create_tween().set_loops()
	arrow_tween.tween_property(drag_arrow_indicator, "position:x", base_x + offset_x, 0.45).set_trans(Tween.TRANS_SINE)
	arrow_tween.tween_property(drag_arrow_indicator, "position:x", base_x, 0.45).set_trans(Tween.TRANS_SINE)

func _start_pin_pulse() -> void:
	if not is_instance_valid(pin_highlight_box):
		return
	if is_instance_valid(pin_pulse_tween):
		pin_pulse_tween.kill()
	pin_highlight_box.visible = true
	pin_highlight_box.modulate.a = 0.4
	pin_pulse_tween = create_tween().set_loops()
	pin_pulse_tween.tween_property(pin_highlight_box, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE)
	pin_pulse_tween.tween_property(pin_highlight_box, "modulate:a", 0.35, 0.45).set_trans(Tween.TRANS_SINE)

func _stop_pin_pulse() -> void:
	if is_instance_valid(pin_pulse_tween):
		pin_pulse_tween.kill()
	if is_instance_valid(pin_highlight_box):
		pin_highlight_box.visible = false

func _update_level_ui_state() -> void:
	var drive_name = "SSD M.2 NVMe" if current_drive_type == "m2" else "SSD SATA 2.5\""
	var tool_name = "Cruz ★ [Tecla 1]" if screw_type == "cruz" else "Pala ▬ [Tecla 2]"
	var prefix = ("BAHÍA SSD #%d DE %d · " % [current_hdd_index + 1, target_hdd_count]) if target_hdd_count > 1 else ""
	
	match level_phase:
		LevelPhase.REMOVE_SCREW:
			status_label.text = prefix + "Paso 1: Quita el tornillo trasero de la [%s] con Destornillador de %s." % [drive_name, tool_name]
			status_label.modulate = Color(1.0, 0.85, 0.2, 1)
			_stop_pin_pulse()
			if is_instance_valid(drag_arrow_indicator): drag_arrow_indicator.visible = false
			if is_instance_valid(btn_toggle_model): btn_toggle_model.visible = false
		LevelPhase.OPEN_PINS:
			status_label.text = prefix + "Paso 2: Haz clic en los PINES del zócalo (recuadro resaltado a la izquierda) para abrir la traba del puerto."
			status_label.modulate = Color(0.0, 0.95, 1.0, 1)
			_start_pin_pulse()
			if is_instance_valid(drag_arrow_indicator): drag_arrow_indicator.visible = false
			if is_instance_valid(btn_toggle_model): btn_toggle_model.visible = false
		LevelPhase.EXTRACT_DRIVE:
			status_label.text = prefix + "Paso 3: Arrastra la [%s] hacia la DERECHA para desconectarla del soporte." % drive_name
			status_label.modulate = Color(0.2, 1.0, 0.5, 1)
			_stop_pin_pulse()
			if is_instance_valid(arrow_label):
				arrow_label.text = "➔ ➔ ARRASTRA A LA DERECHA PARA EXTRAER ➔ ➔"
				arrow_label.modulate = Color(1.0, 0.9, 0.1, 1.0)
			_start_arrow_pulse(true)
			if is_instance_valid(btn_toggle_model): btn_toggle_model.visible = false
		LevelPhase.EMPTY_SLOT:
			status_label.text = prefix + "Soporte vacío. Arrastra el repuesto nuevo hacia la izquierda."
			status_label.modulate = Color(1.0, 0.85, 0.2, 1)
			_stop_pin_pulse()
			if is_instance_valid(drag_arrow_indicator): drag_arrow_indicator.visible = false
			if is_instance_valid(btn_toggle_model): btn_toggle_model.visible = false
		LevelPhase.INSERT_DRAG_LEFT:
			status_label.text = prefix + "Paso 1: Arrastra la [%s] hacia la IZQUIERDA para calzarla en el conector." % drive_name
			status_label.modulate = Color(0.0, 0.9, 1.0, 1)
			_stop_pin_pulse()
			if is_instance_valid(arrow_label):
				arrow_label.text = "◀ ◀ ARRASTRA A LA IZQUIERDA PARA CONECTAR ◀ ◀"
				arrow_label.modulate = Color(0.1, 1.0, 0.85, 1.0)
			_start_arrow_pulse(false)
			if is_instance_valid(btn_toggle_model):
				btn_toggle_model.visible = true
				btn_toggle_model.text = "🔀 CAMBIAR MODELO: M.2 NVMe ⇄ SSD SATA (Actual: %s)" % ("M.2" if current_drive_type == "m2" else "SSD")
		LevelPhase.CLOSE_PINS:
			status_label.text = prefix + "Paso 2: Haz clic en los PINES del zócalo (recuadro resaltado a la izquierda) para trabar y fijar la unidad."
			status_label.modulate = Color(1.0, 0.85, 0.2, 1)
			_start_pin_pulse()
			if is_instance_valid(drag_arrow_indicator): drag_arrow_indicator.visible = false
			if is_instance_valid(btn_toggle_model): btn_toggle_model.visible = false
		LevelPhase.INSTALL_SCREW:
			status_label.text = "Paso 3: Equipa Destornillador de %s y haz clic para ajustar el tornillo trasero." % tool_name
			status_label.modulate = Color(0.2, 1.0, 0.5, 1)
			_stop_pin_pulse()
			if is_instance_valid(drag_arrow_indicator): drag_arrow_indicator.visible = false
			if is_instance_valid(btn_toggle_model): btn_toggle_model.visible = false
		LevelPhase.COMPLETED:
			status_label.text = "✓ ¡Unidad [%s] instalada y asegurada con éxito al 100%%!" % drive_name
			status_label.modulate = Color(0.0, 1.0, 0.4, 1)
			_stop_pin_pulse()
			if is_instance_valid(drag_arrow_indicator): drag_arrow_indicator.visible = false
			if is_instance_valid(btn_toggle_model): btn_toggle_model.visible = false

func _on_level_rear_screw_pressed() -> void:
	if GameManager.equipped_tool == 0:
		GameManager.select_tool(required_tool_id)
		
	if GameManager.equipped_tool != required_tool_id:
		GameManager.register_error(2.0)
		var expected = "CRUZ / ESTRELLA (Tecla 1)" if screw_type == "cruz" else "PALA / PLANO (Tecla 2)"
		status_label.text = "¡Herramienta incorrecta! Este tornillo requiere %s." % expected
		status_label.modulate = Color(1, 0.2, 0.3, 1)
		_shake_node(rear_screw_btn)
		return
		
	if level_phase == LevelPhase.REMOVE_SCREW:
		# Girar y desvanecer tornillo
		rear_screw_btn.disabled = true
		var tw = create_tween().set_parallel(true)
		tw.tween_property(rear_screw_btn, "rotation_degrees", 360.0, 0.25)
		tw.tween_property(rear_screw_btn, "modulate:a", 0.0, 0.25)
		tw.chain().tween_callback(func():
			rear_screw_btn.visible = false
			level_phase = LevelPhase.OPEN_PINS
			_update_level_ui_state()
		)
	elif level_phase == LevelPhase.INSTALL_SCREW:
		# Ajustar tornillo con éxito
		rear_screw_btn.disabled = true
		var tw = create_tween().set_parallel(true)
		tw.tween_property(rear_screw_btn, "rotation_degrees", -360.0, 0.25)
		tw.tween_property(rear_screw_btn, "modulate", Color(0.2, 1.3, 0.5, 1.0), 0.2)
		tw.chain().tween_callback(func():
			_consume_replacement_from_backpack()
			if current_hdd_index < hdd_installed_states.size():
				hdd_installed_states[current_hdd_index] = true
			current_hdd_index += 1
			_update_slots_ui()
			
			if current_hdd_index < target_hdd_count:
				status_label.text = "✓ ¡SSD/M.2 #%d INSTALADO! Haz clic en 'BAHÍA SSD #%d' a la derecha para continuar." % [current_hdd_index, current_hdd_index + 1]
				status_label.modulate = Color(0.2, 1.0, 0.4)
			else:
				level_phase = LevelPhase.COMPLETED
				_update_level_ui_state()
				await get_tree().create_timer(0.5).timeout
				minigame_finished.emit(true)
		)

func _on_level_pins_pressed() -> void:
	if level_phase == LevelPhase.REMOVE_SCREW:
		GameManager.register_error(1.0)
		status_label.text = "¡Atascado! Primero debes retirar el tornillo trasero con el destornillador."
		status_label.modulate = Color(1, 0.2, 0.3, 1)
		_shake_node(rear_screw_btn)
		return
		
	if level_phase == LevelPhase.OPEN_PINS:
		# Abrir pines: cambia a pines abiertos y su capa pasa a estar POR DEBAJO de la memoria (z_index = 0)
		is_pins_open = true
		pins_sprite.texture = TEX_PINES_OPEN
		pins_sprite.z_index = 0
		level_phase = LevelPhase.EXTRACT_DRIVE
		
		# Pulso visual en los pines
		var tw = create_tween()
		tw.tween_property(pins_sprite, "modulate", Color(1.5, 1.5, 0.3, 1.0), 0.1)
		tw.tween_property(pins_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
		
		_update_level_ui_state()
		
	elif level_phase == LevelPhase.CLOSE_PINS:
		# Cerrar pines: cambia a pines cerrados y su capa pasa a estar POR ENCIMA de la memoria (z_index = 2)
		is_pins_open = false
		pins_sprite.texture = TEX_PINES_CLOSED
		pins_sprite.z_index = 2
		level_phase = LevelPhase.INSTALL_SCREW
		
		# Aparece el tornillo trasero listo para ajustar
		rear_screw_btn.visible = true
		rear_screw_btn.disabled = false
		rear_screw_btn.rotation_degrees = 0.0
		rear_screw_btn.modulate = Color(1, 1, 1, 0.0)
		var tw = create_tween()
		tw.tween_property(rear_screw_btn, "modulate:a", 1.0, 0.2)
		
		_update_level_ui_state()

func _on_level_drive_gui_input(event: InputEvent) -> void:
	if level_phase == LevelPhase.OPEN_PINS:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			status_label.text = "¡El puerto está trabado! Haz clic en el recuadro resaltado de los PINES a la izquierda."
			status_label.modulate = Color(1.0, 0.35, 0.45, 1.0)
			_start_pin_pulse()
			if is_instance_valid(pin_highlight_box):
				_shake_node(pin_highlight_box)
			return

	if level_phase == LevelPhase.EXTRACT_DRIVE:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging_level_drive = true
				drag_level_start_x = event.global_position.x
			else:
				if is_dragging_level_drive:
					is_dragging_level_drive = false
					var diff_x = event.global_position.x - drag_level_start_x
					if diff_x >= 40.0:
						_complete_level_drive_extraction()
					else:
						var tw = create_tween()
						tw.tween_property(memory_drive, "position", Vector2(0.0, MEMORY_DRIVE_Y), 0.15)
		elif event is InputEventMouseMotion and is_dragging_level_drive:
			var pull = clamp(event.global_position.x - drag_level_start_x, 0.0, 120.0)
			memory_drive.position = Vector2(pull, MEMORY_DRIVE_Y)
			
	elif level_phase == LevelPhase.INSERT_DRAG_LEFT:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging_level_drive = true
				drag_level_start_x = event.global_position.x
			else:
				if is_dragging_level_drive:
					is_dragging_level_drive = false
					var diff_x = drag_level_start_x - event.global_position.x
					if diff_x >= 35.0:
						_seat_level_drive()
					else:
						var tw = create_tween()
						tw.tween_property(memory_drive, "position", Vector2(85.0, MEMORY_DRIVE_Y), 0.15)
		elif event is InputEventMouseMotion and is_dragging_level_drive:
			var push = clamp(drag_level_start_x - event.global_position.x, 0.0, 85.0)
			memory_drive.position = Vector2(85.0 - push, MEMORY_DRIVE_Y)

func _complete_level_drive_extraction() -> void:
	var tw = create_tween()
	tw.tween_property(memory_drive, "position:x", 250.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(memory_drive, "modulate:a", 0.0, 0.22)
	tw.tween_callback(func():
		memory_drive.visible = false
		
		# Agregar memoria dañada a la mochila
		var display = "SSD M.2 NVMe (Dañado)" if current_drive_type == "m2" else "SSD SATA 2.5\" (Dañado)"
		GameManager.add_item_to_backpack({
			"name": "Disco Duro",
			"type": "Disco Duro",
			"drive_type": current_drive_type,
			"display_name": display,
			"broken": true,
			"functional": false
		})
		old_part_extracted.emit()
		
		status_label.text = "✓ ¡Unidad %s averiada extraída con éxito! Busca el repuesto en el taller." % ("M.2" if current_drive_type == "m2" else "SSD")
		status_label.modulate = Color(0.2, 1.0, 0.5, 1)
		await get_tree().create_timer(1.1).timeout
		minigame_finished.emit(true)
	)

func _seat_level_drive() -> void:
	is_ssd_in_pins = true
	var tw = create_tween()
	tw.tween_property(memory_drive, "position", Vector2(0.0, MEMORY_DRIVE_Y), 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		level_phase = LevelPhase.CLOSE_PINS
		_update_level_ui_state()
	)

func _consume_replacement_from_backpack() -> void:
	var removed_idx = -1
	for i in range(GameManager.backpack.size()):
		var it = GameManager.backpack[i]
		if it.get("name") == "Disco Duro" and not it.get("broken", true):
			if it.get("drive_type", "") == current_drive_type:
				removed_idx = i
				break
			elif removed_idx == -1:
				removed_idx = i
	if removed_idx != -1:
		GameManager.remove_item_from_backpack(removed_idx)

# =============================================================================
# MODO TUTORIAL (LÓGICA ORIGINAL)
# =============================================================================
func _select_guide_tab(idx: int) -> void:
	if is_instance_valid(btn_tab_quitar) and is_instance_valid(btn_tab_poner):
		if idx == 0:
			btn_tab_quitar.modulate = Color(1.2, 1.2, 0.4, 1.0)
			btn_tab_poner.modulate = Color(0.7, 0.7, 0.7, 0.7)
		else:
			btn_tab_quitar.modulate = Color(0.7, 0.7, 0.7, 0.7)
			btn_tab_poner.modulate = Color(0.2, 1.0, 0.5, 1.0)
			
	if initial_installed_count > 0:
		for k in range(min(initial_installed_count, hdd_installed_states.size())):
			hdd_installed_states[k] = true
		current_hdd_index = initial_installed_count
		
	if is_tutorial_mode:
		guide_text.text = "INSTRUCCIONES DE MONTAJE:\n1. Coloca el disco nuevo en la bahía.\n2. Arrástralo hacia abajo hasta calzar.\n3. Ajusta el tornillo de sujeción."
		if current_state == State.UNSCREW or current_state == State.EXTRACT_DRAG_UP:
			_setup_empty_bay_phase()
	else:
		var has_hdd = false
		for it in GameManager.backpack:
			if it.get("name") == "Disco Duro" and not it.get("broken", true):
				has_hdd = true
				break
		var spare_msg = "✓ Unidad SSD / M.2 detectada en inventario.\n\n" if has_hdd else "⚠️ Listo para montar repuesto.\n\n"
		guide_text.text = "INSTRUCCIONES DE MONTAJE:\n\n" + spare_msg + "1. Arrastra la memoria hacia el puerto hasta calzar en los pines.\n2. Clic en los pines para asegurar.\n3. Coloca el tornillo de fijación trasero."

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
				var d_type = item.get("drive_type", "")
				var lbl = ("M.2 (Dañado)" if d_type == "m2" else "SSD (Dañado)") if d_type != "" else "HDD (Dañado)"
				item_btn.text = "%d. %s" % [i + 1, lbl]
				item_btn.modulate = Color(1, 0.3, 0.4, 0.85)
				item_btn.disabled = true
			else:
				found_hdd = true
				var d_type = item.get("drive_type", current_drive_type)
				var d_name = "SSD M.2 NVMe" if d_type == "m2" else "SATA SSD 2.5\""
				item_btn.text = "⇪ %s (NUEVO)\n[Clic: Cambiar M.2 / SSD]" % d_name
				item_btn.modulate = Color(0.0, 1.0, 0.6, 1.0)
				
				item_btn.pressed.connect(func():
					if not is_tutorial_mode:
						var next_t = "ssd" if current_drive_type == "m2" else "m2"
						set_drive_type(next_t)
						item["drive_type"] = next_t
						_refresh_backpack_ui()
					else:
						_insert_hdd_from_backpack(i)
				)
				
				item_btn.gui_input.connect(func(event: InputEvent):
					if is_tutorial_mode and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
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
		
	if not is_tutorial_mode:
		if found_hdd:
			backpack_hint.text = "¡Haz clic en la memoria para elegir modelo (M.2 o SSD)!"
			backpack_hint.modulate = Color(0.0, 1.0, 0.5, 1.0)
		else:
			backpack_hint.text = "No tienes memoria en la mochila.\nSal de la PC y ve a la caja de repuestos."
			backpack_hint.modulate = Color(1.0, 0.4, 0.4, 1.0)
	else:
		if current_state == State.EMPTY_BAY:
			if found_hdd:
				backpack_hint.text = "¡Arrastra el Disco Duro nuevo a la bahía o haz clic!"
				backpack_hint.modulate = Color(0.0, 1.0, 0.5, 1.0)
			else:
				backpack_hint.text = "No tienes Disco Duro nuevo en la mochila.\nSal de la PC y ve a la caja de repuestos."
				backpack_hint.modulate = Color(1.0, 0.4, 0.4, 1.0)

func _update_ui_state() -> void:
	if not is_tutorial_mode:
		_update_level_ui_state()
		return
		
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
			if target_hdd_count > 1:
				status_label.text = "BAHÍA SAS CADDY #%d DE %d · Arrastra el Disco Duro nuevo desde tu mochila hacia la bahía." % [current_hdd_index + 1, target_hdd_count]
			else:
				status_label.text = "Bahía vacía. Arrastra el Disco Duro nuevo desde tu mochila hacia la bahía."
			status_label.modulate = Color(1.0, 0.85, 0.2, 1)
			_refresh_backpack_ui()
		State.INSERT_DRAG_DOWN:
			var prefix = ("BAHÍA SAS #%d: " % [current_hdd_index + 1]) if target_hdd_count > 1 else "Paso 3 (A la inversa): "
			status_label.text = prefix + "Arrastra el Disco Duro hacia ABAJO para encajarlo."
			status_label.modulate = Color(0.0, 0.9, 1.0, 1)
			disk_drag_label.text = "▼ ARRASTRA HACIA ABAJO\nPARA CALZAR EN BAHÍA ▼"
			disk_drag_label.modulate = Color(0, 0.95, 1, 1)
			screw_container.visible = false
		State.SCREW_BACK:
			var tool_name = "Tecla 1 (Cruz ★)" if screw_type == "cruz" else "Tecla 2 (Pala ▬)"
			var prefix = ("BAHÍA SAS #%d: " % [current_hdd_index + 1]) if target_hdd_count > 1 else "Paso 4: "
			status_label.text = prefix + "Con %s, haz clic en el tornillo para ajustar el seguro." % tool_name
			status_label.modulate = Color(1.0, 0.85, 0.2, 1)
			disk_drag_label.text = "SATA/SAS SSD [CALZADO]\n(Ajusta el tornillo de seguridad)"
			disk_drag_label.modulate = Color(0, 1, 0.6, 1)
			screw_container.visible = true
			btn_screw.visible = true
			btn_screw.disabled = false
			btn_screw.modulate = Color(1, 1, 1, 1)
		State.COMPLETED:
			status_label.text = ("¡LOS %d DISCOS SAS CADDIES MONTADOS Y ASEGURADOS CON ÉXITO!" % target_hdd_count) if target_hdd_count > 1 else "¡Disco Duro reemplazado y asegurado con éxito!"
			status_label.modulate = Color(0.0, 1.0, 0.4, 1)

func _on_screw_pressed() -> void:
	if GameManager.equipped_tool == 0:
		GameManager.select_tool(required_tool_id)
		
	if GameManager.equipped_tool != required_tool_id:
		GameManager.register_error(2.0)
		var expected = "CRUZ / ESTRELLA (Tecla 1)" if screw_type == "cruz" else "PALA / PLANO (Tecla 2)"
		status_label.text = "¡Herramienta incorrecta! Este tornillo es de %s." % expected
		status_label.modulate = Color(1, 0.2, 0.3, 1)
		return
		
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
		hdd_installed_states[current_hdd_index] = true
		current_hdd_index += 1
		
		if current_hdd_index < target_hdd_count:
			status_label.text = "✓ ¡DISCO SAS CADDY #%d ATORNILLADO Y FIJADO! Haz clic en la BAHÍA #%d a la derecha para continuar." % [current_hdd_index, current_hdd_index + 1]
			status_label.modulate = Color(0.2, 1.0, 0.4)
			_update_slots_ui()
		else:
			current_state = State.COMPLETED
			_update_ui_state()
			_update_slots_ui()
			var tween = create_tween()
			tween.tween_interval(0.5)
			tween.tween_callback(func():
				minigame_finished.emit(true)
			)

func _on_slot_button_clicked(idx: int) -> void:
	if idx == current_hdd_index and current_hdd_index < target_hdd_count and not hdd_installed_states[idx]:
		if is_tutorial_mode:
			_prepare_next_hdd_bay()
		else:
			_prepare_next_level_drive_slot()

func _prepare_next_level_drive_slot() -> void:
	var has_hdd = false
	for it in GameManager.backpack:
		if it.get("name") == "Disco Duro" and not it.get("broken", true):
			has_hdd = true
			break
	_setup_level_empty_slot_phase()
	_update_level_ui_state()
	_update_slots_ui()
	_refresh_backpack_ui()
	if not has_hdd:
		status_label.text = "⚠️ FALTA DISCO SSD EN MOCHILA · SAL [ESC] PARA RECOGERLO (PROGRESO: %d/%d)" % [current_hdd_index, target_hdd_count]
		status_label.modulate = Color(1.0, 0.4, 0.4)

func _prepare_next_hdd_bay() -> void:
	var has_hdd = false
	for it in GameManager.backpack:
		if it.get("name") == "Disco Duro" and not it.get("broken", true):
			has_hdd = true
			break
	
	disk_panel.visible = false
	empty_bay_label.visible = true
	screw_container.visible = false
	btn_screw.visible = false
	btn_screw.disabled = false
	btn_screw.rotation_degrees = 0.0
	btn_screw.modulate = Color(1, 1, 1, 1)
	current_state = State.EMPTY_BAY
	_update_ui_state()
	_update_slots_ui()
	_refresh_backpack_ui()
	if not has_hdd:
		status_label.text = "⚠️ FALTA DISCO SSD EN MOCHILA · SAL [ESC] PARA RECOGERLO (PROGRESO: %d/%d)" % [current_hdd_index, target_hdd_count]
		status_label.modulate = Color(1.0, 0.4, 0.4)
	_update_ui_state()
	_update_slots_ui()
	_refresh_backpack_ui()

func _update_slots_ui() -> void:
	if target_hdd_count <= 1 or not is_instance_valid(slots_container):
		return
	var buttons = [btn_slot_0, btn_slot_1, btn_slot_2]
	for i in range(buttons.size()):
		var btn = buttons[i]
		if not is_instance_valid(btn):
			continue
		if i >= target_hdd_count:
			btn.visible = false
			continue
		btn.visible = true
		if hdd_installed_states[i]:
			btn.text = "✓ BAHÍA SAS/SSD #%d [INSTALADA]" % (i + 1)
			btn.modulate = Color(0.2, 1.0, 0.45)
			btn.disabled = false
		elif i == current_hdd_index:
			if current_state == State.EMPTY_BAY or current_state == State.INSERT_DRAG_DOWN:
				btn.text = "➔ BAHÍA SAS #%d (EN MONTAJE)" % (i + 1)
				btn.modulate = Color(0.0, 0.95, 1.0)
				btn.disabled = false
			else:
				btn.text = "➔ CLIC PARA MONTAR BAHÍA #%d" % (i + 1)
				btn.modulate = Color(1.0, 0.85, 0.2)
				btn.disabled = false
		else:
			btn.text = "🔒 BAHÍA SAS #%d [PENDIENTE]" % (i + 1)
			btn.modulate = Color(0.55, 0.6, 0.7, 0.6)
			btn.disabled = true

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

func _shake_node(n: Control) -> void:
	var orig_x = n.position.x
	var tw = create_tween()
	tw.tween_property(n, "position:x", orig_x - 6.0, 0.04)
	tw.tween_property(n, "position:x", orig_x + 6.0, 0.04)
	tw.tween_property(n, "position:x", orig_x - 3.0, 0.04)
	tw.tween_property(n, "position:x", orig_x, 0.04)
