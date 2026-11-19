extends Control

var anim_time: float = 0.0
var nodes: Array[Dictionary] = []
var data_packets: Array[Dictionary] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_generate_circuit_nodes()

func _generate_circuit_nodes() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 2026
	nodes.clear()
	data_packets.clear()
	
	# Generar puntos de nodo de circuito en la pantalla
	for i in range(28):
		nodes.append({
			"pos": Vector2(rng.randf(), rng.randf()),
			"size": rng.randf_range(2.5, 5.0),
			"pulse_speed": rng.randf_range(1.5, 3.5),
			"pulse_offset": rng.randf_range(0.0, 6.28),
			"color_type": rng.randi() % 3 # 0: Cyan, 1: Emerald, 2: Slate
		})
		
	# Generar paquetes de datos que viajan por las conexiones
	for i in range(16):
		var src_idx = rng.randi() % nodes.size()
		var dst_idx = (src_idx + 1 + (rng.randi() % 5)) % nodes.size()
		data_packets.append({
			"src": src_idx,
			"dst": dst_idx,
			"progress": rng.randf(),
			"speed": rng.randf_range(0.2, 0.55),
			"length": rng.randf_range(12.0, 24.0)
		})

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	anim_time += delta
	
	for pkt in data_packets:
		pkt["progress"] += delta * pkt["speed"]
		if pkt["progress"] > 1.0:
			pkt["progress"] = 0.0
			pkt["src"] = randi() % nodes.size()
			pkt["dst"] = (pkt["src"] + 1 + (randi() % 5)) % nodes.size()
			
	queue_redraw()

func _draw() -> void:
	var w = size.x
	var h = size.y
	if w <= 10.0 or h <= 10.0:
		return
		
	# 1. Gradiente de fondo en azules profundos, verde cian y gris pizarra
	var c_top = Color(0.015, 0.04, 0.09, 0.95)
	var c_mid = Color(0.03, 0.08, 0.08, 0.96)
	var c_bot = Color(0.02, 0.03, 0.05, 0.97)
	
	draw_rect(Rect2(0, 0, w, h * 0.5), c_top, true)
	draw_rect(Rect2(0, h * 0.5, w, h * 0.5), c_mid, true)
	
	# Banda de resplandor esmeralda/azul en el centro
	var band_y = h * 0.35
	var band_h = h * 0.3
	draw_rect(Rect2(0, band_y, w, band_h), Color(0.0, 0.35, 0.28, 0.12), true)
	
	# 2. Grilla digital técnica (Cuadrícula fina en tonos grisáceos y cian)
	var grid_step = 64.0
	var grid_col = Color(0.12, 0.35, 0.42, 0.18)
	var offset_y = fmod(anim_time * 12.0, grid_step)
	
	for x in range(0, int(w), int(grid_step)):
		draw_line(Vector2(x, 0), Vector2(x, h), grid_col, 1.0)
		
	for y in range(0, int(h + grid_step), int(grid_step)):
		var actual_y = y - offset_y
		if actual_y >= 0 and actual_y <= h:
			draw_line(Vector2(0, actual_y), Vector2(w, actual_y), grid_col, 1.0)
			
	# 3. Dibujar circuitos y conexiones entre nodos
	var cyan_col = Color(0.0, 0.85, 1.0, 0.28)
	var green_col = Color(0.0, 0.95, 0.65, 0.28)
	var gray_col = Color(0.45, 0.55, 0.65, 0.22)
	
	for i in range(nodes.size()):
		var n1 = nodes[i]
		var p1 = Vector2(n1["pos"].x * w, n1["pos"].y * h)
		
		# Conectar con algunos nodos vecinos
		for step in [1, 2]:
			var j = (i + step) % nodes.size()
			var n2 = nodes[j]
			var p2 = Vector2(n2["pos"].x * w, n2["pos"].y * h)
			
			if p1.distance_to(p2) < w * 0.38:
				# Trazar línea en ángulo recto estilo circuito PCB
				var corner = Vector2(p2.x, p1.y)
				draw_line(p1, corner, gray_col, 1.0)
				draw_line(corner, p2, gray_col, 1.0)
				
	# 4. Paquetes de pulsos de datos en movimiento
	for pkt in data_packets:
		var n_src = nodes[pkt["src"]]
		var n_dst = nodes[pkt["dst"]]
		var p_src = Vector2(n_src["pos"].x * w, n_src["pos"].y * h)
		var p_dst = Vector2(n_dst["pos"].x * w, n_dst["pos"].y * h)
		var corner = Vector2(p_dst.x, p_src.y)
		
		var t = pkt["progress"]
		var current_p: Vector2
		if t < 0.5:
			var seg_t = t * 2.0
			current_p = p_src.lerp(corner, seg_t)
		else:
			var seg_t = (t - 0.5) * 2.0
			current_p = corner.lerp(p_dst, seg_t)
			
		var glow_c = Color(0.0, 1.0, 0.75, 0.7)
		draw_circle(current_p, 2.5, glow_c)
		draw_circle(current_p, 1.2, Color.WHITE)
		
	# 5. Dibujar nodos de circuito con pulsación de brillo
	for n in nodes:
		var p = Vector2(n["pos"].x * w, n["pos"].y * h)
		var pulse = (sin(anim_time * n["pulse_speed"] + n["pulse_offset"]) + 1.0) * 0.5
		
		var base_c: Color
		match n["color_type"]:
			0: base_c = Color(0.0, 0.85, 1.0, 0.4 + pulse * 0.5)
			1: base_c = Color(0.0, 0.95, 0.55, 0.4 + pulse * 0.5)
			_: base_c = Color(0.5, 0.65, 0.75, 0.3 + pulse * 0.4)
			
		# Halo y núcleo
		draw_circle(p, n["size"] * (1.2 + pulse * 0.4), Color(base_c.r, base_c.g, base_c.b, 0.25))
		draw_circle(p, n["size"] * 0.6, base_c)
		draw_circle(p, 1.2, Color(1.0, 1.0, 1.0, 0.8))
		
	# 6. Línea de barrido de radar/scanner suave
	var scan_y = fmod(anim_time * 85.0, h)
	draw_line(Vector2(0, scan_y), Vector2(w, scan_y), Color(0.0, 1.0, 0.8, 0.35), 1.5)
	draw_line(Vector2(0, scan_y - 2.0), Vector2(w, scan_y - 2.0), Color(0.0, 0.6, 0.8, 0.12), 4.0)
