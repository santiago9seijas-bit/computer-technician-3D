class_name CyberPlayTransition
extends CanvasLayer

signal transition_completed

# =============================================================================
# CINEMÁTICA Y ANIMACIÓN DE ENTRADA CIBERNÉTICA DE ALTO IMPACTO (PLAY / INICIAR)
# SOPORTA MODO NIVEL (ROJO), MODO TUTORIAL (AZUL) Y MODO PRÁCTICA (NARANJA)
# AUDIO REPRODUCIDO ÚNICAMENTE 1 VEZ AL INICIAR
# =============================================================================

var _tree: SceneTree = null
var _target_scene: String = ""
var _title_text: String = ""
var _subtitle_text: String = ""
var _on_finished: Callable = Callable()
var _is_tutorial: bool = false
var _is_practice: bool = false
var _mode: String = ""
var _is_exit: bool = false
var _transition_type: String = "normal"

# Variables de estado para la cinemática de error glitch sincronizada con audio
var _glitch_active: bool = false
var _glitch_time: float = 0.0
var _glitch_bar_timer: float = 0.0
var _glitch_total_duration: float = 4.63
var _glitch_photo_factor: float = 1.0
var _glitch_screen_w: float = 1280.0
var _glitch_screen_h: float = 720.0
var _glitch_audio_player: AudioStreamPlayer = null
var _glitch_root_ctrl: Control = null
var _glitch_shake_ctrl: Control = null
var _glitch_bg: ColorRect = null
var _glitch_panel: PanelContainer = null
var _glitch_bars: Array[ColorRect] = []
var _glitch_target_scene: String = ""
var _glitch_scene_swapped: bool = false
var _glitch_on_finished: Callable = Callable()

static func play(
	tree: SceneTree,
	target_scene_path: String,
	title_text: String = "INICIALIZANDO SIMULACIÓN",
	subtitle_text: String = "// ENLACE NEURONAL CON TALLER TÉCNICO //",
	on_finished: Callable = Callable(),
	is_tutorial: bool = false,
	is_practice: bool = false,
	mode: String = "",
	is_exit: bool = false
) -> void:
	if not tree or not tree.root:
		return
		
	var old = tree.root.get_node_or_null("CyberPlayTransition")
	if old:
		old.queue_free()
	var old_glitch = tree.root.get_node_or_null("GlitchAudioPlayer")
	if old_glitch:
		old_glitch.queue_free()
		
	# Iniciar la carga en segundo plano (threaded loading) inmediatamente
	# para que los modelos, texturas y shaders de la escena destino se precarguen sin congelar el hilo principal.
	if target_scene_path != "":
		ResourceLoader.load_threaded_request(target_scene_path)
		
	var resolved_mode = mode.to_lower()
	if resolved_mode == "" and target_scene_path != "":
		var low_path = target_scene_path.to_lower()
		if "system" in low_path:
			resolved_mode = "sistema"
		elif "server" in low_path:
			resolved_mode = "servidor"
		elif "level1" in low_path or "reparacion" in low_path:
			resolved_mode = "reparacion"
		elif is_tutorial:
			resolved_mode = "sistema"
		elif is_practice:
			resolved_mode = "servidor"

	var transition = CyberPlayTransition.new()
	transition.name = "CyberPlayTransition"
	transition.layer = 150 # Por encima de cualquier interfaz, modal o HUD
	transition.process_mode = Node.PROCESS_MODE_ALWAYS
	transition._tree = tree
	transition._target_scene = target_scene_path
	transition._title_text = title_text
	transition._subtitle_text = subtitle_text
	transition._on_finished = on_finished
	transition._is_tutorial = is_tutorial
	transition._is_practice = is_practice
	transition._mode = resolved_mode
	transition._is_exit = is_exit
	tree.root.call_deferred("add_child", transition)

static func play_exit(
	tree: SceneTree,
	mode: String = "reparacion",
	target_scene_path: String = "res://scenes/menus/LevelSelect.tscn",
	title_text: String = "",
	subtitle_text: String = "",
	on_finished: Callable = Callable()
) -> void:
	if not tree or not tree.root:
		return
	var m = mode.to_lower()
	if title_text == "":
		if m == "sistema":
			title_text = "DESCONECTANDO ESTACIÓN DE SISTEMAS"
		elif m == "servidor":
			title_text = "DESCONECTANDO DATACENTER CORPORATIVO"
		elif m == "tutorial":
			title_text = "DESCONECTANDO NÚCLEO TUTORIAL"
		elif m == "practica":
			title_text = "DESCONECTANDO SALA DE PRÁCTICA"
		else:
			title_text = "DESCONECTANDO TALLER DE REPARACIÓN"
			
	if subtitle_text == "":
		if m == "sistema":
			subtitle_text = "// RETORNANDO A LA MATRIZ DE SISTEMAS · STATUS: 200 OK //"
		elif m == "servidor":
			subtitle_text = "// RETORNANDO A LA INFRAESTRUCTURA DE SERVIDOR · STATUS: 200 OK //"
		elif m == "tutorial":
			subtitle_text = "// TUTORIAL FINALIZADO · RETORNANDO AL SELECTOR //"
		elif m == "practica":
			subtitle_text = "// PRÁCTICA FINALIZADA · RETORNANDO AL SELECTOR //"
		else:
			subtitle_text = "// RETORNANDO A LA MATRIZ DE HARDWARE · STATUS: 200 OK //"

	if m in ["reparacion", "sistema", "servidor"]:
		LevelSelect.initial_mode = m
		LevelSelect.initial_tab = "niveles"
	elif m == "tutorial":
		var gm = tree.root.get_node_or_null("GameManager")
		if gm and "current_mode" in gm and gm.current_mode in ["reparacion", "sistema", "servidor"]:
			LevelSelect.initial_mode = gm.current_mode
		LevelSelect.initial_tab = "niveles"

	play(tree, target_scene_path, title_text, subtitle_text, on_finished, (m == "tutorial"), (m == "practica"), m, true)

static func play_error_glitch(
	tree: SceneTree,
	target_scene_path: String = "res://scenes/menus/SaveSlotsMenu.tscn",
	on_finished: Callable = Callable()
) -> void:
	if not tree or not tree.root:
		return
	var old = tree.root.get_node_or_null("CyberPlayTransition")
	if old:
		old.queue_free()
	var old_glitch = tree.root.get_node_or_null("GlitchAudioPlayer")
	if old_glitch:
		old_glitch.queue_free()
	if target_scene_path != "":
		ResourceLoader.load_threaded_request(target_scene_path)
	var transition = CyberPlayTransition.new()
	transition.name = "CyberPlayTransition"
	transition.layer = 160
	transition.process_mode = Node.PROCESS_MODE_ALWAYS
	transition._tree = tree
	transition._target_scene = target_scene_path
	transition._on_finished = on_finished
	transition._transition_type = "error"
	tree.root.call_deferred("add_child", transition)

static func play_code_restored(
	tree: SceneTree,
	target_scene_path: String = "res://scenes/menus/MainMenu.tscn",
	on_finished: Callable = Callable()
) -> void:
	if not tree or not tree.root:
		return
	var old = tree.root.get_node_or_null("CyberPlayTransition")
	if old:
		old.queue_free()
	var old_glitch = tree.root.get_node_or_null("GlitchAudioPlayer")
	if old_glitch:
		old_glitch.queue_free()
	if target_scene_path != "":
		ResourceLoader.load_threaded_request(target_scene_path)
	var transition = CyberPlayTransition.new()
	transition.name = "CyberPlayTransition"
	transition.layer = 160
	transition.process_mode = Node.PROCESS_MODE_ALWAYS
	transition._tree = tree
	transition._target_scene = target_scene_path
	transition._on_finished = on_finished
	transition._transition_type = "restored"
	tree.root.call_deferred("add_child", transition)

func _ready() -> void:
	if _transition_type == "error":
		_start_error_glitch_sequence(_tree if _tree else get_tree(), _target_scene, _on_finished)
	elif _transition_type == "restored":
		set_process(false)
		_start_code_restored_sequence(_tree if _tree else get_tree(), _target_scene, _on_finished)
	else:
		set_process(false)
		_start_sequence(_tree if _tree else get_tree(), _target_scene, _title_text, _subtitle_text, _on_finished)

func _exit_tree() -> void:
	_glitch_active = false
	if _glitch_audio_player and is_instance_valid(_glitch_audio_player):
		_glitch_audio_player.queue_free()

func _process(delta: float) -> void:
	if not _glitch_active:
		return

	_glitch_time += delta
	_glitch_bar_timer += delta
	var progress: float = clampf(_glitch_time / _glitch_total_duration, 0.0, 1.0)
	var t_swap: float = minf(1.5, _glitch_total_duration * 0.33)

	# FASE 2: Entrada a la zona de sets de guardado (SaveSlotsMenu) y disolución del cartel de error
	if _glitch_time >= t_swap and not _glitch_scene_swapped:
		_glitch_scene_swapped = true
		var tree = _tree if _tree else get_tree()
		if tree and _glitch_target_scene != "":
			tree.change_scene_to_file(_glitch_target_scene)

		# Permitir al jugador interactuar con la zona de sets mientras el glitch se va quitando poco a poco
		if is_instance_valid(_glitch_root_ctrl):
			_glitch_root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Desvanecer en paralelo el recuadro del error y el fondo oscuro
		var tw_reveal = create_tween().set_parallel(true)
		if is_instance_valid(_glitch_panel):
			tw_reveal.tween_property(_glitch_panel, "modulate:a", 0.0, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if is_instance_valid(_glitch_bg):
			tw_reveal.tween_property(_glitch_bg, "modulate:a", 0.0, 0.50).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		# Destello cibernético suave al cambiar de escena
		if is_instance_valid(_glitch_root_ctrl):
			var flash = ColorRect.new()
			flash.set_anchors_preset(Control.PRESET_FULL_RECT)
			flash.color = Color(1.0, 0.15, 0.3, 0.40 * _glitch_photo_factor)
			flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_glitch_root_ctrl.add_child(flash)
			var tw_flash = create_tween()
			tw_flash.tween_property(flash, "color:a", 0.0, 0.22)
			tw_flash.tween_callback(flash.queue_free)

	# Calcular intensidad del glitch: al inicio al 100%, y a partir de t_swap se disipa poco a poco
	var glitch_intensity: float
	if _glitch_time < t_swap:
		glitch_intensity = 1.0
	else:
		var decay_progress = (_glitch_time - t_swap) / maxf(_glitch_total_duration - t_swap, 0.01)
		# Curva suave para que el glitch se vaya atenuando en sincronía con el sonido
		glitch_intensity = clampf(pow(1.0 - decay_progress, 1.5), 0.0, 1.0)

	# 1. Sacudida de pantalla (shake) proporcional a la intensidad restante
	if is_instance_valid(_glitch_shake_ctrl):
		if glitch_intensity > 0.02:
			var max_sx = 12.0 * glitch_intensity * _glitch_photo_factor
			var max_sy = 7.0 * glitch_intensity * _glitch_photo_factor
			_glitch_shake_ctrl.position = Vector2(randf_range(-max_sx, max_sx), randf_range(-max_sy, max_sy))
		else:
			_glitch_shake_ctrl.position = Vector2.ZERO

	# 2. Barras horizontales de glitch (actualizadas a ~25 FPS para máxima eficiencia y auténtica estética retro)
	if _glitch_bar_timer >= 0.04:
		_glitch_bar_timer = 0.0
		for i in range(_glitch_bars.size()):
			var bar = _glitch_bars[i]
			if not is_instance_valid(bar):
				continue
			if glitch_intensity > 0.03:
				bar.visible = true
				var bar_h = randf_range(2.0, lerpf(4.0, 36.0, glitch_intensity))
				var bar_y = randf_range(0.0, _glitch_screen_h - bar_h)
				bar.size = Vector2(_glitch_screen_w, bar_h)
				bar.position = Vector2(randf_range(-30.0, 30.0) * glitch_intensity, bar_y)
				var base_alpha = randf_range(0.12, 0.50) * glitch_intensity * _glitch_photo_factor
				bar.color = Color(1.0, 0.05, 0.25, base_alpha) if (i % 2 == 0) else Color(0.1, 0.85, 1.0, base_alpha)
			elif bar.visible:
				bar.visible = false

	# 3. Desvanecimiento del audio en el tramo final ("según el sonido se vaya")
	if is_instance_valid(_glitch_audio_player) and _glitch_audio_player.playing:
		if progress >= 0.75:
			var fade_ratio = (progress - 0.75) / 0.25
			_glitch_audio_player.volume_db = lerpf(-9.0, -45.0, fade_ratio)

	# 4. Finalización total cuando concluye la duración del audio
	if progress >= 1.0:
		_glitch_active = false
		set_process(false)
		if is_instance_valid(_glitch_audio_player):
			_glitch_audio_player.queue_free()
		if _glitch_on_finished.is_valid():
			_glitch_on_finished.call()
		transition_completed.emit()
		queue_free()

func _input(event: InputEvent) -> void:
	var is_esc = (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE)
	var is_pause = event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")
	if is_esc or is_pause:
		get_viewport().set_input_as_handled()

# Sonido de entrada / salida de nivel según el modo
func _play_entry_sfx() -> float:
	var sfx_path = "res://efectos/sonido de entrada.ogg"
	if not ResourceLoader.exists(sfx_path):
		return 1.105
	var stream = load(sfx_path)
	if not stream:
		return 1.105
	if stream is AudioStreamOggVorbis:
		stream.loop = false
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = 0.0
	if _is_exit:
		player.pitch_scale = 0.85 # Tono modificado para desconexión
	else:
		player.pitch_scale = 1.0 # Tono natural perfecto al entrar, claro y sin distorsión
	player.bus = "Master"
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
	var dur = stream.get_length() / player.pitch_scale
	return maxf(dur, 0.5)

func _start_sequence(
	tree: SceneTree,
	target_scene_path: String,
	title_text: String,
	subtitle_text: String,
	on_finished: Callable
) -> void:
	# Contenedor raíz a pantalla completa
	var root_ctrl = Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root_ctrl)
	
	# Reproducir el audio una única vez aquí al inicio y sincronizar la transición con su duración exacta
	var sound_duration = _play_entry_sfx()
	var t_close = sound_duration * 0.28
	var t_swap  = sound_duration * 0.44
	var t_open  = sound_duration * 0.28
	
	var screen_w = root_ctrl.size.x if root_ctrl.size.x > 0 else 1280.0
	var screen_h = root_ctrl.size.y if root_ctrl.size.y > 0 else 720.0
	var half_h = screen_h * 0.5
	
	# Paletas de color según el modo (Reparación = Rojo / Sistemas = Azul / Servidor = Naranja)
	var theme_primary_col: Color
	var theme_accent_col: Color
	var theme_bg_shutter: Color
	var theme_shadow_col: Color
	
	if _mode == "servidor" or _is_practice:
		theme_primary_col = Color(1.0, 0.55, 0.08, 1.0) # Naranja Neón Datacenter
		theme_accent_col  = Color(1.0, 0.85, 0.35, 1.0)
		theme_bg_shutter  = Color(0.04, 0.02, 0.01, 0.98)
		theme_shadow_col  = Color(1.0, 0.5, 0.0, 0.55)
	elif _mode == "sistema" or _is_tutorial:
		theme_primary_col = Color(0.18, 0.55, 1.0, 1.0)  # Azul Eléctrico y Cian
		theme_accent_col  = Color(0.55, 0.88, 1.0, 1.0)
		theme_bg_shutter  = Color(0.015, 0.035, 0.09, 0.98)
		theme_shadow_col  = Color(0.15, 0.50, 1.0, 0.55)
	else:
		theme_primary_col = Color(1.0, 0.08, 0.25, 1.0) # Rojo Carmesí Neón
		theme_accent_col  = Color(1.0, 0.40, 0.55, 1.0)
		theme_bg_shutter  = Color(0.04, 0.012, 0.08, 0.98)
		theme_shadow_col  = Color(1.0, 0.05, 0.2, 0.45)
	
	# Fondo oscurecido
	var bg_overlay = ColorRect.new()
	bg_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_overlay.color = Color(0.01, 0.01, 0.02, 0.0)
	bg_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(bg_overlay)
	
	# -------------------------------------------------------------------------
	# MATRIZ Y ELEMENTOS HOLOGRAMA (RETÍCULAS Y LÍNEAS DE ESCANEO)
	# -------------------------------------------------------------------------
	var hologram_layer = Control.new()
	hologram_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	hologram_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hologram_layer.modulate.a = 0.0
	root_ctrl.add_child(hologram_layer)
	
	# Rejilla holográfica sutil
	for y_step in range(0, int(screen_h), 32):
		var grid_line = ColorRect.new()
		grid_line.color = Color(theme_primary_col.r, theme_primary_col.g, theme_primary_col.b, 0.08)
		grid_line.size = Vector2(screen_w, 1.0)
		grid_line.position = Vector2(0.0, float(y_step))
		hologram_layer.add_child(grid_line)
		
	# Brackets y marcas holográficas en las 4 esquinas
	var corner_margin = 28.0
	var corner_size = 40.0
	
	var label_tl = "[+ REPARACIÓN.INIT]"
	var label_tr = "[RED.SYS // +]"
	var label_br = "[OVERRIDE.OK +]"
	if _mode == "servidor" or _is_practice:
		label_tl = "[+ SERVIDOR.INIT]"
		label_tr = "[ORANGE.SYS // +]"
		label_br = "[DATACENTER.OK +]"
	elif _mode == "sistema" or _is_tutorial:
		label_tl = "[+ SISTEMAS.INIT]"
		label_tr = "[BLUE.SYS // +]"
		label_br = "[KERNEL.OK +]"
	
	var corner_positions = [
		{"pos": Vector2(corner_margin, corner_margin), "label": label_tl},
		{"pos": Vector2(screen_w - corner_margin - corner_size, corner_margin), "label": label_tr},
		{"pos": Vector2(corner_margin, screen_h - corner_margin - corner_size), "label": "[+ PWR.NEXUS]"},
		{"pos": Vector2(screen_w - corner_margin - corner_size, screen_h - corner_margin - corner_size), "label": label_br}
	]
	
	for cp in corner_positions:
		var c_rect = Panel.new()
		c_rect.position = cp["pos"]
		c_rect.size = Vector2(corner_size, corner_size)
		c_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var csb = StyleBoxFlat.new()
		csb.draw_center = false
		csb.border_color = theme_primary_col
		csb.set_border_width_all(2)
		csb.shadow_color = theme_shadow_col
		csb.shadow_size = 6
		c_rect.add_theme_stylebox_override("panel", csb)
		hologram_layer.add_child(c_rect)
		
		var clbl = Label.new()
		clbl.text = cp["label"]
		clbl.add_theme_color_override("font_color", theme_primary_col)
		clbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		clbl.add_theme_constant_override("outline_size", 4)
		clbl.add_theme_font_size_override("font_size", 9)
		clbl.position = cp["pos"] + Vector2(0, corner_size + 4.0)
		hologram_layer.add_child(clbl)
	
	# Retícula circular holográfica central
	var reticle_ctrl = Control.new()
	reticle_ctrl.position = Vector2(screen_w * 0.5, screen_h * 0.5)
	reticle_ctrl.scale = Vector2(0.2, 0.2)
	reticle_ctrl.modulate.a = 0.0
	reticle_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(reticle_ctrl)
	
	for r in [90.0, 140.0, 210.0]:
		var ring = Panel.new()
		ring.size = Vector2(r * 2.0, r * 2.0)
		ring.position = Vector2(-r, -r)
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var r_sb = StyleBoxFlat.new()
		r_sb.draw_center = false
		r_sb.border_color = theme_primary_col
		r_sb.set_border_width_all(1)
		r_sb.set_corner_radius_all(int(r))
		r_sb.shadow_color = theme_shadow_col
		r_sb.shadow_size = 8
		ring.add_theme_stylebox_override("panel", r_sb)
		reticle_ctrl.add_child(ring)
	
	# -------------------------------------------------------------------------
	# COMPUERTA SUPERIOR (SHUTTER TOP)
	# -------------------------------------------------------------------------
	var shutter_top = ColorRect.new()
	shutter_top.color = theme_bg_shutter
	shutter_top.size = Vector2(screen_w, half_h + 4.0)
	shutter_top.position = Vector2(0.0, -half_h - 10.0)
	shutter_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(shutter_top)
	
	var line_top = ColorRect.new()
	line_top.color = theme_primary_col
	line_top.size = Vector2(screen_w, 3.0)
	line_top.position = Vector2(0.0, half_h + 1.0)
	shutter_top.add_child(line_top)
	
	var accent_top = ColorRect.new()
	accent_top.color = theme_accent_col
	accent_top.size = Vector2(260.0, 3.0)
	accent_top.position = Vector2((screen_w - 260.0) * 0.5, half_h + 1.0)
	shutter_top.add_child(accent_top)
	
	var top_chevrons = Label.new()
	if _mode == "servidor":
		top_chevrons.text = ">>> [ COMPUERTA A // INFRAESTRUCTURA DATACENTER // MATRIZ NARANJA ] <<<"
	elif _mode == "sistema":
		top_chevrons.text = ">>> [ COMPUERTA A // GESTIÓN DE SISTEMAS // MATRIZ AZUL ] <<<"
	elif _mode == "reparacion":
		top_chevrons.text = ">>> [ COMPUERTA A // TALLER DE REPARACIÓN // MATRIZ ROJA ] <<<"
	elif _is_practice:
		top_chevrons.text = ">>> [ COMPUERTA A // NIVEL DE PRÁCTICA // TIEMPO INFINITO ] <<<"
	elif _is_tutorial:
		top_chevrons.text = ">>> [ COMPUERTA A // NÚCLEO TUTORIAL 3D // AISLAMIENTO NEURONAL ] <<<"
	else:
		top_chevrons.text = ">>> [ SYSTEM OVERRIDE // HOLOGRAMA ROJO ACTIVO // DIVERGENCIA NEURONAL ] <<<"
	top_chevrons.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_chevrons.position = Vector2(0.0, half_h - 22.0)
	top_chevrons.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_chevrons.add_theme_color_override("font_color", theme_primary_col)
	top_chevrons.add_theme_font_size_override("font_size", 10)
	shutter_top.add_child(top_chevrons)
	
	# -------------------------------------------------------------------------
	# COMPUERTA INFERIOR (SHUTTER BOTTOM)
	# -------------------------------------------------------------------------
	var shutter_bot = ColorRect.new()
	shutter_bot.color = theme_bg_shutter
	shutter_bot.size = Vector2(screen_w, half_h + 4.0)
	shutter_bot.position = Vector2(0.0, screen_h + 10.0)
	shutter_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(shutter_bot)
	
	var line_bot = ColorRect.new()
	line_bot.color = theme_primary_col
	line_bot.size = Vector2(screen_w, 3.0)
	line_bot.position = Vector2(0.0, 0.0)
	shutter_bot.add_child(line_bot)
	
	var accent_bot = ColorRect.new()
	accent_bot.color = theme_accent_col
	accent_bot.size = Vector2(260.0, 3.0)
	accent_bot.position = Vector2((screen_w - 260.0) * 0.5, 0.0)
	shutter_bot.add_child(accent_bot)
	
	var bot_chevrons = Label.new()
	if _mode == "servidor":
		bot_chevrons.text = "/// /// /// DATACENTER RACK // REDUNDANCIA SERVIDOR // COMPUERTA B /// /// ///"
	elif _mode == "sistema":
		bot_chevrons.text = "/// /// /// TERMINAL DE SISTEMAS // KERNEL SECURITY // COMPUERTA B /// /// ///"
	elif _mode == "reparacion":
		bot_chevrons.text = "/// /// /// HARDWARE LINK // VULKAN SHADER EMISSION // RED MATRIX /// /// ///"
	elif _is_practice:
		bot_chevrons.text = "/// /// /// TALLER DE PRÁCTICA // ENTRENAMIENTO LIBRE // COMPUERTA B /// /// ///"
	elif _is_tutorial:
		bot_chevrons.text = "/// /// /// SALA DE ENTRENAMIENTO // MODO GUIADO // COMPUERTA B /// /// ///"
	else:
		bot_chevrons.text = "/// /// /// HARDWARE LINK // VULKAN SHADER EMISSION // RED MATRIX // /// ///"
	bot_chevrons.set_anchors_preset(Control.PRESET_FULL_RECT)
	bot_chevrons.position = Vector2(0.0, 8.0)
	bot_chevrons.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bot_chevrons.add_theme_color_override("font_color", theme_primary_col)
	bot_chevrons.add_theme_font_size_override("font_size", 10)
	shutter_bot.add_child(bot_chevrons)
	
	# -------------------------------------------------------------------------
	# HAZ LÁSER ESCÁNER
	# -------------------------------------------------------------------------
	var laser_beam_main = ColorRect.new()
	laser_beam_main.color = theme_primary_col
	laser_beam_main.size = Vector2(screen_w, 5.0)
	laser_beam_main.position = Vector2(0.0, -10.0)
	laser_beam_main.mouse_filter = Control.MOUSE_FILTER_IGNORE
	laser_beam_main.modulate.a = 0.0
	root_ctrl.add_child(laser_beam_main)
	
	var laser_beam_sub = ColorRect.new()
	laser_beam_sub.color = theme_accent_col
	laser_beam_sub.size = Vector2(screen_w, 3.0)
	laser_beam_sub.position = Vector2(0.0, -10.0)
	laser_beam_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	laser_beam_sub.modulate.a = 0.0
	root_ctrl.add_child(laser_beam_sub)
	
	# Fuentes opcionales
	var font_bungee: Font = null
	if ResourceLoader.exists("res://assets/fonts/Bungee-Regular.ttf"):
		font_bungee = load("res://assets/fonts/Bungee-Regular.ttf")
		
	var font_mono: Font = null
	if ResourceLoader.exists("res://assets/fonts/JetBrainsMono-Bold.ttf"):
		font_mono = load("res://assets/fonts/JetBrainsMono-Bold.ttf")

	# Elementos de progreso y telemetría
	var prog_bar: ProgressBar = null
	var lbl_progress_val: Label = null
	var lbl_telemetry: Label = null
	var center_element: Control = null
	
	if (_is_tutorial or _is_practice) and _mode == "":
		# =====================================================================
		# CÍRCULO HOLOGRÁFICO (AZUL PARA TUTORIAL, NARANJA PARA PRÁCTICA)
		# =====================================================================
		var circle_center = Control.new()
		circle_center.custom_minimum_size = Vector2(380.0, 380.0)
		circle_center.size = Vector2(380.0, 380.0)
		circle_center.position = Vector2((screen_w - 380.0) * 0.5, (screen_h - 380.0) * 0.5)
		circle_center.pivot_offset = Vector2(190.0, 190.0)
		circle_center.scale = Vector2(0.2, 0.2)
		circle_center.modulate.a = 0.0
		circle_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root_ctrl.add_child(circle_center)
		center_element = circle_center
		
		# Anillo exterior
		var outer_circle = Panel.new()
		outer_circle.size = Vector2(210.0, 210.0)
		outer_circle.position = Vector2(85.0, 25.0)
		outer_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var oc_sb = StyleBoxFlat.new()
		oc_sb.draw_center = true
		oc_sb.bg_color = theme_bg_shutter
		oc_sb.border_color = theme_primary_col
		oc_sb.set_border_width_all(3)
		oc_sb.set_corner_radius_all(105)
		oc_sb.shadow_color = theme_shadow_col
		oc_sb.shadow_size = 20
		outer_circle.add_theme_stylebox_override("panel", oc_sb)
		circle_center.add_child(outer_circle)
		
		# Anillo interior concéntrico
		var inner_ring = Panel.new()
		inner_ring.size = Vector2(174.0, 174.0)
		inner_ring.position = Vector2(18.0, 18.0)
		inner_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ir_sb = StyleBoxFlat.new()
		ir_sb.draw_center = false
		ir_sb.border_color = theme_accent_col
		ir_sb.set_border_width_all(2)
		ir_sb.set_corner_radius_all(87)
		inner_ring.add_theme_stylebox_override("panel", ir_sb)
		outer_circle.add_child(inner_ring)

		# Núcleo holográfico central limpio
		var core_ring = Panel.new()
		core_ring.size = Vector2(100.0, 100.0)
		core_ring.position = Vector2(55.0, 55.0)
		core_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cr_sb = StyleBoxFlat.new()
		cr_sb.draw_center = true
		cr_sb.bg_color = Color(theme_primary_col.r, theme_primary_col.g, theme_primary_col.b, 0.16)
		cr_sb.border_color = theme_primary_col
		cr_sb.set_border_width_all(2)
		cr_sb.set_corner_radius_all(50)
		cr_sb.shadow_color = theme_shadow_col
		cr_sb.shadow_size = 14
		core_ring.add_theme_stylebox_override("panel", cr_sb)
		outer_circle.add_child(core_ring)
		
		var core_lbl = Label.new()
		core_lbl.text = "🛠" if _is_practice else "⚡"
		core_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		core_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		core_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		core_lbl.add_theme_font_size_override("font_size", 34)
		core_lbl.modulate = Color(1.2, 1.2, 1.3, 1.0)
		core_ring.add_child(core_lbl)
		
		# Títulos e indicador bajo el círculo
		var vbox_center = VBoxContainer.new()
		vbox_center.position = Vector2(0.0, 245.0)
		vbox_center.size = Vector2(380.0, 125.0)
		vbox_center.add_theme_constant_override("separation", 4)
		vbox_center.alignment = BoxContainer.ALIGNMENT_CENTER
		circle_center.add_child(vbox_center)
		
		var lbl_t = Label.new()
		lbl_t.text = "SALA DE PRÁCTICA 3D" if _is_practice else "NÚCLEO TUTORIAL 3D"
		if font_bungee:
			lbl_t.add_theme_font_override("font", font_bungee)
		lbl_t.add_theme_font_size_override("font_size", 18)
		lbl_t.add_theme_color_override("font_color", theme_primary_col)
		lbl_t.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		lbl_t.add_theme_constant_override("outline_size", 6)
		lbl_t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		lbl_t.add_theme_constant_override("shadow_outline_size", 8)
		lbl_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox_center.add_child(lbl_t)
		
		var lbl_sub = Label.new()
		lbl_sub.text = "// ENTRENAMIENTO LIBRE · BANCO DE TRABAJO //" if _is_practice else "// SALA DE ENTRENAMIENTO · INDUCCIÓN TÉCNICA //"
		if font_mono:
			lbl_sub.add_theme_font_override("font", font_mono)
		lbl_sub.add_theme_font_size_override("font_size", 10)
		lbl_sub.add_theme_color_override("font_color", theme_accent_col)
		lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox_center.add_child(lbl_sub)
		
		# Barra de progreso nativa (100% exacta)
		prog_bar = ProgressBar.new()
		prog_bar.custom_minimum_size = Vector2(320.0, 20.0)
		prog_bar.min_value = 0.0
		prog_bar.max_value = 100.0
		prog_bar.value = 0.0
		prog_bar.show_percentage = false
		
		var pb_bg = StyleBoxFlat.new()
		pb_bg.bg_color = Color(0.02, 0.03, 0.05, 0.95)
		pb_bg.border_color = theme_primary_col
		pb_bg.set_border_width_all(1)
		pb_bg.set_corner_radius_all(4)
		prog_bar.add_theme_stylebox_override("background", pb_bg)
		
		var pb_fill = StyleBoxFlat.new()
		pb_fill.bg_color = theme_primary_col
		pb_fill.set_corner_radius_all(3)
		prog_bar.add_theme_stylebox_override("fill", pb_fill)
		vbox_center.add_child(prog_bar)
		
		lbl_progress_val = Label.new()
		lbl_progress_val.text = "[ ENLAZANDO BANCO DE PRÁCTICA: 0% ]" if _is_practice else "[ ENLAZANDO BANCO DE TRABAJO: 0% ]"
		lbl_progress_val.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl_progress_val.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		lbl_progress_val.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		lbl_progress_val.add_theme_constant_override("outline_size", 4)
		lbl_progress_val.add_theme_font_size_override("font_size", 10)
		lbl_progress_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_progress_val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		prog_bar.add_child(lbl_progress_val)
		
		lbl_telemetry = Label.new()
		lbl_telemetry.text = "> PRÁCTICA_3D: CONFIGURANDO REPUESTOS Y COMPONENTES..." if _is_practice else "> INDUCCION_3D: VERIFICANDO PC DE PRUEBA Y REPUESTOS..."
		lbl_telemetry.add_theme_color_override("font_color", theme_accent_col)
		lbl_telemetry.add_theme_font_size_override("font_size", 9)
		lbl_telemetry.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox_center.add_child(lbl_telemetry)
	else:
		# ---------------------------------------------------------------------
		# TARJETA / HUD HOLOGRÁFICO CENTRAL CON ESTÉTICA ROJA CYBERPUNK (NIVELES)
		# ---------------------------------------------------------------------
		var card_center = PanelContainer.new()
		card_center.custom_minimum_size = Vector2(640.0, 225.0)
		card_center.size = Vector2(640.0, 225.0)
		card_center.position = Vector2((screen_w - 640.0) * 0.5, (screen_h - 225.0) * 0.5)
		card_center.pivot_offset = Vector2(320.0, 112.5)
		card_center.scale = Vector2(0.85, 0.85)
		card_center.modulate.a = 0.0
		card_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var card_sb = StyleBoxFlat.new()
		card_sb.bg_color = theme_bg_shutter
		card_sb.border_color = theme_primary_col
		card_sb.set_border_width_all(2)
		card_sb.set_corner_radius_all(8)
		card_sb.content_margin_left = 30.0
		card_sb.content_margin_right = 30.0
		card_sb.content_margin_top = 20.0
		card_sb.content_margin_bottom = 20.0
		card_sb.shadow_color = theme_shadow_col
		card_sb.shadow_size = 18
		card_center.add_theme_stylebox_override("panel", card_sb)
		root_ctrl.add_child(card_center)
		center_element = card_center
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		card_center.add_child(vbox)
		
		var mode_badge = Label.new()
		if _mode == "servidor":
			mode_badge.text = "[ 🖧 SERVIDOR // INFRAESTRUCTURA DATACENTER RACK 2U ]"
		elif _mode == "sistema":
			mode_badge.text = "[ 💻 SISTEMAS // ESTACIÓN KERNEL & TERMINALES ]"
		else:
			mode_badge.text = "[ 🛠 REPARACIÓN // LABORATORIO HARDWARE 3D ]"
		mode_badge.add_theme_color_override("font_color", theme_accent_col)
		mode_badge.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		mode_badge.add_theme_constant_override("outline_size", 4)
		mode_badge.add_theme_font_size_override("font_size", 10)
		mode_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(mode_badge)
		
		var lbl_protocol = Label.new()
		if _mode == "servidor":
			lbl_protocol.text = "🟠 // PROTOCOLO DATACENTER // MATRIZ SERVIDOR NARANJA //"
		elif _mode == "sistema":
			lbl_protocol.text = "🔵 // PROTOCOLO DE SISTEMAS // MATRIZ KERNEL AZUL //"
		elif _mode == "reparacion":
			lbl_protocol.text = "🔴 // PROTOCOLO DE REPARACIÓN // MATRIZ TALLER ROJA //"
		else:
			lbl_protocol.text = "🔴 // PROTOCOLO DE ENLACE // MATRIZ DE SIMULACIÓN //"
		lbl_protocol.add_theme_color_override("font_color", theme_primary_col)
		lbl_protocol.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		lbl_protocol.add_theme_constant_override("shadow_outline_size", 4)
		lbl_protocol.add_theme_font_size_override("font_size", 11)
		lbl_protocol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl_protocol)
		
		var lbl_title = Label.new()
		lbl_title.text = title_text
		if font_bungee:
			lbl_title.add_theme_font_override("font", font_bungee)
		lbl_title.add_theme_font_size_override("font_size", 22)
		lbl_title.add_theme_color_override("font_color", theme_primary_col)
		lbl_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		lbl_title.add_theme_constant_override("outline_size", 6)
		lbl_title.add_theme_color_override("font_shadow_color", theme_shadow_col)
		lbl_title.add_theme_constant_override("shadow_outline_size", 10)
		lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl_title)
		
		var lbl_sub = Label.new()
		lbl_sub.text = subtitle_text
		lbl_sub.add_theme_color_override("font_color", theme_accent_col)
		lbl_sub.add_theme_font_size_override("font_size", 12)
		lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl_sub)
		
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 4)
		vbox.add_child(spacer)
		
		prog_bar = ProgressBar.new()
		prog_bar.custom_minimum_size = Vector2(580.0, 22.0)
		prog_bar.min_value = 0.0
		prog_bar.max_value = 100.0
		prog_bar.value = 0.0
		prog_bar.show_percentage = false
		
		var prog_bg_sb = StyleBoxFlat.new()
		prog_bg_sb.bg_color = Color(0.02, 0.02, 0.04, 0.95)
		prog_bg_sb.border_color = Color(theme_primary_col.r, theme_primary_col.g, theme_primary_col.b, 0.7)
		prog_bg_sb.set_border_width_all(1)
		prog_bg_sb.set_corner_radius_all(4)
		prog_bar.add_theme_stylebox_override("background", prog_bg_sb)
		
		var prog_fill_sb = StyleBoxFlat.new()
		prog_fill_sb.bg_color = theme_primary_col
		prog_fill_sb.set_corner_radius_all(3)
		prog_bar.add_theme_stylebox_override("fill", prog_fill_sb)
		vbox.add_child(prog_bar)
		
		lbl_progress_val = Label.new()
		lbl_progress_val.text = "[ INICIANDO PROTOCOLO: 0% ]"
		lbl_progress_val.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl_progress_val.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		lbl_progress_val.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		lbl_progress_val.add_theme_constant_override("outline_size", 4)
		lbl_progress_val.add_theme_font_size_override("font_size", 11)
		lbl_progress_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_progress_val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		prog_bar.add_child(lbl_progress_val)
		
		lbl_telemetry = Label.new()
		if _mode == "servidor":
			lbl_telemetry.text = "> DATACENTER_CORE: ENLAZANDO TELEMETRÍA Y CONTROLADORES..."
		elif _mode == "sistema":
			lbl_telemetry.text = "> SISTEMAS_CORE: CARGANDO MÓDULOS DE KERNEL Y ENTORNO..."
		else:
			lbl_telemetry.text = "> RED_MATRIX: ACTIVA // CARGANDO CONTROLADORES Y MAPA DE HARDWARE..."
		lbl_telemetry.add_theme_color_override("font_color", theme_accent_col)
		lbl_telemetry.add_theme_font_size_override("font_size", 10)
		lbl_telemetry.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl_telemetry)
	
	# -------------------------------------------------------------------------
	# DESTELLO ÓPTICO (FLASH DE TRASPASO)
	# -------------------------------------------------------------------------
	var flash_rect = ColorRect.new()
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.color = Color(theme_primary_col.r, theme_primary_col.g, theme_primary_col.b, 0.0)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(flash_rect)
	
	# =========================================================================
	# COREOGRAFÍA DE TWEEN (SECUENCIA ENTRADA -> SWAP -> SALIDA)
	# =========================================================================
	var tw = tree.create_tween()
	tw.set_parallel(true)
	
	# 1. Oscurecer fondo y cerrar compuertas con impacto cinemático
	tw.tween_property(bg_overlay, "color:a", 0.90, t_close * 0.9).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(shutter_top, "position:y", 0.0, t_close).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(shutter_bot, "position:y", half_h, t_close).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Micro impacto shake de las compuertas al cerrarse
	tw.tween_property(root_ctrl, "position:y", 4.0, 0.02).set_delay(t_close)
	tw.tween_property(root_ctrl, "position:y", 0.0, 0.02).set_delay(t_close + 0.02)
	
	# Activar capa de hologramas
	tw.tween_property(hologram_layer, "modulate:a", 1.0, t_close * 0.7)
	
	# Retícula holográfica
	tw.tween_property(reticle_ctrl, "modulate:a", 0.90, t_close * 0.6).set_delay(0.04)
	tw.tween_property(reticle_ctrl, "scale", Vector2(1.2, 1.2), t_close).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(0.04)
	
	# 2. Barrido dual de haces láser cruzados
	var gm_ref = get_node_or_null("/root/GameManager")
	var is_photo = gm_ref and gm_ref.has_method("is_photosensitive_mode_enabled") and gm_ref.is_photosensitive_mode_enabled()
	
	if not is_photo:
		laser_beam_main.modulate.a = 1.0
		laser_beam_main.position.y = -10.0
		laser_beam_sub.modulate.a = 0.85
		laser_beam_sub.position.y = screen_h + 10.0
		tw.tween_property(laser_beam_main, "position:y", screen_h + 10.0, t_close).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(laser_beam_sub, "position:y", -10.0, t_close).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT).set_delay(0.02)
	else:
		laser_beam_main.modulate.a = 0.0
		laser_beam_sub.modulate.a = 0.0
	
	# 3. Aparición con escala y glow del elemento central
	if center_element:
		center_element.modulate.a = 0.0
		center_element.scale = Vector2(0.85, 0.85)
		tw.tween_property(center_element, "modulate:a", 1.0, t_close * 0.7).set_delay(0.04)
		tw.tween_property(center_element, "scale", Vector2(1.0, 1.0), t_close).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.04)
	
	# 4. Progreso inicial fluido mientras se cierran compuertas
	if prog_bar:
		tw.tween_property(prog_bar, "value", 25.0, t_close).set_trans(Tween.TRANS_QUAD)
	
	if is_instance_valid(lbl_progress_val):
		tw.tween_method(func(val: float):
			if is_instance_valid(lbl_progress_val):
				lbl_progress_val.text = "[ INICIALIZANDO: %d%% ]" % int(val)
		, 0.0, 25.0, t_close)
	
	# 5. Conmutación y carga activa de escena tras cerrar compuertas
	tw.chain().tween_callback(func():
		_perform_scene_swap_and_reveal(
			tree,
			target_scene_path,
			flash_rect,
			center_element,
			hologram_layer,
			reticle_ctrl,
			shutter_top,
			shutter_bot,
			bg_overlay,
			half_h,
			screen_h,
			on_finished,
			prog_bar,
			lbl_progress_val,
			lbl_telemetry,
			is_photo,
			t_swap,
			t_open
		)
	)

func _perform_scene_swap_and_reveal(
	tree: SceneTree,
	target_scene_path: String,
	flash_rect: ColorRect,
	center_element: Control,
	hologram_layer: Control,
	reticle_ctrl: Control,
	shutter_top: ColorRect,
	shutter_bot: ColorRect,
	bg_overlay: ColorRect,
	half_h: float,
	screen_h: float,
	on_finished: Callable,
	prog_bar: ProgressBar = null,
	lbl_progress_val: Label = null,
	lbl_telemetry: Label = null,
	is_photo: bool = false,
	t_swap: float = 0.48,
	t_open: float = 0.31
) -> void:
	if target_scene_path != "":
		tree.paused = false
		
		# Animar progreso y telemetría de 25% a 100% sincronizado exactamente con t_swap
		var pb_tw = tree.create_tween()
		pb_tw.set_parallel(true)
		if is_instance_valid(prog_bar):
			pb_tw.tween_property(prog_bar, "value", 100.0, t_swap * 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if is_instance_valid(lbl_progress_val):
			pb_tw.tween_method(func(val: float):
				if is_instance_valid(lbl_progress_val):
					if val >= 99.0:
						lbl_progress_val.text = "✓ [ CARGA COMPLETA: 100% OK ]"
						lbl_progress_val.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5, 1.0))
					else:
						lbl_progress_val.text = "[ SINCRONIZANDO: %d%% ]" % int(val)
			, 25.0, 100.0, t_swap * 0.85)
		if is_instance_valid(lbl_telemetry):
			pb_tw.chain().tween_callback(func():
				if is_instance_valid(lbl_telemetry):
					lbl_telemetry.text = "> RED_NEURONAL: ENLACE ESTABLECIDO // ACCESO CONCEDIDO"
			).set_delay(t_swap * 0.45)
		
		var progress_arr: Array = []
		var max_frames := 300 # 5 segundos de seguridad máxima
		var frame_count := 0
		while ResourceLoader.load_threaded_get_status(target_scene_path, progress_arr) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			frame_count += 1
			if frame_count > max_frames:
				break
			await tree.process_frame
			
		var status = ResourceLoader.load_threaded_get_status(target_scene_path)
		var packed: PackedScene = null
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			packed = ResourceLoader.load_threaded_get(target_scene_path) as PackedScene
			
		if not packed and ResourceLoader.exists(target_scene_path):
			packed = load(target_scene_path) as PackedScene
			
		# Esperar a que el tween pb_tw culmine para garantizar que el tiempo del sonido se respete
		if pb_tw and pb_tw.is_running():
			await pb_tw.finished
			
		if is_instance_valid(prog_bar):
			prog_bar.value = 100.0
		if is_instance_valid(lbl_progress_val):
			lbl_progress_val.text = "✓ [ CARGA COMPLETA: 100% OK ]"
			lbl_progress_val.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5, 1.0))
			
		var flash_alpha = 0.0 if is_photo else 0.70
		if flash_alpha > 0.0 and is_instance_valid(flash_rect):
			var tw_flash = tree.create_tween()
			tw_flash.tween_property(flash_rect, "color:a", flash_alpha, t_swap * 0.15).set_trans(Tween.TRANS_QUAD)
			await tw_flash.finished
			
		if packed:
			tree.change_scene_to_packed(packed)
		else:
			tree.change_scene_to_file(target_scene_path)
			
		# Esperar 1 frame con compuertas cerradas para instanciar nodo en el árbol
		await tree.process_frame

	# Apertura sincronizada con t_open hasta completar exactamente la duración del sonido
	var tw_open = tree.create_tween().set_parallel(true)
	tw_open.tween_property(flash_rect, "color:a", 0.0, t_open * 0.7).set_trans(Tween.TRANS_QUAD)
	if center_element and is_instance_valid(center_element):
		tw_open.tween_property(center_element, "modulate:a", 0.0, t_open * 0.6).set_trans(Tween.TRANS_QUAD)
		tw_open.tween_property(center_element, "scale", Vector2(1.15, 1.15), t_open * 0.6).set_trans(Tween.TRANS_QUAD)
	if is_instance_valid(hologram_layer):
		tw_open.tween_property(hologram_layer, "modulate:a", 0.0, t_open * 0.7)
	if is_instance_valid(reticle_ctrl):
		tw_open.tween_property(reticle_ctrl, "modulate:a", 0.0, t_open * 0.7)
		
	if is_instance_valid(shutter_top):
		tw_open.tween_property(shutter_top, "position:y", -half_h - 20.0, t_open).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	if is_instance_valid(shutter_bot):
		tw_open.tween_property(shutter_bot, "position:y", screen_h + 20.0, t_open).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	if is_instance_valid(bg_overlay):
		tw_open.tween_property(bg_overlay, "color:a", 0.0, t_open)
		
	tw_open.chain().tween_callback(func():
		if on_finished.is_valid():
			on_finished.call()
		transition_completed.emit()
		queue_free()
	)

# =============================================================================
# CINEMÁTICA DE ERROR / GLITCH AL ENTRAR AL TEST/SET DE PARTIDA
# =============================================================================
func _start_error_glitch_sequence(
	tree: SceneTree,
	target_scene_path: String,
	on_finished: Callable
) -> void:
	var loc = get_node_or_null("/root/LocalizationManager")
	var t_err = loc.translate_text("[ ⚠️ SYSTEM ERROR // EXCEPCIÓN DE MEMORIA ]") if loc else "[ ⚠️ SYSTEM ERROR // EXCEPCIÓN DE MEMORIA ]"
	var t_sub = loc.translate_text("// REDIRIGIENDO AL GESTOR DE PARTIDAS... //") if loc else "// REDIRIGIENDO AL GESTOR DE PARTIDAS... //"
	
	var root_ctrl = Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root_ctrl)
	
	var screen_w = root_ctrl.size.x if root_ctrl.size.x > 0 else 1280.0
	var screen_h = root_ctrl.size.y if root_ctrl.size.y > 0 else 720.0
	
	var shake_ctrl = Control.new()
	shake_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	shake_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(shake_ctrl)
	
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.08, 0.012, 0.03, 0.96)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shake_ctrl.add_child(bg)
	
	var glitch_bars: Array[ColorRect] = []
	for i in range(8):
		var bar = ColorRect.new()
		var bar_h = randf_range(8.0, 38.0)
		var bar_y = randf_range(0.0, screen_h - bar_h)
		bar.size = Vector2(screen_w, bar_h)
		bar.position = Vector2(0.0, bar_y)
		bar.color = Color(1.0, 0.05, 0.25, 0.35) if (i % 2 == 0) else Color(0.9, 0.0, 0.8, 0.25)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shake_ctrl.add_child(bar)
		glitch_bars.append(bar)
		
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 260)
	panel.position = Vector2((screen_w - 760.0) * 0.5, (screen_h - 260.0) * 0.5)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.02, 0.05, 0.94)
	sb.border_color = Color(1.0, 0.1, 0.3, 1.0)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(8)
	sb.shadow_color = Color(1.0, 0.05, 0.2, 0.6)
	sb.shadow_size = 12
	panel.add_theme_stylebox_override("panel", sb)
	shake_ctrl.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)
	margin.add_child(vbox)
	
	var header_bar = ColorRect.new()
	header_bar.custom_minimum_size = Vector2(0, 32)
	header_bar.color = Color(1.0, 0.12, 0.3, 0.85)
	vbox.add_child(header_bar)
	
	var lbl_badge = Label.new()
	lbl_badge.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_badge.text = t_err
	lbl_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_badge.add_theme_font_size_override("font_size", 13)
	lbl_badge.add_theme_color_override("font_color", Color(0, 0, 0))
	if ResourceLoader.exists("res://assets/fonts/Bungee-Regular.ttf"):
		lbl_badge.add_theme_font_override("font", load("res://assets/fonts/Bungee-Regular.ttf"))
	header_bar.add_child(lbl_badge)
	
	var lbl_code = Label.new()
	lbl_code.text = "EXCEPTION 0x0000007E // CORRUPT_STATE_RECOVERY"
	lbl_code.add_theme_font_size_override("font_size", 16)
	lbl_code.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	lbl_code.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl_code.add_theme_constant_override("outline_size", 4)
	lbl_code.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_code)
	
	var lbl_term = Label.new()
	lbl_term.text = "> ACTIVE SAVE STATE: [NOT DETECTED / UNLINKED]\n> EXCEPTION HANDLER: INVOKING MEMORY RECOVERY MATRIX...\n> OPENING STORAGE SETS GESTOR..."
	lbl_term.add_theme_font_size_override("font_size", 12)
	lbl_term.add_theme_color_override("font_color", Color(1.0, 0.7, 0.75, 0.9))
	vbox.add_child(lbl_term)
	
	var lbl_subt = Label.new()
	lbl_subt.text = t_sub
	lbl_subt.add_theme_font_size_override("font_size", 13)
	lbl_subt.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0))
	lbl_subt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_subt)
	
	var player = _play_glitch_sfx()
	var snd_len: float = 4.63
	if player and player.stream and player.stream.get_length() > 0.5:
		snd_len = player.stream.get_length() / maxf(player.pitch_scale, 0.1)

	var gm_ref = get_node_or_null("/root/GameManager")
	var is_photo: bool = gm_ref and gm_ref.has_method("is_photosensitive_mode_enabled") and gm_ref.is_photosensitive_mode_enabled()

	# Inicializar variables de estado del ciclo continuo de glitch sincronizado con el audio
	_glitch_target_scene = target_scene_path
	_glitch_on_finished = on_finished
	_glitch_root_ctrl = root_ctrl
	_glitch_shake_ctrl = shake_ctrl
	_glitch_bg = bg
	_glitch_panel = panel
	_glitch_bars = glitch_bars
	_glitch_audio_player = player
	_glitch_time = 0.0
	_glitch_bar_timer = 0.0
	_glitch_total_duration = snd_len
	_glitch_photo_factor = 0.35 if is_photo else 1.0
	_glitch_screen_w = screen_w
	_glitch_screen_h = screen_h
	_glitch_scene_swapped = false
	_glitch_active = true
	set_process(true)

# =============================================================================
# CINEMÁTICA DE CÓDIGO FUNCIONAL / REPARADO AL VOLVER AL MENÚ PRINCIPAL
# =============================================================================
func _start_code_restored_sequence(
	tree: SceneTree,
	target_scene_path: String,
	on_finished: Callable
) -> void:
	var loc = get_node_or_null("/root/LocalizationManager")
	var t_rest = loc.translate_text("[ ✓ CÓDIGO FUNCIONAL // SISTEMA REPARADO ]") if loc else "[ ✓ CÓDIGO FUNCIONAL // SISTEMA REPARADO ]"
	var t_sub = loc.translate_text("// KERNEL COMPILADO SIN ERRORES // RETORNANDO AL MENÚ //") if loc else "// KERNEL COMPILADO SIN ERRORES // RETORNANDO AL MENÚ //"
	
	var root_ctrl = Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root_ctrl)
	
	var screen_w = root_ctrl.size.x if root_ctrl.size.x > 0 else 1280.0
	var screen_h = root_ctrl.size.y if root_ctrl.size.y > 0 else 720.0
	
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.01, 0.04, 0.025, 0.96)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(bg)
	
	var scan_beam = ColorRect.new()
	scan_beam.size = Vector2(screen_w, 4.0)
	scan_beam.position = Vector2(0.0, -10.0)
	scan_beam.color = Color(0.0, 1.0, 0.5, 0.8)
	scan_beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(scan_beam)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 260)
	panel.position = Vector2((screen_w - 760.0) * 0.5, (screen_h - 260.0) * 0.5)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.08, 0.05, 0.94)
	sb.border_color = Color(0.0, 1.0, 0.5, 1.0)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(8)
	sb.shadow_color = Color(0.0, 1.0, 0.5, 0.5)
	sb.shadow_size = 12
	panel.add_theme_stylebox_override("panel", sb)
	root_ctrl.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)
	margin.add_child(vbox)
	
	var header_bar = ColorRect.new()
	header_bar.custom_minimum_size = Vector2(0, 32)
	header_bar.color = Color(0.0, 1.0, 0.45, 0.85)
	vbox.add_child(header_bar)
	
	var lbl_badge = Label.new()
	lbl_badge.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_badge.text = t_rest
	lbl_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_badge.add_theme_font_size_override("font_size", 13)
	lbl_badge.add_theme_color_override("font_color", Color(0, 0, 0))
	if ResourceLoader.exists("res://assets/fonts/Bungee-Regular.ttf"):
		lbl_badge.add_theme_font_override("font", load("res://assets/fonts/Bungee-Regular.ttf"))
	header_bar.add_child(lbl_badge)
	
	var lbl_status = Label.new()
	lbl_status.text = "✓ [ STATUS: 200 OK // 0 ERRORS · 0 WARNINGS ]"
	lbl_status.add_theme_font_size_override("font_size", 16)
	lbl_status.add_theme_color_override("font_color", Color(0.2, 1.0, 0.6))
	lbl_status.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl_status.add_theme_constant_override("outline_size", 4)
	lbl_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_status)
	
	var lbl_term = Label.new()
	lbl_term.text = "> KERNEL COMPILATION: SUCCESSFUL\n> SYNTAX VALIDATION: ALL BRANCHES RESOLVED\n> HARDWARE REPAIR OS WORKSPACE ONLINE"
	lbl_term.add_theme_font_size_override("font_size", 12)
	lbl_term.add_theme_color_override("font_color", Color(0.75, 1.0, 0.85, 0.9))
	vbox.add_child(lbl_term)
	
	var lbl_subt = Label.new()
	lbl_subt.text = t_sub
	lbl_subt.add_theme_font_size_override("font_size", 13)
	lbl_subt.add_theme_color_override("font_color", Color(0.0, 0.95, 1.0))
	lbl_subt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_subt)
	
	_play_restored_sfx()
	
	var tw = tree.create_tween()
	tw.set_parallel(true)
	tw.tween_property(scan_beam, "position:y", screen_h + 20.0, 0.50).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	var flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0.0, 1.0, 0.6, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(flash)
	
	tw.chain().tween_property(flash, "color:a", 0.70, 0.10)
	tw.chain().tween_callback(func():
		if target_scene_path != "":
			tree.change_scene_to_file(target_scene_path)
	)
	tw.chain().tween_interval(0.06)
	tw.chain().tween_property(root_ctrl, "modulate:a", 0.0, 0.22)
	tw.chain().tween_callback(func():
		if on_finished.is_valid():
			on_finished.call()
		transition_completed.emit()
		queue_free()
	)

func _play_glitch_sfx() -> AudioStreamPlayer:
	var sfx_path = "res://efectos/audio de error.ogg"
	if not ResourceLoader.exists(sfx_path):
		sfx_path = "res://efectos/sonido de entrada.ogg"
	if not ResourceLoader.exists(sfx_path):
		return null
	var stream = load(sfx_path)
	if not stream:
		return null
	if stream is AudioStreamOggVorbis:
		stream.loop = false

	var tree = _tree if _tree else get_tree()
	if tree and tree.root:
		var old_player = tree.root.get_node_or_null("GlitchAudioPlayer")
		if old_player:
			old_player.queue_free()

	var player = AudioStreamPlayer.new()
	player.name = "GlitchAudioPlayer"
	player.stream = stream
	# Para "audio de error.ogg" (normalizado a 0 dB peak), un volumen de -9.0 dB
	# resulta adecuado, limpio y balanceado con los demás efectos sin saturar.
	if sfx_path == "res://efectos/audio de error.ogg":
		player.volume_db = -9.0
		player.pitch_scale = 1.0
	else:
		player.volume_db = 2.0
		player.pitch_scale = 0.62
	player.bus = "Master"

	# Lo agregamos al root del árbol para que se mantenga sonando fluido y natural
	# al entrar en la zona de sets de guardado (SaveSlotsMenu), sin cortarse abruptamente.
	if tree and tree.root:
		tree.root.add_child(player)
	else:
		add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
	return player

func _play_restored_sfx() -> void:
	var tree = _tree if _tree else get_tree()
	if tree and tree.root:
		var old_glitch = tree.root.get_node_or_null("GlitchAudioPlayer")
		if old_glitch:
			old_glitch.queue_free()

	if not ResourceLoader.exists("res://efectos/sonido de entrada.ogg"):
		return
	var stream = load("res://efectos/sonido de entrada.ogg")
	if stream is AudioStreamOggVorbis:
		stream.loop = false
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = 0.0
	player.pitch_scale = 1.25
	player.bus = "Master"
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
