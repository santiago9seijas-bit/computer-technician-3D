extends StaticBody3D

@export var pc_id: int = 1

var target_fault_component: String = "RAM"

var components: Dictionary = {
	"Fan Cooler": "broken",
	"RAM": "broken",
	"Disco Duro": "broken",
	"Grafica": "broken",
	"Fuente": "broken",
	"Placa Madre": "broken",
	"CPU": "broken"
}

var saved_screw_type: String = ""
var is_completed: bool = false

@onready var label_3d: Label3D = $Label3D
@onready var arrow_mesh: MeshInstance3D = $ArrowMesh
@onready var status_light: OmniLight3D = $StatusLight

var inspection_modal_scene: PackedScene = preload("res://scenes/ui/PCInspectionModal.tscn")
var original_arrow_y: float = 0.0

func _ready() -> void:
	if arrow_mesh:
		original_arrow_y = arrow_mesh.position.y
		
	update_3d_state()

func _process(delta: float) -> void:
	if arrow_mesh and not is_completed:
		var t = Time.get_ticks_msec() / 1000.0
		arrow_mesh.position.y = original_arrow_y + sin(t * 3.0) * 0.08

func is_fully_repaired() -> bool:
	for comp in components.keys():
		if components[comp] == "broken" or components[comp] == "empty":
			return false
	return true

func update_3d_state() -> void:
	if not label_3d:
		return
		
	var fixed_count = 0
	var empty_count = 0
	for comp in components.keys():
		if components[comp] == "fixed":
			fixed_count += 1
		elif components[comp] == "empty":
			empty_count += 1
			
	var total_comps = components.size()
	if is_fully_repaired():
		if not is_completed:
			is_completed = true
			GameManager.computers_fixed += 1
			GameManager.register_repair(150, 15.0)
			GameManager.win_level()
			
		label_3d.text = "PC #%d [TODAS LAS PIEZAS REPARADAS (%d/%d) ✓]" % [pc_id, total_comps, total_comps]
		label_3d.modulate = Color(0.0, 1.0, 0.4, 1.0)
		if arrow_mesh:
			arrow_mesh.visible = false
		if status_light:
			status_light.light_color = Color(0.0, 1.0, 0.5, 1.0)
	else:
		if empty_count > 0:
			label_3d.text = "PC #%d [%d PIEZA(S) VACÍAS - ESPERANDO REPUESTO]" % [pc_id, empty_count]
			label_3d.modulate = Color(1.0, 0.75, 0.1, 1.0)
		else:
			label_3d.text = "PC #%d [BANCO DE PRUEBAS · %d/%d REPARADOS]" % [pc_id, fixed_count, total_comps]
			label_3d.modulate = Color(0.2, 0.8, 1.0, 1.0)
			
		if arrow_mesh:
			arrow_mesh.visible = true
		if status_light:
			status_light.light_color = Color(0.2, 0.8, 1.0, 1.0)

func get_interaction_prompt() -> String:
	if is_completed:
		return "PC #%d: Equipo 100%% reparado y testeado" % pc_id
	return "[E] PC #%d: Diagnosticar falla del cliente" % pc_id

func interact(player) -> void:
	player.set_movement_enabled(false)
	if player.hud_node:
		player.hud_node.visible = false
	var modal = inspection_modal_scene.instantiate()
	get_tree().root.add_child(modal)
	modal.setup_pc(self)
	
	modal.connect("inspection_closed", func():
		if is_fully_repaired():
			player.set_movement_enabled(false)
			if player.hud_node:
				player.hud_node.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			update_3d_state()
		else:
			player.set_movement_enabled(true)
			if player.hud_node:
				player.hud_node.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			update_3d_state()
	)
