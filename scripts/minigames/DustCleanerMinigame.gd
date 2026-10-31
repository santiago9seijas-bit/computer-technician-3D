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

const TEX_RAM: Texture2D = preload("res://pixel art minijuegos/ram.png")

# =============================================================================
# SPRITES DE PELUSA EN PIXEL ART
# =============================================================================
const DUST_SPRITES: Array[Dictionary] = [
	{
		"texture": preload("res://pixel art minijuegos/pelusa grande.png"),
		"base_size": Vector2(98, 82),
		"type": "grande"
	},
	{
		"texture": preload("res://pixel art minijuegos/pelusa mediana.png"),
		"base_size": Vector2(80, 50),
		"type": "mediana"
	},
	{
		"texture": preload("res://pixel art minijuegos/pelusa pequeña.png"),
		"base_size": Vector2(60, 44),
		"type": "pequeña"
	}
]

# Control de aleatoriedad y cantidad de pelusa
@export var randomize_dust: bool = true
@export var clumps_count_ram: int = 10
@export var clumps_count_heatsink: int = 18
@export var target_component: String = "RAM"

# Datos de respaldo (modo estático)
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
var ram_sprite_node: TextureRect = null

func setup_component(comp_name: String) -> void:
	target_component = comp_name
	if is_inside_tree() and modal_control:
		_build_component_background()
		_spawn_dust_clumps()
		_update_component_texts()
		_update_ui()

func _update_component_texts() -> void:
	var title_lbl = modal_control.get_node_or_null("Panel/VBox/Header/TitleLabel") as Label
	if title_lbl:
		var comp_display = "MEMORIA RAM" if ("ram" in target_component.to_lower()) else target_component.to_upper()
		title_lbl.text = "MANTENIMIENTO: LIMPIEZA DE PELUSA Y POLVO (%s)" % comp_display

func _ready() -> void:
	layer = 12
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("select_tool"):
		gm.select_tool(5)
	
	btn_cancel.pressed.connect(_on_cancel_pressed)
	victory_banner.visible = false
	warning_label.text = ""
	
	cleaned_clumps = 0
	is_game_completed = false
	
	_build_component_background()
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

func _build_component_background() -> void:
	for child in heatsink_area.get_children():
		child.queue_free()
	clump_nodes.clear()
	ram_sprite_node = null
	
	var is_ram: bool = "ram" in target_component.to_lower()
	if is_ram:
		_build_ram_background()
	else:
		_build_heatsink_fins()

func _build_ram_background() -> void:
	var area_size: Vector2 = heatsink_area.size
	if area_size.x <= 50.0 or area_size.y <= 50.0:
		area_size = Vector2(748.0, 338.0)
		
	# 1. Tapete de trabajo antiestático (ESD mat)
	var workbench = Panel.new()
	workbench.name = "Workbench"
	workbench.set_anchors_preset(Control.PRESET_FULL_RECT)
	workbench.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.12, 0.95)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.18, 0.32, 0.48, 0.5)
	sb.set_corner_radius_all(6)
	workbench.add_theme_stylebox_override("panel", sb)
	heatsink_area.add_child(workbench)
	
	# 2. Marco / Zócalo guía detrás del módulo de memoria
	var ram_w: float = minf(area_size.x - 60.0, 580.0)
	var ram_h: float = ram_w * (147.0 / 331.0) # Proporción exacta de ram.png (331x147)
	var ram_size = Vector2(ram_w, ram_h)
	var ram_pos = (area_size - ram_size) * 0.5
	
	var slot_guide = Panel.new()
	slot_guide.name = "SlotGuide"
	slot_guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_guide.position = ram_pos - Vector2(14, 12)
	slot_guide.size = ram_size + Vector2(28, 24)
	var guide_sb = StyleBoxFlat.new()
	guide_sb.bg_color = Color(0.03, 0.04, 0.07, 0.85)
	guide_sb.border_width_left = 2
	guide_sb.border_width_top = 2
	guide_sb.border_width_right = 2
	guide_sb.border_width_bottom = 2
	guide_sb.border_color = Color(0.0, 0.85, 0.9, 0.25)
	guide_sb.set_corner_radius_all(8)
	slot_guide.add_theme_stylebox_override("panel", guide_sb)
	heatsink_area.add_child(slot_guide)
	
	# 3. Sprite de la Memoria RAM (pixel art oficial, colocado como fondo debajo de la pelusa)
	var ram_sprite = TextureRect.new()
	ram_sprite.name = "RAMSprite"
	ram_sprite.texture = TEX_RAM
	ram_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ram_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ram_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ram_sprite.custom_minimum_size = ram_size
	ram_sprite.size = ram_size
	ram_sprite.position = ram_pos
	ram_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heatsink_area.add_child(ram_sprite)
	ram_sprite_node = ram_sprite

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
	if randomize_dust:
		randomize()
		
	var area_size = heatsink_area.size
	if area_size.x <= 50.0 or area_size.y <= 50.0:
		area_size = Vector2(748.0, 338.0)
		
	var is_ram: bool = "ram" in target_component.to_lower()
	var bounds: Rect2
	if is_ram and is_instance_valid(ram_sprite_node):
		bounds = Rect2(ram_sprite_node.position, ram_sprite_node.size)
	else:
		bounds = Rect2(Vector2.ZERO, area_size)
		
	var padding: float = 12.0 if is_ram else 18.0
	var count: int = (clumps_count_ram if is_ram else clumps_count_heatsink) if randomize_dust else dust_data.size()
	total_clumps = count
	
	if randomize_dust:
		# Distribución orgánica y dispareja (con cúmulos superpuestos / focos de acumulación)
		# 1. Definir focos aleatorios donde la pelusa se apelmaza una sobre otra
		var num_foci: int = randi_range(3, 5) if is_ram else randi_range(4, 7)
		var foci: Array[Vector2] = []
		for f in range(num_foci):
			var fx = randf_range(bounds.position.x + padding + 25.0, maxf(bounds.position.x + padding + 25.0, bounds.end.x - padding - 65.0))
			var fy = randf_range(bounds.position.y + padding + 15.0, maxf(bounds.position.y + padding + 15.0, bounds.end.y - padding - 45.0))
			foci.append(Vector2(fx, fy))
			
		for i in range(count):
			# Selección aleatoria de sprite (grande, mediana o pequeña)
			var sprite_info: Dictionary = DUST_SPRITES.pick_random()
			var scale_factor: float = randf_range(0.85, 1.22)
			var clump_size: Vector2 = sprite_info["base_size"] * scale_factor
			
			var min_x = bounds.position.x + padding
			var max_x = maxf(min_x, bounds.end.x - clump_size.x - padding)
			var min_y = bounds.position.y + padding
			var max_y = maxf(min_y, bounds.end.y - clump_size.y - padding)
			
			var x: float = 0.0
			var y: float = 0.0
			
			# ~65% de probabilidad de montarse en o cerca de un foco (pelusas una sobre otra)
			# ~35% de probabilidad de caer dispareja en cualquier punto libre
			if randf() < 0.65 and foci.size() > 0:
				var chosen_focus: Vector2 = foci.pick_random()
				x = chosen_focus.x + randf_range(-36.0, 36.0)
				y = chosen_focus.y + randf_range(-25.0, 25.0)
			else:
				x = randf_range(min_x, max_x)
				y = randf_range(min_y, max_y)
			
			# Respetar con precisión los límites del marco o sprite
			var pos = Vector2(
				clampf(x, min_x, max_x),
				clampf(y, min_y, max_y)
			)
			var rot: float = randf_range(-35.0, 35.0)
			
			_create_dust_clump_node(i, sprite_info["texture"], clump_size, pos, rot)
	else:
		# Modo respaldo con posiciones fijas
		for i in range(dust_data.size()):
			var data: Dictionary = dust_data[i]
			var sprite_info: Dictionary = DUST_SPRITES[i % DUST_SPRITES.size()]
			var clump_size: Vector2 = data["size"]
			var pos = Vector2(
				clampf(bounds.position.x + data["pos"].x * bounds.size.x - clump_size.x * 0.5, bounds.position.x + padding, bounds.end.x - clump_size.x - padding),
				clampf(bounds.position.y + data["pos"].y * bounds.size.y - clump_size.y * 0.5, bounds.position.y + padding, bounds.end.y - clump_size.y - padding)
			)
			_create_dust_clump_node(i, sprite_info["texture"], clump_size, pos, data["rot"])

func _create_dust_clump_node(idx: int, tex: Texture2D, clump_size: Vector2, pos: Vector2, rot: float) -> void:
	var clump = TextureRect.new()
	clump.name = "Pelusa_%d" % idx
	clump.texture = tex
	clump.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clump.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	clump.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	clump.custom_minimum_size = clump_size
	clump.size = clump_size
	clump.position = pos
	clump.pivot_offset = clump_size * 0.5
	clump.rotation_degrees = rot
	clump.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	clump.mouse_filter = Control.MOUSE_FILTER_PASS
	
	clump.gui_input.connect(func(event): _on_clump_gui_input(clump, event))
	clump.set_meta("cleaned", false)
	
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
	
	var is_ram: bool = "ram" in target_component.to_lower()
	var comp_name: String = "Memoria RAM" if is_ram else "Disipador"
	if cleaned_clumps < total_clumps:
		status_label.text = "Pasa la brocha o haz clic sobre cada cúmulo de pelusa para limpiar la %s." % comp_name
	else:
		status_label.text = "✓ ¡%s COMPLETAMENTE DESOBSTRUIDA! Limpieza al 100%%." % comp_name.to_upper()

func _trigger_victory() -> void:
	is_game_completed = true
	victory_banner.visible = true
	var is_ram: bool = "ram" in target_component.to_lower()
	var comp_name: String = "Memoria RAM" if is_ram else "Disipador"
	warning_label.text = "✓ ¡Mantenimiento completado! %s al 100%% limpia y libre de obstrucciones." % comp_name
	warning_label.modulate = Color(0.2, 1.0, 0.5)
	
	btn_cancel.text = "✓ FINALIZAR MANTENIMIENTO"
	btn_cancel.modulate = Color(0.2, 1.0, 0.5)
	
	# Destello de éxito en el área de trabajo
	var tw = create_tween().set_parallel(true)
	tw.tween_property(heatsink_area, "modulate", Color(1.3, 1.4, 1.2), 0.25)
	tw.chain().tween_property(heatsink_area, "modulate", Color.WHITE, 0.4)

func _on_cancel_pressed() -> void:
	minigame_finished.emit(is_game_completed)
