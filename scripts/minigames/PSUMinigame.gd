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
var is_tutorial_mode: bool = false

var is_atx24_disconnected: bool = false
var is_eps8_disconnected: bool = false

var screw_types: Array[String] = ["cruz", "cruz", "cruz", "pala"]
var screws_removed: Array[bool] = [false, false, false, false]
var is_psu_slid_out: bool = false
var default_psu_x: float = 0.0

var is_dragging_psu: bool = false
var drag_start_x: float = 0.0

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

@onready var btn_tab_quitar: Button = $ModalControl/Panel/VBox/Header/GuidePanel/VBoxGuide/TabsBox/BtnTabQuitar
@onready var btn_tab_poner: Button = $ModalControl/Panel/VBox/Header/GuidePanel/VBoxGuide/TabsBox/BtnTabPoner
@onready var guide_text: Label = $ModalControl/Panel/VBox/Header/GuidePanel/VBoxGuide/GuideText

var screw_buttons: Array[Button] = []
var screw_icons: Array[TextureRect] = []

func _ready() -> void:
	layer = 12
	default_psu_x = psu_body.position.x
	_setup_screws()
	_setup_ui()
	_update_tool_buttons()
	
	if is_tutorial_mode:
		btn_tab_quitar.pressed.connect(func(): _select_guide_tab(0))
		btn_tab_poner.pressed.connect(func(): _select_guide_tab(1))
	else:
		var tabs = btn_tab_quitar.get_parent()
		if tabs:
			tabs.queue_free()
	
	if start_as_empty_slot:
		current_state = State.EMPTY_TUNNEL
		psu_body.visible = true
		psu_body.position.x = default_psu_x + 200.0
		psu_body.modulate = Color(0.3, 0.9, 1.0, 0.65)
		cable_atx24.modulate.a = 0.3
		cable_atx24.position.y -= 45.0
		cable_eps8.modulate.a = 0.3
		cable_eps8.position.y -= 45.0
		btn_atx24.disabled = true
		btn_eps8.disabled = true
		lbl_atx24.text = "ATX 24P (DESCONECTADO)"
		lbl_eps8.text = "EPS 8P (DESCONECTADO)"
		
		btn_slide_psu.visible = true
		btn_slide_psu.text = "⇪ INSTALAR FUENTE NUEVA (ARRASTRA O CLIC)"
		btn_slide_psu.pressed.disconnect(_on_slide_psu_pressed)
		btn_slide_psu.pressed.connect(_seat_new_psu)
		
		screws_removed = [true, true, true, true]
		for b in screw_buttons:
			b.visible = false
			b.disabled = true
		_select_guide_tab(1)
	else:
		btn_slide_psu.text = "▶ DESLIZAR FUENTE FUERA DEL TÚNEL"
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
			
	if idx == 0:
		guide_text.text = "PASOS DE DESMONTAJE (QUITAR): 1. Desconectar ATX 24P · 2. Desconectar EPS 8P · 3. Retirar 4 tornillos chasis con [1]/[2] · 4. Deslizar fuente"
		if is_tutorial_mode and (is_install_phase() or current_state == State.EMPTY_TUNNEL):
			_setup_quitar_phase()
	else:
		guide_text.text = "PASOS DE MONTAJE (CÓMO PONER AL REVÉS): 1. Deslizar fuente nueva en el túnel · 2. Ajustar 4 tornillos y conectar EPS 8P y ATX 24P (cualquier orden)"
		if is_tutorial_mode and (not is_install_phase() and current_state != State.EMPTY_TUNNEL):
			_setup_empty_tunnel_phase()

func _setup_quitar_phase() -> void:
	current_state = State.DISCONNECT_ATX24
	is_psu_slid_out = false
	psu_body.visible = true
	psu_body.position.x = default_psu_x
	psu_body.modulate = Color(1, 1, 1, 1)
	cable_atx24.visible = true
	cable_atx24.modulate.a = 1.0
	btn_atx24.disabled = false
	lbl_atx24.text = "ARNÉS ATX 24P (CLIC PARA DESCONECTAR)"
	is_atx24_disconnected = false
	cable_eps8.visible = true
	cable_eps8.modulate.a = 1.0
	btn_eps8.disabled = false
	lbl_eps8.text = "CABLE EPS 8P (CLIC PARA DESCONECTAR)"
	is_eps8_disconnected = false
	screws_removed = [false, false, false, false]
	for i in range(screw_buttons.size()):
		var b = screw_buttons[i]
		b.visible = true
		b.disabled = false
		b.modulate.a = 1.0
		if i < screw_icons.size():
			screw_icons[i].scale = Vector2(1, 1)
			screw_icons[i].rotation_degrees = 0.0
	btn_slide_psu.visible = false
	if btn_slide_psu.pressed.is_connected(_seat_new_psu):
		btn_slide_psu.pressed.disconnect(_seat_new_psu)
	if not btn_slide_psu.pressed.is_connected(_on_slide_psu_pressed):
		btn_slide_psu.pressed.connect(_on_slide_psu_pressed)
	_update_status()

func _setup_empty_tunnel_phase() -> void:
	current_state = State.EMPTY_TUNNEL
	psu_body.visible = true
	psu_body.position.x = default_psu_x + 200.0
	psu_body.modulate = Color(0.3, 0.9, 1.0, 0.65)
	cable_atx24.modulate.a = 0.3
	cable_eps8.modulate.a = 0.3
	btn_atx24.disabled = true
	btn_eps8.disabled = true
	lbl_atx24.text = "ATX 24P (DESCONECTADO)"
	lbl_eps8.text = "EPS 8P (DESCONECTADO)"
	btn_slide_psu.visible = true
	btn_slide_psu.disabled = false
	btn_slide_psu.text = "⇪ INSTALAR FUENTE NUEVA (ARRASTRA O CLIC)"
	if not btn_slide_psu.pressed.is_connected(_seat_new_psu):
		btn_slide_psu.pressed.connect(_seat_new_psu)
	if btn_slide_psu.pressed.is_connected(_on_slide_psu_pressed):
		btn_slide_psu.pressed.disconnect(_on_slide_psu_pressed)
	screws_removed = [true, true, true, true]
	for b in screw_buttons:
		b.visible = false
		b.disabled = true
	_update_status()

func _seat_new_psu() -> void:
	var found_idx = -1
	for i in range(GameManager.backpack.size()):
		var it = GameManager.backpack[i]
		if it.get("name") == "Fuente" and not it.get("broken", true):
			found_idx = i
			break
	if found_idx != -1:
		GameManager.remove_item_from_backpack(found_idx)
		
	psu_body.visible = true
	var tw = create_tween().set_parallel(true)
	tw.tween_property(psu_body, "position:x", default_psu_x, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(psu_body, "modulate", Color(1, 1, 1, 1), 0.3)
	
	btn_slide_psu.visible = false
	current_state = State.SCREW_CHASSIS
	
	# Habilitar simultáneamente tornillos y ambos cables (orden libre)
	screws_removed = [true, true, true, true]
	for i in range(4):
		var btn = screw_buttons[i]
		var icon = screw_icons[i]
		btn.visible = true
		btn.disabled = false
		btn.modulate.a = 0.5
		icon.scale = Vector2(0.5, 0.5)
		icon.rotation_degrees = 0.0
		
	is_eps8_disconnected = true
	cable_eps8.visible = true
	cable_eps8.modulate.a = 0.6
	btn_eps8.disabled = false
	lbl_eps8.text = "CABLE EPS 8P (CLIC PARA CONECTAR)"
	lbl_eps8.modulate = Color(1.0, 0.85, 0.2)
	
	is_atx24_disconnected = true
	cable_atx24.visible = true
	cable_atx24.modulate.a = 0.6
	btn_atx24.disabled = false
	lbl_atx24.text = "CABLE ATX 24P (CLIC PARA CONECTAR)"
	lbl_atx24.modulate = Color(1.0, 0.85, 0.2)
	
	_show_warning("✓ Fuente en el túnel. Ajusta tornillos y conecta cables en cualquier orden.", Color(0.2, 1.0, 0.4))
	_update_status()

func _on_psu_body_gui_input(event: InputEvent) -> void:
	if current_state == State.SLIDE_OUT_PSU:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging_psu = true
				drag_start_x = event.global_position.x
			else:
				if is_dragging_psu:
					is_dragging_psu = false
					var diff = event.global_position.x - drag_start_x
					if diff >= 30.0:
						_on_slide_psu_pressed()
					else:
						var tw = create_tween()
						tw.tween_property(psu_body, "position:x", default_psu_x, 0.2)
		elif event is InputEventMouseMotion and is_dragging_psu:
			var pull = clamp(event.global_position.x - drag_start_x, 0.0, 100.0)
			psu_body.position.x = default_psu_x + pull
			
	elif current_state == State.EMPTY_TUNNEL:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging_psu = true
				drag_start_x = event.global_position.x
			else:
				if is_dragging_psu:
					is_dragging_psu = false
					var diff = drag_start_x - event.global_position.x
					if diff >= 30.0:
						_seat_new_psu()
					else:
						var tw = create_tween()
						tw.tween_property(psu_body, "position:x", default_psu_x + 200.0, 0.2)
		elif event is InputEventMouseMotion and is_dragging_psu:
			var push = clamp(drag_start_x - event.global_position.x, 0.0, 180.0)
			psu_body.position.x = (default_psu_x + 200.0) - push

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
	
	psu_body.gui_input.connect(_on_psu_body_gui_input)
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

func is_install_phase() -> bool:
	return current_state in [State.SCREW_CHASSIS, State.CONNECT_EPS8, State.CONNECT_ATX24]

func _check_psu_install_completed() -> void:
	var all_screws = not (screws_removed[0] or screws_removed[1] or screws_removed[2] or screws_removed[3])
	var eps_done = not is_eps8_disconnected
	var atx_done = not is_atx24_disconnected
	if all_screws and eps_done and atx_done:
		current_state = State.COMPLETED
		_update_status()
		_show_warning("✓ ¡REPARACIÓN INTEGRAL SUPERADA! Has completado tanto el desmontaje como el montaje inverso.", Color(0.2, 1.0, 0.4))
		await get_tree().create_timer(1.6).timeout
		minigame_finished.emit(true)
	else:
		_update_status()

func _on_atx24_pressed() -> void:
	if is_install_phase():
		if not is_atx24_disconnected:
			return
		is_atx24_disconnected = false
		btn_atx24.disabled = true
		lbl_atx24.text = "✓ ATX 24P CONECTADO"
		lbl_atx24.modulate = Color(0.2, 1.0, 0.4)
		
		var tw = create_tween().set_parallel(true)
		tw.tween_property(cable_atx24, "position:y", cable_atx24.position.y + 45.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(cable_atx24, "modulate:a", 1.0, 0.35)
		
		_show_warning("✓ Arnés principal ATX 24P conectado con seguro.", Color(0.2, 1.0, 0.4))
		_check_psu_install_completed()
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
	if is_install_phase():
		if not is_eps8_disconnected:
			return
		is_eps8_disconnected = false
		btn_eps8.disabled = true
		lbl_eps8.text = "✓ EPS CPU 8P CONECTADO"
		lbl_eps8.modulate = Color(0.2, 1.0, 0.4)
		
		var tw = create_tween().set_parallel(true)
		tw.tween_property(cable_eps8, "position:y", cable_eps8.position.y + 45.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(cable_eps8, "modulate:a", 1.0, 0.35)
		
		_show_warning("✓ Cable EPS auxiliar de CPU conectado.", Color(0.2, 1.0, 0.4))
		_check_psu_install_completed()
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
	if is_install_phase():
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
		
		_show_warning("✓ Tornillo de chasis ajustado.", Color(0.4, 1.0, 0.4))
		_check_psu_install_completed()
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
	
	# Asegurar que haya una Fuente nueva en la mochila para la fase de colocación
	var has_new = false
	for it in GameManager.backpack:
		if it.get("name") == "Fuente" and not it.get("broken", true):
			has_new = true
			break
	if not has_new:
		GameManager.add_item_to_backpack({"name": "Fuente", "broken": false})
		
	psu_body.visible = true
	psu_body.position.x = default_psu_x + 200.0
	psu_body.modulate = Color(0.3, 0.9, 1.0, 0.65)
	current_state = State.EMPTY_TUNNEL
	_select_guide_tab(1)
	
	btn_slide_psu.visible = true
	btn_slide_psu.disabled = false
	btn_slide_psu.text = "⇪ INSTALAR FUENTE NUEVA (ARRASTRA O CLIC)"
	btn_slide_psu.pressed.disconnect(_on_slide_psu_pressed)
	btn_slide_psu.pressed.connect(_seat_new_psu)
	
	screws_removed = [true, true, true, true]
	for b in screw_buttons:
		b.visible = false
		b.disabled = true
		
	_show_warning("✓ FASE 1 (QUITAR) SUPERADA ➔ AHORA FASE 2: MONTAJE DEL REPUESTO (INVERSO)", Color(0.2, 1.0, 0.5))
	_update_status()

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
			status_label.text = "PASO 4: ¡Todo desconectado! Arrastra la fuente a la derecha o haz clic en el botón."
			status_label.modulate = Color(0.2, 1.0, 0.4)
		State.EMPTY_TUNNEL:
			status_label.text = "INSTALACIÓN: Arrastra la fuente nueva a la izquierda al túnel o haz clic en el botón."
			status_label.modulate = Color(1.0, 0.85, 0.2)
		State.SCREW_CHASSIS, State.CONNECT_EPS8, State.CONNECT_ATX24:
			var pending: Array[String] = []
			var s_rem = 0
			for r in screws_removed:
				if r: s_rem += 1
			if s_rem > 0: pending.append("Ajustar tornillos chasis (%d restantes)" % s_rem)
			if is_eps8_disconnected: pending.append("Conectar cable EPS 8P")
			if is_atx24_disconnected: pending.append("Conectar cable ATX 24P")
			status_label.text = "Fase Montaje: " + " · ".join(pending) + " (cualquier orden)."
			status_label.modulate = Color(0.2, 0.9, 1.0)
		State.COMPLETED:
			status_label.text = "¡OPERACIÓN COMPLETADA! Fuente instalada y testeada con éxito."
			status_label.modulate = Color(0.2, 1.0, 0.4)
