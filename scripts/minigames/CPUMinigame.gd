extends CanvasLayer

# =============================================================================
# MINIJUEGO: EXTRACCIÓN Y MONTAJE DEL PROCESADOR (CPU)
# Mecánica:
# FASE SACAR (Extracción en PC de reparación):
# 1. Arrastrar la palanca lateral hacia abajo (libera la tensión del socket).
# 2. Se quita la placa de protección metálica automáticamente al bajar la palanca.
# 3. Hacer clic en el CPU para extraerlo del zócalo.
# FASE PONER (Montaje en PC de reparación):
# 1. Hacer clic en el zócalo para colocar el nuevo procesador.
# 2. Arrastrar la palanca hacia arriba (al lado contrario) para asegurar y bloquear.
#
# FASE SERVIDOR (Área de Servidores - Dual CPU Enterprise):
# 1. Desatornillar 3 tornillos de sujeción en orden estricto: 3 -> 1 -> 2.
# 2. Se libera la cubierta del socket industrial.
# 3. Clic para asentar el procesador Enterprise.
# 4. Arrastrar palanca arriba para trabar.
# =============================================================================

signal minigame_finished(success: bool)
signal old_part_extracted()

const TEX_PLACA = preload("res://pixel art minijuegos/procesador/placa de procesador.png")
const TEX_INTEL_CERRADO = preload("res://pixel art minijuegos/procesador/intel/intel 5 cerrado.png")
const TEX_INTEL_ABIERTO = preload("res://pixel art minijuegos/procesador/intel/abiertos/intel 5 abierto.png")
const TEX_AMD_CERRADO = preload("res://pixel art minijuegos/procesador/amd/ amd ryzen 3.png")
const TEX_AMD_ABIERTO = preload("res://pixel art minijuegos/procesador/amd/abiertos/ amd ryzen 3 abierto.png")

@export var cpu_brand: String = "intel"
@export var start_as_empty_slot: bool = false
@export var is_tutorial_mode: bool = false
@export var require_screws_sequence: bool = false
@export var target_cpu_count: int = 1
@export var initial_installed_count: int = 0
var current_cpu_index: int = 0
var cpu_installed_states: Array[bool] = [false, false, false]

func get_installed_count() -> int:
	return current_cpu_index

enum Phase {
	EXTRACT_LEVER_DOWN, # Arrastrar palanca abajo
	EXTRACT_CPU_CLICK,  # Clic en CPU para sacarlo
	INSERT_CPU_CLICK,   # 1. Clic en socket para poner CPU
	INSERT_LEVER_UP,    # 2. Arrastrar palanca arriba para trabar
	FASTEN_SCREWS,      # 3. Atornillar en orden: 2 -> 3 -> 1 (Solo servidor)
	COMPLETED
}

var current_phase: Phase = Phase.EXTRACT_LEVER_DOWN

# Nodos de Interfaz
@onready var modal_control: Control = $ModalControl
@onready var title_label: Label = $ModalControl/Panel/VBox/Header/Titulo
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var instruction_badge: Label = $ModalControl/Panel/VBox/Header/InstructionBadge
@onready var order_badge: Label = get_node_or_null("ModalControl/Panel/VBox/Header/OrderBadge")
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel
@onready var feedback_label: Label = $ModalControl/Panel/VBox/FeedbackLabel

# Guía y slots
@onready var right_panel: PanelContainer = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/RightPanel")
@onready var guide_text: Label = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/RightPanel/Margin/VBox/GuideText")
@onready var slots_container: VBoxContainer = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/RightPanel/Margin/VBox/SlotsContainer")
@onready var btn_slot_0: Button = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/RightPanel/Margin/VBox/SlotsContainer/BtnSlot0")
@onready var btn_slot_1: Button = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/RightPanel/Margin/VBox/SlotsContainer/BtnSlot1")
@onready var btn_slot_2: Button = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/RightPanel/Margin/VBox/SlotsContainer/BtnSlot2")

# Área del Socket y Sprites Pixel Art
@onready var socket_base: Panel = $ModalControl/Panel/VBox/ContentHBox/WorkArea/SocketBase
@onready var placa_base_sprite: TextureRect = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/WorkArea/SocketBase/PlacaBaseSprite")
@onready var cpu_sprite: TextureRect = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/WorkArea/SocketBase/CPUSprite")
@onready var socket_grid_pattern: Control = $ModalControl/Panel/VBox/ContentHBox/WorkArea/SocketBase/PinsMatrix
@onready var matrix_text: Label = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/WorkArea/SocketBase/PinsMatrix/MatrixText")
@onready var cpu_chip: Button = $ModalControl/Panel/VBox/ContentHBox/WorkArea/SocketBase/CPUChip
@onready var cpu_label: Label = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/WorkArea/SocketBase/CPUChip/CPULabel")
@onready var notch_indicator: Label = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/WorkArea/SocketBase/CPUChip/NotchIndicator")
@onready var load_plate: Panel = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/WorkArea/SocketBase/LoadPlate")
@onready var btn_brand_toggle: Button = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/WorkArea/SocketBase/BtnBrandToggle")

# Tornillos de sujeción (para área de servidor: orden 2 -> 3 -> 1)
@onready var screw_1: Button = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/WorkArea/SocketBase/Screw1")
@onready var screw_2: Button = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/WorkArea/SocketBase/Screw2")
@onready var screw_3: Button = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/WorkArea/SocketBase/Screw3")

const REQUIRED_SCREW_ORDER: Array[int] = [2, 3, 1]
var current_screw_step: int = 0
var screws_removed: Array[int] = []
var liquid_cooling_card: PanelContainer = null

# Palanca
@onready var lever_handle: Button = $ModalControl/Panel/VBox/ContentHBox/WorkArea/SocketBase/LeverArea/LeverHandle
@onready var lever_arrow: Label = $ModalControl/Panel/VBox/ContentHBox/WorkArea/SocketBase/LeverArea/LeverArrow
@onready var lever_status_text: Label = $ModalControl/Panel/VBox/ContentHBox/WorkArea/SocketBase/LeverArea/LeverStatusText

# Arrastre de palanca
const LEVER_TOP_Y: float = 0.0
const LEVER_BOTTOM_Y: float = 120.0
const LEVER_SNAP_THRESHOLD: float = 80.0

var is_dragging_lever: bool = false
var drag_start_mouse_y: float = 0.0
var drag_start_lever_y: float = 0.0

func _ready() -> void:
	layer = 12
	btn_cancel.pressed.connect(_on_cancel_pressed)
	
	if btn_brand_toggle:
		btn_brand_toggle.pressed.connect(_on_brand_toggle_pressed)
		_update_brand_toggle_label()
	
	# Configurar eventos de la palanca
	lever_handle.gui_input.connect(_on_lever_gui_input)
	
	# Configurar clic en el CPU y en la matriz del socket
	cpu_chip.pressed.connect(_on_cpu_clicked)
	socket_grid_pattern.gui_input.connect(_on_socket_gui_input)
	
	# Configurar eventos de tornillos (solo para modo servidor)
	if screw_1:
		screw_1.pressed.connect(func(): _on_screw_pressed(1))
	if screw_2:
		screw_2.pressed.connect(func(): _on_screw_pressed(2))
	if screw_3:
		screw_3.pressed.connect(func(): _on_screw_pressed(3))
		
	if btn_slot_0: btn_slot_0.pressed.connect(func(): _on_cpu_slot_clicked(0))
	if btn_slot_1: btn_slot_1.pressed.connect(func(): _on_cpu_slot_clicked(1))
	if btn_slot_2: btn_slot_2.pressed.connect(func(): _on_cpu_slot_clicked(2))
	
	if target_cpu_count > 1 and is_instance_valid(slots_container):
		slots_container.visible = true
		_update_slots_ui()
		
	# Definir visibilidad de tornillos según modo
	_apply_screws_visibility(require_screws_sequence)
	
	if initial_installed_count > 0:
		for k in range(min(initial_installed_count, cpu_installed_states.size())):
			cpu_installed_states[k] = true
		current_cpu_index = initial_installed_count
		if current_cpu_index < target_cpu_count:
			_prepare_next_cpu_socket()
			return

	if require_screws_sequence:
		_setup_server_mode()
	elif start_as_empty_slot:
		_setup_insert_mode()
	else:
		_setup_extract_mode()

func _apply_screws_visibility(show_s: bool) -> void:
	if screw_1: screw_1.visible = show_s
	if screw_2: screw_2.visible = show_s
	if screw_3: screw_3.visible = show_s
	if order_badge: order_badge.visible = show_s

# =============================================================================
# ÁREA DE REPARACIÓN (MODO ORIGINAL): DESMONTAJE
# =============================================================================
func _setup_extract_mode() -> void:
	current_phase = Phase.EXTRACT_LEVER_DOWN
	title_label.text = "DESMONTAJE: EXTRACCIÓN DE PROCESADOR (CPU)"
	
	# Palanca arriba (trabada pero lista para arrastrar hacia abajo)
	lever_handle.position.y = LEVER_TOP_Y
	lever_handle.disabled = false
	lever_handle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	lever_arrow.visible = true
	lever_arrow.text = "▼\nARRASTRA\nABAJO"
	lever_arrow.modulate = Color(1.0, 0.85, 0.2, 1.0)
	lever_status_text.text = "PALANCA:\nTRABADA [0°]"
	lever_status_text.modulate = Color(1.0, 0.35, 0.35, 1.0)
	
	if is_instance_valid(load_plate):
		load_plate.visible = false
	
	_update_brand_toggle_label()
	_update_cpu_visuals()
	_update_ui_state()
	_show_feedback("Arrastra la palanca hacia abajo ↓ para liberar el seguro del socket.", Color(1.0, 0.85, 0.2))

# =============================================================================
# ÁREA DE REPARACIÓN (MODO ORIGINAL): MONTAJE
# =============================================================================
func _setup_insert_mode() -> void:
	current_phase = Phase.INSERT_CPU_CLICK
	title_label.text = "MONTAJE: INSTALACIÓN DE PROCESADOR NUEVO (CPU)"
	
	# Palanca abajo (abierta)
	lever_handle.position.y = LEVER_BOTTOM_Y
	lever_handle.disabled = false
	lever_arrow.visible = false
	lever_status_text.text = "PALANCA:\nLIBERADA [90°]"
	lever_status_text.modulate = Color(0.2, 1.0, 0.5, 1.0)
	
	if is_instance_valid(load_plate):
		load_plate.visible = false
	
	_update_brand_toggle_label()
	_update_cpu_visuals()
	_update_ui_state()
	_show_feedback("Haz clic en el socket para asentar el nuevo procesador.", Color(0.2, 0.95, 1.0))

# =============================================================================
# ÁREA DE SERVIDOR: MONTAJE DUAL CPU ENTERPRISE (CPU ➔ PALANCA ARRIBA ➔ TORNILLOS 2 -> 3 -> 1)
# =============================================================================
func _setup_server_mode() -> void:
	current_phase = Phase.INSERT_CPU_CLICK
	current_screw_step = 0
	screws_removed.clear()
	title_label.text = "MONTAJE INDUSTRIAL: MULTI CPU ENTERPRISE (SOCKET #%d)" % (current_cpu_index + 1)
	
	_apply_screws_visibility(false)
	
	if is_instance_valid(load_plate):
		load_plate.visible = false
	
	# Palanca abierta abajo
	lever_handle.position.y = LEVER_BOTTOM_Y
	lever_handle.disabled = false
	lever_arrow.visible = false
	lever_status_text.text = "PALANCA:\nLIBERADA [90°]"
	lever_status_text.modulate = Color(0.2, 1.0, 0.5, 1.0)
	
	_update_brand_toggle_label()
	_update_cpu_visuals()
	_update_ui_state()
	_show_feedback("PASO 1: Haz clic en el socket para asentar el procesador Enterprise #%d." % (current_cpu_index + 1), Color(0.2, 0.95, 1.0))

func _reset_screws() -> void:
	for id in [1, 2, 3]:
		var btn = _get_screw_button(id)
		if btn:
			btn.visible = true
			btn.disabled = false
			btn.scale = Vector2.ONE
			btn.rotation = 0.0
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _get_screw_button(id: int) -> Button:
	match id:
		1: return screw_1
		2: return screw_2
		3: return screw_3
	return null

func _on_screw_pressed(screw_id: int) -> void:
	if current_phase != Phase.FASTEN_SCREWS:
		return
		
	if screw_id in screws_removed:
		return
		
	var expected_screw = REQUIRED_SCREW_ORDER[current_screw_step]
	if screw_id == expected_screw:
		screws_removed.append(screw_id)
		current_screw_step += 1
		
		var btn = _get_screw_button(screw_id)
		if btn:
			btn.disabled = true
			var tw = create_tween().set_parallel(true)
			tw.tween_property(btn, "rotation", TAU, 0.35)
			tw.tween_property(btn, "modulate", Color(0.2, 1.0, 0.5, 1.0), 0.35)
			
		_update_screw_ui()
		
		if current_screw_step >= REQUIRED_SCREW_ORDER.size():
			_show_feedback("✓ ¡Tornillos asegurados en el orden 2 ➔ 3 ➔ 1! Socket fijado.", Color(0.2, 1.0, 0.5))
			if get_tree():
				await get_tree().create_timer(0.45).timeout
			_complete_screws_phase()
		else:
			var next_screw = REQUIRED_SCREW_ORDER[current_screw_step]
			_show_feedback("✓ ¡Tornillo [%d] fijado! Siguiente tornillo en orden: [%d]." % [screw_id, next_screw], Color(0.2, 0.95, 1.0))
			_update_ui_state()
	else:
		var btn = _get_screw_button(screw_id)
		if btn:
			_shake_button(btn)
			
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("register_error"):
			gm.register_error(2.0)
			
		_show_feedback("❌ ¡Orden incorrecto! Debes atornillar en orden: 2 ➔ 3 ➔ 1 (Tornillo requerido: %d)" % expected_screw, Color(1.0, 0.35, 0.35))

func _shake_button(btn: Button) -> void:
	if not btn:
		return
	var orig_color = btn.modulate
	var tw = create_tween()
	tw.tween_property(btn, "modulate", Color(1.5, 0.3, 0.3, 1.0), 0.06)
	tw.tween_property(btn, "rotation", 0.25, 0.05)
	tw.tween_property(btn, "rotation", -0.25, 0.05)
	tw.tween_property(btn, "rotation", 0.15, 0.05)
	tw.tween_property(btn, "rotation", 0.0, 0.05)
	tw.tween_property(btn, "modulate", orig_color, 0.08)

func _update_screw_ui() -> void:
	if not order_badge:
		return
	var text_s2 = "[2 ✓]" if 2 in screws_removed else "[2]"
	var text_s3 = "[3 ✓]" if 3 in screws_removed else "[3]"
	var text_s1 = "[1 ✓]" if 1 in screws_removed else "[1]"
	order_badge.text = "ORDEN DE APRIETE DE TORNILLOS:  %s  ➔  %s  ➔  %s" % [text_s2, text_s3, text_s1]

func _complete_screws_phase() -> void:
	cpu_installed_states[current_cpu_index] = true
	current_cpu_index += 1
	_apply_screws_visibility(false)
	
	if current_cpu_index < target_cpu_count:
		_show_feedback("✓ ¡SOCKET CPU #%d ASEGURADO!" % current_cpu_index, Color(0.0, 1.0, 0.5))
		status_label.text = "✓ CPU #%d INSTALADO · HAZ CLIC EN 'SOCKET CPU #%d' A LA DERECHA PARA CONTINUAR" % [current_cpu_index, current_cpu_index + 1]
		status_label.modulate = Color(0.0, 0.95, 1.0)
		_update_slots_ui()
	else:
		current_phase = Phase.COMPLETED
		_show_feedback("✓ ¡LOS %d PROCESADORES ENTERPRISE INSTALADOS CON ÉXITO!" % target_cpu_count, Color(0.0, 1.0, 0.5))
		status_label.text = "✓ ¡LOS %d PROCESADORES ENTERPRISE ASEGURADOS CON ÉXITO!" % target_cpu_count
		status_label.modulate = Color(0.0, 1.0, 0.5)
		_update_ui_state()
		_update_slots_ui()
		await get_tree().create_timer(0.6).timeout
		minigame_finished.emit(true)
		status_label.modulate = Color(0.0, 1.0, 0.5)
		_update_ui_state()
		_update_slots_ui()
		await get_tree().create_timer(1.2).timeout
		minigame_finished.emit(true)

# =============================================================================
# ARRASTRE DE LA PALANCA CON EL RATÓN
# =============================================================================
func _on_lever_gui_input(event: InputEvent) -> void:
	if require_screws_sequence and current_phase == Phase.FASTEN_SCREWS:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_show_feedback("⚠️ La palanca ya está trabada. Ahora atornilla los pernos en orden: 2 ➔ 3 ➔ 1.", Color(1.0, 0.85, 0.2))
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if (current_phase == Phase.EXTRACT_LEVER_DOWN and lever_handle.position.y < LEVER_BOTTOM_Y) or \
			   (current_phase == Phase.INSERT_LEVER_UP and lever_handle.position.y > LEVER_TOP_Y):
				is_dragging_lever = true
				drag_start_mouse_y = event.global_position.y
				drag_start_lever_y = lever_handle.position.y
		else:
			if is_dragging_lever:
				is_dragging_lever = false
				_evaluate_lever_release()

func _input(event: InputEvent) -> void:
	if is_dragging_lever:
		if event is InputEventMouseMotion:
			var delta_y = event.global_position.y - drag_start_mouse_y
			var target_y = clamp(drag_start_lever_y + delta_y, LEVER_TOP_Y, LEVER_BOTTOM_Y)
			lever_handle.position.y = target_y
			_check_dynamic_lever_progress(target_y)
		elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging_lever = false
			_evaluate_lever_release()

func _check_dynamic_lever_progress(current_y: float) -> void:
	if current_phase == Phase.EXTRACT_LEVER_DOWN:
		var progress = current_y / LEVER_BOTTOM_Y
		lever_status_text.text = "PALANCA:\nBAJANDO (%d%%)" % int(progress * 100.0)
		lever_status_text.modulate = Color(1.0, 0.8, 0.2).lerp(Color(0.2, 1.0, 0.5), progress)
		if current_y >= LEVER_BOTTOM_Y - 5.0:
			is_dragging_lever = false
			_complete_lever_down()
	elif current_phase == Phase.INSERT_LEVER_UP:
		var progress = 1.0 - (current_y / LEVER_BOTTOM_Y)
		lever_status_text.text = "PALANCA:\nCERRANDO (%d%%)" % int(progress * 100.0)
		lever_status_text.modulate = Color(0.2, 0.8, 1.0).lerp(Color(1.0, 0.35, 0.35), progress)
		if current_y <= LEVER_TOP_Y + 5.0:
			is_dragging_lever = false
			_complete_lever_up()

func _evaluate_lever_release() -> void:
	if current_phase == Phase.EXTRACT_LEVER_DOWN:
		if lever_handle.position.y >= LEVER_SNAP_THRESHOLD:
			_complete_lever_down()
		else:
			var tw = create_tween()
			tw.tween_property(lever_handle, "position:y", LEVER_TOP_Y, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			lever_status_text.text = "PALANCA:\nTRABADA [0°]"
			lever_status_text.modulate = Color(1.0, 0.35, 0.35, 1.0)
			_show_feedback("Debes arrastrar la palanca completamente hasta abajo.", Color(1.0, 0.4, 0.4))
	elif current_phase == Phase.INSERT_LEVER_UP:
		if lever_handle.position.y <= (LEVER_BOTTOM_Y - LEVER_SNAP_THRESHOLD):
			_complete_lever_up()
		else:
			var tw = create_tween()
			tw.tween_property(lever_handle, "position:y", LEVER_BOTTOM_Y, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			lever_status_text.text = "PALANCA:\nLIBERADA [90°]"
			lever_status_text.modulate = Color(0.2, 1.0, 0.5, 1.0)
			_show_feedback("Debes arrastrar la palanca completamente hasta arriba para trabar.", Color(1.0, 0.4, 0.4))

# =============================================================================
# FASE EXTRACCIÓN: PALANCA ABAJO Y RETIRO DE PROTECCIÓN
# =============================================================================
func _complete_lever_down() -> void:
	if lever_handle:
		lever_handle.position.y = LEVER_BOTTOM_Y
	if lever_status_text:
		lever_status_text.text = "PALANCA:\nLIBERADA [90°]"
		lever_status_text.modulate = Color(0.2, 1.0, 0.5, 1.0)
	if lever_arrow:
		lever_arrow.visible = false
	
	current_phase = Phase.EXTRACT_CPU_CLICK
	_update_cpu_visuals()
	_update_ui_state()
	_show_feedback("✓ ¡Compuerta abierta! Haz clic en el procesador para extraerlo.", Color(0.0, 0.95, 1.0))
	
	# Animación pop en el sprite
	if is_instance_valid(cpu_sprite):
		var tw_pop = create_tween()
		if tw_pop:
			tw_pop.tween_property(cpu_sprite, "scale", Vector2(1.04, 1.04), 0.1)
			tw_pop.tween_property(cpu_sprite, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Efecto de pulso en el botón de CPU para indicar que es clickeable
	if is_instance_valid(cpu_chip):
		var tw_pulse = create_tween()
		if tw_pulse:
			tw_pulse.set_loops(4)
			tw_pulse.tween_property(cpu_chip, "modulate", Color(1.2, 1.2, 0.6), 0.2)
			tw_pulse.tween_property(cpu_chip, "modulate", Color(1.0, 1.0, 1.0), 0.2)

# =============================================================================
# FASE EXTRACCIÓN: CLIC EN CPU PARA QUITARLO
# =============================================================================
func _on_cpu_clicked() -> void:
	if current_phase != Phase.EXTRACT_CPU_CLICK:
		return
		
	current_phase = Phase.COMPLETED
	cpu_chip.disabled = true
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("add_item_to_backpack"):
		gm.add_item_to_backpack({"name": "CPU", "type": "CPU", "broken": true})
	old_part_extracted.emit()
	
	_show_feedback("✓ ¡CPU retirado con éxito! El zócalo queda listo para el repuesto.", Color(0.0, 1.0, 0.5))
	
	# Animación de elevación y retiro del CPU sprite
	var tw = create_tween().set_parallel(true)
	if is_instance_valid(cpu_sprite):
		tw.tween_property(cpu_sprite, "position:y", cpu_sprite.position.y - 80.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(cpu_sprite, "scale", Vector2(1.2, 1.2), 0.45)
		tw.tween_property(cpu_sprite, "modulate:a", 0.0, 0.45)
	if is_instance_valid(cpu_chip):
		tw.tween_property(cpu_chip, "position:y", cpu_chip.position.y - 80.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(cpu_chip, "modulate:a", 0.0, 0.45)
	await tw.finished
	
	if is_instance_valid(cpu_sprite):
		cpu_sprite.visible = false
	if is_instance_valid(cpu_chip):
		cpu_chip.visible = false
		
	if get_tree():
		await get_tree().create_timer(0.8).timeout
	minigame_finished.emit(true)

# =============================================================================
# FASE MONTAJE: CLIC EN SOCKET PARA COLOCAR CPU
# =============================================================================
func _on_socket_gui_input(event: InputEvent) -> void:
	if current_phase != Phase.INSERT_CPU_CLICK:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_insert_cpu()

func _insert_cpu() -> void:
	var has_cpu = false
	var gm = get_node_or_null("/root/GameManager")
	if gm and "backpack" in gm:
		for it in gm.backpack:
			if it is Dictionary and (it.get("name") == "CPU" or it.get("type") == "CPU") and not it.get("broken", true):
				has_cpu = true
				break
	if not has_cpu:
		_show_feedback("⚠️ No tienes procesadores en la mochila. Sal [ESC] para recogerlos.", Color(1.0, 0.4, 0.4))
		status_label.text = "⚠️ FALTA PROCESADOR EN MOCHILA · SAL [ESC] PARA RECOGERLO (PROGRESO: %d/%d)" % [current_cpu_index, target_cpu_count]
		status_label.modulate = Color(1.0, 0.4, 0.4)
		return

	current_phase = Phase.INSERT_LEVER_UP
	_update_cpu_visuals()
	
	_show_feedback("✓ Asentando procesador en el zócalo...", Color(0.2, 0.95, 1.0))
	
	# Animación de caída e inserción del CPU sprite
	if is_instance_valid(cpu_sprite):
		var base_pos_y = -140.0
		cpu_sprite.position.y = base_pos_y - 80.0
		cpu_sprite.scale = Vector2(1.2, 1.2)
		cpu_sprite.modulate.a = 0.0
		var tw = create_tween().set_parallel(true)
		tw.tween_property(cpu_sprite, "position:y", base_pos_y, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(cpu_sprite, "scale", Vector2(1.0, 1.0), 0.45)
		tw.tween_property(cpu_sprite, "modulate:a", 1.0, 0.35)
		await tw.finished
	
	lever_arrow.visible = true
	lever_arrow.text = "▲\nARRASTRA\nARRIBA"
	lever_arrow.modulate = Color(1.0, 0.85, 0.2, 1.0)
	
	_update_ui_state()
	_show_feedback("✓ CPU colocado. Arrastra la palanca hacia arriba ↑ para asegurar la protección.", Color(1.0, 0.85, 0.2))

# =============================================================================
# FASE MONTAJE: PALANCA ARRIBA (LADO CONTRARIO) PARA TRABAR
# =============================================================================
func _complete_lever_up() -> void:
	if lever_handle:
		lever_handle.position.y = LEVER_TOP_Y
	if lever_status_text:
		lever_status_text.text = "PALANCA:\nTRABADA [0°]"
		lever_status_text.modulate = Color(0.2, 1.0, 0.5, 1.0)
	if lever_arrow:
		lever_arrow.visible = false
	_update_cpu_visuals()
	
	# Retirar el repuesto nuevo de la mochila si el jugador tenía uno
	var gm_up = get_node_or_null("/root/GameManager")
	if gm_up and "backpack" in gm_up:
		for i in range(gm_up.backpack.size()):
			var it = gm_up.backpack[i]
			if it is Dictionary and (it.get("name") == "CPU" or it.get("type") == "CPU") and not it.get("broken", true):
				if gm_up.has_method("remove_item_from_backpack"):
					gm_up.remove_item_from_backpack(i)
				break
				
	if require_screws_sequence:
		current_phase = Phase.FASTEN_SCREWS
		current_screw_step = 0
		screws_removed.clear()
		_reset_screws()
		_apply_screws_visibility(true)
		_update_screw_ui()
		_update_ui_state()
		_show_feedback("✓ ¡Palanca trabada! PASO 3: Atornilla la sujeción en orden estricto: 2 ➔ 3 ➔ 1.", Color(1.0, 0.85, 0.2))
		status_label.text = "SOCKET CPU #%d: Atornilla en orden estricto: 2 ➔ 3 ➔ 1" % (current_cpu_index + 1)
		status_label.modulate = Color(1.0, 0.85, 0.2)
		return
				
	cpu_installed_states[current_cpu_index] = true
	current_cpu_index += 1
	
	if current_cpu_index < target_cpu_count:
		_show_feedback("✓ ¡SOCKET CPU #%d ASEGURADO! Haz clic en el recuadro a la derecha para montar el SOCKET CPU #%d." % [current_cpu_index, current_cpu_index + 1], Color(0.0, 1.0, 0.5))
		status_label.text = "✓ CPU #%d INSTALADO · HAZ CLIC EN EL RECUADRO A LA DERECHA PARA EL SOCKET #%d" % [current_cpu_index, current_cpu_index + 1]
		status_label.modulate = Color(0.0, 0.95, 1.0)
		_update_slots_ui()
	else:
		current_phase = Phase.COMPLETED
		_show_feedback("✓ ¡Palanca trabada y compuerta asegurada con éxito!", Color(0.0, 1.0, 0.5))
		_update_ui_state()
		_update_slots_ui()
		
		if get_tree():
			await get_tree().create_timer(1.2).timeout
		minigame_finished.emit(true)

func _on_cpu_slot_clicked(idx: int) -> void:
	if idx == current_cpu_index and current_cpu_index < target_cpu_count and not cpu_installed_states[idx]:
		_prepare_next_cpu_socket()

func _prepare_next_cpu_socket() -> void:
	current_screw_step = 0
	screws_removed.clear()
	_apply_screws_visibility(false)
	
	if is_instance_valid(load_plate):
		load_plate.visible = false
	
	current_phase = Phase.INSERT_CPU_CLICK
	_update_cpu_visuals()
	
	# Palanca abierta abajo
	lever_handle.position.y = LEVER_BOTTOM_Y
	lever_status_text.text = "PALANCA:\nLIBERADA [90°]"
	lever_status_text.modulate = Color(0.2, 1.0, 0.5, 1.0)
	lever_arrow.visible = false
	
	var has_cpu = false
	var gm = get_node_or_null("/root/GameManager")
	if gm and "backpack" in gm:
		for it in gm.backpack:
			if it is Dictionary and (it.get("name") == "CPU" or it.get("type") == "CPU") and not it.get("broken", true):
				has_cpu = true
				break
				
	if not has_cpu:
		status_label.text = "⚠️ FALTA PROCESADOR EN MOCHILA · SAL [ESC] PARA RECOGERLO (PROGRESO: %d/%d)" % [current_cpu_index, target_cpu_count]
		status_label.modulate = Color(1.0, 0.4, 0.4)
		_show_feedback("⚠️ No tienes más procesadores en la mochila. Sal [ESC] para recogerlos.", Color(1.0, 0.4, 0.4))
	else:
		_show_feedback("PASO 1: Haz clic en el socket para asentar el procesador Enterprise #%d." % (current_cpu_index + 1), Color(0.2, 0.95, 1.0))
		_update_ui_state()
	_update_slots_ui()

func set_cpu_brand_by_name(brand: String) -> void:
	if "amd" in brand.to_lower() or "ryzen" in brand.to_lower():
		cpu_brand = "amd"
	else:
		cpu_brand = "intel"
	_update_brand_toggle_label()
	_update_cpu_visuals()

func _on_brand_toggle_pressed() -> void:
	if cpu_brand == "intel":
		cpu_brand = "amd"
	else:
		cpu_brand = "intel"
	_update_brand_toggle_label()
	_update_cpu_visuals()

func _update_brand_toggle_label() -> void:
	if btn_brand_toggle == null:
		btn_brand_toggle = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/WorkArea/SocketBase/BtnBrandToggle")
	if not is_instance_valid(btn_brand_toggle):
		return
	if cpu_brand == "amd":
		btn_brand_toggle.text = "🔄 MARCA: AMD RYZEN 3"
		btn_brand_toggle.modulate = Color(1.0, 0.5, 0.2, 1.0)
	else:
		btn_brand_toggle.text = "🔄 MARCA: INTEL CORE i5"
		btn_brand_toggle.modulate = Color(0.2, 0.95, 1.0, 1.0)

func _update_cpu_visuals() -> void:
	if cpu_sprite == null:
		cpu_sprite = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/WorkArea/SocketBase/CPUSprite")
	if cpu_chip == null:
		cpu_chip = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/WorkArea/SocketBase/CPUChip")
	if matrix_text == null:
		matrix_text = get_node_or_null("ModalControl/Panel/VBox/ContentHBox/WorkArea/SocketBase/PinsMatrix/MatrixText")
	if not is_instance_valid(cpu_sprite):
		return
	var is_intel = (cpu_brand == "intel")
	match current_phase:
		Phase.EXTRACT_LEVER_DOWN:
			cpu_sprite.visible = true
			cpu_sprite.texture = TEX_INTEL_CERRADO if is_intel else TEX_AMD_CERRADO
			if is_instance_valid(cpu_chip):
				cpu_chip.visible = true
				cpu_chip.disabled = true
			if is_instance_valid(matrix_text):
				matrix_text.visible = false
		Phase.EXTRACT_CPU_CLICK:
			cpu_sprite.visible = true
			cpu_sprite.texture = TEX_INTEL_ABIERTO if is_intel else TEX_AMD_ABIERTO
			if is_instance_valid(cpu_chip):
				cpu_chip.visible = true
				cpu_chip.disabled = false
			if is_instance_valid(matrix_text):
				matrix_text.visible = false
		Phase.INSERT_CPU_CLICK:
			cpu_sprite.visible = false
			if is_instance_valid(cpu_chip):
				cpu_chip.visible = false
				cpu_chip.disabled = true
			if is_instance_valid(matrix_text):
				matrix_text.visible = true
		Phase.INSERT_LEVER_UP:
			cpu_sprite.visible = true
			cpu_sprite.texture = TEX_INTEL_ABIERTO if is_intel else TEX_AMD_ABIERTO
			if is_instance_valid(cpu_chip):
				cpu_chip.visible = true
				cpu_chip.disabled = true
			if is_instance_valid(matrix_text):
				matrix_text.visible = false
		Phase.FASTEN_SCREWS, Phase.COMPLETED:
			cpu_sprite.visible = true
			cpu_sprite.texture = TEX_INTEL_CERRADO if is_intel else TEX_AMD_CERRADO
			if is_instance_valid(cpu_chip):
				cpu_chip.visible = true
				cpu_chip.disabled = true
			if is_instance_valid(matrix_text):
				matrix_text.visible = false

func _update_slots_ui() -> void:
	if target_cpu_count <= 1 or not is_instance_valid(slots_container):
		return
	var buttons = [btn_slot_0, btn_slot_1, btn_slot_2]
	for i in range(buttons.size()):
		var btn = buttons[i]
		if not is_instance_valid(btn):
			continue
		if i >= target_cpu_count:
			btn.visible = false
			continue
		btn.visible = true
		if cpu_installed_states[i]:
			btn.text = "✓ SOCKET CPU #%d [INSTALADO]" % (i + 1)
			btn.modulate = Color(0.2, 1.0, 0.45)
			btn.disabled = false
		elif i == current_cpu_index:
			if current_phase != Phase.COMPLETED and not cpu_installed_states[i] and (screws_removed.size() > 0 or cpu_chip.visible):
				btn.text = "➔ SOCKET CPU #%d (EN MONTAJE)" % (i + 1)
				btn.modulate = Color(0.0, 0.95, 1.0)
				btn.disabled = false
			else:
				btn.text = "➔ CLIC PARA MONTAR CPU #%d" % (i + 1)
				btn.modulate = Color(1.0, 0.85, 0.2)
				btn.disabled = false
		else:
			btn.text = "🔒 SOCKET CPU #%d [PENDIENTE]" % (i + 1)
			btn.modulate = Color(0.55, 0.6, 0.7, 0.6)
			btn.disabled = true

# =============================================================================
# FEEDBACK Y TEXTOS UI
# =============================================================================
func _update_ui_state() -> void:
	var prefix = ""
	if target_cpu_count > 1:
		prefix = "SOCKET CPU #%d DE %d · " % [current_cpu_index + 1, target_cpu_count]
		
	if is_instance_valid(guide_text):
		if require_screws_sequence:
			guide_text.text = "INSTRUCCIONES DE MONTAJE:\n\n1. Haz clic en el socket abierto para asentar el procesador Enterprise.\n2. Arrastra la palanca hacia arriba ↑ para trabar el socket.\n3. Atornilla la sujeción en orden estricto de apriete: [ 2 ➔ 3 ➔ 1 ].\n4. Repite la secuencia para los 3 procesadores del servidor."
		else:
			var has_cpu = false
			var gm = get_node_or_null("/root/GameManager")
			if gm and "backpack" in gm:
				for it in gm.backpack:
					if it.get("name") == "CPU" and not it.get("broken", true):
						has_cpu = true
						break
			var spare_msg = "✓ Procesador de repuesto detectado en inventario.\n\n" if has_cpu else "⚠️ Listo para montar procesador.\n\n"
			guide_text.text = "INSTRUCCIONES DE MONTAJE:\n\n" + spare_msg + "1. Haz clic en el socket para asentar el procesador.\n2. Arrastra la palanca hacia arriba ↑ para trabar la placa de carga."

	match current_phase:
		Phase.EXTRACT_LEVER_DOWN:
			status_label.text = prefix + "PASO 1: Arrastra la palanca metálica hacia abajo para liberar la tensión."
			status_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
			instruction_badge.text = "ACCION: ARRASTRA LA PALANCA HACIA ABAJO ↓"
			instruction_badge.modulate = Color(1.0, 0.85, 0.2, 1.0)
		Phase.EXTRACT_CPU_CLICK:
			status_label.text = prefix + "PASO 2: La protección se ha retirado. Haz clic sobre el CPU para extraerlo."
			status_label.modulate = Color(0.0, 0.95, 1.0, 1.0)
			instruction_badge.text = "ACCION: HAZ CLIC EN EL CPU PARA QUITARLO"
			instruction_badge.modulate = Color(0.0, 0.95, 1.0, 1.0)
		Phase.INSERT_CPU_CLICK:
			if require_screws_sequence:
				status_label.text = prefix + "PASO 1: Haz clic en el socket para colocar el procesador Enterprise."
			else:
				status_label.text = prefix + "PASO 1: Haz clic en el zócalo abierto para colocar el nuevo procesador."
			status_label.modulate = Color(0.2, 1.0, 0.6, 1.0)
			instruction_badge.text = "ACCION: HAZ CLIC EN EL ZÓCALO PARA INSERTAR CPU"
			instruction_badge.modulate = Color(0.2, 1.0, 0.6, 1.0)
		Phase.INSERT_LEVER_UP:
			status_label.text = prefix + "PASO 2: Arrastra la palanca hacia arriba ↑ para trabar el socket."
			status_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
			instruction_badge.text = "ACCION: ARRASTRA LA PALANCA HACIA ARRIBA ↑"
			instruction_badge.modulate = Color(1.0, 0.85, 0.2, 1.0)
		Phase.FASTEN_SCREWS:
			status_label.text = prefix + "PASO 3: Atornilla la sujeción en orden estricto de apriete: [ 2 ➔ 3 ➔ 1 ]."
			status_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
			var next_id = REQUIRED_SCREW_ORDER[current_screw_step] if current_screw_step < REQUIRED_SCREW_ORDER.size() else 0
			instruction_badge.text = "ACCION: ATORNILLA EL PERNO [%d]" % next_id
			instruction_badge.modulate = Color(1.0, 0.85, 0.2, 1.0)
		Phase.COMPLETED:
			status_label.text = ("¡LOS %d PROCESADORES ENTERPRISE INSTALADOS CON ÉXITO!" % target_cpu_count) if target_cpu_count > 1 else "¡OPERACIÓN DE CPU COMPLETADA CON ÉXITO!"
			status_label.modulate = Color(0.0, 1.0, 0.5, 1.0)
			instruction_badge.text = "✓ LISTO"
			instruction_badge.modulate = Color(0.0, 1.0, 0.5, 1.0)

func _show_feedback(msg: String, col: Color) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		if col.r > 0.7 and col.g < 0.5:
			if gm.has_method("register_error"):
				gm.register_error(2.0)
		elif col.g > 0.6:
			if gm.has_method("register_repair"):
				gm.register_repair(25, 2.0)
		
	feedback_label.text = msg
	feedback_label.modulate = col
	var tw = create_tween()
	tw.tween_property(feedback_label, "scale", Vector2(1.05, 1.05), 0.1)
	tw.tween_property(feedback_label, "scale", Vector2(1.0, 1.0), 0.15)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		_on_cancel_pressed()

func _on_cancel_pressed() -> void:
	minigame_finished.emit(false)
