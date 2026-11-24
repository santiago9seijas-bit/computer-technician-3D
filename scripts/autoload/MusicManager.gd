extends Node

# =============================================================================
# GESTOR DE MÚSICA Y AUDIO DE FONDO (MUSIC MANAGER)
# =============================================================================
# Administra la reproducción en bucle continuo de música ambiental para el juego,
# con volúmenes calibrados, balance sonoro estable sin saturación, soporte de bus
# "Music" conectado a las opciones de configuración y transiciones suaves de entrada y salida.

const REPARACION_MUSIC_PATH: String = "res://musica/reparacion.ogg"
const TUTORIAL_MUSIC_PATH: String = "res://musica/tutorial.ogg"

# Calibración de volumen base (Loudness Matching):
# - reparacion.ogg: Volumen medio -6.8 dB (máxima compresión). Base: -19.0 dB -> Resultante -25.8 dB
# - tutorial.ogg:   Volumen medio -14.2 dB. Base: -12.0 dB -> Resultante -26.2 dB
# Ambos temas quedan perfectamente equilibrados, estables, claros y no molestos para el jugador.
const REPARACION_BASE_DB: float = -19.0
const TUTORIAL_BASE_DB: float = -12.0

var music_player: AudioStreamPlayer = null
var current_track: String = ""
var target_base_db: float = 0.0
var _fade_tween: Tween = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_player()

func _setup_audio_player() -> void:
	if not music_player:
		music_player = AudioStreamPlayer.new()
		music_player.name = "BackgroundMusicPlayer"
		music_player.process_mode = Node.PROCESS_MODE_ALWAYS
		_update_bus()
		add_child(music_player)
		music_player.finished.connect(_on_player_finished)

func _update_bus() -> void:
	if not music_player:
		return
	if AudioServer.get_bus_index("Music") != -1:
		music_player.bus = "Music"
	else:
		music_player.bus = "Master"

func play_reparacion(fade_duration: float = 0.8) -> void:
	play_track(REPARACION_MUSIC_PATH, REPARACION_BASE_DB, fade_duration)

func play_tutorial(fade_duration: float = 0.8) -> void:
	play_track(TUTORIAL_MUSIC_PATH, TUTORIAL_BASE_DB, fade_duration)

func play_track(track_path: String, base_volume_db: float, fade_duration: float = 0.8) -> void:
	if not ResourceLoader.exists(track_path):
		return

	# Si ya está reproduciendo la misma pista y está activa, mantener continuidad sin reiniciar
	if current_track == track_path and music_player and music_player.playing:
		return

	var stream = load(track_path)
	if not stream:
		return

	# Garantizar siempre el bucle continuo
	if stream is AudioStreamOggVorbis:
		stream.loop = true

	current_track = track_path
	target_base_db = base_volume_db

	_setup_audio_player()
	_update_bus()
	music_player.stream = stream

	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	# Entrada suave con fade in para evitar cortes bruscos
	music_player.volume_db = target_base_db - 24.0
	music_player.play()

	_fade_tween = create_tween()
	_fade_tween.tween_property(music_player, "volume_db", target_base_db, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func stop_music(fade_duration: float = 0.8) -> void:
	if not music_player or not music_player.playing:
		current_track = ""
		return

	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	current_track = ""
	_fade_tween = create_tween()
	_fade_tween.tween_property(music_player, "volume_db", music_player.volume_db - 28.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_fade_tween.tween_callback(func():
		if is_instance_valid(music_player):
			music_player.stop()
	)

func _on_player_finished() -> void:
	# Respaldo automático para garantizar bucle eterno en caso de que el stream no tenga loop flag
	if current_track != "" and music_player and is_instance_valid(music_player):
		music_player.volume_db = target_base_db
		music_player.play()

func is_playing() -> bool:
	return music_player != null and music_player.playing
