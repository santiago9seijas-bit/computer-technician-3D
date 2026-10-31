extends CanvasLayer

# =============================================================================
# MINIJUEGO: DESOBSTRUCCIÓN DE PELUSA Y POLVO EN DISIPADOR / COOLER
# Enseña:
# 1. Identificación de obstrucciones térmicas por pelusa y polvo apelmazado.
# 2. Uso del Limpiador [5] (Brocha antiestática / Cepillo de precisión).
# 3. Desobstrucción física de aletas metálicas hasta restaurar 100% de flujo de aire.
# =============================================================================

signal minigame_finished(success: bool)

@onready var modal_control: Control = $ModalControl
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var progress_label: Label = $ModalControl/Panel/VBox/Header/ProgressLabel
@onready var progress_bar: ProgressBar = $ModalControl/Panel/VBox/Header/ProgressBar
@onready var heatsink_area: Control = $ModalControl/Panel/VBox/WorkArea/HeatsinkFrame/Margin/HeatsinkArea
@onready var warning_label: Label = $ModalControl/Panel/VBox/WarningLabel
@onready var victory_banner: PanelContainer = $ModalControl/Panel/VBox/VictoryBanner
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel

# Datos de los cúmulos de pelusa (Posición relativa en %, tamaño y densidad)
var dust_data: Array[Dictionary] = [
	{"pos": Vector2(0.18, 0.22), "size": Vector2(64, 52), "rot": -12.0},
	{"pos": Vector2(0.38, 0.18), "size": Vector2(72, 48), "rot": 8.0},
	{"pos": Vector2(0.62, 0.24), "size": Vector2(58, 56), "rot": -18.0},
	{"pos": Vector2(0.82, 0.20), "size": Vector2(68, 50), "rot": 15.0},
	
	{"pos": Vector2(0.25, 0.48), "size": Vector2(78, 62), "rot": 22.0},
	{"pos": Vector2(0.50, 0.42), "size": Vector2(92, 68), "rot": -5.0},
	{"pos": Vector2(0.74, 0.50), "size": Vector2(74, 58), "rot": 14.0},
	
	{"pos": Vector2(0.16, 0.76), "size": Vector2(66, 54), "rot": -20.0},
	{"pos": Vector2(0.36, 0.80), "size": Vector2(80, 60), "rot": 10.0},
	{"pos": Vector2(0.58, 0.74), "size": Vector2(76, 56), "rot": -8.0},
	{"pos": Vector2(0.80, 0.78), "size": Vector2(64, 52), "rot": 25.0},
	
	{"pos": Vector2(0.50, 0.62), "size": Vector2(84, 58), "rot": -15.0}
]

var total_clumps: int = 0
var cleaned_clumps: int = 0
var is_game_completed: bool = false
var is_brush_pressed: bool = false
var clump_nodes: Array[Control] = []
var target_component: String = "Disipador"

func setup_component(comp_name: String) -> void:
	target_component = comp_name
	if is_inside_tree() and modal_control:
		_update_component_texts()

func _update_component_texts() -> void:
	var title_lbl = modal_control.get_node_or_null("Panel/VBox/Header/TitleLabel") as Label
	if title_lbl:
		title_lbl.text = "MANTENIMIENTO: LIMPIEZA DE PELUSA Y POLVO (%s)" % target_component.to_upper()

func _ready() -> void:
	layer = 12
	GameManager.select_tool(5)
	
	btn_cancel.pressed.connect(_on_cancel_pressed)
	victory_banner.visible = false
	warning_label.text = ""
	
	total_clumps = dust_data.size()
	cleaned_clumps = 0
	is_game_completed = false
	
	_build_heatsink_fins()
	_spawn_dust_clumps()
	_update_component_texts()
	_update_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		minigame_finished.emit(false)

func _input(event: InputEvent) -> void:
	if is_game_completed:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_brush_pressed = event.pressed
		if is_brush_pressed:
			_check_brush_at_position(event.global_position)
	elif event is InputEventMouseMotion and is_brush_pressed:
		_check_brush_at_position(event.global_position)

func _build_heatsink_fins() -> void:
	# Dibujar aletas de disipador metálicas horizontales en el fondo
	for child in heatsink_area.get_children():
		child.queue_free()
	clump_nodes.clear()
	
	var fins_container = Control.new()
	fins_container.name = "FinsContainer"
	fins_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	fins_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heatsink_area.add_child(fins_container)
	
	# Tubos de cobre (Heatpipes) verticales en el centro
	var heatpipe_left = ColorRect.new()
	heatpipe_left.color = Color(0.85, 0.45, 0.2, 0.75)
	heatpipe_left.set_anchors_preset(Control.PRESET_FULL_RECT)
	heatpipe_left.anchor_left = 0.36
	heatpipe_left.anchor_right = 0.39
	fins_container.add_child(heatpipe_left)
	
	var heatpipe_right = ColorRect.new()
	heatpipe_right.color = Color(0.85, 0.45, 0.2, 0.75)
	heatpipe_right.set_anchors_preset(Control.PRESET_FULL_RECT)
	heatpipe_right.anchor_left = 0.61
	heatpipe_right.anchor_right = 0.64
	fins_container.add_child(heatpipe_right)
	
	# 18 aletas de aluminio horizontales
	var num_fins = 18
	for i in range(num_fins):
		var fin = ColorRect.new()
		fin.color = Color(0.18, 0.22, 0.28, 0.95) if (i % 2 == 0) else Color(0.24, 0.28, 0.35, 0.95)
		fin.set_anchors_preset(Control.PRESET_FULL_RECT)
		fin.anchor_top = float(i) / float(num_fins)
		fin.anchor_bottom = float(i + 1) / float(num_fins) - 0.015
		fins_container.add_child(fin)
		
		# Borde metálico brillante de cada aleta
		var fin_edge = ColorRect.new()
		fin_edge.color = Color(0.45, 0.55, 0.65, 0.8)
		fin_edge.anchor_right = 1.0
		fin_edge.offset_bottom = 2.0
		fin.add_child(fin_edge)

func _spawn_dust_clumps() -> void:
	var area_size = heatsink_area.size
	if area_size.x <= 50.0 or area_size.y <= 50.0:
		area_size = Vector2(740.0, 320.0)
		
	for i in range(dust_data.size()):
		var data = dust_data[i]
		var clump = Panel.new()
		clump.name = "Clump_%d" % i
		clump.custom_minimum_size = data["size"]
		clump.size = data["size"]
		clump.pivot_offset = data["size"] * 0.5
		clump.position = Vector2(
			data["pos"].x * area_size.x - data["size"].x * 0.5,
			data["pos"].y * area_size.y - data["size"].y * 0.5
		)
		clump.rotation_degrees = data["rot"]
		clump.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		# Estilo esponjoso de pelusa / polvo
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.55, 0.52, 0.48, 0.92)
		sb.set_corner_radius_all(int(min(data["size"].x, data["size"].y) * 0.45))
		sb.border_width_left = 3
		sb.border_width_top = 3
		sb.border_width_right = 3
		sb.border_width_bottom = 3
		sb.border_color = Color(0.42, 0.38, 0.35, 0.9)
		sb.shadow_size = 4
		sb.shadow_color = Color(0, 0, 0, 0.4)
		clump.add_theme_stylebox_override("panel", sb)
		
		# Capa interior de fibra de pelusa
		var inner = Panel.new()
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		var inner_sb = StyleBoxFlat.new()
		inner_sb.bg_color = Color(0.45, 0.42, 0.38, 0.85)
		inner_sb.set_corner_radius_all(int(min(data["size"].x, data["size"].y) * 0.38))
		inner.add_theme_stylebox_override("panel", inner_sb)
		clump.add_child(inner)
		
		# Icono sutil de pelusa
		var lbl = Label.new()
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.text = "☁️"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.modulate = Color(0.7, 0.65, 0.6, 0.6)
		clump.add_child(lbl)
		
		clump.gui_input.connect(func(event): _on_clump_gui_input(clump, event))
		clump.set_meta("cleaned", false)
		clump.set_meta("data_idx", i)
		
		heatsink_area.add_child(clump)
		clump_nodes.append(clump)

func _check_brush_at_position(global_pos: Vector2) -> void:
	for clump in clump_nodes:
		if not is_instance_valid(clump) or clump.get_meta("cleaned", false):
			continue
		var rect = clump.get_global_rect()
		# Área de acción ligeramente ampliada para que el cepillo sea cómodo y fluido
		var expanded_rect = rect.grow(16.0)
		if expanded_rect.has_point(global_pos):
			_clean_clump(clump)

func _on_clump_gui_input(clump: Control, event: InputEvent) -> void:
	if is_game_completed:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_clean_clump(clump)

func _clean_clump(clump: Control) -> void:
	if clump.get_meta("cleaned", false):
		return
	clump.set_meta("cleaned", true)
	cleaned_clumps += 1
	
	# Animación de desintegración / expulsión de la pelusa
	var tw = create_tween().set_parallel(true)
	tw.tween_property(clump, "scale", Vector2(0.1, 0.1), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(clump, "modulate:a", 0.0, 0.22)
	tw.tween_property(clump, "position:y", clump.position.y - 25.0, 0.22)
	
	_spawn_dust_particles(clump.global_position + clump.size * 0.5)
	_update_ui()
	
	if cleaned_clumps >= total_clumps:
		_trigger_victory()

func _spawn_dust_particles(center_pos: Vector2) -> void:
	# Partículas flotantes de polvo desvaneciéndose
	for p in range(5):
		var puff = Label.new()
		puff.top_level = true
		puff.text = "•"
		puff.mouse_filter = Control.MOUSE_FILTER_IGNORE
		puff.add_theme_font_size_override("font_size", 14 + (p % 3) * 4)
		puff.modulate = Color(0.8, 0.78, 0.7, 0.9)
		puff.position = center_pos + Vector2(randf_range(-15, 15), randf_range(-15, 15))
		modal_control.add_child(puff)
		
		var p_tw = create_tween().set_parallel(true)
		var dest = puff.position + Vector2(randf_range(-40, 40), randf_range(-35, -10))
		p_tw.tween_property(puff, "position", dest, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		p_tw.tween_property(puff, "modulate:a", 0.0, 0.35)
		p_tw.chain().tween_callback(puff.queue_free)

func _update_ui() -> void:
	var percent = int((float(cleaned_clumps) / float(max(total_clumps, 1))) * 100.0)
	progress_bar.max_value = total_clumps
	progress_bar.value = cleaned_clumps
	progress_label.text = "PELUSA RETIRADA: %d / %d (%d%%)" % [cleaned_clumps, total_clumps, percent]
	
	if cleaned_clumps < total_clumps:
		status_label.text = "Pasa la brocha o haz clic sobre cada cúmulo de pelusa para liberar las aletas de aluminio."
	else:
		status_label.text = "✓ ¡DISIPADOR COMPLETAMENTE DESOBSTRUIDO! Flujo térmico restaurado al 100%."

func _trigger_victory() -> void:
	is_game_completed = true
	victory_banner.visible = true
	warning_label.text = "✓ ¡Mantenimiento completado! Flujo de aire térmico al 100%."
	warning_label.modulate = Color(0.2, 1.0, 0.5)
	
	btn_cancel.text = "✓ FINALIZAR MANTENIMIENTO"
	btn_cancel.modulate = Color(0.2, 1.0, 0.5)
	
	# Destello de éxito en el disipador
	var tw = create_tween().set_parallel(true)
	tw.tween_property(heatsink_area, "modulate", Color(1.3, 1.4, 1.2), 0.25)
	tw.chain().tween_property(heatsink_area, "modulate", Color.WHITE, 0.4)

func _on_cancel_pressed() -> void:
	minigame_finished.emit(is_game_completed)
