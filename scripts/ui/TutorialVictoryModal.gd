extends Control

signal repeat_pressed
signal finish_pressed

@onready var btn_repetir: Button = $CardModal/Margin/VBox/ButtonsHBox/BtnRepetir
@onready var btn_finalizar: Button = $CardModal/Margin/VBox/ButtonsHBox/BtnFinalizar
@onready var card_modal: PanelContainer = $CardModal
@onready var glow_center: ColorRect = $GlowCenter
@onready var star_1: Label = $CardModal/Margin/VBox/StarsHBox/Star1
@onready var star_2: Label = $CardModal/Margin/VBox/StarsHBox/Star2
@onready var star_3: Label = $CardModal/Margin/VBox/StarsHBox/Star3

var star_tween: Tween = null
var pulse_tween: Tween = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if btn_repetir:
		btn_repetir.pressed.connect(func():
			repeat_pressed.emit()
		)
	if btn_finalizar:
		btn_finalizar.pressed.connect(func():
			finish_pressed.emit()
		)

func setup_mode(mode: String) -> void:
	var title_label = get_node_or_null("CardModal/Margin/VBox/Title") as Label
	var desc_label = get_node_or_null("CardModal/Margin/VBox/Description") as Label
	var badge_ram = get_node_or_null("CardModal/Margin/VBox/BadgesContainer/Margin/HBox/BadgeRAM")
	var badge_ssd = get_node_or_null("CardModal/Margin/VBox/BadgesContainer/Margin/HBox/BadgeSSD")
	var badge_psu = get_node_or_null("CardModal/Margin/VBox/BadgesContainer/Margin/HBox/BadgePSU")
	
	if mode == "sistema":
		if title_label:
			title_label.text = "¡FELICIDADES COMPLETASTE EL TUTORIAL DE SISTEMAS!"
		if desc_label:
			desc_label.text = "¡Has dominado la instalación del sistema operativo, el escaneo de ciberdefensa y la gestión de controladores!"
		if badge_ram:
			var t = badge_ram.get_node_or_null("Title") as Label
			var d = badge_ram.get_node_or_null("Desc") as Label
			if t: t.text = "💿 SISTEMA OPERATIVO"
			if d: d.text = "Partición GPT & Andromeda OS"
		if badge_ssd:
			var t = badge_ssd.get_node_or_null("Title") as Label
			var d = badge_ssd.get_node_or_null("Desc") as Label
			if t: t.text = "🛡️ CIBERDEFENSA"
			if d: d.text = "Escaneo ClamAV Heurístico"
		if badge_psu:
			var t = badge_psu.get_node_or_null("Title") as Label
			var d = badge_psu.get_node_or_null("Desc") as Label
			if t: t.text = "⚙️ CONTROLADORES"
			if d: d.text = "Drivers WHQL & Kernel OK"
	elif mode == "servidor":
		if title_label:
			title_label.text = "¡FELICIDADES COMPLETASTE EL TUTORIAL DE SERVIDOR!"
		if desc_label:
			desc_label.text = "¡Has dominado la programación de servidores y el montaje de refrigeración líquida enterprise!"
		if badge_ram:
			var t = badge_ram.get_node_or_null("Title") as Label
			var d = badge_ram.get_node_or_null("Desc") as Label
			if t: t.text = "💻 CÓDIGO DAEMON"
			if d: d.text = "Depuración de Bugs en Código"
		if badge_ssd:
			var t = badge_ssd.get_node_or_null("Title") as Label
			var d = badge_ssd.get_node_or_null("Desc") as Label
			if t: t.text = "❄️ REFRIGERACIÓN"
			if d: d.text = "Loop Líquido & Cero Fugas"
		if badge_psu:
			var t = badge_psu.get_node_or_null("Title") as Label
			var d = badge_psu.get_node_or_null("Desc") as Label
			if t: t.text = "🌐 RACK OPERATIVO"
			if d: d.text = "Datacenter 100% Online"
	else:
		if title_label:
			title_label.text = "¡FELICIDADES COMPLETASTE EL TUTORIAL!"
		if desc_label:
			desc_label.text = "¡Has completado con éxito el entrenamiento de diagnóstico e instalación de hardware!"
		if badge_ram:
			var t = badge_ram.get_node_or_null("Title") as Label
			var d = badge_ram.get_node_or_null("Desc") as Label
			if t: t.text = "🧠 MEMORIA RAM"
			if d: d.text = "Desbloqueo & Montaje OK"
		if badge_ssd:
			var t = badge_ssd.get_node_or_null("Title") as Label
			var d = badge_ssd.get_node_or_null("Desc") as Label
			if t: t.text = "💾 ALMACENAMIENTO SSD"
			if d: d.text = "Pines, Tornillo & Ranura OK"
		if badge_psu:
			var t = badge_psu.get_node_or_null("Title") as Label
			var d = badge_psu.get_node_or_null("Desc") as Label
			if t: t.text = "⚡ FUENTE DE PODER"
			if d: d.text = "Arnés ATX & CPU OK"

func open() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Animar entrada de tarjeta con rebote cyberpunk
	if card_modal:
		card_modal.scale = Vector2(0.82, 0.82)
		card_modal.modulate.a = 0.0
		var tw = create_tween().set_parallel(true)
		tw.tween_property(card_modal, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(card_modal, "modulate:a", 1.0, 0.25)
	
	# Animar destello de fondo
	if glow_center:
		glow_center.color.a = 0.0
		var tw_glow = create_tween()
		tw_glow.tween_property(glow_center, "color:a", 0.16, 0.35)
		tw_glow.tween_property(glow_center, "color:a", 0.07, 0.5)

	# Animar secuencia de estrellas doradas
	_animate_stars_entrance()

func _animate_stars_entrance() -> void:
	var stars = [star_1, star_2, star_3]
	for s in stars:
		if is_instance_valid(s):
			s.scale = Vector2.ZERO
			s.modulate.a = 0.0
			
	if star_tween and star_tween.is_valid():
		star_tween.kill()
	star_tween = create_tween()
	
	# Esperar 0.15s para que la tarjeta se asiente
	star_tween.tween_interval(0.15)
	
	for i in range(stars.size()):
		var s = stars[i]
		if not is_instance_valid(s):
			continue
		star_tween.tween_callback(func():
			var punch = create_tween().set_parallel(true)
			punch.tween_property(s, "scale", Vector2(1.35, 1.35), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			punch.tween_property(s, "modulate:a", 1.0, 0.12)
			punch.chain().tween_property(s, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE)
		)
		star_tween.tween_interval(0.12)
		
	# Iniciar suave pulso continuo de la estrella central
	star_tween.chain().tween_callback(func():
		_start_center_pulse()
	)

func _start_center_pulse() -> void:
	if not is_instance_valid(star_2):
		return
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(star_2, "scale", Vector2(1.1, 1.1), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(star_2, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _process(_delta: float) -> void:
	if visible:
		if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
