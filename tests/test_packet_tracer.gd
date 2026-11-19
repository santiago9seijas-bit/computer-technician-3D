extends Node

func _ready() -> void:
	print("--- TEST PACKET TRACER & SERVER BUBBLES START ---")
	
	# Test 1: Verify Bubble Scene
	var bubble_scene = load("res://scenes/components/NetworkChallengeBubble.tscn")
	assert(bubble_scene != null, "NetworkChallengeBubble.tscn must load")
	var bubble = bubble_scene.instantiate()
	bubble.challenge_id = 0
	add_child(bubble)
	bubble._update_labels()
	var prompt = bubble.get_interaction_prompt()
	print("Bubble 0 Prompt: ", prompt)
	assert(prompt.contains("INDUCCIÓN"), "Prompt should contain INDUCCIÓN")
	assert(prompt.contains("[E]"), "Prompt should contain [E]")
	bubble.queue_free()
	print("✓ Test 1: NetworkChallengeBubble instantiates and formats prompt properly")
	
	# Test 2: Verify PacketTracerMinigame Scene & Logic
	var pt_scene = load("res://scenes/minigames/PacketTracerMinigame.tscn")
	assert(pt_scene != null, "PacketTracerMinigame.tscn must load")
	var pt = pt_scene.instantiate()
	add_child(pt)
	await get_tree().process_frame
	var btn_c = pt.find_child("BtnCancel", true, false)
	var btn_close = pt.find_child("BtnCloseHeader", true, false)
	assert(btn_c != null, "BtnCancel must exist in footer")
	assert(btn_close != null, "BtnCloseHeader must exist in header")
	
	# Verify Challenge 0 (Inducción: pc0 <-> sw0 con Cable Directo)
	pt.load_challenge(0)
	assert(pt.current_devices.has("pc0"), "Should have pc0")
	assert(pt.current_devices.has("sw0"), "Should have sw0")
	assert(pt.active_connections.size() == 0, "Initially 0 connections")
	
	# Test real mouse click event sequence on pc0
	pt._select_cable_tool(pt.CableType.STRAIGHT)
	var btn_pc = pt.current_devices["pc0"]["node"] as Button
	var btn_sw = pt.current_devices["sw0"]["node"] as Button
	
	# Mouse down on pc0
	var ev_down = InputEventMouseButton.new()
	ev_down.button_index = MOUSE_BUTTON_LEFT
	ev_down.pressed = true
	ev_down.global_position = btn_pc.global_position + Vector2(10, 10)
	btn_pc.gui_input.emit(ev_down)
	
	# Mouse up on pc0
	var ev_up = InputEventMouseButton.new()
	ev_up.button_index = MOUSE_BUTTON_LEFT
	ev_up.pressed = false
	ev_up.global_position = btn_pc.global_position + Vector2(10, 10)
	btn_pc.gui_input.emit(ev_up)
	btn_pc.pressed.emit()
	
	assert(pt.selected_device_id == "pc0", "pc0 MUST REMAIN SELECTED AFTER A FULL REAL CLICK!")
	print("✓ Real mouse click on device correctly sets selection without self-deselection")
	
	# Mouse click on sw0 to connect
	var ev_sw_down = InputEventMouseButton.new()
	ev_sw_down.button_index = MOUSE_BUTTON_LEFT
	ev_sw_down.pressed = true
	ev_sw_down.global_position = btn_sw.global_position + Vector2(10, 10)
	btn_sw.gui_input.emit(ev_sw_down)
	
	var ev_sw_up = InputEventMouseButton.new()
	ev_sw_up.button_index = MOUSE_BUTTON_LEFT
	ev_sw_up.pressed = false
	ev_sw_up.global_position = btn_sw.global_position + Vector2(10, 10)
	btn_sw.gui_input.emit(ev_sw_up)
	btn_sw.pressed.emit()
	
	assert(pt.selected_device_id == "", "Selection should clear after connecting to target")
	assert(pt.active_connections.size() == 1, "Should have 1 connection")
	assert(pt.active_connections[0]["is_valid"] == true, "Straight cable between PC and Switch is valid in Cisco PT")
	print("✓ Real mouse click sequence on target device successfully creates connection")
	
	# Ping test
	pt._on_ping_pressed()
	print("Ping started, waiting for completion...")
	
	# Allow tween / simulation to complete
	await get_tree().create_timer(1.2).timeout
	assert(pt.victory_banner.visible == true, "Victory banner should be visible after successful ping")
	print("✓ Test 2: Challenge 0 topology and ping simulation passed")
	
	# Test 3: Verify Cable Validation (Challenge 3: Crossover & Fiber)
	pt.load_challenge(3)
	assert(pt.current_devices.has("sw0"), "SW-Acceso present")
	assert(pt.current_devices.has("sw1"), "SW-Distribucion present")
	assert(pt.current_devices.has("rt0"), "Router-Core present")
	assert(pt.current_devices.has("srv0"), "Server-Mainframe present")
	
	# Connecting sw0 to sw1 with Straight cable must be INVALID
	pt._select_cable_tool(pt.CableType.STRAIGHT)
	pt._on_device_clicked("sw0")
	pt._on_device_clicked("sw1")
	assert(pt.active_connections.size() == 1, "Connection created")
	assert(pt.active_connections[0]["is_valid"] == false, "Straight cable between 2 switches must be invalid")
	
	# Now connect sw0 to sw1 with Crossover cable -> must be VALID
	pt._select_cable_tool(pt.CableType.CROSSOVER)
	pt._on_device_clicked("sw0")
	pt._on_device_clicked("sw1")
	assert(pt.active_connections.size() == 1, "Replaced connection")
	assert(pt.active_connections[0]["is_valid"] == true, "Crossover cable between switches must be valid")
	
	# Connect srv0 to rt0 with Fiber Optic -> must be VALID
	pt._select_cable_tool(pt.CableType.FIBER)
	pt._on_device_clicked("srv0")
	pt._on_device_clicked("rt0")
	assert(pt.active_connections.size() == 2, "2 connections created")
	assert(pt.active_connections[1]["is_valid"] == true, "Fiber cable between Server and Router core must be valid")
	
	pt.queue_free()
	print("✓ Test 3: Cisco cable type validation (Crossover & Fiber) passed")
	
	# Test 4: Verify LevelServer1 scene structure
	var lvl_scene = load("res://scenes/gameplay/LevelServer1.tscn")
	assert(lvl_scene != null, "LevelServer1.tscn must load")
	var lvl = lvl_scene.instantiate()
	add_child(lvl)
	var bubbles = lvl.get_node_or_null("BurbujasDesafio")
	assert(bubbles != null, "BurbujasDesafio node must exist in LevelServer1")
	assert(bubbles.get_child_count() == 4, "Must have 4 challenge bubbles")
	for i in range(4):
		var b = bubbles.get_child(i)
		assert(b.challenge_id == i, "Bubble %d must have challenge_id %d" % [i, i])
		print("Bubble in LevelServer1 found: ", b.name, " ID: ", b.challenge_id)
		
	lvl.queue_free()
	print("✓ Test 4: LevelServer1 integration verified with 4 bubbles")
	
	print("--- ALL PACKET TRACER TESTS PASSED SUCCESSFULLY! ---")
	get_tree().quit(0)
