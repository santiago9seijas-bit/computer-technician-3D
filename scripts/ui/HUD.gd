extends Control

@onready var lbl_errores: Label = $TopLeft/LblErrores
@onready var lbl_tiempo: Label = $TopCenter/LblTiempo
@onready var lbl_puntaje: Label = $BottomLeft/LblPuntaje
@onready var backpack_container: VBoxContainer = $TopRight/BackpackContainer
@onready var prompt_label: Label = $Center/PromptLabel
@onready var crosshair: Control = $Center/Crosshair
@onready var tools_bar: HBoxContainer = $BottomCenter/ToolsBar
@onready var floating_feedback_container: Control = $FloatingFeedback
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var win_panel: PanelContainer = $WinPanel

var cinematic_overlay: Control = null
var top_cinematic_bar: ColorRect = null
var bottom_cinematic_bar: ColorRect = null
var optic_flash_rect: ColorRect = null
var optic_text_label: Label = null
var is_cinematic_active: bool = false

func _ready() -> void:
	game_over_panel.visible = false
	win_panel.visible = false
	prompt_label.text = ""
	
	GameManager.score_updated.connect(_on_score_updated)
	GameManager.time_updated.connect(_on_time_updated)
	GameManager.error_occurred.connect(_on_error_occurred)
	GameManager.backpack_updated.connect(_on_backpack_updated)
	GameManager.tool_selected.connect(_on_tool_selected)
	GameManager.game_over_triggered.connect(_on_game_over)
	GameManager.level_completed.connect(_on_level_won)
	
	_update_backpack_ui([])
	_update_tools_ui(0)
	_create_cinematic_overlay()
	
	# Conectar botones de la barra de herramientas al hacer clic con el mouse
	for i in range(tools_bar.get_child_count()):
		var btn = tools_bar.get_child(i) as Button
		if btn:
			var t_id = i + 1
			btn.pressed.connect(func(): GameManager.select_tool(t_id))

func _create_cinematic_overlay() -> void:
	if cinematic_overlay:
		return
	cinematic_overlay = Control.new()
	cinematic_overlay.name = "CinematicOverlay"
	cinematic_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	cinematic_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cinematic_overlay.visible = false
	add_child(cinematic_overlay)
	
	# Barra superior estilo panorámico de cine cyberpunk
	top_cinematic_bar = ColorRect.new()
	top_cinematic_bar.color = Color(0.04, 0.02, 0.09, 0.95)
	top_cinematic_bar.anchor_right = 1.0
	top_cinematic_bar.offset_bottom = 54.0
	cinematic_overlay.add_child(top_cinematic_bar)
	
	var top_line = ColorRect.new()
	top_line.color = Color(0.0, 0.9, 1.0, 0.8)
	top_line.anchor_right = 1.0
	top_line.anchor_top = 1.0
	top_line.anchor_bottom = 1.0
	top_line.offset_top = -2.0
	top_cinematic_bar.add_child(top_line)
	
	var top_lbl = Label.new()
	top_lbl.text = "// PROTOCOLO DE TALLER // SINCRONIZANDO TÉCNICO //"
	top_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_lbl.modulate = Color(0.0, 0.95, 1.0, 1.0)
	top_cinematic_bar.add_child(top_lbl)
	
	# Barra inferior con aviso para saltar
	bottom_cinematic_bar = ColorRect.new()
	bottom_cinematic_bar.color = Color(0.04, 0.02, 0.09, 0.95)
	bottom_cinematic_bar.anchor_top = 1.0
	bottom_cinematic_bar.anchor_right = 1.0
	bottom_cinematic_bar.anchor_bottom = 1.0
	bottom_cinematic_bar.offset_top = -54.0
	cinematic_overlay.add_child(bottom_cinematic_bar)
	
	var bot_line = ColorRect.new()
	bot_line.color = Color(1.0, 0.1, 0.5, 0.8)
	bot_line.anchor_right = 1.0
	bot_line.offset_bottom = 2.0
	bottom_cinematic_bar.add_child(bot_line)
	
	var bot_lbl = Label.new()
	bot_lbl.text = "[ESPACIO / CLIC] PARA SALTAR INTRO"
	bot_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	bot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bot_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bot_lbl.modulate = Color(0.85, 0.85, 0.95, 0.85)
	bottom_cinematic_bar.add_child(bot_lbl)
	
	# Destello óptico (visera cibernética)
	optic_flash_rect = ColorRect.new()
	optic_flash_rect.color = Color(0.0, 0.85, 1.0, 0.0)
	optic_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	optic_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cinematic_overlay.add_child(optic_flash_rect)
	
	# Texto de inicio óptico
	optic_text_label = Label.new()
	optic_text_label.text = "[ SISTEMA ÓPTICO SINCRONIZADO // VISOR EN LÍNEA ]"
	optic_text_label.set_anchors_preset(Control.PRESET_CENTER)
	optic_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	optic_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	optic_text_label.modulate = Color(0.0, 1.0, 0.8, 0.0)
	cinematic_overlay.add_child(optic_text_label)

func setup_cinematic_mode() -> void:
	_create_cinematic_overlay()
	is_cinematic_active = true
	cinematic_overlay.visible = true
	
	# Ocultar temporalmente los paneles de juego hasta entrar en 1ra persona
	for panel_name in ["TopLeft", "TopCenter", "BottomLeft", "TopRight", "Center", "BottomCenter"]:
		var p = get_node_or_null(panel_name) as Control
		if p:
			p.modulate.a = 0.0
			
	top_cinematic_bar.modulate.a = 0.0
	bottom_cinematic_bar.modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(top_cinematic_bar, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(bottom_cinematic_bar, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_CUBIC)

func play_optic_boot_transition(callback: Callable = Callable()) -> void:
	if not cinematic_overlay:
		return
	var tw = create_tween()
	# Destello cian óptico sutil
	tw.tween_property(optic_flash_rect, "color:a", 0.45, 0.12).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(optic_text_label, "modulate:a", 1.0, 0.12)
	tw.tween_property(optic_flash_rect, "color:a", 0.0, 0.28).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(optic_text_label, "modulate:a", 0.0, 0.5)
	
	# Desvanecer barras panorámicas hacia fuera
	tw.parallel().tween_property(top_cinematic_bar, "modulate:a", 0.0, 0.35)
	tw.parallel().tween_property(bottom_cinematic_bar, "modulate:a", 0.0, 0.35)
	
	# Desvanecer y mostrar paneles HUD de gameplay
	for panel_name in ["TopLeft", "TopCenter", "BottomLeft", "TopRight", "Center", "BottomCenter"]:
		var p = get_node_or_null(panel_name) as Control
		if p:
			tw.parallel().tween_property(p, "modulate:a", 1.0, 0.4)
			
	tw.chain().tween_callback(func():
		is_cinematic_active = false
		if cinematic_overlay:
			cinematic_overlay.visible = false
		if callback.is_valid():
			callback.call()
	)

func skip_cinematic() -> void:
	is_cinematic_active = false
	if cinematic_overlay:
		cinematic_overlay.visible = false
	for panel_name in ["TopLeft", "TopCenter", "BottomLeft", "TopRight", "Center", "BottomCenter"]:
		var p = get_node_or_null(panel_name) as Control
		if p:
			p.modulate.a = 1.0

func set_interaction_prompt(text: String) -> void:
	prompt_label.text = text

func _on_score_updated(new_score: int, delta: int) -> void:
	lbl_puntaje.text = "Puntaje: %d" % new_score
	if delta > 0:
		_spawn_floating_text("+%d PTS  +10s" % delta, true)

func _on_time_updated(t: float, _delta: float) -> void:
	var mins = int(t) / 60
	var secs = int(t) % 60
	lbl_tiempo.text = "Tiempo: %02d:%02d" % [mins, secs]
	if t < 20.0:
		lbl_tiempo.modulate = Color(1, 0.2, 0.2, 1) # Parpadeo rojo en últimos segundos
	else:
		lbl_tiempo.modulate = Color(1, 1, 1, 1)

func _on_error_occurred(new_errors: int, delta: int) -> void:
	lbl_errores.text = "Errores: %d / 20" % new_errors
	if delta > 0:
		_spawn_floating_text("-5s  +1 ERROR", false)

func _on_backpack_updated(items: Array) -> void:
	_update_backpack_ui(items)

func _update_backpack_ui(items: Array) -> void:
	# Limpiar slots viejos
	for child in backpack_container.get_children():
		if child.name != "TituloMochila":
			child.queue_free()
	
	if items.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "[ Vacía - 0/3 ]"
		empty_lbl.modulate = Color(0.6, 0.6, 0.6, 0.8)
		backpack_container.add_child(empty_lbl)
	else:
		for i in range(items.size()):
			var item = items[i]
			var btn = Button.new()
			var estado = "(Dañada)" if item.get("broken", false) else "(Nueva)"
			btn.text = "%d. %s %s" % [i + 1, item.get("name", "Pieza"), estado]
			if item.get("broken", false):
				btn.modulate = Color(1, 0.4, 0.4, 1)
			else:
				btn.modulate = Color(0.4, 1, 0.6, 1)
			btn.pressed.connect(func(): GameManager.selected_backpack_index = i)
			backpack_container.add_child(btn)

func _on_tool_selected(tool_id: int) -> void:
	_update_tools_ui(tool_id)

func _update_tools_ui(active_tool: int) -> void:
	for i in range(tools_bar.get_child_count()):
		var btn = tools_bar.get_child(i) as Button
		if btn:
			var id = i + 1
			if id == active_tool:
				btn.modulate = Color(0, 1, 0.8, 1) # Seleccionada
			else:
				btn.modulate = Color(0.7, 0.7, 0.7, 0.7)

func _spawn_floating_text(text: String, is_positive: bool) -> void:
	var label = Label.new()
	label.text = text
	label.top_level = true
	var center = get_viewport_rect().size * 0.5
	
	if is_positive:
		# Flotando a la derecha
		label.position = center + Vector2(40, -20)
		label.modulate = Color(0, 1, 0.8, 1)
	else:
		# Flotando a la izquierda en rojo
		label.position = center + Vector2(-160, -20)
		label.modulate = Color(1, 0.1, 0.2, 1)
	
	label.theme = theme
	floating_feedback_container.add_child(label)
	
	var tween = create_tween()
	var target_pos = label.position + Vector2(0, -50)
	tween.tween_property(label, "position", target_pos, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.9)
	tween.tween_callback(label.queue_free)

func _on_game_over(reason: String) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game_over_panel.visible = true
	var reason_lbl = game_over_panel.get_node_or_null("VBox/ReasonLabel") as Label
	if reason_lbl:
		reason_lbl.text = reason

func _on_level_won(stars: int, final_score: int) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	win_panel.visible = true
	var stars_lbl = win_panel.get_node_or_null("VBox/StarsLabel") as Label
	var score_lbl = win_panel.get_node_or_null("VBox/ScoreLabel") as Label
	if stars_lbl:
		var stars_str = ""
		for i in range(stars):
			stars_str += "★ "
		for i in range(3 - stars):
			stars_str += "☆ "
		stars_lbl.text = stars_str
	if score_lbl:
		score_lbl.text = "Puntaje Final: %d" % final_score
