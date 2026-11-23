extends Control

signal started()

@onready var card_modal: PanelContainer = find_child("CardModal", true, false) as PanelContainer
@onready var btn_close: Button = find_child("BtnClose", true, false) as Button
@onready var btn_iniciar: Button = find_child("BtnIniciar", true, false) as Button

var is_dismissed: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true
	is_dismissed = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if btn_close:
		btn_close.pressed.connect(_on_close_pressed)
	if btn_iniciar:
		btn_iniciar.pressed.connect(_on_close_pressed)
		
	_update_desafios_hud()

	# Centrado dinámico del pivote para animación suave
	modulate.a = 0.0
	if card_modal:
		card_modal.scale = Vector2(0.88, 0.88)
		call_deferred("_setup_pivot")
		
		var tw = create_tween().set_parallel(true)
		tw.tween_property(self, "modulate:a", 1.0, 0.22)
		tw.tween_property(card_modal, "scale", Vector2.ONE, 0.22)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		var tw = create_tween()
		tw.tween_property(self, "modulate:a", 1.0, 0.22)

func _setup_pivot() -> void:
	if card_modal and is_instance_valid(card_modal):
		card_modal.pivot_offset = card_modal.size * 0.5

func set_mission_data(title: String, badge: String, objective: String, diagnostic: String = "", tools: String = "") -> void:
	var lbl_title = find_child("Title", true, false) as Label
	if lbl_title and title != "":
		lbl_title.text = title
	var lbl_badge = find_child("Badge", true, false) as Label
	if lbl_badge and badge != "":
		lbl_badge.text = badge
	var obj_box = find_child("ObjBox", true, false)
	if obj_box and objective != "":
		var obj_lbl = obj_box.get_node_or_null("Text") as Label
		if obj_lbl:
			obj_lbl.text = objective
	var diag_box = find_child("DiagBox", true, false)
	if diag_box and diagnostic != "":
		var diag_lbl = diag_box.get_node_or_null("Text") as Label
		if diag_lbl:
			diag_lbl.text = diagnostic
	var tools_box = find_child("ToolsBox", true, false)
	if tools_box and tools != "":
		var tools_lbl = tools_box.get_node_or_null("Text") as Label
		if tools_lbl:
			tools_lbl.text = tools

func _update_desafios_hud() -> void:
	var lbl_desafios = find_child("LblDesafios", true, false) as Label
	var lbl_errores = find_child("LblErrores", true, false) as Label
	var lbl_max_puntos = find_child("LblMaxPuntosNivel", true, false) as Label
	var lbl_puntos_modo = find_child("LblMaxPuntosModo", true, false) as Label
	
	var gm = get_node_or_null("/root/GameManager")
	var sm = get_node_or_null("/root/SaveManager")
	
	var curr_score = gm.score if gm else 0
	var curr_errors = gm.errors if (gm and "errors" in gm) else 0
	var mode_name = gm.current_mode if (gm and "current_mode" in gm) else "reparacion"
	
	# Puntos de nivel estimados / máximos por modo
	var max_nivel_pts = 250
	if mode_name == "sistema":
		max_nivel_pts = 300
	elif mode_name == "servidor":
		max_nivel_pts = 350
		
	var puntos_modo_total = 1970
	if sm and sm.has_method("get_current_slot_data"):
		var slot_data = sm.get_current_slot_data()
		if not slot_data.is_empty():
			puntos_modo_total = slot_data.get("score", 1970)
	
	if lbl_desafios:
		# Verifica si todos los desafíos del modo / nivel están completados
		var all_challenges_done: bool = false
		if gm and "challenges_completed" in gm:
			all_challenges_done = gm.challenges_completed >= 3
		if all_challenges_done:
			lbl_desafios.text = "🏆 DESAFÍOS: ✓ 3/3 COMPLETADOS"
			lbl_desafios.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4, 1.0))
		else:
			lbl_desafios.text = "🏆 DESAFÍOS: ⬡ 0/3 (EN CURSO)"
			lbl_desafios.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
			
	if lbl_errores:
		if curr_errors == 0:
			lbl_errores.text = "🎯 PRECISIÓN: ✓ 0 ERRORES (IMPECABLE)"
			lbl_errores.add_theme_color_override("font_color", Color(0.15, 0.95, 0.6, 1.0))
		else:
			lbl_errores.text = "⚠️ ERRORES: %d COMETIDOS" % curr_errors
			lbl_errores.add_theme_color_override("font_color", Color(1.0, 0.4, 0.35, 1.0))
			
	if lbl_max_puntos:
		if curr_score >= max_nivel_pts:
			lbl_max_puntos.text = "★ PUNTOS NIVEL: %d / %d PTS [MAX ALCANZADO]" % [curr_score, max_nivel_pts]
			lbl_max_puntos.add_theme_color_override("font_color", Color(0.2, 1.0, 0.45, 1.0))
		else:
			lbl_max_puntos.text = "★ PUNTOS NIVEL: %d / %d PTS" % [curr_score, max_nivel_pts]
			lbl_max_puntos.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0, 1.0))
			
	if lbl_puntos_modo:
		lbl_puntos_modo.text = "🌐 PUNTOS TOTALES MODO: %d PTS" % puntos_modo_total
		lbl_puntos_modo.add_theme_color_override("font_color", Color(0.8, 0.7, 1.0, 1.0))

func set_performance_metrics(desafios_completados: bool, errores: int, puntos_nivel: int, max_puntos_nivel: int, puntos_modo: int) -> void:
	var lbl_desafios = find_child("LblDesafios", true, false) as Label
	var lbl_errores = find_child("LblErrores", true, false) as Label
	var lbl_max_puntos = find_child("LblMaxPuntosNivel", true, false) as Label
	var lbl_puntos_modo = find_child("LblMaxPuntosModo", true, false) as Label
	
	if lbl_desafios:
		if desafios_completados:
			lbl_desafios.text = "🏆 DESAFÍOS: ✓ COMPLETADOS"
			lbl_desafios.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4, 1.0))
		else:
			lbl_desafios.text = "🏆 DESAFÍOS: ⬡ EN CURSO"
			lbl_desafios.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
			
	if lbl_errores:
		if errores == 0:
			lbl_errores.text = "🎯 PRECISIÓN: ✓ 0 ERRORES (IMPECABLE)"
			lbl_errores.add_theme_color_override("font_color", Color(0.15, 0.95, 0.6, 1.0))
		else:
			lbl_errores.text = "⚠️ ERRORES: %d COMETIDOS" % errores
			lbl_errores.add_theme_color_override("font_color", Color(1.0, 0.4, 0.35, 1.0))
			
	if lbl_max_puntos:
		if puntos_nivel >= max_puntos_nivel and max_puntos_nivel > 0:
			lbl_max_puntos.text = "★ PUNTOS NIVEL: %d / %d PTS [MAX ALCANZADO]" % [puntos_nivel, max_puntos_nivel]
			lbl_max_puntos.add_theme_color_override("font_color", Color(0.2, 1.0, 0.45, 1.0))
		else:
			lbl_max_puntos.text = "★ PUNTOS NIVEL: %d / %d PTS" % [puntos_nivel, max_puntos_nivel]
			lbl_max_puntos.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0, 1.0))
			
	if lbl_puntos_modo:
		lbl_puntos_modo.text = "🌐 PUNTOS TOTALES MODO: %d PTS" % puntos_modo
		lbl_puntos_modo.add_theme_color_override("font_color", Color(0.8, 0.7, 1.0, 1.0))

func _unhandled_input(event: InputEvent) -> void:
	if visible and not is_dismissed:
		if event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
			_on_close_pressed()
			get_viewport().set_input_as_handled()

func _on_close_pressed() -> void:
	if is_dismissed:
		return
	is_dismissed = true
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	if card_modal:
		tw.tween_property(card_modal, "scale", Vector2(0.88, 0.88), 0.18)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func():
		visible = false
		started.emit()
		queue_free()
	)
