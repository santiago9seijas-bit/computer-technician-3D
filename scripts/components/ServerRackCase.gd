extends StaticBody3D

@export var server_id: int = 1

var components: Dictionary = {
	"Placa Madre": "broken",
	"Bancos RAM ECC (3 Módulos)": "broken",
	"Caddies SSD RAID (3 Discos)": "broken",
	"Multi CPU Enterprise (3 Procesadores)": "broken",
	"Fan Wall de Turbinas": "broken",
	"Riser PCIe / Tarjeta Grafica": "broken",
	"Sistemas Andromeda Linux": "broken",
	"Refrigeracion Liquida Custom Loop": "broken"
}

var components_installed_counts: Dictionary = {
	"Placa Madre": 0,
	"Bancos RAM ECC (3 Módulos)": 0,
	"Caddies SSD RAID (3 Discos)": 0,
	"Multi CPU Enterprise (3 Procesadores)": 0,
	"Fan Wall de Turbinas": 0,
	"Riser PCIe / Tarjeta Grafica": 0,
	"Sistemas Andromeda Linux": 0,
	"Refrigeracion Liquida Custom Loop": 0
}

var is_completed: bool = false
var has_player_inspected: bool = false
var current_glow_color: Color = Color(0.0, 0.65, 1.0)
var custom_interact_callback: Callable = Callable()
var custom_prompt: String = ""

@onready var label_3d: Label3D = $Label3D
@onready var arrow_mesh: MeshInstance3D = $ArrowMesh
@onready var status_light: OmniLight3D = get_node_or_null("StatusLight")
var inner_cyan: OmniLight3D = null
var inner_magenta: OmniLight3D = null
var inner_amber: OmniLight3D = null
@onready var cuadro_de_luz: MeshInstance3D = get_node_or_null("CuadroDeLuz")
@onready var torre_model: Node3D = get_node_or_null("TorreServidorModel")

static var _cached_server_modal: PackedScene = null
var server_modal_scene: PackedScene:
	get:
		if not _cached_server_modal:
			_cached_server_modal = load("res://scenes/ui/ServerInspectionModal.tscn")
		return _cached_server_modal
	set(v):
		_cached_server_modal = v
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
		
		var tw = create_tween().set_loops()
		tw.tween_property(arrow_mesh, "position:y", original_arrow_y + 0.08, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(arrow_mesh, "position:y", original_arrow_y - 0.08, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
	if cuadro_de_luz:
		cuadro_de_luz.visible = false
		
	update_3d_state()

func is_hardware_completed() -> bool:
	for comp in ["Placa Madre", "Bancos RAM ECC (3 Módulos)", "Caddies SSD RAID (3 Discos)", "Multi CPU Enterprise (3 Procesadores)", "Fan Wall de Turbinas", "Riser PCIe / Tarjeta Grafica"]:
		if components.get(comp, "broken") == "broken":
			return false
	return true

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

func get_interaction_prompt() -> String:
	if custom_prompt != "":
		return custom_prompt
	if is_completed:
		return "[E] Inspeccionar Torre de Servidor (Datacenter 100% ✓)"
	elif has_player_inspected:
		var fixed_count = 0
		for comp in components.keys():
			if components[comp] == "fixed": fixed_count += 1
		return "[E] Acceder a la Torre de Servidor (Montaje en curso · %d/9)" % fixed_count
	return "[E] Acceder a la Torre de Servidor (Sin revisar)"

func interact(player) -> void:
	if custom_interact_callback.is_valid():
		custom_interact_callback.call(player)
		return

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
