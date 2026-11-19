class_name TutorialInfoPanel
extends Control

signal launch_requested
signal unlock_requested(data: Dictionary)

enum LevelButtonState {
	PLAYABLE,
	LOCKED_PREV_INCOMPLETE,
	LOCKED_INSUFFICIENT_POINTS,
	CAN_UNLOCK
}

@onready var card_panel: PanelContainer = $CardPanel
@onready var title_label: Label = $CardPanel/Margin/VBox/HeaderBox/LblTitle
@onready var sub_label: Label = $CardPanel/Margin/VBox/HeaderBox/LblSubtitle
@onready var pieces_container: VBoxContainer = $CardPanel/Margin/VBox/PiecesContainer
@onready var btn_iniciar: TextureButton = $CardPanel/Margin/VBox/BottomRow/BtnIniciar
@onready var btn_label: Label = $CardPanel/Margin/VBox/BottomRow/BtnIniciar/LblBtn

var btn_shader_mat: ShaderMaterial = null
var idle_tween: Tween = null
var _panel_tween: Tween = null
var is_hovered: bool = false
var button_state: LevelButtonState = LevelButtonState.PLAYABLE
var current_req_points: int = 0
var current_player_points: int = 0
var is_prev_completed: bool = true
var current_node_data: Dictionary = {}

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
	if _panel_tween and _panel_tween.is_valid():
		_panel_tween.kill()
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
	if btn_iniciar:
		btn_iniciar.modulate = Color.WHITE
	if btn_shader_mat:
		btn_shader_mat.set_shader_parameter("border_color", Color(0.0, 0.88, 1.0, 1.0))
		btn_shader_mat.set_shader_parameter("hover_color", Color(0.65, 1.0, 1.0, 1.0))
		btn_shader_mat.set_shader_parameter("glass_tint", Color(0.01, 0.06, 0.18, 0.9))
	
	_panel_tween = create_tween().set_parallel(true)
	_panel_tween.tween_property(self, "scale", Vector2.ONE, 0.24)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_panel_tween.tween_property(self, "modulate:a", 1.0, 0.22)
	
	_start_idle_pulse()

func open_for_tutorial_node(data: Dictionary, req_points: int = 0, player_points: int = 0, prev_completed: bool = true) -> void:
	if _panel_tween and _panel_tween.is_valid():
		_panel_tween.kill()
	visible = true
	modulate.a = 0.0
	pivot_offset = size * 0.5
	scale = Vector2(0.96, 0.96)
	
	current_node_data = data
	current_req_points = req_points
	current_player_points = player_points
	is_prev_completed = prev_completed
	var is_playable = data.get("can_play", false)
	
	if is_playable:
		button_state = LevelButtonState.PLAYABLE
	elif not prev_completed:
		button_state = LevelButtonState.LOCKED_PREV_INCOMPLETE
	elif player_points < req_points:
		button_state = LevelButtonState.LOCKED_INSUFFICIENT_POINTS
	else:
		button_state = LevelButtonState.CAN_UNLOCK
	
	if card_panel:
		var sb = card_panel.get_theme_stylebox("panel")
		if sb is StyleBoxFlat:
			var nsb = sb.duplicate() as StyleBoxFlat
			nsb.border_color = Color(0.0, 0.88, 1.0, 0.95)
			nsb.shadow_color = Color(0.0, 0.65, 1.0, 0.35)
			card_panel.add_theme_stylebox_override("panel", nsb)
	
	if title_label:
		title_label.text = data.get("title", "NÚCLEO TUTORIAL")
	if sub_label:
		sub_label.text = data.get("stage", "// APRENDIZAJE TÉCNICO GUIADO CON JOA //")
		
	if pieces_container:
		for ch in pieces_container.get_children():
			ch.queue_free()
		var desc_lbl = Label.new()
		desc_lbl.text = data.get("description", "Aprende los protocolos paso a paso con la asistencia técnica de Joa.")
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0, 0.9))
		pieces_container.add_child(desc_lbl)
		
		if data.has("requirements"):
			var req_lbl = Label.new()
			req_lbl.text = data.get("requirements", "")
			req_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			req_lbl.add_theme_font_size_override("font_size", 10)
			req_lbl.add_theme_color_override("font_color", Color(0.2, 0.95, 1.0, 0.8))
			pieces_container.add_child(req_lbl)
		
		match button_state:
			LevelButtonState.CAN_UNLOCK:
				var unl_lbl = Label.new()
				unl_lbl.text = "✓ ¡TIENES LOS %d PUNTOS NECESARIOS! (Tienes %d PTS) · Los puntos no se consumen al desbloquear." % [req_points, player_points]
				unl_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				unl_lbl.add_theme_font_size_override("font_size", 10)
				unl_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6, 0.95))
				pieces_container.add_child(unl_lbl)
			LevelButtonState.LOCKED_INSUFFICIENT_POINTS:
				var pts_lbl = Label.new()
				pts_lbl.text = "⚠️ PUNTOS NECESARIOS: %d · TIENES: %d · Completa más retos para conseguir puntos." % [req_points, player_points]
				pts_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				pts_lbl.add_theme_font_size_override("font_size", 10)
				pts_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2, 0.95))
				pieces_container.add_child(pts_lbl)
			LevelButtonState.LOCKED_PREV_INCOMPLETE:
				var lck_lbl = Label.new()
				lck_lbl.text = "🔒 Debes completar el nivel anterior para desbloquear este nivel. (Puntos requeridos: %d)" % req_points
				lck_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				lck_lbl.add_theme_font_size_override("font_size", 10)
				lck_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45, 0.95))
				pieces_container.add_child(lck_lbl)
		
	match button_state:
		LevelButtonState.PLAYABLE:
			if btn_label:
				btn_label.text = "▶ INICIAR TUTORIAL"
			if btn_iniciar:
				btn_iniciar.modulate = Color.WHITE
			if btn_shader_mat:
				btn_shader_mat.set_shader_parameter("border_color", Color(0.0, 0.88, 1.0, 1.0))
		LevelButtonState.CAN_UNLOCK:
			if btn_label:
				btn_label.text = "🔓 DESBLOQUEAR (%d PTS)" % req_points
			if btn_iniciar:
				btn_iniciar.modulate = Color.WHITE
			if btn_shader_mat:
				btn_shader_mat.set_shader_parameter("border_color", Color(0.2, 1.0, 0.5, 1.0))
		LevelButtonState.LOCKED_INSUFFICIENT_POINTS:
			if btn_label:
				btn_label.text = "🔒 PUNTOS INSUFICIENTES"
			if btn_iniciar:
				btn_iniciar.modulate = Color(0.85, 0.8, 0.75, 0.8)
			if btn_shader_mat:
				btn_shader_mat.set_shader_parameter("border_color", Color(1.0, 0.6, 0.2, 0.8))
		LevelButtonState.LOCKED_PREV_INCOMPLETE:
			if btn_label:
				btn_label.text = "🔒 BLOQUEADO"
			if btn_iniciar:
				btn_iniciar.modulate = Color(0.65, 0.65, 0.65, 0.6)
			if btn_shader_mat:
				btn_shader_mat.set_shader_parameter("border_color", Color(0.4, 0.5, 0.6, 0.8))
	
	_panel_tween = create_tween().set_parallel(true)
	_panel_tween.tween_property(self, "scale", Vector2.ONE, 0.24)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_panel_tween.tween_property(self, "modulate:a", 1.0, 0.22)
	
	_start_idle_pulse()

func open_for_inspection_node(data: Dictionary = {}, req_points: int = 0, player_points: int = 0, prev_completed: bool = true) -> void:
	if _panel_tween and _panel_tween.is_valid():
		_panel_tween.kill()
	visible = true
	modulate.a = 0.0
	pivot_offset = size * 0.5
	scale = Vector2(0.96, 0.96)
	
	current_node_data = data
	current_req_points = req_points
	current_player_points = player_points
	is_prev_completed = prev_completed
	var is_playable = data.get("can_play", false)
	
	if is_playable:
		button_state = LevelButtonState.PLAYABLE
	elif not prev_completed:
		button_state = LevelButtonState.LOCKED_PREV_INCOMPLETE
	elif player_points < req_points:
		button_state = LevelButtonState.LOCKED_INSUFFICIENT_POINTS
	else:
		button_state = LevelButtonState.CAN_UNLOCK
	
	if card_panel:
		var sb = card_panel.get_theme_stylebox("panel")
		if sb is StyleBoxFlat:
			var nsb = sb.duplicate() as StyleBoxFlat
			nsb.border_color = Color(0.85, 0.25, 1.0, 0.95)
			nsb.shadow_color = Color(0.65, 0.10, 0.90, 0.35)
			card_panel.add_theme_stylebox_override("panel", nsb)
			
	if title_label:
		title_label.text = data.get("title", "TALLER DE PRECISIÓN · LUPA")
	if sub_label:
		sub_label.text = data.get("stage", "// ZONA DE INSPECCIÓN // LUPA TÉCNICA //")
		
	if pieces_container:
		for ch in pieces_container.get_children():
			ch.queue_free()
			
		var desc_lbl = Label.new()
		desc_lbl.text = data.get("description", "Micro-taller de inspección y mantenimiento minucioso con lupa técnica.")
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 1.0, 0.92))
		pieces_container.add_child(desc_lbl)
		
		# Cuadro destacado con el mensaje de Joa
		if data.has("joa_speech") and data["joa_speech"] != "":
			var joa_panel = PanelContainer.new()
			var joa_sb = StyleBoxFlat.new()
			joa_sb.bg_color = Color(0.18, 0.04, 0.28, 0.75)
			joa_sb.border_color = Color(0.85, 0.35, 1.0, 0.8)
			joa_sb.set_border_width_all(1)
			joa_sb.set_corner_radius_all(6)
			joa_sb.content_margin_left = 10
			joa_sb.content_margin_top = 8
			joa_sb.content_margin_right = 10
			joa_sb.content_margin_bottom = 8
			joa_panel.add_theme_stylebox_override("panel", joa_sb)
			
			var joa_vbox = VBoxContainer.new()
			joa_vbox.add_theme_constant_override("separation", 4)
			
			var joa_title = Label.new()
			joa_title.text = "💬 JOA // ASISTENTE TÉCNICA:"
			joa_title.add_theme_font_size_override("font_size", 10)
			joa_title.add_theme_color_override("font_color", Color(1.0, 0.65, 0.95, 1.0))
			joa_vbox.add_child(joa_title)
			
			var joa_txt = Label.new()
			joa_txt.text = data.get("joa_speech", "")
			joa_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			joa_txt.add_theme_font_size_override("font_size", 10)
			joa_txt.add_theme_color_override("font_color", Color(0.92, 0.88, 1.0, 0.95))
			joa_vbox.add_child(joa_txt)
			
			joa_panel.add_child(joa_vbox)
			pieces_container.add_child(joa_panel)
			
		if data.has("requirements"):
			var req_lbl = Label.new()
			req_lbl.text = data.get("requirements", "")
			req_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			req_lbl.add_theme_font_size_override("font_size", 10)
			req_lbl.add_theme_color_override("font_color", Color(0.85, 0.45, 1.0, 0.85))
			pieces_container.add_child(req_lbl)
			
		match button_state:
			LevelButtonState.CAN_UNLOCK:
				var unl_lbl = Label.new()
				unl_lbl.text = "✓ ¡TIENES LOS %d PUNTOS NECESARIOS! (Tienes %d PTS)" % [req_points, player_points]
				unl_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				unl_lbl.add_theme_font_size_override("font_size", 10)
				unl_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6, 0.95))
				pieces_container.add_child(unl_lbl)
			LevelButtonState.LOCKED_INSUFFICIENT_POINTS:
				var pts_lbl = Label.new()
				pts_lbl.text = "⚠️ PUNTOS NECESARIOS: %d · TIENES: %d · Completa más retos para conseguir puntos." % [req_points, player_points]
				pts_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				pts_lbl.add_theme_font_size_override("font_size", 10)
				pts_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2, 0.95))
				pieces_container.add_child(pts_lbl)
			LevelButtonState.LOCKED_PREV_INCOMPLETE:
				var lck_lbl = Label.new()
				lck_lbl.text = "🔒 Supera el Nivel 1 en el taller para desbloquear este micro-taller de lupa."
				lck_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				lck_lbl.add_theme_font_size_override("font_size", 10)
				lck_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45, 0.95))
				pieces_container.add_child(lck_lbl)
				
	match button_state:
		LevelButtonState.PLAYABLE:
			if btn_label:
				btn_label.text = "▶ INICIAR MINIJUEGO"
			if btn_iniciar:
				btn_iniciar.modulate = Color.WHITE
			if btn_shader_mat:
				btn_shader_mat.set_shader_parameter("border_color", Color(0.85, 0.25, 1.0, 1.0))
		LevelButtonState.CAN_UNLOCK:
			if btn_label:
				btn_label.text = "🔓 DESBLOQUEAR (%d PTS)" % req_points
			if btn_iniciar:
				btn_iniciar.modulate = Color.WHITE
			if btn_shader_mat:
				btn_shader_mat.set_shader_parameter("border_color", Color(0.3, 1.0, 0.6, 1.0))
		LevelButtonState.LOCKED_INSUFFICIENT_POINTS:
			if btn_label:
				btn_label.text = "🔒 PUNTOS INSUFICIENTES"
			if btn_iniciar:
				btn_iniciar.modulate = Color(0.85, 0.8, 0.75, 0.8)
			if btn_shader_mat:
				btn_shader_mat.set_shader_parameter("border_color", Color(1.0, 0.6, 0.2, 0.8))
		LevelButtonState.LOCKED_PREV_INCOMPLETE:
			if btn_label:
				btn_label.text = "🔒 BLOQUEADO"
			if btn_iniciar:
				btn_iniciar.modulate = Color(0.65, 0.65, 0.65, 0.6)
			if btn_shader_mat:
				btn_shader_mat.set_shader_parameter("border_color", Color(0.5, 0.4, 0.6, 0.8))
				
	_panel_tween = create_tween().set_parallel(true)
	_panel_tween.tween_property(self, "scale", Vector2.ONE, 0.24)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_panel_tween.tween_property(self, "modulate:a", 1.0, 0.22)
	
	_start_idle_pulse()

func open_for_practice(data: Dictionary = {}, req_points: int = 0, player_points: int = 0, prev_completed: bool = true) -> void:
	if _panel_tween and _panel_tween.is_valid():
		_panel_tween.kill()
	visible = true
	modulate.a = 0.0
	pivot_offset = size * 0.5
	scale = Vector2(0.96, 0.96)
	
	current_node_data = data
	current_req_points = req_points
	current_player_points = player_points
	is_prev_completed = prev_completed
	var is_playable = data.get("can_play", false)
	
	if is_playable:
		button_state = LevelButtonState.PLAYABLE
	elif not prev_completed:
		button_state = LevelButtonState.LOCKED_PREV_INCOMPLETE
	elif player_points < req_points:
		button_state = LevelButtonState.LOCKED_INSUFFICIENT_POINTS
	else:
		button_state = LevelButtonState.CAN_UNLOCK
	
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
		sub_label.text = data.get("stage", "// MODO ENTRENAMIENTO LIBRE · TIEMPO ILIMITADO //")
		
	if pieces_container:
		for ch in pieces_container.get_children():
			ch.queue_free()
		var desc_lbl = Label.new()
		desc_lbl.text = data.get("description", "Banco de trabajo libre sin límite de tiempo.")
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.8, 0.9))
		pieces_container.add_child(desc_lbl)
		
		if data.has("requirements"):
			var req_lbl = Label.new()
			req_lbl.text = data.get("requirements", "")
			req_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			req_lbl.add_theme_font_size_override("font_size", 10)
			req_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2, 0.8))
			pieces_container.add_child(req_lbl)
			
		match button_state:
			LevelButtonState.CAN_UNLOCK:
				var unl_lbl = Label.new()
				unl_lbl.text = "✓ ¡TIENES LOS %d PUNTOS NECESARIOS! (Tienes %d PTS) · Los puntos no se consumen al desbloquear." % [req_points, player_points]
				unl_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				unl_lbl.add_theme_font_size_override("font_size", 10)
				unl_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6, 0.95))
				pieces_container.add_child(unl_lbl)
			LevelButtonState.LOCKED_INSUFFICIENT_POINTS:
				var pts_lbl = Label.new()
				pts_lbl.text = "⚠️ PUNTOS NECESARIOS: %d · TIENES: %d · Completa retos para conseguir puntos." % [req_points, player_points]
				pts_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				pts_lbl.add_theme_font_size_override("font_size", 10)
				pts_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2, 0.95))
				pieces_container.add_child(pts_lbl)
			LevelButtonState.LOCKED_PREV_INCOMPLETE:
				var lck_lbl = Label.new()
				lck_lbl.text = "🔒 Debes completar el nivel anterior para desbloquear este nivel. (Puntos requeridos: %d)" % req_points
				lck_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				lck_lbl.add_theme_font_size_override("font_size", 10)
				lck_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45, 0.95))
				pieces_container.add_child(lck_lbl)
		
	match button_state:
		LevelButtonState.PLAYABLE:
			if btn_label:
				btn_label.text = "▶ INICIAR RETO (8 MIN)"
			if btn_iniciar:
				btn_iniciar.modulate = Color.WHITE
			if btn_shader_mat:
				btn_shader_mat.set_shader_parameter("border_color", Color(1.0, 0.55, 0.05, 1.0))
		LevelButtonState.CAN_UNLOCK:
			if btn_label:
				btn_label.text = "🔓 DESBLOQUEAR (%d PTS)" % req_points
			if btn_iniciar:
				btn_iniciar.modulate = Color.WHITE
			if btn_shader_mat:
				btn_shader_mat.set_shader_parameter("border_color", Color(0.2, 1.0, 0.5, 1.0))
		LevelButtonState.LOCKED_INSUFFICIENT_POINTS:
			if btn_label:
				btn_label.text = "🔒 PUNTOS INSUFICIENTES"
			if btn_iniciar:
				btn_iniciar.modulate = Color(0.85, 0.8, 0.75, 0.8)
			if btn_shader_mat:
				btn_shader_mat.set_shader_parameter("border_color", Color(1.0, 0.6, 0.2, 0.8))
		LevelButtonState.LOCKED_PREV_INCOMPLETE:
			if btn_label:
				btn_label.text = "🔒 BLOQUEADO"
			if btn_iniciar:
				btn_iniciar.modulate = Color(0.65, 0.65, 0.65, 0.6)
			if btn_shader_mat:
				btn_shader_mat.set_shader_parameter("border_color", Color(0.5, 0.5, 0.5, 0.8))
		
	_panel_tween = create_tween().set_parallel(true)
	_panel_tween.tween_property(self, "scale", Vector2.ONE, 0.24)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_panel_tween.tween_property(self, "modulate:a", 1.0, 0.22)
	
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
	if _panel_tween and _panel_tween.is_valid():
		_panel_tween.kill()
		
	_panel_tween = create_tween().set_parallel(true)
	_panel_tween.tween_property(self, "scale", Vector2(0.96, 0.96), 0.18)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_panel_tween.tween_property(self, "modulate:a", 0.0, 0.16)
	_panel_tween.chain().tween_callback(func():
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

func _play_unlock_button_animation(on_finished: Callable = Callable()) -> void:
	if idle_tween and idle_tween.is_valid():
		idle_tween.kill()
	if not btn_iniciar:
		if on_finished.is_valid():
			on_finished.call()
		return
	btn_iniciar.pivot_offset = Vector2(125.0, 27.0)
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("play_sfx"):
		gm.play_sfx("click")
	var tw = create_tween()
	tw.tween_property(btn_iniciar, "scale", Vector2(0.90, 0.90), 0.07).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(btn_iniciar, "scale", Vector2(1.18, 1.18), 0.12)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn_iniciar, "scale", Vector2.ONE, 0.12)
	tw.chain().tween_callback(func():
		_start_idle_pulse()
		if on_finished.is_valid():
			on_finished.call()
	)

func _on_btn_pressed() -> void:
	match button_state:
		LevelButtonState.CAN_UNLOCK:
			_play_unlock_button_animation(func():
				unlock_requested.emit(current_node_data)
			)
		LevelButtonState.LOCKED_PREV_INCOMPLETE, LevelButtonState.LOCKED_INSUFFICIENT_POINTS:
			var gm = get_node_or_null("/root/GameManager")
			if gm and gm.has_method("play_sfx"):
				gm.play_sfx("error")
			if btn_iniciar:
				var shake_tw = create_tween()
				shake_tw.tween_property(btn_iniciar, "position:x", btn_iniciar.position.x - 6.0, 0.04)
				shake_tw.tween_property(btn_iniciar, "position:x", btn_iniciar.position.x + 6.0, 0.04)
				shake_tw.tween_property(btn_iniciar, "position:x", btn_iniciar.position.x, 0.04)
		LevelButtonState.PLAYABLE:
			if btn_iniciar:
				var punch_tw = create_tween()
				punch_tw.tween_property(btn_iniciar, "scale", Vector2(0.93, 0.93), 0.07)\
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				punch_tw.tween_property(btn_iniciar, "scale", Vector2(1.08, 1.08), 0.14)\
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				punch_tw.tween_property(btn_iniciar, "scale", Vector2.ONE, 0.1)
			launch_requested.emit()
