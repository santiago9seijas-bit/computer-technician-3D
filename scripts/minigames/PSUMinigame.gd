extends CanvasLayer

# =============================================================================
# MINIJUEGO: DESMONTAJE DE FUENTE DE ALIMENTACIÓN (PSU)
# Enseña:
# 1. Desconectar el conector principal ATX de 24 pines con pestaña de seguridad.
# 2. Desconectar el conector auxiliar EPS de 8 pines de la CPU.
# 3. Retirar los 4 tornillos de anclaje traseros del chasis.
# 4. Deslizar la fuente modular fuera de la bahía inferior (PSU Shroud).
# =============================================================================

signal minigame_finished(success: bool)

enum State {
	DISCONNECT_ATX24,
	DISCONNECT_EPS8,
	UNSCREW_CHASSIS,
	SLIDE_OUT_PSU,
	COMPLETED
}

var current_state: State = State.DISCONNECT_ATX24

var is_atx24_disconnected: bool = false
var is_eps8_disconnected: bool = false

var screw_types: Array[String] = ["cruz", "cruz", "cruz", "pala"]
var screws_removed: Array[bool] = [false, false, false, false]
var is_psu_slid_out: bool = false

var tex_screw_cruz = preload("res://pixel art/tornillo de cruz.png")
var tex_screw_pala = preload("res://pixel art/tornillo de pala.png")

# Nodos
@onready var modal_control: Control = $ModalControl
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var btn_tool_1: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool1
@onready var btn_tool_2: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool2
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel

@onready var work_area: Control = $ModalControl/Panel/VBox/WorkArea
@onready var psu_body: Panel = $ModalControl/Panel/VBox/WorkArea/PSUBody
@onready var cable_atx24: Panel = $ModalControl/Panel/VBox/WorkArea/CableATX24
@onready var btn_atx24: Button = $ModalControl/Panel/VBox/WorkArea/CableATX24/BtnATX24
@onready var lbl_atx24: Label = $ModalControl/Panel/VBox/WorkArea/CableATX24/LblATX24

@onready var cable_eps8: Panel = $ModalControl/Panel/VBox/WorkArea/CableEPS8
@onready var btn_eps8: Button = $ModalControl/Panel/VBox/WorkArea/CableEPS8/BtnEPS8
@onready var lbl_eps8: Label = $ModalControl/Panel/VBox/WorkArea/CableEPS8/LblEPS8

@onready var screws_box: Control = $ModalControl/Panel/VBox/WorkArea/PSUBody/RearFace/ScrewsContainer
@onready var btn_slide_psu: Button = $ModalControl/Panel/VBox/WorkArea/BtnSlidePSU
@onready var warning_label: Label = $ModalControl/Panel/VBox/WorkArea/WarningLabel

var screw_buttons: Array[Button] = []
var screw_icons: Array[TextureRect] = []

func _ready() -> void:
	layer = 12
	_setup_screws()
	_setup_ui()
	_update_tool_buttons()
	_update_status()

func _setup_screws() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in range(4):
		screw_types[i] = "cruz" if rng.randf() > 0.3 else "pala"
		screws_removed[i] = false

func _setup_ui() -> void:
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	
	btn_tool_1.pressed.connect(func(): GameManager.select_tool(1))
	btn_tool_2.pressed.connect(func(): GameManager.select_tool(2))
	GameManager.tool_selected.connect(_on_tool_selected)
	
	btn_atx24.pressed.connect(_on_atx24_pressed)
	btn_eps8.pressed.connect(_on_eps8_pressed)
	btn_slide_psu.pressed.connect(_on_slide_psu_pressed)
	btn_slide_psu.visible = false
	
	screw_buttons.clear()
	screw_icons.clear()
	for i in range(4):
		var btn = screws_box.get_node_or_null("Screw" + str(i + 1)) as Button
		if btn:
			var icon = btn.get_node_or_null("Icon") as TextureRect
			if icon:
				icon.texture = tex_screw_cruz if screw_types[i] == "cruz" else tex_screw_pala
				screw_icons.append(icon)
			btn.pressed.connect(_on_screw_pressed.bind(i))
			screw_buttons.append(btn)
	
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

func _on_atx24_pressed() -> void:
	if is_atx24_disconnected:
		return
	
	is_atx24_disconnected = true
	btn_atx24.disabled = true
	lbl_atx24.text = "✓ ATX 24P DESCONECTADO"
	lbl_atx24.modulate = Color(0.2, 1.0, 0.4)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(cable_atx24, "position:y", cable_atx24.position.y - 45.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(cable_atx24, "modulate:a", 0.3, 0.35)
	
	_show_warning("✓ Clip de 24 pines presionado y conector desconectado.", Color(0.2, 1.0, 0.4))
	_advance_state_check()

func _on_eps8_pressed() -> void:
	if not is_atx24_disconnected:
		_show_warning("Desconecta primero el arnés principal ATX de 24 pines.", Color(1.0, 0.4, 0.4))
		return
	
	if is_eps8_disconnected:
		return
	
	is_eps8_disconnected = true
	btn_eps8.disabled = true
	lbl_eps8.text = "✓ EPS CPU 8P DESCONECTADO"
	lbl_eps8.modulate = Color(0.2, 1.0, 0.4)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(cable_eps8, "position:y", cable_eps8.position.y - 45.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(cable_eps8, "modulate:a", 0.3, 0.35)
	
	_show_warning("✓ Cable EPS auxiliar de CPU desconectado.", Color(0.2, 1.0, 0.4))
	_advance_state_check()

func _on_screw_pressed(idx: int) -> void:
	if not (is_atx24_disconnected and is_eps8_disconnected):
		_show_warning("¡ALERTA! Desconecta todos los cables antes de desatornillar el chasis.", Color(1.0, 0.3, 0.3))
		return
	
	if screws_removed[idx]:
		return
	
	var req = 1 if screw_types[idx] == "cruz" else 2
	var tool_name = "Cruz (+)" if req == 1 else "Pala (-)"
	
	if GameManager.equipped_tool != req:
		_show_warning("Herramienta incorrecta: Este tornillo hexagonal requiere Destornillador " + tool_name + " [Tecla " + str(req) + "]", Color(1.0, 0.3, 0.3))
		return
	
	screws_removed[idx] = true
	var btn = screw_buttons[idx]
	var icon = screw_icons[idx]
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(icon, "rotation_degrees", icon.rotation_degrees + 720.0, 0.35)
	tw.tween_property(icon, "scale", Vector2(0.1, 0.1), 0.35)
	tw.tween_property(btn, "modulate:a", 0.0, 0.35)
	btn.disabled = true
	
	var remaining = 0
	for r in screws_removed:
		if not r: remaining += 1
	
	_show_warning("✓ Tornillo de chasis retirado. Restantes: " + str(remaining) + "/4", Color(0.4, 1.0, 0.4))
	_advance_state_check()

func _advance_state_check() -> void:
	var all_screws = true
	for r in screws_removed:
		if not r:
			all_screws = false
			break
	
	if not is_atx24_disconnected:
		current_state = State.DISCONNECT_ATX24
	elif not is_eps8_disconnected:
		current_state = State.DISCONNECT_EPS8
	elif not all_screws:
		current_state = State.UNSCREW_CHASSIS
	else:
		current_state = State.SLIDE_OUT_PSU
		btn_slide_psu.visible = true
		btn_slide_psu.modulate = Color(1, 1, 1, 0)
		var tw = create_tween()
		tw.tween_property(btn_slide_psu, "modulate:a", 1.0, 0.3)
	
	_update_status()

func _on_slide_psu_pressed() -> void:
	if is_psu_slid_out:
		return
	
	is_psu_slid_out = true
	btn_slide_psu.disabled = true
	current_state = State.COMPLETED
	
	# Deslizar la fuente hacia la derecha fuera del chasis
	var tw = create_tween().set_parallel(true)
	tw.tween_property(psu_body, "position:x", psu_body.position.x + 240.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(psu_body, "modulate:a", 0.3, 0.6)
	
	await tw.finished
	_show_warning("✓ ¡EXCELENTE! Fuente de poder deslizada y retirada sin tirones en el cableado.", Color(0.2, 1.0, 0.4))
	_update_status()
	await get_tree().create_timer(1.6).timeout
	minigame_finished.emit(true)

func _show_warning(msg: String, col: Color) -> void:
	warning_label.text = msg
	warning_label.modulate = col
	var tw = create_tween()
	tw.tween_property(warning_label, "scale", Vector2(1.06, 1.06), 0.1)
	tw.tween_property(warning_label, "scale", Vector2(1.0, 1.0), 0.15)

func _update_status() -> void:
	match current_state:
		State.DISCONNECT_ATX24:
			status_label.text = "PASO 1: Presiona la traba del arnés principal ATX de 24 pines y desconéctalo."
			status_label.modulate = Color(1.0, 0.85, 0.2)
		State.DISCONNECT_EPS8:
			status_label.text = "PASO 2: Desconecta el conector auxiliar EPS de 8 pines de la CPU."
			status_label.modulate = Color(1.0, 0.85, 0.2)
		State.UNSCREW_CHASSIS:
			status_label.text = "PASO 3: Retira los 4 tornillos de sujeción traseros del chasis con [1] Cruz o [2] Pala."
			status_label.modulate = Color(1.0, 0.4, 0.8)
		State.SLIDE_OUT_PSU:
			status_label.text = "PASO 4: ¡Todo desconectado! Haz clic en 'DESLIZAR FUENTE' para extraerla del túnel."
			status_label.modulate = Color(0.2, 1.0, 0.4)
		State.COMPLETED:
			status_label.text = "¡DESMONTAJE COMPLETADO! PSU extraída limpiamente."
			status_label.modulate = Color(0.2, 1.0, 0.4)
