extends CanvasLayer

signal minigame_finished(success: bool)

const DIALOG_BOX_SCENE: PackedScene = preload("res://scenes/ui/DialogBox.tscn")

@export var is_tutorial_mode: bool = true

# Nodos UI
@onready var modal_control: Control = $ModalControl
@onready var work_area: Control = $ModalControl/WorkArea
@onready var progress_bar: ProgressBar = $ModalControl/Header/ProgressBarContainer/ProgressBar
@onready var lbl_percentage: Label = $ModalControl/Header/ProgressBarContainer/LblPercentage
@onready var lbl_status: Label = $ModalControl/Header/LblStatus
@onready var btn_salir: Button = $ModalControl/Footer/BtnSalir

# Nodos de Trabajo
@onready var screwdriver_sprite: TextureRect = $ModalControl/WorkArea/Screwdriver
@onready var ground_contact: Control = $ModalControl/WorkArea/GroundContact
@onready var sparks_canvas: Control = $ModalControl/WorkArea/SparksCanvas
@onready var ram_cursor: Control = $ModalControl/WorkArea/RAMCursor
@onready var ram_sprite: TextureRect = $ModalControl/WorkArea/RAMCursor/RAMSprite
@onready var ram_glow: TextureRect = $ModalControl/WorkArea/RAMCursor/RAMGlow
@onready var victory_panel: PanelContainer = $ModalControl/VictoryPanel
@onready var btn_repeat: Button = $ModalControl/VictoryPanel/Margin/VBox/Buttons/BtnRepeat
@onready var btn_finish: Button = $ModalControl/VictoryPanel/Margin/VBox/Buttons/BtnFinish

# Parámetros del Destornillador (Puntos del vástago de metal para frotar)
var shaft_start_local: Vector2 = Vector2(0, -30) # Cerca del mango
var shaft_end_local: Vector2 = Vector2(0, 140)   # Punta metálica de pala
var screwdriver_center: Vector2 = Vector2(580, 380)
var screwdriver_angle_deg: float = -35.0

# Estado de Estática
var static_charge: float = 100.0
var max_charge: float = 100.0
var is_completed: bool = false
var is_finishing: bool = false
var is_intro_active: bool = false
var countdown_overlay: CanvasLayer = null
var dialog_box_inst: Control = null
var prev_mouse_pos: Vector2 = Vector2.ZERO
var is_touching_screwdriver: bool = false

# Sistema de Chispas / Partículas
var active_sparks: Array[Dictionary] = []
var spark_sound_timer: float = 0.0
var had_sparks: bool = false
var spark_rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Audio synth
var asp_spark: AudioStreamPlayer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	btn_salir.pressed.connect(_on_salir_pressed)
	btn_repeat.pressed.connect(_on_repeat_pressed)
	btn_finish.pressed.connect(_on_finish_pressed)
	
	victory_panel.visible = false
	victory_panel.modulate.a = 0.0
	
	spark_rng.randomize()
	_setup_audio()
	_setup_positions()
	
	sparks_canvas.draw.connect(_on_sparks_draw)
	
	prev_mouse_pos = work_area.get_local_mouse_position()
	
	if get_tree().current_scene == self:
		_start_joa_intro()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _start_joa_intro() -> void:
	is_intro_active = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ram_cursor.visible = false
	
	if DIALOG_BOX_SCENE:
		dialog_box_inst = DIALOG_BOX_SCENE.instantiate()
		if is_instance_valid(work_area):
			work_area.add_child(dialog_box_inst)
		else:
			add_child(dialog_box_inst)
		if dialog_box_inst.has_method("show_message"):
			dialog_box_inst.show_message(
				"JOA",
				"¡Cuidado con la estática! Una descarga electrostática imperceptible puede freír un chip de memoria RAM.\n\nToma el módulo de memoria y frótalo con firmeza contra la varilla metálica del destornillador aterrizado a tierra hasta drenar la carga a cero.",
				func():
					_start_countdown(),
				true
			)
		else:
			_start_countdown()
	else:
		_start_countdown()

func _start_countdown() -> void:
	if countdown_overlay:
		countdown_overlay.queue_free()

	countdown_overlay = CanvasLayer.new()
	countdown_overlay.layer = 110
	add_child(countdown_overlay)

	var root_ctrl = Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	countdown_overlay.add_child(root_ctrl)

	var dim_rect = ColorRect.new()
	dim_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim_rect.color = Color(0.01, 0.03, 0.08, 0.55)
	dim_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(dim_rect)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(center)

	var label = Label.new()
	label.text = ""
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 120)
	label.pivot_offset = Vector2(160, 80)
	center.add_child(label)

	var steps: Array[Dictionary] = [
		{"text": "3", "color": Color(0.85, 0.25, 1.0), "size": 130, "pitch": 1.0},
		{"text": "2", "color": Color(1.0, 0.9, 0.2),  "size": 130, "pitch": 1.25},
		{"text": "1", "color": Color(1.0, 0.55, 0.1), "size": 130, "pitch": 1.5},
		{"text": "¡A DESCARGAR!", "color": Color(0.2, 1.0, 0.5), "size": 95, "pitch": 1.8}
	]

	_run_countdown_step(0, steps, label, root_ctrl)

func _run_countdown_step(index: int, steps: Array[Dictionary], label: Label, root_ctrl: Control) -> void:
	if index >= steps.size():
		var fade_tw = create_tween()
		fade_tw.tween_property(root_ctrl, "modulate:a", 0.0, 0.3)
		fade_tw.chain().tween_callback(func():
			if countdown_overlay:
				countdown_overlay.queue_free()
				countdown_overlay = null
			is_intro_active = false
			ram_cursor.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
			prev_mouse_pos = work_area.get_local_mouse_position()
		)
		return

	var st = steps[index]
	label.text = st["text"]
	label.modulate = st["color"]
	label.add_theme_font_size_override("font_size", st["size"])
	label.scale = Vector2(0.4, 0.4)
	label.modulate.a = 0.0

	if asp_spark:
		asp_spark.pitch_scale = st["pitch"]
		asp_spark.play()

	var tw = create_tween().set_parallel(true)
	tw.tween_property(label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 1.0, 0.15)
	tw.chain().tween_interval(0.4)
	tw.chain().tween_callback(func():
		_run_countdown_step(index + 1, steps, label, root_ctrl)
	)

func _setup_audio() -> void:
	asp_spark = AudioStreamPlayer.new()
	asp_spark.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	var click_res = load("res://efectos/teclado_click.wav")
	if click_res:
		asp_spark.stream = click_res
	add_child(asp_spark)

func _setup_positions() -> void:
	screwdriver_sprite.rotation_degrees = screwdriver_angle_deg
	screwdriver_sprite.pivot_offset = screwdriver_sprite.size * 0.5
	screwdriver_sprite.position = screwdriver_center - screwdriver_sprite.pivot_offset
	
	# La punta del destornillador se ubica en el contacto de tierra
	var tip_global = _get_shaft_end_world()
	ground_contact.position = tip_global - Vector2(ground_contact.size.x * 0.5, 0.0)

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float) -> void:
	spark_sound_timer -= delta
	
	# Actualizar partículas de chispas
	for i in range(active_sparks.size() - 1, -1, -1):
		var spk = active_sparks[i]
		spk["pos"] += spk["vel"] * delta
		spk["life"] -= delta * spk["decay"]
		if spk["life"] <= 0.0:
			active_sparks.remove_at(i)
	
	# Solo redibujar mientras haya chispas (o en el último frame en que desaparecen).
	var has_sparks = not active_sparks.is_empty()
	if has_sparks or had_sparks or is_touching_screwdriver:
		sparks_canvas.queue_redraw()
	had_sparks = has_sparks
	
	# Mover el sprite de RAM con el cursor del mouse
	var mouse_pos = work_area.get_local_mouse_position()
	ram_cursor.position = mouse_pos
	
	if is_completed or is_intro_active:
		return
		
	# Calcular movimiento y frotado
	var mouse_delta = mouse_pos - prev_mouse_pos
	prev_mouse_pos = mouse_pos
	
	# Comprobar contacto entre la RAM y la varilla metálica
	var shaft_a = _get_shaft_start_world()
	var shaft_b = _get_shaft_end_world()
	
	var closest_pt = Geometry2D.get_closest_point_to_segment(mouse_pos, shaft_a, shaft_b)
	var dist = mouse_pos.distance_to(closest_pt)
	
	# La RAM tiene un ancho de ~190 y altura ~70
	var contact_threshold = 65.0
	is_touching_screwdriver = (dist < contact_threshold)
	
	if is_touching_screwdriver:
		var speed = mouse_delta.length()
		if speed > 1.5:
			# Frotado activo!
			var discharge_amount = speed * 0.095
			static_charge = maxf(0.0, static_charge - discharge_amount)
			_spawn_sparks(closest_pt, mouse_pos)
			_play_spark_sound()
			
			if static_charge <= 0.0:
				_on_static_fully_discharged()
	
	_update_ui()

func _get_shaft_start_world() -> Vector2:
	return screwdriver_center + shaft_start_local.rotated(deg_to_rad(screwdriver_angle_deg))

func _get_shaft_end_world() -> Vector2:
	return screwdriver_center + shaft_end_local.rotated(deg_to_rad(screwdriver_angle_deg))

func _spawn_sparks(contact_pt: Vector2, ram_pt: Vector2) -> void:
	var rng = spark_rng
	
	# Chispas en el punto de contacto
	for i in range(3):
		var angle = rng.randf_range(0, TAU)
		var spd = rng.randf_range(60.0, 220.0)
		active_sparks.append({
			"pos": contact_pt + Vector2(rng.randf_range(-6, 6), rng.randf_range(-6, 6)),
			"vel": Vector2(cos(angle), sin(angle)) * spd,
			"color": Color(1.0, rng.randf_range(0.8, 1.0), 0.2, 1.0),
			"life": 1.0,
			"decay": rng.randf_range(3.5, 6.0),
			"size": rng.randf_range(1.8, 3.8)
		})
		
	# Pequeño arco conductor descendiendo hacia la tierra
	var tip_pt = _get_shaft_end_world()
	if rng.randf() < 0.35:
		active_sparks.append({
			"pos": tip_pt + Vector2(rng.randf_range(-8, 8), rng.randf_range(-2, 10)),
			"vel": Vector2(rng.randf_range(-20, 20), rng.randf_range(30, 90)),
			"color": Color(0.2, 1.0, 0.8, 0.9),
			"life": 1.0,
			"decay": 5.0,
			"size": 2.2
		})

func _play_spark_sound() -> void:
	if spark_sound_timer <= 0.0 and asp_spark:
		spark_sound_timer = 0.07 # Throttle para sonido natural de crepitar
		asp_spark.pitch_scale = randf_range(1.6, 2.4)
		asp_spark.play()

func _update_ui() -> void:
	var pct = (static_charge / max_charge) * 100.0
	progress_bar.value = pct
	lbl_percentage.text = "%.1f %%" % pct
	
	# Visual del resplandor estático de la RAM
	if ram_glow:
		var intensity = (static_charge / max_charge)
		ram_glow.modulate = Color(1.0, 0.9, 0.2, intensity * 0.75)
		
	if is_touching_screwdriver and static_charge > 0.0:
		lbl_status.text = "⚡ ¡FROTANDO A TIERRA! Disipando carga electrostática..."
		lbl_status.modulate = Color(1.0, 0.9, 0.2)
	elif static_charge > 0.0:
		lbl_status.text = "👉 Frota la memoria RAM contra el destornillador metálico tocando tierra."
		lbl_status.modulate = Color(0.7, 0.85, 1.0)

func _on_sparks_draw() -> void:
	# Dibujar chispas y arcos eléctricos
	for spk in active_sparks:
		var col = spk["color"]
		col.a = spk["life"]
		sparks_canvas.draw_circle(spk["pos"], spk["size"], col)
		
	# Si está frotando activamente, dibujar micro-arcos tipo rayo entre RAM y el vástago
	if is_touching_screwdriver and not is_completed:
		var shaft_a = _get_shaft_start_world()
		var shaft_b = _get_shaft_end_world()
		var closest_pt = Geometry2D.get_closest_point_to_segment(ram_cursor.position, shaft_a, shaft_b)
		
		# Arco eléctrico
		var points = PackedVector2Array()
		var segs = 4
		for s in range(segs + 1):
			var t = float(s) / float(segs)
			var base_pt = ram_cursor.position.lerp(closest_pt, t)
			if s > 0 and s < segs:
				base_pt += Vector2(randf_range(-6, 6), randf_range(-6, 6))
			points.append(base_pt)
		sparks_canvas.draw_polyline(points, Color(1.0, 0.95, 0.4, 0.8), 2.0)
		sparks_canvas.draw_polyline(points, Color.WHITE, 1.0)

func _on_static_fully_discharged() -> void:
	if is_completed or is_finishing:
		return
	is_completed = true
	is_finishing = true
	static_charge = 0.0
	_update_ui()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	btn_repeat.disabled = true
	btn_finish.disabled = true
	
	# Sonido triunfal
	var asp_win = AudioStreamPlayer.new()
	asp_win.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	var win_res = load("res://efectos/sonido de entrada.ogg")
	if win_res:
		asp_win.stream = win_res
		asp_win.pitch_scale = 1.25
	add_child(asp_win)
	asp_win.play()
	
	lbl_status.text = "✓ ¡ESTÁTICA TOTALMENTE DISIPADA! (0.0%)"
	lbl_status.modulate = Color(0.2, 1.0, 0.5)
	
	if ram_glow:
		# Destello verde de éxito
		ram_glow.modulate = Color(0.2, 1.0, 0.5, 0.85)
		var glow_tw = create_tween()
		glow_tw.tween_property(ram_glow, "modulate:a", 0.0, 0.8)
		
	# Guardar progreso en SaveManager
	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		sm.mark_node_completed("reparacion", 27) # Nivel morado: Descarga Estática RAM
		sm.mark_node_completed("reparacion", 2)  # Tutorial RAM compatibilidad
		sm.unlock_glossary("ram")
		
	# Sin cartel final: al vaciarse la barra el minijuego termina de inmediato.
	_finalize_success()

func _finalize_success() -> void:
	if not is_finishing:
		return
	is_finishing = false
	minigame_finished.emit(true)

	if get_tree().current_scene == self:
		CyberPlayTransition.play_exit(
			get_tree(),
			"reparacion",
			"res://scenes/menus/LevelSelect.tscn",
			"DESCARGA DE ESTÁTICA COMPLETADA",
			"// CARGA ELECTROSTÁTICA DISIPADA A TIERRA //"
		)
	else:
		queue_free()

func _on_repeat_pressed() -> void:
	if is_finishing:
		return
	static_charge = 100.0
	is_completed = false
	active_sparks.clear()
	victory_panel.visible = false
	victory_panel.modulate.a = 0.0
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	prev_mouse_pos = work_area.get_local_mouse_position()

func _on_finish_pressed() -> void:
	if is_finishing:
		return
	is_finishing = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_finalize_success()

func _on_salir_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	minigame_finished.emit(false)
	
	if get_tree().current_scene == self:
		get_tree().change_scene_to_file("res://scenes/menus/LevelSelect.tscn")
	else:
		queue_free()
