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

func _process(_delta: float) -> void:
	if is_dialog_active or is_esc_interrupt_active or (is_instance_valid(victory_modal) and victory_modal.visible) or is_instance_valid(active_minigame):
		if player and player.has_method("set_movement_enabled") and player.can_move:
			player.set_movement_enabled(false)
		if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	if current_mode == "reparacion":
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

	# Configurar la PC del tutorial para que solo tenga RAM, Fuente y Memorias SSD/HDD
	if pc:
		pc.set_meta("is_tutorial_pc", true)
		pc.diagnostic_question = "INDUCCIÓN BÁSICA: Aprende a retirar e inspeccionar los componentes fundamentales:\n• Memoria RAM · • Fuente de Poder (PSU) · • Almacenamiento SSD / HDD"
		pc.diagnostic_faulty_parts.assign(["RAM", "Fuente", "Disco Duro"])
		pc.components = {
			"RAM": "broken",
			"Fuente": "broken",
			"Disco Duro": "broken",
			"Grafica": "empty",
			"Placa Madre": "ok",
			"Fan Cooler": "empty",
			"CPU": "empty"
		}
		if pc.has_method("update_3d_state"):
			pc.update_3d_state()

	# Escuchar eventos de modales de hardware
	get_tree().node_added.connect(_on_tree_node_added)
	get_tree().node_removed.connect(func(_n):
		if not is_dialog_active:
			_check_reparacion_transitions()
	)
	GameManager.backpack_updated.connect(_on_backpack_updated)

func _setup_sistemas_environment() -> void:
	_set_holo_banner_text("LABORATORIO DE SOFTWARE // SISTEMAS OPERATIVOS")
	_set_holo_sub_text("[PASO 1] ACÉRCATE A LA TERMINAL Y PRESIONA [E]")

	# En sistemas no se usan herramientas físicas (puro mouse y teclado)
	if hud and hud.has_method("set_tools_bar_visible"):
		hud.set_tools_bar_visible(false)

	if pc:
		pc.visible = false
		pc.collision_layer = 0
		pc.collision_mask = 0

	_hide_hardware_workshop_props()

	systems_pc_inst = SYSTEMS_PC_SCENE.instantiate()
	systems_pc_inst.name = "SystemsComputerTutorial"
	systems_pc_inst.position = Vector3(0, 0.912, 0)
	work_bench.add_child(systems_pc_inst)

	systems_pc_inst.components = {
		"Sistema Operativo": "broken",
		"Drivers": "broken",
		"Malware": "broken",
		"Adware": "fixed",
		"Debugger": "fixed",
		"Pendrive USB": "fixed",
		"Arcade Ciberdefensa": "fixed"
	}
	systems_pc_inst.custom_prompt = "[E] Iniciar Instalación de Andromeda OS"
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

	var mesa_mesh = work_bench.get_node_or_null("MesaReparacion") as Node3D
	if mesa_mesh:
		mesa_mesh.visible = false
	var bench_col = work_bench.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if bench_col:
		bench_col.disabled = true
	work_bench.collision_layer = 0
	work_bench.collision_mask = 0

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

func _start_current_mode_intro() -> void:
	GameManager.timer_active = false
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
	var text = "¿E-eh...? ¿T-te vas tan pronto? *(se acomoda los lentes con timidez y tristeza)*...\n¿Acaso... te aburrió mi explicación? L-lo siento mucho si hablo muy despacio o si soy aburrida...\n¿De verdad quieres salir al menú o podemos seguir practicando juntos?"
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
					"speaker": "[JOA // DESPEDIDA]",
					"text": "B-bueno... entiendo. Espero no haberte molestado mucho. Vuelve cuando quieras, aquí estaré..."
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
	var intro_dialogs: Array = [
		{
			"speaker": "[JOA // TÉCNICA DE HARDWARE]",
			"text": "H-hola... b-bueno, bienvenido al taller de hardware... *(se acomoda los lentes con timidez)*. Yo... soy Joa. Te voy a acompañar paso a paso para que no te sientas abrumado, ¿de acuerdo?"
		},
		{
			"speaker": "[JOA // MOVIMIENTO & CONTROLES]",
			"text": "Para moverte puedes usar [W, A, S, D], con el ratón miras alrededor y con [Espacio] saltas... Ah, y si mantienes [Shift] corres un poco más rápido... sólo ten cuidado de no tropezar con las herramientas."
		},
		{
			"speaker": "[JOA // TUS HERRAMIENTAS]",
			"text": "E-en la parte inferior verás tus herramientas... De momento sólo te habilité las dos primeras: el destornillador Phillips [ 1 ] y el de pala [ 2 ]... *(se ajusta los lentes nerviosa)*. Con esas dos tenemos más que suficiente para empezar sin que te compliques."
		},
		{
			"speaker": "[JOA // OBJETIVO 1]",
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
	_set_holo_sub_text("[PASO 5] DESMONTA EL DISCO DURO (SSD) Y COLOCA EL REPUESTO NUEVO")
	GameManager.spawn_floating_text("Paso 5: Ahora desmonta y coloca el Disco Duro (SSD)", true)

	var ssd_dialogs: Array = [
		{
			"speaker": "[JOA // RAM INSTALADA]",
			"text": "¡L-lo hiciste de maravilla! La Memoria RAM encajó a la perfección y el zócalo ya está completamente operativo."
		},
		{
			"speaker": "[JOA // ALMACENAMIENTO SSD]",
			"text": "Paso 5: Ahora debemos cambiar el almacenamiento (SSD). Está marcado con [❌]. Haz clic en 'SACAR'. Usa el destornillador para el tornillito, desconecta los pines con cuidado, retira el disco averiado y monta el nuevo SSD."
		}
	]
	_show_dialog_sequence(ssd_dialogs)

func _advance_to_handle_psu() -> void:
	rep_step = ReparacionStep.WAIT_HANDLE_PSU
	_set_holo_sub_text("[PASO 6] DESMONTA LA FUENTE DE PODER (PSU) Y COLOCA EL REPUESTO NUEVO")
	GameManager.spawn_floating_text("Paso 6: Ahora desmonta y coloca la Fuente de Poder", true)

	var psu_dialogs: Array = [
		{
			"speaker": "[JOA // SSD INSTALADO]",
			"text": "Uff... q-qué alivio, el almacenamiento SSD quedó firme y seguro. Lo estás haciendo de verdad muy bien..."
		},
		{
			"speaker": "[JOA // FUENTE DE PODER]",
			"text": "Paso 6: Por último nos falta la Fuente de Poder (PSU). Ubica 'FUENTE DE PODER' averiada [❌], haz clic en 'SACAR', desconecta los cables del conector ATX y la CPU sin tirar con brusquedad... e instala la nueva fuente."
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
			or child.name.ends_with("Minigame") \
			or child.is_in_group("minigames"):
			child.queue_free()

	var completed_dialogs: Array = [
		{
			"speaker": "[JOA // TUTORIAL COMPLETADO]",
			"text": "¡L-lo lograste! *(sonríe aliviada y se acomoda los lentes)*. Todas las piezas están en perfecto estado y la computadora encendió sin un solo error."
		},
		{
			"speaker": "[JOA // CERTIFICACIÓN OFICIAL]",
			"text": "E-eres realmente talentoso para esto... Ya dominas el reemplazo de Memoria RAM, Almacenamiento SSD y Fuente de Poder.\n¡Tu certificación técnica está aprobada! Presiona [E] para continuar."
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
	var psu_ok = pc.components.get("Fuente", "") in ["ok", "fixed"]

	if (ram_ok and ssd_ok and psu_ok) or pc.is_fully_repaired():
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
	sys_step = SistemasStep.INTRO
	var intro_dialogs: Array = [
		{
			"speaker": "[JEREMIAS // SYSADMIN & DEV]",
			"text": "¡Epaaa, qué onda, fiera! ¿Te perdiste o viniste a aprender con el mejor? Soy Jeremias, el de los rulos rebeldes y el amo y señor del software en este laboratorio."
		},
		{
			"speaker": "[JEREMIAS // FILOSOFÍA DE SOFTWARE]",
			"text": "Aquí no nos manchamos las manos con pasta térmica ni polvo, crack. Aquí dominamos el sistema operativo, cazamos virus y ajustamos el kernel como verdaderos hackers de película."
		},
		{
			"speaker": "[JEREMIAS // ¿HERRAMIENTAS? ¡JA!]",
			"text": "¿Y las herramientas? ¡Olvídate de ellas! Aquí es puro mouse y teclado, fiera, así que nada de andar con eso de [ 1 ], [ 2 ], [ 3 ], [ 4 ] ni [ 5 ]. Aquí el único fierro que vas a tocar es tu teclado."
		},
		{
			"speaker": "[JEREMIAS // PASO 1 · INSTALACIÓN DE OS]",
			"text": "Paso 1: Cuando termine de hablarte, camina libremente hacia esa terminal en la mesa y presiona [E] tú mismo. Vamos a particionar el disco en GPT e instalar Andromeda OS. ¡A ver qué tan rápido eres con las particiones!"
		}
	]

	_show_dialog_sequence(intro_dialogs, func():
		sys_step = SistemasStep.WAIT_INTERACT_OS
		_set_holo_sub_text("[PASO 1] ACÉRCATE A LA TERMINAL Y PRESIONA [E]")
		GameManager.spawn_floating_text("Paso 1: Camina a la terminal y presiona [E]", true)
		if is_instance_valid(systems_pc_inst):
			systems_pc_inst.custom_prompt = "[E] Instalar Andromeda OS (Partición GPT)"
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
			"speaker": "[SANTIAGO // ¡CÓDIGO DEPURADO!]",
			"text": "Vaya, miren al señor Neo saliendo de la Matrix... Ni un solo 'null pointer exception'. Casi me haces creer que sabes lo que haces."
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
