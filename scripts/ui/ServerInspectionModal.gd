extends CanvasLayer

signal inspection_closed()

var current_server = null

# Preloads de los 9 minijuegos de montaje de servidor
var mobo_minigame_scene: PackedScene = preload("res://scenes/minigames/MotherboardMinigame.tscn")
var psu_minigame_scene: PackedScene = preload("res://scenes/minigames/PSUMinigame.tscn")
var hdd_minigame_scene: PackedScene = preload("res://scenes/minigames/HDDMinigame.tscn")
var cooler_minigame_scene: PackedScene = preload("res://scenes/minigames/FanCoolerMinigame.tscn")
var liquid_minigame_scene: PackedScene = preload("res://scenes/minigames/LiquidCoolingMinigame.tscn")
var ram_minigame_scene: PackedScene = preload("res://scenes/minigames/RAMMinigame.tscn")
var cpu_minigame_scene: PackedScene = preload("res://scenes/minigames/CPUMinigame.tscn")
var gpu_minigame_scene: PackedScene = preload("res://scenes/minigames/GPUMinigame.tscn")
var debugger_minigame_scene: PackedScene = preload("res://scenes/minigames/CodeDebuggerMinigame.tscn")

@onready var modal_control: Control = $ModalControl
@onready var title_label: Label = $ModalControl/Panel/VBox/Header/TitleLabel
@onready var status_summary: Label = $ModalControl/Panel/VBox/Header/StatusSummary
@onready var server_state_badge: Label = $ModalControl/Panel/VBox/Header/BadgeLabel

# Botones de los 9 componentes de servidor (Grid 3x3)
@onready var btn_lvl_1: Button = $ModalControl/Panel/VBox/GridContainer/BtnLvl1
@onready var btn_lvl_2: Button = $ModalControl/Panel/VBox/GridContainer/BtnLvl2
@onready var btn_lvl_3: Button = $ModalControl/Panel/VBox/GridContainer/BtnLvl3
@onready var btn_lvl_4: Button = $ModalControl/Panel/VBox/GridContainer/BtnLvl4
@onready var btn_lvl_5: Button = $ModalControl/Panel/VBox/GridContainer/BtnLvl5
@onready var btn_lvl_6: Button = $ModalControl/Panel/VBox/GridContainer/BtnLvl6
@onready var btn_lvl_7: Button = $ModalControl/Panel/VBox/GridContainer/BtnLvl7
@onready var btn_lvl_8: Button = $ModalControl/Panel/VBox/GridContainer/BtnLvl8
@onready var btn_lvl_9: Button = $ModalControl/Panel/VBox/GridContainer/BtnLvl9

# Mochila técnica
@onready var slot_0: Button = $ModalControl/Panel/VBox/BackpackSection/BackpackSlots/Slot0
@onready var slot_1: Button = $ModalControl/Panel/VBox/BackpackSection/BackpackSlots/Slot1
@onready var slot_2: Button = $ModalControl/Panel/VBox/BackpackSection/BackpackSlots/Slot2

@onready var btn_volver: Button = $ModalControl/Panel/VBox/Footer/BtnVolver
@onready var feedback_label: Label = $ModalControl/Panel/VBox/FeedbackLabel

var slot_buttons: Array[Button] = []
var selected_backpack_idx: int = -1
var is_dragging_part: bool = false
var dragged_backpack_idx: int = -1
var drag_preview: PanelContainer = null

var current_minigame_instance: Node = null
var active_repair_component: String = ""

const TOTAL_RAMS_REQUIRED: int = 3
const TOTAL_HDDS_REQUIRED: int = 3

func _ready() -> void:
	layer = 10
	btn_volver.pressed.connect(_on_volver_pressed)
	
	btn_lvl_1.pressed.connect(func(): _launch_single_mounting("Bastidores & Rieles 2U", mobo_minigame_scene))
	btn_lvl_2.pressed.connect(func(): _launch_single_mounting("Fuentes 1+1 Hot-Swap", psu_minigame_scene))
	btn_lvl_3.pressed.connect(_on_hdd_level_pressed)
	btn_lvl_4.pressed.connect(func(): _launch_single_mounting("Fan Wall de Turbinas", cooler_minigame_scene))
	btn_lvl_5.pressed.connect(_on_liquid_cooling_pressed)
	btn_lvl_6.pressed.connect(_on_ram_level_pressed)
	btn_lvl_7.pressed.connect(_on_server_cpu_pressed)
	btn_lvl_8.pressed.connect(func(): _launch_single_mounting("Riser PCIe / SmartNIC", gpu_minigame_scene))
	btn_lvl_9.pressed.connect(func(): _launch_single_mounting("Terminal & Scripting", debugger_minigame_scene))
	
	slot_buttons = [slot_0, slot_1, slot_2]
	for i in range(slot_buttons.size()):
		var slot_btn = slot_buttons[i]
		slot_btn.gui_input.connect(func(event): _on_slot_gui_input(i, event))
		slot_btn.pressed.connect(func(): _on_slot_clicked(i))
		
	GameManager.backpack_updated.connect(func(_b): _refresh_ui())
	
	if current_server != null:
		_refresh_ui()

func _input(event: InputEvent) -> void:
	if is_dragging_part:
		if event is InputEventMouseMotion:
			_update_drag_preview_pos(event.global_position)
		elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_finish_drag(event.global_position)

func _unhandled_input(event: InputEvent) -> void:
	if not modal_control or not modal_control.visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		_on_volver_pressed()

func setup_server(server_ref) -> void:
	current_server = server_ref
	if is_inside_tree() and server_state_badge != null:
		_refresh_ui()

func _refresh_ui() -> void:
	if not is_inside_tree() or current_server == null or server_state_badge == null:
		return
		
	if title_label and current_server:
		title_label.text = "TORRE DE SERVIDOR // RACK EMPRESARIAL #%d (ÁREA DE SERVIDORES)" % current_server.server_id
		
	# Comprobar si el jugador tiene el kit de refrigeración líquida en la mochila
	var has_liquid_kit = false
	for it in GameManager.backpack:
		var n = it.get("name", "")
		if (n == "Refrigeracion Liquida" or n == "Kit Refrigeracion") and not it.get("broken", true):
			has_liquid_kit = true
			break
		
	var st1 = current_server.components.get("Bastidores & Rieles 2U", "broken")
	var st2 = current_server.components.get("Fuentes 1+1 Hot-Swap", "broken")
	var st3 = current_server.components.get("Caddies SAS & RAID (3 Discos)", "broken")
	var st4 = current_server.components.get("Fan Wall de Turbinas", "broken")
	var st5 = current_server.components.get("Loop Líquido Rack", "broken")
	var st6 = current_server.components.get("Bancos RAM ECC (3 Módulos)", "broken")
	var st7 = current_server.components.get("Dual CPU Enterprise", "broken")
	var st8 = current_server.components.get("Riser PCIe / SmartNIC", "broken")
	var st9 = current_server.components.get("Terminal & Scripting", "broken")
	
	_update_btn_style(btn_lvl_1, "BASTIDORES & RIELES 2U", "MONTAJE CHASIS 19\" EN RACK", st1)
	_update_btn_style(btn_lvl_2, "FUENTES 1+1 HOT-SWAP", "INSTALAR FUENTE 1200W PLATINUM", st2)
	_update_btn_style(btn_lvl_3, "CADDIES SAS & RAID (3 DISCOS)", "MONTAR 3 DISCOS SAS EN CALIENTE", st3)
	_update_btn_style(btn_lvl_4, "FAN WALL DE TURBINAS", "INSTALAR MÓDULO EN TÚNEL DE AIRE", st4)
	
	# El cuadro de refrigeración líquida solo aparece si el jugador tiene el kit o si ya está instalado
	if st5 == "fixed":
		btn_lvl_5.visible = true
		_update_btn_style(btn_lvl_5, "LOOP LÍQUIDO RACK", "INSTALADO & OPERATIVO", "fixed")
	else:
		btn_lvl_5.visible = has_liquid_kit
		if has_liquid_kit:
			btn_lvl_5.text = "⚡ LOOP LÍQUIDO RACK [CUADRO VACÍO]\n[ARRASTRA EL KIT DE REFRIGERACIÓN AQUÍ]"
			btn_lvl_5.modulate = Color(0.1, 1.0, 0.7, 1.0)
			
	_update_btn_style(btn_lvl_6, "BANCOS RAM ECC (3 MÓDULOS)", "COLOCAR 3 BANCOS RAM DDR5", st6)
	_update_btn_style(btn_lvl_7, "DUAL CPU ENTERPRISE", "COLOCAR CPU EN SOCKET INDUSTRIAL", st7)
	_update_btn_style(btn_lvl_8, "RISER PCIE / SMARTNIC", "INSTALAR TARJETA DE RED 100GBE", st8)
	_update_btn_style(btn_lvl_9, "TERMINAL & SCRIPTING", "DEPURAR SCRIPTS DE RED Y FIREWALL", st9)
	
	# Actualizar slots de mochila
	for i in range(slot_buttons.size()):
		var slot_btn = slot_buttons[i]
		if i < GameManager.backpack.size():
			var it = GameManager.backpack[i]
			var item_name = it.get("name", "")
			var is_selected = (i == selected_backpack_idx)
			if is_selected:
				slot_btn.text = "Slot %d: [ SELECCIONADO ]\n⚡ %s" % [i + 1, item_name]
				slot_btn.modulate = Color(1.5, 1.4, 0.2, 1.0)
			else:
				slot_btn.text = "Slot %d: 📦 %s\n(Arrastra al cuadro)" % [i + 1, item_name]
				slot_btn.modulate = Color(0.2, 0.95, 1.0, 1.0)
		else:
			slot_btn.text = "Slot %d: [ VACÍO ]" % [i + 1]
			slot_btn.modulate = Color(0.5, 0.5, 0.6, 0.6)
	
	var fixed_count = 0
	for k in current_server.components.keys():
		if current_server.components[k] == "fixed":
			fixed_count += 1
			
	if current_server.is_fully_repaired():
		server_state_badge.text = "¡TORRE DE SERVIDOR 100% OPERATIVA · TODOS LOS SUBSISTEMAS MONTADOS! ✓"
		server_state_badge.modulate = Color(0.2, 1.0, 0.4)
		status_summary.text = "TELEMETRÍA ÓPTIMA · 3 DISCOS SAS Y 3 BANCOS RAM OPERATIVOS · SIN ERRORES"
		status_summary.modulate = Color(0.2, 1.0, 0.4)
	else:
		server_state_badge.text = "ESTADO: EN MONTAJE TÉCNICO (%d/9 SUBSISTEMAS MONTADOS)" % fixed_count
		server_state_badge.modulate = Color(1.0, 0.3, 0.45)
		
		if st5 != "fixed" and not has_liquid_kit:
			status_summary.text = "⚠️ EL CUADRO DE REFRIGERACIÓN LÍQUIDA ESTÁ OCULTO: Sal al datacenter y recoge el Kit de la caja con [E] para habilitar el cuadro vacío."
			status_summary.modulate = Color(1.0, 0.85, 0.2, 1.0)
		elif st5 != "fixed" and has_liquid_kit:
			status_summary.text = "✓ ¡Kit de Refrigeración listo en mochila! Arrastra el kit sobre el cuadro vacío para montar el loop."
			status_summary.modulate = Color(0.2, 1.0, 0.5, 1.0)
		else:
			status_summary.text = "TODOS LOS MINIJUEGOS SON EXCLUSIVOS DE MONTAJE (SOLO PONER PIEZAS NUEVAS · 3 RAMS Y 3 DISCOS)"
			status_summary.modulate = Color(0.85, 0.85, 0.9)

func _update_btn_style(btn: Button, main_title: String, subtitle: String, status: String) -> void:
	if btn == null:
		return
	if status == "fixed":
		btn.text = "✓ %s\n[%s · INSTALADO]" % [main_title, subtitle]
		btn.modulate = Color(0.3, 1.0, 0.5)
	else:
		btn.text = "⚡ %s\n[%s · PONER PIEZA]" % [main_title, subtitle]
		btn.modulate = Color(1.0, 0.92, 0.92)

# =============================================================================
# ARRASTRE DE REPUESTOS DESDE LA MOCHILA AL CUADRO
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

func _on_slot_clicked(idx: int) -> void:
	if idx >= GameManager.backpack.size():
		selected_backpack_idx = -1
		_show_feedback("Este slot de la mochila está vacío.", Color(0.7, 0.7, 0.7))
		_refresh_ui()
		return
		
	var it = GameManager.backpack[idx]
	selected_backpack_idx = idx
	_show_feedback("👉 Repuesto [%s] seleccionado. Arrástralo hacia su cuadro para montarlo." % it.get("name", ""), Color(0.2, 1.0, 0.5))
	_refresh_ui()

func _create_drag_preview(item_name: String) -> void:
	if is_instance_valid(drag_preview):
		drag_preview.queue_free()
		
	drag_preview = PanelContainer.new()
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.z_index = 100
	
	var lbl = Label.new()
	lbl.text = "📦 REPUESTO: " + item_name + "\n(Suelta sobre el cuadro vacío para montar)"
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

func _finish_drag(drop_pos: Vector2) -> void:
	var item_idx = dragged_backpack_idx
	is_dragging_part = false
	dragged_backpack_idx = -1
	
	if is_instance_valid(drag_preview):
		drag_preview.queue_free()
		drag_preview = null
		
	if item_idx >= 0 and item_idx < GameManager.backpack.size():
		var item = GameManager.backpack[item_idx]
		var item_name = item.get("name", "")
		if btn_lvl_5.visible and btn_lvl_5.get_global_rect().has_point(drop_pos):
			if item_name == "Refrigeracion Liquida" or item_name == "Kit Refrigeracion":
				_on_liquid_cooling_pressed()
				return
			else:
				_show_feedback("❌ Solo puedes colocar el Kit de Refrigeración Líquida en este cuadro.", Color(1.0, 0.35, 0.35))
				return
				
	_refresh_ui()

# =============================================================================
# LANZADORES DE MINIJUEGOS (SOLO PONER / MONTAJE DIRECTO SIN QUITAR)
# =============================================================================

func _launch_single_mounting(comp_name: String, scene_to_launch: PackedScene) -> void:
	if not scene_to_launch:
		return
		
	if current_server and current_server.components.get(comp_name, "") == "fixed":
		_show_feedback("✓ %s ya está montado y asegurado." % comp_name, Color(0.2, 1.0, 0.4))
		return
		
	active_repair_component = comp_name
	
	# Asegurar destornillador de Cruz [1] por defecto para facilitar el armado
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("select_tool"):
		gm.select_tool(1)
		
	var minigame = scene_to_launch.instantiate()
	# Forzar modo de SOLO PONER pieza (start_as_empty_slot)
	if "start_as_empty_slot" in minigame:
		minigame.start_as_empty_slot = true
		
	current_minigame_instance = minigame
	modal_control.visible = false
	add_child(minigame)
	
	if minigame.has_signal("minigame_finished"):
		minigame.minigame_finished.connect(_on_single_mounting_finished)
	elif minigame.has_signal("tree_exited"):
		minigame.tree_exited.connect(func(): _on_single_mounting_finished(true))

func _on_single_mounting_finished(success: bool) -> void:
	if is_instance_valid(current_minigame_instance):
		current_minigame_instance.queue_free()
		current_minigame_instance = null
		
	modal_control.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if success:
		if active_repair_component == "Loop Líquido Rack":
			for i in range(GameManager.backpack.size()):
				var n = GameManager.backpack[i].get("name", "")
				if n == "Refrigeracion Liquida" or n == "Kit Refrigeracion":
					GameManager.remove_item_from_backpack(i)
					break
					
		if current_server and active_repair_component != "":
			current_server.components[active_repair_component] = "fixed"
			current_server.update_3d_state()
			
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("add_score"):
			gm.add_score(150, 5.0)
			
		_show_feedback("✓ %s MONTADO Y ASEGURADO CON ÉXITO (+150 PTS)" % active_repair_component, Color(0.2, 1.0, 0.4))
	else:
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("register_error"):
			gm.register_error(3.0)
		_show_feedback("⚠️ ERROR DE MONTAJE EN %s (-3s)" % active_repair_component, Color(1.0, 0.25, 0.35))
		
	_refresh_ui()

# =============================================================================
# REFRIGERACIÓN LÍQUIDA: ARRASTRAR O CLIC AL KIT SOBRE EL CUADRO VACÍO
# =============================================================================
func _on_liquid_cooling_pressed() -> void:
	if current_server and current_server.components.get("Loop Líquido Rack", "") == "fixed":
		_show_feedback("✓ El Loop Líquido del rack ya se encuentra completamente purgado y operativo.", Color(0.2, 1.0, 0.4))
		return
		
	var has_kit = false
	for it in GameManager.backpack:
		var n = it.get("name", "")
		if (n == "Refrigeracion Liquida" or n == "Kit Refrigeracion") and not it.get("broken", true):
			has_kit = true
			break
			
	if not has_kit:
		_show_feedback("⚠️ REQUIERES EL KIT DE REFRIGERACIÓN: Sal de la torre y recógelo de la caja de repuestos en la sala (presiona [E]).", Color(1.0, 0.35, 0.35))
		return
		
	_launch_single_mounting("Loop Líquido Rack", liquid_minigame_scene)

# =============================================================================
# MONTAJE ESPECIAL: 3 MÓDULOS DE RAM ECC EN EL MISMO MINIJUEGO
# =============================================================================
func _on_ram_level_pressed() -> void:
	if current_server and current_server.components.get("Bancos RAM ECC (3 Módulos)", "") == "fixed":
		_show_feedback("✓ Los 3 Bancos de RAM ECC ya están montados y funcionando.", Color(0.2, 1.0, 0.4))
		return
		
	active_repair_component = "Bancos RAM ECC (3 Módulos)"
	_ensure_backpack_item("RAM")
	
	var minigame = ram_minigame_scene.instantiate()
	minigame.start_as_empty_slot = true
	minigame.target_ram_count = 3
	current_minigame_instance = minigame
	
	modal_control.visible = false
	add_child(minigame)
	
	minigame.minigame_finished.connect(func(success: bool):
		if is_instance_valid(current_minigame_instance):
			current_minigame_instance.queue_free()
			current_minigame_instance = null
			
		modal_control.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		if success:
			if current_server:
				current_server.components["Bancos RAM ECC (3 Módulos)"] = "fixed"
				current_server.update_3d_state()
			var gm = get_node_or_null("/root/GameManager")
			if gm and gm.has_method("add_score"):
				gm.add_score(150, 15.0)
			_show_feedback("✓ ¡LOS 3 MÓDULOS DE RAM ECC QUEDARON COMPLETAMENTE MONTADOS! (+150 PTS)", Color(0.2, 1.0, 0.4))
		else:
			var gm = get_node_or_null("/root/GameManager")
			if gm and gm.has_method("register_error"):
				gm.register_error(3.0)
			_show_feedback("⚠️ Montaje de RAM cancelado.", Color(1.0, 0.35, 0.35))
			
		_refresh_ui()
	)

# =============================================================================
# MONTAJE ESPECIAL: 3 DISCOS DUROS SAS CADDIES EN EL MISMO MINIJUEGO
# =============================================================================
func _on_hdd_level_pressed() -> void:
	if current_server and current_server.components.get("Caddies SAS & RAID (3 Discos)", "") == "fixed":
		_show_feedback("✓ Los 3 Discos SAS Caddies ya están montados en el arreglo RAID.", Color(0.2, 1.0, 0.4))
		return
		
	active_repair_component = "Caddies SAS & RAID (3 Discos)"
	_ensure_backpack_item("Disco Duro")
	
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("select_tool"):
		gm.select_tool(1)
		
	var minigame = hdd_minigame_scene.instantiate()
	minigame.start_as_empty_slot = true
	minigame.target_hdd_count = 3
	current_minigame_instance = minigame
	
	modal_control.visible = false
	add_child(minigame)
	
	minigame.minigame_finished.connect(func(success: bool):
		if is_instance_valid(current_minigame_instance):
			current_minigame_instance.queue_free()
			current_minigame_instance = null
			
		modal_control.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		if success:
			if current_server:
				current_server.components["Caddies SAS & RAID (3 Discos)"] = "fixed"
				current_server.update_3d_state()
			var gm_s = get_node_or_null("/root/GameManager")
			if gm_s and gm_s.has_method("add_score"):
				gm_s.add_score(150, 15.0)
			_show_feedback("✓ ¡LOS 3 DISCOS SAS QUEDARON MONTADOS Y FIJADOS EN RAID! (+150 PTS)", Color(0.2, 1.0, 0.4))
		else:
			var gm_e = get_node_or_null("/root/GameManager")
			if gm_e and gm_e.has_method("register_error"):
				gm_e.register_error(3.0)
			_show_feedback("⚠️ Montaje de Discos SAS cancelado.", Color(1.0, 0.35, 0.35))
			
		_refresh_ui()
	)

# =============================================================================
# MONTAJE ESPECIAL: DUAL CPU ENTERPRISE CON SECUENCIA DE TORNILLOS (3 -> 1 -> 2)
# =============================================================================
func _on_server_cpu_pressed() -> void:
	if current_server and current_server.components.get("Dual CPU Enterprise", "") == "fixed":
		_show_feedback("✓ Dual CPU Enterprise ya está montado y asegurado.", Color(0.2, 1.0, 0.4))
		return
		
	active_repair_component = "Dual CPU Enterprise"
	_ensure_backpack_item("CPU")
	
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("select_tool"):
		gm.select_tool(1)
		
	var minigame = cpu_minigame_scene.instantiate()
	minigame.start_as_empty_slot = true
	minigame.require_screws_sequence = true
	current_minigame_instance = minigame
	
	modal_control.visible = false
	add_child(minigame)
	
	minigame.minigame_finished.connect(_on_single_mounting_finished)

# Asegura que haya repuestos funcionales en la mochila para montaje directo
func _ensure_backpack_item(item_name: String) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return
	var found = false
	for it in gm.backpack:
		if (it.get("name") == item_name or it.get("type") == item_name) and not it.get("broken", true):
			found = true
			break
	if not found:
		if gm.backpack.size() >= gm.MAX_BACKPACK_SLOTS:
			gm.backpack.pop_back()
		gm.backpack.append({"name": item_name, "type": item_name, "broken": false, "functional": true})
		gm.backpack_updated.emit(gm.backpack)

func _show_feedback(msg: String, col: Color) -> void:
	if feedback_label:
		feedback_label.text = msg
		feedback_label.modulate = col
		var tw = create_tween()
		tw.tween_property(feedback_label, "modulate:a", 1.0, 0.1)
		tw.tween_interval(3.0)
		tw.tween_property(feedback_label, "modulate:a", 0.0, 0.6)

func _on_volver_pressed() -> void:
	if current_server and current_server.get("is_completed"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	inspection_closed.emit()
	queue_free()
