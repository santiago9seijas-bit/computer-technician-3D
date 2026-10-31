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

@onready var modal_control: Control = $ModalControl
@onready var title_label: Label = $ModalControl/Panel/VBox/Header/TitleLabel
@onready var status_summary: Label = $ModalControl/Panel/VBox/Header/StatusSummary
@onready var pc_state_badge: Label = $ModalControl/Panel/VBox/Header/BadgeLabel

# Cards (cuadros de componentes)
@onready var card_ram: PanelContainer = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardRAM
@onready var card_hdd: PanelContainer = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardHDD
@onready var card_gpu: PanelContainer = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardGPU
@onready var card_psu: PanelContainer = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardPSU
@onready var card_mobo: PanelContainer = $ModalControl/Panel/VBox/ComponentsContainer/RowBottom/CardMOBO
@onready var card_cooler: PanelContainer = $ModalControl/Panel/VBox/ComponentsContainer/RowBottom/CardCooler
@onready var card_cpu: PanelContainer = $ModalControl/Panel/VBox/ComponentsContainer/RowBottom/CardCPU

# Etiquetas de estado
@onready var lbl_status_ram: Label = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardRAM/Margin/VBox/Status
@onready var lbl_status_hdd: Label = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardHDD/Margin/VBox/Status
@onready var lbl_status_gpu: Label = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardGPU/Margin/VBox/Status
@onready var lbl_status_psu: Label = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardPSU/Margin/VBox/Status
@onready var lbl_status_mobo: Label = $ModalControl/Panel/VBox/ComponentsContainer/RowBottom/CardMOBO/Margin/VBox/Status
@onready var lbl_status_cooler: Label = $ModalControl/Panel/VBox/ComponentsContainer/RowBottom/CardCooler/Margin/VBox/Status
@onready var lbl_status_cpu: Label = $ModalControl/Panel/VBox/ComponentsContainer/RowBottom/CardCPU/Margin/VBox/Status

# Botones de sacar pieza
@onready var btn_sacar_ram: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardRAM/Margin/VBox/BtnSacar
@onready var btn_sacar_hdd: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardHDD/Margin/VBox/BtnSacar
@onready var btn_sacar_gpu: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardGPU/Margin/VBox/BtnSacar
@onready var btn_sacar_psu: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardPSU/Margin/VBox/BtnSacar
@onready var btn_sacar_mobo: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowBottom/CardMOBO/Margin/VBox/BtnSacar
@onready var btn_sacar_cooler: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowBottom/CardCooler/Margin/VBox/BtnSacar
@onready var btn_sacar_cpu: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowBottom/CardCPU/Margin/VBox/CPUButtons/BtnSacar

# Botones extra del CPU
@onready var btn_cpu_limpiar: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowBottom/CardCPU/Margin/VBox/CPUButtons/BtnLimpiar
@onready var btn_cpu_pines: Button = $ModalControl/Panel/VBox/ComponentsContainer/RowBottom/CardCPU/Margin/VBox/CPUButtons/BtnPines

# Botones de herramientas en la modal
@onready var btn_tool_1: Button = $ModalControl/Panel/VBox/ToolsSection/BtnTool1
@onready var btn_tool_2: Button = $ModalControl/Panel/VBox/ToolsSection/BtnTool2
@onready var btn_tool_3: Button = $ModalControl/Panel/VBox/ToolsSection/BtnTool3
@onready var btn_tool_4: Button = $ModalControl/Panel/VBox/ToolsSection/BtnTool4
@onready var btn_tool_5: Button = $ModalControl/Panel/VBox/ToolsSection/BtnTool5

# Mochila
@onready var slot_0: Button = $ModalControl/Panel/VBox/BackpackSection/BackpackSlots/Slot0
@onready var slot_1: Button = $ModalControl/Panel/VBox/BackpackSection/BackpackSlots/Slot1
@onready var slot_2: Button = $ModalControl/Panel/VBox/BackpackSection/BackpackSlots/Slot2

@onready var btn_volver: Button = $ModalControl/Panel/VBox/Footer/BtnVolver

var slot_buttons: Array[Button] = []
var comp_cards: Dictionary = {}
var comp_sacar_btns: Dictionary = {}
var comp_limpiar_btns: Dictionary = {}
var comp_pines_btns: Dictionary = {}
var comp_status_labels: Dictionary = {}
var card_styleboxes: Dictionary = {}

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
	
	comp_status_labels = {
		"RAM": lbl_status_ram,
		"Disco Duro": lbl_status_hdd,
		"Grafica": lbl_status_gpu,
		"Fuente": lbl_status_psu,
		"Placa Madre": lbl_status_mobo,
		"Fan Cooler": lbl_status_cooler,
		"CPU": lbl_status_cpu
	}
	
	# Inicializar StyleBoxes únicos para cada cuadro
	for comp_name in comp_cards.keys():
		var card: PanelContainer = comp_cards[comp_name]
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = Color(0.08, 0.03, 0.16, 0.92)
		sb.set_border_width_all(2)
		sb.border_color = Color(0.15, 0.85, 1.0, 0.85)
		sb.set_corner_radius_all(6)
		sb.shadow_size = 6
		sb.shadow_color = Color(0, 0, 0, 0.35)
		card.add_theme_stylebox_override("panel", sb)
		card_styleboxes[comp_name] = sb
		
		# Conectar clic en botón SACAR de cada componente
		var btn_sacar: Button = comp_sacar_btns[comp_name]
		btn_sacar.pressed.connect(func(): _on_sacar_pressed(comp_name))
		
		# Permitir también hacer clic en el cuadro para interactuar/instalar
		card.gui_input.connect(func(event): _on_card_gui_input(comp_name, event))
	
	# Registrar botones del CPU
	btn_cpu_limpiar.pressed.connect(func(): _on_limpiar_pressed("CPU"))
	btn_cpu_pines.pressed.connect(func(): _on_pines_pressed("CPU"))
	comp_limpiar_btns["CPU"] = btn_cpu_limpiar
	comp_pines_btns["CPU"] = btn_cpu_pines
	
	# Estilos para botones de herramientas en las demás piezas
	var style_limpiar_normal = btn_cpu_limpiar.get_theme_stylebox("normal")
	var style_limpiar_hover = btn_cpu_limpiar.get_theme_stylebox("hover")
	var style_pines_normal = btn_cpu_pines.get_theme_stylebox("normal")
	var style_pines_hover = btn_cpu_pines.get_theme_stylebox("hover")
	
	var comp_limpiar_labels = {
		"RAM": "🧼 LIMPIAR CONTACTOS [5]",
		"Disco Duro": "🧼 LIMPIAR PUERTOS SATA [5]",
		"Grafica": "🧼 LIMPIAR DISIPADOR & FANS [5]",
		"Fuente": "🧼 LIMPIAR FILTRO / POLVO [5]",
		"Placa Madre": "🧼 LIMPIAR CHIPSET / PISTAS [5]",
		"Fan Cooler": "🧼 LIMPIAR ALETAS & ASPAS [5]"
	}

	var comp_pines_labels = {
		"RAM": "📍 SOLDAR PINES / PISTAS [3]",
		"Disco Duro": "📍 SOLDAR PINES SATA [3]",
		"Grafica": "📍 SOLDAR PINES PCIE [3]",
		"Fuente": "📍 SOLDAR CABLES / PINES [3]",
		"Placa Madre": "📍 SOLDAR SOCKET / PISTAS [3]",
		"Fan Cooler": "📍 SOLDAR CONECTOR PWM [3]"
	}
	
	for comp_name in comp_cards.keys():
		if comp_name == "CPU":
			continue
		var btn_sacar = comp_sacar_btns[comp_name]
		var parent_vbox = btn_sacar.get_parent()
		
		# Botón Limpiar [5]
		var btn_limpiar = Button.new()
		btn_limpiar.custom_minimum_size = Vector2(0, 30)
		btn_limpiar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn_limpiar.add_theme_font_size_override("font_size", 11)
		if style_limpiar_normal:
			btn_limpiar.add_theme_stylebox_override("normal", style_limpiar_normal)
		if style_limpiar_hover:
			btn_limpiar.add_theme_stylebox_override("hover", style_limpiar_hover)
		btn_limpiar.text = comp_limpiar_labels.get(comp_name, "🧼 LIMPIAR [5]")
		btn_limpiar.visible = false
		btn_limpiar.pressed.connect(func(): _on_limpiar_pressed(comp_name))
		parent_vbox.add_child(btn_limpiar)
		comp_limpiar_btns[comp_name] = btn_limpiar
		
		# Botón Pines / Soldar [3]
		var btn_pines = Button.new()
		btn_pines.custom_minimum_size = Vector2(0, 30)
		btn_pines.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn_pines.add_theme_font_size_override("font_size", 11)
		if style_pines_normal:
			btn_pines.add_theme_stylebox_override("normal", style_pines_normal)
		if style_pines_hover:
			btn_pines.add_theme_stylebox_override("hover", style_pines_hover)
		btn_pines.text = comp_pines_labels.get(comp_name, "📍 SOLDAR / PINES [3]")
		btn_pines.visible = false
		btn_pines.pressed.connect(func(): _on_pines_pressed(comp_name))
		parent_vbox.add_child(btn_pines)
		comp_pines_btns[comp_name] = btn_pines
	
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

func setup_pc(pc_node) -> void:
	current_pc = pc_node
	title_label.text = "DIAGNÓSTICO TÉCNICO: COMPUTADORA #%d" % current_pc.pc_id
	_refresh_ui()

# =============================================================================
# INTERACCIÓN CON TARJETAS Y ARRASTRE
# =============================================================================
func _on_card_gui_input(comp_name: String, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if selected_backpack_idx >= 0 and selected_backpack_idx < GameManager.backpack.size():
			_try_install_spare(selected_backpack_idx, comp_name)

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
			_apply_card_border_color(sb, st)

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

func _try_install_spare(backpack_idx: int, target_comp: String) -> void:
	if backpack_idx < 0 or backpack_idx >= GameManager.backpack.size():
		return
	var item = GameManager.backpack[backpack_idx]
	var item_name = item.get("name", "")
	var is_broken = item.get("broken", false)
	
	if is_broken:
		_show_feedback("❌ Esta pieza está dañada. Deséchala en la papelera del taller y toma un repuesto nuevo.", false)
		return
		
	if item_name != target_comp:
		_show_feedback("❌ Este repuesto es de [%s], pero intentas colocarlo en [%s]." % [item_name, target_comp], false)
		return
		
	selected_backpack_idx = -1
	_show_feedback("✓ ¡Repuesto de %s verificado! Iniciando montaje..." % target_comp, true)
	_open_minigame_by_name(target_comp, true)

# =============================================================================
# ACCIÓN DEL BOTÓN SACAR (DESMONTAJE)
# =============================================================================
func _on_sacar_pressed(comp_name: String) -> void:
	if current_pc == null:
		return
		
	var status = current_pc.components.get(comp_name, "ok")
	if status == "empty":
		_show_feedback("🎒 El slot de [%s] está vacío. Arrastra el repuesto nuevo desde tu mochila aquí para montarlo." % comp_name, false)
		return
		
	if comp_name == "CPU":
		_open_cpu_minigame(false)
	else:
		_open_minigame_by_name(comp_name, false)

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
		_show_feedback("⚠️ Necesitas seleccionar el Cautín [3] para realizar micro-soldadura.", false)
		return
	if current_pc == null:
		return
	var status = current_pc.components.get(comp_name, "ok")
	if status == "empty":
		_show_feedback("🎒 El slot de [%s] está vacío. No hay circuitos para soldar." % comp_name, false)
		return

	if comp_name == "CPU":
		_open_cpu_pines()
	else:
		GameManager.register_repair(50, 3.0)
		_show_feedback("✓ ¡Micro-soldadura con Cautín [3] en [%s] completada! Pines, pistas y conectores reparados." % comp_name, true)
		_refresh_ui()

func _open_cpu_limpiar() -> void:
	if not GameManager.is_cleaning_tool_equipped():
		_show_feedback("⚠️ Necesitas seleccionar el Limpiador [5] para limpiar y renovar pasta.", false)
		return
	modal_control.visible = false
	var minigame = cpupaste_minigame_scene.instantiate()
	minigame.set("is_tutorial_mode", false)
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
		_show_feedback("⚠️ Necesitas seleccionar el Cautín [3] para manipular los pines.", false)
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
			current_pc.update_3d_state()
			_show_feedback("✓ ¡CPU REPARADO AL 100%! Pasta térmica nueva y pines enderezados.", true)
		else:
			_show_feedback(msg, true)
	else:
		_show_feedback(msg, true)

# =============================================================================
# ACTUALIZACIÓN DE INTERFAZ Y ESTILOS
# =============================================================================
func _apply_card_border_color(sb: StyleBoxFlat, status: String) -> void:
	match status:
		"empty":
			sb.border_color = Color(1.0, 0.8, 0.1, 0.9)
		"fixed":
			sb.border_color = Color(0.0, 1.0, 0.55, 0.9)
		"broken":
			sb.border_color = Color(1.0, 0.25, 0.25, 0.9)
		_:
			sb.border_color = Color(0.15, 0.85, 1.0, 0.85)

func _refresh_ui() -> void:
	if current_pc == null or not ("components" in current_pc):
		return
		
	var comp_subtitles = {
		"RAM": "DDR5 16GB",
		"Disco Duro": "SATA SSD 1TB",
		"Grafica": "RTX 4070 OC",
		"Fuente": "850W GOLD",
		"Placa Madre": "CHIPSET Z790",
		"Fan Cooler": "DISIPADOR PWM",
		"CPU": "LGA 1700 OCTA-CORE"
	}
	
	for comp_name in comp_cards.keys():
		var status = current_pc.components.get(comp_name, "ok")
		var sb: StyleBoxFlat = card_styleboxes[comp_name]
		_apply_card_border_color(sb, status)
		
		var lbl: Label = comp_status_labels[comp_name]
		var sub = comp_subtitles.get(comp_name, "")
		var btn_sacar: Button = comp_sacar_btns[comp_name]
		
		match status:
			"empty":
				lbl.text = "%s\n[ SLOT VACÍO ]" % sub
				lbl.modulate = Color(1.0, 0.8, 0.1, 1.0)
				btn_sacar.text = "ARRASTRA REPUESTO"
				btn_sacar.disabled = true
				btn_sacar.modulate = Color(0.6, 0.6, 0.6, 0.5)
			"fixed":
				lbl.text = "%s\n[ REPARADO ✓ ]" % sub
				lbl.modulate = Color(0.0, 1.0, 0.55, 1.0)
				btn_sacar.text = "⬇ SACAR"
				btn_sacar.disabled = false
				btn_sacar.modulate = Color(1.0, 1.0, 1.0, 1.0)
			"broken":
				lbl.text = "%s\n[ AVERIADO ⚠️ ]" % sub
				lbl.modulate = Color(1.0, 0.35, 0.35, 1.0)
				btn_sacar.text = "⬇ SACAR"
				btn_sacar.disabled = false
				btn_sacar.modulate = Color(1.0, 0.35, 0.35, 1.0)
			_:
				lbl.text = "%s\n[ INSTALADO ]" % sub
				lbl.modulate = Color(0.15, 0.85, 1.0, 1.0)
				btn_sacar.text = "⬇ SACAR"
				btn_sacar.disabled = false
				btn_sacar.modulate = Color(1.0, 1.0, 1.0, 1.0)
				
		if comp_name == "CPU":
			match status:
				"empty":
					btn_sacar_cpu.disabled = true
					btn_sacar_cpu.text = "ARRASTRA CPU"
					btn_sacar_cpu.modulate = Color(0.6, 0.6, 0.6, 0.5)
				"fixed":
					btn_sacar_cpu.disabled = false
					btn_sacar_cpu.text = "⬇ SACAR"
					btn_sacar_cpu.modulate = Color(1.0, 1.0, 1.0, 1.0)
				_:
					btn_sacar_cpu.disabled = false
					btn_sacar_cpu.text = "⬇ SACAR"
					btn_sacar_cpu.modulate = Color(1.0, 0.4, 0.4, 1.0)

	# REGLA OBLIGATORIA PARA TODAS LAS PIEZAS:
	# Los botones de Cautín [3] y Limpiador [5] solo son visibles con su herramienta activa
	var is_cautin_equipped: bool = GameManager.is_soldering_tool_equipped()
	var is_cleaner_equipped: bool = GameManager.is_cleaning_tool_equipped()

	for comp_name in comp_cards.keys():
		var status = current_pc.components.get(comp_name, "ok")
		var is_empty = (status == "empty")
		
		if comp_limpiar_btns.has(comp_name):
			var btn_l: Button = comp_limpiar_btns[comp_name]
			btn_l.visible = is_cleaner_equipped
			btn_l.disabled = is_empty
			if is_empty:
				btn_l.modulate = Color(0.6, 0.6, 0.6, 0.5)
			else:
				btn_l.modulate = Color(1.0, 1.0, 1.0, 1.0)
				
		if comp_pines_btns.has(comp_name):
			var btn_p: Button = comp_pines_btns[comp_name]
			btn_p.visible = is_cautin_equipped
			btn_p.disabled = is_empty
			if is_empty:
				btn_p.modulate = Color(0.6, 0.6, 0.6, 0.5)
			else:
				btn_p.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	# Actualizar slots de mochila
	for i in range(slot_buttons.size()):
		var slot_btn = slot_buttons[i]
		if i < GameManager.backpack.size():
			var it = GameManager.backpack[i]
			var is_broken = it.get("broken", false)
			var item_name = it.get("name", "")
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
		if (idx + 1) == active_t:
			t_btn.modulate = Color(1.3, 1.3, 0.35, 1.0) # Seleccionado / brillante
		else:
			t_btn.modulate = Color(0.7, 0.7, 0.7, 0.75)
	
	var fixed_count = 0
	for comp in current_pc.components.keys():
		if current_pc.components[comp] == "fixed":
			fixed_count += 1

	var total_comps = current_pc.components.size()
	if current_pc.is_fully_repaired():
		pc_state_badge.text = "PC COMPLETAMENTE REPARADA · " + str(total_comps) + "/" + str(total_comps) + " PIEZAS TESTEADAS ✓"
		pc_state_badge.modulate = Color(0, 1, 0.5, 1)
		status_summary.text = "¡Diagnóstico y reparación exitosos! La máquina bootea al 100%."
		status_summary.modulate = Color(0, 1, 0.5, 1)
	else:
		pc_state_badge.text = "BANCO DE REPARACIÓN ACTIVO · [" + str(fixed_count) + "/" + str(total_comps) + " REPARADOS]"
		pc_state_badge.modulate = Color(1, 0.8, 0.1, 1)
		if selected_backpack_idx < 0:
			status_summary.text = "Presiona 'SACAR' para desmontar piezas averiadas, o arrastra repuestos de tu mochila para montarlos."
			status_summary.modulate = Color(0.2, 0.9, 1.0, 1)

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
		current_pc.update_3d_state()
	)
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		if success:
			if is_empty:
				current_pc.components["Fan Cooler"] = "fixed"
				current_pc.update_3d_state()
				GameManager.register_repair(100, 10.0)
				_show_feedback("✓ ¡Fan Cooler nuevo instalado y testeado!", true)
			else:
				_show_feedback("✓ Fan Cooler averiado retirado. Slot libre para repuesto.", true)
		_refresh_ui()
	)

func _open_ram_minigame(is_empty: bool) -> void:
	modal_control.visible = false
	var minigame = ram_minigame_scene.instantiate()
	minigame.start_as_empty_slot = is_empty
	minigame.set("is_tutorial_mode", false)
	get_tree().root.add_child(minigame)
	
	minigame.connect("old_part_extracted", func():
		current_pc.components["RAM"] = "empty"
		current_pc.update_3d_state()
	)
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		if success:
			if is_empty:
				current_pc.components["RAM"] = "fixed"
				current_pc.update_3d_state()
				GameManager.register_repair(100, 10.0)
				_show_feedback("✓ ¡Módulo RAM nuevo instalado y testeado!", true)
			else:
				_show_feedback("✓ Módulo RAM averiado retirado. Slot libre para repuesto.", true)
		_refresh_ui()
	)

func _open_hdd_minigame(is_empty: bool) -> void:
	modal_control.visible = false
	var minigame = hdd_minigame_scene.instantiate()
	minigame.start_as_empty_slot = is_empty
	minigame.set("is_tutorial_mode", false)
	if current_pc.saved_screw_type != "":
		minigame.screw_type = current_pc.saved_screw_type
	get_tree().root.add_child(minigame)
	
	minigame.connect("old_part_extracted", func():
		current_pc.components["Disco Duro"] = "empty"
		current_pc.saved_screw_type = minigame.screw_type
		current_pc.update_3d_state()
	)
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		if success:
			if is_empty:
				current_pc.components["Disco Duro"] = "fixed"
				current_pc.update_3d_state()
				GameManager.register_repair(100, 10.0)
				_show_feedback("✓ ¡Disco Duro nuevo instalado y testeado!", true)
			else:
				_show_feedback("✓ Disco Duro averiado retirado. Bahía libre para repuesto.", true)
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
		current_pc.update_3d_state()
	)
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		if success:
			if is_empty:
				current_pc.components["Grafica"] = "fixed"
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
		current_pc.update_3d_state()
	)
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		if success:
			if is_empty:
				current_pc.components["Fuente"] = "fixed"
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
		current_pc.update_3d_state()
	)
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		if success:
			if is_empty:
				current_pc.components["Placa Madre"] = "fixed"
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
		current_pc.update_3d_state()
	)
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if success:
			if is_empty:
				current_pc.components["CPU"] = "fixed"
				current_pc.update_3d_state()
				GameManager.register_repair(120, 12.0)
				_show_feedback("✓ ¡Procesador nuevo montado y asegurado!", true)
			else:
				_show_feedback("✓ CPU retirado. Socket listo para repuesto.", true)
		_refresh_ui()
	)

func _show_feedback(msg: String, is_positive: bool) -> void:
	status_summary.text = msg
	status_summary.modulate = Color(0, 1, 0.5, 1) if is_positive else Color(1, 0.2, 0.3, 1)

func _on_volver_pressed() -> void:
	inspection_closed.emit()
	queue_free()
