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
var _e_was_pressed: bool = false
var _f_was_pressed: bool = false

var is_carrying_cabinet: bool = false
var carried_cabinet_data: Dictionary = {}
var held_cabinet_node: Node3D = null

func _ready() -> void:
	_ensure_action("jump", KEY_SPACE)
	_ensure_action("sprint", KEY_SHIFT)
	_ensure_action("spring", KEY_SHIFT)
	_ensure_action("interact", KEY_E)
	_ensure_action("pickup", KEY_F)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_setup_held_cabinet()
	if character_model:
		var found = character_model.find_children("*", "MeshInstance3D")
		for node in found:
			var mi = node as MeshInstance3D
			if mi:
				_cached_mesh_instances.append(mi)
	_setup_animation_player()
	# Sincronizar sensibilidad de ratón con GameManager
	var gm = get_node_or_null("/root/GameManager")
	if gm and "mouse_sensitivity_multiplier" in gm:
		mouse_sensitivity = 0.002 * gm.mouse_sensitivity_multiplier
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

func skip_intro_cinematic() -> void:
	if not is_in_cinematic:
		return
	if intro_tween and intro_tween.is_valid():
		intro_tween.kill()
		intro_tween = null
	_finish_intro_cinematic()

func _input(event: InputEvent) -> void:
	if is_in_cinematic:
		if (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventMouseButton and event.pressed) \
		or event.is_action_pressed("interact") \
		or event.is_action_pressed("pause") \
		or event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			skip_intro_cinematic()
			return

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
	var duration: float = 0.65 # Cinemática rápida y ágil para no retrasar el inicio de la partida
	
	intro_tween.set_parallel(true)
	intro_tween.tween_property(intro_camera_pivot, "rotation:y", 0.0, duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	intro_tween.tween_property(intro_camera, "position", Vector3(0.0, 0.4, 0.05), duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	intro_tween.tween_property(intro_camera, "rotation:x", 0.0, duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	intro_tween.tween_property(intro_camera, "fov", camera.fov, duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	# Disparar arranque óptico y finalizar de inmediato
	intro_tween.chain().tween_callback(_on_cinematic_optic_trigger)
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
	if GameManager.is_game_over:
		can_move = false
		velocity = Vector3.ZERO
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	can_move = enabled
	if not enabled:
		velocity = Vector3.ZERO
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

var _cached_dialog_box: Node = null
var _cached_tutorial_victory: Node = null
var _hud_searched: bool = false
var _modal_search_timer: float = 0.0

func is_dialog_active_anywhere() -> bool:
	if GameManager.is_game_over:
		return true
	if hud_node:
		var go_p = hud_node.get_node_or_null("GameOverPanel")
		if is_instance_valid(go_p) and go_p.visible:
			return true
	var cur_sc = get_tree().current_scene
	if cur_sc and "is_dialog_active" in cur_sc and cur_sc.is_dialog_active:
		return true
		
	# Caché de DialogBox con comprobación amortizada O(1)
	if is_instance_valid(_cached_dialog_box):
		if _cached_dialog_box.visible and _cached_dialog_box.get("is_active"):
			return true
	elif _modal_search_timer <= 0.0:
		_cached_dialog_box = get_tree().root.find_child("DialogBox", true, false)
		if is_instance_valid(_cached_dialog_box) and _cached_dialog_box.visible and _cached_dialog_box.get("is_active"):
			return true

	# Caché de TutorialVictoryModal con comprobación amortizada O(1)
	if is_instance_valid(_cached_tutorial_victory):
		if _cached_tutorial_victory.visible:
			return true
	elif _modal_search_timer <= 0.0:
		_cached_tutorial_victory = get_tree().root.find_child("TutorialVictoryModal", true, false)
		if is_instance_valid(_cached_tutorial_victory) and _cached_tutorial_victory.visible:
			return true

	if _modal_search_timer <= 0.0:
		_modal_search_timer = 1.0 # Evitar búsqueda recursiva del árbol en cada tick si no existen

	return false

func _unhandled_input(event: InputEvent) -> void:
	if is_in_cinematic:
		if event.is_action_pressed("interact") \
		or (event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_ESCAPE)) \
		or (event is InputEventMouseButton and event.pressed):
			_finish_intro_cinematic()
			get_viewport().set_input_as_handled()
			return
		return
		
	if is_dialog_active_anywhere():
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
		if not can_move or GameManager.is_game_paused or is_dialog_active_anywhere():
			return
		if hud_node:
			var win_panel = hud_node.get_node_or_null("WinPanel")
			if is_instance_valid(win_panel) and win_panel.visible:
				return
			var game_over_panel = hud_node.get_node_or_null("GameOverPanel")
			if is_instance_valid(game_over_panel) and game_over_panel.visible:
				return
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			if GameManager.is_any_modal_open():
				return
			var root_node = get_tree().root
			var modal_open = false
			for child in root_node.get_children():
				if child.name.ends_with("Minigame") or child.is_in_group("minigames"):
					modal_open = true
					break
			if not modal_open and not is_in_cinematic:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if _modal_search_timer > 0.0:
		_modal_search_timer -= delta

	if is_dialog_active_anywhere():
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return

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
	
	# Bobbing / oscilación de caminar mientras carga el gabinete en brazos
	if is_carrying_cabinet and held_cabinet_node and held_cabinet_node.visible:
		var is_mov = velocity.x != 0 or velocity.z != 0
		var bob_spd = 10.0 if (velocity.length() > 5.0) else 6.0
		var bob_amt = 0.016 if is_mov else 0.003
		var t = Time.get_ticks_msec() * 0.001
		held_cabinet_node.position.y = -0.38 + sin(t * bob_spd) * bob_amt
		held_cabinet_node.position.x = 0.08 + cos(t * bob_spd * 0.5) * (bob_amt * 0.6)
		
	_update_stamina_hud()
	_handle_interaction(delta)

func _setup_held_cabinet() -> void:
	if not camera:
		return
	var existing = camera.get_node_or_null("HeldCabinetRoot")
	if existing:
		held_cabinet_node = existing
		held_cabinet_node.visible = false
		return
		
	held_cabinet_node = Node3D.new()
	held_cabinet_node.name = "HeldCabinetRoot"
	held_cabinet_node.position = Vector3(0.08, -0.38, -0.65)
	held_cabinet_node.rotation_degrees = Vector3(12.0, -8.0, 3.0)
	held_cabinet_node.visible = false
	
	var gab_res = load("res://modelos_3d/escenario_3d/gabinete.glb")
	if gab_res:
		var gab_inst = gab_res.instantiate()
		gab_inst.scale = Vector3(0.011, 0.011, 0.011)
		held_cabinet_node.add_child(gab_inst)
		
	camera.add_child(held_cabinet_node)

var _f_hold_time: float = 0.0
var _ignore_f_until_release: bool = false
const MAX_CHARGE_TIME: float = 1.0 # 1 segundo para 100% de potencia
const MIN_HOLD_FOR_THROW: float = 0.22 # Menos de 0.22s es toque simple (colocar en mesa / entrega)

func _find_nearby_workbench() -> Node3D:
	if interaction_ray and interaction_ray.is_colliding():
		var col = interaction_ray.get_collider()
		if col:
			if ("WorkBench" in col.name or "Mesa" in col.name or col.is_in_group("workbenches")) and "Pedidos" not in col.name:
				return col
			var p = col.get_parent()
			if p and ("WorkBench" in p.name or "Mesa" in p.name or p.is_in_group("workbenches")) and "Pedidos" not in p.name:
				return p
			if p and p.get_parent() and ("WorkBench" in p.get_parent().name or p.get_parent().is_in_group("workbenches")):
				return p.get_parent()

	var root = get_tree().current_scene
	if root:
		var closest: Node3D = null
		var min_dist: float = 2.8
		for child in root.find_children("*WorkBench*", "StaticBody3D", true, false):
			if "Pedidos" in child.name:
				continue
			var d = global_position.distance_to(child.global_position)
			if d < min_dist:
				min_dist = d
				closest = child
		if closest:
			return closest
		for child in root.find_children("*Mesa*", "StaticBody3D", true, false):
			if "Pedidos" in child.name:
				continue
			var d = global_position.distance_to(child.global_position)
			if d < min_dist:
				min_dist = d
				closest = child
		return closest
	return null

func _get_pc_on_workbench(bench: Node3D) -> Node3D:
	if not bench:
		return null
	# 1. Comprobar si tiene un hijo que sea PC y esté visible
	for child in bench.get_children():
		if (child.name.begins_with("Computer") or child.name.begins_with("SystemsComputer") or child is DeliveredCabinet) and child.visible:
			return child
	# 2. Comprobar si alguna PC del mundo está apoyada sobre esta mesa
	var root = get_tree().current_scene
	if root:
		for pc in root.find_children("*Computer*", "StaticBody3D", true, false):
			if pc.visible and Vector2(pc.global_position.x, pc.global_position.z).distance_to(Vector2(bench.global_position.x, bench.global_position.z)) < 1.1:
				return pc
		for cab in root.find_children("*DeliveredCabinet*", "", true, false):
			if cab.visible and not cab.get("is_in_delivery_zone") and Vector2(cab.global_position.x, cab.global_position.z).distance_to(Vector2(bench.global_position.x, bench.global_position.z)) < 1.1:
				return cab
	return null

func _is_workbench_occupied(bench: Node3D) -> bool:
	return _get_pc_on_workbench(bench) != null

func _is_near_delivery_zone() -> bool:
	var root = get_tree().current_scene
	if not root:
		return false
	if "DELIVERY_WALL_POS" in root:
		var del_pos = root.DELIVERY_WALL_POS
		if global_position.distance_to(del_pos) < 3.2:
			return true
	var mesa_ped = root.find_child("MesaPedidos", true, false)
	if mesa_ped is Node3D:
		if global_position.distance_to(mesa_ped.global_position) < 3.2:
			return true
	return false

func carry_cabinet(cabinet_node: Node = null, data_override: Dictionary = {}) -> void:
	if is_carrying_cabinet:
		return
	is_carrying_cabinet = true
	_ignore_f_until_release = true
	_f_hold_time = 0.0
	carried_cabinet_data = {}
	if not data_override.is_empty():
		carried_cabinet_data = data_override
	elif cabinet_node:
		if "order_data" in cabinet_node and not cabinet_node.order_data.is_empty():
			carried_cabinet_data = cabinet_node.order_data
		if "is_repaired" in cabinet_node:
			carried_cabinet_data["is_completed"] = cabinet_node.is_repaired
			
	if held_cabinet_node:
		held_cabinet_node.visible = true
		held_cabinet_node.scale = Vector3(0.7, 0.7, 0.7)
		var tw = create_tween()
		tw.tween_property(held_cabinet_node, "scale", Vector3.ONE, 0.15)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("play_sfx"):
		gm.play_sfx("click")
	if hud_node and hud_node.has_method("set_interaction_prompt"):
		hud_node.set_interaction_prompt("[F] COLOCAR GABINETE  ·  [MANTENER F] ARROJAR")

func drop_carried_cabinet() -> void:
	if not is_carrying_cabinet:
		return
		
	var bench = _find_nearby_workbench()
	if bench:
		if _is_workbench_occupied(bench):
			var gm = get_node_or_null("/root/GameManager")
			if gm and gm.has_method("play_sfx"):
				gm.play_sfx("error")
			if hud_node and hud_node.has_method("set_interaction_prompt"):
				hud_node.set_interaction_prompt("❌ Esta mesa ya está ocupada por otro gabinete.")
			return
		_place_pc_on_workbench(bench)
		return
		
	var in_delivery = _is_near_delivery_zone()
	is_carrying_cabinet = false
	if held_cabinet_node:
		held_cabinet_node.visible = false
		
	var cabinet_scene = load("res://scenes/components/DeliveredCabinet.tscn")
	if cabinet_scene:
		var inst = cabinet_scene.instantiate()
		var drop_pos = global_position + (-global_transform.basis.z * 1.3)
		drop_pos.y = global_position.y
		
		var root = get_tree().current_scene
		if in_delivery and root and "DELIVERY_WALL_POS" in root:
			drop_pos = root.DELIVERY_WALL_POS
			inst.is_in_delivery_zone = true
		elif interaction_ray and interaction_ray.is_colliding():
			var col_pt = interaction_ray.get_collision_point()
			if global_position.distance_to(col_pt) < 2.5:
				drop_pos = col_pt
				
		if carried_cabinet_data.get("is_completed", false):
			inst.is_repaired = true
		if carried_cabinet_data.has("order_data"):
			inst.order_data = carried_cabinet_data["order_data"]
		elif not carried_cabinet_data.is_empty():
			inst.order_data = carried_cabinet_data
			
		get_parent().add_child(inst)
		inst.global_position = drop_pos
		inst.rotation.y = rotation.y
		inst.spawn_animation(drop_pos)
		
	carried_cabinet_data = {}
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("play_sfx"):
		gm.play_sfx("click")
	if hud_node and hud_node.has_method("set_interaction_prompt"):
		if in_delivery:
			hud_node.set_interaction_prompt("📦 Gabinete entregado. Finaliza el pedido en la PC de pedidos.")
		else:
			hud_node.set_interaction_prompt("")

func _place_pc_on_workbench(bench: Node3D) -> bool:
	if not bench or _is_workbench_occupied(bench):
		return false
		
	is_carrying_cabinet = false
	if held_cabinet_node:
		held_cabinet_node.visible = false
		
	var root = get_tree().current_scene
	var is_systems = false
	if root and ("Systems" in root.name or root.find_child("SystemsComputer", true, false)):
		is_systems = true
		
	var y_offset = 0.912 if is_systems else 0.72
	
	# Buscar si esta mesa ya tiene un nodo PC ocultado previamente para reutilizar
	var pc: Node3D = null
	for child in bench.get_children():
		if (child.name.begins_with("Computer") or child.name.begins_with("SystemsComputer")) and not child.visible:
			pc = child
			break
			
	if not pc:
		# Instanciar una nueva PC para esta mesa específica (soporta hasta 4 mesas con sus propias PCs)
		var scene_path = "res://scenes/components/SystemsComputerCase.tscn" if is_systems else "res://scenes/components/ComputerCase.tscn"
		var pc_scene = load(scene_path)
		if pc_scene:
			pc = pc_scene.instantiate()
			var id_num = 1
			var regex = RegEx.new()
			regex.compile("\\d+")
			var match_res = regex.search(bench.name)
			if match_res:
				id_num = match_res.get_string().to_int()
			else:
				id_num = clamp(bench.get_index() + 1, 1, 4)
				
			pc.name = ("SystemsComputer" if is_systems else "Computer") + str(id_num)
			pc.set("pc_id", id_num)
			bench.add_child(pc)
			pc.position = Vector3(0.0, y_offset, 0.0)
			pc.rotation = Vector3.ZERO
			
	if pc:
		pc.position = Vector3(0.0, y_offset, 0.0)
		pc.rotation = Vector3.ZERO
		if pc.has_method("restore_from_carried"):
			pc.restore_from_carried(carried_cabinet_data)
		else:
			pc.visible = true
			if "collision_layer" in pc:
				pc.collision_layer = 1
				pc.collision_mask = 1
		if carried_cabinet_data.has("order_data"):
			pc.set("order_data", carried_cabinet_data["order_data"])
		if pc.has_method("update_3d_state"):
			pc.update_3d_state()
			
	carried_cabinet_data = {}
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("play_sfx"):
		gm.play_sfx("click")
	if hud_node and hud_node.has_method("set_interaction_prompt"):
		hud_node.set_interaction_prompt("🖥️ Gabinete colocado en la mesa de trabajo.")
	return true

func throw_carried_cabinet(force: float) -> void:
	if not is_carrying_cabinet:
		return
	is_carrying_cabinet = false
	if held_cabinet_node:
		held_cabinet_node.visible = false
		
	var sm = get_node_or_null("/root/SaveManager")
	if sm and force > 12.0:
		sm.unlock_achievement("throw_master")
		
	var cabinet_scene = load("res://scenes/components/DeliveredCabinet.tscn")
	if cabinet_scene:
		var inst = cabinet_scene.instantiate()
		var throw_origin = camera.global_position + (-camera.global_transform.basis.z * 0.7) + Vector3(0.0, -0.2, 0.0)
		var aim_dir = -camera.global_transform.basis.z.normalized()
		var throw_vel = aim_dir * force
		
		if carried_cabinet_data.get("is_completed", false):
			inst.is_repaired = true
		if carried_cabinet_data.has("order_data"):
			inst.order_data = carried_cabinet_data["order_data"]
		elif not carried_cabinet_data.is_empty():
			inst.order_data = carried_cabinet_data
			
		get_parent().add_child(inst)
		inst.throw_from(throw_origin, throw_vel)
		
	carried_cabinet_data = {}
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("play_sfx"):
		gm.play_sfx("click")
	if hud_node and hud_node.has_method("set_interaction_prompt"):
		hud_node.set_interaction_prompt("💥 ¡Gabinete arrojado!")

func _update_stamina_hud() -> void:
	if not hud_node and not _hud_searched:
		_hud_searched = true
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
	# Remover clics de ratón de la acción interactuar para impedir que doble clic abra la PC
	if action_name == "interact":
		for existing in InputMap.action_get_events(action_name):
			if existing is InputEventMouseButton:
				InputMap.action_erase_event(action_name, existing)
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

func _handle_interaction(delta: float = 0.016) -> void:
	var e_pressed = Input.is_physical_key_pressed(KEY_E) or Input.is_key_pressed(KEY_E)
	var just_e = e_pressed and not _e_was_pressed
	_e_was_pressed = e_pressed

	var f_pressed = Input.is_physical_key_pressed(KEY_F) or Input.is_key_pressed(KEY_F) or Input.is_action_pressed("pickup")
	var just_f = f_pressed and not _f_was_pressed

	if not can_move or GameManager.is_game_paused or is_in_cinematic:
		_f_hold_time = 0.0
		_f_was_pressed = f_pressed
		if hud_node and hud_node.has_method("set_throw_charge"):
			hud_node.set_throw_charge(false)
		if _last_interaction_collider != null:
			_last_interaction_collider = null
			if hud_node and hud_node.has_method("set_interaction_prompt"):
				hud_node.set_interaction_prompt("")
		return

	# Si ya está cargando el gabinete en brazos: pulsar = colocar, mantener pulsado = cargar barra y arrojar
	if is_carrying_cabinet:
		if _ignore_f_until_release:
			if not f_pressed:
				_ignore_f_until_release = false
			_f_was_pressed = f_pressed
			return
		if f_pressed:
			_f_hold_time += delta
			if _f_hold_time >= MIN_HOLD_FOR_THROW:
				var charge_ratio = clamp((_f_hold_time - MIN_HOLD_FOR_THROW) / (MAX_CHARGE_TIME - MIN_HOLD_FOR_THROW), 0.0, 1.0)
				if hud_node and hud_node.has_method("set_throw_charge"):
					hud_node.set_throw_charge(true, charge_ratio)
				if hud_node and hud_node.has_method("set_interaction_prompt"):
					hud_node.set_interaction_prompt("⚡ FUERZA: %d%% · SUELTA [F] PARA ARROJAR" % int(charge_ratio * 100.0))
			else:
				var bench = _find_nearby_workbench()
				var prompt_str = "[F] COLOCAR GABINETE  ·  [MANTENER F] ARROJAR"
				if bench:
					if _is_workbench_occupied(bench):
						prompt_str = "⚠️ MESA OCUPADA · NO PUEDES COLOCAR OTRO GABINETE"
					else:
						prompt_str = "[F] COLOCAR EN MESA  ·  [MANTENER F] ARROJAR"
				elif _is_near_delivery_zone():
					prompt_str = "[F] COLOCAR EN ENTREGA  ·  [MANTENER F] ARROJAR"
				if hud_node and hud_node.has_method("set_interaction_prompt"):
					hud_node.set_interaction_prompt(prompt_str)
		else:
			if _f_was_pressed:
				# Tecla F recién liberada
				if _f_hold_time >= MIN_HOLD_FOR_THROW:
					# LANZAMIENTO CON POTENCIA CARGADA
					var charge_ratio = clamp((_f_hold_time - MIN_HOLD_FOR_THROW) / (MAX_CHARGE_TIME - MIN_HOLD_FOR_THROW), 0.0, 1.0)
					var throw_force = lerp(8.0, 24.0, charge_ratio)
					if hud_node and hud_node.has_method("set_throw_charge"):
						hud_node.set_throw_charge(false)
					throw_carried_cabinet(throw_force)
				else:
					# TOQUE CORTO -> COLOCACIÓN / SOLTAR
					if hud_node and hud_node.has_method("set_throw_charge"):
						hud_node.set_throw_charge(false)
					var bench = _find_nearby_workbench()
					if bench and _is_workbench_occupied(bench):
						var gm = get_node_or_null("/root/GameManager")
						if gm and gm.has_method("play_sfx"):
							gm.play_sfx("error")
						if hud_node and hud_node.has_method("set_interaction_prompt"):
							hud_node.set_interaction_prompt("❌ Esta mesa ya está ocupada por otro gabinete.")
					else:
						drop_carried_cabinet()
				_f_hold_time = 0.0
			else:
				_f_hold_time = 0.0
				if hud_node and hud_node.has_method("set_throw_charge"):
					hud_node.set_throw_charge(false)
				var bench = _find_nearby_workbench()
				var prompt_str = "[F] COLOCAR GABINETE  ·  [MANTENER F] ARROJAR"
				if bench:
					if _is_workbench_occupied(bench):
						prompt_str = "⚠️ MESA OCUPADA · NO PUEDES COLOCAR OTRO GABINETE"
					else:
						prompt_str = "[F] COLOCAR EN MESA  ·  [MANTENER F] ARROJAR"
				elif _is_near_delivery_zone():
					prompt_str = "[F] COLOCAR EN ENTREGA  ·  [MANTENER F] ARROJAR"
				if hud_node and hud_node.has_method("set_interaction_prompt"):
					hud_node.set_interaction_prompt(prompt_str)
					
		_f_was_pressed = f_pressed
		return

	_f_was_pressed = f_pressed
	_f_hold_time = 0.0
	if hud_node and hud_node.has_method("set_throw_charge"):
		hud_node.set_throw_charge(false)

	if interaction_ray.is_colliding():
		var target = interaction_ray.get_collider()
		if target:
			if target != _last_interaction_collider:
				_last_interaction_collider = target
				if hud_node and hud_node.has_method("set_interaction_prompt"):
					var p = ""
					if target.has_method("get_interaction_prompt"):
						p = target.get_interaction_prompt()
					elif target.has_method("can_pickup_with_f") and target.can_pickup_with_f():
						p = "[F] CARGAR GABINETE EN BRAZOS"
					hud_node.set_interaction_prompt(p)

			if just_f and target.has_method("can_pickup_with_f") and target.can_pickup_with_f():
				_last_interaction_collider = null
				if target.has_method("pickup_to_arms"):
					var data = target.pickup_to_arms(self)
					carry_cabinet(null, data)
				elif target.has_method("pickup"):
					carry_cabinet(target)
					target.pickup(self)
				else:
					carry_cabinet(target)
				return

			if target.has_method("interact") and (just_e or (Input.is_action_just_pressed("interact") and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))):
				_last_interaction_collider = null
				target.interact(self)
				return
			return
			
	if _last_interaction_collider != null:
		_last_interaction_collider = null
		if hud_node and hud_node.has_method("set_interaction_prompt"):
			hud_node.set_interaction_prompt("")
