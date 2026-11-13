extends Control

# Datacenter Rack Telemetry Background (Área de Servidores)
# Features fiber-optic high-speed data buses, active rack LED arrays,
# and subtle throughput waveforms in electric violet and cyan.

@export var rail_color: Color = Color(0.68, 0.35, 1.0, 0.12)
@export var fiber_color: Color = Color(0.15, 0.85, 1.0, 0.22)
@export var packet_color: Color = Color(0.3, 0.95, 1.0, 0.85)

var font: Font = null
var time: float = 0.0
var packets: Array[Dictionary] = []
var led_arrays: Array[Dictionary] = []

var _cached_rails: PackedVector2Array = PackedVector2Array()
var _cached_fibers: PackedVector2Array = PackedVector2Array()
var _cached_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://assets/fonts/JetBrainsMono-Bold.ttf"):
		font = load("res://assets/fonts/JetBrainsMono-Bold.ttf")
	_init_datacenter_layout()

func _init_datacenter_layout() -> void:
	packets.clear()
	led_arrays.clear()
	_cached_rails.clear()
	_cached_fibers.clear()
	
	var w: float = size.x if size.x > 100.0 else 1160.0
	var h: float = size.y if size.y > 100.0 else 720.0
	_cached_size = Vector2(w, h)
	
	# Precalcular rieles de rack
	var rail_positions = [18.0, 72.0, w - 72.0, w - 18.0]
	for rx in rail_positions:
		_cached_rails.append(Vector2(rx, 30.0))
		_cached_rails.append(Vector2(rx, h - 30.0))
		for u in range(12):
			var uy: float = 70.0 + float(u) * 50.0
			_cached_rails.append(Vector2(rx - 4.0, uy))
			_cached_rails.append(Vector2(rx + 4.0, uy))
	
	# Horizontal fiber optic data beams across rack levels
	var y_lanes = [80.0, 175.0, 270.0, 365.0, 460.0, 555.0, 650.0]
	for idx in range(y_lanes.size()):
		var lane_y: float = y_lanes[idx]
		_cached_fibers.append(Vector2(75.0, lane_y))
		_cached_fibers.append(Vector2(w - 75.0, lane_y))
		
		var count: int = 2 if (idx % 2 == 0) else 3
		for p in range(count):
			packets.append({
				"lane_y": lane_y,
				"t": (float(p) / float(count)) + randf_range(0.04, 0.12),
				"speed": randf_range(0.25, 0.52),
				"len": randf_range(30.0, 65.0),
				"color": packet_color if (idx % 2 == 0) else Color(0.85, 0.45, 1.0, 0.85)
			})
			
	# Vertical LED activity arrays on server rack flanks
	var led_x_positions = [28.0, 54.0, w - 54.0, w - 28.0]
	for lx in led_x_positions:
		var leds = []
		var count: int = int((h - 120.0) / 18.0)
		for j in range(count):
			leds.append({
				"y": 70.0 + float(j) * 18.0,
				"blink_speed": randf_range(4.0, 16.0),
				"offset": randf() * TAU,
				"base_color": Color(0.2, 1.0, 0.5) if (j % 4 != 0) else Color(0.2, 0.85, 1.0)
			})
		led_arrays.append({
			"x": lx,
			"leds": leds
		})

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_init_datacenter_layout()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	time += delta
	for pkt in packets:
		pkt.t += pkt.speed * delta
		if pkt.t > 1.2:
			pkt.t = -0.2
			pkt.speed = randf_range(0.25, 0.52)
	queue_redraw()

func _draw() -> void:
	var w: float = size.x if size.x > 100.0 else 1160.0
	var h: float = size.y if size.y > 100.0 else 720.0
	
	if _cached_size != Vector2(w, h) or _cached_rails.is_empty():
		_init_datacenter_layout()
	
	# Rack vertical guide rails (batched)
	if not _cached_rails.is_empty():
		draw_multiline(_cached_rails, rail_color, 1.8)
			
	# Horizontal fiber optic data beams (batched)
	if not _cached_fibers.is_empty():
		draw_multiline(_cached_fibers, fiber_color, 1.5)
		
	# High-speed data packets
	for pkt in packets:
		var px_start: float = lerpf(75.0, w - 75.0, pkt.t)
		var px_end: float = px_start + pkt.len
		if px_end > 75.0 and px_start < (w - 75.0):
			var x1: float = clampf(px_start, 75.0, w - 75.0)
			var x2: float = clampf(px_end, 75.0, w - 75.0)
			var col: Color = pkt.color
			draw_line(Vector2(x1, pkt.lane_y), Vector2(x2, pkt.lane_y), Color(col.r, col.g, col.b, col.a * 0.3), 5.0)
			draw_line(Vector2(x1, pkt.lane_y), Vector2(x2, pkt.lane_y), col, 2.0)
			draw_circle(Vector2(x2, pkt.lane_y), 3.0, Color(1.0, 1.0, 1.0, 0.95))

	# LED activity lights on server sidebars
	for l_arr in led_arrays:
		var lx: float = l_arr.x
		for led in l_arr.leds:
			var pulse: float = sin(time * led.blink_speed + led.offset)
			var is_on: bool = pulse > 0.1
			var c: Color = led.base_color if is_on else Color(0.1, 0.15, 0.25, 0.3)
			var alpha: float = 0.85 if is_on else 0.25
			draw_circle(Vector2(lx, led.y), 2.5, Color(c.r, c.g, c.b, alpha))
			if is_on:
				draw_circle(Vector2(lx, led.y), 4.5, Color(c.r, c.g, c.b, 0.25))

	# Telemetry network throughput waveform at bottom
	var wave_pts = PackedVector2Array()
	var wave_y_base: float = h - 68.0
	var seg_count: int = 32
	var step: float = (w - 180.0) / float(seg_count)
	for i in range(seg_count + 1):
		var wx: float = 90.0 + float(i) * step
		var wave_amp: float = sin(time * 3.5 + float(i) * 0.45) * 7.0 + sin(time * 7.0 + float(i) * 0.9) * 3.5
		wave_pts.append(Vector2(wx, wave_y_base + wave_amp))
	draw_polyline(wave_pts, Color(0.7, 0.35, 1.0, 0.22), 1.5)
