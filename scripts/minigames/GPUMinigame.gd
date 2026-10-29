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

enum State {
	DISCONNECT_POWER,
	UNSCREW_BRACKET,
	RELEASE_LATCH,
	EXTRACT_GPU,
	COMPLETED
}

var current_state: State = State.DISCONNECT_POWER

# Estado de los tornillos del bracket (2 tornillos)
var screw_types: Array[String] = ["cruz", "cruz"]
var screws_removed: Array[bool] = [false, false]

# Estado de seguros
var is_power_disconnected: bool = false
var is_pcie_latch_unlocked: bool = false
var is_extracted: bool = false

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

func _ready() -> void:
	layer = 12
	_setup_screws()
	_setup_ui()
	_update_tool_buttons()
	_update_status()

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

func _on_cable_pressed() -> void:
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
	current_state = State.COMPLETED
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(gpu_container, "position:y", gpu_container.position.y - 180.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(gpu_container, "modulate:a", 0.4, 0.6)
	
	await tw.finished
	_show_success_flow()

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
			status_label.text = "PASO 4: ¡Todo libre! Presiona el botón para extraer suavemente la GPU hacia arriba."
			status_label.modulate = Color(0.2, 1.0, 0.4)
		State.COMPLETED:
			status_label.text = "¡DESMONTAJE COMPLETADO! GPU desmontada de forma profesional."
			status_label.modulate = Color(0.2, 1.0, 0.4)

func _show_success_flow() -> void:
	_update_status()
	_show_warning("✓ ¡EXCELENTE! Has desmontado la tarjeta gráfica sin dañar el puerto PCIe ni doblar el bracket.", Color(0.2, 1.0, 0.4))
	await get_tree().create_timer(1.6).timeout
	minigame_finished.emit(true)
