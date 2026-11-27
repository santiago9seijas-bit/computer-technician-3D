class_name CyberHackingMinigame
extends CanvasLayer

# Almacén estático para transferir datos de nodo antes de instanciar la escena
static var pending_stage_data: Dictionary = {}

# =============================================================================
# MINIJUEGO CIBERNÉTICO: HACKEO NIE-R AUTOMATA (SISTEMAS // ANOMALÍAS GLITCH)
# Homenaje a la mecánica de hackeo de NieR: Automata:
# 1. Nave cursor flecha con apuntado 360°, desplazamiento ágil y disparo dual de plasma.
# 2. Bloque central objetivo: Núcleo Rojo Anómalo (Red Core) con barra de vida e integridad.
# 3. Enemigos de seguridad que disparan: Torretas fijas y Drones patrulleros (balas destructibles).
# 4. Tipos de bloques: Bloques de datos (1-2 impactos), Blindados (4 impactos),
#    Volátiles explosivos (detonación en cadena) y Barreras láser/cortafuegos.
# 5. Mini-puzzles e interruptores cibernéticos (Switches) conectados a barreras láser.
# 6. Al completar el hackeo: La burbuja en Sistemas se purga, desaparece el glitch
#    y muestra un círculo amarillo limpio con el logo de flecha en el centro.
# =============================================================================

signal minigame_finished(success: bool)

# Nodos UI
@onready var modal_control: Control = $ModalControl
@onready var game_area: Control = $ModalControl/Panel/VBox/GameArea
@onready var lbl_title: Label = $ModalControl/Panel/VBox/Header/Titulo
@onready var lbl_status: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var lbl_score: Label = $ModalControl/Panel/VBox/Header/Metrics/LblScore
@onready var lbl_shields: Label = $ModalControl/Panel/VBox/Header/Metrics/LblShields
@onready var lbl_core_hp: Label = $ModalControl/Panel/VBox/Header/Metrics/LblCoreHp
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel
@onready var game_over_panel: PanelContainer = $ModalControl/Panel/VBox/GameArea/GameOverPanel
@onready var btn_retry: Button = $ModalControl/Panel/VBox/GameArea/GameOverPanel/VBox/BtnRetry
@onready var victory_banner: PanelContainer = $ModalControl/Panel/VBox/GameArea/VictoryBanner

# Dimensiones del campo de juego interno
const FIELD_WIDTH: float = 900.0
const FIELD_HEIGHT: float = 440.0

# Estado del Jugador (Nave Flecha NieR)
var player_pos: Vector2 = Vector2(100.0, 220.0)
var player_vel: Vector2 = Vector2.ZERO
var player_angle: float = 0.0
var player_speed: float = 340.0
var player_shields: int = 4
var max_shields: int = 4
var is_invulnerable: bool = false
var invulnerable_timer: float = 0.0
var shoot_cooldown: float = 0.14
var shoot_timer: float = 0.0
var score: int = 0
var is_game_active: bool = false

# Objeto objetivo: Núcleo Rojo (Red Core)
var red_core: Dictionary = {
	"pos": Vector2(750.0, 220.0),
	"radius": 28.0,
	"hp": 15,
	"max_hp": 15,
	"alive": true,
	"flash_timer": 0.0,
	"rot": 0.0
}

# Colecciones del escenario
var player_bullets: Array[Dictionary] = [] # pos, vel, life
var enemy_bullets: Array[Dictionary] = []  # pos, vel, life, radius
var blocks: Array[Dictionary] = []         # rect, type, hp, max_hp, alive, switch_id
var enemies: Array[Dictionary] = []        # pos, type, hp, shoot_timer, shoot_interval, alive, dir, angle
var buttons: Array[Dictionary] = []        # id, pos, radius, active, links: Array[int], timer: float
var particles: Array[Dictionary] = []      # pos, vel, col, life, max_life, size
var circuit_links: Array[Dictionary] = []  # from_pos, to_pos, active

# Constantes de Bloques
const BLOCK_DATA = 0       # Normal destructible (1-2 hits)
const BLOCK_ARMOR = 1      # Blindado (4 hits)
const BLOCK_EXPLOSIVE = 2  # Explosivo (cadena)
const BLOCK_BARRIER = 3    # Barrera láser (inmune a balas, baja con botón o evento)
const BLOCK_WALL = 4       # Muro perimetral indestructible
const BLOCK_REFLECTOR = 5  # Prisma reflector (rebota el plasma de la nave)
const BLOCK_RED_HAZARD = 6 # Caja Roja de Corrupción (¡NO TOCAR! Daña a la nave si colisiona)

# Diálogo de inducción con Jeremías
const DIALOG_BOX_SCENE: PackedScene = preload("res://scenes/ui/DialogBox.tscn")
var dialog_box_instance: Control = null
var is_tutorial_dialog_active: bool = false
var tutorial_already_shown: bool = false

const JEREMIAS_HACKING_TUTORIAL: Array[Dictionary] = [
	{
		"speaker": "JEREMÍAS",
		"text": "¡Saludos, técnico! Soy Jeremías, director de Sistemas. Te doy la bienvenida a la subrutina de hackeo y purga de anomalías tipo NieR."
	},
	{
		"speaker": "JEREMÍAS",
		"text": "Controlas una nave cursor flecha limpia y ágil. Muévete por el mapa con [W, A, S, D] o [Flechas], y apunta libremente en 360° con el ratón."
	},
	{
		"speaker": "JEREMÍAS",
		"text": "Dispara ráfagas de plasma con [Clic Izquierdo] o [Espacio]. ¡Dato clave! Tus disparos de plasma destruyen e interceptan las balas enemigas al chocar con ellas."
	},
	{
		"speaker": "JEREMÍAS",
		"text": "Encontrarás diversos sectores: romper cajas y guardianes, campos minados con Cajas Rojas que no debes tocar, rondas de amenazas e interruptores en secuencia estricta."
	},
	{
		"speaker": "JEREMÍAS",
		"text": "Para abrir las barreras láser que sellan el Núcleo, activa los interruptores [Switch] o cumple el protocolo del sector."
	},
	{
		"speaker": "JEREMÍAS",
		"text": "Cuidado con las defensas enemigas. ¡Tu misión es abrirte paso y aniquilar el Núcleo Rojo central para restaurar el sector!"
	}
]

static func get_jeremias_tutorial() -> Array[Dictionary]:
	return JEREMIAS_HACKING_TUTORIAL

# Datos de la etapa actual
var current_node_index: int = 26
var current_stage_index: int = 0
var stage_title: String = "ANOMALÍA // GLITCH FORENSE VRAM"

# Estados y mecánicas de etapas variadas
var stage1_guardians_alive: int = 0
var stage1_barrier_cleared: bool = false
var stage3_enemies_remaining: int = 0
var stage3_barrier_cleared: bool = false
var stage4_current_step: int = 1
var stage4_barrier_cleared: bool = false
var stage_status_override: String = ""
var stage_status_timer: float = 0.0

# Efectos visuales de pantalla y glitch
var screen_shake_amp: float = 0.0
var render_canvas: Control = null

# Generador de audio procedural para efectos cyberpunk
var audio_player: AudioStreamPlayer = null
var audio_generator: AudioStreamGenerator = null
var audio_playback: AudioStreamGeneratorPlayback = null
var sfx_queue: Array[Dictionary] = []

func _ready() -> void:
	layer = 12
	_setup_audio_synth()
	_setup_canvas()
	
	if btn_cancel:
		btn_cancel.pressed.connect(_on_cancel_pressed)
	if btn_retry:
		btn_retry.pressed.connect(_start_game)
		
	if game_over_panel:
		game_over_panel.visible = false
	if victory_banner:
		victory_banner.visible = false

	# Si se configuraron datos de etapa estática previa a instanciar la escena
	if not pending_stage_data.is_empty():
		current_node_index = pending_stage_data.get("number", 26)
		current_stage_index = pending_stage_data.get("stage_index", current_node_index - 26)
		stage_title = pending_stage_data.get("title", "ANOMALÍA // CORRUPCIÓN DE KERNEL")
		pending_stage_data.clear()

	# Iniciar la etapa correspondiente
	_start_game()

func _exit_tree() -> void:
	is_game_active = false
	sfx_queue.clear()
	if is_instance_valid(audio_player):
		if audio_player.playing:
			audio_player.stop()
		audio_player.stream = null
	audio_generator = null
	audio_playback = null

func setup_hacking(node_data: Dictionary) -> void:
	current_node_index = node_data.get("number", 26)
	current_stage_index = node_data.get("stage_index", current_node_index - 26)
	stage_title = node_data.get("title", "ANOMALÍA // CORRUPCIÓN DE KERNEL")
	if is_node_ready():
		_start_game()

func _unhandled_input(event: InputEvent) -> void:
	if is_tutorial_dialog_active:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_skip_tutorial_dialog()
			return
		elif (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed and not event.echo and (event.keycode in [KEY_SPACE, KEY_ENTER, KEY_E])):
			if is_instance_valid(dialog_box_instance) and dialog_box_instance.is_active:
				get_viewport().set_input_as_handled()
				if dialog_box_instance.is_typing:
					dialog_box_instance._finish_typing()
				else:
					dialog_box_instance.close_dialog()
				return
		return

	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		_on_cancel_pressed()

func _setup_audio_synth() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_generator = AudioStreamGenerator.new()
	audio_generator.mix_rate = 22050.0
	audio_generator.buffer_length = 0.15
	audio_player.stream = audio_generator
	audio_player.bus = "Master"
	add_child(audio_player)
	audio_player.play()
	audio_playback = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback

func _setup_canvas() -> void:
	if render_canvas != null:
		return
	render_canvas = Control.new()
	render_canvas.name = "RenderCanvas"
	render_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	render_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_area.add_child(render_canvas)
	render_canvas.draw.connect(_on_render_canvas_draw)

func _start_game() -> void:
	is_game_active = true
	score = 0
	player_shields = max_shields
	is_invulnerable = false
	invulnerable_timer = 0.0
	screen_shake_amp = 0.0
	player_bullets.clear()
	enemy_bullets.clear()
	particles.clear()
	circuit_links.clear()
	
	stage1_guardians_alive = 0
	stage1_barrier_cleared = false
	stage3_enemies_remaining = 0
	stage3_barrier_cleared = false
	stage4_current_step = 1
	stage4_barrier_cleared = false
	stage_status_override = ""
	stage_status_timer = 0.0
	
	if game_over_panel:
		game_over_panel.visible = false
	if victory_banner:
		victory_banner.visible = false
		
	_build_stage_layout(current_stage_index)
	_update_ui()
	_play_sfx("start")

	if current_stage_index == 0 and not tutorial_already_shown:
		_start_jeremias_tutorial()

func _start_jeremias_tutorial() -> void:
	if not is_instance_valid(dialog_box_instance):
		dialog_box_instance = DIALOG_BOX_SCENE.instantiate()
		modal_control.add_child(dialog_box_instance)
	is_tutorial_dialog_active = true
	dialog_box_instance.show_sequence(JEREMIAS_HACKING_TUTORIAL, _on_jeremias_tutorial_completed)

func _skip_tutorial_dialog() -> void:
	if is_instance_valid(dialog_box_instance):
		dialog_box_instance.visible = false
		dialog_box_instance.is_active = false
	_on_jeremias_tutorial_completed()

func _on_jeremias_tutorial_completed() -> void:
	is_tutorial_dialog_active = false
	tutorial_already_shown = true
	_play_sfx("start")

# =============================================================================
# CONSTRUCCIÓN DE LOS 6 NIVELES DE HACKEO VARIADOS
# =============================================================================
func _build_stage_layout(stage_idx: int) -> void:
	blocks.clear()
	enemies.clear()
	buttons.clear()
	circuit_links.clear()
	
	# Bordes perimetrales de seguridad del ciberespacio
	_add_wall_rect(Rect2(0, 0, FIELD_WIDTH, 14))
	_add_wall_rect(Rect2(0, FIELD_HEIGHT - 14, FIELD_WIDTH, 14))
	_add_wall_rect(Rect2(0, 0, 14, FIELD_HEIGHT))
	_add_wall_rect(Rect2(FIELD_WIDTH - 14, 0, 14, FIELD_HEIGHT))
	
	match stage_idx:
		0:
			# --- ETAPA 0 (Nodo 26): INDUCCIÓN & PROTOCOLO NIE-R // TUTORIAL CON JEREMÍAS ---
			# Nivel didáctico con la nave limpia sin glitch: controles, disparo y destrucción de núcleo
			player_pos = Vector2(90, 220)
			red_core = {"pos": Vector2(780, 220), "radius": 26.0, "hp": 12, "max_hp": 12, "alive": true, "flash_timer": 0.0, "rot": 0.0}
			
			# Barrera láser que protege el Núcleo Rojo
			_add_barrier(Rect2(650, 60, 18, 320), 0)
			# Botón Switch [A] en zona superior
			_add_button(0, Vector2(450, 90), 22.0, [0])
			_add_circuit_link(Vector2(450, 90), Vector2(650, 220))
			
			# Bloques de datos protegiendo el camino inicial
			for y in range(4):
				_add_data_block(Rect2(260, 80 + y * 75, 36, 55), 2)
			_add_reflector_block(Rect2(260, 350, 36, 36))
				
			# 1 Torreta defensiva para practicar el derribo de balas enemigas
			_add_turret(Vector2(450, 350), 2.4)
			
		1:
			# --- ETAPA 1 (Nodo 27): ROMPER CAJAS, 2 ENEMIGOS Y DESTRUIR EL NÚCLEO ---
			# Objetivo expreso: Romper el muro de cajas, abatir a los 2 enemigos guardianes y después romper el núcleo.
			player_pos = Vector2(90, 220)
			red_core = {"pos": Vector2(780, 220), "radius": 28.0, "hp": 16, "max_hp": 16, "alive": true, "flash_timer": 0.0, "rot": 0.0}
			
			# Barrera que sella el Núcleo hasta que los 2 enemigos guardianes sean eliminados
			_add_barrier(Rect2(660, 60, 18, 320), 10)
			_add_button(10, Vector2(610, 220), 20.0, [10])
			_add_circuit_link(Vector2(610, 220), Vector2(660, 220))
			
			# Muro defensivo de cajas de datos y blindadas que hay que romper
			for y in range(5):
				_add_data_block(Rect2(270, 60 + y * 68, 36, 52), 2)
			for y in range(3):
				_add_armor_block(Rect2(480, 90 + y * 95, 36, 55))
			_add_reflector_block(Rect2(360, 45, 36, 36))
			_add_reflector_block(Rect2(360, 360, 36, 36))
			
			# Exactamente 2 enemigos guardianes
			_add_spread_turret(Vector2(380, 140), 2.2)
			_add_patrol_drone(Vector2(380, 290), Vector2(0, 1), 160.0, 1.8)
			stage1_guardians_alive = 2
			stage1_barrier_cleared = false
			
		2:
			# --- ETAPA 2 (Nodo 28): CAMPO MINADO · NO TOCAR LAS CAJAS ROJAS ---
			# Objetivo expreso: Navegar el pasillo de Cajas Rojas de corrupción SIN TOCARLAS con la nave para llegar al Núcleo.
			player_pos = Vector2(80, 80)
			red_core = {"pos": Vector2(800, 360), "radius": 28.0, "hp": 18, "max_hp": 18, "alive": true, "flash_timer": 0.0, "rot": 0.0}
			
			# Barrera que protege la bahía del Núcleo
			_add_barrier(Rect2(680, 260, 18, 160), 20)
			_add_button(20, Vector2(450, 370), 20.0, [20])
			_add_circuit_link(Vector2(450, 370), Vector2(680, 340))
			
			# Laberinto de CAJAS ROJAS (BLOCK_RED_HAZARD): ¡Dañan a la nave si las toca!
			# Columna 1 de cajas rojas (cierra arriba, paso abajo)
			for y in range(4):
				_add_red_hazard_block(Rect2(200, 20 + y * 65, 38, 55))
			# Columna 2 de cajas rojas (cierra abajo, paso arriba)
			for y in range(4):
				_add_red_hazard_block(Rect2(380, 160 + y * 65, 38, 55))
			# Columna 3 de cajas rojas (cierra arriba, paso abajo)
			for y in range(4):
				_add_red_hazard_block(Rect2(560, 20 + y * 65, 38, 55))
				
			# Cajas de datos normales destruibles como atajos
			_add_data_block(Rect2(200, 290, 38, 45), 2)
			_add_data_block(Rect2(380, 90, 38, 45), 2)
			_add_data_block(Rect2(560, 290, 38, 45), 2)
			_add_reflector_block(Rect2(100, 370, 36, 36))
			
			# Enemigos que disparan proyectiles a esquivar mientras se pilotea entre cajas rojas
			_add_turret(Vector2(450, 80), 2.2)
			_add_patrol_drone(Vector2(640, 180), Vector2(0, 1), 160.0, 1.8)
			
		3:
			# --- ETAPA 3 (Nodo 29): RONDA DE AMENAZAS · ENJAMBRE DEFENSIVO ---
			# Objetivo expreso: Eliminar la ronda completa de enemigos para desactivar el cortafuegos y acceder al Núcleo.
			player_pos = Vector2(90, 220)
			red_core = {"pos": Vector2(800, 220), "radius": 28.0, "hp": 20, "max_hp": 20, "alive": true, "flash_timer": 0.0, "rot": 0.0}
			
			# Barrera principal que solo se retira al matar a toda la ronda
			_add_barrier(Rect2(680, 60, 20, 320), 300)
			_add_button(300, Vector2(740, 90), 20.0, [300])
			_add_circuit_link(Vector2(740, 90), Vector2(680, 220))
			
			# Coberturas y prismas en la arena
			for y in range(3):
				_add_data_block(Rect2(240, 100 + y * 85, 34, 50), 2)
			_add_reflector_block(Rect2(170, 80, 40, 40))
			_add_reflector_block(Rect2(170, 320, 40, 40))
			_add_explosive_block(Rect2(420, 200, 40, 40))
			
			# Ronda de enemigos: 5 amenazas tácticas activas
			_add_spread_turret(Vector2(320, 90), 2.1)
			_add_spread_turret(Vector2(320, 350), 2.1)
			_add_turret(Vector2(500, 220), 2.0)
			_add_patrol_drone(Vector2(420, 120), Vector2(1, 0), 160.0, 1.5)
			_add_patrol_drone(Vector2(420, 310), Vector2(-1, 0), 160.0, 1.5)
			
			stage3_enemies_remaining = 5
			stage3_barrier_cleared = false
			
		4:
			# --- ETAPA 4 (Nodo 30): SECUENCIA DE INTERRUPTORES EN ORDEN ---
			# Objetivo expreso: Tocar los 3 botones en orden estricto [ 1 ➔ 2 ➔ 3 ] y después romper el núcleo.
			player_pos = Vector2(80, 220)
			red_core = {"pos": Vector2(790, 220), "radius": 28.0, "hp": 20, "max_hp": 20, "alive": true, "flash_timer": 0.0, "rot": 0.0}
			
			# Barrera que sella el Núcleo
			_add_barrier(Rect2(680, 60, 20, 320), 400)
			
			# 3 Botones con orden estricto secuencial: 1, 2, 3
			_add_ordered_button(1, Vector2(230, 90), 24.0, 1)
			_add_ordered_button(2, Vector2(450, 350), 24.0, 2)
			_add_ordered_button(3, Vector2(600, 100), 24.0, 3)
			_add_circuit_link(Vector2(230, 90), Vector2(450, 350))
			_add_circuit_link(Vector2(450, 350), Vector2(600, 100))
			_add_circuit_link(Vector2(600, 100), Vector2(680, 220))
			
			stage4_current_step = 1
			stage4_barrier_cleared = false
			
			# Muros protectores, bloques y prismas
			_add_armor_block(Rect2(310, 60, 22, 100))
			_add_armor_block(Rect2(530, 280, 22, 100))
			_add_reflector_block(Rect2(230, 350, 38, 38))
			_add_reflector_block(Rect2(600, 350, 38, 38))
			for i in range(3):
				_add_data_block(Rect2(370, 120 + i * 75, 32, 50), 2)
				
			# Defensas del sector
			_add_spread_turret(Vector2(450, 100), 2.2)
			_add_patrol_drone(Vector2(370, 220), Vector2(0, 1), 140.0, 1.6)
			
		5:
			# --- ETAPA 5 (Nodo 31): PURGA RAÍZ · NÚCLEO JEFE CON SATÉLITES GIRATORIOS ---
			# Objetivo: El Núcleo Maestro posee 4 satélites rotatorios que bloquean disparos y torretas de asedio.
			player_pos = Vector2(100, 220)
			red_core = {
				"pos": Vector2(600, 220),
				"radius": 36.0,
				"hp": 30,
				"max_hp": 30,
				"alive": true,
				"flash_timer": 0.0,
				"rot": 0.0,
				"has_satellites": true,
				"satellites_count": 4,
				"orbit_radius": 88.0
			}
			
			# Barrera principal
			_add_barrier(Rect2(400, 70, 20, 300), 0)
			
			# 2 Interruptores de sobrecarga (uno arriba y otro abajo)
			_add_button(0, Vector2(200, 90), 22.0, [0])
			_add_button(1, Vector2(200, 350), 22.0, [0])
			_add_circuit_link(Vector2(200, 90), Vector2(400, 150))
			_add_circuit_link(Vector2(200, 350), Vector2(400, 290))
			
			# Prismas reflectores perimetrales
			_add_reflector_block(Rect2(310, 75, 42, 42))
			_add_reflector_block(Rect2(310, 325, 42, 42))
			_add_reflector_block(Rect2(810, 75, 42, 42))
			_add_reflector_block(Rect2(810, 325, 42, 42))
			
			# Coberturas y explosivos
			for y in range(4):
				_add_armor_block(Rect2(250, 75 + y * 75, 36, 50))
			_add_explosive_block(Rect2(250, 185, 36, 36))
			_add_explosive_block(Rect2(250, 255, 36, 36))
			
			# 2 Torretas Spread y 2 Drones escolta rápidos
			_add_spread_turret(Vector2(510, 70), 1.8)
			_add_spread_turret(Vector2(510, 370), 1.8)
			_add_patrol_drone(Vector2(700, 130), Vector2(0, 1), 180.0, 1.3)
			_add_patrol_drone(Vector2(780, 220), Vector2(-1, 0), 140.0, 1.4)

func _add_data_block(r: Rect2, hp: int = 2) -> void:
	blocks.append({"rect": r, "type": BLOCK_DATA, "hp": hp, "max_hp": hp, "alive": true, "switch_id": -1})

func _add_armor_block(r: Rect2) -> void:
	blocks.append({"rect": r, "type": BLOCK_ARMOR, "hp": 4, "max_hp": 4, "alive": true, "switch_id": -1})

func _add_explosive_block(r: Rect2) -> void:
	blocks.append({"rect": r, "type": BLOCK_EXPLOSIVE, "hp": 1, "max_hp": 1, "alive": true, "switch_id": -1})

func _add_reflector_block(r: Rect2) -> void:
	blocks.append({"rect": r, "type": BLOCK_REFLECTOR, "hp": 9999, "max_hp": 9999, "alive": true, "switch_id": -1})

func _add_red_hazard_block(r: Rect2) -> void:
	blocks.append({"rect": r, "type": BLOCK_RED_HAZARD, "hp": 9999, "max_hp": 9999, "alive": true, "switch_id": -1})

func _add_barrier(r: Rect2, switch_id: int) -> void:
	blocks.append({"rect": r, "type": BLOCK_BARRIER, "hp": 999, "max_hp": 999, "alive": true, "switch_id": switch_id})

func _add_wall_rect(r: Rect2) -> void:
	blocks.append({"rect": r, "type": BLOCK_WALL, "hp": 9999, "max_hp": 9999, "alive": true, "switch_id": -1})

func _add_button(id: int, pos: Vector2, radius: float, links: Array[int]) -> void:
	buttons.append({"id": id, "pos": pos, "radius": radius, "active": false, "links": links, "pulse": 0.0, "order": 0})

func _add_ordered_button(id: int, pos: Vector2, radius: float, order: int, links: Array[int] = []) -> void:
	buttons.append({"id": id, "pos": pos, "radius": radius, "active": false, "links": links, "pulse": 0.0, "order": order})

func _clear_barriers_with_id(id: int) -> void:
	for b in blocks:
		if b["type"] == BLOCK_BARRIER and (b["switch_id"] == id or id == -1):
			b["alive"] = false
			_spawn_block_shatter_particles(b["rect"])

func _add_circuit_link(from_p: Vector2, to_p: Vector2) -> void:
	circuit_links.append({"from": from_p, "to": to_p, "active": false})

func _add_turret(pos: Vector2, interval: float = 2.0) -> void:
	enemies.append({"pos": pos, "type": "turret", "hp": 3, "shoot_timer": randf() * interval, "shoot_interval": interval, "alive": true, "dir": Vector2.ZERO, "angle": 0.0})

func _add_spread_turret(pos: Vector2, interval: float = 2.4) -> void:
	enemies.append({"pos": pos, "type": "spread_turret", "hp": 4, "shoot_timer": randf() * interval, "shoot_interval": interval, "alive": true, "dir": Vector2.ZERO, "angle": 0.0})

func _add_patrol_drone(pos: Vector2, dir: Vector2, range_dist: float, interval: float = 1.8) -> void:
	enemies.append({
		"pos": pos,
		"origin": pos,
		"type": "drone",
		"hp": 2,
		"shoot_timer": randf() * interval,
		"shoot_interval": interval,
		"alive": true,
		"dir": dir.normalized(),
		"range": range_dist,
		"dist_traveled": 0.0,
		"angle": 0.0
	})

# =============================================================================
# BUCLE PRINCIPAL DE FÍSICAS Y MECÁNICAS
# =============================================================================
func _process(delta: float) -> void:
	_update_audio_buffer()
	if not is_game_active:
		if render_canvas:
			render_canvas.queue_redraw()
		return
		
	_process_player(delta)
	_process_bullets(delta)
	_process_enemies(delta)
	_process_red_core(delta)
	_process_buttons(delta)
	_process_particles(delta)
	
	if stage_status_timer > 0.0:
		stage_status_timer -= delta
		if stage_status_timer <= 0.0:
			stage_status_override = ""
			_update_ui()
	
	if screen_shake_amp > 0.0:
		screen_shake_amp = maxf(0.0, screen_shake_amp - delta * 12.0)
		game_area.position = Vector2(randf_range(-screen_shake_amp, screen_shake_amp), randf_range(-screen_shake_amp, screen_shake_amp))
	else:
		game_area.position = Vector2.ZERO
		
	if render_canvas:
		render_canvas.queue_redraw()

func _process_player(delta: float) -> void:
	if is_tutorial_dialog_active:
		return
	if invulnerable_timer > 0.0:
		invulnerable_timer -= delta
		if invulnerable_timer <= 0.0:
			is_invulnerable = false
			
	# Entrada de movimiento (WASD / Flechas)
	var input_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1.0
		
	input_dir = input_dir.normalized()
	var target_vel = input_dir * player_speed
	player_vel = player_vel.lerp(target_vel, 12.0 * delta)
	
	var next_pos = player_pos + player_vel * delta
	next_pos.x = clampf(next_pos.x, 22.0, FIELD_WIDTH - 22.0)
	next_pos.y = clampf(next_pos.y, 22.0, FIELD_HEIGHT - 22.0)
	
	# Colisión del jugador con bloques sólidos, muros y Cajas Rojas (BLOCK_RED_HAZARD)
	var p_rect = Rect2(next_pos.x - 12.0, next_pos.y - 12.0, 24.0, 24.0)
	var collided = false
	var touched_hazard = false
	for b in blocks:
		if b["alive"] and b["rect"].intersects(p_rect):
			collided = true
			if b["type"] == BLOCK_RED_HAZARD:
				touched_hazard = true
			break
	if not collided:
		player_pos = next_pos
	else:
		# Deslizamiento por ejes
		var try_x = Vector2(next_pos.x, player_pos.y)
		var coll_x = false
		for b in blocks:
			if b["alive"] and b["rect"].intersects(Rect2(try_x.x - 12, try_x.y - 12, 24, 24)):
				coll_x = true
				if b["type"] == BLOCK_RED_HAZARD:
					touched_hazard = true
				break
		if not coll_x:
			player_pos = try_x
		else:
			var try_y = Vector2(player_pos.x, next_pos.y)
			var coll_y = false
			for b in blocks:
				if b["alive"] and b["rect"].intersects(Rect2(try_y.x - 12, try_y.y - 12, 24, 24)):
					coll_y = true
					if b["type"] == BLOCK_RED_HAZARD:
						touched_hazard = true
					break
			if not coll_y:
				player_pos = try_y
				
	if touched_hazard and not is_invulnerable:
		_player_take_hazard_damage()
				
	# Apuntado estilo NieR: Automata (Hacia el puntero del ratón o dirección de movimiento)
	var mouse_p = game_area.get_local_mouse_position()
	if mouse_p.distance_to(player_pos) > 15.0:
		var target_ang = (mouse_p - player_pos).angle()
		player_angle = rotate_toward(player_angle, target_ang, 18.0 * delta)
	elif input_dir.length_squared() > 0.1:
		var target_ang = input_dir.angle()
		player_angle = rotate_toward(player_angle, target_ang, 18.0 * delta)
		
	# Disparo estilo NieR (Click izquierdo o Espacio)
	shoot_timer -= delta
	if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_SPACE)) and shoot_timer <= 0.0:
		_shoot_player_bullet()
		shoot_timer = shoot_cooldown

func _shoot_player_bullet() -> void:
	var forward = Vector2.from_angle(player_angle)
	var perp = Vector2(-forward.y, forward.x)
	var speed = 640.0
	
	# Disparo dual paralelo de plasma (icónico de la nave cursor NieR)
	var p1 = player_pos + forward * 14.0 + perp * 6.0
	var p2 = player_pos + forward * 14.0 - perp * 6.0
	
	player_bullets.append({"pos": p1, "vel": forward * speed, "life": 1.2, "is_reflected": false})
	player_bullets.append({"pos": p2, "vel": forward * speed, "life": 1.2, "is_reflected": false})
	_play_sfx("shoot")

func _process_bullets(delta: float) -> void:
	if is_tutorial_dialog_active:
		return
	# 1. Balas del Jugador
	var kept_p_bullets: Array[Dictionary] = []
	for b in player_bullets:
		b["pos"] += b["vel"] * delta
		b["life"] -= delta
		if b["life"] <= 0.0:
			continue
			
		var hit = false
		var b_pos: Vector2 = b["pos"]
		
		# Impacto contra Núcleo Rojo
		if red_core["alive"] and b_pos.distance_to(red_core["pos"]) < red_core["radius"] + 4.0:
			_hit_red_core(1)
			_spawn_hit_spark(b_pos, Color(1.0, 0.2, 0.3))
			hit = true
			
		# Impacto contra Satélites orbitantes si existen
		if not hit and red_core["alive"] and red_core.get("has_satellites", false):
			var orbit_r = red_core.get("orbit_radius", 88.0)
			var orb_rot = red_core["rot"]
			var s_count = red_core.get("satellites_count", 4)
			for s_idx in range(s_count):
				var ang = orb_rot + float(s_idx) * (TAU / float(s_count))
				var sat_pos = red_core["pos"] + Vector2.from_angle(ang) * orbit_r
				if b_pos.distance_to(sat_pos) < 16.0:
					_spawn_hit_spark(b_pos, Color(1.0, 0.8, 0.2))
					_play_sfx("armor_hit")
					hit = true
					break
					
		# Impacto contra Bloques
		if not hit:
			for blk in blocks:
				if blk["alive"] and blk["rect"].has_point(b_pos):
					if blk["type"] == BLOCK_REFLECTOR:
						var b_center = blk["rect"].get_center()
						var diff = b_pos - b_center
						var extents = blk["rect"].size * 0.5
						var norm = Vector2.ZERO
						if abs(diff.x / maxf(extents.x, 1.0)) > abs(diff.y / maxf(extents.y, 1.0)):
							norm = Vector2(sign(diff.x), 0)
						else:
							norm = Vector2(0, sign(diff.y))
						b["vel"] = b["vel"].bounce(norm)
						b["pos"] += norm * 5.0
						b["is_reflected"] = true
						_spawn_hit_spark(b_pos, Color(0.2, 1.0, 0.7))
						_play_sfx("armor_hit")
						hit = false
						break
					elif blk["type"] == BLOCK_RED_HAZARD:
						_spawn_hit_spark(b_pos, Color(1.0, 0.1, 0.2))
						_play_sfx("armor_hit")
						hit = true
						break
					else:
						_damage_block(blk)
						_spawn_hit_spark(b_pos, Color(0.2, 0.9, 1.0) if blk["type"] == BLOCK_DATA else Color(1.0, 0.6, 0.1))
						hit = true
						break
					
		# Impacto contra Botones/Interruptores (Se pueden activar disparándoles)
		if not hit:
			for btn in buttons:
				if b_pos.distance_to(btn["pos"]) < btn["radius"] + 4.0:
					if not btn["active"]:
						_activate_button(btn)
					_spawn_hit_spark(b_pos, Color(0.2, 1.0, 0.5))
					hit = true
					break
					
		# Impacto contra Enemigos
		if not hit:
			for e in enemies:
				if e["alive"] and b_pos.distance_to(e["pos"]) < 18.0:
					_damage_enemy(e)
					_spawn_hit_spark(b_pos, Color(1.0, 0.4, 0.2))
					hit = true
					break
					
		# Mecánica NieR: Las balas del jugador destruyen las balas enemigas
		if not hit:
			for eb in enemy_bullets:
				if b_pos.distance_to(eb["pos"]) < 14.0:
					eb["life"] = -1.0 # Destruir bala enemiga
					_spawn_hit_spark(b_pos, Color(1.0, 0.7, 0.2))
					_play_sfx("bullet_pop")
					hit = true
					break
					
		if not hit:
			kept_p_bullets.append(b)
			
	player_bullets = kept_p_bullets
	
	# 2. Balas Enemigas
	var kept_e_bullets: Array[Dictionary] = []
	for eb in enemy_bullets:
		eb["pos"] += eb["vel"] * delta
		eb["life"] -= delta
		if eb["life"] <= 0.0:
			continue
			
		var eb_pos: Vector2 = eb["pos"]
		var e_hit = false
		
		# Impacto contra Jugador
		if not is_invulnerable and eb_pos.distance_to(player_pos) < 16.0:
			_player_take_damage()
			_spawn_hit_spark(eb_pos, Color(1.0, 0.1, 0.2))
			e_hit = true
			
		# Impacto contra bloques sólidos
		if not e_hit:
			for blk in blocks:
				if blk["alive"] and blk["rect"].has_point(eb_pos):
					if blk["type"] == BLOCK_EXPLOSIVE:
						_explode_block(blk)
					e_hit = true
					break
					
		if not e_hit:
			kept_e_bullets.append(eb)
			
	enemy_bullets = kept_e_bullets

func _damage_block(b: Dictionary) -> void:
	if b["type"] == BLOCK_WALL or b["type"] == BLOCK_BARRIER or b["type"] == BLOCK_REFLECTOR or b["type"] == BLOCK_RED_HAZARD:
		_play_sfx("armor_hit")
		return
	if b["type"] == BLOCK_EXPLOSIVE:
		_explode_block(b)
		return
		
	b["hp"] -= 1
	if b["hp"] <= 0:
		b["alive"] = false
		score += 50
		_play_sfx("block_shatter")
		_spawn_block_shatter_particles(b["rect"])
	else:
		_play_sfx("armor_hit")

func _explode_block(b: Dictionary) -> void:
	if not b["alive"]:
		return
	b["alive"] = false
	var c_pos = b["rect"].get_center()
	score += 100
	screen_shake_amp = 7.0
	_play_sfx("explosion")
	
	# Onda expansiva que destruye bloques adyacentes y daña enemigos
	var blast_radius = 85.0
	for other in blocks:
		if other["alive"] and other != b:
			if other["rect"].get_center().distance_to(c_pos) < blast_radius:
				if other["type"] == BLOCK_EXPLOSIVE:
					_explode_block(other) # Reacción en cadena
				elif other["type"] != BLOCK_WALL and other["type"] != BLOCK_BARRIER and other["type"] != BLOCK_REFLECTOR and other["type"] != BLOCK_RED_HAZARD:
					other["hp"] -= 3
					if other["hp"] <= 0:
						other["alive"] = false
						_spawn_block_shatter_particles(other["rect"])
						
	for e in enemies:
		if e["alive"] and e["pos"].distance_to(c_pos) < blast_radius:
			e["hp"] -= 3
			if e["hp"] <= 0:
				e["alive"] = false
				score += 200
				_spawn_explosion_particles(e["pos"], Color(1.0, 0.4, 0.1))
				_check_stage_progression()
				
	for eb in enemy_bullets:
		if eb["pos"].distance_to(c_pos) < blast_radius:
			eb["life"] = -1.0
			
	_spawn_explosion_particles(c_pos, Color(1.0, 0.8, 0.1))

func _damage_enemy(e: Dictionary) -> void:
	e["hp"] -= 1
	if e["hp"] <= 0:
		e["alive"] = false
		score += 150
		screen_shake_amp = 4.0
		_play_sfx("explosion")
		_spawn_explosion_particles(e["pos"], Color(1.0, 0.5, 0.2))
		_check_stage_progression()
	else:
		_play_sfx("armor_hit")

func _check_stage_progression() -> void:
	if current_stage_index == 1 and not stage1_barrier_cleared:
		var alive_count = 0
		for e in enemies:
			if e["alive"]:
				alive_count += 1
		stage1_guardians_alive = alive_count
		if alive_count <= 0:
			stage1_barrier_cleared = true
			_clear_barriers_with_id(10)
			_play_sfx("button_on")
			stage_status_override = "¡GUARDIANES DESTRUIDOS! CORTAFUEGOS DEL NÚCLEO DESACTIVADO"
			stage_status_timer = 3.5
		_update_ui()
	elif current_stage_index == 3 and not stage3_barrier_cleared:
		var alive_count = 0
		for e in enemies:
			if e["alive"]:
				alive_count += 1
		stage3_enemies_remaining = alive_count
		if alive_count <= 0:
			stage3_barrier_cleared = true
			_clear_barriers_with_id(300)
			_play_sfx("victory")
			stage_status_override = "¡RONDA COMPLETADA! CORTAFUEGOS DESACTIVADO - DESTRUYE EL NÚCLEO"
			stage_status_timer = 4.0
		_update_ui()

func _process_enemies(delta: float) -> void:
	if is_tutorial_dialog_active:
		return
	for e in enemies:
		if not e["alive"]:
			continue
			
		e["shoot_timer"] -= delta
		if e["type"] == "turret":
			# Torreta apunta suavemente hacia el jugador
			var target_ang = (player_pos - e["pos"]).angle()
			e["angle"] = rotate_toward(e["angle"], target_ang, 2.5 * delta)
			if e["shoot_timer"] <= 0.0:
				_shoot_turret(e)
				e["shoot_timer"] = e["shoot_interval"]
		elif e["type"] == "spread_turret":
			# Torreta Spread apunta y dispara en abanico triple
			var target_ang = (player_pos - e["pos"]).angle()
			e["angle"] = rotate_toward(e["angle"], target_ang, 2.3 * delta)
			if e["shoot_timer"] <= 0.0:
				_shoot_spread_turret(e)
				e["shoot_timer"] = e["shoot_interval"]
		elif e["type"] == "drone":
			# Drone patrulla linealmente
			var move_speed = 90.0
			var next_pos = e["pos"] + e["dir"] * (move_speed * delta)
			e["dist_traveled"] += move_speed * delta
			if e["dist_traveled"] >= e["range"]:
				e["dir"] = -e["dir"]
				e["dist_traveled"] = 0.0
			e["pos"] = next_pos
			e["angle"] = (player_pos - e["pos"]).angle()
			if e["shoot_timer"] <= 0.0:
				_shoot_drone(e)
				e["shoot_timer"] = e["shoot_interval"]

func _shoot_turret(e: Dictionary) -> void:
	var forward = Vector2.from_angle(e["angle"])
	var bullet_speed = 190.0
	enemy_bullets.append({"pos": e["pos"] + forward * 16.0, "vel": forward * bullet_speed, "life": 4.5, "radius": 5.0})
	_play_sfx("turret_shoot")

func _shoot_spread_turret(e: Dictionary) -> void:
	var base_ang = e["angle"]
	var bullet_speed = 195.0
	for ang_offset in [-0.26, 0.0, 0.26]:
		var forward = Vector2.from_angle(base_ang + ang_offset)
		enemy_bullets.append({"pos": e["pos"] + forward * 18.0, "vel": forward * bullet_speed, "life": 4.2, "radius": 5.0})
	_play_sfx("turret_shoot")

func _shoot_drone(e: Dictionary) -> void:
	var forward = Vector2.from_angle(e["angle"])
	var bullet_speed = 220.0
	# Disparo doble
	var perp = Vector2(-forward.y, forward.x)
	enemy_bullets.append({"pos": e["pos"] + forward * 14.0 + perp * 6.0, "vel": forward * bullet_speed, "life": 4.0, "radius": 4.5})
	enemy_bullets.append({"pos": e["pos"] + forward * 14.0 - perp * 6.0, "vel": forward * bullet_speed, "life": 4.0, "radius": 4.5})
	_play_sfx("turret_shoot")

func _process_red_core(delta: float) -> void:
	if not red_core["alive"]:
		return
	red_core["rot"] += delta * 1.5
	if red_core["flash_timer"] > 0.0:
		red_core["flash_timer"] -= delta

func _hit_red_core(dmg: int) -> void:
	if not red_core["alive"]:
		return
	red_core["hp"] -= dmg
	red_core["flash_timer"] = 0.12
	screen_shake_amp = 5.0
	score += 100
	_play_sfx("core_hit")
	_update_ui()
	
	if red_core["hp"] <= 0:
		_victory()

func _process_buttons(delta: float) -> void:
	for btn in buttons:
		btn["pulse"] = fmod(btn["pulse"] + delta * 3.0, TAU)
		# Activar si el jugador pisa el botón
		if not btn["active"] and player_pos.distance_to(btn["pos"]) < btn["radius"] + 8.0:
			_activate_button(btn)

func _activate_button(btn: Dictionary) -> void:
	var ord_val: int = btn.get("order", 0)
	if ord_val > 0:
		# Lógica de secuencia para Stage 4
		if ord_val == stage4_current_step + 1:
			stage4_current_step += 1
			btn["active"] = true
			score += 300
			_play_sfx("button_on")
			_spawn_explosion_particles(btn["pos"], Color(0.2, 1.0, 0.6))
			
			if stage4_current_step >= 3:
				stage4_barrier_cleared = true
				_clear_barriers_with_id(400)
				stage_status_override = "¡SECUENCIA CORRECTA (1-2-3)! CORTAFUEGOS DESACTIVADO"
				stage_status_timer = 4.0
				_play_sfx("victory")
			else:
				stage_status_override = "✓ BOTÓN %d ACTIVADO · SIGUIENTE: BOTÓN %d" % [stage4_current_step, stage4_current_step + 1]
				stage_status_timer = 2.5
			_update_ui()
		else:
			# Orden incorrecto: resetear botones ordenados y sonar error
			_play_sfx("error")
			screen_shake_amp = 7.0
			stage4_current_step = 0
			for b in buttons:
				if b.get("order", 0) > 0:
					b["active"] = false
			stage_status_override = "¡ERROR DE SECUENCIA! ORDEN INCORRECTO · REINICIANDO A BOTÓN 1"
			stage_status_timer = 3.0
			_update_ui()
		return

	# Lógica normal para interruptores convencionales
	btn["active"] = true
	score += 250
	_play_sfx("button_on")
	_spawn_explosion_particles(btn["pos"], Color(0.2, 1.0, 0.6))
	
	# Desactivar barreras enlazadas
	var target_ids: Array = btn["links"]
	for b in blocks:
		if b["type"] == BLOCK_BARRIER and b["switch_id"] in target_ids:
			b["alive"] = false
			_spawn_block_shatter_particles(b["rect"])
			
	# Activar enlaces de circuito
	for l in circuit_links:
		if l["from"].distance_to(btn["pos"]) < 10.0:
			l["active"] = true

func _player_take_damage() -> void:
	if is_invulnerable:
		return
	player_shields -= 1
	is_invulnerable = true
	invulnerable_timer = 1.4
	screen_shake_amp = 9.0
	_play_sfx("player_hit")
	_update_ui()
	
	if player_shields <= 0:
		_game_over()

func _player_take_hazard_damage() -> void:
	if is_invulnerable:
		return
	player_shields -= 1
	is_invulnerable = true
	invulnerable_timer = 1.6
	screen_shake_amp = 11.0
	_play_sfx("hazard")
	stage_status_override = "¡ALERTA! DAÑO POR CONTACTO CON CAJA ROJA"
	stage_status_timer = 2.2
	_update_ui()
	
	if player_shields <= 0:
		_game_over()

func _game_over() -> void:
	is_game_active = false
	_play_sfx("game_over")
	if game_over_panel:
		game_over_panel.visible = true
		game_over_panel.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(game_over_panel, "modulate:a", 1.0, 0.25)

func _victory() -> void:
	is_game_active = false
	red_core["alive"] = false
	score += 1500
	screen_shake_amp = 14.0
	_play_sfx("victory")
	_spawn_explosion_particles(red_core["pos"], Color(1.0, 0.1, 0.3), 60)
	_update_ui()
	
	# Guardar progreso en SaveManager
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.has_method("mark_node_completed"):
		sm.mark_node_completed("sistema", current_node_index)
		
	if victory_banner:
		victory_banner.visible = false

	LevelSelect.initial_mode = "sistema"
	LevelSelect.initial_tab = "niveles"
	LevelSelect.pending_glitch_purge_node = current_node_index
	
	minigame_finished.emit(true)
	CyberPlayTransition.play_exit(
		get_tree(),
		"sistema",
		"res://scenes/menus/LevelSelect.tscn",
		"PURGA DE KERNEL FINALIZADA",
		"// SECTOR RESTAURADO · RETORNANDO A MATRIZ DE SISTEMAS //"
	)

func _on_cancel_pressed() -> void:
	is_game_active = false
	LevelSelect.initial_mode = "sistema"
	LevelSelect.initial_tab = "niveles"
	minigame_finished.emit(false)
	CyberPlayTransition.play_exit(
		get_tree(),
		"sistema",
		"res://scenes/menus/LevelSelect.tscn",
		"HACKEO ABORTADO",
		"// DESCONECTANDO INTERFAZ DE SISTEMAS //"
	)

func _update_ui() -> void:
	if lbl_title:
		lbl_title.text = "HACKEO // %s" % stage_title.to_upper()
	if lbl_status:
		if stage_status_override != "":
			lbl_status.text = stage_status_override
		else:
			match current_stage_index:
				0:
					lbl_status.text = "TUTORIAL: Aprende controles con Jeremías, destruye paquetes y penetra el Núcleo."
				1:
					if not stage1_barrier_cleared:
						lbl_status.text = "Rompe las cajas y destruye a los 2 guardianes (%d restantes) para abrir el núcleo." % stage1_guardians_alive
					else:
						lbl_status.text = "¡Defensas colapsadas! Destruye el Núcleo Rojo para terminar."
				2:
					lbl_status.text = "PELIGRO: ¡No toques las cajas rojas! Esquívalas con precisión para llegar al núcleo."
				3:
					if not stage3_barrier_cleared:
						lbl_status.text = "⚔️ RONDA DE AMENAZAS: Elimina los %d enemigos restantes para desactivar el escudo." % stage3_enemies_remaining
					else:
						lbl_status.text = "¡Ronda de amenazas eliminada! Destruye el Núcleo Rojo."
				4:
					if not stage4_barrier_cleared:
						lbl_status.text = "SECUENCIA: Toca los botones en orden (1 ➔ 2 ➔ 3). Siguiente: Botón %d." % (stage4_current_step + 1)
					else:
						lbl_status.text = "¡Secuencia correcta activada! Núcleo expuesto, destrúyelo."
				_:
					lbl_status.text = "Dispara a los bloques y activa interruptores para penetrar el Núcleo Rojo."
	if lbl_score:
		lbl_score.text = "PUNTUACIÓN: %05d" % score
	if lbl_shields:
		var sh_str = ""
		for i in range(max_shields):
			sh_str += "▲ " if i < player_shields else "△ "
		lbl_shields.text = "ESCUDOS: %s" % sh_str.strip_edges()
	if lbl_core_hp:
		var pct = int((float(red_core["hp"]) / float(red_core["max_hp"])) * 100.0) if red_core["alive"] else 0
		lbl_core_hp.text = "NÚCLEO ROJO: %d%%" % max(0, pct)

# =============================================================================
# PARTÍCULAS Y EFECTOS
# =============================================================================
func _process_particles(delta: float) -> void:
	var kept: Array[Dictionary] = []
	for p in particles:
		p["pos"] += p["vel"] * delta
		p["life"] -= delta
		if p["life"] > 0.0:
			kept.append(p)
	particles = kept

func _spawn_hit_spark(pos: Vector2, col: Color) -> void:
	for i in range(4):
		var ang = randf() * TAU
		var spd = randf_range(60.0, 160.0)
		particles.append({
			"pos": pos,
			"vel": Vector2.from_angle(ang) * spd,
			"col": col,
			"life": randf_range(0.12, 0.25),
			"max_life": 0.25,
			"size": randf_range(2.0, 3.5)
		})

func _spawn_block_shatter_particles(r: Rect2) -> void:
	var c = r.get_center()
	for i in range(12):
		var ang = randf() * TAU
		var spd = randf_range(80.0, 220.0)
		particles.append({
			"pos": c + Vector2(randf_range(-10, 10), randf_range(-10, 10)),
			"vel": Vector2.from_angle(ang) * spd,
			"col": Color(0.2, 0.9, 1.0, 0.9),
			"life": randf_range(0.25, 0.45),
			"max_life": 0.45,
			"size": randf_range(2.5, 4.5)
		})

func _spawn_explosion_particles(pos: Vector2, col: Color, count: int = 24) -> void:
	for i in range(count):
		var ang = randf() * TAU
		var spd = randf_range(70.0, 320.0)
		particles.append({
			"pos": pos,
			"vel": Vector2.from_angle(ang) * spd,
			"col": col,
			"life": randf_range(0.3, 0.6),
			"max_life": 0.6,
			"size": randf_range(3.0, 6.0)
		})

# =============================================================================
# RENDERIZADO VECTORIAL NIE-R AUTOMATA
# =============================================================================
func _on_render_canvas_draw() -> void:
	if render_canvas == null:
		return
		
	# 1. Cuadrícula cibernética de fondo
	_draw_cyber_grid()
	
	# 2. Enlaces de circuitos (Switches a Barreras)
	_draw_circuit_wires()
	
	# 3. Botones / Interruptores
	_draw_buttons()
	
	# 4. Bloques del mapa
	_draw_blocks()
	
	# 5. Enemigos (Torretas y Drones)
	_draw_enemies()
	
	# 6. Núcleo Rojo (Red Core)
	_draw_red_core()
	
	# 7. Balas del jugador y enemigas
	_draw_bullets()
	
	# 8. Nave Jugador (Flecha NieR)
	_draw_player_ship()
	
	# 9. Partículas
	_draw_particles()

func _draw_cyber_grid() -> void:
	var grid_col = Color(0.04, 0.14, 0.22, 0.35)
	var step = 40.0
	var x = 0.0
	while x <= FIELD_WIDTH:
		render_canvas.draw_line(Vector2(x, 0), Vector2(x, FIELD_HEIGHT), grid_col, 1.0)
		x += step
	var y = 0.0
	while y <= FIELD_HEIGHT:
		render_canvas.draw_line(Vector2(0, y), Vector2(FIELD_WIDTH, y), grid_col, 1.0)
		y += step

func _draw_circuit_wires() -> void:
	for l in circuit_links:
		var c_from: Vector2 = l["from"]
		var c_to: Vector2 = l["to"]
		var is_act: bool = l["active"]
		var wire_col = Color(0.2, 1.0, 0.5, 0.85) if is_act else Color(0.1, 0.5, 0.8, 0.35)
		render_canvas.draw_dashed_line(c_from, c_to, wire_col, 2.0, 6.0)
		# Punto luminoso viajando
		if is_act:
			var pulse_t = fmod(Time.get_ticks_msec() * 0.001 * 2.0, 1.0)
			var cur_p = c_from.lerp(c_to, pulse_t)
			render_canvas.draw_circle(cur_p, 3.5, Color.WHITE)

func _draw_buttons() -> void:
	for btn in buttons:
		var bp: Vector2 = btn["pos"]
		var br: float = btn["radius"]
		var is_act: bool = btn["active"]
		var ord_val: int = btn.get("order", 0)
		var ring_col = Color(0.2, 1.0, 0.5, 0.95) if is_act else (Color(1.0, 0.8, 0.2, 0.95) if ord_val > 0 else Color(1.0, 0.2, 0.3, 0.8))
		var bg_col = Color(0.05, 0.25, 0.12, 0.5) if is_act else (Color(0.25, 0.2, 0.05, 0.45) if ord_val > 0 else Color(0.25, 0.05, 0.08, 0.4))
		
		# Anillo exterior
		render_canvas.draw_circle(bp, br, bg_col)
		render_canvas.draw_arc(bp, br, 0, TAU, 24, ring_col, 2.2)
		# Glifo interno
		if is_act:
			render_canvas.draw_circle(bp, br * 0.45, Color(0.2, 1.0, 0.5))
			render_canvas.draw_circle(bp, br * 0.2, Color.WHITE)
		elif ord_val > 0:
			var num_font = ThemeDB.fallback_font
			var num_str = str(ord_val)
			var f_sz = 18
			var str_size = num_font.get_string_size(num_str, HORIZONTAL_ALIGNMENT_CENTER, -1, f_sz)
			render_canvas.draw_string(num_font, bp + Vector2(-str_size.x * 0.5, str_size.y * 0.35), num_str, HORIZONTAL_ALIGNMENT_CENTER, -1, f_sz, ring_col)
		else:
			render_canvas.draw_arc(bp, br * 0.55, btn["pulse"], btn["pulse"] + PI * 1.2, 12, ring_col, 2.0)
			render_canvas.draw_circle(bp, 3.0, ring_col)

func _draw_blocks() -> void:
	for b in blocks:
		if not b["alive"]:
			continue
		var r: Rect2 = b["rect"]
		match b["type"]:
			BLOCK_WALL:
				render_canvas.draw_rect(r, Color(0.06, 0.09, 0.16, 0.95))
				render_canvas.draw_rect(r, Color(0.18, 0.35, 0.55, 0.9), false, 1.5)
			BLOCK_DATA:
				# Bloque de datos NieR (cian/blanco con textura digital)
				render_canvas.draw_rect(r, Color(0.05, 0.22, 0.32, 0.85))
				render_canvas.draw_rect(r, Color(0.2, 0.85, 1.0, 0.95), false, 1.5)
				render_canvas.draw_line(r.position, r.position + r.size, Color(0.2, 0.85, 1.0, 0.3), 1.0)
			BLOCK_ARMOR:
				# Bloque blindado (Gris oscuro y cruz metálica reforzada)
				render_canvas.draw_rect(r, Color(0.14, 0.16, 0.22, 0.95))
				render_canvas.draw_rect(r, Color(0.85, 0.5, 0.15, 0.9), false, 2.0)
				render_canvas.draw_line(r.position, r.position + r.size, Color(0.85, 0.5, 0.15, 0.5), 1.2)
				render_canvas.draw_line(Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), Color(0.85, 0.5, 0.15, 0.5), 1.2)
			BLOCK_EXPLOSIVE:
				# Bloque volátil (Naranja/amarillo pulsante)
				var pulse = sin(Time.get_ticks_msec() * 0.01) * 0.2 + 0.8
				var exp_col = Color(1.0, 0.65, 0.1, pulse)
				render_canvas.draw_rect(r, Color(0.35, 0.18, 0.02, 0.85))
				render_canvas.draw_rect(r, exp_col, false, 2.0)
				# Símbolo de radiación / explosión
				render_canvas.draw_circle(r.get_center(), 4.5, exp_col)
			BLOCK_RED_HAZARD:
				# Caja Roja de advertencia / alto voltaje (Peligro crítico de contacto)
				var pulse_haz = sin(Time.get_ticks_msec() * 0.009) * 0.2 + 0.8
				render_canvas.draw_rect(r, Color(0.35, 0.04, 0.06, 0.92))
				render_canvas.draw_rect(r, Color(1.0, 0.15, 0.25, pulse_haz), false, 2.0)
				render_canvas.draw_line(r.position, r.end, Color(1.0, 0.2, 0.3, 0.75), 1.6)
				render_canvas.draw_line(Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), Color(1.0, 0.2, 0.3, 0.75), 1.6)
				render_canvas.draw_circle(r.get_center(), 3.5, Color(1.0, 0.9, 0.2, pulse_haz))
			BLOCK_REFLECTOR:
				# Prisma Reflector (Espejo Esmeralda / Cian reflectante de plasma)
				var pulse_ref = sin(Time.get_ticks_msec() * 0.008) * 0.15 + 0.85
				render_canvas.draw_rect(r, Color(0.02, 0.22, 0.16, 0.95))
				render_canvas.draw_rect(r, Color(0.2, 1.0, 0.7, pulse_ref), false, 2.0)
				var rc = r.get_center()
				var hw = r.size.x * 0.36
				var hh = r.size.y * 0.36
				var poly = PackedVector2Array([
					rc + Vector2(0, -hh),
					rc + Vector2(hw, 0),
					rc + Vector2(0, hh),
					rc + Vector2(-hw, 0)
				])
				render_canvas.draw_colored_polygon(poly, Color(0.08, 0.45, 0.32, 0.8))
				render_canvas.draw_polyline(PackedVector2Array([poly[0], poly[1], poly[2], poly[3], poly[0]]), Color(0.4, 1.0, 0.85, pulse_ref), 1.6)
				render_canvas.draw_circle(rc, 2.8, Color.WHITE)
			BLOCK_BARRIER:
				# Barrera láser holográfica (rayas de fuerza animadas)
				var phase = fmod(Time.get_ticks_msec() * 0.005, 1.0)
				render_canvas.draw_rect(r, Color(1.0, 0.15, 0.3, 0.35))
				render_canvas.draw_rect(r, Color(1.0, 0.25, 0.45, 0.95), false, 2.0)
				if r.size.x < r.size.y:
					var ly = r.position.y + phase * 20.0
					while ly < r.end.y:
						render_canvas.draw_line(Vector2(r.position.x, ly), Vector2(r.end.x, ly), Color(1.0, 0.6, 0.7, 0.8), 1.2)
						ly += 16.0
				else:
					var lx = r.position.x + phase * 20.0
					while lx < r.end.x:
						render_canvas.draw_line(Vector2(lx, r.position.y), Vector2(lx, r.end.y), Color(1.0, 0.6, 0.7, 0.8), 1.2)
						lx += 16.0

func _draw_enemies() -> void:
	for e in enemies:
		if not e["alive"]:
			continue
		var ep: Vector2 = e["pos"]
		if e["type"] == "turret":
			# Torreta poligonal de seguridad
			render_canvas.draw_circle(ep, 14.0, Color(0.18, 0.04, 0.08, 0.95))
			render_canvas.draw_arc(ep, 14.0, 0, TAU, 18, Color(1.0, 0.2, 0.35, 0.95), 2.0)
			# Cañón apuntando al ángulo
			var fwd = Vector2.from_angle(e["angle"])
			render_canvas.draw_line(ep, ep + fwd * 20.0, Color(1.0, 0.2, 0.35), 3.5)
			render_canvas.draw_circle(ep, 4.0, Color.WHITE)
		elif e["type"] == "spread_turret":
			# Torreta de 3 cañones en abanico (Spread)
			render_canvas.draw_circle(ep, 16.0, Color(0.24, 0.05, 0.06, 0.95))
			render_canvas.draw_arc(ep, 16.0, 0, TAU, 6, Color(1.0, 0.4, 0.15, 0.95), 2.2)
			for ang_off in [-0.26, 0.0, 0.26]:
				var barrel_dir = Vector2.from_angle(e["angle"] + ang_off)
				render_canvas.draw_line(ep, ep + barrel_dir * 22.0, Color(1.0, 0.45, 0.2), 3.0)
			render_canvas.draw_circle(ep, 4.5, Color(1.0, 0.9, 0.3))
			render_canvas.draw_circle(ep, 2.0, Color.WHITE)
		elif e["type"] == "drone":
			# Drone patrullero con forma de rombo
			var sz = 12.0
			var fwd = Vector2.from_angle(e["angle"])
			var perp = Vector2(-fwd.y, fwd.x)
			var pts = PackedVector2Array([
				ep + fwd * sz * 1.3,
				ep + perp * sz,
				ep - fwd * sz * 0.8,
				ep - perp * sz
			])
			render_canvas.draw_colored_polygon(pts, Color(0.3, 0.06, 0.12, 0.95))
			render_canvas.draw_polyline(pts, Color(1.0, 0.35, 0.45), 2.0)
			render_canvas.draw_circle(ep, 3.0, Color(1.0, 0.9, 0.4))

func _draw_red_core() -> void:
	if not red_core["alive"]:
		return
	var cp: Vector2 = red_core["pos"]
	var cr: float = red_core["radius"]
	var rot: float = red_core["rot"]
	var is_flash: bool = red_core["flash_timer"] > 0.0
	
	var core_col = Color.WHITE if is_flash else Color(1.0, 0.15, 0.28, 0.95)
	var glow_col = Color(1.0, 0.4, 0.5, 0.45)
	
	# Halo de radiación anómala
	render_canvas.draw_circle(cp, cr * 1.35, Color(1.0, 0.05, 0.15, 0.22))
	# Cubo rotatorio central estilo NieR
	var corners: PackedVector2Array = []
	for i in range(4):
		var ang = rot + float(i) * (PI * 0.5)
		corners.append(cp + Vector2.from_angle(ang) * cr)
	render_canvas.draw_colored_polygon(corners, Color(0.35, 0.02, 0.06, 0.95))
	render_canvas.draw_polyline(corners, core_col, 2.5)
	render_canvas.draw_line(corners[3], corners[0], core_col, 2.5)
	
	# Cruz de energía interior
	render_canvas.draw_line(corners[0], corners[2], glow_col, 1.8)
	render_canvas.draw_line(corners[1], corners[3], glow_col, 1.8)
	render_canvas.draw_circle(cp, cr * 0.35, core_col)
	render_canvas.draw_circle(cp, cr * 0.15, Color.WHITE)
	
	# Satélites orbitantes blindados
	if red_core.get("has_satellites", false):
		var orbit_r = red_core.get("orbit_radius", 88.0)
		var s_count = red_core.get("satellites_count", 4)
		for s_idx in range(s_count):
			var ang = rot + float(s_idx) * (TAU / float(s_count))
			var sat_pos = cp + Vector2.from_angle(ang) * orbit_r
			render_canvas.draw_circle(sat_pos, 11.0, Color(0.2, 0.05, 0.1, 0.9))
			render_canvas.draw_arc(sat_pos, 11.0, 0, TAU, 12, Color(1.0, 0.7, 0.15), 2.2)
			render_canvas.draw_circle(sat_pos, 3.8, Color.WHITE)

func _draw_bullets() -> void:
	# Balas del jugador (Láser azul eléctrico / cian NieR, o esmeralda si rebotó en prisma)
	for b in player_bullets:
		var bp: Vector2 = b["pos"]
		var b_vel: Vector2 = b["vel"].normalized()
		var is_ref = b.get("is_reflected", false)
		var laser_col = Color(0.2, 1.0, 0.65) if is_ref else Color(0.3, 0.95, 1.0)
		render_canvas.draw_line(bp - b_vel * 9.0, bp, laser_col, 3.0)
		render_canvas.draw_line(bp - b_vel * 4.0, bp, Color.WHITE, 1.5)
		
	# Balas enemigas (Esferas rojas/naranjas con halo)
	for eb in enemy_bullets:
		var ebp: Vector2 = eb["pos"]
		var er: float = eb.get("radius", 4.5)
		render_canvas.draw_circle(ebp, er * 1.5, Color(1.0, 0.1, 0.2, 0.35))
		render_canvas.draw_circle(ebp, er, Color(1.0, 0.35, 0.15))
		render_canvas.draw_circle(ebp, er * 0.45, Color.WHITE)

func _draw_player_ship() -> void:
	# Parpadeo si es invulnerable tras recibir daño
	if is_invulnerable and fmod(invulnerable_timer * 12.0, 1.0) < 0.5:
		return
		
	var fwd = Vector2.from_angle(player_angle)
	var perp = Vector2(-fwd.y, fwd.x)
	var sz = 16.0
	
	# Geometría auténtica de la Flecha de NieR: Automata
	var nose = player_pos + fwd * sz * 1.3
	var wing_r = player_pos - fwd * sz * 0.85 + perp * sz * 0.95
	var wing_l = player_pos - fwd * sz * 0.85 - perp * sz * 0.95
	var inner_notch = player_pos - fwd * sz * 0.35
	
	var ship_pts = PackedVector2Array([nose, wing_r, inner_notch, wing_l])
	
	# Estela de propulsión de la nave
	if player_vel.length_squared() > 100.0:
		var thrust_p = inner_notch - fwd * (randf_range(8.0, 18.0))
		render_canvas.draw_line(inner_notch, thrust_p, Color(0.2, 0.85, 1.0, 0.8), 3.0)
		render_canvas.draw_line(inner_notch, thrust_p * 0.6, Color.WHITE, 1.5)
		
	# Cuerpo blanco y cyan de la flecha NieR
	render_canvas.draw_colored_polygon(ship_pts, Color(0.04, 0.08, 0.15, 0.95))
	render_canvas.draw_polyline(PackedVector2Array([nose, wing_r, inner_notch, wing_l, nose]), Color(0.2, 0.9, 1.0), 2.2)
	# Núcleo luminoso
	render_canvas.draw_circle(player_pos + fwd * 2.0, 3.2, Color(1.0, 0.95, 0.3))
	render_canvas.draw_circle(player_pos + fwd * 2.0, 1.5, Color.WHITE)

func _draw_particles() -> void:
	for p in particles:
		var a = clampf(p["life"] / p["max_life"], 0.0, 1.0)
		var c = p["col"]
		render_canvas.draw_circle(p["pos"], p["size"] * a, Color(c.r, c.g, c.b, a))

# =============================================================================
# SINTETIZADOR DE AUDIO PROCEDURAL (SIN ARCHIVOS EXTERNOS)
# =============================================================================
func _play_sfx(sfx_name: String) -> void:
	if audio_playback == null:
		return
	match sfx_name:
		"shoot":
			sfx_queue.append({"type": "sweep", "f_start": 880.0, "f_end": 260.0, "dur": 0.07, "vol": 0.22, "t": 0.0})
		"armor_hit":
			sfx_queue.append({"type": "square", "freq": 160.0, "dur": 0.05, "vol": 0.18, "t": 0.0})
		"core_hit":
			sfx_queue.append({"type": "sweep", "f_start": 1200.0, "f_end": 440.0, "dur": 0.09, "vol": 0.32, "t": 0.0})
		"block_shatter":
			sfx_queue.append({"type": "noise", "dur": 0.08, "vol": 0.25, "t": 0.0})
		"button_on":
			sfx_queue.append({"type": "sweep", "f_start": 440.0, "f_end": 880.0, "dur": 0.14, "vol": 0.35, "t": 0.0})
		"turret_shoot":
			sfx_queue.append({"type": "sweep", "f_start": 400.0, "f_end": 150.0, "dur": 0.08, "vol": 0.20, "t": 0.0})
		"player_hit":
			sfx_queue.append({"type": "noise", "dur": 0.15, "vol": 0.40, "t": 0.0})
		"explosion":
			sfx_queue.append({"type": "noise", "dur": 0.22, "vol": 0.45, "t": 0.0})
		"bullet_pop":
			sfx_queue.append({"type": "sweep", "f_start": 600.0, "f_end": 900.0, "dur": 0.04, "vol": 0.18, "t": 0.0})
		"victory":
			sfx_queue.append({"type": "sweep", "f_start": 523.0, "f_end": 1046.0, "dur": 0.35, "vol": 0.40, "t": 0.0})
		"game_over":
			sfx_queue.append({"type": "sweep", "f_start": 350.0, "f_end": 90.0, "dur": 0.40, "vol": 0.40, "t": 0.0})
		"error":
			sfx_queue.append({"type": "square", "freq": 110.0, "dur": 0.25, "vol": 0.35, "t": 0.0})
		"hazard":
			sfx_queue.append({"type": "noise", "dur": 0.28, "vol": 0.50, "t": 0.0})
		"start":
			sfx_queue.append({"type": "sweep", "f_start": 300.0, "f_end": 750.0, "dur": 0.18, "vol": 0.28, "t": 0.0})

func _update_audio_buffer() -> void:
	if audio_playback == null or sfx_queue.is_empty():
		return
	var frames_avail = audio_playback.get_frames_available()
	if frames_avail <= 0:
		return
		
	var sample_rate = 22050.0
	var frames_to_fill = min(frames_avail, 512)
	var dt = 1.0 / sample_rate
	
	for i in range(frames_to_fill):
		var mixed_sample = 0.0
		for sfx in sfx_queue:
			sfx["t"] += dt
			var t_curr: float = sfx["t"]
			var t_max: float = sfx["dur"]
			if t_curr < t_max:
				var env = 1.0 - (t_curr / t_max)
				var v = 0.0
				if sfx["type"] == "sweep":
					var f = lerp(sfx["f_start"], sfx["f_end"], t_curr / t_max)
					v = sin(t_curr * f * TAU) * sfx["vol"] * env
				elif sfx["type"] == "square":
					var s = sin(t_curr * sfx["freq"] * TAU)
					v = (1.0 if s > 0.0 else -1.0) * sfx["vol"] * env
				elif sfx["type"] == "noise":
					v = (randf() * 2.0 - 1.0) * sfx["vol"] * env
				mixed_sample += v
		mixed_sample = clampf(mixed_sample, -0.9, 0.9)
		audio_playback.push_frame(Vector2(mixed_sample, mixed_sample))
	
	# Filtrar efectos finalizados de una sola pasada eficiente
	sfx_queue = sfx_queue.filter(func(s): return s["t"] < s["dur"])
