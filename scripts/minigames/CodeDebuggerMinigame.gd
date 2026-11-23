extends CanvasLayer

# =============================================================================
# MINIJUEGO: PROGRAMACIÓN Y TERMINAL DE DESARROLLO (SYSTEM CODE TERMINAL)
# Comandos requeridos por diseño:
# - /sistem-configure (iniciar a programar)
# - var (define variables, lleva [])
# - const (define constantes, lleva [])
# - funcs (define funciones, lleva {})
# - node + name (módulo complejo, lleva () para el nombre y {} al final)
# - if (bucles / condiciones en caso de)
# - else (en caso de error dentro de if)
# - clean (para limpiar en caso de que haya que cambiar un código)
# - exit (por último compilar y salir con éxito)
# Delimitadores: () para name, [] para var/const, {} para node/funcs.
# =============================================================================

signal minigame_finished(success: bool)

# Nodos Principales
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel
@onready var progress_bar: ProgressBar = $ModalControl/Panel/VBox/Header/Metrics/ProgressBar
@onready var lbl_step_count: Label = $ModalControl/Panel/VBox/Header/Metrics/LblStepCount

# Editor / Terminal (Columna Izquierda)
@onready var code_rich_text: RichTextLabel = $ModalControl/Panel/VBox/WorkHBox/LeftCol/VBox/CodePanel/Margin/CodeRichText
@onready var instruction_label: Label = $ModalControl/Panel/VBox/WorkHBox/LeftCol/VBox/InstructionPanel/Margin/InstructionLabel
@onready var command_input: LineEdit = $ModalControl/Panel/VBox/WorkHBox/LeftCol/VBox/InputBar/CommandInput
@onready var btn_execute: Button = $ModalControl/Panel/VBox/WorkHBox/LeftCol/VBox/InputBar/BtnExecute
@onready var btn_clean: Button = $ModalControl/Panel/VBox/WorkHBox/LeftCol/VBox/InputBar/BtnClean
@onready var console_feedback: Label = $ModalControl/Panel/VBox/WorkHBox/LeftCol/VBox/ConsoleFeedback

# Recuadro Lateral de Comandos (Columna Derecha)
@onready var commands_vbox: VBoxContainer = $ModalControl/Panel/VBox/WorkHBox/RightCol/VBox/Scroll/CommandsVBox
@onready var victory_banner: PanelContainer = $ModalControl/Panel/VBox/WorkHBox/RightCol/VBox/VictoryBanner

enum Stage {
	WAIT_INIT,        # Espera /sistem-configure
	NODE_DECLARATION, # node name("CyberCore") {}
	CONST_DECLARATION,# const [MAX_SECURITY]
	VAR_DECLARATION,  # var [firewall_status]
	FUNCS_DECLARATION,# funcs {audit_protocol}
	CONDITIONAL_LOGIC,# if (threat_detected) else
	WAIT_EXIT,        # exit
	COMPLETED
}

var current_stage: Stage = Stage.WAIT_INIT
var is_finished: bool = false
var written_code_lines: Array[String] = []

const STAGE_GOALS: Dictionary = {
	Stage.WAIT_INIT: {
		"title": "PASO 1 / 6: INICIALIZACIÓN DEL SISTEMA",
		"inst": "Escribe '/sistem-configure' en la consola (o pulsa el botón lateral) para arrancar el entorno de programación.",
		"syntax_hint": "Comando inicial: /sistem-configure"
	},
	Stage.NODE_DECLARATION: {
		"title": "PASO 2 / 6: DECLARACIÓN DE NODO RAÍZ",
		"inst": "Declara el nodo del sistema con nombre: 'node name(\"CyberCore\") {}'.\nRecuerda: () encierran el nombre y {} van al final de node.",
		"syntax_hint": "Sintaxis: node name(\"CyberCore\") {}"
	},
	Stage.CONST_DECLARATION: {
		"title": "PASO 3 / 6: DEFINICIÓN DE CONSTANTE",
		"inst": "Define la constante de seguridad usando corchetes []: 'const [MAX_SECURITY]'.",
		"syntax_hint": "Sintaxis: const [NOMBRE_CONST]"
	},
	Stage.VAR_DECLARATION: {
		"title": "PASO 4 / 6: DEFINICIÓN DE VARIABLE",
		"inst": "Define la variable de estado con corchetes []: 'var [firewall_status]'.",
		"syntax_hint": "Sintaxis: var [nombre_variable]"
	},
	Stage.FUNCS_DECLARATION: {
		"title": "PASO 5 / 6: DEFINICIÓN DE FUNCIÓN",
		"inst": "Define la función del protocolo con llaves {}: 'funcs {audit_protocol}'.",
		"syntax_hint": "Sintaxis: funcs {nombre_funcion}"
	},
	Stage.CONDITIONAL_LOGIC: {
		"title": "PASO 6 / 6: LÓGICA CONDICIONAL",
		"inst": "Agrega el bloque condicional con 'if' y 'else': 'if (threat_detected) else'.",
		"syntax_hint": "Sintaxis: if (condicion) else"
	},
	Stage.WAIT_EXIT: {
		"title": "COMPILACIÓN FINAL",
		"inst": "¡Código estructurado al 100%! Escribe 'exit' para compilar el firmware y guardar.",
		"syntax_hint": "Comando final: exit"
	}
}

func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if btn_cancel:
		btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	if btn_execute:
		btn_execute.pressed.connect(_on_execute_pressed)
	if btn_clean:
		btn_clean.pressed.connect(_on_clean_pressed)
	if command_input:
		command_input.text_submitted.connect(_on_input_submitted)
		
	var btn_parens = get_node_or_null("ModalControl/Panel/VBox/WorkHBox/RightCol/VBox/DelimitersGrid/BtnParens") as Button
	if btn_parens:
		btn_parens.pressed.connect(func(): _insert_symbols("()"))
	var btn_brackets = get_node_or_null("ModalControl/Panel/VBox/WorkHBox/RightCol/VBox/DelimitersGrid/BtnBrackets") as Button
	if btn_brackets:
		btn_brackets.pressed.connect(func(): _insert_symbols("[]"))
	var btn_braces = get_node_or_null("ModalControl/Panel/VBox/WorkHBox/RightCol/VBox/DelimitersGrid/BtnBraces") as Button
	if btn_braces:
		btn_braces.pressed.connect(func(): _insert_symbols("{}"))
		
	if victory_banner:
		victory_banner.visible = false
		
	_setup_commands_sidebar()
	_update_stage_ui()
	_render_code_display()
	_set_feedback("Consola lista. Ingresa '/sistem-configure' para inicializar.", Color(0.3, 0.85, 1.0))
	
	# Iniciar explicación interactiva de Jeremías sobre los comandos con recuadro en cada comando y diálogo abajo
	_start_jeremias_in_pc_tutorial()

const DIALOG_BOX_SCENE: PackedScene = preload("res://scenes/ui/DialogBox.tscn")
var command_buttons_by_cmd: Dictionary = {}
var is_jeremias_tutorial_active: bool = false
var jeremias_step_idx: int = 0
var dialog_box_inst: Control = null

const JEREMIAS_COMMAND_EXPLANATIONS: Array[Dictionary] = [
	{
		"cmd": "/sistem-configure",
		"speaker": "[JEREMIAS // SYSADMIN & TUTOR]",
		"text": "¡Epa crack! ¡Bienvenido a la terminal de sistemas y programación! No le tengas miedo a la consola, que yo te voy a guiar por todos los comandos.\nPara empezar, siempre escribes '/sistem-configure'. Esto enciende el entorno interactivo."
	},
	{
		"cmd": "node",
		"speaker": "[JEREMIAS // MÓDULO PRINCIPAL: NODE]",
		"text": "El 'node' es el contenedor o bloque raíz de tu programa (como la estructura de tu proyecto). Se junta siempre con 'name': node name(\"...\") {}."
	},
	{
		"cmd": "name",
		"speaker": "[JEREMIAS // IDENTIFICADOR: NAME]",
		"text": "El 'name' lleva paréntesis () para asignarle el nombre del módulo. Y las llaves {} contendrán todo el bloque de código de ese nodo."
	},
	{
		"cmd": "const",
		"speaker": "[JEREMIAS // CONSTANTES: CONST]",
		"text": "'const' define constantes: valores fijos protegidos que nunca van a cambiar durante la ejecución. Siempre se escriben entre corchetes: const[...]."
	},
	{
		"cmd": "var",
		"speaker": "[JEREMIAS // VARIABLES: VAR]",
		"text": "'var' define variables: cajitas para guardar datos dinámicos que sí pueden cambiar a lo largo del programa. También llevan corchetes: var[...]."
	},
	{
		"cmd": "funcs",
		"speaker": "[JEREMIAS // FUNCIONES: FUNCS]",
		"text": "'funcs' define funciones o bloques de acciones que ejecuta el sistema. Su contenido va encerrado siempre entre llaves: funcs{...}."
	},
	{
		"cmd": "if",
		"speaker": "[JEREMIAS // CONDICIONES: IF]",
		"text": "'if' evalúa condiciones lógicas (en caso de). Si la condición se cumple, se ejecuta el bloque de código correspondiente."
	},
	{
		"cmd": "else",
		"speaker": "[JEREMIAS // CASO ALTERNATIVO: ELSE]",
		"text": "'else' acompaña al 'if' y se activa en caso de error o cuando no se cumple la condición del 'if'."
	},
	{
		"cmd": "clean",
		"speaker": "[JEREMIAS // BORRADO: CLEAN]",
		"text": "'clean' es tu salvavidas: si te equivocas al tipear una línea de código o quieres cambiarla, escribe clean para limpiarla al instante."
	},
	{
		"cmd": "exit",
		"speaker": "[JEREMIAS // COMPILAR: EXIT]",
		"text": "Y por último, 'exit': cuando termines de tipear toda la estructura de código, escribe exit para compilar y desplegar el sistema. ¡A romperla, fiera!"
	}
]

func _start_jeremias_in_pc_tutorial() -> void:
	if not DIALOG_BOX_SCENE:
		return
		
	is_jeremias_tutorial_active = true
	jeremias_step_idx = 0
	
	if command_input:
		command_input.editable = false
		command_input.release_focus()
	
	dialog_box_inst = DIALOG_BOX_SCENE.instantiate()
	dialog_box_inst.name = "DialogBoxTutorial"
	dialog_box_inst.z_index = 80
	add_child(dialog_box_inst)
	
	_show_current_tutorial_step()

func _show_current_tutorial_step() -> void:
	if not is_jeremias_tutorial_active or not is_instance_valid(dialog_box_inst):
		_finish_jeremias_tutorial()
		return
	if jeremias_step_idx >= JEREMIAS_COMMAND_EXPLANATIONS.size():
		_finish_jeremias_tutorial()
		return
		
	var step = JEREMIAS_COMMAND_EXPLANATIONS[jeremias_step_idx]
	_highlight_command_in_sidebar(step["cmd"])
	
	dialog_box_inst.show_message(step["speaker"], step["text"], func():
		_next_jeremias_tutorial_step()
	)

func _next_jeremias_tutorial_step() -> void:
	jeremias_step_idx += 1
	_show_current_tutorial_step()

func _highlight_command_in_sidebar(cmd_name: String) -> void:
	for c_key in command_buttons_by_cmd.keys():
		var b: Button = command_buttons_by_cmd[c_key]
		if not is_instance_valid(b):
			continue
		if c_key == cmd_name:
			var hl_style = StyleBoxFlat.new()
			hl_style.bg_color = Color(0.0, 0.35, 0.45, 0.75)
			hl_style.border_color = Color(0.0, 1.0, 0.85, 1.0)
			hl_style.border_width_left = 2
			hl_style.border_width_top = 2
			hl_style.border_width_right = 2
			hl_style.border_width_bottom = 2
			hl_style.corner_radius_top_left = 6
			hl_style.corner_radius_top_right = 6
			hl_style.corner_radius_bottom_right = 6
			hl_style.corner_radius_bottom_left = 6
			hl_style.content_margin_left = 8
			hl_style.content_margin_right = 8
			b.add_theme_stylebox_override("normal", hl_style)
			b.add_theme_stylebox_override("hover", hl_style)
			b.add_theme_stylebox_override("focus", hl_style)
			
			var scroll = b.get_parent().get_parent() as ScrollContainer
			if scroll and scroll.has_method("ensure_control_visible"):
				scroll.ensure_control_visible(b)
		else:
			b.remove_theme_stylebox_override("normal")
			b.remove_theme_stylebox_override("hover")
			b.remove_theme_stylebox_override("focus")

func _finish_jeremias_tutorial() -> void:
	is_jeremias_tutorial_active = false
	for c_key in command_buttons_by_cmd.keys():
		var b: Button = command_buttons_by_cmd[c_key]
		if is_instance_valid(b):
			b.remove_theme_stylebox_override("normal")
			b.remove_theme_stylebox_override("hover")
			b.remove_theme_stylebox_override("focus")
			
	if is_instance_valid(dialog_box_inst):
		dialog_box_inst.close_dialog()
		dialog_box_inst.queue_free()
		dialog_box_inst = null
		
	if command_input:
		command_input.editable = true
		command_input.grab_focus()

func _input(event: InputEvent) -> void:
	if is_jeremias_tutorial_active and is_instance_valid(dialog_box_inst) and dialog_box_inst.is_active:
		var is_e_key: bool = false
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_E or event.physical_keycode == KEY_E or event.is_action_pressed("interact"):
				is_e_key = true
		var is_left_click: bool = false
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if event.position.y > (get_viewport().get_visible_rect().size.y * 0.5):
				is_left_click = true
				
		if is_e_key or is_left_click:
			get_viewport().set_input_as_handled()
			if dialog_box_inst.is_typing:
				dialog_box_inst._finish_typing()
			else:
				dialog_box_inst.close_dialog()
			return
			
		if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
			get_viewport().set_input_as_handled()
			_finish_jeremias_tutorial()
			return

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		_finish_jeremias_tutorial()
		minigame_finished.emit(false)

func _setup_commands_sidebar() -> void:
	if not commands_vbox:
		return
	for c in commands_vbox.get_children():
		c.queue_free()
	command_buttons_by_cmd.clear()
		
	var commands_data = [
		{"cmd": "/sistem-configure", "desc": "Iniciar a programar la terminal", "token": "/sistem-configure", "col": Color(0.1, 0.95, 0.8)},
		{"cmd": "node", "desc": "Módulo complejo (se junta con name)", "token": "node name(\"CyberCore\") {}", "col": Color(1.0, 0.85, 0.2)},
		{"cmd": "name", "desc": "Asigna el nombre entre ( )", "token": "name(\"CyberCore\")", "col": Color(1.0, 0.7, 0.3)},
		{"cmd": "const", "desc": "Define constantes usando [ ]", "token": "const [MAX_SECURITY]", "col": Color(0.4, 0.9, 1.0)},
		{"cmd": "var", "desc": "Define variables usando [ ]", "token": "var [firewall_status]", "col": Color(0.4, 0.9, 1.0)},
		{"cmd": "funcs", "desc": "Define funciones usando { }", "token": "funcs {audit_protocol}", "col": Color(0.9, 0.45, 1.0)},
		{"cmd": "if", "desc": "Bucles / condición en caso de", "token": "if (threat_detected)", "col": Color(1.0, 0.5, 0.5)},
		{"cmd": "else", "desc": "En caso de error dentro de if", "token": "else", "col": Color(1.0, 0.6, 0.4)},
		{"cmd": "clean", "desc": "Limpiar código para cambiarlo", "token": "clean", "col": Color(0.85, 0.85, 0.85)},
		{"cmd": "exit", "desc": "Por último salir y compilar", "token": "exit", "col": Color(0.2, 1.0, 0.5)},
	]
	
	for item in commands_data:
		var btn = Button.new()
		btn.text = "⌨ %-18s │ %s" % [item["cmd"], item["desc"]]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 32)
		btn.add_theme_font_size_override("font_size", 10)
		btn.add_theme_color_override("font_color", item["col"])
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		var tok = item["token"]
		btn.pressed.connect(func(): _insert_token(tok))
		commands_vbox.add_child(btn)
		command_buttons_by_cmd[item["cmd"]] = btn

func _insert_token(token: String) -> void:
	if command_input:
		command_input.text = token
		command_input.grab_focus()
		command_input.caret_column = command_input.text.length()

func _insert_symbols(symbols: String) -> void:
	if command_input:
		command_input.text += symbols
		command_input.grab_focus()
		command_input.caret_column = command_input.text.length()

func _on_execute_pressed() -> void:
	if command_input:
		_process_command(command_input.text.strip_edges())

func _on_clean_pressed() -> void:
	_execute_clean()

func _on_input_submitted(text: String) -> void:
	_process_command(text.strip_edges())

func _execute_clean() -> void:
	if command_input:
		command_input.clear()
	_set_feedback("🧹 Buffer limpiado. Listo para ingresar nuevo comando.", Color(0.9, 0.85, 0.3))

func _process_command(raw_input: String) -> void:
	if is_jeremias_tutorial_active:
		_finish_jeremias_tutorial()
		
	if raw_input == "":
		_set_feedback("⚠️ Escribe un comando o pulsa uno de la lista lateral.", Color(1.0, 0.4, 0.4))
		return
		
	# Comando global 'clean'
	if raw_input.to_lower() == "clean":
		_execute_clean()
		return
		
	# Normalización para comprobaciones flexibles
	var norm = raw_input.replace("  ", " ").strip_edges()
	var norm_lower = norm.to_lower()
	
	match current_stage:
		Stage.WAIT_INIT:
			if norm_lower == "/sistem-configure" or norm_lower == "/system-configure" or norm_lower == "/sistem_configure":
				_set_feedback("✓ ¡MODO PROGRAMACIÓN ACTIVO! Intérprete inicializado con éxito.", Color(0.2, 1.0, 0.5))
				written_code_lines.append("# --- FIRMWARE SISTEMAS CYBERCORE v4.19 ---")
				written_code_lines.append("# [MODO DE DESARROLLO INICIALIZADO]")
				current_stage = Stage.NODE_DECLARATION
				_advance_stage()
			else:
				_set_feedback("⚠️ COMANDO INCORRECTO: Debes iniciar con '/sistem-configure'. Puedes usar 'clean' para borrar.", Color(1.0, 0.4, 0.4))

		Stage.NODE_DECLARATION:
			# Requiere node y name. Delimitadores: () para el nombre y {} al final
			var has_node = norm_lower.begins_with("node")
			var has_name = "name" in norm_lower
			var has_parens = "(" in norm and ")" in norm
			var has_braces = "{" in norm and "}" in norm
			
			if not has_node or not has_name:
				_set_feedback("⚠️ ERROR DE SINTAXIS: 'node' se junta siempre con 'name'. Ej: node name(\"CyberCore\") {}", Color(1.0, 0.4, 0.4))
			elif not has_parens:
				_set_feedback("⚠️ DELIMITADORES: Las barras '()' van para encerrar el nombre después de 'name'. Ej: name(\"CyberCore\")", Color(1.0, 0.5, 0.3))
			elif not has_braces:
				_set_feedback("⚠️ DELIMITADORES: Las barras '{}' se ponen después de 'node'. Ej: node name(\"CyberCore\") {}", Color(1.0, 0.5, 0.3))
			else:
				_set_feedback("✓ ¡NODO DECLARADO CON ÉXITO! Bloque principal abierto.", Color(0.2, 1.0, 0.5))
				written_code_lines.append("node name(\"CyberCore\") {")
				current_stage = Stage.CONST_DECLARATION
				_advance_stage()

		Stage.CONST_DECLARATION:
			# Requiere const y delimitador []
			var has_const = norm_lower.begins_with("const")
			var has_brackets = "[" in norm and "]" in norm
			
			if not has_const:
				_set_feedback("⚠️ SINTAXIS: Se requiere definir una constante con 'const'. Ej: const [MAX_SECURITY]", Color(1.0, 0.4, 0.4))
			elif not has_brackets:
				_set_feedback("⚠️ DELIMITADORES: Las barras '[]' se ponen después de 'const' o 'var'. Ej: const [MAX_SECURITY]", Color(1.0, 0.5, 0.3))
			else:
				_set_feedback("✓ ¡CONSTANTE REGISTRADA! Parámetro protegido en memoria.", Color(0.2, 1.0, 0.5))
				written_code_lines.append("    const [MAX_SECURITY]")
				current_stage = Stage.VAR_DECLARATION
				_advance_stage()

		Stage.VAR_DECLARATION:
			# Requiere var y delimitador []
			var has_var = norm_lower.begins_with("var")
			var has_brackets = "[" in norm and "]" in norm
			
			if not has_var:
				_set_feedback("⚠️ SINTAXIS: Se requiere definir una variable con 'var'. Ej: var [firewall_status]", Color(1.0, 0.4, 0.4))
			elif not has_brackets:
				_set_feedback("⚠️ DELIMITADORES: Las barras '[]' se ponen después de 'var'. Ej: var [firewall_status]", Color(1.0, 0.5, 0.3))
			else:
				_set_feedback("✓ ¡VARIABLE DEFINIDA! Espacio de control asignado.", Color(0.2, 1.0, 0.5))
				written_code_lines.append("    var [firewall_status]")
				current_stage = Stage.FUNCS_DECLARATION
				_advance_stage()

		Stage.FUNCS_DECLARATION:
			# Requiere funcs y delimitador {}
			var has_funcs = norm_lower.begins_with("funcs") or norm_lower.begins_with("func")
			var has_braces = "{" in norm and "}" in norm
			
			if not has_funcs:
				_set_feedback("⚠️ SINTAXIS: Se requiere definir la función con 'funcs'. Ej: funcs {audit_protocol}", Color(1.0, 0.4, 0.4))
			elif not has_braces:
				_set_feedback("⚠️ DELIMITADORES: Las barras '{}' se ponen después de 'funcs' y 'node'. Ej: funcs {audit_protocol}", Color(1.0, 0.5, 0.3))
			else:
				_set_feedback("✓ ¡FUNCIÓN DEFINIDA! Subrutina de auditoría registrada.", Color(0.2, 1.0, 0.5))
				written_code_lines.append("    funcs {audit_protocol}")
				current_stage = Stage.CONDITIONAL_LOGIC
				_advance_stage()

		Stage.CONDITIONAL_LOGIC:
			# Requiere if y else
			var has_if = "if" in norm_lower
			var has_else = "else" in norm_lower
			
			if not has_if:
				_set_feedback("⚠️ CONDICIONAL: Falta 'if' (bucles / condiciones en caso de).", Color(1.0, 0.4, 0.4))
			elif not has_else:
				_set_feedback("⚠️ CONDICIONAL: Falta 'else' (en caso de error dentro de if). Ej: if (threat_detected) else", Color(1.0, 0.5, 0.3))
			else:
				_set_feedback("✓ ¡ESTRUCTURA DE CONTROL COMPLETADA! if/else configurados.", Color(0.2, 1.0, 0.5))
				written_code_lines.append("        if (threat_detected)")
				written_code_lines.append("        else")
				written_code_lines.append("}")
				current_stage = Stage.WAIT_EXIT
				_advance_stage()

		Stage.WAIT_EXIT:
			if norm_lower == "exit" or norm_lower == "/exit":
				_execute_exit_and_compile()
			else:
				_set_feedback("⚠️ TERMINAL: Código terminado. Escribe 'exit' para compilar y guardar.", Color(1.0, 0.85, 0.2))

func _advance_stage() -> void:
	if command_input:
		command_input.clear()
	_update_stage_ui()
	_render_code_display()

func _update_stage_ui() -> void:
	var step_num = int(current_stage)
	var total_steps = 6
	progress_bar.value = clampf(float(step_num) / float(total_steps) * 100.0, 0.0, 100.0)
	lbl_step_count.text = "PROGRESO: %d / %d PASOS" % [mini(step_num, total_steps), total_steps]
	
	if STAGE_GOALS.has(current_stage):
		var goal = STAGE_GOALS[current_stage]
		instruction_label.text = "🎯 %s\n%s" % [goal["title"], goal["inst"]]
		status_label.text = goal["syntax_hint"]

func _render_code_display() -> void:
	if not code_rich_text:
		return
	var bb = ""
	var line_idx = 1
	for line in written_code_lines:
		var colored_line = _colorize_line(line)
		bb += "[color=#556677]%2d[/color]  %s\n" % [line_idx, colored_line]
		line_idx += 1
		
	# Línea activa parpadeante
	if current_stage != Stage.COMPLETED:
		bb += "[color=#556677]%2d[/color]  [color=#00e5ff]❯[/color] [color=#ffcc00]_[/color]\n" % line_idx
		
	code_rich_text.text = bb

func _colorize_line(line: String) -> String:
	if line.begins_with("#"):
		return "[color=#667788]%s[/color]" % line
		
	var res = line
	res = res.replace("node", "[color=#ffb700]node[/color]")
	res = res.replace("name", "[color=#ff7700]name[/color]")
	res = res.replace("const", "[color=#00ddff]const[/color]")
	res = res.replace("var", "[color=#00ddff]var[/color]")
	res = res.replace("funcs", "[color=#c77dff]funcs[/color]")
	res = res.replace("if", "[color=#ff5555]if[/color]")
	res = res.replace("else", "[color=#ff7755]else[/color]")
	res = res.replace("(", "[color=#ffffff]([/color]")
	res = res.replace(")", "[color=#ffffff])[/color]")
	res = res.replace("[", "[color=#00e5ff][[/color]")
	res = res.replace("]", "[color=#00e5ff]][/color]")
	res = res.replace("{", "[color=#c77dff]{[/color]")
	res = res.replace("}", "[color=#c77dff]}[/color]")
	return res

func _set_feedback(msg: String, color: Color) -> void:
	if console_feedback:
		console_feedback.text = msg
		console_feedback.add_theme_color_override("font_color", color)

func _execute_exit_and_compile() -> void:
	if is_finished:
		return
	is_finished = true
	current_stage = Stage.COMPLETED
	_update_stage_ui()
	_render_code_display()
	
	if command_input:
		command_input.editable = false
	if btn_execute:
		btn_execute.disabled = true
	if btn_clean:
		btn_clean.disabled = true
		
	_set_feedback("🚀 INICIANDO DESPLIEGUE MASIVO // ANDROMEDA CI/CD...", Color(0.2, 1.0, 0.5))
	
	# Ejecutar la secuencia épica de compilación y despliegue
	_play_epic_deployment_sequence()

func _play_epic_deployment_sequence() -> void:
	# Crear overlay visual futurista sobre ModalControl
	var modal_ctrl = get_node_or_null("ModalControl")
	if not modal_ctrl:
		if victory_banner:
			victory_banner.visible = true
		minigame_finished.emit(true)
		return
		
	var overlay = PanelContainer.new()
	overlay.name = "EpicDeployPanel"
	overlay.anchors_preset = Control.PRESET_CENTER
	overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	overlay.custom_minimum_size = Vector2(740, 420)
	overlay.offset_left = -370
	overlay.offset_right = 370
	overlay.offset_top = -210
	overlay.offset_bottom = 210
	overlay.z_index = 50
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.03, 0.06, 0.96)
	style.border_color = Color(0.0, 0.9, 0.6, 0.9)
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.content_margin_left = 20
	style.content_margin_top = 16
	style.content_margin_right = 20
	style.content_margin_bottom = 16
	overlay.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	overlay.add_child(vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = "⚡ SECUENCIA DE COMPILACIÓN & DESPLIEGUE MASIVO ⚡"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", Color(0.1, 1.0, 0.7))
	title_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title_lbl)
	
	var subtitle_lbl = Label.new()
	subtitle_lbl.text = "PROYECTO: CyberCore.firmware [MÓDULOS: node, var, const, funcs, if/else]"
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	subtitle_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(subtitle_lbl)
	
	var d_prog = ProgressBar.new()
	d_prog.custom_minimum_size = Vector2(0, 22)
	d_prog.value = 0.0
	d_prog.show_percentage = true
	var p_style_bg = StyleBoxFlat.new()
	p_style_bg.bg_color = Color(0.05, 0.08, 0.12, 1.0)
	p_style_bg.corner_radius_top_left = 5
	p_style_bg.corner_radius_top_right = 5
	p_style_bg.corner_radius_bottom_left = 5
	p_style_bg.corner_radius_bottom_right = 5
	var p_style_fg = StyleBoxFlat.new()
	p_style_fg.bg_color = Color(0.0, 0.85, 0.6, 1.0)
	p_style_fg.corner_radius_top_left = 5
	p_style_fg.corner_radius_top_right = 5
	p_style_fg.corner_radius_bottom_left = 5
	p_style_fg.corner_radius_bottom_right = 5
	d_prog.add_theme_stylebox_override("background", p_style_bg)
	d_prog.add_theme_stylebox_override("fill", p_style_fg)
	vbox.add_child(d_prog)
	
	var stage_badge = Label.new()
	stage_badge.text = "[ 1/4 ] Descargando dependencias..."
	stage_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_badge.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	stage_badge.add_theme_font_size_override("font_size", 12)
	vbox.add_child(stage_badge)
	
	var log_panel = PanelContainer.new()
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var log_style = StyleBoxFlat.new()
	log_style.bg_color = Color(0.01, 0.02, 0.04, 0.95)
	log_style.border_color = Color(0.15, 0.3, 0.4, 0.7)
	log_style.border_width_bottom = 1
	log_style.border_width_top = 1
	log_style.border_width_left = 1
	log_style.border_width_right = 1
	log_style.content_margin_left = 12
	log_style.content_margin_top = 8
	log_style.content_margin_right = 12
	log_style.content_margin_bottom = 8
	log_panel.add_theme_stylebox_override("panel", log_style)
	vbox.add_child(log_panel)
	
	var log_txt = RichTextLabel.new()
	log_txt.bbcode_enabled = true
	log_txt.scroll_following = true
	log_panel.add_child(log_txt)
	
	modal_ctrl.add_child(overlay)
	
	# Animación secuencial
	_run_deployment_phases(d_prog, stage_badge, log_txt, overlay)

func _run_deployment_phases(d_prog: ProgressBar, stage_badge: Label, log_txt: RichTextLabel, overlay: PanelContainer) -> void:
	# Fase 1: Descarga
	stage_badge.text = "📦 [FASE 1/4] DESCARGANDO DEPENDENCIAS & PAQUETES DEL SISTEMA..."
	log_txt.text = "[color=#00e5ff]>> [FETCH][/color] Conectando a repositorio seguro https://pkg.cybercore.sys/repo...\n[color=#00e5ff]>> [FETCH][/color] Descargando libcore-runtime v4.2 [34.5 MB]... [color=#00ff88]100% OK[/color]\n[color=#00e5ff]>> [FETCH][/color] Descargando syntax-core-symbols [12.1 MB]... [color=#00ff88]100% OK[/color]\n"
	d_prog.value = 25.0
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("spawn_floating_text"):
		gm.spawn_floating_text("📦 DESCARGANDO DEPENDENCIAS...", true)
	await get_tree().create_timer(0.6).timeout
	
	# Fase 2: Comprobación
	stage_badge.text = "🔍 [FASE 2/4] COMPROBANDO CHECKSUMS SHA-256 Y SINTAXIS..."
	log_txt.text += "[color=#ffb700]>> [SHA-256][/color] Verificando suma de comprobación criptográfica: a9f8e4c... [color=#00ff88]VALIDADO[/color]\n[color=#ffb700]>> [AUDIT][/color] Validando estructuras node, var[], const[], funcs{}, if/else... [color=#00ff88]0 ERRORES[/color]\n"
	d_prog.value = 50.0
	if gm and gm.has_method("spawn_floating_text"):
		gm.spawn_floating_text("🔍 CHECKSUMS Y SINTAXIS 100% OK", true)
	await get_tree().create_timer(0.6).timeout
	
	# Fase 3: Compilación
	stage_badge.text = "⚙️ [FASE 3/4] COMPILANDO CÓDIGO FUENTE & ENSAMBLADO NATIVO..."
	log_txt.text += "[color=#c77dff]>> [LLVM-OPT][/color] Ensamblando binario ejecutable x86_64 para Andromeda Kernel...\n[color=#c77dff]>> [LINKER][/color] Enlazando controladores I/O y llamadas de sistema de Ring 0... [color=#00ff88]EXITOSO[/color]\n"
	d_prog.value = 75.0
	if gm and gm.has_method("spawn_floating_text"):
		gm.spawn_floating_text("⚙️ COMPILANDO CÓDIGO FUENTE...", true)
	await get_tree().create_timer(0.6).timeout
	
	# Fase 4: Despliegue y Núcleo en Línea
	stage_badge.text = "🚀 [FASE 4/4] INYECTANDO FIRMWARE EN EL NÚCLEO & DESPLIEGUE MASIVO..."
	log_txt.text += "[color=#00ff88]>> [INJECT][/color] Inyectando microcódigo en los procesadores del servidor...\n[color=#00ff88]>> [KERNEL][/color] ¡TODOS LOS SERVICIOS Y NÓDULOS EN LÍNEA AL 100%! 🚀\n[color=#ffff00]>> [STATUS][/color] ¡DESPLIEGUE MASIVO COMPLETADO CON ÉXITO ABSOLUTO!\n"
	d_prog.value = 100.0
	if gm and gm.has_method("spawn_floating_text"):
		gm.spawn_floating_text("🚀 ¡SISTEMA DESPLEGADO AL 100%!", true)
		
	if victory_banner:
		victory_banner.visible = true
		victory_banner.scale = Vector2(0.6, 0.6)
		victory_banner.modulate.a = 0.0
		var tw = create_tween().set_parallel(true)
		tw.tween_property(victory_banner, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(victory_banner, "modulate:a", 1.0, 0.25)
		
	await get_tree().create_timer(1.0).timeout
	minigame_finished.emit(true)
