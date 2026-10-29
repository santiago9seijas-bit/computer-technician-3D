extends CanvasLayer

# =============================================================================
# MINIJUEGO: DESMONTAJE Y MANTENIMIENTO DEL PROCESADOR (CPU)
# Enseña:
# 1. Limpiar pasta térmica vieja del IHS con alcohol isopropílico.
# 2. Desenganchar la palanca de tensión del socket (Retention Lever).
# 3. Abrir la placa de sujeción metálica (Load Plate).
# 4. Extraer el microprocesador sujetándolo de las esquinas sin doblar pines.
# =============================================================================

signal minigame_finished(success: bool)

enum State {
	CLEAN_PASTE,
	RELEASE_LEVER,
	OPEN_LOAD_PLATE,
	EXTRACT_CPU,
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

func _ready() -> void:
	layer = 12
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
	
	clean_progress_bar.value = 0.0
	warning_label.text = ""

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
	
	# Verificar si tiene equipada la herramienta de limpieza (ID 5)
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
	
	if is_lever_released:
		return
	
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
			status_label.text = "PASO 1: Usa [2] Paño Isopropílico y arrastra el ratón sobre la pasta gris para limpiarla."
			status_label.modulate = Color(1.0, 0.85, 0.2)
		State.RELEASE_LEVER:
			status_label.text = "PASO 2: Haz clic en la palanca lateral metálica para desengancharla y levantarla."
			status_label.modulate = Color(1.0, 0.85, 0.2)
		State.OPEN_LOAD_PLATE:
			status_label.text = "PASO 3: Haz clic en 'ABRIR PLACA DE CARGA' para levantar el marco de sujeción."
			status_label.modulate = Color(1.0, 0.4, 0.8)
		State.EXTRACT_CPU:
			status_label.text = "PASO 4: Sujeta la CPU por las esquinas y presiona 'EXTRAER PROCESADOR'."
			status_label.modulate = Color(0.2, 1.0, 0.4)
		State.COMPLETED:
			status_label.text = "¡DESMONTAJE COMPLETADO! Zócalo protegido y procesador a salvo."
			status_label.modulate = Color(0.2, 1.0, 0.4)
