class_name HardwareMonitorOverlay
extends Control

# =============================================================================
# BARRA LATERAL COMPACTA DE TELEMETRÍA Y CONSUMO EN TIEMPO REAL
# Formato vertical estrecho (tira lateral) con métricas esenciales de hardware:
# FPS en vivo, Frame Time, Tiempos de CPU/Física, RAM, VRAM, Draw Calls y GPU.
# =============================================================================

@onready var panel_container: PanelContainer = $PanelContainer
@onready var lbl_fps: Label = $PanelContainer/Margin/VBox/FPSBlock/LblFPS
@onready var lbl_frame_time: Label = $PanelContainer/Margin/VBox/FPSBlock/LblFrameTime
@onready var lbl_cpu: Label = $PanelContainer/Margin/VBox/DataList/RowCPU/Val
@onready var lbl_phys: Label = $PanelContainer/Margin/VBox/DataList/RowPhys/Val
@onready var lbl_ram: Label = $PanelContainer/Margin/VBox/DataList/RowRAM/Val
@onready var lbl_vram: Label = $PanelContainer/Margin/VBox/DataList/RowVRAM/Val
@onready var lbl_draw: Label = $PanelContainer/Margin/VBox/DataList/RowDraw/Val
@onready var lbl_objs: Label = $PanelContainer/Margin/VBox/DataList/RowObjs/Val
@onready var lbl_device: Label = $PanelContainer/Margin/VBox/Footer/Val

var update_interval: float = 0.20 # 5 actualizaciones por segundo
var timer: float = 0.0

var smoothed_fps: float = 60.0
var cached_device_info: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cache_device_info()
	_update_metrics(0.016)

func _cache_device_info() -> void:
	var gpu_name = RenderingServer.get_video_adapter_name()
	if gpu_name != "":
		# Abreviar nombres largos de GPU para caber en barra lateral estrecha
		var clean_name = gpu_name.replace("Intel(R) HD Graphics", "Intel HD")\
			.replace("Intel(R) UHD Graphics", "Intel UHD")\
			.replace("NVIDIA GeForce", "GTX/RTX")\
			.replace("AMD Radeon", "Radeon")
		if clean_name.length() > 14:
			clean_name = clean_name.substr(0, 14)
		cached_device_info = clean_name
	else:
		cached_device_info = OS.get_name()
	
	if lbl_device:
		lbl_device.text = cached_device_info

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	# Suavizado de FPS real por cuadro para filtrar hipos aislados de cambio de escena
	if delta > 0.0001 and delta < 0.10:
		var cur_fps = 1.0 / delta
		smoothed_fps = lerp(smoothed_fps, cur_fps, 0.2)
	# Si delta >= 0.10, es un salto puntual de carga de escena en disco: ignorarlo para no arrastrar caídas artificiales
		
	timer += delta
	if timer >= update_interval:
		timer = 0.0
		_update_metrics(delta)

func _update_metrics(_delta: float) -> void:
	var engine_fps = Engine.get_frames_per_second()
	var display_fps = int(round(smoothed_fps)) if (engine_fps < 25 and smoothed_fps >= 35) else engine_fps
	display_fps = max(1, display_fps)

	var process_time_ms = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var physics_time_ms = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var ram_mb = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)
	var vram_mb = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / (1024.0 * 1024.0)
	var draw_calls = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var obj_count = int(Performance.get_monitor(Performance.OBJECT_COUNT))

	# 1. FPS y Frame Time
	if lbl_fps:
		lbl_fps.text = "%d FPS" % display_fps
		if display_fps >= 55:
			lbl_fps.add_theme_color_override("font_color", Color(0.15, 1.0, 0.45, 1.0)) # Verde
		elif display_fps >= 35:
			lbl_fps.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15, 1.0)) # Amarillo
		else:
			lbl_fps.add_theme_color_override("font_color", Color(1.0, 0.25, 0.3, 1.0))  # Rojo

	if lbl_frame_time:
		var ft_ms = 1000.0 / maxf(float(display_fps), 1.0)
		lbl_frame_time.text = "%.1f ms" % ft_ms

	# 2. Métricas de Hardware
	if lbl_cpu:
		lbl_cpu.text = "%.1fms" % process_time_ms
	if lbl_phys:
		lbl_phys.text = "%.1fms" % physics_time_ms
	if lbl_ram:
		lbl_ram.text = "%.0fM" % ram_mb
	if lbl_vram:
		lbl_vram.text = "%.0fM" % vram_mb
	if lbl_draw:
		lbl_draw.text = "%d" % draw_calls
	if lbl_objs:
		lbl_objs.text = "%d" % obj_count
