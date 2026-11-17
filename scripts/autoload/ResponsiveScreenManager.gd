extends Node

# =============================================================================
# RESPONSIVE SCREEN MANAGER - ADAPTADOR INTELIGENTE DE PANTALLA Y BORDES
# - Detecta los bordes de la pantalla/viewport en el arranque o cambio de resolución.
# - Adapta automáticamente menús, modales de inspección y minijuegos para que
#   NUNCA se salgan de la pantalla ni se corten sus bordes.
# - Garantiza tamaño de texto óptimo y perfectamente legible en cualquier pantalla.
# - CÁLCULO INMEDIATO Y DE BAJO CONSUMO: Solo realiza el cálculo en el arranque
#   (primeros segundos) o cuando la ventana/resolución cambia de tamaño, con 0%
#   de procesamiento en bucle (_process).
# =============================================================================

signal screen_adapted(viewport_size: Vector2, scale_factor: float)

const BASE_WIDTH: float = 1280.0
const BASE_HEIGHT: float = 720.0
const MIN_READABLE_FONT_SIZE: int = 12
const TARGET_LABEL_FONT_SIZE: int = 13

# Margen mínimo de seguridad respecto a los bordes exteriores de la pantalla (px)
const MIN_BORDER_MARGIN_X: float = 20.0
const MIN_BORDER_MARGIN_Y: float = 16.0

# Registro de paneles activos gestionados
var _tracked_panels: Array[Control] = []
var _cached_viewport_size: Vector2 = Vector2.ZERO
var _cached_scale: float = 1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Conexión al cambio de resolución/pantalla
	get_tree().root.size_changed.connect(_on_screen_size_changed)
	# Detección automática al añadir nuevos menús/minijuegos
	get_tree().node_added.connect(_on_node_added)
	
	# Cálculo inmediato en el arranque
	_recalculate_bounds()

func _on_screen_size_changed() -> void:
	_recalculate_bounds()

func _recalculate_bounds() -> void:
	var vp = get_viewport()
	if not vp:
		return
	var vp_size = vp.get_visible_rect().size
	if vp_size.x <= 0 or vp_size.y <= 0:
		vp_size = Vector2(BASE_WIDTH, BASE_HEIGHT)
		
	_cached_viewport_size = vp_size
	
	# Escala de referencia respecto a 1280x720
	var sx = vp_size.x / BASE_WIDTH
	var sy = vp_size.y / BASE_HEIGHT
	_cached_scale = min(sx, sy)
	
	# Limpiar referencias nulas
	_clean_tracked_panels()
	
	# Re-adaptar inmediatamente todos los paneles actualmente abiertos
	for panel in _tracked_panels:
		if is_instance_valid(panel) and panel.is_inside_tree():
			_apply_adaptation(panel)
			
	screen_adapted.emit(_cached_viewport_size, _cached_scale)

func get_current_viewport_size() -> Vector2:
	if _cached_viewport_size == Vector2.ZERO:
		var vp = get_viewport()
		if vp:
			_cached_viewport_size = vp.get_visible_rect().size
		if _cached_viewport_size == Vector2.ZERO:
			_cached_viewport_size = Vector2(BASE_WIDTH, BASE_HEIGHT)
	return _cached_viewport_size

func get_screen_scale() -> float:
	return _cached_scale

# =============================================================================
# ADAPTACIÓN INTELIGENTE DE PANELES Y MINIJUEGOS
# =============================================================================
func adapt_panel(panel: Control, options: Dictionary = {}) -> void:
	if not is_instance_valid(panel):
		return
	
	if not _tracked_panels.has(panel):
		_tracked_panels.append(panel)
		panel.tree_exiting.connect(func():
			_tracked_panels.erase(panel)
		)
		
	_apply_adaptation(panel, options)

func _apply_adaptation(panel: Control, options: Dictionary = {}) -> void:
	if not is_instance_valid(panel):
		return
		
	var vp_size = get_current_viewport_size()
	
	# Caso especial: PCInspectionModal tiene Panel y ToolsDock simultáneos
	if panel.name == "Panel" and panel.get_parent() and panel.get_parent().name == "ModalControl" and panel.get_parent().get_parent() and panel.get_parent().get_parent().name == "PCInspectionModal":
		_adapt_pc_inspection_modal(panel.get_parent().get_parent())
		return
	
	# Guardar tamaño original del diseño
	if not panel.has_meta("orig_min_size"):
		var orig_size = panel.custom_minimum_size
		if orig_size == Vector2.ZERO:
			orig_size = panel.size
		if orig_size == Vector2.ZERO:
			orig_size = Vector2(960, 560)
		panel.set_meta("orig_min_size", orig_size)
		
	var base_size: Vector2 = panel.get_meta("orig_min_size")
	
	# Margen de seguridad respecto a los bordes de la pantalla
	var margin_x = options.get("margin_x", max(MIN_BORDER_MARGIN_X, vp_size.x * 0.02))
	var margin_y = options.get("margin_y", max(MIN_BORDER_MARGIN_Y, vp_size.y * 0.02))
	
	var available_w = max(100.0, vp_size.x - (margin_x * 2.0))
	var available_h = max(100.0, vp_size.y - (margin_y * 2.0))
	
	# Cálculo de escala de ajuste para que NUNCA se salga de los bordes ni quede diminuto
	var fit_scale_x = available_w / base_size.x
	var fit_scale_y = available_h / base_size.y
	var fit_scale = min(fit_scale_x, fit_scale_y, 1.0)
	fit_scale = clampf(fit_scale, 0.65, 1.0)
	
	# Ajuste de geometría y pivote para centrado perfecto
	panel.pivot_offset = base_size * 0.5
	panel.scale = Vector2(fit_scale, fit_scale)
	
	# Centrado exacto
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -base_size.x * 0.5
	panel.offset_top = -base_size.y * 0.5
	panel.offset_right = base_size.x * 0.5
	panel.offset_bottom = base_size.y * 0.5
	
	# Asegurar legibilidad tipográfica en todo el panel
	enhance_text_legibility(panel, fit_scale)

func _adapt_pc_inspection_modal(modal: Node) -> void:
	var panel: Control = modal.get_node_or_null("ModalControl/Panel")
	var dock: Control = modal.get_node_or_null("ModalControl/ToolsDock")
	if not panel:
		return
		
	# Asegurar que el título esté oculto/removido tal como se solicita
	var title_lbl = modal.get_node_or_null("ModalControl/Panel/VBox/Header/TitleLabel")
	if title_lbl:
		title_lbl.visible = false
		
	var vp_size = get_current_viewport_size()
	var margin_x = max(MIN_BORDER_MARGIN_X, vp_size.x * 0.02)
	var margin_y = max(MIN_BORDER_MARGIN_Y, vp_size.y * 0.02)
	var available_w = max(100.0, vp_size.x - (margin_x * 2.0))
	var available_h = max(100.0, vp_size.y - (margin_y * 2.0))
	
	# Dimensiones base optimizadas
	var base_panel_w = 950.0
	var base_panel_h = 510.0
	var base_dock_w = 120.0
	var base_dock_h = 510.0
	var sep = 12.0
	
	var total_w = base_panel_w + sep + base_dock_w # 1082.0
	var total_h = base_panel_h
	
	# Escala homogénea y legible: nunca menor a 0.82 ni mayor a 1.0
	var fit_scale = min(available_w / total_w, available_h / total_h, 1.0)
	fit_scale = clampf(fit_scale, 0.82, 1.0)
	
	# Centrado conjunto exacto de Panel + ToolsDock
	var panel_center_offset = (-total_w * 0.5 + base_panel_w * 0.5)
	var dock_center_offset = (total_w * 0.5 - base_dock_w * 0.5)
	
	panel.pivot_offset = Vector2(base_panel_w * 0.5, base_panel_h * 0.5)
	panel.scale = Vector2(fit_scale, fit_scale)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = (-base_panel_w * 0.5) + panel_center_offset
	panel.offset_top = -base_panel_h * 0.5
	panel.offset_right = (base_panel_w * 0.5) + panel_center_offset
	panel.offset_bottom = base_panel_h * 0.5
	enhance_text_legibility(panel, fit_scale)
	
	if dock:
		dock.pivot_offset = Vector2(base_dock_w * 0.5, base_dock_h * 0.5)
		dock.scale = Vector2(fit_scale, fit_scale)
		dock.set_anchors_preset(Control.PRESET_CENTER)
		dock.offset_left = (-base_dock_w * 0.5) + dock_center_offset
		dock.offset_top = -base_dock_h * 0.5
		dock.offset_right = (base_dock_w * 0.5) + dock_center_offset
		dock.offset_bottom = base_dock_h * 0.5
		enhance_text_legibility(dock, fit_scale)

# =============================================================================
# ADAPTACIÓN RESPONSIVE DEL HUD DE GAMEPLAY (BOTONES Y CONTADORES)
# =============================================================================
func _adapt_hud(hud: Control) -> void:
	if not is_instance_valid(hud) or not hud.is_inside_tree():
		return
	var vp_size = get_current_viewport_size()
	var scale_factor = min(vp_size.x / BASE_WIDTH, vp_size.y / BASE_HEIGHT)
	scale_factor = clampf(scale_factor, 0.75, 1.05)
	
	# Asegurar que el HUD esté visible
	if hud.has_method("ensure_hud_visible"):
		hud.ensure_hud_visible()
		
	# Ajuste de BottomCenter (barra de herramientas con los botones)
	var bottom_center = hud.get_node_or_null("BottomCenter") as Control
	if bottom_center:
		bottom_center.scale = Vector2(scale_factor, scale_factor)
		bottom_center.pivot_offset = Vector2(bottom_center.size.x * 0.5, bottom_center.size.y)
		bottom_center.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		bottom_center.offset_left = -290.0 * scale_factor
		bottom_center.offset_right = 290.0 * scale_factor
		bottom_center.offset_bottom = -max(8.0, 12.0 * scale_factor)
		bottom_center.offset_top = bottom_center.offset_bottom - (118.0 * scale_factor)
		
	# Ajuste de BottomLeft (contador de puntos)
	var bottom_left = hud.get_node_or_null("BottomLeft") as Control
	if bottom_left:
		bottom_left.scale = Vector2(scale_factor, scale_factor)
		bottom_left.pivot_offset = Vector2(0, bottom_left.size.y)
		bottom_left.offset_left = max(16.0, 24.0 * scale_factor)
		bottom_left.offset_bottom = -max(12.0, 20.0 * scale_factor)
		bottom_left.offset_top = bottom_left.offset_bottom - 54.0
		
	# Ajuste de TopLeft (contador de errores)
	var top_left = hud.get_node_or_null("TopLeft") as Control
	if top_left:
		top_left.scale = Vector2(scale_factor, scale_factor)
		top_left.pivot_offset = Vector2(0, 0)
		top_left.offset_left = max(16.0, 24.0 * scale_factor)
		top_left.offset_top = max(14.0, 20.0 * scale_factor)

# =============================================================================
# POTENCIADOR DE LEGIBILIDAD (FUENTES Y TEXTOS NÍTIDOS)
# =============================================================================
func enhance_text_legibility(root_node: Node, current_scale: float = 1.0) -> void:
	if not is_instance_valid(root_node):
		return
		
	# Recorrer todos los hijos recursivamente
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var node = stack.pop_back()
		if not is_instance_valid(node):
			continue
			
		for child in node.get_children():
			stack.append(child)
			
		# Mejorar legibilidad en Labels
		if node is Label:
			_enhance_label_legibility(node, current_scale)
		elif node is RichTextLabel:
			_enhance_richtext_legibility(node, current_scale)
		elif node.has_method("queue_redraw") and "custom_font_size" in node:
			# Para botones tipo CyberButton
			_enhance_cyber_button_legibility(node, current_scale)

func _enhance_label_legibility(lbl: Label, current_scale: float) -> void:
	# Guardar tamaño de fuente original
	if not lbl.has_meta("orig_font_size"):
		var fs = 0
		if lbl.has_theme_font_size_override("font_size"):
			fs = lbl.get_theme_font_size("font_size")
		else:
			fs = 14
		lbl.set_meta("orig_font_size", fs)
		
	var orig_fs: int = int(lbl.get_meta("orig_font_size"))
	var target_fs: int = orig_fs
	
	# Si la fuente original es diminuta (<= 11px), elevarla a legible (12 - 13px)
	if target_fs <= 10:
		target_fs = 12
	elif target_fs == 11:
		target_fs = TARGET_LABEL_FONT_SIZE
		
	# Compensar si la escala de ajuste es < 0.95
	if current_scale < 0.95 and current_scale > 0.0:
		var compensation = 1.0 / current_scale
		target_fs = int(round(float(target_fs) * min(compensation, 1.25)))
		
	lbl.add_theme_font_size_override("font_size", target_fs)

func _enhance_richtext_legibility(rtl: RichTextLabel, current_scale: float) -> void:
	if not rtl.has_meta("orig_font_size"):
		var fs = 14
		if rtl.has_theme_font_size_override("normal_font_size"):
			fs = rtl.get_theme_font_size("normal_font_size")
		rtl.set_meta("orig_font_size", fs)
		
	var orig_fs: int = int(rtl.get_meta("orig_font_size"))
	var target_fs: int = max(MIN_READABLE_FONT_SIZE, orig_fs)
	if current_scale < 0.95 and current_scale > 0.0:
		target_fs = int(round(float(target_fs) * min(1.0 / current_scale, 1.25)))
	rtl.add_theme_font_size_override("normal_font_size", target_fs)

func _enhance_cyber_button_legibility(btn: Node, current_scale: float) -> void:
	if not btn.has_meta("orig_custom_font_size"):
		btn.set_meta("orig_custom_font_size", btn.custom_font_size)
	var orig_fs: int = int(btn.get_meta("orig_custom_font_size"))
	var target_fs: int = max(13, orig_fs)
	if current_scale < 0.95 and current_scale > 0.0:
		target_fs = int(round(float(target_fs) * min(1.0 / current_scale, 1.2)))
	btn.custom_font_size = target_fs
	btn.queue_redraw()

# =============================================================================
# AUTO-DETECCIÓN DE NUEVOS MENÚS Y MINIJUEGOS EN EL ÁRBOL DE ESCENAS
# =============================================================================
func _on_node_added(node: Node) -> void:
	if not is_instance_valid(node):
		return
	var n_name = node.name
	# Detección de minijuegos y modales de inspección/selección
	var is_target = n_name.ends_with("Minigame") \
		or n_name.ends_with("InspectionModal") \
		or n_name.ends_with("SelectionModal") \
		or n_name.ends_with("Modal") \
		or n_name == "PCInspectionModal" \
		or n_name == "PCSystemsModal" \
		or n_name == "ServerInspectionModal" \
		or n_name == "SaveSlotsMenu" \
		or n_name == "HUD"
		
	if is_target:
		# Ejecutar en el próximo frame tras el _ready del nodo para tener dimensiones finales
		call_deferred("_try_auto_adapt_node", node)

func _try_auto_adapt_node(node: Variant = null) -> void:
	if not is_instance_valid(node) or not (node is Node) or not node.is_inside_tree():
		return
		
	if node.name == "HUD" and node is Control:
		_adapt_hud(node)
		return
		
	if node.name == "PCInspectionModal":
		_adapt_pc_inspection_modal(node)
		return
		
	# Ocultar títulos redundantes que empujan el contenido fuera de la pantalla
	var minigame_title = node.get_node_or_null("ModalControl/Panel/VBox/Header/Titulo")
	if minigame_title:
		minigame_title.visible = false
	var title_lbl = node.get_node_or_null("ModalControl/Panel/VBox/Header/TitleLabel")
	if title_lbl:
		title_lbl.visible = false

	# Buscar el Panel principal (ModalControl/Panel o Panel o PanelContainer)
	var panel = node.get_node_or_null("ModalControl/Panel")
	if not panel:
		panel = node.get_node_or_null("Panel")
	if not panel:
		panel = node.get_node_or_null("PanelContainer")
	if not panel and node is Control:
		# Si el nodo es directamente un Control con dimensiones
		if node.custom_minimum_size != Vector2.ZERO:
			panel = node
			
	if panel and panel is Control:
		adapt_panel(panel)

func _clean_tracked_panels() -> void:
	var valid_panels: Array[Control] = []
	for p in _tracked_panels:
		if is_instance_valid(p) and p.is_inside_tree():
			valid_panels.append(p)
	_tracked_panels = valid_panels
