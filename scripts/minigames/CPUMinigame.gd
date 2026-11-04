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

@export var start_as_empty_slot: bool = false
@export var is_tutorial_mode: bool = false
@export var require_screws_sequence: bool = false

enum Phase {
	EXTRACT_SCREWS,     # Desatornillar en orden: 3 -> 1 -> 2 (Solo nivel servidor)
	EXTRACT_LEVER_DOWN, # Arrastrar palanca abajo
	EXTRACT_CPU_CLICK,  # Clic en CPU para sacarlo
	INSERT_CPU_CLICK,   # Clic en socket para poner CPU
	INSERT_LEVER_UP,    # Arrastrar palanca arriba para trabar
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

# Área del Socket
@onready var socket_base: Panel = $ModalControl/Panel/VBox/WorkArea/SocketBase
@onready var socket_grid_pattern: Panel = $ModalControl/Panel/VBox/WorkArea/SocketBase/PinsMatrix
@onready var cpu_chip: Button = $ModalControl/Panel/VBox/WorkArea/SocketBase/CPUChip
@onready var notch_indicator: Label = $ModalControl/Panel/VBox/WorkArea/SocketBase/CPUChip/NotchIndicator
@onready var load_plate: Panel = $ModalControl/Panel/VBox/WorkArea/SocketBase/LoadPlate

# Tornillos de sujeción (para área de servidor: orden 3 -> 1 -> 2)
@onready var screw_1: Button = get_node_or_null("ModalControl/Panel/VBox/WorkArea/SocketBase/Screw1")
@onready var screw_2: Button = get_node_or_null("ModalControl/Panel/VBox/WorkArea/SocketBase/Screw2")
@onready var screw_3: Button = get_node_or_null("ModalControl/Panel/VBox/WorkArea/SocketBase/Screw3")

const REQUIRED_SCREW_ORDER: Array[int] = [3, 1, 2]
var current_screw_step: int = 0
var screws_removed: Array[int] = []

# Palanca
@onready var lever_handle: Button = $ModalControl/Panel/VBox/WorkArea/SocketBase/LeverArea/LeverHandle
@onready var lever_arrow: Label = $ModalControl/Panel/VBox/WorkArea/SocketBase/LeverArea/LeverArrow
@onready var lever_status_text: Label = $ModalControl/Panel/VBox/WorkArea/SocketBase/LeverArea/LeverStatusText

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
		
	# Definir visibilidad de tornillos según modo
	_apply_screws_visibility(require_screws_sequence)
	
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
	
	# Placa protectora cerrada sobre el procesador
	load_plate.visible = true
	load_plate.position.y = 20.0
	load_plate.modulate.a = 1.0
	load_plate.scale = Vector2(1.0, 1.0)
	
	# CPU visible pero protegido
	cpu_chip.visible = true
	cpu_chip.disabled = true
	cpu_chip.mouse_default_cursor_shape = Control.CURSOR_ARROW
	
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
	
	# Placa de protección abierta (plegada hacia arriba)
	load_plate.visible = true
	load_plate.position.y = -70.0
	load_plate.modulate.a = 0.25
	load_plate.scale = Vector2(1.0, 0.2)
	
	# Socket vacío (sin CPU aún)
	cpu_chip.visible = false
	cpu_chip.disabled = false
	cpu_chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	_update_ui_state()
	_show_feedback("Haz clic en el socket para asentar el nuevo procesador.", Color(0.2, 0.95, 1.0))

# =============================================================================
# ÁREA DE SERVIDOR: MONTAJE DUAL CPU ENTERPRISE CON TORNILLOS (3 -> 1 -> 2)
# =============================================================================
func _setup_server_mode() -> void:
	current_phase = Phase.EXTRACT_SCREWS
	current_screw_step = 0
	screws_removed.clear()
	title_label.text = "MONTAJE INDUSTRIAL: DUAL CPU ENTERPRISE"
	
	_reset_screws()
	
	# Palanca bloqueada mientras haya tornillos de sujeción
	lever_handle.position.y = LEVER_BOTTOM_Y
	lever_handle.disabled = true
	lever_handle.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
	lever_arrow.visible = false
	lever_status_text.text = "PALANCA:\nBLOQUEADA\n(TORNILLOS)"
	lever_status_text.modulate = Color(1.0, 0.35, 0.35, 1.0)
	
	# Placa protectora de fábrica cerrada sobre el zócalo
	load_plate.visible = true
	load_plate.position.y = 20.0
	load_plate.modulate.a = 1.0
	load_plate.scale = Vector2(1.0, 1.0)
	
	# Socket sin CPU aún
	cpu_chip.visible = false
	cpu_chip.disabled = true
	cpu_chip.mouse_default_cursor_shape = Control.CURSOR_ARROW
	
	_update_screw_ui()
	_update_ui_state()
	_show_feedback("PASO 1: Desatornilla el soporte del socket en el orden correcto: 3 ➔ 1 ➔ 2.", Color(1.0, 0.85, 0.2))

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
	if current_phase != Phase.EXTRACT_SCREWS:
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
			tw.tween_property(btn, "scale", Vector2(0.1, 0.1), 0.35)
			tw.tween_property(btn, "modulate:a", 0.0, 0.35)
			
		_update_screw_ui()
		
		if current_screw_step >= REQUIRED_SCREW_ORDER.size():
			_show_feedback("✓ ¡Tornillos retirados en el orden 3 ➔ 1 ➔ 2! Soporte liberado.", Color(0.2, 1.0, 0.5))
			if get_tree():
				await get_tree().create_timer(0.45).timeout
			_complete_screws_phase()
		else:
			var next_screw = REQUIRED_SCREW_ORDER[current_screw_step]
			_show_feedback("✓ ¡Tornillo %d retirado! Siguiente tornillo en orden: [%d]." % [screw_id, next_screw], Color(0.2, 0.95, 1.0))
			_update_ui_state()
	else:
		var btn = _get_screw_button(screw_id)
		if btn:
			_shake_button(btn)
			
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("register_error"):
			gm.register_error(2.0)
			
		_show_feedback("❌ ¡Orden incorrecto! Debes aflojar en orden: 3 ➔ 1 ➔ 2 (Debes retirar primero el Tornillo %d)" % expected_screw, Color(1.0, 0.35, 0.35))

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
	var text_s3 = "[3 ✓]" if 3 in screws_removed else "[3]"
	var text_s1 = "[1 ✓]" if 1 in screws_removed else "[1]"
	var text_s2 = "[2 ✓]" if 2 in screws_removed else "[2]"
	order_badge.text = "ORDEN DE TORNILLOS:  %s  ➔  %s  ➔  %s" % [text_s3, text_s1, text_s2]

func _complete_screws_phase() -> void:
	current_phase = Phase.INSERT_CPU_CLICK
	# Placa de protección abierta (plegada hacia arriba)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(load_plate, "position:y", -70.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(load_plate, "scale", Vector2(1.0, 0.2), 0.4)
	tw.tween_property(load_plate, "modulate:a", 0.25, 0.4)
	
	lever_handle.position.y = LEVER_BOTTOM_Y
	lever_handle.disabled = false
	lever_status_text.text = "PALANCA:\nLIBERADA [90°]"
	lever_status_text.modulate = Color(0.2, 1.0, 0.5, 1.0)
	
	cpu_chip.visible = false
	cpu_chip.disabled = false
	cpu_chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	_update_ui_state()
	_show_feedback("✓ ¡Cubierta retirada! Haz clic en el socket para asentar el procesador Enterprise.", Color(0.2, 0.95, 1.0))

# =============================================================================
# ARRASTRE DE LA PALANCA CON EL RATÓN
# =============================================================================
func _on_lever_gui_input(event: InputEvent) -> void:
	if require_screws_sequence and current_phase == Phase.EXTRACT_SCREWS:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_show_feedback("⚠️ ¡La palanca está bloqueada! Primero debes desatornillar los tornillos en orden: 3 ➔ 1 ➔ 2.", Color(1.0, 0.4, 0.4))
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
	lever_handle.position.y = LEVER_BOTTOM_Y
	lever_status_text.text = "PALANCA:\nLIBERADA [90°]"
	lever_status_text.modulate = Color(0.2, 1.0, 0.5, 1.0)
	lever_arrow.visible = false
	
	current_phase = Phase.EXTRACT_CPU_CLICK
	cpu_chip.disabled = false
	cpu_chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_update_ui_state()
	_show_feedback("✓ ¡Protección retirada! Haz clic en el CPU para extraerlo.", Color(0.0, 0.95, 1.0))
	
	# Quitar la protección con animación fluida
	var tw = create_tween().set_parallel(true)
	tw.tween_property(load_plate, "position:y", -70.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(load_plate, "scale", Vector2(1.0, 0.2), 0.45)
	tw.tween_property(load_plate, "modulate:a", 0.25, 0.45)
	
	# Efecto de pulso en el CPU para indicar que es clickeable
	var tw_pulse = create_tween().set_loops(4)
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
		gm.add_item_to_backpack({"name": "CPU", "broken": true})
	old_part_extracted.emit()
	
	_show_feedback("✓ ¡CPU retirado con éxito! El socket está listo para el repuesto.", Color(0.0, 1.0, 0.5))
	
	# Animación de elevación y retiro del CPU
	var tw = create_tween().set_parallel(true)
	tw.tween_property(cpu_chip, "position:y", cpu_chip.position.y - 100.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(cpu_chip, "scale", Vector2(1.25, 1.25), 0.45)
	tw.tween_property(cpu_chip, "modulate:a", 0.0, 0.45)
	await tw.finished
	
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
	current_phase = Phase.INSERT_LEVER_UP
	cpu_chip.visible = true
	cpu_chip.disabled = true
	
	_show_feedback("✓ Asentando procesador en el zócalo...", Color(0.2, 0.95, 1.0))
	
	# Animación de caída e inserción del CPU
	cpu_chip.position.y = -80.0
	cpu_chip.scale = Vector2(1.25, 1.25)
	cpu_chip.modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(cpu_chip, "position:y", 25.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(cpu_chip, "scale", Vector2(1.0, 1.0), 0.45)
	tw.tween_property(cpu_chip, "modulate:a", 1.0, 0.35)
	await tw.finished
	
	# Destello del notch de alineación
	var tw_notch = create_tween().set_loops(3)
	tw_notch.tween_property(notch_indicator, "modulate", Color(0.0, 1.0, 0.5), 0.15)
	tw_notch.tween_property(notch_indicator, "modulate", Color(1.0, 0.85, 0.2), 0.15)
	
	# Bajar la placa de protección sobre el procesador
	var tw_plate = create_tween().set_parallel(true)
	tw_plate.tween_property(load_plate, "position:y", 20.0, 0.35).set_trans(Tween.TRANS_QUAD)
	tw_plate.tween_property(load_plate, "scale", Vector2(1.0, 1.0), 0.35)
	tw_plate.tween_property(load_plate, "modulate:a", 1.0, 0.35)
	await tw_plate.finished
	
	lever_arrow.visible = true
	lever_arrow.text = "▲\nARRASTRA\nARRIBA"
	lever_arrow.modulate = Color(1.0, 0.85, 0.2, 1.0)
	
	_update_ui_state()
	_show_feedback("✓ CPU colocado. Arrastra la palanca hacia arriba ↑ para asegurar la protección.", Color(1.0, 0.85, 0.2))

# =============================================================================
# FASE MONTAJE: PALANCA ARRIBA (LADO CONTRARIO) PARA TRABAR
# =============================================================================
func _complete_lever_up() -> void:
	lever_handle.position.y = LEVER_TOP_Y
	lever_status_text.text = "PALANCA:\nTRABADA [0°]"
	lever_status_text.modulate = Color(0.2, 1.0, 0.5, 1.0)
	lever_arrow.visible = false
	current_phase = Phase.COMPLETED
	
	# Retirar el repuesto nuevo de la mochila si el jugador tenía uno
	var gm_up = get_node_or_null("/root/GameManager")
	if gm_up and "backpack" in gm_up:
		for i in range(gm_up.backpack.size()):
			var it = gm_up.backpack[i]
			if it is Dictionary and (it.get("name") == "CPU" or it.get("type") == "CPU") and not it.get("broken", true):
				if gm_up.has_method("remove_item_from_backpack"):
					gm_up.remove_item_from_backpack(i)
				break
				
	_show_feedback("✓ ¡Palanca trabada y protección asegurada con éxito!", Color(0.0, 1.0, 0.5))
	_update_ui_state()
	
	if get_tree():
		await get_tree().create_timer(1.2).timeout
	minigame_finished.emit(true)

# =============================================================================
# FEEDBACK Y TEXTOS UI
# =============================================================================
func _update_ui_state() -> void:
	match current_phase:
		Phase.EXTRACT_SCREWS:
			status_label.text = "PASO 1: Desatornilla el soporte del socket en el orden de descompresión: [ 3 ➔ 1 ➔ 2 ]."
			status_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
			var next_id = REQUIRED_SCREW_ORDER[current_screw_step] if current_screw_step < REQUIRED_SCREW_ORDER.size() else 0
			instruction_badge.text = "ACCION: HAZ CLIC EN EL TORNILLO [%d] PARA DESATORNILLARLO" % next_id
			instruction_badge.modulate = Color(1.0, 0.85, 0.2, 1.0)
		Phase.EXTRACT_LEVER_DOWN:
			status_label.text = "PASO 1: Arrastra la palanca metálica hacia abajo para liberar la tensión."
			status_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
			instruction_badge.text = "ACCION: ARRASTRA LA PALANCA HACIA ABAJO ↓"
			instruction_badge.modulate = Color(1.0, 0.85, 0.2, 1.0)
		Phase.EXTRACT_CPU_CLICK:
			status_label.text = "PASO 2: La protección se ha retirado. Haz clic sobre el CPU para extraerlo."
			status_label.modulate = Color(0.0, 0.95, 1.0, 1.0)
			instruction_badge.text = "ACCION: HAZ CLIC EN EL CPU PARA QUITARLO"
			instruction_badge.modulate = Color(0.0, 0.95, 1.0, 1.0)
		Phase.INSERT_CPU_CLICK:
			if require_screws_sequence:
				status_label.text = "PASO 2: Haz clic en el socket para colocar el procesador Enterprise."
			else:
				status_label.text = "PASO 1: Haz clic en el zócalo abierto para colocar el nuevo procesador."
			status_label.modulate = Color(0.2, 1.0, 0.6, 1.0)
			instruction_badge.text = "ACCION: HAZ CLIC EN EL ZÓCALO PARA INSERTAR CPU"
			instruction_badge.modulate = Color(0.2, 1.0, 0.6, 1.0)
		Phase.INSERT_LEVER_UP:
			if require_screws_sequence:
				status_label.text = "PASO 3: Arrastra la palanca hacia arriba para trabar el socket."
			else:
				status_label.text = "PASO 2: Arrastra la palanca hacia arriba para trabar el socket."
			status_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
			instruction_badge.text = "ACCION: ARRASTRA LA PALANCA HACIA ARRIBA ↑"
			instruction_badge.modulate = Color(1.0, 0.85, 0.2, 1.0)
		Phase.COMPLETED:
			status_label.text = "¡OPERACIÓN DE CPU COMPLETADA CON ÉXITO!"
			status_label.modulate = Color(0.0, 1.0, 0.5, 1.0)
			instruction_badge.text = "✓ LISTO"
			instruction_badge.modulate = Color(0.0, 1.0, 0.5, 1.0)

func _show_feedback(msg: String, col: Color) -> void:
	if col.r > 0.7 and col.g < 0.5:
		GameManager.register_error(2.0)
	elif col.g > 0.6:
		GameManager.register_repair(25, 2.0)
		
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
