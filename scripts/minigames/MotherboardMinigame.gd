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
	CONNECT_MAINS,
	COMPLETED
}

var current_phase: Phase = Phase.COMPONENTS
var start_as_empty_slot: bool = false

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

var cooler_screw_buttons: Array[Button] = []
var cooler_screw_icons: Array[TextureRect] = []
var standoff_buttons: Array[Button] = []
var standoff_icons: Array[TextureRect] = []

func _ready() -> void:
	layer = 12
	_setup_screw_types()
	_setup_ui()
	_update_tool_buttons()
	
	if start_as_empty_slot:
		current_phase = Phase.INSTALL_MOBO
		mobo_board.visible = false
		btn_extract_mobo.visible = true
		btn_extract_mobo.text = "⇪ MONTAR PLACA MADRE NUEVA DESDE MOCHILA"
		btn_extract_mobo.pressed.disconnect(_on_extract_mobo_pressed)
		btn_extract_mobo.pressed.connect(_on_insert_new_mobo_pressed)
		standoff_screws_removed = [true, true, true, true, true, true]
		for b in standoff_buttons:
			b.visible = false
			b.disabled = true
	else:
		btn_extract_mobo.text = "▲ EXTRAER PLACA MADRE DEL GABINETE"
		
	_update_status()

func _on_insert_new_mobo_pressed() -> void:
	var found_idx = -1
	for i in range(GameManager.backpack.size()):
		var it = GameManager.backpack[i]
		if it.get("name") == "Placa Madre" and not it.get("broken", true):
			found_idx = i
			break
	if found_idx == -1:
		_show_warning("No tienes Placa Madre nueva en tu mochila. Sal al taller a buscar el repuesto.", Color(1.0, 0.3, 0.3))
		return
		
	GameManager.remove_item_from_backpack(found_idx)
	mobo_board.visible = true
	mobo_board.modulate.a = 0.2
	mobo_board.position.y -= 80.0
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(mobo_board, "position:y", mobo_board.position.y + 80.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(mobo_board, "modulate:a", 1.0, 0.45)
	
	btn_extract_mobo.visible = false
	current_phase = Phase.STANDOFFS_INSTALL
	
	# Habilitar los 6 standoffs para atornillar
	for i in range(6):
		var btn = standoff_buttons[i]
		var icon = standoff_icons[i]
		btn.visible = true
		btn.disabled = false
		btn.modulate.a = 0.45
		icon.scale = Vector2(0.5, 0.5)
		icon.rotation_degrees = 0.0
		
	_show_warning("✓ Placa madre montada en el chasis. Asegura los 6 tornillos Standoff con [1] Cruz o [2] Pala.", Color(0.2, 1.0, 0.4))
	_update_status()

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
	icon_m2_armor.texture = tex_screw_cruz
	icon_m2_screw.texture = tex_screw_cruz
	btn_m2_armor.pressed.connect(_on_m2_armor_pressed)
	btn_m2_screw.pressed.connect(_on_m2_screw_pressed)
	btn_m2_screw.visible = false
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
func _on_cable_atx_pressed() -> void:
	if current_phase == Phase.CONNECT_MAINS:
		is_atx24_unplugged = false
		cable_atx_btn.disabled = true
		cable_atx_btn.text = "✓ ATX 24P CONECTADO"
		cable_atx_btn.modulate = Color(0.2, 1.0, 0.4)
		var tw = create_tween().set_parallel(true)
		tw.tween_property(cable_atx_btn, "position:x", cable_atx_btn.position.x - 35.0, 0.3)
		tw.tween_property(cable_atx_btn, "modulate:a", 1.0, 0.3)
		_check_mains_connected()
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
	if current_phase == Phase.CONNECT_MAINS:
		is_eps8_unplugged = false
		cable_eps_btn.disabled = true
		cable_eps_btn.text = "✓ EPS 8P CONECTADO"
		cable_eps_btn.modulate = Color(0.2, 1.0, 0.4)
		var tw = create_tween().set_parallel(true)
		tw.tween_property(cable_eps_btn, "position:y", cable_eps_btn.position.y + 35.0, 0.3)
		tw.tween_property(cable_eps_btn, "modulate:a", 1.0, 0.3)
		_check_mains_connected()
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
	if not is_atx24_unplugged and not is_eps8_unplugged:
		current_phase = Phase.COMPLETED
		_update_status()
		_show_warning("✓ ¡Placa madre montada, fijada y energizada con éxito!", Color(0.2, 1.0, 0.4))
		await get_tree().create_timer(1.8).timeout
		minigame_finished.emit(true)

func _check_phase_cables() -> void:
	if _are_cables_done():
		_show_warning("✓ Cables de poder (ATX 24P y EPS 8P) retirados.", Color(0.2, 1.0, 0.4))
	_check_all_components_cleared()

# =============================================================================
# 2. TARJETA GRÁFICA (GPU)
# =============================================================================
func _on_gpu_cable_pressed() -> void:
	if is_gpu_cable_unplugged: return
	is_gpu_cable_unplugged = true
	btn_gpu_cable.disabled = true
	var tw = create_tween().set_parallel(true)
	tw.tween_property(btn_gpu_cable, "position:y", btn_gpu_cable.position.y - 25.0, 0.25)
	tw.tween_property(btn_gpu_cable, "modulate:a", 0.0, 0.25)
	_show_warning("✓ Cable PCIe 8P de la GPU desconectado.", Color(0.2, 1.0, 0.4))
	_check_gpu_ready()

func _on_gpu_bracket_pressed() -> void:
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
	if is_cooler_pwm_unplugged: return
	is_cooler_pwm_unplugged = true
	btn_cooler_pwm.disabled = true
	btn_cooler_pwm.text = "✓ PWM OFF"
	btn_cooler_pwm.modulate = Color(0.2, 1.0, 0.4)
	_show_warning("✓ Conector PWM de 4 pines desconectado.", Color(0.2, 1.0, 0.4))
	_check_cooler_ready()

func _on_cooler_screw_pressed(idx: int) -> void:
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
	if is_m2_armor_removed: return
	if GameManager.equipped_tool != 1:
		_show_warning("Usa Destornillador Cruz [1] para retirar el tornillo del M.2 Armor.", Color(1.0, 0.3, 0.3))
		return
	is_m2_armor_removed = true
	btn_m2_armor.disabled = true
	var tw = create_tween().set_parallel(true)
	tw.tween_property(icon_m2_armor, "rotation_degrees", 720.0, 0.3)
	tw.tween_property(btn_m2_armor, "modulate:a", 0.0, 0.3)
	await tw.finished
	btn_m2_armor.visible = false
	btn_m2_screw.visible = true
	_show_warning("✓ Armadura térmica M.2 retirada. Retira el micro-tornillo de standoff.", Color(0.2, 1.0, 0.4))

func _on_m2_screw_pressed() -> void:
	if not is_m2_armor_removed or is_m2_screw_removed: return
	if GameManager.equipped_tool != 1:
		_show_warning("Usa Destornillador Cruz fino [1] para el micro-tornillo.", Color(1.0, 0.3, 0.3))
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
	_show_warning("✓ ¡POP! SSD elevado a 30° por el resorte. Desliza en diagonal.", Color(1.0, 0.85, 0.2))

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
			current_phase = Phase.CONNECT_MAINS
			cable_atx_btn.disabled = false
			cable_eps_btn.disabled = false
			cable_atx_btn.visible = true
			cable_eps_btn.visible = true
			cable_atx_btn.modulate = Color(1.0, 0.85, 0.2)
			cable_eps_btn.modulate = Color(1.0, 0.85, 0.2)
			cable_atx_btn.text = "CONECTAR ATX 24P"
			cable_eps_btn.text = "CONECTAR EPS 8P"
			_show_warning("✓ ¡Standoffs firmes! Conecta los cables ATX y EPS para energizar la placa.", Color(0.2, 1.0, 0.4))
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
	current_phase = Phase.COMPLETED
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(mobo_board, "position:x", mobo_board.position.x - 25.0, 0.4) # Desencastrar del I/O shield
	tw.tween_property(mobo_board, "position:y", mobo_board.position.y - 120.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mobo_board, "modulate:a", 0.25, 0.6)
	
	await tw.finished
	GameManager.add_item_to_backpack({"name": "Placa Madre", "broken": true})
	old_part_extracted.emit()
	_show_warning("✓ ¡MAESTRÍA TOTAL! Desensamblaje completo superado con éxito.", Color(0.2, 1.0, 0.4))
	_update_status()
	await get_tree().create_timer(1.8).timeout
	minigame_finished.emit(true)

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
			status_label.text = "¡Chasis 100% despejado! Desencastra del I/O Shield y levanta la placa madre."
			status_label.modulate = Color(0.2, 1.0, 0.4)
		Phase.INSTALL_MOBO:
			phase_tracker.text = "MONTAJE: PLACA MADRE NUEVA"
			status_label.text = "Haz clic en el botón para colocar la placa madre nueva desde tu mochila."
			status_label.modulate = Color(1.0, 0.85, 0.2)
		Phase.STANDOFFS_INSTALL:
			var rem = 0
			for r in standoff_screws_removed:
				if r: rem += 1
			phase_tracker.text = "FIJACIÓN STANDOFFS (%d/6 restantes)" % rem
			status_label.text = "Fija los 6 tornillos Standoff al chasis con [1] Cruz o [2] Pala."
			status_label.modulate = Color(1.0, 0.85, 0.2)
		Phase.CONNECT_MAINS:
			phase_tracker.text = "CONEXIÓN DE ALIMENTACIÓN ELÉCTRICA"
			status_label.text = "Conecta los arneses de alimentación principal ATX de 24 pines y EPS de 8 pines."
			status_label.modulate = Color(0.2, 1.0, 0.4)
		Phase.COMPLETED:
			phase_tracker.text = "¡OPERACIÓN COMPLETADA! ✓"
			status_label.text = "Has dominado el ciclo completo de la placa madre y sus componentes."
			status_label.modulate = Color(0.2, 1.0, 0.4)
