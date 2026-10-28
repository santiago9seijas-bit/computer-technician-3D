extends CharacterBody3D

@export var move_speed: float = 4.5
@export var mouse_sensitivity: float = 0.002
@export var gravity: float = 12.0

@onready var camera: Camera3D = $Camera3D
@onready var interaction_ray: RayCast3D = $Camera3D/RayCast3D

var can_move: bool = true
var hud_node: Control = null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func set_movement_enabled(enabled: bool) -> void:
	can_move = enabled
	if not enabled:
		velocity = Vector3.ZERO
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if not can_move or GameManager.is_game_paused:
		return
		
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -deg_to_rad(80), deg_to_rad(80))

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if can_move and not GameManager.is_game_paused:
		var input_dir = Vector2.ZERO
		if Input.is_action_pressed("move_forward"):
			input_dir.y -= 1
		if Input.is_action_pressed("move_back"):
			input_dir.y += 1
		if Input.is_action_pressed("move_left"):
			input_dir.x -= 1
		if Input.is_action_pressed("move_right"):
			input_dir.x += 1
		input_dir = input_dir.normalized()
		
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction != Vector3.ZERO:
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0
		velocity.z = 0
		
	move_and_slide()
	_handle_interaction()

func _handle_interaction() -> void:
	if not can_move or GameManager.is_game_paused:
		if hud_node and hud_node.has_method("set_interaction_prompt"):
			hud_node.set_interaction_prompt("")
		return
		
	if interaction_ray.is_colliding():
		var target = interaction_ray.get_collider()
		if target and target.has_method("get_interaction_prompt"):
			var prompt = target.get_interaction_prompt()
			if hud_node and hud_node.has_method("set_interaction_prompt"):
				hud_node.set_interaction_prompt(prompt)
				
			if Input.is_action_just_pressed("interact"):
				target.interact(self)
			return
			
	if hud_node and hud_node.has_method("set_interaction_prompt"):
		hud_node.set_interaction_prompt("")
