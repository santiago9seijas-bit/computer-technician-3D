class_name DifficultySelector
extends Control

# =============================================================================
# SELECTOR DE DIFICULTAD CYBERPUNK FLOTANTE (SIN CAJA GRIS)
# SPRITE DECORATIVO GIGANTE ROJO EN EL FONDO
# BOTONES DE DIFICULTAD EN ESCALERA CON SHADERS Y MICRO-ANIMACIONES
# BOTÓN MEJORADO DE INICIAR NIVEL CON SHADER Y SPRITE DEDICADO
# SIEMPRE INICIA CON EL MODO NORMAL PREDETERMINADO
# =============================================================================

signal difficulty_selected(diff_name: String)
signal launch_requested()

const DECO_TEXTURE = preload("res://pixel art menus/decoracion de menus/decoracion para selector de dificultad.png")
const BTN_LAUNCH_NORMAL = preload("res://pixel art menus/botones/fondo de boton.png")
const BTN_LAUNCH_HOVER = preload("res://pixel art menus/botones/fondo de boton mouse encima.png")

const BTN_TEXTURES = {
	"brutal": {
		"normal": preload("res://pixel art menus/botones/dificultad/fondo de boton de brutal.png"),
		"pressed": preload("res://pixel art menus/botones/dificultad/fondo de boton de brutal presionado.png"),
		"color": Color(1.0, 0.0, 0.34, 1.0),
		"title": "BRUTAL",
		"time_str": "10 MINUTOS",
		"seconds": 600.0,
		"desc": "TIEMPO EXTREMO (10 MIN) · EXIGENCIA MÁXIMA SIN MARGEN DE ERROR"
	},
	"dificil": {
		"normal": preload("res://pixel art menus/botones/dificultad/fondo de boton de dificil.png"),
		"pressed": preload("res://pixel art menus/botones/dificultad/fondo de boton de dificil presionado.png"),
		"color": Color(1.0, 0.28, 0.0, 1.0),
		"title": "DIFÍCIL",
		"time_str": "15 MINUTOS",
		"seconds": 900.0,
		"desc": "RITMO VELOZ (15 MIN) · PRESIÓN CONSTANTE EN CADA REPARACIÓN"
	},
	"normal": {
		"normal": preload("res://pixel art menus/botones/dificultad/fondo de boton de norrmal.png"),
		"pressed": preload("res://pixel art menus/botones/dificultad/fondo de boton de norrmal presionado.png"),
		"color": Color(0.98, 0.95, 0.1, 1.0),
		"title": "NORMAL",
		"time_str": "20 MINUTOS",
		"seconds": 1200.0,
		"desc": "EQUILIBRIO TÁCTICO (20 MIN) · TIEMPO ESTÁNDAR DE TALLER"
	},
	"facil": {
		"normal": preload("res://pixel art menus/botones/dificultad/fondo de boton de facil.png"),
		"pressed": preload("res://pixel art menus/botones/dificultad/fondo de boton de facil presionado.png"),
		"color": Color(0.0, 0.8, 1.0, 1.0),
		"title": "FÁCIL",
		"time_str": "25 MINUTOS",
		"seconds": 1500.0,
		"desc": "PRÁCTICA HOLGADA (25 MIN) · APRENDE Y EXPLORA CON TRANQUILIDAD"
	}
}

const DECO_SHADER = preload("res://styles/cyber_difficulty_decoration.gdshader")
const BTN_SHADER = preload("res://styles/cyber_difficulty_button.gdshader")
const LAUNCH_SHADER = preload("res://styles/cyber_launch_button.gdshader")

@onready var deco_rect: TextureRect = $DecoRect
@onready var lbl_sub_badge: Label = $HeaderBox/LblSubBadge
@onready var lbl_title: Label = $HeaderBox/LblTitle
@onready var status_panel: PanelContainer = $HeaderBox/StatusPanel
@onready var lbl_selected_mode: Label = $HeaderBox/StatusPanel/VBox/LblSelectedMode
@onready var lbl_desc: Label = $HeaderBox/StatusPanel/VBox/LblDesc

@onready var buttons_root: Control = $ButtonsRoot
@onready var btn_brutal: TextureButton = $ButtonsRoot/BtnBrutal
@onready var btn_dificil: TextureButton = $ButtonsRoot/BtnDificil
@onready var btn_normal: TextureButton = $ButtonsRoot/BtnNormal
@onready var btn_facil: TextureButton = $ButtonsRoot/BtnFacil

@onready var btn_iniciar: TextureButton = $BtnIniciar
@onready var lbl_iniciar_sub: Label = $BtnIniciar/VBox/LblSub

var _button_map: Dictionary = {}
var _button_materials: Dictionary = {}
var _button_base_x: Dictionary = {}
var _deco_material: ShaderMaterial = null
var _launch_material: ShaderMaterial = null
var _current_tween: Tween = null
var _launch_pulse_tween: Tween = null

func _start_idle_launch_pulse() -> void:
	if _launch_pulse_tween and _launch_pulse_tween.is_valid():
		_launch_pulse_tween.kill()
	if not btn_iniciar or not visible:
		return
	btn_iniciar.pivot_offset = btn_iniciar.custom_minimum_size * 0.5
	_launch_pulse_tween = create_tween().set_loops()
	_launch_pulse_tween.tween_property(btn_iniciar, "scale", Vector2(1.035, 1.035), 0.85)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_launch_pulse_tween.tween_property(btn_iniciar, "scale", Vector2(0.99, 0.99), 0.85)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _ready() -> void:
	_button_map = {
		"brutal": btn_brutal,
		"dificil": btn_dificil,
		"normal": btn_normal,
		"facil": btn_facil
	}
	
	# Guardar posiciones base en escalera
	_button_base_x = {
		"brutal": 80.0,
		"dificil": 120.0,
		"normal": 160.0,
		"facil": 200.0
	}
	
	# Shader fijo para la decoración (SIEMPRE ROJO / CARMESÍ NEÓN, CERO AMARILLO)
	_deco_material = ShaderMaterial.new()
	_deco_material.shader = DECO_SHADER
	if deco_rect:
		deco_rect.texture = DECO_TEXTURE
		deco_rect.material = _deco_material
		deco_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Shaders para cada botón de dificultad
	for diff_key in ["brutal", "dificil", "normal", "facil"]:
		var btn = _button_map.get(diff_key) as TextureButton
		if not btn:
			continue
		
		var data = BTN_TEXTURES[diff_key]
		var mat = ShaderMaterial.new()
		mat.shader = BTN_SHADER
		mat.set_shader_parameter("accent_color", data["color"])
		mat.set_shader_parameter("is_hovered", 0.0)
		mat.set_shader_parameter("is_selected", 0.0)
		_button_materials[diff_key] = mat
		btn.material = mat
		btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pivot_offset = btn.custom_minimum_size * 0.5
		
		btn.pressed.connect(_on_difficulty_btn_pressed.bind(diff_key))
		btn.mouse_entered.connect(_on_btn_hover.bind(diff_key, true))
		btn.mouse_exited.connect(_on_btn_hover.bind(diff_key, false))
	
	# Shader para el botón mejorado de Iniciar
	if btn_iniciar:
		_launch_material = ShaderMaterial.new()
		_launch_material.shader = LAUNCH_SHADER
		btn_iniciar.material = _launch_material
		btn_iniciar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		btn_iniciar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn_iniciar.pivot_offset = btn_iniciar.custom_minimum_size * 0.5
		
		btn_iniciar.pressed.connect(func():
			_play_launch_punch()
			launch_requested.emit()
		)
		btn_iniciar.mouse_entered.connect(func():
			if _launch_pulse_tween and _launch_pulse_tween.is_valid():
				_launch_pulse_tween.kill()
			if _launch_material:
				_launch_material.set_shader_parameter("is_hovered", 1.0)
			var tw = create_tween()
			tw.tween_property(btn_iniciar, "scale", Vector2(1.06, 1.06), 0.12)\
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		)
		btn_iniciar.mouse_exited.connect(func():
			if _launch_material:
				_launch_material.set_shader_parameter("is_hovered", 0.0)
			var tw = create_tween()
			tw.tween_property(btn_iniciar, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD)
			tw.chain().tween_callback(_start_idle_launch_pulse)
		)
	
	# SIEMPRE iniciar en modo NORMAL predeterminado
	select_difficulty("normal", false)

func select_difficulty(diff_name: String, animate: bool = true) -> void:
	var key = diff_name.to_lower().strip_edges()
	if not BTN_TEXTURES.has(key):
		key = "normal"
	
	var data = BTN_TEXTURES[key]
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("set_difficulty"):
		gm.set_difficulty(key)
	
	# Actualizar apariencia de los 4 botones escalonados
	for d_key in ["brutal", "dificil", "normal", "facil"]:
		var btn = _button_map.get(d_key) as TextureButton
		var mat = _button_materials.get(d_key) as ShaderMaterial
		if not btn or not mat:
			continue
		
		var is_selected = (d_key == key)
		var b_data = BTN_TEXTURES[d_key]
		var base_x = _button_base_x.get(d_key, 80.0)
		
		if is_selected:
			btn.texture_normal = b_data["pressed"]
			mat.set_shader_parameter("is_selected", 1.0)
			
			if animate:
				btn.pivot_offset = btn.custom_minimum_size * 0.5
				var punch_tw = create_tween()
				punch_tw.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.08)\
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				punch_tw.tween_property(btn, "scale", Vector2.ONE, 0.14)\
					.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
				# Ligero empuje hacia la derecha al estar activo
				punch_tw.parallel().tween_property(btn, "position:x", base_x + 14.0, 0.12)
			else:
				btn.position.x = base_x + 14.0
		else:
			btn.texture_normal = b_data["normal"]
			mat.set_shader_parameter("is_selected", 0.0)
			btn.scale = Vector2.ONE
			if animate:
				var tw = create_tween()
				tw.tween_property(btn, "position:x", base_x, 0.15).set_trans(Tween.TRANS_QUAD)
			else:
				btn.position.x = base_x
	
	# Actualizar encabezados y subtítulo del botón de entrar
	_update_feedback_text(data, animate)
	difficulty_selected.emit(key)

func _update_feedback_text(data: Dictionary, animate: bool) -> void:
	if lbl_selected_mode:
		lbl_selected_mode.text = "MODO: [ %s ] · %s" % [data["title"], data["time_str"]]
		lbl_selected_mode.add_theme_color_override("font_color", data["color"])
		lbl_selected_mode.add_theme_color_override("font_shadow_color", data["color"] * Color(0.3, 0.3, 0.3, 0.9))
		
		if animate:
			var tw = create_tween()
			lbl_selected_mode.pivot_offset = Vector2(0, lbl_selected_mode.size.y * 0.5)
			tw.tween_property(lbl_selected_mode, "scale", Vector2(1.06, 1.06), 0.08)
			tw.tween_property(lbl_selected_mode, "scale", Vector2.ONE, 0.12)
			
	if lbl_desc:
		lbl_desc.text = data["desc"]
		lbl_desc.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95, 0.95))
		
	if lbl_iniciar_sub:
		lbl_iniciar_sub.text = "[ TIEMPO LÍMITE: %s ]" % data["time_str"]
		lbl_iniciar_sub.add_theme_color_override("font_color", data["color"])

func _on_difficulty_btn_pressed(diff_key: String) -> void:
	select_difficulty(diff_key, true)

func _on_btn_hover(diff_key: String, hovered: bool) -> void:
	var btn = _button_map.get(diff_key) as TextureButton
	var mat = _button_materials.get(diff_key) as ShaderMaterial
	if not btn or not mat:
		return
	
	mat.set_shader_parameter("is_hovered", 1.0 if hovered else 0.0)
	
	var gm = get_node_or_null("/root/GameManager")
	var is_current = (gm and "current_difficulty" in gm and gm.current_difficulty == diff_key)
	var base_x = _button_base_x.get(diff_key, 80.0)
	var target_x = base_x + (20.0 if hovered else (14.0 if is_current else 0.0))
	var target_scale = Vector2(1.05, 1.05) if hovered else Vector2.ONE
	
	btn.pivot_offset = btn.custom_minimum_size * 0.5
	var tw = create_tween().set_parallel(true)
	tw.tween_property(btn, "scale", target_scale, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "position:x", target_x, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _play_launch_punch() -> void:
	if _launch_pulse_tween and _launch_pulse_tween.is_valid():
		_launch_pulse_tween.kill()
	if btn_iniciar:
		btn_iniciar.pivot_offset = btn_iniciar.custom_minimum_size * 0.5
		var tw = create_tween()
		tw.tween_property(btn_iniciar, "scale", Vector2(0.94, 0.94), 0.06).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(btn_iniciar, "scale", Vector2(1.14, 1.14), 0.1)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn_iniciar, "scale", Vector2.ONE, 0.12)

func open_for_level() -> void:
	# REQUISITO EXPRESO: Siempre al abrir/entrar a un nivel, el predeterminado es NORMAL
	select_difficulty("normal", false)
	play_enter_animation()

func play_enter_animation() -> void:
	visible = true
	modulate.a = 0.0
	scale = Vector2(0.92, 0.92)
	pivot_offset = size * 0.5
	
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
		
	_current_tween = create_tween().set_parallel(true)
	_current_tween.tween_property(self, "modulate:a", 1.0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_current_tween.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Entrada escalonada de botones en escalera
	var delay := 0.06
	for d_key in ["brutal", "dificil", "normal", "facil"]:
		var btn = _button_map.get(d_key) as TextureButton
		if btn:
			var base_x = _button_base_x.get(d_key, 80.0)
			btn.modulate.a = 0.0
			btn.position.x = base_x + 60.0
			var b_tw = create_tween()
			b_tw.tween_interval(delay)
			b_tw.tween_property(btn, "modulate:a", 1.0, 0.2)
			b_tw.parallel().tween_property(btn, "position:x", base_x, 0.24)\
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			delay += 0.05
			
	# Entrada del botón Iniciar y arranque de respiración idle
	if btn_iniciar:
		btn_iniciar.modulate.a = 0.0
		var in_tw = create_tween()
		in_tw.tween_interval(delay + 0.05)
		in_tw.tween_property(btn_iniciar, "modulate:a", 1.0, 0.22)
		in_tw.chain().tween_callback(_start_idle_launch_pulse)

func play_exit_animation(on_complete: Callable = Callable()) -> void:
	if _launch_pulse_tween and _launch_pulse_tween.is_valid():
		_launch_pulse_tween.kill()
		
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
		
	_current_tween = create_tween().set_parallel(true)
	_current_tween.tween_property(self, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_current_tween.tween_property(self, "scale", Vector2(0.92, 0.92), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_current_tween.chain().tween_callback(func():
		visible = false
		if on_complete.is_valid():
			on_complete.call()
	)
