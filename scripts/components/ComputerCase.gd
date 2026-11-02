extends StaticBody3D

@export var pc_id: int = 1
@export var custom_case_index: int = -1

var diagnostic_question: String = ""
var diagnostic_faulty_parts: Array[String] = []

const DIAGNOSTIC_CASES: Array[Dictionary] = [
	{
		"question": "¿El equipo enciende pero emite 3 pitidos largos continuos y la pantalla permanece sin señal de video? ¿Qué pieza está fallando?",
		"faulty": ["RAM"]
	},
	{
		"question": "¿Aparecen líneas verdes y artefactos gráficos en pantalla al ejecutar aplicaciones 3D, tras lo cual se congela el driver de video? ¿Qué pieza está defectuosa?",
		"faulty": ["Grafica"]
	},
	{
		"question": "¿Al arrancar el sistema aparece el error 'Reboot and Select proper Boot device' y no se reconoce el disco de almacenamiento? ¿Qué pieza falló?",
		"faulty": ["Disco Duro"]
	},
	{
		"question": "¿La PC no enciende ningún LED ni giran los ventiladores tras un chispazo y olor a quemado en la toma de corriente trasera? ¿Qué pieza está averiada?",
		"faulty": ["Fuente"]
	},
	{
		"question": "¿La BIOS arroja la alerta 'CPU Fan Error', el disipador no gira y el procesador supera los 95°C apagándose a los 2 minutos? ¿Qué pieza presenta la falla?",
		"faulty": ["Fan Cooler"]
	},
	{
		"question": "¿El equipo sufre congelamientos repentinos con pantalla azul 'CLOCK_WATCHDOG_TIMEOUT' y se observan pines doblados en el socket? ¿Qué pieza está dañada?",
		"faulty": ["CPU"]
	},
	{
		"question": "¿Condensadores hinchados en el circuito VRM, puertos USB traseros sin energía y el chipset no responde al encendido? ¿Qué componente falló?",
		"faulty": ["Placa Madre"]
	}
]

var components: Dictionary = {
	"Fan Cooler": "ok",
	"RAM": "ok",
	"Disco Duro": "ok",
	"Grafica": "ok",
	"Fuente": "ok",
	"Placa Madre": "ok",
	"CPU": "ok"
}

var saved_screw_type: String = ""
var is_completed: bool = false

@onready var label_3d: Label3D = $Label3D
@onready var arrow_mesh: MeshInstance3D = $ArrowMesh
@onready var status_light: OmniLight3D = $StatusLight

var inspection_modal_scene: PackedScene = preload("res://scenes/ui/PCInspectionModal.tscn")
var original_arrow_y: float = 0.0

func _ready() -> void:
	if arrow_mesh:
		original_arrow_y = arrow_mesh.position.y
	if diagnostic_question == "":
		setup_diagnostic_case()
	update_3d_state()

func setup_diagnostic_case(case_idx: int = -1) -> void:
	if case_idx < 0:
		if custom_case_index >= 0:
			case_idx = custom_case_index % DIAGNOSTIC_CASES.size()
		else:
			case_idx = (pc_id - 1) % DIAGNOSTIC_CASES.size()
	var d_case = DIAGNOSTIC_CASES[case_idx]
	diagnostic_question = d_case["question"]
	diagnostic_faulty_parts.assign(d_case["faulty"])
	
	# Solo las piezas asociadas a la pregunta están en "broken", las demás en "ok"
	components = {
		"RAM": "ok",
		"Disco Duro": "ok",
		"Grafica": "ok",
		"Fuente": "ok",
		"Placa Madre": "ok",
		"Fan Cooler": "ok",
		"CPU": "ok"
	}
	for part in diagnostic_faulty_parts:
		components[part] = "broken"

func _process(delta: float) -> void:
	if arrow_mesh and not is_completed:
		var t = Time.get_ticks_msec() / 1000.0
		arrow_mesh.position.y = original_arrow_y + sin(t * 3.0) * 0.08

func is_fully_repaired() -> bool:
	for comp in components.keys():
		if components[comp] == "broken" or components[comp] == "empty":
			return false
	return true

func update_3d_state() -> void:
	if not label_3d:
		return
		
	var empty_count = 0
	var broken_count = 0
	for comp in components.keys():
		if components[comp] == "empty":
			empty_count += 1
		elif components[comp] == "broken":
			broken_count += 1
			
	if is_fully_repaired():
		if not is_completed:
			is_completed = true
			GameManager.computers_fixed += 1
			GameManager.register_repair(150, 15.0)
			GameManager.win_level()
			
		label_3d.text = "PC #%d [FALLA SOLUCIONADA ✓ EQUIPO 100%% OPERATIVO]" % pc_id
		label_3d.modulate = Color(0.0, 1.0, 0.4, 1.0)
		if arrow_mesh:
			arrow_mesh.visible = false
		if status_light:
			status_light.light_color = Color(0.0, 1.0, 0.5, 1.0)
	else:
		if empty_count > 0:
			label_3d.text = "PC #%d [ESPERANDO MONTAJE DE REPUESTO NUEVO]" % pc_id
			label_3d.modulate = Color(1.0, 0.75, 0.1, 1.0)
		else:
			label_3d.text = "PC #%d [DIAGNÓSTICO PENDIENTE · REVISA LA PREGUNTA]" % pc_id
			label_3d.modulate = Color(0.2, 0.8, 1.0, 1.0)
			
		if arrow_mesh:
			arrow_mesh.visible = true
		if status_light:
			status_light.light_color = Color(0.2, 0.8, 1.0, 1.0)

func get_interaction_prompt() -> String:
	if is_completed:
		return "PC #%d: Equipo 100%% reparado y testeado" % pc_id
	return "[E] PC #%d: Diagnosticar falla del cliente" % pc_id

func interact(player) -> void:
	player.set_movement_enabled(false)
	if player.hud_node:
		player.hud_node.visible = false
	var modal = inspection_modal_scene.instantiate()
	get_tree().root.add_child(modal)
	modal.setup_pc(self)
	
	modal.connect("inspection_closed", func():
		if is_fully_repaired():
			player.set_movement_enabled(false)
			if player.hud_node:
				player.hud_node.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			update_3d_state()
		else:
			player.set_movement_enabled(true)
			if player.hud_node:
				player.hud_node.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			update_3d_state()
	)
