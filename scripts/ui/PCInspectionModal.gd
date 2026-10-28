extends Control

signal inspection_closed()

var current_pc = null
var ram_minigame_scene: PackedScene = preload("res://scenes/minigames/RAMMinigame.tscn")
var hdd_minigame_scene: PackedScene = preload("res://scenes/minigames/HDDMinigame.tscn")

@onready var title_label: Label = $Panel/VBox/Header/TitleLabel
@onready var status_summary: Label = $Panel/VBox/Header/StatusSummary

@onready var btn_comp_ram: Button = $Panel/VBox/GridContainer/BtnRAM
@onready var btn_comp_hdd: Button = $Panel/VBox/GridContainer/BtnHDD
@onready var btn_comp_gpu: Button = $Panel/VBox/GridContainer/BtnGPU
@onready var btn_comp_psu: Button = $Panel/VBox/GridContainer/BtnPSU
@onready var btn_comp_mobo: Button = $Panel/VBox/GridContainer/BtnMOBO

@onready var pc_state_badge: Label = $Panel/VBox/GridContainer/ChassisCard/Margin/VBox/BadgeLabel
@onready var btn_volver: Button = $Panel/VBox/Footer/BtnVolver

func _ready() -> void:
	btn_volver.pressed.connect(_on_volver_pressed)
	
	btn_comp_ram.pressed.connect(_on_ram_clicked)
	btn_comp_hdd.pressed.connect(_on_hdd_clicked)
	btn_comp_gpu.pressed.connect(func(): _show_ok_hint("Tarjeta Gráfica RTX 4070"))
	btn_comp_psu.pressed.connect(func(): _show_ok_hint("Fuente de Poder 850W Gold"))
	btn_comp_mobo.pressed.connect(func(): _show_ok_hint("Placa Madre Z790"))

func setup_pc(pc_node) -> void:
	current_pc = pc_node
	title_label.text = "INSPECCIÓN DE GABINETE: COMPUTADORA #%d" % current_pc.pc_id
	_refresh_ui()

func _refresh_ui() -> void:
	if current_pc == null:
		return
		
	var ram_status = current_pc.components.get("RAM", "broken")
	var hdd_status = current_pc.components.get("Disco Duro", "broken")
	
	# Cuadro 1: Memoria RAM
	match ram_status:
		"broken":
			btn_comp_ram.text = "MEMORIA RAM\n\n[ QUEMADA ]\n▶ Clic para desarmar"
			btn_comp_ram.modulate = Color(1.0, 0.25, 0.45, 1.0)
		"empty":
			btn_comp_ram.text = "MEMORIA RAM\n\n[ SLOT VACÍO ]\n▶ Clic para instalar"
			btn_comp_ram.modulate = Color(1.0, 0.85, 0.1, 1.0)
		"fixed":
			btn_comp_ram.text = "MEMORIA RAM\n\nDDR5 16GB\n[ INSTALADA ✓ ]"
			btn_comp_ram.modulate = Color(0.0, 1.0, 0.5, 1.0)
			
	# Cuadro 2: Disco Duro
	match hdd_status:
		"broken":
			btn_comp_hdd.text = "DISCO DURO\n\n[ ERROR SMART ]\n▶ Clic para desarmar"
			btn_comp_hdd.modulate = Color(1.0, 0.25, 0.45, 1.0)
		"empty":
			btn_comp_hdd.text = "DISCO DURO\n\n[ BAHÍA VACÍA ]\n▶ Clic para instalar"
			btn_comp_hdd.modulate = Color(1.0, 0.85, 0.1, 1.0)
		"fixed":
			btn_comp_hdd.text = "DISCO DURO\n\nSATA SSD 1TB\n[ INSTALADO ✓ ]"
			btn_comp_hdd.modulate = Color(0.0, 1.0, 0.5, 1.0)
			
	# Cuadros sanos (OK)
	btn_comp_gpu.text = "TARJETA GRÁFICA\n\nRTX 4070 OC\n[ ESTADO OK ✓ ]"
	btn_comp_gpu.modulate = Color(0.0, 0.85, 0.95, 0.85)
	
	btn_comp_psu.text = "FUENTE DE PODER\n\n850W GOLD\n[ ESTADO OK ✓ ]"
	btn_comp_psu.modulate = Color(0.0, 0.85, 0.95, 0.85)
	
	btn_comp_mobo.text = "PLACA MADRE\n\nCHIPSET Z790\n[ ESTADO OK ✓ ]"
	btn_comp_mobo.modulate = Color(0.0, 0.85, 0.95, 0.85)
	
	# Cuadro de Estado del Equipo
	if current_pc.is_fully_repaired():
		pc_state_badge.text = "PC COMPLETAMENTE REPARADA\nLISTA PARA ENTREGA ✓"
		pc_state_badge.modulate = Color(0, 1, 0.5, 1)
		status_summary.text = "Todos los componentes de este equipo funcionan al 100%."
		status_summary.modulate = Color(0, 1, 0.5, 1)
	else:
		pc_state_badge.text = "EN REPARACIÓN\nSE REQUIEREN REPUESTOS"
		pc_state_badge.modulate = Color(1, 0.8, 0.1, 1)
		status_summary.text = "Selecciona un componente averiado o vacío para trabajar en él."
		status_summary.modulate = Color(1, 0.85, 0.2, 1)

func _on_ram_clicked() -> void:
	if current_pc == null:
		return
	var ram_status = current_pc.components.get("RAM", "broken")
	if ram_status == "fixed":
		_show_ok_hint("Memoria RAM")
		return
		
	visible = false
	var minigame = ram_minigame_scene.instantiate()
	minigame.start_as_empty_slot = (ram_status == "empty")
	get_tree().root.add_child(minigame)
	
	minigame.connect("old_part_extracted", func():
		current_pc.components["RAM"] = "empty"
		current_pc.update_3d_state()
	)
	
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		visible = true
		if success:
			current_pc.components["RAM"] = "fixed"
			current_pc.update_3d_state()
			GameManager.register_repair(100, 10.0)
		_refresh_ui()
	)

func _on_hdd_clicked() -> void:
	if current_pc == null:
		return
	var hdd_status = current_pc.components.get("Disco Duro", "broken")
	if hdd_status == "fixed":
		_show_ok_hint("Disco Duro")
		return
		
	visible = false
	var minigame = hdd_minigame_scene.instantiate()
	minigame.start_as_empty_slot = (hdd_status == "empty")
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
		visible = true
		if success:
			current_pc.components["Disco Duro"] = "fixed"
			current_pc.update_3d_state()
			GameManager.register_repair(100, 10.0)
		_refresh_ui()
	)

func _show_ok_hint(comp_name: String) -> void:
	status_summary.text = "%s: Este componente ya fue testeado y funciona sin errores." % comp_name
	status_summary.modulate = Color(0, 1, 0.5, 1)

func _on_volver_pressed() -> void:
	inspection_closed.emit()
	queue_free()
