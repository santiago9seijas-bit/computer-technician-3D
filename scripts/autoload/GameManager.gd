extends Node

# Señales de estado global
signal score_updated(new_score: int, delta: int)
signal time_updated(time_left: float, delta: float)
signal error_occurred(new_errors: int, delta: int)
signal backpack_updated(items: Array)
signal tool_selected(tool_id: int)
signal game_over_triggered(reason: String)
signal level_completed(stars: int, final_score: int)
signal spares_repopulated()
signal pause_state_changed(is_paused: bool)

# Variables de juego
var time_left: float = 120.0
var timer_active: bool = false
var score: int = 0
var errors: int = 0
var computers_fixed: int = 0

# Mochila / Inventario
const MAX_BACKPACK_SLOTS: int = 3
var backpack: Array[Dictionary] = []
var selected_backpack_index: int = -1

# Herramienta activa (0 = Ninguna, 1 = Estrella, 2 = Pala, 3 = Cautín, 4 = Voltímetro, 5 = Limpiador)
var equipped_tool: int = 0

# Stock de repuestos disponible en la caja
var spares_stock: Dictionary = {
	"RAM": 3,
	"Disco Duro": 3,
	"Fan Cooler": 3,
	"Fuente": 2,
	"Grafica": 2,
	"Placa Madre": 2,
	"CPU": 2,
	"Refrigeracion Liquida": 3
}

# Estado de pausa
var is_game_paused: bool = false

var feedback_canvas_layer: CanvasLayer = null
var feedback_container: Control = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_feedback_layer()

func _setup_feedback_layer() -> void:
	if feedback_canvas_layer != null:
		return
	feedback_canvas_layer = CanvasLayer.new()
	feedback_canvas_layer.name = "GlobalFeedbackLayer"
	feedback_canvas_layer.layer = 128 # Máxima prioridad: siempre por encima de cualquier minijuego o modal
	add_child(feedback_canvas_layer)
	
	feedback_container = Control.new()
	feedback_container.name = "FeedbackContainer"
	feedback_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	feedback_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_canvas_layer.add_child(feedback_container)

func _process(delta: float) -> void:
	if timer_active and not is_game_paused:
		time_left -= delta
		if time_left <= 0.0:
			time_left = 0.0
			timer_active = false
			time_updated.emit(time_left, 0.0)
			trigger_game_over("¡Tiempo agotado! El cliente canceló el pedido.")
		else:
			time_updated.emit(time_left, -delta)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		match event.keycode:
			KEY_1, KEY_KP_1:
				select_tool(1)
			KEY_2, KEY_KP_2:
				select_tool(2)
			KEY_3, KEY_KP_3:
				select_tool(3)
			KEY_4, KEY_KP_4:
				select_tool(4)
			KEY_5, KEY_KP_5:
				select_tool(5)

func select_tool(tool_id: int) -> void:
	equipped_tool = tool_id
	tool_selected.emit(equipped_tool)

func is_soldering_tool_equipped() -> bool:
	return equipped_tool == 3

func is_voltimeter_equipped() -> bool:
	return equipped_tool == 4

func is_cleaning_tool_equipped() -> bool:
	return equipped_tool == 5

func start_level(initial_time: float = 120.0) -> void:
	time_left = initial_time
	score = 0
	errors = 0
	computers_fixed = 0
	backpack.clear()
	equipped_tool = 0
	is_game_paused = false
	timer_active = true
	
	spares_stock = {
		"RAM": 3,
		"Disco Duro": 3,
		"Fan Cooler": 3,
		"Fuente": 2,
		"Grafica": 2,
		"Placa Madre": 2,
		"CPU": 2,
		"Refrigeracion Liquida": 3
	}
	
	score_updated.emit(score, 0)
	time_updated.emit(time_left, 0.0)
	error_occurred.emit(errors, 0)
	backpack_updated.emit(backpack)
	tool_selected.emit(equipped_tool)

func register_repair(points: int = 100, time_bonus: float = 10.0, custom_pos: Vector2 = Vector2.ZERO) -> void:
	score += points
	if timer_active:
		time_left += time_bonus
		time_updated.emit(time_left, time_bonus)
	score_updated.emit(score, points)
	
	var txt = "+%d PTS" % points
	if time_bonus > 0.0 and timer_active:
		txt = "+%d PTS  +%.0fs" % [points, time_bonus]
	spawn_floating_text(txt, true, custom_pos)

func add_score(points: int = 100, time_bonus: float = 10.0, custom_pos: Vector2 = Vector2.ZERO) -> void:
	register_repair(points, time_bonus, custom_pos)

func register_error(time_penalty: float = 5.0, custom_pos: Vector2 = Vector2.ZERO) -> void:
	errors += 1
	if timer_active:
		time_left = max(0.0, time_left - time_penalty)
		time_updated.emit(time_left, -time_penalty)
	error_occurred.emit(errors, 1)
	
	var txt = "-%.0fs  +1 ERROR" % time_penalty if (time_penalty > 0.0 and timer_active) else "+1 ERROR"
	spawn_floating_text(txt, false, custom_pos)
	
	if errors >= 20:
		trigger_game_over("¡Demasiados errores acumulados (20)! El equipo sufrió daños irreparables.")

func add_error(time_penalty: float = 5.0, custom_pos: Vector2 = Vector2.ZERO) -> void:
	register_error(time_penalty, custom_pos)

func spawn_floating_text(text: String, is_positive: bool, custom_origin: Vector2 = Vector2.ZERO) -> void:
	_setup_feedback_layer()
	if not feedback_container or not is_inside_tree():
		return
		
	var label = Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var vp = get_viewport()
	var vp_rect = vp.get_visible_rect() if vp else Rect2(0, 0, 1280, 720)
	var screen_center = vp_rect.size * 0.5
	
	# Determinar posición de referencia del cursor
	var cursor_pos: Vector2
	if custom_origin != Vector2.ZERO:
		cursor_pos = custom_origin
	elif Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		cursor_pos = vp.get_mouse_position() if vp else screen_center
		if cursor_pos.x <= 0.0 or cursor_pos.y <= 0.0:
			cursor_pos = screen_center
	else:
		cursor_pos = screen_center
		
	var spawn_pos: Vector2
	var move_offset: Vector2
	
	if is_positive:
		# AMARILLOS: Lado izquierdo del cursor (Aciertos / Puntos)
		var left_dist = 110.0
		spawn_pos = cursor_pos + Vector2(-left_dist, -16.0)
		
		# Mantener alejado de la barra de estamina central (radio 52px)
		if abs(spawn_pos.x - screen_center.x) < 85.0 and abs(spawn_pos.y - screen_center.y) < 65.0:
			spawn_pos.x = screen_center.x - 115.0
			
		move_offset = Vector2(-22.0, -50.0)
		
		# Estilo Amarillo Neón
		label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.12, 1.0))
		label.add_theme_color_override("font_shadow_color", Color(0.65, 0.45, 0.0, 0.95))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.add_theme_constant_override("shadow_outline_size", 6)
	else:
		# ROJOS: Lado derecho del cursor (Errores / Penalizaciones)
		var right_dist = 110.0
		spawn_pos = cursor_pos + Vector2(right_dist, -16.0)
		
		# Mantener alejado de la barra de estamina central (radio 52px)
		if abs(spawn_pos.x - screen_center.x) < 85.0 and abs(spawn_pos.y - screen_center.y) < 65.0:
			spawn_pos.x = screen_center.x + 115.0
			
		move_offset = Vector2(22.0, -50.0)
		
		# Estilo Rojo Neón
		label.add_theme_color_override("font_color", Color(1.0, 0.15, 0.25, 1.0))
		label.add_theme_color_override("font_shadow_color", Color(0.5, 0.0, 0.08, 0.95))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.add_theme_constant_override("shadow_outline_size", 6)
		
	# Limitar a los márgenes seguros de pantalla
	spawn_pos.x = clampf(spawn_pos.x, 25.0, vp_rect.size.x - 220.0)
	spawn_pos.y = clampf(spawn_pos.y, 35.0, vp_rect.size.y - 70.0)
	label.position = spawn_pos
	
	if ResourceLoader.exists("res://assets/fonts/Bungee-Regular.ttf"):
		label.add_theme_font_override("font", load("res://assets/fonts/Bungee-Regular.ttf"))
	elif ResourceLoader.exists("res://assets/fonts/JetBrainsMono-Bold.ttf"):
		label.add_theme_font_override("font", load("res://assets/fonts/JetBrainsMono-Bold.ttf"))
	label.add_theme_font_size_override("font_size", 16)
	
	label.scale = Vector2(1.3, 1.3)
	label.pivot_offset = Vector2(0.0, 10.0)
	
	feedback_container.add_child(label)
	
	var tween = feedback_container.create_tween()
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "position", label.position + move_offset, 0.95).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.95).set_delay(0.25)
	tween.tween_callback(label.queue_free)

func add_item_to_backpack(item: Dictionary) -> bool:
	if backpack.size() >= MAX_BACKPACK_SLOTS:
		return false
	backpack.append(item)
	backpack_updated.emit(backpack)
	return true

func remove_item_from_backpack(index: int) -> Dictionary:
	if index >= 0 and index < backpack.size():
		var item = backpack[index]
		backpack.remove_at(index)
		backpack_updated.emit(backpack)
		return item
	return {}

func trash_selected_item() -> bool:
	if selected_backpack_index >= 0 and selected_backpack_index < backpack.size():
		var item = backpack[selected_backpack_index]
		backpack.remove_at(selected_backpack_index)
		selected_backpack_index = -1
		backpack_updated.emit(backpack)
		return true
	elif backpack.size() > 0:
		backpack.remove_at(backpack.size() - 1)
		backpack_updated.emit(backpack)
		return true
	return false

func request_spares_refill() -> void:
	spares_stock = {
		"RAM": 3,
		"Disco Duro": 3,
		"Fan Cooler": 3,
		"Fuente": 2,
		"Grafica": 2,
		"Placa Madre": 2,
		"CPU": 2,
		"Refrigeracion Liquida": 3
	}
	spares_repopulated.emit()

func calculate_stars() -> int:
	if errors <= 5:
		return 3
	elif errors <= 12:
		return 2
	elif errors < 20:
		return 1
	return 0

func win_level() -> void:
	timer_active = false
	var final_stars = calculate_stars()
	level_completed.emit(final_stars, score)

func complete_level() -> void:
	win_level()

func trigger_game_over(reason: String) -> void:
	timer_active = false
	game_over_triggered.emit(reason)

func toggle_pause() -> void:
	is_game_paused = !is_game_paused
	get_tree().paused = is_game_paused
	pause_state_changed.emit(is_game_paused)
