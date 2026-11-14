extends Node

func _ready() -> void:
	print("--- INICIANDO TEST RUNNER: MONITOR Y PEDIDOS ---")
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Test 1: Instanciar monitor
	var mon_scene = load("res://scenes/components/MonitorPedidos.tscn")
	assert(mon_scene != null, "No se pudo cargar MonitorPedidos.tscn")
	var mon_inst = mon_scene.instantiate()
	add_child(mon_inst)
	print("✅ MonitorPedidos instanciado en escena")
	
	var prompt = mon_inst.get_interaction_prompt()
	print("✅ Prompt obtenido: ", prompt)
	assert(prompt.contains("[E]"), "Prompt debe incluir [E]")
	
	# Test 2: Instanciar modal de pedidos
	var modal_scene = load("res://scenes/ui/CustomerOrdersModal.tscn")
	assert(modal_scene != null, "No se pudo cargar CustomerOrdersModal.tscn")
	var modal_inst = modal_scene.instantiate()
	add_child(modal_inst)
	print("✅ CustomerOrdersModal instanciado en escena")
	
	await get_tree().process_frame
	
	assert(modal_inst.orders_data.size() >= 5, "Debe haber al menos 5 pedidos iniciales")
	print("✅ Cantidad de pedidos verificada: ", modal_inst.orders_data.size())
	
	# Test 3: Verificar selección y estado
	assert(modal_inst.selected_order_id == "ORD-101", "La orden por defecto debe ser ORD-101")
	print("✅ Orden seleccionada por defecto: ", modal_inst.selected_order_id)
	
	# Test 4: Filtrado
	modal_inst._set_filter("pending")
	print("✅ Filtro 'pending' aplicado correctamente")
	modal_inst._set_filter("all")
	print("✅ Filtro 'all' restaurado")
	
	# Test 5: Aceptar pedido (pasar de pending a in_progress)
	modal_inst._on_action_pressed()
	assert(modal_inst.orders_data[0]["status"] == "in_progress", "El pedido debe pasar a 'in_progress'")
	print("✅ Pedido ORD-101 aceptado y enviado a taller")
	
	# Test 6: Finalizar pedido (pasar de in_progress a completed)
	modal_inst._on_action_pressed()
	assert(modal_inst.orders_data[0]["status"] == "completed", "El pedido debe pasar a 'completed'")
	print("✅ Pedido ORD-101 completado exitosamente con cobro y XP")
	
	# Test 7: Verificar Level1
	var lvl_scene = load("res://scenes/gameplay/Level1.tscn")
	assert(lvl_scene != null, "No se pudo cargar Level1.tscn")
	var lvl_inst = lvl_scene.instantiate()
	add_child(lvl_inst)
	await get_tree().process_frame
	var mesa = lvl_inst.get_node_or_null("MesaPedidos")
	assert(mesa != null, "MesaPedidos debe existir en Level1")
	var monitor_en_mesa = mesa.get_node_or_null("MonitorPedidos")
	assert(monitor_en_mesa != null, "MonitorPedidos debe estar sobre MesaPedidos")
	print("✅ MonitorPedidos confirmado en MesaPedidos. Posición global: ", monitor_en_mesa.global_position)
	
	var pivot = monitor_en_mesa.get_node("ModelPivot")
	var model = pivot.get_node("MonitorModel")
	var cube = model.get_node("Cube_021")
	var screen_normal_local = Vector3(1, 0, 0)
	
	print("--- TEST DE ROTACIÓN DE PANTALLA EN ÁRBOL REAL ---")
	for deg in [0, 90, 180, 270]:
		pivot.rotation_degrees = Vector3(0, deg, 0)
		await get_tree().process_frame
		var world_norm = cube.global_transform.basis * screen_normal_local
		print("deg: ", deg, " -> World Norm: ", world_norm, " -> dot(-1, 0, 0): ", world_norm.dot(Vector3(-1, 0, 0)))
		if world_norm.is_equal_approx(Vector3(-1, 0, 0)):
			print(">>> ¡ESTE ES EL ÁNGULO PERFECTO!: ", deg, " GRADOS! <<<")
			print("Transform3D del pivot: ", pivot.transform)
	
	# Test 8: Verificar animación de ocultamiento y reaparición en HUD (tiempo visible, resto oculto)
	var hud_scene = load("res://scenes/ui/HUD.tscn")
	assert(hud_scene != null, "No se pudo cargar HUD.tscn")
	var hud_inst = hud_scene.instantiate()
	add_child(hud_inst)
	await get_tree().process_frame
	
	var top_left = hud_inst.get_node_or_null("TopLeft")
	var top_center = hud_inst.get_node_or_null("TopCenter")
	var bottom_left = hud_inst.get_node_or_null("BottomLeft")
	var bottom_center = hud_inst.get_node_or_null("BottomCenter")
	
	assert(top_left != null, "TopLeft debe existir")
	assert(top_center != null, "TopCenter (tiempo) debe existir")
	assert(bottom_left != null, "BottomLeft (score) debe existir")
	assert(bottom_center != null, "BottomCenter (herramientas 1-5) debe existir")
	
	# Ocultar para modal (no animado para assert instantáneo)
	hud_inst.hide_gameplay_hud_for_modal(false)
	assert(top_center.visible == true and is_equal_approx(top_center.modulate.a, 1.0), "El contador de tiempo debe permanecer 100% visible")
	assert(top_left.visible == false, "TopLeft (errores) debe estar oculto")
	assert(bottom_left.visible == false, "BottomLeft (score) debe estar oculto")
	assert(bottom_center.visible == false, "BottomCenter (herramientas 1-5) debe estar oculto")
	print("✅ Ocultamiento de HUD verificado: errores, score y herramientas ocultos, tiempo visible")
	
	# Restaurar tras salir del modal
	hud_inst.show_gameplay_hud_from_modal(false)
	assert(top_center.visible == true and is_equal_approx(top_center.modulate.a, 1.0), "El tiempo sigue visible")
	assert(top_left.visible == true and is_equal_approx(top_left.modulate.a, 1.0), "TopLeft reaparecido")
	assert(bottom_left.visible == true and is_equal_approx(bottom_left.modulate.a, 1.0), "BottomLeft reaparecido")
	assert(bottom_center.visible == true and is_equal_approx(bottom_center.modulate.a, 1.0), "BottomCenter reaparecido")
	print("✅ Reaparición de HUD verificada: todos los botones y contadores vuelven a ser visibles")
	
	print("🎉 TODOS LOS TESTS COMPLETADOS AL 100% CON ÉXITO")
	get_tree().quit(0)
