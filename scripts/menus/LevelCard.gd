extends PanelContainer

signal closed()

@onready var btn_jugar_nivel: Button = $VBox/BtnJugarNivel
@onready var btn_close: Button = $VBox/HeaderHBox/BtnClose
@onready var titulo_label: Label = $VBox/HeaderHBox/TitleVBox/Titulo
@onready var subtitulo_label: Label = $VBox/HeaderHBox/TitleVBox/Subtitulo
@onready var desc_label: Label = $VBox/Descripcion
@onready var record_label: Label = $VBox/Record

var current_level_data: Dictionary = {}
var is_closing: bool = false

func _ready() -> void:
	btn_jugar_nivel.pressed.connect(_on_jugar_nivel_pressed)
	btn_close.pressed.connect(close_card)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close_card()
		get_viewport().set_input_as_handled()

func setup_level(data: Dictionary) -> void:
	current_level_data = data
	visible = true
	is_closing = false
	
	var is_playable = data.get("can_play", false)
	
	if titulo_label:
		titulo_label.text = data.get("title", "NIVEL TÉCNICO")
		var accent_col = Color(1.0, 0.1, 0.28) if is_playable else Color(0.0, 0.9, 1.0)
		titulo_label.add_theme_color_override("font_color", accent_col)
		
	if subtitulo_label:
		var mode_name = data.get("mode_name", "REPARACIÓN").to_upper()
		var stage = data.get("stage", "ETAPA I")
		if is_playable:
			subtitulo_label.text = "%s · %s · [DISPONIBLE PARA JUGAR ▶]" % [mode_name, stage]
			subtitulo_label.add_theme_color_override("font_color", Color(1.0, 0.15, 0.32))
		else:
			subtitulo_label.text = "%s · %s · [NIVEL BLOQUEADO 🔒]" % [mode_name, stage]
			subtitulo_label.add_theme_color_override("font_color", Color(0.6, 0.75, 0.88))
			
	if desc_label:
		desc_label.text = data.get("description", "Misión técnica.")
	if record_label:
		record_label.text = data.get("requirements", "OBJETIVO: Diagnosticar y reparar los módulos del sistema.")
		
	if btn_jugar_nivel:
		if is_playable:
			btn_jugar_nivel.text = "JUGAR NIVEL ▶"
			btn_jugar_nivel.disabled = false
			btn_jugar_nivel.modulate = Color(1.0, 0.15, 0.32, 1.0)
		else:
			btn_jugar_nivel.text = "🔒 MODO INSPECCIÓN"
			btn_jugar_nivel.disabled = false
			btn_jugar_nivel.modulate = Color(0.65, 0.75, 0.85, 0.9)

func open_card(data: Dictionary) -> void:
	setup_level(data)
	visible = true
	is_closing = false
	
	# Deslizar sutilmente la tarjeta compacta a la derecha del círculo ampliado
	var target_x: float = 480.0
	position.x = 540.0
	modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "position:x", target_x, 0.32)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.22)

func close_card() -> void:
	if is_closing or not visible:
		return
	is_closing = true
	closed.emit()
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "position:x", 540.0, 0.22)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(func():
		visible = false
		is_closing = false
	)

func _on_jugar_nivel_pressed() -> void:
	if current_level_data.get("can_play", false):
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("start_level"):
			gm.start_level(120.0)
		get_tree().change_scene_to_file("res://scenes/gameplay/Level1.tscn")
	else:
		close_card()
