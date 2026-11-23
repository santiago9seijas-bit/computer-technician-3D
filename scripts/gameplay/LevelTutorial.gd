extends Node3D

# =============================================================================
# NIVEL TUTORIAL 3D MULTIMODO (REPARACIÓN, SISTEMAS, SERVIDOR)
# PERSONAJES CON PERSONALIDAD Y DIÁLOGOS DINÁMICOS [E]
# - REPARACIÓN: Joa (mujer tímida, introvertida, lentes, meticulosa y dulce)
# - SISTEMAS: Jeremias (chico de rulos, carismático, extrovertido, burlón / sysadmin)
# - SERVIDOR: Santiago (chico alto, pelo liso, ojos claros, sarcástico / chistes malos)
# INTERRUPCIÓN ESPECIAL EN ESCAPE: Cada personaje reacciona si el jugador intenta salir
# =============================================================================

const DIALOG_SCENE: PackedScene = preload("res://scenes/ui/DialogBox.tscn")
const VICTORY_MODAL_SCENE: PackedScene = preload("res://scenes/ui/TutorialVictoryModal.tscn")
const SYSTEMS_PC_SCENE: PackedScene = preload("res://scenes/components/SystemsComputerCase.tscn")
const SERVER_RACK_SCENE: PackedScene = preload("res://scenes/components/ServerRackCase.tscn")

# Minijuegos para Sistemas (3 minijuegos interactivos)
const OS_MINIGAME_SCENE: PackedScene = preload("res://scenes/minigames/OSInstallMinigame.tscn")
const MALWARE_MINIGAME_SCENE: PackedScene = preload("res://scenes/minigames/MalwareScannerMinigame.tscn")
const DRIVER_MINIGAME_SCENE: PackedScene = preload("res://scenes/minigames/DriverUpdaterMinigame.tscn")
const ADWARE_MINIGAME_SCENE: PackedScene = preload("res://scenes/minigames/AdwareCleanerMinigame.tscn")
const USB_MINIGAME_SCENE: PackedScene = preload("res://scenes/minigames/UsbPendriveMinigame.tscn")

# Minijuegos para Servidor (2 minijuegos finales)
const DEBUGGER_MINIGAME_SCENE: PackedScene = preload("res://scenes/minigames/CodeDebuggerMinigame.tscn")
const LIQUID_COOLING_SCENE: PackedScene = preload("res://scenes/minigames/LiquidCoolingMinigame.tscn")

enum ReparacionStep {
	INTRO,
	WAIT_INSPECT_PC,
	WAIT_REMOVE_RAM,
	WAIT_FETCH_RAM,
	WAIT_INSTALL_RAM,
	WAIT_HANDLE_SSD,
	WAIT_HANDLE_GPU,
	WAIT_HANDLE_COOLER,
	WAIT_HANDLE_CPU,
	WAIT_HANDLE_PSU,
	COMPLETED
}

enum SistemasStep {
	INTRO,
	WAIT_INTERACT_OS,
	WAIT_INTERACT_MALWARE,
	WAIT_INTERACT_DRIVERS,
	COMPLETED
}

enum ServidorStep {
	INTRO,
	WAIT_INTERACT_DEBUGGER,
	WAIT_INTERACT_COOLING,
	COMPLETED
}

@onready var player: CharacterBody3D = $Player
@onready var hud: Control = $CanvasLayerHUD/HUD
@onready var pc: StaticBody3D = $WorkBench/Computer1
@onready var work_bench: StaticBody3D = $WorkBench
@onready var holo_banner: MeshInstance3D = $WorkBench/HoloBanner
@onready var holo_sub_banner: MeshInstance3D = $WorkBench/HoloSubBanner

@onready var spares_ram: StaticBody3D = get_node_or_null("SparesRAM")
@onready var spares_hdd: StaticBody3D = get_node_or_null("SparesHDD")
@onready var spares_psu: StaticBody3D = get_node_or_null("SparesPSU")
@onready var trash_bin: StaticBody3D = get_node_or_null("TrashBin")
@onready var wall_dispenser: StaticBody3D = get_node_or_null("WallDispenser")

var current_mode: String = "reparacion"
var dialog_box: Control = null
var victory_modal: Control = null
var is_dialog_active: bool = false
var is_esc_interrupt_active: bool = false
var active_minigame: Node = null

static var target_component: String = "general"
@export var tutorial_component: String = "general"

# Estados según el modo
var rep_step: ReparacionStep = ReparacionStep.INTRO
var sys_step: SistemasStep = SistemasStep.INTRO
var srv_step: ServidorStep = ServidorStep.INTRO

# Nodos instanciados dinámicamente para sistemas y servidor
var systems_pc_inst: StaticBody3D = null
var server_rack_inst: StaticBody3D = null

func _ready() -> void:
	if player and hud:
		player.hud_node = hud

	var gm = get_node_or_null("/root/GameManager")
	if gm and "current_mode" in gm and str(gm.current_mode) != "":
		current_mode = str(gm.current_mode).to_lower()
	else:
		current_mode = "reparacion"

	if tutorial_component != "" and tutorial_component != "general":
		target_component = tutorial_component
	elif gm and "tutorial_target_component" in gm and str(gm.tutorial_target_component) != "":
		target_component = str(gm.tutorial_target_component).to_lower()
	elif target_component == "":
		target_component = "general"

	var btn_reintentar = hud.get_node_or_null("GameOverPanel/VBox/BtnReiniciarGO") as Button
	if btn_reintentar:
		btn_reintentar.pressed.connect(_on_reintentar)

	var btn_siguiente = hud.get_node_or_null("WinPanel/VBox/BtnSiguiente") as Button
	if btn_siguiente:
		btn_siguiente.pressed.connect(_on_siguiente)

	# Inicializar el tutorial con tiempo infinito para aprendizaje guiado
	GameManager.start_level(999.0)
	GameManager.timer_active = false
	if hud and hud.has_method("set_infinite_time"):
		hud.set_infinite_time(true)

	# Instanciar el sistema de diálogo y modal de victoria
	dialog_box = DIALOG_SCENE.instantiate()
	victory_modal = VICTORY_MODAL_SCENE.instantiate()
	var dlg_canvas = get_node_or_null("CanvasLayerDialog") as CanvasLayer
	if dlg_canvas:
		dlg_canvas.add_child(dialog_box)
		dlg_canvas.add_child(victory_modal)
	else:
		$CanvasLayerHUD.add_child(dialog_box)
		$CanvasLayerHUD.add_child(victory_modal)

	if victory_modal:
		victory_modal.repeat_pressed.connect(_on_reintentar)
		victory_modal.finish_pressed.connect(_on_siguiente)
		if victory_modal.has_method("setup_mode"):
			victory_modal.setup_mode(current_mode)

	# Configurar el escenario según el modo activo
	_setup_mode_environment()

	# Iniciar cinemática de entrada o secuencia directa
	if player and player.has_method("play_intro_cinematic"):
		player.play_intro_cinematic(func():
			_start_current_mode_intro()
		)
	else:
		_start_current_mode_intro()

func _input(event: InputEvent) -> void:
	# Si la cinemática de entrada orbital del jugador está activa, omitirla inmediatamente con ESC
	if is_instance_valid(player) and "is_in_cinematic" in player and player.is_in_cinematic:
		var is_esc = (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE)
		var is_pause = event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")
		var is_space = (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE)
		if is_esc or is_pause or is_space:
			get_viewport().set_input_as_handled()
			if player.has_method("skip_intro_cinematic"):
				player.skip_intro_cinematic()
			return

	# Si una transición de pantalla está activa, ignorar ESC
	if get_tree().root.get_node_or_null("CyberPlayTransition") != null or get_tree().root.find_child("CyberPlayTransition", true, false) != null:
		get_viewport().set_input_as_handled()
		return

	# Interceptar la tecla ESC para activar la interrupción personalizada de personaje antes de salir
	var is_esc_key = (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE)
	var is_pause_act = event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")
	if is_esc_key or is_pause_act:
		if not is_dialog_active and not is_instance_valid(active_minigame) and not (is_instance_valid(victory_modal) and victory_modal.visible) and not _is_modal_currently_open():
			get_viewport().set_input_as_handled()
			_trigger_character_esc_interruption()

var _rep_trans_timer: float = 0.0

func _process(delta: float) -> void:
	if is_dialog_active or is_esc_interrupt_active or (is_instance_valid(victory_modal) and victory_modal.visible) or is_instance_valid(active_minigame):
		if player and player.has_method("set_movement_enabled") and player.can_move:
			player.set_movement_enabled(false)
		if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	if current_mode == "reparacion":
		_rep_trans_timer += delta
		if _rep_trans_timer >= 0.15:
			_rep_trans_timer = 0.0
			_check_reparacion_transitions()

# =============================================================================
# CONFIGURACIÓN DEL ENTORNO SEGÚN EL MODO
# =============================================================================

func _setup_mode_environment() -> void:
	match current_mode:
		"sistema":
			_setup_sistemas_environment()
		"servidor":
			_setup_servidor_environment()
		_:
			_setup_reparacion_environment()

func _setup_reparacion_environment() -> void:
	_set_holo_banner_text("SALA DE ENTRENAMIENTO // HARDWARE & REPARACIÓN")
	_set_holo_sub_text("[PASO 1] ACÉRCATE A LA COMPUTADORA Y PRESIONA [E]")

	# En el tutorial de reparación solo se usan las 2 primeras herramientas (Phillips y Pala)
	if hud and hud.has_method("set_visible_tools"):
		hud.set_visible_tools(2)

	var banner_title = "INDUCCIÓN INTEGRAL DE HARDWARE // TALLER 3D"
	var diag_question = "INDUCCIÓN INTEGRAL DE HARDWARE CON JOA:\nAprende a diagnosticar, desmontar y ensamblar las 3 piezas fundamentales:\n• Memoria RAM · • Almacenamiento HDD/SSD · • Fuente de Poder PSU"
	var faulty_parts: Array[String] = ["RAM", "Disco Duro", "Fuente"]
	var comp_dict = {
		"RAM": "broken",
		"Disco Duro": "broken",
		"Grafica": "ok",
		"Fan Cooler": "ok",
		"CPU": "ok",
		"Fuente": "broken",
		"Placa Madre": "ok"
	}

	match target_component:
		"ram":
			banner_title = "TUTORIAL DE HARDWARE // BANCO DE MEMORIAS RAM"
			diag_question = "TUTORIAL DE MEMORIA RAM CON JOA:\nAprende el desacople de trabas laterales, extracción y alineación de la muesca central."
			faulty_parts = ["RAM"]
			comp_dict = {"RAM": "broken", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "CPU": "ok", "Fuente": "ok", "Placa Madre": "ok"}
		"hdd":
			banner_title = "TUTORIAL DE HARDWARE // ALMACENAMIENTO (SSD M.2 Y DISCO HDD)"
			diag_question = "TUTORIAL DE ALMACENAMIENTO (2 PARTES) CON JOA:\nParte 1: Extracción diagonal de SSD M.2 NVMe.\nParte 2: Desmontaje y montaje de Disco HDD 3.5\" mecánico."
			faulty_parts = ["Disco Duro"]
			comp_dict = {"RAM": "ok", "Disco Duro": "broken", "Grafica": "ok", "Fan Cooler": "ok", "CPU": "ok", "Fuente": "ok", "Placa Madre": "ok"}
		"gpu":
			banner_title = "TUTORIAL DE HARDWARE // TARJETA GRÁFICA (GPU)"
			diag_question = "TUTORIAL DE TARJETA GRÁFICA CON JOA:\nAprende la desconexión PCIe para frenar ventiladores, tornillos de bracket HDMI y extracción."
			faulty_parts = ["Grafica"]
			comp_dict = {"RAM": "ok", "Disco Duro": "ok", "Grafica": "broken", "Fan Cooler": "ok", "CPU": "ok", "Fuente": "ok", "Placa Madre": "ok"}
		"cooler":
			banner_title = "TUTORIAL DE HARDWARE // FAN COOLER (DISIPADOR)"
			diag_question = "TUTORIAL DE FAN COOLER CON JOA:\nAprende la desconexión del cable PWM y el aflojado en cruz de los 4 tornillos."
			faulty_parts = ["Fan Cooler"]
			comp_dict = {"RAM": "ok", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "broken", "CPU": "ok", "Fuente": "ok", "Placa Madre": "ok"}
		"psu":
			banner_title = "TUTORIAL DE HARDWARE // FUENTE DE PODER (PSU)"
			diag_question = "TUTORIAL DE FUENTE DE PODER CON JOA:\nAprende a desconectar los pestillos del conector ATX 24 pines y cable auxiliar EPS."
			faulty_parts = ["Fuente"]
			comp_dict = {"RAM": "ok", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "CPU": "ok", "Fuente": "broken", "Placa Madre": "ok"}
		"cpu":
			banner_title = "TUTORIAL DE HARDWARE // PROCESADOR (CPU)"
			diag_question = "TUTORIAL DE PROCESADOR CPU CON JOA:\nAprende la palanca de retención del socket LGA y alineación del triángulo de pines."
			faulty_parts = ["CPU"]
			comp_dict = {"RAM": "ok", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "CPU": "broken", "Fuente": "ok", "Placa Madre": "ok"}

	_set_holo_banner_text(banner_title)

	# Filtrar cajas de repuestos: en la introducción solo las cajas de los repuestos a quitar / arreglar
	var needed_boxes: Array[String] = []
	for p in faulty_parts:
		needed_boxes.append(p)

	for child in get_children():
		if child.name.begins_with("Spares"):
			var st = child.get("spare_type") if "spare_type" in child else ""
			var is_needed = (st in needed_boxes)
			child.visible = is_needed
			var col = child.get_node_or_null("CollisionShape3D")
			if col:
				col.disabled = not is_needed

	if pc:
		pc.set_meta("is_tutorial_pc", true)
		pc.set_meta("tutorial_component", target_component)
		if target_component == "hdd":
			pc.set_meta("storage_part", 1)
			pc.drive_type = "m2"
		pc.diagnostic_question = diag_question
		pc.diagnostic_faulty_parts.assign(faulty_parts)
		pc.components = comp_dict
		if pc.has_method("update_3d_state"):
			pc.update_3d_state()

	# Escuchar eventos de modales de hardware
	if not get_tree().node_added.is_connected(_on_tree_node_added):
		get_tree().node_added.connect(_on_tree_node_added)
	if not GameManager.backpack_updated.is_connected(_on_backpack_updated):
		GameManager.backpack_updated.connect(_on_backpack_updated)

func _setup_sistemas_environment() -> void:
	_set_holo_banner_text("LABORATORIO DE SOFTWARE // SISTEMAS OPERATIVOS")
	_set_holo_sub_text("[PASO 1] ACÉRCATE A LA TERMINAL Y PRESIONA [E]")

	# Forzar modo sistema para que el HUD oculte la barra y círculos de herramientas
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.current_mode = "sistema"

	if hud and hud.has_method("set_tools_bar_visible"):
		hud.set_tools_bar_visible(false)
	if hud and hud.has_method("set_visible_tools"):
		hud.set_visible_tools(0)

	if pc:
		pc.visible = false
		pc.collision_layer = 0
		pc.collision_mask = 0

	_hide_hardware_workshop_props()

	# En el área de sistemas la mesa es el modelo 'mesa de pedidos.glb' (no la de reparación)
	var old_mesa = work_bench.get_node_or_null("MesaModel")
	if old_mesa:
		old_mesa.visible = false

	var mesa_ped_scene = load("res://modelos_3d/escenario_3d/mesa de pedidos.glb")
	if mesa_ped_scene:
		var mesa_ped = mesa_ped_scene.instantiate()
		mesa_ped.name = "MesaPedidosModel"
		mesa_ped.scale = Vector3(0.012, 0.012, 0.012)
		mesa_ped.position = Vector3.ZERO
		work_bench.add_child(mesa_ped)

	# Monitor en el escritorio: OBJETO INTERACTIVO CON FLECHA AZUL Y PROMPT [E]
	var monitor_scene = load("res://scenes/components/SystemsMonitor.tscn")
	if monitor_scene:
		systems_pc_inst = monitor_scene.instantiate()
		systems_pc_inst.name = "MonitorTutorial"
		systems_pc_inst.position = Vector3(0.0, 0.912, -0.15)
		work_bench.add_child(systems_pc_inst)

	# Teclado en el escritorio
	var teclado_scene = load("res://modelos_3d/escenario_3d/teclado.glb")
	if teclado_scene:
		var tec = teclado_scene.instantiate()
		tec.name = "TecladoTutorial"
		tec.scale = Vector3(0.012, 0.012, 0.012)
		tec.position = Vector3(0.0, 0.912, 0.15)
		work_bench.add_child(tec)

	# Mouse en el escritorio
	var raton_scene = load("res://modelos_3d/escenario_3d/raton.glb")
	if raton_scene:
		var rat = raton_scene.instantiate()
		rat.name = "RatonTutorial"
		rat.scale = Vector3(0.012, 0.012, 0.012)
		rat.position = Vector3(0.38, 0.912, 0.15)
		work_bench.add_child(rat)

	# PC que se va a reparar: LADO IZQUIERDO ARRIBA sobre el escritorio, GIRADA PARA VER AL JUGADOR (modelo visual sin prompt [E])
	var pc_visual = SYSTEMS_PC_SCENE.instantiate()
	pc_visual.name = "SystemsComputerTutorial"
	pc_visual.position = Vector3(-0.55, 0.912, 0.0)
	pc_visual.rotation_degrees.y = -90.0
	pc_visual.collision_layer = 0
	pc_visual.collision_mask = 0
	if pc_visual.has_node("ArrowMesh"):
		pc_visual.get_node("ArrowMesh").visible = false
	if pc_visual.has_node("Label3D"):
		pc_visual.get_node("Label3D").visible = false
	work_bench.add_child(pc_visual)

	# Otra PC del sistema: LADO DERECHO AFUERA AL LADO DEL ESCRITORIO (en el piso)
	var gabinete_scene = load("res://modelos_3d/escenario_3d/gabinete.glb")
	if gabinete_scene:
		var gab_abajo = gabinete_scene.instantiate()
		gab_abajo.name = "GabineteAbajoTutorial"
		gab_abajo.scale = Vector3(0.013, 0.013, 0.013)
		gab_abajo.position = Vector3(1.25, 0.0, 0.0)
		gab_abajo.rotation_degrees.y = 0.0
		work_bench.add_child(gab_abajo)

	if is_instance_valid(systems_pc_inst):
		systems_pc_inst.components = {
			"Sistema Operativo": "broken",
			"Drivers": "broken",
			"Malware": "broken",
			"Adware": "fixed",
			"Debugger": "fixed",
			"Pendrive USB": "fixed",
			"Arcade Ciberdefensa": "fixed"
		}
		systems_pc_inst.custom_prompt = "[E] Instalar Andromeda OS"
		systems_pc_inst.custom_interact_callback = Callable(self, "_on_interact_systems_pc")
		systems_pc_inst.update_3d_state()

func _setup_servidor_environment() -> void:
	_set_holo_banner_text("INFRAESTRUCTURA ENTERPRISE // DATA CENTER 3D")
	_set_holo_sub_text("[PASO 1] ACÉRCATE AL RACK Y PRESIONA [E]")

	# En servidor los minijuegos son de software y fluidos
	if hud and hud.has_method("set_tools_bar_visible"):
		hud.set_tools_bar_visible(false)

	if pc:
		pc.visible = false
		pc.collision_layer = 0
		pc.collision_mask = 0

	if is_instance_valid(work_bench):
		work_bench.visible = false
		work_bench.collision_layer = 0
		work_bench.collision_mask = 0
		for child in work_bench.get_children():
			if child is VisualInstance3D or child is Node3D:
				child.visible = false
			if child is CollisionShape3D:
				child.disabled = true

	if holo_banner:
		holo_banner.position = Vector3(0, 3.4, -0.4)
	if holo_sub_banner:
		holo_sub_banner.position = Vector3(0, 3.05, -0.4)

	_hide_hardware_workshop_props()

	server_rack_inst = SERVER_RACK_SCENE.instantiate()
	server_rack_inst.name = "ServerRackTutorial"
	server_rack_inst.position = Vector3(0, 0, -2.5)
	add_child(server_rack_inst)

	server_rack_inst.components = {
		"Placa Madre": "fixed",
		"Bancos RAM ECC (3 Módulos)": "fixed",
		"Caddies SSD RAID (3 Discos)": "fixed",
		"Multi CPU Enterprise (3 Procesadores)": "fixed",
		"Fan Wall de Turbinas": "fixed",
		"Riser PCIe / Tarjeta Grafica": "fixed",
		"Sistemas Andromeda Linux": "broken",
		"Refrigeracion Liquida Custom Loop": "broken"
	}
	server_rack_inst.components_installed_counts = {
		"Placa Madre": 1,
		"Bancos RAM ECC (3 Módulos)": 3,
		"Caddies SSD RAID (3 Discos)": 3,
		"Multi CPU Enterprise (3 Procesadores)": 3,
		"Fan Wall de Turbinas": 1,
		"Riser PCIe / Tarjeta Grafica": 1,
		"Sistemas Andromeda Linux": 0,
		"Refrigeracion Liquida Custom Loop": 0
	}
	server_rack_inst.has_player_inspected = true
	server_rack_inst.custom_prompt = "[E] Depurar Daemon del Servidor"
	server_rack_inst.custom_interact_callback = Callable(self, "_on_interact_server_rack")
	server_rack_inst.update_3d_state()

func _hide_hardware_workshop_props() -> void:
	var nodes_to_hide = [spares_ram, spares_hdd, spares_psu, trash_bin, wall_dispenser]
	for n in nodes_to_hide:
		if is_instance_valid(n):
			n.visible = false
			if "collision_layer" in n:
				n.collision_layer = 0
			if "collision_mask" in n:
				n.collision_mask = 0
	# Ocultar cualquier caja de repuestos (SparesBox) restante en el área
	for child in find_children("*", "StaticBody3D", true, false):
		if child and ("Spares" in child.name or child.scene_file_path.ends_with("SparesBox.tscn")):
			child.visible = false
			child.collision_layer = 0
			child.collision_mask = 0

func _set_holo_banner_text(text: String) -> void:
	if holo_banner and holo_banner.mesh is TextMesh:
		var tm = holo_banner.mesh.duplicate() as TextMesh
		tm.text = text
		holo_banner.mesh = tm

func _set_holo_sub_text(text: String) -> void:
	if holo_sub_banner and holo_sub_banner.mesh is TextMesh:
		var tm = holo_sub_banner.mesh.duplicate() as TextMesh
		tm.text = text
		holo_sub_banner.mesh = tm

func _show_dialog_sequence(dialogs: Array, on_finish: Callable = Callable()) -> void:
	if not is_instance_valid(dialog_box):
		if on_finish.is_valid():
			on_finish.call()
		return

	is_dialog_active = true
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	dialog_box.show_sequence(dialogs, func():
		is_dialog_active = false
		var in_modal = _is_modal_currently_open()
		if not in_modal:
			_restore_player_free_movement()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

		if on_finish.is_valid():
			on_finish.call()
	)

func _restore_player_free_movement() -> void:
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _is_modal_currently_open() -> bool:
	if is_instance_valid(active_minigame):
		return true
	for child in get_tree().root.get_children():
		if child.name.begins_with("PCInspectionModal") \
			or child.name.begins_with("RAMSelectionModal") \
			or child.name.begins_with("SSDSelectionModal") \
			or child.name.begins_with("PCSystemsModal") \
			or child.name.begins_with("ServerInspectionModal") \
			or (child.has_method("is_closed") and not child.is_closed):
			return true
	return false

func _play_tutorial_entrance_animation() -> void:
	if player and player.get_node_or_null("Camera3D"):
		var cam = player.get_node_or_null("Camera3D") as Camera3D
		var orig_fov = cam.fov
		cam.fov = orig_fov + 6.0
		var tw_cam = create_tween()
		tw_cam.tween_property(cam, "fov", orig_fov, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
	if holo_banner:
		var orig_y = holo_banner.position.y
		holo_banner.position.y = orig_y + 0.35
		holo_banner.scale = Vector3(0.8, 0.8, 0.8)
		var tw_b = create_tween().set_parallel(true)
		tw_b.tween_property(holo_banner, "position:y", orig_y, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_b.tween_property(holo_banner, "scale", Vector3.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _start_current_mode_intro() -> void:
	GameManager.timer_active = false
	_play_tutorial_entrance_animation()
	match current_mode:
		"sistema":
			_start_sistemas_intro()
		"servidor":
			_start_servidor_intro()
		_:
			_start_reparacion_intro()

# =============================================================================
# INTERRUPCIÓN PERSONALIZADA AL PRESIONAR ESCAPE (JOA, JEREMIAS, SANTIAGO)
# =============================================================================

func _trigger_character_esc_interruption() -> void:
	if is_dialog_active or is_esc_interrupt_active or not is_instance_valid(dialog_box):
		return

	is_esc_interrupt_active = true
	is_dialog_active = true
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	match current_mode:
		"sistema":
			_show_jeremias_esc_interruption()
		"servidor":
			_show_santiago_esc_interruption()
		_:
			_show_joa_esc_interruption()

func _show_joa_esc_interruption() -> void:
	var speaker = "[JOA // TÉCNICA DE HARDWARE]"
	var text = "¿E-eh...? ¿T-te vas tan pronto? *(se le llenan los ojos de lágrimas y se acomoda los lentes con tristeza)*...\n¿Acaso... te aburrió mi explicación? L-lo siento mucho si hablo muy despacio o si soy aburrida...\n¿De verdad quieres salir al menú o podemos seguir practicando juntos?"
	var stay_txt = "[ ⌨ [E] QUEDARME CON JOA ]"
	var exit_txt = "[ ❌ [ESC] SALIR AL MENÚ ]"

	dialog_box.show_choice(
		speaker,
		text,
		stay_txt,
		exit_txt,
		func():
			# Eligió quedarse
			is_esc_interrupt_active = false
			var thanks_dialog = [
				{
					"speaker": "[JOA // ¡QUÉ ALIVIO!]",
					"text": "¡G-gracias!... *(sonríe aliviada mientras se acomoda los lentes)*. Sabía que eras una buena persona. Vamos a terminar de reparar la computadora, ¡tú puedes!"
				}
			]
			_show_dialog_sequence(thanks_dialog, func():
				_restore_player_free_movement()
			),
		func():
			# Eligió salir
			is_esc_interrupt_active = false
			var bye_dialog = [
				{
					"speaker": "[JOA // DESPEDIDA LLORANDO]",
					"text": "B-bueno... entiendo. *(se limpia las lágrimas con tristeza mientras baja la mirada)*. Espero no haberte molestado mucho. Vuelve cuando quieras a practicar, aquí estaré esperándote..."
				}
			]
			_show_dialog_sequence(bye_dialog, func():
				_exit_to_level_select()
			)
	)

func _show_jeremias_esc_interruption() -> void:
	var speaker = "[JEREMIAS // SYSADMIN & DEV]"
	var text = "¡Epa, epa, fiera! ¿Adónde crees que vas tan apurado? ¿Ya viste dos comandos en la terminal y te dio pánico escénico de hackers?\n¡No me dejes el café a medias ni la máquina en kernel panic, crack! ¿En serio te vas a rajar al menú o te vas a quedar a demostrar que tienes madera de sysadmin?"
	var stay_txt = "[ ⌨ [E] QUEDARME CON JEREMIAS ]"
	var exit_txt = "[ ❌ [ESC] SALIR AL MENÚ ]"

	dialog_box.show_choice(
		speaker,
		text,
		stay_txt,
		exit_txt,
		func():
			is_esc_interrupt_active = false
			var stay_dialog = [
				{
					"speaker": "[JEREMIAS // ¡ESA ES!]",
					"text": "¡Esa es la actitud, fiera! Sabía que no te ibas a acobardar frente a una terminal. ¡A romperla en el sistema!"
				}
			]
			_show_dialog_sequence(stay_dialog, func():
				_restore_player_free_movement()
			),
		func():
			is_esc_interrupt_active = false
			var bye_dialog = [
				{
					"speaker": "[JEREMIAS // HASTA LUEGO]",
					"text": "¡Bueno, pero que conste que me debes un café bien cargado! Nos vemos en el próximo deploy, fiera."
				}
			]
			_show_dialog_sequence(bye_dialog, func():
				_exit_to_level_select()
			)
	)

func _show_santiago_esc_interruption() -> void:
	var gm = get_node_or_null("/root/GameManager")
	var esc_count = 0
	if gm and "santiago_esc_count" in gm:
		esc_count = gm.santiago_esc_count
		gm.santiago_esc_count += 1
		
	var speaker = "[SANTIAGO // 4TA PARED & SERVIDORES]"
	var text = ""
	var stay_txt = "[ ⌨ [E] QUEDARME CON SANTIAGO ]"
	var exit_txt = "[ ❌ [ESC] SALIR AL MENÚ ]"
	var stay_reply = ""
	var exit_reply = ""
	
	match esc_count:
		0:
			text = "¿Presionando Escape para... escapar? Vaya, qué nivel de originalidad , y si acabo de romper la cuarta pared ¿ Algun problema ? es mi juego y yo hago lo que se me antoje ¿ Entendido ? Bueno como ya superaste los 2 modos anteriores te crees un genio ¿ No ? , bueno ve a jugar un nivel o hacer otra practica o lo que sea , ya no me importa ( se pone a ver reels en ig )"
			stay_reply = "¿Ah, te quedas? Pensé que te habías ido... espera que termine este reel."
			exit_reply = "Hasta la vista. Te dije que fueras a jugar otra cosa..."
		1:
			text = "¿ Otra vez ? tonces pa que entras"
			stay_reply = "Más te vale... ponte a trabajar y deja de molestar."
			exit_reply = "Eso pensé. Ni tú sabes qué haces aquí."
		2:
			text = "y vuelve el perro arrepentido"
			stay_reply = "Con el rabo entre las patas... en fin, mueve esos dedos."
			exit_reply = "Chao, perrito arrepentido."
		_:
			text = "( se pone a ver reels en ig y no le da importancia )"
			stay_reply = "( Sigue scrolleando reels en IG y ni te mira )"
			exit_reply = "( Ni se inmuta cuando te vas, sigue viendo memes en IG )"

	dialog_box.show_choice(
		speaker,
		text,
		stay_txt,
		exit_txt,
		func():
			is_esc_interrupt_active = false
			var stay_dialog = [
				{
					"speaker": speaker,
					"text": stay_reply
				}
			]
			_show_dialog_sequence(stay_dialog, func():
				_restore_player_free_movement()
			),
		func():
			is_esc_interrupt_active = false
			var bye_dialog = [
				{
					"speaker": speaker,
					"text": exit_reply
				}
			]
			_show_dialog_sequence(bye_dialog, func():
				_exit_to_level_select()
			)
	)

func _exit_to_level_select() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	LevelSelect.initial_tab = "niveles"
	LevelSelect.initial_mode = current_mode
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.current_mode = current_mode
	CyberPlayTransition.play_exit(
		get_tree(),
		current_mode,
		"res://scenes/menus/LevelSelect.tscn",
		"SALIENDO DEL TUTORIAL",
		"// SESIÓN DE ENTRENAMIENTO INTERRUMPIDA //"
	)

# =============================================================================
# MODO 1: REPARACIÓN DE HARDWARE (JOA)
# Personalidad: Mujer tímida, introvertida, lentes, meticulosa, dulce y educada
# =============================================================================

func _get_ram_type_name() -> String:
	if is_instance_valid(pc) and "ram_type" in pc and str(pc.ram_type) != "":
		return str(pc.ram_type).to_upper()
	for it in GameManager.backpack:
		if it is Dictionary and it.get("name") == "RAM" and str(it.get("ram_type", "")) != "":
			return str(it.get("ram_type")).to_upper()
	return "DDR4"

func _start_reparacion_intro() -> void:
	rep_step = ReparacionStep.INTRO
	var intro_dialogs: Array = []

	match target_component:
		"ram":
			intro_dialogs = [
				{
					"speaker": "JOA",
					"text": "H-hola... bienvenida al Tutorial de Memoria RAM... *(se acomoda los lentes con timidez)*. Yo soy Joa. Te enseñaré a liberar las trabas laterales y reemplazar el módulo DDR sin dañar las pistas de contacto."
				},
				{
					"speaker": "JOA",
					"text": "Paso 1: Acércate a la computadora central y presiona la tecla [E] para inspeccionar los zócalos de memoria RAM."
				}
			]
		"hdd":
			intro_dialogs = [
				{
					"speaker": "JOA",
					"text": "¡Hola!... *(te sonríe dulcemente mientras se acomoda los lentes)*. Bienvenida al Tutorial de Almacenamiento. Hoy aprenderemos a manipular dos tipos de unidades: SSD M.2 NVMe y discos mecánicos HDD."
				},
				{
					"speaker": "JOA",
					"text": "Este tutorial consta de 2 partes: primero veremos la extracción de un SSD M.2 de la placa base, y luego el desmontaje y montaje de un HDD. ¡Acércate a la computadora y presiona [E]!"
				}
			]
		"gpu":
			intro_dialogs = [
				{
					"speaker": "JOA",
					"text": "H-hola... *(se ajusta los lentes con admiración y nervios)*. Bienvenida al Tutorial de Tarjeta Gráfica (GPU). Esta es la pieza de procesamiento 3D más potente de la máquina."
				},
				{
					"speaker": "JOA",
					"text": "Paso 1: Por favor, acércate al gabinete central y presiona [E] para ver la GPU conectada al puerto PCIe x16."
				}
			]
		"cooler":
			intro_dialogs = [
				{
					"speaker": "JOA",
					"text": "¡B-bienvenida al Tutorial de Fan Cooler!... *(se acomoda los lentes meticulosamente)*. El procesador genera mucho calor y el disipador activo con ventilador PWM lo mantiene seguro bajo los 70°C."
				},
				{
					"speaker": "JOA",
					"text": "Paso 1: Acércate a la computadora central y presiona [E] para examinar el anclaje del disipador sobre la placa madre."
				}
			]
		"psu":
			intro_dialogs = [
				{
					"speaker": "JOA",
					"text": "H-hola... *(te saluda con una tímida inclinación de cabeza)*. Bienvenida al Tutorial de Fuente de Poder (PSU). Es el corazón eléctrico que distribuye voltajes regulados a todos los componentes."
				},
				{
					"speaker": "JOA",
					"text": "Paso 1: Acércate al equipo y presiona [E] para inspeccionar los arneses de potencia principal y auxiliar."
				}
			]
		"cpu":
			intro_dialogs = [
				{
					"speaker": "JOA",
					"text": "¡Hola!... *(respira hondo y se ajusta los lentes con emoción)*. Bienvenida al Tutorial de Procesador (CPU). El zócalo LGA es el componente de mayor precisión del taller."
				},
				{
					"speaker": "JOA",
					"text": "Paso 1: Acércate a la PC central y presiona [E] para abrir el chasis y acceder a la compuerta del procesador."
				}
			]
		_: # General
			intro_dialogs = [
				{
					"speaker": "JOA",
					"text": "H-hola... b-bueno, bienvenido al taller de hardware... *(se acomoda los lentes con timidez)*. Yo... soy Joa. Te voy a acompañar paso a paso para que no te sientas abrumado, ¿de acuerdo?"
				},
				{
					"speaker": "JOA",
					"text": "Para moverte puedes usar [W, A, S, D], con el ratón miras alrededor y con [Espacio] saltas... Ah, y si mantienes [Shift] corres un poco más rápido... sólo ten cuidado de no tropezar con las herramientas."
				},
				{
					"speaker": "JOA",
					"text": "E-en la parte inferior verás tus herramientas... Tienes habilitados el destornillador Phillips [ 1 ] y el de pala [ 2 ]... Con esas dos tenemos más que suficiente para empezar."
				},
				{
					"speaker": "JOA",
					"text": "P-paso 1: Por favor, acércate a la mesa central donde está el gabinete... y presiona la tecla [E] para abrirlo e inspeccionarlo por dentro."
				}
			]

	_show_dialog_sequence(intro_dialogs, func():
		rep_step = ReparacionStep.WAIT_INSPECT_PC
		_set_holo_sub_text("[PASO 1] ACÉRCATE A LA COMPUTADORA Y PRESIONA [E]")
		GameManager.spawn_floating_text("Paso 1: Acércate a la PC y presiona [E]", true)
		_restore_player_free_movement()
	)

func _advance_to_remove_ram() -> void:
	rep_step = ReparacionStep.WAIT_REMOVE_RAM
	var exact_ram = _get_ram_type_name()
	_set_holo_sub_text("[PASO 2] OBSERVA LA RAM %s [❌] Y HAZ CLIC EN 'SACAR'" % exact_ram)

	var inspect_dialogs: Array = [
		{
			"speaker": "[JOA // INSPECCIÓN DE PC]",
			"text": "E-eso es... muy bien... *(se ajusta los lentes)*. Mira, aquí dentro están los componentes. Si te fijas en la Memoria RAM, tiene una cruz roja [❌]... está defectuosa."
		},
		{
			"speaker": "[JOA // SACAR MEMORIA RAM]",
			"text": "Paso 2: Observa la Memoria RAM %s. Haz clic en el botón 'SACAR' para desmontarla de la placa base con cuidado y guardarla en tu mochila técnica." % exact_ram
		}
	]
	_show_dialog_sequence(inspect_dialogs)

func _advance_to_fetch_ram() -> void:
	rep_step = ReparacionStep.WAIT_FETCH_RAM
	var exact_ram = _get_ram_type_name()
	_set_holo_sub_text("[PASO 3] CIERRA LA PC [VOLVER], VE A LA CAJA DE RAM Y TOMA UN REPUESTO DE RAM %s" % exact_ram)

	var fetch_dialogs: Array = [
		{
			"speaker": "[JOA // PIEZA EN MOCHILA]",
			"text": "G-genial, la sacaste sin dañar los clips del zócalo... Ahora haz clic en el botón 'VOLVER' para cerrar el panel del chasis."
		},
		{
			"speaker": "[JOA // CAJAS DE REPUESTOS]",
			"text": "Paso 3: A tu derecha están las cajas de repuestos. Camina a la caja marcada como 'REPUESTO: RAM' y presiona [E] para elegir un módulo nuevo y compatible de Memoria RAM %s." % exact_ram
		}
	]
	_show_dialog_sequence(fetch_dialogs, func():
		_restore_player_free_movement()
	)

func _advance_to_install_ram() -> void:
	rep_step = ReparacionStep.WAIT_INSTALL_RAM
	var exact_ram = _get_ram_type_name()
	_set_holo_sub_text("[PASO 4] REGRESA A LA PC [E] E INSTALA LA RAM %s EN SU RANURA" % exact_ram)

	var install_dialogs: Array = [
		{
			"speaker": "[JOA // REPUESTO OBTENIDO]",
			"text": "P-perfecto... tienes el módulo nuevo y 100%% compatible en tu mochila técnica."
		},
		{
			"speaker": "[JOA // INSTALAR MEMORIA RAM]",
			"text": "Paso 4: Vuelve a la computadora central, presiona [E] para abrirla e instala la nueva Memoria RAM %s haciendo clic en su ranura vacía... Asegúrate de que quede bien ajustada." % exact_ram
		}
	]
	_show_dialog_sequence(install_dialogs, func():
		_restore_player_free_movement()
	)

func _advance_to_handle_ssd() -> void:
	rep_step = ReparacionStep.WAIT_HANDLE_SSD
	var storage_part = pc.get_meta("storage_part", 1) if is_instance_valid(pc) else 1
	var step_num = "2" if target_component == "hdd" else "5"

	var ssd_dialogs: Array = []
	if target_component == "hdd":
		if storage_part == 1:
			_set_holo_sub_text("[PARTE 1/2] DESMONTA LA UNIDAD SSD M.2 NVMe DE LA PLACA MADRE")
			GameManager.spawn_floating_text("Parte 1: Desmonta el SSD M.2", true)
			ssd_dialogs = [
				{
					"speaker": "JOA",
					"text": "M-muy bien... *(apunta hacia la placa)*. Empecemos con la Parte 1: El SSD M.2 NVMe. Este módulo ultrarrápido va insertado directamente sobre la placa madre bajo una armadura térmica."
				},
				{
					"speaker": "JOA",
					"text": "Paso 1: Haz clic en 'SACAR' en Almacenamiento. En el minijuego, usa el Destornillador Phillips [1] para retirar el disipador, luego el micro-tornillo del standoff, observa la elevación a 30° y desliza el SSD en diagonal."
				}
			]
		else:
			_set_holo_sub_text("[PARTE 2/2] DESMONTA EL DISCO HDD Y COLOCA EL REPUESTO NUEVO")
			GameManager.spawn_floating_text("Parte 2: Desmonta y coloca el Disco HDD", true)
			ssd_dialogs = [
				{
					"speaker": "JOA",
					"text": "Paso 2: Ahora haz clic en 'SACAR' en el Disco HDD. Retira los 4 tornillos de las esquinas con el destornillador, desconecta el cable SATA y arrástralo a la derecha. Luego busca el repuesto nuevo en la caja para instalarlo."
				}
			]
	else:
		_set_holo_sub_text("[PASO %s] DESMONTA EL ALMACENAMIENTO (DISCO HDD / SSD) Y COLOCA EL REPUESTO NUEVO" % step_num)
		GameManager.spawn_floating_text("Paso %s: Ahora desmonta y coloca el Almacenamiento" % step_num, true)
		ssd_dialogs = [
			{
				"speaker": "[JOA // RAM INSTALADA]",
				"text": "¡L-lo hiciste de maravilla! La Memoria RAM encajó a la perfección y el zócalo ya está completamente operativo."
			},
			{
				"speaker": "[JOA // ALMACENAMIENTO HDD / SSD]",
				"text": "Paso 5: Ahora debemos cambiar la unidad de Almacenamiento [❌]. Haz clic en 'SACAR'. Si es un Disco HDD, retira primero los 4 tornillos de las esquinas con el destornillador, luego clic en el cable SATA para desconectarlo, y arrástralo a la derecha para extraerlo."
			}
		]
	_show_dialog_sequence(ssd_dialogs)

func _on_m2_tutorial_part_completed() -> void:
	if target_component != "hdd":
		return
	if is_instance_valid(pc):
		pc.set_meta("storage_part", 2)
		pc.drive_type = "hdd"
		pc.components["Disco Duro"] = "broken"
		if pc.has_method("update_3d_state"):
			pc.update_3d_state()

	_set_holo_sub_text("[PARTE 2/2] DESMONTA EL DISCO HDD Y COLOCA EL REPUESTO NUEVO")
	GameManager.spawn_floating_text("Parte 2: Ahora desmonta el Disco HDD", true)

	var transition_dialogs: Array = [
		{
			"speaker": "JOA",
			"text": "Bueno, esa es la explicación de las unidades SSD y cómo se instalan... *(te sonríe dulcemente mientras se acomoda los lentes)*. Ahora te voy a explicar sobre los discos mecánicos HDD."
		},
		{
			"speaker": "JOA",
			"text": "Los discos HDD son unidades de almacenamiento magnéticas con platos giratorios y cabezales electromagnéticos que leen y guardan datos. Son muy comunes y económicos para almacenar grandes volúmenes de información. Ahora debemos colocar uno en la bahía SATA."
		},
		{
			"speaker": "JOA",
			"text": "Paso 2: Haz clic en 'SACAR' en Almacenamiento, retira con el destornillador los 4 tornillos de las esquinas, desconecta el cable SATA y arrastra el disco hacia la derecha. Luego ve a la caja de repuestos para buscar uno nuevo e instalarlo."
		}
	]
	_show_dialog_sequence(transition_dialogs)

func _advance_to_handle_gpu() -> void:
	rep_step = ReparacionStep.WAIT_HANDLE_GPU
	var step_num = "2" if target_component == "gpu" else "6"
	_set_holo_sub_text("[PASO %s] DESMONTA LA TARJETA GRÁFICA (GPU) Y COLOCA EL REPUESTO NUEVO" % step_num)
	GameManager.spawn_floating_text("Paso %s: Ahora reemplaza la Tarjeta Gráfica (GPU)" % step_num, true)

	var gpu_dialogs: Array = []
	if target_component == "gpu":
		gpu_dialogs = [
			{
				"speaker": "JOA",
				"text": "E-eso es... muy bien... *(se acomoda los lentes)*. Aquí dentro puedes ver la Tarjeta Gráfica (GPU) con la cruz roja [❌]... sus ventiladores están fallando y necesita reemplazo inmediato."
			},
			{
				"speaker": "JOA",
				"text": "Paso 2: Haz clic en el botón 'SACAR' de la GPU. En el minijuego, haz clic en el conector PCIe para desconectarla y frenar los ventiladores. Luego retira con el destornillador los 2 tornillos del bracket HDMI y arrastra la GPU hacia ARRIBA. ¡El soporte se quedará firme en el gabinete!"
			},
			{
				"speaker": "JOA",
				"text": "Paso 3: Después ve a la caja de Gráficas para elegir tu modelo preferido (Monocooler o Dual Cooler con sus VRAM) e instálala en la ranura PCIe."
			}
		]
	else:
		gpu_dialogs = [
			{
				"speaker": "[JOA // DISCO INSTALADO]",
				"text": "Uff... q-qué alivio, el almacenamiento quedó firme y seguro con sus cables bien acoplados..."
			},
			{
				"speaker": "[JOA // TARJETA GRÁFICA (GPU)]",
				"text": "Paso 6: Ahora observemos la Tarjeta Gráfica (GPU) [❌]... *(sus ojos brillan detrás de sus lentes)*. Primero haz clic en el cable PCIe para frenar los ventiladores (de a poco hasta detenerse). Luego retira los 2 tornillos del bracket HDMI y arrastra la GPU hacia ARRIBA. ¡El soporte se quedará en su sitio!"
			}
		]
	_show_dialog_sequence(gpu_dialogs)

func _advance_to_handle_cooler() -> void:
	rep_step = ReparacionStep.WAIT_HANDLE_COOLER
	var step_num = "2" if target_component == "cooler" else "7"
	_set_holo_sub_text("[PASO %s] DESMONTA EL FAN COOLER Y COLOCA EL REPUESTO NUEVO" % step_num)
	GameManager.spawn_floating_text("Paso %s: Ahora desmonta y coloca el Fan Cooler" % step_num, true)

	var cooler_dialogs: Array = []
	if target_component == "cooler":
		cooler_dialogs = [
			{
				"speaker": "JOA",
				"text": "E-excelente... *(mira fijamente el gabinete)*. El Fan Cooler sobre el procesador tiene la cruz roja [❌]... la turbina está bloqueada y el CPU se recalienta."
			},
			{
				"speaker": "JOA",
				"text": "Paso 2: Haz clic en 'SACAR' en el Fan Cooler. En el minijuego, desconecta el cable PWM de 4 pines, retira en cruz los 4 tornillos con el destornillador y levanta el disipador. Luego ve a la caja de Fan Cooler por el repuesto e instálalo."
			}
		]
	else:
		cooler_dialogs = [
			{
				"speaker": "[JOA // GPU INSTALADA]",
				"text": "¡M-maravilloso! La GPU encajó como un guante en el zócalo PCIe y sus ventiladores ya giran seguros."
			},
			{
				"speaker": "[JOA // FAN COOLER (DISIPADOR)]",
				"text": "Paso 7: Ahora revisemos el Fan Cooler sobre el procesador [❌]. Desconecta el cable PWM de 4 pines, retira los 4 tornillos en cruz y levanta el disipador para renovar la refrigeración térmica del procesador."
			}
		]
	_show_dialog_sequence(cooler_dialogs)

func _advance_to_handle_cpu() -> void:
	rep_step = ReparacionStep.WAIT_HANDLE_CPU
	var step_num = "2" if target_component == "cpu" else "8"
	_set_holo_sub_text("[PASO %s] DESMONTA EL PROCESADOR (CPU) LIBERANDO LA PALANCA DEL ZÓCALO LGA" % step_num)
	GameManager.spawn_floating_text("Paso %s: Ahora inspecciona y sustituye el Procesador (CPU)" % step_num, true)

	var cpu_dialogs: Array = []
	if target_component == "cpu":
		cpu_dialogs = [
			{
				"speaker": "JOA",
				"text": "L-llegamos al núcleo de todo... *(se acomoda los lentes con emoción)*. El Procesador (CPU) está marcado con [❌] en el socket LGA."
			},
			{
				"speaker": "JOA",
				"text": "Paso 2: Haz clic en 'SACAR'. Destraba la palanca metálica lateral hacia abajo y hacia afuera para levantar la compuerta. Retira el procesador dañado, ve a la caja de CPU por el repuesto nuevo, alinea las muescas doradas sin forzar los pines y baja la palanca para fijarlo."
			}
		]
	else:
		cpu_dialogs = [
			{
				"speaker": "[JOA // DISIPADOR RETIRADO]",
				"text": "¡Uff, qué bien!... Sin el disipador podemos ver el die del microprocesador."
			},
			{
				"speaker": "[JOA // PROCESADOR (CPU)]",
				"text": "Paso 8: Observa el zócalo del Procesador (CPU) [❌]... *(se acomoda los lentes con reverencia y emoción)*. Arrastra la palanca lateral metálica hacia abajo para destrabar la compuerta de retención. Luego extrae el CPU defectuoso y coloca el procesador nuevo alineando las muescas doradas sin forzar los pines. ¡Al final vuelve a asegurar la palanca!"
			}
		]
	_show_dialog_sequence(cpu_dialogs)

func _advance_to_handle_psu() -> void:
	rep_step = ReparacionStep.WAIT_HANDLE_PSU
	var step_num = "2" if target_component == "psu" else "9"
	_set_holo_sub_text("[PASO %s] DESMONTA LA FUENTE DE PODER (PSU) Y COLOCA EL REPUESTO NUEVO" % step_num)
	GameManager.spawn_floating_text("Paso %s: Ahora desmonta y coloca la Fuente de Poder" % step_num, true)

	var psu_dialogs: Array = []
	if target_component == "psu":
		psu_dialogs = [
			{
				"speaker": "JOA",
				"text": "C-cuidado con la estática aquí... *(respira hondo)*. La Fuente de Poder (PSU) [❌] no entrega voltajes estables en la línea de +12V."
			},
			{
				"speaker": "JOA",
				"text": "Paso 2: Haz clic en 'SACAR'. Presiona los pestillos de seguridad y desconecta el arnés principal ATX de 24 pines y el auxiliar EPS de la CPU sin doblar los cables. Luego toma una fuente nueva de la caja de repuestos e instálala."
			}
		]
	else:
		psu_dialogs = [
			{
				"speaker": "[JOA // PROCESADOR ASENTADO]",
				"text": "¡P-perfecto! Los pines del socket quedaron intactos y la palanca bien asegurada."
			},
			{
				"speaker": "[JOA // FUENTE DE PODER (PSU)]",
				"text": "Paso 9: Por último nos falta la Fuente de Poder (PSU) [❌]. Haz clic en 'SACAR', desconecta los cables del conector principal ATX y la CPU sin tirar con brusquedad... e instala la nueva fuente para suministrar energía limpia."
			}
		]
	_show_dialog_sequence(psu_dialogs)

func _advance_to_reparacion_completed() -> void:
	if rep_step == ReparacionStep.COMPLETED:
		return
	rep_step = ReparacionStep.COMPLETED
	_set_holo_sub_text("¡TUTORIAL COMPLETADO! HABILIDADES ADQUIRIDAS AL 100% ✓")

	for child in get_tree().root.get_children():
		if child.name.begins_with("PCInspectionModal") \
			or child.name.begins_with("RAMSelectionModal") \
			or child.name.begins_with("SSDSelectionModal") \
			or child.name.begins_with("GPUSelectionModal") \
			or child.name.ends_with("Minigame") \
			or child.is_in_group("minigames"):
			child.queue_free()

	var comp_title = "HARDWARE INTEGRAL"
	match target_component:
		"ram": comp_title = "MEMORIA RAM"
		"hdd": comp_title = "ALMACENAMIENTO (HDD / SSD)"
		"gpu": comp_title = "TARJETA GRÁFICA (GPU)"
		"cooler": comp_title = "FAN COOLER (DISIPADOR)"
		"cpu": comp_title = "PROCESADOR (CPU)"
		"psu": comp_title = "FUENTE DE PODER (PSU)"

	var completed_dialogs: Array = [
		{
			"speaker": "JOA",
			"text": "¡L-lo lograste todo! *(sonríe aliviada con emoción y se acomoda los lentes)*. Has completado con éxito el tutorial técnico de %s." % comp_title
		},
		{
			"speaker": "JOA",
			"text": "E-eres realmente talentoso para esto... Ya dominas el desmontaje y ensamblaje correcto de %s.\n¡Tu certificación técnica está aprobada! Presiona [E] para continuar." % comp_title
		}
	]
	_show_dialog_sequence(completed_dialogs, func():
		_show_tutorial_victory()
	)

func _on_tree_node_added(node: Node) -> void:
	if current_mode != "reparacion":
		return
	if rep_step == ReparacionStep.WAIT_INSPECT_PC:
		if node.name.begins_with("PCInspectionModal") or node.has_method("setup_pc"):
			get_tree().create_timer(0.12).timeout.connect(func():
				if rep_step == ReparacionStep.WAIT_INSPECT_PC:
					match target_component:
						"hdd":
							_advance_to_handle_ssd()
						"gpu":
							_advance_to_handle_gpu()
						"cooler":
							_advance_to_handle_cooler()
						"cpu":
							_advance_to_handle_cpu()
						"psu":
							_advance_to_handle_psu()
						_:
							_advance_to_remove_ram()
			)

func _on_backpack_updated(_items: Array) -> void:
	if current_mode != "reparacion" or is_dialog_active:
		return
	_check_reparacion_transitions()

func _check_reparacion_transitions() -> void:
	if not is_instance_valid(pc) or rep_step == ReparacionStep.COMPLETED:
		return

	var ram_ok = pc.components.get("RAM", "") in ["ok", "fixed"]
	var ssd_ok = pc.components.get("Disco Duro", "") in ["ok", "fixed"]
	var gpu_ok = pc.components.get("Grafica", "") in ["ok", "fixed", "empty"]
	var cooler_ok = pc.components.get("Fan Cooler", "") in ["ok", "fixed", "empty"]
	var cpu_ok = pc.components.get("CPU", "") in ["ok", "fixed", "empty"]
	var psu_ok = pc.components.get("Fuente", "") in ["ok", "fixed"]

	# Casos para tutoriales individuales
	match target_component:
		"ram":
			if pc.components.get("RAM", "") == "empty" and rep_step == ReparacionStep.WAIT_REMOVE_RAM:
				_advance_to_fetch_ram()
			elif _has_functional_ram_in_backpack() and rep_step == ReparacionStep.WAIT_FETCH_RAM and not _is_modal_currently_open():
				_advance_to_install_ram()
			elif ram_ok and rep_step == ReparacionStep.WAIT_INSTALL_RAM:
				_advance_to_reparacion_completed()
			return
		"hdd":
			if is_instance_valid(pc) and pc.get_meta("storage_part", 1) == 1:
				if pc.components.get("Disco Duro", "") == "empty":
					var has_ssd = false
					for it in GameManager.backpack:
						if (it.get("name") == "Disco Duro" or it.get("type") == "Disco Duro") and not it.get("broken", true):
							has_ssd = true
							break
					if has_ssd:
						_set_holo_sub_text("[PARTE 1/2] TIENES EL SSD EN LA MOCHILA. VUELVE A LA PC PARA INSTALARLO")
					else:
						_set_holo_sub_text("[PARTE 1/2] VE A LA CAJA DE ALMACENAMIENTO, TOMA EL REPUESTO SSD Y REGRESA A INSTALARLO")
				return
			if pc.components.get("Disco Duro", "") == "empty":
				var has_hdd = false
				for it in GameManager.backpack:
					if (it.get("name") == "Disco Duro" or it.get("type") == "Disco Duro") and not it.get("broken", true):
						has_hdd = true
						break
				if has_hdd:
					_set_holo_sub_text("[PARTE 2/2] TIENES EL DISCO HDD EN LA MOCHILA. VUELVE A LA PC PARA INSTALARLO")
				else:
					_set_holo_sub_text("[PARTE 2/2] VE A LA CAJA DE ALMACENAMIENTO, TOMA EL REPUESTO HDD Y REGRESA A INSTALARLO")
			elif ssd_ok and pc.components.get("Disco Duro", "") != "empty":
				_advance_to_reparacion_completed()
			return
		"gpu":
			if pc.components.get("Grafica", "") == "empty":
				_set_holo_sub_text("[PASO 3] VE A LA CAJA DE TARJETAS GRÁFICAS, ELIGE TU MODELO Y REGRESA A INSTALARLA")
			elif gpu_ok and pc.components.get("Grafica", "") != "empty":
				_advance_to_reparacion_completed()
			return
		"cooler":
			if pc.components.get("Fan Cooler", "") == "empty":
				_set_holo_sub_text("[PASO 3] VE A LA CAJA DE FAN COOLERS, TOMA EL REPUESTO Y REGRESA A INSTALARLO")
			elif cooler_ok and pc.components.get("Fan Cooler", "") != "empty":
				_advance_to_reparacion_completed()
			return
		"cpu":
			if pc.components.get("CPU", "") == "empty":
				_set_holo_sub_text("[PASO 3] VE A LA CAJA DE PROCESADORES, TOMA EL REPUESTO Y REGRESA A INSTALARLO")
			elif cpu_ok and pc.components.get("CPU", "") != "empty":
				_advance_to_reparacion_completed()
			return
		"psu":
			if pc.components.get("Fuente", "") == "empty":
				_set_holo_sub_text("[PASO 3] VE A LA CAJA DE FUENTES DE PODER, TOMA EL REPUESTO Y REGRESA A INSTALARLO")
			elif psu_ok and pc.components.get("Fuente", "") != "empty":
				_advance_to_reparacion_completed()
			return

	if pc.is_fully_repaired() or (ram_ok and ssd_ok and gpu_ok and cooler_ok and cpu_ok and psu_ok):
		_advance_to_reparacion_completed()
		return

	match rep_step:
		ReparacionStep.WAIT_REMOVE_RAM:
			if pc.components.get("RAM", "") == "empty":
				_advance_to_fetch_ram()

		ReparacionStep.WAIT_FETCH_RAM:
			if _has_functional_ram_in_backpack() and not _is_modal_currently_open():
				_advance_to_install_ram()

		ReparacionStep.WAIT_INSTALL_RAM:
			if ram_ok:
				_advance_to_handle_ssd()

		ReparacionStep.WAIT_HANDLE_SSD:
			if ssd_ok:
				if pc.components.has("Grafica") and pc.components.get("Grafica", "") == "broken":
					_advance_to_handle_gpu()
				elif pc.components.has("Fan Cooler") and pc.components.get("Fan Cooler", "") == "broken":
					_advance_to_handle_cooler()
				elif pc.components.has("CPU") and pc.components.get("CPU", "") == "broken":
					_advance_to_handle_cpu()
				else:
					_advance_to_handle_psu()

		ReparacionStep.WAIT_HANDLE_GPU:
			if gpu_ok:
				if pc.components.has("Fan Cooler") and pc.components.get("Fan Cooler", "") == "broken":
					_advance_to_handle_cooler()
				elif pc.components.has("CPU") and pc.components.get("CPU", "") == "broken":
					_advance_to_handle_cpu()
				else:
					_advance_to_handle_psu()

		ReparacionStep.WAIT_HANDLE_COOLER:
			if cooler_ok:
				if pc.components.has("CPU") and pc.components.get("CPU", "") == "broken":
					_advance_to_handle_cpu()
				else:
					_advance_to_handle_psu()

		ReparacionStep.WAIT_HANDLE_CPU:
			if cpu_ok:
				_advance_to_handle_psu()

		ReparacionStep.WAIT_HANDLE_PSU:
			if psu_ok:
				_advance_to_reparacion_completed()

func _has_functional_ram_in_backpack() -> bool:
	for item in GameManager.backpack:
		if item is Dictionary and item.get("type", "") == "RAM":
			if item.get("functional", false) or not item.get("broken", true):
				return true
	return false

# =============================================================================
# MODO 2: SISTEMAS (JEREMIAS)
# Personalidad: Chico de rulos, carismático, extrovertido, burlón / sysadmin
# 3 minijuegos interactivos: OSInstall, MalwareScanner, DriverUpdater
# Flujo: Diálogo [E] -> Libertad de movimiento -> Acercarse y dar [E] él mismo
# =============================================================================

func _start_sistemas_intro() -> void:
	if target_component != "general" and target_component != "":
		_start_targeted_sistemas_tutorial()
		return

	sys_step = SistemasStep.INTRO
	var intro_dialogs: Array = [
		{
			"speaker": "[JEREMIAS // SYSADMIN & DEV]",
			"text": "¡Epaaa, qué onda, fiera! ¿Te perdiste o viniste a aprender con el mejor? Soy Jeremias, el amo y señor del software en este laboratorio. ¡Bienvenido!"
		},
		{
			"speaker": "[JEREMIAS // BIENVENIDA A SISTEMAS]",
			"text": "Acércate al monitor en el escritorio y presiona [E] para entrar a la terminal. Allá adentro te enseño todo lo que necesitas saber paso a paso."
		}
	]

	_show_dialog_sequence(intro_dialogs, func():
		sys_step = SistemasStep.WAIT_INTERACT_OS
		_set_holo_sub_text("[PASO 1] ACÉRCATE AL MONITOR Y PRESIONA [E]")
		GameManager.spawn_floating_text("Paso 1: Camina al monitor y presiona [E]", true)
		if is_instance_valid(systems_pc_inst):
			systems_pc_inst.custom_prompt = "[E] Instalar Andromeda OS (Partición GPT)"
		_restore_player_free_movement()
	)

func _start_targeted_sistemas_tutorial() -> void:
	var tut_configs: Dictionary = {
		"os_install": {
			"sub": "TUTORIAL // INSTALACIÓN DE SISTEMAS & GPT",
			"prompt": "[E] Instalar Andromeda OS (Partición GPT)",
			"dialog": "¡A ver esa agilidad con las particiones, crack! Camina al monitor y presiona [E] para crear la tabla GPT e instalar Andromeda OS.",
			"scene": OS_MINIGAME_SCENE,
			"key": "Sistema Operativo"
		},
		"malware_scan": {
			"sub": "TUTORIAL // CIBERDEFENSA & ESCANEO DE MALWARE",
			"prompt": "[E] Ejecutar Escáner de Malware ClamAV",
			"dialog": "¡Cuidado que hay gusanos sueltos en memoria, fiera! Camina al monitor y presiona [E] para pasar el antivirus heurístico.",
			"scene": MALWARE_MINIGAME_SCENE,
			"key": "Malware"
		},
		"driver_install": {
			"sub": "TUTORIAL // CONTROLADORES WHQL & MÓDULOS DE KERNEL",
			"prompt": "[E] Actualizar Controladores WHQL",
			"dialog": "¡A calibrar esa gráfica y red sin pantallas azules! Camina al monitor y presiona [E] para instalar los drivers certificados.",
			"scene": DRIVER_MINIGAME_SCENE,
			"key": "Drivers"
		},
		"adware_cleaner": {
			"sub": "TUTORIAL // DESINFECCIÓN DE ADWARE & POP-UPS",
			"prompt": "[E] Iniciar Limpieza de Adware",
			"dialog": "¡El navegador está infestado de pop-ups engañosos, fiera! Camina al monitor y presiona [E] para activar el escudo Ad-Blocker.",
			"scene": ADWARE_MINIGAME_SCENE,
			"key": "Adware"
		},
		"code_debugger": {
			"sub": "TUTORIAL // PROGRAMACIÓN & TERMINAL DE SISTEMAS",
			"prompt": "[E] Abrir Terminal de Programación",
			"dialog": "¡Epa, fiera! Bienvenido a la consola de programación. Camina hacia el monitor y presiona [E] para entrar a la terminal. Adentro te explico cada comando paso a paso.",
			"scene": DEBUGGER_MINIGAME_SCENE,
			"key": "Debugger"
		},
		"usb_backup": {
			"sub": "TUTORIAL // UNIDADES BOOTEABLES USB & RESPALDO",
			"prompt": "[E] Crear Unidad USB Booteable de Rescate",
			"dialog": "¡Hora de preparar el pendrive salvavidas, crack! Camina al monitor y presiona [E] para flashear la ISO con dd/Ventoy.",
			"scene": USB_MINIGAME_SCENE,
			"key": "Pendrive USB"
		}
	}

	var conf = tut_configs.get(target_component, tut_configs["os_install"])
	_set_holo_sub_text(conf["sub"])
	var dialogs: Array = []
	if conf.has("dialogs"):
		dialogs = conf["dialogs"]
	else:
		dialogs = [
			{
				"speaker": "[JEREMIAS // ENTRENAMIENTO GUIADO]",
				"text": conf.get("dialog", "")
			}
		]
		
	if target_component == "code_debugger":
		var sm = get_node_or_null("/root/SaveManager")
		if sm and sm.has_method("unlock_glossary"):
			sm.unlock_glossary("sistemas_programacion")

	_show_dialog_sequence(dialogs, func():
		_set_holo_sub_text(conf["sub"])
		GameManager.spawn_floating_text("Camina a la terminal y presiona [E]", true)
		if is_instance_valid(systems_pc_inst):
			systems_pc_inst.custom_prompt = conf["prompt"]
			systems_pc_inst.custom_interact_callback = func(_p):
				_launch_minigame_sistemas(conf["scene"], conf["key"], func(success: bool):
					if success:
						if target_component == "code_debugger":
							var sm_win = get_node_or_null("/root/SaveManager")
							if sm_win and sm_win.has_method("unlock_glossary"):
								sm_win.unlock_glossary("sistemas_programacion")
						var win_dialogs: Array = [
							{
								"speaker": "[JEREMIAS // ¡EXCELENTE TRABAJO!]",
								"text": "¡Naaaaah, qué crack! Protocolo completado al 100%. Reclama tu certificación técnica."
							}
						]
						_show_dialog_sequence(win_dialogs, func():
							_show_tutorial_victory()
						)
					else:
						_on_sistemas_minigame_failed("¡Casi, fiera! Respira hondo, acércate a la terminal y presiona [E] para intentarlo de nuevo.")
				)
		_restore_player_free_movement()
	)

func _on_interact_systems_pc(_player_ref) -> void:
	if is_dialog_active or is_esc_interrupt_active or is_instance_valid(active_minigame):
		return

	match sys_step:
		SistemasStep.WAIT_INTERACT_OS:
			_launch_minigame_sistemas(OS_MINIGAME_SCENE, "Sistema Operativo", func(success: bool):
				if success:
					_on_os_install_completed()
				else:
					_on_sistemas_minigame_failed("¡Oye, oye! ¡Casi dejas el disco en blanco de por vida! Tranquilo crack, respira hondo, camina hacia la terminal y presiona [E] para intentarlo otra vez. ¡Tú puedes, fiera!")
			)

		SistemasStep.WAIT_INTERACT_MALWARE:
			_launch_minigame_sistemas(MALWARE_MINIGAME_SCENE, "Malware", func(success: bool):
				if success:
					_on_malware_scanner_completed()
				else:
					_on_sistemas_minigame_failed("¡Cuidado, crack! Los virus casi se comen el procesador vivo. Camina hacia la terminal, dale a [E] e inténtalo con más calma.")
			)

		SistemasStep.WAIT_INTERACT_DRIVERS:
			_launch_minigame_sistemas(DRIVER_MINIGAME_SCENE, "Drivers", func(success: bool):
				if success:
					_on_drivers_completed()
				else:
					_on_sistemas_minigame_failed("¡Uy, pantalla azul de controladores! No pasa nada fiera, pulsa [E] en la terminal y monta los drivers correctos.")
			)

func _launch_minigame_sistemas(minigame_scene: PackedScene, comp_key: String, on_result: Callable) -> void:
	if minigame_scene == null:
		return

	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	if player and player.hud_node:
		player.hud_node.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var minigame = minigame_scene.instantiate()
	minigame.set("is_tutorial_mode", true)
	active_minigame = minigame
	get_tree().root.add_child(minigame)

	minigame.connect("minigame_finished", func(success: bool):
		if is_instance_valid(active_minigame):
			active_minigame.queue_free()
			active_minigame = null

		if player and player.hud_node:
			player.hud_node.visible = true

		if success and is_instance_valid(systems_pc_inst):
			systems_pc_inst.components[comp_key] = "fixed"
			systems_pc_inst.update_3d_state()

		if on_result.is_valid():
			on_result.call(success)
	)

func _on_os_install_completed() -> void:
	var dialogs: Array = [
		{
			"speaker": "[JEREMIAS // ¡SISTEMA OPERATIVO LISTO!]",
			"text": "¡Opaaa! ¡Mira nada más! No hiciste explotar el disco ni borraste la tabla de particiones... ¡Milagro en el laboratorio! Andromeda Linux ya bootea como los dioses."
		},
		{
			"speaker": "[JEREMIAS // PASO 2 · ESCANEO DE MALWARE]",
			"text": "Paso 2: Pero no te me relajes todavía, fiera. Alguien anduvo descargando porquerías y el sistema está hasta el cuello de virus.\nCamina hacia la terminal y presiona [E] tú mismo para pasar el escáner ClamAV y purgar las amenazas."
		}
	]
	_show_dialog_sequence(dialogs, func():
		sys_step = SistemasStep.WAIT_INTERACT_MALWARE
		_set_holo_sub_text("[PASO 2] ACÉRCATE A LA TERMINAL Y PRESIONA [E]")
		GameManager.spawn_floating_text("Paso 2: Camina a la terminal y presiona [E]", true)
		if is_instance_valid(systems_pc_inst):
			systems_pc_inst.custom_prompt = "[E] Ejecutar Escáner de Malware ClamAV"
		_restore_player_free_movement()
	)

func _on_malware_scanner_completed() -> void:
	var dialogs: Array = [
		{
			"speaker": "[JEREMIAS // ¡AMENAZAS PURGADAS!]",
			"text": "¡Boom! ¡Limpio como patena! Ni un mísero gusano sobrevivió a esa purga. Ya te estás creyendo hacker de película, ¿eh?"
		},
		{
			"speaker": "[JEREMIAS // PASO 3 · DRIVERS & KERNEL]",
			"text": "Paso 3: Solo nos queda el toque final para que este bicho vuele. Faltan los drivers de la gráfica y el chipset.\nCamina hacia la terminal y presiona [E] para actualizar los controladores a versión WHQL."
		}
	]
	_show_dialog_sequence(dialogs, func():
		sys_step = SistemasStep.WAIT_INTERACT_DRIVERS
		_set_holo_sub_text("[PASO 3] ACÉRCATE A LA TERMINAL Y PRESIONA [E]")
		GameManager.spawn_floating_text("Paso 3: Camina a la terminal y presiona [E]", true)
		if is_instance_valid(systems_pc_inst):
			systems_pc_inst.custom_prompt = "[E] Actualizar Controladores y Módulos de Kernel"
		_restore_player_free_movement()
	)

func _on_drivers_completed() -> void:
	sys_step = SistemasStep.COMPLETED
	_set_holo_sub_text("¡TUTORIAL DE SISTEMAS COMPLETADO! SOFTWARE AL 100% ✓")

	var dialogs: Array = [
		{
			"speaker": "[JEREMIAS // ¡SOFTWARE OPTIMIZADO AL 100%!]",
			"text": "¡Naaaaah, qué animal! ¡Corriendo a 144Hz y con latencia cero! Te tengo que admitir que tienes madera de sysadmin, crack."
		},
		{
			"speaker": "[JEREMIAS // CERTIFICACIÓN APROBADA]",
			"text": "Completaste el tutorial de sistemas sin prender fuego la terminal ni romper el kernel. ¡Eso ya es un logro histórico en mi libro!\nPresiona [E] para reclamar tu certificación oficial."
		}
	]
	_show_dialog_sequence(dialogs, func():
		_show_tutorial_victory()
	)

func _on_sistemas_minigame_failed(tease_text: String) -> void:
	var dialogs: Array = [
		{
			"speaker": "[JEREMIAS // ¿QUÉ FUE ESO?]",
			"text": tease_text
		}
	]
	_show_dialog_sequence(dialogs, func():
		_restore_player_free_movement()
	)

# =============================================================================
# MODO 3: SERVIDOR (SANTIAGO)
# Personalidad: Chico pelo liso, alto, ojos claros, bastante burlón, sarcástico,
# le encanta hacer juegos de palabras y chistes malos de tecnología.
# Flujo: Diálogo [E] -> Libertad de movimiento -> Acercarse y dar [E] él mismo
# =============================================================================

func _start_servidor_intro() -> void:
	srv_step = ServidorStep.INTRO
	var intro_dialogs: Array = [
		{
			"speaker": "[SANTIAGO // INFRAESTRUCTURA & RACKS]",
			"text": "Bueno, bueno... miren a quién tenemos por aquí. Ya para este punto debes de creerte un maestro absoluto montando PCs de juguete con Joa y Jeremias, ¿verdad? Pero lamento bajarte de esa nube: bienvenido a las grandes ligas... esto es un servidor."
		},
		{
			"speaker": "[SANTIAGO // DATA CENTER ARCHITECTURE]",
			"text": "Un servidor es algo más complicado: con más procesadores Xeon escupiendo fuego, bancos masivos de memoria ECC y discos enterprise en RAID. Aquí te he dejado uno ya ensamblado en su chasis... porque si te dejaba armarlo desde cero, seguro me montabas la placa madre al revés."
		},
		{
			"speaker": "[SANTIAGO // OBJETIVOS DEL SERVIDOR]",
			"text": "Pero faltan 2 cosas importantes antes de ponerlo en producción: montar y depurar su sistema de servidor, y colocarle la refrigeración líquida custom loop para evitar fallas por sobrecalentamiento."
		},
		{
			"speaker": "[SANTIAGO // ¿ESTÁS LISTO?]",
			"text": "¿Estás listo? Vamos a ver si todo ese conocimiento previo en los otros 2 modos se te quedó grabado... o si se te evaporó como memoria volátil al cortar la corriente."
		},
		{
			"speaker": "[SANTIAGO // CHISTE TÉCNICO INCLUIDO]",
			"text": "Y por cierto... ¿sabes por qué los administradores de servidores nunca duermen? Porque sueñan en binario y le tienen fobia al 'Kernel Panic'... ja, qué buen chiste.\nEn fin, camina libremente hacia el rack y presiona [E] tú mismo para comenzar la depuración."
		}
	]

	_show_dialog_sequence(intro_dialogs, func():
		srv_step = ServidorStep.WAIT_INTERACT_DEBUGGER
		_set_holo_sub_text("[PASO 1] ACÉRCATE AL RACK Y PRESIONA [E]")
		GameManager.spawn_floating_text("Paso 1: Camina hacia el rack y presiona [E]", true)
		if is_instance_valid(server_rack_inst):
			server_rack_inst.custom_prompt = "[E] Depurar Daemon del Servidor"
		_restore_player_free_movement()
	)

func _on_interact_server_rack(_player_ref) -> void:
	if is_dialog_active or is_esc_interrupt_active or is_instance_valid(active_minigame):
		return

	match srv_step:
		ServidorStep.WAIT_INTERACT_DEBUGGER:
			_launch_minigame_servidor(DEBUGGER_MINIGAME_SCENE, "Sistemas Andromeda Linux", func(success: bool):
				if success:
					_on_debugger_completed()
				else:
					_on_servidor_minigame_failed("Vaya... eso estuvo a punto de convertirse en una fuga de memoria cósmica. Camina hacia el rack y vuelve a presionar [E] cuando tus neuronas se sincronicen, genio.")
			)

		ServidorStep.WAIT_INTERACT_COOLING:
			_launch_minigame_servidor(LIQUID_COOLING_SCENE, "Refrigeracion Liquida Custom Loop", func(success: bool):
				if success:
					_on_liquid_cooling_completed()
				else:
					_on_servidor_minigame_failed("¡Oye, oye! ¡Casi inundas los zócalos PCIe! Menos mal que los sensores apagaron la bomba a tiempo. Camina hacia el rack, presiona [E] y no me hagas un cortocircuito.")
			)

func _launch_minigame_servidor(minigame_scene: PackedScene, comp_key: String, on_result: Callable) -> void:
	if minigame_scene == null:
		return

	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	if player and player.hud_node:
		player.hud_node.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var minigame = minigame_scene.instantiate()
	minigame.set("is_tutorial_mode", true)
	active_minigame = minigame
	get_tree().root.add_child(minigame)

	minigame.connect("minigame_finished", func(success: bool):
		if is_instance_valid(active_minigame):
			active_minigame.queue_free()
			active_minigame = null

		if player and player.hud_node:
			player.hud_node.visible = true

		if success and is_instance_valid(server_rack_inst):
			server_rack_inst.components[comp_key] = "fixed"
			server_rack_inst.components_installed_counts[comp_key] = 1
			server_rack_inst.update_3d_state()

		if on_result.is_valid():
			on_result.call(success)
	)

func _on_debugger_completed() -> void:
	var dialogs: Array = [
		{
			"speaker": "[JEREMIAS // ¡CÓDIGO PROGRAMADO CON ÉXITO!]",
			"text": "¡Naaaaah, qué crack! Has dominado todos los comandos: /sistem-configure, node name() {}, delimitadores [] para var y const, {} para funcs y la lógica if/else. ¡Todo compilado con exit al 100%!"
		},
		{
			"speaker": "[SANTIAGO // PASO 2 · LOOP LÍQUIDO CUSTOM]",
			"text": "Paso 2: Ahora viene lo divertido... y peligroso. La refrigeración líquida custom loop. ¿Líquido conductor dentro de un rack que vale más que mi departamento? ¿Qué podría salir mal?\nCamina hacia el rack y presiona [E] tú mismo para conectar los racores y purgar el refrigerante sin derramar una sola gota."
		}
	]
	_show_dialog_sequence(dialogs, func():
		srv_step = ServidorStep.WAIT_INTERACT_COOLING
		_set_holo_sub_text("[PASO 2] ACÉRCATE AL RACK Y PRESIONA [E]")
		GameManager.spawn_floating_text("Paso 2: Camina hacia el rack y presiona [E]", true)
		if is_instance_valid(server_rack_inst):
			server_rack_inst.custom_prompt = "[E] Montar y Purgar Refrigeración Líquida"
		_restore_player_free_movement()
	)

func _on_liquid_cooling_completed() -> void:
	srv_step = ServidorStep.COMPLETED
	_set_holo_sub_text("¡TUTORIAL DE SERVIDOR COMPLETADO! DATA CENTER AL 100% ✓")

	if is_instance_valid(server_rack_inst):
		server_rack_inst.update_3d_state()

	var dialogs: Array = [
		{
			"speaker": "[SANTIAGO // ¡TEMPERATURAS EN BAJA!]",
			"text": "¡Cero fugas y el flujo de refrigerante está óptimo! Los procesadores Xeon acaban de pasar de 'volcán en erupción' a 'cubito de hielo'. Bien jugado, genio."
		},
		{
			"speaker": "[SANTIAGO // CERTIFICACIÓN ENTERPRISE]",
			"text": "¿Sabes cuál es la diferencia entre un novato y un administrador de servidores? ¡Que tú acabas de graduarte con honores y el servidor sigue en una sola pieza!\nPresiona [E] para recibir tu certificación oficial."
		}
	]
	_show_dialog_sequence(dialogs, func():
		_show_tutorial_victory()
	)

func _on_servidor_minigame_failed(tease_text: String) -> void:
	var dialogs: Array = [
		{
			"speaker": "[SANTIAGO // ¿QUÉ PASÓ AHÍ?]",
			"text": tease_text
		}
	]
	_show_dialog_sequence(dialogs, func():
		_restore_player_free_movement()
	)

# =============================================================================
# FINALIZACIÓN Y REINICIO
# =============================================================================

func _show_tutorial_victory() -> void:
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Mapear tutorial completado y desbloquear su correspondiente nivel de práctica
	var tut_comp_to_node: Dictionary = {
		"general": 0,
		"cooler": 1,
		"ram": 2,
		"hdd": 3,
		"gpu": 4,
		"psu": 5,
		"cpu": 6
	}
	var tut_comp_to_node_sis: Dictionary = {
		"general": 0,
		"os_install": 1,
		"malware_scan": 2,
		"driver_install": 3,
		"adware_cleaner": 4,
		"code_debugger": 5,
		"usb_backup": 6
	}
	var effective_mode = current_mode if current_mode in ["reparacion", "sistema", "servidor"] else "reparacion"
	var current_node_idx = tut_comp_to_node_sis.get(target_component, 0) if effective_mode == "sistema" else tut_comp_to_node.get(target_component, 0)
	var tut_to_practice: Dictionary = {
		0: 25, # Intro -> Práctica Reto 0
		1: 19, # Módulo 1 -> Práctica 1
		2: 20, # Módulo 2 -> Práctica 2
		3: 21, # Módulo 3 -> Práctica 3
		4: 22, # Módulo 4 -> Práctica 4
		5: 23, # Módulo 5 -> Práctica 5
		6: 24  # Módulo 6 -> Práctica 6
	}
	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		sm.mark_node_completed(effective_mode, current_node_idx)
		if tut_to_practice.has(current_node_idx):
			var prac_node = tut_to_practice[current_node_idx]
			sm.unlock_node(effective_mode, prac_node)
			SaveManager.just_unlocked_node = prac_node
		sm.pending_glossary_toast_topic = target_component

	if is_instance_valid(victory_modal):
		if victory_modal.has_method("setup_mode"):
			victory_modal.setup_mode(current_mode)
		victory_modal.open()

func _on_reintentar() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	CyberPlayTransition.play(
		get_tree(),
		"res://scenes/gameplay/LevelTutorial.tscn",
		"REINICIANDO ENTRENAMIENTO",
		"// RESTABLECIENDO COMPONENTES DE PRUEBA //",
		Callable(),
		true,
		false,
		current_mode
	)

func _on_siguiente() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		sm.pending_glossary_toast_topic = target_component
	LevelSelect.initial_tab = "niveles"
	LevelSelect.initial_mode = current_mode
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.current_mode = current_mode
	CyberPlayTransition.play_exit(
		get_tree(),
		current_mode,
		"res://scenes/menus/LevelSelect.tscn",
		"TUTORIAL COMPLETADO",
		"// CERTIFICACIÓN TÉCNICA OFICIAL REGISTRADA //"
	)
