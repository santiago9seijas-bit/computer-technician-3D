extends Control

@onready var top_left_container: Control = $TopLeft
@onready var lbl_errores: Label = $TopLeft/LblErrores
@onready var lbl_tiempo: Label = $TopCenter/LblTiempo
@onready var lbl_puntaje: Label = $BottomLeft/LblPuntaje
@onready var top_right_panel: PanelContainer = $TopRight
@onready var backpack_container: VBoxContainer = $TopRight/BackpackContainer
@onready var falla_solucionada_hud: Label = $FallaSolucionadaHUD
@onready var prompt_label: Label = $Center/PromptLabel
@onready var stamina_bar: Control = $Center/CurvedStaminaBar
@onready var bottom_center_panel: PanelContainer = $BottomCenter
@onready var tools_bar: HBoxContainer = $BottomCenter/ToolsBar
@onready var floating_feedback_container: Control = $FloatingFeedback
@onready var game_over_dim: ColorRect = get_node_or_null("GameOverDim")
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var win_panel: PanelContainer = $WinPanel

var cinematic_overlay: Control = null
var top_cinematic_bar: ColorRect = null
var bottom_cinematic_bar: ColorRect = null
var optic_flash_rect: ColorRect = null
var optic_text_label: Label = null
var is_cinematic_active: bool = false
var is_infinite_time: bool = false

# Animación y estado deslizante de la mochila
var _tw_backpack: Tween = null
var _backpack_is_shown: bool = false
const BACKPACK_RESTING_LEFT: float = -260.0
const BACKPACK_RESTING_RIGHT: float = -30.0
const BACKPACK_HIDDEN_LEFT: float = 30.0
const BACKPACK_HIDDEN_RIGHT: float = 260.0

# Animación de ocultamiento/aparición al abrir modales (PC y Pedidos)
var _modal_hud_tween: Tween = null
var _orig_top_left_y: float = 20.0
var _orig_bottom_left_y: float = -74.0
var _orig_bottom_center_y: float = -128.0
var _positions_cached: bool = false

func set_infinite_time(enabled: bool = true) -> void:
	is_infinite_time = enabled
	if is_infinite_time and lbl_tiempo:
		var txt = "Tiempo: Infinito"
		if has_node("/root/LocalizationManager"):
			txt = get_node("/root/LocalizationManager").translate_text(txt)
		lbl_tiempo.text = txt
		lbl_tiempo.modulate = Color(0, 0.9, 1, 1)

func _ready() -> void:
	set_process(false) # Optimización: no ejecutar _process en cada frame innecesariamente
	if game_over_dim:
		game_over_dim.visible = false
	game_over_panel.visible = false
	win_panel.visible = false
	prompt_label.text = ""
	
	# Asegurar que todos los elementos clave del HUD estén completamente visibles
	ensure_hud_visible()
	
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.score_updated.connect(_on_score_updated)
		gm.time_updated.connect(_on_time_updated)
		gm.error_occurred.connect(_on_error_occurred)
		gm.backpack_updated.connect(_on_backpack_updated)
		gm.tool_selected.connect(_on_tool_selected)
		gm.game_over_triggered.connect(_on_game_over)
		gm.level_completed.connect(_on_level_won)
		if gm.has_signal("hardware_monitor_changed"):
			gm.hardware_monitor_changed.connect(_on_hardware_monitor_changed)
			if gm.has_method("is_hardware_monitor_enabled"):
				_on_hardware_monitor_changed(gm.is_hardware_monitor_enabled())
		if "score" in gm:
			_on_score_updated(gm.score, 0)
		if "errors" in gm:
			_on_error_occurred(gm.errors, 0)
	
	var init_items: Array = gm.backpack if gm and "backpack" in gm else []
	_update_backpack_ui(init_items, false)
	_update_tools_ui(0)
	_create_cinematic_overlay()
	
	# Conectar botones de la barra de herramientas al hacer clic con el mouse
	for i in range(tools_bar.get_child_count()):
		var btn = tools_bar.get_child(i) as Button
		if btn:
			var t_id = i + 1
			btn.pressed.connect(func():
				var g = get_node_or_null("/root/GameManager")
				if g and g.has_method("select_tool"):
					g.select_tool(t_id)
			)

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
		ensure_hud_visible()
		if callback.is_valid():
			callback.call()
	)

func skip_cinematic() -> void:
	is_cinematic_active = false
	if cinematic_overlay:
		cinematic_overlay.visible = false
	ensure_hud_visible()

func _cache_hud_positions() -> void:
	if _positions_cached:
		return
	_positions_cached = true
	if top_left_container:
		_orig_top_left_y = top_left_container.offset_top
	var bl = get_node_or_null("BottomLeft") as Control
	if bl:
		_orig_bottom_left_y = bl.offset_top
	if bottom_center_panel:
		_orig_bottom_center_y = bottom_center_panel.offset_top

func hide_gameplay_hud_for_modal(animated: bool = true) -> void:
	_cache_hud_positions()
	if _modal_hud_tween and _modal_hud_tween.is_valid():
		_modal_hud_tween.kill()

	var panels_to_hide: Array[Control] = []
	if top_left_container: panels_to_hide.append(top_left_container)
	var bl = get_node_or_null("BottomLeft") as Control
	if bl: panels_to_hide.append(bl)
	if bottom_center_panel: panels_to_hide.append(bottom_center_panel)
	var center = get_node_or_null("Center") as Control
	if center: panels_to_hide.append(center)
	var tr = get_node_or_null("TopRight") as Control
	if tr: panels_to_hide.append(tr)

	# Asegurar que el contador de tiempo del nivel (TopCenter) permanezca 100% visible
	if lbl_tiempo and lbl_tiempo.get_parent():
		var tc = lbl_tiempo.get_parent() as Control
		tc.visible = true
		tc.modulate.a = 1.0

	if not animated:
		for p in panels_to_hide:
			p.modulate.a = 0.0
			p.visible = false
		return

	_modal_hud_tween = create_tween().set_parallel(true)
	for p in panels_to_hide:
		_modal_hud_tween.tween_property(p, "modulate:a", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if top_left_container:
		_modal_hud_tween.tween_property(top_left_container, "offset_top", _orig_top_left_y - 18.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if bl:
		_modal_hud_tween.tween_property(bl, "offset_top", _orig_bottom_left_y + 18.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if bottom_center_panel:
		_modal_hud_tween.tween_property(bottom_center_panel, "offset_top", _orig_bottom_center_y + 24.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_modal_hud_tween.chain().tween_callback(func():
		for p in panels_to_hide:
			p.visible = false
	)

func show_gameplay_hud_from_modal(animated: bool = true) -> void:
	_cache_hud_positions()
	if _modal_hud_tween and _modal_hud_tween.is_valid():
		_modal_hud_tween.kill()

	var panels_to_show: Array[Control] = []
	if top_left_container: panels_to_show.append(top_left_container)
	var bl = get_node_or_null("BottomLeft") as Control
	if bl: panels_to_show.append(bl)
	if bottom_center_panel: panels_to_show.append(bottom_center_panel)
	var center = get_node_or_null("Center") as Control
	if center: panels_to_show.append(center)

	# Asegurar que el contador de tiempo continúe 100% visible
	if lbl_tiempo and lbl_tiempo.get_parent():
		var tc = lbl_tiempo.get_parent() as Control
		tc.visible = true
		tc.modulate.a = 1.0

	for p in panels_to_show:
		p.visible = true

	if not animated:
		for p in panels_to_show:
			p.modulate.a = 1.0
		if top_left_container: top_left_container.offset_top = _orig_top_left_y
		if bl: bl.offset_top = _orig_bottom_left_y
		if bottom_center_panel: bottom_center_panel.offset_top = _orig_bottom_center_y
		return

	# Iniciar desde transparente y animar suavemente hacia adentro
	for p in panels_to_show:
		p.modulate.a = 0.0

	_modal_hud_tween = create_tween().set_parallel(true)
	for p in panels_to_show:
		_modal_hud_tween.tween_property(p, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	if top_left_container:
		top_left_container.offset_top = _orig_top_left_y - 18.0
		_modal_hud_tween.tween_property(top_left_container, "offset_top", _orig_top_left_y, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if bl:
		bl.offset_top = _orig_bottom_left_y + 18.0
		_modal_hud_tween.tween_property(bl, "offset_top", _orig_bottom_left_y, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if bottom_center_panel:
		bottom_center_panel.offset_top = _orig_bottom_center_y + 24.0
		_modal_hud_tween.tween_property(bottom_center_panel, "offset_top", _orig_bottom_center_y, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func ensure_hud_visible() -> void:
	_cache_hud_positions()
	is_cinematic_active = false
	if cinematic_overlay:
		cinematic_overlay.visible = false
	for panel_name in ["TopLeft", "TopCenter", "BottomLeft", "TopRight", "Center", "BottomCenter"]:
		var p = get_node_or_null(panel_name) as Control
		if p:
			p.modulate.a = 1.0
			p.visible = true
	if top_left_container:
		top_left_container.offset_top = _orig_top_left_y
	var bl = get_node_or_null("BottomLeft") as Control
	if bl:
		bl.offset_top = _orig_bottom_left_y
	if bottom_center_panel:
		bottom_center_panel.visible = true
		bottom_center_panel.modulate.a = 1.0
		bottom_center_panel.offset_top = _orig_bottom_center_y
	if tools_bar:
		tools_bar.visible = true
		for i in range(tools_bar.get_child_count()):
			var btn = tools_bar.get_child(i) as Control
			if btn:
				btn.visible = true

var _last_prompt: String = ""
var _last_displayed_second: int = -1

func set_interaction_prompt(text: String) -> void:
	if text == _last_prompt:
		return
	_last_prompt = text
	prompt_label.text = text

func _on_score_updated(new_score: int, _delta: int) -> void:
	var prefix = "Puntaje:"
	if has_node("/root/LocalizationManager"):
		prefix = get_node("/root/LocalizationManager").translate_text(prefix)
	lbl_puntaje.text = "%s %d" % [prefix, new_score]

func _on_time_updated(t: float, _delta: float) -> void:
	if is_infinite_time:
		var txt = "Tiempo: Infinito"
		if has_node("/root/LocalizationManager"):
			txt = get_node("/root/LocalizationManager").translate_text(txt)
		lbl_tiempo.text = txt
		lbl_tiempo.modulate = Color(0, 0.9, 1, 1)
		return
	var total_sec := int(t)
	if total_sec == _last_displayed_second:
		return
	_last_displayed_second = total_sec
	var mins = total_sec / 60
	var secs = total_sec % 60
	var prefix = "Tiempo:"
	if has_node("/root/LocalizationManager"):
		prefix = get_node("/root/LocalizationManager").translate_text(prefix)
	lbl_tiempo.text = "%s %02d:%02d" % [prefix, mins, secs]
	if t < 20.0:
		lbl_tiempo.modulate = Color(1, 0.2, 0.2, 1) # Parpadeo rojo en últimos segundos
	else:
		lbl_tiempo.modulate = Color(1, 1, 1, 1)

func _on_error_occurred(new_errors: int, _delta: int) -> void:
	var prefix = "Errores:"
	if has_node("/root/LocalizationManager"):
		prefix = get_node("/root/LocalizationManager").translate_text(prefix)
	lbl_errores.text = "%s %d / 20" % [prefix, new_errors]

func _on_backpack_updated(items: Array) -> void:
	_update_backpack_ui(items, true)

func _update_backpack_ui(items: Array, animate: bool = true) -> void:
	# Limpiar slots viejos
	for child in backpack_container.get_children():
		if child.name != "TituloMochila":
			child.queue_free()
	
	if items.is_empty():
		_set_backpack_visible(false, animate)
	else:
		for i in range(items.size()):
			var item = items[i]
			var btn = Button.new()
			var estado = "(Dañada)" if item.get("broken", false) else "(Nueva)"
			var item_label = item.get("display_name", item.get("name", "Pieza"))
			if has_node("/root/LocalizationManager"):
				var loc = get_node("/root/LocalizationManager")
				estado = loc.translate_text(estado)
				item_label = loc.translate_text(item_label)
			btn.text = "%d. %s %s" % [i + 1, item_label, estado]
			if item.get("broken", false):
				btn.modulate = Color(1, 0.4, 0.4, 1)
			else:
				btn.modulate = Color(0.4, 1, 0.6, 1)
			btn.pressed.connect(func():
				var g = get_node_or_null("/root/GameManager")
				if g:
					g.selected_backpack_index = i
			)
			backpack_container.add_child(btn)
		_set_backpack_visible(true, animate)

func _set_backpack_visible(show_it: bool, animate: bool = true) -> void:
	if not top_right_panel:
		return
	if _tw_backpack and _tw_backpack.is_valid():
		_tw_backpack.kill()

	if show_it:
		top_right_panel.visible = true
		if not _backpack_is_shown:
			_backpack_is_shown = true
			if animate:
				top_right_panel.offset_left = BACKPACK_HIDDEN_LEFT
				top_right_panel.offset_right = BACKPACK_HIDDEN_RIGHT
				top_right_panel.modulate.a = 0.0
				_tw_backpack = create_tween().set_parallel(true)
				_tw_backpack.tween_property(top_right_panel, "offset_left", BACKPACK_RESTING_LEFT, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				_tw_backpack.tween_property(top_right_panel, "offset_right", BACKPACK_RESTING_RIGHT, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				_tw_backpack.tween_property(top_right_panel, "modulate:a", 1.0, 0.25)
			else:
				top_right_panel.offset_left = BACKPACK_RESTING_LEFT
				top_right_panel.offset_right = BACKPACK_RESTING_RIGHT
				top_right_panel.modulate.a = 1.0
	else:
		if _backpack_is_shown:
			_backpack_is_shown = false
			if animate:
				_tw_backpack = create_tween().set_parallel(true)
				_tw_backpack.tween_property(top_right_panel, "offset_left", BACKPACK_HIDDEN_LEFT, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				_tw_backpack.tween_property(top_right_panel, "offset_right", BACKPACK_HIDDEN_RIGHT, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				_tw_backpack.tween_property(top_right_panel, "modulate:a", 0.0, 0.22)
				_tw_backpack.chain().tween_callback(func():
					if not _backpack_is_shown and top_right_panel:
						top_right_panel.visible = false
				)
			else:
				top_right_panel.visible = false
				top_right_panel.offset_left = BACKPACK_HIDDEN_LEFT
				top_right_panel.offset_right = BACKPACK_HIDDEN_RIGHT
				top_right_panel.modulate.a = 0.0
		else:
			top_right_panel.visible = false
			top_right_panel.offset_left = BACKPACK_HIDDEN_LEFT
			top_right_panel.offset_right = BACKPACK_HIDDEN_RIGHT
			top_right_panel.modulate.a = 0.0

func set_visible_tools(count: int) -> void:
	if not tools_bar:
		return
	if bottom_center_panel:
		bottom_center_panel.visible = true
		bottom_center_panel.modulate.a = 1.0
	for i in range(tools_bar.get_child_count()):
		var btn = tools_bar.get_child(i) as Control
		if btn:
			btn.visible = (count <= 0 or i < count)

func set_tools_bar_visible(enabled: bool) -> void:
	if bottom_center_panel:
		bottom_center_panel.visible = enabled
		bottom_center_panel.modulate.a = 1.0 if enabled else 0.0
	if tools_bar:
		tools_bar.visible = enabled
		for i in range(tools_bar.get_child_count()):
			var btn = tools_bar.get_child(i) as Control
			if btn:
				btn.visible = enabled

func _on_tool_selected(tool_id: int) -> void:
	_update_tools_ui(tool_id)

func _update_tools_ui(active_tool: int) -> void:
	for i in range(tools_bar.get_child_count()):
		var btn = tools_bar.get_child(i) as Button
		if btn:
			var id = i + 1
			if btn.has_method("set_active_tool"):
				btn.set_active_tool(id == active_tool)
			elif id == active_tool:
				btn.modulate = Color(0, 1, 0.8, 1) # Seleccionada
			else:
				btn.modulate = Color(0.7, 0.7, 0.7, 0.7)

func _on_hardware_monitor_changed(is_enabled: bool) -> void:
	if not top_left_container:
		return
	var target_y = 175.0 if is_enabled else 20.0
	var tw = create_tween()
	tw.tween_property(top_left_container, "position:y", target_y, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _spawn_floating_text(text: String, is_positive: bool, custom_origin: Vector2 = Vector2.ZERO) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("spawn_floating_text"):
		gm.spawn_floating_text(text, is_positive, custom_origin)

func _process(_delta: float) -> void:
	if (game_over_panel and game_over_panel.visible) or (win_panel and win_panel.visible):
		if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_game_over(reason: String) -> void:
	if game_over_dim:
		game_over_dim.visible = true
	game_over_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var reason_lbl = game_over_panel.get_node_or_null("VBox/ReasonLabel") as Label
	if reason_lbl:
		reason_lbl.text = reason

func _on_level_won(stars: int, final_score: int) -> void:
	if falla_solucionada_hud:
		falla_solucionada_hud.visible = true
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

func update_stamina(current: float, max_val: float, is_exhausted: bool) -> void:
	if not stamina_bar:
		stamina_bar = get_node_or_null("Center/CurvedStaminaBar")
	if stamina_bar and stamina_bar.has_method("set_stamina"):
		stamina_bar.set_stamina(current, max_val, is_exhausted)
