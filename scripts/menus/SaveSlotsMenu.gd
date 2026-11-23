class_name SaveSlotsMenu
extends Control

# =============================================================================
# MENÚ DE PARTIDAS (SISTEMA DE 5 SLOTS / SETS DE GUARDADO)
# =============================================================================

@onready var title_label: Label = $Margin/VBox/Header/Title
@onready var subtitle_label: Label = $Margin/VBox/Header/Subtitle
@onready var slots_container: VBoxContainer = $Margin/VBox/SlotsContainer

# Panel Inferior de Detalles
@onready var detail_panel: PanelContainer = $Margin/VBox/DetailPanel
@onready var circular_progress: Control = $Margin/VBox/DetailPanel/Margin/HBox/CircleCol/CircularProgress
@onready var lbl_tools_count: Label = $Margin/VBox/DetailPanel/Margin/HBox/ToolsAndMedalsCol/ToolsBox/Header/LblToolsCount
@onready var tools_grid: HBoxContainer = $Margin/VBox/DetailPanel/Margin/HBox/ToolsAndMedalsCol/ToolsBox/ToolsGrid
@onready var lbl_medals_count: Label = $Margin/VBox/DetailPanel/Margin/HBox/ToolsAndMedalsCol/MedalsBox/Header/LblMedalsCount
@onready var medals_grid: HBoxContainer = $Margin/VBox/DetailPanel/Margin/HBox/ToolsAndMedalsCol/MedalsBox/MedalsGrid

@onready var lbl_score_val: Label = $Margin/VBox/DetailPanel/Margin/HBox/StatsCol/StatsGrid/LblScoreVal
@onready var lbl_stars_val: Label = $Margin/VBox/DetailPanel/Margin/HBox/StatsCol/StatsGrid/LblStarsVal
@onready var lbl_tutorials_val: Label = $Margin/VBox/DetailPanel/Margin/HBox/StatsCol/StatsGrid/LblTutorialsVal
@onready var lbl_levels_val: Label = $Margin/VBox/DetailPanel/Margin/HBox/StatsCol/StatsGrid/LblLevelsVal
@onready var lbl_practice_val: Label = $Margin/VBox/DetailPanel/Margin/HBox/StatsCol/StatsGrid/LblPracticeVal
@onready var lbl_secrets_val: Label = $Margin/VBox/DetailPanel/Margin/HBox/StatsCol/StatsGrid/LblSecretsVal
@onready var lbl_characters_val: Label = $Margin/VBox/DetailPanel/Margin/HBox/StatsCol/StatsGrid/LblCharactersVal

# Footer
@onready var btn_volver: Button = $Margin/VBox/Footer/BtnVolver
@onready var prompt_hint: Label = $Margin/VBox/Footer/PromptHint
@onready var btn_entrar: Button = $Margin/VBox/Footer/BtnEntrar
@onready var btn_borrar: Button = $Margin/VBox/Footer/BtnBorrar

var current_selected_index: int = 1
var row_buttons: Array[Button] = []
var is_transitioning: bool = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_setup_slots_ui()
	_select_slot(1, false)

	btn_volver.pressed.connect(_on_volver_pressed)
	btn_entrar.pressed.connect(_on_entrar_pressed)
	btn_borrar.pressed.connect(_on_borrar_pressed)

	if has_node("/root/LocalizationManager"):
		get_node("/root/LocalizationManager").locale_changed.connect(func(_loc: String):
			_on_locale_changed()
		)
	_on_locale_changed()

func _unhandled_input(event: InputEvent) -> void:
	if is_transitioning:
		return

	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		_on_volver_pressed()
	elif event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER)):
		get_viewport().set_input_as_handled()
		_on_entrar_pressed()
	elif event.is_action_pressed("ui_up") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_UP or event.keycode == KEY_W)):
		get_viewport().set_input_as_handled()
		var prev_idx = current_selected_index - 1
		if prev_idx < 1:
			prev_idx = SaveManager.TOTAL_SLOTS
		_select_slot(prev_idx, true)
	elif event.is_action_pressed("ui_down") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_DOWN or event.keycode == KEY_S)):
		get_viewport().set_input_as_handled()
		var next_idx = current_selected_index + 1
		if next_idx > SaveManager.TOTAL_SLOTS:
			next_idx = 1
		_select_slot(next_idx, true)

func _setup_slots_ui() -> void:
	row_buttons.clear()
	for child in slots_container.get_children():
		child.queue_free()

	for slot_idx in range(1, SaveManager.TOTAL_SLOTS + 1):
		var slot_data = SaveManager.get_slot(slot_idx)
		var row_btn = _create_slot_row_button(slot_idx, slot_data)
		slots_container.add_child(row_btn)
		row_buttons.append(row_btn)

func _create_slot_row_button(slot_idx: int, data: Dictionary) -> Button:
	var btn = Button.new()
	btn.name = "SlotRow_%d" % slot_idx
	btn.custom_minimum_size = Vector2(0, 52)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.focus_mode = Control.FOCUS_ALL

	var hbox = HBoxContainer.new()
	hbox.name = "HBox"
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 14)
	btn.add_child(hbox)

	var margin_left = Control.new()
	margin_left.custom_minimum_size = Vector2(10, 0)
	hbox.add_child(margin_left)

	# Etiqueta de Ranura (SET 01, etc.)
	var loc = get_node_or_null("/root/LocalizationManager")
	var set_word = loc.translate_text("SET") if loc else "SET"
	var lbl_badge = Label.new()
	lbl_badge.name = "Badge"
	lbl_badge.text = "%s %02d" % [set_word, slot_idx]
	lbl_badge.add_theme_font_size_override("font_size", 14)
	lbl_badge.add_theme_color_override("font_color", Color(0.0, 0.95, 1.0))
	lbl_badge.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lbl_badge.add_theme_constant_override("outline_size", 4)
	if ResourceLoader.exists("res://assets/fonts/Bungee-Regular.ttf"):
		lbl_badge.add_theme_font_override("font", load("res://assets/fonts/Bungee-Regular.ttf"))
	hbox.add_child(lbl_badge)

	# Línea separadora vertical sutil
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(2, 28)
	sep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sep.color = Color(0.2, 0.5, 0.8, 0.4)
	hbox.add_child(sep)

	# Info principal del Set
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(info_vbox)

	var lbl_title = Label.new()
	lbl_title.name = "Title"
	var is_empty = data.get("is_empty", true)
	if is_empty:
		lbl_title.text = loc.translate_text("[ RANURA VACÍA - PARTIDA NUEVA ]") if loc else "[ RANURA VACÍA - PARTIDA NUEVA ]"
	else:
		var raw_name = str(data.get("slot_name", ""))
		if raw_name.begins_with("Partida ") or raw_name == "":
			var p_word = loc.translate_text("Partida") if loc else "Partida"
			lbl_title.text = "%s %d" % [p_word, slot_idx]
		else:
			lbl_title.text = raw_name
	lbl_title.add_theme_font_size_override("font_size", 13)
	lbl_title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0) if not is_empty else Color(0.65, 0.65, 0.75))
	info_vbox.add_child(lbl_title)

	var lbl_sub = Label.new()
	lbl_sub.name = "Sub"
	var last_sess_word = loc.translate_text("Última sesión:") if loc else "Última sesión:"
	lbl_sub.text = "%s %s" % [last_sess_word, str(data.get("last_played", "--/--/----"))]
	lbl_sub.add_theme_font_size_override("font_size", 10)
	lbl_sub.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 0.8))
	info_vbox.add_child(lbl_sub)

	# Estadísticas compactas en el extremo derecho
	var stats_hbox = HBoxContainer.new()
	stats_hbox.name = "StatsHBox"
	stats_hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stats_hbox.add_theme_constant_override("separation", 16)
	hbox.add_child(stats_hbox)

	var pts_word = loc.translate_text("PTS") if loc else "PTS"
	var lbl_pts = Label.new()
	lbl_pts.text = "%d %s" % [int(data.get("score", 0)), pts_word]
	lbl_pts.add_theme_font_size_override("font_size", 12)
	lbl_pts.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	stats_hbox.add_child(lbl_pts)

	var lbl_str = Label.new()
	lbl_str.text = "★ %d" % int(data.get("stars", 0))
	lbl_str.add_theme_font_size_override("font_size", 12)
	lbl_str.add_theme_color_override("font_color", Color(0.1, 1.0, 0.5))
	stats_hbox.add_child(lbl_str)

	var lbl_pct = Label.new()
	lbl_pct.text = "%d%%" % int(round(data.get("completion_percentage", 0.0)))
	lbl_pct.add_theme_font_size_override("font_size", 13)
	lbl_pct.add_theme_color_override("font_color", Color(0.0, 0.95, 1.0))
	stats_hbox.add_child(lbl_pct)

	var margin_right = Control.new()
	margin_right.custom_minimum_size = Vector2(12, 0)
	hbox.add_child(margin_right)

	# Conexión de clic
	btn.pressed.connect(func():
		if current_selected_index == slot_idx:
			_on_entrar_pressed()
		else:
			_select_slot(slot_idx, true)
	)

	return btn

func _select_slot(slot_idx: int, animate_selection: bool = true) -> void:
	current_selected_index = slot_idx

	# Actualizar estilos visuales de las 5 filas
	for i in range(row_buttons.size()):
		var b = row_buttons[i]
		var idx = i + 1
		var is_selected = (idx == current_selected_index)

		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		style.border_width_left = 3
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1

		if is_selected:
			style.bg_color = Color(0.12, 0.04, 0.26, 0.92)
			style.border_color = Color(0.0, 0.95, 1.0, 1.0)
			style.border_width_left = 5
			style.shadow_color = Color(0.0, 0.95, 1.0, 0.4)
			style.shadow_size = 4
		else:
			style.bg_color = Color(0.05, 0.02, 0.12, 0.8)
			style.border_color = Color(0.2, 0.1, 0.35, 0.6)
			style.border_width_left = 2
			style.shadow_size = 0

		b.add_theme_stylebox_override("normal", style)
		b.add_theme_stylebox_override("hover", style)
		b.add_theme_stylebox_override("pressed", style)
		b.add_theme_stylebox_override("focus", style)

	# Actualizar datos del panel de objetos desbloqueados y porcentaje
	var data = SaveManager.get_slot(current_selected_index)
	_update_details_panel(data, animate_selection)

	# Actualizar texto del botón Entrar
	var loc = get_node_or_null("/root/LocalizationManager")
	var is_empty = data.get("is_empty", true)
	if is_empty:
		btn_entrar.text = loc.translate_text("▶ PARTIDA NUEVA (ENTER)") if loc else "▶ PARTIDA NUEVA (ENTER)"
		btn_borrar.visible = false
	else:
		btn_entrar.text = loc.translate_text("▶ ENTRAR A LA PARTIDA (ENTER)") if loc else "▶ ENTRAR A LA PARTIDA (ENTER)"
		btn_borrar.visible = true

func _update_details_panel(data: Dictionary, animate: bool) -> void:
	var loc = get_node_or_null("/root/LocalizationManager")
	# 1. Círculo de porcentaje
	var pct = data.get("completion_percentage", 0.0)
	circular_progress.set_progress(pct, animate)

	# 2. Herramientas (5 en total)
	var tools = data.get("tools", [])
	var unlocked_tools_count = 0
	for t in tools:
		if t.get("unlocked", false):
			unlocked_tools_count += 1
	var des_word = loc.translate_text("DESBLOQUEADAS") if loc else "DESBLOQUEADAS"
	lbl_tools_count.text = "%d / 5 %s" % [unlocked_tools_count, des_word]

	for child in tools_grid.get_children():
		child.queue_free()

	for t in tools:
		var badge = _create_tool_badge(t)
		tools_grid.add_child(badge)

	# 3. Medallas de los 3 modos
	var medals = data.get("medals", {})
	var unlocked_medals_count = 0
	for m_key in ["reparacion", "sistema", "servidor"]:
		if medals.get(m_key, false):
			unlocked_medals_count += 1
	var obt_word = loc.translate_text("OBTENIDAS") if loc else "OBTENIDAS"
	lbl_medals_count.text = "%d / 3 %s" % [unlocked_medals_count, obt_word]

	for child in medals_grid.get_children():
		child.queue_free()

	var medal_definitions = [
		{"key": "reparacion", "name": "Reparación", "icon": "🔧"},
		{"key": "sistema", "name": "Sistema", "icon": "💻"},
		{"key": "servidor", "name": "Servidor", "icon": "🖧"}
	]
	for m_def in medal_definitions:
		var has_it = medals.get(m_def["key"], false)
		var m_badge = _create_medal_badge(m_def["name"], m_def["icon"], has_it)
		medals_grid.add_child(m_badge)

	# 4. Estadísticas numéricas
	var pts_suffix = loc.translate_text("PTS") if loc else "PTS"
	lbl_score_val.text = "%d %s" % [int(data.get("score", 0)), pts_suffix]
	lbl_stars_val.text = "%d ★" % int(data.get("stars", 0))
	lbl_tutorials_val.text = "%d / %d" % [int(data.get("tutorials_completed", 0)), int(data.get("tutorials_total", 4))]
	lbl_levels_val.text = "%d / %d" % [int(data.get("levels_completed", 0)), int(data.get("levels_total", 36))]
	lbl_practice_val.text = "%d / %d" % [int(data.get("practice_completed", 0)), int(data.get("practice_total", 3))]
	lbl_secrets_val.text = "%d / %d" % [int(data.get("secrets_unlocked", 0)), int(data.get("secrets_total", 3))]
	lbl_characters_val.text = "%d / %d" % [int(data.get("characters_unlocked", 0)), int(data.get("characters_total", 3))]

func _create_tool_badge(tool_data: Dictionary) -> PanelContainer:
	var p = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1

	var is_unlocked = tool_data.get("unlocked", false)
	if is_unlocked:
		style.bg_color = Color(0.04, 0.18, 0.28, 0.9)
		style.border_color = Color(0.0, 0.95, 1.0, 0.8)
	else:
		style.bg_color = Color(0.08, 0.04, 0.12, 0.6)
		style.border_color = Color(0.3, 0.2, 0.4, 0.5)

	p.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	p.add_child(margin)

	var loc = get_node_or_null("/root/LocalizationManager")
	var raw_name = tool_data.get("name", "Herramienta")
	var t_name = loc.translate_text(raw_name) if loc else raw_name
	var lbl = Label.new()
	var check = "✓" if is_unlocked else "🔒"
	lbl.text = "%s %s" % [check, t_name]
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.85, 1.0, 1.0) if is_unlocked else Color(0.55, 0.5, 0.65))
	margin.add_child(lbl)

	return p

func _create_medal_badge(m_name: String, icon: String, is_unlocked: bool) -> PanelContainer:
	var p = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1

	if is_unlocked:
		style.bg_color = Color(0.24, 0.15, 0.02, 0.9)
		style.border_color = Color(1.0, 0.85, 0.2, 0.9)
	else:
		style.bg_color = Color(0.08, 0.04, 0.12, 0.6)
		style.border_color = Color(0.3, 0.2, 0.4, 0.5)

	p.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	p.add_child(margin)

	var loc = get_node_or_null("/root/LocalizationManager")
	var tr_name = loc.translate_text(m_name) if loc else m_name
	var lbl = Label.new()
	var mark = "★" if is_unlocked else "🔒"
	lbl.text = "%s %s %s" % [icon, tr_name, mark]
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4) if is_unlocked else Color(0.55, 0.5, 0.65))
	margin.add_child(lbl)

	return p

func _on_entrar_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true

	var old_glitch = get_tree().root.get_node_or_null("GlitchAudioPlayer")
	if old_glitch:
		old_glitch.queue_free()

	# Aplicar el slot seleccionado
	SaveManager.select_and_apply_slot(current_selected_index)

	# Transición clásica cibernética de entrada a partida
	CyberPlayTransition.play(
		get_tree(),
		"res://scenes/menus/LevelSelect.tscn",
		"ACCEDIENDO AL SISTEMA",
		"// CARGANDO SET DE PARTIDA %02d //" % current_selected_index
	)

func _on_borrar_pressed() -> void:
	SaveManager.reset_slot(current_selected_index)
	_setup_slots_ui()
	_select_slot(current_selected_index, true)

func _on_volver_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	var old_glitch = get_tree().root.get_node_or_null("GlitchAudioPlayer")
	if old_glitch:
		old_glitch.queue_free()
	CyberPlayTransition.play_code_restored(
		get_tree(),
		"res://scenes/menus/MainMenu.tscn"
	)

func _on_locale_changed() -> void:
	if not has_node("/root/LocalizationManager"):
		return
	var loc = get_node("/root/LocalizationManager")
	if title_label:
		title_label.text = loc.translate_text("PARTIDAS")
	if subtitle_label:
		subtitle_label.text = loc.translate_text("Selecciona un set de guardado para continuar o iniciar tu trayectoria técnica")
	var badge_hdr = get_node_or_null("Margin/VBox/Header/Badge")
	if badge_hdr:
		badge_hdr.text = loc.translate_text("[ SISTEMA // GESTOR DE ALMACENAMIENTO ]")
	if btn_volver:
		btn_volver.text = loc.translate_text("◀ VOLVER")
	if prompt_hint:
		prompt_hint.text = loc.translate_text("[ ENTER ] o [ CLIC ] para entrar en ese set de partida")
	if btn_borrar:
		btn_borrar.text = loc.translate_text("🗑️ REINICIAR SET")

	var t_title = get_node_or_null("Margin/VBox/DetailPanel/Margin/HBox/ToolsAndMedalsCol/ToolsBox/Header/Title")
	if t_title:
		t_title.text = loc.translate_text("🛠️ HERRAMIENTAS DESBLOQUEADAS:")
	var m_title = get_node_or_null("Margin/VBox/DetailPanel/Margin/HBox/ToolsAndMedalsCol/MedalsBox/Header/Title")
	if m_title:
		m_title.text = loc.translate_text("🎖️ MEDALLAS DE DIVISIÓN (3 MODOS):")
	var s_title = get_node_or_null("Margin/VBox/DetailPanel/Margin/HBox/StatsCol/Header/Title")
	if s_title:
		s_title.text = loc.translate_text("📊 REGISTRO DE AVANCE:")

	var stat_nodes = {
		"Margin/VBox/DetailPanel/Margin/HBox/StatsCol/StatsGrid/LblScore": "🪙 Puntos:",
		"Margin/VBox/DetailPanel/Margin/HBox/StatsCol/StatsGrid/LblStars": "⭐ Estrellas:",
		"Margin/VBox/DetailPanel/Margin/HBox/StatsCol/StatsGrid/LblTutorials": "📚 Tutoriales:",
		"Margin/VBox/DetailPanel/Margin/HBox/StatsCol/StatsGrid/LblLevels": "🏆 Niveles:",
		"Margin/VBox/DetailPanel/Margin/HBox/StatsCol/StatsGrid/LblPractice": "🔧 Prácticas:",
		"Margin/VBox/DetailPanel/Margin/HBox/StatsCol/StatsGrid/LblSecrets": "👾 Secretos:",
		"Margin/VBox/DetailPanel/Margin/HBox/StatsCol/StatsGrid/LblCharacters": "👤 Personajes:"
	}
	for path in stat_nodes:
		var node = get_node_or_null(path)
		if node:
			node.text = loc.translate_text(stat_nodes[path])

	# Refrescar filas y detalle con el nuevo idioma
	_setup_slots_ui()
	_select_slot(current_selected_index, false)
