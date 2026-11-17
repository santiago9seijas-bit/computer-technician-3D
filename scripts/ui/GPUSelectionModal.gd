extends Control

signal gpu_selected(gpu_type: String)
signal modal_closed()

@onready var card_modal: PanelContainer = $CardModal
@onready var btn_close: Button = $CardModal/Margin/VBox/Header/BtnClose
@onready var stock_label: Label = $CardModal/Margin/VBox/Header/TitleVBox/StockLabel

@onready var btn_mono: Button = $CardModal/Margin/VBox/CardsContainer/CardMono/BtnSelect
@onready var btn_dual: Button = $CardModal/Margin/VBox/CardsContainer/CardDual/BtnSelect

var spares_box: Object = null
var player_ref: Object = null
var is_closed: bool = false
var flipping_cards: Array = []

const GPU_CONFIG: Dictionary = {
	"monocooler": {
		"title": "GPU Monocooler 1 Fan",
		"tag": "[1] MONOCOOLER (ITX)",
		"gpu_type": "monocooler",
		"capacities": ["4 GB", "6 GB", "8 GB", "12 GB"],
		"default_cap": "8 GB",
		"color": Color(0.2, 0.95, 1.0)
	},
	"dual_cooler": {
		"title": "GPU 2 Coolers Dual Fan",
		"tag": "[2] DUAL COOLER (GAMING)",
		"gpu_type": "dual_cooler",
		"capacities": ["8 GB", "12 GB", "16 GB", "24 GB"],
		"default_cap": "16 GB",
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
		"monocooler": get_node_or_null("CardModal/Margin/VBox/CardsContainer/CardMono"),
		"dual_cooler": get_node_or_null("CardModal/Margin/VBox/CardsContainer/CardDual")
	}
	
	for gpu_key in GPU_CONFIG.keys():
		selected_capacities[gpu_key] = GPU_CONFIG[gpu_key]["default_cap"]
		card_flipped[gpu_key] = false
		var card = card_nodes.get(gpu_key)
		if card:
			_build_card_backside(card, gpu_key)
	
	if btn_close:
		btn_close.pressed.connect(_on_close_pressed)
		
	if btn_mono: btn_mono.pressed.connect(func(): _toggle_card_flip("monocooler"))
	if btn_dual: btn_dual.pressed.connect(func(): _toggle_card_flip("dual_cooler"))
	
	_setup_card_hover_effects()
	_update_stock_ui()
	
	modulate.a = 0.0
	card_modal.scale = Vector2(0.92, 0.92)
	card_modal.pivot_offset = card_modal.size * 0.5 if card_modal.size != Vector2.ZERO else Vector2(400, 240)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.20)
	tw.tween_property(card_modal, "scale", Vector2.ONE, 0.20)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func setup(box: Object, player: Object = null) -> void:
	spares_box = box
	player_ref = player
	_update_stock_ui()

func _update_stock_ui() -> void:
	var stock = GameManager.spares_stock.get("Grafica", 0)
	if stock_label:
		stock_label.text = "STOCK DISPONIBLE EN CAJA: %d UNIDADES" % stock
		stock_label.modulate = Color(0.2, 1.0, 0.5) if stock > 0 else Color(1.0, 0.3, 0.3)
	
	for gpu_key in card_nodes.keys():
		var btn = btn_mono if gpu_key == "monocooler" else btn_dual
		if btn:
			btn.disabled = (stock <= 0)

func _setup_card_hover_effects() -> void:
	for gpu_key in card_nodes.keys():
		var card = card_nodes[gpu_key]
		if not card: continue
		card.pivot_offset = Vector2(160, 160)
		card.mouse_entered.connect(func():
			if not card_flipped.get(gpu_key, false) and not (gpu_key in flipping_cards):
				var tw = create_tween()
				tw.tween_property(card, "scale", Vector2(1.03, 1.03), 0.12)
		)
		card.mouse_exited.connect(func():
			if not card_flipped.get(gpu_key, false) and not (gpu_key in flipping_cards):
				var tw = create_tween()
				tw.tween_property(card, "scale", Vector2.ONE, 0.12)
		)

func _build_card_backside(card: Control, gpu_key: String) -> void:
	var cfg = GPU_CONFIG[gpu_key]
	var back_panel = PanelContainer.new()
	back_panel.name = "BackSide"
	back_panel.visible = false
	back_panel.layout_mode = 1
	back_panel.anchors_preset = Control.PRESET_FULL_RECT
	back_panel.offset_left = 0
	back_panel.offset_top = 0
	back_panel.offset_right = 0
	back_panel.offset_bottom = 0
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.12, 0.98)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = cfg["color"]
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
	sb.shadow_color = cfg["color"] * Color(1, 1, 1, 0.3)
	sb.shadow_size = 6
	back_panel.add_theme_stylebox_override("panel", sb)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	back_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = "ELEGIR VRAM (GB):"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", cfg["color"])
	title_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(title_lbl)
	
	var cap_grid = GridContainer.new()
	cap_grid.columns = 2
	cap_grid.add_theme_constant_override("h_separation", 6)
	cap_grid.add_theme_constant_override("v_separation", 6)
	cap_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(cap_grid)
	
	var cap_buttons: Array[Button] = []
	for cap in cfg["capacities"]:
		var b = Button.new()
		b.text = cap
		b.custom_minimum_size = Vector2(0, 32)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 11)
		
		if cap == cfg["default_cap"]:
			b.modulate = Color(1.3, 1.3, 0.4, 1.0)
		else:
			b.modulate = Color(0.8, 0.85, 0.95, 0.8)
			
		b.pressed.connect(func():
			selected_capacities[gpu_key] = cap
			for ob in cap_buttons:
				if ob.text == cap:
					ob.modulate = Color(1.3, 1.3, 0.4, 1.0)
				else:
					ob.modulate = Color(0.8, 0.85, 0.95, 0.8)
		)
		cap_grid.add_child(b)
		cap_buttons.append(b)
		
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	var btn_confirm = Button.new()
	btn_confirm.text = "TOMAR REPUESTO ❯"
	btn_confirm.custom_minimum_size = Vector2(0, 36)
	btn_confirm.modulate = Color(0.2, 1.1, 0.5, 1.0)
	btn_confirm.pressed.connect(func():
		_select_gpu_spare(gpu_key)
	)
	vbox.add_child(btn_confirm)
	
	var btn_flip_back = Button.new()
	btn_flip_back.text = "↩ VOLVER"
	btn_flip_back.custom_minimum_size = Vector2(0, 26)
	btn_flip_back.modulate = Color(0.7, 0.7, 0.8, 0.8)
	btn_flip_back.pressed.connect(func():
		_toggle_card_flip(gpu_key)
	)
	vbox.add_child(btn_flip_back)
	
	card.add_child(back_panel)
	back_side_nodes[gpu_key] = back_panel

func _toggle_card_flip(gpu_key: String) -> void:
	if gpu_key in flipping_cards:
		return
		
	var card = card_nodes.get(gpu_key)
	var back = back_side_nodes.get(gpu_key)
	var front_vbox = card.get_node_or_null("VBox")
	var front_btn = card.get_node_or_null("BtnSelect")
	if not card or not back: return
	
	flipping_cards.append(gpu_key)
	var is_to_back = not card_flipped.get(gpu_key, false)
	card.pivot_offset = Vector2(card.size.x * 0.5, card.size.y * 0.5)
	
	var tw = create_tween()
	tw.tween_property(card, "scale:x", 0.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		if is_to_back:
			if front_vbox: front_vbox.visible = false
			if front_btn: front_btn.visible = false
			back.visible = true
		else:
			back.visible = false
			if front_vbox: front_vbox.visible = true
			if front_btn: front_btn.visible = true
		card_flipped[gpu_key] = is_to_back
	)
	tw.tween_property(card, "scale:x", 1.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		flipping_cards.erase(gpu_key)
	)

func _select_gpu_spare(gpu_key: String) -> void:
	var stock = GameManager.spares_stock.get("Grafica", 0)
	if stock <= 0:
		GameManager.spawn_floating_text("¡Sin stock de Tarjetas Gráficas!", false)
		return
		
	if GameManager.backpack.size() >= GameManager.MAX_BACKPACK_SLOTS:
		GameManager.spawn_floating_text("¡Mochila llena (3/3)! Desecha una pieza en la papelera.", false)
		return
		
	var cfg = GPU_CONFIG[gpu_key]
	var capacity = selected_capacities.get(gpu_key, cfg["default_cap"])
	var display = "%s (%s)" % [cfg["title"], capacity]
	
	var item_data = {
		"name": "Grafica",
		"type": "Grafica",
		"gpu_type": cfg["gpu_type"],
		"capacity": capacity,
		"display_name": display,
		"broken": false,
		"functional": true
	}
	
	if GameManager.add_item_to_backpack(item_data):
		GameManager.spares_stock["Grafica"] -= 1
		if spares_box and spares_box.has_method("_update_label"):
			spares_box._update_label()
		GameManager.spawn_floating_text("✓ Obtenido: %s" % display, true)
		gpu_selected.emit(gpu_key)
		_close_dialog()

func _on_close_pressed() -> void:
	if is_closed: return
	_close_dialog()

func _close_dialog() -> void:
	if is_closed: return
	is_closed = true
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_property(card_modal, "scale", Vector2(0.85, 0.85), 0.15)
	
	await tw.finished
	if player_ref and player_ref.has_method("set_movement_enabled"):
		player_ref.set_movement_enabled(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	modal_closed.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		_on_close_pressed()
