extends CanvasLayer

# =============================================================================
# MINIJUEGO: DESMONTAJE Y MONTAJE DE TARJETA GRÁFICA (GPU)
# Modelos:
# 1. Gráfica Monocooler (1 cooler con soporte superpuesto)
# 2. Gráfica de 2 Coolers (Dual Cooler con soporte superpuesto)
#
# Reglas de Jugabilidad:
# 1. Al desconectar la alimentación PCIe, los ventiladores frenan de a poco
#    y cambia a la textura de gráfica desconectada (monocooler o 2 coolers).
# 2. Los 2 tornillos van en el soporte metálico cerca del cable/puerto HDMI.
# 3. Al extraer la gráfica, el soporte SE QUEDA EN SU LUGAR (solo sube la GPU).
# 4. Detección automática de fase PONER o QUITAR con explicaciones específicas.
# =============================================================================

signal minigame_finished(success: bool)
signal old_part_extracted()

enum State {
	DISCONNECT_POWER,   # 1. Desconectar cable PCIe (ventiladores frenan de a poco)
	UNSCREW_SOPORTE,    # 2. Quitar los 2 tornillos del bracket HDMI
	EXTRACT_DRAG_UP,    # 3. Arrastrar la GPU hacia arriba (soporte se queda)
	EMPTY_SLOT,         # Slot vacío esperando repuesto
	INSERT_DRAG_DOWN,   # 1. Arrastrar GPU nueva hacia abajo bajo el soporte
	SCREW_NEW_SOPORTE,  # 2. Atornillar los 2 tornillos en el bracket HDMI
	CONNECT_NEW_POWER,  # 3. Conectar cable PCIe (ventiladores aceleran)
	COMPLETED
}

enum GPUType {
	MONO_COOLER,
	DUAL_COOLER
}

var current_state: State = State.DISCONNECT_POWER
var current_gpu_type: GPUType = GPUType.MONO_COOLER
var gpu_type_configured: bool = false
var start_as_empty_slot: bool = false
var is_tutorial_mode: bool = false

func set_gpu_type_by_name(t_name: String) -> void:
	if is_tutorial_mode:
		current_gpu_type = GPUType.MONO_COOLER
		gpu_type_configured = true
		if is_inside_tree() and is_instance_valid(work_area):
			_apply_gpu_model_layout()
		return
		
	gpu_type_configured = true
	var tn = t_name.to_lower().strip_edges()
	if tn == "monocooler" or tn == "mono_cooler" or tn == "mono":
		current_gpu_type = GPUType.MONO_COOLER
	elif tn == "dual_cooler" or tn == "dual" or tn == "2 coolers" or tn == "dos coolers":
		current_gpu_type = GPUType.DUAL_COOLER
	else:
		current_gpu_type = GPUType.MONO_COOLER
	if is_inside_tree() and is_instance_valid(work_area):
		_apply_gpu_model_layout()
@export var target_gpu_count: int = 1
@export var initial_installed_count: int = 0
var current_gpu_index: int = 0

func get_installed_count() -> int:
	return current_gpu_index

# Estado de tornillos (2 tornillos en el bracket HDMI)
var screw_types: Array[String] = ["cruz", "cruz"]
var screws_removed: Array[bool] = [false, false]

var is_power_disconnected: bool = false
var is_extracted: bool = false

# Dragging
var is_dragging_gpu: bool = false
var drag_start_y: float = 0.0

# Animación de giro y frenado progresivo
const SPIN_MAX_FPS: float = 14.0
const DECELERATION_RATE: float = 35.0
var is_spinning: bool = true
var is_decelerating: bool = false
var is_accelerating: bool = false
var current_spin_fps: float = 14.0
var anim_frame_idx: int = 0
var anim_frame_timer: float = 0.0

# Texturas Monocooler (285 x 203)
var mono_anim_frames: Array[Texture2D] = [
	preload("res://pixel art minijuegos/grafica/grafica de un cooler/monocooler grafica/fotograma0000.png"),
	preload("res://pixel art minijuegos/grafica/grafica de un cooler/monocooler grafica/fotograma0001.png"),
	preload("res://pixel art minijuegos/grafica/grafica de un cooler/monocooler grafica/fotograma0002.png"),
	preload("res://pixel art minijuegos/grafica/grafica de un cooler/monocooler grafica/fotograma0003.png")
]
var tex_mono_soporte: Texture2D = preload("res://pixel art minijuegos/grafica/grafica de un cooler/soporte de grafica monocooler .png")
var tex_mono_desconectada: Texture2D = preload("res://pixel art minijuegos/grafica/grafica de un cooler/desconectada grafica monocooler .png")

# Texturas Dual Cooler (500 x 231)
var dual_anim_frames: Array[Texture2D] = [
	preload("res://pixel art minijuegos/grafica/grafica de dos coolers/grafica dos coolers/fotograma0000.png"),
	preload("res://pixel art minijuegos/grafica/grafica de dos coolers/grafica dos coolers/fotograma0001.png"),
	preload("res://pixel art minijuegos/grafica/grafica de dos coolers/grafica dos coolers/fotograma0002.png"),
	preload("res://pixel art minijuegos/grafica/grafica de dos coolers/grafica dos coolers/fotograma0003.png")
]
var tex_dual_soporte: Texture2D = preload("res://pixel art minijuegos/grafica/grafica de dos coolers/soporte de grafica de dos cooler.png")
var tex_dual_desconectada: Texture2D = preload("res://pixel art minijuegos/grafica/grafica de dos coolers/grafica desconectada.png")

var tex_screw_cruz: Texture2D = preload("res://pixel art minijuegos/tornillos/tornillo de cruz.png")
var tex_screw_pala: Texture2D = preload("res://pixel art minijuegos/tornillos/tornillo de pala.png")

# Nodos
@onready var modal_control: Control = $ModalControl
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var btn_tool_1: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool1
@onready var btn_tool_2: Button = $ModalControl/Panel/VBox/Header/ToolBar/BtnTool2
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel

@onready var work_area: Control = $ModalControl/Panel/VBox/WorkArea
@onready var pcie_slot: Panel = $ModalControl/Panel/VBox/WorkArea/PCIeSlot

# El soporte es ESTACIONARIO en el chasis (se queda en el sitio)
@onready var soporte_gpu_sprite: TextureRect = $ModalControl/Panel/VBox/WorkArea/SoporteGPUSprite

# El contenedor de la GPU es el que se extrae y se mueve hacia arriba
@onready var gpu_container: Control = $ModalControl/Panel/VBox/WorkArea/GPUContainer
@onready var base_gpu_sprite: TextureRect = $ModalControl/Panel/VBox/WorkArea/GPUContainer/BaseGPUSprite
@onready var btn_cable_power: Button = $ModalControl/Panel/VBox/WorkArea/GPUContainer/BtnCablePower
@onready var cable_highlight: Panel = $ModalControl/Panel/VBox/WorkArea/GPUContainer/BtnCablePower/CableHighlight
@onready var cable_hint_label: Label = $ModalControl/Panel/VBox/WorkArea/GPUContainer/BtnCablePower/CableHintLabel

# Tornillos cerca del cable HDMI
@onready var btn_screw_1: Button = $ModalControl/Panel/VBox/WorkArea/Screw1
@onready var btn_screw_2: Button = $ModalControl/Panel/VBox/WorkArea/Screw2
@onready var icon_screw_1: TextureRect = $ModalControl/Panel/VBox/WorkArea/Screw1/Icon
@onready var icon_screw_2: TextureRect = $ModalControl/Panel/VBox/WorkArea/Screw2/Icon

@onready var drag_arrow_indicator: PanelContainer = $ModalControl/Panel/VBox/WorkArea/DragArrowIndicator
@onready var arrow_label: Label = $ModalControl/Panel/VBox/WorkArea/DragArrowIndicator/ArrowLabel
@onready var warning_label: Label = $ModalControl/Panel/VBox/WorkArea/WarningLabel
@onready var btn_extract: Button = $ModalControl/Panel/VBox/WorkArea/BtnExtractGPU

# Panel Lateral con Detección Automática
@onready var lbl_mode_badge: Label = $ModalControl/Panel/VBox/WorkArea/RightGuidePanel/Margin/VBoxGuide/ModeBadge
@onready var guide_text: Label = $ModalControl/Panel/VBox/WorkArea/RightGuidePanel/Margin/VBoxGuide/GuideText

@onready var chk_power: Label = $ModalControl/Panel/VBox/WorkArea/RightGuidePanel/Margin/VBoxGuide/ChecklistContainer/ChkPower
@onready var chk_screws: Label = $ModalControl/Panel/VBox/WorkArea/RightGuidePanel/Margin/VBoxGuide/ChecklistContainer/ChkBracket
@onready var chk_extract: Label = $ModalControl/Panel/VBox/WorkArea/RightGuidePanel/Margin/VBoxGuide/ChecklistContainer/ChkExtract

@onready var slots_container: VBoxContainer = get_node_or_null("ModalControl/Panel/VBox/WorkArea/RightGuidePanel/Margin/VBoxGuide/SlotsContainer")
@onready var btn_slot_0: Button = get_node_or_null("ModalControl/Panel/VBox/WorkArea/RightGuidePanel/Margin/VBoxGuide/SlotsContainer/BtnSlot0")
@onready var btn_slot_1: Button = get_node_or_null("ModalControl/Panel/VBox/WorkArea/RightGuidePanel/Margin/VBoxGuide/SlotsContainer/BtnSlot1")
@onready var btn_slot_2: Button = get_node_or_null("ModalControl/Panel/VBox/WorkArea/RightGuidePanel/Margin/VBoxGuide/SlotsContainer/BtnSlot2")

var gpu_installed_states: Array[bool] = [false, false, false]
var cable_pulse_tween: Tween = null
var arrow_tween: Tween = null

func _ready() -> void:
	layer = 12
	if is_tutorial_mode:
		current_gpu_type = GPUType.MONO_COOLER
		gpu_type_configured = true
	elif not gpu_type_configured:
		current_gpu_type = GPUType.MONO_COOLER
		gpu_type_configured = true
	
	_setup_screws()
	_setup_ui()
	_update_tool_buttons()
	_apply_gpu_model_layout()
	
	if btn_slot_0: btn_slot_0.pressed.connect(func(): _on_slot_button_clicked(0))
	if btn_slot_1: btn_slot_1.pressed.connect(func(): _on_slot_button_clicked(1))
	if btn_slot_2: btn_slot_2.pressed.connect(func(): _on_slot_button_clicked(2))
	
	if target_gpu_count > 1 and is_instance_valid(slots_container):
		slots_container.visible = true
		_update_slots_ui()
		
	if initial_installed_count > 0:
		for k in range(min(initial_installed_count, gpu_installed_states.size())):
			gpu_installed_states[k] = true
		current_gpu_index = initial_installed_count
		_prepare_next_gpu_slot()
		_update_slots_ui()
	elif start_as_empty_slot:
		_setup_empty_slot_phase()
	else:
		_setup_removal_phase()
		
	_update_status()

func _process(delta: float) -> void:
	if not visible:
		return
		
	if is_decelerating:
		current_spin_fps -= DECELERATION_RATE * delta
		if current_spin_fps <= 1.0:
			current_spin_fps = 0.0
			is_spinning = false
			is_decelerating = false
			is_power_disconnected = true
			_on_deceleration_finished()
			return
			
	elif is_accelerating:
		current_spin_fps += DECELERATION_RATE * delta
		if current_spin_fps >= SPIN_MAX_FPS:
			current_spin_fps = SPIN_MAX_FPS
			is_accelerating = false
			
	if is_spinning and current_spin_fps > 0.0:
		anim_frame_timer += delta
		var frame_dur = 1.0 / maxf(current_spin_fps, 0.001)
		if anim_frame_timer >= frame_dur:
			anim_frame_timer -= frame_dur
			var frames = mono_anim_frames if current_gpu_type == GPUType.MONO_COOLER else dual_anim_frames
			anim_frame_idx = (anim_frame_idx + 1) % frames.size()
			base_gpu_sprite.texture = frames[anim_frame_idx]

func _apply_gpu_model_layout() -> void:
	var is_mono = current_gpu_type == GPUType.MONO_COOLER
	if is_mono:
		var pos = Vector2((work_area.size.x - 285) * 0.5 - 70, (work_area.size.y - 203) * 0.5 - 10)
		gpu_container.custom_minimum_size = Vector2(285, 203)
		gpu_container.size = Vector2(285, 203)
		gpu_container.position = pos
		
		# El soporte se ubica un poco hacia la derecha
		soporte_gpu_sprite.size = Vector2(285, 203)
		soporte_gpu_sprite.position = pos + Vector2(16, 0)
		soporte_gpu_sprite.texture = tex_mono_soporte
		
		# Conector de corriente PCIe en Monocooler
		btn_cable_power.position = Vector2(10, 35)
		btn_cable_power.size = Vector2(55, 45)
		
		# Tornillos ubicados cerca del cable/bracket HDMI (lado izquierdo vertical)
		btn_screw_1.position = pos + Vector2(64, 34)
		btn_screw_2.position = pos + Vector2(64, 94)
	else:
		var pos = Vector2((work_area.size.x - 500) * 0.5 - 70, (work_area.size.y - 231) * 0.5 - 10)
		gpu_container.custom_minimum_size = Vector2(500, 231)
		gpu_container.size = Vector2(500, 231)
		gpu_container.position = pos
		
		# El soporte se ubica un poco hacia la derecha
		soporte_gpu_sprite.size = Vector2(500, 231)
		soporte_gpu_sprite.position = pos + Vector2(16, 0)
		soporte_gpu_sprite.texture = tex_dual_soporte
		
		# Conector de corriente PCIe en Dual Cooler
		btn_cable_power.position = Vector2(20, 45)
		btn_cable_power.size = Vector2(55, 60)
		
		# Tornillos ubicados cerca del cable/bracket HDMI (lado izquierdo vertical)
		btn_screw_1.position = pos + Vector2(66, 44)
		btn_screw_2.position = pos + Vector2(66, 108)
		
	if current_state == State.INSERT_DRAG_DOWN:
		gpu_container.position.y = -120.0
		
	if is_power_disconnected and not is_spinning and not is_accelerating:
		base_gpu_sprite.texture = tex_mono_desconectada if is_mono else tex_dual_desconectada
	else:
		var frames = mono_anim_frames if is_mono else dual_anim_frames
		base_gpu_sprite.texture = frames[0]

func _toggle_gpu_model() -> void:
	if is_decelerating or is_accelerating: return
	current_gpu_type = GPUType.DUAL_COOLER if current_gpu_type == GPUType.MONO_COOLER else GPUType.MONO_COOLER
	_apply_gpu_model_layout()
	if current_state == State.DISCONNECT_POWER:
		is_spinning = true
		current_spin_fps = SPIN_MAX_FPS
	elif is_power_disconnected:
		base_gpu_sprite.texture = tex_mono_desconectada if current_gpu_type == GPUType.MONO_COOLER else tex_dual_desconectada
	_update_status()

func _setup_screws() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	screw_types[0] = "pala" if rng.randf() > 0.6 else "cruz"
	screw_types[1] = "pala" if rng.randf() > 0.6 else "cruz"
	screws_removed = [false, false]
	if is_instance_valid(icon_screw_1):
		icon_screw_1.texture = tex_screw_cruz if screw_types[0] == "cruz" else tex_screw_pala
	if is_instance_valid(icon_screw_2):
		icon_screw_2.texture = tex_screw_cruz if screw_types[1] == "cruz" else tex_screw_pala

func _setup_ui() -> void:
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	btn_tool_1.pressed.connect(func(): GameManager.select_tool(1))
	btn_tool_2.pressed.connect(func(): GameManager.select_tool(2))
	GameManager.tool_selected.connect(_on_tool_selected)
	
	btn_screw_1.pressed.connect(func(): _on_screw_pressed(0))
	btn_screw_2.pressed.connect(func(): _on_screw_pressed(1))
	btn_cable_power.pressed.connect(_on_cable_power_pressed)
	
	gpu_container.gui_input.connect(_on_gpu_container_gui_input)
	btn_extract.pressed.connect(_on_extract_btn_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		minigame_finished.emit(false)
		return
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_1:
			GameManager.select_tool(1)
		elif event.keycode == KEY_2:
			GameManager.select_tool(2)

func _on_tool_selected(_tool_id: int) -> void:
	_update_tool_buttons()

func _update_tool_buttons() -> void:
	var active = GameManager.equipped_tool
	btn_tool_1.modulate = Color(1.2, 1.2, 0.4) if active == 1 else Color(0.8, 0.8, 0.8)
	btn_tool_2.modulate = Color(1.2, 1.2, 0.4) if active == 2 else Color(0.8, 0.8, 0.8)

func is_install_phase() -> bool:
	return current_state in [State.EMPTY_SLOT, State.INSERT_DRAG_DOWN, State.SCREW_NEW_SOPORTE, State.CONNECT_NEW_POWER]

# =============================================================================
# DETECCIÓN AUTOMÁTICA DE "PONER" O "QUITAR"
# =============================================================================
func _auto_detect_operation_mode() -> void:
	var is_install = is_install_phase()
	if is_install:
		if is_instance_valid(lbl_mode_badge):
			lbl_mode_badge.text = "🔺 MODO: MONTAJE (INSTALAR GPU NUEVA)"
			lbl_mode_badge.modulate = Color(0.2, 1.0, 0.5)
		if is_instance_valid(guide_text):
			var has_gpu = false
			for it in GameManager.backpack:
				if it.get("name") == "Grafica" and not it.get("broken", true):
					has_gpu = true
					break
			var spare_msg = "✓ Tarjeta Gráfica en mochila lista para montar.\n\n" if has_gpu else "⚠️ Preparado para montar repuesto.\n\n"
			guide_text.text = spare_msg + "PASOS DE INSTALACIÓN:\n1. Calza la nueva GPU hacia ABAJO en el slot PCIe bajo el soporte.\n2. Coloca y aprieta los 2 tornillos del bracket HDMI con destornillador.\n3. Conecta el cable PCIe 8-pin (los ventiladores acelerarán)."
	else:
		if is_instance_valid(lbl_mode_badge):
			lbl_mode_badge.text = "🔻 MODO: DESMONTAJE (QUITAR GPU AVERIADA)"
			lbl_mode_badge.modulate = Color(1.0, 0.85, 0.2)
		if is_instance_valid(guide_text):
			guide_text.text = "PASOS DE DESMONTAJE:\n1. Clic en cable PCIe para frenar los ventiladores (de a poco hasta detenerse).\n2. Retira los 2 tornillos del soporte ubicados cerca del cable HDMI.\n3. Arrastra la GPU hacia ARRIBA (el soporte permanece fijo en el sitio)."

func _setup_removal_phase() -> void:
	current_state = State.DISCONNECT_POWER
	is_power_disconnected = false
	is_extracted = false
	is_spinning = true
	is_decelerating = false
	current_spin_fps = SPIN_MAX_FPS
	
	soporte_gpu_sprite.visible = true
	gpu_container.visible = true
	gpu_container.position.y = (work_area.size.y - gpu_container.size.y) * 0.5 - 10
	gpu_container.modulate = Color(1, 1, 1, 1)
	
	screws_removed = [false, false]
	btn_screw_1.visible = true
	btn_screw_1.disabled = false
	btn_screw_1.modulate = Color(1, 1, 1, 1)
	btn_screw_1.rotation_degrees = 0.0
	icon_screw_1.scale = Vector2(1, 1)
	
	btn_screw_2.visible = true
	btn_screw_2.disabled = false
	btn_screw_2.modulate = Color(1, 1, 1, 1)
	btn_screw_2.rotation_degrees = 0.0
	icon_screw_2.scale = Vector2(1, 1)
	
	_start_cable_pulse()
	_stop_arrow_pulse()
	btn_extract.visible = false
	_auto_detect_operation_mode()
	_update_status()

func _setup_empty_slot_phase() -> void:
	current_state = State.INSERT_DRAG_DOWN
	is_power_disconnected = true
	is_spinning = false
	
	# El soporte se queda en su lugar visible
	soporte_gpu_sprite.visible = true
	
	gpu_container.visible = true
	gpu_container.position.y = -120.0
	gpu_container.modulate = Color(0.4, 0.95, 1.0, 0.7)
	
	screws_removed = [true, true]
	btn_screw_1.visible = false
	btn_screw_2.visible = false
	
	_stop_cable_pulse()
	_start_arrow_pulse(false)
	btn_extract.visible = true
	btn_extract.text = "⇪ CLIC O ARRASTRA PARA INSTALAR GPU NUEVA"
	_auto_detect_operation_mode()
	_update_status()

# =============================================================================
# PASO 1: DESCONECTAR ALIMENTACIÓN PCIE (Frena de a poquito y cambia textura)
# =============================================================================
func _on_cable_power_pressed() -> void:
	if is_install_phase():
		_on_cable_power_pressed_install()
		return
		
	if is_decelerating or is_power_disconnected:
		return
		
	is_decelerating = true
	_stop_cable_pulse()
	_show_warning("⚡ Desconectando cable PCIe... Los ventiladores frenan progresivamente...", Color(1.0, 0.85, 0.2))
	
	var tw = create_tween()
	tw.tween_property(btn_cable_power, "modulate", Color(1.8, 1.6, 0.3, 1.0), 0.15)
	tw.tween_property(btn_cable_power, "modulate", Color(1, 1, 1, 1), 0.2)

func _on_deceleration_finished() -> void:
	is_spinning = false
	is_decelerating = false
	is_power_disconnected = true
	# Al detenerse la animación por completo, cambiamos al sprite desconectado
	base_gpu_sprite.texture = tex_mono_desconectada if (current_gpu_type == GPUType.MONO_COOLER or is_tutorial_mode) else tex_dual_desconectada
		
	_show_warning("✓ Ventiladores detenidos y cable desconectado. Ahora retira los 2 tornillos junto al cable HDMI.", Color(0.2, 1.0, 0.5))
	current_state = State.UNSCREW_SOPORTE
	_update_status()

# =============================================================================
# PASO 2: QUITAR LOS 2 TORNILLOS (Cerca del cable HDMI en el bracket)
# =============================================================================
func _on_screw_pressed(idx: int) -> void:
	if is_install_phase():
		_on_screw_pressed_install(idx)
		return
		
	if current_state == State.DISCONNECT_POWER:
		GameManager.register_error(2.0)
		_show_warning("¡PELIGRO! Primero desconecta la alimentación PCIe (los ventiladores aún giran).", Color(1.0, 0.3, 0.3))
		_shake_node(btn_cable_power)
		return
		
	if screws_removed[idx]:
		return
		
	var req_tool = 1 if screw_types[idx] == "cruz" else 2
	var tool_name = "Cruz (+)" if req_tool == 1 else "Pala (-)"
	
	if GameManager.equipped_tool != req_tool:
		GameManager.register_error(2.0)
		_show_warning("Herramienta incorrecta: Este tornillo requiere Destornillador " + tool_name + " [Tecla " + str(req_tool) + "]", Color(1.0, 0.3, 0.3))
		_shake_node(btn_screw_1 if idx == 0 else btn_screw_2)
		return
		
	screws_removed[idx] = true
	var btn = btn_screw_1 if idx == 0 else btn_screw_2
	var icon = icon_screw_1 if idx == 0 else icon_screw_2
	btn.disabled = true
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(icon, "rotation_degrees", icon.rotation_degrees + 720.0, 0.35)
	tw.tween_property(icon, "scale", Vector2(0.1, 0.1), 0.35)
	tw.tween_property(btn, "modulate:a", 0.0, 0.35)
	
	GameManager.register_repair(20, 1.5)
	var s_rem = (1 if not screws_removed[0] else 0) + (1 if not screws_removed[1] else 0)
	
	if s_rem > 0:
		_show_warning("✓ Tornillo de bracket HDMI retirado. Falta 1 tornillo.", Color(0.4, 1.0, 0.4))
	else:
		_show_warning("✓ ¡Tornillos retirados! Arrastra la GPU hacia ARRIBA (el soporte se quedará en su sitio).", Color(0.2, 1.0, 0.5))
		current_state = State.EXTRACT_DRAG_UP
		_start_arrow_pulse(true)
		btn_extract.visible = true
		btn_extract.text = "▲ EXTRAER TARJETA GRÁFICA (GPU)"
		
	_update_status()

# =============================================================================
# PASO 3: ARRASTRAR HACIA ARRIBA (El soporte se queda en su sitio)
# =============================================================================
func _on_gpu_container_gui_input(event: InputEvent) -> void:
	if current_state == State.EXTRACT_DRAG_UP:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging_gpu = true
				drag_start_y = event.global_position.y
			else:
				if is_dragging_gpu:
					is_dragging_gpu = false
					var diff_y = drag_start_y - event.global_position.y
					if diff_y >= 35.0:
						_complete_gpu_extraction()
					else:
						var orig_y = (work_area.size.y - gpu_container.size.y) * 0.5 - 10
						var tw = create_tween()
						tw.tween_property(gpu_container, "position:y", orig_y, 0.18)
		elif event is InputEventMouseMotion and is_dragging_gpu:
			var pull = clamp(drag_start_y - event.global_position.y, 0.0, 150.0)
			var orig_y = (work_area.size.y - gpu_container.size.y) * 0.5 - 10
			gpu_container.position.y = orig_y - pull
			
	elif current_state == State.INSERT_DRAG_DOWN:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging_gpu = true
				drag_start_y = event.global_position.y
			else:
				if is_dragging_gpu:
					is_dragging_gpu = false
					var diff_y = event.global_position.y - drag_start_y
					if diff_y >= 30.0 or abs(event.global_position.y - drag_start_y) < 6.0:
						_seat_new_gpu()
					else:
						var tw = create_tween()
						tw.tween_property(gpu_container, "position:y", -120.0, 0.18)
		elif event is InputEventMouseMotion and is_dragging_gpu:
			var push = clamp(event.global_position.y - drag_start_y, 0.0, 120.0)
			gpu_container.position.y = -120.0 + push

func _on_extract_btn_pressed() -> void:
	if current_state == State.EXTRACT_DRAG_UP:
		_complete_gpu_extraction()
	elif current_state == State.INSERT_DRAG_DOWN:
		_seat_new_gpu()

func _complete_gpu_extraction() -> void:
	if is_extracted: return
	is_extracted = true
	_stop_arrow_pulse()
	btn_extract.visible = false
	
	# Solo se desplaza hacia arriba gpu_container (la tarjeta).
	# El soporte_gpu_sprite se queda en el sitio como pidió el usuario.
	var tw = create_tween().set_parallel(true)
	tw.tween_property(gpu_container, "position:y", -260.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(gpu_container, "modulate:a", 0.0, 0.3)
	
	await tw.finished
	gpu_container.visible = false
	
	var t_str = "monocooler" if current_gpu_type == GPUType.MONO_COOLER else "dual_cooler"
	GameManager.add_item_to_backpack({"name": "Grafica", "broken": true, "type": "Grafica", "gpu_type": t_str})
	old_part_extracted.emit()
	
	_show_warning("✓ GPU averiada extraída con éxito. Ve a la caja de repuestos en el taller por la nueva.", Color(0.2, 1.0, 0.5))
	await get_tree().create_timer(1.0).timeout
	minigame_finished.emit(true)

# =============================================================================
# FASE DE MONTAJE (Instalación de repuesto)
# =============================================================================
func _seat_new_gpu() -> void:
	var found_idx = -1
	var picked_item: Dictionary = {}
	for i in range(GameManager.backpack.size()):
		var it = GameManager.backpack[i]
		if it is Dictionary and (it.get("name") == "Grafica" or it.get("type") == "Grafica") and not it.get("broken", true):
			found_idx = i
			picked_item = it
			break
			
	if found_idx == -1:
		_show_warning("⚠️ No tienes Tarjeta Gráfica en la mochila. Sal [ESC] para recogerla en la caja.", Color(1.0, 0.4, 0.4))
		status_label.text = "⚠️ FALTA GPU EN MOCHILA · SAL [ESC] PARA BUSCARLA"
		status_label.modulate = Color(1.0, 0.4, 0.4)
		return
		
	if found_idx != -1:
		GameManager.remove_item_from_backpack(found_idx)
		if picked_item.has("gpu_type") and str(picked_item.get("gpu_type", "")) != "":
			set_gpu_type_by_name(str(picked_item.get("gpu_type")))
			_apply_gpu_model_layout()
		
	_stop_arrow_pulse()
	btn_extract.visible = false
	gpu_container.visible = true
	
	# La nueva GPU baja y calza debajo del soporte
	var target_y = (work_area.size.y - gpu_container.size.y) * 0.5 - 10
	var tw = create_tween().set_parallel(true)
	tw.tween_property(gpu_container, "position:y", target_y, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(gpu_container, "modulate", Color(1, 1, 1, 1), 0.25)
	
	current_state = State.SCREW_NEW_SOPORTE
	screws_removed = [true, true]
	btn_screw_1.visible = true
	btn_screw_1.disabled = false
	btn_screw_1.modulate.a = 0.45
	icon_screw_1.scale = Vector2(0.5, 0.5)
	icon_screw_1.rotation_degrees = 0.0
	
	btn_screw_2.visible = true
	btn_screw_2.disabled = false
	btn_screw_2.modulate.a = 0.45
	icon_screw_2.scale = Vector2(0.5, 0.5)
	icon_screw_2.rotation_degrees = 0.0
	
	_show_warning("✓ GPU calzada en el zócalo PCIe. Ajusta los 2 tornillos del bracket HDMI.", Color(0.2, 1.0, 0.4))
	_update_status()

func _on_screw_pressed_install(idx: int) -> void:
	if not screws_removed[idx]:
		return
		
	var req_tool = 1 if screw_types[idx] == "cruz" else 2
	var tool_name = "Cruz (+)" if req_tool == 1 else "Pala (-)"
	
	if GameManager.equipped_tool != req_tool:
		GameManager.register_error(2.0)
		_show_warning("Herramienta incorrecta: Este tornillo requiere Destornillador " + tool_name + " [Tecla " + str(req_tool) + "]", Color(1.0, 0.3, 0.3))
		_shake_node(btn_screw_1 if idx == 0 else btn_screw_2)
		return
		
	screws_removed[idx] = false
	var btn = btn_screw_1 if idx == 0 else btn_screw_2
	var icon = icon_screw_1 if idx == 0 else icon_screw_2
	btn.disabled = true
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(icon, "rotation_degrees", icon.rotation_degrees - 720.0, 0.35)
	tw.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.35)
	tw.tween_property(btn, "modulate:a", 1.0, 0.35)
	
	GameManager.register_repair(20, 1.5)
	var s_rem = (1 if screws_removed[0] else 0) + (1 if screws_removed[1] else 0)
	
	if s_rem > 0:
		_show_warning("✓ Tornillo de bracket fijado. Falta 1 tornillo.", Color(0.4, 1.0, 0.4))
		_update_status()
	else:
		current_state = State.CONNECT_NEW_POWER
		_start_cable_pulse()
		_show_warning("✓ ¡Soporte asegurado con sus tornillos! Conecta el cable PCIe 8-pin.", Color(0.2, 1.0, 0.5))
		_update_status()

func _on_cable_power_pressed_install() -> void:
	if current_state != State.CONNECT_NEW_POWER:
		return
		
	is_power_disconnected = false
	_stop_cable_pulse()
	
	is_spinning = true
	is_accelerating = true
	current_spin_fps = 2.0
	
	var tw = create_tween()
	tw.tween_property(btn_cable_power, "modulate", Color(0.2, 1.5, 0.5, 1.0), 0.2)
	tw.tween_property(btn_cable_power, "modulate", Color(1, 1, 1, 1), 0.2)
	
	_check_gpu_install_completed()

func _check_gpu_install_completed() -> void:
	if current_gpu_index < gpu_installed_states.size():
		gpu_installed_states[current_gpu_index] = true
	current_gpu_index += 1
	_update_slots_ui()
	
	if current_gpu_index < target_gpu_count:
		_show_warning("✓ ¡TARJETA GPU #%d MONTADA!" % current_gpu_index, Color(0.2, 1.0, 0.4))
		status_label.text = "✓ GPU #%d INSTALADA · HAZ CLIC EN 'RANURA GPU #%d' A LA DERECHA PARA CONTINUAR" % [current_gpu_index, current_gpu_index + 1]
		status_label.modulate = Color(0.0, 0.95, 1.0)
	else:
		current_state = State.COMPLETED
		_update_status()
		_show_warning("✓ ¡OPERACIÓN COMPLETADA! Tarjeta gráfica instalada y testeada con éxito.", Color(0.2, 1.0, 0.4))
		await get_tree().create_timer(0.6).timeout
		minigame_finished.emit(true)

# =============================================================================
# MULTI-SLOT SERVIDOR
# =============================================================================
func _on_slot_button_clicked(idx: int) -> void:
	if idx == current_gpu_index and current_gpu_index < target_gpu_count and not gpu_installed_states[idx]:
		_prepare_next_gpu_slot()

func _update_slots_ui() -> void:
	if target_gpu_count <= 1 or not is_instance_valid(slots_container):
		return
	var buttons = [btn_slot_0, btn_slot_1, btn_slot_2]
	for i in range(buttons.size()):
		var btn = buttons[i]
		if not is_instance_valid(btn): continue
		if i >= target_gpu_count:
			btn.visible = false
			continue
		btn.visible = true
		if gpu_installed_states[i]:
			btn.text = "✓ RANURA GPU #%d [MONTADA]" % (i + 1)
			btn.modulate = Color(0.2, 1.0, 0.45)
			btn.disabled = false
		elif i == current_gpu_index:
			btn.text = "➔ CLIC PARA MONTAR GPU #%d" % (i + 1)
			btn.modulate = Color(1.0, 0.85, 0.2)
			btn.disabled = false
		else:
			btn.text = "🔒 RANURA GPU #%d [PENDIENTE]" % (i + 1)
			btn.modulate = Color(0.55, 0.6, 0.7, 0.6)
			btn.disabled = true

func _prepare_next_gpu_slot() -> void:
	_setup_screws()
	_setup_empty_slot_phase()
	_update_status()

# =============================================================================
# INDICADORES VISUALES Y FEEDBACK
# =============================================================================
func _update_status() -> void:
	_auto_detect_operation_mode()
	var prefix = ("RANURA #%d DE %d · " % [current_gpu_index + 1, target_gpu_count]) if target_gpu_count > 1 else ""
	var model_str = "MONOCOOLER" if current_gpu_type == GPUType.MONO_COOLER else "2 COOLERS"
	
	match current_state:
		State.DISCONNECT_POWER:
			status_label.text = prefix + "[%s] PASO 1: Clic en cable PCIe 8-pin para desconectar (los ventiladores frenarán de a poco)." % model_str
			status_label.modulate = Color(1.0, 0.85, 0.2)
		State.UNSCREW_SOPORTE:
			var s_rem = (1 if not screws_removed[0] else 0) + (1 if not screws_removed[1] else 0)
			status_label.text = prefix + "[%s] PASO 2: Quita los 2 tornillos junto al puerto HDMI con [1] Cruz o [2] Pala (%d restantes)." % [model_str, s_rem]
			status_label.modulate = Color(1.0, 0.85, 0.2)
		State.EXTRACT_DRAG_UP:
			status_label.text = prefix + "[%s] PASO 3: Arrastra la GPU hacia ARRIBA (el soporte permanece fijo en el sitio)." % model_str
			status_label.modulate = Color(0.2, 1.0, 0.5)
		State.INSERT_DRAG_DOWN:
			status_label.text = prefix + "MONTAJE PASO 1: Arrastra la nueva GPU hacia ABAJO para encajarla bajo el soporte."
			status_label.modulate = Color(0.0, 0.95, 1.0)
		State.SCREW_NEW_SOPORTE:
			var s_rem = (1 if screws_removed[0] else 0) + (1 if screws_removed[1] else 0)
			status_label.text = prefix + "MONTAJE PASO 2: Coloca y aprieta los 2 tornillos del bracket HDMI con destornillador (%d restantes)." % s_rem
			status_label.modulate = Color(1.0, 0.85, 0.2)
		State.CONNECT_NEW_POWER:
			status_label.text = prefix + "MONTAJE PASO 3: Haz clic para conectar el cable PCIe 8-pin (los ventiladores acelerarán)."
			status_label.modulate = Color(0.2, 1.0, 0.5)
		State.COMPLETED:
			status_label.text = "✓ ¡Tarjeta gráfica instalada y funcionando con éxito!"
			status_label.modulate = Color(0.2, 1.0, 0.4)
			
	_update_checklist()

func _update_checklist() -> void:
	if not is_instance_valid(chk_power) or not is_instance_valid(chk_screws) or not is_instance_valid(chk_extract):
		return
	var is_install = is_install_phase()
	if not is_install:
		_format_check_item(chk_power, is_power_disconnected, "1. Desconectar PCIe 8-Pin", current_state == State.DISCONNECT_POWER)
		var s_rem = (1 if not screws_removed[0] else 0) + (1 if not screws_removed[1] else 0)
		_format_check_item(chk_screws, s_rem == 0, "2. Quitar 2 tornillos HDMI (%d/2)" % (2 - s_rem), current_state == State.UNSCREW_SOPORTE)
		_format_check_item(chk_extract, is_extracted, "3. Extraer GPU hacia arriba", current_state == State.EXTRACT_DRAG_UP)
	else:
		_format_check_item(chk_extract, current_state != State.INSERT_DRAG_DOWN, "1. Calzar GPU en slot PCIe", current_state == State.INSERT_DRAG_DOWN)
		var s_fast = (1 if not screws_removed[0] else 0) + (1 if not screws_removed[1] else 0)
		_format_check_item(chk_screws, s_fast == 2, "2. Ajustar 2 tornillos HDMI (%d/2)" % s_fast, current_state == State.SCREW_NEW_SOPORTE)
		_format_check_item(chk_power, not is_power_disconnected, "3. Conectar cable PCIe 8-Pin", current_state == State.CONNECT_NEW_POWER)

func _format_check_item(lbl: Label, done: bool, text: String, active: bool = false) -> void:
	if done:
		lbl.text = "✓ " + text
		lbl.modulate = Color(0.2, 1.0, 0.5, 0.95)
	elif active:
		lbl.text = "➔ " + text
		lbl.modulate = Color(1.0, 0.85, 0.2, 1.0)
	else:
		lbl.text = "○ " + text
		lbl.modulate = Color(0.7, 0.75, 0.85, 0.6)

func _start_cable_pulse() -> void:
	if not is_instance_valid(cable_highlight): return
	if is_instance_valid(cable_pulse_tween): cable_pulse_tween.kill()
	cable_highlight.visible = true
	cable_hint_label.visible = true
	cable_pulse_tween = create_tween().set_loops()
	cable_pulse_tween.tween_property(cable_highlight, "modulate", Color(1.6, 1.4, 0.2, 1.0), 0.4).set_trans(Tween.TRANS_SINE)
	cable_pulse_tween.tween_property(cable_highlight, "modulate", Color(0.1, 1.0, 0.85, 0.5), 0.4).set_trans(Tween.TRANS_SINE)

func _stop_cable_pulse() -> void:
	if is_instance_valid(cable_pulse_tween):
		cable_pulse_tween.kill()
		cable_pulse_tween = null
	if is_instance_valid(cable_highlight):
		cable_highlight.visible = false
	if is_instance_valid(cable_hint_label):
		cable_hint_label.visible = false

func _start_arrow_pulse(to_up: bool) -> void:
	if not is_instance_valid(drag_arrow_indicator): return
	if is_instance_valid(arrow_tween): arrow_tween.kill()
	drag_arrow_indicator.visible = true
	if to_up:
		arrow_label.text = "▲ ▲ ARRASTRA LA GPU HACIA ARRIBA (SOPORTE FIJO) ▲ ▲"
		arrow_label.modulate = Color(1.0, 0.9, 0.1, 1.0)
	else:
		arrow_label.text = "▼ ▼ ARRASTRA LA GPU HACIA ABAJO BAJO EL SOPORTE ▼ ▼"
		arrow_label.modulate = Color(0.1, 1.0, 0.85, 1.0)
		
	var base_y = 12.0
	var offset_y = -10.0 if to_up else 10.0
	arrow_tween = create_tween().set_loops()
	arrow_tween.tween_property(drag_arrow_indicator, "position:y", base_y + offset_y, 0.4).set_trans(Tween.TRANS_SINE)
	arrow_tween.tween_property(drag_arrow_indicator, "position:y", base_y, 0.4).set_trans(Tween.TRANS_SINE)

func _stop_arrow_pulse() -> void:
	if is_instance_valid(arrow_tween):
		arrow_tween.kill()
		arrow_tween = null
	if is_instance_valid(drag_arrow_indicator):
		drag_arrow_indicator.visible = false

func _show_warning(msg: String, col: Color) -> void:
	if not is_instance_valid(warning_label): return
	warning_label.text = msg
	warning_label.modulate = col
	var tw = create_tween()
	tw.tween_property(warning_label, "scale", Vector2(1.08, 1.08), 0.1)
	tw.tween_property(warning_label, "scale", Vector2(1.0, 1.0), 0.15)

func _shake_node(node: Control) -> void:
	if not is_instance_valid(node): return
	var orig = node.position
	var tw = create_tween()
	tw.tween_property(node, "position:x", orig.x - 5.0, 0.05)
	tw.tween_property(node, "position:x", orig.x + 5.0, 0.05)
	tw.tween_property(node, "position:x", orig.x, 0.05)
