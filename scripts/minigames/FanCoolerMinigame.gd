extends CanvasLayer

# =============================================================================
# MINIJUEGO: DESMONTAJE Y MANTENIMIENTO DEL FAN COOLER
# =============================================================================

signal minigame_finished(success: bool)
signal old_part_extracted()

enum State {
	IN_PROGRESS,
	READY_TO_EXTRACT,
	EXTRACTING,
	EMPTY_SOCKET,
	FASTEN_SCREWS,
	CONNECT_CABLE,
	COMPLETED
}

var current_state: State = State.IN_PROGRESS
var start_as_empty_slot: bool = false
var is_tutorial_mode: bool = false
var is_cable_disconnected: bool = false
var screws_fastened: Array[bool] = [false, false, false, false]

# Herramienta requerida para cada tornillo (puede ser cruz o pala)
# Tornillos: 0: Top-Left, 1: Top-Right, 2: Bottom-Left, 3: Bottom-Right
var screw_types: Array[String] = ["cruz", "cruz", "pala", "cruz"]
var screws_removed: Array[bool] = [false, false, false, false]
var total_screws: int = 4

# Referencias a texturas
var tex_cooler_connected = preload("res://pixel art/fancooler conectado.png")
var tex_cooler_disconnected = preload("res://pixel art/fancooler.png")
var tex_screw_cruz = preload("res://pixel art/tornillo de cruz.png")
var tex_screw_pala = preload("res://pixel art/tornillo de pala.png")
var tex_cooler_frame = preload("res://pixel art/cuadro de fancoolerpng.png")

# Nodos de la escena
@onready var modal_control: Control = $ModalControl
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var btn_tool_1: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool1
@onready var btn_tool_2: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool2
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel

@onready var socket_frame: TextureRect = $ModalControl/Panel/VBox/ContentHBox/WorkArea/SocketFrame
@onready var cooler_sprite: TextureRect = $ModalControl/Panel/VBox/ContentHBox/WorkArea/CoolerSprite
@onready var cable_button: Button = $ModalControl/Panel/VBox/ContentHBox/WorkArea/CableArea/BtnCable
@onready var cable_hint: Label = $ModalControl/Panel/VBox/ContentHBox/WorkArea/CableArea/CableHint
@onready var screws_container: Control = $ModalControl/Panel/VBox/ContentHBox/WorkArea/ScrewsContainer
@onready var cooler_extract_btn: Button = $ModalControl/Panel/VBox/ContentHBox/WorkArea/BtnExtractCooler

@onready var btn_tab_quitar: Button = $ModalControl/Panel/VBox/ContentHBox/SideInfo/Margin/VBox/TabsBox/BtnTabQuitar
@onready var btn_tab_poner: Button = $ModalControl/Panel/VBox/ContentHBox/SideInfo/Margin/VBox/TabsBox/BtnTabPoner
@onready var instructions_text: Label = $ModalControl/Panel/VBox/ContentHBox/SideInfo/Margin/VBox/Text
@onready var backpack_box: VBoxContainer = $ModalControl/Panel/VBox/ContentHBox/SideInfo/Margin/VBox/BackpackBox
@onready var backpack_items_box: VBoxContainer = $ModalControl/Panel/VBox/ContentHBox/SideInfo/Margin/VBox/BackpackBox/ItemsContainer
@onready var backpack_hint: Label = $ModalControl/Panel/VBox/ContentHBox/SideInfo/Margin/VBox/BackpackBox/BackpackHint

# Lista de botones de tornillos
var screw_buttons: Array[Button] = []
var screw_icons: Array[TextureRect] = []

var default_cooler_pos: Vector2 = Vector2.ZERO
var is_dragging_cooler: bool = false
var drag_start_y: float = 0.0

func _ready() -> void:
	layer = 12
	_setup_screw_types()
	_setup_ui()
	_update_tool_buttons()
	
	default_cooler_pos = cooler_sprite.position
	cooler_sprite.gui_input.connect(_on_cooler_sprite_gui_input)
	
	GameManager.backpack_updated.connect(_on_backpack_changed)
	
	btn_tab_quitar.pressed.connect(func(): _select_tab(0))
	btn_tab_poner.pressed.connect(func(): _select_tab(1))
	
	if not is_tutorial_mode and btn_tab_quitar.get_parent():
		btn_tab_quitar.get_parent().visible = false
	
	if start_as_empty_slot:
		current_state = State.EMPTY_SOCKET
		_setup_empty_socket_visual()
		_select_tab(1)
		_refresh_backpack_ui()
	else:
		_select_tab(0)
		_refresh_backpack_ui()
		
	_update_status()

func _setup_empty_socket_visual() -> void:
	screws_container.visible = false
	cable_button.visible = false
	cable_hint.visible = false
	cooler_extract_btn.visible = false
	
	cooler_sprite.visible = true
	cooler_sprite.texture = tex_cooler_disconnected
	cooler_sprite.modulate = Color(0.2, 0.9, 1.0, 0.6)
	cooler_sprite.position = default_cooler_pos + Vector2(0, -90.0)

func _on_cooler_sprite_gui_input(event: InputEvent) -> void:
	if current_state != State.EMPTY_SOCKET:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging_cooler = true
			drag_start_y = event.global_position.y
		else:
			if is_dragging_cooler:
				is_dragging_cooler = false
				var diff_y = event.global_position.y - drag_start_y
				if diff_y >= 30.0 or cooler_sprite.position.distance_to(default_cooler_pos) < 60.0:
					_seat_cooler_into_socket()
				else:
					var tw = create_tween()
					tw.tween_property(cooler_sprite, "position", default_cooler_pos + Vector2(0, -90.0), 0.2)
	elif event is InputEventMouseMotion and is_dragging_cooler:
		var push = clamp(event.global_position.y - drag_start_y, 0.0, 110.0)
		cooler_sprite.position = default_cooler_pos + Vector2(0, -90.0 + push)

func _seat_cooler_into_socket() -> void:
	# Retirar repuesto de la mochila si existe
	for i in range(GameManager.backpack.size()):
		var it = GameManager.backpack[i]
		if it.get("name") == "Fan Cooler" and not it.get("broken", true):
			GameManager.remove_item_from_backpack(i)
			break
			
	var tw = create_tween()
	tw.tween_property(cooler_sprite, "position", default_cooler_pos, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(cooler_sprite, "modulate", Color(1, 1, 1, 1), 0.25)
	
	screws_container.visible = true
	screws_fastened = [false, false, false, false]
	for i in range(4):
		var btn = screw_buttons[i]
		var icon = screw_icons[i]
		btn.visible = true
		btn.disabled = false
		icon.modulate = Color(1.0, 1.0, 1.0, 0.7)
		icon.rotation = 0.0
		icon.scale = Vector2(1, 1)
		
	cable_button.visible = true
	cable_hint.visible = true
	cable_hint.modulate.a = 1.0
	cable_hint.text = "🔌 CABLE PWM (CLIC PARA CONECTAR)"
	is_cable_disconnected = true
	
	current_state = State.FASTEN_SCREWS
	_show_floating_feedback("✓ ¡FAN COOLER MONTADO! COLOCA LOS TORNILLOS O CONECTA EL CABLE EN CUALQUIER ORDEN", Color(0.2, 1.0, 0.5))
	_update_status()
	_refresh_backpack_ui()

func _select_tab(idx: int) -> void:
	if idx == 0:
		btn_tab_quitar.modulate = Color(1.2, 1.2, 0.4, 1.0)
		btn_tab_poner.modulate = Color(0.7, 0.7, 0.7, 0.7)
		instructions_text.text = "• FASE 1: DESMONTAJE (QUITAR)\n\n1. Desconecta el cable PWM de alimentación (clic en el cable).\n2. Identifica la cabeza de cada tornillo: Cruz [1] o Pala [2].\n3. Retira los 4 tornillos de sujeción.\n4. Al quedar libre, presiona 'EXTRAER DISIPADOR'."
		if current_state == State.EMPTY_SOCKET or current_state == State.FASTEN_SCREWS or current_state == State.CONNECT_CABLE:
			_setup_quitar_phase()
	else:
		btn_tab_quitar.modulate = Color(0.7, 0.7, 0.7, 0.7)
		btn_tab_poner.modulate = Color(0.2, 1.0, 0.5, 1.0)
		instructions_text.text = "• FASE 2: MONTAJE INVERSO (PONER)\n\n1. Arrastra el Fan Cooler nuevo hacia el zócalo.\n2. Ajusta los 4 tornillos con Cruz [1] o Pala [2].\n3. Conecta el cable PWM (tornillos y cable en cualquier orden)."
		if current_state != State.EMPTY_SOCKET and current_state != State.FASTEN_SCREWS and current_state != State.CONNECT_CABLE:
			current_state = State.EMPTY_SOCKET
			_setup_empty_socket_visual()
			_update_status()
			_refresh_backpack_ui()

func _setup_quitar_phase() -> void:
	current_state = State.IN_PROGRESS
	cooler_sprite.visible = true
	cooler_sprite.modulate = Color(1, 1, 1, 1)
	cooler_sprite.position = default_cooler_pos
	cooler_sprite.texture = tex_cooler_connected
	is_cable_disconnected = false
	cable_button.visible = true
	cable_hint.visible = true
	cable_hint.modulate.a = 1.0
	cable_hint.text = "🔌 CABLE (CLIC PARA DESCONECTAR)"
	screws_container.visible = true
	for i in range(4):
		screws_removed[i] = false
		if i < screw_buttons.size():
			screw_buttons[i].visible = true
			screw_buttons[i].disabled = false
		if i < screw_icons.size():
			screw_icons[i].modulate.a = 1.0
			screw_icons[i].rotation = 0.0
			screw_icons[i].scale = Vector2(1, 1)
	cooler_extract_btn.visible = false
	_update_status()
	_refresh_backpack_ui()

func _on_backpack_changed(_items: Array) -> void:
	_refresh_backpack_ui()

func _refresh_backpack_ui() -> void:
	if not backpack_items_box:
		return
		
	for child in backpack_items_box.get_children():
		child.queue_free()
		
	if GameManager.backpack.is_empty():
		var lbl = Label.new()
		lbl.text = "[ Mochila Vacía ]"
		lbl.modulate = Color(0.6, 0.6, 0.7, 0.8)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		backpack_items_box.add_child(lbl)
		backpack_hint.text = "Sin repuestos en inventario"
		return
		
	var found_cooler = false
	for i in range(GameManager.backpack.size()):
		var item = GameManager.backpack[i]
		var item_btn = Button.new()
		
		if item.get("name") == "Fan Cooler":
			if item.get("broken", true):
				item_btn.text = "%d. Fan Cooler (Quemado)" % (i + 1)
				item_btn.modulate = Color(1, 0.3, 0.4, 0.85)
				item_btn.disabled = true
			else:
				found_cooler = true
				item_btn.text = "⇪ FAN COOLER (NUEVO)\n[Clic para instalar]"
				item_btn.modulate = Color(0.0, 1.0, 0.6, 1.0)
				item_btn.pressed.connect(func(): _insert_cooler_from_backpack(i))
		else:
			item_btn.text = "%d. %s" % [i + 1, item.get("name", "Pieza")]
			item_btn.modulate = Color(0.6, 0.7, 0.8, 0.7)
			item_btn.disabled = true
			
		backpack_items_box.add_child(item_btn)
		
	if current_state == State.EMPTY_SOCKET:
		if found_cooler:
			backpack_hint.text = "¡Haz clic en el Fan Cooler nuevo para montarlo en la CPU!"
			backpack_hint.modulate = Color(0.0, 1.0, 0.5, 1.0)
		else:
			backpack_hint.text = "No tienes Fan Cooler nuevo en la mochila.\nSal al taller y tómalo de la caja de repuestos."
			backpack_hint.modulate = Color(1.0, 0.4, 0.4, 1.0)

func _insert_cooler_from_backpack(_idx: int) -> void:
	if current_state != State.EMPTY_SOCKET:
		return
	_seat_cooler_into_socket()

func _setup_screw_types() -> void:
	# Generar una distribución variada de tornillos Cruz y Pala
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in range(4):
		screw_types[i] = "cruz" if rng.randf() > 0.45 else "pala"
		screws_removed[i] = false

func _setup_ui() -> void:
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	
	# Herramientas
	btn_tool_1.pressed.connect(func(): GameManager.select_tool(1))
	btn_tool_2.pressed.connect(func(): GameManager.select_tool(2))
	GameManager.tool_selected.connect(_on_tool_selected)
	
	# Desconexión del cable
	cable_button.pressed.connect(_on_cable_disconnected)
	
	# Botón para extraer el fan cooler cuando esté libre
	cooler_extract_btn.pressed.connect(_on_extract_cooler_pressed)
	cooler_extract_btn.visible = false
	
	# Texturas base
	cooler_sprite.texture = tex_cooler_connected
	socket_frame.texture = tex_cooler_frame
	
	# Configurar los 4 tornillos sobre el sprite del fan cooler
	screw_buttons.clear()
	screw_icons.clear()
	for i in range(4):
		var btn = screws_container.get_node_or_null("Screw" + str(i + 1))
		if btn:
			var icon = btn.get_node_or_null("Icon") as TextureRect
			if icon:
				icon.texture = tex_screw_cruz if screw_types[i] == "cruz" else tex_screw_pala
				screw_icons.append(icon)
			btn.pressed.connect(_on_screw_clicked.bind(i))
			screw_buttons.append(btn)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_1:
			GameManager.select_tool(1)
		elif event.keycode == KEY_2:
			GameManager.select_tool(2)
		elif event.keycode == KEY_ESCAPE:
			minigame_finished.emit(false)

func _on_tool_selected(tool_id: int) -> void:
	_update_tool_buttons()

func _update_tool_buttons() -> void:
	var t = GameManager.equipped_tool
	btn_tool_1.modulate = Color(1.2, 1.2, 1.2, 1.0) if t == 1 else Color(0.65, 0.65, 0.7, 0.8)
	btn_tool_2.modulate = Color(1.2, 1.2, 1.2, 1.0) if t == 2 else Color(0.65, 0.65, 0.7, 0.8)

func _on_cable_disconnected() -> void:
	if current_state == State.FASTEN_SCREWS or current_state == State.CONNECT_CABLE:
		if not is_cable_disconnected:
			return
		is_cable_disconnected = false
		cooler_sprite.texture = tex_cooler_connected
		cable_button.visible = false
		cable_hint.visible = false
		_show_floating_feedback("¡CABLE CONECTADO CON ÉXITO!", Color(0.2, 1.0, 0.5))
		_check_install_completed()
		return
		
	if is_cable_disconnected:
		return
		
	is_cable_disconnected = true
	
	# Animación de desconexión del cable
	var tw = create_tween()
	tw.tween_property(cable_hint, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func():
		cable_button.visible = false
		cable_hint.visible = false
		cooler_sprite.texture = tex_cooler_disconnected
		_check_readiness()
	)
	
	_show_floating_feedback("¡CABLE DESCONECTADO!", Color(0.0, 1.0, 0.85))

func _on_screw_clicked(index: int) -> void:
	if current_state == State.FASTEN_SCREWS or current_state == State.CONNECT_CABLE:
		if screws_fastened[index]:
			return
		var req = 1 if screw_types[index] == "cruz" else 2
		var req_name = "Destornillador Cruz" if req == 1 else "Destornillador Pala"
		if GameManager.equipped_tool != req:
			_show_floating_feedback("HERRAMIENTA INCORRECTA: USA " + req_name.to_upper(), Color(1.0, 0.85, 0.1))
			_shake_node(screw_buttons[index])
			return
			
		screws_fastened[index] = true
		var icon = screw_icons[index]
		var tw = create_tween().set_parallel(true)
		tw.tween_property(icon, "rotation", deg_to_rad(-360.0), 0.35)
		tw.tween_property(icon, "modulate", Color(0.2, 1.0, 0.5, 1.0), 0.3)
		
		_show_floating_feedback("✓ TORNILLO AJUSTADO Y APRETADO", Color(0.2, 1.0, 0.5))
		_check_install_completed()
		return

	if screws_removed[index]:
		return
		
	var required_tool = 1 if screw_types[index] == "cruz" else 2
	var required_name = "Destornillador Cruz" if required_tool == 1 else "Destornillador Pala"
	
	if GameManager.equipped_tool != required_tool:
		_show_floating_feedback("HERRAMIENTA INCORRECTA: USA " + required_name.to_upper(), Color(1.0, 0.85, 0.1))
		_shake_node(screw_buttons[index])
		return
		
	# Desatornillar exitoso con animación rotativa y desvanecimiento
	screws_removed[index] = true
	var icon = screw_icons[index]
	var btn = screw_buttons[index]
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(icon, "rotation", deg_to_rad(360.0), 0.35).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(icon, "scale", Vector2(1.4, 1.4), 0.2)
	tw.chain().tween_property(icon, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func():
		btn.visible = false
		_check_readiness()
	)
	
	_show_floating_feedback("✓ TORNILLO RETIRADO", Color(0.2, 1.0, 0.5))

func _check_install_completed() -> void:
	var all_screws = true
	for f in screws_fastened:
		if not f:
			all_screws = false
			break
	if all_screws and not is_cable_disconnected:
		current_state = State.COMPLETED
		_update_status()
		_show_victory_panel()
	else:
		_update_status()

func _check_readiness() -> void:
	var remaining_screws = 0
	for r in screws_removed:
		if not r:
			remaining_screws += 1
			
	if remaining_screws == 0 and is_cable_disconnected:
		current_state = State.READY_TO_EXTRACT
		cooler_extract_btn.visible = true
		_show_floating_feedback("¡FAN COOLER LIBRE! HAZ CLIC PARA EXTRAER", Color(1.0, 0.8, 0.2))
	else:
		cooler_extract_btn.visible = false
		
	_update_status()

func _on_extract_cooler_pressed() -> void:
	if current_state != State.READY_TO_EXTRACT:
		return
		
	current_state = State.EXTRACTING
	cooler_extract_btn.visible = false
	
	# Animación de extracción hacia arriba
	var tw = create_tween().set_parallel(true)
	tw.tween_property(cooler_sprite, "position:y", cooler_sprite.position.y - 70.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(cooler_sprite, "modulate:a", 0.0, 0.45).set_delay(0.2)
	
	tw.chain().tween_callback(func():
		GameManager.add_item_to_backpack({"name": "Fan Cooler", "broken": true})
		old_part_extracted.emit()
		
		# Asegurar que haya un Fan Cooler nuevo en la mochila para la fase de colocación
		var has_new = false
		for it in GameManager.backpack:
			if it.get("name") == "Fan Cooler" and not it.get("broken", true):
				has_new = true
				break
		if not has_new:
			GameManager.add_item_to_backpack({"name": "Fan Cooler", "broken": false})
			
		current_state = State.EMPTY_SOCKET
		_select_tab(1)
		_show_floating_feedback("✓ FASE 1 (QUITAR) COMPLETADA ➔ AHORA FASE 2: MONTAJE INVERSO (PONER)", Color(0.2, 1.0, 0.5))
		_update_status()
		_refresh_backpack_ui()
	)

func _show_victory_panel() -> void:
	status_label.text = "¡REPARACIÓN INTEGRAL SUPERADA (QUITAR Y PONER COMPLETADOS)!"
	status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5, 1.0))
	
	var victory_modal = $ModalControl/VictoryPanel
	if victory_modal:
		var v_title = victory_modal.get_node_or_null("VBox/Title")
		if v_title:
			v_title.text = "¡REPARACIÓN INTEGRAL COMPLETADA! ✓"
		var v_desc = victory_modal.get_node_or_null("VBox/Desc")
		if v_desc:
			v_desc.text = "Has desmontado la pieza averiada e instalado el Fan Cooler nuevo en orden inverso con total éxito."
		victory_modal.visible = true
		var btn_done = victory_modal.get_node_or_null("VBox/BtnContinuar")
		if btn_done:
			btn_done.pressed.connect(func(): minigame_finished.emit(true))

func _update_status() -> void:
	match current_state:
		State.EMPTY_SOCKET:
			status_label.text = "Paso 1: Zócalo de CPU vacío. Monta el Fan Cooler nuevo desde tu mochila."
			status_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
			return
		State.FASTEN_SCREWS, State.CONNECT_CABLE:
			var rem_fasten = 0
			for f in screws_fastened:
				if not f: rem_fasten += 1
			if is_cable_disconnected and rem_fasten > 0:
				status_label.text = "Fase Montaje: Ajusta los 4 tornillos con [1]/[2] y conecta el cable PWM (cualquier orden). Restan %d tornillos." % rem_fasten
				status_label.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0, 1.0))
			elif is_cable_disconnected and rem_fasten == 0:
				status_label.text = "Fase Montaje: ¡Tornillos asegurados! Haz clic en el cable PWM para conectarlo."
				status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5, 1.0))
			elif not is_cable_disconnected and rem_fasten > 0:
				status_label.text = "Fase Montaje: ¡Cable PWM conectado! Ajusta los %d tornillos restantes con [1] Cruz o [2] Pala." % rem_fasten
				status_label.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0, 1.0))
			return
		State.COMPLETED:
			status_label.text = "¡Operación completada con éxito!"
			status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4, 1.0))
			return

	if current_state == State.READY_TO_EXTRACT:
		status_label.text = "¡COMPONENTE LIBRE! Haz clic en el Fan Cooler para retirarlo."
		status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.6, 1.0))
		return
		
	var rem = 0
	for r in screws_removed:
		if not r: rem += 1
		
	if not is_cable_disconnected and rem == 0:
		status_label.text = "¡Tornillos retirados! Desconecta el cable de alimentación para liberar."
		status_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	elif is_cable_disconnected and rem > 0:
		status_label.text = "Cable desconectado. Retira los tornillos restantes (%d/4) con Cruz [1] o Pala [2]." % rem
		status_label.add_theme_color_override("font_color", Color(0.9, 0.5, 1.0, 1.0))
	else:
		status_label.text = "Desconecta el cable y retira los 4 tornillos (cualquier orden). Faltan: %d tornillos." % rem
		status_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))

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
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var vp_size = modal_control.size if modal_control else Vector2(1152, 648)
	lbl.position = Vector2(vp_size.x * 0.5 - 150.0, vp_size.y * 0.5 - 160.0)
	lbl.size = Vector2(300, 30)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if modal_control:
		modal_control.add_child(lbl)
	else:
		add_child(lbl)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 30.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.8).set_delay(0.2)
	tw.chain().tween_callback(lbl.queue_free)
