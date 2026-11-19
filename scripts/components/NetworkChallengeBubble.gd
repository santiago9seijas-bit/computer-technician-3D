extends StaticBody3D

@export var challenge_id: int = 0
@export var custom_title: String = ""
@export var custom_dialog: String = ""

@onready var visuals: Node3D = $Visuals
@onready var bubble_mesh: MeshInstance3D = $Visuals/BubbleMesh
@onready var torus_mesh: MeshInstance3D = $Visuals/TorusMesh
@onready var label_3d: Label3D = $Label3D
@onready var light: OmniLight3D = $OmniLight3D

const MINIGAME_SCENE: PackedScene = preload("res://scenes/minigames/PacketTracerMinigame.tscn")

const CHALLENGE_INFO = [
	{
		"title": "🟢 INDUCCIÓN: PACKET TRACER",
		"desc": "Santiago: 'Aprende los fundamentos de Cisco y conexión con Cable Directo.'",
		"tag": "Tutorial & Fundamentos"
	},
	{
		"title": "🟢 RETO 1: LAN & SERVIDOR",
		"desc": "Santiago: 'Interconecta PCs de oficina y el Servidor de Archivos al Switch.'",
		"tag": "Capa 2 / Access Layer"
	},
	{
		"title": "🟢 RETO 2: ROUTER & SUBREDES",
		"desc": "Santiago: 'Conecta dos switches a las interfaces Gigabit del Router.'",
		"tag": "Capa 3 / Enrutamiento"
	},
	{
		"title": "🟢 RETO 3: FIBRA ÓPTICA & CROSSOVER",
		"desc": "Santiago: 'Usa Cable Cruzado entre Switches y Fibra Óptica para el Data Center.'",
		"tag": "Capa Física Avanzada"
	}
]

var _base_y: float = 0.9
var _time_passed: float = 0.0
var _active_minigame: CanvasLayer = null

func _ready() -> void:
	# Configurar capa de colisión para que el raycast del player lo detecte
	collision_layer = 1
	collision_mask = 0
	
	_update_labels()

func _process(delta: float) -> void:
	_time_passed += delta
	
	# Efecto de levitación y oscilación suave
	if visuals:
		visuals.position.y = _base_y + sin(_time_passed * 2.2 + float(challenge_id)) * 0.06
	
	if torus_mesh:
		torus_mesh.rotate_y(delta * 1.2)
		torus_mesh.rotate_x(delta * 0.4)
		
	if light:
		light.light_energy = 1.4 + sin(_time_passed * 3.0) * 0.3

func _update_labels() -> void:
	if not label_3d:
		return
		
	var info = _get_info()
	var t = info["title"]
	var d = info["desc"]
	
	if custom_title != "":
		t = custom_title
	if custom_dialog != "":
		d = custom_dialog
		
	label_3d.text = "%s\n%s\n[E] Iniciar Reto de Red" % [t, d]
	label_3d.modulate = Color(0.2, 1.0, 0.5)

func _get_info() -> Dictionary:
	var idx = clamp(challenge_id, 0, CHALLENGE_INFO.size() - 1)
	return CHALLENGE_INFO[idx]

func get_interaction_prompt() -> String:
	var info = _get_info()
	var t = custom_title if custom_title != "" else info["title"]
	return "[E] " + t + " (Cisco Packet Tracer)"

func interact(player) -> void:
	if _active_minigame and is_instance_valid(_active_minigame):
		return
		
	if not MINIGAME_SCENE:
		return
		
	var minigame = MINIGAME_SCENE.instantiate()
	_active_minigame = minigame
	get_tree().root.add_child(minigame)
	
	if minigame.has_method("load_challenge"):
		minigame.load_challenge(challenge_id)
		
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var cleanup_cb = func(_success: bool = false):
		if player and is_instance_valid(player) and player.has_method("set_movement_enabled"):
			player.set_movement_enabled(true)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	minigame.minigame_finished.connect(cleanup_cb)
	minigame.tree_exited.connect(func():
		cleanup_cb.call(false)
	)
