extends Node3D
class_name FirstPersonTools

## =============================================================================
## SISTEMA DE HERRAMIENTAS EN PRIMERA PERSONA (FPS VIEWMODEL)
## Permite cambiar y sostener en mano las 5 herramientas 3D con teclas [1] a [5]:
##   [1] Destornillador de Pala (Mango Rojo, punta plana)
##   [2] Destornillador de Estrella (Mango Azul, punta en cruz)
##   [3] Voltímetro Digital (Carcasa Amarilla, pantalla LCD y sondas)
##   [4] Lupa de Precisión (Marco de acero, mango de madera y lente de cristal)
##   [5] Aspiradora Portátil (Boquilla de cepillo, chasis oscuro y luz LED)
##   [0] Guardar / Ocultar herramienta (Holster)
## =============================================================================

@export var sway_amount: float = 0.025
@export var sway_smooth: float = 12.0
@export var bob_amount_walk: float = 0.012
@export var bob_amount_sprint: float = 0.022
@export var bob_speed_walk: float = 9.0
@export var bob_speed_sprint: float = 14.0

var current_tool_id: int = 0
var target_tool_id: int = 0
var is_switching: bool = false
var _switch_tween: Tween = null

# Nodos contenedores de cada herramienta
var tool_nodes: Dictionary = {}
var tool_configs: Dictionary = TOOL_DATA.duplicate(true)

# Offsets para oscilación de movimiento y sway
var _sway_offset: Vector3 = Vector3.ZERO
var _mouse_delta: Vector2 = Vector2.ZERO
var _bob_timer: float = 0.0
var _is_hidden_by_cabinet: bool = false

# Referencia al jugador
var player_ref: CharacterBody3D = null

const TOOL_DATA: Dictionary = {
	1: {
		"name": "Destornillador de Pala",
		"paths": [
			"res://herramientas modelos/destornillador_pala.glb",
			"res://modelos de herramientas/destornillador_pala.glb"
		],
		"pos": Vector3(0.24, -0.19, -0.42),
		"rot": Vector3(12.0, -78.0, -18.0),
		"scale": Vector3(0.09, 0.09, 0.09),
		"hide_offset_y": -0.35
	},
	2: {
		"name": "Destornillador de Estrella",
		"paths": [
			"res://herramientas modelos/destornillador_estrella.glb",
			"res://modelos de herramientas/destornillador_estrella.glb"
		],
		"pos": Vector3(0.24, -0.19, -0.42),
		"rot": Vector3(12.0, -78.0, -18.0),
		"scale": Vector3(0.09, 0.09, 0.09),
		"hide_offset_y": -0.35
	},
	3: {
		"name": "Voltímetro Digital",
		"paths": [
			"res://herramientas modelos/voltimetro.glb",
			"res://modelos de herramientas/voltimetro.glb"
		],
		"pos": Vector3(0.22, -0.17, -0.38),
		"rot": Vector3(-48.0, -90.0, 12.0),
		"scale": Vector3(0.075, 0.075, 0.075),
		"hide_offset_y": -0.32
	},
	4: {
		"name": "Lupa de Precisión",
		"paths": [
			"res://herramientas modelos/lupa.glb",
			"res://modelos de herramientas/lupa.glb"
		],
		"pos": Vector3(0.20, -0.09, -0.36),
		"rot": Vector3(12.0, -78.0, -18.0),
		"scale": Vector3(0.085, 0.085, 0.085),
		"hide_offset_y": -0.32
	},
	5: {
		"name": "Aspiradora Portátil",
		"paths": [
			"res://herramientas modelos/aspiradora.glb",
			"res://modelos de herramientas/aspiradora.glb"
		],
		"pos": Vector3(0.22, -0.16, -0.42),
		"rot": Vector3(15.0, -95.0, -12.0),
		"scale": Vector3(0.013, 0.013, 0.013),
		"hide_offset_y": -0.38
	}
}

func _ready() -> void:
	# Encontrar nodo Player
	player_ref = get_parent() as CharacterBody3D
	if not player_ref:
		player_ref = owner as CharacterBody3D
	if not player_ref:
		var p = get_parent()
		while p and not (p is CharacterBody3D):
			p = p.get_parent()
		player_ref = p as CharacterBody3D

	_build_tools()
	_setup_viewmodel_light()

	# Conectar con GameManager
	if is_inside_tree():
		var gm = get_tree().root.get_node_or_null("GameManager")
		if gm and gm.has_signal("tool_selected"):
			gm.tool_selected.connect(_on_game_manager_tool_selected)
			# Inicializar según herramienta equipada
			if "equipped_tool" in gm and gm.equipped_tool > 0:
				equip_tool(gm.equipped_tool, true)

func _build_tools() -> void:
	for tool_id in TOOL_DATA.keys():
		var data: Dictionary = TOOL_DATA[tool_id]
		var scene_res: PackedScene = null
		for p in data["paths"]:
			if ResourceLoader.exists(p):
				scene_res = load(p) as PackedScene
				if scene_res:
					break

		if not scene_res:
			push_warning("FirstPersonTools: No se pudo cargar el modelo para herramienta %d (%s)" % [tool_id, data["name"]])
			continue

		# Instanciar el nodo pivote de la herramienta
		var pivot = Node3D.new()
		pivot.name = "ToolPivot_%d" % tool_id
		add_child(pivot)

		var model_inst = scene_res.instantiate()
		model_inst.name = "Model_%d" % tool_id
		pivot.add_child(model_inst)

		# Aplicar transformaciones base
		pivot.position = data["pos"]
		pivot.rotation_degrees = data["rot"]
		pivot.scale = data["scale"]
		pivot.visible = false

		_enhance_tool_materials(tool_id, model_inst)

		tool_nodes[tool_id] = pivot
		tool_configs[tool_id] = data

func _enhance_tool_materials(tool_id: int, model: Node) -> void:
	for child in model.find_children("*", "MeshInstance3D", true, false):
		var mi = child as MeshInstance3D
		if not mi or not mi.mesh:
			continue
		
		# Desactivar sombras y GI en viewmodel para rendimiento máximo de GPU y evitar auto-oclusión
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED

		# Mejoras de material por herramienta
		if tool_id == 4 and child.name == "Lente":
			# Lente de cristal transparente realista para la lupa
			for s in range(mi.mesh.get_surface_count()):
				var mat = mi.mesh.surface_get_material(s)
				if mat is StandardMaterial3D:
					var g_mat = mat.duplicate() as StandardMaterial3D
					g_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					g_mat.albedo_color = Color(0.85, 0.95, 1.0, 0.35)
					g_mat.roughness = 0.04
					g_mat.metallic = 0.1
					mi.set_surface_override_material(s, g_mat)

		elif tool_id == 3 and child.name == "Pantalla":
			# Pantalla LCD del multímetro con leve retroiluminación digital
			for s in range(mi.mesh.get_surface_count()):
				var mat = mi.mesh.surface_get_material(s)
				if mat is StandardMaterial3D:
					var lcd_mat = mat.duplicate() as StandardMaterial3D
					lcd_mat.emission_enabled = true
					lcd_mat.emission = Color(0.45, 0.75, 0.52)
					lcd_mat.emission_energy_multiplier = 0.4
					mi.set_surface_override_material(s, lcd_mat)

		elif tool_id == 5 and child.name == "Asp_LED":
			# LED de estado de la aspiradora con brillo visible
			for s in range(mi.mesh.get_surface_count()):
				var mat = mi.mesh.surface_get_material(s)
				if mat is StandardMaterial3D:
					var led_mat = mat.duplicate() as StandardMaterial3D
					led_mat.emission_enabled = true
					led_mat.emission = Color(0.2, 0.5, 1.0)
					led_mat.emission_energy_multiplier = 1.6
					mi.set_surface_override_material(s, led_mat)

func _setup_viewmodel_light() -> void:
	# Luz suave local para mantener colores vivos y detalles visibles en cualquier rincón oscuro
	var fill_light = OmniLight3D.new()
	fill_light.name = "ViewmodelFillLight"
	fill_light.position = Vector3(0.18, 0.05, -0.28)
	fill_light.omni_range = 1.2
	fill_light.light_energy = 0.45
	fill_light.shadow_enabled = false
	fill_light.light_color = Color(0.96, 0.98, 1.0)
	add_child(fill_light)

func _input(event: InputEvent) -> void:
	if current_tool_id == 0 or _is_hidden_by_cabinet:
		return
	# Capturar movimiento de ratón para inercia / sway
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_delta.x += event.relative.x * sway_amount * 0.001
		_mouse_delta.y += event.relative.y * sway_amount * 0.001

func _process(delta: float) -> void:
	if current_tool_id == 0 and not is_switching and not _is_hidden_by_cabinet:
		return
	# Sway elástico volviendo a cero
	_sway_offset.x = lerp(_sway_offset.x, -_mouse_delta.x, clamp(delta * sway_smooth, 0.0, 1.0))
	_sway_offset.y = lerp(_sway_offset.y, _mouse_delta.y, clamp(delta * sway_smooth, 0.0, 1.0))
	_mouse_delta = lerp(_mouse_delta, Vector2.ZERO, clamp(delta * 10.0, 0.0, 1.0))

	# Comprobar si el jugador está cargando gabinete en brazos
	var is_carrying = false
	if is_instance_valid(player_ref) and "is_carrying_cabinet" in player_ref:
		is_carrying = player_ref.is_carrying_cabinet

	if is_carrying != _is_hidden_by_cabinet:
		_is_hidden_by_cabinet = is_carrying
		if _is_hidden_by_cabinet:
			_hide_all_immediate()
		elif current_tool_id > 0:
			equip_tool(current_tool_id, true)

	if _is_hidden_by_cabinet:
		return

	# Animación sutil de caminar / correr (bobbing)
	var is_moving = false
	var is_sprinting = false
	if is_instance_valid(player_ref):
		var vel_h = Vector2(player_ref.velocity.x, player_ref.velocity.z).length()
		is_moving = vel_h > 0.4 and player_ref.is_on_floor()
		is_sprinting = vel_h > 5.2

	var cur_pivot: Node3D = tool_nodes.get(current_tool_id)
	if cur_pivot and cur_pivot.visible and not is_switching:
		var cfg: Dictionary = tool_configs.get(current_tool_id, {})
		var base_pos: Vector3 = cfg.get("pos", Vector3.ZERO)
		var base_rot: Vector3 = cfg.get("rot", Vector3.ZERO)

		if is_moving:
			var b_speed = bob_speed_sprint if is_sprinting else bob_speed_walk
			var b_amt = bob_amount_sprint if is_sprinting else bob_amount_walk
			_bob_timer += delta * b_speed
			var bob_y = sin(_bob_timer) * b_amt
			var bob_x = cos(_bob_timer * 0.5) * (b_amt * 0.7)
			cur_pivot.position = base_pos + Vector3(bob_x + _sway_offset.x, bob_y + _sway_offset.y, 0)
			cur_pivot.rotation_degrees = base_rot + Vector3(-_sway_offset.y * 35.0, _sway_offset.x * 45.0, -bob_x * 40.0)
		else:
			# Respiración idle sutil
			var t = Time.get_ticks_msec() * 0.001
			var idle_y = sin(t * 2.2) * 0.002
			cur_pivot.position = base_pos + Vector3(_sway_offset.x, idle_y + _sway_offset.y, 0)
			cur_pivot.rotation_degrees = base_rot + Vector3(-_sway_offset.y * 35.0, _sway_offset.x * 45.0, 0)

func equip_tool(tool_id: int, instant: bool = false) -> void:
	if tool_nodes.is_empty():
		_build_tools()

	if _is_hidden_by_cabinet:
		current_tool_id = tool_id
		return

	if tool_id == current_tool_id and not instant:
		return

	if _switch_tween and _switch_tween.is_valid():
		_switch_tween.kill()

	target_tool_id = tool_id
	var old_pivot: Node3D = tool_nodes.get(current_tool_id)
	var new_pivot: Node3D = tool_nodes.get(target_tool_id)

	if instant:
		_hide_all_immediate()
		current_tool_id = target_tool_id
		if new_pivot:
			var cfg = tool_configs.get(target_tool_id, {})
			new_pivot.position = cfg.get("pos", Vector3.ZERO)
			new_pivot.rotation_degrees = cfg.get("rot", Vector3.ZERO)
			new_pivot.visible = true
		return

	is_switching = true
	_switch_tween = create_tween()

	# Bajar herramienta anterior
	if old_pivot and old_pivot.visible:
		var old_cfg = tool_configs.get(current_tool_id, {})
		var down_pos = old_cfg.get("pos", Vector3.ZERO) + Vector3(0, old_cfg.get("hide_offset_y", -0.3), 0)
		_switch_tween.tween_property(old_pivot, "position", down_pos, 0.10)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_switch_tween.tween_callback(func(): old_pivot.visible = false)

	# Subir nueva herramienta
	if new_pivot:
		var new_cfg = tool_configs.get(target_tool_id, {})
		var target_pos: Vector3 = new_cfg.get("pos", Vector3.ZERO)
		var start_pos: Vector3 = target_pos + Vector3(0, new_cfg.get("hide_offset_y", -0.3), 0)

		_switch_tween.tween_callback(func():
			new_pivot.position = start_pos
			new_pivot.rotation_degrees = new_cfg.get("rot", Vector3.ZERO)
			new_pivot.visible = true
			current_tool_id = target_tool_id
		)
		_switch_tween.tween_property(new_pivot, "position", target_pos, 0.14)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_switch_tween.tween_callback(func(): current_tool_id = 0)

	_switch_tween.tween_callback(func(): is_switching = false)

func holster_tool(instant: bool = false) -> void:
	equip_tool(0, instant)

func toggle_tool(tool_id: int) -> void:
	var gm = get_tree().root.get_node_or_null("GameManager") if is_inside_tree() else null
	if current_tool_id == tool_id:
		# Si ya está equipada, guardarla
		if gm and gm.has_method("select_tool"):
			gm.select_tool(0)
		else:
			holster_tool()
	else:
		# Equipar nueva herramienta
		if gm and gm.has_method("select_tool"):
			gm.select_tool(tool_id)
		else:
			equip_tool(tool_id)

func _hide_all_immediate() -> void:
	for node in tool_nodes.values():
		if node:
			node.visible = false

func _on_game_manager_tool_selected(tool_id: int) -> void:
	if tool_id in tool_nodes or tool_id == 0:
		equip_tool(tool_id)
