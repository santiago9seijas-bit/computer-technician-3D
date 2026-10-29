extends CanvasLayer

signal inspection_closed()

var current_pc = null
var cooler_minigame_scene: PackedScene = preload("res://scenes/minigames/FanCoolerMinigame.tscn")
var ram_minigame_scene: PackedScene = preload("res://scenes/minigames/RAMMinigame.tscn")
var hdd_minigame_scene: PackedScene = preload("res://scenes/minigames/HDDMinigame.tscn")
var gpu_minigame_scene: PackedScene = preload("res://scenes/minigames/GPUMinigame.tscn")
var psu_minigame_scene: PackedScene = preload("res://scenes/minigames/PSUMinigame.tscn")
var mobo_minigame_scene: PackedScene = preload("res://scenes/minigames/MotherboardMinigame.tscn")

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

@onready var btn_volver: Button = $ModalControl/Panel/VBox/Footer/BtnVolver

func _ready() -> void:
	layer = 10 # Prioridad por encima del HUD (layer 1)
	btn_volver.pressed.connect(_on_volver_pressed)
	
	btn_comp_ram.pressed.connect(_on_ram_clicked)
	btn_comp_hdd.pressed.connect(_on_hdd_clicked)
	btn_comp_cooler.pressed.connect(_on_cooler_clicked)
	btn_comp_gpu.pressed.connect(_on_gpu_clicked)
	btn_comp_psu.pressed.connect(_on_psu_clicked)
	btn_comp_mobo.pressed.connect(_on_mobo_clicked)

func setup_pc(pc_node) -> void:
	current_pc = pc_node
	title_label.text = "DIAGNÓSTICO TÉCNICO: COMPUTADORA #%d" % current_pc.pc_id
	_refresh_ui()

func _update_button_style(btn: Button, title: String, subtitle: String, status: String) -> void:
	match status:
		"empty":
			btn.text = "%s\n\n[ SLOT VACÍO ]\n▶ Clic para instalar repuesto" % title
			btn.modulate = Color(1.0, 0.85, 0.1, 1.0)
		"fixed":
			btn.text = "%s\n\n%s\n[ INSTALADO Y TESTEADO ✓ ]" % [title, subtitle]
			btn.modulate = Color(0.0, 1.0, 0.5, 1.0)
		_:
			btn.text = "%s\n\n%s\n[ INSTALADO ]" % [title, subtitle]
			btn.modulate = Color(0.15, 0.85, 1.0, 0.9)

func _refresh_ui() -> void:
	if current_pc == null:
		return
		
	var ram_status = current_pc.components.get("RAM", "ok")
	var hdd_status = current_pc.components.get("Disco Duro", "ok")
	var cooler_status = current_pc.components.get("Fan Cooler", "ok")
	var gpu_status = current_pc.components.get("Grafica", "ok")
	var psu_status = current_pc.components.get("Fuente", "ok")
	var mobo_status = current_pc.components.get("Placa Madre", "ok")
	
	_update_button_style(btn_comp_ram, "MEMORIA RAM", "DDR5 16GB", ram_status)
	_update_button_style(btn_comp_hdd, "DISCO DURO", "SATA SSD 1TB", hdd_status)
	_update_button_style(btn_comp_cooler, "FAN COOLER (CPU)", "DISIPADOR TÉRMICO PWM", cooler_status)
	_update_button_style(btn_comp_gpu, "TARJETA GRÁFICA", "RTX 4070 OC", gpu_status)
	_update_button_style(btn_comp_psu, "FUENTE DE PODER", "850W GOLD", psu_status)
	_update_button_style(btn_comp_mobo, "PLACA MADRE", "CHIPSET Z790", mobo_status)
	
	# Mostrar el reporte del cliente
	if current_pc.is_fully_repaired():
		pc_state_badge.text = "PC COMPLETAMENTE REPARADA · LISTA PARA ENTREGA ✓"
		pc_state_badge.modulate = Color(0, 1, 0.5, 1)
		status_summary.text = "¡Diagnóstico y reparación exitosos! La máquina bootea al 100%."
		status_summary.modulate = Color(0, 1, 0.5, 1)
	else:
		pc_state_badge.text = "FALLA ACTIVA · DEDUCE EL COMPONENTE"
		pc_state_badge.modulate = Color(1, 0.8, 0.1, 1)
		status_summary.text = current_pc.symptom_report
		status_summary.modulate = Color(1, 0.85, 0.2, 1)

# =============================================================================
# MANEJADORES DE CLIC POR COMPONENTE
# =============================================================================
func _on_cooler_clicked() -> void:
	if current_pc == null: return
	var status = current_pc.components.get("Fan Cooler", "ok")
	if status == "fixed":
		_show_feedback("El Fan Cooler ya fue cambiado y disipa térmicamente al 100%.", true)
		return
	if status == "empty" or current_pc.target_fault_component == "Fan Cooler":
		_open_cooler_minigame(status == "empty")
	else:
		GameManager.register_error(2.0)
		_show_feedback("❌ Diagnóstico incorrecto: El disipador gira a 2200 RPM y la CPU está a 38°C.", false)

func _open_cooler_minigame(is_empty: bool) -> void:
	modal_control.visible = false
	var minigame = cooler_minigame_scene.instantiate()
	minigame.start_as_empty_slot = is_empty
	get_tree().root.add_child(minigame)
	
	minigame.connect("old_part_extracted", func():
		current_pc.components["Fan Cooler"] = "empty"
		current_pc.update_3d_state()
	)
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		if success:
			current_pc.components["Fan Cooler"] = "fixed"
			current_pc.update_3d_state()
			GameManager.register_repair(100, 10.0)
		_refresh_ui()
	)

func _on_ram_clicked() -> void:
	if current_pc == null: return
	var status = current_pc.components.get("RAM", "ok")
	if status == "fixed":
		_show_feedback("La Memoria RAM ya fue cambiada y funciona sin errores.", true)
		return
	if status == "empty" or current_pc.target_fault_component == "RAM":
		_open_ram_minigame(status == "empty")
	else:
		GameManager.register_error(2.0)
		_show_feedback("❌ Diagnóstico incorrecto: La Memoria RAM pasó los tests de paridad. No causa este síntoma.", false)

func _open_ram_minigame(is_empty: bool) -> void:
	modal_control.visible = false
	var minigame = ram_minigame_scene.instantiate()
	minigame.start_as_empty_slot = is_empty
	get_tree().root.add_child(minigame)
	
	minigame.connect("old_part_extracted", func():
		current_pc.components["RAM"] = "empty"
		current_pc.update_3d_state()
	)
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		if success:
			current_pc.components["RAM"] = "fixed"
			current_pc.update_3d_state()
			GameManager.register_repair(100, 10.0)
		_refresh_ui()
	)

func _on_hdd_clicked() -> void:
	if current_pc == null: return
	var status = current_pc.components.get("Disco Duro", "ok")
	if status == "fixed":
		_show_feedback("El Disco Duro ya fue cambiado y funciona sin errores.", true)
		return
	if status == "empty" or current_pc.target_fault_component == "Disco Duro":
		_open_hdd_minigame(status == "empty")
	else:
		GameManager.register_error(2.0)
		_show_feedback("❌ Diagnóstico incorrecto: El Disco Duro responde al SMART al 100%. No causa este síntoma.", false)

func _open_hdd_minigame(is_empty: bool) -> void:
	modal_control.visible = false
	var minigame = hdd_minigame_scene.instantiate()
	minigame.start_as_empty_slot = is_empty
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
			current_pc.components["Disco Duro"] = "fixed"
			current_pc.update_3d_state()
			GameManager.register_repair(100, 10.0)
		_refresh_ui()
	)

func _on_gpu_clicked() -> void:
	if current_pc == null: return
	var status = current_pc.components.get("Grafica", "ok")
	if status == "fixed":
		_show_feedback("La Tarjeta Gráfica ya fue cambiada y renderiza a 144 FPS.", true)
		return
	if status == "empty" or current_pc.target_fault_component == "Grafica":
		_open_gpu_minigame(status == "empty")
	else:
		GameManager.register_error(2.0)
		_show_feedback("❌ Diagnóstico incorrecto: La GPU da video y sus voltajes PCIe son normales. No es la causa.", false)

func _open_gpu_minigame(is_empty: bool) -> void:
	modal_control.visible = false
	var minigame = gpu_minigame_scene.instantiate()
	minigame.start_as_empty_slot = is_empty
	get_tree().root.add_child(minigame)
	
	minigame.connect("old_part_extracted", func():
		current_pc.components["Grafica"] = "empty"
		current_pc.update_3d_state()
	)
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		if success:
			current_pc.components["Grafica"] = "fixed"
			current_pc.update_3d_state()
			GameManager.register_repair(100, 10.0)
		_refresh_ui()
	)

func _on_psu_clicked() -> void:
	if current_pc == null: return
	var status = current_pc.components.get("Fuente", "ok")
	if status == "fixed":
		_show_feedback("La Fuente de Poder ya fue cambiada y entrega 12V y 5V estables.", true)
		return
	if status == "empty" or current_pc.target_fault_component == "Fuente":
		_open_psu_minigame(status == "empty")
	else:
		GameManager.register_error(2.0)
		_show_feedback("❌ Diagnóstico incorrecto: La Fuente de Poder entrega voltajes estables. No es la causa.", false)

func _open_psu_minigame(is_empty: bool) -> void:
	modal_control.visible = false
	var minigame = psu_minigame_scene.instantiate()
	minigame.start_as_empty_slot = is_empty
	get_tree().root.add_child(minigame)
	
	minigame.connect("old_part_extracted", func():
		current_pc.components["Fuente"] = "empty"
		current_pc.update_3d_state()
	)
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		if success:
			current_pc.components["Fuente"] = "fixed"
			current_pc.update_3d_state()
			GameManager.register_repair(100, 10.0)
		_refresh_ui()
	)

func _on_mobo_clicked() -> void:
	if current_pc == null: return
	var status = current_pc.components.get("Placa Madre", "ok")
	if status == "fixed":
		_show_feedback("La Placa Madre ya fue cambiada y supera el POST sin errores.", true)
		return
	if status == "empty" or current_pc.target_fault_component == "Placa Madre":
		_open_mobo_minigame(status == "empty")
	else:
		GameManager.register_error(2.0)
		_show_feedback("❌ Diagnóstico incorrecto: La Placa Madre no tiene pistas cortadas ni capacitores hinchados.", false)

func _open_mobo_minigame(is_empty: bool) -> void:
	modal_control.visible = false
	var minigame = mobo_minigame_scene.instantiate()
	minigame.start_as_empty_slot = is_empty
	get_tree().root.add_child(minigame)
	
	minigame.connect("old_part_extracted", func():
		current_pc.components["Placa Madre"] = "empty"
		current_pc.update_3d_state()
	)
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		if success:
			current_pc.components["Placa Madre"] = "fixed"
			current_pc.update_3d_state()
			GameManager.register_repair(150, 15.0)
		_refresh_ui()
	)

func _show_feedback(msg: String, is_positive: bool) -> void:
	status_summary.text = msg
	status_summary.modulate = Color(0, 1, 0.5, 1) if is_positive else Color(1, 0.2, 0.3, 1)

func _on_volver_pressed() -> void:
	inspection_closed.emit()
	queue_free()
