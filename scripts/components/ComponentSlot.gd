extends Area3D

@export var component_name: String = "RAM"
@export var is_damaged: bool = true
@export var minigame_scene: PackedScene

@onready var arrow_mesh: MeshInstance3D = $ArrowMesh
@onready var label_3d: Label3D = $Label3D
@onready var piece_mesh: MeshInstance3D = $PieceMesh

var is_fixed: bool = false
var is_empty_slot: bool = false
var saved_screw_type: String = ""
var original_arrow_y: float = 0.0

func _ready() -> void:
	if arrow_mesh:
		original_arrow_y = arrow_mesh.position.y
	_update_3d_visuals()

func _process(delta: float) -> void:
	if arrow_mesh and not is_fixed:
		var t = Time.get_ticks_msec() / 1000.0
		arrow_mesh.position.y = original_arrow_y + sin(t * 3.0) * 0.08

func _update_3d_visuals() -> void:
	if not label_3d:
		return
		
	if is_fixed:
		label_3d.text = "%s (OK)" % component_name
		label_3d.modulate = Color(0, 1, 0.4, 1)
		if arrow_mesh:
			arrow_mesh.visible = false
		if piece_mesh:
			piece_mesh.visible = true
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.0, 0.95, 0.6, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(0.0, 0.95, 0.6, 1.0)
			mat.emission_energy_multiplier = 0.3
			piece_mesh.material_override = mat
	elif is_empty_slot:
		label_3d.text = "%s [SLOT VACÍO]" % component_name
		label_3d.modulate = Color(1.0, 0.75, 0.1, 1)
		if arrow_mesh:
			arrow_mesh.visible = true
		if piece_mesh:
			piece_mesh.visible = false # Pieza retirada físicamente de la PC
	else:
		label_3d.text = component_name
		label_3d.modulate = Color(1, 0.2, 0.5, 1)
		if arrow_mesh:
			arrow_mesh.visible = true
		if piece_mesh:
			piece_mesh.visible = true

func get_interaction_prompt() -> String:
	if is_fixed:
		return "%s: Reparada y funcionando correctamente" % component_name
	elif is_empty_slot:
		return "[E] %s: Slot Vacío (Instalar repuesto nuevo)" % component_name
	return "[E] Reparar %s (Extraer componente dañado)" % component_name

func interact(player) -> void:
	if is_fixed:
		return
		
	if minigame_scene:
		player.set_movement_enabled(false)
		var minigame = minigame_scene.instantiate()
		
		# Transferir estado de persistencia al minijuego
		if "start_as_empty_slot" in minigame:
			minigame.start_as_empty_slot = is_empty_slot
		if "saved_screw_type" in minigame and saved_screw_type != "":
			minigame.screw_type = saved_screw_type
			
		get_tree().root.add_child(minigame)
		
		# Si el jugador retira la pieza rota durante el minijuego, persistimos el estado inmediatamente
		if minigame.has_signal("old_part_extracted"):
			minigame.connect("old_part_extracted", func():
				is_empty_slot = true
				if "screw_type" in minigame:
					saved_screw_type = minigame.screw_type
				_update_3d_visuals()
			)
			
		minigame.connect("minigame_finished", func(success: bool):
			player.set_movement_enabled(true)
			minigame.queue_free()
			if success:
				_on_repaired()
			else:
				_update_3d_visuals()
		)

func _on_repaired() -> void:
	is_fixed = true
	is_empty_slot = false
	is_damaged = false
	_update_3d_visuals()
	GameManager.register_repair(100, 10.0)
