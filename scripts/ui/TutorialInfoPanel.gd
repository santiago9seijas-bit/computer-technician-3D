class_name TutorialInfoPanel
extends Control

signal launch_requested

@onready var card_panel: PanelContainer = $CardPanel
@onready var title_label: Label = $CardPanel/Margin/VBox/HeaderBox/LblTitle
@onready var sub_label: Label = $CardPanel/Margin/VBox/HeaderBox/LblSubtitle
@onready var pieces_container: VBoxContainer = $CardPanel/Margin/VBox/PiecesContainer
@onready var btn_iniciar: TextureButton = $CardPanel/Margin/VBox/BottomRow/BtnIniciar
@onready var btn_label: Label = $CardPanel/Margin/VBox/BottomRow/BtnIniciar/LblBtn

var btn_shader_mat: ShaderMaterial = null
var idle_tween: Tween = null
var is_hovered: bool = false

const LAUNCH_SHADER = preload("res://styles/cyber_launch_button.gdshader")

func _ready() -> void:
	_setup_button_shader()
	
	if btn_iniciar:
		_make_children_mouse_ignore(btn_iniciar)
		btn_iniciar.mouse_entered.connect(_on_btn_mouse_entered)
		btn_iniciar.mouse_exited.connect(_on_btn_mouse_exited)
		btn_iniciar.pressed.connect(_on_btn_pressed)
		btn_iniciar.pivot_offset = Vector2(125.0, 27.0)
		_start_idle_pulse()

func _make_children_mouse_ignore(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_make_children_mouse_ignore(child)

func _setup_button_shader() -> void:
	if not btn_iniciar:
		return
	btn_shader_mat = ShaderMaterial.new()
	btn_shader_mat.shader = LAUNCH_SHADER
	# Tonos azul eléctrico / cian neón para el botón del tutorial
	btn_shader_mat.set_shader_parameter("border_color", Color(0.0, 0.88, 1.0, 1.0))
	btn_shader_mat.set_shader_parameter("hover_color", Color(0.65, 1.0, 1.0, 1.0))
	btn_shader_mat.set_shader_parameter("glass_tint", Color(0.01, 0.06, 0.18, 0.9))
	btn_shader_mat.set_shader_parameter("is_hovered", 0.0)
	btn_shader_mat.set_shader_parameter("shine_speed", 2.6)
	btn_shader_mat.set_shader_parameter("pulse_speed", 4.2)
	btn_shader_mat.set_shader_parameter("chromatic_shift", 1.8)
	btn_iniciar.material = btn_shader_mat

func _start_idle_pulse() -> void:
	if not is_instance_valid(btn_iniciar):
		return
	if idle_tween and idle_tween.is_valid():
		idle_tween.kill()
		
	idle_tween = create_tween().set_loops()
	idle_tween.tween_property(btn_iniciar, "scale", Vector2(1.025, 1.025), 1.05)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.tween_property(btn_iniciar, "scale", Vector2(1.0, 1.0), 1.05)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func open_for_tutorial(mode: String = "reparacion") -> void:
	visible = true
	modulate.a = 0.0
	pivot_offset = size * 0.5
	scale = Vector2(0.96, 0.96)
	
	if card_panel:
		var sb = card_panel.get_theme_stylebox("panel")
		if sb is StyleBoxFlat:
			var nsb = sb.duplicate() as StyleBoxFlat
			nsb.border_color = Color(0.0, 0.88, 1.0, 0.95)
			nsb.shadow_color = Color(0.0, 0.65, 1.0, 0.35)
			card_panel.add_theme_stylebox_override("panel", nsb)
	
	_configure_content(mode)
	if btn_label:
		btn_label.text = "▶ INICIAR TUTORIAL"
	if btn_shader_mat:
		btn_shader_mat.set_shader_parameter("border_color", Color(0.0, 0.88, 1.0, 1.0))
		btn_shader_mat.set_shader_parameter("hover_color", Color(0.65, 1.0, 1.0, 1.0))
		btn_shader_mat.set_shader_parameter("glass_tint", Color(0.01, 0.06, 0.18, 0.9))
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE, 0.24)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.22)
	
	_start_idle_pulse()

func open_for_practice(data: Dictionary = {}) -> void:
	visible = true
	modulate.a = 0.0
	pivot_offset = size * 0.5
	scale = Vector2(0.96, 0.96)
	
	if card_panel:
		var sb = card_panel.get_theme_stylebox("panel")
		if sb is StyleBoxFlat:
			var nsb = sb.duplicate() as StyleBoxFlat
			nsb.border_color = Color(1.0, 0.55, 0.05, 0.95)
			nsb.shadow_color = Color(1.0, 0.45, 0.0, 0.35)
			card_panel.add_theme_stylebox_override("panel", nsb)
	
	if title_label:
		title_label.text = data.get("title", "SALA DE PRÁCTICA 3D")
	if sub_label:
		sub_label.text = "// MODO ENTRENAMIENTO LIBRE · TIEMPO ILIMITADO //"
	if btn_label:
		btn_label.text = "▶ INICIAR PRÁCTICA"
	if btn_shader_mat:
		btn_shader_mat.set_shader_parameter("border_color", Color(1.0, 0.55, 0.05, 1.0))
		btn_shader_mat.set_shader_parameter("hover_color", Color(1.0, 0.85, 0.4, 1.0))
		btn_shader_mat.set_shader_parameter("glass_tint", Color(0.18, 0.08, 0.01, 0.9))
		
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE, 0.24)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.22)
	
	_start_idle_pulse()

func _configure_content(mode: String) -> void:
	match mode:
		"sistema":
			if title_label:
				title_label.text = "TUTORIAL: INDUCCIÓN DE SISTEMAS"
			if sub_label:
				sub_label.text = "// CICLOS POST, SETUP UEFI & ARRANQUE SEGURO //"
		"servidor":
			if title_label:
				title_label.text = "TUTORIAL: DATACENTER & CLOUD"
			if sub_label:
				sub_label.text = "// RACKS, CONECTIVIDAD SAS & ENERGÍA REDUNDANTE //"
		_:
			if title_label:
				title_label.text = "TUTORIAL: REPARACIÓN BÁSICA"
			if sub_label:
				sub_label.text = "// EXTRACCIÓN Y DIAGNÓSTICO DE PIEZAS CLAVE //"

func play_exit_animation() -> void:
	if not visible:
		return
	if idle_tween and idle_tween.is_valid():
		idle_tween.kill()
		
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2(0.96, 0.96), 0.18)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.16)
	tw.chain().tween_callback(func():
		visible = false
		scale = Vector2.ONE
	)

func _on_btn_mouse_entered() -> void:
	is_hovered = true
	if btn_shader_mat:
		var tw = create_tween()
		tw.tween_method(func(v: float):
			if btn_shader_mat:
				btn_shader_mat.set_shader_parameter("is_hovered", v)
		, 0.0, 1.0, 0.15)
	if btn_iniciar:
		var tw_s = create_tween()
		tw_s.tween_property(btn_iniciar, "scale", Vector2(1.05, 1.05), 0.12)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_btn_mouse_exited() -> void:
	is_hovered = false
	if btn_shader_mat:
		var tw = create_tween()
		tw.tween_method(func(v: float):
			if btn_shader_mat:
				btn_shader_mat.set_shader_parameter("is_hovered", v)
		, 1.0, 0.0, 0.15)
	if btn_iniciar:
		var tw_s = create_tween()
		tw_s.tween_property(btn_iniciar, "scale", Vector2(1.0, 1.0), 0.12)
	_start_idle_pulse()

func _on_btn_pressed() -> void:
	if btn_iniciar:
		var punch_tw = create_tween()
		punch_tw.tween_property(btn_iniciar, "scale", Vector2(0.93, 0.93), 0.07)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		punch_tw.tween_property(btn_iniciar, "scale", Vector2(1.08, 1.08), 0.14)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		punch_tw.tween_property(btn_iniciar, "scale", Vector2(1.0, 1.0), 0.1)
		
	launch_requested.emit()
