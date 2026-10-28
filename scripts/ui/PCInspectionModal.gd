extends Control

signal inspection_closed()

var current_pc = null
var ram_minigame_scene: PackedScene = preload("res://scenes/minigames/RAMMinigame.tscn")
var hdd_minigame_scene: PackedScene = preload("res://scenes/minigames/HDDMinigame.tscn")

@onready var title_label: Label = $Panel/VBox/Header/TitleLabel
@onready var status_summary: Label = $Panel/VBox/Header/StatusSummary

@onready var btn_comp_ram: Button = $Panel/VBox/ContentHBox/ComponentsGrid/BtnRAM
@onready var btn_comp_hdd: Button = $Panel/VBox/ContentHBox/ComponentsGrid/BtnHDD
@onready var btn_comp_psu: Button = $Panel/VBox/ContentHBox/ComponentsGrid/BtnPSU
@onready var btn_comp_gpu: Button = $Panel/VBox/ContentHBox/ComponentsGrid/BtnGPU
@onready var btn_comp_mobo: Button = $Panel/VBox/ContentHBox/ComponentsGrid/BtnMOBO

@onready var pc_state_badge: Label = $Panel/VBox/ContentHBox/PCVisualPanel/Margin/VBox/BadgeLabel
@onready var btn_volver: Button = $Panel/VBox/Footer/BtnVolver

func _ready() -> void:
	btn_volver.pressed.connect(_on_volver_pressed)
	
	btn_comp_ram.pressed.connect(_on_ram_clicked)
	btn_comp_hdd.pressed.connect(_on_hdd_clicked)
	btn_comp_psu.pressed.connect(func(): _show_ok_hint("Fuente de Poder"))
	btn_comp_gpu.pressed.connect(func(): _show_ok_hint("Tarjeta Gráfica"))
	btn_comp_mobo.pressed.connect(func(): _show_ok_hint("Placa Madre"))

func setup_pc(pc_node) -> void:
	current_pc = pc_node
	title_label.text = "INSPECCIÓN DE GABINETE: PC #%d" % current_pc.pc_id
	_refresh_ui()

func _refresh_ui() -> void:
	if current_pc == null:
		return
		
	var ram_status = current_pc.components.get("RAM", "broken")
	var hdd_status = current_pc.components.get("Disco Duro", "broken")
	
	# Botón RAM
	match ram_status:
		"broken":
			btn_comp_ram.text = "1. MEMORIA RAM: [DAÑADA / QUEMADA]\n▶ Clic para desarmar y extraer"
			btn_comp_ram.modulate = Color(1.0, 0.2, 0.4, 1.0)
		"empty":
			btn_comp_ram.text = "1. MEMORIA RAM: [SLOT VACÍO]\n▶ Clic para instalar repuesto nuevo"
			btn_comp_ram.modulate = Color(1.0, 0.8, 0.1, 1.0)
		"fixed":
			btn_comp_ram.text = "1. MEMORIA RAM: [DDR5 INSTALADA Y TESTEADA ✓]"
			btn_comp_ram.modulate = Color(0.0, 1.0, 0.5, 1.0)
			
	# Botón HDD
	match hdd_status:
		"broken":
			btn_comp_hdd.text = "2. DISCO DURO: [FALLA DE LECTURA SMART]\n▶ Clic para desarmar y extraer"
			btn_comp_hdd.modulate = Color(1.0, 0.2, 0.4, 1.0)
		"empty":
			btn_comp_hdd.text = "2. DISCO DURO: [BAHÍA VACÍA]\n▶ Clic para instalar repuesto nuevo"
			btn_comp_hdd.modulate = Color(1.0, 0.8, 0.1, 1.0)
		"fixed":
			btn_comp_hdd.text = "2. DISCO DURO: [SSD 1TB INSTALADO Y TESTEADO ✓]"
			btn_comp_hdd.modulate = Color(0.0, 1.0, 0.5, 1.0)
			
	# Componentes sanos
	btn_comp_psu.text = "3. FUENTE DE PODER: [850W GOLD - OK ✓]"
	btn_comp_psu.modulate = Color(0.0, 0.85, 0.9, 0.8)
	
	btn_comp_gpu.text = "4. TARJETA GRÁFICA: [RTX 4070 - OK ✓]"
	btn_comp_gpu.modulate = Color(0.0, 0.85, 0.9, 0.8)
	
	btn_comp_mobo.text = "5. PLACA MADRE: [CHIPSET Z790 - OK ✓]"
	btn_comp_mobo.modulate = Color(0.0, 0.85, 0.9, 0.8)
	
	# Resumen y estado general de la PC
	if current_pc.is_fully_repaired():
		pc_state_badge.text = "PC COMPLETAMENTE REPARADA\nLISTA PARA ENTREGA"
		pc_state_badge.modulate = Color(0, 1, 0.5, 1)
		status_summary.text = "Todos los componentes de este equipo funcionan al 100%."
		status_summary.modulate = Color(0, 1, 0.5, 1)
	else:
		pc_state_badge.text = "EN PROCESO DE REPARACIÓN\nSE REQUIEREN REPUESTOS"
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
