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
var ram_type: String = "ddr4"
var drive_type: String = "m2"
var gpu_type: String = "monocooler"
@export var cpu_brand: String = ""
var is_completed: bool = false
var has_player_inspected: bool = false
var current_glow_color: Color = Color(0.0, 0.65, 1.0)

@onready var label_3d: Label3D = $Label3D
@onready var arrow_mesh: MeshInstance3D = $ArrowMesh
@onready var status_light: OmniLight3D = $StatusLight

var _inspection_modal_scene: PackedScene = null
var inspection_modal_scene: PackedScene:
	get:
		if not _inspection_modal_scene:
			_inspection_modal_scene = load("res://scenes/ui/PCInspectionModal.tscn")
		return _inspection_modal_scene
	set(v):
		_inspection_modal_scene = v

var original_arrow_y: float = 0.0
var arrow_mat: StandardMaterial3D = null

func _ready() -> void:
	set_process(false)
	if arrow_mesh:
		original_arrow_y = arrow_mesh.position.y
		arrow_mat = StandardMaterial3D.new()
		arrow_mat.emission_enabled = true
		arrow_mat.emission_energy_multiplier = 3.0
		arrow_mesh.material_override = arrow_mat
		arrow_mesh.visible = true
		
		# Animación de levitación optimizada mediante Tween cíclico (0% sobrecarga en _process)
		var tw = create_tween().set_loops()
		tw.tween_property(arrow_mesh, "position:y", original_arrow_y + 0.08, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(arrow_mesh, "position:y", original_arrow_y - 0.08, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

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
	if drive_type == "":
		drive_type = "m2" if randf() > 0.5 else "ssd"
	if cpu_brand == "":
		cpu_brand = "amd" if randf() > 0.5 else "intel"

func is_fully_repaired() -> bool:
	if get_meta("is_tutorial_pc", false):
		if not diagnostic_faulty_parts.is_empty():
			for target in diagnostic_faulty_parts:
				var st = components.get(target, "")
				if st != "ok" and st != "fixed":
					return false
			return true
		for target in ["RAM", "Fuente", "Disco Duro"]:
			var st = components.get(target, "")
			if st != "ok" and st != "fixed":
				return false
		return true
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
		current_glow_color = Color(0.1, 1.0, 0.35) # Verde: 100% reparado
		if not is_completed:
			is_completed = true
			GameManager.computers_fixed += 1
			GameManager.register_repair(150, 15.0)
			
			var sm = get_node_or_null("/root/SaveManager")
			if sm:
				if GameManager.computers_fixed >= 1:
					sm.unlock_achievement("first_repair")
				if GameManager.computers_fixed >= 5:
					sm.unlock_achievement("repair_5")
				if GameManager.computers_fixed >= 20:
					sm.unlock_achievement("repair_20")
					
			var cur_sc = get_tree().current_scene
			if cur_sc and cur_sc.has_method("_advance_to_completed"):
				cur_sc._advance_to_completed()
			else:
				GameManager.win_level()
			
		label_3d.text = "PC #%d [FALLA SOLUCIONADA ✓ EQUIPO 100%% OPERATIVO]" % pc_id
		label_3d.modulate = current_glow_color
	elif has_player_inspected or empty_count > 0:
		current_glow_color = Color(1.0, 0.85, 0.05) # Amarillo: ya entró a ver o esperando repuesto
		if empty_count > 0:
			label_3d.text = "PC #%d [ESPERANDO MONTAJE DE REPUESTO NUEVO]" % pc_id
		else:
			label_3d.text = "PC #%d [DIAGNÓSTICO EN CURSO · REVISA LA PREGUNTA]" % pc_id
		label_3d.modulate = current_glow_color
	else:
		current_glow_color = Color(0.0, 0.65, 1.0) # Azul: pendiente de revisión
		label_3d.text = "PC #%d [PENDIENTE DE REVISIÓN]" % pc_id
		label_3d.modulate = current_glow_color
		
	# La flecha SIEMPRE permanece visible en todas las etapas
	if arrow_mesh:
		arrow_mesh.visible = true
		if arrow_mat:
			arrow_mat.albedo_color = current_glow_color
			arrow_mat.emission = current_glow_color
			
	if status_light:
		status_light.light_color = current_glow_color

	var led_node = get_node_or_null("GabineteModel/Led")
	if led_node and led_node is MeshInstance3D:
		var mat = led_node.get_surface_override_material(0)
		if not mat:
			mat = StandardMaterial3D.new()
			mat.emission_enabled = true
			mat.emission_energy_multiplier = 4.0
			led_node.set_surface_override_material(0, mat)
		mat.albedo_color = current_glow_color
		mat.emission = current_glow_color

func can_pickup_with_f() -> bool:
	return visible

func pickup_to_arms(_player: Node) -> Dictionary:
	var data = {
		"type": "reparacion",
		"pc_id": pc_id,
		"is_completed": is_fully_repaired(),
		"components": components.duplicate(true),
		"diagnostic_question": diagnostic_question,
		"diagnostic_faulty_parts": diagnostic_faulty_parts.duplicate()
	}
	visible = false
	collision_layer = 0
	collision_mask = 0
	return data

func restore_from_carried(data: Dictionary) -> void:
	visible = true
	collision_layer = 1
	collision_mask = 1
	if data.has("components"):
		components = data["components"]
	if data.has("is_completed"):
		is_completed = data["is_completed"]
	if data.has("diagnostic_question"):
		diagnostic_question = data["diagnostic_question"]
	if data.has("diagnostic_faulty_parts"):
		diagnostic_faulty_parts = data["diagnostic_faulty_parts"]
	update_3d_state()

func get_interaction_prompt() -> String:
	var action_txt = ""
	if is_completed:
		action_txt = "PC #%d: Equipo 100%% reparado" % pc_id
	elif has_player_inspected:
		action_txt = "[E] PC #%d: Continuar reparación" % pc_id
	else:
		action_txt = "[E] PC #%d: Diagnosticar falla" % pc_id
	return "%s  ·  [F] CARGAR EN BRAZOS" % action_txt

func interact(player) -> void:
	has_player_inspected = true
	update_3d_state()
	
	player.set_movement_enabled(false)
	if player.hud_node:
		if player.hud_node.has_method("hide_gameplay_hud_for_modal"):
			player.hud_node.hide_gameplay_hud_for_modal(true)
		else:
			player.hud_node.visible = false
	var modal = inspection_modal_scene.instantiate()
	get_tree().root.add_child(modal)
	modal.setup_pc(self)
	
	modal.connect("inspection_closed", func():
		update_3d_state()
		if is_fully_repaired():
			player.set_movement_enabled(false)
			if player.hud_node:
				if player.hud_node.has_method("show_gameplay_hud_from_modal"):
					player.hud_node.show_gameplay_hud_from_modal(true)
				else:
					player.hud_node.visible = true
				if player.hud_node.has_method("ensure_hud_visible"):
					player.hud_node.ensure_hud_visible()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			player.set_movement_enabled(true)
			if player.hud_node:
				if player.hud_node.has_method("show_gameplay_hud_from_modal"):
					player.hud_node.show_gameplay_hud_from_modal(true)
				else:
					player.hud_node.visible = true
				if player.hud_node.has_method("ensure_hud_visible"):
					player.hud_node.ensure_hud_visible()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	)
