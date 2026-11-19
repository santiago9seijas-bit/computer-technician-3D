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

@onready var label_3d: Label3D = $Label3D
@onready var arrow_mesh: MeshInstance3D = $ArrowMesh
@onready var status_light: OmniLight3D = $StatusLight

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
var custom_interact_callback: Callable = Callable()
var custom_prompt: String = ""

func _ready() -> void:
	set_process(false)
	if arrow_mesh:
		original_arrow_y = arrow_mesh.position.y
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
		if not is_connected:
			label_3d.text = "TERMINAL #%d · REQUIERE CONEXIÓN (%d/7)" % [pc_id, fixed_count]
			label_3d.modulate = Color(1.0, 0.75, 0.2)
		else:
			label_3d.text = "TERMINAL #%d · ENLAZADA ✓ (%d/7)" % [pc_id, fixed_count]
			label_3d.modulate = Color(0.0, 0.95, 1.0) if fixed_count > 0 else Color(1.0, 0.25, 0.5)

	var led_color = Color(0.2, 1.0, 0.4) if is_completed else (Color(0.2, 0.95, 1.0) if is_connected else Color(1.0, 0.6, 0.1))
	var led_node = get_node_or_null("GabineteModel/Led")
	if led_node and led_node is MeshInstance3D:
		var mat = led_node.get_surface_override_material(0)
		if not mat:
			mat = StandardMaterial3D.new()
			mat.emission_enabled = true
			mat.emission_energy_multiplier = 4.0
			led_node.set_surface_override_material(0, mat)
		mat.albedo_color = led_color
		mat.emission = led_color

func can_pickup_with_f() -> bool:
	return visible

func pickup_to_arms(_player: Node) -> Dictionary:
	var data = {
		"type": "sistema",
		"pc_id": pc_id,
		"is_completed": is_fully_repaired(),
		"is_connected": false,
		"components": components.duplicate(true)
	}
	is_connected = false
	visible = false
	collision_layer = 0
	collision_mask = 0
	return data

func restore_from_carried(data: Dictionary) -> void:
	visible = true
	collision_layer = 1
	collision_mask = 1
	if data.has("components"):
		components = data["components"]
	if data.has("is_completed"):
		is_completed = data["is_completed"]
	is_connected = data.get("is_connected", false)
	update_3d_state()

func get_interaction_prompt() -> String:
	if custom_prompt != "":
		return "%s  ·  [F] CARGAR EN BRAZOS" % custom_prompt
	if is_fully_repaired():
		return "[E] Terminal de Sistemas (Optimizada ✓)  ·  [F] CARGAR EN BRAZOS"
	if not is_connected:
		return "[E] Enlazar Conexión de Sistemas  ·  [F] CARGAR EN BRAZOS"
	return "[E] Acceder a Terminal de Sistemas (Enlazada ✓)  ·  [F] CARGAR EN BRAZOS"

func interact(player) -> void:
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
