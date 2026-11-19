extends CanvasLayer

# =============================================================================
# MINIJUEGO: LIMPIEZA Y REAPLICACIÓN DE PASTA TÉRMICA EN PROCESADOR (CPU)
# - Base: Placa de procesador (placa de procesador.png)
# - Procesador: Abierto Intel / AMD según la máquina del cliente
# - Capa superior: Pasta térmica mancha (pasta termica mancha.png)
# - Fase 1 (Limpieza): Cursor pañuelo, cada clic encoge la mancha vieja hasta 0
# - Fase 2 (Aplicación): Cursor pasta térmica en uso, cada clic agranda la
#   nueva mancha de pasta térmica hasta completar al 100%.
# =============================================================================

signal minigame_finished(success: bool)

@export var is_tutorial_mode: bool = false
@export var cpu_brand: String = "" # "intel" o "amd"

enum Phase {
	CLEAN_OLD_PASTE,
	APPLY_NEW_PASTE,
	COMPLETED
}

var current_phase: Phase = Phase.CLEAN_OLD_PASTE

# Texturas
var tex_placa: Texture2D = preload("res://pixel art minijuegos/procesador/placa de procesador.png")
var tex_cpu_intel: Texture2D = preload("res://pixel art minijuegos/procesador/intel/abiertos/intel 5 abierto.png")
var tex_cpu_amd: Texture2D = preload("res://pixel art minijuegos/procesador/amd/abiertos/ amd ryzen 3 abierto.png")
var tex_paste_stain: Texture2D = preload("res://pixel art minijuegos/limpiezaprofunda/cpuprofunda/pasta termica mancha.png")
var tex_cursor_cloth: Texture2D = preload("res://pixel art minijuegos/limpiezaprofunda/cpuprofunda/pañuelo.png")
var tex_cursor_syringe: Texture2D = preload("res://pixel art minijuegos/limpiezaprofunda/cpuprofunda/pasta termica en uso.png")

# Nodos UI
@onready var modal_control: Control = $ModalControl
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var btn_tool_1: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool1
@onready var btn_tool_2: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool2
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel
@onready var warning_label: Label = $ModalControl/Panel/VBox/WarningLabel

# Barras de Progreso
@onready var clean_progress_bar: ProgressBar = $ModalControl/Panel/VBox/WorkArea/ProgressBars/CleanProgress/ProgressBar
@onready var apply_progress_container: Control = $ModalControl/Panel/VBox/WorkArea/ProgressBars/ApplyProgress
@onready var apply_progress_bar: ProgressBar = $ModalControl/Panel/VBox/WorkArea/ProgressBars/ApplyProgress/ProgressBar
@onready var apply_progress_label: Label = $ModalControl/Panel/VBox/WorkArea/ProgressBars/ApplyProgress/Lbl

# Socket y Sprites del CPU
@onready var socket_center: Control = $ModalControl/Panel/VBox/WorkArea/SocketCenter
@onready var placa_base: TextureRect = $ModalControl/Panel/VBox/WorkArea/SocketCenter/PlacaBase
@onready var cpu_sprite: TextureRect = $ModalControl/Panel/VBox/WorkArea/SocketCenter/CPUSprite
@onready var old_paste_stain: TextureRect = $ModalControl/Panel/VBox/WorkArea/SocketCenter/OldPasteStain
@onready var new_paste_stain: TextureRect = $ModalControl/Panel/VBox/WorkArea/SocketCenter/NewPasteStain
@onready var cpu_tag: Label = $ModalControl/Panel/VBox/WorkArea/SocketCenter/CPUTag
@onready var click_area: Control = $ModalControl/Panel/VBox/WorkArea/SocketCenter/ClickArea

# Cursor flotante personalizado
@onready var cursor_sprite: TextureRect = $ModalControl/CursorSprite

@onready var chk_clean: Label = $ModalControl/Panel/VBox/WorkArea/RightGuidePanel/Margin/VBoxGuide/ChecklistContainer/ChkClean
@onready var chk_apply: Label = $ModalControl/Panel/VBox/WorkArea/RightGuidePanel/Margin/VBoxGuide/ChecklistContainer/ChkApply

var active_tool: int = 1 # 1 = Pañuelo, 2 = Pasta
var clean_clicks: int = 0
const MAX_CLEAN_CLICKS: int = 5

var apply_clicks: int = 0
const MAX_APPLY_CLICKS: int = 5

var cursor_hotspot: Vector2 = Vector2(42, 40)
var is_busy_animating: bool = false
var is_intro_active: bool = false
var countdown_overlay: CanvasLayer = null
var dialog_box_inst: Control = null

func _get_game_manager() -> Node:
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/GameManager")

func _ready() -> void:
	layer = 12
	var gm = _get_game_manager()
	if gm and gm.has_method("select_tool"):
		gm.select_tool(5) # Limpiador
	
	# Determinar modelo Intel o AMD
	if cpu_brand == "":
		cpu_brand = "amd" if randf() < 0.5 else "intel"
	var brand_lower = cpu_brand.to_lower()
	
	if "amd" in brand_lower or "ryzen" in brand_lower:
		cpu_sprite.texture = tex_cpu_amd
		cpu_tag.text = "AMD RYZEN 3 // AM4 SOCKET"
		cpu_tag.modulate = Color(1.0, 0.45, 0.2, 0.95)
	else:
		cpu_sprite.texture = tex_cpu_intel
		cpu_tag.text = "INTEL CORE I5 // LGA 1700"
		cpu_tag.modulate = Color(0.2, 0.75, 1.0, 0.95)
		
	# Conexiones de botones
	btn_cancel.pressed.connect(func():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		minigame_finished.emit(false)
		if get_tree().current_scene == self:
			get_tree().change_scene_to_file("res://scenes/menus/LevelSelect.tscn")
		else:
			queue_free()
	)
	
	btn_tool_1.pressed.connect(func(): _select_tool(1))
	btn_tool_2.pressed.connect(func(): _select_tool(2))
	
	# Interactividad
	click_area.gui_input.connect(_on_click_area_gui_input)
	old_paste_stain.gui_input.connect(_on_click_area_gui_input)
	new_paste_stain.gui_input.connect(_on_click_area_gui_input)
	
	# Estado inicial de nodos
	clean_progress_bar.value = 0.0
	apply_progress_bar.value = 0.0
	warning_label.text = ""
	
	old_paste_stain.visible = true
	old_paste_stain.scale = Vector2(1.0, 1.0)
	old_paste_stain.modulate.a = 1.0
	
	new_paste_stain.visible = false
	new_paste_stain.scale = Vector2(0.12, 0.12)
	apply_progress_container.visible = false
	
	_select_tool(1)
	_update_cursor_visual()
	_update_status()
	
	if get_tree().current_scene == self:
		_start_joa_intro()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _start_joa_intro() -> void:
	is_intro_active = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if cursor_sprite:
		cursor_sprite.visible = false
		
	var dlg_scene = load("res://scenes/ui/DialogBox.tscn")
	if dlg_scene:
		dialog_box_inst = dlg_scene.instantiate()
		add_child(dialog_box_inst)
		if dialog_box_inst.has_method("show_message"):
			dialog_box_inst.show_message(
				"JOA",
				"¡Atención al procesador! La pasta térmica vieja se ha solidificado y perdió su conductividad térmica.\n\nPrimero selecciona el [1] Pañuelo y haz clic sobre el IHS para retirar toda la pasta seca. Luego selecciona la [2] Pasta Térmica y aplica una gota limpia hasta lograr 100% de cobertura.",
				func():
					_start_countdown()
			)
		else:
			_start_countdown()
	else:
		_start_countdown()

func _start_countdown() -> void:
	if countdown_overlay:
		countdown_overlay.queue_free()

	countdown_overlay = CanvasLayer.new()
	countdown_overlay.layer = 110
	add_child(countdown_overlay)

	var root_ctrl = Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	countdown_overlay.add_child(root_ctrl)

	var dim_rect = ColorRect.new()
	dim_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim_rect.color = Color(0.01, 0.03, 0.08, 0.55)
	dim_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(dim_rect)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(center)

	var label = Label.new()
	label.text = ""
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 120)
	label.pivot_offset = Vector2(160, 80)
	center.add_child(label)

	var steps: Array[Dictionary] = [
		{"text": "3", "color": Color(0.85, 0.25, 1.0), "size": 130},
		{"text": "2", "color": Color(1.0, 0.9, 0.2),  "size": 130},
		{"text": "1", "color": Color(1.0, 0.55, 0.1), "size": 130},
		{"text": "¡A LIMPIAR Y APLICAR!", "color": Color(0.2, 1.0, 0.5), "size": 85}
	]

	_run_countdown_step(0, steps, label, root_ctrl)

func _run_countdown_step(index: int, steps: Array[Dictionary], label: Label, root_ctrl: Control) -> void:
	if index >= steps.size():
		var fade_tw = create_tween()
		fade_tw.tween_property(root_ctrl, "modulate:a", 0.0, 0.3)
		fade_tw.chain().tween_callback(func():
			if countdown_overlay:
				countdown_overlay.queue_free()
				countdown_overlay = null
			is_intro_active = false
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
			if cursor_sprite:
				cursor_sprite.visible = true
		)
		return

	var st = steps[index]
	label.text = st["text"]
	label.modulate = st["color"]
	label.add_theme_font_size_override("font_size", st["size"])
	label.scale = Vector2(0.4, 0.4)
	label.modulate.a = 0.0

	var gm = _get_game_manager()
	if gm and gm.has_method("play_sfx"):
		gm.play_sfx("click")

	var tw = create_tween().set_parallel(true)
	tw.tween_property(label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 1.0, 0.15)
	tw.chain().tween_interval(0.4)
	tw.chain().tween_callback(func():
		_run_countdown_step(index + 1, steps, label, root_ctrl)
	)

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and cursor_sprite:
		cursor_sprite.global_position = event.global_position - cursor_hotspot

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		minigame_finished.emit(false)
		return
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_1:
			_select_tool(1)
		elif event.keycode == KEY_2 or event.keycode == KEY_5:
			_select_tool(2)

func _select_tool(tool_id: int) -> void:
	active_tool = tool_id
	if active_tool == 1:
		btn_tool_1.modulate = Color(1.3, 1.3, 0.4)
		btn_tool_2.modulate = Color(0.8, 0.8, 0.8)
	else:
		btn_tool_1.modulate = Color(0.8, 0.8, 0.8)
		btn_tool_2.modulate = Color(1.3, 1.3, 0.4)
	_update_cursor_visual()

func _update_cursor_visual() -> void:
	if not cursor_sprite:
		return
	if active_tool == 1:
		cursor_sprite.texture = tex_cursor_cloth
		cursor_sprite.size = Vector2(84, 80)
		cursor_sprite.pivot_offset = Vector2(42, 40)
		cursor_hotspot = Vector2(42, 40)
	else:
		cursor_sprite.texture = tex_cursor_syringe
		cursor_sprite.size = Vector2(138, 136)
		cursor_sprite.pivot_offset = Vector2(69, 68)
		cursor_hotspot = Vector2(69, 68)
	cursor_sprite.global_position = modal_control.get_global_mouse_position() - cursor_hotspot

# =============================================================================
# MANEJO DE CLICS EN EL ÁREA DEL PROCESADOR
# =============================================================================
func _on_click_area_gui_input(event: InputEvent) -> void:
	if is_busy_animating or is_intro_active or current_phase == Phase.COMPLETED:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if current_phase == Phase.CLEAN_OLD_PASTE:
			if active_tool != 1:
				_show_warning("Selecciona el [1] Pañuelo Limpiador para limpiar la pasta vieja.", Color(1.0, 0.4, 0.4))
				return
			_handle_clean_click()
		elif current_phase == Phase.APPLY_NEW_PASTE:
			if active_tool != 2:
				_show_warning("Selecciona la [2] Jeringa de Pasta para aplicar pasta nueva.", Color(1.0, 0.4, 0.4))
				return
			_handle_apply_click()

func _handle_clean_click() -> void:
	if clean_clicks >= MAX_CLEAN_CLICKS:
		return
		
	clean_clicks += 1
	var progress = float(clean_clicks) / float(MAX_CLEAN_CLICKS)
	clean_progress_bar.value = progress * 100.0
	
	var target_scale = lerp(1.0, 0.0, progress)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(old_paste_stain, "scale", Vector2(target_scale, target_scale), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(old_paste_stain, "modulate:a", max(0.0, 1.0 - progress * 0.4), 0.12)
	
	# Micro animación de frotado con el pañuelo
	var tw_wobble = create_tween()
	tw_wobble.tween_property(cursor_sprite, "rotation_degrees", -22.0, 0.06)
	tw_wobble.tween_property(cursor_sprite, "rotation_degrees", 18.0, 0.06)
	tw_wobble.tween_property(cursor_sprite, "rotation_degrees", 0.0, 0.06)
	
	_show_warning("¡Limpiando pasta vieja con pañuelo! [%d%%]" % int(progress * 100.0), Color(0.3, 0.9, 1.0))
	_update_checklist()
	
	if clean_clicks >= MAX_CLEAN_CLICKS:
		old_paste_stain.visible = false
		_complete_cleaning_phase()

func _complete_cleaning_phase() -> void:
	is_busy_animating = true
	current_phase = Phase.APPLY_NEW_PASTE
	_show_warning("✓ ¡IHS limpio y reluciente! Pasta térmica vieja removida al 100%.", Color(0.2, 1.0, 0.5))
	
	# Transición a Fase 2: Mostrar barra de aplicación
	apply_progress_container.visible = true
	apply_progress_container.modulate.a = 0.0
	var tw_prog = create_tween()
	tw_prog.tween_property(apply_progress_container, "modulate:a", 1.0, 0.3)
	
	# Cambiar automáticamente a la herramienta de pasta térmica
	_select_tool(2)
	
	# Nueva mancha empieza pequeña
	new_paste_stain.visible = true
	new_paste_stain.scale = Vector2(0.12, 0.12)
	new_paste_stain.modulate.a = 0.0
	var tw_stain = create_tween()
	tw_stain.tween_property(new_paste_stain, "modulate:a", 1.0, 0.25)
	
	_update_status()
	await get_tree().create_timer(0.35).timeout
	is_busy_animating = false

func _handle_apply_click() -> void:
	if apply_clicks >= MAX_APPLY_CLICKS:
		return
		
	apply_clicks += 1
	var progress = float(apply_clicks) / float(MAX_APPLY_CLICKS)
	apply_progress_bar.value = progress * 100.0
	apply_progress_label.text = "2. APLICACIÓN DE PASTA: %d%%" % int(progress * 100.0)
	
	var target_scale = lerp(0.18, 1.0, progress)
	var tw = create_tween()
	# Efecto elástico de gota colocándose y expandiéndose
	tw.tween_property(new_paste_stain, "scale", Vector2(target_scale * 1.15, target_scale * 0.88), 0.08)
	tw.tween_property(new_paste_stain, "scale", Vector2(target_scale, target_scale), 0.1)
	
	# Micro animación de inyección de pasta
	var tw_inj = create_tween()
	tw_inj.tween_property(cursor_sprite, "scale", Vector2(0.9, 0.9), 0.07)
	tw_inj.tween_property(cursor_sprite, "scale", Vector2(1.0, 1.0), 0.09)
	
	_show_warning("¡Aplicando pasta térmica! Gota expandiéndose... [%d%%]" % int(progress * 100.0), Color(0.1, 1.0, 0.7))
	_update_checklist()
	
	if apply_clicks >= MAX_APPLY_CLICKS:
		_complete_apply_phase()

func _complete_apply_phase() -> void:
	current_phase = Phase.COMPLETED
	is_busy_animating = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if cursor_sprite:
		cursor_sprite.visible = false
		
	_show_warning("✓ ¡Pasta térmica nueva aplicada al 100%! Cobertura perfecta.", Color(0.2, 1.0, 0.5))
	status_label.text = "¡PROCESO COMPLETADO! Procesador con pasta térmica renovada."
	status_label.modulate = Color(0.0, 1.0, 0.5)
	
	var tw_flash = create_tween()
	tw_flash.tween_property(new_paste_stain, "modulate", Color(1.3, 1.3, 1.3, 1.0), 0.2)
	tw_flash.tween_property(new_paste_stain, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)
	
	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		sm.mark_node_completed("reparacion", 28)
		sm.unlock_glossary("cpu")
		
	await get_tree().create_timer(1.2).timeout
	minigame_finished.emit(true)
	
	if get_tree().current_scene == self:
		CyberPlayTransition.play_exit(
			get_tree(),
			"reparacion",
			"res://scenes/menus/LevelSelect.tscn",
			"PASTA TÉRMICA RENOVADA",
			"// TRANSFERENCIA TÉRMICA OPTIMIZADA AL 100% //"
		)
	else:
		queue_free()

func _show_warning(msg: String, col: Color) -> void:
	var gm = _get_game_manager()
	if col.r > 0.7 and col.g < 0.5:
		if gm and gm.has_method("register_error"):
			gm.register_error(2.0)
	elif col.g > 0.6:
		if gm and gm.has_method("register_repair"):
			gm.register_repair(25, 2.0)
		
	warning_label.text = msg
	warning_label.modulate = col
	var tw = create_tween()
	tw.tween_property(warning_label, "scale", Vector2(1.05, 1.05), 0.1)
	tw.tween_property(warning_label, "scale", Vector2(1.0, 1.0), 0.15)

func _update_status() -> void:
	match current_phase:
		Phase.CLEAN_OLD_PASTE:
			status_label.text = "PASO 1 (LIMPIAR): Haz clic con el [1] Pañuelo sobre la pasta térmica vieja para removerla."
			status_label.modulate = Color(1.0, 0.85, 0.2)
		Phase.APPLY_NEW_PASTE:
			status_label.text = "PASO 2 (APLICAR): Haz clic con la [2] Pasta Térmica para aplicar la nueva capa sobre el CPU."
			status_label.modulate = Color(0.1, 0.95, 0.7)
		Phase.COMPLETED:
			status_label.text = "¡PROCESO COMPLETADO! CPU listo con pasta térmica nueva."
			status_label.modulate = Color(0.2, 1.0, 0.5)
			
	_update_checklist()

func _update_checklist() -> void:
	if not is_instance_valid(chk_clean) or not is_instance_valid(chk_apply):
		return
	var c_pct: int = int((float(clean_clicks) / float(MAX_CLEAN_CLICKS)) * 100.0)
	var a_pct: int = int((float(apply_clicks) / float(MAX_APPLY_CLICKS)) * 100.0)
	
	if current_phase == Phase.CLEAN_OLD_PASTE:
		if c_pct >= 100:
			chk_clean.text = "✓ 1. Limpieza de IHS con [1] (100%)"
			chk_clean.modulate = Color(0.2, 1.0, 0.5)
		else:
			chk_clean.text = "➔ 1. Limpieza de IHS con [1] (%d%%)" % c_pct
			chk_clean.modulate = Color(1.0, 0.85, 0.2)
		chk_apply.text = "○ 2. Aplicar Pasta con [2] (0%)"
		chk_apply.modulate = Color(0.7, 0.75, 0.85, 0.6)
	elif current_phase == Phase.APPLY_NEW_PASTE:
		chk_clean.text = "✓ 1. Limpieza de IHS con [1] (100%)"
		chk_clean.modulate = Color(0.2, 1.0, 0.5)
		if a_pct >= 100:
			chk_apply.text = "✓ 2. Aplicar Pasta con [2] (100%)"
			chk_apply.modulate = Color(0.2, 1.0, 0.5)
		else:
			chk_apply.text = "➔ 2. Aplicar Pasta con [2] (%d%%)" % a_pct
			chk_apply.modulate = Color(0.1, 1.0, 0.7)
	else:
		chk_clean.text = "✓ 1. Limpieza de IHS con [1] (100%)"
		chk_clean.modulate = Color(0.2, 1.0, 0.5)
		chk_apply.text = "✓ 2. Aplicar Pasta con [2] (100%)"
		chk_apply.modulate = Color(0.2, 1.0, 0.5)
