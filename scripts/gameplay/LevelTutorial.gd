extends Node3D

# =============================================================================
# NIVEL TUTORIAL 3D - SISTEMA INTERACTIVO DE GUÍA PASO A PASO "HOLA LIDEL"
# GUÍA NARRADA CON DIÁLOGOS DINÁMICOS EXCLUSIVOS PARA EL TUTORIAL
# =============================================================================

const DIALOG_SCENE: PackedScene = preload("res://scenes/ui/DialogBox.tscn")
const VICTORY_MODAL_SCENE: PackedScene = preload("res://scenes/ui/TutorialVictoryModal.tscn")

enum TutorialStep {
	INTRO,
	WAIT_INSPECT_PC,
	WAIT_REMOVE_RAM,
	WAIT_FETCH_RAM,
	WAIT_INSTALL_RAM,
	WAIT_HANDLE_SSD,
	WAIT_HANDLE_PSU,
	COMPLETED
}

@onready var player: CharacterBody3D = $Player
@onready var hud: Control = $CanvasLayerHUD/HUD
@onready var pc: StaticBody3D = $WorkBench/Computer1
@onready var holo_sub_banner: MeshInstance3D = $WorkBench/HoloSubBanner

var dialog_box: Control = null
var victory_modal: Control = null
var current_step: TutorialStep = TutorialStep.INTRO
var is_dialog_active: bool = false

func _ready() -> void:
	if player and hud:
		player.hud_node = hud
		
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

	# Instanciar el sistema de diálogo en CanvasLayerDialog (capa superior a cualquier modal)
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

	# Escuchar eventos de adición y remoción de nodos para detectar apertura y cierre de modales
	get_tree().node_added.connect(_on_tree_node_added)
	get_tree().node_removed.connect(func(_n):
		if not is_dialog_active:
			_check_state_transitions()
	)
	GameManager.backpack_updated.connect(_on_backpack_updated)

	# Iniciar cinemática de entrada del técnico
	if player and player.has_method("play_intro_cinematic"):
		player.play_intro_cinematic(func():
			_start_intro_sequence()
		)
	else:
		_start_intro_sequence()

func _process(_delta: float) -> void:
	if is_dialog_active or (is_instance_valid(victory_modal) and victory_modal.visible):
		if player and player.has_method("set_movement_enabled") and player.can_move:
			player.set_movement_enabled(false)
		if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	_check_state_transitions()

func _set_holo_sub_text(text: String) -> void:
	if holo_sub_banner and holo_sub_banner.mesh is TextMesh:
		var tm = holo_sub_banner.mesh.duplicate() as TextMesh
		tm.text = text
		holo_sub_banner.mesh = tm

func _is_modal_currently_open() -> bool:
	for child in get_tree().root.get_children():
		if child.name.begins_with("PCInspectionModal") \
			or child.name.begins_with("RAMSelectionModal") \
			or (child.has_method("is_closed") and not child.is_closed):
			return true
	return false

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
			if player and player.has_method("set_movement_enabled"):
				player.set_movement_enabled(true)
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			
		if on_finish.is_valid():
			on_finish.call()
	)

# =============================================================================
# SECUENCIA DE DIÁLOGOS PASO A PASO
# =============================================================================

func _get_ram_type_name() -> String:
	if is_instance_valid(pc) and "ram_type" in pc and str(pc.ram_type) != "":
		return str(pc.ram_type).to_upper()
	for it in GameManager.backpack:
		if it is Dictionary and it.get("name") == "RAM" and str(it.get("ram_type", "")) != "":
			return str(it.get("ram_type")).to_upper()
	return "DDR4"

func _start_intro_sequence() -> void:
	GameManager.timer_active = false
	var intro_dialogs: Array = [
		{
			"speaker": "[SISTEMA // TUTORIAL]",
			"text": "hola lidel :)"
		},
		{
			"speaker": "[SISTEMA // TUTORIAL]",
			"text": "¡Te doy la bienvenida al centro de entrenamiento técnico!\nAquí aprenderás paso a paso los fundamentos para reparar computadoras."
		},
		{
			"speaker": "[CONTROLES // MOVIMIENTO]",
			"text": "Para moverte usa las teclas [W, A, S, D], el ratón para mirar alrededor, [Espacio] para saltar y mantén presionada la tecla [Shift] para correr más rápido."
		},
		{
			"speaker": "[OBJETIVO 1 // ACÉRCATE A LA PC]",
			"text": "Paso 1: Camina hacia la mesa central, apunta con la mira a la computadora y presiona la tecla [E] para abrirla e inspeccionar su interior."
		}
	]
	
	_show_dialog_sequence(intro_dialogs, func():
		current_step = TutorialStep.WAIT_INSPECT_PC
		_set_holo_sub_text("[PASO 1] ACÉRCATE A LA COMPUTADORA Y PRESIONA [E]")
		GameManager.spawn_floating_text("Paso 1: Acércate a la PC y presiona [E]", true)
	)

func _advance_to_remove_ram() -> void:
	current_step = TutorialStep.WAIT_REMOVE_RAM
	var exact_ram = _get_ram_type_name()
	_set_holo_sub_text("[PASO 2] OBSERVA LA RAM %s [❌] Y HAZ CLIC EN 'SACAR'" % exact_ram)
	
	var inspect_dialogs: Array = [
		{
			"speaker": "[SISTEMA // INSPECCIÓN DE PC]",
			"text": "¡Excelente! Ahora estás viendo el interior del gabinete de la PC.\nAquí puedes observar todos los componentes instalados y su estado (Roto ❌ / OK ✓ / Vacío)."
		},
		{
			"speaker": "[OBJETIVO 2 // EXTRAER PIEZA DEFECTUOSA]",
			"text": "Paso 2: Observa la Memoria RAM %s: está averiada [❌].\nHaz clic en el botón 'SACAR' para desmontarla de la placa base y guardarla en tu mochila técnica." % exact_ram
		}
	]
	_show_dialog_sequence(inspect_dialogs)

func _advance_to_fetch_ram() -> void:
	current_step = TutorialStep.WAIT_FETCH_RAM
	var exact_ram = _get_ram_type_name()
	_set_holo_sub_text("[PASO 3] CIERRA LA PC [VOLVER], VE A LA CAJA DE RAM Y TOMA UN REPUESTO DE RAM %s" % exact_ram)
	
	var fetch_dialogs: Array = [
		{
			"speaker": "[SISTEMA // PIEZA EN MOCHILA]",
			"text": "¡Muy bien! Has desmontado el módulo averiado de Memoria RAM %s y ahora está guardado en tu mochila técnica (ranuras superiores).\n(Consejo: si necesitas espacio en tu mochila, puedes desechar piezas rotas en la papelera)." % exact_ram
		},
		{
			"speaker": "[OBJETIVO 3 // BUSCAR REPUESTO NUEVO]",
			"text": "Paso 3: Haz clic en el botón 'VOLVER' para cerrar el chasis de la PC.\nCamina hacia las cajas de repuestos a la derecha, acércate a 'REPUESTO: RAM' y presiona [E] para elegir exactamente un repuesto nuevo de Memoria RAM %s compatible." % exact_ram
		}
	]
	_show_dialog_sequence(fetch_dialogs)

func _advance_to_install_ram() -> void:
	current_step = TutorialStep.WAIT_INSTALL_RAM
	var exact_ram = _get_ram_type_name()
	_set_holo_sub_text("[PASO 4] REGRESA A LA PC [E] E INSTALA LA RAM %s EN SU RANURA" % exact_ram)
	
	var install_dialogs: Array = [
		{
			"speaker": "[SISTEMA // REPUESTO OBTENIDO]",
			"text": "¡Perfecto! Ya tienes una Memoria RAM %s nueva y 100%% compatible en tu mochila técnica." % exact_ram
		},
		{
			"speaker": "[OBJETIVO 4 // INSTALAR EL REPUESTO]",
			"text": "Paso 4: Regresa a la computadora central, presiona [E] para abrirla e instala la nueva Memoria RAM %s haciendo clic en su ranura vacía." % exact_ram
		}
	]
	_show_dialog_sequence(install_dialogs)

func _advance_to_handle_ssd() -> void:
	current_step = TutorialStep.WAIT_HANDLE_SSD
	_set_holo_sub_text("[PASO 2] DESMONTA EL DISCO DURO (SSD) Y COLOCA EL REPUESTO NUEVO")
	GameManager.spawn_floating_text("Paso 2: Ahora desmonta y coloca el Disco Duro (SSD)", true)
	
	var ssd_dialogs: Array = [
		{
			"speaker": "[SISTEMA // RAM INSTALADA CON ÉXITO]",
			"text": "¡Gran trabajo! Has colocado la Memoria RAM correctamente y su zócalo ya está 100%% operativo."
		},
		{
			"speaker": "[OBJETIVO 2 // AHORA EL DISCO DURO]",
			"text": "Paso 2: Ahora el Disco Duro (Almacenamiento SSD).\nEn el panel de la PC, ubica 'ALMACENAMIENTO (SSD / HDD)' averiado [❌] y haz clic en 'SACAR'.\nUsa el destornillador para quitar el tornillo trasero, haz clic en el recuadro resaltado de los PINES para destrabar el conector, arrastra el disco para retirarlo y luego instala el repuesto nuevo."
		}
	]
	_show_dialog_sequence(ssd_dialogs)

func _advance_to_handle_psu() -> void:
	current_step = TutorialStep.WAIT_HANDLE_PSU
	_set_holo_sub_text("[PASO 3] DESMONTA LA FUENTE DE PODER (PSU) Y COLOCA EL REPUESTO NUEVO")
	GameManager.spawn_floating_text("Paso 3: Ahora desmonta y coloca la Fuente de Poder", true)
	
	var psu_dialogs: Array = [
		{
			"speaker": "[SISTEMA // DISCO DURO INSTALADO]",
			"text": "¡Perfecto! El almacenamiento SSD ha quedado conectado y asegurado en el puerto con éxito."
		},
		{
			"speaker": "[OBJETIVO 3 // AHORA LA FUENTE DE PODER]",
			"text": "Paso 3: Ahora la Fuente de Poder (PSU).\nUbica 'FUENTE DE PODER' averiada [❌] y haz clic en 'SACAR'.\nDesconecta el conector ATX principal y el arnés de CPU para retirar la fuente dañada, y luego instala la nueva fuente."
		}
	]
	_show_dialog_sequence(psu_dialogs)

func _advance_to_completed() -> void:
	if current_step == TutorialStep.COMPLETED:
		return
	current_step = TutorialStep.COMPLETED
	_set_holo_sub_text("¡TUTORIAL COMPLETADO! HABILIDADES ADQUIRIDAS AL 100% ✓")
	
	# Si algún modal de inspección o minijuego sigue abierto, cerrarlo inmediatamente
	for child in get_tree().root.get_children():
		if child.name.begins_with("PCInspectionModal") \
			or child.name.begins_with("RAMSelectionModal") \
			or child.name.ends_with("Minigame") \
			or child.is_in_group("minigames"):
			child.queue_free()
	
	var completed_dialogs: Array = [
		{
			"speaker": "[SISTEMA // TUTORIAL COMPLETADO]",
			"text": "¡FELICITACIONES, LÍDER! :)\n¡Has colocado todas las piezas buenas en la computadora y el equipo quedó 100%% reparado y operativo!"
		},
		{
			"speaker": "[CERTIFICACIÓN TÉCNICA // APROBADA]",
			"text": "¡Has completado el entrenamiento técnico al 100%%!\nYa dominas los procedimientos para Memoria RAM, Almacenamiento SSD y Fuente de Poder.\n¡Presiona [E] para continuar!"
		}
	]
	_show_dialog_sequence(completed_dialogs, func():
		_show_tutorial_victory()
	)

func _show_tutorial_victory() -> void:
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if is_instance_valid(victory_modal):
		victory_modal.open()

# =============================================================================
# MONITOREO DE EVENTOS Y PROGRESIÓN
# =============================================================================

func _on_tree_node_added(node: Node) -> void:
	if current_step == TutorialStep.WAIT_INSPECT_PC:
		if node.name.begins_with("PCInspectionModal") or node.has_method("setup_pc"):
			# Dar un pequeño frame para que el modal se asiente antes de mostrar la guía
			get_tree().create_timer(0.12).timeout.connect(func():
				if current_step == TutorialStep.WAIT_INSPECT_PC:
					_advance_to_remove_ram()
			)

func _on_backpack_updated(_items: Array) -> void:
	if is_dialog_active:
		return
	_check_state_transitions()

func _check_state_transitions() -> void:
	if not is_instance_valid(pc) or current_step == TutorialStep.COMPLETED:
		return
		
	var ram_ok = pc.components.get("RAM", "") in ["ok", "fixed"]
	var ssd_ok = pc.components.get("Disco Duro", "") in ["ok", "fixed"]
	var psu_ok = pc.components.get("Fuente", "") in ["ok", "fixed"]
	
	# Verificación maestra: si todas las piezas del tutorial fueron reparadas o si la PC está 100% reparada
	if (ram_ok and ssd_ok and psu_ok) or pc.is_fully_repaired():
		_advance_to_completed()
		return

	match current_step:
		TutorialStep.WAIT_REMOVE_RAM:
			# Si la ranura de RAM de la PC quedó vacía (la desmontó)
			if pc.components.get("RAM", "") == "empty":
				_advance_to_fetch_ram()
				
		TutorialStep.WAIT_FETCH_RAM:
			# Si tomó una RAM funcional en la mochila Y ya cerró el modal de selección
			if _has_functional_ram_in_backpack() and not _is_modal_currently_open():
				_advance_to_install_ram()
				
		TutorialStep.WAIT_INSTALL_RAM:
			# Si instaló la RAM en la PC con éxito
			if ram_ok:
				_advance_to_handle_ssd()
				
		TutorialStep.WAIT_HANDLE_SSD:
			# Si instaló el Disco Duro en la PC con éxito
			if ssd_ok:
				_advance_to_handle_psu()
				
		TutorialStep.WAIT_HANDLE_PSU:
			# Si instaló la Fuente en la PC con éxito
			if psu_ok:
				_advance_to_completed()

func _has_functional_ram_in_backpack() -> bool:
	for item in GameManager.backpack:
		if item is Dictionary and item.get("type", "") == "RAM":
			if item.get("functional", false) or not item.get("broken", true):
				return true
	return false

func _on_reintentar() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	CyberPlayTransition.play(
		get_tree(),
		"res://scenes/gameplay/LevelTutorial.tscn",
		"REINICIANDO ENTRENAMIENTO",
		"// RESTABLECIENDO COMPONENTES DE PRUEBA //",
		Callable(),
		true
	)

func _on_siguiente() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	CyberPlayTransition.play_exit(
		get_tree(),
		"tutorial",
		"res://scenes/menus/LevelSelect.tscn",
		"TUTORIAL COMPLETADO",
		"// CERTIFICACIÓN TÉCNICA OFICIAL REGISTRADA //"
	)
