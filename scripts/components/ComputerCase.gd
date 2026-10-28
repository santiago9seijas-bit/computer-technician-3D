extends StaticBody3D

@export var pc_id: int = 1

# Estado de los componentes de esta computadora ("broken", "empty", "fixed")
var components: Dictionary = {
	"RAM": "broken",
	"Disco Duro": "broken"
}

var saved_screw_type: String = ""
var is_completed: bool = false

@onready var label_3d: Label3D = $Label3D
@onready var arrow_mesh: MeshInstance3D = $ArrowMesh
@onready var status_light: OmniLight3D = $StatusLight
@onready var case_mesh: MeshInstance3D = $CaseMesh

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
	for comp in components:
		if components[comp] != "fixed":
			return false
	return true

func update_3d_state() -> void:
	if not label_3d:
		return
		
	if is_fully_repaired():
		if not is_completed:
			is_completed = true
			GameManager.computers_fixed += 1
			GameManager.register_repair(150, 15.0)
			
		label_3d.text = "PC #%d [REPARADA ✓]" % pc_id
		label_3d.modulate = Color(0.0, 1.0, 0.4, 1.0)
		if arrow_mesh:
			arrow_mesh.visible = false
		if status_light:
			status_light.light_color = Color(0.0, 1.0, 0.5, 1.0)
	else:
		var pending = []
		for comp in components:
			if components[comp] == "empty":
				pending.append(comp + " (Vacío)")
			elif components[comp] == "broken":
				pending.append(comp + " (Dañado)")
				
		label_3d.text = "PC #%d [%s]" % [pc_id, ", ".join(pending)]
		label_3d.modulate = Color(1.0, 0.2, 0.45, 1.0)
		if arrow_mesh:
			arrow_mesh.visible = true
		if status_light:
			status_light.light_color = Color(1.0, 0.1, 0.4, 1.0)

func get_interaction_prompt() -> String:
	if is_completed:
		return "PC #%d: Equipo 100%% reparado y operativo" % pc_id
	return "[E] Abrir Gabinete PC #%d (Inspeccionar componentes)" % pc_id

func interact(player) -> void:
	player.set_movement_enabled(false)
	var modal = inspection_modal_scene.instantiate()
	get_tree().root.add_child(modal)
	modal.setup_pc(self)
	
	modal.connect("inspection_closed", func():
		player.set_movement_enabled(true)
		update_3d_state()
	)
