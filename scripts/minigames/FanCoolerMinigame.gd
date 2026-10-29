extends CanvasLayer

# =============================================================================
# MINIJUEGO: DESMONTAJE Y MANTENIMIENTO DEL FAN COOLER
# =============================================================================

signal minigame_finished(success: bool)

enum State {
	IN_PROGRESS,
	READY_TO_EXTRACT,
	EXTRACTING,
	COMPLETED
}

var current_state: State = State.IN_PROGRESS
var is_cable_disconnected: bool = false

# Herramienta requerida para cada tornillo (puede ser cruz o pala)
# Tornillos: 0: Top-Left, 1: Top-Right, 2: Bottom-Left, 3: Bottom-Right
var screw_types: Array[String] = ["cruz", "cruz", "pala", "cruz"]
var screws_removed: Array[bool] = [false, false, false, false]
var total_screws: int = 4

# Referencias a texturas
var tex_cooler_connected = preload("res://pixel art/fancooler conectado.png")
var tex_cooler_disconnected = preload("res://pixel art/fancooler.png")
var tex_screw_cruz = preload("res://pixel art/tornillo de cruz.png")
var tex_screw_pala = preload("res://pixel art/tornillo de pala.png")
var tex_cooler_frame = preload("res://pixel art/cuadro de fancoolerpng.png")

# Nodos de la escena
@onready var modal_control: Control = $ModalControl
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var btn_tool_1: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool1
@onready var btn_tool_2: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool2
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel

@onready var socket_frame: TextureRect = $ModalControl/Panel/VBox/ContentHBox/WorkArea/SocketFrame
@onready var cooler_sprite: TextureRect = $ModalControl/Panel/VBox/ContentHBox/WorkArea/CoolerSprite
@onready var cable_button: Button = $ModalControl/Panel/VBox/ContentHBox/WorkArea/CableArea/BtnCable
@onready var cable_hint: Label = $ModalControl/Panel/VBox/ContentHBox/WorkArea/CableArea/CableHint
@onready var screws_container: Control = $ModalControl/Panel/VBox/ContentHBox/WorkArea/ScrewsContainer
@onready var cooler_extract_btn: Button = $ModalControl/Panel/VBox/ContentHBox/WorkArea/BtnExtractCooler

# Lista de botones de tornillos
var screw_buttons: Array[Button] = []
var screw_icons: Array[TextureRect] = []

func _ready() -> void:
	layer = 12
	_setup_screw_types()
	_setup_ui()
	_update_tool_buttons()
	_update_status()

func _setup_screw_types() -> void:
	# Generar una distribución variada de tornillos Cruz y Pala
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in range(4):
		screw_types[i] = "cruz" if rng.randf() > 0.45 else "pala"
		screws_removed[i] = false

func _setup_ui() -> void:
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	
	# Herramientas
	btn_tool_1.pressed.connect(func(): GameManager.select_tool(1))
	btn_tool_2.pressed.connect(func(): GameManager.select_tool(2))
	GameManager.tool_selected.connect(_on_tool_selected)
	
	# Desconexión del cable
	cable_button.pressed.connect(_on_cable_disconnected)
	
	# Botón para extraer el fan cooler cuando esté libre
	cooler_extract_btn.pressed.connect(_on_extract_cooler_pressed)
	cooler_extract_btn.visible = false
	
	# Texturas base
	cooler_sprite.texture = tex_cooler_connected
	socket_frame.texture = tex_cooler_frame
	
	# Configurar los 4 tornillos sobre el sprite del fan cooler
	screw_buttons.clear()
	screw_icons.clear()
	for i in range(4):
		var btn = screws_container.get_node_or_null("Screw" + str(i + 1))
		if btn:
			var icon = btn.get_node_or_null("Icon") as TextureRect
			if icon:
				icon.texture = tex_screw_cruz if screw_types[i] == "cruz" else tex_screw_pala
				screw_icons.append(icon)
			btn.pressed.connect(_on_screw_clicked.bind(i))
			screw_buttons.append(btn)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_1:
			GameManager.select_tool(1)
		elif event.keycode == KEY_2:
			GameManager.select_tool(2)
		elif event.keycode == KEY_ESCAPE:
			minigame_finished.emit(false)

func _on_tool_selected(tool_id: int) -> void:
	_update_tool_buttons()

func _update_tool_buttons() -> void:
	var t = GameManager.equipped_tool
	btn_tool_1.modulate = Color(1.2, 1.2, 1.2, 1.0) if t == 1 else Color(0.65, 0.65, 0.7, 0.8)
	btn_tool_2.modulate = Color(1.2, 1.2, 1.2, 1.0) if t == 2 else Color(0.65, 0.65, 0.7, 0.8)

func _on_cable_disconnected() -> void:
	if is_cable_disconnected:
		return
		
	is_cable_disconnected = true
	
	# Animación de desconexión del cable
	var tw = create_tween()
	tw.tween_property(cable_hint, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func():
		cable_button.visible = false
		cable_hint.visible = false
		cooler_sprite.texture = tex_cooler_disconnected
		_check_readiness()
	)
	
	_show_floating_feedback("¡CABLE DESCONECTADO!", Color(0.0, 1.0, 0.85))

func _on_screw_clicked(index: int) -> void:
	if screws_removed[index]:
		return
		
	var required_tool = 1 if screw_types[index] == "cruz" else 2
	var required_name = "Destornillador Cruz" if required_tool == 1 else "Destornillador Pala"
	
	if GameManager.equipped_tool != required_tool:
		_show_floating_feedback("HERRAMIENTA INCORRECTA: USA " + required_name.to_upper(), Color(1.0, 0.85, 0.1))
		_shake_node(screw_buttons[index])
		return
		
	# Desatornillar exitoso con animación rotativa y desvanecimiento
	screws_removed[index] = true
	var icon = screw_icons[index]
	var btn = screw_buttons[index]
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(icon, "rotation", deg_to_rad(360.0), 0.35).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(icon, "scale", Vector2(1.4, 1.4), 0.2)
	tw.chain().tween_property(icon, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func():
		btn.visible = false
		_check_readiness()
	)
	
	_show_floating_feedback("✓ TORNILLO RETIRADO", Color(0.2, 1.0, 0.5))

func _check_readiness() -> void:
	var remaining_screws = 0
	for r in screws_removed:
		if not r:
			remaining_screws += 1
			
	if remaining_screws == 0 and is_cable_disconnected:
		current_state = State.READY_TO_EXTRACT
		cooler_extract_btn.visible = true
		_show_floating_feedback("¡FAN COOLER LIBRE! HAZ CLIC PARA EXTRAER", Color(1.0, 0.8, 0.2))
	else:
		cooler_extract_btn.visible = false
		
	_update_status()

func _on_extract_cooler_pressed() -> void:
	if current_state != State.READY_TO_EXTRACT:
		return
		
	current_state = State.EXTRACTING
	cooler_extract_btn.visible = false
	
	# Animación de extracción hacia arriba
	var tw = create_tween().set_parallel(true)
	tw.tween_property(cooler_sprite, "position:y", cooler_sprite.position.y - 70.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(cooler_sprite, "modulate:a", 0.0, 0.45).set_delay(0.2)
	
	tw.chain().tween_callback(func():
		current_state = State.COMPLETED
		_show_victory_panel()
	)

func _show_victory_panel() -> void:
	status_label.text = "¡FAN COOLER DESMONTADO CON ÉXITO!"
	status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5, 1.0))
	
	var victory_modal = $ModalControl/VictoryPanel
	if victory_modal:
		victory_modal.visible = true
		var btn_done = victory_modal.get_node_or_null("VBox/BtnContinuar")
		if btn_done:
			btn_done.pressed.connect(func(): minigame_finished.emit(true))

func _update_status() -> void:
	if current_state == State.READY_TO_EXTRACT:
		status_label.text = "¡COMPONENTE LIBRE! Haz clic en el Fan Cooler para retirarlo."
		status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.6, 1.0))
		return
		
	var rem = 0
	for r in screws_removed:
		if not r: rem += 1
		
	if not is_cable_disconnected and rem == 0:
		status_label.text = "¡Tornillos retirados! Desconecta el cable de alimentación para liberar."
		status_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	elif is_cable_disconnected and rem > 0:
		status_label.text = "Cable desconectado. Retira los tornillos restantes (%d/4) con Cruz [1] o Pala [2]." % rem
		status_label.add_theme_color_override("font_color", Color(0.9, 0.5, 1.0, 1.0))
	else:
		status_label.text = "Desconecta el cable y retira los 4 tornillos (cualquier orden). Faltan: %d tornillos." % rem
		status_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))

func _shake_node(n: CanvasItem) -> void:
	if not n: return
	var orig_x = n.position.x
	var tw = create_tween()
	tw.tween_property(n, "position:x", orig_x - 6.0, 0.04)
	tw.tween_property(n, "position:x", orig_x + 6.0, 0.04)
	tw.tween_property(n, "position:x", orig_x - 3.0, 0.04)
	tw.tween_property(n, "position:x", orig_x, 0.04)

func _show_floating_feedback(msg: String, color: Color) -> void:
	var lbl = Label.new()
	lbl.text = msg
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("shadow_outline_size", 6)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var vp_size = modal_control.size if modal_control else Vector2(1152, 648)
	lbl.position = Vector2(vp_size.x * 0.5 - 150.0, vp_size.y * 0.5 - 160.0)
	lbl.size = Vector2(300, 30)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if modal_control:
		modal_control.add_child(lbl)
	else:
		add_child(lbl)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 30.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.8).set_delay(0.2)
	tw.chain().tween_callback(lbl.queue_free)
