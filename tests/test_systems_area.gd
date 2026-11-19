extends Node

func _ready() -> void:
	print("--- INICIANDO TEST: ÁREA DE SISTEMAS, MESAS Y MINIJUEGO DE CONEXIÓN ---")
	await get_tree().process_frame
	await get_tree().process_frame
	
	# 1. Cargar e instanciar LevelSystems1
	var lvl_scene = load("res://scenes/gameplay/LevelSystems1.tscn")
	assert(lvl_scene != null, "No se pudo cargar LevelSystems1.tscn")
	var lvl = lvl_scene.instantiate()
	add_child(lvl)
	await get_tree().process_frame
	print("✅ LevelSystems1 cargado e instanciado.")
	
	# 2. Verificar las 4 paredes con pared.glb
	var walls = lvl.get_node_or_null("Room/Walls")
	assert(walls != null, "El nodo Room/Walls debe existir")
	var w_north = walls.get_node_or_null("WallNorth/ParedModel")
	var w_south = walls.get_node_or_null("WallSouth/ParedModel")
	var w_west = walls.get_node_or_null("WallWest/ParedModel")
	var w_east = walls.get_node_or_null("WallEast/ParedModel")
	assert(w_north != null and w_south != null and w_west != null and w_east != null, "Las 4 paredes deben tener ParedModel")
	print("✅ 4 paredes con modelo 'pared' verificadas.")
	
	# 3. Verificar las 4 mesas de trabajo con mesa de pedidos.glb giradas viendo hacia el centro de la habitación
	var mesas = lvl.get_node_or_null("MesasTrabajo")
	assert(mesas != null, "El nodo MesasTrabajo debe existir")
	for i in range(1, 5):
		var wb = mesas.get_node_or_null("WorkBench%d" % i)
		assert(wb != null, "WorkBench%d debe existir" % i)
		# basis.z debe apuntar hacia -X (-1, 0, 0) para que el frente dé al cuarto y no a la pared
		assert(wb.transform.basis.z.x > 0.9, "WorkBench%d debe estar girada viendo a la habitación" % i)
		var mesa_model = wb.get_node_or_null("MesaModel")
		assert(mesa_model != null, "WorkBench%d debe tener MesaModel" % i)
		var mon = wb.get_node_or_null("MonitorTaller")
		var rat = wb.get_node_or_null("RatonTaller")
		assert(mon != null, "WorkBench%d debe tener MonitorTaller" % i)
		assert(rat != null, "WorkBench%d debe tener RatonTaller" % i)
	print("✅ 4 mesas de trabajo giradas hacia la habitación con monitor y ratón verificadas.")
	
	# 4. Verificar mesa de pedidos en esquina girada hacia el cuarto
	var mesa_ped = lvl.get_node_or_null("MesaPedidos")
	assert(mesa_ped != null, "MesaPedidos debe existir")
	assert(mesa_ped.transform.basis.z.x < -0.9, "MesaPedidos debe estar girada viendo a la habitación")
	var mon_ped = mesa_ped.get_node_or_null("MonitorPedidos")
	var rat_ped = mesa_ped.get_node_or_null("RatonPedidos")
	assert(mon_ped != null, "MesaPedidos debe tener MonitorPedidos")
	assert(rat_ped != null, "MesaPedidos debe tener RatonPedidos")
	print("✅ Mesa de pedidos de esquina girada correctamente hacia el cuarto verificada.")
	
	# 5. Verificar posición de SystemsComputer1 en el lado izquierdo de la mesa (perspectiva del jugador)
	var pc = mesas.get_node_or_null("WorkBench1/SystemsComputer1")
	assert(pc != null, "SystemsComputer1 debe existir en WorkBench1")
	print("Posición local de la PC en la mesa: ", pc.position)
	assert(pc.position.x > 0.35, "La PC debe colocarse en el lado izquierdo de la mesa (x > 0.35)")
	print("✅ PC colocada en el lado izquierdo del modelo de mesa de pedidos.")
	
	# 6. Probar pickup con [F] y colocación en WorkBench2
	var player = lvl.get_node_or_null("Player")
	assert(player != null, "Player debe existir")
	
	var carried_data = pc.pickup_to_arms(player)
	assert(not pc.visible, "La PC debe quedar oculta al ser cargada con F")
	assert(carried_data.has("type") and carried_data["type"] == "sistema", "Datos deben ser de tipo sistema")
	player.carry_cabinet(null, carried_data)
	assert(player.is_carrying_cabinet, "El jugador debe estar cargando el gabinete")
	print("✅ Gabinete recogido con [F] en brazos.")
	
	var wb2 = mesas.get_node_or_null("WorkBench2")
	var placed = player._place_pc_on_workbench(wb2)
	assert(placed, "Debe colocarse exitosamente en WorkBench2")
	var pc2 = player._get_pc_on_workbench(wb2)
	assert(pc2 != null and pc2.visible, "WorkBench2 debe tener la PC colocada y visible")
	assert(pc2.position.x > 0.35, "La PC en WorkBench2 debe colocarse en el lado izquierdo (x > 0.35)")
	print("✅ Gabinete colocado con [F] en WorkBench2 en el lado izquierdo: ", pc2.position)
	
	# 7. Probar minijuego de conexión de sistemas antes de reparar
	assert(not pc2.is_connected, "La PC debe iniciar sin conexión")
	pc2.interact(player)
	await get_tree().process_frame
	
	var conn_minigame = get_tree().root.get_node_or_null("SystemConnectionMinigame")
	assert(conn_minigame != null, "Al interactuar antes de reparar debe abrirse SystemConnectionMinigame")
	print("✅ Minijuego de conexión de sistemas lanzado correctamente.")
	
	# Simular pasos del minijuego: conectar cable, sincronizar canales y ejecutar handshake
	conn_minigame._on_connect_cable_pressed()
	assert(conn_minigame.is_cable_connected, "El cable debe estar conectado")
	conn_minigame._toggle_channel("A")
	conn_minigame._toggle_channel("B")
	conn_minigame._toggle_channel("C")
	await get_tree().process_frame
	
	conn_minigame._on_continue_pressed()
	await get_tree().process_frame
	
	assert(pc2.is_connected, "Tras el minijuego de conexión exitoso, is_connected debe ser true")
	print("✅ Minijuego de conexión completado con éxito, is_connected = true.")
	
	var systems_modal = get_tree().root.get_node_or_null("PCSystemsModal")
	assert(systems_modal != null, "Tras conectar, debe abrirse automáticamente PCSystemsModal")
	print("✅ PCSystemsModal abierta automáticamente tras la conexión.")
	systems_modal._on_volver_pressed()
	await get_tree().process_frame
	
	# 8. Test de lanzamiento con la F mirando horizontal / recto
	player.carry_cabinet(pc2)
	assert(player.is_carrying_cabinet, "Jugador debe cargar la PC para test de lanzamiento")
	
	# Simular cámara mirando perfectamente recta/horizontal (basis.z = Vector3(0, 0, 1), cam_forward = (0, 0, -1), y = 0)
	var cam = player.get_node("Camera3D")
	cam.transform = Transform3D.IDENTITY
	player.throw_carried_cabinet(24.0)
	await get_tree().process_frame
	
	var thrown_cabs = get_tree().get_nodes_in_group("delivered_cabinets")
	assert(thrown_cabs.size() > 0, "Debe existir al menos un gabinete arrojado")
	var last_cab = thrown_cabs[thrown_cabs.size() - 1] as DeliveredCabinet
	assert(last_cab != null and last_cab.is_flying, "El gabinete debe estar volando")
	print("Velocidad de lanzamiento con mouse recto: ", last_cab.throw_velocity)
	assert(last_cab.throw_velocity.y >= 5.0, "El gabinete debe tener elevación suficiente (vy >= 5.0) incluso con mouse recto")
	assert(last_cab.throw_velocity.length() >= 20.0, "El gabinete debe mantener fuerza consistente al lanzar recto")
	print("✅ Test de lanzamiento potente con mouse recto exitoso: ", last_cab.throw_velocity)
	
	print("--- TODOS LOS TESTS DEL ÁREA DE SISTEMAS Y LANZAMIENTO PASARON EXITOSAMENTE ---")
	get_tree().quit()
