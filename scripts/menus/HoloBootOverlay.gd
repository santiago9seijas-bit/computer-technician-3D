extends Control

# =============================================================================
# SECUENCIA DE ACTIVACIÓN HOLOGRÁFICA "TONY STARK" (JARVIS BOOT SEQUENCE)
# =============================================================================
# Recrea el encendido cinematográfico de dispositivos holográficos Stark:
# Ignición de núcleo, anillos de calibración rotativos, retículas tácticas
# y barrido de despliegue en Rojo Carmesí, Negro y Morado Neón.

signal boot_completed

var time: float = 0.0
var duration: float = 1.35
var is_active: bool = true

# Posición del núcleo holográfico (Nodo 1 del mapa)
var core_origin: Vector2 = Vector2(160.0, 440.0)

# Posiciones de los nodos del mapa para fijar retículas tácticas
var target_nodes: Array[Vector2] = [
	Vector2(160, 440), # Nodo 1
	Vector2(320, 320), # Nodo 2
	Vector2(320, 560), # Nodo 3
	Vector2(530, 350), # Nodo 4
	Vector2(530, 530), # Nodo 5
	Vector2(720, 440), # Nodo 6
	Vector2(920, 320), # Nodo 7
	Vector2(920, 560), # Nodo 8
	Vector2(1080, 440) # Nodo 9
]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	if not is_active:
		return
		
	time += delta
	queue_redraw()
	
	if time >= duration:
		complete_boot()

func _gui_input(event: InputEvent) -> void:
	# Si el jugador hace clic o presiona tecla, salta la animación al instante
	if is_active and (event is InputEventMouseButton or event is InputEventKey):
		complete_boot()

func complete_boot() -> void:
	if not is_active:
		return
	is_active = false
	time = duration
	boot_completed.emit()
	
	# Desvanecimiento final suave
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25).set_ease(Tween.EASE_OUT)
	tw.tween_callback(queue_free)

func _draw() -> void:
	if time <= 0.0:
		return
		
	var w = size.x
	var h = size.y
	var p = clamp(time / duration, 0.0, 1.0)
	
	# Paleta Stark: Rojo Carmesí, Negro y Morado Neón
	var red_neon = Color(1.0, 0.10, 0.25, 1.0)
	var purple_neon = Color(0.80, 0.08, 0.98, 1.0)
	var crimson_glow = Color(0.85, 0.02, 0.18, 0.4)
	var white_flash = Color(1.0, 0.95, 1.0, 1.0)
	
	# Factor de desvanecimiento global al final de la secuencia
	var fade = 1.0
	if p > 0.75:
		fade = 1.0 - (p - 0.75) / 0.25
	
	# -------------------------------------------------------------------------
	# 1. DESTELLO INICIAL E IGNICIÓN DEL REACTOR
	# -------------------------------------------------------------------------
	if p < 0.25:
		var flash_t = p / 0.25
		var flash_alpha = (1.0 - flash_t) * 0.75
		# Destello pantalla completa
		draw_rect(Rect2(0, 0, w, h), Color(0.12, 0.0, 0.16, flash_alpha * 0.5), true)
		# Punto brillante de ignición en el núcleo
		draw_circle(core_origin, (1.0 - flash_t) * 60.0, Color(1.0, 0.2, 0.4, flash_alpha))
		draw_circle(core_origin, (1.0 - flash_t) * 20.0, white_flash)

	# -------------------------------------------------------------------------
	# 2. ONDAS EXPANSIVAS RADIALES (SONAR HOLOGRÁFICO)
	# -------------------------------------------------------------------------
	# Onda 1 (Rojo Neón rápida)
	var wave1_r = ease(p, 0.35) * max(w, h) * 1.2
	if wave1_r > 5.0 and wave1_r < max(w, h) * 1.3:
		var w1_alpha = clamp(1.0 - p * 1.1, 0.0, 1.0) * fade
		draw_arc(core_origin, wave1_r, 0, TAU, 64, Color(red_neon.r, red_neon.g, red_neon.b, w1_alpha * 0.7), 2.5)
		draw_arc(core_origin, wave1_r - 6.0, 0, TAU, 48, Color(crimson_glow.r, crimson_glow.g, crimson_glow.b, w1_alpha * 0.3), 6.0)

	# Onda 2 (Morado Neón secundaria desfasada)
	if p > 0.12:
		var p2 = (p - 0.12) / 0.88
		var wave2_r = ease(p2, 0.4) * max(w, h) * 1.0
		var w2_alpha = clamp(1.0 - p2 * 1.1, 0.0, 1.0) * fade
		draw_arc(core_origin, wave2_r, 0, TAU, 64, Color(purple_neon.r, purple_neon.g, purple_neon.b, w2_alpha * 0.6), 2.0)

	# -------------------------------------------------------------------------
	# 3. ANILLOS DE CALIBRACIÓN ROTATIVOS "STARK HUD" EN EL NÚCLEO
	# -------------------------------------------------------------------------
	var hud_alpha = clamp(p / 0.25, 0.0, 1.0) * fade
	var rot = time * 3.2
	
	# Anillo interior con muescas técnicas (radio 48)
	var r_inner = 48.0
	draw_arc(core_origin, r_inner, rot, rot + PI * 0.55, 24, Color(red_neon.r, red_neon.g, red_neon.b, hud_alpha * 0.9), 2.2)
	draw_arc(core_origin, r_inner, rot + PI, rot + PI * 1.55, 24, Color(red_neon.r, red_neon.g, red_neon.b, hud_alpha * 0.9), 2.2)
	
	# Anillo medio en contragiro (radio 72, morado)
	var r_mid = 72.0
	var rot_inv = -time * 2.5
	draw_arc(core_origin, r_mid, rot_inv, rot_inv + PI * 0.35, 16, Color(purple_neon.r, purple_neon.g, purple_neon.b, hud_alpha * 0.85), 1.8)
	draw_arc(core_origin, r_mid, rot_inv + PI * 0.65, rot_inv + PI, 16, Color(purple_neon.r, purple_neon.g, purple_neon.b, hud_alpha * 0.85), 1.8)
	draw_arc(core_origin, r_mid, rot_inv + PI * 1.35, rot_inv + PI * 1.7, 16, Color(purple_neon.r, purple_neon.g, purple_neon.b, hud_alpha * 0.85), 1.8)
	
	# Ticks radiales en el círculo de calibración (12 grados)
	for i in range(12):
		var tick_ang = float(i) / 12.0 * TAU + rot * 0.4
		var v_dir = Vector2(cos(tick_ang), sin(tick_ang))
		var pt_a = core_origin + v_dir * 84.0
		var pt_b = core_origin + v_dir * 92.0
		draw_line(pt_a, pt_b, Color(red_neon.r, red_neon.g, red_neon.b, hud_alpha * 0.7), 1.5)

	# Corchetes tácticos envolventes (radio 108)
	var r_outer = 108.0
	var b_rot = rot * 0.6
	for bi in range(4):
		var b_ang = float(bi) / 4.0 * TAU + b_rot
		var b_center = core_origin + Vector2(cos(b_ang), sin(b_ang)) * r_outer
		# Pequeño corchete angular
		var tang = b_ang + PI * 0.5
		var t_dir = Vector2(cos(tang), sin(tang)) * 10.0
		draw_line(b_center - t_dir, b_center + t_dir, Color(purple_neon.r, purple_neon.g, purple_neon.b, hud_alpha * 0.85), 2.0)
		draw_circle(b_center, 2.0, white_flash)

	# -------------------------------------------------------------------------
	# 4. HAZ LÁSER ROTATIVO DE ESCANEO DE ÁREA (RADAR STARK)
	# -------------------------------------------------------------------------
	var scan_ang = time * 4.5
	var scan_len = min(w, h) * 0.75 * clamp(p / 0.4, 0.0, 1.0)
	var scan_end = core_origin + Vector2(cos(scan_ang), sin(scan_ang)) * scan_len
	draw_line(core_origin, scan_end, Color(red_neon.r, red_neon.g, red_neon.b, hud_alpha * 0.5), 1.8)
	# Estela tenue
	var trail_end = core_origin + Vector2(cos(scan_ang - 0.25), sin(scan_ang - 0.25)) * scan_len
	draw_line(core_origin, trail_end, Color(purple_neon.r, purple_neon.g, purple_neon.b, hud_alpha * 0.2), 1.0)

	# -------------------------------------------------------------------------
	# 5. RETÍCULAS DE FIJACIÓN TÁCTICA EN CADA NODO (LOCK-ON EN CASCADA)
	# -------------------------------------------------------------------------
	for i in range(target_nodes.size()):
		var np = target_nodes[i]
		# Cada nodo se activa según la distancia al núcleo
		var dist = core_origin.distance_to(np)
		var trigger_p = 0.20 + (dist / (w * 0.95)) * 0.45
		
		if p >= trigger_p:
			var node_t = clamp((p - trigger_p) / 0.25, 0.0, 1.0)
			var node_alpha = clamp(sin(node_t * PI), 0.0, 1.0) * fade
			var reticle_r = lerp(45.0, 24.0, ease(node_t, 0.4))
			
			# Corchetes de mira de fijación: ⌜ ⌝ ⌞ ⌟
			var c_len = 8.0
			var c_col = red_neon if i == 0 else purple_neon
			c_col.a = node_alpha * 0.95
			
			# Superior izquierda ⌜
			draw_line(np + Vector2(-reticle_r, -reticle_r), np + Vector2(-reticle_r + c_len, -reticle_r), c_col, 2.0)
			draw_line(np + Vector2(-reticle_r, -reticle_r), np + Vector2(-reticle_r, -reticle_r + c_len), c_col, 2.0)
			# Superior derecha ⌝
			draw_line(np + Vector2(reticle_r, -reticle_r), np + Vector2(reticle_r - c_len, -reticle_r), c_col, 2.0)
			draw_line(np + Vector2(reticle_r, -reticle_r), np + Vector2(reticle_r, -reticle_r + c_len), c_col, 2.0)
			# Inferior izquierda ⌞
			draw_line(np + Vector2(-reticle_r, reticle_r), np + Vector2(-reticle_r + c_len, reticle_r), c_col, 2.0)
			draw_line(np + Vector2(-reticle_r, reticle_r), np + Vector2(-reticle_r, reticle_r - c_len), c_col, 2.0)
			# Inferior derecha ⌟
			draw_line(np + Vector2(reticle_r, reticle_r), np + Vector2(reticle_r - c_len, reticle_r), c_col, 2.0)
			draw_line(np + Vector2(reticle_r, reticle_r), np + Vector2(reticle_r, reticle_r - c_len), c_col, 2.0)
			
			# Línea de enlace relámpago temporal hacia el núcleo
			if i > 0 and node_t < 0.6:
				var link_alpha = (1.0 - node_t / 0.6) * 0.45 * fade
				draw_line(core_origin, np, Color(red_neon.r, red_neon.g, red_neon.b, link_alpha), 1.2)

	# -------------------------------------------------------------------------
	# 6. BARRIDO DE LÍNEA HOLOGRÁFICA HORIZONTAL (HOLO SCAN PLANE)
	# -------------------------------------------------------------------------
	if p > 0.15 and p < 0.85:
		var plane_p = (p - 0.15) / 0.70
		var plane_y = plane_p * h
		var plane_alpha = sin(plane_p * PI) * 0.5 * fade
		draw_line(Vector2(0, plane_y), Vector2(w, plane_y), Color(red_neon.r, red_neon.g, red_neon.b, plane_alpha * 0.8), 2.0)
		draw_line(Vector2(0, plane_y - 3), Vector2(w, plane_y - 3), Color(purple_neon.r, purple_neon.g, purple_neon.b, plane_alpha * 0.35), 4.0)
