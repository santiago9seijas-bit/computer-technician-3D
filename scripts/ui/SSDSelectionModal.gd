extends Control

signal storage_selected(storage_type: String)
signal modal_closed()

@onready var card_modal: PanelContainer = $CardModal
@onready var btn_close: Button = $CardModal/Margin/VBox/Header/BtnClose
@onready var stock_label: Label = $CardModal/Margin/VBox/Header/TitleVBox/StockLabel

# Botones frontales de selección de cada tarjeta
@onready var btn_sata: Button = $CardModal/Margin/VBox/CardsContainer/CardSATA/BtnSelect
@onready var btn_m2_nvme: Button = $CardModal/Margin/VBox/CardsContainer/CardM2NVME/BtnSelect
@onready var btn_m2_sata: Button = $CardModal/Margin/VBox/CardsContainer/CardM2SATA/BtnSelect
@onready var btn_hdd: Button = $CardModal/Margin/VBox/CardsContainer/CardHDD/BtnSelect

var spares_box: Object = null
var player_ref: Object = null
var is_closed: bool = false
var flipping_cards: Array = []

const STORAGE_CONFIG: Dictionary = {
	"sata_ssd": {
		"title": "SSD SATA 2.5\"",
		"tag": "[1] SSD SATA",
		"drive_type": "ssd",
		"capacities": ["128 GB", "256 GB", "512 GB", "1 TB", "2 TB"],
		"default_cap": "512 GB",
		"color": Color(0.2, 0.95, 1.0)
	},
	"m2_nvme": {
		"title": "SSD M.2 NVMe PCIe",
		"tag": "[2] M.2 NVMe",
		"drive_type": "m2",
		"capacities": ["256 GB", "512 GB", "1 TB", "2 TB"],
		"default_cap": "1 TB",
		"color": Color(1.0, 0.85, 0.2)
	},
	"m2_sata": {
		"title": "SSD M.2 SATA",
		"tag": "[3] M.2 SATA",
		"drive_type": "m2",
		"capacities": ["128 GB", "256 GB", "512 GB", "1 TB"],
		"default_cap": "256 GB",
		"color": Color(0.2, 1.0, 0.6)
	},
	"hdd": {
		"title": "Disco HDD Mecánico 3.5\"",
		"tag": "[4] HDD 3.5\"",
		"drive_type": "hdd",
		"capacities": ["500 GB", "1 TB", "2 TB", "4 TB"],
		"default_cap": "1 TB",
		"color": Color(1.0, 0.15, 0.55)
	}
}

var card_nodes: Dictionary = {}
var selected_capacities: Dictionary = {}
var card_flipped: Dictionary = {}
var back_side_nodes: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true
	is_closed = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	card_nodes = {
		"sata_ssd": get_node_or_null("CardModal/Margin/VBox/CardsContainer/CardSATA"),
		"m2_nvme": get_node_or_null("CardModal/Margin/VBox/CardsContainer/CardM2NVME"),
		"m2_sata": get_node_or_null("CardModal/Margin/VBox/CardsContainer/CardM2SATA"),
		"hdd": get_node_or_null("CardModal/Margin/VBox/CardsContainer/CardHDD")
	}
	
	for storage_key in STORAGE_CONFIG.keys():
		selected_capacities[storage_key] = STORAGE_CONFIG[storage_key]["default_cap"]
		card_flipped[storage_key] = false
		var card = card_nodes.get(storage_key)
		if card:
			_build_card_backside(card, storage_key)
	
	if btn_close:
		btn_close.pressed.connect(_on_close_pressed)
		
	if btn_sata: btn_sata.pressed.connect(func(): _toggle_card_flip("sata_ssd"))
	if btn_m2_nvme: btn_m2_nvme.pressed.connect(func(): _toggle_card_flip("m2_nvme"))
	if btn_m2_sata: btn_m2_sata.pressed.connect(func(): _toggle_card_flip("m2_sata"))
	if btn_hdd: btn_hdd.pressed.connect(func(): _toggle_card_flip("hdd"))
	
	_setup_card_hover_effects()
	_update_stock_ui()
	
	# Animación de apertura suave
	modulate.a = 0.0
	card_modal.scale = Vector2(0.92, 0.92)
	card_modal.pivot_offset = card_modal.size * 0.5 if card_modal.size != Vector2.ZERO else Vector2(510, 240)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.20)
	tw.tween_property(card_modal, "scale", Vector2.ONE, 0.20)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func setup(box: Object, player: Object) -> void:
	spares_box = box
	player_ref = player
	_update_stock_ui()

func _update_stock_ui() -> void:
	var stock = GameManager.spares_stock.get("Disco Duro", 0)
	if stock_label:
		stock_label.text = "Stock disponible en caja: %d unidades | Mochila: %d/%d" % [
			stock,
			GameManager.backpack.size(),
			GameManager.MAX_BACKPACK_SLOTS
		]
		if stock <= 0:
			stock_label.modulate = Color(1.0, 0.3, 0.3)
		else:
			stock_label.modulate = Color(0.2, 1.0, 0.6)

func _setup_card_hover_effects() -> void:
	for storage_key in card_nodes.keys():
		var card: Control = card_nodes[storage_key]
		if card:
			card.mouse_entered.connect(func(): _animate_card_hover(card, true))
			card.mouse_exited.connect(func(): _animate_card_hover(card, false))

func _animate_card_hover(card: Control, hovered: bool) -> void:
	if card in flipping_cards:
		return
	var tw = card.create_tween()
	var target_scale = Vector2(1.025, 1.025) if hovered else Vector2.ONE
	var target_mod = Color(1.12, 1.12, 1.12, 1.0) if hovered else Color(1.0, 1.0, 1.0, 1.0)
	card.pivot_offset = card.size * 0.5
	tw.set_parallel(true)
	tw.tween_property(card, "scale", target_scale, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate", target_mod, 0.12)

# =============================================================================
# CONSTRUCCIÓN DEL REVERSO (SELECCIÓN DE CAPACIDAD)
# =============================================================================
func _build_card_backside(card: Control, storage_key: String) -> void:
	var cfg = STORAGE_CONFIG[storage_key]
	
	var back = VBoxContainer.new()
	back.name = "BackSide"
	back.visible = false
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.size_flags_vertical = Control.SIZE_EXPAND_FILL
	back.alignment = BoxContainer.ALIGNMENT_CENTER
	back.set("theme_override_constants/separation", 8)
	
	var margin = MarginContainer.new()
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.set("theme_override_constants/margin_left", 10)
	margin.set("theme_override_constants/margin_top", 12)
	margin.set("theme_override_constants/margin_right", 10)
	margin.set("theme_override_constants/margin_bottom", 6)
	back.add_child(margin)
	
	var content = VBoxContainer.new()
	content.set("theme_override_constants/separation", 6)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(content)
	
	# Tag / Título
	var tag_lbl = Label.new()
	tag_lbl.text = cfg["tag"]
	tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_lbl.modulate = cfg["color"]
	tag_lbl.set("theme_override_font_sizes/font_size", 13)
	content.add_child(tag_lbl)
	
	var sub_lbl = Label.new()
	sub_lbl.text = "ELIGE CAPACIDAD:"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.modulate = Color(0.7, 0.85, 1.0, 0.9)
	sub_lbl.set("theme_override_font_sizes/font_size", 10)
	content.add_child(sub_lbl)
	
	# Contenedor de botones de capacidad
	var caps_container = VBoxContainer.new()
	caps_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caps_container.alignment = BoxContainer.ALIGNMENT_CENTER
	caps_container.set("theme_override_constants/separation", 5)
	content.add_child(caps_container)
	
	var btn_caps_map = {}
	
	# Etiqueta de previsualización
	var sel_lbl = Label.new()
	sel_lbl.text = "Capacidad: " + cfg["default_cap"]
	sel_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sel_lbl.modulate = Color(0.2, 1.0, 0.6)
	sel_lbl.set("theme_override_font_sizes/font_size", 11)
	content.add_child(sel_lbl)
	
	# Botón Tomar
	var btn_tomar = Button.new()
	btn_tomar.name = "BtnTomar"
	btn_tomar.custom_minimum_size = Vector2(0, 34)
	btn_tomar.size_flags_vertical = Control.SIZE_SHRINK_END
	btn_tomar.text = "✓ TOMAR (%s)" % cfg["default_cap"]
	btn_tomar.modulate = cfg["color"]
	btn_tomar.set("theme_override_font_sizes/font_size", 11)
	btn_tomar.pressed.connect(func(): _choose_storage(storage_key, selected_capacities[storage_key]))
	back.add_child(btn_tomar)
	
	# Botón Volver (girar de vuelta al frente)
	var btn_volver = Button.new()
	btn_volver.name = "BtnVolver"
	btn_volver.custom_minimum_size = Vector2(0, 24)
	btn_volver.size_flags_vertical = Control.SIZE_SHRINK_END
	btn_volver.text = "↩ VOLVER AL FRENTE"
	btn_volver.flat = true
	btn_volver.modulate = Color(0.7, 0.75, 0.85, 0.8)
	btn_volver.set("theme_override_font_sizes/font_size", 9.5)
	btn_volver.pressed.connect(func(): _toggle_card_flip(storage_key))
	back.add_child(btn_volver)
	
	# Crear botones para cada capacidad
	for cap in cfg["capacities"]:
		var b = Button.new()
		b.text = "UNIDAD " + cap
		b.custom_minimum_size = Vector2(0, 26)
		b.set("theme_override_font_sizes/font_size", 10.5)
		caps_container.add_child(b)
		btn_caps_map[cap] = b
		
		var this_cap = cap
		b.pressed.connect(func():
			selected_capacities[storage_key] = this_cap
			sel_lbl.text = "Capacidad: " + this_cap
			btn_tomar.text = "✓ TOMAR (%s)" % this_cap
			_refresh_cap_buttons(btn_caps_map, this_cap, cfg["color"])
		)
	
	_refresh_cap_buttons(btn_caps_map, cfg["default_cap"], cfg["color"])
	card.add_child(back)
	back_side_nodes[storage_key] = {
		"back": back,
		"btn_tomar": btn_tomar,
		"sel_lbl": sel_lbl,
		"btn_caps_map": btn_caps_map
	}

func _refresh_cap_buttons(caps_map: Dictionary, active_cap: String, active_color: Color) -> void:
	for cap in caps_map.keys():
		var btn: Button = caps_map[cap]
		if cap == active_cap:
			btn.modulate = Color(1.2, 1.2, 1.2, 1.0)
			btn.text = "▶ " + cap + " ◀"
		else:
			btn.modulate = Color(0.75, 0.8, 0.9, 0.7)
			btn.text = "  " + cap

# =============================================================================
# ANIMACIÓN DE GIRO (CARD FLIP)
# =============================================================================
func _toggle_card_flip(storage_key: String) -> void:
	var card: Control = card_nodes.get(storage_key)
	if not card:
		return
	if is_closed:
		return
		
	var is_flipped = card_flipped.get(storage_key, false)
	if is_flipped:
		card_flipped[storage_key] = false
		_flip_card_tween(card, false)
	else:
		# Girar de vuelta cualquier otra carta que esté dada vuelta
		for other_key in card_nodes.keys():
			if other_key != storage_key and card_flipped.get(other_key, false):
				card_flipped[other_key] = false
				_flip_card_tween(card_nodes[other_key], false)
				
		card_flipped[storage_key] = true
		_flip_card_tween(card, true)

func _flip_card_tween(card: Control, to_back: bool) -> void:
	if card in flipping_cards:
		return
	flipping_cards.append(card)
	
	card.pivot_offset = card.size * 0.5
	var tw = create_tween()
	tw.tween_property(card, "scale:x", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		var front = card.get_node_or_null("VBox")
		var back = card.get_node_or_null("BackSide")
		if front: front.visible = not to_back
		if back: back.visible = to_back
	)
	tw.tween_property(card, "scale:x", 1.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		flipping_cards.erase(card)
	)

# =============================================================================
# ENTRADA DE TECLADO Y SELECCIÓN FINAL
# =============================================================================
func _unhandled_input(event: InputEvent) -> void:
	if visible and not is_closed:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				get_viewport().set_input_as_handled()
				_on_close_pressed()
			elif event.keycode == KEY_1 or event.keycode == KEY_KP_1:
				_handle_key_selection("sata_ssd")
			elif event.keycode == KEY_2 or event.keycode == KEY_KP_2:
				_handle_key_selection("m2_nvme")
			elif event.keycode == KEY_3 or event.keycode == KEY_KP_3:
				_handle_key_selection("m2_sata")
			elif event.keycode == KEY_4 or event.keycode == KEY_KP_4:
				_handle_key_selection("hdd")

func _handle_key_selection(storage_key: String) -> void:
	if card_flipped.get(storage_key, false):
		_choose_storage(storage_key, selected_capacities[storage_key])
	else:
		_toggle_card_flip(storage_key)

func _choose_storage(storage_key: String, capacity: String = "") -> void:
	if is_closed:
		return
		
	var stock = GameManager.spares_stock.get("Disco Duro", 0)
	if stock <= 0:
		GameManager.spawn_floating_text("¡Sin stock de Almacenamiento! Pulsa el botón de la pared.", false)
		return
		
	if GameManager.backpack.size() >= GameManager.MAX_BACKPACK_SLOTS:
		GameManager.spawn_floating_text("¡Mochila llena (3/3)! Desecha una pieza en la papelera.", false)
		return
		
	var cfg = STORAGE_CONFIG[storage_key]
	if capacity == "":
		capacity = selected_capacities.get(storage_key, cfg["default_cap"])
		
	var display = "%s (%s)" % [cfg["title"], capacity]
	var item_data = {
		"name": "Disco Duro",
		"type": "Disco Duro",
		"drive_type": cfg["drive_type"],
		"storage_type": storage_key,
		"capacity": capacity,
		"display_name": display,
		"broken": false,
		"functional": true
	}
	
	if GameManager.add_item_to_backpack(item_data):
		GameManager.spares_stock["Disco Duro"] -= 1
		if spares_box and spares_box.has_method("_update_label"):
			spares_box._update_label()
		GameManager.spawn_floating_text("✓ Obtenido: %s" % display, true)
		storage_selected.emit(storage_key)
		_close_dialog()

func _on_close_pressed() -> void:
	if is_closed:
		return
	_close_dialog()

func _close_dialog() -> void:
	if is_closed:
		return
	is_closed = true
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_property(card_modal, "scale", Vector2(0.92, 0.92), 0.15)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func():
		visible = false
		modal_closed.emit()
		
		# Solo rehabilitar movimiento si NO hay un diálogo activo en la escena
		var current_sc = get_tree().current_scene
		var is_dialog = false
		if current_sc and "is_dialog_active" in current_sc and current_sc.is_dialog_active:
			is_dialog = true
		var dlg = get_tree().root.find_child("DialogBox", true, false)
		if is_instance_valid(dlg) and dlg.visible and dlg.get("is_active"):
			is_dialog = true
				
		if not is_dialog:
			if player_ref and is_instance_valid(player_ref) and player_ref.has_method("set_movement_enabled"):
				player_ref.set_movement_enabled(true)
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			if player_ref and is_instance_valid(player_ref) and player_ref.has_method("set_movement_enabled"):
				player_ref.set_movement_enabled(false)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			
		queue_free()
	)
