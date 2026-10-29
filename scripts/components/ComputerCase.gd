extends StaticBody3D

@export var pc_id: int = 1

# Componente que tiene la falla real en esta PC ("RAM" o "Disco Duro")
var target_fault_component: String = "RAM"
var symptom_report: String = ""

var components: Dictionary = {
	"RAM": "broken",
	"Disco Duro": "ok"
}

var saved_screw_type: String = ""
var is_completed: bool = false

@onready var label_3d: Label3D = $Label3D
@onready var arrow_mesh: MeshInstance3D = $ArrowMesh
@onready var status_light: OmniLight3D = $StatusLight
@onready var case_mesh: MeshInstance3D = $CaseMesh

var inspection_modal_scene: PackedScene = preload("res://scenes/ui/PCInspectionModal.tscn")
var original_arrow_y: float = 0.0

var ram_symptoms = [
	"El cliente reporta: 'La PC enciende los ventiladores pero no da video y emite 3 pitidos cortos intermitentes. Se reinicia en bucle.'",
	"El cliente reporta: 'Al abrir programas pesados o juegos, la máquina sufre pantallazos azules continuos con error MEMORY_MANAGEMENT.'",
	"El cliente reporta: 'Windows se congela en el logo de carga y el test de arranque indica fallo de paridad en los buses de datos.'"
]

var hdd_symptoms = [
	"El cliente reporta: 'Al encender aparece pantalla negra con el mensaje: 'No bootable device found'. La BIOS no detecta ninguna unidad de almacenamiento.'",
	"El cliente reporta: 'Windows no termina de cargar y tira pantallazo azul con código UNMOUNTABLE_BOOT_VOLUME. El equipo no halla el sistema.'",
	"El cliente reporta: 'La máquina se queda congelada al 100% de uso de disco y arroja error de redundancia cíclica (CRC) al leer archivos.'"
]

var cooler_symptoms = [
	"El cliente reporta: 'La PC se apaga sola a los 2 minutos de encender. Se escucha un zumbido seco y la CPU alcanza los 100°C por sobrecalentamiento crítico.'",
	"El cliente reporta: 'El ventilador del disipador no gira, las aspas están trabadas y la BIOS alerta: 'CPU Fan Speed Error Detect. Shutdown in 15s'.'",
	"El cliente reporta: 'La computadora va a tirones extremos. Al monitorizar la placa, el procesador hace Thermal Throttling severo.'"
]

var gpu_symptoms = [
	"El cliente reporta: 'La pantalla muestra rayas de colores, artefactos visuales y el controlador de video crashea continuamente al abrir gráficos 3D.'",
	"El cliente reporta: 'No hay señal de video por los puertos HDMI ni DisplayPort de la GPU dedicada. Solo arranca por video integrado.'",
	"El cliente reporta: 'Los ventiladores de la placa de video giran al 100% ruidosamente pero no da imagen y la BIOS pita 1 largo y 2 cortos.'"
]

var psu_symptoms = [
	"El cliente reporta: 'La máquina se apaga instantáneamente al iniciar una prueba de carga y huele a plástico caliente en la parte trasera.'",
	"El cliente reporta: 'No enciende ningún LED ni ventilador. La fuente emite un 'clic' seco cada 3 segundos por disparo de la protección contra corto (SCP).'",
	"El cliente reporta: 'El equipo se reinicia aleatoriamente cuando la demanda eléctrica aumenta. Las líneas de 12V caen a 10.4V.'"
]

var mobo_symptoms = [
	"El cliente reporta: 'La placa madre no pasa el POST, el LED de diagnóstico 'CPU/DRAM' queda fijo y varios puertos USB traseros no entregan 5V.'",
	"El cliente reporta: 'Hubo una sobretensión eléctrica y la máquina no responde al botón frontal a pesar de que la fuente está viva.'",
	"El cliente reporta: 'El chipset principal hierve al tacto y el bus PCIe no reconoce ningún dispositivo secundario.'"
]

func _ready() -> void:
	if arrow_mesh:
		original_arrow_y = arrow_mesh.position.y
		
	# Elegir falla y síntoma técnico entre cualquiera de los 6 componentes
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var possible_components = ["Fan Cooler", "RAM", "Disco Duro", "Grafica", "Fuente", "Placa Madre"]
	target_fault_component = possible_components[rng.randi_range(0, possible_components.size() - 1)]
	
	match target_fault_component:
		"Fan Cooler":
			symptom_report = cooler_symptoms[rng.randi_range(0, cooler_symptoms.size() - 1)]
		"RAM":
			symptom_report = ram_symptoms[rng.randi_range(0, ram_symptoms.size() - 1)]
		"Disco Duro":
			symptom_report = hdd_symptoms[rng.randi_range(0, hdd_symptoms.size() - 1)]
		"Grafica":
			symptom_report = gpu_symptoms[rng.randi_range(0, gpu_symptoms.size() - 1)]
		"Fuente":
			symptom_report = psu_symptoms[rng.randi_range(0, psu_symptoms.size() - 1)]
		"Placa Madre":
			symptom_report = mobo_symptoms[rng.randi_range(0, mobo_symptoms.size() - 1)]
			
	components = {
		"Fan Cooler": "broken" if target_fault_component == "Fan Cooler" else "ok",
		"RAM": "broken" if target_fault_component == "RAM" else "ok",
		"Disco Duro": "broken" if target_fault_component == "Disco Duro" else "ok",
		"Grafica": "broken" if target_fault_component == "Grafica" else "ok",
		"Fuente": "broken" if target_fault_component == "Fuente" else "ok",
		"Placa Madre": "broken" if target_fault_component == "Placa Madre" else "ok"
	}
		
	update_3d_state()

func _process(delta: float) -> void:
	if arrow_mesh and not is_completed:
		var t = Time.get_ticks_msec() / 1000.0
		arrow_mesh.position.y = original_arrow_y + sin(t * 3.0) * 0.08

func is_fully_repaired() -> bool:
	return components.get(target_fault_component) == "fixed"

func update_3d_state() -> void:
	if not label_3d:
		return
		
	if is_fully_repaired():
		if not is_completed:
			is_completed = true
			GameManager.computers_fixed += 1
			GameManager.register_repair(150, 15.0)
			
		label_3d.text = "PC #%d [REPARADA Y OPERATIVA ✓]" % pc_id
		label_3d.modulate = Color(0.0, 1.0, 0.4, 1.0)
		if arrow_mesh:
			arrow_mesh.visible = false
		if status_light:
			status_light.light_color = Color(0.0, 1.0, 0.5, 1.0)
	else:
		var state_comp = components.get(target_fault_component)
		if state_comp == "empty":
			label_3d.text = "PC #%d [ESPERANDO REPUESTO: %s]" % [pc_id, target_fault_component]
			label_3d.modulate = Color(1.0, 0.75, 0.1, 1.0)
		else:
			label_3d.text = "PC #%d [REPORTE DE FALLA PENDIENTE]" % pc_id
			label_3d.modulate = Color(1.0, 0.2, 0.45, 1.0)
			
		if arrow_mesh:
			arrow_mesh.visible = true
		if status_light:
			status_light.light_color = Color(1.0, 0.1, 0.4, 1.0)

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
		player.set_movement_enabled(true)
		if player.hud_node:
			player.hud_node.visible = true
		update_3d_state()
	)
