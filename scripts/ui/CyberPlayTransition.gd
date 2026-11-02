class_name CyberPlayTransition
extends CanvasLayer

# =============================================================================
# CINEMÁTICA Y ANIMACIÓN DE ENTRADA CIBERNÉTICA DE ALTO IMPACTO (PLAY / INICIAR)
# =============================================================================

var _tree: SceneTree = null
var _target_scene: String = ""
var _title_text: String = ""
var _subtitle_text: String = ""
var _on_finished: Callable = Callable()

static func play(
	tree: SceneTree,
	target_scene_path: String,
	title_text: String = "INICIALIZANDO SIMULACIÓN",
	subtitle_text: String = "// ENLACE NEURONAL CON TALLER TÉCNICO //",
	on_finished: Callable = Callable()
) -> void:
	if not tree or not tree.root:
		return
		
	var transition = CyberPlayTransition.new()
	transition.layer = 150 # Por encima de cualquier interfaz, modal o HUD
	transition._tree = tree
	transition._target_scene = target_scene_path
	transition._title_text = title_text
	transition._subtitle_text = subtitle_text
	transition._on_finished = on_finished
	tree.root.call_deferred("add_child", transition)

func _ready() -> void:
	_start_sequence(_tree if _tree else get_tree(), _target_scene, _title_text, _subtitle_text, _on_finished)

# Sonido de pulso cibernético sintetizado procedimentalmente
func _play_synth_sfx() -> void:
	var player = AudioStreamPlayer.new()
	player.bus = "Master"
	var sample_hz = 22050
	var duration = 0.28
	var num_samples = int(sample_hz * duration)
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_hz
	wav.stereo = false
	var bytes = PackedByteArray()
	bytes.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / float(sample_hz)
		var freq = lerp(960.0, 360.0, pow(t / duration, 0.6))
		var envelope = sin((1.0 - (t / duration)) * PI * 0.5)
		var sample_val = sin(t * freq * TAU) * envelope * 115.0
		# Agregar armónico retro de onda cuadrada ligera
		if fmod(t * freq * 2.0, 1.0) > 0.5:
			sample_val += envelope * 20.0
		bytes[i] = int(clamp(sample_val + 128.0, 0, 255))
	wav.data = bytes
	player.stream = wav
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

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
	
	_play_synth_sfx()
	
	var screen_w = root_ctrl.size.x if root_ctrl.size.x > 0 else 1280.0
	var screen_h = root_ctrl.size.y if root_ctrl.size.y > 0 else 720.0
	var half_h = screen_h * 0.5
	
	# Fondo oscurecido con tinte cian/púrpura
	var bg_overlay = ColorRect.new()
	bg_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_overlay.color = Color(0.02, 0.005, 0.05, 0.0)
	bg_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(bg_overlay)
	
	# -------------------------------------------------------------------------
	# MATRIZ Y ELEMENTOS HOLOGRAMA ROJO CYBERPUNK (RETÍCULAS Y LÍNEAS DE ESCANEO)
	# -------------------------------------------------------------------------
	var red_hologram_layer = Control.new()
	red_hologram_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	red_hologram_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	red_hologram_layer.modulate.a = 0.0
	root_ctrl.add_child(red_hologram_layer)
	
	# Rejilla roja holográfica sutil
	for y_step in range(0, int(screen_h), 32):
		var grid_line = ColorRect.new()
		grid_line.color = Color(1.0, 0.05, 0.2, 0.08)
		grid_line.size = Vector2(screen_w, 1.0)
		grid_line.position = Vector2(0.0, float(y_step))
		red_hologram_layer.add_child(grid_line)
		
	# Brackets y marcas holográficas rojas en las 4 esquinas
	var corner_margin = 28.0
	var corner_size = 40.0
	var red_bracket_col = Color(1.0, 0.08, 0.25, 0.95)
	
	var corner_positions = [
		{"pos": Vector2(corner_margin, corner_margin), "label": "[+ REC.01 // RED-LINK]"},
		{"pos": Vector2(screen_w - corner_margin - corner_size, corner_margin), "label": "[RED.SYS // +]"},
		{"pos": Vector2(corner_margin, screen_h - corner_margin - corner_size), "label": "[+ PWR.NEXUS]"},
		{"pos": Vector2(screen_w - corner_margin - corner_size, screen_h - corner_margin - corner_size), "label": "[OVERRIDE.OK +]"}
	]
	
	for cp in corner_positions:
		var c_rect = Panel.new()
		c_rect.position = cp["pos"]
		c_rect.size = Vector2(corner_size, corner_size)
		c_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var csb = StyleBoxFlat.new()
		csb.draw_center = false
		csb.border_color = red_bracket_col
		csb.set_border_width_all(2)
		csb.shadow_color = Color(1.0, 0.05, 0.2, 0.6)
		csb.shadow_size = 6
		c_rect.add_theme_stylebox_override("panel", csb)
		red_hologram_layer.add_child(c_rect)
		
		var clbl = Label.new()
		clbl.text = cp["label"]
		clbl.add_theme_color_override("font_color", Color(1.0, 0.15, 0.3, 0.95))
		clbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		clbl.add_theme_constant_override("outline_size", 4)
		clbl.add_theme_font_size_override("font_size", 9)
		clbl.position = cp["pos"] + Vector2(0, corner_size + 4.0)
		red_hologram_layer.add_child(clbl)
	
	# Retícula circular holográfica roja central
	var red_reticle = Control.new()
	red_reticle.position = Vector2(screen_w * 0.5, screen_h * 0.5)
	red_reticle.scale = Vector2(0.2, 0.2)
	red_reticle.modulate.a = 0.0
	red_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(red_reticle)
	
	# Dibujar anillos concéntricos rojos mediante ColorRects circulares estilizados
	for r in [90.0, 140.0, 210.0]:
		var ring = Panel.new()
		ring.size = Vector2(r * 2.0, r * 2.0)
		ring.position = Vector2(-r, -r)
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var r_sb = StyleBoxFlat.new()
		r_sb.draw_center = false
		r_sb.border_color = Color(1.0, 0.08, 0.25, 0.65)
		r_sb.set_border_width_all(1)
		r_sb.set_corner_radius_all(int(r))
		r_sb.shadow_color = Color(1.0, 0.05, 0.2, 0.4)
		r_sb.shadow_size = 8
		ring.add_theme_stylebox_override("panel", r_sb)
		red_reticle.add_child(ring)
	
	# -------------------------------------------------------------------------
	# COMPUERTA SUPERIOR (SHUTTER TOP)
	# -------------------------------------------------------------------------
	var shutter_top = ColorRect.new()
	shutter_top.color = Color(0.04, 0.012, 0.08, 0.98)
	shutter_top.size = Vector2(screen_w, half_h + 4.0)
	shutter_top.position = Vector2(0.0, -half_h - 10.0)
	shutter_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(shutter_top)
	
	# Borde inferior de la compuerta superior (Línea Neón Roja y Cian)
	var line_top = ColorRect.new()
	line_top.color = Color(1.0, 0.08, 0.25, 1.0) # Borde Rojo Neón Holográfico
	line_top.size = Vector2(screen_w, 3.0)
	line_top.position = Vector2(0.0, half_h + 1.0)
	shutter_top.add_child(line_top)
	
	var accent_top = ColorRect.new()
	accent_top.color = Color(0.0, 0.95, 1.0, 1.0) # Centro cian de contraste
	accent_top.size = Vector2(220.0, 3.0)
	accent_top.position = Vector2((screen_w - 220.0) * 0.5, half_h + 1.0)
	shutter_top.add_child(accent_top)
	
	# Chevrons rojos de advertencia cyberpunk en la compuerta superior
	var top_chevrons = Label.new()
	top_chevrons.text = ">>> [ SYSTEM OVERRIDE // HOLOGRAMA ROJO ACTIVO // DIVERGENCIA NEURONAL ] <<<"
	top_chevrons.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_chevrons.position = Vector2(0.0, half_h - 22.0)
	top_chevrons.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_chevrons.add_theme_color_override("font_color", Color(1.0, 0.15, 0.3, 0.85))
	top_chevrons.add_theme_font_size_override("font_size", 10)
	shutter_top.add_child(top_chevrons)
	
	# -------------------------------------------------------------------------
	# COMPUERTA INFERIOR (SHUTTER BOTTOM)
	# -------------------------------------------------------------------------
	var shutter_bot = ColorRect.new()
	shutter_bot.color = Color(0.04, 0.012, 0.08, 0.98)
	shutter_bot.size = Vector2(screen_w, half_h + 4.0)
	shutter_bot.position = Vector2(0.0, screen_h + 10.0)
	shutter_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(shutter_bot)
	
	# Borde superior de la compuerta inferior (Línea Neón Roja y Magenta)
	var line_bot = ColorRect.new()
	line_bot.color = Color(1.0, 0.08, 0.25, 1.0)
	line_bot.size = Vector2(screen_w, 3.0)
	line_bot.position = Vector2(0.0, 0.0)
	shutter_bot.add_child(line_bot)
	
	var accent_bot = ColorRect.new()
	accent_bot.color = Color(1.0, 0.08, 0.45, 1.0)
	accent_bot.size = Vector2(220.0, 3.0)
	accent_bot.position = Vector2((screen_w - 220.0) * 0.5, 0.0)
	shutter_bot.add_child(accent_bot)
	
	var bot_chevrons = Label.new()
	bot_chevrons.text = "/// /// /// HARDWARE LINK // VULKAN SHADER EMISSION // RED MATRIX // /// ///"
	bot_chevrons.set_anchors_preset(Control.PRESET_FULL_RECT)
	bot_chevrons.position = Vector2(0.0, 8.0)
	bot_chevrons.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bot_chevrons.add_theme_color_override("font_color", Color(1.0, 0.15, 0.3, 0.85))
	bot_chevrons.add_theme_font_size_override("font_size", 10)
	shutter_bot.add_child(bot_chevrons)
	
	# -------------------------------------------------------------------------
	# DOS HAZES LÁSER ESCÁNER (ROJO NEÓN Y CIAN)
	# -------------------------------------------------------------------------
	var laser_beam_red = ColorRect.new()
	laser_beam_red.color = Color(1.0, 0.08, 0.25, 0.95) # Láser Rojo Neón Principal
	laser_beam_red.size = Vector2(screen_w, 5.0)
	laser_beam_red.position = Vector2(0.0, -10.0)
	laser_beam_red.mouse_filter = Control.MOUSE_FILTER_IGNORE
	laser_beam_red.modulate.a = 0.0
	root_ctrl.add_child(laser_beam_red)
	
	var laser_beam_cyan = ColorRect.new()
	laser_beam_cyan.color = Color(0.1, 1.0, 0.9, 0.85) # Láser Cian secundario
	laser_beam_cyan.size = Vector2(screen_w, 3.0)
	laser_beam_cyan.position = Vector2(0.0, -10.0)
	laser_beam_cyan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	laser_beam_cyan.modulate.a = 0.0
	root_ctrl.add_child(laser_beam_cyan)
	
	# -------------------------------------------------------------------------
	# TARJETA / HUD HOLOGRÁFICO CENTRAL CON ESTÉTICA ROJA CYBERPUNK
	# -------------------------------------------------------------------------
	var card_center = PanelContainer.new()
	card_center.custom_minimum_size = Vector2(640.0, 225.0)
	card_center.size = Vector2(640.0, 225.0)
	card_center.position = Vector2((screen_w - 640.0) * 0.5, (screen_h - 225.0) * 0.5)
	card_center.pivot_offset = Vector2(320.0, 112.5)
	card_center.scale = Vector2(0.85, 0.85)
	card_center.modulate.a = 0.0
	card_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var card_sb = StyleBoxFlat.new()
	card_sb.bg_color = Color(0.04, 0.015, 0.08, 0.96)
	card_sb.border_color = Color(1.0, 0.08, 0.25, 0.95) # Borde Rojo Neón
	card_sb.set_border_width_all(2)
	card_sb.set_corner_radius_all(8)
	card_sb.content_margin_left = 30.0
	card_sb.content_margin_right = 30.0
	card_sb.content_margin_top = 20.0
	card_sb.content_margin_bottom = 20.0
	card_sb.shadow_color = Color(1.0, 0.05, 0.2, 0.45) # Resplandor Rojo Holográfico
	card_sb.shadow_size = 18
	card_center.add_theme_stylebox_override("panel", card_sb)
	root_ctrl.add_child(card_center)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card_center.add_child(vbox)
	
	# Etiqueta de Protocolo / Header Rojo
	var lbl_protocol = Label.new()
	lbl_protocol.text = "🔴 // PROTOCOLO DE ENLACE // MATRIZ HOLOGRAMA ROJO v0.0.6 //"
	lbl_protocol.add_theme_color_override("font_color", Color(1.0, 0.2, 0.35, 1.0))
	lbl_protocol.add_theme_color_override("font_shadow_color", Color(0.8, 0.0, 0.1, 0.9))
	lbl_protocol.add_theme_constant_override("shadow_outline_size", 4)
	lbl_protocol.add_theme_font_size_override("font_size", 11)
	lbl_protocol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_protocol)
	
	# Título Principal
	var font_bungee: Font = null
	if ResourceLoader.exists("res://assets/fonts/Bungee-Regular.ttf"):
		font_bungee = load("res://assets/fonts/Bungee-Regular.ttf")
		
	var lbl_title = Label.new()
	lbl_title.text = title_text
	if font_bungee:
		lbl_title.add_theme_font_override("font", font_bungee)
	lbl_title.add_theme_font_size_override("font_size", 22)
	lbl_title.add_theme_color_override("font_color", Color(1.0, 0.15, 0.3, 1.0)) # Rojo Neón Intenso
	lbl_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lbl_title.add_theme_constant_override("outline_size", 6)
	lbl_title.add_theme_color_override("font_shadow_color", Color(0.9, 0.0, 0.2, 0.95))
	lbl_title.add_theme_constant_override("shadow_outline_size", 10)
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_title)
	
	# Subtítulo
	var lbl_sub = Label.new()
	lbl_sub.text = subtitle_text
	lbl_sub.add_theme_color_override("font_color", Color(0.95, 0.45, 0.6, 1.0))
	lbl_sub.add_theme_font_size_override("font_size", 12)
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_sub)
	
	# Espaciador
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(spacer)
	
	# Barra de progreso cibernética en tonos rojo neón y cian
	var progress_box = PanelContainer.new()
	progress_box.custom_minimum_size = Vector2(0, 22)
	var prog_bg_sb = StyleBoxFlat.new()
	prog_bg_sb.bg_color = Color(0.08, 0.015, 0.04, 0.95)
	prog_bg_sb.border_color = Color(1.0, 0.1, 0.3, 0.8)
	prog_bg_sb.set_border_width_all(1)
	prog_bg_sb.set_corner_radius_all(4)
	progress_box.add_theme_stylebox_override("panel", prog_bg_sb)
	vbox.add_child(progress_box)
	
	var progress_bar_fill = ColorRect.new()
	progress_bar_fill.color = Color(1.0, 0.1, 0.3, 0.95) # Relleno Rojo Neón
	progress_bar_fill.size = Vector2(0.0, 22.0)
	progress_box.add_child(progress_bar_fill)
	
	var lbl_progress_val = Label.new()
	lbl_progress_val.text = "[ INICIANDO PROTOCOLO: 0% ]"
	lbl_progress_val.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_progress_val.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	lbl_progress_val.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lbl_progress_val.add_theme_constant_override("outline_size", 4)
	lbl_progress_val.add_theme_font_size_override("font_size", 11)
	lbl_progress_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_progress_val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_box.add_child(lbl_progress_val)
	
	# Consola de telemetría inferior con advertencia roja
	var lbl_telemetry = Label.new()
	lbl_telemetry.text = "> RED_MATRIX: ACTIVA // CARGANDO CONTROLADORES Y MAPA DE HARDWARE..."
	lbl_telemetry.add_theme_color_override("font_color", Color(1.0, 0.45, 0.55, 0.85))
	lbl_telemetry.add_theme_font_size_override("font_size", 10)
	lbl_telemetry.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_telemetry)
	
	# -------------------------------------------------------------------------
	# DESTELLO ÓPTICO BLANCO/CIAN (FLASH DE TRASPASO)
	# -------------------------------------------------------------------------
	var flash_rect = ColorRect.new()
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.color = Color(0.8, 1.0, 1.0, 0.0)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(flash_rect)
	
	# =========================================================================
	# COREOGRAFÍA DE TWEEN (SECUENCIA ENTRADA -> SWAP -> SALIDA)
	# =========================================================================
	var tw = tree.create_tween()
	tw.set_parallel(true)
	
	# 1. Oscurecer fondo y cerrar compuertas
	tw.tween_property(bg_overlay, "color:a", 0.75, 0.28).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(shutter_top, "position:y", 0.0, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(shutter_bot, "position:y", half_h, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Activar capa de hologramas y rejilla roja
	tw.tween_property(red_hologram_layer, "modulate:a", 1.0, 0.22)
	
	# Retícula holográfica roja circular expandiéndose
	tw.tween_property(red_reticle, "modulate:a", 0.85, 0.2).set_delay(0.08)
	tw.tween_property(red_reticle, "scale", Vector2(1.15, 1.15), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(0.08)
	
	# 2. Barrido de haz láser doble (Rojo Neón y Cian)
	laser_beam_red.modulate.a = 1.0
	laser_beam_cyan.modulate.a = 0.8
	tw.tween_property(laser_beam_red, "position:y", screen_h + 10.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(laser_beam_cyan, "position:y", screen_h + 10.0, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT).set_delay(0.04)
	
	# 3. Aparición con escala del HUD central
	tw.tween_property(card_center, "modulate:a", 1.0, 0.25).set_delay(0.12)
	tw.tween_property(card_center, "scale", Vector2(1.0, 1.0), 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.1)
	
	# 4. Llenado rápido de la barra de progreso
	var max_fill_w = 640.0 - 60.0 # ancho interior aproximado
	tw.tween_property(progress_bar_fill, "size:x", max_fill_w, 0.45).set_trans(Tween.TRANS_QUAD).set_delay(0.12)
	
	# Actualizar texto de progreso dinámicamente
	tw.tween_method(func(val: float):
		if is_instance_valid(lbl_progress_val):
			var pct = int(val * 100.0)
			if pct >= 100:
				lbl_progress_val.text = "✓ [ CARGA COMPLETA: 100% OK ]"
				lbl_progress_val.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5, 1.0))
				lbl_telemetry.text = "> TECNICO_VULKAN: CONECTADO // BIENVENIDO AL ENTORNO TÉCNICO"
			elif pct >= 65:
				lbl_progress_val.text = "[ SINCRONIZANDO NODOS: %d%% ]" % pct
				lbl_telemetry.text = "> WORKSHOP_3D: INSTANCIANDO MÁQUINAS Y BANCO DE TRABAJO..."
			elif pct >= 30:
				lbl_progress_val.text = "[ DESPLEGANDO SISTEMA: %d%% ]" % pct
				lbl_telemetry.text = "> DIAGNOSTIC_ENGINE: VERIFICANDO PREGUNTAS Y REPUESTOS..."
			else:
				lbl_progress_val.text = "[ INICIALIZANDO: %d%% ]" % pct
	, 0.0, 1.0, 0.45).set_delay(0.12)
	
	# 5. Destello óptico en el pico de la animación (0.55s)
	tw.chain().tween_property(flash_rect, "color:a", 0.65, 0.12).set_trans(Tween.TRANS_QUAD)
	
	# 6. Momento pico: Cambio de escena seguro bajo el destello y compuertas cerradas
	tw.chain().tween_callback(func():
		if target_scene_path != "":
			tree.change_scene_to_file(target_scene_path)
	)
	
	# 7. Desvanecer destello y abrir compuertas revelando la nueva escena
	tw.chain().set_parallel(true)
	tw.tween_property(flash_rect, "color:a", 0.0, 0.28).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(card_center, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(card_center, "scale", Vector2(1.1, 1.1), 0.2).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(red_hologram_layer, "modulate:a", 0.0, 0.25).set_delay(0.05)
	tw.tween_property(red_reticle, "modulate:a", 0.0, 0.25).set_delay(0.05)
	
	tw.tween_property(shutter_top, "position:y", -half_h - 20.0, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(0.08)
	tw.tween_property(shutter_bot, "position:y", screen_h + 20.0, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(0.08)
	tw.tween_property(bg_overlay, "color:a", 0.0, 0.32).set_delay(0.1)
	
	# 8. Liberación y finalización
	tw.chain().tween_callback(func():
		if on_finished.is_valid():
			on_finished.call()
		queue_free()
	)
