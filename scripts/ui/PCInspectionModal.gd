extends CanvasLayer

signal inspection_closed()

var current_pc = null
var cooler_minigame_scene: PackedScene = preload("res://scenes/minigames/FanCoolerMinigame.tscn")
var ram_minigame_scene: PackedScene = preload("res://scenes/minigames/RAMMinigame.tscn")
var hdd_minigame_scene: PackedScene = preload("res://scenes/minigames/HDDMinigame.tscn")
var gpu_minigame_scene: PackedScene = preload("res://scenes/minigames/GPUMinigame.tscn")
var psu_minigame_scene: PackedScene = preload("res://scenes/minigames/PSUMinigame.tscn")
var mobo_minigame_scene: PackedScene = preload("res://scenes/minigames/MotherboardMinigame.tscn")
var cpu_minigame_scene: PackedScene = preload("res://scenes/minigames/CPUMinigame.tscn")
var cpupaste_minigame_scene: PackedScene = preload("res://scenes/minigames/CPUPasteMinigame.tscn")
var cpupins_minigame_scene: PackedScene = preload("res://scenes/minigames/CPUPinsMinigame.tscn")
var dustcleaner_minigame_scene: PackedScene = preload("res://scenes/minigames/DustCleanerMinigame.tscn")
var voltimeter_minigame_scene: PackedScene = preload("res://scenes/minigames/VoltimeterMinigame.tscn")
var liquid_cooling_scene: PackedScene = preload("res://scenes/minigames/LiquidCoolingMinigame.tscn")

@onready var modal_control: Control = $ModalControl
@onready var title_label: Label = $ModalControl/Panel/VBox/Header/TitleLabel
@onready var status_summary: Label = $ModalControl/Panel/VBox/Header/StatusSummary
@onready var pc_state_badge: Label = $ModalControl/Panel/VBox/BadgeLabel
@onready var question_text: Label = $ModalControl/Panel/VBox/Header/QuestionPanel/Margin/VBox/QuestionText

# Cards (arquitectura física de una placa madre / chasis PC)
@onready var card_cpu: PanelContainer = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardCPU
@onready var card_cooler: PanelContainer = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardCooler
@onready var card_ram: PanelContainer = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardRAM
@onready var card_gpu: PanelContainer = $ModalControl/Panel/VBox/ComponentsContainer/RowMiddle/CardGPU
@onready var card_hdd: PanelContainer = $ModalControl/Panel/VBox/ComponentsContainer/RowMiddle/CardHDD
@onready var card_mobo: PanelContainer = $ModalControl/Panel/VBox/ComponentsContainer/RowBottom/CardMOBO
@onready var card_psu: PanelContainer = $ModalControl/Panel/VBox/ComponentsContainer/RowBottom/CardPSU
@onready var row_bottom: Container = $ModalControl/Panel/VBox/ComponentsContainer/RowBottom

# Etiquetas de estado
@onready var lbl_status_cpu: Label = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardCPU/Margin/VBox/Status
@onready var lbl_status_cooler: Label = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardCooler/Margin/VBox/Status
@onready var lbl_status_ram: Label = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardRAM/Margin/VBox/Status
@onready var lbl_status_gpu: Label = $ModalControl/Panel/VBox/ComponentsContainer/RowMiddle/CardGPU/Margin/VBox/Status
@onready var lbl_status_hdd: Label = $ModalControl/Panel/VBox/ComponentsContainer/RowMiddle/CardHDD/Margin/VBox/Status
@onready var lbl_status_mobo: Label = $ModalControl/Panel/VBox/ComponentsContainer/RowBottom/CardMOBO/Margin/VBox/Status
@onready var lbl_status_psu: Label = $ModalControl/Panel/VBox/ComponentsContainer/RowBottom/CardPSU/Margin/VBox/Status

# Botones de sacar pieza
@onready var btn_sacar_cpu: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardCPU/Margin/VBox/CPUButtons/HBoxMain/BtnSacar
@onready var btn_sacar_cooler: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardCooler/Margin/VBox/HBoxBtns/BtnSacar
@onready var btn_sacar_ram: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardRAM/Margin/VBox/HBoxBtns/BtnSacar
@onready var btn_sacar_gpu: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowMiddle/CardGPU/Margin/VBox/HBoxBtns/BtnSacar
@onready var btn_sacar_hdd: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowMiddle/CardHDD/Margin/VBox/HBoxBtns/BtnSacar
@onready var btn_sacar_mobo: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowBottom/CardMOBO/Margin/VBox/HBoxBtns/BtnSacar
@onready var btn_sacar_psu: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowBottom/CardPSU/Margin/VBox/HBoxBtns/BtnSacar

# Botones de examinar pieza
@onready var btn_examinar_cpu: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardCPU/Margin/VBox/CPUButtons/HBoxMain/BtnExaminar
@onready var btn_examinar_cooler: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardCooler/Margin/VBox/HBoxBtns/BtnExaminar
@onready var btn_examinar_ram: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardRAM/Margin/VBox/HBoxBtns/BtnExaminar
@onready var btn_examinar_gpu: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowMiddle/CardGPU/Margin/VBox/HBoxBtns/BtnExaminar
@onready var btn_examinar_hdd: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowMiddle/CardHDD/Margin/VBox/HBoxBtns/BtnExaminar
@onready var btn_examinar_mobo: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowBottom/CardMOBO/Margin/VBox/HBoxBtns/BtnExaminar
@onready var btn_examinar_psu: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowBottom/CardPSU/Margin/VBox/HBoxBtns/BtnExaminar

# Botones extra del CPU
@onready var btn_cpu_limpiar: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardCPU/Margin/VBox/CPUButtons/HBoxExtra/BtnLimpiar
@onready var btn_cpu_pines: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardCPU/Margin/VBox/CPUButtons/HBoxExtra/BtnPines

# Botones de herramientas en la barra lateral derecha
@onready var btn_tool_1: Button = $ModalControl/ToolsDock/Margin/VBox/BtnTool1
@onready var btn_tool_2: Button = $ModalControl/ToolsDock/Margin/VBox/BtnTool2
@onready var btn_tool_3: Button = $ModalControl/ToolsDock/Margin/VBox/BtnTool3
@onready var btn_tool_4: Button = $ModalControl/ToolsDock/Margin/VBox/BtnTool4
@onready var btn_tool_5: Button = $ModalControl/ToolsDock/Margin/VBox/BtnTool5

# Puntos de examinación (4 círculos amarillos)
@onready var exam_circle_0: TextureRect = $ModalControl/Panel/VBox/ExaminationSection/Margin/HBox/CirclesContainer/Circle0
@onready var exam_circle_1: TextureRect = $ModalControl/Panel/VBox/ExaminationSection/Margin/HBox/CirclesContainer/Circle1
@onready var exam_circle_2: TextureRect = $ModalControl/Panel/VBox/ExaminationSection/Margin/HBox/CirclesContainer/Circle2
@onready var exam_circle_3: TextureRect = $ModalControl/Panel/VBox/ExaminationSection/Margin/HBox/CirclesContainer/Circle3
@onready var exam_count_label: Label = $ModalControl/Panel/VBox/ExaminationSection/Margin/HBox/ExamCountLabel
@onready var exam_recharge_label: Label = $ModalControl/Panel/VBox/ExaminationSection/Margin/HBox/ExamRechargeLabel

# Mochila
@onready var slot_0: Button = $ModalControl/Panel/VBox/BackpackSection/BackpackSlots/Slot0
@onready var slot_1: Button = $ModalControl/Panel/VBox/BackpackSection/BackpackSlots/Slot1
@onready var slot_2: Button = $ModalControl/Panel/VBox/BackpackSection/BackpackSlots/Slot2

@onready var btn_volver: Button = $ModalControl/Panel/VBox/Footer/BtnVolver

var slot_buttons: Array[Button] = []
var comp_cards: Dictionary = {}
var comp_sacar_btns: Dictionary = {}
var comp_examinar_btns: Dictionary = {}
var comp_limpiar_btns: Dictionary = {}
var comp_pines_btns: Dictionary = {}
var comp_voltimeter_btns: Dictionary = {}
var comp_status_labels: Dictionary = {}
var card_styleboxes: Dictionary = {}

# Estado de diagnóstico y examen
var is_examining: bool = false

func get_examined_status(comp_name: String) -> String:
	if current_pc and current_pc.has_meta("examined_components"):
		var examined_dict: Dictionary = current_pc.get_meta("examined_components")
		return examined_dict.get(comp_name, "")
	return ""

func _set_examined_status(comp_name: String, status_val: String) -> void:
	if current_pc:
		var examined_dict: Dictionary = {}
		if current_pc.has_meta("examined_components"):
			examined_dict = current_pc.get_meta("examined_components")
		examined_dict[comp_name] = status_val
		current_pc.set_meta("examined_components", examined_dict)

func _clear_examined_status(comp_name: String) -> void:
	if current_pc and current_pc.has_meta("examined_components"):
		var examined_dict: Dictionary = current_pc.get_meta("examined_components")
		examined_dict.erase(comp_name)
		current_pc.set_meta("examined_components", examined_dict)

# Estado de arrastre y selección de repuestos
var selected_backpack_idx: int = -1
var is_dragging_part: bool = false
var dragged_backpack_idx: int = -1
var drag_preview: PanelContainer = null

func _ready() -> void:
	layer = 10
	btn_volver.pressed.connect(_on_volver_pressed)
	
	comp_cards = {
		"RAM": card_ram,
		"Disco Duro": card_hdd,
		"Grafica": card_gpu,
		"Fuente": card_psu,
		"Placa Madre": card_mobo,
		"Fan Cooler": card_cooler,
		"CPU": card_cpu
	}
	
	comp_sacar_btns = {
		"RAM": btn_sacar_ram,
		"Disco Duro": btn_sacar_hdd,
		"Grafica": btn_sacar_gpu,
		"Fuente": btn_sacar_psu,
		"Placa Madre": btn_sacar_mobo,
		"Fan Cooler": btn_sacar_cooler,
		"CPU": btn_sacar_cpu
	}
	
	comp_examinar_btns = {
		"RAM": btn_examinar_ram,
		"Disco Duro": btn_examinar_hdd,
		"Grafica": btn_examinar_gpu,
		"Fuente": btn_examinar_psu,
		"Placa Madre": btn_examinar_mobo,
		"Fan Cooler": btn_examinar_cooler,
		"CPU": btn_examinar_cpu
	}
	
	comp_status_labels = {
		"RAM": lbl_status_ram,
		"Disco Duro": lbl_status_hdd,
		"Grafica": lbl_status_gpu,
		"Fuente": lbl_status_psu,
		"Placa Madre": lbl_status_mobo,
		"Fan Cooler": lbl_status_cooler,
		"CPU": lbl_status_cpu
	}
	
	# Inicializar StyleBoxes únicos para cada cuadro (estética ámbar / hardware cyberpunk)
	for comp_name in comp_cards.keys():
		var card: PanelContainer = comp_cards[comp_name]
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = Color(0.08, 0.06, 0.02, 0.94)
		sb.set_border_width_all(2)
		sb.border_color = Color(1.0, 0.72, 0.22, 0.9)
		sb.set_corner_radius_all(6)
		sb.shadow_size = 6
		sb.shadow_color = Color(0, 0, 0, 0.35)
		card.add_theme_stylebox_override("panel", sb)
		card_styleboxes[comp_name] = sb
		
		# Conectar clic en botón SACAR de cada componente
		var btn_sacar: Button = comp_sacar_btns[comp_name]
		btn_sacar.pressed.connect(func(): _on_sacar_pressed(comp_name))
		
		# Conectar clic en botón EXAMINAR de cada componente
		var btn_examinar: Button = comp_examinar_btns[comp_name]
		btn_examinar.pressed.connect(func(): _on_examinar_pressed(comp_name))
		
		# Permitir también hacer clic en el cuadro para interactuar/instalar
		card.gui_input.connect(func(event): _on_card_gui_input(comp_name, event))
	
	# Registrar botones del CPU (ocultos por defecto para mantener diseño limpio y chill)
	btn_cpu_limpiar.visible = false
	btn_cpu_pines.visible = false
	
	# Botones de selección rápida de herramientas
	btn_tool_1.pressed.connect(func(): GameManager.select_tool(1))
	btn_tool_2.pressed.connect(func(): GameManager.select_tool(2))
	btn_tool_3.pressed.connect(func(): GameManager.select_tool(3))
	btn_tool_4.pressed.connect(func(): GameManager.select_tool(4))
	btn_tool_5.pressed.connect(func(): GameManager.select_tool(5))
	
	# Mochila
	slot_buttons = [slot_0, slot_1, slot_2]
	for i in range(slot_buttons.size()):
		var slot_btn = slot_buttons[i]
		slot_btn.gui_input.connect(func(event): _on_slot_gui_input(i, event))
		slot_btn.pressed.connect(func(): _on_slot_clicked(i))
		
	GameManager.backpack_updated.connect(func(_b): _refresh_ui())
	GameManager.tool_selected.connect(func(_tool_id): _refresh_ui())
	GameManager.examination_points_updated.connect(func(_pts, _max_pts, _prog): _update_examination_points_ui())
	_update_examination_points_ui()

func setup_pc(pc_node) -> void:
	current_pc = pc_node
	var is_tutorial_pc: bool = (current_pc and current_pc.has_meta("is_tutorial_pc") and current_pc.get_meta("is_tutorial_pc")) or (get_tree().current_scene and "LevelTutorial" in get_tree().current_scene.name)
	var pc_id_val = current_pc.get("pc_id") if current_pc.get("pc_id") != null else 1
	if is_tutorial_pc:
		title_label.text = "INDUCCIÓN TÉCNICA: PC DE ENTRENAMIENTO"
		if pc_state_badge:
			pc_state_badge.text = "[ MODO TUTORIAL: EXTRACCIÓN GUIADA ]"
	else:
		title_label.text = "DIAGNÓSTICO TÉCNICO: COMPUTADORA #%d" % pc_id_val
	
	# Mostrar la pregunta de diagnóstico según el reporte del cliente
	var q_text = current_pc.get("diagnostic_question") if current_pc.get("diagnostic_question") != null else ""
	if q_text == "" and current_pc.has_method("setup_diagnostic_case"):
		current_pc.setup_diagnostic_case()
		q_text = current_pc.get("diagnostic_question")
		
	if question_text:
		if q_text != "":
			question_text.text = q_text
		else:
			question_text.text = "Identifica qué componente está averiado según el reporte del cliente. Examina cada pieza para localizar la falla."

	if not current_pc.has_meta("examined_components"):
		current_pc.set_meta("examined_components", {})
	_refresh_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		_on_volver_pressed()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_KP_1:
				GameManager.select_tool(1)
			KEY_2, KEY_KP_2:
				GameManager.select_tool(2)
			KEY_3, KEY_KP_3:
				GameManager.select_tool(3)
			KEY_4, KEY_KP_4:
				GameManager.select_tool(4)
			KEY_5, KEY_KP_5:
				GameManager.select_tool(5)

# =============================================================================
# INTERACCIÓN CON TARJETAS Y ARRASTRE
# =============================================================================
func _on_card_gui_input(comp_name: String, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if selected_backpack_idx >= 0 and selected_backpack_idx < GameManager.backpack.size():
			_try_install_spare(selected_backpack_idx, comp_name)
		else:
			_on_sacar_pressed(comp_name)

func _on_slot_gui_input(idx: int, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if idx < GameManager.backpack.size():
				var it = GameManager.backpack[idx]
				if not it.get("broken", false):
					is_dragging_part = true
					dragged_backpack_idx = idx
					_create_drag_preview(it.get("name", ""))
					_update_drag_preview_pos(event.global_position)
		else:
			if is_dragging_part:
				_finish_drag(event.global_position)

func _input(event: InputEvent) -> void:
	if is_dragging_part:
		if event is InputEventMouseMotion:
			_update_drag_preview_pos(event.global_position)
			_highlight_component_under_cursor(event.global_position)
		elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_finish_drag(event.global_position)

func _unhandled_key_input(event: InputEvent) -> void:
	if not modal_control.visible:
		return
	if event is InputEventKey and event.pressed and not event.is_echo():
		match event.keycode:
			KEY_1, KEY_KP_1:
				GameManager.select_tool(1)
				get_viewport().set_input_as_handled()
			KEY_2, KEY_KP_2:
				GameManager.select_tool(2)
				get_viewport().set_input_as_handled()
			KEY_3, KEY_KP_3:
				GameManager.select_tool(3)
				get_viewport().set_input_as_handled()
			KEY_4, KEY_KP_4:
				GameManager.select_tool(4)
				get_viewport().set_input_as_handled()
			KEY_5, KEY_KP_5:
				GameManager.select_tool(5)
				get_viewport().set_input_as_handled()

func _create_drag_preview(item_name: String) -> void:
	if is_instance_valid(drag_preview):
		drag_preview.queue_free()
		
	drag_preview = PanelContainer.new()
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.z_index = 100
	
	var lbl = Label.new()
	lbl.text = "📦 REPUESTO: " + item_name + "\n(Suelta sobre el cuadro para montar)"
	lbl.add_theme_color_override("font_color", Color(0, 1, 0.6))
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.08, 0.16, 0.95)
	sb.border_color = Color(0, 0.95, 1, 1)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	drag_preview.add_theme_stylebox_override("panel", sb)
	
	drag_preview.add_child(lbl)
	modal_control.add_child(drag_preview)

func _update_drag_preview_pos(global_pos: Vector2) -> void:
	if is_instance_valid(drag_preview):
		drag_preview.global_position = global_pos + Vector2(16, 16)

func _highlight_component_under_cursor(mouse_pos: Vector2) -> void:
	for comp_name in comp_cards.keys():
		var card: PanelContainer = comp_cards[comp_name]
		var sb: StyleBoxFlat = card_styleboxes[comp_name]
		if card.get_global_rect().has_point(mouse_pos):
			sb.border_color = Color(1.5, 1.4, 0.2, 1.0)
		else:
			var st = current_pc.components.get(comp_name, "ok") if current_pc else "ok"
			_apply_card_border_color(sb, st, comp_name)

func _finish_drag(drop_pos: Vector2) -> void:
	var dropped_comp_name = ""
	for comp_name in comp_cards.keys():
		var card: PanelContainer = comp_cards[comp_name]
		if card.get_global_rect().has_point(drop_pos):
			dropped_comp_name = comp_name
			break
			
	var item_idx = dragged_backpack_idx
	is_dragging_part = false
	dragged_backpack_idx = -1
	
	if is_instance_valid(drag_preview):
		drag_preview.queue_free()
		drag_preview = null
		
	if dropped_comp_name != "":
		_try_install_spare(item_idx, dropped_comp_name)
	else:
		_refresh_ui()

func _on_slot_clicked(idx: int) -> void:
	if idx >= GameManager.backpack.size():
		selected_backpack_idx = -1
		_show_feedback("Este slot de la mochila está vacío. Busca repuestos en las cajas del taller.", false)
		_refresh_ui()
		return
		
	var it = GameManager.backpack[idx]
	if it.get("broken", false):
		selected_backpack_idx = -1
		_show_feedback("⚠️ Esta pieza está dañada (%s). Ve a la papelera del taller para desecharla." % it.get("name", ""), false)
		_refresh_ui()
		return
		
	selected_backpack_idx = idx
	_show_feedback("👉 Repuesto [%s] seleccionado. Haz clic en el cuadro del componente o en 'MONTAR' para instalarlo." % it.get("name", ""), true)
	_refresh_ui()

func _is_component_locked_for_tutorial(comp_name: String) -> bool:
	if current_pc == null or not current_pc.get_meta("is_tutorial_pc", false):
		return false
		
	var ram_done = current_pc.components.get("RAM", "") in ["ok", "fixed"]
	var ssd_done = current_pc.components.get("Disco Duro", "") in ["ok", "fixed"]
	
	if not ram_done:
		if comp_name != "RAM":
			_show_feedback("🔒 [TUTORIAL] Paso 1: Primero debes retirar e instalar la nueva Memoria RAM.", false)
			GameManager.spawn_floating_text("🔒 Paso 1: Primero instala la Memoria RAM", false)
			return true
	elif not ssd_done:
		if comp_name == "Fuente":
			_show_feedback("🔒 [TUTORIAL] Paso 2: Primero debes retirar e instalar el Disco Duro (SSD).", false)
			GameManager.spawn_floating_text("🔒 Paso 2: Primero instala el Disco Duro (SSD)", false)
			return true
			
	return false

func _try_install_spare(backpack_idx: int, target_comp: String) -> void:
	if backpack_idx < 0 or backpack_idx >= GameManager.backpack.size():
		return
	if _is_component_locked_for_tutorial(target_comp):
		return
	var item = GameManager.backpack[backpack_idx]
	var item_name = item.get("name", "")
	var is_broken = item.get("broken", false)
	
	if is_broken:
		_show_feedback("❌ Esta pieza está dañada. Deséchala en la papelera del taller y toma un repuesto nuevo.", false)
		return
		
	if item_name != target_comp:
		if (item_name == "Refrigeracion Liquida" or item_name == "Kit Refrigeracion") and target_comp == "Fan Cooler":
			selected_backpack_idx = -1
			_show_feedback("✓ ¡Kit de Refrigeración Líquida verificado desde el taller! Iniciando montaje...", true)
			_open_liquid_cooling_minigame()
			return
		_show_feedback("❌ Este repuesto es de [%s], pero intentas colocarlo en [%s]." % [item_name, target_comp], false)
		return
		
	selected_backpack_idx = -1
	_show_feedback("✓ ¡Repuesto de %s verificado! Iniciando montaje..." % target_comp, true)
	if target_comp == "RAM":
		_open_ram_minigame(true, item.get("ram_type", ""))
	elif target_comp == "Disco Duro":
		_open_hdd_minigame(true, item.get("drive_type", ""))
	else:
		_open_minigame_by_name(target_comp, true)

func _find_spare_in_backpack(comp_name: String) -> int:
	for i in range(GameManager.backpack.size()):
		var it = GameManager.backpack[i]
		if it.get("broken", false):
			continue
		var n = it.get("name", "")
		if n == comp_name:
			return i
		if comp_name == "Fan Cooler" and (n == "Refrigeracion Liquida" or n == "Kit Refrigeracion"):
			return i
	return -1

# =============================================================================
# ACCIÓN DEL BOTÓN SACAR (DESMONTAJE O MONTAJE SEGÚN DETECCIÓN) Y EXAMINAR
# =============================================================================
func _on_sacar_pressed(comp_name: String) -> void:
	if current_pc == null:
		return
	if _is_component_locked_for_tutorial(comp_name):
		return
		
	var status = current_pc.components.get(comp_name, "ok")
	
	# Acción contextual de herramienta especial si la pieza está presente
	if status != "empty":
		if GameManager.is_cleaning_tool_equipped():
			_on_limpiar_pressed(comp_name)
			return
		elif GameManager.is_voltimeter_equipped() and (comp_name in ["RAM", "Fuente", "Fan Cooler"]):
			_on_voltimeter_pressed(comp_name)
			return
		elif GameManager.is_soldering_tool_equipped() and (comp_name in ["CPU", "RAM"]):
			_on_pines_pressed(comp_name)
			return

	if status == "empty":
		var spare_idx = _find_spare_in_backpack(comp_name)
		if spare_idx != -1:
			_try_install_spare(spare_idx, comp_name)
		else:
			_show_feedback("🎒 El zócalo de [%s] está vacío. No tienes un repuesto compatible en la mochila. Búscalo en las cajas del taller." % comp_name, false)
		return
		
	if comp_name == "CPU":
		_open_cpu_minigame(false)
	else:
		_open_minigame_by_name(comp_name, false)

var exam_circles: Array[TextureRect] = []

func _update_examination_points_ui() -> void:
	if exam_circles.is_empty():
		exam_circles = [exam_circle_0, exam_circle_1, exam_circle_2, exam_circle_3]
		
	var current_pts = GameManager.examination_points
	var max_pts = GameManager.MAX_EXAMINATION_POINTS
	var progress = GameManager.pieces_repaired_since_recharge
	
	for i in range(exam_circles.size()):
		var circle = exam_circles[i]
		if circle == null:
			continue
		if i < current_pts:
			circle.modulate = Color(1.0, 0.88, 0.15, 1.0) # Amarillo brillante
		else:
			circle.modulate = Color(0.25, 0.25, 0.3, 0.35) # Consumido / apagado
			
	if exam_count_label:
		exam_count_label.text = "[ %d / %d DISPONIBLES ]" % [current_pts, max_pts]
		if current_pts == 0:
			exam_count_label.modulate = Color(1.0, 0.35, 0.35)
		else:
			exam_count_label.modulate = Color(1.0, 0.88, 0.15)
			
	if exam_recharge_label:
		exam_recharge_label.text = "⚡ Recarga: +1 cada 2 piezas reparadas (%d/2)" % progress

func _on_examinar_pressed(comp_name: String) -> void:
	if is_examining or current_pc == null:
		return
	var comps_dict = current_pc.get("components") if current_pc.get("components") != null else {}
	var status = comps_dict.get(comp_name, "ok")
	if status == "empty":
		_show_feedback("🔍 El slot de [%s] está vacío. No hay componente para examinar." % comp_name, false)
		return

	# Si ya fue examinado este componente, no gastar puntos de nuevo y mostrar resultado
	var examined_st = get_examined_status(comp_name)
	if examined_st != "":
		_show_feedback("🔍 [%s] ya fue diagnosticado previamente: %s." % [comp_name, "DEFECTUOSO ❌" if examined_st == "broken" else "OPERATIVO ✓"], true)
		return

	# Comprobar puntos de examinación
	if not GameManager.can_examine():
		_show_feedback("⚠️ ¡Sin puntos de examinación! Repara 2 piezas para recargar 1 punto de diagnóstico.", false)
		GameManager.spawn_floating_text("⚠️ ¡Sin Puntos de Examinación!", false)
		return

	GameManager.consume_examination_point()
	_update_examination_points_ui()

	is_examining = true
	var btn_ex: Button = comp_examinar_btns.get(comp_name)
	if btn_ex:
		btn_ex.text = "⏳ ANALIZANDO..."
		btn_ex.disabled = true
	
	_show_feedback("🔍 Analizando circuitos e integridad de [%s] (-1 Punto)..." % comp_name, true)
	
	# Indicador visual temporal en la tarjeta (parpadeo amarillo durante análisis)
	var sb: StyleBoxFlat = card_styleboxes.get(comp_name)
	if sb:
		sb.border_color = Color(1.0, 0.9, 0.2, 1.0)
	
	# Demora breve de 1.0 segundos (instantáneo pero con feedback claro)
	await get_tree().create_timer(1.0).timeout
	
	if not is_instance_valid(self) or current_pc == null:
		return
		
	# Comprobar si está mala o buena
	comps_dict = current_pc.get("components") if current_pc.get("components") != null else {}
	status = comps_dict.get(comp_name, "ok")
	
	if status == "broken":
		_set_examined_status(comp_name, "broken")
		_show_feedback("❌ ¡DIAGNÓSTICO: [%s] ESTÁ DEFECTUOSO! Presenta fallas críticas. Retíralo con [SACAR]." % comp_name, false)
	else:
		_set_examined_status(comp_name, "ok")
		_show_feedback("✓ ¡DIAGNÓSTICO: [%s] ESTÁ EN BUEN ESTADO! Módulo operativo al 100%%." % comp_name, true)
		
	is_examining = false
	_refresh_ui()

# =============================================================================
# ACCIONES DE HERRAMIENTAS ESPECIALES: LIMPIADOR [5] Y CAUTÍN [3] EN TODAS LAS PIEZAS
# =============================================================================
var cpu_paste_done: bool = false
var cpu_pins_done: bool = false

func _on_limpiar_pressed(comp_name: String) -> void:
	if not GameManager.is_cleaning_tool_equipped():
		_show_feedback("⚠️ Necesitas seleccionar el Limpiador [5] para realizar la limpieza.", false)
		return
	if current_pc == null:
		return
	var status = current_pc.components.get(comp_name, "ok")
	if status == "empty":
		_show_feedback("🎒 El slot de [%s] está vacío. No hay componente para limpiar." % comp_name, false)
		return

	if comp_name == "CPU":
		_open_cpu_limpiar()
	else:
		_open_dust_cleaner(comp_name)

func _open_dust_cleaner(comp_name: String) -> void:
	if not GameManager.is_cleaning_tool_equipped():
		_show_feedback("⚠️ Necesitas seleccionar el Limpiador [5] para desobstruir la pelusa.", false)
		return
	modal_control.visible = false
	var minigame = dustcleaner_minigame_scene.instantiate()
	if minigame.has_method("setup_component"):
		minigame.setup_component(comp_name)
	get_tree().root.add_child(minigame)
	
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if success:
			GameManager.register_repair(70, 5.0)
			_show_feedback("✓ ¡Limpieza profunda en [%s] completada al 100%%! Pelusa y polvo eliminados." % comp_name, true)
		_refresh_ui()
	)

func _on_pines_pressed(comp_name: String) -> void:
	if not GameManager.is_soldering_tool_equipped():
		_show_feedback("⚠️ Necesitas seleccionar la Lupa [3] para inspeccionar y alinear pines.", false)
		return
	if current_pc == null:
		return
	var status = current_pc.components.get(comp_name, "ok")
	if status == "empty":
		_show_feedback("🎒 El slot de [%s] está vacío. No hay pines para inspeccionar." % comp_name, false)
		return

	if comp_name == "CPU":
		_open_cpu_pines()
	elif comp_name == "RAM":
		_open_ram_pines()
	else:
		GameManager.register_repair(50, 3.0)
		_show_feedback("✓ ¡Inspección con Lupa [3] en [%s] completada! Pines y contactos reparados." % comp_name, true)
		_refresh_ui()

func _open_ram_pines() -> void:
	if not GameManager.is_soldering_tool_equipped():
		_show_feedback("⚠️ Necesitas seleccionar la Lupa [3] para inspeccionar los pines de la RAM.", false)
		return
	modal_control.visible = false
	var minigame = cpupins_minigame_scene.instantiate()
	get_tree().root.add_child(minigame)
	
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if success:
			GameManager.register_repair(80, 5.0)
			_show_feedback("✓ ¡Pines y contactos de la RAM inspeccionados con Lupa [3] y enderezados!", true)
			if current_pc and current_pc.components.get("RAM", "") == "broken":
				current_pc.components["RAM"] = "ok"
				_set_examined_status("RAM", "ok")
				current_pc.update_3d_state()
		_refresh_ui()
	)

func _open_cpu_limpiar() -> void:
	if not GameManager.is_cleaning_tool_equipped():
		_show_feedback("⚠️ Necesitas seleccionar el Limpiador [5] para limpiar y renovar pasta.", false)
		return
	modal_control.visible = false
	var minigame = cpupaste_minigame_scene.instantiate()
	minigame.set("is_tutorial_mode", false)
	if current_pc:
		var brand = current_pc.get("cpu_brand")
		if brand != null and brand != "":
			minigame.set("cpu_brand", brand)
	get_tree().root.add_child(minigame)
	
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if success:
			cpu_paste_done = true
			GameManager.register_repair(60, 5.0)
			_check_cpu_repaired_status("✓ ¡Pasta térmica renovada al 100% con nueva capa protectora!")
		_refresh_ui()
	)

func _open_cpu_pines() -> void:
	if not GameManager.is_soldering_tool_equipped():
		_show_feedback("⚠️ Necesitas seleccionar la Lupa [3] para manipular los pines.", false)
		return
	modal_control.visible = false
	var minigame = cpupins_minigame_scene.instantiate()
	get_tree().root.add_child(minigame)
	
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if success:
			cpu_pins_done = true
			GameManager.register_repair(80, 5.0)
			_check_cpu_repaired_status("✓ ¡Pines del CPU alineados y corregidos a 90°!")
		_refresh_ui()
	)

func _check_cpu_repaired_status(msg: String) -> void:
	if current_pc and current_pc.components.get("CPU", "") != "empty":
		if cpu_paste_done and cpu_pins_done:
			current_pc.components["CPU"] = "fixed"
			_set_examined_status("CPU", "ok")
			current_pc.update_3d_state()
			_show_feedback("✓ ¡CPU REPARADO AL 100%! Pasta térmica nueva y pines enderezados.", true)
		else:
			_show_feedback(msg, true)
	else:
		_show_feedback(msg, true)

func _on_voltimeter_pressed(comp_name: String) -> void:
	if not GameManager.is_voltimeter_equipped():
		_show_feedback("⚠️ Necesitas seleccionar el Multímetro [4] para medir.", false)
		return
	if current_pc == null:
		return
	var status = current_pc.components.get(comp_name, "ok")
	if status == "empty":
		_show_feedback("🎒 El slot de [%s] está vacío. No hay circuitos para medir." % comp_name, false)
		return
	_open_voltimeter(comp_name)

func _open_voltimeter(comp_name: String) -> void:
	if not GameManager.is_voltimeter_equipped():
		_show_feedback("⚠️ Necesitas seleccionar el Multímetro [4] para medir.", false)
		return
	modal_control.visible = false
	var minigame = voltimeter_minigame_scene.instantiate()
	if minigame.has_method("setup_component"):
		minigame.setup_component(comp_name)
	get_tree().root.add_child(minigame)
	
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if success:
			GameManager.register_repair(90, 6.0)
			if current_pc and current_pc.components.get(comp_name, "") == "broken":
				current_pc.components[comp_name] = "fixed"
				_set_examined_status(comp_name, "ok")
				current_pc.update_3d_state()
			_show_feedback("✓ ¡Diagnóstico con Multímetro [4] en [%s] completado al 100%%! Rieles y voltajes calibrados." % comp_name, true)
		_refresh_ui()
	)

# =============================================================================
# ACTUALIZACIÓN DE INTERFAZ Y ESTILOS
# =============================================================================
func _apply_card_border_color(sb: StyleBoxFlat, status: String, comp_name: String = "") -> void:
	if status == "empty":
		var spare_idx = _find_spare_in_backpack(comp_name)
		if spare_idx != -1:
			sb.border_color = Color(0.2, 1.0, 0.65, 0.95)
			sb.bg_color = Color(0.02, 0.12, 0.07, 0.95)
		else:
			sb.border_color = Color(1.0, 0.72, 0.22, 0.9)
			sb.bg_color = Color(0.08, 0.06, 0.02, 0.94)
		return
		
	var examined_st = get_examined_status(comp_name) if comp_name != "" else ""
	if examined_st == "broken":
		# Si la pieza está mala el cuadro se pone rojo
		sb.border_color = Color(1.0, 0.2, 0.25, 0.95)
		sb.bg_color = Color(0.18, 0.04, 0.06, 0.95)
	elif examined_st == "ok" or status == "fixed":
		# Si la pieza está buena se queda en verde
		sb.border_color = Color(0.0, 1.0, 0.55, 0.95)
		sb.bg_color = Color(0.02, 0.14, 0.08, 0.95)
	else:
		# Antes de examinar se muestran en ámbar cyberpunk
		sb.border_color = Color(1.0, 0.72, 0.22, 0.9)
		sb.bg_color = Color(0.08, 0.06, 0.02, 0.94)

func _apply_contextual_action_button(btn: Button, comp_name: String, _status: String, examined_st: String) -> void:
	if not is_instance_valid(btn):
		return
	if GameManager.is_cleaning_tool_equipped():
		btn.text = "🧼 LIMPIAR [5]"
		btn.disabled = false
		btn.modulate = Color(0.2, 1.0, 0.85, 1.0)
	elif GameManager.is_voltimeter_equipped() and (comp_name in ["RAM", "Fuente", "Fan Cooler"]):
		btn.text = "⚡ MEDIR [4]"
		btn.disabled = false
		btn.modulate = Color(1.0, 0.85, 0.2, 1.0)
	elif GameManager.is_soldering_tool_equipped() and (comp_name in ["CPU", "RAM"]):
		btn.text = "📍 PINES [3]"
		btn.disabled = false
		btn.modulate = Color(1.0, 0.6, 0.2, 1.0)
	else:
		btn.text = "⬇ EXTRAER"
		btn.disabled = false
		if examined_st == "broken":
			btn.modulate = Color(1.0, 0.35, 0.35, 1.0)
		else:
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _refresh_ui() -> void:
	_update_examination_points_ui()
	if current_pc == null:
		return
	var comps_dict: Dictionary = current_pc.get("components") if current_pc.get("components") != null else {}
	if comps_dict.is_empty():
		return
		
	var ram_spec = ("%s 16GB · 1.35V · DIMM_A2" % current_pc.ram_type.to_upper()) if (current_pc and "ram_type" in current_pc) else "DDR5 16GB · 1.35V · DIMM_A2"
	var drive_spec = ("NVMe PCIe 4.0 x4 · M2_0" if current_pc.get("drive_type") == "m2" else "SATA 6Gbps · PORT_0") if (current_pc and "drive_type" in current_pc) else "NVMe PCIe 4.0 x4 · M2_0"
	var cpu_spec = ("AMD RYZEN 3 · AM4 · 65W TDP" if (current_pc and current_pc.get("cpu_brand") == "amd") else "INTEL CORE I5 · LGA1700 · 125W TDP") if (current_pc and "cpu_brand" in current_pc) else "INTEL CORE I5 · LGA1700 · 125W TDP"
	var comp_subtitles = {
		"RAM": ram_spec,
		"Disco Duro": drive_spec,
		"Grafica": "RTX 4070 · PCIe 4.0 x16 · 12VHPWR",
		"Fuente": "850W ATX 3.0 · +12V Single Rail · 80+ Gold",
		"Placa Madre": "Chipset Z790 · PCIe Gen5 · BIOS 2.8",
		"Fan Cooler": "PWM 4-Pin · 1850 RPM · Dual Tower",
		"CPU": cpu_spec
	}
	
	# Comprobar si el jugador tiene el kit de refrigeración líquida en la mochila
	var has_liquid_kit = false
	for it in GameManager.backpack:
		var n = it.get("name", "")
		if (n == "Refrigeracion Liquida" or n == "Kit Refrigeracion") and not it.get("broken", true):
			has_liquid_kit = true
			break

	var is_tut_pc: bool = (current_pc and current_pc.has_meta("is_tutorial_pc") and current_pc.get_meta("is_tutorial_pc")) or (get_tree().current_scene and "LevelTutorial" in get_tree().current_scene.name)

	for comp_name in comp_cards.keys():
		var status = comps_dict.get(comp_name, "ok")
		var sb: StyleBoxFlat = card_styleboxes[comp_name]
		_apply_card_border_color(sb, status, comp_name)
		
		var lbl: Label = comp_status_labels[comp_name]
		var sub = comp_subtitles.get(comp_name, "")
		var btn_sacar: Button = comp_sacar_btns[comp_name]
		var examined_st = get_examined_status(comp_name)
		
		# Botón SACAR / PONER interactivo y visible
		btn_sacar.visible = true
		btn_sacar.disabled = false

		match status:
			"empty":
				var spare_idx = _find_spare_in_backpack(comp_name)
				if spare_idx != -1:
					var spare_item = GameManager.backpack[spare_idx]
					var spare_name = spare_item.get("name", comp_name)
					lbl.text = "%s\n[ ⚡ REPUESTO DETECTADO EN MOCHILA ]\n(Pulsa 'PONER' o haz clic para instalar)" % sub
					lbl.modulate = Color(0.2, 1.0, 0.65, 1.0)
					btn_sacar.text = "⬆ PONER"
					btn_sacar.disabled = false
					btn_sacar.modulate = Color(0.2, 1.0, 0.65, 1.0)
				else:
					if comp_name == "Fan Cooler":
						lbl.text = "%s\n[ ⚠️ ZÓCALO VACÍO ]\n(Requiere Kit de Líquida o Cooler del taller)" % sub
						lbl.modulate = Color(1.0, 0.72, 0.22, 1.0)
					else:
						lbl.text = "%s\n[ ⚠️ ZÓCALO VACÍO ]\n(Consigue el repuesto en las cajas del taller)" % sub
						lbl.modulate = Color(1.0, 0.72, 0.22, 1.0)
					btn_sacar.text = "⚠️ VACÍO"
					btn_sacar.disabled = true
					btn_sacar.modulate = Color(0.6, 0.6, 0.6, 0.6)
			"fixed":
				lbl.text = "%s\n[ ✓ COMPONENTE OPERATIVO AL 100%% ]" % sub
				lbl.modulate = Color(0.0, 1.0, 0.55, 1.0)
				btn_sacar.text = "⬇ SACAR"
				btn_sacar.disabled = false
				btn_sacar.modulate = Color(0.7, 0.9, 1.0, 0.9)
			_:
				btn_sacar.text = "⬇ SACAR"
				btn_sacar.disabled = false
				if examined_st == "broken":
					lbl.text = "%s\n[ ❌ DEFECTUOSO // FALLA DETECTADA ]\n(Pulsa 'SACAR' para desmontar)" % sub
					lbl.modulate = Color(1.0, 0.3, 0.3, 1.0)
					btn_sacar.modulate = Color(1.0, 0.35, 0.35, 1.0)
				elif examined_st == "ok":
					lbl.text = "%s\n[ ✓ VERIFICADO EN BUEN ESTADO ]" % sub
					lbl.modulate = Color(0.0, 1.0, 0.55, 1.0)
					btn_sacar.modulate = Color(0.2, 0.95, 1.0, 1.0)
				else:
					lbl.text = "%s\n[ 🔧 COMPONENTE INSTALADO ]\n(Pulsa 'SACAR' o examina con 🔍)" % sub
					lbl.modulate = Color(1.0, 0.75, 0.2, 1.0)
					btn_sacar.modulate = Color(1.0, 1.0, 1.0, 1.0)

		# Bloqueo visual progresivo exclusivo para el tutorial
		if is_tut_pc:
			var ram_done = current_pc.components.get("RAM", "") in ["ok", "fixed"]
			var ssd_done = current_pc.components.get("Disco Duro", "") in ["ok", "fixed"]
			if not ram_done and comp_name != "RAM":
				btn_sacar.text = "🔒 PRIMERO LA RAM"
				btn_sacar.disabled = true
				btn_sacar.modulate = Color(0.5, 0.5, 0.5, 0.6)
			elif not ssd_done and comp_name == "Fuente":
				btn_sacar.text = "🔒 PRIMERO EL DISCO"
				btn_sacar.disabled = true
				btn_sacar.modulate = Color(0.5, 0.5, 0.5, 0.6)
				
		if comp_name == "CPU":
			btn_cpu_limpiar.visible = false
			btn_cpu_pines.visible = false

		# Estado de botón EXAMINAR en cada cuadro
		if comp_examinar_btns.has(comp_name):
			var btn_ex: Button = comp_examinar_btns[comp_name]
			if status == "empty":
				btn_ex.disabled = true
				btn_ex.text = "🔍 EXAMINAR"
				btn_ex.modulate = Color(0.6, 0.6, 0.6, 0.5)
			else:
				btn_ex.disabled = is_examining
				if examined_st == "broken":
					btn_ex.text = "⚠️ DEFECTUOSO"
					btn_ex.modulate = Color(1.0, 0.4, 0.4, 1.0)
				elif examined_st == "ok" or status == "fixed":
					btn_ex.text = "✓ OPERATIVO"
					btn_ex.modulate = Color(0.3, 1.0, 0.6, 1.0)
				else:
					btn_ex.text = "🔍 EXAMINAR"
					btn_ex.modulate = Color(1.0, 1.0, 1.0, 1.0)

	# En el tutorial solo se muestra RAM, Fuente de Poder y Almacenamiento (SSD/HDD)
	if is_tut_pc:
		if card_cpu:
			card_cpu.visible = false
		if card_cooler:
			card_cooler.visible = false
		if card_ram:
			card_ram.visible = true
		if card_gpu:
			card_gpu.visible = false
		if card_hdd:
			card_hdd.visible = true
			var hdd_title = card_hdd.get_node_or_null("Margin/VBox/Title") as Label
			if hdd_title:
				hdd_title.text = "ALMACENAMIENTO (SSD / HDD)"
		if card_mobo:
			card_mobo.visible = false
		if card_psu:
			card_psu.visible = true
		if row_bottom:
			row_bottom.visible = true
	else:
		if card_cpu:
			card_cpu.visible = true
		if card_cooler:
			card_cooler.visible = true
		if card_ram:
			card_ram.visible = true
		if card_gpu:
			card_gpu.visible = true
		if card_hdd:
			card_hdd.visible = true
			var hdd_title = card_hdd.get_node_or_null("Margin/VBox/Title") as Label
			if hdd_title:
				hdd_title.text = "ALMACENAMIENTO (M.2 / SATA)"
		if card_mobo:
			card_mobo.visible = true
		if card_psu:
			card_psu.visible = true
		if row_bottom:
			row_bottom.visible = true
	
	# Actualizar slots de mochila
	for i in range(slot_buttons.size()):
		var slot_btn = slot_buttons[i]
		if i < GameManager.backpack.size():
			var it = GameManager.backpack[i]
			var is_broken = it.get("broken", false)
			var item_name = it.get("display_name", it.get("name", ""))
			if is_broken:
				slot_btn.text = "Slot %d: [ DAÑADO ]\n%s (Papelera)" % [i + 1, item_name]
				slot_btn.modulate = Color(1.0, 0.35, 0.35, 0.85)
			else:
				var is_selected = (i == selected_backpack_idx)
				if is_selected:
					slot_btn.text = "Slot %d: [ SELECCIONADO ]\n⚡ %s (Clic en cuadro)" % [i + 1, item_name]
					slot_btn.modulate = Color(1.5, 1.4, 0.2, 1.0)
				else:
					slot_btn.text = "Slot %d: [ REPUESTO NUEVO ]\n⚡ %s (Arrastra a la PC)" % [i + 1, item_name]
					slot_btn.modulate = Color(0.2, 1.0, 0.6, 1.0)
		else:
			slot_btn.text = "Slot %d: [ VACÍO ]\n(Busca repuestos en sala)" % (i + 1)
			slot_btn.modulate = Color(0.5, 0.5, 0.5, 0.5)

	# Actualizar botones de barra de herramientas en la modal
	var active_t = GameManager.equipped_tool
	var tool_btns = [btn_tool_1, btn_tool_2, btn_tool_3, btn_tool_4, btn_tool_5]
	for idx in range(tool_btns.size()):
		var t_btn = tool_btns[idx]
		if not t_btn:
			continue
		if t_btn.has_method("set_active_tool"):
			t_btn.set_active_tool((idx + 1) == active_t)
		elif (idx + 1) == active_t:
			t_btn.modulate = Color(1.3, 1.3, 0.35, 1.0) # Seleccionado / brillante
		else:
			t_btn.modulate = Color(0.7, 0.7, 0.7, 0.75)
	
	var fixed_count = 0
	for comp in comps_dict.keys():
		if comps_dict.get(comp) == "fixed":
			fixed_count += 1

	var total_comps = comps_dict.size()
	var badge_sb = pc_state_badge.get_theme_stylebox("normal")
	if current_pc.has_method("is_fully_repaired") and current_pc.is_fully_repaired():
		pc_state_badge.text = "🎉 ¡FALLA SOLUCIONADA! · EQUIPO REPARADO AL 100% ✓"
		pc_state_badge.modulate = Color(0.0, 1.0, 0.45, 1.0)
		if badge_sb is StyleBoxFlat:
			badge_sb.border_color = Color(0.0, 1.0, 0.5, 0.95)
			badge_sb.bg_color = Color(0.01, 0.14, 0.08, 0.95)
		status_summary.text = "¡Diagnóstico y reparación exitosos! La máquina bootea al 100%."
		status_summary.modulate = Color(0.0, 1.0, 0.45, 1.0)
	else:
		var broken_count = 0
		var empty_count = 0
		for comp in comps_dict.keys():
			if comps_dict.get(comp) == "broken":
				broken_count += 1
			elif comps_dict.get(comp) == "empty":
				empty_count += 1
		if empty_count > 0:
			var empty_with_spare = 0
			for comp_k in comps_dict.keys():
				if comps_dict.get(comp_k) == "empty" and _find_spare_in_backpack(comp_k) != -1:
					empty_with_spare += 1
			if empty_with_spare > 0:
				pc_state_badge.text = "🎒 REPUESTO DETECTADO EN MOCHILA · HAZ CLIC EN [MONTAR] PARA INSTALAR"
				pc_state_badge.modulate = Color(0.2, 1.0, 0.65, 1.0)
				if badge_sb is StyleBoxFlat:
					badge_sb.border_color = Color(0.2, 1.0, 0.65, 0.95)
					badge_sb.bg_color = Color(0.02, 0.12, 0.08, 0.95)
			else:
				pc_state_badge.text = "MONTAJE PENDIENTE · CONSIGUE EL REPUESTO EN LAS CAJAS DEL TALLER"
				pc_state_badge.modulate = Color(1.0, 0.85, 0.2, 1.0)
				if badge_sb is StyleBoxFlat:
					badge_sb.border_color = Color(1.0, 0.85, 0.2, 0.9)
					badge_sb.bg_color = Color(0.12, 0.08, 0.02, 0.95)
		else:
			pc_state_badge.text = "DIAGNÓSTICO EN CURSO · RESPONDE LA PREGUNTA Y LOCALIZA LA AVERÍA"
			pc_state_badge.modulate = Color(1.0, 0.75, 0.2, 1.0)
			if badge_sb is StyleBoxFlat:
				badge_sb.border_color = Color(1.0, 0.72, 0.22, 0.9)
				badge_sb.bg_color = Color(0.08, 0.06, 0.02, 0.95)
		if selected_backpack_idx < 0 and not is_examining:
			if comps_dict.get("Fan Cooler") == "empty" and not has_liquid_kit:
				status_summary.text = "⚠️ EL CUADRO DE REFRIGERACIÓN ESTÁ OCULTO: Ve a la sala y recoge el Kit de Refrigeración con [E] para habilitar el cuadro vacío."
				status_summary.modulate = Color(1.0, 0.85, 0.2, 1.0)
			elif comps_dict.get("Fan Cooler") == "empty" and has_liquid_kit:
				status_summary.text = "✓ ¡Kit de Refrigeración disponible! Haz clic en [⬆ MONTAR KIT] o arrástralo sobre el cuadro vacío."
				status_summary.modulate = Color(0.2, 1.0, 0.5, 1.0)
			elif empty_count > 0:
				status_summary.text = "Detectando zócalo vacío. Si tienes el repuesto listo, haz clic en [⬆ MONTAR REPUESTO] en el cuadro."
				status_summary.modulate = Color(0.2, 1.0, 0.65, 1.0)
			else:
				status_summary.text = "Lee la pregunta arriba, presiona 'EXAMINAR' para corroborar la pieza y 'SACAR' para reemplazarla."
				status_summary.modulate = Color(1.0, 0.85, 0.2, 1.0)

# =============================================================================
# LANZAMIENTO DE MINIJUEGOS (DESMONTAJE O MONTAJE)
# =============================================================================
func _open_minigame_by_name(comp_name: String, is_empty: bool) -> void:
	match comp_name:
		"Fan Cooler":
			_open_cooler_minigame(is_empty)
		"RAM":
			_open_ram_minigame(is_empty)
		"Disco Duro":
			_open_hdd_minigame(is_empty)
		"Grafica":
			_open_gpu_minigame(is_empty)
		"Fuente":
			_open_psu_minigame(is_empty)
		"Placa Madre":
			_open_mobo_minigame(is_empty)
		"CPU":
			_open_cpu_minigame(is_empty)

func _open_cooler_minigame(is_empty: bool) -> void:
	modal_control.visible = false
	var minigame = cooler_minigame_scene.instantiate()
	minigame.start_as_empty_slot = is_empty
	minigame.set("is_tutorial_mode", false)
	get_tree().root.add_child(minigame)
	
	minigame.connect("old_part_extracted", func():
		current_pc.components["Fan Cooler"] = "empty"
		_clear_examined_status("Fan Cooler")
		current_pc.update_3d_state()
	)
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		if success:
			if is_empty:
				current_pc.components["Fan Cooler"] = "fixed"
				_set_examined_status("Fan Cooler", "ok")
				current_pc.update_3d_state()
				GameManager.register_repair(100, 10.0)
				_show_feedback("✓ ¡Fan Cooler nuevo instalado y testeado!", true)
			else:
				_show_feedback("✓ Fan Cooler averiado retirado. Slot libre para repuesto.", true)
		_refresh_ui()
	)

func _open_ram_minigame(is_empty: bool, preferred_ram_type: String = "") -> void:
	modal_control.visible = false
	var minigame = ram_minigame_scene.instantiate()
	minigame.start_as_empty_slot = is_empty
	minigame.set("is_tutorial_mode", false)
	if preferred_ram_type != "":
		minigame.set_ram_type(preferred_ram_type)
	elif not is_empty and current_pc and "ram_type" in current_pc:
		minigame.set_ram_type(current_pc.ram_type)
	get_tree().root.add_child(minigame)
	
	minigame.connect("old_part_extracted", func():
		current_pc.components["RAM"] = "empty"
		_clear_examined_status("RAM")
		current_pc.update_3d_state()
	)
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		if success:
			if is_empty:
				current_pc.components["RAM"] = "fixed"
				if minigame.get("current_ram_type") != null and minigame.current_ram_type != "":
					current_pc.ram_type = minigame.current_ram_type
				_set_examined_status("RAM", "ok")
				current_pc.update_3d_state()
				GameManager.register_repair(100, 10.0)
				var type_lbl = current_pc.ram_type.to_upper() if "ram_type" in current_pc else "DDR"
				_show_feedback("✓ ¡Módulo RAM %s nuevo instalado y testeado!" % type_lbl, true)
			else:
				_show_feedback("✓ Módulo RAM averiado retirado. Slot libre para repuesto.", true)
		_refresh_ui()
	)

func _open_hdd_minigame(is_empty: bool, preferred_drive_type: String = "") -> void:
	modal_control.visible = false
	var minigame = hdd_minigame_scene.instantiate()
	minigame.start_as_empty_slot = is_empty
	minigame.set("is_tutorial_mode", false)
	if current_pc and "saved_screw_type" in current_pc and current_pc.saved_screw_type != "":
		minigame.screw_type = current_pc.saved_screw_type
	if preferred_drive_type != "":
		minigame.set("current_drive_type", preferred_drive_type)
	elif current_pc and "drive_type" in current_pc and current_pc.drive_type != "":
		minigame.set("current_drive_type", current_pc.drive_type)
	get_tree().root.add_child(minigame)
	
	minigame.connect("old_part_extracted", func():
		if current_pc:
			current_pc.components["Disco Duro"] = "empty"
			_clear_examined_status("Disco Duro")
			current_pc.saved_screw_type = minigame.screw_type
			if "current_drive_type" in minigame and "drive_type" in current_pc:
				current_pc.drive_type = minigame.current_drive_type
			current_pc.update_3d_state()
	)
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		if success and current_pc:
			var d_type = minigame.get("current_drive_type") if minigame.get("current_drive_type") != null else "m2"
			var d_lbl = "SSD M.2 NVMe" if d_type == "m2" else "SSD SATA"
			if is_empty:
				current_pc.components["Disco Duro"] = "fixed"
				if "drive_type" in current_pc:
					current_pc.drive_type = d_type
				_set_examined_status("Disco Duro", "ok")
				current_pc.update_3d_state()
				GameManager.register_repair(100, 10.0)
				_show_feedback("✓ ¡Unidad %s nueva instalada y testeada!" % d_lbl, true)
			else:
				_show_feedback("✓ Unidad %s averiada retirada. Puerto libre para repuesto." % d_lbl, true)
		_refresh_ui()
	)

func _open_gpu_minigame(is_empty: bool) -> void:
	modal_control.visible = false
	var minigame = gpu_minigame_scene.instantiate()
	minigame.start_as_empty_slot = is_empty
	minigame.set("is_tutorial_mode", false)
	get_tree().root.add_child(minigame)
	
	minigame.connect("old_part_extracted", func():
		current_pc.components["Grafica"] = "empty"
		_clear_examined_status("Grafica")
		current_pc.update_3d_state()
	)
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		if success:
			if is_empty:
				current_pc.components["Grafica"] = "fixed"
				_set_examined_status("Grafica", "ok")
				current_pc.update_3d_state()
				GameManager.register_repair(100, 10.0)
				_show_feedback("✓ ¡Tarjeta Gráfica nueva instalada y testeada!", true)
			else:
				_show_feedback("✓ Tarjeta Gráfica averiada retirada. Slot PCIe libre para repuesto.", true)
		_refresh_ui()
	)

func _open_psu_minigame(is_empty: bool) -> void:
	modal_control.visible = false
	var minigame = psu_minigame_scene.instantiate()
	minigame.start_as_empty_slot = is_empty
	minigame.set("is_tutorial_mode", false)
	get_tree().root.add_child(minigame)
	
	minigame.connect("old_part_extracted", func():
		current_pc.components["Fuente"] = "empty"
		_clear_examined_status("Fuente")
		current_pc.update_3d_state()
	)
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		if success:
			if is_empty:
				current_pc.components["Fuente"] = "fixed"
				_set_examined_status("Fuente", "ok")
				current_pc.update_3d_state()
				GameManager.register_repair(100, 10.0)
				_show_feedback("✓ ¡Fuente de alimentación nueva instalada y testeada!", true)
			else:
				_show_feedback("✓ Fuente averiada retirada. Túnel de chasis libre para repuesto.", true)
		_refresh_ui()
	)

func _open_mobo_minigame(is_empty: bool) -> void:
	modal_control.visible = false
	var minigame = mobo_minigame_scene.instantiate()
	minigame.start_as_empty_slot = is_empty
	minigame.set("is_tutorial_mode", false)
	get_tree().root.add_child(minigame)
	
	minigame.connect("old_part_extracted", func():
		current_pc.components["Placa Madre"] = "empty"
		_clear_examined_status("Placa Madre")
		current_pc.update_3d_state()
	)
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		if success:
			if is_empty:
				current_pc.components["Placa Madre"] = "fixed"
				_set_examined_status("Placa Madre", "ok")
				current_pc.update_3d_state()
				GameManager.register_repair(150, 15.0)
				_show_feedback("✓ ¡Placa Madre nueva instalada y testeada!", true)
			else:
				_show_feedback("✓ Placa Madre averiada retirada. Chasis libre para repuesto.", true)
		_refresh_ui()
	)

func _open_cpu_minigame(is_empty: bool) -> void:
	modal_control.visible = false
	var minigame = cpu_minigame_scene.instantiate()
	minigame.start_as_empty_slot = is_empty
	minigame.set("is_tutorial_mode", false)
	get_tree().root.add_child(minigame)
	
	minigame.connect("old_part_extracted", func():
		current_pc.components["CPU"] = "empty"
		_clear_examined_status("CPU")
		current_pc.update_3d_state()
	)
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if success:
			if is_empty:
				current_pc.components["CPU"] = "fixed"
				_set_examined_status("CPU", "ok")
				current_pc.update_3d_state()
				GameManager.register_repair(120, 12.0)
				_show_feedback("✓ ¡Procesador nuevo montado y asegurado!", true)
			else:
				_show_feedback("✓ CPU retirado. Socket listo para repuesto.", true)
		_refresh_ui()
	)

func _open_liquid_cooling_minigame() -> void:
	modal_control.visible = false
	var minigame = liquid_cooling_scene.instantiate()
	get_tree().root.add_child(minigame)
	
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if success:
			for i in range(GameManager.backpack.size()):
				var bname = GameManager.backpack[i].get("name", "")
				if bname == "Refrigeracion Liquida" or bname == "Kit Refrigeracion":
					GameManager.remove_item_from_backpack(i)
					break
			if current_pc:
				current_pc.components["Fan Cooler"] = "fixed"
				_set_examined_status("Fan Cooler", "ok")
				current_pc.update_3d_state()
			GameManager.register_repair(150, 15.0)
			_show_feedback("✓ ¡Sistema de Refrigeración Líquida montado y purgado con éxito!", true)
		_refresh_ui()
	)

func _show_feedback(msg: String, is_positive: bool) -> void:
	status_summary.text = msg
	status_summary.modulate = Color(0, 1, 0.5, 1) if is_positive else Color(1, 0.2, 0.3, 1)

func _on_volver_pressed() -> void:
	if current_pc and current_pc.has_method("is_fully_repaired") and current_pc.is_fully_repaired():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var cur_sc = get_tree().current_scene
		if cur_sc and cur_sc.has_method("_advance_to_completed"):
			cur_sc._advance_to_completed()
		elif not current_pc.get_meta("is_tutorial_pc", false):
			GameManager.win_level()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	inspection_closed.emit()
	queue_free()
