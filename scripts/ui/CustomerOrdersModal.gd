class_name CustomerOrdersModal
extends Control

# =============================================================================
# CUSTOMER ORDERS MODAL - TERMINAL DE CLIENTES Y GESTOR DE PEDIDOS
# =============================================================================

signal order_accepted(order_data: Dictionary)
signal order_completed(order_data: Dictionary)
signal modal_closed

@onready var main_panel: PanelContainer = $MainPanel
@onready var orders_container: VBoxContainer = $MainPanel/MarginContainer/VBox/ContentSplit/LeftColumn/ScrollContainer/OrdersList
@onready var detail_panel: PanelContainer = $MainPanel/MarginContainer/VBox/ContentSplit/RightColumn/DetailPanel
@onready var btn_close: Button = $MainPanel/MarginContainer/VBox/Header/BtnClose
@onready var stats_label: Label = $MainPanel/MarginContainer/VBox/Header/StatsLabel
@onready var notification_label: Label = $MainPanel/MarginContainer/VBox/NotificationLabel

# Elementos del panel de detalle
@onready var lbl_detail_title: Label = $MainPanel/MarginContainer/VBox/ContentSplit/RightColumn/DetailPanel/Margin/VBoxDetail/ClientTitle
@onready var lbl_detail_badge: Label = $MainPanel/MarginContainer/VBox/ContentSplit/RightColumn/DetailPanel/Margin/VBoxDetail/StatusBadge
@onready var lbl_pc_model: Label = $MainPanel/MarginContainer/VBox/ContentSplit/RightColumn/DetailPanel/Margin/VBoxDetail/PcModelLabel
@onready var lbl_issue_desc: Label = $MainPanel/MarginContainer/VBox/ContentSplit/RightColumn/DetailPanel/Margin/VBoxDetail/IssueDesc
@onready var lbl_task_needed: Label = $MainPanel/MarginContainer/VBox/ContentSplit/RightColumn/DetailPanel/Margin/VBoxDetail/TaskNeeded
@onready var lbl_reward: Label = $MainPanel/MarginContainer/VBox/ContentSplit/RightColumn/DetailPanel/Margin/VBoxDetail/RewardLabel
@onready var btn_action: Button = $MainPanel/MarginContainer/VBox/ContentSplit/RightColumn/DetailPanel/Margin/VBoxDetail/ActionBtn

# Botones de filtro
@onready var btn_filter_all: Button = $MainPanel/MarginContainer/VBox/FiltersBar/BtnFilterAll
@onready var btn_filter_pending: Button = $MainPanel/MarginContainer/VBox/FiltersBar/BtnFilterPending
@onready var btn_filter_active: Button = $MainPanel/MarginContainer/VBox/FiltersBar/BtnFilterActive
@onready var btn_filter_done: Button = $MainPanel/MarginContainer/VBox/FiltersBar/BtnFilterDone

var current_filter: String = "all"
var selected_order_id: String = ""

# Lista inicial de pedidos predeterminados
var orders_data: Array[Dictionary] = [
	{
		"id": "ORD-101",
		"client_name": "Elena Rostova",
		"client_type": "Gamer / Creadora de Contenido",
		"avatar": "👾",
		"stars": 5,
		"pc_model": "CyberRig RTX 4090 Extreme",
		"issue_title": "Sobrecalentamiento y throttling",
		"description": "El equipo se apaga a los 10 minutos de iniciar streaming. La pasta térmica del disipador parece completamente seca y el ventilador está atascado.",
		"task_needed": "Limpieza general de componentes y aplicación de nueva pasta térmica.",
		"status": "pending",
		"reward_money": 350,
		"reward_xp": 120
	},
	{
		"id": "ORD-102",
		"client_name": "Dr. Marcus Vance",
		"client_type": "Investigador / Laboratorio IA",
		"avatar": "🔬",
		"stars": 4,
		"pc_model": "Workstation Dual Threadripper",
		"issue_title": "Pantallazo azul en renderizado 3D",
		"description": "Fallo crítico con código MEMORY_MANAGEMENT al renderizar redes neuronales. Sospecha de módulo RAM defectuoso en banco 2.",
		"task_needed": "Diagnóstico de memoria RAM y reemplazo de módulo DDR5 defectuoso.",
		"status": "pending",
		"reward_money": 520,
		"reward_xp": 200
	},
	{
		"id": "ORD-103",
		"client_name": "Kaelen Jax",
		"client_type": "Productor Musical Synthwave",
		"avatar": "🎧",
		"stars": 5,
		"pc_model": "StudioMini ITX Beast",
		"issue_title": "Chispazos y olor a quemado",
		"description": "Al conectar la interfaz de audio se escuchó un chasquido eléctrico en la parte posterior. La PC ya no enciende.",
		"task_needed": "Sustitución de fuente de poder quemada y testeo de líneas de voltaje.",
		"status": "in_progress",
		"reward_money": 420,
		"reward_xp": 150
	},
	{
		"id": "ORD-104",
		"client_name": "Sora Takahashi",
		"client_type": "Programador de Videojuegos",
		"avatar": "💻",
		"stars": 5,
		"pc_model": "DevStation Obsidian Pro",
		"issue_title": "Sector defectuoso en arranque",
		"description": "Tiempos de carga interminables al compilar código. El disco mecánico secundario hace chasquidos repetitivos.",
		"task_needed": "Migración de sistema a SSD NVMe de alta velocidad.",
		"status": "pending",
		"reward_money": 280,
		"reward_xp": 95
	},
	{
		"id": "ORD-105",
		"client_name": "Valeria Gomez",
		"client_type": "Empresa Contable Nexus",
		"avatar": "📊",
		"stars": 4,
		"pc_model": "OptiCorp Slim Office 7",
		"issue_title": "Polvo excesivo y ruido de turbina",
		"description": "La computadora suena muy fuerte en la oficina y se apaga en días calurosos. Mantenimiento preventivo necesario.",
		"task_needed": "Sopleteado completo con aire comprimido y lubricación de ventiladores.",
		"status": "completed",
		"reward_money": 190,
		"reward_xp": 80
	}
]

func _get_loc():
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/LocalizationManager")

func _get_gm():
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/GameManager")

func _tr(key: String) -> String:
	var lm = _get_loc()
	if lm and lm.has_method("translate"):
		return lm.translate(key)
	return key

func _ready() -> void:
	# Adaptación responsive de pantalla
	if has_node("/root/ResponsiveScreenManager"):
		var rsm = get_node("/root/ResponsiveScreenManager")
		if rsm.has_method("adapt_control"):
			rsm.adapt_control(main_panel, {"margin_x": 28.0, "margin_y": 20.0})

	# Conexión de botones
	btn_close.pressed.connect(_on_close_pressed)
	btn_filter_all.pressed.connect(func(): _set_filter("all"))
	btn_filter_pending.pressed.connect(func(): _set_filter("pending"))
	btn_filter_active.pressed.connect(func(): _set_filter("in_progress"))
	btn_filter_done.pressed.connect(func(): _set_filter("completed"))
	btn_action.pressed.connect(_on_action_pressed)

	var lm = _get_loc()
	if lm and lm.has_signal("locale_changed"):
		lm.locale_changed.connect(func(_l): _update_texts())

	_update_texts()
	_update_stats()
	_refresh_orders_list()
	
	# Seleccionar el primer pedido disponible
	if orders_data.size() > 0:
		_select_order(orders_data[0]["id"])
		
	# Ocultar paneles del HUD excepto el contador de tiempo para leer cómodamente los pedidos
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("hide_gameplay_hud_for_modal"):
		hud.hide_gameplay_hud_for_modal(true)

func _exit_tree() -> void:
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("show_gameplay_hud_from_modal"):
		hud.show_gameplay_hud_from_modal(true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_on_close_pressed()
			get_viewport().set_input_as_handled()

func _update_texts() -> void:
	var lm = _get_loc()
	if lm and lm.has_method("translate_tree"):
		lm.translate_tree(self)
	_update_filter_buttons_style()

func _update_stats() -> void:
	var pending_count = 0
	var active_count = 0
	var completed_count = 0
	var total_earned = 0
	
	for ord in orders_data:
		match ord.get("status", ""):
			"pending": pending_count += 1
			"in_progress": active_count += 1
			"completed":
				completed_count += 1
				total_earned += ord.get("reward_money", 0)

	var txt_pending = _tr("En Espera")
	var txt_active = _tr("En Taller")
	var txt_done = _tr("Completados")
	
	stats_label.text = "📋 %s: %d  |  🛠️ %s: %d  |  ✅ %s: %d  |  💰 Total: $%d" % [
		txt_pending, pending_count, txt_active, active_count, txt_done, completed_count, total_earned
	]

func _set_filter(new_filter: String) -> void:
	current_filter = new_filter
	_update_filter_buttons_style()
	_refresh_orders_list()

func _update_filter_buttons_style() -> void:
	var active_color = Color(0.0, 0.95, 1.0, 1.0)
	var inactive_color = Color(0.7, 0.7, 0.7, 0.8)
	
	btn_filter_all.modulate = active_color if current_filter == "all" else inactive_color
	btn_filter_pending.modulate = active_color if current_filter == "pending" else inactive_color
	btn_filter_active.modulate = active_color if current_filter == "in_progress" else inactive_color
	btn_filter_done.modulate = active_color if current_filter == "completed" else inactive_color

func _refresh_orders_list() -> void:
	# Limpiar tarjetas actuales
	for child in orders_container.get_children():
		child.queue_free()

	var count = 0
	for ord in orders_data:
		var st = ord.get("status", "")
		if current_filter != "all" and st != current_filter:
			continue
			
		var card = _create_order_card(ord)
		orders_container.add_child(card)
		count += 1

	if count == 0:
		var empty_lbl = Label.new()
		empty_lbl.text = _tr("No hay pedidos en esta categoría")
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.modulate = Color(0.6, 0.6, 0.7, 0.7)
		orders_container.add_child(empty_lbl)

func _create_order_card(ord: Dictionary) -> Control:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(340, 72)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	# Estilo personalizado de la tarjeta
	var sb = StyleBoxFlat.new()
	var is_selected = (ord.get("id", "") == selected_order_id)
	
	match ord.get("status", ""):
		"pending":
			sb.bg_color = Color(0.08, 0.08, 0.14, 0.92)
			sb.border_color = Color(1.0, 0.75, 0.2, 0.95) if is_selected else Color(1.0, 0.75, 0.2, 0.35)
		"in_progress":
			sb.bg_color = Color(0.06, 0.10, 0.18, 0.92)
			sb.border_color = Color(0.0, 0.9, 1.0, 1.0) if is_selected else Color(0.0, 0.9, 1.0, 0.4)
		"completed":
			sb.bg_color = Color(0.05, 0.12, 0.08, 0.92)
			sb.border_color = Color(0.2, 1.0, 0.5, 0.95) if is_selected else Color(0.2, 1.0, 0.5, 0.35)

	sb.set_border_width_all(2 if is_selected else 1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12.0
	sb.content_margin_top = 8.0
	sb.content_margin_right = 12.0
	sb.content_margin_bottom = 8.0
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)

	var hbox = HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.anchors_preset = Control.PRESET_FULL_RECT
	hbox.anchor_right = 1.0
	hbox.anchor_bottom = 1.0
	hbox.offset_left = 12
	hbox.offset_top = 8
	hbox.offset_right = -12
	hbox.offset_bottom = -8
	hbox.add_theme_constant_override("separation", 10)

	# Avatar / Icono
	var lbl_avatar = Label.new()
	lbl_avatar.text = ord.get("avatar", "💻")
	lbl_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_avatar.add_theme_font_size_override("font_size", 24)
	hbox.add_child(lbl_avatar)

	# Info del cliente y equipo
	var vbox_text = VBoxContainer.new()
	vbox_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var lbl_name = Label.new()
	lbl_name.text = ord.get("client_name", "Cliente") + "  [" + ord.get("id", "") + "]"
	lbl_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_name.add_theme_font_size_override("font_size", 14)
	lbl_name.modulate = Color(1.0, 1.0, 1.0, 1.0)
	vbox_text.add_child(lbl_name)

	var lbl_model = Label.new()
	lbl_model.text = ord.get("pc_model", "")
	lbl_model.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_model.add_theme_font_size_override("font_size", 12)
	lbl_model.modulate = Color(0.0, 0.85, 1.0, 0.85)
	vbox_text.add_child(lbl_model)
	
	hbox.add_child(vbox_text)

	# Badge de estado pequeño
	var badge = Label.new()
	var status_text = ""
	match ord.get("status", ""):
		"pending":
			status_text = "⏳ " + _tr("ESPERA")
			badge.modulate = Color(1.0, 0.8, 0.2, 1.0)
		"in_progress":
			status_text = "🛠️ " + _tr("TALLER")
			badge.modulate = Color(0.0, 0.95, 1.0, 1.0)
		"completed":
			status_text = "✅ " + _tr("LISTO")
			badge.modulate = Color(0.2, 1.0, 0.5, 1.0)
	
	badge.text = status_text
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_font_size_override("font_size", 11)
	hbox.add_child(badge)

	btn.add_child(hbox)
	var ord_id = ord.get("id", "")
	btn.pressed.connect(func(): _select_order(ord_id))
	return btn

func _select_order(ord_id: String) -> void:
	selected_order_id = ord_id
	var ord: Dictionary = {}
	for item in orders_data:
		if item.get("id", "") == ord_id:
			ord = item
			break

	if ord.is_empty():
		return

	# Actualizar lista para resaltar la tarjeta activa
	_refresh_orders_list()

	# Llenar panel de detalle
	lbl_detail_title.text = ord.get("avatar", "") + " " + ord.get("client_name", "") + " (" + ord.get("client_type", "") + ")"
	lbl_pc_model.text = "🖥️ " + _tr("Equipo") + ": " + ord.get("pc_model", "")
	lbl_issue_desc.text = "⚠️ " + _tr("Síntoma Reportado") + ":\n\"" + ord.get("description", "") + "\""
	lbl_task_needed.text = "🔧 " + _tr("Diagnóstico / Tarea") + ":\n" + ord.get("task_needed", "")
	
	var stars_str = "⭐".repeat(ord.get("stars", 5))
	lbl_reward.text = "💰 " + _tr("Recompensa") + ": $" + str(ord.get("reward_money", 0)) + "  |  ⭐ " + stars_str + "  |  ✨ " + str(ord.get("reward_xp", 0)) + " XP"

	var sb_badge = StyleBoxFlat.new()
	sb_badge.set_corner_radius_all(4)
	sb_badge.content_margin_left = 10.0
	sb_badge.content_margin_top = 4.0
	sb_badge.content_margin_right = 10.0
	sb_badge.content_margin_bottom = 4.0

	match ord.get("status", ""):
		"pending":
			lbl_detail_badge.text = "⏳ " + _tr("ESTADO: EN ESPERA DE ASIGNACIÓN")
			lbl_detail_badge.modulate = Color(1.0, 0.85, 0.2, 1.0)
			sb_badge.bg_color = Color(0.25, 0.18, 0.04, 0.8)
			sb_badge.border_color = Color(1.0, 0.75, 0.2, 0.9)
			btn_action.disabled = false
			btn_action.text = "📥 " + _tr("ACEPTAR PEDIDO Y ENVIAR AL TALLER")
			btn_action.modulate = Color(0.0, 0.95, 1.0, 1.0)

		"in_progress":
			lbl_detail_badge.text = "🛠️ " + _tr("ESTADO: EN REPARACIÓN EN TALLER")
			lbl_detail_badge.modulate = Color(0.0, 0.95, 1.0, 1.0)
			sb_badge.bg_color = Color(0.04, 0.15, 0.25, 0.8)
			sb_badge.border_color = Color(0.0, 0.9, 1.0, 0.9)
			btn_action.disabled = false
			btn_action.text = "✅ " + _tr("COMPLETAR Y ENTREGAR A CLIENTE")
			btn_action.modulate = Color(0.2, 1.0, 0.55, 1.0)

		"completed":
			lbl_detail_badge.text = "🎉 " + _tr("ESTADO: ENTREGADO Y COBRADO")
			lbl_detail_badge.modulate = Color(0.2, 1.0, 0.5, 1.0)
			sb_badge.bg_color = Color(0.04, 0.2, 0.08, 0.8)
			sb_badge.border_color = Color(0.2, 1.0, 0.5, 0.9)
			btn_action.disabled = true
			btn_action.text = "✔️ " + _tr("ORDEN FINALIZADA CON ÉXITO")
			btn_action.modulate = Color(0.6, 0.6, 0.6, 1.0)

	sb_badge.set_border_width_all(1)
	lbl_detail_badge.add_theme_stylebox_override("normal", sb_badge)

	sb_badge.set_border_width_all(1)
	lbl_detail_badge.add_theme_stylebox_override("normal", sb_badge)

func _on_action_pressed() -> void:
	if selected_order_id.is_empty():
		return

	for ord in orders_data:
		if ord.get("id", "") == selected_order_id:
			match ord.get("status", ""):
				"pending":
					ord["status"] = "in_progress"
					_show_notification("📦 ¡Pedido " + ord["id"] + " aceptado! Equipo enviado al área de reparación.", Color(0.0, 0.95, 1.0, 1.0))
					order_accepted.emit(ord)
					var gm = _get_gm()
					if gm and gm.has_signal("order_accepted"):
						gm.order_accepted.emit(ord)
					_update_stats()
					_select_order(selected_order_id)
				"in_progress":
					ord["status"] = "completed"
					var reward_m = ord.get("reward_money", 0)
					var reward_xp = ord.get("reward_xp", 0)
					
					# Sumar fondos y puntos en GameManager si existe
					var gm = _get_gm()
					if gm and "score" in gm:
						gm.score += reward_xp
					
					_show_notification("💰 ¡Reparación finalizada! Has ganado $" + str(reward_m) + " y " + str(reward_xp) + " XP.", Color(0.2, 1.0, 0.55, 1.0))
					order_completed.emit(ord)
					if gm and gm.has_signal("order_completed"):
						gm.order_completed.emit(ord)
					_update_stats()
					_select_order(selected_order_id)
			break

func _show_notification(text: String, color: Color) -> void:
	if notification_label:
		notification_label.text = text
		notification_label.modulate = color
		notification_label.visible = true
		var tw = create_tween()
		tw.tween_interval(3.0)
		tw.tween_property(notification_label, "modulate:a", 0.0, 0.5)
		tw.tween_callback(func(): notification_label.visible = false; notification_label.modulate.a = 1.0)

func _on_close_pressed() -> void:
	modal_closed.emit()
	queue_free()
