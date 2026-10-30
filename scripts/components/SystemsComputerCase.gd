extends StaticBody3D

@export var pc_id: int = 1

var components: Dictionary = {
	"Sistema Operativo": "broken",
	"Drivers": "broken",
	"Malware": "broken",
	"Adware": "broken",
	"Debugger": "broken",
	"Pendrive USB": "broken",
	"Arcade Ciberdefensa": "broken"
}

var is_completed: bool = false

@onready var label_3d: Label3D = $Label3D
@onready var arrow_mesh: MeshInstance3D = $ArrowMesh
@onready var status_light: OmniLight3D = $StatusLight

var systems_modal_scene: PackedScene = preload("res://scenes/ui/PCSystemsModal.tscn")
var original_arrow_y: float = 0.0

func _ready() -> void:
	if arrow_mesh:
		original_arrow_y = arrow_mesh.position.y
	update_3d_state()

func _process(_delta: float) -> void:
	if arrow_mesh and not is_completed:
		var t = Time.get_ticks_msec() / 1000.0
		arrow_mesh.position.y = original_arrow_y + sin(t * 3.0) * 0.08

func is_fully_repaired() -> bool:
	for comp in components.keys():
		if components[comp] == "broken":
			return false
	return true

func update_3d_state() -> void:
	if not label_3d:
		return
		
	var fixed_count = 0
	for comp in components.keys():
		if components[comp] == "fixed":
			fixed_count += 1
			
	if is_fully_repaired():
		is_completed = true
		if status_light:
			status_light.light_color = Color(0.2, 1.0, 0.4)
			status_light.light_energy = 2.0
		if arrow_mesh:
			arrow_mesh.visible = false
		label_3d.text = "[ TERMINAL RESTAURADA 100% ✓ ]"
		label_3d.modulate = Color(0.2, 1.0, 0.4)
		
		# Notificar victoria de nivel
		GameManager.complete_level()
	else:
		is_completed = false
		if status_light:
			status_light.light_color = Color(0.0, 0.85, 1.0)
			status_light.light_energy = 1.6
		if arrow_mesh:
			arrow_mesh.visible = true
		label_3d.text = "TERMINAL #%d · SOFTWARE (%d/7)" % [pc_id, fixed_count]
		label_3d.modulate = Color(0.0, 0.95, 1.0) if fixed_count > 0 else Color(1.0, 0.25, 0.5)

func get_interaction_prompt() -> String:
	if is_fully_repaired():
		return "[E] Inspeccionar Terminal de Sistemas (Optimizada ✓)"
	return "[E] Acceder a la Terminal de Sistemas y Ciberseguridad"

func interact(player) -> void:
	var hud = player.hud_node
	if hud and hud.has_node("PCSystemsModal"):
		return
		
	var modal = systems_modal_scene.instantiate()
	modal.setup_pc(self)
	
	player.set_movement_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	modal.connect("inspection_closed", func():
		player.set_movement_enabled(true)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	)
	
	if hud:
		hud.add_child(modal)
	else:
		get_tree().root.add_child(modal)
