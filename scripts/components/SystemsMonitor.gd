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
var is_connected: bool = false
var has_player_inspected: bool = false
var current_glow_color: Color = Color(0.0, 0.65, 1.0)

@onready var label_3d: Label3D = $Label3D
@onready var arrow_mesh: MeshInstance3D = $ArrowMesh
@onready var screen_light: OmniLight3D = $ScreenLight

var _systems_modal_scene: PackedScene = null
var systems_modal_scene: PackedScene:
	get:
		if not _systems_modal_scene:
			_systems_modal_scene = load("res://scenes/ui/PCSystemsModal.tscn")
		return _systems_modal_scene
	set(v):
		_systems_modal_scene = v

var _conn_minigame_scene: PackedScene = null
var conn_minigame_scene: PackedScene:
	get:
		if not _conn_minigame_scene:
			_conn_minigame_scene = load("res://scenes/minigames/SystemConnectionMinigame.tscn")
		return _conn_minigame_scene
	set(v):
		_conn_minigame_scene = v

var original_arrow_y: float = 0.0
var arrow_mat: StandardMaterial3D = null
var custom_interact_callback: Callable = Callable()
var custom_prompt: String = ""

func _ready() -> void:
	set_process(false)
	if arrow_mesh:
		original_arrow_y = arrow_mesh.position.y
		arrow_mat = StandardMaterial3D.new()
		arrow_mat.emission_enabled = true
		arrow_mat.emission_energy_multiplier = 3.0
		arrow_mesh.material_override = arrow_mat
		arrow_mesh.visible = true
		
		var tw = create_tween().set_loops()
		tw.tween_property(arrow_mesh, "position:y", original_arrow_y + 0.08, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(arrow_mesh, "position:y", original_arrow_y - 0.08, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	update_3d_state()

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
		current_glow_color = Color(0.2, 1.0, 0.4) # Verde: listo al 100%
		if screen_light:
			screen_light.light_color = current_glow_color
			screen_light.light_energy = 1.4
		label_3d.text = "[ TERMINAL RESTAURADA 100% ✓ ]"
		label_3d.modulate = current_glow_color
		
		# Notificar victoria de nivel
		GameManager.complete_level()
	elif has_player_inspected or is_connected or fixed_count > 0:
		is_completed = false
		current_glow_color = Color(1.0, 0.85, 0.2) # Amarillo: en progreso / ya abierto
		if screen_light:
			screen_light.light_color = current_glow_color
			screen_light.light_energy = 1.2
		if is_connected:
			label_3d.text = "TERMINAL #%d · ENLAZADA ✓ (%d/7)" % [pc_id, fixed_count]
		else:
			label_3d.text = "TERMINAL #%d · EN REVISIÓN (%d/7)" % [pc_id, fixed_count]
		label_3d.modulate = current_glow_color
	else:
		is_completed = false
		current_glow_color = Color(0.0, 0.65, 1.0) # Azul: sin revisar / requiere conexión
		if screen_light:
			screen_light.light_color = current_glow_color
			screen_light.light_energy = 1.0
		label_3d.text = "TERMINAL #%d · [ SIN REVISAR ]" % [pc_id]
		label_3d.modulate = current_glow_color

	if arrow_mesh:
		arrow_mesh.visible = true
		if arrow_mat:
			arrow_mat.albedo_color = current_glow_color
			arrow_mat.emission = current_glow_color

func get_interaction_prompt() -> String:
	if custom_prompt != "":
		return custom_prompt
	if is_fully_repaired():
		return "[E] Terminal de Sistemas (Optimizada ✓)"
	if not is_connected:
		return "[E] Enlazar Conexión de Sistemas"
	return "[E] Acceder a Terminal de Sistemas (Enlazada ✓)"

func interact(player) -> void:
	has_player_inspected = true
	update_3d_state()
	
	if custom_interact_callback.is_valid():
		custom_interact_callback.call(player)
		return

	if get_tree().root.has_node("PCSystemsModal") or get_tree().root.has_node("SystemConnectionMinigame"):
		return

	if not is_connected:
		_launch_connection_minigame(player)
	else:
		_open_systems_modal(player)

func _launch_connection_minigame(player) -> void:
	var minigame = conn_minigame_scene.instantiate()
	minigame.name = "SystemConnectionMinigame"
	
	player.set_movement_enabled(false)
	if player.hud_node:
		player.hud_node.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	minigame.connect("minigame_finished", func(success: bool):
		if success:
			is_connected = true
			update_3d_state()
			var gm = get_node_or_null("/root/GameManager")
			if gm and gm.has_method("spawn_floating_text"):
				gm.spawn_floating_text("¡SISTEMAS CONECTADOS!", true)
			_open_systems_modal(player)
		else:
			player.set_movement_enabled(true)
			if player.hud_node:
				player.hud_node.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			update_3d_state()
	)
	
	get_tree().root.add_child(minigame)
	if minigame.has_method("setup_target"):
		minigame.setup_target(self)

func _open_systems_modal(player) -> void:
	if get_tree().root.has_node("PCSystemsModal"):
		return
		
	var modal = systems_modal_scene.instantiate()
	modal.name = "PCSystemsModal"
	
	player.set_movement_enabled(false)
	if player.hud_node:
		player.hud_node.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	modal.connect("inspection_closed", func():
		if is_instance_valid(modal):
			modal.queue_free()
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
	
	get_tree().root.add_child(modal)
	modal.setup_pc(self)
