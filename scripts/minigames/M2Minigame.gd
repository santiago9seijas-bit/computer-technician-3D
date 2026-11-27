extends CanvasLayer

# =============================================================================
# MINIJUEGO: DESMONTAJE Y MONTAJE DE UNIDAD M.2 NVMe / SSD SATA
# Utiliza los sprites oficiales de la carpeta memoriastipos:
# - placa.png (soporte de placa base)
# - memoria M.2.png y memoria.png (SSD SATA)
# - pines de memoria.png (cerrados) / pines de memoria abiertos.png
# =============================================================================

signal minigame_finished(success: bool)
signal old_part_extracted()

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

var level_phase: LevelPhase = LevelPhase.REMOVE_SCREW
var start_as_empty_slot: bool = false
var is_tutorial_mode: bool = false
var current_drive_type: String = "m2" # "m2" o "ssd"

var screw_type: String = "cruz"
var required_tool_id: int = 1

# Dragging variables
var is_dragging_level_drive: bool = false
var drag_level_start_x: float = 0.0
var is_pins_open: bool = false
var arrow_tween: Tween = null

# Texturas oficiales
const TEX_PLACA = preload("res://pixel art minijuegos/memoriastipos/soporte para ssd/placa.png")
const TEX_M2 = preload("res://pixel art minijuegos/memoriastipos/m.2/memoria M.2.png")
const TEX_SSD = preload("res://pixel art minijuegos/memoriastipos/ssd/memoria.png")
const TEX_PINES_CLOSED = preload("res://pixel art minijuegos/memoriastipos/soporte para ssd/pines de memoria.png")
const TEX_PINES_OPEN = preload("res://pixel art minijuegos/memoriastipos/soporte para ssd/pines de memoria abiertos.png")
const TEX_SCREW_CRUZ = preload("res://pixel art minijuegos/tornillos/tornillo de cruz.png")
const TEX_SCREW_PALA = preload("res://pixel art minijuegos/tornillos/tornillo de pala.png")

# Nodos
@onready var modal_control: Control = $ModalControl
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var btn_tool_1: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool1
@onready var btn_tool_2: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool2
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel

@onready var level_drive_area: Control = $ModalControl/Panel/VBox/WorkArea/LevelDriveArea
@onready var placa_base: TextureRect = $ModalControl/Panel/VBox/WorkArea/LevelDriveArea/PlacaBase
@onready var memory_drive: Control = $ModalControl/Panel/VBox/WorkArea/LevelDriveArea/MemoryDrive
@onready var memory_sprite: TextureRect = $ModalControl/Panel/VBox/WorkArea/LevelDriveArea/MemoryDrive/MemorySprite
@onready var pins_sprite: TextureRect = $ModalControl/Panel/VBox/WorkArea/LevelDriveArea/PinsSprite
@onready var btn_pins: Button = $ModalControl/Panel/VBox/WorkArea/LevelDriveArea/BtnPins
@onready var rear_screw_btn: Button = $ModalControl/Panel/VBox/WorkArea/LevelDriveArea/RearScrewBtn
@onready var screw_icon: TextureRect = $ModalControl/Panel/VBox/WorkArea/LevelDriveArea/RearScrewBtn/ScrewIcon
@onready var drag_arrow_indicator: PanelContainer = $ModalControl/Panel/VBox/WorkArea/LevelDriveArea/DragArrowIndicator
@onready var arrow_label: Label = $ModalControl/Panel/VBox/WorkArea/LevelDriveArea/DragArrowIndicator/ArrowLabel
@onready var btn_toggle_model: Button = $ModalControl/Panel/VBox/WorkArea/LevelDriveArea/BtnToggleModel

func _ready() -> void:
	layer = 12
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	btn_tool_1.pressed.connect(func(): GameManager.select_tool(1))
	btn_tool_2.pressed.connect(func(): GameManager.select_tool(2))
	GameManager.tool_selected.connect(_on_tool_selected)
	
	btn_pins.pressed.connect(_on_level_pins_pressed)
	rear_screw_btn.pressed.connect(_on_level_rear_screw_pressed)
	memory_drive.gui_input.connect(_on_level_drive_gui_input)
	
	if btn_toggle_model:
		btn_toggle_model.pressed.connect(func():
			var next_type = "ssd" if current_drive_type == "m2" else "m2"
			set_drive_type(next_type)
		)
		
	if screw_type == "":
		screw_type = "cruz"
	_update_level_screw_visuals()
	
	if start_as_empty_slot:
		_setup_level_empty_slot_phase()
	else:
		_setup_level_removal_phase()
		
	_update_tool_buttons(GameManager.equipped_tool)

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

func _on_tool_selected(tool_id: int) -> void:
	_update_tool_buttons(tool_id)

func _update_tool_buttons(tool_id: int) -> void:
	if btn_tool_1:
		btn_tool_1.modulate = Color(1.2, 1.2, 0.4) if tool_id == 1 else Color(0.85, 0.85, 0.85)
	if btn_tool_2:
		btn_tool_2.modulate = Color(1.2, 1.2, 0.4) if tool_id == 2 else Color(0.85, 0.85, 0.85)

func set_drive_type(type_name: String) -> void:
	if type_name == "m2" or type_name.to_lower().contains("m.2") or type_name.to_lower().contains("nvme"):
		current_drive_type = "m2"
		if memory_sprite: memory_sprite.texture = TEX_M2
	else:
		current_drive_type = "ssd"
		if memory_sprite: memory_sprite.texture = TEX_SSD
	_update_level_ui_state()

func _update_level_screw_visuals() -> void:
	if is_instance_valid(screw_icon):
		screw_icon.texture = TEX_SCREW_CRUZ if screw_type == "cruz" else TEX_SCREW_PALA
	required_tool_id = 2 if screw_type == "cruz" else 1

func _setup_level_removal_phase() -> void:
	level_phase = LevelPhase.REMOVE_SCREW
	is_pins_open = false
	
	# 1. Base / Soporte (Capa inferior z_index = 0)
	placa_base.texture = TEX_PLACA
	placa_base.z_index = 0
	
	# 2. Memoria instalada (Capa intermedia z_index = 1, centrada perfectamente en la placa)
	memory_drive.visible = true
	memory_drive.modulate = Color(1, 1, 1, 1)
	memory_drive.position = Vector2(0.0, 0.0)
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
	
	placa_base.texture = TEX_PLACA
	placa_base.z_index = 0
	
	# Memoria lista para colocarse (aparece a la derecha para arrastrar a la izquierda)
	memory_drive.visible = true
	memory_drive.modulate = Color(1, 1, 1, 1)
	memory_drive.position = Vector2(85.0, 0.0)
	memory_drive.z_index = 1
	memory_sprite.texture = TEX_M2 if current_drive_type == "m2" else TEX_SSD
	
	# Pines abiertos: su capa pasa a estar POR DEBAJO de la memoria (z_index = 0)
	pins_sprite.texture = TEX_PINES_OPEN
	pins_sprite.z_index = 0
	
	rear_screw_btn.visible = false
	_update_level_ui_state()

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

func _stop_arrow_pulse() -> void:
	if is_instance_valid(arrow_tween):
		arrow_tween.kill()
	if is_instance_valid(drag_arrow_indicator):
		drag_arrow_indicator.visible = false

func _update_level_ui_state() -> void:
	var drive_name = "SSD M.2 NVMe" if current_drive_type == "m2" else "SSD SATA 2.5\""
	var tool_name = "Cruz ★ [Tecla 1]" if screw_type == "cruz" else "Pala ▬ [Tecla 2]"
	
	match level_phase:
		LevelPhase.REMOVE_SCREW:
			status_label.text = "Paso 1: Quita el tornillo trasero de la [%s] con Destornillador de %s." % [drive_name, tool_name]
			status_label.modulate = Color(1.0, 0.85, 0.2, 1)
			_stop_arrow_pulse()
			if is_instance_valid(btn_toggle_model): btn_toggle_model.visible = false
		LevelPhase.OPEN_PINS:
			status_label.text = "Paso 2: Haz clic sobre el PIN del conector (izquierda) para abrir la traba."
			status_label.modulate = Color(0.0, 0.9, 1.0, 1)
			_stop_arrow_pulse()
			if is_instance_valid(btn_toggle_model): btn_toggle_model.visible = false
		LevelPhase.EXTRACT_DRIVE:
			status_label.text = "Paso 3: Arrastra la [%s] hacia la DERECHA para desconectarla del soporte." % drive_name
			status_label.modulate = Color(0.2, 1.0, 0.5, 1)
			if is_instance_valid(arrow_label):
				arrow_label.text = "➔ ➔ ARRASTRA A LA DERECHA PARA EXTRAER ➔ ➔"
				arrow_label.modulate = Color(1.0, 0.9, 0.1, 1.0)
			_start_arrow_pulse(true)
			if is_instance_valid(btn_toggle_model): btn_toggle_model.visible = false
		LevelPhase.EMPTY_SLOT:
			status_label.text = "Soporte vacío. Arrastra el repuesto nuevo hacia la izquierda."
			status_label.modulate = Color(1.0, 0.85, 0.2, 1)
			_stop_arrow_pulse()
			if is_instance_valid(btn_toggle_model): btn_toggle_model.visible = false
		LevelPhase.INSERT_DRAG_LEFT:
			status_label.text = "Paso 1: Arrastra la [%s] hacia la IZQUIERDA para calzarla en el conector." % drive_name
			status_label.modulate = Color(0.0, 0.9, 1.0, 1)
			if is_instance_valid(arrow_label):
				arrow_label.text = "◀ ◀ ARRASTRA A LA IZQUIERDA PARA CONECTAR ◀ ◀"
				arrow_label.modulate = Color(0.1, 1.0, 0.85, 1.0)
			_start_arrow_pulse(false)
			if is_instance_valid(btn_toggle_model):
				btn_toggle_model.visible = true
				btn_toggle_model.text = "🔀 MODELO: M.2 NVMe ⇄ SSD SATA (Actual: %s)" % ("M.2" if current_drive_type == "m2" else "SSD")
		LevelPhase.CLOSE_PINS:
			status_label.text = "Paso 2: Haz clic sobre el PIN del conector para cerrarlo y asegurar el puerto."
			status_label.modulate = Color(1.0, 0.85, 0.2, 1)
			_stop_arrow_pulse()
			if is_instance_valid(btn_toggle_model): btn_toggle_model.visible = false
		LevelPhase.INSTALL_SCREW:
			status_label.text = "Paso 3: Equipa Destornillador de %s y haz clic para ajustar el tornillo trasero." % tool_name
			status_label.modulate = Color(0.2, 1.0, 0.5, 1)
			_stop_arrow_pulse()
			if is_instance_valid(btn_toggle_model): btn_toggle_model.visible = false
		LevelPhase.COMPLETED:
			status_label.text = "✓ ¡Unidad [%s] instalada y asegurada con éxito al 100%%!" % drive_name
			status_label.modulate = Color(0.0, 1.0, 0.4, 1)
			_stop_arrow_pulse()
			if is_instance_valid(btn_toggle_model): btn_toggle_model.visible = false

func _on_level_rear_screw_pressed() -> void:
	if GameManager.equipped_tool == 0:
		GameManager.select_tool(required_tool_id)
		
	if GameManager.equipped_tool != required_tool_id:
		GameManager.register_error(2.0)
		var expected = "CRUZ / ESTRELLA (Tecla 2)" if screw_type == "cruz" else "PALA / PLANO (Tecla 1)"
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
			level_phase = LevelPhase.COMPLETED
			_update_level_ui_state()
			await get_tree().create_timer(0.6).timeout
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
						tw.tween_property(memory_drive, "position:x", 0.0, 0.15)
		elif event is InputEventMouseMotion and is_dragging_level_drive:
			var pull = clamp(event.global_position.x - drag_level_start_x, 0.0, 120.0)
			memory_drive.position.x = pull
			memory_drive.position.y = 0.0
			
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
						tw.tween_property(memory_drive, "position:x", 85.0, 0.15)
		elif event is InputEventMouseMotion and is_dragging_level_drive:
			var push = clamp(drag_level_start_x - event.global_position.x, 0.0, 85.0)
			memory_drive.position.x = 85.0 - push
			memory_drive.position.y = 0.0

func _complete_level_drive_extraction() -> void:
	var tw = create_tween()
	tw.tween_property(memory_drive, "position:x", 250.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(memory_drive, "modulate:a", 0.0, 0.22)
	tw.tween_callback(func():
		memory_drive.visible = false
		
		# Agregar memoria averiada a la mochila
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
		
		status_label.text = "✓ ¡Unidad averiada retirada! Sal y busca el repuesto nuevo en la caja del taller."
		status_label.modulate = Color(0.2, 1.0, 0.5, 1)
		await get_tree().create_timer(0.7).timeout
		minigame_finished.emit(true)
	)

func _seat_level_drive() -> void:
	# Si existe un repuesto funcional en la mochila, descontarlo
	for i in range(GameManager.backpack.size()):
		var it = GameManager.backpack[i]
		if (it.get("name") == "Disco Duro" or it.get("type") == "Disco Duro") and not it.get("broken", true):
			GameManager.remove_item_from_backpack(i)
			break

	var tw = create_tween()
	tw.tween_property(memory_drive, "position:x", 0.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		level_phase = LevelPhase.CLOSE_PINS
		_update_level_ui_state()
	)

func _shake_node(target: CanvasItem) -> void:
	if not is_instance_valid(target):
		return
	var orig = target.position
	var tw = create_tween()
	tw.tween_property(target, "position:x", orig.x - 6.0, 0.04)
	tw.tween_property(target, "position:x", orig.x + 6.0, 0.04)
	tw.tween_property(target, "position:x", orig.x - 3.0, 0.04)
	tw.tween_property(target, "position:x", orig.x + 3.0, 0.04)
	tw.tween_property(target, "position:x", orig.x, 0.04)
