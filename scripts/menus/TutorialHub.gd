extends Control

# =============================================================================
# TUTORIAL HUB (REDIRECCIÓN AL SISTEMA UNIFICADO LEVEL SELECT / ENTRENAMIENTO)
# =============================================================================

var LevelSelectScript = preload("res://scripts/menus/LevelSelect.gd")

func _ready() -> void:
	call_deferred("_redirect_to_level_select")

func _redirect_to_level_select() -> void:
	LevelSelectScript.initial_tab = "tutoriales"
	get_tree().change_scene_to_file("res://scenes/menus/LevelSelect.tscn")
