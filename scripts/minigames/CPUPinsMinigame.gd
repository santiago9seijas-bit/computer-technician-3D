extends CanvasLayer

# =============================================================================
# MINIJUEGO: REPARACIÓN DE PINES DOBLADOS (CPU / SOCKET)
# Enseña:
# 1. Inspección microscópica de la matriz de pines del procesador / socket.
# 2. Identificación de pines desviados por mala inserción o presión desigual.
# 3. Alineación micrométrica de cada pin hasta recuperar la verticalidad de 90°.
# =============================================================================

signal minigame_finished(success: bool)

const TEX_PIN: Texture2D = preload("res://pixel art minijuegos/limpiezaprofunda/pines/pines.png")
const TEX_FONDO: Texture2D = preload("res://pixel art minijuegos/limpiezaprofunda/pines/fondo gris.png")
const TEX_LENTE: Texture2D = preload("res://pixel art minijuegos/limpiezaprofunda/pines/lente.png")

@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var progress_label: Label = $ModalControl/Panel/VBox/Header/ProgressLabel
@onready var progress_bar: ProgressBar = $ModalControl/Panel/VBox/Header/ProgressBar
@onready var work_area: Control = $ModalControl/Panel/VBox/WorkArea
@onready var socket_frame: PanelContainer = $ModalControl/Panel/VBox/WorkArea/SocketFrame
@onready var grid_container: GridContainer = $ModalControl/Panel/VBox/WorkArea/SocketFrame/Margin/PinGrid
@onready var lente_overlay: TextureRect = $ModalControl/Panel/VBox/WorkArea/LenteOverlay
@onready var microscope_iris: ColorRect = $ModalControl/Panel/VBox/WorkArea/MicroscopeIris
@onready var warning_label: Label = $ModalControl/Panel/VBox/WarningLabel
@onready var victory_banner: PanelContainer = $ModalControl/Panel/VBox/VictoryBanner
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel

var lens_idle_tween: Tween = null

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
	_play_microscope_intro_animation.call_deferred()

func _play_microscope_intro_animation() -> void:
	if not is_instance_valid(socket_frame) or not is_instance_valid(lente_overlay):
		return
		
	if is_instance_valid(microscope_iris):
		microscope_iris.visible = true
		microscope_iris.modulate.a = 1.0
		
	socket_frame.pivot_offset = socket_frame.size * 0.5
	socket_frame.scale = Vector2(1.15, 1.15)
	socket_frame.modulate = Color(0.65, 0.85, 1.1, 0.3)
	
	lente_overlay.pivot_offset = Vector2(511.0, 316.0)
	lente_overlay.scale = Vector2(1.18, 1.18)
	lente_overlay.modulate = Color(1.2, 1.3, 1.5, 0.6)
	
	status_label.text = "🔬 AJUSTANDO ENFOQUE DE MICROSCOPIO (100x)..."
	status_label.modulate = Color(0.0, 0.9, 1.0, 1.0)
	
	var tw = create_tween()
	if is_instance_valid(microscope_iris):
		tw.parallel().tween_property(microscope_iris, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(socket_frame, "scale", Vector2(0.97, 0.97), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(lente_overlay, "scale", Vector2(0.98, 0.98), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(socket_frame, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.28)
	
	tw.chain().tween_property(socket_frame, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lente_overlay, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lente_overlay, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)
	
	tw.chain().tween_callback(func():
		if is_instance_valid(microscope_iris):
			microscope_iris.visible = false
		status_label.text = "✓ ¡ENFOQUE 100x CALIBRADO! Haz clic en los pines doblados para enderezarlos a 90°."
		status_label.modulate = Color(0.2, 1.0, 0.5, 1.0)
		_start_lens_idle_breathing()
	)

func _start_lens_idle_breathing() -> void:
	if not is_instance_valid(lente_overlay):
		return
	if is_instance_valid(lens_idle_tween):
		lens_idle_tween.kill()
	lens_idle_tween = create_tween().set_loops()
	lens_idle_tween.tween_property(lente_overlay, "scale", Vector2(1.008, 1.008), 2.0).set_trans(Tween.TRANS_SINE)
	lens_idle_tween.tween_property(lente_overlay, "scale", Vector2(0.995, 0.995), 2.0).set_trans(Tween.TRANS_SINE)

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
			var is_bent = (bent_info != null and not bent_info.is_empty())
			
			var pin_btn = Button.new()
			pin_btn.custom_minimum_size = Vector2(38, 30)
			pin_btn.flat = true
			pin_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			
			# Pin gráfico con sprite pines.png
			var pin_sprite = TextureRect.new()
			pin_sprite.name = "PinSprite"
			pin_sprite.texture = TEX_PIN
			pin_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			pin_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pin_sprite.custom_minimum_size = Vector2(22, 28)
			pin_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pin_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			pin_sprite.position = Vector2(8, 1)
			pin_sprite.pivot_offset = Vector2(11, 25) # Pivote en la base del pin
			
			if is_bent:
				pin_sprite.rotation_degrees = float(bent_info.get("angle", 0.0))
				pin_sprite.modulate = Color(1.3, 0.45, 0.15, 1.0)
				pin_btn.tooltip_text = "⚠️ Pin doblado (%d°). ¡Usa la pinza para enderezarlo a 90°!" % int(bent_info.get("angle", 0.0))
			else:
				pin_sprite.rotation_degrees = 0.0
				pin_sprite.modulate = Color(1.0, 1.0, 1.0, 0.95)
				pin_btn.tooltip_text = "Pin alineado a 90° ✓"
				
			pin_btn.add_child(pin_sprite)
			
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
	var pin_sprite = pin_btn.get_node_or_null("PinSprite") as TextureRect
	
	if pin_sprite:
		var tw = create_tween().set_parallel(true)
		tw.tween_property(pin_sprite, "rotation_degrees", 0.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(pin_sprite, "modulate", Color(0.2, 1.4, 0.6, 1.0), 0.18)
		tw.chain().tween_property(pin_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)
	
	# Micro reacción óptica en la lente del microscopio
	if is_instance_valid(lente_overlay):
		var lens_tw = create_tween()
		lens_tw.tween_property(lente_overlay, "scale", Vector2(1.015, 1.015), 0.08).set_trans(Tween.TRANS_SINE)
		lens_tw.tween_property(lente_overlay, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_SINE)
		
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
		status_label.text = "✓ ¡TODOS LOS PINES REPARADOS! Continuidad eléctrica y geometría restauradas al 100%%."
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
	if col.r > 0.7 and col.g < 0.5:
		GameManager.register_error(2.0)
	elif col.g > 0.6:
		GameManager.register_repair(25, 2.0)
		
	warning_label.text = msg
	warning_label.modulate = col
	var tw = create_tween()
	tw.tween_property(warning_label, "scale", Vector2(1.05, 1.05), 0.08)
	tw.tween_property(warning_label, "scale", Vector2(1.0, 1.0), 0.12)
