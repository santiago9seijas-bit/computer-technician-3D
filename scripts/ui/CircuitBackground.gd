extends Control

# Circuit traces and electrical pulses (Área de Reparación)
# Procedural copper tracks with 45-degree bends, solder joints,
# and traveling electrical sparks/pulses.

@export var base_color: Color = Color(1.0, 0.68, 0.2, 0.13)
@export var glow_color: Color = Color(1.0, 0.85, 0.35, 0.75)
@export var bus_color: Color = Color(1.0, 0.5, 0.1, 0.20)

var traces: Array[Dictionary] = []
var pulses: Array[Dictionary] = []
var pads: Array[Vector2] = []
var time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_generate_circuit_layout()

func _generate_circuit_layout() -> void:
	traces.clear()
	pulses.clear()
	pads.clear()
	
	var w = size.x if size.x > 100.0 else 1160.0
	var h = size.y if size.y > 100.0 else 720.0
	
	# Horizontal segmented copper bus lines
	var y_levels = [60.0, 115.0, 175.0, 235.0, 305.0, 375.0, 445.0, 515.0, 585.0, 650.0]
	for idx in range(y_levels.size()):
		var y = y_levels[idx]
		var pts = PackedVector2Array()
		var x = 25.0
		pts.append(Vector2(x, y))
		
		var bend1_x = 180.0 + float((idx * 73) % 260)
		var bend_offset = 26.0 if (idx % 2 == 0) else -26.0
		pts.append(Vector2(bend1_x, y))
		pts.append(Vector2(bend1_x + 32.0, y + bend_offset))
		
		var bend2_x = bend1_x + 240.0 + float((idx * 57) % 220)
		pts.append(Vector2(bend2_x, y + bend_offset))
		pts.append(Vector2(bend2_x + 36.0, y))
		pts.append(Vector2(w - 25.0, y))
		
		traces.append({
			"points": pts,
			"width": 2.0 if (idx % 3 != 0) else 3.5,
			"color": base_color if (idx % 3 != 0) else bus_color
		})
		
		pads.append(Vector2(bend1_x, y))
		pads.append(Vector2(bend1_x + 32.0, y + bend_offset))
		pads.append(Vector2(bend2_x, y + bend_offset))
		pads.append(Vector2(bend2_x + 36.0, y))
		
		# Pulso eléctrico viajero
		pulses.append({
			"trace_idx": idx,
			"t": fmod(float(idx) * 0.23, 1.0),
			"speed": 0.12 + float(idx % 4) * 0.04,
			"size": 4.0 if (idx % 3 != 0) else 6.0
		})
		
		if idx % 2 == 0:
			pulses.append({
				"trace_idx": idx,
				"t": fmod(float(idx) * 0.23 + 0.5, 1.0),
				"speed": 0.10 + float(idx % 3) * 0.03,
				"size": 3.5
			})

	# Líneas verticales de interconexión PCB
	var x_cols = [120.0, 310.0, 560.0, 820.0, 1040.0]
	for cx in x_cols:
		var pts_v = PackedVector2Array()
		pts_v.append(Vector2(cx, 45.0))
		pts_v.append(Vector2(cx, h - 45.0))
		traces.append({
			"points": pts_v,
			"width": 1.5,
			"color": Color(1.0, 0.75, 0.3, 0.08)
		})
		pads.append(Vector2(cx, 45.0))
		pads.append(Vector2(cx, h - 45.0))

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_generate_circuit_layout()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	time += delta
	for p in pulses:
		p.t += p.speed * delta
		if p.t > 1.0:
			p.t -= 1.0
	queue_redraw()

func _draw() -> void:
	for tr in traces:
		draw_polyline(tr.points, tr.color, tr.width)
		
	for pad in pads:
		draw_circle(pad, 3.5, Color(1.0, 0.75, 0.3, 0.22))
		draw_arc(pad, 4.5, 0.0, TAU, 12, Color(1.0, 0.85, 0.4, 0.35), 1.0)
		draw_circle(pad, 1.2, Color(0.08, 0.04, 0.02, 0.8))
		
	for p in pulses:
		var tr = traces[p.trace_idx]
		var pos = _sample_polyline(tr.points, p.t)
		var p_color = glow_color
		p_color.a *= (0.75 + 0.25 * sin(time * 10.0 + float(p.trace_idx)))
		
		draw_circle(pos, p.size * 2.2, Color(p_color.r, p_color.g, p_color.b, p_color.a * 0.25))
		draw_circle(pos, p.size, p_color)
		draw_circle(pos, p.size * 0.4, Color(1.0, 1.0, 0.9, 0.95))

func _sample_polyline(pts: PackedVector2Array, t: float) -> Vector2:
	if pts.size() == 0:
		return Vector2.ZERO
	if pts.size() == 1:
		return pts[0]
		
	var total_len = 0.0
	var seg_lens: Array[float] = []
	for i in range(pts.size() - 1):
		var l = pts[i].distance_to(pts[i + 1])
		seg_lens.append(l)
		total_len += l
		
	if total_len <= 0.001:
		return pts[0]
		
	var target_dist = clampf(t, 0.0, 1.0) * total_len
	var curr_dist = 0.0
	
	for i in range(pts.size() - 1):
		var sl = seg_lens[i]
		if curr_dist + sl >= target_dist:
			var seg_t = (target_dist - curr_dist) / maxf(sl, 0.0001)
			return pts[i].lerp(pts[i + 1], seg_t)
		curr_dist += sl
		
	return pts[pts.size() - 1]
