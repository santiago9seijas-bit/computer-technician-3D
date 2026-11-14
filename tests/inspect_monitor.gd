extends SceneTree

func _init():
	var lvl_scene = load("res://scenes/gameplay/Level1.tscn")
	var lvl = lvl_scene.instantiate()
	root.add_child(lvl)
	var mesa = lvl.get_node("MesaPedidos")
	var mon = mesa.get_node("MonitorPedidos")
	var pivot = mon.get_node("ModelPivot")
	var model = pivot.get_node("MonitorModel")
	var cube = model.get_node("Cube_021")
	
	print("Probando en arbol real:")
	for deg in [0, 90, 180, 270]:
		pivot.rotation_degrees = Vector3(0, deg, 0)
		var world_norm = cube.global_transform.basis * Vector3(1, 0, 0)
		print("deg: ", deg, " -> world_norm: ", world_norm, " -> dot(-1,0,0): ", world_norm.dot(Vector3(-1, 0, 0)))
		if world_norm.is_equal_approx(Vector3(-1, 0, 0)):
			print(">>> ¡EL VALOR GANADOR EN rotation_degrees ES: ", deg, " GRADOS! <<<")
			print("Transform3D del nodo pivot: ", pivot.transform)
	quit()





