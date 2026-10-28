extends StaticBody3D

func get_interaction_prompt() -> String:
	if GameManager.backpack.is_empty():
		return "[E] Papelera (Mochila vacía)"
	return "[E] Papelera: Desechar pieza de la mochila"

func interact(_player) -> void:
	if GameManager.trash_selected_item():
		# Pieza desechada con éxito
		pass
