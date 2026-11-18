extends CanvasLayer

signal inspection_closed()

var current_pc = null

# Lazy loading de los 7 minijuegos de sistemas para maximizar rendimiento y velocidad de carga
var _os_minigame_scene: PackedScene = null
var os_minigame_scene: PackedScene:
	get:
		if not _os_minigame_scene: _os_minigame_scene = load("res://scenes/minigames/OSInstallMinigame.tscn")
		return _os_minigame_scene
	set(v): _os_minigame_scene = v

var _driver_minigame_scene: PackedScene = null
var driver_minigame_scene: PackedScene:
	get:
		if not _driver_minigame_scene: _driver_minigame_scene = load("res://scenes/minigames/DriverUpdaterMinigame.tscn")
		return _driver_minigame_scene
	set(v): _driver_minigame_scene = v

var _malware_minigame_scene: PackedScene = null
var malware_minigame_scene: PackedScene:
	get:
		if not _malware_minigame_scene: _malware_minigame_scene = load("res://scenes/minigames/MalwareScannerMinigame.tscn")
		return _malware_minigame_scene
	set(v): _malware_minigame_scene = v

var _adware_minigame_scene: PackedScene = null
var adware_minigame_scene: PackedScene:
	get:
		if not _adware_minigame_scene: _adware_minigame_scene = load("res://scenes/minigames/AdwareCleanerMinigame.tscn")
		return _adware_minigame_scene
	set(v): _adware_minigame_scene = v

var _debugger_minigame_scene: PackedScene = null
var debugger_minigame_scene: PackedScene:
	get:
		if not _debugger_minigame_scene: _debugger_minigame_scene = load("res://scenes/minigames/CodeDebuggerMinigame.tscn")
		return _debugger_minigame_scene
	set(v): _debugger_minigame_scene = v

var _usb_minigame_scene: PackedScene = null
var usb_minigame_scene: PackedScene:
	get:
		if not _usb_minigame_scene: _usb_minigame_scene = load("res://scenes/minigames/UsbPendriveMinigame.tscn")
		return _usb_minigame_scene
	set(v): _usb_minigame_scene = v

var _arcade_minigame_scene: PackedScene = null
var arcade_minigame_scene: PackedScene:
	get:
		if not _arcade_minigame_scene: _arcade_minigame_scene = load("res://scenes/minigames/MalwareInvadersMinigame.tscn")
		return _arcade_minigame_scene
	set(v): _arcade_minigame_scene = v

@onready var modal_control: Control = $ModalControl
@onready var title_label: Label = $ModalControl/Panel/VBox/Header/TitleLabel
@onready var status_summary: Label = $ModalControl/Panel/VBox/Header/StatusSummary
@onready var pc_state_badge: Label = $ModalControl/Panel/VBox/Header/BadgeLabel
@onready var neofetch_specs: Label = $ModalControl/Panel/VBox/MainContentHBox/NeofetchPanel/Margin/VBox/NeofetchSpecs

@onready var btn_comp_os: Button = $ModalControl/Panel/VBox/MainContentHBox/TilingGrid/BtnOS
@onready var btn_comp_drivers: Button = $ModalControl/Panel/VBox/MainContentHBox/TilingGrid/BtnDrivers
@onready var btn_comp_malware: Button = $ModalControl/Panel/VBox/MainContentHBox/TilingGrid/BtnMalware
@onready var btn_comp_adware: Button = $ModalControl/Panel/VBox/MainContentHBox/TilingGrid/BtnAdware
@onready var btn_comp_debugger: Button = $ModalControl/Panel/VBox/MainContentHBox/TilingGrid/BtnDebugger
@onready var btn_comp_usb: Button = $ModalControl/Panel/VBox/MainContentHBox/TilingGrid/BtnUSB
@onready var btn_comp_arcade: Button = $ModalControl/Panel/VBox/MainContentHBox/TilingGrid/BtnArcade

@onready var btn_volver: Button = $ModalControl/Panel/VBox/Footer/BtnVolver
@onready var feedback_label: Label = $ModalControl/Panel/VBox/FeedbackLabel

var comp_buttons: Dictionary = {}

func _ready() -> void:
	layer = 10
	btn_volver.pressed.connect(_on_volver_pressed)
	
	comp_buttons = {
		btn_comp_os: "Sistema Operativo",
		btn_comp_drivers: "Drivers",
		btn_comp_malware: "Malware",
		btn_comp_adware: "Adware",
		btn_comp_debugger: "Debugger",
		btn_comp_usb: "Pendrive USB",
		btn_comp_arcade: "Arcade Ciberdefensa"
	}
	
	btn_comp_os.pressed.connect(func(): _launch_minigame("Sistema Operativo", os_minigame_scene))
	btn_comp_drivers.pressed.connect(func(): _launch_minigame("Drivers", driver_minigame_scene))
	btn_comp_malware.pressed.connect(func(): _launch_minigame("Malware", malware_minigame_scene))
	btn_comp_adware.pressed.connect(func(): _launch_minigame("Adware", adware_minigame_scene))
	btn_comp_debugger.pressed.connect(func(): _launch_minigame("Debugger", debugger_minigame_scene))
	btn_comp_usb.pressed.connect(func(): _launch_minigame("Pendrive USB", usb_minigame_scene))
	btn_comp_arcade.pressed.connect(func(): _launch_minigame("Arcade Ciberdefensa", arcade_minigame_scene))
	
	for btn in comp_buttons.keys():
		if btn:
			btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	if current_pc != null:
		_refresh_ui()

func _unhandled_input(event: InputEvent) -> void:
	if not modal_control or not modal_control.visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		_on_volver_pressed()

func setup_pc(pc_ref) -> void:
	current_pc = pc_ref
	if is_inside_tree() and pc_state_badge != null:
		_refresh_ui()

func _refresh_ui() -> void:
	if not is_inside_tree() or current_pc == null or pc_state_badge == null:
		return
		
	var pc_id_str = str(current_pc.pc_id) if current_pc else "1"
	if title_label and current_pc:
		title_label.text = "ESTACIÓN DE SISTEMAS // CONSOLA ANDROMEDA LINUX BSPWM (PC #" + pc_id_str + ")"
		
	var os_status = current_pc.components.get("Sistema Operativo", "broken")
	var driver_status = current_pc.components.get("Drivers", "broken")
	var mal_status = current_pc.components.get("Malware", "broken")
	var ad_status = current_pc.components.get("Adware", "broken")
	var deb_status = current_pc.components.get("Debugger", "broken")
	var usb_status = current_pc.components.get("Pendrive USB", "broken")
	var arc_status = current_pc.components.get("Arcade Ciberdefensa", "broken")
	
	_update_btn_style(btn_comp_os, "❯ pacman -S andromeda-os-uefi", "Particionado GPT · systemd-boot", os_status)
	_update_btn_style(btn_comp_drivers, "❯ mhwd -a pci nonfree", "Controladores WHQL & Kernel modules", driver_status)
	_update_btn_style(btn_comp_malware, "❯ clamav --scan /system", "Escaneo heurístico & Firmas SHA256", mal_status)
	_update_btn_style(btn_comp_adware, "❯ ublock --purge-adware", "Filtro anti-adware & Daemon popups", ad_status)
	_update_btn_style(btn_comp_debugger, "❯ gdb -q ./security_daemon", "Depuración sintaxis & Tests unitarios", deb_status)
	_update_btn_style(btn_comp_usb, "❯ dd if=andromeda.iso of=/dev/sdb", "Montaje pendrive rescate FAT32", usb_status)
	_update_btn_style(btn_comp_arcade, "❯ ./malware_invaders.sh", "Ciberdefensa del núcleo del sistema", arc_status)
	
	var fixed_count = 0
	for k in current_pc.components.keys():
		if current_pc.components[k] == "fixed":
			fixed_count += 1
			
	if neofetch_specs:
		neofetch_specs.text = "tech@andromeda-station\n" + \
			"--------------------\n" + \
			"OS: Andromeda Linux x86_64\n" + \
			"Host: Workstation #" + pc_id_str + "\n" + \
			"Kernel: 6.9.1-arch1-zen\n" + \
			"Uptime: 1h 45m\n" + \
			"Packages: 7 (pacman)\n" + \
			"Shell: zsh 5.9\n" + \
			"WM: bspwm (tiling)\n" + \
			"Terminal: kitty\n" + \
			"Tasks: " + str(fixed_count) + "/7 Resueltos\n" + \
			"Security: " + ("100% OK ✓" if fixed_count == 7 else "INCIDENCIAS ACTIVAS")
			
	if current_pc.is_fully_repaired():
		pc_state_badge.text = "¡ANDROMEDA LINUX 100% OPERATIVO · 7/7 TAREAS RESUELTAS! ✓"
		pc_state_badge.modulate = Color(0.2, 1.0, 0.4)
		status_summary.text = "Todos los demonios, paquetes y defensas del sistema Andromeda Linux están en estado activo."
		if btn_volver:
			btn_volver.text = "★ COMPLETAR TRABAJO Y CERRAR SESIÓN ANDROMEDA ★"
			btn_volver.modulate = Color(0.2, 1.0, 0.5)
	else:
		pc_state_badge.text = "ESTADO: INCIDENCIAS PENDIENTES (" + str(fixed_count) + "/7 COMPLETADAS)"
		pc_state_badge.modulate = Color(0.15, 0.85, 1.0)
		status_summary.text = "Haz clic en una de las ventanas del tiling window manager para resolver la incidencia."
		if btn_volver:
			btn_volver.text = "◀ CERRAR SESIÓN ANDROMEDA LINUX"
			btn_volver.modulate = Color(1.0, 1.0, 1.0)

func _update_btn_style(btn: Button, cmd_title: String, subtitle: String, status: String) -> void:
	if not btn: return
	if status == "fixed":
		btn.text = "✓ " + cmd_title + "\n" + subtitle + "\n[ ✓ RESTAURADO ]"
		btn.modulate = Color(0.2, 1.0, 0.55, 1.0)
	else:
		btn.text = "❯ " + cmd_title + "\n" + subtitle + "\n[ PENDIENTE ]"
		btn.modulate = Color(0.15, 0.75, 1.0, 1.0)

func _launch_minigame(task_name: String, scene_packed: PackedScene) -> void:
	if scene_packed == null: return
	modal_control.visible = false
	var minigame = scene_packed.instantiate()
	minigame.set("is_tutorial_mode", false)
	get_tree().root.add_child(minigame)
	
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if success:
			if current_pc:
				current_pc.components[task_name] = "fixed"
				current_pc.update_3d_state()
			GameManager.register_repair(100, 15.0)
			_show_feedback("✓ ¡Incidencia de " + task_name + " resuelta con éxito!", true)
		else:
			_show_feedback("Incidencia de " + task_name + " no completada.", false)
		_refresh_ui()
	)

func _show_feedback(msg: String, is_success: bool) -> void:
	if not feedback_label: return
	feedback_label.text = msg
	feedback_label.modulate = Color(0.2, 1.0, 0.4) if is_success else Color(1.0, 0.3, 0.3)
	var tw = create_tween()
	tw.tween_property(feedback_label, "modulate:a", 1.0, 0.1)
	tw.tween_interval(2.5)
	tw.tween_property(feedback_label, "modulate:a", 0.0, 0.4)

func _on_volver_pressed() -> void:
	if current_pc and current_pc.has_method("is_fully_repaired") and current_pc.is_fully_repaired():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	inspection_closed.emit()
	queue_free()
