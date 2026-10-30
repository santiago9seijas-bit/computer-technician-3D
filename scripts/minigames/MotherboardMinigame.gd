extends CanvasLayer

# =============================================================================
# MINIJUEGO: DESMONTAJE MAESTRO DE LA PLACA MADRE
# Resume e integra las mecánicas de todos los componentes (excepto la CPU,
# que en la vida real se deja protegida en el zócalo para no doblar sus pines).
# DESMONTAJE NO LINEAL: El usuario puede retirar las piezas en CUALQUIER orden:
# - Cables de Alimentación (ATX 24P y EPS CPU 8P).
# - Tarjeta Gráfica (GPU: Cable PCIe, tornillo de bracket, pestillo PCIe, extracción).
# - Disipador Térmico (Fan Cooler: Cable PWM 4P, 4 tornillos, levantamiento).
# - Almacenamiento SSD M.2 (Armor M.2, tornillo de standoff, resorte 30°, extracción).
# - Memoria RAM (Apertura de trabas laterales y extracción vertical).
#
# Una vez retirados todos los módulos:
# - Tornillos Standoff (6 tornillos de separación al chasis con Cruz o Pala).
# - Extracción de Placa Madre (Desencastre de I/O Shield y levantamiento limpio).
# =============================================================================

signal minigame_finished(success: bool)
signal old_part_extracted()

enum Phase {
	COMPONENTS,
	STANDOFFS,
	EXTRACT_MOBO,
	INSTALL_MOBO,
	STANDOFFS_INSTALL,
	REINSTALL_COMPONENTS,
	COMPLETED
}

var current_phase: Phase = Phase.COMPONENTS
var start_as_empty_slot: bool = false
var is_tutorial_mode: bool = false

# Reinstalación de componentes al montar placa nueva
var is_reinstall_cooler_seated: bool = false
var reinstall_cooler_screws_done: Array[bool] = [false, false, false, false]
var is_reinstall_cooler_pwm_done: bool = false
var is_reinstall_cooler_done: bool = false

var is_reinstall_ram_seated: bool = false
var is_reinstall_ram_top_done: bool = false
var is_reinstall_ram_bot_done: bool = false
var is_reinstall_ram_done: bool = false

var is_reinstall_m2_seated: bool = false
var is_reinstall_m2_screw_done: bool = false
var is_reinstall_m2_done: bool = false

var is_reinstall_gpu_seated: bool = false
var is_reinstall_gpu_latch_done: bool = false
var is_reinstall_gpu_bracket_done: bool = false
var is_reinstall_gpu_cable_done: bool = false
var is_reinstall_gpu_done: bool = false

var is_reinstall_atx_done: bool = false
var is_reinstall_eps_done: bool = false

# 1. Cables
var is_atx24_unplugged: bool = false
var is_eps8_unplugged: bool = false

# 2. GPU
var is_gpu_cable_unplugged: bool = false
var is_gpu_bracket_unscrewed: bool = false
var is_gpu_latch_opened: bool = false
var is_gpu_extracted: bool = false
var gpu_bracket_screw_type: String = "cruz"

# 3. Cooler (4 tornillos)
var is_cooler_pwm_unplugged: bool = false
var cooler_screws_removed: Array[bool] = [false, false, false, false]
var cooler_screw_types: Array[String] = ["cruz", "cruz", "pala", "cruz"]
var is_cooler_extracted: bool = false

# 4. M.2 SSD
var is_m2_armor_removed: bool = false
var is_m2_screw_removed: bool = false
var is_m2_sprung_up: bool = false
var is_m2_extracted: bool = false

# 5. RAM
var is_ram_left_latch: bool = false
var is_ram_right_latch: bool = false
var is_ram_extracted: bool = false

# 6. Standoffs (6 tornillos de chasis)
var standoff_screws_removed: Array[bool] = [false, false, false, false, false, false]
var standoff_screw_types: Array[String] = ["cruz", "cruz", "cruz", "cruz", "pala", "cruz"]

var is_mobo_lifted: bool = false
var is_dragging_mobo: bool = false
var drag_start_y: float = 0.0

# Texturas
var tex_screw_cruz = preload("res://pixel art/tornillo de cruz.png")
var tex_screw_pala = preload("res://pixel art/tornillo de pala.png")

# Nodos UI
@onready var modal_control: Control = $ModalControl
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var phase_tracker: Label = $ModalControl/Panel/VBox/Header/PhaseTracker
@onready var btn_tool_1: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool1
@onready var btn_tool_2: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool2
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel

@onready var work_area: Control = $ModalControl/Panel/VBox/WorkArea
@onready var chassis_tray: Panel = $ModalControl/Panel/VBox/WorkArea/ChassisTray
@onready var mobo_board: Panel = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard
@onready var io_shield: Panel = $ModalControl/Panel/VBox/WorkArea/ChassisTray/IOShield

# 1. Cables
@onready var cable_atx_btn: Button = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard/CableATX
@onready var cable_eps_btn: Button = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard/CableEPS

# 2. GPU
@onready var gpu_container: Panel = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard/GPUContainer
@onready var btn_gpu_cable: Button = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard/GPUContainer/BtnGPUCable
@onready var btn_gpu_bracket: Button = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard/GPUContainer/BtnGPUBracket
@onready var icon_gpu_bracket: TextureRect = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard/GPUContainer/BtnGPUBracket/Icon
@onready var btn_gpu_latch: Button = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard/BtnGPULatch
@onready var btn_extract_gpu: Button = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard/GPUContainer/BtnExtractGPU

# 3. Cooler
@onready var cooler_container: Panel = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard/CoolerContainer
@onready var btn_cooler_pwm: Button = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard/CoolerContainer/BtnPWM
@onready var cooler_screws_box: Control = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard/CoolerContainer/ScrewsBox
@onready var btn_extract_cooler: Button = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard/CoolerContainer/BtnExtractCooler

# 4. M.2
@onready var m2_container: Panel = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard/M2Container
@onready var btn_m2_armor: Button = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard/M2Container/BtnArmorScrew
@onready var icon_m2_armor: TextureRect = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard/M2Container/BtnArmorScrew/Icon
@onready var btn_m2_screw: Button = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard/M2Container/BtnM2Screw
@onready var icon_m2_screw: TextureRect = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard/M2Container/BtnM2Screw/Icon
@onready var m2_pcb_panel: Panel = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard/M2Container/M2PCB
@onready var btn_extract_m2: Button = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard/M2Container/BtnExtractM2

# 5. RAM
@onready var ram_container: Panel = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard/RAMContainer
@onready var btn_ram_latch_top: Button = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard/RAMContainer/BtnLatchTop
@onready var btn_ram_latch_bot: Button = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard/RAMContainer/BtnLatchBot
@onready var btn_extract_ram: Button = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard/RAMContainer/BtnExtractRAM

# 6. Standoffs
@onready var standoffs_container: Control = $ModalControl/Panel/VBox/WorkArea/ChassisTray/MoboBoard/StandoffsContainer
@onready var btn_extract_mobo: Button = $ModalControl/Panel/VBox/WorkArea/BtnExtractMobo
@onready var warning_label: Label = $ModalControl/Panel/VBox/WorkArea/WarningLabel

@onready var btn_tab_quitar: Button = $ModalControl/Panel/VBox/Header/GuidePanel/VBoxGuide/TabsBox/BtnTabQuitar
@onready var btn_tab_poner: Button = $ModalControl/Panel/VBox/Header/GuidePanel/VBoxGuide/TabsBox/BtnTabPoner
@onready var guide_text: Label = $ModalControl/Panel/VBox/Header/GuidePanel/VBoxGuide/GuideText

var cooler_screw_buttons: Array[Button] = []
var cooler_screw_icons: Array[TextureRect] = []
var standoff_buttons: Array[Button] = []
var standoff_icons: Array[TextureRect] = []

func _ready() -> void:
	layer = 12
	_setup_screw_types()
	_setup_ui()
	_update_tool_buttons()
	
	if is_tutorial_mode:
		btn_tab_quitar.pressed.connect(func(): _select_guide_tab(0))
		btn_tab_poner.pressed.connect(func(): _select_guide_tab(1))
	else:
		var tabs = btn_tab_quitar.get_parent()
		if tabs:
			tabs.queue_free()
	
	if start_as_empty_slot:
		_setup_empty_tray_phase()
		_select_guide_tab(1)
	else:
		btn_extract_mobo.text = "▲ EXTRAER PLACA MADRE DEL GABINETE"
		_select_guide_tab(0)
		
	_update_status()

func _select_guide_tab(idx: int) -> void:
	if is_instance_valid(btn_tab_quitar) and is_instance_valid(btn_tab_poner):
		if idx == 0:
			btn_tab_quitar.modulate = Color(1.2, 1.2, 0.4, 1.0)
			btn_tab_poner.modulate = Color(0.7, 0.7, 0.7, 0.7)
		else:
			btn_tab_quitar.modulate = Color(0.7, 0.7, 0.7, 0.7)
			btn_tab_poner.modulate = Color(0.2, 1.0, 0.5, 1.0)
			
	if idx == 0:
		guide_text.text = "PASOS DE DESMONTAJE (QUITAR): 1. Desmontar componentes/cables (ATX/EPS, GPU, Cooler, M.2, RAM) · 2. Retirar 6 standoffs con [1]/[2] · 3. Extraer placa madre"
		if is_tutorial_mode and (is_mobo_install_phase() or current_phase == Phase.INSTALL_MOBO):
			_setup_quitar_phase()
	else:
		guide_text.text = "PASOS DE MONTAJE (CÓMO PONER AL REVÉS): 1. Monta la placa madre con el procesador pegado · 2. Atornilla los 6 standoffs · 3. Haz clic en las piezas transparentes para colocarlas una a una"
		if is_tutorial_mode and (not is_mobo_install_phase() and current_phase != Phase.INSTALL_MOBO):
			_setup_empty_tray_phase()

func _clean_reinstall_overlays() -> void:
	for c in [cooler_container, ram_container, m2_container, gpu_container]:
		if is_instance_valid(c):
			var ov = c.get_node_or_null("GhostOverlay")
			if ov:
				ov.queue_free()

func _create_ghost_overlay(parent_panel: Control, label_text: String) -> Button:
	var old_ov = parent_panel.get_node_or_null("GhostOverlay")
	if old_ov:
		old_ov.queue_free()
		
	var btn = Button.new()
	btn.name = "GhostOverlay"
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.text = label_text
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var sb_normal = StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.12, 0.13, 0.16, 0.65)
	sb_normal.border_width_left = 2
	sb_normal.border_width_top = 2
	sb_normal.border_width_right = 2
	sb_normal.border_width_bottom = 2
	sb_normal.border_color = Color(0.8, 0.8, 0.85, 0.7)
	sb_normal.corner_radius_top_left = 4
	sb_normal.corner_radius_top_right = 4
	sb_normal.corner_radius_bottom_left = 4
	sb_normal.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", sb_normal)
	
	var sb_hover = sb_normal.duplicate()
	sb_hover.bg_color = Color(0.2, 0.22, 0.26, 0.85)
	sb_hover.border_color = Color(1.0, 1.0, 0.4, 1.0)
	btn.add_theme_stylebox_override("hover", sb_hover)
	
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.2, 1.0))
	btn.add_theme_font_size_override("font_size", 9)
	
	parent_panel.add_child(btn)
	return btn

func _setup_quitar_phase() -> void:
	current_phase = Phase.COMPONENTS
	_clean_reinstall_overlays()
	is_mobo_lifted = false
	mobo_board.visible = true
	mobo_board.position = Vector2.ZERO
	mobo_board.modulate = Color(1, 1, 1, 1)
	
	# Restaurar cables
	is_atx24_unplugged = false
	is_eps8_unplugged = false
	cable_atx_btn.visible = true
	cable_atx_btn.disabled = false
	cable_atx_btn.modulate = Color(1, 1, 1, 1)
	cable_atx_btn.text = "🔌 ATX 24P"
	cable_eps_btn.visible = true
	cable_eps_btn.disabled = false
	cable_eps_btn.modulate = Color(1, 1, 1, 1)
	cable_eps_btn.text = "🔌 EPS 8P"
	
	# Restaurar GPU
	is_gpu_cable_unplugged = false
	is_gpu_bracket_unscrewed = false
	is_gpu_latch_opened = false
	is_gpu_extracted = false
	gpu_container.visible = true
	gpu_container.position.y = 195.0
	gpu_container.modulate = Color(1, 1, 1, 1)
	btn_gpu_bracket.visible = true
	btn_gpu_bracket.disabled = false
	btn_gpu_bracket.modulate.a = 1.0
	btn_gpu_cable.visible = true
	btn_gpu_cable.disabled = false
	btn_gpu_cable.modulate.a = 1.0
	btn_gpu_cable.text = "🔌 PCIe 8-Pin"
	btn_gpu_latch.visible = true
	btn_gpu_latch.modulate = Color(1, 1, 1, 1)
	btn_gpu_latch.text = "TRABADO"
	btn_extract_gpu.visible = false
	btn_extract_gpu.disabled = false
	
	# Restaurar Cooler
	is_cooler_pwm_unplugged = false
	is_cooler_extracted = false
	cooler_screws_removed = [false, false, false, false]
	cooler_container.visible = true
	cooler_container.position.y = 35.0
	cooler_container.modulate = Color(1, 1, 1, 1)
	cooler_container.scale = Vector2(1, 1)
	btn_cooler_pwm.visible = true
	btn_cooler_pwm.disabled = false
	btn_cooler_pwm.modulate = Color(1, 1, 1, 1)
	btn_cooler_pwm.text = "🔌 PWM 4P"
	for i in range(4):
		cooler_screw_buttons[i].visible = true
		cooler_screw_buttons[i].disabled = false
		cooler_screw_buttons[i].modulate.a = 1.0
		cooler_screw_icons[i].rotation_degrees = 0.0
	btn_extract_cooler.visible = false
	btn_extract_cooler.disabled = false
	
	# Restaurar M.2
	is_m2_armor_removed = true
	is_m2_screw_removed = false
	is_m2_sprung_up = false
	is_m2_extracted = false
	m2_container.visible = true
	m2_container.position.x = 465.0
	m2_container.modulate = Color(1, 1, 1, 1)
	m2_pcb_panel.rotation_degrees = 0.0
	btn_m2_armor.visible = false
	btn_m2_screw.visible = true
	btn_m2_screw.disabled = false
	btn_m2_screw.modulate.a = 1.0
	icon_m2_screw.rotation_degrees = 0.0
	icon_m2_screw.scale = Vector2(1, 1)
	btn_extract_m2.visible = false
	btn_extract_m2.disabled = false
	
	# Restaurar RAM
	is_ram_left_latch = false
	is_ram_right_latch = false
	is_ram_extracted = false
	ram_container.visible = true
	ram_container.position.y = 35.0
	ram_container.modulate = Color(1, 1, 1, 1)
	btn_ram_latch_top.text = "TRABA SUP"
	btn_ram_latch_top.modulate = Color(1, 1, 1, 1)
	btn_ram_latch_top.disabled = false
	btn_ram_latch_bot.text = "TRABA INF"
	btn_ram_latch_bot.modulate = Color(1, 1, 1, 1)
	btn_ram_latch_bot.disabled = false
	btn_extract_ram.visible = false
	btn_extract_ram.disabled = false
	
	# Standoffs
	standoff_screws_removed = [false, false, false, false, false, false]
	for i in range(6):
		standoff_buttons[i].visible = false
		standoff_buttons[i].disabled = false
		standoff_buttons[i].modulate.a = 1.0
		standoff_icons[i].rotation_degrees = 0.0
		standoff_icons[i].scale = Vector2(1, 1)
		
	btn_extract_mobo.visible = false
	btn_extract_mobo.text = "▲ EXTRAER PLACA MADRE DEL GABINETE"
	if btn_extract_mobo.pressed.is_connected(_seat_new_mobo):
		btn_extract_mobo.pressed.disconnect(_seat_new_mobo)
	if not btn_extract_mobo.pressed.is_connected(_on_extract_mobo_pressed):
		btn_extract_mobo.pressed.connect(_on_extract_mobo_pressed)
	_update_status()

func _setup_empty_tray_phase() -> void:
	current_phase = Phase.INSTALL_MOBO
	_clean_reinstall_overlays()
	is_mobo_lifted = true
	mobo_board.visible = true
	mobo_board.position.x = 0.0
	mobo_board.position.y = -80.0
	mobo_board.modulate = Color(1.0, 1.0, 1.0, 0.75)
	
	# Las partes desmontables deben estar ocultas inicialmente (solo el zócalo del procesador queda pegado a la placa)
	cooler_container.visible = false
	ram_container.visible = false
	m2_container.visible = false
	gpu_container.visible = false
	btn_gpu_latch.visible = false
	cable_atx_btn.visible = false
	cable_eps_btn.visible = false
	
	btn_extract_mobo.visible = true
	btn_extract_mobo.disabled = false
	btn_extract_mobo.text = "⇪ MONTAR PLACA MADRE NUEVA (ARRASTRA O CLIC)"
	if btn_extract_mobo.pressed.is_connected(_on_extract_mobo_pressed):
		btn_extract_mobo.pressed.disconnect(_on_extract_mobo_pressed)
	if not btn_extract_mobo.pressed.is_connected(_seat_new_mobo):
		btn_extract_mobo.pressed.connect(_seat_new_mobo)
		
	standoff_screws_removed = [true, true, true, true, true, true]
	for b in standoff_buttons:
		b.visible = false
		b.disabled = true
	_update_status()

func _seat_new_mobo() -> void:
	var found_idx = -1
	for i in range(GameManager.backpack.size()):
		var it = GameManager.backpack[i]
		if it.get("name") == "Placa Madre" and not it.get("broken", true):
			found_idx = i
			break
	if found_idx != -1:
		GameManager.remove_item_from_backpack(found_idx)
		
	mobo_board.visible = true
	var tw = create_tween().set_parallel(true)
	tw.tween_property(mobo_board, "position:x", 0.0, 0.35)
	tw.tween_property(mobo_board, "position:y", 0.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(mobo_board, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.35)
	tw.chain().tween_callback(func(): mobo_board.modulate = Color(1.0, 1.0, 1.0, 1.0))
	
	btn_extract_mobo.visible = false
	current_phase = Phase.STANDOFFS_INSTALL
	
	# Habilitar los 6 standoffs para que el usuario los atornille primero
	standoff_screws_removed = [true, true, true, true, true, true]
	for i in range(6):
		var btn = standoff_buttons[i]
		var icon = standoff_icons[i]
		btn.visible = true
		btn.disabled = false
		btn.modulate.a = 0.5
		icon.scale = Vector2(0.5, 0.5)
		icon.rotation_degrees = 0.0
		
	# Las piezas aún no se muestran hasta que los 6 tornillos estén colocados
	cooler_container.visible = false
	ram_container.visible = false
	m2_container.visible = false
	gpu_container.visible = false
	btn_gpu_latch.visible = false
	cable_atx_btn.visible = false
	cable_eps_btn.visible = false
	
	_show_warning("✓ Placa encajada con la CPU protegida. Atornilla los 6 tornillos Standoff del chasis.", Color(0.2, 1.0, 0.4))
	_update_status()

func _on_mobo_board_gui_input(event: InputEvent) -> void:
	if current_phase == Phase.EXTRACT_MOBO:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging_mobo = true
				drag_start_y = event.global_position.y
			else:
				if is_dragging_mobo:
					is_dragging_mobo = false
					var diff = drag_start_y - event.global_position.y
					if diff >= 30.0:
						_on_extract_mobo_pressed()
					else:
						var tw = create_tween()
						tw.tween_property(mobo_board, "position:y", 0.0, 0.2)
		elif event is InputEventMouseMotion and is_dragging_mobo:
			var pull = clamp(drag_start_y - event.global_position.y, 0.0, 60.0)
			mobo_board.position.y = -pull
			
	elif current_phase == Phase.INSTALL_MOBO:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging_mobo = true
				drag_start_y = event.global_position.y
			else:
				if is_dragging_mobo:
					is_dragging_mobo = false
					# Tanto si se hace clic como si se arrastra hacia abajo, se coloca la placa
					_seat_new_mobo()
		elif event is InputEventMouseMotion and is_dragging_mobo:
			var push = clamp(event.global_position.y - drag_start_y, 0.0, 80.0)
			mobo_board.position.y = -80.0 + push

func _setup_screw_types() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	gpu_bracket_screw_type = "cruz" if rng.randf() > 0.3 else "pala"
	for i in range(4):
		cooler_screw_types[i] = "cruz" if rng.randf() > 0.4 else "pala"
		cooler_screws_removed[i] = false
	for i in range(6):
		standoff_screw_types[i] = "cruz" if rng.randf() > 0.35 else "pala"
		standoff_screws_removed[i] = false

func _setup_ui() -> void:
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	btn_tool_1.pressed.connect(func(): GameManager.select_tool(1))
	btn_tool_2.pressed.connect(func(): GameManager.select_tool(2))
	GameManager.tool_selected.connect(_on_tool_selected)
	
	# 1. Cables
	mobo_board.gui_input.connect(_on_mobo_board_gui_input)
	cable_atx_btn.pressed.connect(_on_cable_atx_pressed)
	cable_eps_btn.pressed.connect(_on_cable_eps_pressed)
	
	# 2. GPU
	icon_gpu_bracket.texture = tex_screw_cruz if gpu_bracket_screw_type == "cruz" else tex_screw_pala
	btn_gpu_cable.pressed.connect(_on_gpu_cable_pressed)
	btn_gpu_bracket.pressed.connect(_on_gpu_bracket_pressed)
	btn_gpu_latch.pressed.connect(_on_gpu_latch_pressed)
	btn_extract_gpu.pressed.connect(_on_extract_gpu_pressed)
	btn_extract_gpu.visible = false
	
	# 3. Cooler
	btn_cooler_pwm.pressed.connect(_on_cooler_pwm_pressed)
	btn_extract_cooler.pressed.connect(_on_extract_cooler_pressed)
	btn_extract_cooler.visible = false
	
	cooler_screw_buttons.clear()
	cooler_screw_icons.clear()
	for i in range(4):
		var btn = cooler_screws_box.get_node_or_null("Screw" + str(i + 1)) as Button
		if btn:
			var icon = btn.get_node_or_null("Icon") as TextureRect
			if icon:
				icon.texture = tex_screw_cruz if cooler_screw_types[i] == "cruz" else tex_screw_pala
				cooler_screw_icons.append(icon)
			btn.pressed.connect(_on_cooler_screw_pressed.bind(i))
			cooler_screw_buttons.append(btn)
			
	# 4. M.2
	btn_m2_armor.visible = false
	icon_m2_screw.texture = tex_screw_cruz
	icon_m2_screw.pivot_offset = Vector2(10, 10)
	btn_m2_screw.pressed.connect(_on_m2_screw_pressed)
	btn_m2_screw.visible = true
	btn_extract_m2.pressed.connect(_on_extract_m2_pressed)
	btn_extract_m2.visible = false
	
	# 5. RAM
	btn_ram_latch_top.pressed.connect(_on_ram_latch_pressed.bind("top"))
	btn_ram_latch_bot.pressed.connect(_on_ram_latch_pressed.bind("bot"))
	btn_extract_ram.pressed.connect(_on_extract_ram_pressed)
	btn_extract_ram.visible = false
	
	# 6. Standoffs
	standoff_buttons.clear()
	standoff_icons.clear()
	for i in range(6):
		var btn = standoffs_container.get_node_or_null("Standoff" + str(i + 1)) as Button
		if btn:
			var icon = btn.get_node_or_null("Icon") as TextureRect
			if icon:
				icon.texture = tex_screw_cruz if standoff_screw_types[i] == "cruz" else tex_screw_pala
				standoff_icons.append(icon)
			btn.pressed.connect(_on_standoff_pressed.bind(i))
			standoff_buttons.append(btn)
			btn.visible = false
			
	# 7. Extracción Placa Madre
	btn_extract_mobo.pressed.connect(_on_extract_mobo_pressed)
	btn_extract_mobo.visible = false
	warning_label.text = ""

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_1:
			GameManager.select_tool(1)
		elif event.keycode == KEY_2:
			GameManager.select_tool(2)
		elif event.keycode == KEY_ESCAPE:
			minigame_finished.emit(false)

func _on_tool_selected(_tool_id: int) -> void:
	_update_tool_buttons()

func _update_tool_buttons() -> void:
	var active = GameManager.equipped_tool
	btn_tool_1.modulate = Color(1.2, 1.2, 0.4) if active == 1 else Color(0.8, 0.8, 0.8)
	btn_tool_2.modulate = Color(1.2, 1.2, 0.4) if active == 2 else Color(0.8, 0.8, 0.8)

# =============================================================================
# ESTADO DE DESMONTAJE LIBRE
# =============================================================================
func _are_cables_done() -> bool:
	return is_atx24_unplugged and is_eps8_unplugged

func _is_gpu_done() -> bool:
	return is_gpu_extracted

func _is_cooler_done() -> bool:
	return is_cooler_extracted

func _is_m2_done() -> bool:
	return is_m2_extracted

func _is_ram_done() -> bool:
	return is_ram_extracted

func _get_cleared_components_count() -> int:
	var c = 0
	if _are_cables_done(): c += 1
	if _is_gpu_done(): c += 1
	if _is_cooler_done(): c += 1
	if _is_m2_done(): c += 1
	if _is_ram_done(): c += 1
	return c

func _check_all_components_cleared() -> void:
	var cleared = _get_cleared_components_count()
	if cleared >= 5:
		current_phase = Phase.STANDOFFS
		for btn in standoff_buttons:
			btn.visible = true
			btn.modulate.a = 0.0
			var tw_st = create_tween()
			tw_st.tween_property(btn, "modulate:a", 1.0, 0.25)
		_show_warning("✓ ¡Placa totalmente despejada! Desatornilla los 6 tornillos Standoff del chasis.", Color(0.2, 1.0, 0.4))
	_update_status()

# =============================================================================
# 1. CABLES DE ALIMENTACIÓN
# =============================================================================
func is_mobo_install_phase() -> bool:
	return current_phase in [Phase.STANDOFFS_INSTALL, Phase.REINSTALL_COMPONENTS]

func _start_reinstall_components_phase() -> void:
	current_phase = Phase.REINSTALL_COMPONENTS
	_clean_reinstall_overlays()
	
	is_reinstall_cooler_seated = false
	reinstall_cooler_screws_done = [false, false, false, false]
	is_reinstall_cooler_pwm_done = false
	is_reinstall_cooler_done = false
	
	is_reinstall_ram_seated = false
	is_reinstall_ram_top_done = false
	is_reinstall_ram_bot_done = false
	is_reinstall_ram_done = false
	
	is_reinstall_m2_seated = false
	is_reinstall_m2_screw_done = false
	is_reinstall_m2_done = false
	
	is_reinstall_gpu_seated = false
	is_reinstall_gpu_latch_done = false
	is_reinstall_gpu_bracket_done = false
	is_reinstall_gpu_cable_done = false
	is_reinstall_gpu_done = false
	
	is_reinstall_atx_done = false
	is_reinstall_eps_done = false
	
	_show_warning("✓ ¡Standoffs asegurados! Haz clic en cada pieza para colocarla, fijar sus tornillos y conectarla.", Color(0.2, 1.0, 0.4))
	
	# Mostrar las piezas transparentes neutrales (sin tinte azul)
	_setup_transparent_cooler()
	_setup_transparent_ram()
	_setup_transparent_m2()
	_setup_transparent_gpu()
	_setup_transparent_cables()
	
	_update_status()

func _setup_transparent_cooler() -> void:
	cooler_container.visible = true
	cooler_container.position.y = 35.0
	cooler_container.scale = Vector2(1, 1)
	cooler_container.modulate = Color(1.0, 1.0, 1.0, 0.4)
	btn_extract_cooler.visible = false
	btn_cooler_pwm.visible = false
	for b in cooler_screw_buttons:
		b.visible = false
	var btn = _create_ghost_overlay(cooler_container, "⇪ CLIC PARA COLOCAR\nFAN COOLER")
	btn.pressed.connect(_on_ghost_cooler_clicked)

func _setup_transparent_ram() -> void:
	ram_container.visible = true
	ram_container.position.y = 35.0
	ram_container.modulate = Color(1.0, 1.0, 1.0, 0.4)
	btn_extract_ram.visible = false
	btn_ram_latch_top.visible = false
	btn_ram_latch_bot.visible = false
	var btn = _create_ghost_overlay(ram_container, "⇪ CLIC PARA COLOCAR\nMEMORIA RAM")
	btn.pressed.connect(_on_ghost_ram_clicked)

func _setup_transparent_m2() -> void:
	m2_container.visible = true
	m2_container.position.x = 465.0
	m2_container.modulate = Color(1.0, 1.0, 1.0, 0.4)
	m2_pcb_panel.rotation_degrees = 0.0
	btn_extract_m2.visible = false
	btn_m2_armor.visible = false
	btn_m2_screw.visible = false
	var btn = _create_ghost_overlay(m2_container, "⇪ CLIC PARA COLOCAR\nSSD M.2")
	btn.pressed.connect(_on_ghost_m2_clicked)

func _setup_transparent_gpu() -> void:
	gpu_container.visible = true
	gpu_container.position.y = 195.0
	gpu_container.modulate = Color(1.0, 1.0, 1.0, 0.4)
	btn_extract_gpu.visible = false
	btn_gpu_bracket.visible = false
	btn_gpu_cable.visible = false
	btn_gpu_latch.visible = false
	var btn = _create_ghost_overlay(gpu_container, "⇪ CLIC PARA COLOCAR\nTARJETA GPU")
	btn.pressed.connect(_on_ghost_gpu_clicked)

func _setup_transparent_cables() -> void:
	cable_atx_btn.visible = true
	cable_atx_btn.disabled = false
	cable_atx_btn.text = "🔌 CONECTAR\nATX 24P"
	cable_atx_btn.modulate = Color(1.0, 0.85, 0.2, 0.8)
	
	cable_eps_btn.visible = true
	cable_eps_btn.disabled = false
	cable_eps_btn.text = "🔌 CONECTAR\nEPS 8P"
	cable_eps_btn.modulate = Color(1.0, 0.85, 0.2, 0.8)

# --- 1. FAN COOLER ---
func _on_ghost_cooler_clicked() -> void:
	if is_reinstall_cooler_seated: return
	is_reinstall_cooler_seated = true
	var overlay = cooler_container.get_node_or_null("GhostOverlay")
	if overlay: overlay.queue_free()
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(cooler_container, "modulate", Color(1, 1, 1, 1), 0.2)
	
	for i in range(4):
		var b = cooler_screw_buttons[i]
		var icon = cooler_screw_icons[i]
		b.visible = true
		b.disabled = false
		b.modulate.a = 0.5
		icon.scale = Vector2(0.5, 0.5)
		icon.rotation_degrees = 0.0
		
	btn_cooler_pwm.visible = true
	btn_cooler_pwm.disabled = false
	btn_cooler_pwm.text = "🔌 CONECTAR PWM"
	btn_cooler_pwm.modulate = Color(1.0, 0.85, 0.2)
	
	_show_warning("✓ Fan Cooler posicionado. Atornilla los 4 tornillos con [1]/[2] y conecta el cable PWM.", Color(1.0, 0.85, 0.2))
	_update_status()

func _on_reinstall_cooler_screw(idx: int) -> void:
	if reinstall_cooler_screws_done[idx]: return
	var req = 1 if cooler_screw_types[idx] == "cruz" else 2
	var tname = "Cruz [1]" if req == 1 else "Pala [2]"
	if GameManager.equipped_tool != req:
		_show_warning("Usa Destornillador " + tname + " para este tornillo del cooler.", Color(1.0, 0.3, 0.3))
		return
	reinstall_cooler_screws_done[idx] = true
	var btn = cooler_screw_buttons[idx]
	var icon = cooler_screw_icons[idx]
	var tw = create_tween().set_parallel(true)
	tw.tween_property(icon, "rotation_degrees", -720.0, 0.25)
	tw.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.25)
	tw.tween_property(btn, "modulate:a", 1.0, 0.25)
	btn.disabled = true
	_check_cooler_reinstall_done()

func _on_reinstall_cooler_pwm() -> void:
	if is_reinstall_cooler_pwm_done: return
	is_reinstall_cooler_pwm_done = true
	btn_cooler_pwm.disabled = true
	btn_cooler_pwm.text = "✓ PWM OK"
	btn_cooler_pwm.modulate = Color(0.2, 1.0, 0.4)
	_show_warning("✓ Cable PWM 4P conectado.", Color(0.2, 1.0, 0.4))
	_check_cooler_reinstall_done()

func _check_cooler_reinstall_done() -> void:
	var all_screws = true
	for s in reinstall_cooler_screws_done:
		if not s: all_screws = false; break
	if all_screws and is_reinstall_cooler_pwm_done and not is_reinstall_cooler_done:
		is_reinstall_cooler_done = true
		_show_warning("✓ ¡Fan Cooler completamente atornillado y conectado!", Color(0.2, 1.0, 0.4))
		_check_reinstall_completed()
	else:
		_update_status()

# --- 2. MEMORIA RAM ---
func _on_ghost_ram_clicked() -> void:
	if is_reinstall_ram_seated: return
	is_reinstall_ram_seated = true
	var overlay = ram_container.get_node_or_null("GhostOverlay")
	if overlay: overlay.queue_free()
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(ram_container, "modulate", Color(1, 1, 1, 1), 0.2)
	
	btn_ram_latch_top.visible = true
	btn_ram_latch_top.disabled = false
	btn_ram_latch_top.text = "CERRAR TRABA"
	btn_ram_latch_top.modulate = Color(1.0, 0.85, 0.2)
	
	btn_ram_latch_bot.visible = true
	btn_ram_latch_bot.disabled = false
	btn_ram_latch_bot.text = "CERRAR TRABA"
	btn_ram_latch_bot.modulate = Color(1.0, 0.85, 0.2)
	
	_show_warning("✓ Memoria RAM calzada en el zócalo. Cierra las 2 trabas de sujeción.", Color(1.0, 0.85, 0.2))
	_update_status()

func _on_reinstall_ram_latch(pos: String) -> void:
	if pos == "top":
		if is_reinstall_ram_top_done: return
		is_reinstall_ram_top_done = true
		btn_ram_latch_top.text = "✓ TRABA SUP"
		btn_ram_latch_top.modulate = Color(0.2, 1.0, 0.4)
		btn_ram_latch_top.disabled = true
	else:
		if is_reinstall_ram_bot_done: return
		is_reinstall_ram_bot_done = true
		btn_ram_latch_bot.text = "✓ TRABA INF"
		btn_ram_latch_bot.modulate = Color(0.2, 1.0, 0.4)
		btn_ram_latch_bot.disabled = true
		
	if is_reinstall_ram_top_done and is_reinstall_ram_bot_done and not is_reinstall_ram_done:
		is_reinstall_ram_done = true
		_show_warning("✓ ¡Memoria RAM asegurada con ambas trabas bloqueadas!", Color(0.2, 1.0, 0.4))
		_check_reinstall_completed()
	else:
		_update_status()

# --- 3. SSD M.2 ---
func _on_ghost_m2_clicked() -> void:
	if is_reinstall_m2_seated: return
	is_reinstall_m2_seated = true
	var overlay = m2_container.get_node_or_null("GhostOverlay")
	if overlay: overlay.queue_free()
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(m2_container, "modulate", Color(1, 1, 1, 1), 0.2)
	
	btn_m2_screw.visible = true
	btn_m2_screw.disabled = false
	btn_m2_screw.modulate.a = 0.5
	icon_m2_screw.scale = Vector2(0.5, 0.5)
	icon_m2_screw.rotation_degrees = 0.0
	
	_show_warning("✓ SSD M.2 insertado. Atornilla el tornillo con Destornillador Cruz [1].", Color(1.0, 0.85, 0.2))
	_update_status()

func _on_reinstall_m2_screw_pressed() -> void:
	if is_reinstall_m2_screw_done: return
	if GameManager.equipped_tool != 1:
		_show_warning("Usa Destornillador Cruz fino [1] para atornillar el SSD M.2.", Color(1.0, 0.3, 0.3))
		return
	is_reinstall_m2_screw_done = true
	is_reinstall_m2_done = true
	var tw = create_tween().set_parallel(true)
	tw.tween_property(icon_m2_screw, "rotation_degrees", -720.0, 0.25)
	tw.tween_property(icon_m2_screw, "scale", Vector2(1.0, 1.0), 0.25)
	tw.tween_property(btn_m2_screw, "modulate:a", 1.0, 0.25)
	btn_m2_screw.disabled = true
	
	_show_warning("✓ ¡SSD M.2 fijado y asegurado con su tornillo!", Color(0.2, 1.0, 0.4))
	_check_reinstall_completed()

# --- 4. GPU ---
func _on_ghost_gpu_clicked() -> void:
	if is_reinstall_gpu_seated: return
	is_reinstall_gpu_seated = true
	var overlay = gpu_container.get_node_or_null("GhostOverlay")
	if overlay: overlay.queue_free()
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(gpu_container, "modulate", Color(1, 1, 1, 1), 0.2)
	
	btn_gpu_latch.visible = true
	btn_gpu_latch.disabled = false
	btn_gpu_latch.text = "TRABAR PESTILLO"
	btn_gpu_latch.modulate = Color(1.0, 0.85, 0.2)
	
	btn_gpu_bracket.visible = true
	btn_gpu_bracket.disabled = false
	btn_gpu_bracket.modulate.a = 0.5
	icon_gpu_bracket.scale = Vector2(0.5, 0.5)
	icon_gpu_bracket.rotation_degrees = 0.0
	
	btn_gpu_cable.visible = true
	btn_gpu_cable.disabled = false
	btn_gpu_cable.text = "🔌 CONECTAR PCIe 8P"
	btn_gpu_cable.modulate = Color(1.0, 0.85, 0.2)
	
	_show_warning("✓ GPU calzada en el zócalo. Traba el pestillo, atornilla el bracket y conecta el cable PCIe.", Color(1.0, 0.85, 0.2))
	_update_status()

func _on_reinstall_gpu_latch() -> void:
	if is_reinstall_gpu_latch_done: return
	is_reinstall_gpu_latch_done = true
	btn_gpu_latch.text = "✓ TRABADO"
	btn_gpu_latch.modulate = Color(0.2, 1.0, 0.4)
	btn_gpu_latch.disabled = true
	_show_warning("✓ Pestillo PCIe trabado.", Color(0.2, 1.0, 0.4))
	_check_gpu_reinstall_done()

func _on_reinstall_gpu_bracket() -> void:
	if is_reinstall_gpu_bracket_done: return
	var req = 1 if gpu_bracket_screw_type == "cruz" else 2
	var tname = "Cruz [1]" if req == 1 else "Pala [2]"
	if GameManager.equipped_tool != req:
		_show_warning("Usa Destornillador " + tname + " para el tornillo del bracket PCI.", Color(1.0, 0.3, 0.3))
		return
	is_reinstall_gpu_bracket_done = true
	var tw = create_tween().set_parallel(true)
	tw.tween_property(icon_gpu_bracket, "rotation_degrees", -720.0, 0.25)
	tw.tween_property(icon_gpu_bracket, "scale", Vector2(1.0, 1.0), 0.25)
	tw.tween_property(btn_gpu_bracket, "modulate:a", 1.0, 0.25)
	btn_gpu_bracket.disabled = true
	_show_warning("✓ Tornillo del bracket PCI atornillado.", Color(0.2, 1.0, 0.4))
	_check_gpu_reinstall_done()

func _on_reinstall_gpu_cable() -> void:
	if is_reinstall_gpu_cable_done: return
	is_reinstall_gpu_cable_done = true
	btn_gpu_cable.disabled = true
	btn_gpu_cable.text = "✓ PCIe 8P OK"
	btn_gpu_cable.modulate = Color(0.2, 1.0, 0.4)
	_show_warning("✓ Cable PCIe 8-Pin conectado a la GPU.", Color(0.2, 1.0, 0.4))
	_check_gpu_reinstall_done()

func _check_gpu_reinstall_done() -> void:
	if is_reinstall_gpu_latch_done and is_reinstall_gpu_bracket_done and is_reinstall_gpu_cable_done and not is_reinstall_gpu_done:
		is_reinstall_gpu_done = true
		_show_warning("✓ ¡Tarjeta Gráfica completamente trabada, atornillada y conectada!", Color(0.2, 1.0, 0.4))
		_check_reinstall_completed()
	else:
		_update_status()

# --- 5. CABLES ---
func _on_ghost_atx_clicked() -> void:
	if is_reinstall_atx_done: return
	is_reinstall_atx_done = true
	cable_atx_btn.disabled = true
	cable_atx_btn.text = "✓ ATX 24P CONECTADO"
	var tw = create_tween().set_parallel(true)
	tw.tween_property(cable_atx_btn, "modulate", Color(0.2, 1.0, 0.4, 1.0), 0.25)
	
	_show_warning("✓ Arnés principal ATX 24P conectado con seguro.", Color(0.2, 1.0, 0.4))
	_check_reinstall_completed()

func _on_ghost_eps_clicked() -> void:
	if is_reinstall_eps_done: return
	is_reinstall_eps_done = true
	cable_eps_btn.disabled = true
	cable_eps_btn.text = "✓ EPS 8P CONECTADO"
	var tw = create_tween().set_parallel(true)
	tw.tween_property(cable_eps_btn, "modulate", Color(0.2, 1.0, 0.4, 1.0), 0.25)
	
	_show_warning("✓ Conector auxiliar EPS 8P de CPU conectado.", Color(0.2, 1.0, 0.4))
	_check_reinstall_completed()

func _check_reinstall_completed() -> void:
	var all_done = (
		is_reinstall_cooler_done and
		is_reinstall_ram_done and
		is_reinstall_m2_done and
		is_reinstall_gpu_done and
		is_reinstall_atx_done and
		is_reinstall_eps_done
	)
	if all_done:
		current_phase = Phase.COMPLETED
		_update_status()
		_show_warning("✓ ¡REPARACIÓN COMPLETADA! Placa madre y módulos reinstalados con total éxito.", Color(0.2, 1.0, 0.4))
		await get_tree().create_timer(1.6).timeout
		minigame_finished.emit(true)
	else:
		_update_status()

func _on_cable_atx_pressed() -> void:
	if current_phase == Phase.REINSTALL_COMPONENTS:
		_on_ghost_atx_clicked()
		return

	if is_atx24_unplugged: return
	is_atx24_unplugged = true
	cable_atx_btn.disabled = true
	var tw = create_tween().set_parallel(true)
	tw.tween_property(cable_atx_btn, "position:x", cable_atx_btn.position.x + 35.0, 0.3)
	tw.tween_property(cable_atx_btn, "modulate:a", 0.0, 0.3)
	_show_warning("✓ Clip del conector ATX 24P presionado y liberado.", Color(0.2, 1.0, 0.4))
	_check_phase_cables()

func _on_cable_eps_pressed() -> void:
	if current_phase == Phase.REINSTALL_COMPONENTS:
		_on_ghost_eps_clicked()
		return

	if is_eps8_unplugged: return
	is_eps8_unplugged = true
	cable_eps_btn.disabled = true
	var tw = create_tween().set_parallel(true)
	tw.tween_property(cable_eps_btn, "position:y", cable_eps_btn.position.y - 35.0, 0.3)
	tw.tween_property(cable_eps_btn, "modulate:a", 0.0, 0.3)
	_show_warning("✓ Conector auxiliar EPS CPU 8P desconectado.", Color(0.2, 1.0, 0.4))
	_check_phase_cables()

func _check_mains_connected() -> void:
	_check_reinstall_completed()

func _check_phase_cables() -> void:
	if _are_cables_done():
		_show_warning("✓ Cables de poder (ATX 24P y EPS 8P) retirados.", Color(0.2, 1.0, 0.4))
	_check_all_components_cleared()

# =============================================================================
# 2. TARJETA GRÁFICA (GPU)
# =============================================================================
func _on_gpu_cable_pressed() -> void:
	if current_phase == Phase.REINSTALL_COMPONENTS:
		_on_reinstall_gpu_cable()
		return

	if is_gpu_cable_unplugged: return
	is_gpu_cable_unplugged = true
	btn_gpu_cable.disabled = true
	var tw = create_tween().set_parallel(true)
	tw.tween_property(btn_gpu_cable, "position:y", btn_gpu_cable.position.y - 25.0, 0.25)
	tw.tween_property(btn_gpu_cable, "modulate:a", 0.0, 0.25)
	_show_warning("✓ Cable PCIe 8P de la GPU desconectado.", Color(0.2, 1.0, 0.4))
	_check_gpu_ready()

func _on_gpu_bracket_pressed() -> void:
	if current_phase == Phase.REINSTALL_COMPONENTS:
		_on_reinstall_gpu_bracket()
		return

	if is_gpu_bracket_unscrewed: return
	var req = 1 if gpu_bracket_screw_type == "cruz" else 2
	var tname = "Cruz [1]" if req == 1 else "Pala [2]"
	if GameManager.equipped_tool != req:
		_show_warning("Usa el Destornillador " + tname + " para el tornillo del bracket PCI.", Color(1.0, 0.3, 0.3))
		return
		
	is_gpu_bracket_unscrewed = true
	btn_gpu_bracket.disabled = true
	var tw = create_tween().set_parallel(true)
	tw.tween_property(icon_gpu_bracket, "rotation_degrees", 720.0, 0.3)
	tw.tween_property(btn_gpu_bracket, "modulate:a", 0.0, 0.3)
	_show_warning("✓ Tornillo de chasis del bracket PCI retirado.", Color(0.2, 1.0, 0.4))
	_check_gpu_ready()

func _on_gpu_latch_pressed() -> void:
	if current_phase == Phase.REINSTALL_COMPONENTS:
		_on_reinstall_gpu_latch()
		return

	if is_gpu_latch_opened: return
	is_gpu_latch_opened = true
	btn_gpu_latch.text = "ABIERTO"
	btn_gpu_latch.modulate = Color(0.2, 1.0, 0.4)
	_show_warning("✓ Pestillo PCIe desbloqueado.", Color(0.2, 1.0, 0.4))
	_check_gpu_ready()

func _check_gpu_ready() -> void:
	if is_gpu_cable_unplugged and is_gpu_bracket_unscrewed and is_gpu_latch_opened and not is_gpu_extracted:
		btn_extract_gpu.visible = true
		btn_extract_gpu.modulate = Color(1, 1, 1, 0)
		var tw = create_tween()
		tw.tween_property(btn_extract_gpu, "modulate:a", 1.0, 0.2)

func _on_extract_gpu_pressed() -> void:
	if is_gpu_extracted: return
	is_gpu_extracted = true
	btn_extract_gpu.disabled = true
	btn_gpu_latch.visible = false
	var tw = create_tween().set_parallel(true)
	tw.tween_property(gpu_container, "position:y", gpu_container.position.y - 80.0, 0.4).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(gpu_container, "modulate:a", 0.0, 0.4)
	await tw.finished
	gpu_container.visible = false
	_show_warning("✓ Tarjeta Gráfica retirada del zócalo PCIe.", Color(0.2, 1.0, 0.4))
	_check_all_components_cleared()

# =============================================================================
# 3. DISIPADOR (FAN COOLER)
# =============================================================================
func _on_cooler_pwm_pressed() -> void:
	if current_phase == Phase.REINSTALL_COMPONENTS:
		_on_reinstall_cooler_pwm()
		return

	if is_cooler_pwm_unplugged: return
	is_cooler_pwm_unplugged = true
	btn_cooler_pwm.disabled = true
	btn_cooler_pwm.text = "✓ PWM OFF"
	btn_cooler_pwm.modulate = Color(0.2, 1.0, 0.4)
	_show_warning("✓ Conector PWM de 4 pines desconectado.", Color(0.2, 1.0, 0.4))
	_check_cooler_ready()

func _on_cooler_screw_pressed(idx: int) -> void:
	if current_phase == Phase.REINSTALL_COMPONENTS:
		_on_reinstall_cooler_screw(idx)
		return

	if cooler_screws_removed[idx]: return
	var req = 1 if cooler_screw_types[idx] == "cruz" else 2
	var tname = "Cruz [1]" if req == 1 else "Pala [2]"
	if GameManager.equipped_tool != req:
		_show_warning("Usa Destornillador " + tname + " para este tornillo del disipador.", Color(1.0, 0.3, 0.3))
		return
		
	cooler_screws_removed[idx] = true
	var btn = cooler_screw_buttons[idx]
	var icon = cooler_screw_icons[idx]
	var tw = create_tween().set_parallel(true)
	tw.tween_property(icon, "rotation_degrees", 720.0, 0.3)
	tw.tween_property(btn, "modulate:a", 0.0, 0.3)
	btn.disabled = true
	
	var rem = 0
	for r in cooler_screws_removed:
		if not r: rem += 1
	_show_warning("✓ Tornillo de cooler retirado. Restantes: " + str(rem) + "/4", Color(0.4, 1.0, 0.4))
	_check_cooler_ready()

func _check_cooler_ready() -> void:
	var all_screws = true
	for r in cooler_screws_removed:
		if not r: all_screws = false; break
	if is_cooler_pwm_unplugged and all_screws and not is_cooler_extracted:
		btn_extract_cooler.visible = true
		btn_extract_cooler.modulate = Color(1, 1, 1, 0)
		var tw = create_tween()
		tw.tween_property(btn_extract_cooler, "modulate:a", 1.0, 0.2)

func _on_extract_cooler_pressed() -> void:
	if is_cooler_extracted: return
	is_cooler_extracted = true
	btn_extract_cooler.disabled = true
	var tw = create_tween().set_parallel(true)
	tw.tween_property(cooler_container, "scale", Vector2(1.15, 1.15), 0.35)
	tw.tween_property(cooler_container, "modulate:a", 0.0, 0.35)
	await tw.finished
	cooler_container.visible = false
	_show_warning("✓ Fan Cooler retirado. (CPU protegida en su socket ✓).", Color(0.2, 1.0, 0.4))
	_check_all_components_cleared()

# =============================================================================
# 4. ALMACENAMIENTO SSD M.2 (NVME)
# =============================================================================
func _on_m2_armor_pressed() -> void:
	pass

func _on_m2_screw_pressed() -> void:
	if current_phase == Phase.REINSTALL_COMPONENTS:
		_on_reinstall_m2_screw_pressed()
		return

	if is_m2_screw_removed: return
	if GameManager.equipped_tool != 1:
		_show_warning("Usa Destornillador Cruz fino [1] para el micro-tornillo M.2.", Color(1.0, 0.3, 0.3))
		return
	is_m2_screw_removed = true
	btn_m2_screw.disabled = true
	var tw = create_tween().set_parallel(true)
	tw.tween_property(icon_m2_screw, "rotation_degrees", 720.0, 0.3)
	tw.tween_property(btn_m2_screw, "modulate:a", 0.0, 0.3)
	await tw.finished
	btn_m2_screw.visible = false
	
	# Efecto de elevación por resorte a 30°
	is_m2_sprung_up = true
	var tw_pop = create_tween()
	tw_pop.tween_property(m2_pcb_panel, "rotation_degrees", -16.0, 0.3).set_trans(Tween.TRANS_BOUNCE)
	btn_extract_m2.visible = true
	_show_warning("✓ ¡POP! Tornillo M.2 retirado. SSD elevado a 30° por el resorte. Desliza en diagonal.", Color(1.0, 0.85, 0.2))

func _on_extract_m2_pressed() -> void:
	if is_m2_extracted: return
	is_m2_extracted = true
	btn_extract_m2.disabled = true
	var tw = create_tween().set_parallel(true)
	tw.tween_property(m2_container, "position:x", m2_container.position.x + 80.0, 0.35)
	tw.tween_property(m2_container, "modulate:a", 0.0, 0.35)
	await tw.finished
	m2_container.visible = false
	_show_warning("✓ SSD M.2 desacoplado sin quebrar pistas.", Color(0.2, 1.0, 0.4))
	_check_all_components_cleared()

# =============================================================================
# 5. MEMORIA RAM
# =============================================================================
func _on_ram_latch_pressed(pos: String) -> void:
	if current_phase == Phase.REINSTALL_COMPONENTS:
		_on_reinstall_ram_latch(pos)
		return

	if pos == "top":
		is_ram_left_latch = true
		btn_ram_latch_top.text = "ABIERTA"
		btn_ram_latch_top.modulate = Color(0.2, 1.0, 0.4)
	else:
		is_ram_right_latch = true
		btn_ram_latch_bot.text = "ABIERTA"
		btn_ram_latch_bot.modulate = Color(0.2, 1.0, 0.4)
		
	if is_ram_left_latch and is_ram_right_latch and not is_ram_extracted:
		btn_extract_ram.visible = true
		_show_warning("✓ Ambas trabas laterales abiertas. Extrae el módulo.", Color(0.2, 1.0, 0.4))

func _on_extract_ram_pressed() -> void:
	if is_ram_extracted: return
	is_ram_extracted = true
	btn_extract_ram.disabled = true
	var tw = create_tween().set_parallel(true)
	tw.tween_property(ram_container, "position:y", ram_container.position.y - 50.0, 0.35)
	tw.tween_property(ram_container, "modulate:a", 0.0, 0.35)
	await tw.finished
	ram_container.visible = false
	_show_warning("✓ Módulo de memoria RAM retirado.", Color(0.2, 1.0, 0.4))
	_check_all_components_cleared()

# =============================================================================
# 6. TORNILLOS STANDOFFS AL CHASIS
# =============================================================================
func _on_standoff_pressed(idx: int) -> void:
	if current_phase == Phase.STANDOFFS_INSTALL:
		if not standoff_screws_removed[idx]: return
		var req = 1 if standoff_screw_types[idx] == "cruz" else 2
		var tname = "Cruz [1]" if req == 1 else "Pala [2]"
		if GameManager.equipped_tool != req:
			_show_warning("Usa Destornillador " + tname + " para este standoff de chasis.", Color(1.0, 0.3, 0.3))
			return
			
		standoff_screws_removed[idx] = false
		var btn = standoff_buttons[idx]
		var icon = standoff_icons[idx]
		var tw = create_tween().set_parallel(true)
		tw.tween_property(icon, "rotation_degrees", icon.rotation_degrees - 720.0, 0.3)
		tw.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.3)
		tw.tween_property(btn, "modulate:a", 1.0, 0.3)
		btn.disabled = true
		
		var rem = 0
		for r in standoff_screws_removed:
			if r: rem += 1
		_show_warning("✓ Standoff asegurado. Restantes: " + str(rem) + "/6", Color(0.4, 1.0, 0.4))
		
		if rem == 0:
			_start_reinstall_components_phase()
		else:
			_update_status()
		return

	if current_phase != Phase.STANDOFFS or standoff_screws_removed[idx]: return
	var req = 1 if standoff_screw_types[idx] == "cruz" else 2
	var tname = "Cruz [1]" if req == 1 else "Pala [2]"
	if GameManager.equipped_tool != req:
		_show_warning("Usa Destornillador " + tname + " para este standoff de chasis.", Color(1.0, 0.3, 0.3))
		return
		
	standoff_screws_removed[idx] = true
	var btn = standoff_buttons[idx]
	var icon = standoff_icons[idx]
	var tw = create_tween().set_parallel(true)
	tw.tween_property(icon, "rotation_degrees", 720.0, 0.3)
	tw.tween_property(btn, "modulate:a", 0.0, 0.3)
	btn.disabled = true
	
	var rem = 0
	for r in standoff_screws_removed:
		if not r: rem += 1
	_show_warning("✓ Standoff retirado. Restantes: " + str(rem) + "/6", Color(0.4, 1.0, 0.4))
	
	if rem == 0:
		current_phase = Phase.EXTRACT_MOBO
		btn_extract_mobo.visible = true
		btn_extract_mobo.modulate.a = 0.0
		var tw_btn = create_tween()
		tw_btn.tween_property(btn_extract_mobo, "modulate:a", 1.0, 0.3)
		_show_warning("✓ ¡Placa totalmente libre de tornillos! Lista para extraer.", Color(0.2, 1.0, 0.4))
		_update_status()

# =============================================================================
# 7. EXTRACCIÓN PLACA MADRE
# =============================================================================
func _on_extract_mobo_pressed() -> void:
	if is_mobo_lifted: return
	is_mobo_lifted = true
	btn_extract_mobo.disabled = true
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(mobo_board, "position:x", mobo_board.position.x - 25.0, 0.4) # Desencastrar del I/O shield
	tw.tween_property(mobo_board, "position:y", mobo_board.position.y - 120.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mobo_board, "modulate:a", 0.25, 0.6)
	
	await tw.finished
	GameManager.add_item_to_backpack({"name": "Placa Madre", "broken": true})
	old_part_extracted.emit()
	
	if not is_tutorial_mode:
		_show_warning("✓ Placa Madre averiada extraída. Busca el repuesto nuevo en el taller.", Color(0.2, 1.0, 0.5))
		await get_tree().create_timer(1.2).timeout
		minigame_finished.emit(true)
		return
	
	# Modo tutorial:
	var has_new = false
	for it in GameManager.backpack:
		if it.get("name") == "Placa Madre" and not it.get("broken", true):
			has_new = true
			break
	if not has_new:
		GameManager.add_item_to_backpack({"name": "Placa Madre", "broken": false})
		
	_setup_empty_tray_phase()
	_select_guide_tab(1)
	_show_warning("✓ FASE 1 (QUITAR) SUPERADA ➔ AHORA FASE 2: MONTAJE DEL REPUESTO (INVERSO)", Color(0.2, 1.0, 0.5))
	_update_status()

func _show_warning(msg: String, col: Color) -> void:
	warning_label.text = msg
	warning_label.modulate = col
	var tw = create_tween()
	tw.tween_property(warning_label, "scale", Vector2(1.05, 1.05), 0.1)
	tw.tween_property(warning_label, "scale", Vector2(1.0, 1.0), 0.12)

func _update_status() -> void:
	match current_phase:
		Phase.COMPONENTS:
			var cleared = _get_cleared_components_count()
			phase_tracker.text = "DESMONTAJE LIBRE: %d/5 SECCIONES LIBERADAS" % cleared
			var pending: Array[String] = []
			if not _are_cables_done(): pending.append("Cables")
			if not _is_gpu_done(): pending.append("GPU")
			if not _is_cooler_done(): pending.append("Cooler")
			if not _is_m2_done(): pending.append("M.2")
			if not _is_ram_done(): pending.append("RAM")
			status_label.text = "Desmonta las piezas en cualquier orden. Pendientes: " + ", ".join(pending) + "."
			status_label.modulate = Color(1.0, 0.85, 0.2)
		Phase.STANDOFFS:
			var rem = 0
			for r in standoff_screws_removed:
				if not r: rem += 1
			phase_tracker.text = "STANDOFFS AL CHASIS (%d/6 restantes)" % rem
			status_label.text = "Usa Destornillador Cruz [1] o Pala [2] para retirar los 6 tornillos de fijación al gabinete."
			status_label.modulate = Color(1.0, 0.75, 0.2)
		Phase.EXTRACT_MOBO:
			phase_tracker.text = "EXTRACCIÓN FINAL DE PLACA MADRE"
			status_label.text = "¡Chasis 100% despejado! Arrastra la placa hacia arriba o presiona el botón."
			status_label.modulate = Color(0.2, 1.0, 0.4)
		Phase.INSTALL_MOBO:
			phase_tracker.text = "MONTAJE: PLACA MADRE NUEVA"
			status_label.text = "Arrastra la placa nueva hacia abajo contra el I/O Shield o presiona el botón."
			status_label.modulate = Color(1.0, 0.85, 0.2)
		Phase.STANDOFFS_INSTALL:
			var s_rem = 0
			for r in standoff_screws_removed:
				if r: s_rem += 1
			phase_tracker.text = "MONTAJE: ATORNILLAR STANDOFFS (%d/6 restantes)" % s_rem
			status_label.text = "Paso 2: Atornilla los 6 tornillos Standoff al gabinete con [1] Cruz o [2] Pala (%d restantes)." % s_rem
			status_label.modulate = Color(1.0, 0.85, 0.2)
		Phase.REINSTALL_COMPONENTS:
			var pending: Array[String] = []
			if not is_reinstall_cooler_done:
				if not is_reinstall_cooler_seated: pending.append("Cooler (colocar)")
				elif not is_reinstall_cooler_pwm_done: pending.append("Cooler (PWM)")
				else: pending.append("Cooler (tornillos)")
			if not is_reinstall_ram_done:
				if not is_reinstall_ram_seated: pending.append("RAM (colocar)")
				else: pending.append("RAM (trabas)")
			if not is_reinstall_m2_done:
				if not is_reinstall_m2_seated: pending.append("SSD M.2 (colocar)")
				else: pending.append("SSD M.2 (tornillo)")
			if not is_reinstall_gpu_done:
				if not is_reinstall_gpu_seated: pending.append("GPU (colocar)")
				else: pending.append("GPU (tornillo/traba/cable)")
			if not is_reinstall_atx_done: pending.append("Cable ATX")
			if not is_reinstall_eps_done: pending.append("Cable EPS")
			phase_tracker.text = "MONTAJE: REINSTALAR Y FIJAR (%d/6 pendientes)" % pending.size()
			status_label.text = "Coloca las piezas, atornilla sus tornillos y conéctalas: " + ", ".join(pending) + "."
			status_label.modulate = Color(1.0, 0.85, 0.2)
		Phase.COMPLETED:
			phase_tracker.text = "¡OPERACIÓN COMPLETADA! ✓"
			status_label.text = "¡Placa madre asegurada y todos los componentes reinstalados con éxito!"
			status_label.modulate = Color(0.2, 1.0, 0.4)
