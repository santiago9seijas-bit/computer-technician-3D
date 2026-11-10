extends Control

# Binary Matrix Rain (Área de Sistemas)
# Drops cascading columns of 0, 1, and hex glyphs in emerald green with bright glowing heads.

@export var rain_color: Color = Color(0.0, 0.95, 0.55, 0.22)
@export var head_color: Color = Color(0.85, 1.0, 0.92, 0.85)
@export var font_size: int = 12

var font: Font = null
var columns: Array[Dictionary] = []
var time: float = 0.0
var glyphs = ["0", "1", "0", "1", "1", "0", "A", "F", "X", "7", "C", "9", "E", "3"]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://assets/fonts/JetBrainsMono-Bold.ttf"):
		font = load("res://assets/fonts/JetBrainsMono-Bold.ttf")
	elif ResourceLoader.exists("res://assets/fonts/JetBrainsMono-Regular.ttf"):
		font = load("res://assets/fonts/JetBrainsMono-Regular.ttf")
	else:
		font = ThemeDB.fallback_font
	_init_columns()

func _init_columns() -> void:
	columns.clear()
	var w = size.x if size.x > 100.0 else 1160.0
	var col_spacing = 24.0
	var total_cols = int(w / col_spacing)
	
	for i in range(total_cols):
		var col_x = float(i) * col_spacing + 14.0
		var num_chars = randi_range(9, 20)
		var chars: Array[String] = []
		for c in range(num_chars):
			chars.append(glyphs[randi() % glyphs.size()])
			
		columns.append({
			"x": col_x,
			"y": randf_range(-350.0, 650.0),
			"speed": randf_range(80.0, 175.0),
			"chars": chars,
			"mutation_timer": randf_range(0.06, 0.22)
		})

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_init_columns()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	time += delta
	var h = size.y if size.y > 100.0 else 720.0
	var char_h = float(font_size + 4)
	
	for col in columns:
		col.y += col.speed * delta
		var trail_h = float(col.chars.size()) * char_h
		if col.y - trail_h > h:
			col.y = randf_range(-140.0, -30.0)
			col.speed = randf_range(80.0, 175.0)
			
		col.mutation_timer -= delta
		if col.mutation_timer <= 0.0:
			col.mutation_timer = randf_range(0.08, 0.25)
			var r_idx = randi() % col.chars.size()
			col.chars[r_idx] = glyphs[randi() % glyphs.size()]
			
	queue_redraw()

func _draw() -> void:
	if font == null:
		return
		
	var char_h = float(font_size + 4)
	var h = size.y if size.y > 100.0 else 720.0
	
	for col in columns:
		var x = col.x
		var num_chars = col.chars.size()
		for idx in range(num_chars):
			var cy = col.y - float(num_chars - 1 - idx) * char_h
			if cy < -20.0 or cy > (h + 20.0):
				continue
				
			var ch = col.chars[idx]
			var is_head = (idx == num_chars - 1)
			
			if is_head:
				draw_string(font, Vector2(x, cy), ch, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, head_color)
			else:
				var frac = float(idx) / float(num_chars)
				var alpha = lerpf(0.02, rain_color.a, frac)
				var c = Color(rain_color.r, rain_color.g, rain_color.b, alpha)
				draw_string(font, Vector2(x, cy), ch, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, c)
