extends CanvasLayer

# =============================================================================
# MINIJUEGO: LIMPIEZA DE PASTA TÉRMICA EN IHS (CPU)
# Enseña:
# 1. Uso de alcohol isopropílico para disolver compuesto térmico seco o degradado.
# 2. Fricción circular suave sobre el IHS sin desbordar el socket ni tocar pines.
# 3. Verificación de la superficie antes de montar nuevo disipador.
# =============================================================================

signal minigame_finished(success: bool)

@export var is_tutorial_mode: bool = false

@onready var modal_control: Control = $ModalControl
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var btn_tool_1: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool1
@onready var btn_tool_2: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool2
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel

@onready var cpu_ihs: Panel = $ModalControl/Panel/VBox/WorkArea/SocketBase/CPUIHS
@onready var paste_stain: ColorRect = $ModalControl/Panel/VBox/WorkArea/SocketBase/CPUIHS/PasteStain
@onready var clean_progress_bar: ProgressBar = $ModalControl/Panel/VBox/WorkArea/CleanProgress/ProgressBar
@onready var clean_progress_container: Control = $ModalControl/Panel/VBox/WorkArea/CleanProgress
@onready var warning_label: Label = $ModalControl/Panel/VBox/WarningLabel

var paste_cleaned_percent: float = 0.0
var is_completed: bool = false

func _ready() -> void:
	layer = 12
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	
	btn_tool_1.pressed.connect(func(): GameManager.select_tool(1))
	btn_tool_2.pressed.connect(func(): GameManager.select_tool(5))
	GameManager.tool_selected.connect(_on_tool_selected)
	
	# Automáticamente equipar paño con alcohol isopropílico (Tool 5)
	GameManager.select_tool(5)
	_update_tool_buttons()
	
	paste_stain.gui_input.connect(_on_paste_gui_input)
	clean_progress_bar.value = 0.0
	warning_label.text = ""
	_update_status()

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
	if is_completed:
		return
		
	if GameManager.equipped_tool != 5:
		if event is InputEventMouseButton and event.pressed:
			_show_warning("Selecciona el [2] Paño con Alcohol Isopropílico para disolver la pasta seca.", Color(1.0, 0.4, 0.4))
		return
		
	if (event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT)) or (event is InputEventMouseButton and event.pressed):
		paste_cleaned_percent += 4.0
		if paste_cleaned_percent > 100.0:
			paste_cleaned_percent = 100.0
			
		clean_progress_bar.value = paste_cleaned_percent
		var alpha = 1.0 - (paste_cleaned_percent / 100.0)
		paste_stain.modulate.a = alpha
		
		if paste_cleaned_percent >= 100.0:
			is_completed = true
			_show_warning("✓ ¡IHS limpio y reluciente! Alcohol isopropílico evaporado.", Color(0.2, 1.0, 0.4))
			status_label.text = "¡LIMPIEZA COMPLETADA! Superficie térmica lista para nuevo compuesto."
			status_label.modulate = Color(0.2, 1.0, 0.4)
			
			await get_tree().create_timer(1.2).timeout
			minigame_finished.emit(true)

func _show_warning(msg: String, col: Color) -> void:
	warning_label.text = msg
	warning_label.modulate = col
	var tw = create_tween()
	tw.tween_property(warning_label, "scale", Vector2(1.05, 1.05), 0.1)
	tw.tween_property(warning_label, "scale", Vector2(1.0, 1.0), 0.15)

func _update_status() -> void:
	status_label.text = "Haz clic o arrastra el ratón con [2] Paño Isopropílico sobre la pasta gris para limpiarla."
	status_label.modulate = Color(1.0, 0.85, 0.2)
