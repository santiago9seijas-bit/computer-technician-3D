extends Node3D

# =============================================================================
# NIVEL DE PRÁCTICA 3D - SALAS DE ENTRENAMIENTO DEDICADAS Y MAESTRA
# BANCOS DE TRABAJO LIBRES POR PIEZA: RAM, HDD/SSD, GPU, FAN COOLER, PSU Y CPU
# =============================================================================

const INTRO_SCENE: PackedScene = preload("res://scenes/ui/LevelIntroModal.tscn")
const DIALOG_SCENE: PackedScene = preload("res://scenes/ui/DialogBox.tscn")

static var practice_zone: String = "maestra"

@onready var player: CharacterBody3D = $Player
@onready var hud: Control = $CanvasLayerHUD/HUD

var dialog_box: Control = null
var current_zone: String = "maestra"

const PRACTICE_ZONE_CONFIG: Dictionary = {
	"ram": {
		"title": "ZONA DE PRÁCTICA: BANCO DE MEMORIAS RAM",
		"sub": "// ENTRENAMIENTO DE TRABAS Y MÓDULOS DDR //",
		"parts": ["RAM"],
		"components": {"RAM": "broken", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"},
		"joa_dialog": "¡H-hola!... *(se acomoda los lentes con dulzura)*. Bienvenida al Banco de Memorias RAM. Aquí puedes practicar abrir las pestañas laterales, extraer módulos DDR y encajar repuestos alineando la muesca central sin miedo a equivocarte. ¡Tómate todo el tiempo que necesites!",
		"desc": "¡Banco de Memoria RAM listo!\n\nInteractúa con la PC en la mesa [E] para extraer el módulo DDR averiado y toma un repuesto nuevo de la caja de RAM lateral.\n\nTiempo: Ilimitado."
	},
	"hdd": {
		"title": "ZONA DE PRÁCTICA: BANCO DE ALMACENAMIENTO HDD / SSD",
		"sub": "// TORNILLERÍA DE BAHÍA, CABLES SATA Y EXTRACCIÓN //",
		"parts": ["Disco Duro"],
		"components": {"RAM": "ok", "Disco Duro": "broken", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"},
		"joa_dialog": "¡Hola de nuevo!... *(sonríe ajustándose las gafas)*. En este banco puedes practicar con discos duros mecánicos y SSD SATA. Recuerda el orden: primero los 4 tornillos de las esquinas, luego desconectas el cable de datos y lo deslizas hacia la derecha. ¡Practica las veces que quieras!",
		"desc": "¡Banco de Almacenamiento listo!\n\nRetira los 4 tornillos, desconecta el cable SATA y desliza el disco hacia la derecha. Reemplázalo con un disco nuevo de la caja de repuestos.\n\nTiempo: Ilimitado."
	},
	"gpu": {
		"title": "ZONA DE PRÁCTICA: BANCO DE TARJETAS GRÁFICAS (GPU)",
		"sub": "// DESCONEXIÓN PCIE, BRACKET HDMI Y SOPORTE //",
		"parts": ["Grafica"],
		"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "broken", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"},
		"joa_dialog": "¡H-hola!... *(mira el gabinete con emoción y nervios)*. Las tarjetas gráficas son piezas muy valiosas... Desconecta siempre el cable PCIe para frenar los ventiladores antes de retirar los tornillos del bracket HDMI. ¡El soporte se queda firme en su sitio, no te preocupes!",
		"desc": "¡Banco de Tarjetas Gráficas listo!\n\nDesconecta la alimentación PCIe, retira los 2 tornillos del bracket metálico cerca de los puertos HDMI y extrae la gráfica. Reemplaza con una GPU nueva de la caja.\n\nTiempo: Ilimitado."
	},
	"cooler": {
		"title": "ZONA DE PRÁCTICA: BANCO DE REFRIGERACIÓN (FAN COOLER)",
		"sub": "// DESCONEXIÓN PWM Y APRIETE EN CRUZ //",
		"parts": ["Fan Cooler"],
		"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "broken", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"},
		"joa_dialog": "¡Bienvenida a la zona de refrigeración!... *(se acomoda los lentes con minuciosidad)*. El Fan Cooler debe desatornillarse en patrón diagonal de cruz para no romper el anclaje ni hacer presión desigual sobre el procesador. Desconecta el conector PWM de 4 pines y entrena con calma.",
		"desc": "¡Banco de Fan Cooler listo!\n\nDesconecta el arnés PWM, afloja los 4 tornillos en diagonal cruzada y monta el cooler de repuesto.\n\nTiempo: Ilimitado."
	},
	"psu": {
		"title": "ZONA DE PRÁCTICA: BANCO DE ENERGÍA (FUENTE PSU)",
		"sub": "// CONECTORES ATX 24 PINES, EPS Y ANCLAJES //",
		"parts": ["Fuente"],
		"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "broken", "CPU": "ok", "Placa Madre": "ok"},
		"joa_dialog": "¡Hola!... *(te saluda con una tímida reverencia)*. La fuente entrega corriente a todos los circuitos. Recuerda presionar los clips plásticos de seguridad del arnés ATX de 24 pines y el auxiliar EPS antes de jalar. ¡Aquí tienes todo el tiempo para perfeccionar la técnica!",
		"desc": "¡Banco de Fuentes ATX listo!\n\nDesconecta los arneses de potencia, desatornilla los 4 anclajes de chasis e instala la fuente de reemplazo.\n\nTiempo: Ilimitado."
	},
	"cpu": {
		"title": "ZONA DE PRÁCTICA: BANCO DE PROCESADORES (CPU)",
		"sub": "// PALANCA DE SOCKET LGA Y ALINEACIÓN DE PINES //",
		"parts": ["CPU"],
		"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "broken", "Placa Madre": "ok"},
		"joa_dialog": "¡Cuidado con la matriz de pines!... *(susurra con emoción)*. El procesador es el corazón de la máquina. Libera la palanca metálica de retención, levanta la placa de carga y alinea el triángulo dorado con suma suavidad. ¡Tú tienes una excelente precisión técnica!",
		"desc": "¡Banco de Procesadores listo!\n\nDesbloquea la palanca de tensión del socket LGA, monta el nuevo procesador y traba nuevamente la compuerta metálica.\n\nTiempo: Ilimitado."
	},
	"maestra": {
		"title": "SALA DE PRÁCTICA 3D MAESTRA",
		"sub": "// ENTRENAMIENTO TOTAL · TODAS LAS PIEZAS //",
		"parts": ["RAM", "Disco Duro", "Grafica", "Fan Cooler", "Fuente", "CPU"],
		"components": {"RAM": "broken", "Disco Duro": "broken", "Grafica": "broken", "Fan Cooler": "broken", "Fuente": "broken", "CPU": "broken", "Placa Madre": "ok"},
		"joa_dialog": "¡H-hola!... *(se acomoda los lentes con timidez y una amplia sonrisa aliviada)*. Bienvenida a la Sala de Práctica Maestra. Aquí puedes entrenar el desmontaje y montaje de todas las piezas del taller con calma: RAM, Discos HDD o SSD, Gráficas, Fan Cooler, Fuentes y CPU. ¡Tómate todo el tiempo que quieras!",
		"desc": "¡Laboratorio Maestro listo!\n\nPractica la extracción, cambio y fijación de todos los componentes del computador tomando repuestos de las cajas laterales.\n\nTiempo: Ilimitado."
	}
}

func _ready() -> void:
	if player and hud:
		player.hud_node = hud
		
	var btn_reintentar = hud.get_node_or_null("GameOverPanel/VBox/BtnReiniciarGO") as Button
	if btn_reintentar:
		btn_reintentar.pressed.connect(_on_reintentar)
		
	var btn_siguiente = hud.get_node_or_null("WinPanel/VBox/BtnSiguiente") as Button
	if btn_siguiente:
		btn_siguiente.pressed.connect(_on_siguiente)

	# Determinar zona de práctica activa
	var gm = get_node_or_null("/root/GameManager")
	if gm and "practice_target_mode" in gm and str(gm.practice_target_mode) != "":
		current_zone = str(gm.practice_target_mode).to_lower()
	elif practice_zone != "":
		current_zone = practice_zone.to_lower()
	else:
		current_zone = "maestra"

	if not PRACTICE_ZONE_CONFIG.has(current_zone):
		current_zone = "maestra"

	var cfg = PRACTICE_ZONE_CONFIG[current_zone]

	# Inicializar la práctica con tiempo infinito sin cuenta regresiva
	GameManager.start_level(999.0)
	GameManager.timer_active = false
	if hud and hud.has_method("set_infinite_time"):
		hud.set_infinite_time(true)

	# Configurar la PC de práctica con las piezas de esta zona
	var pc = get_node_or_null("WorkBench/Computer1")
	if pc:
		pc.set_meta("is_tutorial_pc", true)
		pc.diagnostic_question = "%s:\nEntrena sin presión de tiempo.\n%s" % [cfg["title"], cfg["sub"]]
		pc.diagnostic_faulty_parts.assign(cfg["parts"])
		pc.components = cfg["components"].duplicate()
		if pc.has_method("update_3d_state"):
			pc.update_3d_state()

	# Diálogo de bienvenida al modo de práctica con Joa
	dialog_box = DIALOG_SCENE.instantiate()
	$CanvasLayerHUD.add_child(dialog_box)

	if player and player.has_method("play_intro_cinematic"):
		player.play_intro_cinematic(func():
			_show_initial_dialog()
		)
	else:
		_show_initial_dialog()

func _show_initial_dialog() -> void:
	GameManager.timer_active = false
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var cfg = PRACTICE_ZONE_CONFIG.get(current_zone, PRACTICE_ZONE_CONFIG["maestra"])

	if dialog_box and dialog_box.has_method("show_message"):
		dialog_box.show_message(
			"JOA",
			cfg["joa_dialog"],
			func():
				_show_practice_briefing()
		)
	else:
		_show_practice_briefing()

func _show_practice_briefing() -> void:
	GameManager.timer_active = false
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var cfg = PRACTICE_ZONE_CONFIG.get(current_zone, PRACTICE_ZONE_CONFIG["maestra"])
	var modal = INTRO_SCENE.instantiate()
	add_child(modal)
	
	var title_lbl = modal.get_node_or_null("Margin/Panel/VBox/TitleVBox/Title") as Label
	if title_lbl:
		title_lbl.text = cfg["title"]
	var sub_lbl = modal.get_node_or_null("Margin/Panel/VBox/TitleVBox/Subtitle") as Label
	if sub_lbl:
		sub_lbl.text = cfg["sub"]
		
	var desc_lbl = modal.get_node_or_null("Margin/Panel/VBox/Content/DescVBox/LblDesc") as Label
	if desc_lbl:
		desc_lbl.text = cfg["desc"]
		
	modal.started.connect(func():
		GameManager.timer_active = false
		if player and player.has_method("set_movement_enabled"):
			player.set_movement_enabled(true)
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	)

func _on_reintentar() -> void:
	get_tree().reload_current_scene()

func _on_siguiente() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var gm = get_node_or_null("/root/GameManager")
	var m = gm.current_mode if gm and "current_mode" in gm else "reparacion"
	LevelSelect.initial_tab = "niveles"
	LevelSelect.initial_mode = m
	CyberPlayTransition.play_exit(get_tree(), m)
