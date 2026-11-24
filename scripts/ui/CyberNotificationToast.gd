extends Control

signal toast_clicked

@onready var panel: PanelContainer = $ToastPanel
@onready var icon_label: Label = $ToastPanel/Margin/HBox/IconLabel
@onready var header_label: Label = $ToastPanel/Margin/HBox/VBox/HeaderLabel
@onready var title_label: Label = $ToastPanel/Margin/HBox/VBox/TitleLabel
@onready var hint_label: Label = $ToastPanel/Margin/HBox/VBox/HintLabel
@onready var timer_bar: ColorRect = $ToastPanel/TimerBar
@onready var btn_action: Button = $ToastPanel/BtnAction

var on_click_callback: Callable = Callable()
var duration: float = 5.0
var elapsed: float = 0.0
var is_closing: bool = false
var is_hovered: bool = false
var target_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	custom_minimum_size = Vector2(390, 88)
	size = Vector2(390, 88)
	
	btn_action.pressed.connect(_on_banner_clicked)
	btn_action.mouse_entered.connect(func(): is_hovered = true)
	btn_action.mouse_exited.connect(func(): is_hovered = false)
	
	_setup_position_and_slide()
	_play_notification_sfx()

func _setup_position_and_slide() -> void:
	var vp_size = get_viewport_rect().size
	if vp_size.x <= 100.0 or vp_size.y <= 100.0:
		vp_size = Vector2(1280.0, 720.0)
		
	var w = 400.0
	var h = 90.0
	var margin_right = 20.0
	var margin_bottom = 20.0
	
	target_pos = Vector2(vp_size.x - w - margin_right, vp_size.y - h - margin_bottom)
	var start_pos = Vector2(vp_size.x + 30.0, target_pos.y)
	
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	size = Vector2(w, h)
	position = start_pos
	modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "position:x", target_pos.x, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.25)

func setup_achievement(title: String, desc: String, callback: Callable = Callable()) -> void:
	on_click_callback = callback
	if not is_node_ready():
		await ready
	
	icon_label.text = "🏆"
	header_label.text = "¡NUEVO LOGRO DESBLOQUEADO!"
	header_label.modulate = Color(1.0, 0.85, 0.2)
	title_label.text = title
	hint_label.text = "[ Haz clic para ver en Extras ]"
	
	var sb = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	sb.border_color = Color(1.0, 0.85, 0.2, 0.9)
	panel.add_theme_stylebox_override("panel", sb)
	timer_bar.color = Color(1.0, 0.85, 0.2, 0.85)

func setup_glossary(topic_title: String, callback: Callable = Callable()) -> void:
	on_click_callback = callback
	if not is_node_ready():
		await ready
		
	icon_label.text = "📖"
	header_label.text = "¡GLOSARIO TÉCNICO ACTUALIZADO!"
	header_label.modulate = Color(0.0, 0.95, 0.75)
	title_label.text = topic_title
	hint_label.text = "[ Haz clic para consultar la guía técnica ]"
	
	var sb = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	sb.border_color = Color(0.0, 0.95, 0.75, 0.9)
	panel.add_theme_stylebox_override("panel", sb)
	timer_bar.color = Color(0.0, 0.95, 0.75, 0.85)

func _process(delta: float) -> void:
	if is_closing:
		return
		
	if not is_hovered:
		elapsed += delta
		var progress = clamp(1.0 - (elapsed / duration), 0.0, 1.0)
		if timer_bar:
			timer_bar.anchor_right = progress
			
		if elapsed >= duration:
			_dismiss()

func _on_banner_clicked() -> void:
	if is_closing:
		return
	is_closing = true
	
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("play_sfx"):
		gm.play_sfx("click")
		
	toast_clicked.emit()
	if on_click_callback.is_valid():
		on_click_callback.call()
		
	_dismiss(true)

func _dismiss(instant: bool = false) -> void:
	if is_closing and not instant:
		return
	is_closing = true
	
	if instant:
		queue_free()
		return
		
	var vp_size = get_viewport_rect().size
	if vp_size.x <= 100.0:
		vp_size = Vector2(1280.0, 720.0)
	var exit_x = vp_size.x + 30.0
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "position:x", exit_x, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(queue_free)

func _exit_tree() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			if child.playing:
				child.stop()
			child.stream = null

static func dismiss_all(tree: SceneTree) -> void:
	if not tree or not tree.root:
		return
	for child in tree.root.get_children():
		if child is Control and child.name.begins_with("CyberNotificationToast"):
			child.free()

func _play_notification_sfx() -> void:
	var asp = AudioStreamPlayer.new()
	asp.bus = "Master"
	asp.stream = load("res://efectos/sonido de entrada.ogg")
	asp.pitch_scale = 1.35
	add_child(asp)
	asp.play()
	asp.finished.connect(asp.queue_free)
