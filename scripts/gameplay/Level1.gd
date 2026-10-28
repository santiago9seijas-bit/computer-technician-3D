extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var hud: Control = $CanvasLayer/HUD
@onready var pause_menu: Control = $CanvasLayer/PauseMenu

func _ready() -> void:
	if player and hud:
		player.hud_node = hud
		
	# Reiniciar o arrancar nivel
	GameManager.start_level(120.0)
	
	# Conectar botones de victoria / derrota del HUD
	var btn_reintentar = hud.get_node_or_null("GameOverPanel/VBox/BtnReiniciarGO") as Button
	if btn_reintentar:
		btn_reintentar.pressed.connect(_on_reintentar)
		
	var btn_siguiente = hud.get_node_or_null("WinPanel/VBox/BtnSiguiente") as Button
	if btn_siguiente:
		btn_siguiente.pressed.connect(_on_siguiente)

func _on_reintentar() -> void:
	get_tree().reload_current_scene()

func _on_siguiente() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/LevelSelect.tscn")
