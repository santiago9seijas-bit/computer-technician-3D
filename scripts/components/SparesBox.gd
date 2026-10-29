extends StaticBody3D

@export var spare_type: String = "RAM"

@onready var label_3d: Label3D = $Label3D

func _ready() -> void:
	_update_label()
	GameManager.spares_repopulated.connect(_update_label)

func _update_label() -> void:
	if label_3d:
		var stock = GameManager.spares_stock.get(spare_type, 0)
		label_3d.text = "REPUESTO: %s\n[ STOCK: %d ]" % [spare_type.to_upper(), stock]

func get_interaction_prompt() -> String:
	var stock = GameManager.spares_stock.get(spare_type, 0)
	if stock <= 0:
		return "Caja de %s: Sin stock (¡Usa el botón de la pared!)" % spare_type
	if GameManager.backpack.size() >= GameManager.MAX_BACKPACK_SLOTS:
		return "Caja de %s: Mochila llena (3/3)" % spare_type
	return "[E] Tomar repuesto nuevo de %s (Disponibles: %d)" % [spare_type, stock]

func interact(_player) -> void:
	var stock = GameManager.spares_stock.get(spare_type, 0)
	if stock > 0:
		if GameManager.add_item_to_backpack({"name": spare_type, "broken": false}):
			GameManager.spares_stock[spare_type] -= 1
			_update_label()
