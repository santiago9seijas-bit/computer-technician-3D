extends Control

signal closed(final_score: int)

# =============================================================================
# TERMINAL TETRIS: RETRO ARCADE EDITION (1984 VT100 / CRT)
# Minijuego clásico de Tetris completamente funcional para Andromeda OS.
# Soporta múltiples niveles con velocidad progresiva, retención (Hold),
# proyección de fantasma (Ghost piece), sistema de puntuación arcade y SFX sintéticos.
# =============================================================================

# --- CONSTANTES DE CUADRÍCULA ---
const COLS: int = 10
const ROWS: int = 20
const CELL_SIZE: float = 21.0

# Tetrominoes estándar con rotaciones SRS relativas a su caja 4x4 / 3x3
const TETROMINOES: Dictionary = {
	"I": {
		"color": Color(0.0, 0.95, 1.0), # Cian Neón
		"shapes": [
			[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)],
			[Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3)],
			[Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)],
			[Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3)]
		]
	},
	"O": {
		"color": Color(1.0, 0.9, 0.15), # Amarillo
		"shapes": [
			[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)]
		]
	},
	"T": {
		"color": Color(0.75, 0.2, 0.95), # Morado Neón
		"shapes": [
			[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
			[Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],
			[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],
			[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)]
		]
	},
	"S": {
		"color": Color(0.2, 0.95, 0.35), # Verde Neón
		"shapes": [
			[Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
			[Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)],
			[Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2), Vector2i(1, 2)],
			[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)]
		]
	},
	"Z": {
		"color": Color(1.0, 0.2, 0.25), # Rojo Carmesí
		"shapes": [
			[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)],
			[Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],
			[Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)],
			[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)]
		]
	},
	"J": {
		"color": Color(0.2, 0.45, 1.0), # Azul Royal
		"shapes": [
			[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
			[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, 2)],
			[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)],
			[Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)]
		]
	},
	"L": {
		"color": Color(1.0, 0.6, 0.1), # Naranja Brillante
		"shapes": [
			[Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
			[Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)],
			[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2)],
			[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)]
		]
	}
}

const PIECE_NAMES: Array[String] = ["I", "O", "T", "S", "Z", "J", "L"]

# Estado del juego
var grid: Array = [] # 20 filas x 10 columnas (Color o null)
var score: int = 0
var high_score: int = 10000
var lines_cleared: int = 0
var level: int = 1
var is_game_over: bool = false
var is_paused: bool = false

# Pieza actual
var current_type: String = ""
var current_rot: int = 0
var current_pos: Vector2i = Vector2i(3, 0)
var drop_timer: float = 0.0
var drop_interval: float = 0.8

# Pieza siguiente y Hold
var next_type: String = ""
var hold_type: String = ""
var can_hold: bool = true
var bag: Array[String] = []

# Efecto de despeje de líneas
var clearing_lines: Array[int] = []
var clear_timer: float = 0.0
var clear_duration: float = 0.22

# Audio procedimental sintético
var sfx_player: AudioStreamPlayer = null
var sfx_cache: Dictionary = {}

func _init() -> void:
	custom_minimum_size = Vector2(800, 470)

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
	sfx_cache["move"] = _generate_tone_wav(400.0, 0.04, 0.12)
	sfx_cache["rotate"] = _generate_tone_wav(580.0, 0.05, 0.15)
	sfx_cache["drop"] = _generate_tone_wav(260.0, 0.06, 0.18)
	sfx_cache["hard_drop"] = _generate_chirp_wav(500.0, 180.0, 0.08)
	sfx_cache["clear"] = _generate_arpeggio_wav([523.25, 659.25, 783.99], 0.05)
	sfx_cache["tetris"] = _generate_arpeggio_wav([523.25, 659.25, 783.99, 1046.50], 0.06)
	sfx_cache["level_up"] = _generate_arpeggio_wav([440.0, 554.0, 659.0, 880.0], 0.07)
	sfx_cache["game_over"] = _generate_chirp_wav(600.0, 100.0, 0.45)

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
	grid.clear()
	for y in range(ROWS):
		var row: Array = []
		for x in range(COLS):
			row.append(null)
		grid.append(row)

	score = 0
	lines_cleared = 0
	level = 1
	_update_drop_interval()
	is_game_over = false
	is_paused = false
	hold_type = ""
	can_hold = true
	clearing_lines.clear()

	bag.clear()
	next_type = _get_next_piece_from_bag()
	_spawn_next_piece()
	queue_redraw()

func _update_drop_interval() -> void:
	# Aceleración progresiva por cada nivel (Nivel 1: 0.8s -> Nivel 10+: 0.12s)
	drop_interval = maxf(0.08, 0.82 - float(level - 1) * 0.075)

func _get_next_piece_from_bag() -> String:
	if bag.is_empty():
		bag = PIECE_NAMES.duplicate()
		bag.shuffle()
	return bag.pop_front()

func _spawn_next_piece() -> void:
	current_type = next_type
	next_type = _get_next_piece_from_bag()
	current_rot = 0
	current_pos = Vector2i(3, 0)
	drop_timer = 0.0
	can_hold = true

	if not _is_valid_position(current_pos, current_rot, current_type):
		is_game_over = true
		_play_sfx("game_over")

# =============================================================================
# ENTRADA DE USUARIO
# =============================================================================

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if is_game_over:
			if event.keycode == KEY_R:
				_reset_game_full()
				accept_event()
			elif event.keycode == KEY_Q or event.keycode == KEY_ESCAPE:
				exit_to_terminal()
				accept_event()
			return

		match event.keycode:
			KEY_LEFT, KEY_A:
				_move(Vector2i(-1, 0))
				accept_event()
			KEY_RIGHT, KEY_D:
				_move(Vector2i(1, 0))
				accept_event()
			KEY_DOWN, KEY_S:
				_soft_drop()
				accept_event()
			KEY_UP, KEY_W, KEY_Z:
				_rotate_piece()
				accept_event()
			KEY_SPACE:
				_hard_drop()
				accept_event()
			KEY_C, KEY_SHIFT:
				_hold_piece()
				accept_event()
			KEY_P:
				is_paused = not is_paused
				queue_redraw()
				accept_event()
			KEY_R:
				_reset_game_full()
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
	if not visible or is_paused or is_game_over:
		return

	# Si se están despejando líneas (efecto visual de flash)
	if not clearing_lines.is_empty():
		clear_timer += delta
		if clear_timer >= clear_duration:
			_finish_line_clearing()
		queue_redraw()
		return

	drop_timer += delta
	if drop_timer >= drop_interval:
		drop_timer = 0.0
		_tick_drop()
		queue_redraw()

func _tick_drop() -> void:
	if _can_move(Vector2i(0, 1)):
		current_pos.y += 1
	else:
		_lock_piece()

func _move(dir: Vector2i) -> void:
	if _can_move(dir):
		current_pos += dir
		_play_sfx("move")
		queue_redraw()

func _soft_drop() -> void:
	if _can_move(Vector2i(0, 1)):
		current_pos.y += 1
		score += 1
		if score > high_score:
			high_score = score
		drop_timer = 0.0
		_play_sfx("drop")
		queue_redraw()

func _hard_drop() -> void:
	var dropped_cells: int = 0
	while _can_move(Vector2i(0, 1)):
		current_pos.y += 1
		dropped_cells += 1
	score += dropped_cells * 2
	if score > high_score:
		high_score = score
	_play_sfx("hard_drop")
	_lock_piece()
	queue_redraw()

func _rotate_piece() -> void:
	var shapes = TETROMINOES[current_type]["shapes"]
	var next_rot = (current_rot + 1) % shapes.size()

	# Sistema de patada de pared básica (Wall Kick)
	var kicks: Array[Vector2i] = [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, -1)]
	for k in kicks:
		if _is_valid_position(current_pos + k, next_rot, current_type):
			current_pos += k
			current_rot = next_rot
			_play_sfx("rotate")
			queue_redraw()
			return

func _hold_piece() -> void:
	if not can_hold:
		return
	can_hold = false
	_play_sfx("rotate")

	if hold_type == "":
		hold_type = current_type
		_spawn_next_piece()
	else:
		var temp = hold_type
		hold_type = current_type
		current_type = temp
		current_rot = 0
		current_pos = Vector2i(3, 0)
		drop_timer = 0.0
	queue_redraw()

func _can_move(dir: Vector2i) -> bool:
	return _is_valid_position(current_pos + dir, current_rot, current_type)

func _is_valid_position(pos: Vector2i, rot: int, type: String) -> bool:
	var shapes = TETROMINOES[type]["shapes"]
	var shape = shapes[rot % shapes.size()]
	for block in shape:
		var gx = pos.x + block.x
		var gy = pos.y + block.y
		if gx < 0 or gx >= COLS or gy >= ROWS:
			return false
		if gy >= 0 and grid[gy][gx] != null:
			return false
	return true

func _lock_piece() -> void:
	var shapes = TETROMINOES[current_type]["shapes"]
	var shape = shapes[current_rot % shapes.size()]
	var col = TETROMINOES[current_type]["color"]

	for block in shape:
		var gx = current_pos.x + block.x
		var gy = current_pos.y + block.y
		if gy >= 0 and gy < ROWS and gx >= 0 and gx < COLS:
			grid[gy][gx] = col

	# Comprobar líneas completas
	var full_lines: Array[int] = []
	for y in range(ROWS):
		var full = true
		for x in range(COLS):
			if grid[y][x] == null:
				full = false
				break
		if full:
			full_lines.append(y)

	if not full_lines.is_empty():
		clearing_lines = full_lines
		clear_timer = 0.0
		if full_lines.size() >= 4:
			_play_sfx("tetris")
		else:
			_play_sfx("clear")
	else:
		_spawn_next_piece()

func _finish_line_clearing() -> void:
	var count = clearing_lines.size()
	for line_y in clearing_lines:
		grid.remove_at(line_y)
		var new_row: Array = []
		for x in range(COLS):
			new_row.append(null)
		grid.insert(0, new_row)

	clearing_lines.clear()
	lines_cleared += count

	# Puntuación retro clásica
	match count:
		1: score += 100 * level
		2: score += 300 * level
		3: score += 500 * level
		4: score += 800 * level # ¡TETRIS!

	if score > high_score:
		high_score = score

	# Comprobar subida de nivel (cada 10 líneas)
	var new_level = 1 + int(lines_cleared / 10)
	if new_level > level:
		level = new_level
		_update_drop_interval()
		_play_sfx("level_up")

	_spawn_next_piece()

# =============================================================================
# RENDERIZADO VISUAL ESTÉTICA RETRO TERMINAL / CRT ARCADE
# =============================================================================

func _draw() -> void:
	var total_w = size.x
	var total_h = size.y

	# Fondo CRT negro profundo de terminal
	draw_rect(Rect2(0, 0, total_w, total_h), Color(0.02, 0.03, 0.06, 1.0))

	# Coordenadas del tablero central
	var board_w = float(COLS) * CELL_SIZE
	var board_h = float(ROWS) * CELL_SIZE
	var start_x = 240.0
	var start_y = (total_h - board_h) * 0.5

	# Marco del tablero
	draw_rect(Rect2(start_x, start_y, board_w, board_h), Color(0.04, 0.06, 0.1, 0.95))
	draw_rect(Rect2(start_x - 3, start_y - 3, board_w + 6, board_h + 6), Color(0.0, 0.88, 1.0, 0.75), false, 2.0)

	# Líneas tenues de cuadrícula
	for x in range(1, COLS):
		var px = start_x + float(x) * CELL_SIZE
		draw_line(Vector2(px, start_y), Vector2(px, start_y + board_h), Color(0.1, 0.25, 0.4, 0.25), 1.0)
	for y in range(1, ROWS):
		var py = start_y + float(y) * CELL_SIZE
		draw_line(Vector2(start_x, py), Vector2(start_x + board_w, py), Color(0.1, 0.25, 0.4, 0.25), 1.0)

	# Dibujar bloques fijados en la cuadrícula
	for y in range(ROWS):
		var is_clearing = clearing_lines.has(y)
		for x in range(COLS):
			var col = grid[y][x]
			if col != null:
				var block_col: Color = Color.WHITE if is_clearing and int(Time.get_ticks_msec() * 0.02) % 2 == 0 else col
				_draw_tetris_block(start_x + float(x) * CELL_SIZE, start_y + float(y) * CELL_SIZE, block_col)

	# Dibujar sombra / fantasma de la pieza (Ghost Piece)
	if not is_game_over and current_type != "" and clearing_lines.is_empty():
		var ghost_pos = current_pos
		while _is_valid_position(ghost_pos + Vector2i(0, 1), current_rot, current_type):
			ghost_pos.y += 1
		
		var shapes = TETROMINOES[current_type]["shapes"]
		var shape = shapes[current_rot % shapes.size()]
		var ghost_col = Color(1.0, 1.0, 1.0, 0.25)
		for block in shape:
			var gx = ghost_pos.x + block.x
			var gy = ghost_pos.y + block.y
			if gy >= 0:
				var rx = start_x + float(gx) * CELL_SIZE
				var ry = start_y + float(gy) * CELL_SIZE
				draw_rect(Rect2(rx + 1, ry + 1, CELL_SIZE - 2, CELL_SIZE - 2), ghost_col, false, 1.5)

		# Dibujar pieza activa actual
		var piece_col = TETROMINOES[current_type]["color"]
		for block in shape:
			var gx = current_pos.x + block.x
			var gy = current_pos.y + block.y
			if gy >= 0:
				_draw_tetris_block(start_x + float(gx) * CELL_SIZE, start_y + float(gy) * CELL_SIZE, piece_col)

	# Dibujar panel izquierdo (HOLD)
	_draw_hold_box(start_x - 170.0, start_y + 20.0, 140.0, 130.0)

	# Dibujar panel derecho (HUD + NEXT PIECE + CONTROLES)
	_draw_hud_panel(start_x + board_w + 30.0, 20.0, total_w - (start_x + board_w + 50.0), total_h - 40.0)

	# Overlay de Pausa / Game Over
	if is_game_over:
		_draw_status_overlay("GAME OVER", "Presiona [R] para reiniciar o [Q / ESC] para salir al terminal", Color(1.0, 0.25, 0.25))
	elif is_paused:
		_draw_status_overlay("PAUSA", "Presiona [P] para continuar", Color(1.0, 0.85, 0.2))

func _draw_tetris_block(x: float, y: float, col: Color) -> void:
	var r = Rect2(x + 1, y + 1, CELL_SIZE - 2, CELL_SIZE - 2)
	draw_rect(r, col)
	# Relieve biselado retro
	draw_line(Vector2(x + 1, y + 1), Vector2(x + CELL_SIZE - 2, y + 1), col.lightened(0.4), 1.5)
	draw_line(Vector2(x + 1, y + 1), Vector2(x + 1, y + CELL_SIZE - 2), col.lightened(0.4), 1.5)
	draw_line(Vector2(x + CELL_SIZE - 2, y + 1), Vector2(x + CELL_SIZE - 2, y + CELL_SIZE - 2), col.darkened(0.4), 1.5)
	draw_line(Vector2(x + 1, y + CELL_SIZE - 2), Vector2(x + CELL_SIZE - 2, y + CELL_SIZE - 2), col.darkened(0.4), 1.5)

func _draw_hold_box(x: float, y: float, w: float, h: float) -> void:
	var font = ThemeDB.fallback_font
	draw_rect(Rect2(x, y, w, h), Color(0.04, 0.07, 0.12, 0.95))
	draw_rect(Rect2(x, y, w, h), Color(0.0, 0.88, 1.0, 0.65), false, 1.5)
	draw_string(font, Vector2(x + 12, y + 22), "HOLD [C]", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.0, 0.88, 1.0))

	if hold_type != "":
		_draw_preview_piece(hold_type, x + w * 0.5, y + h * 0.55, can_hold)

func _draw_preview_piece(type: String, center_x: float, center_y: float, active: bool = true) -> void:
	var shape = TETROMINOES[type]["shapes"][0]
	var col = TETROMINOES[type]["color"] if active else Color(0.5, 0.5, 0.5, 0.5)
	var p_size: float = 16.0

	var min_x = 99
	var max_x = -99
	var min_y = 99
	var max_y = -99
	for b in shape:
		min_x = mini(min_x, b.x)
		max_x = maxi(max_x, b.x)
		min_y = mini(min_y, b.y)
		max_y = maxi(max_y, b.y)

	var offset_x = center_x - float(max_x - min_x + 1) * p_size * 0.5
	var offset_y = center_y - float(max_y - min_y + 1) * p_size * 0.5

	for b in shape:
		var bx = offset_x + float(b.x - min_x) * p_size
		var by = offset_y + float(b.y - min_y) * p_size
		var r = Rect2(bx + 1, by + 1, p_size - 2, p_size - 2)
		draw_rect(r, col)
		draw_rect(r, col.lightened(0.3), false, 1.0)

func _draw_hud_panel(x: float, y: float, w: float, h: float) -> void:
	var font = ThemeDB.fallback_font
	draw_rect(Rect2(x, y, w, h), Color(0.04, 0.07, 0.12, 0.95))
	draw_rect(Rect2(x, y, w, h), Color(0.0, 0.88, 1.0, 0.65), false, 1.5)

	var cur_y = y + 24.0
	var col_cyan = Color(0.0, 0.88, 1.0)
	var col_yellow = Color(1.0, 0.9, 0.2)
	var col_green = Color(0.3, 0.95, 0.45)
	var col_dim = Color(0.65, 0.75, 0.85)

	# Título
	draw_string(font, Vector2(x + 14, cur_y), "TETRIS ARCADE (1984)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col_yellow)
	cur_y += 18.0
	draw_string(font, Vector2(x + 14, cur_y), "Andromeda OS Package /usr/bin/tetris", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col_dim)
	cur_y += 24.0

	# Caja NEXT PIECE
	draw_string(font, Vector2(x + 14, cur_y), "SIGUIENTE:", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col_cyan)
	var next_box_w = 110.0
	var next_box_h = 75.0
	var nb_x = x + 14.0
	var nb_y = cur_y + 8.0
	draw_rect(Rect2(nb_x, nb_y, next_box_w, next_box_h), Color(0.02, 0.04, 0.08, 0.9))
	draw_rect(Rect2(nb_x, nb_y, next_box_w, next_box_h), Color(0.0, 0.88, 1.0, 0.4), false, 1.0)
	if next_type != "":
		_draw_preview_piece(next_type, nb_x + next_box_w * 0.5, nb_y + next_box_h * 0.5)
	cur_y += next_box_h + 20.0

	# Nivel, Puntos, Líneas
	draw_string(font, Vector2(x + 14, cur_y), "NIVEL:", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col_dim)
	draw_string(font, Vector2(x + 110, cur_y), "%d" % level, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.4, 0.9))
	cur_y += 18.0

	draw_string(font, Vector2(x + 14, cur_y), "LÍNEAS:", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col_dim)
	draw_string(font, Vector2(x + 110, cur_y), "%d" % lines_cleared, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col_green)
	cur_y += 18.0

	draw_string(font, Vector2(x + 14, cur_y), "SCORE:", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col_dim)
	draw_string(font, Vector2(x + 110, cur_y), "%06d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col_cyan)
	cur_y += 18.0

	draw_string(font, Vector2(x + 14, cur_y), "HIGH SCORE:", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col_dim)
	draw_string(font, Vector2(x + 110, cur_y), "%06d" % high_score, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col_yellow)
	cur_y += 24.0

	# Guía de Controles
	draw_line(Vector2(x + 14, cur_y), Vector2(x + w - 14, cur_y), Color(0.0, 0.88, 1.0, 0.3), 1.0)
	cur_y += 16.0
	draw_string(font, Vector2(x + 14, cur_y), "CONTROLES DE TECLADO:", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col_cyan)
	cur_y += 16.0
	draw_string(font, Vector2(x + 14, cur_y), "[A / D] o [← / →] : Desplazar", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.9, 0.95, 1.0))
	cur_y += 14.0
	draw_string(font, Vector2(x + 14, cur_y), "[W / Z / ↑] : Rotar pieza", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.9, 0.95, 1.0))
	cur_y += 14.0
	draw_string(font, Vector2(x + 14, cur_y), "[S] o [↓] : Soft Drop (Caída suave)", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col_dim)
	cur_y += 14.0
	draw_string(font, Vector2(x + 14, cur_y), "[ESPACIO] : Hard Drop (Caída instantánea)", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col_yellow)
	cur_y += 14.0
	draw_string(font, Vector2(x + 14, cur_y), "[C] o [Shift] : Hold (Reservar pieza)", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.2, 0.85, 1.0))
	cur_y += 14.0
	draw_string(font, Vector2(x + 14, cur_y), "[P] : Pausa  |  [R] : Reiniciar", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col_dim)
	cur_y += 14.0
	draw_string(font, Vector2(x + 14, cur_y), "[Q] o [ESC] : Volver a la Terminal", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.45, 0.45))

func _draw_status_overlay(title: String, subtitle: String, title_col: Color) -> void:
	var font = ThemeDB.fallback_font
	var total_w = size.x
	var total_h = size.y
	draw_rect(Rect2(0, 0, total_w, total_h), Color(0.0, 0.0, 0.0, 0.72))
	var box_w = 480.0
	var box_h = 110.0
	var box_rect = Rect2((total_w - box_w) * 0.5, (total_h - box_h) * 0.5, box_w, box_h)
	draw_rect(box_rect, Color(0.05, 0.08, 0.14, 0.95))
	draw_rect(box_rect, title_col, false, 2.0)

	draw_string(font, Vector2(box_rect.position.x + 20, box_rect.position.y + 44), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, title_col)
	draw_string(font, Vector2(box_rect.position.x + 20, box_rect.position.y + 76), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.85, 0.88, 0.92))
