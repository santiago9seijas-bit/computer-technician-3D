extends CanvasLayer

# =============================================================================
# MINIJUEGO: DESMONTAJE Y MONTAJE DEL PROCESADOR (CPU)
# Enseña:
# FASE QUITAR:
# 1. Limpiar pasta térmica vieja del IHS con alcohol isopropílico.
# 2. Desenganchar la palanca de tensión del socket (Retention Lever).
# 3. Abrir la placa de sujeción metálica (Load Plate).
# 4. Extraer el microprocesador sujetándolo de las esquinas sin doblar pines.
# FASE PONER:
# 1. Asentar el microprocesador nuevo alineando el triángulo polarizado (Notch).
# 2. Bajar la placa de presión sobre el procesador.
# 3. Bloquear la palanca lateral bajo el pestillo de seguridad.
# 4. Dispensar compuesto térmico en el centro del IHS.
# =============================================================================

signal minigame_finished(success: bool)
signal old_part_extracted()

var start_as_empty_slot: bool = false
var is_tutorial_mode: bool = false

enum State {
	# Fase Desmontaje (Quitar)
	CLEAN_PASTE,
	RELEASE_LEVER,
	OPEN_LOAD_PLATE,
	EXTRACT_CPU,
	# Fase Montaje (Poner)
	INSERT_CPU,
	CLOSE_LOAD_PLATE,
	LOCK_LEVER,
	APPLY_PASTE,
	COMPLETED
}

var current_state: State = State.CLEAN_PASTE

# Progreso de limpieza (0.0 a 100.0)
var paste_cleaned_percent: float = 0.0
var is_lever_released: bool = false
var is_plate_opened: bool = false
var is_cpu_extracted: bool = false

# Nodos UI
@onready var modal_control: Control = $ModalControl
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var btn_tool_1: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool1
@onready var btn_tool_2: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool2
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel

@onready var work_area: Control = $ModalControl/Panel/VBox/WorkArea
@onready var socket_panel: Panel = $ModalControl/Panel/VBox/WorkArea/SocketBase
@onready var cpu_ihs: Panel = $ModalControl/Panel/VBox/WorkArea/SocketBase/CPUIHS
@onready var paste_stain: ColorRect = $ModalControl/Panel/VBox/WorkArea/SocketBase/CPUIHS/PasteStain
@onready var clean_progress_bar: ProgressBar = $ModalControl/Panel/VBox/WorkArea/CleanProgress/ProgressBar
@onready var clean_progress_container: Control = $ModalControl/Panel/VBox/WorkArea/CleanProgress

@onready var load_plate: Panel = $ModalControl/Panel/VBox/WorkArea/SocketBase/LoadPlate
@onready var lever_btn: Button = $ModalControl/Panel/VBox/WorkArea/SocketBase/BtnLever
@onready var lever_label: Label = $ModalControl/Panel/VBox/WorkArea/SocketBase/LeverStatus

@onready var btn_open_plate: Button = $ModalControl/Panel/VBox/WorkArea/SocketBase/BtnOpenPlate
@onready var btn_extract_cpu: Button = $ModalControl/Panel/VBox/WorkArea/SocketBase/BtnExtractCPU
@onready var warning_label: Label = $ModalControl/Panel/VBox/WorkArea/WarningLabel
@onready var notch_indicator: Label = $ModalControl/Panel/VBox/WorkArea/SocketBase/CPUIHS/NotchIndicator

var orig_ihs_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	layer = 12
	orig_ihs_pos = cpu_ihs.position
	_setup_ui()
	_update_tool_buttons()
	_update_status()

func _setup_ui() -> void:
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	
	btn_tool_1.pressed.connect(func(): GameManager.select_tool(1))
	btn_tool_2.pressed.connect(func(): GameManager.select_tool(5))
	GameManager.tool_selected.connect(_on_tool_selected)
	
	# Interacción de limpieza sobre la pasta térmica
	paste_stain.gui_input.connect(_on_paste_gui_input)
	
	# Palanca de retención
	lever_btn.pressed.connect(_on_lever_pressed)
	
	# Placa de carga
	btn_open_plate.pressed.connect(_on_open_plate_pressed)
	btn_open_plate.visible = false
	
	# Extracción
	btn_extract_cpu.pressed.connect(_on_extract_cpu_pressed)
	btn_extract_cpu.visible = false
	
	warning_label.text = ""
	
	if start_as_empty_slot:
		# Iniciar en modo montaje (socket abierto sin CPU)
		current_state = State.INSERT_CPU
		clean_progress_container.visible = false
		paste_stain.visible = false
		cpu_ihs.visible = false
		load_plate.scale.y = 0.15
		load_plate.modulate.a = 0.2
		is_lever_released = true
		is_plate_opened = true
		lever_btn.rotation_degrees = -85.0
		lever_btn.modulate = Color(0.2, 1.0, 0.4)
		lever_label.text = "PALANCA: LIBERADA (90°)"
		lever_label.modulate = Color(0.2, 1.0, 0.4)
		
		btn_extract_cpu.text = "⬇ ASENTAR PROCESADOR NUEVO (Alinear ▲)"
		btn_extract_cpu.visible = true
		btn_extract_cpu.modulate = Color(0.2, 1.0, 0.6)
		btn_extract_cpu.pressed.disconnect(_on_extract_cpu_pressed)
		btn_extract_cpu.pressed.connect(_on_insert_cpu_pressed)
	else:
		current_state = State.CLEAN_PASTE
		clean_progress_bar.value = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_1:
			GameManager.select_tool(1)
		elif event.keycode == KEY_5 or event.keycode == KEY_2:
			GameManager.select_tool(5)
		elif event.keycode == KEY_ESCAPE:
			minigame_finished.emit(false)

func _on_tool_selected(_tool_id: int) -> void:
	_update_tool_buttons()

func _update_tool_buttons() -> void:
	var active = GameManager.equipped_tool
	btn_tool_1.modulate = Color(1.2, 1.2, 0.4) if active == 1 else Color(0.8, 0.8, 0.8)
	btn_tool_2.modulate = Color(1.2, 1.2, 0.4) if active == 5 else Color(0.8, 0.8, 0.8)

func _on_paste_gui_input(event: InputEvent) -> void:
	if current_state != State.CLEAN_PASTE:
		return
	
	if GameManager.equipped_tool != 5:
		if event is InputEventMouseButton and event.pressed:
			_show_warning("Selecciona el [2] Paño con Alcohol Isopropílico para disolver la pasta seca.", Color(1.0, 0.4, 0.4))
		return
	
	if (event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT)) or (event is InputEventMouseButton and event.pressed):
		paste_cleaned_percent += 3.5
		if paste_cleaned_percent > 100.0:
			paste_cleaned_percent = 100.0
		
		clean_progress_bar.value = paste_cleaned_percent
		var alpha = 1.0 - (paste_cleaned_percent / 100.0)
		paste_stain.modulate.a = alpha
		
		if paste_cleaned_percent >= 100.0:
			_show_warning("✓ ¡IHS limpio y reluciente! Alcohol isopropílico evaporado.", Color(0.2, 1.0, 0.4))
			current_state = State.RELEASE_LEVER
			clean_progress_container.visible = false
			_update_status()

func _on_lever_pressed() -> void:
	if current_state == State.CLEAN_PASTE:
		_show_warning("Limpia primero el residuo de pasta antes de manipular la palanca.", Color(1.0, 0.4, 0.4))
		return
	
	if current_state == State.RELEASE_LEVER:
		if is_lever_released: return
		is_lever_released = true
		var tw = create_tween().set_parallel(true)
		tw.tween_property(lever_btn, "rotation_degrees", -85.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(lever_btn, "modulate", Color(0.2, 1.0, 0.4), 0.3)
		lever_label.text = "PALANCA: LIBERADA (90°)"
		lever_label.modulate = Color(0.2, 1.0, 0.4)
		
		_show_warning("✓ ¡Palanca desenganchada! Tensión del socket liberada.", Color(0.2, 1.0, 0.4))
		current_state = State.OPEN_LOAD_PLATE
		btn_open_plate.visible = true
		_update_status()
		
	elif current_state == State.LOCK_LEVER:
		# Fase de montaje: bajar la palanca y trabarla
		var tw = create_tween().set_parallel(true)
		tw.tween_property(lever_btn, "rotation_degrees", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(lever_btn, "modulate", Color(1.0, 1.0, 1.0), 0.3)
		lever_label.text = "PALANCA: TRABADA (0°)"
		lever_label.modulate = Color(1.0, 0.35, 0.35, 1.0)
		
		_show_warning("✓ ¡Palanca trabada bajo el pestillo! Presión de contacto establecida.", Color(0.2, 1.0, 0.4))
		current_state = State.APPLY_PASTE
		btn_extract_cpu.text = "💧 APLICAR PASTA TÉRMICA EN IHS"
		btn_extract_cpu.visible = true
		btn_extract_cpu.disabled = false
		btn_extract_cpu.modulate = Color(0.2, 0.9, 1.0)
		btn_extract_cpu.pressed.disconnect(_on_insert_cpu_pressed)
		btn_extract_cpu.pressed.connect(_on_apply_paste_pressed)
		_update_status()

func _on_open_plate_pressed() -> void:
	if not is_lever_released:
		_show_warning("¡ALERTA! Debes desenganchar la palanca antes de abrir la placa de carga.", Color(1.0, 0.2, 0.2))
		return
	
	if is_plate_opened:
		return
	
	is_plate_opened = true
	btn_open_plate.disabled = true
	var tw = create_tween().set_parallel(true)
	tw.tween_property(load_plate, "scale:y", 0.15, 0.35).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(load_plate, "modulate:a", 0.2, 0.35)
	
	_show_warning("✓ Placa de presión abierta. El microprocesador está listo para extracción.", Color(0.2, 1.0, 0.4))
	current_state = State.EXTRACT_CPU
	btn_extract_cpu.visible = true
	btn_extract_cpu.modulate = Color(1, 1, 1, 0)
	var tw_btn = create_tween()
	tw_btn.tween_property(btn_extract_cpu, "modulate:a", 1.0, 0.3)
	_update_status()

func _on_close_plate_pressed() -> void:
	btn_open_plate.disabled = true
	btn_open_plate.visible = false
	var tw = create_tween().set_parallel(true)
	tw.tween_property(load_plate, "scale:y", 1.0, 0.35).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(load_plate, "modulate:a", 1.0, 0.35)
	await tw.finished
	
	_show_warning("✓ Placa de presión cerrada sobre el procesador.", Color(0.2, 1.0, 0.4))
	current_state = State.LOCK_LEVER
	_update_status()

func _on_extract_cpu_pressed() -> void:
	if is_cpu_extracted:
		return
	
	is_cpu_extracted = true
	btn_extract_cpu.disabled = true
	current_state = State.COMPLETED
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(cpu_ihs, "scale", Vector2(1.2, 1.2), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(cpu_ihs, "position:y", cpu_ihs.position.y - 120.0, 0.5)
	tw.tween_property(cpu_ihs, "modulate:a", 0.5, 0.5)
	
	await tw.finished
	_show_warning("✓ ¡PERFECTO! CPU retirada sujetando los bordes sin tocar los contactos.", Color(0.2, 1.0, 0.4))
	_update_status()
	old_part_extracted.emit()
	await get_tree().create_timer(1.6).timeout
	minigame_finished.emit(true)

func _on_insert_cpu_pressed() -> void:
	btn_extract_cpu.disabled = true
	btn_extract_cpu.visible = false
	
	cpu_ihs.visible = true
	cpu_ihs.position.y = orig_ihs_pos.y - 100.0
	cpu_ihs.scale = Vector2(1.2, 1.2)
	cpu_ihs.modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(cpu_ihs, "position:y", orig_ihs_pos.y, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(cpu_ihs, "scale", Vector2(1.0, 1.0), 0.45)
	tw.tween_property(cpu_ihs, "modulate:a", 1.0, 0.35)
	await tw.finished
	
	var tw_notch = create_tween().set_loops(3)
	tw_notch.tween_property(notch_indicator, "modulate", Color(0.2, 1.0, 0.4), 0.15)
	tw_notch.tween_property(notch_indicator, "modulate", Color(1.0, 0.85, 0.2), 0.15)
	
	_show_warning("✓ ¡CPU asentada en el zócalo! Muesca polarizada alineada con el socket.", Color(0.2, 1.0, 0.4))
	current_state = State.CLOSE_LOAD_PLATE
	btn_open_plate.text = "🔒 BAJAR PLACA DE CARGA"
	btn_open_plate.visible = true
	btn_open_plate.disabled = false
	btn_open_plate.pressed.disconnect(_on_open_plate_pressed)
	btn_open_plate.pressed.connect(_on_close_plate_pressed)
	_update_status()

func _on_apply_paste_pressed() -> void:
	btn_extract_cpu.disabled = true
	btn_extract_cpu.visible = false
	
	paste_stain.visible = true
	paste_stain.color = Color(0.7, 0.72, 0.76, 1.0)
	var lbl = paste_stain.get_node_or_null("PasteLabel") as Label
	if lbl:
		lbl.text = "PASTA TÉRMICA NUEVA\n[ APLICADA ✓ ]"
		lbl.add_theme_color_override("font_color", Color(0.1, 0.15, 0.2))
		
	paste_stain.scale = Vector2(0.1, 0.1)
	paste_stain.modulate.a = 0.0
	var tw = create_tween().set_parallel(true)
	tw.tween_property(paste_stain, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(paste_stain, "modulate:a", 1.0, 0.2)
	await tw.finished
	
	current_state = State.COMPLETED
	_show_warning("✓ ¡Pasta térmica aplicada con éxito! Procesador 100% montado y protegido.", Color(0.2, 1.0, 0.4))
	_update_status()
	await get_tree().create_timer(1.6).timeout
	minigame_finished.emit(true)

func _show_warning(msg: String, col: Color) -> void:
	warning_label.text = msg
	warning_label.modulate = col
	var tw = create_tween()
	tw.tween_property(warning_label, "scale", Vector2(1.06, 1.06), 0.1)
	tw.tween_property(warning_label, "scale", Vector2(1.0, 1.0), 0.15)

func _update_status() -> void:
	match current_state:
		State.CLEAN_PASTE:
			status_label.text = "PASO 1 (QUITAR): Usa [2] Paño Isopropílico y arrastra el ratón sobre la pasta gris para limpiarla."
			status_label.modulate = Color(1.0, 0.85, 0.2)
		State.RELEASE_LEVER:
			status_label.text = "PASO 2 (QUITAR): Haz clic en la palanca lateral metálica para desengancharla y levantarla."
			status_label.modulate = Color(1.0, 0.85, 0.2)
		State.OPEN_LOAD_PLATE:
			status_label.text = "PASO 3 (QUITAR): Haz clic en 'ABRIR PLACA DE CARGA' para levantar el marco de sujeción."
			status_label.modulate = Color(1.0, 0.4, 0.8)
		State.EXTRACT_CPU:
			status_label.text = "PASO 4 (QUITAR): Sujeta la CPU por las esquinas y presiona 'EXTRAER PROCESADOR'."
			status_label.modulate = Color(0.2, 1.0, 0.4)
		State.INSERT_CPU:
			status_label.text = "PASO 1 (PONER): Asienta el nuevo microprocesador alineando la muesca polarizada [▲]."
			status_label.modulate = Color(0.2, 1.0, 0.6)
		State.CLOSE_LOAD_PLATE:
			status_label.text = "PASO 2 (PONER): Presiona 'BAJAR PLACA DE CARGA' para asegurar el marco."
			status_label.modulate = Color(1.0, 0.4, 0.8)
		State.LOCK_LEVER:
			status_label.text = "PASO 3 (PONER): Haz clic en la palanca lateral metálica para bajarla y engancharla a 0°."
			status_label.modulate = Color(1.0, 0.85, 0.2)
		State.APPLY_PASTE:
			status_label.text = "PASO 4 (PONER): Presiona 'APLICAR PASTA TÉRMICA' para dispensar compuesto de alta conductividad."
			status_label.modulate = Color(0.2, 0.9, 1.0)
		State.COMPLETED:
			if start_as_empty_slot:
				status_label.text = "¡MONTAJE COMPLETADO! Procesador instalado y listo para recibir el disipador."
			else:
				status_label.text = "¡DESMONTAJE COMPLETADO! Zócalo protegido y procesador a salvo."
			status_label.modulate = Color(0.2, 1.0, 0.4)
