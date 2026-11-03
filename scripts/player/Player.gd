extends CharacterBody3D

@export var move_speed: float = 4.5
@export var sprint_speed: float = 7.5
@export var jump_velocity: float = 5.2
@export var mouse_sensitivity: float = 0.002
@export var gravity: float = 12.0

@export_group("Stamina")
@export var max_stamina: float = 100.0
@export var stamina_drain_rate: float = 25.0
@export var stamina_regen_rate: float = 30.0
@export var stamina_regen_delay: float = 0.5

var current_stamina: float = 100.0
var is_stamina_exhausted: bool = false
var _stamina_regen_timer: float = 0.0

@onready var camera: Camera3D = $Camera3D
@onready var interaction_ray: RayCast3D = $Camera3D/RayCast3D
@onready var character_model: Node3D = $ModelRoot/CharacterModel
@onready var animation_player: AnimationPlayer = $ModelRoot/AnimationPlayer
@onready var intro_camera_pivot: Node3D = $IntroCameraPivot
@onready var intro_camera: Camera3D = $IntroCameraPivot/IntroCamera3D

var can_move: bool = true
var hud_node: Control = null

var is_in_cinematic: bool = false
var intro_tween: Tween = null
var intro_callback: Callable = Callable()
var _cached_mesh_instances: Array[MeshInstance3D] = []
var _space_was_pressed: bool = false

func _ready() -> void:
	_ensure_action("jump", KEY_SPACE)
	_ensure_action("sprint", KEY_SHIFT)
	_ensure_action("spring", KEY_SHIFT)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if character_model:
		var found = character_model.find_children("*", "MeshInstance3D")
		for node in found:
			var mi = node as MeshInstance3D
			if mi:
				_cached_mesh_instances.append(mi)
	_setup_animation_player()
	# En vista primera persona habitual, ocultar malla para no bloquear cámara pero manteniendo sombras
	set_character_shadows_only(true)

func _setup_animation_player() -> void:
	if not animation_player:
		return
	# Configurar librería de animación base preparada para recibir futuras animaciones 3D
	if not animation_player.has_animation_library(""):
		var anim_lib = AnimationLibrary.new()
		var idle_anim = Animation.new()
		idle_anim.length = 2.4
		idle_anim.loop_mode = Animation.LOOP_LINEAR
		
		# Animación idle sutil de respiración en CharacterModel
		var track_idx = idle_anim.add_track(Animation.TYPE_POSITION_3D)
		idle_anim.track_set_path(track_idx, "CharacterModel:position")
		idle_anim.track_insert_key(track_idx, 0.0, Vector3.ZERO)
		idle_anim.track_insert_key(track_idx, 1.2, Vector3(0.0, 0.012, 0.0))
		idle_anim.track_insert_key(track_idx, 2.4, Vector3.ZERO)
		
		anim_lib.add_animation("idle", idle_anim)
		animation_player.add_animation_library("", anim_lib)
		animation_player.play("idle")
	elif animation_player.has_animation("idle"):
		animation_player.play("idle")

func set_character_shadows_only(shadows_only: bool) -> void:
	if shadows_only:
		# En primera persona ocultamos el modelo para no sobrecargar el renderizado de sombras ni cálculos de huesos
		for mi in _cached_mesh_instances:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.visible = false
		if animation_player:
			animation_player.pause()
	else:
		for mi in _cached_mesh_instances:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			mi.visible = true
		if animation_player and animation_player.has_animation("idle"):
			animation_player.play("idle")

func play_intro_cinematic(on_finished: Callable = Callable()) -> void:
	is_in_cinematic = true
	can_move = false
	velocity = Vector3.ZERO
	intro_callback = on_finished
	
	# Mostrar el modelo 3D completo en la cinemática aérea
	set_character_shadows_only(false)
	
	if hud_node and hud_node.has_method("setup_cinematic_mode"):
		hud_node.setup_cinematic_mode()
	
	# Configuración inicial de la cámara aérea orbital
	intro_camera_pivot.rotation.y = deg_to_rad(120.0)
	intro_camera.position = Vector3(0.0, 0.6, 2.4)
	intro_camera.rotation.x = deg_to_rad(-12.0)
	intro_camera.fov = 68.0
	intro_camera.make_current()
	
	if intro_tween and intro_tween.is_valid():
		intro_tween.kill()

	# Esperar fotogramas para que el motor renderice el entorno 3D, compile shaders
	# y estabilice el framerate antes de arrancar la animación orbital (evita el congelamiento y salto)
	await get_tree().process_frame
	await get_tree().process_frame

	if not is_in_cinematic:
		return
		
	intro_tween = create_tween()
	var duration: float = 1.8
	
	intro_tween.set_parallel(true)
	intro_tween.tween_property(intro_camera_pivot, "rotation:y", 0.0, duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	intro_tween.tween_property(intro_camera, "position", Vector3(0.0, 0.4, 0.05), duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	intro_tween.tween_property(intro_camera, "rotation:x", 0.0, duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	intro_tween.tween_property(intro_camera, "fov", camera.fov, duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	# Disparar arranque óptico al final de la transición
	intro_tween.chain().tween_callback(_on_cinematic_optic_trigger)
	intro_tween.tween_interval(0.2)
	intro_tween.chain().tween_callback(_finish_intro_cinematic)

func _on_cinematic_optic_trigger() -> void:
	if hud_node and hud_node.has_method("play_optic_boot_transition"):
		hud_node.play_optic_boot_transition()

func _finish_intro_cinematic() -> void:
	if not is_in_cinematic:
		return
	is_in_cinematic = false
	
	if intro_tween and intro_tween.is_valid():
		intro_tween.kill()
		
	# Conmutar suavemente a la cámara de primera persona
	camera.make_current()
	intro_camera_pivot.rotation.y = 0.0
	
	# Mover el modelo a modo solo sombra para no obstruir la vista interna
	set_character_shadows_only(true)
	
	if hud_node and hud_node.has_method("skip_cinematic"):
		hud_node.skip_cinematic()
		
	set_movement_enabled(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if intro_callback.is_valid():
		var cb = intro_callback
		intro_callback = Callable()
		cb.call()

func set_movement_enabled(enabled: bool) -> void:
	can_move = enabled
	if not enabled:
		velocity = Vector3.ZERO
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if is_in_cinematic:
		if event.is_action_pressed("interact") \
		or (event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_ESCAPE)) \
		or (event is InputEventMouseButton and event.pressed):
			_finish_intro_cinematic()
			get_viewport().set_input_as_handled()
			return
		return
		
	if not can_move or GameManager.is_game_paused:
		return

	# Solo permitir rotación de cámara si el ratón está estrictamente capturado
	if event is InputEventMouseMotion:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			return
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -deg_to_rad(80), deg_to_rad(80))
		return
		
	# Si se hace clic en pantalla durante juego libre, asegurar captura del ratón
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not can_move or GameManager.is_game_paused:
			return
		if hud_node:
			var win_panel = hud_node.get_node_or_null("WinPanel")
			if is_instance_valid(win_panel) and win_panel.visible:
				return
			var game_over_panel = hud_node.get_node_or_null("GameOverPanel")
			if is_instance_valid(game_over_panel) and game_over_panel.visible:
				return
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			var root_node = get_tree().root
			var modal_open = false
			for modal_name in ["PCInspectionModal", "ServerInspectionModal", "LevelIntroModal", "LevelSystemsIntroModal", "LevelServerIntroModal", "PCSystemsModal"]:
				var found = root_node.find_child(modal_name, true, false)
				if is_instance_valid(found) and (not ("visible" in found) or found.visible):
					modal_open = true
					break
			if not modal_open:
				for child in root_node.get_children():
					if child.name.ends_with("Minigame") or child.is_in_group("minigames"):
						modal_open = true
						break
			if not modal_open and not is_in_cinematic:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0
		
	if can_move and not GameManager.is_game_paused and not is_in_cinematic:
		# Mecánica de Salto (jump)
		var wants_jump: bool = Input.is_action_just_pressed("jump") or _is_space_just_pressed()
		if wants_jump and is_on_floor():
			velocity.y = jump_velocity

		if is_on_ceiling() and velocity.y > 0.0:
			velocity.y = 0.0

		# Mecánica de Correr / Sprint / Spring con consumo de estamina
		var wants_sprint: bool = (
			Input.is_action_pressed("sprint")
			or Input.is_action_pressed("spring")
			or Input.is_physical_key_pressed(KEY_SHIFT)
			or Input.is_key_pressed(KEY_SHIFT)
		)

		var input_dir = Vector2.ZERO
		if Input.is_action_pressed("move_forward") or Input.is_physical_key_pressed(KEY_W):
			input_dir.y -= 1
		if Input.is_action_pressed("move_back") or Input.is_physical_key_pressed(KEY_S):
			input_dir.y += 1
		if Input.is_action_pressed("move_left") or Input.is_physical_key_pressed(KEY_A):
			input_dir.x -= 1
		if Input.is_action_pressed("move_right") or Input.is_physical_key_pressed(KEY_D):
			input_dir.x += 1
		input_dir = input_dir.normalized()
		
		var is_moving: bool = input_dir != Vector2.ZERO
		var is_sprinting: bool = wants_sprint and is_moving and not is_stamina_exhausted and current_stamina > 0.0

		if is_sprinting:
			current_stamina = maxf(0.0, current_stamina - stamina_drain_rate * delta)
			_stamina_regen_timer = stamina_regen_delay
			if current_stamina <= 0.0:
				is_stamina_exhausted = true
		else:
			if _stamina_regen_timer > 0.0:
				_stamina_regen_timer -= delta
			else:
				current_stamina = minf(max_stamina, current_stamina + stamina_regen_rate * delta)
				if is_stamina_exhausted and current_stamina >= max_stamina * 0.25:
					is_stamina_exhausted = false

		var current_speed: float = sprint_speed if is_sprinting else move_speed

		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction != Vector3.ZERO:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)

		# FOV dinámico en cámara al correr (solo interpola si hay diferencia activa)
		if camera and not is_in_cinematic:
			var target_fov: float = 82.0 if (is_sprinting and direction != Vector3.ZERO and is_on_floor()) else 75.0
			if abs(camera.fov - target_fov) > 0.05:
				camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
			elif camera.fov != target_fov:
				camera.fov = target_fov
	else:
		velocity.x = 0
		velocity.z = 0
		if current_stamina < max_stamina:
			if _stamina_regen_timer > 0.0:
				_stamina_regen_timer -= delta
			else:
				current_stamina = minf(max_stamina, current_stamina + stamina_regen_rate * delta)
				if is_stamina_exhausted and current_stamina >= max_stamina * 0.25:
					is_stamina_exhausted = false
		
	move_and_slide()
	_update_stamina_hud()
	_handle_interaction()

func _update_stamina_hud() -> void:
	if not hud_node:
		var hud_cand = get_tree().root.find_child("HUD", true, false)
		if hud_cand is Control:
			hud_node = hud_cand
	if hud_node and hud_node.has_method("update_stamina"):
		hud_node.update_stamina(current_stamina, max_stamina, is_stamina_exhausted)

func _is_space_just_pressed() -> bool:
	var pressed: bool = Input.is_physical_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_SPACE)
	var just_pressed: bool = pressed and not _space_was_pressed
	_space_was_pressed = pressed
	return just_pressed

func spring_jump(force: float = 8.5) -> void:
	velocity.y = force

func bounce(force: float = 8.5) -> void:
	spring_jump(force)

func _ensure_action(action_name: String, key: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var has_event := false
	for existing in InputMap.action_get_events(action_name):
		if existing is InputEventKey and (existing.physical_keycode == key or existing.keycode == key):
			has_event = true
			break
	if not has_event:
		var ev1 := InputEventKey.new()
		ev1.physical_keycode = key
		var ev2 := InputEventKey.new()
		ev2.keycode = key
		InputMap.action_add_event(action_name, ev1)
		InputMap.action_add_event(action_name, ev2)

var _last_interaction_collider: Object = null

func _handle_interaction() -> void:
	if not can_move or GameManager.is_game_paused or is_in_cinematic:
		if _last_interaction_collider != null:
			_last_interaction_collider = null
			if hud_node and hud_node.has_method("set_interaction_prompt"):
				hud_node.set_interaction_prompt("")
		return
		
	if interaction_ray.is_colliding():
		var target = interaction_ray.get_collider()
		if target and target.has_method("get_interaction_prompt"):
			_last_interaction_collider = target
			var prompt = target.get_interaction_prompt()
			if hud_node and hud_node.has_method("set_interaction_prompt"):
				hud_node.set_interaction_prompt(prompt)
				
			if Input.is_action_just_pressed("interact"):
				target.interact(self)
			return
			
	if _last_interaction_collider != null:
		_last_interaction_collider = null
		if hud_node and hud_node.has_method("set_interaction_prompt"):
			hud_node.set_interaction_prompt("")
