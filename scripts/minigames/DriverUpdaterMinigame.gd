extends CanvasLayer

# =============================================================================
# MINIJUEGO: ACTUALIZACIÓN DE CONTROLADORES & GESTIÓN DE PAQUETES (DRIVERS)
# Enseña:
# 1. Identificar controladores de hardware desactualizados causantes de fallas.
# 2. Elegir versiones oficiales WHQL (Windows Hardware Quality Labs) frente a Betas inestables.
# 3. Evitar drivers genéricos o sin firma digital de fuentes no autorizadas.
# 4. Verificar integridad y calibrar dispositivos tras una instalación limpia.
# =============================================================================

signal minigame_finished(success: bool)

# Nodos Principales
@onready var modal_control: Control = $ModalControl
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel
@onready var progress_bar: ProgressBar = $ModalControl/Panel/VBox/Header/Metrics/ProgressBar
@onready var lbl_updated_count: Label = $ModalControl/Panel/VBox/Header/Metrics/LblUpdatedCount

# Contenedor de dispositivos (Columna izquierda)
@onready var devices_list_container: VBoxContainer = $ModalControl/Panel/VBox/WorkHBox/LeftCol/DevicesList

# Contenedor de inspección (Columna derecha)
@onready var lbl_device_name: Label = $ModalControl/Panel/VBox/WorkHBox/RightCol/VBox/DeviceName
@onready var lbl_device_issue: Label = $ModalControl/Panel/VBox/WorkHBox/RightCol/VBox/DeviceIssue
@onready var packages_vbox: VBoxContainer = $ModalControl/Panel/VBox/WorkHBox/RightCol/VBox/PackagesVBox
@onready var btn_apply_update: Button = $ModalControl/Panel/VBox/WorkHBox/RightCol/VBox/BtnApplyUpdate
@onready var install_progress: ProgressBar = $ModalControl/Panel/VBox/WorkHBox/RightCol/VBox/InstallProgress
@onready var toast_label: Label = $ModalControl/Panel/VBox/WorkHBox/RightCol/VBox/ToastLabel
@onready var victory_banner: PanelContainer = $ModalControl/Panel/VBox/WorkHBox/RightCol/VBox/VictoryBanner

var selected_device_idx: int = 0
var updated_devices_count: int = 0
var selected_package_idx: int = -1
var is_installing: bool = false
var is_completed: bool = false

var DEVICES_DATA: Array[Dictionary] = [
	{
		"name": "GPU: Tarjeta Gráfica CyberGeForce RTX",
		"category": "GRÁFICOS & PANTALLA",
		"current_ver": "v410.2 (Año 2021)",
		"issue": "Falla: Tirones severos (stuttering) y parpadeos negros en salida DisplayPort.",
		"is_updated": false,
		"packages": [
			{"name": "v410.2 (Mantener versión de fábrica actual)", "is_correct": false, "reason": "No resuelve las fallas ni el bajo rendimiento."},
			{"name": "v560.1 Beta Experimental (Inestable)", "is_correct": false, "reason": "Versión de prueba no firmada: provoca pantallazos azules (BSOD)."},
			{"name": "v550.4 WHQL Game-Ready Certified (Estable)", "is_correct": true, "reason": "Controlador oficial certificado con soporte Vulkan 1.3 y parches térmicos."}
		]
	},
	{
		"name": "Red: Adaptador Wi-Fi 6 802.11ax",
		"category": "CONECTIVIDAD & REDES",
		"current_ver": "v1.0.1 (Año 2020)",
		"issue": "Falla: Desconexiones intermitentes cada 5 minutos y alta latencia de ping.",
		"is_updated": false,
		"packages": [
			{"name": "v1.0.1 (Reinstalar driver actual)", "is_correct": false, "reason": "Persisten los problemas de microcortes."},
			{"name": "v2.5.0 Firmware Oficial con Roaming Fix", "is_correct": true, "reason": "Resuelve la gestión de canales a 5 GHz y estabiliza la tasa de paquetes."},
			{"name": "Controlador Genérico de Red 2015", "is_correct": false, "reason": "Limita la velocidad a solo 10 Mbps sin soporte Wi-Fi 6."}
		]
	},
	{
		"name": "Audio: Códec Realtek High Definition ALC",
		"category": "MULTIMEDIA & SONIDO",
		"current_ver": "v0.9 Beta",
		"issue": "Falla: Ruido estático 'clic' constante por desbordamiento de búfer (buffer underrun).",
		"is_updated": false,
		"packages": [
			{"name": "Driver genérico sin firma digital", "is_correct": false, "reason": "Alerta de seguridad: archivos sin firma criptográfica confiable."},
			{"name": "v3.2 Parche Oficial de Baja Latencia & ASIO", "is_correct": true, "reason": "Configura correctamente los búferes de muestreo a 24-bit / 96 kHz."}
		]
	},
	{
		"name": "Placa: Controlador Chipset PCIe Bus Master",
		"category": "INFRAESTRUCTURA DE PLACA",
		"current_ver": "v1.1 (Gen 2)",
		"issue": "Falla: Líneas PCIe estranguladas a 5 GT/s (Gen 2 en vez de Gen 4 de alta velocidad).",
		"is_updated": false,
		"packages": [
			{"name": "v4.2 Master Bus Chipset Driver WHQL", "is_correct": true, "reason": "Desbloquea 16 GT/s completos en líneas PCIe Gen 4 para SSD M.2 y GPU."},
			{"name": "Driver básico de almacenamiento MBR", "is_correct": false, "reason": "Incompatible con transferencias directas de memoria DMA."}
		]
	}
]

var device_buttons: Array[Button] = []
var package_buttons: Array[Button] = []

func _ready() -> void:
	layer = 12
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	btn_apply_update.pressed.connect(_on_apply_update_pressed)
	btn_apply_update.disabled = true
	install_progress.visible = false
	toast_label.visible = false
	victory_banner.visible = false
	
	_build_devices_list()
	_select_device(0)
	_update_metrics()
	_update_status("Selecciona cada dispositivo desactualizado e instala el paquete certificado WHQL.")

func _build_devices_list() -> void:
	for child in devices_list_container.get_children():
		child.queue_free()
	device_buttons.clear()
	
	for i in range(DEVICES_DATA.size()):
		var data = DEVICES_DATA[i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 54)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_style_device_button(btn, data)
		
		var idx = i
		btn.pressed.connect(func(): _select_device(idx))
		devices_list_container.add_child(btn)
		device_buttons.append(btn)

func _style_device_button(btn: Button, data: Dictionary) -> void:
	if data["is_updated"]:
		btn.text = " ✓ %s\n   Versión actual: ACTUALIZADO [WHQL]" % data["name"]
		btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	else:
		btn.text = " ⚠️ %s\n   Versión actual: %s [DESACTUALIZADO]" % [data["name"], data["current_ver"]]
		btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))

func _select_device(idx: int) -> void:
	if is_installing:
		return
		
	selected_device_idx = idx
	selected_package_idx = -1
	btn_apply_update.disabled = true
	var data = DEVICES_DATA[idx]
	
	lbl_device_name.text = "%s\nCategoría: %s" % [data["name"], data["category"]]
	lbl_device_issue.text = "%s\nVersión instalada: %s" % [data["issue"], data["current_ver"]]
	
	if data["is_updated"]:
		lbl_device_issue.text += "\n\n✓ Este componente ya cuenta con su última versión estable certificada."
	
	_build_packages_list(data)

func _build_packages_list(data: Dictionary) -> void:
	for child in packages_vbox.get_children():
		child.queue_free()
	package_buttons.clear()
	
	if data["is_updated"]:
		var lbl = Label.new()
		lbl.text = "✓ No se requieren actualizaciones adicionales para este dispositivo."
		lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
		lbl.add_theme_font_size_override("font_size", 11)
		packages_vbox.add_child(lbl)
		return
		
	for i in range(data["packages"].size()):
		var pkg = data["packages"][i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 36)
		btn.text = " 📦 %s" % pkg["name"]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 10)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		var p_idx = i
		btn.pressed.connect(func(): _select_package(p_idx))
		packages_vbox.add_child(btn)
		package_buttons.append(btn)

func _select_package(p_idx: int) -> void:
	if is_installing:
		return
	selected_package_idx = p_idx
	btn_apply_update.disabled = false
	
	for i in range(package_buttons.size()):
		var btn = package_buttons[i]
		if i == p_idx:
			btn.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0))
		else:
			btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))

func _on_apply_update_pressed() -> void:
	if selected_package_idx < 0 or is_installing:
		return
		
	var dev_data = DEVICES_DATA[selected_device_idx]
	var pkg_data = dev_data["packages"][selected_package_idx]
	
	if not pkg_data["is_correct"]:
		_show_toast("⚠️ ERROR: %s" % pkg_data["reason"])
		var tw_shake = create_tween()
		tw_shake.tween_property(btn_apply_update, "position:x", btn_apply_update.position.x + 8, 0.05)
		tw_shake.tween_property(btn_apply_update, "position:x", btn_apply_update.position.x - 8, 0.05)
		tw_shake.tween_property(btn_apply_update, "position:x", btn_apply_update.position.x, 0.05)
		return
		
	# Iniciar instalación del paquete correcto
	is_installing = true
	btn_apply_update.disabled = true
	install_progress.visible = true
	install_progress.value = 0.0
	_show_toast("Descargando paquete oficial y verificando firma SHA-256...")
	
	var tw = create_tween()
	tw.tween_property(install_progress, "value", 100.0, 1.2)
	await tw.finished
	
	install_progress.visible = false
	is_installing = false
	dev_data["is_updated"] = true
	updated_devices_count += 1
	
	_show_toast("✓ ¡Instalación exitosa! %s" % pkg_data["reason"])
	_style_device_button(device_buttons[selected_device_idx], dev_data)
	_select_device(selected_device_idx)
	_update_metrics()
	
	if updated_devices_count >= DEVICES_DATA.size():
		_on_all_devices_updated()

func _on_all_devices_updated() -> void:
	if is_completed:
		return
	is_completed = true
	_update_status("¡TODOS LOS DRIVERS HAN SIDO ACTUALIZADOS! Hardware operando a máxima capacidad.")
	
	victory_banner.visible = true
	victory_banner.scale = Vector2(0.6, 0.6)
	victory_banner.modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(victory_banner, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(victory_banner, "modulate:a", 1.0, 0.25)
	
	await get_tree().create_timer(2.3).timeout
	minigame_finished.emit(true)

func _update_metrics() -> void:
	var total = DEVICES_DATA.size()
	var pct = float(updated_devices_count) / float(total) * 100.0
	progress_bar.value = pct
	lbl_updated_count.text = "DISPOSITIVOS ACTUALIZADOS: %d / %d" % [updated_devices_count, total]
	
	if updated_devices_count == total:
		lbl_updated_count.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))

func _update_status(msg: String) -> void:
	status_label.text = msg

func _show_toast(msg: String) -> void:
	toast_label.text = msg
	toast_label.visible = true
	toast_label.modulate.a = 1.0
	var tw = create_tween()
	tw.tween_property(toast_label, "modulate:a", 0.0, 2.4).set_delay(1.2)
	tw.chain().tween_callback(func(): toast_label.visible = false)
