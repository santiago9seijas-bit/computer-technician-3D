extends Control

signal modal_closed

@onready var tab_logros_btn: Button = $PanelContainer/VBox/TabsHBox/BtnLogros
@onready var tab_explicaciones_btn: Button = $PanelContainer/VBox/TabsHBox/BtnExplicaciones
@onready var btn_cerrar: Button = $PanelContainer/VBox/TabsHBox/BtnCerrar

@onready var view_logros: Control = $PanelContainer/VBox/Views/LogrosView
@onready var view_explicaciones: Control = $PanelContainer/VBox/Views/ExplicacionesView

@onready var logros_list_container: VBoxContainer = $PanelContainer/VBox/Views/LogrosView/ScrollContainer/LogrosVBox
@onready var lbl_logros_counter: Label = $PanelContainer/VBox/Views/LogrosView/CounterHeader/LblCounter

@onready var guides_list_container: VBoxContainer = $PanelContainer/VBox/Views/ExplicacionesView/ScrollContainer/GuidesVBox
@onready var lbl_guides_counter: Label = $PanelContainer/VBox/Views/ExplicacionesView/CounterHeader/LblGuidesCounter

@onready var animated_backdrop: Control = $AnimatedBackdrop

var active_tab: String = "logros"
var _logros_populated: bool = false
var _guides_populated: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_styles()
	
	tab_logros_btn.pressed.connect(func(): _switch_tab("logros"))
	tab_explicaciones_btn.pressed.connect(func(): _switch_tab("explicaciones"))
	btn_cerrar.pressed.connect(_on_close_pressed)
	
	# Animación suave de entrada
	modulate.a = 0.0
	$PanelContainer.scale = Vector2(0.94, 0.94)
	$PanelContainer.pivot_offset = $PanelContainer.size * 0.5
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.25)
	tw.tween_property($PanelContainer, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Carga perezosa del tab activo
	_switch_tab(active_tab)

func _process(_delta: float) -> void:
	pass

func set_initial_tab(tab_name: String) -> void:
	active_tab = tab_name
	if is_node_ready():
		_switch_tab(tab_name)

func _setup_styles() -> void:
	tab_logros_btn.focus_mode = Control.FOCUS_NONE
	tab_explicaciones_btn.focus_mode = Control.FOCUS_NONE
	btn_cerrar.focus_mode = Control.FOCUS_NONE

func _switch_tab(tab_name: String) -> void:
	active_tab = tab_name
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("play_sfx"):
		gm.play_sfx("click")
		
	if tab_name == "logros":
		view_logros.visible = true
		view_explicaciones.visible = false
		tab_logros_btn.modulate = Color(0.0, 1.0, 0.9)
		tab_explicaciones_btn.modulate = Color(0.6, 0.7, 0.8)
		if not _logros_populated:
			_populate_logros()
	else:
		view_logros.visible = false
		view_explicaciones.visible = true
		tab_logros_btn.modulate = Color(0.6, 0.7, 0.8)
		tab_explicaciones_btn.modulate = Color(0.0, 1.0, 0.9)
		if not _guides_populated:
			_populate_guides()

func _populate_logros() -> void:
	if not logros_list_container:
		return
	_logros_populated = true
		
	for child in logros_list_container.get_children():
		child.queue_free()
		
	var sm = get_node_or_null("/root/SaveManager")
	var unlocked_count = 0
	var total_count = SaveManager.ACHIEVEMENTS_CONFIG.size() if sm else 0
	
	if sm:
		unlocked_count = sm.get_unlocked_achievements_count()
		
	if lbl_logros_counter:
		var pct = int((float(unlocked_count) / float(max(total_count, 1))) * 100.0)
		lbl_logros_counter.text = "🏆 LOGROS DESBLOQUEADOS: %d / %d (%d%%)" % [unlocked_count, total_count, pct]
		
	if not sm:
		return
		
	for ach_id in SaveManager.ACHIEVEMENTS_CONFIG.keys():
		var ach = SaveManager.ACHIEVEMENTS_CONFIG[ach_id]
		var is_unlocked = sm.is_achievement_unlocked(ach_id)
		
		var card = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var sb = StyleBoxFlat.new()
		if is_unlocked:
			sb.bg_color = Color(0.04, 0.1, 0.16, 0.95)
			sb.border_color = Color(0.0, 0.95, 0.75, 0.9)
		else:
			sb.bg_color = Color(0.03, 0.05, 0.09, 0.88)
			sb.border_color = Color(0.2, 0.3, 0.4, 0.55)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(6)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		sb.content_margin_top = 10
		sb.content_margin_bottom = 10
		card.add_theme_stylebox_override("panel", sb)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_child(hbox)
		
		# Icono
		var icon_lbl = Label.new()
		icon_lbl.text = ach["icon"] if is_unlocked else "🔒"
		icon_lbl.add_theme_font_size_override("font_size", 28)
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(icon_lbl)
		
		# Textos con Word Wrap para no desbordar
		var vbox_info = VBoxContainer.new()
		vbox_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox_info.add_theme_constant_override("separation", 4)
		hbox.add_child(vbox_info)
		
		var title_lbl = Label.new()
		title_lbl.text = ach["title"]
		title_lbl.add_theme_font_size_override("font_size", 14)
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_lbl.modulate = Color(1.0, 0.85, 0.2) if is_unlocked else Color(0.7, 0.75, 0.85)
		vbox_info.add_child(title_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if is_unlocked:
			desc_lbl.text = ach["desc"]
			desc_lbl.modulate = Color(0.85, 0.9, 0.95, 0.95)
		else:
			if ach.get("secret", false):
				desc_lbl.text = "[ LOGRO SECRETO: ??? ]"
				desc_lbl.modulate = Color(0.85, 0.5, 0.2, 0.85)
			else:
				desc_lbl.text = ach["desc"]
				desc_lbl.modulate = Color(0.55, 0.6, 0.7, 0.75)
		desc_lbl.add_theme_font_size_override("font_size", 11)
		vbox_info.add_child(desc_lbl)
		
		# Insignia de estado
		var badge_lbl = Label.new()
		if is_unlocked:
			badge_lbl.text = "[ ✓ DESBLOQUEADO ]"
			badge_lbl.modulate = Color(0.2, 1.0, 0.4)
		else:
			badge_lbl.text = "[ 🔒 BLOQUEADO ]"
			badge_lbl.modulate = Color(0.5, 0.55, 0.6)
		badge_lbl.add_theme_font_size_override("font_size", 11)
		badge_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(badge_lbl)
		
		logros_list_container.add_child(card)

func _populate_guides() -> void:
	if not guides_list_container:
		return
	_guides_populated = true
		
	for child in guides_list_container.get_children():
		child.queue_free()
		
	var sm = get_node_or_null("/root/SaveManager")
	var topics_dict: Dictionary = SaveManager.GLOSSARY_TOPICS if sm else {}
	var unlocked_topics = 0
	var total_topics = topics_dict.size()
	
	for t_id in topics_dict.keys():
		if sm and sm.is_glossary_unlocked(t_id):
			unlocked_topics += 1
			
	if lbl_guides_counter:
		var pct = int((float(unlocked_topics) / float(max(total_topics, 1))) * 100.0)
		lbl_guides_counter.text = "📖 GLOSARIO TÉCNICO REGISTRADO: %d / %d DESBLOQUEADOS (%d%%)" % [unlocked_topics, total_topics, pct]
		
	for t_id in topics_dict.keys():
		var topic = topics_dict[t_id]
		var is_unlocked = sm.is_glossary_unlocked(t_id) if sm else false
		
		var card = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var sb = StyleBoxFlat.new()
		if is_unlocked:
			sb.bg_color = Color(0.03, 0.07, 0.14, 0.94)
			sb.border_color = Color(0.0, 0.85, 1.0, 0.8)
		else:
			sb.bg_color = Color(0.02, 0.04, 0.08, 0.88)
			sb.border_color = Color(0.2, 0.3, 0.45, 0.4)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 16
		sb.content_margin_right = 16
		sb.content_margin_top = 12
		sb.content_margin_bottom = 12
		card.add_theme_stylebox_override("panel", sb)
		
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 8)
		card.add_child(vbox)
		
		# Cabecera de la tarjeta
		var head_hbox = HBoxContainer.new()
		head_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(head_hbox)
		
		var title_lbl = Label.new()
		var icon_str = topic.get("icon", "📄") if is_unlocked else "🔒"
		title_lbl.text = "%s %s // %s" % [icon_str, topic.get("category", "TALLER"), topic.get("title", "Tema")]
		title_lbl.add_theme_font_size_override("font_size", 15)
		title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_lbl.modulate = Color(0.0, 0.95, 1.0) if is_unlocked else Color(0.6, 0.65, 0.75)
		head_hbox.add_child(title_lbl)
		
		var status_lbl = Label.new()
		if is_unlocked:
			status_lbl.text = "[ ✓ DISPONIBLE ]"
			status_lbl.modulate = Color(0.2, 1.0, 0.4)
		else:
			status_lbl.text = "[ 🔒 BLOQUEADO · COMPLETA EL TUTORIAL ]"
			status_lbl.modulate = Color(1.0, 0.65, 0.2)
		status_lbl.add_theme_font_size_override("font_size", 11)
		head_hbox.add_child(status_lbl)
		
		var sep = HSeparator.new()
		vbox.add_child(sep)
		
		# Contenido detallado
		var body_lbl = Label.new()
		body_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body_lbl.add_theme_font_size_override("font_size", 12)
		
		if is_unlocked:
			body_lbl.text = topic.get("content", "")
			body_lbl.modulate = Color(0.88, 0.92, 0.97, 0.95)
		else:
			body_lbl.text = "🔒 Información técnica restringida. Completa el tutorial correspondiente a '%s' para registrar el análisis completo de arquitectura, protocolos y diagnóstico en el glosario oficial." % topic.get("title", "")
			body_lbl.modulate = Color(0.55, 0.6, 0.7, 0.8)
			
		vbox.add_child(body_lbl)
		guides_list_container.add_child(card)

func _on_close_pressed() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("play_sfx"):
		gm.play_sfx("click")
		
	# Animación suave de salida
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_property($PanelContainer, "scale", Vector2(0.92, 0.92), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func():
		modal_closed.emit()
		queue_free()
	)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		_on_close_pressed()
