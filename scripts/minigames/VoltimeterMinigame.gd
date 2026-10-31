extends CanvasLayer

# =============================================================================
# MINIJUEGO: DIAGNÓSTICO CON MULTÍMETRO DIGITAL // CÍRCULO CALIBRADOR ANALÓGICO
# Enseña:
# 1. Medición de rieles DC (12V, 5VSB, 3.3V, VCore).
# 2. Medición de ruido/ripple en modo AC (V~).
# 3. Detección obligatoria de cortocircuitos en OHMIOS (Ω).
# 4. Calibración interactiva con aguja y marca aleatoria en el círculo [ESPACIO].
# 5. Parada de aguja y confirmación visual clara de parte ya medida/reparada.
# =============================================================================

signal minigame_finished(success: bool)

@onready var modal_control: Control = $ModalControl
@onready var title_label: Label = $ModalControl/Panel/VBox/Header/TitleLabel
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var progress_label: Label = $ModalControl/Panel/VBox/Header/ProgressLabel
@onready var progress_bar: ProgressBar = $ModalControl/Panel/VBox/Header/ProgressBar

# Multímetro UI
@onready var brand_label: Label = $ModalControl/Panel/VBox/WorkArea/HBox/MultimeterFrame/Margin/VBox/BrandLabel
@onready var lbl_voltage: Label = $ModalControl/Panel/VBox/WorkArea/HBox/MultimeterFrame/Margin/VBox/LcdScreen/Margin/VBox/LblVoltage
@onready var lbl_readout_status: Label = $ModalControl/Panel/VBox/WorkArea/HBox/MultimeterFrame/Margin/VBox/LcdScreen/Margin/VBox/LblReadoutStatus
@onready var lcd_bargraph: ProgressBar = $ModalControl/Panel/VBox/WorkArea/HBox/MultimeterFrame/Margin/VBox/LcdScreen/Margin/VBox/LcdBargraph
@onready var lbl_mode_badge: Label = $ModalControl/Panel/VBox/WorkArea/HBox/MultimeterFrame/Margin/VBox/LcdScreen/Margin/VBox/HBoxBadges/LblModeBadge
@onready var btn_mode_dc: Button = $ModalControl/Panel/VBox/WorkArea/HBox/MultimeterFrame/Margin/VBox/DialBox/BtnModeDC
@onready var btn_mode_ac: Button = $ModalControl/Panel/VBox/WorkArea/HBox/MultimeterFrame/Margin/VBox/DialBox/BtnModeAC
@onready var btn_mode_ohm: Button = $ModalControl/Panel/VBox/WorkArea/HBox/MultimeterFrame/Margin/VBox/DialBox/BtnModeOhm
@onready var tp_container: VBoxContainer = $ModalControl/Panel/VBox/WorkArea/HBox/MultimeterFrame/Margin/VBox/TPScroll/TPList

# Círculo Calibrador Analógico
@onready var circle_area: Control = $ModalControl/Panel/VBox/WorkArea/HBox/CalibrationFrame/Margin/VBox/CircleArea
@onready var circle_face: TextureRect = $ModalControl/Panel/VBox/WorkArea/HBox/CalibrationFrame/Margin/VBox/CircleArea/CircleFace
@onready var target_mark: TextureRect = $ModalControl/Panel/VBox/WorkArea/HBox/CalibrationFrame/Margin/VBox/CircleArea/TargetMark
@onready var needle: TextureRect = $ModalControl/Panel/VBox/WorkArea/HBox/CalibrationFrame/Margin/VBox/CircleArea/Needle
@onready var center_hub: Panel = $ModalControl/Panel/VBox/WorkArea/HBox/CalibrationFrame/Margin/VBox/CircleArea/CenterHub
@onready var lbl_calibration_hint: Label = $ModalControl/Panel/VBox/WorkArea/HBox/CalibrationFrame/Margin/VBox/LblCalibrationHint
@onready var btn_calibrate: Button = $ModalControl/Panel/VBox/WorkArea/HBox/CalibrationFrame/Margin/VBox/BtnCalibrate
@onready var repair_box: PanelContainer = $ModalControl/Panel/VBox/WorkArea/HBox/CalibrationFrame/Margin/VBox/RepairBox
@onready var btn_repair: Button = $ModalControl/Panel/VBox/WorkArea/HBox/CalibrationFrame/Margin/VBox/RepairBox/Margin/HBox/BtnRepair

@onready var victory_banner: PanelContainer = $ModalControl/Panel/VBox/VictoryBanner
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel

# Geometría de la aguja:
const NEEDLE_SPRITE_ANGLE: float = 0.0
const CIRCLE_CENTER: Vector2 = Vector2(170.0, 170.0)
const CIRCLE_RADIUS: float = 120.0
# Tolerancia más generosa y cómoda (~22 grados) para que sea divertido y fácil
const HIT_TOLERANCE: float = 0.38

# Velocidad de rotación normal (~137 grados/seg)
var needle_speed: float = 2.4
var needle_angle: float = 0.0
var target_angle: float = 0.0
var is_needle_spinning: bool = false

# Datos de los Test Points
var test_points_data: Array[Dictionary] = [
	{
		"id": "tp1_12v",
		"name": "TP1: RIEL 12V ATX",
		"desc": "Alimentación principal CPU & GPU",
		"required_mode": "DC",
		"nominal_str": "12.00 V DC",
		"reading_dc": 12.06,
		"reading_ac": 0.0,
		"reading_ohm": 18500.0,
		"verified": false,
		"color": Color(1.0, 0.85, 0.15)
	},
	{
		"id": "tp2_5vsb",
		"name": "TP2: RIEL 5V STANDBY",
		"desc": "Línea permanente de arranque",
		"required_mode": "DC",
		"nominal_str": "5.00 V DC",
		"reading_dc": 5.03,
		"reading_ac": 0.0,
		"reading_ohm": 12400.0,
		"verified": false,
		"color": Color(0.95, 0.45, 0.1)
	},
	{
		"id": "tp3_3v3",
		"name": "TP3: RIEL 3.3V LOGIC",
		"desc": "Chipset, BIOS & Buses de datos",
		"required_mode": "DC",
		"nominal_str": "3.30 V DC",
		"reading_dc": 3.31,
		"reading_ac": 0.0,
		"reading_ohm": 9800.0,
		"verified": false,
		"color": Color(0.1, 0.85, 1.0)
	},
	{
		"id": "tp4_ripple_ac",
		"name": "TP4: FILTRO RIPPLE AC",
		"desc": "Ruido residual de filtrado (Modo AC)",
		"required_mode": "AC",
		"nominal_str": "< 0.12 V AC",
		"reading_dc": 0.0,
		"reading_ac": 0.08, # 80 mV AC Ripple normal
		"reading_ohm": 15000.0,
		"verified": false,
		"color": Color(0.85, 0.35, 1.0)
	},
	{
		"id": "tp5_vcore_short",
		"name": "TP5: VRM VCORE (C124)",
		"desc": "¡CORTO A TIERRA! (Medir en OHM)",
		"required_mode": "OHM", # Obligatorio medir en Ohmios para diagnosticar
		"nominal_str": "1.25 V DC / > 10 kΩ",
		"reading_dc": 0.01,
		"reading_ac": 0.0,
		"reading_ohm": 0.1, # Corto a tierra (0.1 ohm)
		"is_shorted": true,
		"short_diagnosed": false,
		"verified": false,
		"color": Color(1.0, 0.25, 0.35)
	},
	{
		"id": "tp6_pwrgood",
		"name": "TP6: SEÑAL POWER_GOOD",
		"desc": "Confirmación de voltaje estable ATX",
		"required_mode": "DC",
		"nominal_str": "3.30 V DC",
		"reading_dc": 0.0, # 0V hasta que se arregle el corto
		"reading_ac": 0.0,
		"reading_ohm": 22000.0,
		"verified": false,
		"color": Color(0.2, 1.0, 0.5)
	}
]

var target_component: String = ""
var active_tp_index: int = -1
var current_mode: String = "DC" # DC, AC, OHM
var is_short_repaired: bool = false
var is_completed: bool = false
var tp_button_nodes: Array[Button] = []

func setup_component(comp_name: String) -> void:
	target_component = comp_name
	if is_inside_tree():
		_apply_component_data()
		_set_multimeter_mode("DC")
		_build_test_points_ui()
		_update_multimeter_display("0.00 V", "SELECCIONA UN TEST POINT (TP) DE [%s] PARA COMENZAR" % comp_name.to_upper(), false, 0.0)
		_update_progress()

func _apply_component_data() -> void:
	match target_component:
		"RAM":
			if title_label:
				title_label.text = "DIAGNÓSTICO CON MULTÍMETRO DIGITAL // BANCO DE MEMORIA RAM"
			if brand_label:
				brand_label.text = "FLUKE-CYBER 87V // BANCO DE PRUEBAS DDR5"
			test_points_data = [
				{
					"id": "ram_tp1_vdd",
					"name": "TP1: RIEL VDD DRAM",
					"desc": "Alimentación principal chips de memoria",
					"required_mode": "DC",
					"nominal_str": "1.20 V DC",
					"reading_dc": 1.21,
					"reading_ac": 0.0,
					"reading_ohm": 15400.0,
					"verified": false,
					"color": Color(1.0, 0.85, 0.15)
				},
				{
					"id": "ram_tp2_vddq",
					"name": "TP2: RIEL VDDQ I/O",
					"desc": "Tensión de búfer de bus de datos",
					"required_mode": "DC",
					"nominal_str": "1.20 V DC",
					"reading_dc": 1.20,
					"reading_ac": 0.0,
					"reading_ohm": 14200.0,
					"verified": false,
					"color": Color(0.95, 0.45, 0.1)
				},
				{
					"id": "ram_tp3_vpp",
					"name": "TP3: RIEL VPP ACTIVACIÓN",
					"desc": "Tensión de activación de filas DRAM",
					"required_mode": "DC",
					"nominal_str": "2.50 V DC",
					"reading_dc": 2.51,
					"reading_ac": 0.0,
					"reading_ohm": 18900.0,
					"verified": false,
					"color": Color(0.1, 0.85, 1.0)
				},
				{
					"id": "ram_tp4_ripple",
					"name": "TP4: RUIDO / RIPPLE VDD",
					"desc": "Filtrado en condensador de desacoplo",
					"required_mode": "AC",
					"nominal_str": "< 0.05 V AC",
					"reading_dc": 0.0,
					"reading_ac": 0.03,
					"reading_ohm": 12000.0,
					"verified": false,
					"color": Color(0.85, 0.35, 1.0)
				},
				{
					"id": "ram_tp5_short",
					"name": "TP5: CAP CERÁMICO C8 (RAM)",
					"desc": "¡CORTO A TIERRA! (Medir en OHM)",
					"required_mode": "OHM",
					"nominal_str": "1.20 V DC / > 10 kΩ",
					"reading_dc": 0.01,
					"reading_ac": 0.0,
					"reading_ohm": 0.1,
					"is_shorted": true,
					"short_diagnosed": false,
					"verified": false,
					"color": Color(1.0, 0.25, 0.35)
				},
				{
					"id": "ram_tp6_spd",
					"name": "TP6: BUS SPD I2C (EEPROM)",
					"desc": "Lectura de perfiles de memoria",
					"required_mode": "DC",
					"nominal_str": "3.30 V DC",
					"reading_dc": 0.0,
					"reading_ac": 0.0,
					"reading_ohm": 22000.0,
					"verified": false,
					"color": Color(0.2, 1.0, 0.5)
				}
			]
		"Fan Cooler":
			if title_label:
				title_label.text = "DIAGNÓSTICO CON MULTÍMETRO DIGITAL // FAN COOLER PWM"
			if brand_label:
				brand_label.text = "FLUKE-CYBER 87V // CONTROLADOR PWM Y TACÓMETRO"
			test_points_data = [
				{
					"id": "fan_tp1_12v",
					"name": "TP1: VCC 12V MOTOR FAN",
					"desc": "Alimentación de bobinas del estator",
					"required_mode": "DC",
					"nominal_str": "12.00 V DC",
					"reading_dc": 12.08,
					"reading_ac": 0.0,
					"reading_ohm": 21000.0,
					"verified": false,
					"color": Color(1.0, 0.85, 0.15)
				},
				{
					"id": "fan_tp2_pwm",
					"name": "TP2: SEÑAL PWM CONTROL",
					"desc": "Modulación por ancho de pulsos",
					"required_mode": "DC",
					"nominal_str": "5.00 V DC",
					"reading_dc": 4.98,
					"reading_ac": 0.0,
					"reading_ohm": 16500.0,
					"verified": false,
					"color": Color(0.95, 0.45, 0.1)
				},
				{
					"id": "fan_tp3_tach",
					"name": "TP3: SENSOR TACH (RPM)",
					"desc": "Lectura de efecto Hall por revolución",
					"required_mode": "DC",
					"nominal_str": "3.30 V DC",
					"reading_dc": 3.32,
					"reading_ac": 0.0,
					"reading_ohm": 11200.0,
					"verified": false,
					"color": Color(0.1, 0.85, 1.0)
				},
				{
					"id": "fan_tp4_ripple",
					"name": "TP4: RUIDO CEM INDUCTIVO",
					"desc": "Ruido de conmutación de motor (AC)",
					"required_mode": "AC",
					"nominal_str": "< 0.20 V AC",
					"reading_dc": 0.0,
					"reading_ac": 0.11,
					"reading_ohm": 14000.0,
					"verified": false,
					"color": Color(0.85, 0.35, 1.0)
				},
				{
					"id": "fan_tp5_short",
					"name": "TP5: DIODO FLYBACK (D2)",
					"desc": "¡CORTO A TIERRA! (Medir en OHM)",
					"required_mode": "OHM",
					"nominal_str": "12.00 V DC / > 10 kΩ",
					"reading_dc": 0.01,
					"reading_ac": 0.0,
					"reading_ohm": 0.1,
					"is_shorted": true,
					"short_diagnosed": false,
					"verified": false,
					"color": Color(1.0, 0.25, 0.35)
				},
				{
					"id": "fan_tp6_pwr",
					"name": "TP6: RETORNO DE TIERRA (GND)",
					"desc": "Masa común y retorno de corriente",
					"required_mode": "DC",
					"nominal_str": "0.00 V DC",
					"reading_dc": 0.0,
					"reading_ac": 0.0,
					"reading_ohm": 0.05,
					"verified": false,
					"color": Color(0.2, 1.0, 0.5)
				}
			]
		"Fuente":
			if title_label:
				title_label.text = "DIAGNÓSTICO CON MULTÍMETRO DIGITAL // FUENTE DE PODER ATX"
			if brand_label:
				brand_label.text = "FLUKE-CYBER 87V // ANALIZADOR DE RIELES ATX"
		_:
			pass

func _ready() -> void:
	layer = 12
	randomize()
	victory_banner.visible = false
	repair_box.visible = false
	
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	btn_repair.pressed.connect(_on_repair_component_pressed)
	btn_calibrate.pressed.connect(_attempt_calibration)
	
	btn_mode_dc.pressed.connect(func(): _set_multimeter_mode("DC"))
	btn_mode_ac.pressed.connect(func(): _set_multimeter_mode("AC"))
	btn_mode_ohm.pressed.connect(func(): _set_multimeter_mode("OHM"))
	
	if target_component != "":
		_apply_component_data()
	
	_set_multimeter_mode("DC")
	_build_test_points_ui()
	_update_multimeter_display("0.00 V", "SELECCIONA UN TEST POINT (TP) PARA COMENZAR", false, 0.0)
	_update_progress()
	
	target_mark.visible = false
	needle.visible = false

func _process(delta: float) -> void:
	if is_needle_spinning:
		needle_angle = wrapf(needle_angle + needle_speed * delta, -PI, PI)
		needle.rotation = needle_angle - NEEDLE_SPRITE_ANGLE

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		minigame_finished.emit(false)
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			get_viewport().set_input_as_handled()
			_attempt_calibration()
			return

func _set_multimeter_mode(mode: String) -> void:
	current_mode = mode
	
	btn_mode_dc.modulate = Color(1.3, 1.3, 1.0) if mode == "DC" else Color(0.65, 0.65, 0.7)
	btn_mode_ac.modulate = Color(1.3, 1.3, 1.0) if mode == "AC" else Color(0.65, 0.65, 0.7)
	btn_mode_ohm.modulate = Color(1.3, 1.3, 1.0) if mode == "OHM" else Color(0.65, 0.65, 0.7)
	
	match mode:
		"DC":
			lbl_mode_badge.text = "[ DC V⎓ ] [ AUTO 20V ]"
		"AC":
			lbl_mode_badge.text = "[ AC V~ ] [ RMS 20V ]"
		"OHM":
			lbl_mode_badge.text = "[ Ω OHM / 🔊 CONT ]"
			
	if active_tp_index >= 0:
		_on_tp_mode_updated()

func _build_test_points_ui() -> void:
	for c in tp_container.get_children():
		c.queue_free()
	tp_button_nodes.clear()
	
	for i in range(test_points_data.size()):
		var tp = test_points_data[i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 44)
		btn.flat = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pressed.connect(_on_tp_button_pressed.bind(i))
		
		var panel = PanelContainer.new()
		panel.name = "CardPanel"
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.08, 0.1, 0.14, 0.95)
		sb.border_width_left = 3
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = tp["color"]
		sb.corner_radius_top_left = 4
		sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_right = 6
		sb.corner_radius_bottom_left = 4
		panel.add_theme_stylebox_override("panel", sb)
		btn.add_child(panel)
		
		var margin = MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_bottom", 4)
		panel.add_child(margin)
		
		var hbox = HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(hbox)
		
		var probe_icon = Label.new()
		probe_icon.name = "ProbeIcon"
		probe_icon.text = "🔴 [TP%d]" % (i + 1)
		probe_icon.add_theme_color_override("font_color", tp["color"])
		probe_icon.add_theme_font_size_override("font_size", 11)
		probe_icon.custom_minimum_size = Vector2(60, 0)
		hbox.add_child(probe_icon)
		
		var vbox_info = VBoxContainer.new()
		vbox_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(vbox_info)
		
		var lbl_name = Label.new()
		lbl_name.text = tp["name"]
		lbl_name.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
		lbl_name.add_theme_font_size_override("font_size", 11)
		vbox_info.add_child(lbl_name)
		
		var lbl_desc = Label.new()
		lbl_desc.text = "%s (%s)" % [tp["desc"], tp["nominal_str"]]
		lbl_desc.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
		lbl_desc.add_theme_font_size_override("font_size", 9)
		vbox_info.add_child(lbl_desc)
		
		var lbl_badge = Label.new()
		lbl_badge.name = "LblBadge"
		lbl_badge.text = "[ SIN MEDIR ]"
		lbl_badge.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		lbl_badge.add_theme_font_size_override("font_size", 10)
		hbox.add_child(lbl_badge)
		
		tp_container.add_child(btn)
		tp_button_nodes.append(btn)

func _on_tp_button_pressed(index: int) -> void:
	if is_completed:
		return
	active_tp_index = index
	_on_tp_mode_updated()

func _get_or_randomize_target_angle(tp: Dictionary) -> float:
	# Si ya tiene un ángulo objetivo asignado, lo preserva
	if not tp.has("target_angle"):
		# Generar posición en un ángulo aleatorio bien repartido por la circunferencia
		var random_degrees = randf_range(-170.0, 170.0)
		# Redondear a múltiplos de 5 grados para alineación nítida
		random_degrees = round(random_degrees / 5.0) * 5.0
		tp["target_angle"] = deg_to_rad(random_degrees)
	return float(tp["target_angle"])

func _on_tp_mode_updated() -> void:
	if active_tp_index < 0 or active_tp_index >= test_points_data.size():
		return
		
	var tp = test_points_data[active_tp_index]
	var req_mode = tp.get("required_mode", "DC")
	
	# Resaltar botón seleccionado en la lista
	_refresh_tp_buttons_styling()
	
	# Obtener o generar ángulo objetivo aleatorio
	target_angle = _get_or_randomize_target_angle(tp)
	_position_target_mark(target_angle)
	
	# CASO 1: LA PARTE YA FUE MEDIDA / REPARADA
	if tp.get("verified", false):
		# La aguja se para en la marca y se le indica al jugador que ya está medido/reparado
		is_needle_spinning = false
		target_mark.visible = true
		target_mark.modulate = Color(0.2, 1.8, 0.5, 1.0)
		needle.visible = true
		needle.rotation = target_angle - NEEDLE_SPRITE_ANGLE # Aguja parada en la marca exacta
		circle_face.modulate = Color(0.3, 1.2, 0.8, 1.0)
		
		var v_str = ""
		if tp["id"] == "tp4_ripple_ac":
			v_str = "%.2f V AC" % float(tp["reading_ac"])
		else:
			v_str = "%.2f V DC" % float(tp["reading_dc"])
			
		_update_multimeter_display(v_str, "✓ ESTA PARTE YA SE MIDIÓ Y SE CALIBRÓ (%s) // SELECCIONA OTRO RIEL." % v_str, false, 12.0)
		lbl_calibration_hint.text = "✓ ¡PARTE YA MEDIDA / REPARADA CON ÉXITO! Selecciona el siguiente punto."
		lbl_calibration_hint.modulate = Color(0.2, 1.0, 0.5)
		btn_calibrate.text = "✓ YA MEDIDO Y REPARADO"
		btn_calibrate.disabled = true
		return
		
	# CASO 2: COMPROBAR SI EL MODO DEL MULTÍMETRO ES CORRECTO
	var mode_is_correct = false
	if tp.get("is_shorted", false):
		if not is_short_repaired:
			mode_is_correct = (current_mode == "OHM")
		else:
			mode_is_correct = (current_mode == "DC")
	else:
		mode_is_correct = (current_mode == req_mode)
		
	if not mode_is_correct:
		# Modo erróneo: apagar giro de la aguja y advertir
		is_needle_spinning = false
		target_mark.visible = false
		needle.visible = false
		circle_face.modulate = Color(0.5, 0.5, 0.5, 0.6)
		
		var warn_msg = ""
		match req_mode:
			"DC":
				warn_msg = "⚠️ ESTE RIEL ES CONTINUO. GIRA AJURO EL DIAL A [ V⎓ DC ] PARA MEDIR."
			"AC":
				warn_msg = "⚠️ ESTA SEÑAL ES RIPPLE/RUIDO ALTERNO. GIRA AJURO EL DIAL A [ V~ AC ] PARA MEDIR."
			"OHM":
				warn_msg = "⚠️ DEBES GIRAR AJURO EL DIAL A [ Ω OHM ] PARA MEDIR LA RESISTENCIA Y DETECTAR EL CORTO."
				
		var disp_val = "0.00 V" if current_mode in ["DC", "AC"] else "O . L"
		_update_multimeter_display(disp_val, warn_msg, true, 0.0)
		lbl_calibration_hint.text = "⚠️ Modo incorrecto. Gira el selector en el multímetro."
		lbl_calibration_hint.modulate = Color(1.0, 0.4, 0.3)
		btn_calibrate.text = "⚠️ SELECCIONA EL MODO CORRECTO EN EL DIAL"
		btn_calibrate.disabled = true
	else:
		# Modo correcto: encender el calibrador analógico con aguja girando
		is_needle_spinning = true
		target_mark.visible = true
		target_mark.modulate = Color(1.0, 1.0, 1.0, 1.0)
		needle.visible = true
		circle_face.modulate = Color(1.0, 1.0, 1.0, 1.0)
		btn_calibrate.disabled = false
		btn_calibrate.text = "🎯 AJUSTAR Y FIJAR VOLTAJE [ESPACIO]"
		
		lbl_calibration_hint.text = "⚡ Presiona [ESPACIO] cuando la aguja se alinee con la marca para calibrar."
		lbl_calibration_hint.modulate = Color(1.0, 0.9, 0.3)
		
		if tp.get("is_shorted", false) and not is_short_repaired:
			_update_multimeter_display("000.1 Ω", "🚨 COMPONENTE SOSPECHOSO. CALIBRA CON [ESPACIO] PARA CONFIRMAR EL CORTO.", true, 0.1)
		elif current_mode == "DC":
			_update_multimeter_display("0.00 V", "SINTONIZANDO SEÑAL... PULSA [ESPACIO] EN LA MARCA.", false, 0.0)
		elif current_mode == "AC":
			_update_multimeter_display("0.00 V", "SINTONIZANDO RIPPLE AC... PULSA [ESPACIO] EN LA MARCA.", false, 0.0)
		else:
			_update_multimeter_display("--- Ω", "MIDIENDO IMPEDANCIA... PULSA [ESPACIO] EN LA MARCA.", false, 0.0)

func _position_target_mark(angle: float) -> void:
	target_mark.pivot_offset = target_mark.size / 2.0
	target_mark.position = CIRCLE_CENTER + Vector2(cos(angle), sin(angle)) * CIRCLE_RADIUS - target_mark.size / 2.0
	target_mark.rotation = angle # Gira el sprite para concordar radialmente con la curva del círculo

func _attempt_calibration() -> void:
	if is_completed or active_tp_index < 0:
		return
		
	var tp = test_points_data[active_tp_index]
	
	# Si ya fue verificado, no volver a calibrar
	if tp.get("verified", false):
		return
		
	var req_mode = tp.get("required_mode", "DC")
	var mode_is_correct = false
	if tp.get("is_shorted", false):
		mode_is_correct = (current_mode == "OHM") if not is_short_repaired else (current_mode == "DC")
	else:
		mode_is_correct = (current_mode == req_mode)
		
	if not mode_is_correct:
		_show_feedback(false, "⚠️ MODO INCORRECTO // GIRA EL DIAL DEL MULTÍMETRO")
		return
		
	# Comprobar diferencia de ángulo con la tolerancia cómoda
	var diff = abs(wrapf(needle_angle - target_angle, -PI, PI))
	if diff <= HIT_TOLERANCE:
		# ¡ACIERTO EN LA MARCA!
		_on_calibration_success(tp)
	else:
		# Desfasado
		_show_feedback(false, "❌ DESFASADO // VUELVE A INTENTAR CON [ESPACIO] JUSTO EN LA MARCA")

func _on_calibration_success(tp: Dictionary) -> void:
	# 1. LA FLECHA SE PARA EXACTAMENTE EN LA MARCA
	is_needle_spinning = false
	needle.rotation = target_angle - NEEDLE_SPRITE_ANGLE
	
	_show_feedback(true, "✓ ¡EXCELENTE! PARTE MEDIDA Y CALIBRADA CON ÉXITO")
	
	if tp.get("is_shorted", false) and not is_short_repaired:
		# Corto diagnosticado en Ohmios
		tp["short_diagnosed"] = true
		repair_box.visible = true
		_update_multimeter_display("000.1 Ω", "🚨 ¡CORTOCIRCUITO CONFIRMADO A TIERRA! (0.1 Ω).", true, 0.1)
		_set_tp_badge(active_tp_index, "🚨 CORTO (0.1 Ω)", Color(1.0, 0.2, 0.3))
		status_label.text = "🚨 ¡Cortocircuito medido en Ohmios! Presiona 'REEMPLAZAR COMPONENTE' para desoldar la pieza dañada."
		status_label.modulate = Color(1.0, 0.3, 0.3)
		lbl_calibration_hint.text = "🚨 Corto localizado en Ohmios. Presiona 'REEMPLAZAR COMPONENTE' para repararlo."
		lbl_calibration_hint.modulate = Color(1.0, 0.3, 0.3)
		btn_calibrate.text = "🚨 CORTO CONFIRMADO // REEMPLAZAR COMPONENTE"
		btn_calibrate.disabled = true
	else:
		# 2. INDICAR AL JUGADOR QUE ESTA PARTE YA SE MIDIÓ / REPARÓ
		tp["verified"] = true
		var val_str = ""
		var bar_v = 0.0
		
		if current_mode == "DC":
			var v = float(tp["reading_dc"])
			val_str = "%.2f V" % v
			bar_v = v
			_update_multimeter_display(val_str, "✓ [TP%d] YA SE MIDIÓ Y SE CALIBRÓ (%.2fV) // PARTE OPERATIVA AL 100%%." % [active_tp_index + 1, v], false, bar_v)
			_set_tp_badge(active_tp_index, "✓ MEDIDO / REPARADO", Color(0.2, 1.0, 0.5))
		elif current_mode == "AC":
			var v = float(tp["reading_ac"])
			val_str = "%.2f V" % v
			bar_v = v * 50.0
			_update_multimeter_display(val_str, "✓ [TP%d] RIPPLE AC MEDIDO Y CALIBRADO DENTRO DE NORMA (%.2fV AC)." % [active_tp_index + 1, v], false, bar_v)
			_set_tp_badge(active_tp_index, "✓ MEDIDO / REPARADO", Color(0.2, 1.0, 0.5))
		else:
			var o = float(tp["reading_ohm"])
			val_str = "%.1f kΩ" % (o / 1000.0)
			bar_v = 10.0
			_update_multimeter_display(val_str, "✓ [TP%d] IMPEDANCIA NORMAL CONFIRMADA (> 10 kΩ) // SIN FUGAS." % [active_tp_index + 1], false, bar_v)
			_set_tp_badge(active_tp_index, "✓ MEDIDO / REPARADO", Color(0.2, 1.0, 0.5))
			
		lbl_calibration_hint.text = "✓ ¡PARTE YA MEDIDA Y REPARADA! Selecciona el siguiente punto en la lista."
		lbl_calibration_hint.modulate = Color(0.2, 1.0, 0.5)
		btn_calibrate.text = "✓ ESTA PARTE YA FUE MEDIDA / REPARADA"
		btn_calibrate.disabled = true
		
	_refresh_tp_buttons_styling()
	_update_progress()
	_check_victory()

func _refresh_tp_buttons_styling() -> void:
	for i in range(tp_button_nodes.size()):
		var b = tp_button_nodes[i]
		var tp = test_points_data[i]
		var panel = b.get_node_or_null("CardPanel") as PanelContainer
		if panel:
			var sb = panel.get_theme_stylebox("panel") as StyleBoxFlat
			if sb:
				if tp.get("verified", false):
					# Estilo verde de éxito permanente
					sb.bg_color = Color(0.04, 0.16, 0.1, 0.95)
					sb.border_color = Color(0.2, 1.0, 0.5, 1.0)
					sb.border_width_left = 6 if i == active_tp_index else 3
				else:
					sb.bg_color = Color(0.12, 0.16, 0.24, 0.98) if i == active_tp_index else Color(0.08, 0.1, 0.14, 0.95)
					sb.border_color = tp["color"]
					sb.border_width_left = 6 if i == active_tp_index else 3

func _show_feedback(success: bool, msg: String) -> void:
	lbl_calibration_hint.text = msg
	if success:
		lbl_calibration_hint.modulate = Color(0.2, 1.0, 0.5)
		var tw = create_tween()
		tw.tween_property(circle_face, "modulate", Color(0.3, 1.8, 0.8), 0.15)
		tw.tween_property(circle_face, "modulate", Color(0.3, 1.2, 0.8, 1.0), 0.25)
		tw.parallel().tween_property(target_mark, "modulate", Color(0.2, 1.8, 0.5), 0.15)
	else:
		lbl_calibration_hint.modulate = Color(1.0, 0.35, 0.35)
		var tw = create_tween()
		tw.tween_property(circle_face, "modulate", Color(1.8, 0.3, 0.3), 0.12)
		tw.tween_property(circle_face, "modulate", Color(1.0, 1.0, 1.0), 0.2)

func _update_multimeter_display(val_str: String, status_msg: String, is_error: bool, bar_val: float) -> void:
	lbl_voltage.text = val_str
	lbl_readout_status.text = status_msg
	
	if is_error:
		lbl_voltage.modulate = Color(1.0, 0.25, 0.35)
		lbl_readout_status.modulate = Color(1.0, 0.45, 0.35)
	else:
		lbl_voltage.modulate = Color(0.1, 0.95, 1.0)
		lbl_readout_status.modulate = Color(0.35, 1.0, 0.6)
		
	lcd_bargraph.max_value = 15.0
	lcd_bargraph.value = clamp(bar_val, 0.0, 15.0)

func _set_tp_badge(index: int, text: String, col: Color) -> void:
	if index >= 0 and index < tp_button_nodes.size():
		var btn = tp_button_nodes[index]
		var badge = btn.find_child("LblBadge", true, false) as Label
		if badge:
			badge.text = text
			badge.add_theme_color_override("font_color", col)

func _on_repair_component_pressed() -> void:
	btn_repair.disabled = true
	var part_repair_name = "COMPONENTE DAÑADO"
	match target_component:
		"RAM":
			part_repair_name = "CONDENSADOR C8 (RAM)"
		"Fan Cooler":
			part_repair_name = "DIODO FLYBACK D2"
		_:
			part_repair_name = "CONDENSADOR C124"
			
	btn_repair.text = "⏳ DESOLDANDO %s..." % part_repair_name
	
	var tw = create_tween()
	tw.tween_property(btn_repair, "modulate", Color(1.5, 1.5, 0.2), 0.3)
	tw.tween_property(btn_repair, "modulate", Color(0.2, 1.5, 0.5), 0.3)
	
	await tw.finished
	await get_tree().create_timer(0.4).timeout
	
	is_short_repaired = true
	repair_box.visible = false
	
	# Restaurar lecturas del circuito según el componente activo
	match target_component:
		"RAM":
			test_points_data[4]["reading_ohm"] = 15200.0
			test_points_data[4]["reading_dc"] = 1.20
			test_points_data[4]["is_shorted"] = false
			test_points_data[4]["required_mode"] = "DC"
			test_points_data[4].erase("target_angle")
			test_points_data[5]["reading_dc"] = 3.30
			status_label.text = "✓ ¡Condensador C8 de la RAM reemplazado! Ahora pon el dial en [V⎓ DC] y calibra TP5 a 1.20V."
		"Fan Cooler":
			test_points_data[4]["reading_ohm"] = 16800.0
			test_points_data[4]["reading_dc"] = 12.00
			test_points_data[4]["is_shorted"] = false
			test_points_data[4]["required_mode"] = "DC"
			test_points_data[4].erase("target_angle")
			test_points_data[5]["reading_dc"] = 0.00
			status_label.text = "✓ ¡Diodo Flyback D2 reemplazado! Ahora pon el dial en [V⎓ DC] y calibra TP5 a 12.00V."
		_:
			test_points_data[4]["reading_ohm"] = 14800.0
			test_points_data[4]["reading_dc"] = 1.24
			test_points_data[4]["is_shorted"] = false
			test_points_data[4]["required_mode"] = "DC"
			test_points_data[4].erase("target_angle")
			test_points_data[5]["reading_dc"] = 3.30
			status_label.text = "✓ ¡Condensador C124 reemplazado! Ahora pon el dial en [V⎓ DC] y calibra TP5 a 1.24V."
			
	status_label.modulate = Color(0.2, 1.0, 0.5)
	
	if active_tp_index >= 0:
		_on_tp_mode_updated()

func _update_progress() -> void:
	var verified_count = 0
	for tp in test_points_data:
		if tp["verified"]:
			verified_count += 1
			
	progress_label.text = "PUNTOS CALIBRADOS / REPARADOS: %d / %d" % [verified_count, test_points_data.size()]
	progress_bar.max_value = test_points_data.size()
	progress_bar.value = verified_count

func _check_victory() -> void:
	if is_completed or not is_short_repaired:
		return
		
	for tp in test_points_data:
		if not tp["verified"]:
			return
			
	is_completed = true
	victory_banner.visible = true
	is_needle_spinning = false
	
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("add_score"):
		gm.add_score(200)
		
	status_label.text = "★ ¡TODOS LOS RIELES MEDIDOS, CALIBRADOS Y REPARADOS! DIAGNÓSTICO EXITOSO (+200 PTS) ★"
	status_label.modulate = Color(0.2, 1.0, 0.5)
	
	await get_tree().create_timer(1.8).timeout
	minigame_finished.emit(true)
