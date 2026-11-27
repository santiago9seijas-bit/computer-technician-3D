extends CanvasLayer

# =============================================================================
# MINIJUEGO: HERRAMIENTA TÉCNICA - PENDRIVE BOOTEABLE Y RESPALDO DE DATOS
# Enseña:
# 1. Conexión de la herramienta USB arrastrándola físicamente al puerto USB 3.2.
# 2. Arrastre (Drag & Drop) de archivos del cliente hacia el inventario del pendrive.
# 3. Flasheo y verificación de integridad de los datos grabados.
# 4. Desconexión por arrastre seguro para prevenir la pérdida de datos.
# =============================================================================

signal minigame_finished(success: bool)

# Nodos Principales
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var step_label: Label = $ModalControl/Panel/VBox/Header/StepLabel
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel

# Área de Hardware USB (Conexión física)
@onready var usb_port_panel: PanelContainer = $ModalControl/Panel/VBox/HardwareArea/PortPanel
@onready var pendrive_body: PanelContainer = $ModalControl/Panel/VBox/HardwareArea/PendriveBody
@onready var pendrive_led: ColorRect = $ModalControl/Panel/VBox/HardwareArea/PendriveBody/Margin/HBox/Led
@onready var pendrive_name_lbl: Label = $ModalControl/Panel/VBox/HardwareArea/PendriveBody/Margin/HBox/Name
@onready var drag_hint_lbl: Label = $ModalControl/Panel/VBox/HardwareArea/DragHint
@onready var btn_toggle_connect: Button = $ModalControl/Panel/VBox/HardwareArea/BtnToggleConnect

# Área de Archivos & Inventario (Software / Transferencia)
@onready var files_work_area: HBoxContainer = $ModalControl/Panel/VBox/FilesWorkArea
@onready var local_files_vbox: VBoxContainer = $ModalControl/Panel/VBox/FilesWorkArea/LeftCol/Margin/VBox/LocalFilesVBox
@onready var right_col: PanelContainer = $ModalControl/Panel/VBox/FilesWorkArea/RightCol
@onready var usb_inventory_vbox: VBoxContainer = $ModalControl/Panel/VBox/FilesWorkArea/RightCol/Margin/VBox/USBInventoryVBox
@onready var drop_zone_hint: PanelContainer = $ModalControl/Panel/VBox/FilesWorkArea/RightCol/Margin/VBox/DropZoneHint
@onready var lbl_usb_storage: Label = $ModalControl/Panel/VBox/FilesWorkArea/RightCol/Margin/VBox/LblUSBStorage
@onready var btn_start_transfer: Button = $ModalControl/Panel/VBox/TransferControls/BtnStartTransfer
@onready var transfer_progress_bar: ProgressBar = $ModalControl/Panel/VBox/TransferControls/TransferProgress
@onready var lbl_transfer_status: Label = $ModalControl/Panel/VBox/TransferControls/LblTransferStatus

@onready var victory_banner: PanelContainer = $ModalControl/Panel/VBox/VictoryBanner
@onready var toast_label: Label = $ModalControl/Panel/VBox/ToastLabel
@onready var drag_ghost: PanelContainer = $ModalControl/DragGhost
@onready var ghost_label: Label = $ModalControl/DragGhost/GhostLabel

enum State {
	CONNECT_USB,
	DRAG_FILES,
	TRANSFERRING,
	EJECT_USB,
	COMPLETED
}

var current_state: State = State.CONNECT_USB
var is_usb_connected: bool = false
var transferred_files_count: int = 0
const TOTAL_FILES: int = 4
var is_transferring: bool = false

# Variables de arrastre de hardware (Pendrive)
var is_dragging_pendrive: bool = false
var pendrive_drag_mouse_offset: float = 0.0
var initial_pendrive_pos: Vector2 = Vector2.ZERO
var connected_pendrive_x: float = 0.0

# Variables de arrastre de archivos
var is_dragging_file: bool = false
var dragged_file_data: Dictionary = {}
var file_cards: Dictionary = {}

var FILES_DATA: Array[Dictionary] = [
	{
		"id": "iso",
		"name": "💿 CyberOS_Installer_2026.iso",
		"size": "4.2 GB",
		"size_gb": 4.2,
		"desc": "Imagen de instalación limpia UEFI con soporte NVMe.",
		"transferred": false
	},
	{
		"id": "backup",
		"name": "🗄️ Database_Backup_Empresa.sql",
		"size": "1.5 GB",
		"size_gb": 1.5,
		"desc": "Copia de seguridad cifrada de bases de datos de clientes.",
		"transferred": false
	},
	{
		"id": "drivers",
		"name": "📦 Network_Drivers_Offline.zip",
		"size": "650 MB",
		"size_gb": 0.65,
		"desc": "Controladores Wi-Fi 6 y Ethernet offline.",
		"transferred": false
	},
	{
		"id": "rescue",
		"name": "🛡️ Antivirus_Rescue_Kit.bin",
		"size": "420 MB",
		"size_gb": 0.42,
		"desc": "Entorno de arranque para desinfección forense.",
		"transferred": false
	}
]

func _ready() -> void:
	layer = 12
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	btn_start_transfer.pressed.connect(_on_start_transfer_pressed)
	btn_toggle_connect.pressed.connect(_on_btn_toggle_connect_pressed)
	
	btn_start_transfer.disabled = true
	transfer_progress_bar.visible = false
	lbl_transfer_status.visible = false
	victory_banner.visible = false
	toast_label.visible = false
	files_work_area.visible = false
	drag_ghost.visible = false
	
	initial_pendrive_pos = pendrive_body.position
	connected_pendrive_x = usb_port_panel.position.x + 40.0
	
	pendrive_body.gui_input.connect(_on_pendrive_gui_input)
	usb_port_panel.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			if current_state == State.CONNECT_USB:
				var tw = create_tween()
				tw.tween_property(pendrive_body, "position:x", connected_pendrive_x, 0.15)
				await tw.finished
				_trigger_usb_connected()
	)
	_setup_files_ui()
	_update_state(State.CONNECT_USB)

func _input(event: InputEvent) -> void:
	if is_dragging_pendrive:
		if event is InputEventMouseMotion:
			var target_x = pendrive_body.get_global_mouse_position().x - pendrive_drag_mouse_offset
			pendrive_body.position.x = clampf(target_x, connected_pendrive_x, initial_pendrive_pos.x)
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			is_dragging_pendrive = false
			_handle_pendrive_release()
			
	if is_dragging_file:
		if event is InputEventMouseMotion:
			drag_ghost.global_position = event.global_position - Vector2(120, 20)
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			is_dragging_file = false
			drag_ghost.visible = false
			drop_zone_hint.modulate = Color(1.0, 1.0, 1.0, 1.0)
			_check_file_drop(event.global_position)

func _on_btn_toggle_connect_pressed() -> void:
	if current_state == State.CONNECT_USB:
		var tw = create_tween()
		tw.tween_property(pendrive_body, "position:x", connected_pendrive_x, 0.2).set_trans(Tween.TRANS_QUAD)
		await tw.finished
		_trigger_usb_connected()
	elif current_state == State.EJECT_USB:
		var tw = create_tween()
		tw.tween_property(pendrive_body, "position:x", initial_pendrive_pos.x, 0.2).set_trans(Tween.TRANS_QUAD)
		await tw.finished
		_trigger_usb_ejected()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		minigame_finished.emit(false)

func _update_state(new_state: State) -> void:
	current_state = new_state
	match current_state:
		State.CONNECT_USB:
			step_label.text = "PASO 1 / 4: CONEXIÓN DE LA UNIDAD PENDRIVE"
			status_label.text = "Haz clic o arrastra el pendrive hacia la izquierda para insertarlo en el puerto USB 3.2."
			drag_hint_lbl.text = "◀ ARRASTRA HACIA EL PUERTO USB ◀"
			drag_hint_lbl.visible = true
			pendrive_name_lbl.text = "💾 CyberDrive 64GB\n(Arrastra al puerto)"
			pendrive_led.color = Color(0.3, 0.3, 0.35)
			btn_toggle_connect.visible = true
			btn_toggle_connect.text = "⚡ CONECTAR AL PUERTO"
			files_work_area.visible = false
			
		State.DRAG_FILES:
			step_label.text = "PASO 2 / 4: ARRASTRA LOS ARCHIVOS AL PENDRIVE"
			status_label.text = "Haz clic o arrastra cada archivo del cliente hacia el panel derecho del pendrive."
			drag_hint_lbl.text = "🔌 PENDRIVE CONECTADO EN PUERTO USB 3.2"
			drag_hint_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.6))
			pendrive_name_lbl.text = "💾 CyberDrive (E:)\n[CONECTADO]"
			pendrive_led.color = Color(0.2, 1.0, 0.6)
			btn_toggle_connect.visible = false
			files_work_area.visible = true
			drop_zone_hint.visible = true
			_update_storage_label()
			
		State.TRANSFERRING:
			step_label.text = "PASO 3 / 4: ESCRITURA Y VERIFICACIÓN DE DATOS"
			status_label.text = "Grabando celdas flash y creando booteo GPT. ¡No desconectes la unidad!"
			btn_start_transfer.disabled = true
			btn_toggle_connect.visible = false
			transfer_progress_bar.visible = true
			lbl_transfer_status.visible = true
			drop_zone_hint.visible = false
			
		State.EJECT_USB:
			step_label.text = "PASO 4 / 4: EXTRACCIÓN SEGURA DEL DISPOSITIVO"
			status_label.text = "Copia completada al 100%. Haz clic o arrastra el pendrive hacia la derecha para desconectarlo."
			drag_hint_lbl.text = "▶ ARRASTRA HACIA LA DERECHA PARA EXTRAER ▶"
			drag_hint_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
			pendrive_name_lbl.text = "💾 CyberDrive (E:)\n(Listo para extraer)"
			btn_toggle_connect.visible = true
			btn_toggle_connect.text = "⚡ EXTRAER DISPOSITIVO"
			
			var tw_pulse = create_tween().set_loops(3)
			tw_pulse.tween_property(drag_hint_lbl, "modulate:a", 0.3, 0.25)
			tw_pulse.tween_property(drag_hint_lbl, "modulate:a", 1.0, 0.25)
			
		State.COMPLETED:
			step_label.text = "PROCEDIMIENTO COMPLETADO CON ÉXITO"
			status_label.text = "El pendrive contiene las herramientas y respaldos necesarios listos para el trabajo."
			drag_hint_lbl.text = "✓ PENDRIVE EXTRAÍDO DE FORMA SEGURA"
			drag_hint_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
			btn_toggle_connect.visible = false

# =============================================================================
# ARRASTRE DEL PENDRIVE (CONEXIÓN Y DESCONEXIÓN FÍSICA)
# =============================================================================
func _on_pendrive_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if current_state == State.CONNECT_USB or current_state == State.EJECT_USB:
				is_dragging_pendrive = true
				pendrive_drag_mouse_offset = pendrive_body.get_global_mouse_position().x - pendrive_body.position.x
		else:
			if is_dragging_pendrive:
				is_dragging_pendrive = false
				_handle_pendrive_release()
				
	elif event is InputEventMouseMotion and is_dragging_pendrive:
		var target_x = pendrive_body.get_global_mouse_position().x - pendrive_drag_mouse_offset
		if current_state == State.CONNECT_USB:
			pendrive_body.position.x = clampf(target_x, connected_pendrive_x, initial_pendrive_pos.x)
		elif current_state == State.EJECT_USB:
			pendrive_body.position.x = clampf(target_x, connected_pendrive_x, initial_pendrive_pos.x)

func _handle_pendrive_release() -> void:
	if current_state == State.CONNECT_USB:
		# Si se acercó o hizo clic en el pendrive
		if pendrive_body.position.x <= connected_pendrive_x + 120.0:
			var tw = create_tween()
			tw.tween_property(pendrive_body, "position:x", connected_pendrive_x, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			await tw.finished
			_trigger_usb_connected()
		else:
			# Si hizo un simple clic, conectarlo directamente de forma intuitiva
			var tw = create_tween()
			tw.tween_property(pendrive_body, "position:x", connected_pendrive_x, 0.2).set_trans(Tween.TRANS_QUAD)
			await tw.finished
			_trigger_usb_connected()
			
	elif current_state == State.EJECT_USB:
		# Si se arrastró o hizo clic para expulsar
		var tw = create_tween()
		tw.tween_property(pendrive_body, "position:x", initial_pendrive_pos.x, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tw.finished
		_trigger_usb_ejected()

func _trigger_usb_connected() -> void:
	is_usb_connected = true
	var tw_led = create_tween().set_loops(3)
	tw_led.tween_property(pendrive_led, "color", Color(0.1, 0.9, 1.0), 0.08)
	tw_led.tween_property(pendrive_led, "color", Color(0.2, 1.0, 0.5), 0.08)
	await tw_led.finished
	
	_show_toast("✓ ¡DISPOSITIVO RECONOCIDO! CyberDrive USB 3.2 montado en E:.")
	_update_state(State.DRAG_FILES)

func _trigger_usb_ejected() -> void:
	pendrive_led.color = Color(0.2, 0.2, 0.25)
	_update_state(State.COMPLETED)
	
	victory_banner.visible = false
	minigame_finished.emit(true)

# =============================================================================
# ARRASTRE DE ARCHIVOS (DRAG & DROP DE DATOS)
# =============================================================================
func _setup_files_ui() -> void:
	for child in local_files_vbox.get_children():
		child.queue_free()
	for child in usb_inventory_vbox.get_children():
		child.queue_free()
	file_cards.clear()
	
	for file in FILES_DATA:
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(0, 46)
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.06, 0.08, 0.12, 0.95)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.2, 0.6, 0.9, 0.8)
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_right = 6
		style.corner_radius_bottom_left = 6
		panel.add_theme_stylebox_override("panel", style)
		
		var lbl = Label.new()
		lbl.text = " %s (%s) [CLIC O ARRASTRA]\n  %s" % [file["name"], file["size"], file["desc"]]
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
		panel.add_child(lbl)
		
		var f_copy = file
		panel.gui_input.connect(func(ev: InputEvent): _on_file_item_gui_input(ev, f_copy, panel))
		local_files_vbox.add_child(panel)
		file_cards[file["id"]] = panel

func _on_file_item_gui_input(event: InputEvent, file: Dictionary, card_panel: PanelContainer) -> void:
	if file["transferred"] or current_state != State.DRAG_FILES:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging_file = true
			dragged_file_data = file
			drag_ghost.visible = true
			ghost_label.text = "📄 Arrastrando: %s [%s]" % [file["name"], file["size"]]
			drag_ghost.global_position = event.global_position - Vector2(120, 20)
			
			# Efecto de atenuación en la tarjeta de origen
			card_panel.modulate.a = 0.4
			
			# Iluminar zona de destino
			drop_zone_hint.modulate = Color(1.2, 1.2, 1.2, 1.0)
		else:
			if is_dragging_file:
				is_dragging_file = false
				card_panel.modulate.a = 1.0
				drag_ghost.visible = false
				drop_zone_hint.modulate = Color(1.0, 1.0, 1.0, 1.0)
				_check_file_drop(event.global_position)
				
	elif event is InputEventMouseMotion and is_dragging_file:
		drag_ghost.global_position = event.global_position - Vector2(120, 20)

func _check_file_drop(mouse_pos: Vector2) -> void:
	var right_col_rect = right_col.get_global_rect()
	var origin_rect = Rect2()
	if dragged_file_data and file_cards.has(dragged_file_data["id"]):
		origin_rect = file_cards[dragged_file_data["id"]].get_global_rect()
		
	# Aceptar arrastre hacia la derecha O clic directo sobre el archivo
	if right_col_rect.has_point(mouse_pos) or origin_rect.has_point(mouse_pos):
		_deposit_file_in_usb(dragged_file_data)
	else:
		_show_toast("Arrastra o haz clic en el archivo para copiarlo al pendrive.")

func _deposit_file_in_usb(file: Dictionary) -> void:
	if file["transferred"]:
		return
		
	file["transferred"] = true
	transferred_files_count += 1
	
	# Deshabilitar tarjeta de origen
	var card_origin = file_cards[file["id"]]
	card_origin.modulate.a = 0.45
	var lbl_origin: Label = card_origin.get_child(0)
	lbl_origin.text = " ✓ %s [TRANSFERIDO AL PENDRIVE]" % file["name"]
	lbl_origin.add_theme_color_override("font_color", Color(0.4, 0.7, 0.5))
	
	# Agregar al inventario de destino con animación
	var item_panel = PanelContainer.new()
	item_panel.custom_minimum_size = Vector2(0, 36)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.15, 0.2, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.2, 0.85, 0.6, 0.85)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	item_panel.add_theme_stylebox_override("panel", style)
	
	var lbl = Label.new()
	lbl.text = "  💾 %s  [%s]" % [file["name"], file["size"]]
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.6))
	item_panel.add_child(lbl)
	
	usb_inventory_vbox.add_child(item_panel)
	
	# Animación pop de llegada
	item_panel.scale = Vector2(0.85, 0.85)
	var tw = create_tween()
	tw.tween_property(item_panel, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	_show_toast("✓ '%s' soltado y listo en el pendrive." % file["name"])
	_update_storage_label()
	
	if transferred_files_count >= TOTAL_FILES:
		btn_start_transfer.disabled = false
		btn_start_transfer.modulate = Color(0.2, 1.0, 0.6)
		_show_toast("⚡ ¡4/4 archivos colocados! Presiona 'INICIAR ESCRITURA Y RESPALDO'.")

func _update_storage_label() -> void:
	var used_gb = 0.0
	for f in FILES_DATA:
		if f["transferred"]:
			used_gb += f["size_gb"]
	lbl_usb_storage.text = "ESPACIO UTILIZADO: %.2f GB / 64.00 GB  (%d / %d ARCHIVOS)" % [
		used_gb, transferred_files_count, TOTAL_FILES
	]

func _on_start_transfer_pressed() -> void:
	if is_transferring or transferred_files_count < TOTAL_FILES:
		return
	is_transferring = true
	_update_state(State.TRANSFERRING)
	
	var steps = [
		{"log": "▶ Escribiendo sectores de arranque GPT / UEFI en el MBR...", "progress": 18.0},
		{"log": "▶ Copiando imagen ISO de CyberOS a 185 MB/s...", "progress": 48.0},
		{"log": "▶ Transfiriendo archivo de volcado de base de datos...", "progress": 72.0},
		{"log": "▶ Transfiriendo paquetes de controladores y kit de rescate...", "progress": 90.0},
		{"log": "▶ Sincronizando búferes y verificando sumas hash SHA-256...", "progress": 100.0}
	]
	
	transfer_progress_bar.value = 0.0
	for s in steps:
		lbl_transfer_status.text = s["log"]
		pendrive_led.color = Color(1.0, 0.8, 0.2)
		var tw = create_tween()
		tw.tween_property(transfer_progress_bar, "value", s["progress"], 0.45)
		await tw.finished
		pendrive_led.color = Color(0.2, 1.0, 0.6)
		await get_tree().create_timer(0.2).timeout
		
	lbl_transfer_status.text = "✓ ¡DATOS ESCRITOS Y VERIFICADOS CON ÉXITO! Arrastra el pendrive hacia la derecha para extraerlo."
	lbl_transfer_status.add_theme_color_override("font_color", Color(0.2, 1.0, 0.6))
	is_transferring = false
	_update_state(State.EJECT_USB)

func _show_toast(msg: String) -> void:
	toast_label.text = msg
	toast_label.visible = true
	toast_label.modulate.a = 1.0
	var tw = create_tween()
	tw.tween_property(toast_label, "modulate:a", 0.0, 2.2).set_delay(1.2)
	tw.chain().tween_callback(func(): toast_label.visible = false)
