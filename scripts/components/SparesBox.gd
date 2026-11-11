extends StaticBody3D

@export var spare_type: String = "RAM"

@onready var label_3d: Label3D = $Label3D

var ram_selection_modal_scene: PackedScene = preload("res://scenes/ui/RAMSelectionModal.tscn")
var ssd_selection_modal_scene: PackedScene = preload("res://scenes/ui/SSDSelectionModal.tscn")

func _ready() -> void:
	_update_label()
	GameManager.spares_repopulated.connect(_update_label)

func _get_display_name() -> String:
	if spare_type == "Disco Duro":
		return "SSD / HDD"
	return spare_type

func _update_label() -> void:
	if label_3d:
		var stock = GameManager.spares_stock.get(spare_type, 0)
		label_3d.text = "REPUESTO: %s\n[ STOCK: %d ]" % [_get_display_name().to_upper(), stock]

func get_interaction_prompt() -> String:
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
	var stock = GameManager.spares_stock.get(spare_type, 0)
	if stock <= 0:
		GameManager.spawn_floating_text("¡Sin stock de %s! Usa el botón de pared." % spare_type, false)
		return
	if GameManager.backpack.size() >= GameManager.MAX_BACKPACK_SLOTS:
		GameManager.spawn_floating_text("¡Mochila llena (3/3)!", false)
		return
		
	if spare_type == "RAM":
		_open_ram_selection(player)
		return
	if spare_type == "Disco Duro":
		_open_storage_selection(player)
		return
		
	if GameManager.add_item_to_backpack({"name": spare_type, "type": spare_type, "broken": false, "functional": true}):
		GameManager.spares_stock[spare_type] -= 1
		_update_label()

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
