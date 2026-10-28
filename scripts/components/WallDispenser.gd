extends StaticBody3D

@onready var indicator_light: OmniLight3D = $IndicatorLight

func get_interaction_prompt() -> String:
	return "[E] Botón de Pared: Reabastecer Repuestos"

func interact(_player) -> void:
	GameManager.request_spares_refill()
	if indicator_light:
		indicator_light.light_color = Color(0, 1, 0.4, 1)
		var tween = create_tween()
		tween.tween_property(indicator_light, "light_color", Color(1, 0.08, 0.45, 1), 1.0)
