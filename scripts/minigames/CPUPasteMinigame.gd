extends CanvasLayer

# =============================================================================
# MINIJUEGO: LIMPIEZA Y REAPLICACIÓN DE PASTA TÉRMICA EN IHS (CPU)
# Enseña:
# FASE 1:
# 1. Uso de alcohol isopropílico para disolver la pasta térmica seca o degradada.
# 2. Fricción circular suave sobre el IHS sin desbordar el socket.
# FASE 2:
# 1. Arrastre del dispensador térmico (cubo gris interactivo) hacia el IHS.
# 2. Dosificación y llenado continuo de 0% a 100% mientras se desplaza sobre el CPU.
# =============================================================================

signal minigame_finished(success: bool)

@export var is_tutorial_mode: bool = false

enum Phase {
	CLEAN_OLD_PASTE,
	APPLY_NEW_PASTE,
	COMPLETED
}

var current_phase: Phase = Phase.CLEAN_OLD_PASTE

# Nodos UI
@onready var modal_control: Control = $ModalControl
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var btn_tool_1: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool1
@onready var btn_tool_2: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool2
@onready var btn_tool_3: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool3
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel
@onready var warning_label: Label = $ModalControl/Panel/VBox/WarningLabel

# Barras de Progreso
@onready var clean_progress_container: Control = $ModalControl/Panel/VBox/WorkArea/ProgressBars/CleanProgress
@onready var clean_progress_bar: ProgressBar = $ModalControl/Panel/VBox/WorkArea/ProgressBars/CleanProgress/ProgressBar
@onready var apply_progress_container: Control = $ModalControl/Panel/VBox/WorkArea/ProgressBars/ApplyProgress
@onready var apply_progress_bar: ProgressBar = $ModalControl/Panel/VBox/WorkArea/ProgressBars/ApplyProgress/ProgressBar
@onready var apply_progress_label: Label = $ModalControl/Panel/VBox/WorkArea/ProgressBars/ApplyProgress/Lbl

# Socket y CPU
@onready var socket_base: Panel = $ModalControl/Panel/VBox/WorkArea/SocketBase
@onready var cpu_ihs: Panel = $ModalControl/Panel/VBox/WorkArea/SocketBase/CPUIHS
@onready var paste_stain: ColorRect = $ModalControl/Panel/VBox/WorkArea/SocketBase/CPUIHS/PasteStain
@onready var apply_target: Panel = $ModalControl/Panel/VBox/WorkArea/SocketBase/CPUIHS/ApplyTarget
@onready var new_paste_dot: Panel = $ModalControl/Panel/VBox/WorkArea/SocketBase/CPUIHS/NewPasteDot

# Cubo Gris Dispensador (Estilo refrigeración líquida)
@onready var dispenser_cube: Panel = $ModalControl/Panel/VBox/WorkArea/DispenserCube

var paste_cleaned_percent: float = 0.0
var apply_paste_percent: float = 0.0
var active_tool: int = 5

# Arrastre del cubo gris
var is_dragging_cube: bool = false
var cube_drag_offset: Vector2 = Vector2.ZERO
var dispenser_start_pos: Vector2 = Vector2.ZERO
var is_cube_over_ihs: bool = false
var last_ihs_motion_pos: Vector2 = Vector2.ZERO
var has_last_ihs_pos: bool = false

func _ready() -> void:
	layer = 12
	GameManager.select_tool(5)
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	
	btn_tool_1.pressed.connect(func(): _select_tool(1))
	btn_tool_2.pressed.connect(func(): _select_tool(5))
	btn_tool_3.pressed.connect(func(): _select_tool(6))
	
	# Automáticamente equipar el paño con alcohol isopropílico al iniciar
	_select_tool(5)
	
	paste_stain.gui_input.connect(_on_paste_gui_input)
	dispenser_cube.gui_input.connect(_on_cube_gui_input)
	dispenser_cube.z_index = 10
	dispenser_start_pos = dispenser_cube.position
	
	clean_progress_bar.value = 0.0
	apply_progress_bar.value = 0.0
	warning_label.text = ""
	
	apply_target.visible = false
	new_paste_dot.visible = false
	apply_progress_container.visible = false
	dispenser_cube.visible = false
	
	_update_status()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_1:
			_select_tool(1)
		elif event.keycode == KEY_2 or event.keycode == KEY_5:
			_select_tool(5)
		elif event.keycode == KEY_3:
			_select_tool(6)
		elif event.keycode == KEY_ESCAPE:
			minigame_finished.emit(false)

func _select_tool(tool_id: int) -> void:
	active_tool = tool_id
	btn_tool_1.modulate = Color(1.3, 1.3, 0.4) if active_tool == 1 else Color(0.8, 0.8, 0.8)
	btn_tool_2.modulate = Color(1.3, 1.3, 0.4) if active_tool == 5 else Color(0.8, 0.8, 0.8)
	btn_tool_3.modulate = Color(1.3, 1.3, 0.4) if active_tool == 6 else Color(0.8, 0.8, 0.8)

# =============================================================================
# FASE 1: LIMPIEZA DE LA PASTA VIEJA (FROTE CON ISOPROPÍLICO)
# =============================================================================
func _on_paste_gui_input(event: InputEvent) -> void:
	if current_phase != Phase.CLEAN_OLD_PASTE:
		return
		
	if active_tool != 5:
		if event is InputEventMouseButton and event.pressed:
			_show_warning("Selecciona el [2] Paño con Alcohol Isopropílico para disolver la pasta seca.", Color(1.0, 0.4, 0.4))
		return
		
	if (event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT)) or (event is InputEventMouseButton and event.pressed):
		paste_cleaned_percent += 3.8
		if paste_cleaned_percent > 100.0:
			paste_cleaned_percent = 100.0
			
		clean_progress_bar.value = paste_cleaned_percent
		var alpha = 1.0 - (paste_cleaned_percent / 100.0)
		paste_stain.modulate.a = alpha
		
		if paste_cleaned_percent >= 100.0:
			_complete_cleaning_phase()

func _complete_cleaning_phase() -> void:
	paste_stain.visible = false
	current_phase = Phase.APPLY_NEW_PASTE
	
	_select_tool(6)
	_show_warning("✓ ¡IHS limpio y reluciente! Alcohol evaporado.", Color(0.2, 1.0, 0.5))
	
	# Transición a Fase 2: Mostrar barra de aplicación y Cubo Gris Dispensador
	apply_progress_container.visible = true
	apply_progress_container.modulate.a = 0.0
	var tw_prog = create_tween()
	tw_prog.tween_property(apply_progress_container, "modulate:a", 1.0, 0.3)
	
	apply_target.visible = true
	apply_target.modulate.a = 0.0
	var tw_tgt = create_tween()
	tw_tgt.tween_property(apply_target, "modulate:a", 0.9, 0.3)
	
	var tw_pulse = create_tween().set_loops()
	tw_pulse.tween_property(apply_target, "modulate", Color(1.4, 1.3, 0.4, 1.0), 0.3)
	tw_pulse.tween_property(apply_target, "modulate", Color(0.1, 0.9, 1.0, 0.8), 0.3)
	
	dispenser_cube.visible = true
	dispenser_cube.modulate.a = 0.0
	dispenser_cube.position = dispenser_start_pos
	dispenser_cube.move_to_front()
	var tw_cube = create_tween().set_parallel(true)
	tw_cube.tween_property(dispenser_cube, "modulate:a", 1.0, 0.35)
	tw_cube.tween_property(dispenser_cube, "scale", Vector2(1.0, 1.0), 0.35)
	
	_update_status()

# =============================================================================
# FASE 2: ARRASTRE DEL CUBO GRIS Y LLENADO DE PASTA (VARIAS PASADAS DE 0 A 100%)
# =============================================================================
func _on_cube_gui_input(event: InputEvent) -> void:
	if current_phase != Phase.APPLY_NEW_PASTE:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging_cube = true
			has_last_ihs_pos = false
			dispenser_cube.move_to_front()
			cube_drag_offset = dispenser_cube.get_global_mouse_position() - dispenser_cube.global_position
		else:
			is_dragging_cube = false
			_check_cube_drop()

func _input(event: InputEvent) -> void:
	if is_dragging_cube:
		if event is InputEventMouseMotion:
			dispenser_cube.global_position = dispenser_cube.get_global_mouse_position() - cube_drag_offset
			_check_cube_hover_ihs()
		elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging_cube = false
			_check_cube_drop()

func _check_cube_hover_ihs() -> void:
	var cube_rect = dispenser_cube.get_global_rect()
	var ihs_rect = cpu_ihs.get_global_rect().grow(15.0)
	
	if cube_rect.intersects(ihs_rect):
		if not is_cube_over_ihs:
			is_cube_over_ihs = true
			has_last_ihs_pos = false
			var tw_tilt = create_tween()
			tw_tilt.tween_property(dispenser_cube, "rotation_degrees", -20.0, 0.15)
			
		var current_cube_center = dispenser_cube.global_position + (dispenser_cube.size * 0.5)
		if not has_last_ihs_pos:
			last_ihs_motion_pos = current_cube_center
			has_last_ihs_pos = true
		else:
			var delta_dist = current_cube_center.distance_to(last_ihs_motion_pos)
			# Requiere movimiento real sobre la superficie (evita sumar por solo temblar en el mismo punto)
			if delta_dist >= 6.0:
				last_ihs_motion_pos = current_cube_center
				var clamped_dist = min(delta_dist, 30.0)
				# ~650px de recorrido total en el procesador (requiere pasar varias veces, ~5 pasadas completas)
				var progress_gain = (clamped_dist / 650.0) * 100.0
				apply_paste_percent += progress_gain
				if apply_paste_percent > 100.0:
					apply_paste_percent = 100.0
					
				_update_apply_progress_visual()
				
				if apply_paste_percent >= 100.0:
					_complete_apply_phase()
	else:
		has_last_ihs_pos = false
		if is_cube_over_ihs:
			is_cube_over_ihs = false
			var tw_straight = create_tween()
			tw_straight.tween_property(dispenser_cube, "rotation_degrees", 0.0, 0.15)

func _check_cube_drop() -> void:
	has_last_ihs_pos = false
	is_cube_over_ihs = false
	if apply_paste_percent < 100.0:
		var tw = create_tween().set_parallel(true)
		tw.tween_property(dispenser_cube, "position", dispenser_start_pos, 0.25).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(dispenser_cube, "rotation_degrees", 0.0, 0.15)
		if apply_paste_percent > 0.0:
			_show_warning("¡Sigue pasando la pasta! Llevas %d%% aplicado (requiere varias pasadas)." % int(apply_paste_percent), Color(0.9, 0.85, 0.3))

func _update_apply_progress_visual() -> void:
	apply_progress_bar.value = apply_paste_percent
	var pass_count = clamp(int(apply_paste_percent / 20.0) + 1, 1, 5)
	if apply_paste_percent >= 100.0:
		apply_progress_label.text = "2. APLICACIÓN DE PASTA: 100% [COMPLETO]"
	else:
		apply_progress_label.text = "2. APLICACIÓN DE PASTA: %d%% (Pasada %d/5)" % [int(apply_paste_percent), pass_count]
	
	new_paste_dot.visible = true
	var s = clamp(apply_paste_percent / 100.0, 0.15, 1.0)
	new_paste_dot.scale = Vector2(s, s)
	new_paste_dot.modulate.a = clamp(apply_paste_percent / 35.0, 0.25, 1.0)
	_update_status()

func _complete_apply_phase() -> void:
	current_phase = Phase.COMPLETED
	is_dragging_cube = false
	apply_target.visible = false
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(dispenser_cube, "modulate:a", 0.0, 0.35)
	tw.tween_property(dispenser_cube, "scale", Vector2(0.5, 0.5), 0.35)
	
	_show_warning("✓ ¡Pasta térmica aplicada al 100%! Cobertura uniforme tras varias pasadas.", Color(0.2, 1.0, 0.5))
	status_label.text = "¡PASTA TÉRMICA RENOVADA AL 100%! Procesador listo para el disipador."
	status_label.modulate = Color(0.0, 1.0, 0.5)
	
	await get_tree().create_timer(1.3).timeout
	minigame_finished.emit(true)

func _show_warning(msg: String, col: Color) -> void:
	warning_label.text = msg
	warning_label.modulate = col
	var tw = create_tween()
	tw.tween_property(warning_label, "scale", Vector2(1.05, 1.05), 0.1)
	tw.tween_property(warning_label, "scale", Vector2(1.0, 1.0), 0.15)

func _update_status() -> void:
	match current_phase:
		Phase.CLEAN_OLD_PASTE:
			status_label.text = "PASO 1 (LIMPIAR): Frota el [2] Paño Isopropílico sobre la pasta seca para disolverla."
			status_label.modulate = Color(1.0, 0.85, 0.2)
		Phase.APPLY_NEW_PASTE:
			var pass_count = clamp(int(apply_paste_percent / 20.0) + 1, 1, 5)
			status_label.text = "PASO 2 (APLICAR): Arrastra y pasa la pasta térmica varias veces sobre el CPU (%d%% - Pasada %d/5)." % [int(apply_paste_percent), pass_count]
			status_label.modulate = Color(0.1, 0.95, 0.7)
		Phase.COMPLETED:
			status_label.text = "¡PROCESO COMPLETADO! CPU listo con pasta térmica nueva."
			status_label.modulate = Color(0.2, 1.0, 0.5)
