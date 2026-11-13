extends StaticBody3D

@export var spare_type: String = "TODOS"

@onready var label_3d: Label3D = $Label3D

var ram_selection_modal_scene: PackedScene = preload("res://scenes/ui/RAMSelectionModal.tscn")
var ssd_selection_modal_scene: PackedScene = preload("res://scenes/ui/SSDSelectionModal.tscn")
var spares_modal_scene: PackedScene = preload("res://scenes/ui/SparesSelectionModal.tscn")

func _ready() -> void:
	_update_label()
	if GameManager.has_signal("spares_repopulated"):
		GameManager.spares_repopulated.connect(_update_label)

func _is_master_box() -> bool:
	return spare_type == "TODOS" or spare_type == "" or spare_type == "Caja"

func _get_display_name() -> String:
	if _is_master_box():
		return "CAJA DE REPUESTOS"
	match spare_type:
		"Disco Duro":
			return "SSD / DISCO DURO"
		"Refrigeracion Liquida":
			return "REFRIG. LÍQUIDA"
		"Placa Madre":
			return "PLACA MADRE"
		"Fan Cooler":
			return "FAN COOLER"
		_:
			return spare_type

func _update_label() -> void:
	if not label_3d:
		return
	if _is_master_box():
		label_3d.text = "📦 CAJA DE REPUESTOS\n[ PRESIONA E ]"
		label_3d.modulate = Color(0.2, 1.0, 0.7, 1)
	else:
		var stock = GameManager.spares_stock.get(spare_type, 0)
		if stock > 0:
			label_3d.text = "📦 %s\n[ STOCK: %d ]\n[E] TOMAR" % [_get_display_name().to_upper(), stock]
			label_3d.modulate = Color(0.2, 1.0, 0.7, 1)
		else:
			label_3d.text = "📦 %s\n[ SIN STOCK ]\n(Recargar en botón)" % _get_display_name().to_upper()
			label_3d.modulate = Color(1.0, 0.35, 0.35, 1)

func get_interaction_prompt() -> String:
	if _is_master_box():
		return "[E] Abrir caja: Buscar repuestos de reemplazo"
	var stock = GameManager.spares_stock.get(spare_type, 0)
	var d_name = _get_display_name()
	if stock <= 0:
		return "Caja de %s: Sin stock (¡Usa el botón de la pared!)" % d_name
	if GameManager.backpack.size() >= GameManager.MAX_BACKPACK_SLOTS:
		return "Caja de %s: Mochila llena (3/3)" % d_name
	if spare_type == "RAM":
		return "[E] Abrir caja de RAM: Elegir modelo (Disponibles: %d)" % stock
	if spare_type == "Disco Duro":
		return "[E] Abrir caja de Almacenamiento SSD/HDD: Elegir modelo (Disponibles: %d)" % stock
	return "[E] Tomar repuesto nuevo de %s (Disponibles: %d)" % [d_name, stock]

func interact(player) -> void:
	if _is_master_box():
		_open_master_spares_modal(player)
		return
		
	var stock = GameManager.spares_stock.get(spare_type, 0)
	var d_name = _get_display_name()
	if stock <= 0:
		GameManager.spawn_floating_text("¡Sin stock de %s! Usa el botón de pared." % d_name, false)
		return
	if GameManager.backpack.size() >= GameManager.MAX_BACKPACK_SLOTS:
		GameManager.spawn_floating_text("¡Mochila llena (3/3)! Desecha una pieza en la papelera.", false)
		return
		
	if spare_type == "RAM":
		_open_ram_selection(player)
		return
	if spare_type == "Disco Duro":
		_open_storage_selection(player)
		return
		
	if GameManager.add_item_to_backpack({"name": spare_type, "type": spare_type, "broken": false, "functional": true}):
		GameManager.spares_stock[spare_type] -= 1
		GameManager.spawn_floating_text("+ %s (Nuevo)" % d_name, true)
		_update_label()

func _open_master_spares_modal(player) -> void:
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var modal = spares_modal_scene.instantiate()
	get_tree().root.add_child(modal)
	modal.setup(self, player)

func _open_ram_selection(player) -> void:
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var modal = ram_selection_modal_scene.instantiate()
	get_tree().root.add_child(modal)
	modal.setup(self, player)

func _open_storage_selection(player) -> void:
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var modal = ssd_selection_modal_scene.instantiate()
	get_tree().root.add_child(modal)
	modal.setup(self, player)
