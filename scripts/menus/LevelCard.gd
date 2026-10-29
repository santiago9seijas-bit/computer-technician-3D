extends PanelContainer

@onready var btn_jugar_nivel: Button = $HBox/VBox/BtnJugarNivel
@onready var btn_close: Button = $BtnClose
@onready var number_label: Label = $HBox/BadgeContainer/CircleBadge/NumberLabel
@onready var titulo_label: Label = $HBox/VBox/Titulo
@onready var subtitulo_label: Label = $HBox/VBox/Subtitulo
@onready var desc_label: Label = $HBox/VBox/Descripcion
@onready var record_label: Label = $HBox/VBox/Record

var current_level_data: Dictionary = {}

func _ready() -> void:
	btn_jugar_nivel.pressed.connect(_on_jugar_nivel_pressed)
	btn_close.pressed.connect(func(): visible = false)

func setup_level(data: Dictionary) -> void:
	current_level_data = data
	visible = true
	
	if number_label:
		number_label.text = str(data.get("number", 1))
	if titulo_label:
		titulo_label.text = data.get("title", "NIVEL TÉCNICO")
		titulo_label.add_theme_color_override("font_color", data.get("color_accent", Color(1.0, 0.15, 0.45)))
	if subtitulo_label:
		var mode_name = data.get("mode_name", "REPARACIÓN").to_upper()
		var stage = data.get("stage", "ETAPA I")
		subtitulo_label.text = "%s · %s · [NIVEL BLOQUEADO 🔒]" % [mode_name, stage]
	if desc_label:
		desc_label.text = data.get("description", "Misión técnica.")
	if record_label:
		record_label.text = data.get("requirements", "OBJETIVO: Diagnosticar y reparar los módulos del sistema.")
		
	if btn_jugar_nivel:
		if data.get("can_play", false):
			btn_jugar_nivel.text = "JUGAR NIVEL"
			btn_jugar_nivel.disabled = false
			btn_jugar_nivel.modulate = Color(1.2, 1.2, 1.2)
		else:
			btn_jugar_nivel.text = "🔒 MODO INSPECCIÓN"
			btn_jugar_nivel.disabled = false
			btn_jugar_nivel.modulate = Color(0.9, 0.8, 1.0)

func _on_jugar_nivel_pressed() -> void:
	if current_level_data.get("can_play", false):
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("start_level"):
			gm.start_level(120.0)
		get_tree().change_scene_to_file("res://scenes/gameplay/Level1.tscn")
	else:
		# Feedback informativo para niveles bloqueados
		visible = false
