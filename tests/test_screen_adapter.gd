extends Node

func _ready() -> void:
	print("--- TEST DE RESPONSIVE SCREEN MANAGER ---")
	
	# 1. Verificar existencia del Autoload
	var rsm = get_node_or_null("/root/ResponsiveScreenManager")
	assert(rsm != null, "ResponsiveScreenManager debe estar cargado como Autoload")
	print("[1] Autoload ResponsiveScreenManager cargado correctamente.")
	
	# 2. Verificar dimensiones y cálculo inmediato de bordes
	var vp_size = rsm.get_current_viewport_size()
	print("[2] Viewport inicial detectado:", vp_size)
	assert(vp_size.x > 0 and vp_size.y > 0, "El tamaño de viewport debe ser válido")
	
	# 3. Probar adaptación de PCInspectionModal
	print("[3] Probando adaptación de PCInspectionModal...")
	var modal_scene = load("res://scenes/ui/PCInspectionModal.tscn")
	var modal = modal_scene.instantiate()
	add_child(modal)
	
	var panel = modal.get_node("ModalControl/Panel")
	var dock = modal.get_node("ModalControl/ToolsDock")
	
	rsm.adapt_panel(panel)
	print("  PCInspectionModal -> Panel scale:", panel.scale, " | ToolsDock scale:", dock.scale)
	assert(panel.scale.x <= 0.86 and panel.scale.x >= 0.60, "PCInspectionModal debe estar achicado y compacto entre 0.60 y 0.85")
	assert(dock.offset_left >= panel.offset_right - 100.0, "ToolsDock debe estar posicionado a la derecha del panel")
	
	# Verificar que el botón volver está a la altura de los 3 slots de la mochila
	var btn_v = modal.get_node_or_null("ModalControl/Panel/VBox/BackpackSection/BackpackSlots/BtnVolver")
	assert(btn_v != null, "BtnVolver debe estar dentro de BackpackSlots a la altura de los 3 slots")
	assert("VOLVER" in btn_v.text, "BtnVolver debe decir VOLVER con flecha")
	print("  BtnVolver en BackpackSlots:", btn_v.text)
	
	# Verificar que no hay título gigante arriba estorbando
	var title_lbl = modal.get_node_or_null("ModalControl/Panel/VBox/Header/TitleLabel")
	assert(title_lbl == null or not title_lbl.visible, "El título superior no debe estar presente o visible")
	
	# Verificar legibilidad de fuentes
	var status_cpu = modal.get_node("ModalControl/Panel/VBox/ComponentsContainer/RowTop/CardCPU/Margin/VBox/Status")
	var fs = status_cpu.get_theme_font_size("font_size")
	print("  Status CPU font_size:", fs)
	assert(fs >= 12, "La fuente de los estados debe ser al menos 12px para máxima legibilidad")
	
	modal.queue_free()
	
	# 4. Probar adaptación de un minijuego (RAMMinigame)
	print("[4] Probando adaptación de RAMMinigame...")
	var ram_scene = load("res://scenes/minigames/RAMMinigame.tscn")
	var ram_minigame = ram_scene.instantiate()
	add_child(ram_minigame)
	
	var ram_panel = ram_minigame.get_node("ModalControl/Panel")
	rsm.adapt_panel(ram_panel)
	print("  RAMMinigame -> Panel scale:", ram_panel.scale)
	assert(ram_panel.scale.x >= 0.95, "RAMMinigame debe escalar cómodamente cerca de 1.0 en 720p/1080p")
	
	ram_minigame.queue_free()
	
	# 5. Probar visibilidad y adaptación de HUD
	print("[5] Probando visibilidad y adaptación de HUD...")
	var hud_scene = load("res://scenes/ui/HUD.tscn")
	var hud_inst = hud_scene.instantiate()
	add_child(hud_inst)
	rsm._adapt_hud(hud_inst)
	
	var top_left = hud_inst.get_node("TopLeft")
	var top_center = hud_inst.get_node("TopCenter")
	var bottom_left = hud_inst.get_node("BottomLeft")
	var bottom_center = hud_inst.get_node("BottomCenter")
	var tools = hud_inst.get_node("BottomCenter/ToolsBar")
	
	assert(top_left.visible and top_left.modulate.a > 0.9, "TopLeft (contador errores) debe estar visible")
	assert(top_center.visible and top_center.modulate.a > 0.9, "TopCenter (contador tiempo) debe estar visible")
	assert(bottom_left.visible and bottom_left.modulate.a > 0.9, "BottomLeft (contador puntos) debe estar visible")
	assert(bottom_center.visible and bottom_center.modulate.a > 0.9, "BottomCenter (barra herramientas) debe estar visible")
	assert(tools.visible, "ToolsBar debe estar visible")
	print("  HUD: TopLeft (Errores), BottomLeft (Puntos), BottomCenter (Herramientas) y TopCenter (Tiempo) 100% visibles")
	hud_inst.queue_free()
	
	print(">>> ¡TEST DE RESPONSIVE SCREEN MANAGER EXITOSO! <<<")
	get_tree().quit(0)
