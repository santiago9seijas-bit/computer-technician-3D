extends StaticBody3D

@export var server_id: int = 1

var components: Dictionary = {
	"Bastidores & Rieles 2U": "broken",
	"Fuentes 1+1 Hot-Swap": "broken",
	"Caddies SAS & RAID (3 Discos)": "broken",
	"Fan Wall de Turbinas": "broken",
	"Loop Líquido Rack": "broken",
	"Bancos RAM ECC (3 Módulos)": "broken",
	"Dual CPU Enterprise": "broken",
	"Riser PCIe / SmartNIC": "broken",
	"Terminal & Scripting": "broken"
}

var is_completed: bool = false
var has_player_inspected: bool = false
var current_glow_color: Color = Color(0.0, 0.65, 1.0)

@onready var label_3d: Label3D = $Label3D
@onready var arrow_mesh: MeshInstance3D = $ArrowMesh
@onready var status_light: OmniLight3D = $StatusLight
@onready var inner_cyan: OmniLight3D = get_node_or_null("InteriorLights/InnerLightCyan")
@onready var inner_magenta: OmniLight3D = get_node_or_null("InteriorLights/InnerLightMagenta")
@onready var inner_amber: OmniLight3D = get_node_or_null("InteriorLights/InnerLightAmber")
@onready var cuadro_de_luz: MeshInstance3D = get_node_or_null("CuadroDeLuz")
@onready var torre_model: Node3D = get_node_or_null("TorreServidorModel")

var server_modal_scene: PackedScene = preload("res://scenes/ui/ServerInspectionModal.tscn")
var original_arrow_y: float = 0.0

var light_box_mat: StandardMaterial3D = null
var arrow_mat: StandardMaterial3D = null

func _ready() -> void:
	if arrow_mesh:
		original_arrow_y = arrow_mesh.position.y
		arrow_mat = StandardMaterial3D.new()
		arrow_mat.emission_enabled = true
		arrow_mat.emission_energy_multiplier = 3.0
		arrow_mesh.material_override = arrow_mat
		arrow_mesh.visible = true
		
	if cuadro_de_luz:
		light_box_mat = StandardMaterial3D.new()
		light_box_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		light_box_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		light_box_mat.albedo_color = Color(current_glow_color.r, current_glow_color.g, current_glow_color.b, 0.72)
		light_box_mat.emission_enabled = true
		light_box_mat.emission = current_glow_color
		light_box_mat.emission_energy_multiplier = 3.5
		cuadro_de_luz.material_override = light_box_mat
		
	update_3d_state()

func _process(_delta: float) -> void:
	var t = Time.get_ticks_msec() / 1000.0
	if arrow_mesh:
		arrow_mesh.position.y = original_arrow_y + sin(t * 3.0) * 0.08
		
	# Pulsación suave del cuadro de luz interior y luces del rack
	var pulse = 0.88 + sin(t * 2.8) * 0.12
	if light_box_mat:
		light_box_mat.emission_energy_multiplier = 3.5 * pulse
		
	var base_energy = 1.6 if is_completed else 1.3
	if inner_cyan:
		inner_cyan.light_energy = (base_energy + sin(t * 2.5) * 0.3) * pulse
	if inner_magenta:
		inner_magenta.light_energy = (base_energy + cos(t * 2.2) * 0.3) * pulse
	if inner_amber:
		inner_amber.light_energy = (base_energy + sin(t * 2.8 + 1.0) * 0.3) * pulse
	if status_light:
		status_light.light_energy = 1.3 * pulse

func is_fully_repaired() -> bool:
	for comp in components.keys():
		if components[comp] == "broken":
			return false
	return true

func update_3d_state() -> void:
	if not label_3d:
		return
		
	var fixed_count = 0
	for comp in components.keys():
		if components[comp] == "fixed":
			fixed_count += 1
			
	# Determinar color según el estado del servidor:
	# 1. AZUL: si no ha sido modificado o el jugador no ha entrado a revisar
	# 2. AMARILLO: si ya entró a ver o está armando componentes
	# 3. VERDE: cuando ya todo se armó (100% completado)
	if is_fully_repaired():
		is_completed = true
		current_glow_color = Color(0.1, 1.0, 0.35) # Verde brillante
		label_3d.text = "[ TORRE DE SERVIDOR 100% OPERATIVA ✓ ]"
		label_3d.modulate = current_glow_color
		GameManager.complete_level()
	elif has_player_inspected or fixed_count > 0:
		is_completed = false
		current_glow_color = Color(1.0, 0.85, 0.05) # Amarillo cálido
		label_3d.text = "TORRE DE SERVIDOR #%d · EN MONTAJE (%d/9)" % [server_id, fixed_count]
		label_3d.modulate = current_glow_color
	else:
		is_completed = false
		current_glow_color = Color(0.0, 0.65, 1.0) # Azul técnico
		label_3d.text = "TORRE DE SERVIDOR #%d · [ SIN REVISAR ]" % [server_id]
		label_3d.modulate = current_glow_color
		
	# La flecha SIEMPRE permanece visible como indicador
	if arrow_mesh:
		arrow_mesh.visible = true
		if arrow_mat:
			arrow_mat.albedo_color = current_glow_color
			arrow_mat.emission = current_glow_color
			
	# Actualizar color del cuadro de luz interior
	if light_box_mat:
		light_box_mat.albedo_color = Color(current_glow_color.r, current_glow_color.g, current_glow_color.b, 0.72)
		light_box_mat.emission = current_glow_color
			
	# Aplicar el color a todas las luces interiores y exteriores
	if inner_cyan:
		inner_cyan.light_color = current_glow_color
	if inner_magenta:
		inner_magenta.light_color = current_glow_color
	if inner_amber:
		inner_amber.light_color = current_glow_color
	if status_light:
		status_light.light_color = current_glow_color

func get_interaction_prompt() -> String:
	if is_completed:
		return "[E] Inspeccionar Torre de Servidor (Datacenter 100% ✓)"
	elif has_player_inspected:
		var fixed_count = 0
		for comp in components.keys():
			if components[comp] == "fixed": fixed_count += 1
		return "[E] Acceder a la Torre de Servidor (Montaje en curso · %d/9)" % fixed_count
	return "[E] Acceder a la Torre de Servidor (Sin revisar)"

func interact(player) -> void:
	if get_tree().root.has_node("ServerInspectionModal"):
		return
		
	has_player_inspected = true
	update_3d_state()
		
	var modal = server_modal_scene.instantiate()
	get_tree().root.add_child(modal)
	modal.setup_server(self)
	
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	modal.inspection_closed.connect(func():
		update_3d_state()
		if is_completed:
			if player and player.has_method("set_movement_enabled"):
				player.set_movement_enabled(false)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			if player and player.has_method("set_movement_enabled"):
				player.set_movement_enabled(true)
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	)
