extends Control

signal closed(final_score: int)

# =============================================================================
# TERMINAL PAC-MAN: ARCADE EDITION (1980 RETRO VT100 / CRT)
# Minijuego arcade completamente funcional renderizado con estética retro
# de terminal para Andromeda OS.
# =============================================================================

# --- CONSTANTES DE CUADRÍCULA ---
const COLS: int = 21
const ROWS: int = 21
const CELL_SIZE: float = 19.0

# Mapa clásico adaptado y balanceado de 21x21
# '#' = Muro
# '.' = Píldora (+10 pts)
# 'o' = Superpíldora / Energizante (+50 pts)
# ' ' = Pasillo vacío
# '=' = Puerta casa de fantasmas
# 'G' = Interior casa de fantasmas
# 'P' = Posición inicial de Pacman
const MAZE_TEMPLATE: Array[String] = [
	"#####################",
	"#o........#........o#",
	"#.###.###.#.###.###.#",
	"#.# #.# #.#.# #.# #.#",
	"#.###.###.#.###.###.#",
	"#...................#",
	"#.###.#.#####.#.###.#",
	"#.....#...#...#.....#",
	"#####.### # ###.#####",
	"    #.#   =   #.#    ",
	"#####.# GG GG #.#####",
	"    #.# ===== #.#    ",
	"#####.# ##### #.#####",
	"#.........#.........#",
	"#.###.###.#.###.###.#",
	"#o..#.....P.....#..o#",
	"###.#.#.#####.#.#.###",
	"#.....#...#...#.....#",
	"#.#######.#.#######.#",
	"#...................#",
	"#####################"
]

# Direcciones cardinales
const DIR_NONE: Vector2i = Vector2i(0, 0)
const DIR_UP: Vector2i = Vector2i(0, -1)
const DIR_DOWN: Vector2i = Vector2i(0, 1)
const DIR_LEFT: Vector2i = Vector2i(-1, 0)
const DIR_RIGHT: Vector2i = Vector2i(1, 0)

# Estados de Fantasmas
enum GhostMode { CHASE, SCATTER, FRIGHTENED, EATEN }

# Estado del juego
var maze_data: Array = []
var total_dots: int = 0
var dots_remaining: int = 0
var score: int = 0
var high_score: int = 5000
var lives: int = 3
var level: int = 1
var is_game_over: bool = false
var is_stage_clear: bool = false
var is_paused: bool = false

# Pacman
var pac_grid: Vector2i = Vector2i(10, 15)
var pac_pos: Vector2 = Vector2.ZERO # Posición continua para dibujo fluido
var pac_dir: Vector2i = DIR_LEFT
var pac_next_dir: Vector2i = DIR_LEFT
var pac_speed: float = 7.0 # casillas por segundo
var pac_mouth_angle: float = 0.0
var pac_mouth_dir: float = 1.0
var pac_dying: bool = false
var pac_death_timer: float = 0.0

# Temporizadores
var energizer_timer: float = 0.0
var energizer_duration: float = 7.5
var ghost_combo: int = 0
var chomp_sound_toggle: bool = false

# Fruta / Bonus (Aparece a mitad de las píldoras)
var fruit_pos: Vector2i = Vector2i(10, 11)
var fruit_active: bool = false
var fruit_timer: float = 0.0

# Fantasmas (Blinky, Pinky, Inky, Clyde)
var ghosts: Array[Dictionary] = []

# Audio procedimental sintético
var sfx_player: AudioStreamPlayer = null
var sfx_cache: Dictionary = {}

func _init() -> void:
	custom_minimum_size = Vector2(800, 470)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

func _ready() -> void:
	set_process_input(true)
	set_process(true)
	_setup_audio()
	_reset_game_full()

func _setup_audio() -> void:
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "Master"
	add_child(sfx_player)
	_generate_sfx_cache()

func _generate_sfx_cache() -> void:
	sfx_cache["waka1"] = _generate_tone_wav(460.0, 0.05, 0.15)
	sfx_cache["waka2"] = _generate_tone_wav(280.0, 0.05, 0.15)
	sfx_cache["power"] = _generate_tone_wav(680.0, 0.12, 0.25)
	sfx_cache["eat_ghost"] = _generate_chirp_wav(300.0, 900.0, 0.25)
	sfx_cache["death"] = _generate_chirp_wav(800.0, 150.0, 0.5)
	sfx_cache["win"] = _generate_arpeggio_wav([440.0, 554.0, 659.0, 880.0], 0.08)

func _play_sfx(sound_name: String) -> void:
	if not sfx_player or not sfx_cache.has(sound_name):
		return
	sfx_player.stream = sfx_cache[sound_name]
	sfx_player.play()

func _generate_tone_wav(freq: float, duration: float, volume: float = 0.2) -> AudioStreamWAV:
	var sample_rate: int = 11025
	var num_samples: int = int(sample_rate * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(num_samples)
	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		# Onda cuadrada retro suavizada
		var s: float = 1.0 if sin(TAU * freq * t) >= 0.0 else -1.0
		var envelope: float = 1.0 - (float(i) / float(num_samples))
		var val: float = s * volume * envelope
		data[i] = clampi(int(val * 127.0 + 128.0), 0, 255)
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _generate_chirp_wav(start_f: float, end_f: float, duration: float) -> AudioStreamWAV:
	var sample_rate: int = 11025
	var num_samples: int = int(sample_rate * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(num_samples)
	for i in range(num_samples):
		var frac: float = float(i) / float(num_samples)
		var freq: float = lerp(start_f, end_f, frac)
		var t: float = float(i) / float(sample_rate)
		var s: float = 1.0 if sin(TAU * freq * t) >= 0.0 else -1.0
		var envelope: float = 1.0 - frac
		var val: float = s * 0.22 * envelope
		data[i] = clampi(int(val * 127.0 + 128.0), 0, 255)
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _generate_arpeggio_wav(freqs: Array, note_duration: float) -> AudioStreamWAV:
	var sample_rate: int = 11025
	var total_duration = note_duration * freqs.size()
	var num_samples: int = int(sample_rate * total_duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(num_samples)
	for i in range(num_samples):
		var t_tot: float = float(i) / float(sample_rate)
		var note_idx: int = clampi(int(t_tot / note_duration), 0, freqs.size() - 1)
		var freq: float = freqs[note_idx]
		var s: float = 1.0 if sin(TAU * freq * t_tot) >= 0.0 else -1.0
		data[i] = clampi(int(s * 0.22 * 127.0 + 128.0), 0, 255)
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

# =============================================================================
# INICIALIZACIÓN Y REINICIO
# =============================================================================

func _reset_game_full() -> void:
	score = 0
	lives = 3
	level = 1
	is_game_over = false
	is_stage_clear = false
	_build_maze()
	_reset_positions()

func _build_maze() -> void:
	maze_data.clear()
	total_dots = 0
	for y in range(ROWS):
		var row: Array = []
		var line: String = MAZE_TEMPLATE[y]
		for x in range(COLS):
			var ch: String = line[x]
			row.append(ch)
			if ch == "." or ch == "o":
				total_dots += 1
		maze_data.append(row)
	dots_remaining = total_dots
	fruit_active = false
	fruit_timer = 0.0

func _reset_positions() -> void:
	pac_grid = Vector2i(10, 15)
	pac_pos = Vector2(pac_grid.x, pac_grid.y)
	pac_dir = DIR_LEFT
	pac_next_dir = DIR_LEFT
	pac_dying = false
	pac_death_timer = 0.0
	energizer_timer = 0.0

	# 4 Fantasmas
	ghosts = [
		{
			"name": "Blinky",
			"color": Color(1.0, 0.15, 0.15), # Rojo
			"grid": Vector2i(10, 7),
			"pos": Vector2(10, 7),
			"dir": DIR_LEFT,
			"mode": GhostMode.CHASE,
			"scatter_target": Vector2i(19, 0),
			"speed": 6.2,
			"home": Vector2i(10, 7),
			"in_house": false
		},
		{
			"name": "Pinky",
			"color": Color(1.0, 0.72, 1.0), # Rosa
			"grid": Vector2i(10, 10),
			"pos": Vector2(10, 10),
			"dir": DIR_UP,
			"mode": GhostMode.CHASE,
			"scatter_target": Vector2i(1, 0),
			"speed": 5.9,
			"home": Vector2i(10, 10),
			"in_house": true
		},
		{
			"name": "Inky",
			"color": Color(0.0, 0.95, 1.0), # Cian
			"grid": Vector2i(9, 10),
			"pos": Vector2(9, 10),
			"dir": DIR_UP,
			"mode": GhostMode.CHASE,
			"scatter_target": Vector2i(19, 20),
			"speed": 5.7,
			"home": Vector2i(9, 10),
			"in_house": true
		},
		{
			"name": "Clyde",
			"color": Color(1.0, 0.72, 0.32), # Naranja
			"grid": Vector2i(11, 10),
			"pos": Vector2(11, 10),
			"dir": DIR_UP,
			"mode": GhostMode.CHASE,
			"scatter_target": Vector2i(1, 20),
			"speed": 5.5,
			"home": Vector2i(11, 10),
			"in_house": true
		}
	]

# =============================================================================
# ENTRADA DE USUARIO
# =============================================================================

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT, KEY_A:
				pac_next_dir = DIR_LEFT
				accept_event()
			KEY_RIGHT, KEY_D:
				pac_next_dir = DIR_RIGHT
				accept_event()
			KEY_UP, KEY_W:
				pac_next_dir = DIR_UP
				accept_event()
			KEY_DOWN, KEY_S:
				pac_next_dir = DIR_DOWN
				accept_event()
			KEY_R:
				_reset_game_full()
				accept_event()
			KEY_P:
				is_paused = not is_paused
				queue_redraw()
				accept_event()
			KEY_Q, KEY_ESCAPE:
				exit_to_terminal()
				accept_event()

func exit_to_terminal() -> void:
	visible = false
	closed.emit(score)

# =============================================================================
# BUCLE PRINCIPAL (PROCESS)
# =============================================================================

func _process(delta: float) -> void:
	if not visible or is_paused:
		return

	if is_game_over or is_stage_clear:
		queue_redraw()
		return

	# Animación de muerte
	if pac_dying:
		pac_death_timer += delta
		if pac_death_timer > 1.2:
			pac_dying = false
			lives -= 1
			if lives <= 0:
				is_game_over = true
			else:
				_reset_positions()
		queue_redraw()
		return

	# Temporizador de energizante / superpíldora
	if energizer_timer > 0.0:
		energizer_timer -= delta
		if energizer_timer <= 0.0:
			energizer_timer = 0.0
			ghost_combo = 0
			for g in ghosts:
				if g["mode"] == GhostMode.FRIGHTENED:
					g["mode"] = GhostMode.CHASE

	# Fruta bonus
	if not fruit_active and dots_remaining <= total_dots / 2:
		fruit_active = true
		fruit_timer = 12.0
	elif fruit_active:
		fruit_timer -= delta
		if fruit_timer <= 0.0:
			fruit_active = false

	# Animación de boca de Pacman
	pac_mouth_angle += pac_mouth_dir * delta * 12.0
	if pac_mouth_angle > 0.85:
		pac_mouth_angle = 0.85
		pac_mouth_dir = -1.0
	elif pac_mouth_angle < 0.05:
		pac_mouth_angle = 0.05
		pac_mouth_dir = 1.0

	_update_pacman(delta)
	_update_ghosts(delta)
	_check_collisions()
	queue_redraw()

# =============================================================================
# MOVIMIENTO Y LÓGICA DE PACMAN
# =============================================================================

func _update_pacman(delta: float) -> void:
	# Intento de giro según buffer
	if pac_next_dir != pac_dir:
		if _can_move_to(pac_grid + pac_next_dir, false):
			# Giro suave si estamos cerca del centro de la celda o alineados
			var offset: Vector2 = pac_pos - Vector2(pac_grid.x, pac_grid.y)
			if offset.length() < 0.45 or pac_next_dir == -pac_dir:
				pac_dir = pac_next_dir
				pac_pos = Vector2(pac_grid.x, pac_grid.y)

	if pac_dir != DIR_NONE:
		var target_grid: Vector2i = pac_grid + pac_dir
		if _can_move_to(target_grid, false):
			var step: float = pac_speed * delta
			pac_pos += Vector2(pac_dir.x, pac_dir.y) * step
			
			# Chequeo si cruzó al centro de la nueva casilla
			var cur_v = Vector2(pac_grid.x, pac_grid.y)
			var dist = (pac_pos - cur_v).length()
			if dist >= 1.0:
				pac_grid = target_grid
				pac_pos = Vector2(pac_grid.x, pac_grid.y)
				_on_pacman_entered_cell(pac_grid)
		else:
			# Chocó contra la pared
			pac_pos = Vector2(pac_grid.x, pac_grid.y)

	# Túneles laterales (Wrap-around clásico en fila 9 / 10)
	if pac_pos.x < -0.5:
		pac_pos.x = float(COLS - 1)
		pac_grid.x = COLS - 1
	elif pac_pos.x > float(COLS - 1) + 0.5:
		pac_pos.x = 0.0
		pac_grid.x = 0

func _on_pacman_entered_cell(pos: Vector2i) -> void:
	if pos.y < 0 or pos.y >= ROWS or pos.x < 0 or pos.x >= COLS:
		return
	var cell: String = maze_data[pos.y][pos.x]
	if cell == ".":
		maze_data[pos.y][pos.x] = " "
		score += 10
		dots_remaining -= 1
		chomp_sound_toggle = not chomp_sound_toggle
		_play_sfx("waka1" if chomp_sound_toggle else "waka2")
		_check_victory()
	elif cell == "o":
		maze_data[pos.y][pos.x] = " "
		score += 50
		dots_remaining -= 1
		energizer_timer = energizer_duration
		ghost_combo = 0
		_play_sfx("power")
		for g in ghosts:
			if g["mode"] != GhostMode.EATEN:
				g["mode"] = GhostMode.FRIGHTENED
				g["dir"] = -g["dir"] # Invierten marcha
		_check_victory()

	# Recoger fruta
	if fruit_active and pos == fruit_pos:
		fruit_active = false
		score += 300
		_play_sfx("power")

	if score > high_score:
		high_score = score

func _check_victory() -> void:
	if dots_remaining <= 0:
		is_stage_clear = true
		_play_sfx("win")

# =============================================================================
# MOVIMIENTO Y LÓGICA DE FANTASMAS
# =============================================================================

func _update_ghosts(delta: float) -> void:
	for g in ghosts:
		var speed: float = g["speed"]
		if g["mode"] == GhostMode.FRIGHTENED:
			speed *= 0.55
		elif g["mode"] == GhostMode.EATEN:
			speed *= 1.85

		# Liberar de la casa progresivamente
		if g["in_house"]:
			if g["name"] == "Pinky" and dots_remaining <= total_dots - 5:
				g["in_house"] = false
				g["grid"] = Vector2i(10, 8)
				g["pos"] = Vector2(10, 8)
			elif g["name"] == "Inky" and dots_remaining <= total_dots - 20:
				g["in_house"] = false
				g["grid"] = Vector2i(10, 8)
				g["pos"] = Vector2(10, 8)
			elif g["name"] == "Clyde" and dots_remaining <= total_dots - 45:
				g["in_house"] = false
				g["grid"] = Vector2i(10, 8)
				g["pos"] = Vector2(10, 8)
			continue

		# Si el fantasma comido llegó a la casa
		if g["mode"] == GhostMode.EATEN and g["grid"] == Vector2i(10, 8):
			g["mode"] = GhostMode.CHASE

		# Movimiento
		var step: float = speed * delta
		g["pos"] += Vector2(g["dir"].x, g["dir"].y) * step
		var cur_v = Vector2(g["grid"].x, g["grid"].y)
		var dist = (g["pos"] - cur_v).length()

		if dist >= 1.0:
			g["grid"] = g["grid"] + g["dir"]
			g["pos"] = Vector2(g["grid"].x, g["grid"].y)
			# Elegir nueva dirección en la intersección
			g["dir"] = _choose_ghost_dir(g)

		# Wrap-around túnel lateral
		if g["pos"].x < -0.5:
			g["pos"].x = float(COLS - 1)
			g["grid"].x = COLS - 1
		elif g["pos"].x > float(COLS - 1) + 0.5:
			g["pos"].x = 0.0
			g["grid"].x = 0

func _choose_ghost_dir(g: Dictionary) -> Vector2i:
	var target: Vector2i = pac_grid
	var mode: GhostMode = g["mode"]

	if mode == GhostMode.EATEN:
		target = Vector2i(10, 8)
	elif mode == GhostMode.FRIGHTENED:
		# Movimiento aleatorio en modo asustado
		var valid_dirs: Array[Vector2i] = []
		var test_dirs: Array[Vector2i] = [DIR_UP, DIR_LEFT, DIR_DOWN, DIR_RIGHT]
		for d in test_dirs:
			if d != -g["dir"] and _can_move_to(g["grid"] + d, true):
				valid_dirs.append(d)
		if not valid_dirs.is_empty():
			return valid_dirs[randi() % valid_dirs.size()]
		return g["dir"]
	else:
		# Personalidades clásicas de la IA arcade
		match g["name"]:
			"Blinky":
				target = pac_grid
			"Pinky":
				target = pac_grid + pac_dir * 3
			"Inky":
				var blinky = ghosts[0]
				var pivot = pac_grid + pac_dir * 2
				target = pivot + (pivot - blinky["grid"])
			"Clyde":
				var d_to_pac = (Vector2(g["grid"]) - Vector2(pac_grid)).length()
				target = pac_grid if d_to_pac > 6.0 else g["scatter_target"]

	# Buscar dirección disponible más cercana al objetivo
	var best_dir: Vector2i = g["dir"]
	var min_dist: float = 999999.0
	var dirs: Array[Vector2i] = [DIR_UP, DIR_LEFT, DIR_DOWN, DIR_RIGHT]

	for d in dirs:
		if d == -g["dir"]:
			continue # Los fantasmas no pueden dar media vuelta inmediatamente
		var next_cell = g["grid"] + d
		if _can_move_to(next_cell, mode == GhostMode.EATEN):
			var d_sq = Vector2(next_cell).distance_squared_to(Vector2(target))
			if d_sq < min_dist:
				min_dist = d_sq
				best_dir = d

	return best_dir

func _can_move_to(pos: Vector2i, allow_gate: bool) -> bool:
	# Wrap-around túnel lateral siempre permitido
	if (pos.y == 9 or pos.y == 10) and (pos.x < 0 or pos.x >= COLS):
		return true
	if pos.y < 0 or pos.y >= ROWS or pos.x < 0 or pos.x >= COLS:
		return false
	var cell: String = maze_data[pos.y][pos.x]
	if cell == "#":
		return false
	if cell == "=" and not allow_gate:
		return false
	if cell == "G" and not allow_gate:
		return false
	return true

# =============================================================================
# COLISIONES
# =============================================================================

func _check_collisions() -> void:
	if pac_dying:
		return

	for g in ghosts:
		var d = (g["pos"] - pac_pos).length()
		if d < 0.75:
			if g["mode"] == GhostMode.FRIGHTENED:
				# Fantasma comido por Pacman
				g["mode"] = GhostMode.EATEN
				ghost_combo += 1
				var pts = int(pow(2, ghost_combo) * 100) # 200, 400, 800, 1600
				score += pts
				_play_sfx("eat_ghost")
			elif g["mode"] == GhostMode.CHASE or g["mode"] == GhostMode.SCATTER:
				# Pacman atrapado por fantasma
				pac_dying = true
				pac_death_timer = 0.0
				_play_sfx("death")
				break

# =============================================================================
# RENDERIZADO VISUAL ESTÉTICA RETRO TERMINAL / CRT ARCADE
# =============================================================================

func _draw() -> void:
	var total_w = size.x
	var total_h = size.y

	# Fondo CRT negro profundo de terminal
	draw_rect(Rect2(0, 0, total_w, total_h), Color(0.02, 0.03, 0.06, 1.0))

	# Coordenadas de centrado del laberinto
	var maze_pixel_w = float(COLS) * CELL_SIZE
	var maze_pixel_h = float(ROWS) * CELL_SIZE
	var start_x = 24.0
	var start_y = (total_h - maze_pixel_h) * 0.5 + 10.0

	# Marco del laberinto
	draw_rect(Rect2(start_x - 3, start_y - 3, maze_pixel_w + 6, maze_pixel_h + 6), Color(0.0, 0.55, 0.85, 0.25), false, 2.0)

	# 1. Dibujar Celdas del Laberinto
	for y in range(ROWS):
		for x in range(COLS):
			var cell: String = maze_data[y][x]
			var cp = Vector2(start_x + float(x) * CELL_SIZE, start_y + float(y) * CELL_SIZE)
			var cell_rect = Rect2(cp, Vector2(CELL_SIZE, CELL_SIZE))

			if cell == "#":
				# Muro cibernético terminal azul neón
				draw_rect(cell_rect, Color(0.05, 0.10, 0.22, 1.0))
				draw_rect(cell_rect, Color(0.0, 0.75, 1.0, 0.85), false, 1.5)
			elif cell == "=":
				# Puerta de casa de fantasmas
				draw_line(cp + Vector2(0, CELL_SIZE * 0.5), cp + Vector2(CELL_SIZE, CELL_SIZE * 0.5), Color(1.0, 0.6, 0.8, 0.9), 3.0)
			elif cell == ".":
				# Píldora / Punto
				var center = cp + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)
				draw_circle(center, 2.2, Color(1.0, 0.88, 0.6, 0.95))
			elif cell == "o":
				# Superpíldora energizante (parpadea)
				var pulse = (sin(Time.get_ticks_msec() * 0.008) + 1.0) * 0.5
				var center = cp + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)
				draw_circle(center, 5.0 + pulse * 1.5, Color(1.0, 0.92, 0.4, 0.95))
				draw_arc(center, 7.0 + pulse * 2.0, 0, TAU, 16, Color(1.0, 0.6, 0.2, 0.6 * pulse), 1.5)

	# Fruta Bonus
	if fruit_active:
		var fp = Vector2(start_x + float(fruit_pos.x) * CELL_SIZE + CELL_SIZE * 0.5, start_y + float(fruit_pos.y) * CELL_SIZE + CELL_SIZE * 0.5)
		draw_circle(fp, 6.0, Color(1.0, 0.1, 0.3, 1.0))
		draw_circle(fp + Vector2(4, 2), 5.0, Color(0.9, 0.05, 0.2, 1.0))
		draw_line(fp, fp + Vector2(0, -7), Color(0.2, 0.9, 0.3), 2.0)

	# 2. Dibujar Pacman
	if not pac_dying:
		var pp = Vector2(start_x + pac_pos.x * CELL_SIZE + CELL_SIZE * 0.5, start_y + pac_pos.y * CELL_SIZE + CELL_SIZE * 0.5)
		var base_angle: float = 0.0
		if pac_dir == DIR_RIGHT:
			base_angle = 0.0
		elif pac_dir == DIR_DOWN:
			base_angle = PI * 0.5
		elif pac_dir == DIR_LEFT:
			base_angle = PI
		elif pac_dir == DIR_UP:
			base_angle = PI * 1.5

		var half_mouth: float = pac_mouth_angle * 0.5
		var radius: float = CELL_SIZE * 0.52

		# Pacman retro amarillo con cuña de boca
		var points: PackedVector2Array = [pp]
		var segments: int = 24
		var start_a = base_angle + half_mouth
		var end_a = base_angle + TAU - half_mouth
		for i in range(segments + 1):
			var a = lerp(start_a, end_a, float(i) / float(segments))
			points.append(pp + Vector2(cos(a), sin(a)) * radius)
		draw_colored_polygon(points, Color(1.0, 0.92, 0.0, 1.0))
		# Ojo retro
		var eye_offset = Vector2(cos(base_angle - PI * 0.35), sin(base_angle - PI * 0.35)) * (radius * 0.45)
		draw_circle(pp + eye_offset, 1.8, Color(0.1, 0.1, 0.1))
	else:
		# Animación de muerte (desvanecimiento)
		var pp = Vector2(start_x + pac_pos.x * CELL_SIZE + CELL_SIZE * 0.5, start_y + pac_pos.y * CELL_SIZE + CELL_SIZE * 0.5)
		var frac = clampf(pac_death_timer / 1.2, 0.0, 1.0)
		var radius = (CELL_SIZE * 0.52) * (1.0 - frac)
		draw_circle(pp, radius, Color(1.0, 0.8, 0.0, 1.0 - frac))

	# 3. Dibujar Fantasmas
	for g in ghosts:
		var gp = Vector2(start_x + g["pos"].x * CELL_SIZE + CELL_SIZE * 0.5, start_y + g["pos"].y * CELL_SIZE + CELL_SIZE * 0.5)
		_draw_retro_ghost(gp, g)

	# 4. Panel Lateral y Marcadores de Terminal Arcade
	_draw_terminal_arcade_hud(start_x + maze_pixel_w + 24.0, 20.0, total_w - (start_x + maze_pixel_w + 40.0), total_h - 40.0)

	# Overlay de Pausa / Game Over / Victoria
	if is_game_over:
		_draw_status_overlay("GAME OVER", "Presiona [R] para reiniciar o [Q / ESC] para salir al terminal", Color(1.0, 0.25, 0.25))
	elif is_stage_clear:
		_draw_status_overlay("¡NIVEL COMPLETADO!", "¡Has limpiado todo el laberinto! Presiona [R] para jugar de nuevo", Color(0.25, 1.0, 0.45))
	elif is_paused:
		_draw_status_overlay("PAUSA", "Presiona [P] para continuar", Color(1.0, 0.85, 0.2))

func _draw_retro_ghost(gp: Vector2, g: Dictionary) -> void:
	var r: float = CELL_SIZE * 0.52
	var mode: GhostMode = g["mode"]
	var body_col: Color = g["color"]

	if mode == GhostMode.FRIGHTENED:
		# Asustado: Azul marino, parpadea en blanco si queda poco tiempo
		if energizer_timer < 2.0 and int(energizer_timer * 6.0) % 2 == 0:
			body_col = Color(1.0, 1.0, 1.0)
		else:
			body_col = Color(0.13, 0.18, 0.95)
	elif mode == GhostMode.EATEN:
		body_col = Color(0.0, 0.0, 0.0, 0.0) # Solo se dibujan los ojos

	# Cuerpo del fantasma (solo si no ha sido comido)
	if mode != GhostMode.EATEN:
		# Cúpula superior
		var pts: PackedVector2Array = []
		var segs: int = 16
		for i in range(segs + 1):
			var a = lerp(PI, TAU, float(i) / float(segs))
			pts.append(gp + Vector2(cos(a) * r, sin(a) * r * 0.85))
		# Base con patas onduladas
		var foot_wave = sin(Time.get_ticks_msec() * 0.015) * 2.0
		pts.append(gp + Vector2(r, r * 0.85))
		pts.append(gp + Vector2(r * 0.5, r * 0.65 + foot_wave))
		pts.append(gp + Vector2(0.0, r * 0.85))
		pts.append(gp + Vector2(-r * 0.5, r * 0.65 - foot_wave))
		pts.append(gp + Vector2(-r, r * 0.85))
		draw_colored_polygon(pts, body_col)

	# Ojos del fantasma (miran en la dirección de marcha)
	var eye_dir = Vector2(g["dir"].x, g["dir"].y)
	var eye_l = gp + Vector2(-r * 0.35, -r * 0.2) + eye_dir * 1.5
	var eye_r = gp + Vector2(r * 0.35, -r * 0.2) + eye_dir * 1.5

	if mode == GhostMode.FRIGHTENED:
		# Ojos asustados pequeños
		draw_circle(eye_l, 2.0, Color(1.0, 0.8, 0.2))
		draw_circle(eye_r, 2.0, Color(1.0, 0.8, 0.2))
	else:
		# Esclerótica blanca y pupila azul
		draw_circle(eye_l, 3.2, Color(1.0, 1.0, 1.0))
		draw_circle(eye_r, 3.2, Color(1.0, 1.0, 1.0))
		draw_circle(eye_l + eye_dir * 1.2, 1.6, Color(0.1, 0.25, 0.95))
		draw_circle(eye_r + eye_dir * 1.2, 1.6, Color(0.1, 0.25, 0.95))

func _draw_terminal_arcade_hud(x: float, y: float, w: float, h: float) -> void:
	var font = ThemeDB.fallback_font
	var font_size = 11

	# Panel estilo marco de terminal ASCII
	draw_rect(Rect2(x, y, w, h), Color(0.04, 0.07, 0.12, 0.95))
	draw_rect(Rect2(x, y, w, h), Color(0.0, 0.88, 1.0, 0.65), false, 1.5)

	var cur_y = y + 24.0
	var col_cyan = Color(0.0, 0.88, 1.0)
	var col_yellow = Color(1.0, 0.9, 0.2)
	var col_green = Color(0.3, 0.95, 0.45)
	var col_dim = Color(0.65, 0.75, 0.85)

	# Título Terminal
	draw_string(font, Vector2(x + 14, cur_y), "PAC-MAN ARCADE (1980)", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col_yellow)
	cur_y += 18.0
	draw_string(font, Vector2(x + 14, cur_y), "Andromeda OS Package /usr/bin/pacman", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col_dim)
	cur_y += 24.0

	# Puntuaciones
	draw_string(font, Vector2(x + 14, cur_y), "SCORE:", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col_dim)
	draw_string(font, Vector2(x + 110, cur_y), "%06d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col_cyan)
	cur_y += 18.0
	draw_string(font, Vector2(x + 14, cur_y), "HIGH SCORE:", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col_dim)
	draw_string(font, Vector2(x + 110, cur_y), "%06d" % high_score, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col_green)
	cur_y += 24.0

	# Vidas restantes con iconos de Pacman
	draw_string(font, Vector2(x + 14, cur_y), "VIDAS:", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col_dim)
	for i in range(lives):
		var lx = x + 70 + float(i) * 18.0
		draw_circle(Vector2(lx, cur_y - 4), 6.0, col_yellow)
	cur_y += 26.0

	# Píldoras restantes
	draw_string(font, Vector2(x + 14, cur_y), "PÍLDORAS RESTANTES:", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col_dim)
	draw_string(font, Vector2(x + 150, cur_y), "%d / %d" % [dots_remaining, total_dots], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col_yellow)
	cur_y += 26.0

	# Tabla de puntos
	draw_line(Vector2(x + 14, cur_y), Vector2(x + w - 14, cur_y), Color(0.0, 0.88, 1.0, 0.3), 1.0)
	cur_y += 16.0
	draw_string(font, Vector2(x + 14, cur_y), "TABLA DE PUNTOS:", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col_cyan)
	cur_y += 16.0
	draw_string(font, Vector2(x + 14, cur_y), " · Píldora ordinaria      10 PTS", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col_dim)
	cur_y += 14.0
	draw_string(font, Vector2(x + 14, cur_y), " ● Energizante           50 PTS", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col_yellow)
	cur_y += 14.0
	draw_string(font, Vector2(x + 14, cur_y), " 👻 Fantasma Asustado    200..1600 PTS", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.4, 0.6, 1.0))
	cur_y += 14.0
	draw_string(font, Vector2(x + 14, cur_y), " 🍒 Cereza Bonus         300 PTS", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.3, 0.3))
	cur_y += 24.0

	# Controles
	draw_line(Vector2(x + 14, cur_y), Vector2(x + w - 14, cur_y), Color(0.0, 0.88, 1.0, 0.3), 1.0)
	cur_y += 16.0
	draw_string(font, Vector2(x + 14, cur_y), "CONTROLES DE TECLADO:", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col_cyan)
	cur_y += 16.0
	draw_string(font, Vector2(x + 14, cur_y), "[W / A / S / D] o [Flechas] : Mover", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.9, 0.95, 1.0))
	cur_y += 14.0
	draw_string(font, Vector2(x + 14, cur_y), "[P] : Pausa / Reanudar", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col_dim)
	cur_y += 14.0
	draw_string(font, Vector2(x + 14, cur_y), "[R] : Reiniciar partida", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col_dim)
	cur_y += 14.0
	draw_string(font, Vector2(x + 14, cur_y), "[Q] o [ESC] : Volver a la Terminal", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.45, 0.45))

func _draw_status_overlay(title: String, subtitle: String, title_col: Color) -> void:
	var font = ThemeDB.fallback_font
	var total_w = size.x
	var total_h = size.y
	# Sombra
	draw_rect(Rect2(0, 0, total_w, total_h), Color(0.0, 0.0, 0.0, 0.72))
	var box_w = 480.0
	var box_h = 110.0
	var box_rect = Rect2((total_w - box_w) * 0.5, (total_h - box_h) * 0.5, box_w, box_h)
	draw_rect(box_rect, Color(0.05, 0.08, 0.14, 0.95))
	draw_rect(box_rect, title_col, false, 2.0)

	var ty = box_rect.position.y + 44.0
	draw_string(font, Vector2(box_rect.position.x, ty), title, HORIZONTAL_ALIGNMENT_CENTER, int(box_w), 20, title_col)
	draw_string(font, Vector2(box_rect.position.x, ty + 30.0), subtitle, HORIZONTAL_ALIGNMENT_CENTER, int(box_w), 11, Color(0.85, 0.9, 0.95))
