class_name SparesSelectionModal
extends Control

signal modal_closed

@onready var btn_close: Button = $PanelContainer/Margin/VBox/Header/BtnCerrar
@onready var grid_container: GridContainer = $PanelContainer/Margin/VBox/Scroll/Grid
@onready var lbl_backpack: Label = $PanelContainer/Margin/VBox/Footer/LblBackpack

var spares_box_ref = null
var player_ref = null

const PART_DATA = [
	{
		"key": "RAM",
		"name": "Memoria RAM",
		"icon": "🧠",
		"desc": "Módulos DDR / DDR2 / DDR3 / DDR4 / DDR5",
		"color": Color(0.0, 0.88, 1.0)
	},
	{
		"key": "Disco Duro",
		"name": "Almacenamiento SSD/HDD",
		"icon": "💽",
		"desc": "Unidades SATA 2.5\", M.2 NVMe y HDD 3.5\"",
		"color": Color(0.2, 1.0, 0.5)
	},
	{
		"key": "Fan Cooler",
		"name": "Fan Cooler (Disipador)",
		"icon": "❄️",
		"desc": "Disipador con ventilador PWM de 4 pines",
		"color": Color(0.3, 0.7, 1.0)
	},
	{
		"key": "Grafica",
		"name": "Tarjeta Gráfica (GPU)",
		"icon": "🎮",
		"desc": "GPU PCIe 16X de alto rendimiento",
		"color": Color(1.0, 0.2, 0.6)
	},
	{
		"key": "Fuente",
		"name": "Fuente de Poder (PSU)",
		"icon": "⚡",
		"desc": "Fuente ATX modular certificada",
		"color": Color(1.0, 0.85, 0.2)
	},
	{
		"key": "Placa Madre",
		"name": "Placa Base (MOBO)",
		"icon": "🖲️",
		"desc": "Motherboard con zócalos y ranuras de expansión",
		"color": Color(0.7, 0.3, 1.0)
	},
	{
		"key": "CPU",
		"name": "Procesador (CPU)",
		"icon": "🔬",
		"desc": "Microprocesador central multinúcleo",
		"color": Color(1.0, 0.5, 0.2)
	},
	{
		"key": "Refrigeracion Liquida",
		"name": "Refrigeración Líquida",
		"icon": "💧",
		"desc": "Bomba AIO con radiador y tubos de refrigerante",
		"color": Color(0.1, 0.9, 0.9)
	}
]

func setup(spares_box, player) -> void:
	spares_box_ref = spares_box
	player_ref = player
	_build_ui()

func _ready() -> void:
	if btn_close:
		btn_close.pressed.connect(close_modal)
	_update_backpack_label()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_E:
			get_viewport().set_input_as_handled()
			close_modal()

func _build_ui() -> void:
	if not grid_container:
		return
	for c in grid_container.get_children():
		c.queue_free()
		
	for p in PART_DATA:
		var card = _create_part_card(p)
		grid_container.add_child(card)

func _create_part_card(data: Dictionary) -> PanelContainer:
	var key = data.key
	var stock = GameManager.spares_stock.get(key, 0)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(240, 110)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.03, 0.12, 0.92)
	sb.border_color = data.color * 0.7
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", sb)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	
	# Fila encabezado con Icono y Nombre
	var hbox_head = HBoxContainer.new()
	var lbl_icon = Label.new()
	lbl_icon.text = data.icon
	lbl_icon.add_theme_font_size_override("font_size", 18)
	hbox_head.add_child(lbl_icon)
	
	var lbl_name = Label.new()
	lbl_name.text = data.name
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_name.add_theme_color_override("font_color", data.color)
	lbl_name.add_theme_font_size_override("font_size", 13)
	hbox_head.add_child(lbl_name)
	vbox.add_child(hbox_head)
	
	# Descripción corta
	var lbl_desc = Label.new()
	lbl_desc.text = data.desc
	lbl_desc.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 0.8))
	lbl_desc.add_theme_font_size_override("font_size", 10)
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl_desc)
	
	# Fila inferior con Stock y Botón Tomar
	var hbox_bot = HBoxContainer.new()
	var lbl_stock = Label.new()
	lbl_stock.text = "Stock: %d" % stock
	lbl_stock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_stock.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5) if stock > 0 else Color(1.0, 0.25, 0.25))
	lbl_stock.add_theme_font_size_override("font_size", 11)
	hbox_bot.add_child(lbl_stock)
	
	var btn_take = Button.new()
	btn_take.text = "ELEGIR" if (key == "RAM" or key == "Disco Duro") else "TOMAR"
	btn_take.custom_minimum_size = Vector2(85, 26)
	btn_take.disabled = (stock <= 0)
	btn_take.pressed.connect(_on_take_part.bind(key))
	hbox_bot.add_child(btn_take)
	
	vbox.add_child(hbox_bot)
	return panel

func _on_take_part(key: String) -> void:
	var stock = GameManager.spares_stock.get(key, 0)
	if stock <= 0:
		GameManager.spawn_floating_text("¡Sin stock de %s! Usa el botón de pared." % key, false)
		return
		
	if GameManager.backpack.size() >= GameManager.MAX_BACKPACK_SLOTS:
		GameManager.spawn_floating_text("¡Mochila llena (3/3)!", false)
		return
		
	if key == "RAM":
		close_modal()
		if spares_box_ref and spares_box_ref.has_method("_open_ram_selection"):
			spares_box_ref._open_ram_selection(player_ref)
		return
		
	if key == "Disco Duro":
		close_modal()
		if spares_box_ref and spares_box_ref.has_method("_open_storage_selection"):
			spares_box_ref._open_storage_selection(player_ref)
		return
		
	# Para el resto de componentes se añaden directo a la mochila
	var item = {
		"name": key,
		"type": key,
		"broken": false,
		"functional": true
	}
	if GameManager.add_item_to_backpack(item):
		GameManager.spares_stock[key] -= 1
		GameManager.spawn_floating_text("+1 %s agregado a la mochila" % key, true)
		_update_backpack_label()
		_build_ui()
		if spares_box_ref and spares_box_ref.has_method("_update_label"):
			spares_box_ref._update_label()

func _update_backpack_label() -> void:
	if lbl_backpack:
		var count = GameManager.backpack.size()
		var max_slots = GameManager.MAX_BACKPACK_SLOTS
		lbl_backpack.text = "MOCHILA DEL TÉCNICO: %d / %d ESPACIOS OCUPADOS" % [count, max_slots]
		if count >= max_slots:
			lbl_backpack.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		else:
			lbl_backpack.add_theme_color_override("font_color", Color(0.2, 1.0, 0.6))

func close_modal() -> void:
	if player_ref and player_ref.has_method("set_movement_enabled"):
		player_ref.set_movement_enabled(true)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	modal_closed.emit()
	queue_free()
