extends CanvasLayer

# =============================================================================
# MINIJUEGO: LIMPIEZA DE ANUNCIOS & POP-UPS (ADWARE CLEANER)
# Enseña:
# 1. Identificar ventanas emergentes fraudulentas y publicidad invasiva (adware).
# 2. Reconocer falsos botones de cerrar y trampas de redirección.
# 3. Desactivar casillas de instalación de software no deseado (PUPs).
# 4. Desplegar extensiones de filtrado y bloqueo de anuncios (Ad-Blockers).
# =============================================================================

signal minigame_finished(success: bool)

# Nodos principales
@onready var modal_control: Control = $ModalControl
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel
@onready var desktop_area: Control = $ModalControl/Panel/VBox/DesktopArea
@onready var progress_bar: ProgressBar = $ModalControl/Panel/VBox/Header/Metrics/ProgressBar
@onready var lbl_ads_count: Label = $ModalControl/Panel/VBox/Header/Metrics/LblAdsCount
@onready var lbl_cpu_load: Label = $ModalControl/Panel/VBox/Header/Metrics/LblCPULoad
@onready var btn_adblock: Button = $ModalControl/Panel/VBox/Footer/BtnAdBlock
@onready var victory_banner: PanelContainer = $ModalControl/Panel/VBox/DesktopArea/VictoryBanner
@onready var notification_toast: Label = $ModalControl/Panel/VBox/DesktopArea/NotificationToast

var total_ads_target: int = 8
var closed_ads: int = 0
var cpu_load: float = 95.0
var adblock_unlocked: bool = false
var is_completed: bool = false
var active_popups: Array[PanelContainer] = []

const POPUP_DATA = [
	{
		"title": "🎉 ¡PREMIO EXCLUSIVO!",
		"text": "¡Has sido seleccionado como el visitante #1.000.000!\nReclama un procesador Quantum Core gratis.",
		"type": "standard",
		"pos": Vector2(60, 40),
		"color": Color(0.95, 0.2, 0.4)
	},
	{
		"title": "⚠️ ALERTA DE SEGURIDAD FALSA",
		"text": "¡Se detectaron 43 virus en tu tarjeta madre!\nNo hagas clic en el botón verde gigante.",
		"type": "deceptive",
		"pos": Vector2(360, 25),
		"color": Color(1.0, 0.5, 0.1)
	},
	{
		"title": "⚡ DESCARGA MÁS MEMORIA RAM",
		"text": "Aumenta la memoria RAM de tu equipo a 128 GB\ncon un solo clic en la nube sin coste.",
		"type": "evasive",
		"pos": Vector2(160, 160),
		"color": Color(0.2, 0.8, 1.0)
	},
	{
		"title": "📦 ACTUALIZADOR DE CÓDECS",
		"text": "Instalación de paquetes multimedia 2026.\nDesmarca las casillas trampa antes de aceptar.",
		"type": "checkbox",
		"pos": Vector2(460, 150),
		"color": Color(0.85, 0.25, 0.9)
	},
	{
		"title": "💰 CRIPTO-MINERÍA AUTOMÁTICA",
		"text": "Multiplica tus créditos usando el 99% de tu GPU.\nMonetiza tus núcleos mientras juegas.",
		"type": "standard",
		"pos": Vector2(100, 260),
		"color": Color(0.9, 0.85, 0.15)
	},
	{
		"title": "🚀 DUPLICADOR DE ANCHO DE BANDA",
		"text": "Tu proveedor limita tu red a 50 Mbps.\nDesbloquea 10 Gbps con nuestro acelerador.",
		"type": "evasive",
		"pos": Vector2(380, 265),
		"color": Color(0.1, 0.9, 0.5)
	},
	{
		"title": "💬 MENSAJE DE SOPORTE FALSO",
		"text": "Técnico en línea: 'Tu licencia de Windows expira hoy.\nPermite el control remoto inmediato.'",
		"type": "deceptive",
		"pos": Vector2(240, 90),
		"color": Color(0.9, 0.1, 0.3)
	},
	{
		"title": "🍪 AVISO DE RASTREADORES",
		"text": "¿Aceptas compartir tu historial y pulsaciones\nde teclado con 480 empresas de publicidad?",
		"type": "checkbox",
		"pos": Vector2(520, 80),
		"color": Color(0.65, 0.3, 0.95)
	}
]

func _ready() -> void:
	layer = 12
	btn_cancel.pressed.connect(_on_cancel_pressed)
	btn_adblock.pressed.connect(_on_adblock_pressed)
	btn_adblock.disabled = true
	btn_adblock.modulate = Color(0.6, 0.6, 0.6, 0.6)
	victory_banner.visible = false
	notification_toast.visible = false
	
	_spawn_all_popups()
	_update_metrics()
	_update_status("Cierra las ventanas emergentes falsas con [X]. ¡Cuidado con los botones trampa!")

func _spawn_all_popups() -> void:
	var index = 0
	for data in POPUP_DATA:
		var popup = _create_popup_node(data, index)
		desktop_area.add_child(popup)
		active_popups.append(popup)
		
		# Animación de aparición escalonada estilo adware invasivo
		popup.scale = Vector2(0.3, 0.3)
		popup.modulate.a = 0.0
		var tw = create_tween().set_parallel(true)
		tw.tween_property(popup, "scale", Vector2(1.0, 1.0), 0.35).set_delay(index * 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(popup, "modulate:a", 1.0, 0.25).set_delay(index * 0.07)
		index += 1

func _create_popup_node(data: Dictionary, index: int) -> PanelContainer:
	var p = PanelContainer.new()
	p.name = "AdPopup_%d" % index
	p.position = data["pos"]
	p.custom_minimum_size = Vector2(290, 145)
	
	# Estilo Cyberpunk Ventana Emergente
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.14, 0.96)
	style.border_width_left = 2
	style.border_width_top = 26
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = data["color"]
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.shadow_size = 6
	style.shadow_color = Color(0, 0, 0, 0.65)
	p.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	p.add_child(vbox)
	
	# Cabecera con Título y Botón [X] Real
	var header = HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 22)
	vbox.add_child(header)
	
	var title_lbl = Label.new()
	title_lbl.text = data["title"]
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 11)
	title_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	header.add_child(title_lbl)
	
	var close_btn = Button.new()
	close_btn.text = " ✕ "
	close_btn.custom_minimum_size = Vector2(26, 20)
	close_btn.flat = true
	close_btn.add_theme_font_size_override("font_size", 12)
	close_btn.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	close_btn.pressed.connect(func(): _close_popup(p, false))
	header.add_child(close_btn)
	
	# Contenido del anuncio
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 6)
	vbox.add_child(margin)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 6)
	margin.add_child(inner_vbox)
	
	var text_lbl = Label.new()
	text_lbl.text = data["text"]
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_lbl.add_theme_font_size_override("font_size", 10)
	text_lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92))
	inner_vbox.add_child(text_lbl)
	
	# Controles específicos según el tipo de engaño publicitario
	match data["type"]:
		"deceptive":
			# Botón engañoso gigante que finge ser 'Cerrar' pero instala más cosas
			var fake_btn = Button.new()
			fake_btn.text = "✓ CERRAR Y REPARAR AHORA"
			fake_btn.add_theme_color_override("font_color", Color(0.1, 1.0, 0.4))
			fake_btn.add_theme_font_size_override("font_size", 10)
			fake_btn.pressed.connect(func():
				_show_toast("⚠️ ¡Trampa! Era un botón engañoso que abre más adware.")
				cpu_load = minf(100.0, cpu_load + 5.0)
				_shake_popup(p)
				_update_metrics()
			)
			inner_vbox.add_child(fake_btn)
			
		"checkbox":
			var cb = CheckBox.new()
			cb.text = "Acepto instalar barra de adware en el navegador"
			cb.button_pressed = true
			cb.add_theme_font_size_override("font_size", 9)
			cb.toggled.connect(func(pressed):
				if not pressed:
					_show_toast("✓ ¡Excelente! Desmarcaste el software no deseado (PUP).")
			)
			inner_vbox.add_child(cb)
			
		"evasive":
			var fake_down = Button.new()
			fake_down.text = "⬇ DESCARGAR RAM ULTRA"
			fake_down.add_theme_font_size_override("font_size", 10)
			fake_down.pressed.connect(func():
				_show_toast("⚠️ La memoria RAM es hardware físico; no se puede descargar.")
				_shake_popup(p)
			)
			inner_vbox.add_child(fake_down)
			
		_:
			var claim_btn = Button.new()
			claim_btn.text = "🎁 RECLAMAR AQUÍ"
			claim_btn.add_theme_font_size_override("font_size", 10)
			claim_btn.pressed.connect(func():
				_show_toast("⚠️ Clic fraudulento evitado. Cierra siempre desde la [X].")
				_shake_popup(p)
			)
			inner_vbox.add_child(claim_btn)
			
	return p

func _close_popup(popup: PanelContainer, from_adblock: bool = false) -> void:
	if not active_popups.has(popup):
		return
		
	active_popups.erase(popup)
	closed_ads += 1
	cpu_load = maxf(4.0, cpu_load - (11.0 if not from_adblock else 20.0))
	_update_metrics()
	
	# Animación de cierre
	var tw = create_tween().set_parallel(true)
	tw.tween_property(popup, "scale", Vector2(0.2, 0.2), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(popup, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(popup.queue_free)
	
	if closed_ads >= 4 and not adblock_unlocked:
		_unlock_adblock()
		
	if active_popups.is_empty():
		_on_all_ads_cleared()

func _shake_popup(popup: PanelContainer) -> void:
	var orig_pos = popup.position
	var tw = create_tween()
	tw.tween_property(popup, "position:x", orig_pos.x + 8, 0.05)
	tw.tween_property(popup, "position:x", orig_pos.x - 8, 0.05)
	tw.tween_property(popup, "position:x", orig_pos.x + 4, 0.04)
	tw.tween_property(popup, "position:x", orig_pos.x, 0.04)

func _unlock_adblock() -> void:
	adblock_unlocked = true
	btn_adblock.disabled = false
	btn_adblock.text = "🛡️ ¡ACTIVAR ESCUDO AD-BLOCKER! (PULSO EMP)"
	btn_adblock.modulate = Color(0.2, 1.0, 0.8, 1.0)
	_show_toast("⚡ ¡ESCUDO AD-BLOCKER CARGADO! Actívalo para purgar los restantes.")
	_update_status("¡El Escudo Ad-Blocker está listo! Presiónalo para neutralizar todos los pop-ups restantes.")
	
	# Pulso en el botón
	var tw = create_tween().set_loops(3)
	tw.tween_property(btn_adblock, "scale", Vector2(1.05, 1.05), 0.2)
	tw.tween_property(btn_adblock, "scale", Vector2(1.0, 1.0), 0.2)

func _on_adblock_pressed() -> void:
	if not adblock_unlocked or active_popups.is_empty():
		return
		
	btn_adblock.disabled = true
	_show_toast("💥 ¡PULSO AD-BLOCKER EJECUTADO! Filtrando scripts maliciosos...")
	
	# Efecto flash en el escritorio
	var flash = ColorRect.new()
	flash.color = Color(0.2, 1.0, 0.8, 0.6)
	flash.anchors_preset = Control.PRESET_FULL_RECT
	desktop_area.add_child(flash)
	
	var tw_flash = create_tween()
	tw_flash.tween_property(flash, "modulate:a", 0.0, 0.45)
	tw_flash.chain().tween_callback(flash.queue_free)
	
	# Eliminar todos los popups activos en cascada
	var remaining = active_popups.duplicate()
	for p in remaining:
		_close_popup(p, true)

func _on_all_ads_cleared() -> void:
	if is_completed:
		return
	is_completed = true
	cpu_load = 4.0
	_update_metrics()
	_update_status("¡ESCRITORIO 100% LIMPIO! Adware eliminado y consumo de recursos restablecido.")
	
	victory_banner.visible = true
	victory_banner.scale = Vector2(0.5, 0.5)
	victory_banner.modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(victory_banner, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(victory_banner, "modulate:a", 1.0, 0.3)
	
	await get_tree().create_timer(2.2).timeout
	minigame_finished.emit(true)

func _update_metrics() -> void:
	var pct = float(closed_ads) / float(total_ads_target) * 100.0
	progress_bar.value = clampf(pct, 0.0, 100.0)
	lbl_ads_count.text = "ANUNCIOS ELIMINADOS: %d / %d" % [closed_ads, total_ads_target]
	lbl_cpu_load.text = "USO DE CPU: %d%%" % int(cpu_load)
	
	if cpu_load > 70.0:
		lbl_cpu_load.add_theme_color_override("font_color", Color(1.0, 0.25, 0.3))
	elif cpu_load > 30.0:
		lbl_cpu_load.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	else:
		lbl_cpu_load.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))

func _update_status(msg: String) -> void:
	status_label.text = msg

func _show_toast(msg: String) -> void:
	notification_toast.text = msg
	notification_toast.visible = true
	notification_toast.modulate.a = 1.0
	var tw = create_tween()
	tw.tween_property(notification_toast, "modulate:a", 0.0, 1.8).set_delay(1.0)
	tw.chain().tween_callback(func(): notification_toast.visible = false)

func _on_cancel_pressed() -> void:
	minigame_finished.emit(false)
