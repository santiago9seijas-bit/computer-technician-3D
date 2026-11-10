extends CanvasLayer

# =============================================================================
# MINIJUEGO: DESMONTAJE DE TARJETA GRÁFICA (GPU)
# Enseña:
# 1. Desconectar cable PCIe (8-pin) con seguro.
# 2. Retirar tornillos del bracket metálico del chasis (Cruz o Pala).
# 3. Abrir el pestillo/palanca de retención PCIe de la placa madre.
# 4. Extraer la GPU verticalmente sin torsionar el bus.
# =============================================================================

signal minigame_finished(success: bool)
signal old_part_extracted()

enum State {
	DISCONNECT_POWER,
	UNSCREW_BRACKET,
	RELEASE_LATCH,
	EXTRACT_GPU,
	EMPTY_SLOT,
	LATCH_NEW_GPU,
	SCREW_NEW_BRACKET,
	CONNECT_NEW_POWER,
	COMPLETED
}

var current_state: State = State.DISCONNECT_POWER
var start_as_empty_slot: bool = false
var is_tutorial_mode: bool = false
@export var target_gpu_count: int = 1 # Servidor requiere 3 aceleradores
@export var initial_installed_count: int = 0
var current_gpu_index: int = 0

func get_installed_count() -> int:
	return current_gpu_index

# Estado de los tornillos del bracket (2 tornillos)
var screw_types: Array[String] = ["cruz", "cruz"]
var screws_removed: Array[bool] = [false, false]

# Estado de seguros
var is_power_disconnected: bool = false
var is_pcie_latch_unlocked: bool = false
var is_extracted: bool = false

const CABLE_Y_CONNECTED: float = 65.0
const CABLE_Y_DISCONNECTED: float = 15.0

var is_dragging_gpu: bool = false
var drag_start_y: float = 0.0

# Texturas
var tex_screw_cruz = preload("res://pixel art minijuegos/tornillos/tornillo de cruz.png")
var tex_screw_pala = preload("res://pixel art minijuegos/tornillos/tornillo de pala.png")

# Nodos
@onready var modal_control: Control = $ModalControl
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var btn_tool_1: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool1
@onready var btn_tool_2: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool2
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel

@onready var work_area: Control = $ModalControl/Panel/VBox/WorkArea
@onready var gpu_container: Control = $ModalControl/Panel/VBox/WorkArea/GPUContainer
@onready var pcie_latch_btn: Button = $ModalControl/Panel/VBox/WorkArea/PCIeSlot/BtnLatch
@onready var latch_status_label: Label = $ModalControl/Panel/VBox/WorkArea/PCIeSlot/LatchStatus

@onready var cable_container: Control = $ModalControl/Panel/VBox/WorkArea/CableContainer
@onready var btn_cable_clip: Button = $ModalControl/Panel/VBox/WorkArea/CableContainer/BtnCableClip
@onready var cable_hint: Label = $ModalControl/Panel/VBox/WorkArea/CableContainer/CableHint

@onready var btn_screw_1: Button = $ModalControl/Panel/VBox/WorkArea/GPUContainer/BracketArea/Screw1
@onready var btn_screw_2: Button = $ModalControl/Panel/VBox/WorkArea/GPUContainer/BracketArea/Screw2
@onready var icon_screw_1: TextureRect = $ModalControl/Panel/VBox/WorkArea/GPUContainer/BracketArea/Screw1/Icon
@onready var icon_screw_2: TextureRect = $ModalControl/Panel/VBox/WorkArea/GPUContainer/BracketArea/Screw2/Icon

@onready var btn_extract: Button = $ModalControl/Panel/VBox/WorkArea/BtnExtractGPU
@onready var warning_label: Label = $ModalControl/Panel/VBox/WorkArea/WarningLabel

@onready var btn_tab_quitar: Button = $ModalControl/Panel/VBox/WorkArea/RightGuidePanel/Margin/VBoxGuide/TabsBox/BtnTabQuitar
@onready var btn_tab_poner: Button = $ModalControl/Panel/VBox/WorkArea/RightGuidePanel/Margin/VBoxGuide/TabsBox/BtnTabPoner
@onready var guide_text: Label = $ModalControl/Panel/VBox/WorkArea/RightGuidePanel/Margin/VBoxGuide/GuideText

@onready var chk_power: Label = $ModalControl/Panel/VBox/WorkArea/RightGuidePanel/Margin/VBoxGuide/ChecklistContainer/ChkPower
@onready var chk_bracket: Label = $ModalControl/Panel/VBox/WorkArea/RightGuidePanel/Margin/VBoxGuide/ChecklistContainer/ChkBracket
@onready var chk_latch: Label = $ModalControl/Panel/VBox/WorkArea/RightGuidePanel/Margin/VBoxGuide/ChecklistContainer/ChkLatch
@onready var chk_extract: Label = $ModalControl/Panel/VBox/WorkArea/RightGuidePanel/Margin/VBoxGuide/ChecklistContainer/ChkExtract

func _ready() -> void:
	layer = 12
	_setup_screws()
	_setup_ui()
	_update_tool_buttons()
	
	if is_instance_valid(btn_tab_quitar) and is_instance_valid(btn_tab_quitar.get_parent()):
		btn_tab_quitar.get_parent().visible = false
	if is_instance_valid(btn_tab_quitar):
		btn_tab_quitar.pressed.connect(func(): _select_guide_tab(0))
	if is_instance_valid(btn_tab_poner):
		btn_tab_poner.pressed.connect(func(): _select_guide_tab(1))
	
	pcie_latch_btn.pivot_offset = Vector2(35, 14)
	
	if initial_installed_count > 0:
		current_gpu_index = initial_installed_count
		_prepare_next_gpu_slot()
		_select_guide_tab(1)
	elif start_as_empty_slot:
		current_state = State.EMPTY_SLOT
		gpu_container.visible = true
		gpu_container.position.y = -100.0
		gpu_container.modulate = Color(0.3, 0.9, 1.0, 0.65)
		cable_container.visible = false
		cable_container.position.y = CABLE_Y_DISCONNECTED
		is_power_disconnected = true
		btn_extract.visible = true
		btn_extract.text = "⇪ INSTALAR GPU NUEVA (ARRASTRA O CLIC)"
		if btn_extract.pressed.is_connected(_on_extract_pressed):
			btn_extract.pressed.disconnect(_on_extract_pressed)
		if not btn_extract.pressed.is_connected(_seat_new_gpu):
			btn_extract.pressed.connect(_seat_new_gpu)
		btn_screw_1.visible = false
		btn_screw_2.visible = false
		screws_removed = [true, true]
		is_pcie_latch_unlocked = true
		latch_status_label.text = "PESTILLO PCIE: ABIERTO"
		pcie_latch_btn.rotation_degrees = 45.0
		pcie_latch_btn.text = "ABIERTO"
		pcie_latch_btn.modulate = Color(1.0, 0.8, 0.2)
		_select_guide_tab(1)
	else:
		cable_container.position.y = CABLE_Y_CONNECTED
		cable_container.visible = true
		is_power_disconnected = false
		btn_cable_clip.disabled = false
		btn_extract.text = "▲ EXTRAER TARJETA GRÁFICA (GPU)"
		_select_guide_tab(0)
		
	_update_status()

func _select_guide_tab(idx: int) -> void:
	if is_instance_valid(btn_tab_quitar) and is_instance_valid(btn_tab_poner):
		if idx == 0:
			btn_tab_quitar.modulate = Color(1.2, 1.2, 0.4, 1.0)
			btn_tab_poner.modulate = Color(0.7, 0.7, 0.7, 0.7)
		else:
			btn_tab_quitar.modulate = Color(0.7, 0.7, 0.7, 0.7)
			btn_tab_poner.modulate = Color(0.2, 1.0, 0.5, 1.0)
			
	var has_gpu = false
	for it in GameManager.backpack:
		if it.get("name") == "Grafica" and not it.get("broken", true):
			has_gpu = true
			break
	var spare_msg = "✓ Tarjeta Gráfica de repuesto detectada en inventario.\n\n" if has_gpu else "⚠️ Preparado para montar repuesto.\n\n"
	guide_text.text = "INSTRUCCIONES DE MONTAJE:\n\n" + spare_msg + "1. Monta la GPU nueva en el slot PCIe.\n2. Cierra el pestillo de retención.\n3. Atornilla el bracket metálico con destornillador.\n4. Conecta el cable PCIe 8-pin."

func _setup_quitar_phase() -> void:
	current_state = State.DISCONNECT_POWER
	is_extracted = false
	gpu_container.visible = true
	gpu_container.position.y = 0.0
	gpu_container.modulate = Color(1, 1, 1, 1)
	cable_container.visible = true
	cable_container.position.y = CABLE_Y_CONNECTED
	cable_container.modulate.a = 1.0
	is_power_disconnected = false
	btn_cable_clip.disabled = false
	cable_hint.text = "CLIC PARA DESCONECTAR CABLE PCIE 8-PIN"
	cable_hint.modulate = Color(1, 0.85, 0.2)
	screws_removed = [false, false]
	btn_screw_1.visible = true
	btn_screw_1.disabled = false
	btn_screw_1.modulate.a = 1.0
	icon_screw_1.scale = Vector2(1, 1)
	btn_screw_2.visible = true
	btn_screw_2.disabled = false
	btn_screw_2.modulate.a = 1.0
	icon_screw_2.scale = Vector2(1, 1)
	is_pcie_latch_unlocked = false
	pcie_latch_btn.rotation_degrees = 0.0
	pcie_latch_btn.text = "TRABADO"
	pcie_latch_btn.modulate = Color(0.2, 1.0, 0.4)
	latch_status_label.text = "PESTILLO PCIE: TRABADO"
	latch_status_label.modulate = Color(1, 0.3, 0.3)
	btn_extract.visible = false
	if btn_extract.pressed.is_connected(_seat_new_gpu):
		btn_extract.pressed.disconnect(_seat_new_gpu)
	if not btn_extract.pressed.is_connected(_on_extract_pressed):
		btn_extract.pressed.connect(_on_extract_pressed)
	_update_status()

func _setup_empty_slot_phase() -> void:
	current_state = State.EMPTY_SLOT
	gpu_container.visible = true
	gpu_container.position.y = -100.0
	gpu_container.modulate = Color(0.3, 0.9, 1.0, 0.65)
	cable_container.visible = false
	cable_container.position.y = CABLE_Y_DISCONNECTED
	is_power_disconnected = true
	btn_cable_clip.disabled = false
	btn_extract.visible = true
	btn_extract.disabled = false
	btn_extract.text = "⇪ INSTALAR GPU NUEVA (ARRASTRA O CLIC)"
	if not btn_extract.pressed.is_connected(_seat_new_gpu):
		btn_extract.pressed.connect(_seat_new_gpu)
	if btn_extract.pressed.is_connected(_on_extract_pressed):
		btn_extract.pressed.disconnect(_on_extract_pressed)
	btn_screw_1.visible = false
	btn_screw_2.visible = false
	screws_removed = [true, true]
	is_pcie_latch_unlocked = true
	latch_status_label.text = "PESTILLO PCIE: ABIERTO"
	pcie_latch_btn.rotation_degrees = 45.0
	pcie_latch_btn.text = "ABIERTO"
	pcie_latch_btn.modulate = Color(1.0, 0.8, 0.2)
	_update_status()

func _seat_new_gpu() -> void:
	var found_idx = -1
	for i in range(GameManager.backpack.size()):
		var it = GameManager.backpack[i]
		if it.get("name") == "Grafica" and not it.get("broken", true):
			found_idx = i
			break
	if found_idx == -1:
		_show_warning("⚠️ No tienes Tarjetas Gráficas de repuesto en la mochila. Sal [ESC] para recogerlas.", Color(1.0, 0.4, 0.4))
		status_label.text = "⚠️ FALTA GPU EN MOCHILA · SAL [ESC] PARA BUSCARLA (PROGRESO: %d/%d)" % [current_gpu_index, target_gpu_count]
		status_label.modulate = Color(1.0, 0.4, 0.4)
		return
	GameManager.remove_item_from_backpack(found_idx)
		
	gpu_container.visible = true
	var tw = create_tween().set_parallel(true)
	tw.tween_property(gpu_container, "position:y", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(gpu_container, "modulate", Color(1, 1, 1, 1), 0.25)
	
	btn_extract.visible = false
	current_state = State.LATCH_NEW_GPU
	
	# Activar simultáneamente los 3 elementos (orden libre)
	is_pcie_latch_unlocked = true
	pcie_latch_btn.disabled = false
	pcie_latch_btn.rotation_degrees = 45.0
	pcie_latch_btn.text = "ABIERTO"
	pcie_latch_btn.modulate = Color(1.0, 0.8, 0.2)
	latch_status_label.text = "PESTILLO PCIE: ABIERTO"
	latch_status_label.modulate = Color(1.0, 0.8, 0.2)
	
	screws_removed = [true, true]
	btn_screw_1.visible = true
	btn_screw_1.disabled = false
	btn_screw_1.modulate.a = 0.5
	icon_screw_1.scale = Vector2(0.6, 0.6)
	icon_screw_1.rotation_degrees = 0.0
	
	btn_screw_2.visible = true
	btn_screw_2.disabled = false
	btn_screw_2.modulate.a = 0.5
	icon_screw_2.scale = Vector2(0.6, 0.6)
	icon_screw_2.rotation_degrees = 0.0
	
	is_power_disconnected = true
	cable_container.visible = true
	cable_container.position.y = CABLE_Y_DISCONNECTED
	cable_container.modulate.a = 0.8
	btn_cable_clip.disabled = false
	cable_hint.text = "HAZ CLIC PARA CONECTAR CABLE PCIE 8-PIN"
	cable_hint.modulate = Color(1.0, 0.85, 0.2)
	
	_show_warning("✓ GPU calzada en el zócalo. Asegura pestillo, tornillos y cable en cualquier orden.", Color(0.2, 1.0, 0.4))
	_update_status()

func _on_gpu_container_gui_input(event: InputEvent) -> void:
	if current_state == State.EXTRACT_GPU:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging_gpu = true
				drag_start_y = event.global_position.y
			else:
				if is_dragging_gpu:
					is_dragging_gpu = false
					var diff = drag_start_y - event.global_position.y
					if diff >= 30.0:
						_on_extract_pressed()
					else:
						var tw = create_tween()
						tw.tween_property(gpu_container, "position:y", 0.0, 0.2)
		elif event is InputEventMouseMotion and is_dragging_gpu:
			var pull = clamp(drag_start_y - event.global_position.y, 0.0, 60.0)
			gpu_container.position.y = -pull
			
	elif current_state == State.EMPTY_SLOT:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging_gpu = true
				drag_start_y = event.global_position.y
			else:
				if is_dragging_gpu:
					is_dragging_gpu = false
					var diff = event.global_position.y - drag_start_y
					if diff >= 20.0 or abs(diff) < 5.0: # Arrastre hacia abajo o clic directo
						_seat_new_gpu()
					else:
						var tw = create_tween()
						tw.tween_property(gpu_container, "position:y", -100.0, 0.2)
		elif event is InputEventMouseMotion and is_dragging_gpu:
			var push = clamp(event.global_position.y - drag_start_y, 0.0, 100.0)
			gpu_container.position.y = -100.0 + push

func _setup_screws() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	screw_types[0] = "cruz" if rng.randf() > 0.4 else "pala"
	screw_types[1] = "cruz" if rng.randf() > 0.4 else "pala"
	screws_removed = [false, false]

func _setup_ui() -> void:
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	
	btn_tool_1.pressed.connect(func(): GameManager.select_tool(1))
	btn_tool_2.pressed.connect(func(): GameManager.select_tool(2))
	GameManager.tool_selected.connect(_on_tool_selected)
	
	gpu_container.gui_input.connect(_on_gpu_container_gui_input)
	
	# Cable PCIe 8-pin
	btn_cable_clip.pressed.connect(_on_cable_pressed)
	
	# Tornillos bracket
	icon_screw_1.texture = tex_screw_cruz if screw_types[0] == "cruz" else tex_screw_pala
	icon_screw_2.texture = tex_screw_cruz if screw_types[1] == "cruz" else tex_screw_pala
	btn_screw_1.pressed.connect(_on_screw_pressed.bind(0))
	btn_screw_2.pressed.connect(_on_screw_pressed.bind(1))
	
	# Pestillo de seguridad PCIe
	pcie_latch_btn.pressed.connect(_on_latch_pressed)
	
	# Extracción de la tarjeta
	btn_extract.pressed.connect(_on_extract_pressed)
	btn_extract.visible = false
	warning_label.text = ""

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

func is_install_phase() -> bool:
	return current_state in [State.LATCH_NEW_GPU, State.SCREW_NEW_BRACKET, State.CONNECT_NEW_POWER]

func _check_gpu_install_completed() -> void:
	var screws_done = not screws_removed[0] and not screws_removed[1]
	var latch_done = not is_pcie_latch_unlocked
	var cable_done = not is_power_disconnected
	if screws_done and latch_done and cable_done:
		current_gpu_index += 1
		if current_gpu_index < target_gpu_count:
			_show_warning("✓ ¡TARJETA GPU #%d/%d MONTADA! Preparando siguiente ranura..." % [current_gpu_index, target_gpu_count], Color(0.2, 1.0, 0.4))
			await get_tree().create_timer(0.8).timeout
			_prepare_next_gpu_slot()
		else:
			current_state = State.COMPLETED
			_show_success_flow()
	else:
		_update_status()

func _prepare_next_gpu_slot() -> void:
	var has_gpu = false
	for it in GameManager.backpack:
		if it.get("name") == "Grafica" and not it.get("broken", true):
			has_gpu = true
			break

	current_state = State.EMPTY_SLOT
	gpu_container.visible = true
	gpu_container.position.y = -100.0
	gpu_container.modulate = Color(0.3, 0.9, 1.0, 0.65)
	
	btn_extract.visible = true
	btn_extract.disabled = false
	btn_extract.text = "⇪ INSTALAR GPU #%d (CLIC O ARRASTRA)" % (current_gpu_index + 1)
	if btn_extract.pressed.is_connected(_on_extract_pressed):
		btn_extract.pressed.disconnect(_on_extract_pressed)
	if not btn_extract.pressed.is_connected(_seat_new_gpu):
		btn_extract.pressed.connect(_seat_new_gpu)
		
	btn_screw_1.visible = false
	btn_screw_2.visible = false
	cable_container.visible = false
	cable_container.position.y = CABLE_Y_DISCONNECTED
	is_power_disconnected = true
	is_pcie_latch_unlocked = true
	pcie_latch_btn.rotation_degrees = 45.0
	pcie_latch_btn.text = "ABIERTO"
	pcie_latch_btn.modulate = Color(1.0, 0.8, 0.2)
	latch_status_label.text = "PESTILLO PCIE: ABIERTO"
	screws_removed = [true, true]
	
	_setup_screws()
	screws_removed = [true, true]
	if is_instance_valid(icon_screw_1):
		icon_screw_1.texture = tex_screw_cruz if screw_types[0] == "cruz" else tex_screw_pala
	if is_instance_valid(icon_screw_2):
		icon_screw_2.texture = tex_screw_cruz if screw_types[1] == "cruz" else tex_screw_pala
		
	if not has_gpu:
		status_label.text = "⚠️ FALTA GPU EN MOCHILA · SAL [ESC] PARA RECOGERLA (PROGRESO: %d/%d)" % [current_gpu_index, target_gpu_count]
		status_label.modulate = Color(1.0, 0.4, 0.4)
		_show_warning("⚠️ No tienes más GPUs en la mochila. Sal [ESC] para buscarlas.", Color(1.0, 0.4, 0.4))
	else:
		status_label.text = "RISER PCIE: Ranura #%d de %d · Asienta la nueva GPU (Clic o Arrastra)" % [current_gpu_index + 1, target_gpu_count]
		status_label.modulate = Color(1.0, 0.85, 0.2)
	_update_status()

func _on_cable_pressed() -> void:
	if is_install_phase():
		if not is_power_disconnected:
			return
		is_power_disconnected = false
		var tw = create_tween().set_parallel(true)
		tw.tween_property(cable_container, "position:y", CABLE_Y_CONNECTED, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(cable_container, "modulate:a", 1.0, 0.35)
		cable_hint.text = "✓ ALIMENTACIÓN PCIe 8-PIN CONECTADA"
		cable_hint.modulate = Color(0.2, 1.0, 0.4)
		btn_cable_clip.disabled = true
		_show_warning("✓ Cable PCIe 8-pin conectado con traba de seguridad.", Color(0.2, 1.0, 0.4))
		_check_gpu_install_completed()
		return

	if is_power_disconnected:
		return
	
	is_power_disconnected = true
	var tw = create_tween().set_parallel(true)
	tw.tween_property(cable_container, "position:y", CABLE_Y_DISCONNECTED, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(cable_container, "modulate:a", 0.4, 0.35)
	cable_hint.text = "✓ ALIMENTACIÓN DESCONECTADA"
	cable_hint.modulate = Color(0.2, 1.0, 0.4)
	btn_cable_clip.disabled = true
	
	_show_warning("✓ Conector PCIe 8-pin desconectado con seguridad.", Color(0.2, 1.0, 0.4))
	_advance_state_check()

func _on_screw_pressed(idx: int) -> void:
	if is_install_phase():
		if not screws_removed[idx]:
			return # Ya apretado
		
		var req_tool = 1 if screw_types[idx] == "cruz" else 2
		var tool_name = "Cruz (+)" if req_tool == 1 else "Pala (-)"
		
		if GameManager.equipped_tool != req_tool:
			GameManager.register_error(2.0)
			_show_warning("Herramienta incorrecta: Este tornillo requiere Destornillador " + tool_name + " [Tecla " + str(req_tool) + "]", Color(1.0, 0.3, 0.3))
			return
		
		screws_removed[idx] = false
		var btn = btn_screw_1 if idx == 0 else btn_screw_2
		var icon = icon_screw_1 if idx == 0 else icon_screw_2
		
		var tw = create_tween().set_parallel(true)
		tw.tween_property(icon, "rotation_degrees", icon.rotation_degrees - 720.0, 0.4)
		tw.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.4)
		tw.tween_property(btn, "modulate:a", 1.0, 0.4)
		btn.disabled = true
		
		GameManager.register_repair(25, 2.0)
		_show_warning("✓ Tornillo de chasis " + str(idx + 1) + "/2 colocado y ajustado.", Color(0.4, 1.0, 0.4))
		_check_gpu_install_completed()
		return

	if screws_removed[idx]:
		return
	
	var req_tool = 1 if screw_types[idx] == "cruz" else 2
	var tool_name = "Cruz (+)" if req_tool == 1 else "Pala (-)"
	
	if GameManager.equipped_tool != req_tool:
		GameManager.register_error(2.0)
		_show_warning("Herramienta incorrecta: Este tornillo requiere Destornillador " + tool_name + " [Tecla " + str(req_tool) + "]", Color(1.0, 0.3, 0.3))
		return
	
	screws_removed[idx] = true
	var btn = btn_screw_1 if idx == 0 else btn_screw_2
	var icon = icon_screw_1 if idx == 0 else icon_screw_2
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(icon, "rotation_degrees", icon.rotation_degrees + 720.0, 0.4)
	tw.tween_property(icon, "scale", Vector2(0.1, 0.1), 0.4)
	tw.tween_property(btn, "modulate:a", 0.0, 0.4)
	
	btn.disabled = true
	GameManager.register_repair(25, 2.0)
	_show_warning("✓ Tornillo de chasis " + str(idx + 1) + "/2 retirado.", Color(0.4, 1.0, 0.4))
	_advance_state_check()

func _on_latch_pressed() -> void:
	if is_install_phase():
		if not is_pcie_latch_unlocked:
			return # Ya trabado
		is_pcie_latch_unlocked = false
		var tw = create_tween()
		tw.tween_property(pcie_latch_btn, "rotation_degrees", 0.0, 0.25).set_trans(Tween.TRANS_QUAD)
		pcie_latch_btn.text = "TRABADO"
		pcie_latch_btn.modulate = Color(0.2, 1.0, 0.4)
		latch_status_label.text = "PESTILLO PCIE: TRABADO (SEGURO)"
		latch_status_label.modulate = Color(0.2, 1.0, 0.4)
		_show_warning("✓ ¡CLICK! Pestillo PCIe x16 trabado y asegurado.", Color(0.2, 1.0, 0.4))
		_check_gpu_install_completed()
		return

	if is_pcie_latch_unlocked:
		return
	
	is_pcie_latch_unlocked = true
	var tw = create_tween()
	tw.tween_property(pcie_latch_btn, "rotation_degrees", 45.0, 0.25).set_trans(Tween.TRANS_QUAD)
	pcie_latch_btn.text = "ABIERTO"
	pcie_latch_btn.modulate = Color(0.2, 1.0, 0.4)
	latch_status_label.text = "PESTILLO PCIE: LIBERADO"
	latch_status_label.modulate = Color(0.2, 1.0, 0.4)
	
	_show_warning("✓ ¡CLICK! Pestillo PCIe x16 destrabado.", Color(0.2, 1.0, 0.4))
	_advance_state_check()

func _advance_state_check() -> void:
	var all_screws = screws_removed[0] and screws_removed[1]
	
	if not is_power_disconnected:
		current_state = State.DISCONNECT_POWER
	elif not all_screws:
		current_state = State.UNSCREW_BRACKET
	elif not is_pcie_latch_unlocked:
		current_state = State.RELEASE_LATCH
	else:
		current_state = State.EXTRACT_GPU
		btn_extract.visible = true
		btn_extract.modulate = Color(1, 1, 1, 0)
		var tw = create_tween()
		tw.tween_property(btn_extract, "modulate:a", 1.0, 0.3)
	
	_update_status()

func _on_extract_pressed() -> void:
	if is_extracted:
		return
	
	if not is_pcie_latch_unlocked:
		GameManager.register_error(2.0)
		_show_warning("¡ALERTA CRÍTICA! Debes desbloquear el pestillo PCIe antes de extraer la tarjeta.", Color(1.0, 0.1, 0.1))
		return
	
	if not is_power_disconnected:
		GameManager.register_error(2.0)
		_show_warning("¡PELIGRO! El cable de corriente PCIe aún está conectado.", Color(1.0, 0.1, 0.1))
		return
	
	if not (screws_removed[0] and screws_removed[1]):
		GameManager.register_error(2.0)
		_show_warning("¡ALERTA! Retira los tornillos del bracket metálico primero.", Color(1.0, 0.1, 0.1))
		return
	
	is_extracted = true
	btn_extract.disabled = true
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(gpu_container, "position:y", gpu_container.position.y - 180.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(gpu_container, "modulate:a", 0.4, 0.6)
	
	await tw.finished
	GameManager.add_item_to_backpack({"name": "Grafica", "broken": true})
	old_part_extracted.emit()
	
	if not is_tutorial_mode:
		_show_warning("✓ GPU averiada extraída. Slot vacío. Busca el repuesto nuevo en el taller.", Color(0.2, 1.0, 0.4))
		await get_tree().create_timer(1.2).timeout
		minigame_finished.emit(true)
		return
	
	# Solo en modo tutorial (práctica continua):
	var has_new = false
	for it in GameManager.backpack:
		if it.get("name") == "Grafica" and not it.get("broken", true):
			has_new = true
			break
	if not has_new:
		GameManager.add_item_to_backpack({"name": "Grafica", "broken": false})
		
	gpu_container.visible = true
	gpu_container.position.y = -100.0
	gpu_container.modulate = Color(0.3, 0.9, 1.0, 0.65)
	current_state = State.EMPTY_SLOT
	_select_guide_tab(1)
	
	btn_extract.visible = true
	btn_extract.disabled = false
	btn_extract.text = "⇪ INSTALAR GPU NUEVA (ARRASTRA O CLIC)"
	if btn_extract.pressed.is_connected(_on_extract_pressed):
		btn_extract.pressed.disconnect(_on_extract_pressed)
	if not btn_extract.pressed.is_connected(_seat_new_gpu):
		btn_extract.pressed.connect(_seat_new_gpu)
	
	_show_warning("✓ Espacio despejado ➔ AHORA: MONTAJE DEL REPUESTO", Color(0.2, 1.0, 0.5))
	_update_status()

func _show_warning(msg: String, col: Color) -> void:
	warning_label.text = msg
	warning_label.modulate = col
	var tw = create_tween()
	tw.tween_property(warning_label, "scale", Vector2(1.08, 1.08), 0.1)
	tw.tween_property(warning_label, "scale", Vector2(1.0, 1.0), 0.15)

func _update_status() -> void:
	match current_state:
		State.DISCONNECT_POWER:
			status_label.text = "PASO 1: Presiona el clip de seguridad y desconecta el cable PCIe de 8 pines."
			status_label.modulate = Color(1.0, 0.85, 0.2)
		State.UNSCREW_BRACKET:
			status_label.text = "PASO 2: Retira los 2 tornillos del bracket metálico del chasis con [1] Cruz o [2] Pala."
			status_label.modulate = Color(1.0, 0.85, 0.2)
		State.RELEASE_LATCH:
			status_label.text = "PASO 3: Presiona el pestillo plástico de retención al final del zócalo PCIe x16."
			status_label.modulate = Color(1.0, 0.4, 0.8)
		State.EXTRACT_GPU:
			status_label.text = "PASO 4: ¡Todo libre! Arrastra la GPU hacia arriba o presiona el botón."
			status_label.modulate = Color(0.2, 1.0, 0.4)
		State.EMPTY_SLOT:
			status_label.text = "INSTALACIÓN: Arrastra la GPU nueva hacia abajo al slot o presiona el botón."
			status_label.modulate = Color(1.0, 0.85, 0.2)
		State.LATCH_NEW_GPU, State.SCREW_NEW_BRACKET, State.CONNECT_NEW_POWER:
			var pending: Array[String] = []
			if is_pcie_latch_unlocked: pending.append("Trabar pestillo PCIe")
			if screws_removed[0] or screws_removed[1]:
				var s_rem = (1 if screws_removed[0] else 0) + (1 if screws_removed[1] else 0)
				pending.append("Atornillar bracket (%d restantes)" % s_rem)
			if is_power_disconnected: pending.append("Conectar cable PCIe 8P")
			status_label.text = "Fase Montaje: " + " · ".join(pending) + " (cualquier orden)."
			status_label.modulate = Color(0.2, 0.9, 1.0)
		State.COMPLETED:
			status_label.text = "¡OPERACIÓN COMPLETADA! GPU instalada y testeada con éxito."
			status_label.modulate = Color(0.2, 1.0, 0.4)
	
	_update_checklist()

func _update_checklist() -> void:
	if not is_instance_valid(chk_power) or not is_instance_valid(chk_bracket):
		return
	var is_install: bool = is_install_phase() or current_state == State.EMPTY_SLOT
	if not is_install:
		_format_check_item(chk_power, is_power_disconnected, "1. Cable PCIe 8-Pines", current_state == State.DISCONNECT_POWER)
		var s_rem = (1 if screws_removed[0] else 0) + (1 if screws_removed[1] else 0)
		_format_check_item(chk_bracket, s_rem == 2, "2. Tornillos bracket (%d/2)" % s_rem, current_state == State.UNSCREW_BRACKET)
		_format_check_item(chk_latch, is_pcie_latch_unlocked, "3. Pestillo Slot PCIe", current_state == State.RELEASE_LATCH)
		_format_check_item(chk_extract, is_extracted, "4. Extraer Tarjeta Gráfica", current_state == State.EXTRACT_GPU)
	else:
		_format_check_item(chk_extract, current_state != State.EMPTY_SLOT, "1. Calzar GPU en zócalo", current_state == State.EMPTY_SLOT)
		_format_check_item(chk_latch, not is_pcie_latch_unlocked, "2. Trabar pestillo PCIe", is_pcie_latch_unlocked)
		var s_fast = (0 if screws_removed[0] else 1) + (0 if screws_removed[1] else 1)
		_format_check_item(chk_bracket, s_fast == 2, "3. Tornillos bracket (%d/2)" % s_fast, s_fast < 2)
		_format_check_item(chk_power, not is_power_disconnected, "4. Cable PCIe 8-Pines", is_power_disconnected)

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

func _show_success_flow() -> void:
	current_state = State.COMPLETED
	_update_status()
	_show_warning("✓ ¡REPARACIÓN COMPLETADA! GPU instalada y testeada con éxito.", Color(0.2, 1.0, 0.4))
	await get_tree().create_timer(1.2).timeout
	minigame_finished.emit(true)
