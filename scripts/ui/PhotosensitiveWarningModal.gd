class_name PhotosensitiveWarningModal
extends Control

signal modal_closed

@onready var backdrop: ColorRect = $Backdrop
@onready var panel_container: PanelContainer = $CenterContainer/PanelContainer
@onready var btn_toggle_mode: Button = $CenterContainer/PanelContainer/Margin/VBox/ToggleRow/BtnToggleMode
@onready var lbl_mode_status: Label = $CenterContainer/PanelContainer/Margin/VBox/ToggleRow/LblStatus
@onready var btn_continuar: Button = $CenterContainer/PanelContainer/Margin/VBox/Footer/BtnContinuar

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	modulate.a = 0.0
	visible = true
	
	_update_toggle_button_visuals()
	
	btn_toggle_mode.pressed.connect(_on_toggle_pressed)
	btn_continuar.pressed.connect(_on_continuar_pressed)
	
	# Animación de entrada suave
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.35)
	if panel_container:
		panel_container.scale = Vector2(0.92, 0.92)
		tw.tween_property(panel_container, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)

func _update_toggle_button_visuals() -> void:
	var gm = get_node_or_null("/root/GameManager")
	var is_on = gm and gm.is_photosensitive_mode_enabled()
	
	if is_on:
		btn_toggle_mode.text = "MODO FOTOSENSIBLE: [ ACTIVADO ✓ ]"
		btn_toggle_mode.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5, 1.0))
		lbl_mode_status.text = "Luces continuas y destellos reducidos"
		lbl_mode_status.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5, 0.9))
	else:
		btn_toggle_mode.text = "MODO FOTOSENSIBLE: [ DESACTIVADO (Por defecto) ]"
		btn_toggle_mode.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2, 1.0))
		lbl_mode_status.text = "Efectos visuales e iluminación originales activos"
		lbl_mode_status.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 0.75))

func _on_toggle_pressed() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.toggle_photosensitive_mode()
	_update_toggle_button_visuals()

func _on_continuar_pressed() -> void:
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.22)
	if panel_container:
		tw.tween_property(panel_container, "scale", Vector2(0.95, 0.95), 0.22)
	tw.chain().tween_callback(func():
		modal_closed.emit()
		queue_free()
	)
