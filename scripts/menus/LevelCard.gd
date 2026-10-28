extends PanelContainer

@onready var btn_jugar_nivel: Button = $HBox/VBox/BtnJugarNivel
@onready var btn_close: Button = $BtnClose

func _ready() -> void:
	btn_jugar_nivel.pressed.connect(_on_jugar_nivel_pressed)
	btn_close.pressed.connect(func(): visible = false)

func _on_jugar_nivel_pressed() -> void:
	GameManager.start_level(120.0)
	get_tree().change_scene_to_file("res://scenes/gameplay/Level1.tscn")
