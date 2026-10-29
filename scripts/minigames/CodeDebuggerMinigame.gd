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
@onready var modal_control: Control = $ModalControl
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
const TOTAL_BUGS: int = 4
var is_compiled: bool = false

# Definición del script y los 4 bugs
var BUGS_DATA: Array[Dictionary] = [
	{
		"line_num": 4,
		"title": "Error de Sintaxis en Línea 4",
		"bad_text": "4  func audit_network(target_ip: String)   # ❌ Error de sintaxis",
		"fixed_text": "4  func audit_network(target_ip: String):  # ✓ Cabecera corregida",
		"desc": "La declaración de la función 'audit_network' carece del carácter de terminación ':' de bloque.",
		"is_fixed": false,
		"options": [
			{"code": "func audit_network(target_ip: String)", "is_correct": false, "msg": "Sigue faltando el carácter ':' al final."},
			{"code": "func audit_network(target_ip: String):", "is_correct": true, "msg": "¡Correcto! En GDScript/Python los bloques de función terminan con ':'."},
			{"code": "function audit_network()", "is_correct": false, "msg": "'function' no es una palabra reservada válida aquí."}
		]
	},
	{
		"line_num": 9,
		"title": "Variable no Definida en Línea 9",
		"bad_text": "9      for port in opne_ports:             # ❌ Typo en variable",
		"fixed_text": "9      for port in open_ports:             # ✓ Variable válida",
		"desc": "El identificador 'opne_ports' no existe en este ámbito. Arriba se declaró 'open_ports'.",
		"is_fixed": false,
		"options": [
			{"code": "for port in opne_ports:", "is_correct": false, "msg": "El error tipográfico 'opne' sigue presente."},
			{"code": "for port in open_ports:", "is_correct": true, "msg": "¡Excelente! La variable coincide con la lista declarada en la línea 6."},
			{"code": "for port in 80:", "is_correct": false, "msg": "Un entero no es un objeto iterable."}
		]
	},
	{
		"line_num": 14,
		"title": "Bucle Infinito en Línea 14",
		"bad_text": "14     while retries < 3:                  # ❌ Bucle infinito",
		"fixed_text": "14     while retries < 3:\n15         retries += 1                    # ✓ Contador incrementado",
		"desc": "La condición 'while retries < 3' nunca cambia porque 'retries' no se incrementa, congelando el hilo.",
		"is_fixed": false,
		"options": [
			{"code": "while retries < 3: (sin incremento)", "is_correct": false, "msg": "El bucle seguirá ejecutándose eternamente sin salir."},
			{"code": "while retries < 3:\n        retries += 1", "is_correct": true, "msg": "¡Perfecto! Incrementar la variable de control garantiza la terminación del bucle."},
			{"code": "while true:", "is_correct": false, "msg": "Un bucle 'while true' sin break incondicional agrava el problema."}
		]
	},
	{
		"line_num": 19,
		"title": "Retorno Erróneo en Línea 19",
		"bad_text": "19     return false                        # ❌ Falla unit tests",
		"fixed_text": "19     return true                         # ✓ Conexión verificada",
		"desc": "La función retorna un valor 'false' predeterminado que hace fallar los tests de validación del firewall.",
		"is_fixed": false,
		"options": [
			{"code": "return false", "is_correct": false, "msg": "El test unitario espera que la auditoría devuelva true al finalizar."},
			{"code": "return true", "is_correct": true, "msg": "¡Muy bien! Indica al llamador que la auditoría de red concluyó con éxito."},
			{"code": "return null", "is_correct": false, "msg": "Null provoca error de desempaquetado en el cliente."}
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
		{"num": 12, "text": "12     # Reintentos de conexión segura", "is_bug": false},
		{"num": 13, "text": "13     var retries = 0", "is_bug": false},
		{"num": 14, "text": "", "is_bug": true, "bug_idx": 2},
		{"num": 16, "text": "16         var success = handshake(target_ip)", "is_bug": false},
		{"num": 17, "text": "17         if success: break", "is_bug": false},
		{"num": 18, "text": "18     ", "is_bug": false},
		{"num": 19, "text": "", "is_bug": true, "bug_idx": 3}
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
		btn.text = b_data["fixed_text"]
		btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	else:
		btn.text = b_data["bad_text"]
		btn.add_theme_color_override("font_color", Color(1.0, 0.3, 0.35))

func _select_bug(idx: int) -> void:
	selected_bug_id = idx
	var b_data = BUGS_DATA[idx]
	
	lbl_bug_title.text = "%s (Línea %d)" % [b_data["title"], b_data["line_num"]]
	lbl_bug_desc.text = b_data["desc"]
	
	for child in patches_vbox.get_children():
		child.queue_free()
		
	if b_data["is_fixed"]:
		var lbl = Label.new()
		lbl.text = "✓ Esta línea ya fue corregida satisfactoriamente."
		lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
		lbl.add_theme_font_size_override("font_size", 11)
		patches_vbox.add_child(lbl)
		return
		
	for opt in b_data["options"]:
		var btn = Button.new()
		btn.text = " 🛠️ " + opt["code"]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 36)
		btn.add_theme_font_size_override("font_size", 10)
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
	_select_bug(selected_bug_id)
	
	if resolved_bugs_count >= TOTAL_BUGS:
		btn_compile.disabled = false
		btn_compile.text = "🚀 COMPILAR Y EJECUTAR TESTS UNITARIOS"
		btn_compile.modulate = Color(0.2, 1.0, 0.5)
		_update_status("¡Todos los bugs corregidos! Presiona 'COMPILAR' para verificar los tests del sistema.")

func _on_compile_pressed() -> void:
	if is_compiled:
		return
	is_compiled = true
	btn_compile.disabled = true
	
	terminal_console.text = "$ gdscript-lint --strict --check CyberSecurityAudit.gd\n"
	await get_tree().create_timer(0.35).timeout
	terminal_console.text += "✓ Analizando árbol sintáctico (AST)... [OK: 0 errores]\n"
	await get_tree().create_timer(0.3).timeout
	terminal_console.text += "✓ Ejecutando test_syntax_header()........... [PASSED]\n"
	await get_tree().create_timer(0.25).timeout
	terminal_console.text += "✓ Ejecutando test_variable_resolution()..... [PASSED]\n"
	await get_tree().create_timer(0.25).timeout
	terminal_console.text += "✓ Ejecutando test_loop_termination()........ [PASSED]\n"
	await get_tree().create_timer(0.25).timeout
	terminal_console.text += "✓ Ejecutando test_firewall_return_state()... [PASSED]\n"
	terminal_console.text += "\n🎉 ¡4/4 TESTS SUPERADOS! 0 WARNINGS, 0 ERRORS."
	
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
