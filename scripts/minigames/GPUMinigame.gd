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

# Estado de los tornillos del bracket (2 tornillos)
var screw_types: Array[String] = ["cruz", "cruz"]
var screws_removed: Array[bool] = [false, false]

# Estado de seguros
var is_power_disconnected: bool = false
var is_pcie_latch_unlocked: bool = false
var is_extracted: bool = false

var is_dragging_gpu: bool = false
var drag_start_y: float = 0.0

# Texturas
var tex_screw_cruz = preload("res://pixel art/tornillo de cruz.png")
var tex_screw_pala = preload("res://pixel art/tornillo de pala.png")

# Nodos
@onready var modal_control: Control = $ModalControl
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var btn_tool_1: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool1
@onready var btn_tool_2: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool2
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel

@onready var work_area: Control = $ModalControl/Panel/VBox/WorkArea
@onready var gpu_container: Control = $ModalControl/Panel/VBox/WorkArea/GPUContainer
@onready var pcie_slot: Panel = $ModalControl/Panel/VBox/WorkArea/PCIeSlot
@onready var pcie_latch_btn: Button = $ModalControl/Panel/VBox/WorkArea/PCIeSlot/BtnLatch
@onready var latch_status_label: Label = $ModalControl/Panel/VBox/WorkArea/PCIeSlot/LatchStatus

@onready var cable_container: Control = $ModalControl/Panel/VBox/WorkArea/CableContainer
@onready var btn_cable_clip: Button = $ModalControl/Panel/VBox/WorkArea/CableContainer/BtnCableClip
@onready var cable_hint: Label = $ModalControl/Panel/VBox/WorkArea/CableContainer/CableHint

@onready var bracket_area: Control = $ModalControl/Panel/VBox/WorkArea/GPUContainer/BracketArea
@onready var btn_screw_1: Button = $ModalControl/Panel/VBox/WorkArea/GPUContainer/BracketArea/Screw1
@onready var btn_screw_2: Button = $ModalControl/Panel/VBox/WorkArea/GPUContainer/BracketArea/Screw2
@onready var icon_screw_1: TextureRect = $ModalControl/Panel/VBox/WorkArea/GPUContainer/BracketArea/Screw1/Icon
@onready var icon_screw_2: TextureRect = $ModalControl/Panel/VBox/WorkArea/GPUContainer/BracketArea/Screw2/Icon

@onready var btn_extract: Button = $ModalControl/Panel/VBox/WorkArea/BtnExtractGPU
@onready var warning_label: Label = $ModalControl/Panel/VBox/WorkArea/WarningLabel

@onready var btn_tab_quitar: Button = $ModalControl/Panel/VBox/Header/GuidePanel/VBoxGuide/TabsBox/BtnTabQuitar
@onready var btn_tab_poner: Button = $ModalControl/Panel/VBox/Header/GuidePanel/VBoxGuide/TabsBox/BtnTabPoner
@onready var guide_text: Label = $ModalControl/Panel/VBox/Header/GuidePanel/VBoxGuide/GuideText

func _ready() -> void:
	layer = 12
	_setup_screws()
	_setup_ui()
	_update_tool_buttons()
	
	btn_tab_quitar.pressed.connect(func(): _select_guide_tab(0))
	btn_tab_poner.pressed.connect(func(): _select_guide_tab(1))
	
	if not is_tutorial_mode and btn_tab_quitar.get_parent():
		btn_tab_quitar.get_parent().visible = false
	
	if start_as_empty_slot:
		current_state = State.EMPTY_SLOT
		gpu_container.visible = true
		gpu_container.position.y = -100.0
		gpu_container.modulate = Color(0.3, 0.9, 1.0, 0.65)
		cable_container.visible = false
		btn_extract.visible = true
		btn_extract.text = "⇪ INSTALAR GPU NUEVA (ARRASTRA O CLIC)"
		btn_extract.pressed.disconnect(_on_extract_pressed)
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
		btn_extract.text = "▲ EXTRAER TARJETA GRÁFICA (GPU)"
		_select_guide_tab(0)
		
	_update_status()

func _select_guide_tab(idx: int) -> void:
	if idx == 0:
		btn_tab_quitar.modulate = Color(1.2, 1.2, 0.4, 1.0)
		btn_tab_poner.modulate = Color(0.7, 0.7, 0.7, 0.7)
		guide_text.text = "PASOS DE DESMONTAJE (QUITAR): 1. Desconecta cable PCIe 8P · 2. Retira 2 tornillos de bracket con [1]/[2] · 3. Abre pestillo PCIe · 4. Extrae GPU."
		if is_install_phase() or current_state == State.EMPTY_SLOT:
			_setup_quitar_phase()
	else:
		btn_tab_quitar.modulate = Color(0.7, 0.7, 0.7, 0.7)
		btn_tab_poner.modulate = Color(0.2, 1.0, 0.5, 1.0)
		guide_text.text = "PASOS DE MONTAJE (CÓMO PONER AL REVÉS): 1. Monta la GPU nueva en el slot PCIe · 2. Cierra pestillo, atornilla bracket y conecta cable (cualquier orden)."
		if not is_install_phase() and current_state != State.EMPTY_SLOT:
			_setup_empty_slot_phase()

func _setup_quitar_phase() -> void:
	current_state = State.DISCONNECT_POWER
	is_extracted = false
	gpu_container.visible = true
	gpu_container.position.y = 0.0
	gpu_container.modulate = Color(1, 1, 1, 1)
	cable_container.visible = true
	cable_container.position.y = 0.0
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
	if found_idx != -1:
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
	cable_container.modulate.a = 0.6
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
					if diff >= 30.0:
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
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_1:
			GameManager.select_tool(1)
		elif event.keycode == KEY_2:
			GameManager.select_tool(2)
		elif event.keycode == KEY_ESCAPE:
			minigame_finished.emit(false)

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
		current_state = State.COMPLETED
		_show_success_flow()
	else:
		_update_status()

func _on_cable_pressed() -> void:
	if is_install_phase():
		if not is_power_disconnected:
			return
		is_power_disconnected = false
		var tw = create_tween().set_parallel(true)
		tw.tween_property(cable_container, "position:y", cable_container.position.y + 70.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(cable_container, "modulate:a", 1.0, 0.4)
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
	tw.tween_property(cable_container, "position:y", cable_container.position.y - 70.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(cable_container, "modulate:a", 0.3, 0.4)
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
		
		_show_warning("✓ Tornillo de chasis " + str(idx + 1) + "/2 colocado y ajustado.", Color(0.4, 1.0, 0.4))
		_check_gpu_install_completed()
		return

	if screws_removed[idx]:
		return
	
	var req_tool = 1 if screw_types[idx] == "cruz" else 2
	var tool_name = "Cruz (+)" if req_tool == 1 else "Pala (-)"
	
	if GameManager.equipped_tool != req_tool:
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
		_show_warning("¡ALERTA CRÍTICA! Debes desbloquear el pestillo PCIe antes de extraer la tarjeta.", Color(1.0, 0.1, 0.1))
		return
	
	if not is_power_disconnected:
		_show_warning("¡PELIGRO! El cable de corriente PCIe aún está conectado.", Color(1.0, 0.1, 0.1))
		return
	
	if not (screws_removed[0] and screws_removed[1]):
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
	
	# Asegurar que haya una GPU nueva en la mochila para la fase de colocación
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
	btn_extract.pressed.disconnect(_on_extract_pressed)
	btn_extract.pressed.connect(_seat_new_gpu)
	
	_show_warning("✓ FASE 1 (QUITAR) SUPERADA ➔ AHORA FASE 2: MONTAJE DEL REPUESTO (INVERSO)", Color(0.2, 1.0, 0.5))
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

func _show_success_flow() -> void:
	_update_status()
	_show_warning("✓ ¡REPARACIÓN INTEGRAL SUPERADA! Has completado tanto el desmontaje como el montaje inverso.", Color(0.2, 1.0, 0.4))
	await get_tree().create_timer(1.6).timeout
	minigame_finished.emit(true)
