extends CanvasLayer

signal minigame_finished(success: bool)

# =============================================================================
# MINIJUEGO: CONEXIÓN DE SISTEMAS (ESTACIÓN TALLER <---> PC DAÑADA CLIENTE)
# Permite enlazar la terminal técnica del taller con la PC dañada antes de
# ingresar a la suite de reparación de software Andromeda Linux.
# =============================================================================

@onready var modal_control: Control = $ModalControl
@onready var title_label: Label = $ModalControl/Panel/VBox/Header/TitleLabel
@onready var status_badge: Label = $ModalControl/Panel/VBox/Header/StatusBadge
@onready var step_counter_lbl: Label = $ModalControl/Panel/VBox/Header/StepCounter

# Paneles laterales
@onready var client_led: ColorRect = $ModalControl/Panel/VBox/MainHBox/ClientPCPanel/Margin/VBox/PortHBox/PortLED
@onready var client_status_lbl: Label = $ModalControl/Panel/VBox/MainHBox/ClientPCPanel/Margin/VBox/StatusLabel
@onready var client_ip_lbl: Label = $ModalControl/Panel/VBox/MainHBox/ClientPCPanel/Margin/VBox/IPLbl

@onready var workshop_led: ColorRect = $ModalControl/Panel/VBox/MainHBox/WorkshopPanel/Margin/VBox/PortHBox/PortLED
@onready var workshop_status_lbl: Label = $ModalControl/Panel/VBox/MainHBox/WorkshopPanel/Margin/VBox/StatusLabel

# Área central de enlace
@onready var cable_visual: ColorRect = $ModalControl/Panel/VBox/MainHBox/CenterBridge/CableBox/CableLine
@onready var cable_pulse: ColorRect = $ModalControl/Panel/VBox/MainHBox/CenterBridge/CableBox/CableLine/PulseLine
@onready var cable_status_lbl: Label = $ModalControl/Panel/VBox/MainHBox/CenterBridge/CableBox/CableStatusLbl

# Botón conectar cable (Paso 1)
@onready var btn_connect_cable: Button = $ModalControl/Panel/VBox/MainHBox/CenterBridge/Step1Box/BtnConnectCable

# Canales de sincronización (Paso 2)
@onready var step2_box: VBoxContainer = $ModalControl/Panel/VBox/MainHBox/CenterBridge/Step2Box
@onready var btn_channel_a: Button = $ModalControl/Panel/VBox/MainHBox/CenterBridge/Step2Box/ChannelsHBox/BtnChannelA
@onready var btn_channel_b: Button = $ModalControl/Panel/VBox/MainHBox/CenterBridge/Step2Box/ChannelsHBox/BtnChannelB
@onready var btn_channel_c: Button = $ModalControl/Panel/VBox/MainHBox/CenterBridge/Step2Box/ChannelsHBox/BtnChannelC
@onready var sync_progress: ProgressBar = $ModalControl/Panel/VBox/MainHBox/CenterBridge/Step2Box/SyncProgress
@onready var sync_status_lbl: Label = $ModalControl/Panel/VBox/MainHBox/CenterBridge/Step2Box/SyncStatusLbl

# Handshake & Terminal (Paso 3)
@onready var step3_box: VBoxContainer = $ModalControl/Panel/VBox/MainHBox/CenterBridge/Step3Box
@onready var btn_handshake: Button = $ModalControl/Panel/VBox/MainHBox/CenterBridge/Step3Box/BtnHandshake
@onready var term_log: RichTextLabel = $ModalControl/Panel/VBox/MainHBox/CenterBridge/Step3Box/TermLog
@onready var success_banner: PanelContainer = $ModalControl/Panel/VBox/MainHBox/CenterBridge/Step3Box/SuccessBanner
@onready var btn_continue: Button = $ModalControl/Panel/VBox/MainHBox/CenterBridge/Step3Box/SuccessBanner/Margin/VBox/BtnContinue

@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel
@onready var feedback_label: Label = $ModalControl/Panel/VBox/FeedbackLabel

var target_pc: Node = null
var current_step: int = 1

var is_cable_connected: bool = false
var channel_a_active: bool = false
var channel_b_active: bool = false
var channel_c_active: bool = false
var is_handshake_done: bool = false

var pulse_tween: Tween = null

func _ready() -> void:
	layer = 15
	if btn_cancel:
		btn_cancel.pressed.connect(_on_cancel_pressed)
	if btn_connect_cable:
		btn_connect_cable.pressed.connect(_on_connect_cable_pressed)
		
	if btn_channel_a:
		btn_channel_a.pressed.connect(func(): _toggle_channel("A"))
	if btn_channel_b:
		btn_channel_b.pressed.connect(func(): _toggle_channel("B"))
	if btn_channel_c:
		btn_channel_c.pressed.connect(func(): _toggle_channel("C"))
		
	if btn_handshake:
		btn_handshake.pressed.connect(_on_handshake_pressed)
	if btn_continue:
		btn_continue.pressed.connect(_on_continue_pressed)
		
	_refresh_ui_state()

func _unhandled_input(event: InputEvent) -> void:
	if not modal_control or not modal_control.visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		_on_cancel_pressed()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if current_step == 1 and not is_cable_connected:
				get_viewport().set_input_as_handled()
				_on_connect_cable_pressed()
			elif current_step == 3 and not is_handshake_done:
				get_viewport().set_input_as_handled()
				_on_handshake_pressed()
			elif is_handshake_done:
				get_viewport().set_input_as_handled()
				_on_continue_pressed()

func setup_target(pc_node: Node) -> void:
	target_pc = pc_node
	if target_pc and client_ip_lbl:
		var pc_id_val = target_pc.get("pc_id") if "pc_id" in target_pc else 1
		client_ip_lbl.text = "IP HOST: 192.168.1.%d" % (100 + pc_id_val)

func _refresh_ui_state() -> void:
	if current_step == 1:
		step_counter_lbl.text = "PASO 1 DE 3: ENLACE FÍSICO DE FIBRA"
		status_badge.text = "ESTADO: DESCONECTADO (ESPERANDO CABLE)"
		status_badge.modulate = Color(1.0, 0.35, 0.45)
		
		client_led.color = Color(0.9, 0.2, 0.2)
		client_status_lbl.text = "PUERTO RX/TX: DESCONECTADO"
		client_status_lbl.modulate = Color(1.0, 0.4, 0.4)
		
		workshop_led.color = Color(0.2, 0.7, 1.0)
		workshop_status_lbl.text = "TERMINAL TALLER: EN ESPERA"
		workshop_status_lbl.modulate = Color(0.3, 0.85, 1.0)
		
		cable_visual.color = Color(0.25, 0.28, 0.35, 0.8)
		if cable_pulse: cable_pulse.visible = false
		cable_status_lbl.text = "CANAL DE TRANSMISIÓN AISLADO"
		cable_status_lbl.modulate = Color(0.6, 0.65, 0.7)
		
		btn_connect_cable.visible = true
		step2_box.visible = false
		step3_box.visible = false
		
	elif current_step == 2:
		step_counter_lbl.text = "PASO 2 DE 3: SINCRONIZACIÓN DE FRECUENCIA & BUS"
		status_badge.text = "ESTADO: CABLE ENLAZADO · CALIBRANDO CANALES"
		status_badge.modulate = Color(1.0, 0.8, 0.2)
		
		client_led.color = Color(1.0, 0.75, 0.1)
		client_status_lbl.text = "PUERTO RX/TX: ENLACE FÍSICO OK"
		client_status_lbl.modulate = Color(1.0, 0.8, 0.2)
		
		workshop_led.color = Color(1.0, 0.75, 0.1)
		workshop_status_lbl.text = "TERMINAL TALLER: SINCRONIZANDO..."
		workshop_status_lbl.modulate = Color(1.0, 0.8, 0.2)
		
		cable_visual.color = Color(0.1, 0.7, 0.9, 0.9)
		if cable_pulse:
			cable_pulse.visible = true
			_start_cable_pulse()
		cable_status_lbl.text = "CABLE CONECTADO (BUS ACTIVO 10 Gbps)"
		cable_status_lbl.modulate = Color(0.2, 0.9, 1.0)
		
		btn_connect_cable.visible = false
		step2_box.visible = true
		step3_box.visible = false
		
		_update_channel_buttons()
		
	elif current_step == 3:
		step_counter_lbl.text = "PASO 3 DE 3: PROTOCOLO HANDSHAKE & AUTENTICACIÓN"
		status_badge.text = "ESTADO: CANALES CALIBRADOS 100% · LISTO PARA HANDSHAKE"
		status_badge.modulate = Color(0.2, 0.9, 1.0)
		
		step2_box.visible = false
		step3_box.visible = true
		success_banner.visible = is_handshake_done
		btn_handshake.visible = not is_handshake_done

func _start_cable_pulse() -> void:
	if not cable_pulse:
		return
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	pulse_tween = create_tween().set_loops()
	cable_pulse.position.x = 0
	pulse_tween.tween_property(cable_pulse, "position:x", 320.0, 0.9).from(0.0)

func _on_connect_cable_pressed() -> void:
	is_cable_connected = true
	current_step = 2
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("play_sfx"):
		gm.play_sfx("click")
	_show_feedback("✓ Cable de diagnóstico conectado con éxito.", true)
	_refresh_ui_state()

func _toggle_channel(channel: String) -> void:
	match channel:
		"A": channel_a_active = not channel_a_active
		"B": channel_b_active = not channel_b_active
		"C": channel_c_active = not channel_c_active
		
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("play_sfx"):
		gm.play_sfx("click")
		
	_update_channel_buttons()
	
	var active_count = (1 if channel_a_active else 0) + (1 if channel_b_active else 0) + (1 if channel_c_active else 0)
	if active_count == 3:
		_show_feedback("✓ ¡Frecuencia bloqueada! Todos los canales sincronizados.", true)
		await get_tree().create_timer(0.45).timeout
		if not is_inside_tree(): return
		current_step = 3
		_refresh_ui_state()

func _update_channel_buttons() -> void:
	var active_count = (1 if channel_a_active else 0) + (1 if channel_b_active else 0) + (1 if channel_c_active else 0)
	var pct = float(active_count) / 3.0 * 100.0
	sync_progress.value = pct
	
	_style_channel_btn(btn_channel_a, "CANAL A: TCP/IP SSHv2", channel_a_active)
	_style_channel_btn(btn_channel_b, "CANAL B: BUS 10 Gbps", channel_b_active)
	_style_channel_btn(btn_channel_c, "CANAL C: ANDROMEDA ROOT", channel_c_active)
	
	if active_count == 3:
		sync_status_lbl.text = "FRECUENCIA DE ENLACE BLOQUEADA: 100% OK"
		sync_status_lbl.modulate = Color(0.2, 1.0, 0.4)
	else:
		sync_status_lbl.text = "SINCRONIZANDO: %d / 3 CANALES ACTIVOS (%d%%)" % [active_count, int(pct)]
		sync_status_lbl.modulate = Color(1.0, 0.8, 0.2)

func _style_channel_btn(btn: Button, title: String, active: bool) -> void:
	if not btn: return
	if active:
		btn.text = "✓ " + title + "\n[ EN FASE ]"
		btn.modulate = Color(0.2, 1.0, 0.5)
	else:
		btn.text = "○ " + title + "\n[ DESFASADO ]"
		btn.modulate = Color(0.85, 0.85, 0.9)

func _on_handshake_pressed() -> void:
	if is_handshake_done:
		return
	btn_handshake.disabled = true
	term_log.text = ""
	
	var steps_text = [
		"[color=#00e5ff]❯ [INIT][/color] Transmitiendo paquetes SYN a host remoto (192.168.1.10X:22)...",
		"[color=#00e5ff]❯ [ACK][/color] SYN-ACK recibido · Enlace simétrico de 10 Gbps verificado.",
		"[color=#00e5ff]❯ [AUTH][/color] Intercambiando par de claves RSA-4096 & túnel SSH seguro...",
		"[color=#39ff14]✓ [LINK][/color] Puente de telemetría Andromeda OS establecido con éxito.",
		"[b][color=#39ff14]★ ¡TERMINAL DEL TALLER Y PC DAÑADA CONECTADAS AL 100%! ★[/color][/b]"
	]
	
	for i in range(steps_text.size()):
		term_log.append_text(steps_text[i] + "\n")
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("play_sfx"):
			gm.play_sfx("click")
		await get_tree().create_timer(0.32).timeout
		if not is_inside_tree(): return
		
	is_handshake_done = true
	status_badge.text = "ESTADO: ¡SISTEMAS CONECTADOS Y ENLAZADOS! ✓"
	status_badge.modulate = Color(0.2, 1.0, 0.4)
	
	client_led.color = Color(0.2, 1.0, 0.4)
	client_status_lbl.text = "PUERTO RX/TX: ENLACE COMPLETO 100%"
	client_status_lbl.modulate = Color(0.2, 1.0, 0.4)
	
	workshop_led.color = Color(0.2, 1.0, 0.4)
	workshop_status_lbl.text = "TERMINAL TALLER: ACCESO ROOT CONCEDIDO"
	workshop_status_lbl.modulate = Color(0.2, 1.0, 0.4)
	
	cable_visual.color = Color(0.2, 1.0, 0.4, 0.95)
	cable_status_lbl.text = "ENLACE BIDIRECCIONAL ULTRA-RÁPIDO ACTIVO"
	cable_status_lbl.modulate = Color(0.2, 1.0, 0.4)
	
	btn_handshake.visible = false
	success_banner.visible = true
	
	var gm_final = get_node_or_null("/root/GameManager")
	if gm_final and gm_final.has_method("register_repair"):
		gm_final.register_repair(50, 5.0)

func _on_continue_pressed() -> void:
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	minigame_finished.emit(true)
	queue_free()

func _on_cancel_pressed() -> void:
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	minigame_finished.emit(false)
	queue_free()

func _show_feedback(msg: String, is_success: bool) -> void:
	if not feedback_label: return
	feedback_label.text = msg
	feedback_label.modulate = Color(0.2, 1.0, 0.4) if is_success else Color(1.0, 0.35, 0.35)
	var tw = create_tween()
	tw.tween_property(feedback_label, "modulate:a", 1.0, 0.1)
	tw.tween_interval(2.0)
	tw.tween_property(feedback_label, "modulate:a", 0.0, 0.3)
