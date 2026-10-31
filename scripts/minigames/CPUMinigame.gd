extends CanvasLayer

# =============================================================================
# MINIJUEGO: EXTRACCIÓN Y MONTAJE DEL PROCESADOR (CPU)
# Mecánica:
# FASE SACAR (Extracción):
# 1. Arrastrar la palanca lateral hacia abajo (libera la tensión del socket).
# 2. Se quita la placa de protección metálica automáticamente al bajar la palanca.
# 3. Hacer clic en el CPU para extraerlo del zócalo.
# FASE PONER (Montaje):
# 1. Hacer clic en el zócalo para colocar el nuevo procesador.
# 2. Arrastrar la palanca hacia arriba (al lado contrario) para asegurar y bloquear.
# =============================================================================

signal minigame_finished(success: bool)
signal old_part_extracted()

@export var start_as_empty_slot: bool = false
@export var is_tutorial_mode: bool = false

enum Phase {
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
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel
@onready var feedback_label: Label = $ModalControl/Panel/VBox/FeedbackLabel

# Área del Socket
@onready var socket_base: Panel = $ModalControl/Panel/VBox/WorkArea/SocketBase
@onready var socket_grid_pattern: Panel = $ModalControl/Panel/VBox/WorkArea/SocketBase/PinsMatrix
@onready var cpu_chip: Button = $ModalControl/Panel/VBox/WorkArea/SocketBase/CPUChip
@onready var cpu_label: Label = $ModalControl/Panel/VBox/WorkArea/SocketBase/CPUChip/CPULabel
@onready var notch_indicator: Label = $ModalControl/Panel/VBox/WorkArea/SocketBase/CPUChip/NotchIndicator
@onready var load_plate: Panel = $ModalControl/Panel/VBox/WorkArea/SocketBase/LoadPlate

# Palanca
@onready var lever_track: Panel = $ModalControl/Panel/VBox/WorkArea/SocketBase/LeverArea/LeverTrack
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
	
	if start_as_empty_slot:
		_setup_insert_mode()
	else:
		_setup_extract_mode()

func _setup_extract_mode() -> void:
	current_phase = Phase.EXTRACT_LEVER_DOWN
	title_label.text = "DESMONTAJE: EXTRACCIÓN DE PROCESADOR (CPU)"
	
	# Palanca arriba (trabada)
	lever_handle.position.y = LEVER_TOP_Y
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

func _setup_insert_mode() -> void:
	current_phase = Phase.INSERT_CPU_CLICK
	title_label.text = "MONTAJE: INSTALACIÓN DE PROCESADOR NUEVO (CPU)"
	
	# Palanca abajo (abierta)
	lever_handle.position.y = LEVER_BOTTOM_Y
	lever_arrow.text = "▲\nARRASTRA\nARRIBA"
	lever_arrow.modulate = Color(0.2, 0.8, 1.0, 0.6)
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
# ARRASTRE DE LA PALANCA CON EL RATÓN
# =============================================================================
func _on_lever_gui_input(event: InputEvent) -> void:
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
	old_part_extracted.emit()
	
	_show_feedback("✓ ¡CPU retirado con éxito! El socket está listo para el repuesto.", Color(0.0, 1.0, 0.5))
	
	# Animación de elevación y retiro del CPU
	var tw = create_tween().set_parallel(true)
	tw.tween_property(cpu_chip, "position:y", cpu_chip.position.y - 100.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(cpu_chip, "scale", Vector2(1.25, 1.25), 0.45)
	tw.tween_property(cpu_chip, "modulate:a", 0.0, 0.45)
	await tw.finished
	
	cpu_chip.visible = false
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
	
	_show_feedback("✓ Asentando procesador nuevo en el zócalo...", Color(0.2, 0.95, 1.0))
	
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
	
	_show_feedback("✓ ¡Palanca trabada y protección asegurada con éxito!", Color(0.0, 1.0, 0.5))
	_update_ui_state()
	
	await get_tree().create_timer(1.2).timeout
	minigame_finished.emit(true)

# =============================================================================
# FEEDBACK Y TEXTOS UI
# =============================================================================
func _update_ui_state() -> void:
	match current_phase:
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
			status_label.text = "PASO 1: Haz clic en el zócalo abierto para colocar el nuevo procesador."
			status_label.modulate = Color(0.2, 1.0, 0.6, 1.0)
			instruction_badge.text = "ACCION: HAZ CLIC EN EL ZÓCALO PARA INSERTAR CPU"
			instruction_badge.modulate = Color(0.2, 1.0, 0.6, 1.0)
		Phase.INSERT_LEVER_UP:
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
	feedback_label.text = msg
	feedback_label.modulate = col
	var tw = create_tween()
	tw.tween_property(feedback_label, "scale", Vector2(1.05, 1.05), 0.1)
	tw.tween_property(feedback_label, "scale", Vector2(1.0, 1.0), 0.15)

func _on_cancel_pressed() -> void:
	minigame_finished.emit(false)
