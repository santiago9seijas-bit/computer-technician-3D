extends CanvasLayer

signal inspection_closed()

var current_pc = null

# Preload de los 7 minijuegos de sistemas
var os_minigame_scene: PackedScene = preload("res://scenes/minigames/OSInstallMinigame.tscn")
var driver_minigame_scene: PackedScene = preload("res://scenes/minigames/DriverUpdaterMinigame.tscn")
var malware_minigame_scene: PackedScene = preload("res://scenes/minigames/MalwareScannerMinigame.tscn")
var adware_minigame_scene: PackedScene = preload("res://scenes/minigames/AdwareCleanerMinigame.tscn")
var debugger_minigame_scene: PackedScene = preload("res://scenes/minigames/CodeDebuggerMinigame.tscn")
var usb_minigame_scene: PackedScene = preload("res://scenes/minigames/UsbPendriveMinigame.tscn")
var arcade_minigame_scene: PackedScene = preload("res://scenes/minigames/MalwareInvadersMinigame.tscn")

@onready var modal_control: Control = $ModalControl
@onready var title_label: Label = $ModalControl/Panel/VBox/Header/TitleLabel
@onready var status_summary: Label = $ModalControl/Panel/VBox/Header/StatusSummary
@onready var pc_state_badge: Label = $ModalControl/Panel/VBox/Header/BadgeLabel

@onready var btn_comp_os: Button = $ModalControl/Panel/VBox/GridContainer/BtnOS
@onready var btn_comp_drivers: Button = $ModalControl/Panel/VBox/GridContainer/BtnDrivers
@onready var btn_comp_malware: Button = $ModalControl/Panel/VBox/GridContainer/BtnMalware
@onready var btn_comp_adware: Button = $ModalControl/Panel/VBox/GridContainer/BtnAdware
@onready var btn_comp_debugger: Button = $ModalControl/Panel/VBox/GridContainer/BtnDebugger
@onready var btn_comp_usb: Button = $ModalControl/Panel/VBox/GridContainer/BtnUSB
@onready var btn_comp_arcade: Button = $ModalControl/Panel/VBox/GridContainer/BtnArcade

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
	
	_refresh_ui()

func setup_pc(pc_ref) -> void:
	current_pc = pc_ref
	_refresh_ui()

func _refresh_ui() -> void:
	if current_pc == null:
		return
		
	var os_status = current_pc.components.get("Sistema Operativo", "broken")
	var driver_status = current_pc.components.get("Drivers", "broken")
	var mal_status = current_pc.components.get("Malware", "broken")
	var ad_status = current_pc.components.get("Adware", "broken")
	var deb_status = current_pc.components.get("Debugger", "broken")
	var usb_status = current_pc.components.get("Pendrive USB", "broken")
	var arc_status = current_pc.components.get("Arcade Ciberdefensa", "broken")
	
	_update_btn_style(btn_comp_os, "SISTEMA OPERATIVO", "CYBER-OS UEFI & GPT", os_status)
	_update_btn_style(btn_comp_drivers, "CONTROLADORES", "DRIVERS WHQL", driver_status)
	_update_btn_style(btn_comp_malware, "ESCÁNER ANTIMALWARE", "HEURÍSTICA & FIRMAS", mal_status)
	_update_btn_style(btn_comp_adware, "LIMPIEZA DE ADWARE", "BLOQUEADOR DE POP-UPS", ad_status)
	_update_btn_style(btn_comp_debugger, "TERMINAL & DEBUGGER", "CORRECCIÓN DE BUGS", deb_status)
	_update_btn_style(btn_comp_usb, "HERRAMIENTA USB", "RESPALDO & BOOTABLE", usb_status)
	_update_btn_style(btn_comp_arcade, "ARCADE CIBERDEFENSA", "DEFENSA RETRO", arc_status)
	
	var fixed_count = 0
	for k in current_pc.components.keys():
		if current_pc.components[k] == "fixed":
			fixed_count += 1
			
	if current_pc.is_fully_repaired():
		pc_state_badge.text = "¡PC DE SISTEMAS 100% OPERATIVA · 7/7 TAREAS RESUELTAS! ✓"
		pc_state_badge.modulate = Color(0.2, 1.0, 0.4)
		status_summary.text = "Todos los servicios de software y ciberseguridad han sido restaurados con éxito."
	else:
		pc_state_badge.text = "ESTADO: INCIDENCIAS PENDIENTES (" + str(fixed_count) + "/7 COMPLETADAS)"
		pc_state_badge.modulate = Color(1.0, 0.85, 0.2)
		status_summary.text = "Haz clic en cualquiera de los módulos para iniciar el diagnóstico y reparación de software."

func _update_btn_style(btn: Button, title: String, subtitle: String, status: String) -> void:
	if not btn: return
	if status == "fixed":
		btn.text = "✓ " + title + "\n" + subtitle + "\n[ RESTAURADO / OK ]"
		btn.modulate = Color(0.3, 1.0, 0.5, 1.0)
	else:
		btn.text = "⚡ " + title + "\n" + subtitle + "\n[ PENDIENTE // CLIC PARA INICIAR ]"
		btn.modulate = Color(1.0, 0.4, 0.5, 1.0)

func _launch_minigame(task_name: String, scene_packed: PackedScene) -> void:
	if scene_packed == null: return
	modal_control.visible = false
	var minigame = scene_packed.instantiate()
	minigame.set("is_tutorial_mode", false)
	get_tree().root.add_child(minigame)
	
	minigame.connect("minigame_finished", func(success: bool):
		minigame.queue_free()
		modal_control.visible = true
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
	inspection_closed.emit()
	queue_free()
