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
var cpupins_minigame_scene: PackedScene = preload("res://scenes/minigames/CPUPinsMinigame.tscn")

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

# Mochila
@onready var slot_0: Button = $ModalControl/Panel/VBox/BackpackSection/BackpackSlots/Slot0
@onready var slot_1: Button = $ModalControl/Panel/VBox/BackpackSection/BackpackSlots/Slot1
@onready var slot_2: Button = $ModalControl/Panel/VBox/BackpackSection/BackpackSlots/Slot2

@onready var btn_volver: Button = $ModalControl/Panel/VBox/Footer/BtnVolver

var slot_buttons: Array[Button] = []
var comp_cards: Dictionary = {}
var comp_sacar_btns: Dictionary = {}
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
	
	# Botones extra del CPU
	btn_cpu_limpiar.pressed.connect(_open_cpu_limpiar)
	btn_cpu_pines.pressed.connect(_open_cpu_pines)
	
	# Mochila
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
		
	# Si hay un repuesto seleccionado de la mochila, intentar colocarlo
	if selected_backpack_idx >= 0 and selected_backpack_idx < GameManager.backpack.size():
		_try_install_spare(selected_backpack_idx, comp_name)
		return
		
	var status = current_pc.components.get(comp_name, "ok")
	if status == "empty":
		_show_feedback("🎒 El slot de [%s] está vacío. Toma un repuesto nuevo de la caja en la sala y arrástralo aquí." % comp_name, false)
		return
		
	if comp_name == "CPU":
		_on_cpu_sacar_pressed()
	else:
		_open_minigame_by_name(comp_name, false)

func _on_cpu_sacar_pressed() -> void:
	# El minijuego específico de sacar CPU se configurará según las especificaciones del usuario
	_show_feedback("🔧 Desmontaje de CPU preparado. Listo para la extracción del procesador.", true)

# =============================================================================
# BOTONES EXTRA DEL CPU: LIMPIAR Y PINES
# =============================================================================
func _open_cpu_limpiar() -> void:
	modal_control.visible = false
	var minigame = cpu_minigame_scene.instantiate()
	minigame.start_as_empty_slot = false
	minigame.set("is_tutorial_mode", false)
	get_tree().root.add_child(minigame)
	
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if success:
			GameManager.register_repair(60, 5.0)
			_show_feedback("✓ ¡Pasta térmica del procesador limpiada con éxito!", true)
		_refresh_ui()
	)

func _open_cpu_pines() -> void:
	modal_control.visible = false
	var minigame = cpupins_minigame_scene.instantiate()
	get_tree().root.add_child(minigame)
	
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if success:
			GameManager.register_repair(80, 5.0)
			_show_feedback("✓ ¡Pines del CPU alineados y corregidos a 90°!", true)
		_refresh_ui()
	)

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
	if current_pc == null:
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
				btn_sacar.text = "📦 MONTAR"
				btn_sacar.modulate = Color(1.0, 0.9, 0.2, 1.0)
			"fixed":
				lbl.text = "%s\n[ REPARADO ✓ ]" % sub
				lbl.modulate = Color(0.0, 1.0, 0.55, 1.0)
				btn_sacar.text = "⬇ SACAR"
				btn_sacar.modulate = Color(1.0, 1.0, 1.0, 1.0)
			"broken":
				lbl.text = "%s\n[ AVERIADO ⚠️ ]" % sub
				lbl.modulate = Color(1.0, 0.35, 0.35, 1.0)
				btn_sacar.text = "⬇ SACAR"
				btn_sacar.modulate = Color(1.0, 1.0, 1.0, 1.0)
			_:
				lbl.text = "%s\n[ INSTALADO ]" % sub
				lbl.modulate = Color(0.15, 0.85, 1.0, 1.0)
				btn_sacar.text = "⬇ SACAR"
				btn_sacar.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
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
