extends Node

func _ready() -> void:
	print("--- TEST LEVEL SELECT PACKET TRACER INTEGRATION START ---")
	
	# Reset save state for a predictable progression test
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.has_method("reset_progression_lock"):
		sm.reset_progression_lock()
		
	# Test 1: Load LevelSelect scene
	var ls_scene = load("res://scenes/menus/LevelSelect.tscn")
	assert(ls_scene != null, "LevelSelect.tscn must load")
	var ls = ls_scene.instantiate()
	add_child(ls)
	await get_tree().process_frame
	
	# Switch to servidor mode
	ls._switch_mode("servidor")
	await get_tree().process_frame
	
	var srv_data = ls.LEVELS_DATA["servidor"]
	print("Servidor data nodes count: ", srv_data.size())
	assert(srv_data.size() >= 18, "Servidor data must contain at least 18 nodes (0-17)")
	
	for i in [14, 15, 16, 17]:
		var node_info = srv_data[i]
		assert(node_info.get("is_network", false) == true, "Node %d must be is_network" % i)
		assert(node_info.get("challenge_id", -1) == (i - 14), "Node %d must have challenge_id %d" % [i, i - 14])
		print("Node %d: %s | Challenge: %d" % [i, node_info["title"], node_info["challenge_id"]])
		
	# Verify ConstellationGraph nodes for servidor and distributed positions
	var graph = ls.graph_lines
	assert(graph != null, "GraphLines must exist")
	assert(graph.nodes.size() >= 18, "ConstellationGraph must have 18 nodes for servidor, found %d" % graph.nodes.size())
	assert(graph.nodes[14] == Vector2(480, 210), "Node 14 must be at (480, 210)")
	assert(graph.nodes[15] == Vector2(900, 210), "Node 15 must be at (900, 210)")
	assert(graph.nodes[16] == Vector2(320, 520), "Node 16 must be at (320, 520)")
	assert(graph.nodes[17] == Vector2(1040, 540), "Node 17 must be at (1040, 540)")
	print("✓ Distributed node coordinates verified across all 4 quadrants")
	
	# Verify node buttons
	assert(ls.node_buttons.size() >= 18, "LevelSelect must have 18 node buttons, found %d" % ls.node_buttons.size())
	
	# Verify initial unlock states: Node 14 is unlocked, 15..17 locked initially
	assert(graph.is_node_unlocked(14) == true, "Node 14 (Cisco Intro) must be unlocked initially")
	assert(graph.is_node_unlocked(15) == false, "Node 15 (Reto 1) must be locked initially")
	assert(graph.is_node_unlocked(16) == false, "Node 16 (Reto 2) must be locked initially")
	assert(graph.is_node_unlocked(17) == false, "Node 17 (Reto 3) must be locked initially")
	print("✓ Initial unlock state verified (Node 14 unlocked, 15-17 locked)")
	
	# Verify progression unlock: completing Node 14 unlocks Node 15
	if sm:
		sm.mark_node_completed("servidor", 14)
		ls._sync_progression_from_save()
		assert(graph.is_node_unlocked(15) == true, "Node 15 must unlock after completing Node 14")
		print("✓ Completing Node 14 unlocked Node 15")
		
		# Completing Node 15 unlocks Node 16
		sm.mark_node_completed("servidor", 15)
		ls._sync_progression_from_save()
		assert(graph.is_node_unlocked(16) == true, "Node 16 must unlock after completing Node 15")
		print("✓ Completing Node 15 unlocked Node 16")
		
		# Completing Node 16 unlocks Node 17
		sm.mark_node_completed("servidor", 16)
		ls._sync_progression_from_save()
		assert(graph.is_node_unlocked(17) == true, "Node 17 must unlock after completing Node 16")
		print("✓ Completing Node 16 unlocked Node 17")
	
	# Test 2: Simulate clicking node 14 (Inducción Cisco)
	ls._on_node_clicked(14)
	await get_tree().process_frame
	assert(ls.is_level_zoomed == true, "Level must be zoomed")
	assert(ls.active_zoomed_index == 14, "Active zoomed index must be 14")
	assert(ls.tutorial_info_panel.visible == true, "TutorialInfoPanel must be visible for network challenge")
	print("✓ Test 2: Node 14 zoom and panel presentation passed")
	
	# Test 3: Simulate launching the challenge from LevelSelect
	ls._on_btn_play_level_pressed()
	await get_tree().process_frame
	assert(ls.current_minigame_instance != null, "PacketTracerMinigame instance must be created")
	assert(ls.current_minigame_instance.current_challenge_id == 0, "Must be loaded with challenge 0")
	assert(ls.current_minigame_instance.current_devices.has("pc0"), "pc0 device must be present in minigame")
	print("✓ Test 3: Minigame launched directly from LevelSelect circle node")
	
	# Test 4: Finish minigame and verify clean cleanup
	ls.current_minigame_instance.minigame_finished.emit(true)
	await get_tree().process_frame
	assert(ls.current_minigame_instance == null, "Minigame instance must be freed after finish")
	assert(ls.is_launching_level == false, "is_launching_level must be reset to false")
	print("✓ Test 4: Minigame cleanup and return to constellation verified")
	
	ls.queue_free()
	print("--- ALL LEVEL SELECT PACKET TRACER TESTS PASSED SUCCESSFULLY! ---")
	get_tree().quit(0)
