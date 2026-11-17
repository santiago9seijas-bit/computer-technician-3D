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
signal difficulty_changed(new_difficulty: String)
signal examination_points_updated(current_pts: int, max_pts: int, recharge_progress: int)
signal hardware_monitor_changed(enabled: bool)
signal photosensitive_mode_changed(enabled: bool)
signal settings_loaded()

# Sistema de Dificultad: "brutal" (10 min), "dificil" (15 min), "normal" (20 min), "facil" (25 min)
const DIFFICULTY_TIMES: Dictionary = {
	"brutal": 600.0,   # 10 minutos
	"dificil": 900.0,  # 15 minutos
	"normal": 1200.0,  # 20 minutos
	"facil": 1500.0    # 25 minutos
}

var current_difficulty: String = "normal"
var current_mode: String = "reparacion"
var tutorial_target_component: String = "general"
var practice_target_mode: String = "maestra"
var santiago_esc_count: int = 0

func set_difficulty(diff: String) -> void:
	var lower = diff.to_lower().strip_edges()
	if DIFFICULTY_TIMES.has(lower):
		current_difficulty = lower
		difficulty_changed.emit(current_difficulty)

func get_difficulty_time() -> float:
	return DIFFICULTY_TIMES.get(current_difficulty, 1200.0)

func get_difficulty_name() -> String:
	match current_difficulty:
		"brutal":
			return "BRUTAL"
		"dificil":
			return "DIFÍCIL"
		"normal":
			return "NORMAL"
		"facil":
			return "FÁCIL"
		_:
			return "NORMAL"

# Variables de juego
var time_left: float = 120.0
var timer_active: bool = false
var is_game_over: bool = false
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
	"RAM": 6,
	"Disco Duro": 6,
	"Fan Cooler": 4,
	"Fuente": 4,
	"Grafica": 4,
	"Placa Madre": 4,
	"CPU": 4,
	"Refrigeracion Liquida": 4
}

# Estado de pausa y configuración
var is_game_paused: bool = false
var mouse_sensitivity_multiplier: float = 1.0
var master_volume: float = 100.0
var sfx_volume: float = 100.0
var performance_mode: bool = false
var show_hardware_monitor: bool = false # Consumo / Monitor en off por defecto
var photosensitive_mode: bool = false # Modo prevención fotosensible en off por defecto

# Sistema de Puntos de Examinación (Diagnóstico de Hardware)
const MAX_EXAMINATION_POINTS: int = 4
var examination_points: int = 4
var pieces_repaired_since_recharge: int = 0

func can_examine() -> bool:
	return examination_points > 0

func consume_examination_point() -> bool:
	if examination_points > 0:
		examination_points -= 1
		examination_points_updated.emit(examination_points, MAX_EXAMINATION_POINTS, pieces_repaired_since_recharge)
		return true
	return false

func notify_piece_repaired(custom_pos: Vector2 = Vector2.ZERO) -> void:
	pieces_repaired_since_recharge += 1
	if pieces_repaired_since_recharge >= 2:
		pieces_repaired_since_recharge = 0
		if examination_points < MAX_EXAMINATION_POINTS:
			examination_points += 1
			spawn_floating_text("🔍 +1 PUNTO DE EXAMINACIÓN", true, custom_pos)
	examination_points_updated.emit(examination_points, MAX_EXAMINATION_POINTS, pieces_repaired_since_recharge)

# Seguimiento de modales abiertos para optimizar comprobaciones sin find_child recursivo
var _open_modals_set: Dictionary = {}

func register_modal_opened(modal_node: Node) -> void:
	if modal_node:
		_open_modals_set[modal_node] = true

func register_modal_closed(modal_node: Node) -> void:
	if modal_node:
		_open_modals_set.erase(modal_node)

func is_any_modal_open() -> bool:
	for node in _open_modals_set.keys():
		if is_instance_valid(node) and (not ("visible" in node) or node.visible):
			return true
	return false

# Capas globales de UI
var feedback_canvas_layer: CanvasLayer = null
var feedback_container: Control = null
var hardware_monitor_layer: CanvasLayer = null
var hardware_monitor_instance: Control = null

const SETTINGS_FILE_PATH: String = "user://settings.cfg"
const HARDWARE_MONITOR_SCENE: PackedScene = preload("res://scenes/ui/HardwareMonitorOverlay.tscn")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_feedback_layer()
	_setup_hardware_monitor_layer()
	load_settings()
	get_tree().node_added.connect(func(n: Node):
		if photosensitive_mode and n is WorldEnvironment and n.environment:
			n.environment.glow_enabled = false
	)

func _setup_hardware_monitor_layer() -> void:
	if hardware_monitor_layer != null:
		return
	hardware_monitor_layer = CanvasLayer.new()
	hardware_monitor_layer.name = "HardwareMonitorLayer"
	hardware_monitor_layer.layer = 126 # Muy alta prioridad pero debajo de feedback
	add_child(hardware_monitor_layer)

	hardware_monitor_instance = HARDWARE_MONITOR_SCENE.instantiate()
	hardware_monitor_instance.visible = show_hardware_monitor
	hardware_monitor_instance.set_process(show_hardware_monitor)
	hardware_monitor_layer.add_child(hardware_monitor_instance)

func set_hardware_monitor_enabled(enabled: bool) -> void:
	show_hardware_monitor = enabled
	if hardware_monitor_instance:
		hardware_monitor_instance.visible = enabled
		hardware_monitor_instance.set_process(enabled)
	hardware_monitor_changed.emit(show_hardware_monitor)

func toggle_hardware_monitor() -> bool:
	set_hardware_monitor_enabled(!show_hardware_monitor)
	return show_hardware_monitor

func is_hardware_monitor_enabled() -> bool:
	return show_hardware_monitor

func set_photosensitive_mode(enabled: bool) -> void:
	photosensitive_mode = enabled
	photosensitive_mode_changed.emit(photosensitive_mode)
	_apply_photosensitive_mode()
	save_settings()

func toggle_photosensitive_mode() -> bool:
	set_photosensitive_mode(!photosensitive_mode)
	return photosensitive_mode

func is_photosensitive_mode_enabled() -> bool:
	return photosensitive_mode

func _apply_photosensitive_mode() -> void:
	var tree = get_tree()
	if not tree or not tree.root:
		return
	_update_environments_recursive(tree.root)

func _update_environments_recursive(node: Node) -> void:
	if node is WorldEnvironment and node.environment:
		var env = node.environment
		if photosensitive_mode:
			env.glow_enabled = false
		else:
			env.glow_enabled = true
			env.glow_bloom = 0.08
			env.glow_intensity = 0.75
	for child in node.get_children():
		_update_environments_recursive(child)

func set_performance_mode(enabled: bool) -> void:
	performance_mode = enabled
	var vp = get_viewport()
	if vp:
		if performance_mode:
			# Modo Rendimiento Suave: escala 3D a 0.85 y menor carga de filtrado
			vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
			vp.scaling_3d_scale = 0.85
			RenderingServer.viewport_set_msaa_3d(vp.get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_DISABLED)
		else:
			# Modo Alta Definición nativo
			vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
			vp.scaling_3d_scale = 1.0
			RenderingServer.viewport_set_msaa_3d(vp.get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_2X)
	save_settings()

func set_mouse_sensitivity(multiplier: float) -> void:
	mouse_sensitivity_multiplier = clampf(multiplier, 0.1, 4.0)
	save_settings()

func set_master_volume_val(val: float) -> void:
	master_volume = clampf(val, 0.0, 100.0)
	var bus = AudioServer.get_bus_index("Master")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(max(master_volume / 100.0, 0.0001)))
	save_settings()

func set_sfx_volume_val(val: float) -> void:
	sfx_volume = clampf(val, 0.0, 100.0)
	var bus = AudioServer.get_bus_index("SFX")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(max(sfx_volume / 100.0, 0.0001)))
	save_settings()

func load_settings() -> void:
	var cfg = ConfigFile.new()
	var err = cfg.load(SETTINGS_FILE_PATH)
	var saved_lang = "es"
	if err == OK:
		# El monitor de consumo SIEMPRE inicia desactivado (OFF) por defecto en cada sesión
		show_hardware_monitor = false
		photosensitive_mode = cfg.get_value("accessibility", "photosensitive_mode", false)
		performance_mode = cfg.get_value("graphics", "performance_mode", false)
		master_volume = cfg.get_value("audio", "master_volume", 100.0)
		sfx_volume = cfg.get_value("audio", "sfx_volume", 100.0)
		mouse_sensitivity_multiplier = cfg.get_value("controls", "mouse_sensitivity", 1.0)
		saved_lang = cfg.get_value("general", "language", "es")
	else:
		show_hardware_monitor = false
		photosensitive_mode = false
		performance_mode = false
		master_volume = 100.0
		sfx_volume = 100.0
		mouse_sensitivity_multiplier = 1.0
		saved_lang = "es"

	# Aplicar volumen cargado
	set_master_volume_val(master_volume)
	set_sfx_volume_val(sfx_volume)
	set_performance_mode(performance_mode)
	_apply_photosensitive_mode()
	if has_node("/root/LocalizationManager"):
		var loc = get_node("/root/LocalizationManager")
		loc.set_locale(saved_lang, false)
	if hardware_monitor_instance:
		hardware_monitor_instance.visible = false
		hardware_monitor_instance.set_process(false)
	settings_loaded.emit()

func save_settings() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("accessibility", "photosensitive_mode", photosensitive_mode)
	cfg.set_value("graphics", "performance_mode", performance_mode)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("controls", "mouse_sensitivity", mouse_sensitivity_multiplier)
	if has_node("/root/LocalizationManager"):
		var loc = get_node("/root/LocalizationManager")
		cfg.set_value("general", "language", loc.get_locale())
	cfg.save(SETTINGS_FILE_PATH)

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

func start_level(initial_time: float = -1.0) -> void:
	if initial_time <= 0.0:
		initial_time = get_difficulty_time()
	# Cancelar cualquier audio residual de menús o selección de nivel al iniciar la partida
	var tree = get_tree()
	if tree and tree.root:
		for child in tree.root.get_children():
			if child is AudioStreamPlayer:
				if child.stream and ("seleccion" in child.stream.resource_path or "entrada" in child.stream.resource_path):
					child.stop()
					child.queue_free()

	time_left = initial_time
	score = 0
	errors = 0
	computers_fixed = 0
	backpack.clear()
	equipped_tool = 0
	is_game_paused = false
	is_game_over = false
	timer_active = true
	examination_points = 4
	pieces_repaired_since_recharge = 0
	
	spares_stock = {
		"RAM": 6,
		"Disco Duro": 6,
		"Fan Cooler": 4,
		"Fuente": 4,
		"Grafica": 4,
		"Placa Madre": 4,
		"CPU": 4,
		"Refrigeracion Liquida": 4
	}
	
	score_updated.emit(score, 0)
	time_updated.emit(time_left, 0.0)
	error_occurred.emit(errors, 0)
	backpack_updated.emit(backpack)
	tool_selected.emit(equipped_tool)
	examination_points_updated.emit(examination_points, MAX_EXAMINATION_POINTS, pieces_repaired_since_recharge)

func register_repair(points: int = 100, time_bonus: float = 10.0, custom_pos: Vector2 = Vector2.ZERO) -> void:
	score += points
	if timer_active:
		time_left += time_bonus
		time_updated.emit(time_left, time_bonus)
	score_updated.emit(score, points)
	notify_piece_repaired(custom_pos)
	
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
		"RAM": 6,
		"Disco Duro": 6,
		"Fan Cooler": 4,
		"Fuente": 4,
		"Grafica": 4,
		"Placa Madre": 4,
		"CPU": 4,
		"Refrigeracion Liquida": 4
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
	is_game_over = true
	timer_active = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game_over_triggered.emit(reason)

func toggle_pause() -> void:
	is_game_paused = !is_game_paused
	get_tree().paused = is_game_paused
	pause_state_changed.emit(is_game_paused)
