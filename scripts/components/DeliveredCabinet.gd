class_name DeliveredCabinet
extends CharacterBody3D

# =============================================================================
# GABINETE DE PEDIDO ENTREGADO (APARICIÓN LIGERA, ARROJO FÍSICO & RECOGIDA [F])
# SE CARGA EN LOS BRAZOS DEL JUGADOR (NO EN LA MOCHILA)
# =============================================================================

signal picked_up(player: Node)

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var model_root: Node3D = $ModelRoot
@onready var light: OmniLight3D = $OmniLight3D
@onready var label_3d: Label3D = $Label3D

var order_data: Dictionary = {}
var is_picked_up: bool = false
var is_repaired: bool = false
var is_in_delivery_zone: bool = false

var is_flying: bool = false
var throw_velocity: Vector3 = Vector3.ZERO
var spin_axis: Vector3 = Vector3.ZERO
var spin_speed: float = 0.0

func _ready() -> void:
	add_to_group("delivered_cabinets")
	collision_layer = 1
	collision_mask = 1
	set_physics_process(false)
	if light:
		light.shadow_enabled = false
		light.light_energy = 0.8
	update_label()

func update_label() -> void:
	if not label_3d:
		return
	label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	if is_repaired:
		label_3d.text = "📦 GABINETE REPARADO ✓\n[F] CARGAR EN BRAZOS"
		label_3d.modulate = Color(0.2, 1.0, 0.45, 1.0)
	else:
		label_3d.text = "📦 GABINETE DE PEDIDO\n[F] CARGAR EN BRAZOS"
		label_3d.modulate = Color(0.2, 0.95, 1.0, 1.0)
	label_3d.outline_modulate = Color(0.0, 0.05, 0.15, 0.9)

func get_interaction_prompt() -> String:
	if is_picked_up or is_flying:
		return ""
	if is_repaired:
		return "[F] CARGAR GABINETE REPARADO EN BRAZOS"
	return "[F] CARGAR GABINETE EN BRAZOS"

func can_pickup_with_f() -> bool:
	return not is_picked_up and not is_flying

# Animación super sencilla y de bajísimo consumo
func spawn_animation(target_pos: Vector3, on_complete: Callable = Callable()) -> void:
	global_position = target_pos
	scale = Vector3(0.2, 0.2, 0.2)
	visible = true
	
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("play_sfx"):
		gm.play_sfx("click")
		
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3.ONE, 0.15)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	tw.tween_callback(func():
		update_label()
		if on_complete.is_valid():
			on_complete.call()
	)

# Animación ligera de desaparición al finalizar pedido en la terminal
func disappear_animation(on_complete: Callable = Callable()) -> void:
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.2)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		if on_complete.is_valid():
			on_complete.call()
		queue_free()
	)

# Lanzamiento físico con arco parabólico proporcional a la carga de la barra
func throw_from(start_pos: Vector3, initial_vel: Vector3) -> void:
	global_position = start_pos
	throw_velocity = initial_vel
	is_flying = true
	spin_axis = Vector3(randf_range(-1.0, 1.0), randf_range(-0.3, 0.3), randf_range(-1.0, 1.0)).normalized()
	spin_speed = randf_range(5.0, 9.0)
	if label_3d:
		label_3d.visible = false
	visible = true
	scale = Vector3.ONE
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if not is_flying:
		set_physics_process(false)
		return
		
	throw_velocity.y -= 11.0 * delta # Gravedad equilibrada para que vuele con fuerza consistente
	
	if model_root and spin_speed > 0.1:
		model_root.rotate(spin_axis, spin_speed * delta)
		spin_speed = max(0.0, spin_speed - 2.0 * delta)
		
	var col = move_and_collide(throw_velocity * delta)
	if col:
		# Rebote con fricción
		if throw_velocity.length() > 2.5:
			throw_velocity = throw_velocity.bounce(col.get_normal()) * 0.42
			var gm = get_node_or_null("/root/GameManager")
			if gm and gm.has_method("play_sfx"):
				gm.play_sfx("click")
		else:
			is_flying = false
			set_physics_process(false)
			# Enderezar el modelo al aterrizar
			if model_root:
				var tw = create_tween()
				tw.tween_property(model_root, "rotation", Vector3.ZERO, 0.18).set_trans(Tween.TRANS_QUAD)
			if label_3d:
				label_3d.visible = true
				
			# Comprobar si aterrizó cerca de la zona de entrega
			var root = get_tree().current_scene
			if root and "DELIVERY_WALL_POS" in root:
				if global_position.distance_to(root.DELIVERY_WALL_POS) < 3.2:
					is_in_delivery_zone = true
					update_label()

func pickup(player_node: Node) -> void:
	if is_picked_up:
		return
	is_picked_up = true
	picked_up.emit(player_node)
	queue_free()
