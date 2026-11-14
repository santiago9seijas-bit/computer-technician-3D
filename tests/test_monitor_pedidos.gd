extends SceneTree

func _init():
	print("--- INICIANDO TEST: MONITOR DE PEDIDOS Y CLIENTES ---")
	var success = true
	
	# Test 1: Carga e instanciación de MonitorPedidos
	var monitor_scene = load("res://scenes/components/MonitorPedidos.tscn")
	if not monitor_scene:
		print("❌ FALLO: No se pudo cargar res://scenes/components/MonitorPedidos.tscn")
		quit(1)
		return
	var monitor_inst = monitor_scene.instantiate()
	if not monitor_inst:
		print("❌ FALLO: No se pudo instanciar MonitorPedidos.tscn")
		quit(1)
		return
	root.add_child(monitor_inst)
	print("✅ MonitorPedidos instanciado exitosamente")

	# Test 2: Métodos de interacción
	if not monitor_inst.has_method("get_interaction_prompt"):
		print("❌ FALLO: MonitorPedidos no tiene método get_interaction_prompt()")
		success = false
	else:
		var prompt = monitor_inst.get_interaction_prompt()
		print("✅ get_interaction_prompt() devolvió: ", prompt)
		if not prompt.contains("[E]"):
			print("❌ FALLO: Prompt no contiene [E]")
			success = false

	if not monitor_inst.has_method("interact"):
		print("❌ FALLO: MonitorPedidos no tiene método interact()")
		success = false

	# Test 3: Carga e instanciación de CustomerOrdersModal
	var modal_scene = load("res://scenes/ui/CustomerOrdersModal.tscn")
	if not modal_scene:
		print("❌ FALLO: No se pudo cargar res://scenes/ui/CustomerOrdersModal.tscn")
		quit(1)
		return
	var modal_inst = modal_scene.instantiate()
	if not modal_inst:
		print("❌ FALLO: No se pudo instanciar CustomerOrdersModal.tscn")
		quit(1)
		return
	root.add_child(modal_inst)
	print("✅ CustomerOrdersModal instanciado e insertado en el árbol")

	# Test 4: Comprobar elementos y filtros del modal
	if modal_inst.orders_data.size() < 3:
		print("❌ FALLO: Menos de 3 pedidos en orders_data")
		success = false
	else:
		print("✅ Cantidad de pedidos disponibles: ", modal_inst.orders_data.size())

	# Test 5: Comprobar selección y estructura de datos
	var first_ord_id = modal_inst.orders_data[0]["id"]
	if first_ord_id != "ORD-101":
		print("❌ FALLO: Primer pedido no coincide con ORD-101")
		success = false
	else:
		print("✅ Primer pedido verificado: ", first_ord_id)

	modal_inst.queue_free()
	monitor_inst.queue_free()

	# Test 6: Comprobar Level1.tscn y MesaPedidos
	var level1_scene = load("res://scenes/gameplay/Level1.tscn")
	if not level1_scene:
		print("❌ FALLO: No se pudo cargar res://scenes/gameplay/Level1.tscn")
		quit(1)
		return
	var level1_inst = level1_scene.instantiate()
	var mesa_pedidos = level1_inst.get_node_or_null("MesaPedidos")
	if not mesa_pedidos:
		print("❌ FALLO: MesaPedidos no encontrada en Level1")
		success = false
	else:
		var monitor_en_mesa = mesa_pedidos.get_node_or_null("MonitorPedidos")
		if not monitor_en_mesa:
			print("❌ FALLO: MonitorPedidos no es hijo de MesaPedidos en Level1")
			success = false
		else:
			print("✅ MonitorPedidos encontrado sobre MesaPedidos en posición: ", monitor_en_mesa.position)

	level1_inst.queue_free()

	if success:
		print("🎉 TODOS LOS TESTS DE MONITOR Y PEDIDOS PASARON EXITOSAMENTE")
		quit(0)
	else:
		print("❌ HUBO FALLOS EN LOS TESTS")
		quit(1)
