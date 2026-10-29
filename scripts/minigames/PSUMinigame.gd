extends CanvasLayer

# =============================================================================
# MINIJUEGO: DESMONTAJE Y MONTAJE DE FUENTE DE ALIMENTACIÓN (PSU)
# Enseña:
# 1. Desconectar el conector principal ATX de 24 pines con pestaña de seguridad.
# 2. Desconectar el conector auxiliar EPS de 8 pines de la CPU.
# 3. Retirar los 4 tornillos de anclaje traseros del chasis.
# 4. Deslizar la fuente modular fuera de la bahía inferior (PSU Shroud).
# MODO INVERSO (Instalación):
# 1. Deslizar la fuente nueva dentro del túnel.
# 2. Ajustar los 4 tornillos de chasis.
# 3. Conectar cable auxiliar EPS de 8 pines.
# 4. Conectar cable principal ATX de 24 pines con clip.
# =============================================================================

signal minigame_finished(success: bool)
signal old_part_extracted()

enum State {
	DISCONNECT_ATX24,
	DISCONNECT_EPS8,
	UNSCREW_CHASSIS,
	SLIDE_OUT_PSU,
	EMPTY_TUNNEL,
	SCREW_CHASSIS,
	CONNECT_EPS8,
	CONNECT_ATX24,
	COMPLETED
}

var current_state: State = State.DISCONNECT_ATX24
var start_as_empty_slot: bool = false

var is_atx24_disconnected: bool = false
var is_eps8_disconnected: bool = false

var screw_types: Array[String] = ["cruz", "cruz", "cruz", "pala"]
var screws_removed: Array[bool] = [false, false, false, false]
var is_psu_slid_out: bool = false
var default_psu_x: float = 0.0

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
	default_psu_x = psu_body.position.x
	_setup_screws()
	_setup_ui()
	_update_tool_buttons()
	
	if start_as_empty_slot:
		current_state = State.EMPTY_TUNNEL
		psu_body.visible = false
		cable_atx24.modulate.a = 0.3
		cable_atx24.position.y -= 45.0
		cable_eps8.modulate.a = 0.3
		cable_eps8.position.y -= 45.0
		btn_atx24.disabled = true
		btn_eps8.disabled = true
		lbl_atx24.text = "ATX 24P (DESCONECTADO)"
		lbl_eps8.text = "EPS 8P (DESCONECTADO)"
		
		btn_slide_psu.visible = true
		btn_slide_psu.text = "⇪ INSTALAR FUENTE NUEVA DESDE MOCHILA"
		btn_slide_psu.pressed.disconnect(_on_slide_psu_pressed)
		btn_slide_psu.pressed.connect(_on_insert_new_psu_pressed)
		
		screws_removed = [true, true, true, true]
		for b in screw_buttons:
			b.visible = false
			b.disabled = true
	else:
		btn_slide_psu.text = "▶ DESLIZAR FUENTE FUERA DEL TÚNEL"
		
	_update_status()

func _on_insert_new_psu_pressed() -> void:
	var found_idx = -1
	for i in range(GameManager.backpack.size()):
		var it = GameManager.backpack[i]
		if it.get("name") == "Fuente" and not it.get("broken", true):
			found_idx = i
			break
	if found_idx == -1:
		_show_warning("No tienes Fuente de Poder nueva en tu mochila. Sal al taller a buscar el repuesto.", Color(1.0, 0.3, 0.3))
		return
		
	GameManager.remove_item_from_backpack(found_idx)
	psu_body.visible = true
	psu_body.position.x = default_psu_x + 200.0
	psu_body.modulate.a = 0.2
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(psu_body, "position:x", default_psu_x, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(psu_body, "modulate:a", 1.0, 0.45)
	
	btn_slide_psu.visible = false
	current_state = State.SCREW_CHASSIS
	
	# Habilitar tornillos para atornillar
	for i in range(4):
		var btn = screw_buttons[i]
		var icon = screw_icons[i]
		btn.visible = true
		btn.disabled = false
		btn.modulate.a = 0.45
		icon.scale = Vector2(0.5, 0.5)
		icon.rotation_degrees = 0.0
		
	_show_warning("✓ Fuente colocada en el túnel. Ajusta los 4 tornillos con [1] Cruz o [2] Pala.", Color(0.2, 1.0, 0.4))
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
	if current_state == State.CONNECT_ATX24:
		btn_atx24.disabled = true
		lbl_atx24.text = "✓ ATX 24P CONECTADO"
		lbl_atx24.modulate = Color(0.2, 1.0, 0.4)
		
		var tw = create_tween().set_parallel(true)
		tw.tween_property(cable_atx24, "position:y", cable_atx24.position.y + 45.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(cable_atx24, "modulate:a", 1.0, 0.35)
		
		current_state = State.COMPLETED
		_update_status()
		_show_warning("✓ ¡Cable ATX de 24 pines asegurado con éxito! Fuente operativa.", Color(0.2, 1.0, 0.4))
		await get_tree().create_timer(1.6).timeout
		minigame_finished.emit(true)
		return

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
	if current_state == State.CONNECT_EPS8:
		btn_eps8.disabled = true
		lbl_eps8.text = "✓ EPS CPU 8P CONECTADO"
		lbl_eps8.modulate = Color(0.2, 1.0, 0.4)
		
		var tw = create_tween().set_parallel(true)
		tw.tween_property(cable_eps8, "position:y", cable_eps8.position.y + 45.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(cable_eps8, "modulate:a", 1.0, 0.35)
		
		current_state = State.CONNECT_ATX24
		btn_atx24.disabled = false
		lbl_atx24.text = "HAZ CLIC PARA CONECTAR ATX 24P"
		lbl_atx24.modulate = Color(1.0, 0.85, 0.2)
		_show_warning("✓ Cable EPS conectado. Por último conecta el arnés ATX de 24 pines.", Color(0.2, 1.0, 0.4))
		_update_status()
		return

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
	if current_state == State.SCREW_CHASSIS:
		if not screws_removed[idx]:
			return # Ya asegurado
			
		var req = 1 if screw_types[idx] == "cruz" else 2
		var tool_name = "Cruz (+)" if req == 1 else "Pala (-)"
		
		if GameManager.equipped_tool != req:
			_show_warning("Herramienta incorrecta: Este tornillo requiere Destornillador " + tool_name + " [Tecla " + str(req) + "]", Color(1.0, 0.3, 0.3))
			return
			
		screws_removed[idx] = false
		var btn = screw_buttons[idx]
		var icon = screw_icons[idx]
		
		var tw = create_tween().set_parallel(true)
		tw.tween_property(icon, "rotation_degrees", icon.rotation_degrees - 720.0, 0.35)
		tw.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.35)
		tw.tween_property(btn, "modulate:a", 1.0, 0.35)
		btn.disabled = true
		
		var all_screwed = true
		for r in screws_removed:
			if r:
				all_screwed = false
				break
				
		if all_screwed:
			current_state = State.CONNECT_EPS8
			btn_eps8.disabled = false
			lbl_eps8.text = "HAZ CLIC PARA CONECTAR EPS 8P"
			lbl_eps8.modulate = Color(1.0, 0.85, 0.2)
			_show_warning("✓ 4 tornillos de chasis asegurados. Ahora conecta el cable EPS de 8 pines.", Color(0.2, 1.0, 0.4))
			_update_status()
		else:
			_show_warning("✓ Tornillo de chasis ajustado.", Color(0.4, 1.0, 0.4))
		return

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
	tw.tween_property(psu_body, "position:x", default_psu_x + 240.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(psu_body, "modulate:a", 0.3, 0.6)
	
	await tw.finished
	GameManager.add_item_to_backpack({"name": "Fuente", "broken": true})
	old_part_extracted.emit()
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
		State.EMPTY_TUNNEL:
			status_label.text = "INSTALACIÓN: Haz clic en el botón para insertar la fuente nueva desde tu mochila."
			status_label.modulate = Color(1.0, 0.85, 0.2)
		State.SCREW_CHASSIS:
			status_label.text = "PASO 1 (INSTALACIÓN): Fija los 4 tornillos de anclaje traseros con [1] Cruz o [2] Pala."
			status_label.modulate = Color(1.0, 0.85, 0.2)
		State.CONNECT_EPS8:
			status_label.text = "PASO 2 (INSTALACIÓN): Haz clic sobre el conector EPS de 8 pines para energizar la CPU."
			status_label.modulate = Color(1.0, 0.4, 0.8)
		State.CONNECT_ATX24:
			status_label.text = "PASO 3 (INSTALACIÓN): Conecta el arnés principal ATX de 24 pines a la placa madre."
			status_label.modulate = Color(0.2, 1.0, 0.4)
		State.COMPLETED:
			status_label.text = "¡OPERACIÓN COMPLETADA! Fuente instalada y testeada con éxito."
			status_label.modulate = Color(0.2, 1.0, 0.4)
