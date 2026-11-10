extends CanvasLayer

# =============================================================================
# MINIJUEGO: PROGRAMACIÓN & DEPURACIÓN DE CÓDIGO (DEBUGGING TERMINAL)
# Enseña:
# 1. Identificar errores de sintaxis (delimitadores y dos puntos en funciones).
# 2. Corregir errores de tipografía (typos) en nombres de variables.
# 3. Detectar y prevenir bucles infinitos (actualización de variables de control).
# 4. Ajustar valores de retorno de funciones para pruebas unitarias exitosas.
# =============================================================================

signal minigame_finished(success: bool)

# Nodos Principales
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel
@onready var progress_bar: ProgressBar = $ModalControl/Panel/VBox/Header/Metrics/ProgressBar
@onready var lbl_bugs_count: Label = $ModalControl/Panel/VBox/Header/Metrics/LblBugsCount

# Editor de Código (Columna Izquierda)
@onready var code_lines_vbox: VBoxContainer = $ModalControl/Panel/VBox/WorkHBox/LeftCol/Scroll/CodeLinesVBox

# Panel de Corrección y Terminal (Columna Derecha)
@onready var lbl_bug_title: Label = $ModalControl/Panel/VBox/WorkHBox/RightCol/VBox/BugTitle
@onready var lbl_bug_desc: Label = $ModalControl/Panel/VBox/WorkHBox/RightCol/VBox/BugDesc
@onready var patches_vbox: VBoxContainer = $ModalControl/Panel/VBox/WorkHBox/RightCol/VBox/PatchesVBox
@onready var btn_compile: Button = $ModalControl/Panel/VBox/WorkHBox/RightCol/VBox/BtnCompile
@onready var terminal_console: Label = $ModalControl/Panel/VBox/WorkHBox/RightCol/VBox/TerminalConsole
@onready var toast_label: Label = $ModalControl/Panel/VBox/WorkHBox/RightCol/VBox/ToastLabel
@onready var victory_banner: PanelContainer = $ModalControl/Panel/VBox/WorkHBox/RightCol/VBox/VictoryBanner

var selected_bug_id: int = -1
var resolved_bugs_count: int = 0
const TOTAL_BUGS: int = 3
var is_compiled: bool = false

# Definición del script y los 3 bugs simplificados, intuitivos y educativos
var BUGS_DATA: Array[Dictionary] = [
	{
		"line_num": 4,
		"title": "Error de Sintaxis (Falta ':')",
		"concept": "💡 Pista: En GDScript/Python, las funciones terminan con ':' para abrir el bloque.",
		"bad_text": "4  func audit_network(target_ip: String)   # ❌ Falta ':' al final",
		"fixed_text": "4  func audit_network(target_ip: String):  # ✓ Cabecera corregida",
		"desc": "La función 'audit_network' necesita los dos puntos ':' al final para abrir su bloque.",
		"is_fixed": false,
		"options": [
			{"code": "func audit_network(target_ip: String):  [✓ AGREGAR ':']", "is_correct": true, "msg": "¡Correcto! Los dos puntos ':' abren el bloque de la función."},
			{"code": "func audit_network(target_ip: String)   [❌ DEJAR IGUAL]", "is_correct": false, "msg": "Sigue faltando el carácter ':' al final de la línea."}
		]
	},
	{
		"line_num": 9,
		"title": "Variable con Typo (Letras Cambiadas)",
		"concept": "💡 Pista: La lista de la línea 6 se llama 'open_ports', no 'opne_ports'.",
		"bad_text": "9      for port in opne_ports:             # ❌ Typo 'opne_ports'",
		"fixed_text": "9      for port in open_ports:             # ✓ Variable corregida",
		"desc": "La variable fue escrita como 'opne_ports' por error tipográfico.",
		"is_fixed": false,
		"options": [
			{"code": "for port in open_ports:  [✓ CORREGIR A 'open_ports']", "is_correct": true, "msg": "¡Excelente! 'open_ports' coincide exactamente con la lista."},
			{"code": "for port in opne_ports:  [❌ DEJAR 'opne_ports']", "is_correct": false, "msg": "Aún contiene el error tipográfico 'opne'."}
		]
	},
	{
		"line_num": 16,
		"title": "Resultado del Test (Retorno)",
		"concept": "💡 Pista: El validador espera que la función devuelva 'true' para confirmar éxito.",
		"bad_text": "16     return false                        # ❌ Retorna fallo",
		"fixed_text": "16     return true                         # ✓ Auditoría exitosa",
		"desc": "Al retornar 'false', el sistema cree que falló. Debe retornar 'true'.",
		"is_fixed": false,
		"options": [
			{"code": "return true  [✓ APROBAR TEST]", "is_correct": true, "msg": "¡Muy bien! 'return true' aprueba la verificación."},
			{"code": "return false [❌ RECHAZAR TEST]", "is_correct": false, "msg": "Devolver 'false' hace que las pruebas fallen."}
		]
	}
]

var line_buttons: Dictionary = {}

func _ready() -> void:
	layer = 12
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	btn_compile.pressed.connect(_on_compile_pressed)
	btn_compile.disabled = true
	toast_label.visible = false
	victory_banner.visible = false
	
	_render_code_editor()
	_update_metrics()
	_update_status("Haz clic en las líneas con errores marcadas en rojo para desplegar el menú de corrección.")
	_select_bug(0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		minigame_finished.emit(false)

func _render_code_editor() -> void:
	for child in code_lines_vbox.get_children():
		child.queue_free()
	line_buttons.clear()
	
	var all_lines = [
		{"num": 1, "text": "1  class_name CyberSecurityAudit", "is_bug": false},
		{"num": 2, "text": "2  extends Node", "is_bug": false},
		{"num": 3, "text": "3  # Módulo de auditoría de seguridad y cortafuegos", "is_bug": false},
		{"num": 4, "text": "", "is_bug": true, "bug_idx": 0},
		{"num": 5, "text": "5      var active_nodes = get_firewall_nodes()", "is_bug": false},
		{"num": 6, "text": "6      var open_ports = [80, 443, 8080]", "is_bug": false},
		{"num": 7, "text": "7      ", "is_bug": false},
		{"num": 8, "text": "8      # Inspección de paquetes por puerto", "is_bug": false},
		{"num": 9, "text": "", "is_bug": true, "bug_idx": 1},
		{"num": 10, "text": "10         log_packet_stream(target_ip, port)", "is_bug": false},
		{"num": 11, "text": "11     ", "is_bug": false},
		{"num": 12, "text": "12     # Verificación final de integridad", "is_bug": false},
		{"num": 13, "text": "13     var is_valid = check_encryption()", "is_bug": false},
		{"num": 14, "text": "14     if is_valid:", "is_bug": false},
		{"num": 15, "text": "15         log_status(\"Auditoría exitosa\")", "is_bug": false},
		{"num": 16, "text": "", "is_bug": true, "bug_idx": 2}
	]
	
	for line in all_lines:
		var btn = Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 10)
		
		if not line["is_bug"]:
			btn.text = line["text"]
			btn.flat = true
			btn.disabled = true
			btn.add_theme_color_override("font_color_disabled", Color(0.7, 0.75, 0.8))
		else:
			var b_idx = line["bug_idx"]
			var b_data = BUGS_DATA[b_idx]
			_update_bug_button_display(btn, b_data)
			btn.pressed.connect(func(): _select_bug(b_idx))
			line_buttons[b_idx] = btn
			
		code_lines_vbox.add_child(btn)

func _update_bug_button_display(btn: Button, b_data: Dictionary) -> void:
	if b_data["is_fixed"]:
		btn.text = "✓ " + b_data["fixed_text"]
		btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	else:
		btn.text = "🐛 " + b_data["bad_text"]
		btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.45))

func _select_bug(idx: int) -> void:
	selected_bug_id = idx
	var b_data = BUGS_DATA[idx]
	
	lbl_bug_title.text = "🔍 %s (Línea %d)" % [b_data["title"], b_data["line_num"]]
	var concept_text = b_data.get("concept", "")
	lbl_bug_desc.text = "%s\n\n%s" % [b_data["desc"], concept_text]
	
	# Resaltar la línea activa en el editor
	for b_i in line_buttons.keys():
		var b_btn = line_buttons[b_i]
		if is_instance_valid(b_btn):
			if b_i == idx:
				b_btn.modulate = Color(1.3, 1.3, 1.0)
			else:
				b_btn.modulate = Color(1.0, 1.0, 1.0)
	
	for child in patches_vbox.get_children():
		child.queue_free()
		
	if b_data["is_fixed"]:
		var lbl = Label.new()
		lbl.text = "✓ ¡Esta línea ya fue corregida satisfactoriamente!"
		lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
		lbl.add_theme_font_size_override("font_size", 12)
		patches_vbox.add_child(lbl)
		return
		
	for opt in b_data["options"]:
		var btn = Button.new()
		btn.text = " 🛠️ " + opt["code"]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 38)
		btn.add_theme_font_size_override("font_size", 11)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		var o_copy = opt
		btn.pressed.connect(func(): _apply_patch(b_data, o_copy))
		patches_vbox.add_child(btn)

func _apply_patch(b_data: Dictionary, option: Dictionary) -> void:
	if not option["is_correct"]:
		_show_toast("⚠️ ERROR: %s" % option["msg"])
		return
		
	b_data["is_fixed"] = true
	resolved_bugs_count += 1
	_show_toast("✓ %s" % option["msg"])
	
	if line_buttons.has(selected_bug_id):
		_update_bug_button_display(line_buttons[selected_bug_id], b_data)
		
	_update_metrics()
	
	if resolved_bugs_count >= TOTAL_BUGS:
		btn_compile.disabled = false
		btn_compile.text = "🚀 ¡TODOS LOS BUGS RESUELTOS! CLIC PARA COMPILAR Y TESTEAR"
		btn_compile.modulate = Color(0.2, 1.0, 0.5)
		_update_status("¡Todos los bugs corregidos! Presiona 'COMPILAR' para verificar los tests del sistema.")
		_select_bug(selected_bug_id)
	else:
		# Auto-avanzar al siguiente bug no resuelto suavemente
		var next_idx = -1
		for i in range(TOTAL_BUGS):
			var check_i = (selected_bug_id + 1 + i) % TOTAL_BUGS
			if not BUGS_DATA[check_i]["is_fixed"]:
				next_idx = check_i
				break
		if next_idx != -1:
			_select_bug(selected_bug_id)
			await get_tree().create_timer(0.35).timeout
			if is_instance_valid(self):
				_select_bug(next_idx)
		else:
			_select_bug(selected_bug_id)

func _on_compile_pressed() -> void:
	if is_compiled:
		return
	is_compiled = true
	btn_compile.disabled = true
	
	terminal_console.text = "$ gdscript-lint --strict --check CyberSecurityAudit.gd\n"
	await get_tree().create_timer(0.3).timeout
	terminal_console.text += "✓ Analizando árbol sintáctico (AST)... [OK: Cabecera ':' verificada]\n"
	await get_tree().create_timer(0.25).timeout
	terminal_console.text += "✓ Verificando referencias a variables... [OK: 'open_ports' resuelta]\n"
	await get_tree().create_timer(0.25).timeout
	terminal_console.text += "✓ Ejecutando test_security_return()... [PASSED: true]\n"
	terminal_console.text += "\n🎉 ¡3/3 TESTS SUPERADOS! 0 WARNINGS, 0 ERRORS."
	
	_on_debugging_completed()

func _on_debugging_completed() -> void:
	_update_status("¡CÓDIGO DEPURADO CON ÉXITO! El script ha compilado sin errores.")
	
	victory_banner.visible = true
	victory_banner.scale = Vector2(0.6, 0.6)
	victory_banner.modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(victory_banner, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(victory_banner, "modulate:a", 1.0, 0.25)
	
	await get_tree().create_timer(2.4).timeout
	minigame_finished.emit(true)

func _update_metrics() -> void:
	var pct = float(resolved_bugs_count) / float(TOTAL_BUGS) * 100.0
	progress_bar.value = pct
	lbl_bugs_count.text = "BUGS RESUELTOS: %d / %d" % [resolved_bugs_count, TOTAL_BUGS]
	
	if resolved_bugs_count == TOTAL_BUGS:
		lbl_bugs_count.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))

func _update_status(msg: String) -> void:
	status_label.text = msg

func _show_toast(msg: String) -> void:
	toast_label.text = msg
	toast_label.visible = true
	toast_label.modulate.a = 1.0
	var tw = create_tween()
	tw.tween_property(toast_label, "modulate:a", 0.0, 2.2).set_delay(1.2)
	tw.chain().tween_callback(func(): toast_label.visible = false)
