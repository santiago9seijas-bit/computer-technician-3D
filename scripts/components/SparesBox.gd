extends StaticBody3D

@export var spare_type: String = "RAM"

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
