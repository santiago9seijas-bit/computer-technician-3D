extends CanvasLayer

# =============================================================================
# MINIJUEGO: REPARACIÓN DE PINES DOBLADOS (CPU / SOCKET)
# Enseña:
# 1. Inspección microscópica de la matriz de pines del procesador / socket.
# 2. Identificación de pines desviados por mala inserción o presión desigual.
# 3. Alineación micrométrica de cada pin hasta recuperar la verticalidad de 90°.
# =============================================================================

signal minigame_finished(success: bool)

@onready var modal_control: Control = $ModalControl
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var progress_label: Label = $ModalControl/Panel/VBox/Header/ProgressLabel
@onready var progress_bar: ProgressBar = $ModalControl/Panel/VBox/Header/ProgressBar
@onready var grid_container: GridContainer = $ModalControl/Panel/VBox/WorkArea/SocketFrame/Margin/PinGrid
@onready var warning_label: Label = $ModalControl/Panel/VBox/WarningLabel
@onready var victory_banner: PanelContainer = $ModalControl/Panel/VBox/VictoryBanner
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel

const GRID_ROWS: int = 8
const GRID_COLS: int = 10
const TOTAL_PINS: int = GRID_ROWS * GRID_COLS

# Posiciones fijas de los pines doblados (fila, columna, ángulo de desvío en grados)
var bent_pins_data: Array[Dictionary] = [
	{"row": 1, "col": 2, "angle": 42.0, "fixed": false},
	{"row": 2, "col": 7, "angle": -38.0, "fixed": false},
	{"row": 4, "col": 4, "angle": 45.0, "fixed": false},
	{"row": 5, "col": 1, "angle": -50.0, "fixed": false},
	{"row": 6, "col": 8, "angle": 35.0, "fixed": false},
	{"row": 3, "col": 6, "angle": -45.0, "fixed": false}
]

var total_bent_pins: int = 0
var fixed_pins_count: int = 0
var is_game_completed: bool = false

# Referencias a los botones de cada pin
var pin_nodes: Dictionary = {}

func _ready() -> void:
	layer = 12
	GameManager.select_tool(3)
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	victory_banner.visible = false
	warning_label.text = ""
	total_bent_pins = bent_pins_data.size()
	fixed_pins_count = 0
	
	_build_pin_matrix()
	_update_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		minigame_finished.emit(false)

func _build_pin_matrix() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	pin_nodes.clear()
	
	for r in range(GRID_ROWS):
		for c in range(GRID_COLS):
			var bent_info = _get_bent_info(r, c)
			var is_bent = (bent_info != null)
			
			var pin_btn = Button.new()
			pin_btn.custom_minimum_size = Vector2(48, 48)
			pin_btn.flat = true
			pin_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			
			# Contenedor visual del pin
			var pin_visual = Panel.new()
			pin_visual.name = "Visual"
			pin_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pin_visual.anchors_preset = Control.PRESET_FULL_RECT
			
			var sb = StyleBoxFlat.new()
			sb.set_corner_radius_all(24)
			sb.bg_color = Color(0.12, 0.14, 0.18, 0.95)
			sb.border_width_left = 2
			sb.border_width_top = 2
			sb.border_width_right = 2
			sb.border_width_bottom = 2
			
			# Pin gráfico central (aguja / punto dorado)
			var pin_core = ColorRect.new()
			pin_core.name = "PinCore"
			pin_core.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pin_core.custom_minimum_size = Vector2(8, 22)
			pin_core.pivot_offset = Vector2(4, 20)
			pin_core.position = Vector2(20, 13)
			
			if is_bent:
				sb.border_color = Color(1.0, 0.35, 0.1, 0.9)
				pin_core.color = Color(1.0, 0.4, 0.1, 1.0)
				pin_core.rotation_degrees = float(bent_info.get("angle", 0.0))
				pin_btn.tooltip_text = "⚠️ Pin doblado (%d°). ¡Haz clic para enderezarlo!" % int(bent_info.get("angle", 0.0))
			else:
				sb.border_color = Color(0.2, 0.7, 0.4, 0.4)
				pin_core.color = Color(0.9, 0.8, 0.3, 0.85)
				pin_core.rotation_degrees = 0.0
				pin_btn.tooltip_text = "Pin alineado a 90° ✓"
				
			pin_visual.add_theme_stylebox_override("panel", sb)
			pin_visual.add_child(pin_core)
			pin_btn.add_child(pin_visual)
			
			var pin_coord = Vector2i(r, c)
			pin_btn.pressed.connect(func(): _on_pin_clicked(pin_coord))
			
			grid_container.add_child(pin_btn)
			pin_nodes[pin_coord] = pin_btn

func _get_bent_info(r: int, c: int) -> Dictionary:
	for b in bent_pins_data:
		if b.get("row", -1) == r and b.get("col", -1) == c:
			return b
	return {}

func _on_pin_clicked(coord: Vector2i) -> void:
	if is_game_completed: return
	
	var bent_info: Dictionary = _get_bent_info(coord.x, coord.y)
	if bent_info.is_empty():
		_show_feedback("Este pin ya está perfectamente alineado a 90°.", Color(0.3, 0.8, 1.0))
		return
		
	if bent_info.get("fixed", false):
		_show_feedback("Este pin ya fue enderezado y testeado con éxito.", Color(0.2, 1.0, 0.5))
		return
		
	# Enderezar el pin
	bent_info["fixed"] = true
	fixed_pins_count += 1
	
	var pin_btn = pin_nodes[coord] as Button
	var visual = pin_btn.get_node("Visual") as Panel
	var pin_core = visual.get_node("PinCore") as ColorRect
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(pin_core, "rotation_degrees", 0.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(pin_core, "color", Color(0.2, 1.0, 0.5), 0.25)
	
	var sb = visual.get_theme_stylebox("panel") as StyleBoxFlat
	if sb:
		var new_sb = sb.duplicate() as StyleBoxFlat
		new_sb.border_color = Color(0.2, 1.0, 0.5, 0.9)
		visual.add_theme_stylebox_override("panel", new_sb)
		
	_show_feedback("✓ ¡Pin [%d, %d] enderezado con precisión micrométrica!" % [coord.x + 1, coord.y + 1], Color(0.2, 1.0, 0.5))
	_update_ui()
	
	if fixed_pins_count >= total_bent_pins:
		_trigger_victory()

func _update_ui() -> void:
	progress_label.text = "PINES REPARADOS: %d / %d" % [fixed_pins_count, total_bent_pins]
	progress_bar.max_value = total_bent_pins
	progress_bar.value = fixed_pins_count
	
	if fixed_pins_count < total_bent_pins:
		status_label.text = "Haz clic en los pines marcados en naranja/rojo con la pinza para enderezarlos."
		status_label.modulate = Color(1.0, 0.85, 0.2)
	else:
		status_label.text = "✓ ¡TODOS LOS PINES REPARADOS! Continuidad eléctrica y geometría restauradas al 100%."
		status_label.modulate = Color(0.2, 1.0, 0.5)

func _trigger_victory() -> void:
	is_game_completed = true
	victory_banner.visible = true
	victory_banner.scale = Vector2(0.6, 0.6)
	victory_banner.modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(victory_banner, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(victory_banner, "modulate:a", 1.0, 0.25)
	
	await get_tree().create_timer(2.2).timeout
	minigame_finished.emit(true)

func _show_feedback(msg: String, col: Color) -> void:
	warning_label.text = msg
	warning_label.modulate = col
	var tw = create_tween()
	tw.tween_property(warning_label, "scale", Vector2(1.05, 1.05), 0.08)
	tw.tween_property(warning_label, "scale", Vector2(1.0, 1.0), 0.12)
