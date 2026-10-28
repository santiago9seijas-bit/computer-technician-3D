extends Control

@onready var btn_jugar: Button = $VBoxContainer/BtnJugar
@onready var btn_controles: Button = $VBoxContainer/BtnControles
@onready var btn_tutoriales: Button = $VBoxContainer/BtnTutoriales
@onready var btn_configuracion: Button = $VBoxContainer/BtnConfiguracion
@onready var btn_salir: Button = $VBoxContainer/BtnSalir
@onready var controls_modal: PanelContainer = $ControlsModal

func _ready() -> void:
	btn_jugar.pressed.connect(_on_jugar_pressed)
	btn_controles.pressed.connect(_on_controles_pressed)
	btn_tutoriales.pressed.connect(_on_tutoriales_pressed)
	btn_configuracion.pressed.connect(_on_configuracion_pressed)
	btn_salir.pressed.connect(_on_salir_pressed)
	
	if controls_modal:
		controls_modal.visible = false
		var close_btn = controls_modal.get_node_or_null("VBox/BtnCerrar")
		if close_btn:
			close_btn.pressed.connect(func(): controls_modal.visible = false)

func _on_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/LevelSelect.tscn")

func _on_controles_pressed() -> void:
	if controls_modal:
		controls_modal.visible = true

func _on_tutoriales_pressed() -> void:
	# Ir al selector de niveles con tutoriales
	get_tree().change_scene_to_file("res://scenes/menus/LevelSelect.tscn")

func _on_configuracion_pressed() -> void:
	# Modal o ajuste rápido
	if controls_modal:
		controls_modal.visible = true

func _on_salir_pressed() -> void:
	get_tree().quit()
