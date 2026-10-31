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

@onready var modal_control: Control = $ModalControl
@onready var title_label: Label = $ModalControl/Panel/VBox/Header/TitleLabel
@onready var status_summary: Label = $ModalControl/Panel/VBox/Header/StatusSummary
@onready var pc_state_badge: Label = $ModalControl/Panel/VBox/Header/BadgeLabel

@onready var btn_comp_ram: Button = $ModalControl/Panel/VBox/GridContainer/BtnRAM
@onready var btn_comp_hdd: Button = $ModalControl/Panel/VBox/GridContainer/BtnHDD
@onready var btn_comp_cooler: Button = $ModalControl/Panel/VBox/GridContainer/BtnCooler
@onready var btn_comp_gpu: Button = $ModalControl/Panel/VBox/GridContainer/BtnGPU
@onready var btn_comp_psu: Button = $ModalControl/Panel/VBox/GridContainer/BtnPSU
@onready var btn_comp_mobo: Button = $ModalControl/Panel/VBox/GridContainer/BtnMOBO
@onready var btn_comp_cpu: Button = $ModalControl/Panel/VBox/GridContainer/BtnCPU

@onready var slot_0: Button = $ModalControl/Panel/VBox/BackpackSection/BackpackSlots/Slot0
@onready var slot_1: Button = $ModalControl/Panel/VBox/BackpackSection/BackpackSlots/Slot1
@onready var slot_2: Button = $ModalControl/Panel/VBox/BackpackSection/BackpackSlots/Slot2

@onready var btn_volver: Button = $ModalControl/Panel/VBox/Footer/BtnVolver

var slot_buttons: Array[Button] = []
var comp_buttons: Dictionary = {}

# Estado de arrastre y selección de repuestos
var selected_backpack_idx: int = -1
var is_dragging_part: bool = false
var dragged_backpack_idx: int = -1
var drag_preview: PanelContainer = null

func _ready() -> void:
	layer = 10 # Prioridad por encima del HUD
	btn_volver.pressed.connect(_on_volver_pressed)
	
	comp_buttons = {
		btn_comp_ram: "RAM",
		btn_comp_hdd: "Disco Duro",
		btn_comp_cooler: "Fan Cooler",
		btn_comp_gpu: "Grafica",
		btn_comp_psu: "Fuente",
		btn_comp_mobo: "Placa Madre",
		btn_comp_cpu: "CPU"
	}
	
	btn_comp_ram.pressed.connect(func(): _handle_component_interaction("RAM"))
	btn_comp_hdd.pressed.connect(func(): _handle_component_interaction("Disco Duro"))
	btn_comp_cooler.pressed.connect(func(): _handle_component_interaction("Fan Cooler"))
	btn_comp_gpu.pressed.connect(func(): _handle_component_interaction("Grafica"))
	btn_comp_psu.pressed.connect(func(): _handle_component_interaction("Fuente"))
	btn_comp_mobo.pressed.connect(func(): _handle_component_interaction("Placa Madre"))
	btn_comp_cpu.pressed.connect(func(): _handle_component_interaction("CPU"))
	
	slot_buttons = [slot_0, slot_1, slot_2]
	for i in range(slot_buttons.size()):
		var slot_btn = slot_buttons[i]
		slot_btn.gui_input.connect(func(event): _on_slot_gui_input(i, event))
		slot_btn.pressed.connect(func(): _on_slot_clicked(i))
		
	GameManager.backpack_updated.connect(func(_b): _refresh_ui())

func setup_pc(pc_node) -> void:
	current_pc = pc_node
	title_label.text = "DIAGNÓSTICO TÉCNICO: COMPUTADORA #%d" % current_pc.pc_id
	_refresh_ui()

# =============================================================================
# ARRASTRE Y SOLTADO DE REPUESTOS DESDE LA MOCHILA
# =============================================================================
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

func _create_drag_preview(item_name: String) -> void:
	if is_instance_valid(drag_preview):
		drag_preview.queue_free()
		
	drag_preview = PanelContainer.new()
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.z_index = 100
	
	var lbl = Label.new()
	lbl.text = "📦 REPUESTO: " + item_name + "\n(Suelta sobre la pieza para montar)"
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
	for btn in comp_buttons.keys():
		if btn.get_global_rect().has_point(mouse_pos):
			btn.modulate = Color(1.5, 1.4, 0.2, 1.0)
		else:
			var comp_name = comp_buttons[btn]
			var st = current_pc.components.get(comp_name, "ok") if current_pc else "ok"
			_apply_button_color(btn, st)

func _finish_drag(drop_pos: Vector2) -> void:
	var dropped_comp_name = ""
	for btn in comp_buttons.keys():
		if btn.get_global_rect().has_point(drop_pos):
			dropped_comp_name = comp_buttons[btn]
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
	_show_feedback("👉 Repuesto [%s] seleccionado. Haz clic en el componente de la PC o arrástralo para instalarlo." % it.get("name", ""), true)
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

func _handle_component_interaction(comp_name: String) -> void:
	if current_pc == null: return
	
	# Si hay un repuesto seleccionado de la mochila, intentar colocarlo
	if selected_backpack_idx >= 0 and selected_backpack_idx < GameManager.backpack.size():
		_try_install_spare(selected_backpack_idx, comp_name)
		return
		
	var status = current_pc.components.get(comp_name, "ok")
	if status == "empty":
		_show_feedback("🎒 El slot de [%s] está vacío. Toma un repuesto nuevo de la caja en la sala y arrástralo aquí." % comp_name, false)
	else:
		# Pieza instalada (averiada o testeada) -> Modo Desmontaje (Quitar)
		_open_minigame_by_name(comp_name, false)

func _apply_button_color(btn: Button, status: String) -> void:
	match status:
		"empty":
			btn.modulate = Color(1.0, 0.85, 0.1, 1.0)
		"fixed":
			btn.modulate = Color(0.0, 1.0, 0.5, 1.0)
		"broken":
			btn.modulate = Color(1.0, 0.45, 0.35, 1.0)
		_:
			btn.modulate = Color(0.15, 0.85, 1.0, 0.9)

func _update_button_style(btn: Button, title: String, subtitle: String, status: String) -> void:
	match status:
		"empty":
			btn.text = "%s\n\n[ SLOT VACÍO ]\n▶ Arrastra aquí el repuesto" % title
		"fixed":
			btn.text = "%s\n\n%s\n[ INSTALADO Y TESTEADO ✓ ]\n▶ Clic para desmontar" % [title, subtitle]
		"broken":
			btn.text = "%s\n\n%s\n[ PIEZA DAÑADA ⚠️ ]\n▶ Clic para desmontar\n(o arrastra repuesto para montar)" % [title, subtitle]
		_:
			btn.text = "%s\n\n%s\n[ INSTALADO ]\n▶ Clic para desmontar" % [title, subtitle]
	_apply_button_color(btn, status)

func _refresh_ui() -> void:
	if current_pc == null:
		return
		
	var ram_status = current_pc.components.get("RAM", "ok")
	var hdd_status = current_pc.components.get("Disco Duro", "ok")
	var cooler_status = current_pc.components.get("Fan Cooler", "ok")
	var gpu_status = current_pc.components.get("Grafica", "ok")
	var psu_status = current_pc.components.get("Fuente", "ok")
	var mobo_status = current_pc.components.get("Placa Madre", "ok")
	var cpu_status = current_pc.components.get("CPU", "ok")
	
	_update_button_style(btn_comp_ram, "MEMORIA RAM", "DDR5 16GB", ram_status)
	_update_button_style(btn_comp_hdd, "DISCO DURO", "SATA SSD 1TB", hdd_status)
	_update_button_style(btn_comp_cooler, "FAN COOLER (CPU)", "DISIPADOR PWM", cooler_status)
	_update_button_style(btn_comp_gpu, "TARJETA GRÁFICA", "RTX 4070 OC", gpu_status)
	_update_button_style(btn_comp_psu, "FUENTE DE PODER", "850W GOLD", psu_status)
	_update_button_style(btn_comp_mobo, "PLACA MADRE", "CHIPSET Z790", mobo_status)
	_update_button_style(btn_comp_cpu, "PROCESADOR (CPU)", "LGA 1700 OCTA-CORE", cpu_status)
	
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
					slot_btn.text = "Slot %d: [ SELECCIONADO ]\n⚡ %s (Clic en componente)" % [i + 1, item_name]
					slot_btn.modulate = Color(1.5, 1.4, 0.2, 1.0)
				else:
					slot_btn.text = "Slot %d: [ REPUESTO NUEVO ]\n⚡ %s (Arrastra a la PC)" % [i + 1, item_name]
					slot_btn.modulate = Color(0.2, 1.0, 0.6, 1.0)
		else:
			slot_btn.text = "Slot %d: [ VACÍO ]\n(Busca repuestos en sala)" % (i + 1)
			slot_btn.modulate = Color(0.5, 0.5, 0.5, 0.5)
	
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
			status_summary.text = "Arrastra un repuesto de tu mochila al componente dañado para montarlo, o haz clic para desmontar."
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
				_show_feedback("✓ ¡Procesador nuevo instalado y testeado!", true)
			else:
				_show_feedback("✓ CPU averiado retirado. Socket listo para repuesto.", true)
		_refresh_ui()
	)

func _show_feedback(msg: String, is_positive: bool) -> void:
	status_summary.text = msg
	status_summary.modulate = Color(0, 1, 0.5, 1) if is_positive else Color(1, 0.2, 0.3, 1)

func _on_volver_pressed() -> void:
	inspection_closed.emit()
	queue_free()
