extends Control

@onready var btn_volver: Button = $TopBar/BtnVolver
@onready var btn_reparacion: Button = $ModeSelector/BtnReparacion
@onready var btn_sistema: Button = $ModeSelector/BtnSistema
@onready var btn_servidor: Button = $ModeSelector/BtnServidor
@onready var level_card_modal: Control = $LevelCardModal
@onready var node_level_1: Button = $ConstellationArea/Node1

func _ready() -> void:
	btn_volver.pressed.connect(_on_volver_pressed)
	node_level_1.pressed.connect(_on_node_1_pressed)
	if level_card_modal:
		level_card_modal.visible = false

func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")

func _on_node_1_pressed() -> void:
	if level_card_modal:
		level_card_modal.visible = true
