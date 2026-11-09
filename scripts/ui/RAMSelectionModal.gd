extends Control

signal ram_selected(ram_type: String)
signal modal_closed()

@onready var card_modal: PanelContainer = $CardModal
@onready var btn_close: Button = $CardModal/Margin/VBox/Header/BtnClose
@onready var stock_label: Label = $CardModal/Margin/VBox/Header/TitleVBox/StockLabel

# Botones de selección de cada tarjeta
@onready var btn_ddr: Button = $CardModal/Margin/VBox/CardsContainer/CardDDR/BtnSelect
@onready var btn_ddr2: Button = $CardModal/Margin/VBox/CardsContainer/CardDDR2/BtnSelect
@onready var btn_ddr3: Button = $CardModal/Margin/VBox/CardsContainer/CardDDR3/BtnSelect
@onready var btn_ddr4: Button = $CardModal/Margin/VBox/CardsContainer/CardDDR4/BtnSelect
@onready var btn_ddr5: Button = $CardModal/Margin/VBox/CardsContainer/CardDDR5/BtnSelect

var spares_box: Object = null
var player_ref: Object = null
var is_closed: bool = false

const RAM_DESCRIPTIONS: Dictionary = {
	"ddr": "RAM DDR (DDR1)",
	"ddr2": "RAM DDR2",
	"ddr3": "RAM DDR3",
	"ddr4": "RAM DDR4",
	"ddr5": "RAM DDR5"
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true
	is_closed = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if btn_close:
		btn_close.pressed.connect(_on_close_pressed)
		
	if btn_ddr: btn_ddr.pressed.connect(func(): _choose_ram("ddr"))
	if btn_ddr2: btn_ddr2.pressed.connect(func(): _choose_ram("ddr2"))
	if btn_ddr3: btn_ddr3.pressed.connect(func(): _choose_ram("ddr3"))
	if btn_ddr4: btn_ddr4.pressed.connect(func(): _choose_ram("ddr4"))
	if btn_ddr5: btn_ddr5.pressed.connect(func(): _choose_ram("ddr5"))
	
	_setup_card_hover_effects()
	_update_stock_ui()
	
	# Animación de apertura suave
	modulate.a = 0.0
	card_modal.scale = Vector2(0.92, 0.92)
	card_modal.pivot_offset = card_modal.size * 0.5 if card_modal.size != Vector2.ZERO else Vector2(530, 240)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.20)
	tw.tween_property(card_modal, "scale", Vector2.ONE, 0.20)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func setup(box: Object, player: Object) -> void:
	spares_box = box
	player_ref = player
	_update_stock_ui()

func _update_stock_ui() -> void:
	var stock = GameManager.spares_stock.get("RAM", 0)
	if stock_label:
		stock_label.text = "Stock disponible en caja: %d módulos | Mochila: %d/%d" % [
			stock,
			GameManager.backpack.size(),
			GameManager.MAX_BACKPACK_SLOTS
		]
		if stock <= 0:
			stock_label.modulate = Color(1.0, 0.3, 0.3)
		else:
			stock_label.modulate = Color(0.2, 1.0, 0.6)

func _setup_card_hover_effects() -> void:
	var cards_parent = get_node_or_null("CardModal/Margin/VBox/CardsContainer")
	if not cards_parent:
		return
	for card in cards_parent.get_children():
		if card is Control:
			card.mouse_entered.connect(func(): _animate_card_hover(card, true))
			card.mouse_exited.connect(func(): _animate_card_hover(card, false))

func _animate_card_hover(card: Control, hovered: bool) -> void:
	var tw = card.create_tween()
	var target_scale = Vector2(1.03, 1.03) if hovered else Vector2.ONE
	var target_mod = Color(1.15, 1.15, 1.15, 1.0) if hovered else Color(1.0, 1.0, 1.0, 1.0)
	card.pivot_offset = card.size * 0.5
	tw.set_parallel(true)
	tw.tween_property(card, "scale", target_scale, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate", target_mod, 0.12)

func _unhandled_input(event: InputEvent) -> void:
	if visible and not is_closed:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				get_viewport().set_input_as_handled()
				_on_close_pressed()
			elif event.keycode == KEY_1 or event.keycode == KEY_KP_1:
				_choose_ram("ddr")
			elif event.keycode == KEY_2 or event.keycode == KEY_KP_2:
				_choose_ram("ddr2")
			elif event.keycode == KEY_3 or event.keycode == KEY_KP_3:
				_choose_ram("ddr3")
			elif event.keycode == KEY_4 or event.keycode == KEY_KP_4:
				_choose_ram("ddr4")
			elif event.keycode == KEY_5 or event.keycode == KEY_KP_5:
				_choose_ram("ddr5")

func _choose_ram(ram_key: String) -> void:
	if is_closed:
		return
		
	var stock = GameManager.spares_stock.get("RAM", 0)
	if stock <= 0:
		GameManager.spawn_floating_text("¡Sin stock de RAM! Pulsa el botón de la pared.", false)
		return
		
	if GameManager.backpack.size() >= GameManager.MAX_BACKPACK_SLOTS:
		GameManager.spawn_floating_text("¡Mochila llena (3/3)! Desecha una pieza en la papelera.", false)
		return
		
	var display = RAM_DESCRIPTIONS.get(ram_key, "RAM " + ram_key.to_upper())
	var item_data = {
		"name": "RAM",
		"type": "RAM",
		"ram_type": ram_key,
		"display_name": display,
		"broken": false,
		"functional": true
	}
	
	if GameManager.add_item_to_backpack(item_data):
		GameManager.spares_stock["RAM"] -= 1
		if spares_box and spares_box.has_method("_update_label"):
			spares_box._update_label()
		GameManager.spawn_floating_text("✓ Obtenido: %s" % display, true)
		ram_selected.emit(ram_key)
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
