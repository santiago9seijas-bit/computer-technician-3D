extends CanvasLayer

# =============================================================================
# MINIJUEGO: DESMONTAJE DE UNIDAD SSD M.2 (NVME)
# Enseña:
# 1. Retirar el disipador pasivo / armadura térmica M.2.
# 2. Desatornillar el micro-tornillo de retención sobre el standoff.
# 3. Reconocer la inclinación natural a 30° generada por los resortes del slot.
# 4. Extraer la unidad en diagonal sin hacer palanca vertical.
# =============================================================================

signal minigame_finished(success: bool)

enum State {
	REMOVE_HEATSINK,
	UNSCREW_STANDOFF,
	SPRING_TENSION_30DEG,
	EXTRACT_DIAGONAL,
	COMPLETED
}

var current_state: State = State.REMOVE_HEATSINK

var is_heatsink_removed: bool = false
var is_standoff_screw_removed: bool = false
var is_sprung_up: bool = false
var is_extracted: bool = false

var tex_screw_cruz = preload("res://pixel art/tornillo de cruz.png")

# Nodos
@onready var modal_control: Control = $ModalControl
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var btn_tool_1: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool1
@onready var btn_tool_2: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool2
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel

@onready var work_area: Control = $ModalControl/Panel/VBox/WorkArea
@onready var mobo_base: Panel = $ModalControl/Panel/VBox/WorkArea/MoboBase
@onready var m2_slot: Panel = $ModalControl/Panel/VBox/WorkArea/MoboBase/M2Slot
@onready var m2_drive: Panel = $ModalControl/Panel/VBox/WorkArea/MoboBase/M2Drive
@onready var heatsink_panel: Panel = $ModalControl/Panel/VBox/WorkArea/MoboBase/HeatsinkPanel

@onready var btn_screw_heatsink: Button = $ModalControl/Panel/VBox/WorkArea/MoboBase/HeatsinkPanel/BtnScrewHeatsink
@onready var icon_screw_heatsink: TextureRect = $ModalControl/Panel/VBox/WorkArea/MoboBase/HeatsinkPanel/BtnScrewHeatsink/Icon

@onready var btn_screw_standoff: Button = $ModalControl/Panel/VBox/WorkArea/MoboBase/BtnScrewStandoff
@onready var icon_screw_standoff: TextureRect = $ModalControl/Panel/VBox/WorkArea/MoboBase/BtnScrewStandoff/Icon
@onready var standoff_label: Label = $ModalControl/Panel/VBox/WorkArea/MoboBase/StandoffLabel

@onready var spring_indicator: Label = $ModalControl/Panel/VBox/WorkArea/MoboBase/SpringIndicator
@onready var btn_extract_m2: Button = $ModalControl/Panel/VBox/WorkArea/BtnExtractM2
@onready var warning_label: Label = $ModalControl/Panel/VBox/WorkArea/WarningLabel

func _ready() -> void:
	layer = 12
	_setup_ui()
	_update_tool_buttons()
	_update_status()

func _setup_ui() -> void:
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	
	btn_tool_1.pressed.connect(func(): GameManager.select_tool(1))
	btn_tool_2.pressed.connect(func(): GameManager.select_tool(2))
	GameManager.tool_selected.connect(_on_tool_selected)
	
	icon_screw_heatsink.texture = tex_screw_cruz
	icon_screw_standoff.texture = tex_screw_cruz
	
	btn_screw_heatsink.pressed.connect(_on_screw_heatsink_pressed)
	btn_screw_standoff.pressed.connect(_on_screw_standoff_pressed)
	btn_screw_standoff.visible = false
	standoff_label.visible = false
	
	btn_extract_m2.pressed.connect(_on_extract_m2_pressed)
	btn_extract_m2.visible = false
	spring_indicator.visible = false
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

func _on_screw_heatsink_pressed() -> void:
	if is_heatsink_removed:
		return
	
	if GameManager.equipped_tool != 1:
		_show_warning("Usa el Destornillador Cruz [1] para retirar el tornillo del disipador.", Color(1.0, 0.3, 0.3))
		return
	
	is_heatsink_removed = true
	var tw = create_tween().set_parallel(true)
	tw.tween_property(icon_screw_heatsink, "rotation_degrees", 720.0, 0.3)
	tw.tween_property(icon_screw_heatsink, "scale", Vector2(0.1, 0.1), 0.3)
	tw.tween_property(heatsink_panel, "position:y", heatsink_panel.position.y - 70.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(heatsink_panel, "modulate:a", 0.0, 0.5)
	
	btn_screw_heatsink.disabled = true
	await tw.finished
	heatsink_panel.visible = false
	
	btn_screw_standoff.visible = true
	standoff_label.visible = true
	current_state = State.UNSCREW_STANDOFF
	_show_warning("✓ Disipador térmico retirado. Pad térmico y SSD expuestos.", Color(0.2, 1.0, 0.4))
	_update_status()

func _on_screw_standoff_pressed() -> void:
	if current_state != State.UNSCREW_STANDOFF or is_standoff_screw_removed:
		return
	
	if GameManager.equipped_tool != 1:
		_show_warning("Usa el Destornillador Cruz fino [1] para el micro-tornillo de sujeción.", Color(1.0, 0.3, 0.3))
		return
	
	is_standoff_screw_removed = true
	var tw_screw = create_tween().set_parallel(true)
	tw_screw.tween_property(icon_screw_standoff, "rotation_degrees", 720.0, 0.3)
	tw_screw.tween_property(icon_screw_standoff, "scale", Vector2(0.1, 0.1), 0.3)
	tw_screw.tween_property(btn_screw_standoff, "modulate:a", 0.0, 0.3)
	btn_screw_standoff.disabled = true
	
	await tw_screw.finished
	btn_screw_standoff.visible = false
	standoff_label.text = "STANDOFF: LIBRE"
	standoff_label.modulate = Color(0.2, 1.0, 0.4)
	
	_trigger_spring_ejection()

func _trigger_spring_ejection() -> void:
	current_state = State.SPRING_TENSION_30DEG
	is_sprung_up = true
	
	# Efecto de elevación a 30 grados
	var tw = create_tween()
	tw.tween_property(m2_drive, "rotation_degrees", -18.0, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	spring_indicator.visible = true
	spring_indicator.text = "¡POP! Resorte M.2 elevado a 30° (Listo para deslizar en diagonal)"
	spring_indicator.modulate = Color(1.0, 0.85, 0.2)
	
	btn_extract_m2.visible = true
	btn_extract_m2.modulate = Color(1, 1, 1, 0)
	var tw_btn = create_tween()
	tw_btn.tween_property(btn_extract_m2, "modulate:a", 1.0, 0.3)
	
	_show_warning("✓ El resorte del slot elevó el SSD a 30° para evitar roces.", Color(0.2, 1.0, 0.4))
	current_state = State.EXTRACT_DIAGONAL
	_update_status()

func _on_extract_m2_pressed() -> void:
	if is_extracted:
		return
	
	if not is_sprung_up:
		_show_warning("¡ALERTA! El SSD no ha sido liberado del tornillo de anclaje.", Color(1.0, 0.2, 0.2))
		return
	
	is_extracted = true
	btn_extract_m2.disabled = true
	current_state = State.COMPLETED
	
	# Deslizamiento en diagonal fuera del slot M-Key
	var tw = create_tween().set_parallel(true)
	tw.tween_property(m2_drive, "position:x", m2_drive.position.x + 160.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(m2_drive, "position:y", m2_drive.position.y - 70.0, 0.5)
	tw.tween_property(m2_drive, "modulate:a", 0.3, 0.5)
	
	await tw.finished
	_show_warning("✓ ¡EXCELENTE! SSD M.2 desacoplado en diagonal sin torcer las pistas Key-M.", Color(0.2, 1.0, 0.4))
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
		State.REMOVE_HEATSINK:
			status_label.text = "PASO 1: Usa [1] Destornillador Cruz para retirar el tornillo del disipador M.2 Armor."
			status_label.modulate = Color(1.0, 0.85, 0.2)
		State.UNSCREW_STANDOFF:
			status_label.text = "PASO 2: Retira el micro-tornillo de sujeción ubicado en el standoff posterior."
			status_label.modulate = Color(1.0, 0.85, 0.2)
		State.SPRING_TENSION_30DEG:
			status_label.text = "PASO 3: Observa la elevación natural a 30° impulsada por el zócalo M.2."
			status_label.modulate = Color(1.0, 0.4, 0.8)
		State.EXTRACT_DIAGONAL:
			status_label.text = "PASO 4: Haz clic en 'DESLIZAR EN DIAGONAL' para retirar el módulo suavemente."
			status_label.modulate = Color(0.2, 1.0, 0.4)
		State.COMPLETED:
			status_label.text = "¡DESMONTAJE COMPLETADO! Almacenamiento NVMe retirado con éxito."
			status_label.modulate = Color(0.2, 1.0, 0.4)
