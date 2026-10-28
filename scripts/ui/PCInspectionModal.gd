extends CanvasLayer

signal inspection_closed()

var current_pc = null
var ram_minigame_scene: PackedScene = preload("res://scenes/minigames/RAMMinigame.tscn")
var hdd_minigame_scene: PackedScene = preload("res://scenes/minigames/HDDMinigame.tscn")

@onready var modal_control: Control = $ModalControl
@onready var title_label: Label = $ModalControl/Panel/VBox/Header/TitleLabel
@onready var status_summary: Label = $ModalControl/Panel/VBox/Header/StatusSummary

@onready var btn_comp_ram: Button = $ModalControl/Panel/VBox/GridContainer/BtnRAM
@onready var btn_comp_hdd: Button = $ModalControl/Panel/VBox/GridContainer/BtnHDD
@onready var btn_comp_gpu: Button = $ModalControl/Panel/VBox/GridContainer/BtnGPU
@onready var btn_comp_psu: Button = $ModalControl/Panel/VBox/GridContainer/BtnPSU
@onready var btn_comp_mobo: Button = $ModalControl/Panel/VBox/GridContainer/BtnMOBO

@onready var pc_state_badge: Label = $ModalControl/Panel/VBox/GridContainer/ChassisCard/Margin/VBox/BadgeLabel
@onready var btn_volver: Button = $ModalControl/Panel/VBox/Footer/BtnVolver

func _ready() -> void:
	layer = 10 # Prioridad por encima del HUD (layer 1)
	btn_volver.pressed.connect(_on_volver_pressed)
	
	btn_comp_ram.pressed.connect(_on_ram_clicked)
	btn_comp_hdd.pressed.connect(_on_hdd_clicked)
	btn_comp_gpu.pressed.connect(_on_gpu_clicked)
	btn_comp_psu.pressed.connect(_on_psu_clicked)
	btn_comp_mobo.pressed.connect(_on_mobo_clicked)

func setup_pc(pc_node) -> void:
	current_pc = pc_node
	title_label.text = "DIAGNÓSTICO TÉCNICO: COMPUTADORA #%d" % current_pc.pc_id
	_refresh_ui()

func _refresh_ui() -> void:
	if current_pc == null:
		return
		
	var ram_status = current_pc.components.get("RAM", "ok")
	var hdd_status = current_pc.components.get("Disco Duro", "ok")
	
	# Cuadro 1: Memoria RAM (NO revela la falla)
	match ram_status:
		"empty":
			btn_comp_ram.text = "MEMORIA RAM\n\n[ SLOT VACÍO ]\n▶ Clic para instalar repuesto"
			btn_comp_ram.modulate = Color(1.0, 0.85, 0.1, 1.0)
		"fixed":
			btn_comp_ram.text = "MEMORIA RAM\n\nDDR5 16GB\n[ INSTALADA Y TESTEADA ✓ ]"
			btn_comp_ram.modulate = Color(0.0, 1.0, 0.5, 1.0)
		_:
			btn_comp_ram.text = "MEMORIA RAM\n\nDDR5 16GB\n[ INSTALADA EN ZÓCALO ]"
			btn_comp_ram.modulate = Color(0.15, 0.85, 1.0, 0.9)
			
	# Cuadro 2: Disco Duro (NO revela la falla)
	match hdd_status:
		"empty":
			btn_comp_hdd.text = "DISCO DURO\n\n[ BAHÍA VACÍA ]\n▶ Clic para instalar repuesto"
			btn_comp_hdd.modulate = Color(1.0, 0.85, 0.1, 1.0)
		"fixed":
			btn_comp_hdd.text = "DISCO DURO\n\nSATA SSD 1TB\n[ INSTALADO Y TESTEADO ✓ ]"
			btn_comp_hdd.modulate = Color(0.0, 1.0, 0.5, 1.0)
		_:
			btn_comp_hdd.text = "DISCO DURO\n\nSATA SSD 1TB\n[ INSTALADO EN BAHÍA ]"
			btn_comp_hdd.modulate = Color(0.15, 0.85, 1.0, 0.9)
			
	# Cuadros sanos (Presentación técnica uniforme)
	btn_comp_gpu.text = "TARJETA GRÁFICA\n\nRTX 4070 OC\n[ INSTALADA EN PCIE ]"
	btn_comp_gpu.modulate = Color(0.15, 0.85, 1.0, 0.9)
	
	btn_comp_psu.text = "FUENTE DE PODER\n\n850W GOLD\n[ INSTALADA ]"
	btn_comp_psu.modulate = Color(0.15, 0.85, 1.0, 0.9)
	
	btn_comp_mobo.text = "PLACA MADRE\n\nCHIPSET Z790\n[ INSTALADA ]"
	btn_comp_mobo.modulate = Color(0.15, 0.85, 1.0, 0.9)
	
	# Mostrar el reporte del cliente
	if current_pc.is_fully_repaired():
		pc_state_badge.text = "PC COMPLETAMENTE REPARADA\nLISTA PARA ENTREGA ✓"
		pc_state_badge.modulate = Color(0, 1, 0.5, 1)
		status_summary.text = "¡Diagnóstico y reparación exitosos! La máquina bootea al 100%."
		status_summary.modulate = Color(0, 1, 0.5, 1)
	else:
		pc_state_badge.text = "FALLA ACTIVA\nDEDUCE EL COMPONENTE"
		pc_state_badge.modulate = Color(1, 0.8, 0.1, 1)
		status_summary.text = current_pc.symptom_report
		status_summary.modulate = Color(1, 0.85, 0.2, 1)

func _on_ram_clicked() -> void:
	if current_pc == null:
		return
	var ram_status = current_pc.components.get("RAM", "ok")
	if ram_status == "fixed":
		_show_feedback("La Memoria RAM ya fue cambiada y funciona sin errores.", true)
		return
		
	if ram_status == "empty" or current_pc.target_fault_component == "RAM":
		_open_ram_minigame(ram_status == "empty")
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
	if current_pc == null:
		return
	var hdd_status = current_pc.components.get("Disco Duro", "ok")
	if hdd_status == "fixed":
		_show_feedback("El Disco Duro ya fue cambiado y funciona sin errores.", true)
		return
		
	if hdd_status == "empty" or current_pc.target_fault_component == "Disco Duro":
		_open_hdd_minigame(hdd_status == "empty")
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
	GameManager.register_error(2.0)
	_show_feedback("❌ Diagnóstico incorrecto: La GPU da video y sus voltajes PCIe son normales. No es la causa.", false)

func _on_psu_clicked() -> void:
	GameManager.register_error(2.0)
	_show_feedback("❌ Diagnóstico incorrecto: La Fuente de Poder entrega los 12V y 5V estables. No es la causa.", false)

func _on_mobo_clicked() -> void:
	GameManager.register_error(2.0)
	_show_feedback("❌ Diagnóstico incorrecto: La Placa Madre no tiene pistas cortadas ni capacitores hinchados.", false)

func _show_feedback(msg: String, is_positive: bool) -> void:
	status_summary.text = msg
	status_summary.modulate = Color(0, 1, 0.5, 1) if is_positive else Color(1, 0.2, 0.3, 1)

func _on_volver_pressed() -> void:
	inspection_closed.emit()
	queue_free()
