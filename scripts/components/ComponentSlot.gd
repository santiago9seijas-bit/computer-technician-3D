extends Area3D

@export var component_name: String = "RAM"
@export var is_damaged: bool = true
@export var minigame_scene: PackedScene

@onready var arrow_mesh: MeshInstance3D = $ArrowMesh
@onready var label_3d: Label3D = $Label3D

var is_fixed: bool = false
var original_arrow_y: float = 0.0

func _ready() -> void:
	if arrow_mesh:
		original_arrow_y = arrow_mesh.position.y
	if label_3d:
		label_3d.text = component_name

func _process(delta: float) -> void:
	if arrow_mesh and not is_fixed:
		# Animación de flotación suave arriba/abajo para la flecha
		var t = Time.get_ticks_msec() / 1000.0
		arrow_mesh.position.y = original_arrow_y + sin(t * 3.0) * 0.08

func get_interaction_prompt() -> String:
	if is_fixed:
		return "%s: Reparada y funcionando correctamente" % component_name
	return "[E] Reparar %s (Iniciar Minijuego)" % component_name

func interact(player) -> void:
	if is_fixed:
		return
		
	# Pausar control del jugador e instanciar minijuego
	if minigame_scene:
		player.set_movement_enabled(false)
		var minigame = minigame_scene.instantiate()
		get_tree().root.add_child(minigame)
		
		minigame.connect("minigame_finished", func(success: bool):
			player.set_movement_enabled(true)
			minigame.queue_free()
			if success:
				_on_repaired()
		)

func _on_repaired() -> void:
	is_fixed = true
	is_damaged = false
	if label_3d:
		label_3d.text = "%s (OK)" % component_name
		label_3d.modulate = Color(0, 1, 0.4, 1)
	if arrow_mesh:
		arrow_mesh.visible = false
	GameManager.register_repair(100, 10.0)
