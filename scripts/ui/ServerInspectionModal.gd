extends CanvasLayer

signal inspection_closed()

var current_server = null

# Preloads de los minijuegos de ensamble de servidor y CLI de Andromeda
var mobo_minigame_scene: PackedScene = preload("res://scenes/minigames/MotherboardMinigame.tscn")
var ram_minigame_scene: PackedScene = preload("res://scenes/minigames/RAMMinigame.tscn")
var hdd_minigame_scene: PackedScene = preload("res://scenes/minigames/HDDMinigame.tscn")
var cpu_minigame_scene: PackedScene = preload("res://scenes/minigames/CPUMinigame.tscn")
var cooler_minigame_scene: PackedScene = preload("res://scenes/minigames/FanCoolerMinigame.tscn")
var gpu_minigame_scene: PackedScene = preload("res://scenes/minigames/GPUMinigame.tscn")
var andromeda_cli_scene: PackedScene = preload("res://scenes/minigames/AndromedaCliMinigame.tscn")
var liquid_minigame_scene: PackedScene = preload("res://scenes/minigames/LiquidCoolingMinigame.tscn")

@onready var modal_control: Control = $ModalControl
@onready var bg_frame: NinePatchRect = $ModalControl/Panel/CyberBackgroundFrame
@onready var title_label: Label = $ModalControl/Panel/VBox/Header/TitleLabel
@onready var status_summary: Label = $ModalControl/Panel/VBox/Header/StatusSummary
@onready var badge_label: Label = $ModalControl/Panel/VBox/Header/BadgeLabel
@onready var divider: ColorRect = $ModalControl/Panel/VBox/Divider

# Cuadro Azul de Refrigeración Líquida
@onready var cuadro_azul: PanelContainer = get_node_or_null("ModalControl/CuadroAzulRefrigeracion")
@onready var btn_acoplar_liquid: Button = get_node_or_null("ModalControl/CuadroAzulRefrigeracion/Margin/VBox/BtnAcoplarLiquid")
@onready var desc_liquid: Label = get_node_or_null("ModalControl/CuadroAzulRefrigeracion/Margin/VBox/DescLabel")

# Pestañas
@onready var btn_tab_hardware: Button = $ModalControl/Panel/VBox/TabsHBox/BtnTabHardware
@onready var btn_tab_systems: Button = $ModalControl/Panel/VBox/TabsHBox/BtnTabSystems
@onready var hardware_container: VBoxContainer = $ModalControl/Panel/VBox/HardwareContainer
@onready var systems_container: VBoxContainer = $ModalControl/Panel/VBox/SystemsContainer

# Tier 1 (Red / Riser GPU)
@onready var card_gpu: PanelContainer = $ModalControl/Panel/VBox/HardwareContainer/Tier1_HBox/CardGPU
@onready var btn_gpu: Button = $ModalControl/Panel/VBox/HardwareContainer/Tier1_HBox/CardGPU/Margin/HBox/BtnGPU

# Tier 2 (Cómputo / CPU, RAM, Fan Wall)
@onready var card_cpu: PanelContainer = $ModalControl/Panel/VBox/HardwareContainer/Tier2_HBox/CardCPU
@onready var btn_cpu: Button = $ModalControl/Panel/VBox/HardwareContainer/Tier2_HBox/CardCPU/Margin/VBox/BtnCPU

@onready var card_ram: PanelContainer = $ModalControl/Panel/VBox/HardwareContainer/Tier2_HBox/CardRAM
@onready var btn_ram: Button = $ModalControl/Panel/VBox/HardwareContainer/Tier2_HBox/CardRAM/Margin/VBox/BtnRAM

@onready var card_cooler: PanelContainer = $ModalControl/Panel/VBox/HardwareContainer/Tier2_HBox/CardCooler
@onready var btn_cooler: Button = $ModalControl/Panel/VBox/HardwareContainer/Tier2_HBox/CardCooler/Margin/VBox/BtnCooler

# Tier 3 (Almacenamiento / SSD RAID y Base Placa Madre)
@onready var card_ssd: PanelContainer = $ModalControl/Panel/VBox/HardwareContainer/Tier3_HBox/CardSSD
@onready var btn_ssd: Button = $ModalControl/Panel/VBox/HardwareContainer/Tier3_HBox/CardSSD/Margin/HBox/BtnSSD

@onready var card_mobo: PanelContainer = $ModalControl/Panel/VBox/HardwareContainer/Tier3_HBox/CardMobo
@onready var btn_mobo: Button = $ModalControl/Panel/VBox/HardwareContainer/Tier3_HBox/CardMobo/Margin/HBox/BtnMobo

# Mochila técnica
@onready var slot_0: Button = $ModalControl/Panel/VBox/HardwareContainer/BackpackSection/BackpackSlots/Slot0
@onready var slot_1: Button = $ModalControl/Panel/VBox/HardwareContainer/BackpackSection/BackpackSlots/Slot1
@onready var slot_2: Button = $ModalControl/Panel/VBox/HardwareContainer/BackpackSection/BackpackSlots/Slot2

# Pestaña de Sistemas (Locked / Unlocked)
@onready var locked_panel: PanelContainer = $ModalControl/Panel/VBox/SystemsContainer/LockedPanel
@onready var lock_desc: Label = $ModalControl/Panel/VBox/SystemsContainer/LockedPanel/Margin/VBox/LockDesc
@onready var btn_go_hardware: Button = $ModalControl/Panel/VBox/SystemsContainer/LockedPanel/Margin/VBox/BtnGoHardware

@onready var unlocked_panel: PanelContainer = $ModalControl/Panel/VBox/SystemsContainer/UnlockedPanel
@onready var btn_launch_cli: Button = $ModalControl/Panel/VBox/SystemsContainer/UnlockedPanel/Margin/VBox/BtnLaunchCli

@onready var feedback_label: Label = $ModalControl/Panel/VBox/FeedbackLabel
@onready var btn_volver: Button = $ModalControl/Panel/VBox/Footer/BtnVolver

var active_tab: int = 0 # 0 = Hardware, 1 = Sistemas
var current_minigame_instance: Node = null
var active_repair_component: String = ""

# Componentes de hardware
const HARDWARE_COMPONENTS = [
	{
		"key": "Placa Madre",
		"item_name": "Placa Madre",
		"btn_node": "btn_mobo",
		"card_node": "card_mobo",
		"title": "🗄️ [U1] PLACA MADRE // TRAY Y RIELES",
		"scene": "mobo_minigame_scene",
		"is_base": true
	},
	{
		"key": "Bancos RAM ECC (3 Módulos)",
		"item_name": "RAM",
		"btn_node": "btn_ram",
		"card_node": "card_ram",
		"title": "🧠 [U2] BANCOS RAM ECC (3x)",
		"scene": "ram_minigame_scene",
		"target_count": 3
	},
	{
		"key": "Caddies SSD RAID (3 Discos)",
		"item_name": "Disco Duro",
		"btn_node": "btn_ssd",
		"card_node": "card_ssd",
		"title": "💾 [U3] CADDIES SSD RAID (3x)",
		"scene": "hdd_minigame_scene",
		"target_count": 3
	},
	{
		"key": "Multi CPU Enterprise (3 Procesadores)",
		"item_name": "CPU",
		"btn_node": "btn_cpu",
		"card_node": "card_cpu",
		"title": "⚙️ [U4] MULTI CPU ENTERPRISE (3x)",
		"scene": "cpu_minigame_scene",
		"target_count": 3
	},
	{
		"key": "Fan Wall de Turbinas",
		"item_name": "Fan Cooler",
		"btn_node": "btn_cooler",
		"card_node": "card_cooler",
		"title": "💨 [U5] FAN WALL DE TURBINAS (3x)",
		"scene": "cooler_minigame_scene",
		"target_count": 3
	},
	{
		"key": "Riser PCIe / Tarjeta Grafica",
		"item_name": "Grafica",
		"btn_node": "btn_gpu",
		"card_node": "card_gpu",
		"title": "🌐 [U6] RISER PCIE / ACELERADORES GPU (3x)",
		"scene": "gpu_minigame_scene",
		"target_count": 3
	}
]

func _ready() -> void:
	layer = 10
	btn_volver.pressed.connect(_on_volver_pressed)
	btn_tab_hardware.pressed.connect(func(): _switch_tab(0))
	btn_tab_systems.pressed.connect(func(): _switch_tab(1))
	btn_go_hardware.pressed.connect(func(): _switch_tab(0))
	
	btn_mobo.pressed.connect(func(): _on_component_clicked(0))
	btn_ram.pressed.connect(func(): _on_component_clicked(1))
	btn_ssd.pressed.connect(func(): _on_component_clicked(2))
	btn_cpu.pressed.connect(func(): _on_component_clicked(3))
	btn_cooler.pressed.connect(func(): _on_component_clicked(4))
	btn_gpu.pressed.connect(func(): _on_component_clicked(5))
	
	btn_launch_cli.pressed.connect(_launch_andromeda_cli)
	
	if btn_acoplar_liquid:
		btn_acoplar_liquid.pressed.connect(_launch_liquid_cooling)
		
	# Clic o arrastre en los slots de la mochila
	var backpack_slot_nodes = [slot_0, slot_1, slot_2]
	for idx in range(backpack_slot_nodes.size()):
		var slot_btn = backpack_slot_nodes[idx]
		if is_instance_valid(slot_btn):
			slot_btn.pressed.connect(func(): _on_backpack_slot_pressed(idx))
	
	GameManager.backpack_updated.connect(func(_b): _refresh_ui())
	
	_switch_tab(0)
	if current_server != null:
		_refresh_ui()

func _unhandled_input(event: InputEvent) -> void:
	if not modal_control or not modal_control.visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		_on_volver_pressed()

func setup_server(server_ref) -> void:
	current_server = server_ref
	if is_inside_tree():
		_refresh_ui()

func _switch_tab(tab_idx: int) -> void:
	active_tab = tab_idx
	if active_tab == 0:
		# Pestaña Hardware -> Colores Naranjas
		bg_frame.modulate = Color(1.0, 0.55, 0.1, 1.0)
		divider.color = Color(1.0, 0.55, 0.1, 0.55)
		hardware_container.visible = true
		systems_container.visible = false
		btn_tab_hardware.modulate = Color(1.3, 1.1, 0.3, 1.0)
		btn_tab_systems.modulate = Color(0.7, 0.7, 0.7, 0.7)
	else:
		# Pestaña Sistemas -> Colores Azules Andromeda
		bg_frame.modulate = Color(0.09, 0.58, 0.82, 1.0)
		divider.color = Color(0.09, 0.58, 0.82, 0.55)
		hardware_container.visible = false
		systems_container.visible = true
		btn_tab_hardware.modulate = Color(0.7, 0.7, 0.7, 0.7)
		btn_tab_systems.modulate = Color(0.2, 0.95, 1.0, 1.0)
		
	_refresh_ui()

func _has_item_in_backpack(item_name: String) -> bool:
	for it in GameManager.backpack:
		var n = it.get("name", "")
		if not it.get("broken", true):
			if n == item_name:
				return true
			if item_name == "CPU" and (n == "Procesador" or n == "CPU"):
				return true
			if item_name == "Grafica" and (n == "Tarjeta Grafica" or n == "Grafica" or n == "GPU"):
				return true
			if item_name == "Disco Duro" and (n == "Disco Duro" or n == "SSD" or n == "M.2"):
				return true
			if item_name == "Fan Cooler" and (n == "Fan Cooler" or n == "Cooler"):
				return true
			if item_name == "Refrigeracion Liquida" and ("Refrigeracion" in n or "Liquid" in n):
				return true
	return false

func _consume_item_from_backpack(item_name: String) -> void:
	for i in range(GameManager.backpack.size()):
		var it = GameManager.backpack[i]
		var n = it.get("name", "")
		var matches = (n == item_name)
		if not matches:
			if item_name == "CPU" and (n == "Procesador" or n == "CPU"): matches = true
			elif item_name == "Grafica" and (n == "Tarjeta Grafica" or n == "Grafica" or n == "GPU"): matches = true
			elif item_name == "Disco Duro" and (n == "Disco Duro" or n == "SSD" or n == "M.2"): matches = true
			elif item_name == "Fan Cooler" and (n == "Fan Cooler" or n == "Cooler"): matches = true
			elif item_name == "Refrigeracion Liquida" and ("Refrigeracion" in n or "Liquid" in n): matches = true
		if matches and not it.get("broken", true):
			GameManager.remove_item_from_backpack(i)
			break

func _refresh_ui() -> void:
	if not is_inside_tree() or current_server == null:
		return
		
	if title_label:
		title_label.text = "TORRE DE SERVIDOR #%d // RACK EMPRESARIAL 19 PULGADAS" % current_server.server_id
		
	var is_mobo_fixed = (current_server.components.get("Placa Madre", "broken") == "fixed")
	var hw_fixed_count = 0
	var missing_names: Array[String] = []
	var buttons = [btn_mobo, btn_ram, btn_ssd, btn_cpu, btn_cooler, btn_gpu]
	var cards = [card_mobo, card_ram, card_ssd, card_cpu, card_cooler, card_gpu]
	
	for i in range(HARDWARE_COMPONENTS.size()):
		var data = HARDWARE_COMPONENTS[i]
		var btn: Button = buttons[i]
		var card: PanelContainer = cards[i]
		var key = data["key"]
		var item_name = data["item_name"]
		var is_base = data.get("is_base", false)
		var status = current_server.components.get(key, "broken")
		
		if status == "fixed":
			hw_fixed_count += 1
			card.modulate = Color(1.0, 1.0, 1.0, 1.0)
			btn.disabled = false
			btn.text = "✓ OPERATIVO [INSTALADO]"
			btn.modulate = Color(0.2, 1.0, 0.5)
		else:
			missing_names.append(item_name)
			if not is_base and not is_mobo_fixed:
				# BLOQUEADO HASTA QUE SE INSTALE LA PLACA MADRE
				card.modulate = Color(0.65, 0.65, 0.7, 0.5)
				btn.disabled = true
				btn.text = "🔒 [BLOQUEADO: Instala primero la Placa Madre]"
				btn.modulate = Color(0.4, 0.4, 0.45, 0.5)
			else:
				# Desbloqueado: detectar si el jugador tiene la pieza
				card.modulate = Color(1.0, 1.0, 1.0, 1.0)
				btn.disabled = false
				var target_count = data.get("target_count", 1)
				var installed = current_server.components_installed_counts.get(key, 0) if current_server and "components_installed_counts" in current_server else 0
				var count_in_backpack = 0
				for it in GameManager.backpack:
					if it is Dictionary and (it.get("name") == item_name or it.get("type") == item_name) and not it.get("broken", true):
						count_in_backpack += 1
				
				if count_in_backpack > 0:
					if target_count > 1 and installed > 0:
						btn.text = "⚡ %d EN MOCHILA · CONTINUAR (%d/%d MONTADOS)" % [count_in_backpack, installed, target_count]
					elif target_count > 1:
						btn.text = "⚡ %d EN MOCHILA · INICIAR MONTAJE (0/%d)" % [count_in_backpack, target_count]
					else:
						btn.text = "⚡ REPUESTO DETECTADO EN INVENTARIO · CLIC PARA INTERVENIR"
					btn.modulate = Color(1.0, 0.65, 0.15)
				else:
					if target_count > 1 and installed > 0:
						btn.text = "⚠️ PAUSADO (%d/%d MONTADOS) · BÚSCA REPUESTO EN EL DATACENTER" % [installed, target_count]
					else:
						btn.text = "⚠️ FALTA [%s] · BÚSCALO EN EL DATACENTER" % item_name.to_upper()
					btn.modulate = Color(0.65, 0.65, 0.7, 0.65)
					
	# Mochila
	var slots = [slot_0, slot_1, slot_2]
	for i in range(slots.size()):
		var s = slots[i]
		if i < GameManager.backpack.size():
			var it = GameManager.backpack[i]
			s.text = "Slot %d: 📦 %s" % [i + 1, it.get("name", "Item")]
			s.modulate = Color(1.0, 0.8, 0.25)
		else:
			s.text = "Slot %d: [ VACÍO ]" % [i + 1]
			s.modulate = Color(0.5, 0.5, 0.55, 0.5)
			
	var is_hw_complete = (hw_fixed_count >= HARDWARE_COMPONENTS.size())
	
	# Pestaña Sistemas
	if is_hw_complete:
		btn_tab_systems.text = "󰣇 SISTEMAS ANDROMEDA LINUX [✓ DESBLOQUEADO]"
		btn_tab_systems.add_theme_color_override("font_color", Color(0.1, 0.9, 1.0))
	else:
		btn_tab_systems.text = "󰣇 SISTEMAS ANDROMEDA LINUX [🔒]"
		btn_tab_systems.add_theme_color_override("font_color", Color(0.8, 0.4, 0.3))
		
	var is_sys_done = (current_server.components.get("Sistemas Andromeda Linux", "broken") == "fixed")
	
	if not is_hw_complete:
		locked_panel.visible = true
		unlocked_panel.visible = false
		lock_desc.text = "El servidor no tiene energía ni subsistemas físicos completos. Debes ensamblar los 6 componentes de hardware para habilitar la instalación de Andromeda Linux:\n\nPiezas pendientes: " + ", ".join(missing_names)
	else:
		locked_panel.visible = false
		unlocked_panel.visible = true
		if is_sys_done:
			btn_launch_cli.text = "✓ SISTEMA ANDROMEDA LINUX OPERATIVO · [REPETIR INSTALACIÓN]"
			btn_launch_cli.modulate = Color(0.2, 1.0, 0.55)
		else:
			btn_launch_cli.text = "⌨️ INICIAR INSTALACIÓN DE ANDROMEDA LINUX (CLI)"
			btn_launch_cli.modulate = Color(0.1, 1.0, 0.8)
			
	var is_liquid_done = (current_server.components.get("Refrigeracion Liquida Custom Loop", "broken") == "fixed")
	var has_liquid = _has_item_in_backpack("Refrigeracion Liquida")
	
	# Control de visibilidad del Cuadro Azul de Refrigeración Líquida
	if is_sys_done and not is_liquid_done:
		if is_instance_valid(cuadro_azul):
			cuadro_azul.visible = true
			if has_liquid:
				desc_liquid.text = "✓ Refrigeración Líquida detectada en inventario.\n¡Haz clic aquí o arrastra para acoplar el bloque y montar los tubos del servidor!"
				btn_acoplar_liquid.text = "💧 [ INSTALAR REFRIGERACIÓN LÍQUIDA (CLIC O ARRASTRA AQUÍ) ]"
				btn_acoplar_liquid.modulate = Color(0.1, 1.0, 0.9)
			else:
				desc_liquid.text = "🔒 FASE FINAL PENDIENTE: Ve a la caja de Refrigeración Líquida en la sala de servidores (frente a la torre) y recógela con [E]."
				btn_acoplar_liquid.text = "⚠️ FALTA REFRIGERACIÓN LÍQUIDA EN INVENTARIO"
				btn_acoplar_liquid.modulate = Color(1.0, 0.6, 0.2)
	else:
		if is_instance_valid(cuadro_azul):
			cuadro_azul.visible = false
			
	# Cabecera de estado
	if current_server.is_fully_repaired():
		badge_label.text = "¡TORRE DE SERVIDOR 100% OPERATIVA · CLÚSTER ANDROMEDA ONLINE! ✓"
		badge_label.modulate = Color(0.2, 1.0, 0.4)
		status_summary.text = "TELEMETRÍA ÓPTIMA · HARDWARE, ANDROMEDA LINUX Y REFRIGERACIÓN LÍQUIDA DESPLEGADOS"
		status_summary.modulate = Color(0.2, 1.0, 0.4)
	elif is_sys_done and not is_liquid_done:
		badge_label.text = "SISTEMA OPERATIVO INSTALADO · PENDIENTE: REFRIGERACIÓN LÍQUIDA"
		badge_label.modulate = Color(0.1, 0.95, 1.0)
		status_summary.text = "Recoge la Refrigeración Líquida de la sala y acóplala en el Cuadro Azul central para cerrar el circuito térmico."
		status_summary.modulate = Color(0.1, 0.95, 1.0)
	elif not is_mobo_fixed:
		badge_label.text = "ESTADO: BLOQUEO DE SEGURIDAD · MONTA LA PLACA MADRE PRIMERO"
		badge_label.modulate = Color(1.0, 0.5, 0.2)
		status_summary.text = "⚠️ PRIMER PASO: Monta la Placa Madre base en la bandeja inferior [U1] para desbloquear los demás zócalos."
		status_summary.modulate = Color(1.0, 0.85, 0.2)
	elif is_hw_complete:
		badge_label.text = "HARDWARE 100% ENSAMBLADO (6/6) · PENDIENTE: INSTALAR ANDROMEDA LINUX"
		badge_label.modulate = Color(0.2, 0.85, 1.0)
		status_summary.text = "Ve a la pestaña [󰣇 SISTEMAS ANDROMEDA LINUX] para instalar el sistema operativo por teclado."
		status_summary.modulate = Color(0.2, 0.85, 1.0)
	else:
		badge_label.text = "ESTADO: EN MONTAJE DE HARDWARE (%d/6 COMPONENTES MONTADOS)" % hw_fixed_count
		badge_label.modulate = Color(1.0, 0.65, 0.2)
		status_summary.text = "✓ ¡Placa Madre instalada! Todas las bahías desbloqueadas. Recoge los repuestos de la sala para montar cada componente."
		status_summary.modulate = Color(0.2, 1.0, 0.5)

func _apply_server_orange_theme(minigame: Node) -> void:
	var bg = minigame.find_child("CyberBackgroundFrame", true, false)
	if bg:
		bg.modulate = Color(1.0, 0.55, 0.1, 1.0)
	var tit = minigame.find_child("Titulo", true, false)
	if tit and tit is Label:
		tit.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	var st = minigame.find_child("StatusLabel", true, false)
	if st and st is Label:
		st.modulate = Color(1.0, 0.85, 0.3)
	var hdr = minigame.find_child("Header", true, false)
	if hdr:
		hdr.modulate = Color(1.05, 0.95, 0.85)

func _on_backpack_slot_pressed(idx: int) -> void:
	if idx < 0 or idx >= GameManager.backpack.size():
		return
	var item = GameManager.backpack[idx]
	var item_name = item.get("name", "")
	if item_name == "Refrigeracion Liquida":
		var is_sys_done = (current_server and current_server.components.get("Sistemas Andromeda Linux", "broken") == "fixed")
		if is_sys_done:
			if is_instance_valid(cuadro_azul):
				cuadro_azul.visible = true
			_launch_liquid_cooling()
		else:
			_show_feedback("⚠️ Instala primero el sistema operativo Andromeda Linux antes de acoplar la refrigeración líquida.", Color(1.0, 0.6, 0.2))

func _on_component_clicked(comp_idx: int) -> void:
	if comp_idx < 0 or comp_idx >= HARDWARE_COMPONENTS.size():
		return
	var data = HARDWARE_COMPONENTS[comp_idx]
	var key = data["key"]
	var item_name = data["item_name"]
	var is_base = data.get("is_base", false)
	
	if current_server and current_server.components.get(key, "") == "fixed":
		_show_feedback("✓ %s ya está montado y asegurado." % data["title"], Color(0.2, 1.0, 0.5))
		return
		
	# Si no es la placa madre y la placa aún no está fija, bloquear
	var is_mobo_fixed = (current_server.components.get("Placa Madre", "broken") == "fixed")
	if not is_base and not is_mobo_fixed:
		_show_feedback("🔒 BLOQUEADO: Debes montar primero la Placa Madre en la bahía [U1].", Color(1.0, 0.4, 0.2))
		return
		
	# Comprobar si el jugador tiene la pieza en la mochila
	if not _has_item_in_backpack(item_name):
		_show_feedback("⚠️ No tienes [%s] en tu mochila. Sal de la torre y recógela de la sala con [E]." % item_name, Color(1.0, 0.35, 0.35))
		return
		
	active_repair_component = key
	var scene_to_launch: PackedScene = get(data["scene"])
	if not scene_to_launch:
		return
		
	var minigame = scene_to_launch.instantiate()
	minigame.start_as_empty_slot = true
	_apply_server_orange_theme(minigame)
	
	if data.has("target_count"):
		if "target_ram_count" in minigame:
			minigame.target_ram_count = data["target_count"]
		if "target_hdd_count" in minigame:
			minigame.target_hdd_count = data["target_count"]
		if "target_cpu_count" in minigame:
			minigame.target_cpu_count = data["target_count"]
			minigame.require_screws_sequence = true
		if "target_cooler_count" in minigame:
			minigame.target_cooler_count = data["target_count"]
		if "target_gpu_count" in minigame:
			minigame.target_gpu_count = data["target_count"]
			
	var current_done = 0
	if current_server and "components_installed_counts" in current_server:
		current_done = current_server.components_installed_counts.get(key, 0)
	if "initial_installed_count" in minigame:
		minigame.initial_installed_count = current_done
			
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("select_tool"):
		gm.select_tool(1)
		
	current_minigame_instance = minigame
	modal_control.visible = false
	add_child(minigame)
	
	minigame.minigame_finished.connect(func(success: bool):
		_on_hardware_minigame_finished(success, item_name, key)
	)

func _on_hardware_minigame_finished(success: bool, item_name: String, key: String) -> void:
	var installed_count = 0
	if is_instance_valid(current_minigame_instance):
		if current_minigame_instance.has_method("get_installed_count"):
			installed_count = current_minigame_instance.get_installed_count()
		current_minigame_instance.queue_free()
		current_minigame_instance = null
		
	modal_control.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var target_count = 1
	for comp in HARDWARE_COMPONENTS:
		if comp["key"] == key:
			target_count = comp.get("target_count", 1)
			break
			
	if current_server and "components_installed_counts" in current_server:
		if success:
			current_server.components_installed_counts[key] = target_count
		elif installed_count > 0:
			current_server.components_installed_counts[key] = max(current_server.components_installed_counts.get(key, 0), installed_count)
	
	if success:
		if target_count == 1:
			_consume_item_from_backpack(item_name)
		if current_server:
			current_server.components[key] = "fixed"
			current_server.update_3d_state()
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("add_score"):
			gm.add_score(150, 10.0)
		_show_feedback("✓ ¡%s MONTADO Y ASEGURADO CON ÉXITO! (+150 PTS)" % key.to_upper(), Color(0.2, 1.0, 0.5))
	else:
		var cur_installed = current_server.components_installed_counts.get(key, 0) if current_server and "components_installed_counts" in current_server else 0
		if cur_installed > 0 and cur_installed < target_count:
			_show_feedback("Progreso guardado: %d de %d piezas montadas. Ve al datacenter por los repuestos restantes." % [cur_installed, target_count], Color(1.0, 0.85, 0.2))
		else:
			_show_feedback("⚠️ Montaje de %s pausado." % key, Color(1.0, 0.65, 0.2))
		
	_refresh_ui()

func _launch_andromeda_cli() -> void:
	if not current_server or not current_server.is_hardware_completed():
		_show_feedback("⚠️ Debes ensamblar los 6 componentes de hardware antes de instalar el sistema.", Color(1.0, 0.35, 0.35))
		return
		
	var minigame = andromeda_cli_scene.instantiate()
	current_minigame_instance = minigame
	modal_control.visible = false
	add_child(minigame)
	
	minigame.minigame_finished.connect(func(success: bool):
		if is_instance_valid(current_minigame_instance):
			current_minigame_instance.queue_free()
			current_minigame_instance = null
			
		modal_control.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		if success:
			if current_server:
				current_server.components["Sistemas Andromeda Linux"] = "fixed"
				current_server.update_3d_state()
			var gm = get_node_or_null("/root/GameManager")
			if gm and gm.has_method("add_score"):
				gm.add_score(300, 20.0)
			_show_feedback("✓ ¡ANDROMEDA LINUX ENTERPRISE INSTALADO! ¡SERVIDOR 100% ONLINE! (+300 PTS)", Color(0.2, 1.0, 0.5))
		else:
			_show_feedback("⚠️ Instalación de Andromeda Linux pausada.", Color(1.0, 0.85, 0.2))
			
		_refresh_ui()
	)

func _launch_liquid_cooling() -> void:
	if not _has_item_in_backpack("Refrigeracion Liquida"):
		_show_feedback("⚠️ No tienes [Refrigeracion Liquida] en tu mochila. Sal y recógela de la sala.", Color(1.0, 0.35, 0.35))
		return
		
	var minigame = liquid_minigame_scene.instantiate()
	current_minigame_instance = minigame
	modal_control.visible = false
	add_child(minigame)
	
	minigame.minigame_finished.connect(func(success: bool):
		if is_instance_valid(current_minigame_instance):
			current_minigame_instance.queue_free()
			current_minigame_instance = null
			
		modal_control.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		if success:
			_consume_item_from_backpack("Refrigeracion Liquida")
			if current_server:
				current_server.components["Refrigeracion Liquida Custom Loop"] = "fixed"
				current_server.update_3d_state()
			var gm = get_node_or_null("/root/GameManager")
			if gm and gm.has_method("add_score"):
				gm.add_score(500, 30.0)
			if gm and gm.has_method("complete_level"):
				gm.complete_level()
			_show_feedback("✓ ¡REFRIGERACIÓN LÍQUIDA INSTALADA! ¡TORRE DE SERVIDOR 100% OPERATIVA! (+500 PTS)", Color(0.2, 1.0, 0.5))
		else:
			_show_feedback("⚠️ Montaje de refrigeración líquida pausado.", Color(1.0, 0.85, 0.2))
			
		_refresh_ui()
	)

func _show_feedback(msg: String, col: Color) -> void:
	feedback_label.text = msg
	feedback_label.modulate = col
	feedback_label.visible = true
	var tw = create_tween()
	tw.tween_property(feedback_label, "modulate:a", 1.0, 0.2)
	tw.tween_property(feedback_label, "modulate:a", 0.0, 2.8).set_delay(1.5)

func _on_volver_pressed() -> void:
	inspection_closed.emit()
	queue_free()
