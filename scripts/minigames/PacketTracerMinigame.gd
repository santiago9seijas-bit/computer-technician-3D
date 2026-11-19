extends CanvasLayer

signal minigame_finished(success: bool)

# =============================================================================
# MINIJUEGO: CISCO PACKET TRACER SIMULATOR (SIMULADOR DE REDES SIMPLIFICADO)
# Enseña:
# 1. Identificación de dispositivos: PC, Switch, Router, Servidor.
# 2. Selección de cables según la regla de Cisco:
#    - Cable Directo (Straight-Through): Dispositivos distintos (PC/Server <-> Switch, Switch <-> Router).
#    - Cable Cruzado (Crossover): Dispositivos de la misma capa (Switch <-> Switch, PC <-> PC).
#    - Fibra Óptica (Fiber Optic): Enlaces troncales de alta velocidad (Server <-> Router/Core).
# 3. Simulación de tráfico y prueba de Ping (ICMP Echo Request/Reply).
# =============================================================================

@onready var modal_control: Control = $ModalControl
@onready var panel_container: PanelContainer = $ModalControl/Panel
@onready var title_label: Label = $ModalControl/Panel/VBox/Header/TopHBox/TitleLabel
@onready var btn_close_header: Button = $ModalControl/Panel/VBox/Header/TopHBox/BtnCloseHeader
@onready var level_label: Label = $ModalControl/Panel/VBox/Header/SubHeaderHBox/LevelLabel
@onready var status_badge: Label = $ModalControl/Panel/VBox/Header/SubHeaderHBox/StatusBadge

# Panel de Santiago
@onready var santiago_text: Label = $ModalControl/Panel/VBox/SantiagoPanel/Margin/HBox/VBox/DialogText

# Área de Topología
@onready var canvas_area: Control = $ModalControl/Panel/VBox/Workspace/CanvasArea
@onready var canvas_bg: ColorRect = $ModalControl/Panel/VBox/Workspace/CanvasArea/CanvasBg
@onready var topology_draw: Control = $ModalControl/Panel/VBox/Workspace/CanvasArea/TopologyDraw

# Herramientas de Cables
@onready var btn_cable_straight: Button = $ModalControl/Panel/VBox/Toolbar/HBox/BtnCableStraight
@onready var btn_cable_crossover: Button = $ModalControl/Panel/VBox/Toolbar/HBox/BtnCableCrossover
@onready var btn_cable_fiber: Button = $ModalControl/Panel/VBox/Toolbar/HBox/BtnCableFiber
@onready var btn_tool_delete: Button = $ModalControl/Panel/VBox/Toolbar/HBox/BtnToolDelete

# Botones de Acción
@onready var btn_ping: Button = $ModalControl/Panel/VBox/Toolbar/HBoxActions/BtnPing
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel
@onready var term_log: RichTextLabel = $ModalControl/Panel/VBox/Workspace/Sidebar/Margin/VBox/TermLog
@onready var victory_banner: PanelContainer = $ModalControl/Panel/VBox/VictoryBanner
@onready var btn_next_level: Button = $ModalControl/Panel/VBox/VictoryBanner/Margin/HBox/BtnNextLevel

enum CableType {
	NONE,
	STRAIGHT,    # Cable Directo (UTP)
	CROSSOVER,   # Cable Cruzado
	FIBER,       # Fibra Óptica
	DELETE       # Herramienta Borrar
}

var current_cable: CableType = CableType.STRAIGHT
var current_challenge_id: int = 0
var selected_device_id: String = ""
var is_dragging_cable: bool = false
var mouse_canvas_pos: Vector2 = Vector2.ZERO

var drag_press_dev_id: String = ""
var drag_press_pos: Vector2 = Vector2.ZERO
var was_dragged: bool = false

# Estructura del nivel actual
var current_devices: Dictionary = {}
var active_connections: Array = []
var required_links: Array = []

# Animación de Ping PDU
var is_pinging: bool = false
var ping_packet_pos: Vector2 = Vector2.ZERO
var ping_progress: float = 0.0
var ping_path: Array = []

const CHALLENGES = [
	{
		"id": 0,
		"node_index": 14,
		"title": "INDUCCIÓN: FUNDAMENTOS CISCO PACKET TRACER",
		"subtitle": "Aprende a interconectar una PC a un Switch usando Cable Directo.",
		"santiago_dialog": "¡Hola! Soy Santiago. Si alguna vez viste Cisco Packet Tracer, sabes la regla de oro:\n• Dispositivos DISTINTOS (PC a Switch) usan CABLE DIRECTO (Straight-Through).\n• Dispositivos IGUALES (Switch a Switch) usan CABLE CRUZADO (Crossover).\nSelecciona Cable Directo [1], haz clic en la PC y luego en el Switch. ¡Luego envía un Ping!",
		"devices": [
			{"id": "pc0", "type": "pc", "name": "PC-Cliente0", "ip": "192.168.1.10", "pos": Vector2(160, 160)},
			{"id": "sw0", "type": "switch", "name": "Switch-2960", "ip": "VLAN1", "pos": Vector2(490, 160)}
		],
		"required_links": [
			{"from": "pc0", "to": "sw0", "valid_cables": [CableType.STRAIGHT]}
		]
	},
	{
		"id": 1,
		"node_index": 15,
		"title": "DESAFÍO #1: LAN DE OFICINA & SERVIDOR LOCAL",
		"subtitle": "Conecta 2 PCs de empleados y el Servidor de Archivos al Switch central.",
		"santiago_dialog": "Buen trabajo. Ahora tenemos una oficina: dos PCs de empleados y el Servidor de Archivos. Todos van al Switch central. Como son equipos de diferente función que el Switch, usa CABLE DIRECTO [1] para todos. Conéctalos y haz Ping global.",
		"devices": [
			{"id": "pc0", "type": "pc", "name": "PC-Ventas", "ip": "192.168.1.11", "pos": Vector2(140, 90)},
			{"id": "pc1", "type": "pc", "name": "PC-Admin", "ip": "192.168.1.12", "pos": Vector2(140, 230)},
			{"id": "sw0", "type": "switch", "name": "Switch-Core", "ip": "VLAN1", "pos": Vector2(340, 160)},
			{"id": "srv0", "type": "server", "name": "Server-Data", "ip": "192.168.1.5", "pos": Vector2(530, 160)}
		],
		"required_links": [
			{"from": "pc0", "to": "sw0", "valid_cables": [CableType.STRAIGHT]},
			{"from": "pc1", "to": "sw0", "valid_cables": [CableType.STRAIGHT]},
			{"from": "srv0", "to": "sw0", "valid_cables": [CableType.STRAIGHT]}
		]
	},
	{
		"id": 2,
		"node_index": 16,
		"title": "DESAFÍO #2: ENLACE DE ROUTER & SUBREDES",
		"subtitle": "Interconecta los switches de dos áreas al Router central corporativo.",
		"santiago_dialog": "Dos departamentos distintos necesitan comunicarse en Capa 3. Conecta la PC al Switch-Piso, el Servidor al Switch-Server, y ambos switches a las interfaces Gigabit del Router usando Cable Directo [1].",
		"devices": [
			{"id": "pc0", "type": "pc", "name": "PC-Oficina", "ip": "10.0.1.50", "pos": Vector2(110, 90)},
			{"id": "sw0", "type": "switch", "name": "SW-Piso1", "ip": "10.0.1.2", "pos": Vector2(230, 90)},
			{"id": "rt0", "type": "router", "name": "Router-4331", "ip": "GW: 10.0.0.1", "pos": Vector2(340, 160)},
			{"id": "sw1", "type": "switch", "name": "SW-DataCenter", "ip": "10.0.2.2", "pos": Vector2(450, 90)},
			{"id": "srv0", "type": "server", "name": "Server-App", "ip": "10.0.2.10", "pos": Vector2(450, 230)}
		],
		"required_links": [
			{"from": "pc0", "to": "sw0", "valid_cables": [CableType.STRAIGHT]},
			{"from": "sw0", "to": "rt0", "valid_cables": [CableType.STRAIGHT]},
			{"from": "rt0", "to": "sw1", "valid_cables": [CableType.STRAIGHT]},
			{"from": "srv0", "to": "sw1", "valid_cables": [CableType.STRAIGHT]}
		]
	},
	{
		"id": 3,
		"node_index": 17,
		"title": "DESAFÍO #3: TRONCAL DE FIBRA & CROSSOVER",
		"subtitle": "Usa Cable Cruzado entre Switches y Fibra Óptica para el Servidor Data Center.",
		"santiago_dialog": "¡Prueba de fuego! Aquí la regla es estricta:\n1. Conecta SW-Acceso con SW-Distribucion usando CABLE CRUZADO [2] (Misma capa).\n2. Conecta el Servidor Mainframe al Router usando enlace de FIBRA ÓPTICA [3] (amarillo).",
		"devices": [
			{"id": "pc0", "type": "pc", "name": "PC-Workstation", "ip": "172.16.1.20", "pos": Vector2(110, 160)},
			{"id": "sw0", "type": "switch", "name": "SW-Acceso", "ip": "172.16.1.2", "pos": Vector2(240, 160)},
			{"id": "sw1", "type": "switch", "name": "SW-Distribucion", "ip": "172.16.1.3", "pos": Vector2(370, 160)},
			{"id": "rt0", "type": "router", "name": "Router-Core", "ip": "172.16.0.1", "pos": Vector2(370, 70)},
			{"id": "srv0", "type": "server", "name": "Server-Mainframe", "ip": "172.16.10.1", "pos": Vector2(530, 70)}
		],
		"required_links": [
			{"from": "pc0", "to": "sw0", "valid_cables": [CableType.STRAIGHT]},
			{"from": "sw0", "to": "sw1", "valid_cables": [CableType.CROSSOVER]},
			{"from": "sw1", "to": "rt0", "valid_cables": [CableType.STRAIGHT]},
			{"from": "srv0", "to": "rt0", "valid_cables": [CableType.FIBER]}
		]
	}
]

func _ready() -> void:
	layer = 15
	
	# Asegurar centrado y dimensiones exactas dentro del viewport
	var vp = get_viewport()
	var vp_size = vp.get_visible_rect().size if vp else Vector2(1280, 720)
	if modal_control:
		modal_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	if panel_container:
		panel_container.custom_minimum_size = Vector2(1040, 520)
		panel_container.size = Vector2(1040, 520)
		panel_container.set_anchors_preset(Control.PRESET_CENTER)
		panel_container.position = Vector2(max(0.0, (vp_size.x - 1040.0) * 0.5), max(0.0, (vp_size.y - 520.0) * 0.5))
		
	if topology_draw:
		topology_draw.draw.connect(_on_topology_draw)
		
	if canvas_area:
		canvas_area.mouse_filter = Control.MOUSE_FILTER_PASS
		canvas_area.gui_input.connect(_on_canvas_gui_input)
		
	if btn_close_header:
		btn_close_header.pressed.connect(_on_cancel_pressed)
	if btn_cable_straight:
		btn_cable_straight.pressed.connect(func(): _select_cable_tool(CableType.STRAIGHT))
	if btn_cable_crossover:
		btn_cable_crossover.pressed.connect(func(): _select_cable_tool(CableType.CROSSOVER))
	if btn_cable_fiber:
		btn_cable_fiber.pressed.connect(func(): _select_cable_tool(CableType.FIBER))
	if btn_tool_delete:
		btn_tool_delete.pressed.connect(func(): _select_cable_tool(CableType.DELETE))
		
	if btn_ping:
		btn_ping.pressed.connect(_on_ping_pressed)
	if btn_cancel:
		btn_cancel.pressed.connect(_on_cancel_pressed)
	if btn_next_level:
		btn_next_level.pressed.connect(_on_next_level_pressed)
		
	_select_cable_tool(CableType.STRAIGHT)
	load_challenge(current_challenge_id)

func _process(_delta: float) -> void:
	if selected_device_id != "" and canvas_area:
		mouse_canvas_pos = canvas_area.get_local_mouse_position()
		if topology_draw:
			topology_draw.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not modal_control or not modal_control.visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		_on_cancel_pressed()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			_select_cable_tool(CableType.STRAIGHT)
		elif event.keycode == KEY_2:
			_select_cable_tool(CableType.CROSSOVER)
		elif event.keycode == KEY_3:
			_select_cable_tool(CableType.FIBER)
		elif event.keycode == KEY_4 or event.keycode == KEY_X:
			_select_cable_tool(CableType.DELETE)
		elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if not is_pinging and not victory_banner.visible:
				_on_ping_pressed()
			elif victory_banner.visible:
				_on_next_level_pressed()

func load_challenge(challenge_idx: int) -> void:
	current_challenge_id = clamp(challenge_idx, 0, CHALLENGES.size() - 1)
	var cfg = CHALLENGES[current_challenge_id]
	
	if victory_banner: victory_banner.visible = false
	selected_device_id = ""
	is_dragging_cable = false
	active_connections.clear()
	required_links = cfg["required_links"]
	
	if title_label: title_label.text = "🌐 CISCO PACKET TRACER // " + cfg["title"]
	if level_label: level_label.text = cfg["subtitle"]
	if santiago_text: santiago_text.text = cfg["santiago_dialog"]
	if status_badge:
		status_badge.text = "TOPOLOGÍA NO CONECTADA (0/%d ENLACES)" % required_links.size()
		status_badge.modulate = Color(1.0, 0.75, 0.2)
		
	_clear_device_nodes()
	_create_device_nodes(cfg["devices"])
	
	if term_log:
		term_log.text = "[color=#00e5ff]Packet Tracer CLI v8.2.1 initialized.[/color]\n"
		term_log.append_text("[color=#a0a8b5]Cargando topología: " + cfg["title"] + "...[/color]\n")
		term_log.append_text("[color=#ffff66]Usa los cables de la barra inferior para interconectar los nodos.[/color]\n")
		
	if topology_draw:
		topology_draw.queue_redraw()

func _clear_device_nodes() -> void:
	current_devices.clear()
	for child in canvas_area.get_children():
		if child != topology_draw and child != canvas_bg:
			child.queue_free()

func _create_device_nodes(dev_list: Array) -> void:
	for dev in dev_list:
		var btn = Button.new()
		btn.name = dev["id"]
		btn.custom_minimum_size = Vector2(96, 68)
		btn.size = Vector2(96, 68)
		btn.position = dev["pos"] - Vector2(48, 34)
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		var icon_str = "💻"
		var color_accent = Color(0.15, 0.7, 1.0)
		match dev["type"]:
			"switch":
				icon_str = "🖧"
				color_accent = Color(0.2, 0.9, 0.6)
			"router":
				icon_str = "🌐"
				color_accent = Color(0.9, 0.4, 0.9)
			"server":
				icon_str = "🖥️"
				color_accent = Color(1.0, 0.65, 0.1)
				
		btn.text = "%s\n%s\n[%s]" % [icon_str, dev["name"], dev["ip"]]
		btn.add_theme_font_size_override("font_size", 10)
		
		# Estilo de tarjeta Cisco
		var sb_norm = StyleBoxFlat.new()
		sb_norm.bg_color = Color(0.06, 0.08, 0.14, 0.95)
		sb_norm.border_width_left = 2
		sb_norm.border_width_top = 2
		sb_norm.border_width_right = 2
		sb_norm.border_width_bottom = 2
		sb_norm.border_color = color_accent
		sb_norm.corner_radius_top_left = 6
		sb_norm.corner_radius_top_right = 6
		sb_norm.corner_radius_bottom_right = 6
		sb_norm.corner_radius_bottom_left = 6
		btn.add_theme_stylebox_override("normal", sb_norm)
		
		var sb_hover = sb_norm.duplicate() as StyleBoxFlat
		sb_hover.bg_color = Color(0.12, 0.18, 0.32, 0.98)
		sb_hover.border_color = Color(1, 1, 1, 1)
		btn.add_theme_stylebox_override("hover", sb_hover)
		
		var id_copy = dev["id"]
		btn.pressed.connect(func(): _on_device_clicked(id_copy))
		btn.gui_input.connect(func(ev: InputEvent): _on_device_gui_input(ev, id_copy))
		
		canvas_area.add_child(btn)
		current_devices[dev["id"]] = {
			"cfg": dev,
			"node": btn,
			"center": dev["pos"]
		}

func _on_canvas_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_canvas_pos = event.position
		if selected_device_id != "":
			if topology_draw: topology_draw.queue_redraw()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_LEFT:
			# Clic en el fondo vacío cancela el arrastre/selección de cable
			if selected_device_id != "":
				selected_device_id = ""
				is_dragging_cable = false
				_highlight_selected_device(false)
				if topology_draw: topology_draw.queue_redraw()

func _on_device_gui_input(event: InputEvent, dev_id: String) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				drag_press_dev_id = dev_id
				drag_press_pos = event.global_position
				was_dragged = false
			elif not event.pressed:
				if was_dragged and drag_press_dev_id != "":
					# Soltar sobre otro equipo al terminar arrastre
					var drop_dev = _get_device_under_cursor(canvas_area.get_local_mouse_position())
					if drop_dev != "" and drop_dev != drag_press_dev_id:
						_connect_devices(drag_press_dev_id, drop_dev, current_cable)
					selected_device_id = ""
					is_dragging_cable = false
					_highlight_selected_device(false)
					if topology_draw: topology_draw.queue_redraw()
				drag_press_dev_id = ""
				was_dragged = false
	elif event is InputEventMouseMotion:
		if drag_press_dev_id != "" and not was_dragged:
			if (event.global_position - drag_press_pos).length() > 8.0:
				was_dragged = true
				selected_device_id = drag_press_dev_id
				is_dragging_cable = true
				_highlight_selected_device(true)
				if topology_draw: topology_draw.queue_redraw()

func _get_device_under_cursor(c_pos: Vector2) -> String:
	for id in current_devices.keys():
		var btn = current_devices[id]["node"] as Button
		if not btn: continue
		var rect = Rect2(btn.position, btn.size)
		if rect.has_point(c_pos):
			return id
	return ""

func _select_cable_tool(tool_type: CableType) -> void:
	current_cable = tool_type
	selected_device_id = ""
	is_dragging_cable = false
	
	_style_tool_btn(btn_cable_straight, tool_type == CableType.STRAIGHT)
	_style_tool_btn(btn_cable_crossover, tool_type == CableType.CROSSOVER)
	_style_tool_btn(btn_cable_fiber, tool_type == CableType.FIBER)
	_style_tool_btn(btn_tool_delete, tool_type == CableType.DELETE)
	
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("play_sfx"):
		gm.play_sfx("click")
		
	if topology_draw:
		topology_draw.queue_redraw()

func _style_tool_btn(btn: Button, is_active: bool) -> void:
	if not btn: return
	if is_active:
		btn.modulate = Color(1.2, 1.2, 1.2, 1.0)
	else:
		btn.modulate = Color(0.65, 0.7, 0.75, 0.8)

func _on_device_clicked(dev_id: String) -> void:
	if was_dragged:
		return
		
	if current_cable == CableType.DELETE:
		_delete_connections_for(dev_id)
		return
		
	if selected_device_id == "":
		# Primer clic: seleccionar equipo origen
		selected_device_id = dev_id
		is_dragging_cable = true
		_highlight_selected_device(true)
		if term_log:
			term_log.append_text("[color=#00e5ff]Puerto origen: %s. Haz clic en el equipo de destino para conectar.[/color]\n" % dev_id)
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("play_sfx"):
			gm.play_sfx("click")
		if topology_draw: topology_draw.queue_redraw()
	elif selected_device_id == dev_id:
		# Clic en el mismo equipo: deseleccionar
		selected_device_id = ""
		is_dragging_cable = false
		_highlight_selected_device(false)
		if topology_draw: topology_draw.queue_redraw()
	else:
		# Clic en segundo equipo: ¡CONECTAR!
		_connect_devices(selected_device_id, dev_id, current_cable)
		selected_device_id = ""
		is_dragging_cable = false
		_highlight_selected_device(false)
		if topology_draw: topology_draw.queue_redraw()

func _highlight_selected_device(highlight: bool) -> void:
	for id in current_devices.keys():
		var btn = current_devices[id]["node"] as Button
		if not btn: continue
		if highlight and id == selected_device_id:
			btn.modulate = Color(0.4, 1.2, 0.9, 1.0)
		else:
			btn.modulate = Color.WHITE

func _connect_devices(dev_a: String, dev_b: String, cable: CableType) -> void:
	_remove_link(dev_a, dev_b)
	
	var link_data = {
		"from": dev_a,
		"to": dev_b,
		"cable": cable,
		"is_valid": _validate_cable_connection(dev_a, dev_b, cable)
	}
	active_connections.append(link_data)
	
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("play_sfx"):
		gm.play_sfx("click")
		
	var cable_name = "Cable Directo" if cable == CableType.STRAIGHT else ("Cable Cruzado" if cable == CableType.CROSSOVER else "Fibra Óptica")
	if link_data["is_valid"]:
		if term_log:
			term_log.append_text("[color=#39ff14]✓ Enlace UP entre %s y %s (%s compatible).[/color]\n" % [dev_a, dev_b, cable_name])
	else:
		if term_log:
			term_log.append_text("[color=#ff3366]❌ Error de Capa Física: %s incompatible entre %s y %s.[/color]\n" % [cable_name, dev_a, dev_b])
			
	_check_topology_progress()
	if topology_draw:
		topology_draw.queue_redraw()

func _validate_cable_connection(dev_a: String, dev_b: String, cable: CableType) -> bool:
	for req in required_links:
		if (req["from"] == dev_a and req["to"] == dev_b) or (req["from"] == dev_b and req["to"] == dev_a):
			return cable in req["valid_cables"]
	return false

func _remove_link(dev_a: String, dev_b: String) -> void:
	for i in range(active_connections.size() - 1, -1, -1):
		var c = active_connections[i]
		if (c["from"] == dev_a and c["to"] == dev_b) or (c["from"] == dev_b and c["to"] == dev_a):
			active_connections.remove_at(i)

func _delete_connections_for(dev_id: String) -> void:
	var removed = 0
	for i in range(active_connections.size() - 1, -1, -1):
		var c = active_connections[i]
		if c["from"] == dev_id or c["to"] == dev_id:
			active_connections.remove_at(i)
			removed += 1
	if removed > 0:
		if term_log:
			term_log.append_text("[color=#ff9933]Cables desconectados de %s.[/color]\n" % dev_id)
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("play_sfx"):
			gm.play_sfx("click")
		_check_topology_progress()
		if topology_draw:
			topology_draw.queue_redraw()

func _check_topology_progress() -> void:
	var valid_count = 0
	for c in active_connections:
		if c["is_valid"]:
			valid_count += 1
			
	if status_badge:
		if valid_count == required_links.size():
			status_badge.text = "TOPOLOGÍA COMPLETA (%d/%d) · LISTO PARA TEST PING" % [valid_count, required_links.size()]
			status_badge.modulate = Color(0.2, 1.0, 0.4)
			if btn_ping:
				btn_ping.modulate = Color(1.2, 1.3, 1.2)
		else:
			status_badge.text = "ENLACES ACTIVOS: %d / %d REQUERIDOS" % [valid_count, required_links.size()]
			status_badge.modulate = Color(1.0, 0.75, 0.2)
			if btn_ping:
				btn_ping.modulate = Color.WHITE

func _on_topology_draw() -> void:
	# Dibujar cables activos
	for c in active_connections:
		if not current_devices.has(c["from"]) or not current_devices.has(c["to"]):
			continue
		var pos_a: Vector2 = current_devices[c["from"]]["center"]
		var pos_b: Vector2 = current_devices[c["to"]]["center"]
		
		var cable_color = Color(0.0, 0.85, 1.0) # Straight
		var cable_width = 4.0
		var is_dashed = false
		
		match c["cable"]:
			CableType.STRAIGHT:
				cable_color = Color(0.0, 0.85, 1.0)
			CableType.CROSSOVER:
				cable_color = Color(1.0, 0.55, 0.1)
				is_dashed = true
			CableType.FIBER:
				cable_color = Color(1.0, 0.95, 0.2)
				cable_width = 5.0
				
		if not c["is_valid"]:
			cable_color = Color(0.9, 0.2, 0.3)
			
		if is_dashed:
			topology_draw.draw_dashed_line(pos_a, pos_b, cable_color, cable_width, 10.0)
		else:
			topology_draw.draw_line(pos_a, pos_b, cable_color, cable_width, true)
			
		# Dibujar LEDs de puerto en los extremos
		var led_col = Color(0.2, 1.0, 0.4) if c["is_valid"] else Color(1.0, 0.2, 0.3)
		var dir = (pos_b - pos_a).normalized()
		topology_draw.draw_circle(pos_a + dir * 36.0, 5.0, led_col)
		topology_draw.draw_circle(pos_b - dir * 36.0, 5.0, led_col)
		
	# Dibujar cable guía en tiempo real si el jugador está conectando
	if selected_device_id != "" and current_devices.has(selected_device_id):
		var p_start: Vector2 = current_devices[selected_device_id]["center"]
		var p_cur = mouse_canvas_pos
		var guide_col = Color(0.2, 0.9, 1.0, 0.85)
		if current_cable == CableType.CROSSOVER:
			guide_col = Color(1.0, 0.6, 0.2, 0.85)
		elif current_cable == CableType.FIBER:
			guide_col = Color(1.0, 0.95, 0.2, 0.85)
		elif current_cable == CableType.DELETE:
			guide_col = Color(1.0, 0.2, 0.3, 0.85)
		topology_draw.draw_dashed_line(p_start, p_cur, guide_col, 3.0, 8.0)
		topology_draw.draw_circle(p_cur, 4.0, guide_col)
		
	# Dibujar paquete Ping animado si está en curso
	if is_pinging and ping_path.size() >= 2:
		topology_draw.draw_circle(ping_packet_pos, 8.0, Color(1.0, 1.0, 0.3))
		topology_draw.draw_circle(ping_packet_pos, 4.5, Color(1.0, 0.5, 0.1))

func _on_ping_pressed() -> void:
	if is_pinging:
		return
		
	# Validar si todos los enlaces requeridos están completos y correctos
	var valid_count = 0
	for req in required_links:
		var has_it = false
		for c in active_connections:
			if ((c["from"] == req["from"] and c["to"] == req["to"]) or (c["from"] == req["to"] and c["to"] == req["from"])) and c["is_valid"]:
				has_it = true
				break
		if has_it:
			valid_count += 1
			
	if valid_count < required_links.size():
		if term_log:
			term_log.append_text("[color=#ff3366]PING FAILED: Host unreachable (Faltan enlaces requeridos o tipo de cable erróneo).[/color]\n")
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("register_error"):
			gm.register_error(3.0)
		return
		
	# Iniciar animación de Ping ICMP
	is_pinging = true
	btn_ping.disabled = true
	
	if term_log:
		term_log.append_text("[color=#00e5ff]Iniciando simulación ICMP Ping Echo Request...[/color]\n")
		
	ping_path.clear()
	for req in required_links:
		if current_devices.has(req["from"]) and current_devices.has(req["to"]):
			ping_path.append(current_devices[req["from"]]["center"])
			ping_path.append(current_devices[req["to"]]["center"])
			
	if ping_path.is_empty():
		is_pinging = false
		btn_ping.disabled = false
		return
		
	# Animar el paquetito
	ping_packet_pos = ping_path[0]
	var tw = create_tween()
	for i in range(1, ping_path.size()):
		var target_pt = ping_path[i]
		tw.tween_method(func(pos: Vector2):
			ping_packet_pos = pos
			if topology_draw: topology_draw.queue_redraw()
		, ping_packet_pos, target_pt, 0.45).set_trans(Tween.TRANS_LINEAR)
		tw.tween_callback(func():
			var gm = get_node_or_null("/root/GameManager")
			if gm and gm.has_method("play_sfx"):
				gm.play_sfx("click")
		)
		
	await tw.finished
	if not is_inside_tree(): return
	
	is_pinging = false
	btn_ping.disabled = false
	
	if term_log:
		term_log.append_text("[color=#39ff14]Reply from Destination: bytes=32 time=0.8ms TTL=64 · 100% SUCCESS[/color]\n")
		term_log.append_text("[b][color=#39ff14]¡TOPOLOGÍA DE RED VERIFICADA Y OPERATIVA AL 100%! ✓[/color][/b]\n")
		
	victory_banner.visible = true
	status_badge.text = "¡DESAFÍO COMPLETADO CON ÉXITO! ✓"
	status_badge.modulate = Color(0.2, 1.0, 0.4)
	
	# Guardar progreso en SaveManager
	var cfg = CHALLENGES[current_challenge_id]
	var node_idx = cfg.get("node_index", 14 + current_challenge_id)
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.has_method("mark_node_completed"):
		sm.mark_node_completed("servidor", node_idx)
		if current_challenge_id < CHALLENGES.size() - 1:
			var next_node_idx = CHALLENGES[current_challenge_id + 1].get("node_index", node_idx + 1)
			sm.unlock_node("servidor", next_node_idx)
	
	var gm_win = get_node_or_null("/root/GameManager")
	if gm_win and gm_win.has_method("register_repair"):
		gm_win.register_repair(100, 10.0)

func _on_next_level_pressed() -> void:
	if current_challenge_id < CHALLENGES.size() - 1:
		load_challenge(current_challenge_id + 1)
	else:
		# Completados todos los desafíos
		minigame_finished.emit(true)
		queue_free()

func _on_cancel_pressed() -> void:
	minigame_finished.emit(false)
	queue_free()
