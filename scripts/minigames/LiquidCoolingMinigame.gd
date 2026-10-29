extends CanvasLayer

# =============================================================================
# MINIJUEGO: REFRIGERACIÓN LÍQUIDA CUSTOM LOOP COMPLETO
# Mecánicas avanzadas:
# 1. Mapeado de componentes calientes: GPU, CPU, RAM + Radiador 360mm y Bomba D5.
# 2. Montaje tubo a tubo arrastrando piezas desde el rack hacia sus racores:
#    - Tubo 1: Bomba D5 ➔ Bloque Full-Cover de GPU
#    - Tubo 2: Salida GPU ➔ Bloque Acrílico de CPU
#    - Tubo 3: Salida CPU ➔ Bloque de Memoria RAM
#    - Tubo 4: Salida RAM ➔ Radiador Superior 360mm
#    - Tubo 5: Radiador ➔ Depósito/Bomba (Cierre hermético del circuito)
# 3. Llenado interactivo con bidón de refrigerante cian premix al 100%.
# 4. Encendido de bomba D5: purgado de burbujas, flujo laminar activo y
#    caída térmica simultánea en GPU, CPU y RAM.
# =============================================================================

signal minigame_finished(success: bool)

enum Phase {
	TUBES_SETUP,
	FILL_COOLANT,
	START_PUMP,
	COMPLETED
}

var current_phase: Phase = Phase.TUBES_SETUP

# Estado de tubos (5 tramos)
var tubes_connected: Array[bool] = [false, false, false, false, false]
var active_drag_tube_idx: int = -1
var is_dragging_tube: bool = false
var tube_drag_offset: Vector2 = Vector2.ZERO

# Estado de bidón de llenado
var is_dragging_jug: bool = false
var jug_drag_offset: Vector2 = Vector2.ZERO
var jug_start_pos: Vector2 = Vector2.ZERO
var coolant_level_pct: float = 0.0
var is_jug_over_fillport: bool = false

# Estado de bomba y telemetría
var is_pump_running: bool = false

# Nodos UI principales
@onready var modal_control: Control = $ModalControl
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var phase_tracker: Label = $ModalControl/Panel/VBox/Header/PhaseTracker
@onready var telemetry_label: Label = $ModalControl/Panel/VBox/Header/TelemetryLabel
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel

@onready var work_area: Control = $ModalControl/Panel/VBox/WorkArea
@onready var tubes_rack: Panel = $ModalControl/Panel/VBox/WorkArea/TubesRack
@onready var chassis_frame: Panel = $ModalControl/Panel/VBox/WorkArea/ChassisFrame
@onready var drag_ghost: Panel = $ModalControl/Panel/VBox/WorkArea/DragGhost
@onready var ghost_label: Label = $ModalControl/Panel/VBox/WorkArea/DragGhost/GhostLabel
@onready var warning_label: Label = $ModalControl/Panel/VBox/WorkArea/WarningLabel

# Componentes calientes en el chasis
@onready var radiator_panel: Panel = $ModalControl/Panel/VBox/WorkArea/ChassisFrame/Radiator
@onready var cpu_temp_lbl: Label = $ModalControl/Panel/VBox/WorkArea/ChassisFrame/CPUBlock/Temp
@onready var ram_temp_lbl: Label = $ModalControl/Panel/VBox/WorkArea/ChassisFrame/RAMBlock/Temp
@onready var gpu_temp_lbl: Label = $ModalControl/Panel/VBox/WorkArea/ChassisFrame/GPUBlock/Temp

# Depósito y Bomba
@onready var reservoir_panel: Panel = $ModalControl/Panel/VBox/WorkArea/ChassisFrame/Reservoir
@onready var reservoir_liquid: ColorRect = $ModalControl/Panel/VBox/WorkArea/ChassisFrame/Reservoir/Cylinder/LiquidLevel
@onready var reservoir_level_label: Label = $ModalControl/Panel/VBox/WorkArea/ChassisFrame/Reservoir/LevelLabel
@onready var fill_port_area: Control = $ModalControl/Panel/VBox/WorkArea/ChassisFrame/Reservoir/FillPortArea

# Bidón
@onready var coolant_jug: Panel = $ModalControl/Panel/VBox/WorkArea/CoolantJug

# Controles de Bomba
@onready var pump_control_box: Panel = $ModalControl/Panel/VBox/WorkArea/PumpControlBox
@onready var btn_start_pump: Button = $ModalControl/Panel/VBox/WorkArea/PumpControlBox/BtnStartPump
@onready var pump_status_lbl: Label = $ModalControl/Panel/VBox/WorkArea/PumpControlBox/PumpStatusLbl

# Listas de elementos de tubos
var tube_items: Array[Panel] = []
var tube_item_statuses: Array[Label] = []
var tube_sockets: Array[ColorRect] = []
var tube_graphics: Array[CanvasItem] = []

var tube_names: Array[String] = [
	"1. Bomba ➔ GPU",
	"2. GPU ➔ CPU",
	"3. CPU ➔ RAM",
	"4. RAM ➔ Radiador",
	"5. Radiador ➔ Depósito"
]

var tube_color_empty = Color(0.2, 0.45, 0.65, 0.4)
var tube_color_flowing = Color(0.05, 0.95, 0.95, 0.95)

func _ready() -> void:
	layer = 12
	_setup_ui()
	_update_status()

func _setup_ui() -> void:
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	
	# Inicializar los 5 items del rack de tubos
	tube_items.clear()
	tube_item_statuses.clear()
	for i in range(5):
		var item = tubes_rack.get_node_or_null("RackVBox/TubeItem" + str(i)) as Panel
		if item:
			tube_items.append(item)
			var st = item.get_node_or_null("Status") as Label
			tube_item_statuses.append(st)
			item.gui_input.connect(_on_tube_item_gui_input.bind(i))
	
	# Inicializar los 5 sockets/zonas de acople en el chasis
	tube_sockets.clear()
	for i in range(5):
		var sock = chassis_frame.get_node_or_null("Sockets/Socket" + str(i)) as ColorRect
		if sock:
			tube_sockets.append(sock)
			sock.visible = true
			sock.modulate.a = 0.5
	
	# Inicializar los gráficos de tubos
	tube_graphics.clear()
	tube_graphics.append(chassis_frame.get_node_or_null("Tubes/Tube0"))
	tube_graphics.append(chassis_frame.get_node_or_null("Tubes/Tube1"))
	tube_graphics.append(chassis_frame.get_node_or_null("Tubes/Tube2"))
	tube_graphics.append(chassis_frame.get_node_or_null("Tubes/Tube3"))
	# El tramo 5 tiene parte H y parte V
	var t4h = chassis_frame.get_node_or_null("Tubes/Tube4_H")
	var t4v = chassis_frame.get_node_or_null("Tubes/Tube4_V")
	tube_graphics.append(t4h) # usaremos t4h y t4v juntos
	
	for tg in tube_graphics:
		if tg:
			tg.visible = false
	if t4v:
		t4v.visible = false
		
	drag_ghost.visible = false
	
	# Bidón interactivo
	jug_start_pos = coolant_jug.position
	coolant_jug.gui_input.connect(_on_jug_gui_input)
	coolant_jug.visible = false
	
	reservoir_liquid.size.y = 0.0
	reservoir_liquid.position.y = 202.0
	reservoir_level_label.text = "0%"
	
	# Bomba
	pump_control_box.visible = false
	btn_start_pump.pressed.connect(_on_start_pump_pressed)
	
	warning_label.text = ""

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_ESCAPE:
			minigame_finished.emit(false)

# =============================================================================
# FASE 1: ARRASTRE Y ACOPLE DE TUBOS (DRAG & DROP TUBO A TUBO)
# =============================================================================
func _on_tube_item_gui_input(event: InputEvent, tube_idx: int) -> void:
	if current_phase != Phase.TUBES_SETUP or tubes_connected[tube_idx]:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_dragging_tube(tube_idx)
			else:
				if is_dragging_tube and active_drag_tube_idx == tube_idx:
					_stop_dragging_tube()
					
	elif event is InputEventMouseMotion and is_dragging_tube and active_drag_tube_idx == tube_idx:
		drag_ghost.global_position = drag_ghost.get_global_mouse_position() - tube_drag_offset

func _start_dragging_tube(tube_idx: int) -> void:
	is_dragging_tube = true
	active_drag_tube_idx = tube_idx
	ghost_label.text = "ACOPLAR: " + tube_names[tube_idx]
	drag_ghost.visible = true
	tube_drag_offset = Vector2(80.0, 20.0)
	drag_ghost.global_position = drag_ghost.get_global_mouse_position() - tube_drag_offset
	
	# Resaltar la zona de acople en el chasis
	if tube_idx < tube_sockets.size():
		var sock = tube_sockets[tube_idx]
		sock.color = Color(1.0, 0.85, 0.2, 0.45)
		var tw = create_tween().set_loops(4)
		tw.tween_property(sock, "modulate:a", 1.0, 0.15)
		tw.tween_property(sock, "modulate:a", 0.4, 0.15)

func _stop_dragging_tube() -> void:
	if not is_dragging_tube or active_drag_tube_idx < 0:
		return
		
	var tube_idx = active_drag_tube_idx
	is_dragging_tube = false
	active_drag_tube_idx = -1
	drag_ghost.visible = false
	
	# Restaurar socket normal
	if tube_idx < tube_sockets.size():
		tube_sockets[tube_idx].color = Color(0.1, 0.8, 1.0, 0.15)
		tube_sockets[tube_idx].modulate.a = 0.5
		
	# Comprobar si el cursor cayó dentro o cerca del socket correspondiente
	var sock = tube_sockets[tube_idx]
	var sock_rect = sock.get_global_rect().grow(45.0) # Margen de tolerancia de 45px
	var mouse_pos = modal_control.get_global_mouse_position()
	
	if sock_rect.has_point(mouse_pos):
		_install_tube(tube_idx)
	else:
		_show_warning("Suelta el " + tube_names[tube_idx] + " sobre su acople parpadeante en el chasis.", Color(1.0, 0.35, 0.35))

func _install_tube(idx: int) -> void:
	tubes_connected[idx] = true
	
	# Actualizar item en el rack
	if idx < tube_items.size():
		tube_items[idx].modulate = Color(0.5, 0.7, 0.8, 0.6)
		if idx < tube_item_statuses.size():
			tube_item_statuses[idx].text = "✓ [ACOPLADO]"
			tube_item_statuses[idx].modulate = Color(0.2, 1.0, 0.4)
			
	# Ocultar socket de guía
	if idx < tube_sockets.size():
		tube_sockets[idx].visible = false
		
	# Mostrar gráfico del tubo acoplado con animación de snap
	if idx < tube_graphics.size():
		var tg = tube_graphics[idx]
		if tg:
			tg.visible = true
			tg.modulate.a = 0.0
			var tw = create_tween()
			tw.tween_property(tg, "modulate:a", 1.0, 0.25)
	if idx == 4:
		var t4v = chassis_frame.get_node_or_null("Tubes/Tube4_V") as CanvasItem
		if t4v:
			t4v.visible = true
			t4v.modulate.a = 0.0
			var tw_v = create_tween()
			tw_v.tween_property(t4v, "modulate:a", 1.0, 0.25)
			
	_show_warning("✓ ¡CLICK! " + tube_names[idx] + " fijado con racores G1/4 de compresión.", Color(0.2, 1.0, 0.5))
	
	# Verificar si todos los tubos están conectados
	var connected_count = 0
	for c in tubes_connected:
		if c: connected_count += 1
		
	if connected_count >= 5:
		_complete_all_tubes()
	else:
		_update_status()

func _complete_all_tubes() -> void:
	_show_warning("✓ ¡CIRCUITO DE FLUIDO CERRADO HERMÉTICAMENTE! Pasando a fase de llenado...", Color(0.2, 1.0, 0.4))
	
	# Efecto visual en todo el circuito
	for tg in tube_graphics:
		if tg:
			var tw_flash = create_tween()
			tw_flash.tween_property(tg, "modulate", Color(1.5, 1.5, 1.5), 0.15)
			tw_flash.tween_property(tg, "modulate", Color(1.0, 1.0, 1.0), 0.2)
			
	await get_tree().create_timer(0.6).timeout
	
	# Transición a Fase 2: Ocultar rack de tubos y mostrar bidón de llenado
	current_phase = Phase.FILL_COOLANT
	var tw_rack = create_tween()
	tw_rack.tween_property(tubes_rack, "modulate:a", 0.0, 0.3)
	await tw_rack.finished
	tubes_rack.visible = false
	
	coolant_jug.visible = true
	coolant_jug.modulate.a = 0.0
	var tw_jug = create_tween()
	tw_jug.tween_property(coolant_jug, "modulate:a", 1.0, 0.35)
	
	_update_status()

# =============================================================================
# FASE 2: LLENADO CON BIDÓN ARRASTRABLE AL TAPÓN DE LA BOMBA
# =============================================================================
func _on_jug_gui_input(event: InputEvent) -> void:
	if current_phase != Phase.FILL_COOLANT:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging_jug = true
				jug_drag_offset = coolant_jug.get_global_mouse_position() - coolant_jug.global_position
			else:
				is_dragging_jug = false
				_check_jug_drop()
				
	elif event is InputEventMouseMotion and is_dragging_jug:
		coolant_jug.global_position = coolant_jug.get_global_mouse_position() - jug_drag_offset
		_check_jug_hover_fill()

func _check_jug_hover_fill() -> void:
	var jug_rect = coolant_jug.get_global_rect()
	var fill_rect = fill_port_area.get_global_rect().grow(30.0)
	
	if jug_rect.intersects(fill_rect):
		if not is_jug_over_fillport:
			is_jug_over_fillport = true
			var tw_tilt = create_tween()
			tw_tilt.tween_property(coolant_jug, "rotation_degrees", -35.0, 0.2)
			
		# Llenar el depósito gradualmente mientras se mantenga encima
		coolant_level_pct += 1.6
		if coolant_level_pct > 100.0:
			coolant_level_pct = 100.0
			
		_update_reservoir_level_visual()
		
		if coolant_level_pct >= 100.0:
			_complete_filling()
	else:
		if is_jug_over_fillport:
			is_jug_over_fillport = false
			var tw_straight = create_tween()
			tw_straight.tween_property(coolant_jug, "rotation_degrees", 0.0, 0.15)

func _check_jug_drop() -> void:
	if coolant_level_pct < 100.0:
		var tw = create_tween()
		tw.tween_property(coolant_jug, "position", jug_start_pos, 0.3).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(coolant_jug, "rotation_degrees", 0.0, 0.15)

func _update_reservoir_level_visual() -> void:
	var max_height = 200.0
	var h = (coolant_level_pct / 100.0) * max_height
	reservoir_liquid.size.y = h
	reservoir_liquid.position.y = 202.0 - h
	reservoir_level_label.text = "%d%%" % int(coolant_level_pct)
	reservoir_liquid.color = Color(0.05, 0.95, 0.85, 0.88)

func _complete_filling() -> void:
	is_dragging_jug = false
	var tw = create_tween().set_parallel(true)
	tw.tween_property(coolant_jug, "position:x", jug_start_pos.x + 80.0, 0.4)
	tw.tween_property(coolant_jug, "modulate:a", 0.0, 0.4)
	
	_show_warning("✓ ¡Depósito lleno al 100%! Tapón superior roscado y sellado a presión.", Color(0.2, 1.0, 0.4))
	
	current_phase = Phase.START_PUMP
	pump_control_box.visible = true
	pump_control_box.modulate.a = 0.0
	var tw_p = create_tween()
	tw_p.tween_property(pump_control_box, "modulate:a", 1.0, 0.3)
	_update_status()

# =============================================================================
# FASE 3: ENCENDIDO DE BOMBA Y PURGADO DEL CIRCUITO (LOOP BLEEDING)
# =============================================================================
func _on_start_pump_pressed() -> void:
	if is_pump_running:
		return
		
	is_pump_running = true
	btn_start_pump.disabled = true
	btn_start_pump.text = "⚡ BOMBA D5 ACTIVA"
	pump_status_lbl.text = "PURGANDO BURBUJAS // FLUJO ACTIVO"
	pump_status_lbl.modulate = Color(0.2, 1.0, 0.5)
	
	# Animación secuencial del fluido circulando a través de todos los componentes
	var tw = create_tween()
	
	# Tramo 1: Bomba a GPU
	tw.tween_property(tube_graphics[0], "color", tube_color_flowing, 0.3)
	tw.tween_callback(func():
		_show_warning("🌊 Líquido refrigerante entrando al bloque de la GPU...", Color(0.2, 0.9, 1.0))
		_animate_temp_drop(gpu_temp_lbl, 79.0, 32.5, "GPU")
	)
	
	# Tramo 2: GPU a CPU
	tw.tween_property(tube_graphics[1], "color", tube_color_flowing, 0.3)
	tw.tween_callback(func():
		_show_warning("🌊 Líquido refrigerante enfriando los micro-canales de la CPU...", Color(0.2, 0.9, 1.0))
		_animate_temp_drop(cpu_temp_lbl, 86.0, 28.0, "CPU")
	)
	
	# Tramo 3: CPU a RAM
	tw.tween_property(tube_graphics[2], "color", tube_color_flowing, 0.25)
	tw.tween_callback(func():
		_show_warning("🌊 Líquido circulando a través de los disipadores de la RAM...", Color(0.85, 0.4, 1.0))
		_animate_temp_drop(ram_temp_lbl, 64.0, 29.5, "RAM")
	)
	
	# Tramo 4: RAM a Radiador
	tw.tween_property(tube_graphics[3], "color", tube_color_flowing, 0.3)
	tw.tween_callback(func():
		_show_warning("🌊 Expulsando calor residual por el radiador 360mm...", Color(0.2, 0.9, 1.0))
	)
	
	# Tramo 5: Radiador a Depósito (cierre)
	tw.tween_property(tube_graphics[4], "color", tube_color_flowing, 0.25)
	var t4v = chassis_frame.get_node_or_null("Tubes/Tube4_V") as ColorRect
	if t4v:
		tw.tween_property(t4v, "color", tube_color_flowing, 0.2)
		
	await tw.finished
	
	# Telemetría final en vivo
	telemetry_label.text = "CAUDAL: 4.2 L/min · RPM: 4500 · CPU: 28.0°C · RAM: 29.5°C · GPU: 32.5°C (100% REFRIGERADO ✓)"
	telemetry_label.modulate = Color(0.2, 1.0, 0.5)
	
	current_phase = Phase.COMPLETED
	_show_warning("✓ ¡CIRCUITO CUSTOM LOOP PURGADO CON ÉXITO! Disipación térmica óptima.", Color(0.2, 1.0, 0.4))
	_update_status()
	
	await get_tree().create_timer(2.2).timeout
	minigame_finished.emit(true)

func _animate_temp_drop(label: Label, start_val: float, end_val: float, _comp_name: String) -> void:
	var tw = create_tween()
	tw.tween_method(func(val: float):
		label.text = "%.1f°C" % val
		if val <= 40.0:
			label.modulate = Color(0.2, 1.0, 0.6)
		elif val <= 60.0:
			label.modulate = Color(1.0, 0.85, 0.2)
		else:
			label.modulate = Color(1.0, 0.3, 0.3)
	, start_val, end_val, 1.2)

func _show_warning(msg: String, col: Color) -> void:
	warning_label.text = msg
	warning_label.modulate = col
	var tw = create_tween()
	tw.tween_property(warning_label, "scale", Vector2(1.04, 1.04), 0.08)
	tw.tween_property(warning_label, "scale", Vector2(1.0, 1.0), 0.1)

func _update_status() -> void:
	match current_phase:
		Phase.TUBES_SETUP:
			var connected_count = 0
			for c in tubes_connected:
				if c: connected_count += 1
			phase_tracker.text = "FASE 1/3: MONTAJE DE TUBOS RÍGIDOS (%d/5 INSTALADOS)" % connected_count
			status_label.text = "Arrastra cada tubo desde el rack izquierdo hacia sus racores en el mapa del chasis."
			status_label.modulate = Color(1.0, 0.85, 0.2)
		Phase.FILL_COOLANT:
			phase_tracker.text = "FASE 2/3: LLENADO DE LÍQUIDO REFRIGERANTE"
			status_label.text = "Arrastra el bidón de líquido sobre la boca de llenado del depósito hasta alcanzar el 100%."
			status_label.modulate = Color(0.2, 0.9, 1.0)
		Phase.START_PUMP:
			phase_tracker.text = "FASE 3/3: ENCENDIDO DE BOMBA Y PURGADO"
			status_label.text = "Presiona 'ENCENDER BOMBA D5' para activar el flujo y disipar calor en GPU, CPU y RAM."
			status_label.modulate = Color(1.0, 0.3, 0.7)
		Phase.COMPLETED:
			phase_tracker.text = "¡CIRCUITO DE REFRIGERACIÓN LÍQUIDA OPERATIVO! ✓"
			status_label.text = "Has dominado el montaje completo de un Custom Watercooling Loop profesional."
			status_label.modulate = Color(0.2, 1.0, 0.4)
