extends Node3D

const INTRO_SCENE: PackedScene = preload("res://scenes/ui/LevelSystemsIntroModal.tscn")
const DELIVERED_CABINET_SCENE: PackedScene = preload("res://scenes/components/DeliveredCabinet.tscn")
const DELIVERY_WALL_POS: Vector3 = Vector3(3.2, 0.0, 1.5)

@onready var player: CharacterBody3D = $Player
@onready var hud: Control = $CanvasLayerHUD/HUD

func _ready() -> void:
	GameManager.order_accepted.connect(_on_order_accepted)
	GameManager.order_completed.connect(_on_order_completed)
	if player and hud:
		player.hud_node = hud
		
	var btn_reintentar = hud.get_node_or_null("GameOverPanel/VBox/BtnReiniciarGO") as Button
	if btn_reintentar:
		btn_reintentar.pressed.connect(_on_reintentar)
		
	var btn_siguiente = hud.get_node_or_null("WinPanel/VBox/BtnSiguiente") as Button
	if btn_siguiente:
		btn_siguiente.pressed.connect(_on_siguiente)

	# Pre-inicializar el nivel con el tiempo según la dificultad seleccionada
	GameManager.start_level(GameManager.get_difficulty_time())
	GameManager.timer_active = false

	# Cinemática aérea suave optimizada
	if player and player.has_method("play_intro_cinematic"):
		player.play_intro_cinematic(func():
			_show_mission_briefing()
		)
	else:
		_show_mission_briefing()

func _show_mission_briefing() -> void:
	GameManager.timer_active = false
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var modal = INTRO_SCENE.instantiate()
	var hud_layer = get_node_or_null("CanvasLayerHUD")
	if hud_layer:
		hud_layer.add_child(modal)
	else:
		add_child(modal)
		
	modal.started.connect(func():
		GameManager.timer_active = true
		if player and player.has_method("set_movement_enabled"):
			player.set_movement_enabled(true)
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	)

func _on_reintentar() -> void:
	get_tree().reload_current_scene()

func _on_siguiente() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.has_method("mark_node_completed"):
		sm.mark_node_completed("sistema", 7)
	CyberPlayTransition.play_exit(get_tree(), "sistema")

func _on_order_accepted(order_data: Dictionary) -> void:
	if not DELIVERED_CABINET_SCENE:
		return
	var cabinet = DELIVERED_CABINET_SCENE.instantiate()
	cabinet.order_data = order_data
	add_child(cabinet)
	cabinet.spawn_animation(DELIVERY_WALL_POS)
	if hud and hud.has_method("set_interaction_prompt"):
		hud.set_interaction_prompt("📦 ¡Gabinete entregado junto a la pared! Recógelo con [F]")

func _on_order_completed(order_data: Dictionary) -> void:
	var cabinets = get_tree().get_nodes_in_group("delivered_cabinets")
	if cabinets.is_empty():
		for child in find_children("*", "DeliveredCabinet", true, false):
			cabinets.append(child)
			
	for cab in cabinets:
		if cab is DeliveredCabinet and is_instance_valid(cab):
			cab.disappear_animation()
			break
			
	if hud and hud.has_method("set_interaction_prompt"):
		hud.set_interaction_prompt("🎉 ¡Pedido completado y retirado con éxito!")
