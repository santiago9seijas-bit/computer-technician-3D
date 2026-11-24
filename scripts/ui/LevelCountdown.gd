class_name LevelCountdown
extends CanvasLayer

signal countdown_finished()

var root_ctrl: Control = null
var dim_rect: ColorRect = null
var center: CenterContainer = null
var label: Label = null
var is_running: bool = false
var on_finished_cb: Callable = Callable()
var current_step_index: int = 0
var countdown_steps: Array[Dictionary] = []
var action_word: String = "Reparar"
var active_tween: Tween = null

static func get_action_word(mode_name: String) -> String:
	var low_m = mode_name.to_lower()
	if "sistema" in low_m:
		return "Programar"
	elif "servidor" in low_m:
		return "Armar"
	else:
		return "Reparar"

static func start_countdown(
	tree: SceneTree,
	parent: Node,
	mode_name: String = "reparacion",
	callback: Callable = Callable()
) -> Node:
	var existing = parent.get_node_or_null("LevelCountdownOverlay")
	if existing:
		existing.queue_free()

	var script_res = load("res://scripts/ui/LevelCountdown.gd")
	var countdown = script_res.new()
	countdown.name = "LevelCountdownOverlay"
	countdown.layer = 120
	countdown.process_mode = Node.PROCESS_MODE_ALWAYS
	countdown.on_finished_cb = callback
	parent.add_child(countdown)
	countdown._start(mode_name)
	return countdown

func _start(mode_name: String) -> void:
	is_running = true
	action_word = get_action_word(mode_name)

	root_ctrl = Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_ctrl)

	dim_rect = ColorRect.new()
	dim_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim_rect.color = Color(0.01, 0.02, 0.05, 0.60)
	dim_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(dim_rect)

	center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(center)

	label = Label.new()
	label.text = ""
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.pivot_offset = Vector2(250, 100)
	
	if ResourceLoader.exists("res://assets/fonts/Bungee-Regular.ttf"):
		var font_res = load("res://assets/fonts/Bungee-Regular.ttf")
		if font_res:
			label.add_theme_font_override("font", font_res)

	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 12)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 4)
	label.add_theme_constant_override("shadow_offset_y", 4)
	center.add_child(label)

	countdown_steps = [
		{"text": "3", "color": Color(0.0, 0.95, 1.0), "size": 130, "pitch": 1.0, "confirm": false},
		{"text": "2", "color": Color(1.0, 0.9, 0.2),  "size": 130, "pitch": 1.25, "confirm": false},
		{"text": "1", "color": Color(1.0, 0.55, 0.1), "size": 130, "pitch": 1.5, "confirm": false},
		{"text": action_word, "color": Color(0.2, 1.0, 0.45), "size": 105, "pitch": 1.8, "confirm": true}
	]

	current_step_index = 0
	_run_step(0)

func _run_step(index: int) -> void:
	if not is_running:
		return
	if index >= countdown_steps.size():
		_finish_countdown()
		return

	current_step_index = index
	var st = countdown_steps[index]
	label.text = st["text"]
	label.modulate = st["color"]
	label.add_theme_font_size_override("font_size", st["size"])
	label.scale = Vector2(1.8, 1.8)
	label.modulate.a = 0.0

	_play_sfx(st["pitch"], st["confirm"])

	if active_tween and active_tween.is_valid():
		active_tween.kill()

	active_tween = create_tween().set_parallel(true)
	active_tween.tween_property(label, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(label, "modulate:a", 1.0, 0.16)

	var hold_time = 0.65 if index < countdown_steps.size() - 1 else 0.85
	get_tree().create_timer(hold_time).timeout.connect(func():
		_run_step(index + 1)
	)

func _finish_countdown() -> void:
	if not is_running:
		return
	is_running = false

	if active_tween and active_tween.is_valid():
		active_tween.kill()

	var fade_tw = create_tween()
	if is_instance_valid(root_ctrl):
		fade_tw.tween_property(root_ctrl, "modulate:a", 0.0, 0.28)
	fade_tw.chain().tween_callback(func():
		if on_finished_cb.is_valid():
			on_finished_cb.call()
		countdown_finished.emit()
		queue_free()
	)

func _exit_tree() -> void:
	is_running = false
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	for child in get_children():
		if child is AudioStreamPlayer:
			if child.playing:
				child.stop()
			child.stream = null

func _unhandled_input(event: InputEvent) -> void:
	if not is_running:
		return
	# Si el jugador presiona ESC, saltar inmediatamente la cuenta regresiva e iniciar
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_finish_countdown()

func _play_sfx(pitch: float = 1.0, is_confirm: bool = false) -> void:
	var asp = AudioStreamPlayer.new()
	asp.bus = "Master"
	if is_confirm and ResourceLoader.exists("res://efectos/sonido de entrada.ogg"):
		asp.stream = load("res://efectos/sonido de entrada.ogg")
	elif ResourceLoader.exists("res://efectos/teclado_click.wav"):
		asp.stream = load("res://efectos/teclado_click.wav")
	asp.pitch_scale = pitch
	add_child(asp)
	asp.play()
	asp.finished.connect(asp.queue_free)
