extends CanvasLayer

signal minigame_finished(success: bool)
signal old_part_extracted()

enum State {
	EXTRACT_SIDES,
	EXTRACT_CENTER,
	INSTALL_DRAG,
	COMPLETED
}

var current_state: State = State.EXTRACT_SIDES
var start_as_empty_slot: bool = false

# Estados de extracción de la RAM vieja (hacia arriba)
var left_unseated: bool = false
var right_unseated: bool = false

# Estados de instalación de la RAM nueva (desde arriba hacia abajo)
var top_left_done: bool = false
var top_right_done: bool = false
var top_center_done: bool = false

# Arrastre interactivo en el módulo (fase quitar)
var dragging_part: String = "" # "left", "right", "center"
var drag_start_pos: Vector2 = Vector2.ZERO

# Arrastre interactivo superior (fase poner)
var dragging_top_part: String = "" # "left", "right", "center"
var top_drag_start_y: float = 0.0

var default_seated_y: float = 82.0

const COLOR_RED = Color(1.0, 0.15, 0.25, 1.0)
const COLOR_GREEN = Color(0.2, 1.0, 0.45, 1.0)

# Nodos de la escena
@onready var modal_control: Control = $ModalControl
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var socket_area: Control = $ModalControl/Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea
@onready var socket_base: Panel = $ModalControl/Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/SocketBase
@onready var empty_slot_label: Label = $ModalControl/Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/SocketBase/EmptySlotLabel
@onready var ram_stick: TextureRect = $ModalControl/Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/RAMStick

# Zonas de extracción (en la RAM)
@onready var zone_left: Control = $ModalControl/Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/RAMStick/ZoneLeft
@onready var zone_right: Control = $ModalControl/Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/RAMStick/ZoneRight
@onready var zone_center: Control = $ModalControl/Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/RAMStick/ZoneCenter

@onready var lbl_left: Label = $ModalControl/Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/RAMStick/ZoneLeft/LblLeft
@onready var lbl_right: Label = $ModalControl/Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/RAMStick/ZoneRight/LblRight
@onready var lbl_center: Label = $ModalControl/Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/RAMStick/ZoneCenter/LblCenter

# Zonas de instalación inversa (arriba en el recuadro, sin la RAM)
@onready var install_top_area: Control = $ModalControl/Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/InstallTopArea
@onready var top_zone_left: Control = $ModalControl/Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/InstallTopArea/TopZoneLeft
@onready var top_zone_center: Control = $ModalControl/Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/InstallTopArea/TopZoneCenter
@onready var top_zone_right: Control = $ModalControl/Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/InstallTopArea/TopZoneRight

@onready var lbl_top_left: Label = $ModalControl/Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/InstallTopArea/TopZoneLeft/LblTopLeft
@onready var lbl_top_center: Label = $ModalControl/Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/InstallTopArea/TopZoneCenter/LblTopCenter
@onready var lbl_top_right: Label = $ModalControl/Panel/VBox/ContentHBox/SocketAreaContainer/SocketArea/InstallTopArea/TopZoneRight/LblTopRight

# Mochila y pestañas
@onready var backpack_items_box: VBoxContainer = $ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/ItemsContainer
@onready var backpack_hint: Label = $ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/BackpackHint
@onready var btn_tab_quitar: Button = $ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/TabsBox/BtnTabQuitar
@onready var btn_tab_poner: Button = $ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/TabsBox/BtnTabPoner
@onready var guide_text: Label = $ModalControl/Panel/VBox/ContentHBox/BackpackPanel/Margin/VBox/GuideText
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel

func _ready() -> void:
	layer = 12
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	
	# Inputs de extracción en la RAM
	zone_left.gui_input.connect(func(event): _handle_zone_input("left", event))
	zone_right.gui_input.connect(func(event): _handle_zone_input("right", event))
	zone_center.gui_input.connect(func(event): _handle_zone_input("center", event))
	
	# Inputs de instalación en la parte superior
	top_zone_left.gui_input.connect(func(event): _handle_top_zone_input("left", event))
	top_zone_right.gui_input.connect(func(event): _handle_top_zone_input("right", event))
	top_zone_center.gui_input.connect(func(event): _handle_top_zone_input("center", event))
	
	GameManager.backpack_updated.connect(_on_backpack_changed)
	
	btn_tab_quitar.pressed.connect(func(): _select_guide_tab(0))
	btn_tab_poner.pressed.connect(func(): _select_guide_tab(1))
	
	if start_as_empty_slot:
		_start_install_drag_phase()
	else:
		_select_guide_tab(0)
		ram_stick.visible = true
		empty_slot_label.visible = false
		install_top_area.visible = false
		current_state = State.EXTRACT_SIDES
		_init_base_position.call_deferred()
		
	_update_ui_state()
	_refresh_backpack_ui()

func _select_guide_tab(idx: int) -> void:
	if idx == 0:
		btn_tab_quitar.modulate = Color(1.2, 1.2, 0.4, 1.0)
		btn_tab_poner.modulate = Color(0.7, 0.7, 0.7, 0.7)
		guide_text.text = "FASE 1 (QUITAR): Arrastra hacia arriba lados izq y der (un poquitito). Luego arrastra el centro para retirar la RAM."
		_setup_quitar_phase()
	else:
		btn_tab_quitar.modulate = Color(0.7, 0.7, 0.7, 0.7)
		btn_tab_poner.modulate = Color(0.2, 1.0, 0.5, 1.0)
		guide_text.text = "FASE 2 (PONER AL REVÉS): El zócalo está vacío. Arrastra hacia abajo las flechas superiores (izq y der) y al tercer jalón (centro) la RAM baja y se engancha."
		_start_install_drag_phase()

func _setup_quitar_phase() -> void:
	current_state = State.EXTRACT_SIDES
	ram_stick.visible = true
	ram_stick.modulate = Color(1, 1, 1, 1)
	ram_stick.position.y = _get_base_y()
	ram_stick.rotation_degrees = 0.0
	empty_slot_label.visible = false
	install_top_area.visible = false
	left_unseated = false
	right_unseated = false
	_update_ui_state()

func _init_base_position() -> void:
	await get_tree().process_frame
	if ram_stick != null and ram_stick.position.y > 0.0:
		default_seated_y = ram_stick.position.y

func _on_backpack_changed(_items: Array) -> void:
	_refresh_backpack_ui()

func _refresh_backpack_ui() -> void:
	if not backpack_items_box:
		return
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
		
	var found_ram = false
	for i in range(GameManager.backpack.size()):
		var item = GameManager.backpack[i]
		var item_btn = Button.new()
		
		if item.get("name") == "RAM":
			if item.get("broken", true):
				item_btn.text = "%d. RAM (Quemada/Rota)" % (i + 1)
				item_btn.modulate = Color(1, 0.3, 0.4, 0.85)
				item_btn.disabled = true
			else:
				found_ram = true
				item_btn.text = "⇪ RAM DDR5 (NUEVA)\n[Lista para instalar]"
				item_btn.modulate = Color(0.0, 1.0, 0.6, 1.0)
				item_btn.pressed.connect(func():
					_show_floating_feedback("¡Arrastra las flechas superiores rojas hacia abajo!", Color(1.0, 0.85, 0.2))
				)
		else:
			item_btn.text = "%d. %s" % [i + 1, item.get("name", "Pieza")]
			item_btn.modulate = Color(0.6, 0.7, 0.8, 0.7)
			item_btn.disabled = true
			
		backpack_items_box.add_child(item_btn)
		
	if current_state == State.INSTALL_DRAG:
		if found_ram:
			backpack_hint.text = "¡Arrastra hacia abajo las flechas superiores (izq/der y luego centro)!"
			backpack_hint.modulate = Color(0.0, 1.0, 0.5, 1.0)
		else:
			backpack_hint.text = "No tienes RAM nueva en la mochila.\nSal al taller a buscar repuestos."
			backpack_hint.modulate = Color(1.0, 0.4, 0.4, 1.0)

# =============================================================================
# FASE 1: DESMONTAJE (QUITAR)
# =============================================================================
func _update_removal_indicators() -> void:
	match current_state:
		State.EXTRACT_SIDES:
			lbl_left.text = "▲\n●"
			lbl_left.modulate = COLOR_GREEN if left_unseated else COLOR_RED
			lbl_right.text = "▲\n●"
			lbl_right.modulate = COLOR_GREEN if right_unseated else COLOR_RED
			lbl_center.text = "▲\n●"
			lbl_center.modulate = COLOR_RED
		State.EXTRACT_CENTER:
			lbl_left.text = "▲\n●"
			lbl_left.modulate = COLOR_GREEN
			lbl_right.text = "▲\n●"
			lbl_right.modulate = COLOR_GREEN
			lbl_center.text = "▲\n●"
			lbl_center.modulate = COLOR_RED
		_:
			pass

func _update_ui_state() -> void:
	if current_state == State.INSTALL_DRAG:
		_update_install_status()
		return
		
	_update_removal_indicators()
	match current_state:
		State.EXTRACT_SIDES:
			if not left_unseated and not right_unseated:
				status_label.text = "Paso 1: Arrastra hacia ARRIBA el lado IZQUIERDO y DERECHO (se levantará un poquitito)."
				status_label.modulate = Color(1.0, 0.85, 0.2, 1)
			elif left_unseated and not right_unseated:
				status_label.text = "¡Lado izquierdo listo! Ahora arrastra el lado DERECHO hacia ARRIBA."
				status_label.modulate = Color(0.0, 0.9, 1.0, 1)
			elif right_unseated and not left_unseated:
				status_label.text = "¡Lado derecho listo! Ahora arrastra el lado IZQUIERDO hacia ARRIBA."
				status_label.modulate = Color(0.0, 0.9, 1.0, 1)
			else:
				current_state = State.EXTRACT_CENTER
				_update_ui_state()
		State.EXTRACT_CENTER:
			status_label.text = "¡Ambos lados liberados! Ahora arrastra el CENTRO hacia ARRIBA para retirarla."
			status_label.modulate = Color(0.0, 1.0, 0.5, 1)
		State.COMPLETED:
			status_label.text = "¡RAM nueva completamente instalada y enganchada!"
			status_label.modulate = Color(0.0, 1.0, 0.4, 1)

func _handle_zone_input(part: String, event: InputEvent) -> void:
	if current_state != State.EXTRACT_SIDES and current_state != State.EXTRACT_CENTER:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging_part = part
			drag_start_pos = event.global_position
		else:
			if dragging_part == part:
				var delta_y = event.global_position.y - drag_start_pos.y
				_process_removal_drag_release(part, delta_y)
				dragging_part = ""

func _process_removal_drag_release(part: String, delta_y: float) -> void:
	var threshold = 25.0
	var pulled_up = -delta_y >= threshold
	
	if part == "left":
		if pulled_up and not left_unseated:
			left_unseated = true
			_animate_stick_tilt_up()
			_show_floating_feedback("✓ Lado izquierdo descalzado", COLOR_GREEN)
			_update_ui_state()
	elif part == "right":
		if pulled_up and not right_unseated:
			right_unseated = true
			_animate_stick_tilt_up()
			_show_floating_feedback("✓ Lado derecho descalzado", COLOR_GREEN)
			_update_ui_state()
	elif part == "center":
		if current_state == State.EXTRACT_CENTER:
			if pulled_up:
				_complete_ram_removal()
		else:
			GameManager.register_error(2.0)
			status_label.text = "¡Atascado! Primero arrastra el lado izquierdo y el derecho hacia arriba."
			status_label.modulate = Color(1, 0.2, 0.3, 1)
			_shake_node(lbl_center)

func _get_base_y() -> float:
	if ram_stick != null and ram_stick.position.y > 0.0:
		default_seated_y = ram_stick.position.y
	return default_seated_y

func _animate_stick_tilt_up() -> void:
	var tween = create_tween().set_parallel(true)
	var base_y = _get_base_y()
	if left_unseated and not right_unseated:
		tween.tween_property(ram_stick, "rotation_degrees", -0.8, 0.15)
		tween.tween_property(ram_stick, "position:y", base_y - 2.0, 0.15)
	elif right_unseated and not left_unseated:
		tween.tween_property(ram_stick, "rotation_degrees", 0.8, 0.15)
		tween.tween_property(ram_stick, "position:y", base_y - 2.0, 0.15)
	elif left_unseated and right_unseated:
		tween.tween_property(ram_stick, "rotation_degrees", 0.0, 0.15)
		tween.tween_property(ram_stick, "position:y", base_y - 3.0, 0.15)

func _complete_ram_removal() -> void:
	lbl_center.modulate = COLOR_GREEN
	var tween = create_tween().set_parallel(true)
	var target_y = _get_base_y() - 100.0
	tween.tween_property(ram_stick, "position:y", target_y, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ram_stick, "modulate:a", 0.0, 0.30)
	tween.chain().tween_callback(func():
		ram_stick.visible = false
		empty_slot_label.visible = true
		GameManager.add_item_to_backpack({"name": "RAM", "broken": true})
		old_part_extracted.emit()
		
		# Asegurar que haya una RAM nueva en la mochila para la fase de colocación
		var has_new = false
		for it in GameManager.backpack:
			if it.get("name") == "RAM" and not it.get("broken", true):
				has_new = true
				break
		if not has_new:
			GameManager.add_item_to_backpack({"name": "RAM", "broken": false})
			
		_select_guide_tab(1)
		_start_install_drag_phase()
	)

# =============================================================================
# FASE 2: MONTAJE INVERSO (PONER)
# La RAM NO APARECE en el zócalo. Las flechas rojas salen arriba en el recuadro.
# El jugador arrastra hacia abajo y al tercer jalón (centro) aparece la RAM y se engancha.
# =============================================================================
func _start_install_drag_phase() -> void:
	current_state = State.INSTALL_DRAG
	ram_stick.visible = false
	empty_slot_label.visible = true
	
	install_top_area.visible = true
	install_top_area.modulate.a = 1.0
	
	top_left_done = false
	top_right_done = false
	top_center_done = false
	
	lbl_top_left.text = "▼\n●"
	lbl_top_left.modulate = COLOR_RED
	lbl_top_left.position.y = 0.0
	
	lbl_top_right.text = "▼\n●"
	lbl_top_right.modulate = COLOR_RED
	lbl_top_right.position.y = 0.0
	
	lbl_top_center.text = "▼\n●"
	lbl_top_center.modulate = COLOR_RED
	lbl_top_center.position.y = 0.0
	
	_show_floating_feedback("✓ FASE 1 SUPERADA ➔ MONTAJE INVERSO: ARRASTRA FLECHAS HACIA ABAJO", COLOR_GREEN)
	_update_ui_state()
	_refresh_backpack_ui()

func _update_install_status() -> void:
	lbl_top_left.modulate = COLOR_GREEN if top_left_done else COLOR_RED
	lbl_top_right.modulate = COLOR_GREEN if top_right_done else COLOR_RED
	lbl_top_center.modulate = COLOR_GREEN if top_center_done else COLOR_RED
	
	if not top_left_done and not top_right_done:
		status_label.text = "Fase Montaje: Arrastra hacia ABAJO las flechas superiores (IZQUIERDA y DERECHA, cualquier orden)."
		status_label.modulate = Color(1.0, 0.85, 0.2, 1)
	elif top_left_done and not top_right_done:
		status_label.text = "¡Izquierda lista! Ahora arrastra hacia ABAJO la flecha superior DERECHA."
		status_label.modulate = Color(0.0, 0.9, 1.0, 1)
	elif top_right_done and not top_left_done:
		status_label.text = "¡Derecha lista! Ahora arrastra hacia ABAJO la flecha superior IZQUIERDA."
		status_label.modulate = Color(0.0, 0.9, 1.0, 1)
	elif top_left_done and top_right_done and not top_center_done:
		status_label.text = "¡Ambos lados listos! Arrastra el CENTRO hacia ABAJO para enganchar la RAM en el zócalo."
		status_label.modulate = Color(0.2, 1.0, 0.5, 1)

func _handle_top_zone_input(part: String, event: InputEvent) -> void:
	if current_state != State.INSTALL_DRAG:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging_top_part = part
			top_drag_start_y = event.global_position.y
		else:
			if dragging_top_part == part:
				var delta_y = event.global_position.y - top_drag_start_y
				_process_top_drag_release(part, delta_y)
				dragging_top_part = ""
	elif event is InputEventMouseMotion and dragging_top_part == part:
		var push = clamp(event.global_position.y - top_drag_start_y, 0.0, 22.0)
		_animate_top_label_drag(part, push)

func _animate_top_label_drag(part: String, push: float) -> void:
	if part == "left" and not top_left_done:
		lbl_top_left.position.y = push
	elif part == "right" and not top_right_done:
		lbl_top_right.position.y = push
	elif part == "center" and not top_center_done:
		lbl_top_center.position.y = push

func _process_top_drag_release(part: String, delta_y: float) -> void:
	var threshold = 22.0
	var pulled_down = delta_y >= threshold
	
	if part == "left":
		if pulled_down and not top_left_done:
			top_left_done = true
			var tw = create_tween()
			tw.tween_property(lbl_top_left, "position:y", 10.0, 0.15).set_trans(Tween.TRANS_BACK)
			_show_floating_feedback("✓ Traba izquierda hacia abajo", COLOR_GREEN)
			_update_ui_state()
		else:
			if not top_left_done:
				var tw = create_tween()
				tw.tween_property(lbl_top_left, "position:y", 0.0, 0.15)
				
	elif part == "right":
		if pulled_down and not top_right_done:
			top_right_done = true
			var tw = create_tween()
			tw.tween_property(lbl_top_right, "position:y", 10.0, 0.15).set_trans(Tween.TRANS_BACK)
			_show_floating_feedback("✓ Traba derecha hacia abajo", COLOR_GREEN)
			_update_ui_state()
		else:
			if not top_right_done:
				var tw = create_tween()
				tw.tween_property(lbl_top_right, "position:y", 0.0, 0.15)
				
	elif part == "center":
		if not top_left_done or not top_right_done:
			GameManager.register_error(2.0)
			status_label.text = "¡Primero arrastra hacia ABAJO el lado izquierdo y el derecho!"
			status_label.modulate = Color(1, 0.2, 0.3, 1)
			_shake_node(lbl_top_center)
			var tw = create_tween()
			tw.tween_property(lbl_top_center, "position:y", 0.0, 0.15)
		else:
			if pulled_down and not top_center_done:
				top_center_done = true
				var tw = create_tween()
				tw.tween_property(lbl_top_center, "position:y", 10.0, 0.15)
				# ¡TERCER JALÓN: Aparece la RAM y se engancha en lo gris!
				_latch_ram_into_socket()
			else:
				if not top_center_done:
					var tw = create_tween()
					tw.tween_property(lbl_top_center, "position:y", 0.0, 0.15)

func _latch_ram_into_socket() -> void:
	current_state = State.COMPLETED
	
	# Retirar el repuesto de la mochila
	for i in range(GameManager.backpack.size()):
		var it = GameManager.backpack[i]
		if it.get("name") == "RAM" and not it.get("broken", true):
			GameManager.remove_item_from_backpack(i)
			break
			
	empty_slot_label.visible = false
	
	# La RAM aparece arriba y se desliza hacia abajo para engancharse en la base gris
	ram_stick.visible = true
	ram_stick.rotation_degrees = 0.0
	ram_stick.modulate = Color(1, 1, 1, 0.0)
	ram_stick.position.y = default_seated_y - 100.0
	
	# Desvanecer las flechas superiores
	var tw_top = create_tween()
	tw_top.tween_property(install_top_area, "modulate:a", 0.0, 0.2)
	tw_top.tween_callback(func(): install_top_area.visible = false)
	
	# Animación de enganche ("se engancha en lo gris")
	var tw = create_tween().set_parallel(true)
	tw.tween_property(ram_stick, "modulate:a", 1.0, 0.15)
	tw.tween_property(ram_stick, "position:y", default_seated_y, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Pulso visual en la base gris al trabarse
	var tw_base = create_tween()
	tw_base.tween_interval(0.2)
	tw_base.tween_property(socket_base, "modulate", Color(0.2, 1.3, 0.6, 1.0), 0.12)
	tw_base.tween_property(socket_base, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)
	
	# En la RAM, los indicadores se ponen verdes asegurados
	lbl_left.text = "●"
	lbl_left.modulate = COLOR_GREEN
	lbl_center.text = "●"
	lbl_center.modulate = COLOR_GREEN
	lbl_right.text = "●"
	lbl_right.modulate = COLOR_GREEN
	
	_show_floating_feedback("✓ ¡CLICK! RAM ENGANCHADA AL ZÓCALO CON ÉXITO", COLOR_GREEN)
	status_label.text = "¡RAM NUEVA INSTALADA Y ENGANCHADA CON TOTAL ÉXITO!"
	status_label.modulate = COLOR_GREEN
	
	await get_tree().create_timer(1.3).timeout
	minigame_finished.emit(true)

func _shake_node(n: CanvasItem) -> void:
	if not n: return
	var orig_x = n.position.x
	var tw = create_tween()
	tw.tween_property(n, "position:x", orig_x - 6.0, 0.04)
	tw.tween_property(n, "position:x", orig_x + 6.0, 0.04)
	tw.tween_property(n, "position:x", orig_x - 3.0, 0.04)
	tw.tween_property(n, "position:x", orig_x, 0.04)

func _show_floating_feedback(msg: String, color: Color) -> void:
	var lbl = Label.new()
	lbl.text = msg
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("shadow_outline_size", 6)
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var vp_size = modal_control.size if modal_control else Vector2(960, 560)
	lbl.position = Vector2(vp_size.x * 0.5 - 200.0, vp_size.y * 0.5 - 150.0)
	lbl.size = Vector2(400, 30)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if modal_control:
		modal_control.add_child(lbl)
	else:
		add_child(lbl)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 25.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.8).set_delay(0.2)
	tw.chain().tween_callback(lbl.queue_free)
