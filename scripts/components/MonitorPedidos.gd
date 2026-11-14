class_name MonitorPedidos
extends StaticBody3D

signal terminal_opened
signal terminal_closed

const ORDERS_MODAL_SCENE: PackedScene = preload("res://scenes/ui/CustomerOrdersModal.tscn")

@onready var label_3d: Label3D = $Label3D
@onready var light_3d: OmniLight3D = $OmniLight3D

var _active_modal: Control = null
var _player_ref: Node = null

func _get_loc():
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/LocalizationManager")

func _tr(key: String) -> String:
	var lm = _get_loc()
	if lm and lm.has_method("translate"):
		return lm.translate(key)
	return key

func _ready() -> void:
	# Configurar colisiones para que el raycast del jugador lo detecte
	collision_layer = 1
	collision_mask = 1
	_update_label_text()
	var lm = _get_loc()
	if lm and lm.has_signal("locale_changed"):
		lm.locale_changed.connect(func(_l): _update_label_text())

func _update_label_text() -> void:
	if label_3d:
		var txt_title = _tr("TERMINAL DE PEDIDOS")
		var txt_prompt = _tr("[ E ] ACCEDER")
		label_3d.text = "🖥️ " + txt_title + "\n" + txt_prompt

func get_interaction_prompt() -> String:
	var action_text = _tr("Terminal de Pedidos: Gestión de Clientes")
	return "[E] " + action_text

func interact(player) -> void:
	if _active_modal and is_instance_valid(_active_modal):
		return
	_player_ref = player
	_open_terminal()

func _get_hud() -> Control:
	if _player_ref and "hud_node" in _player_ref and _player_ref.hud_node:
		return _player_ref.hud_node
	return get_tree().root.find_child("HUD", true, false) as Control

func _open_terminal() -> void:
	if not ORDERS_MODAL_SCENE:
		push_error("CustomerOrdersModal scene not found!")
		return
		
	# Pausar temporalmente movimiento del jugador
	if _player_ref and "can_move" in _player_ref:
		_player_ref.can_move = false
		
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Ocultar con animación el contador de errores, score y botones 1 al 5 (el tiempo sigue visible)
	var hud = _get_hud()
	if hud and hud.has_method("hide_gameplay_hud_for_modal"):
		hud.hide_gameplay_hud_for_modal(true)
	
	_active_modal = ORDERS_MODAL_SCENE.instantiate()
	_active_modal.connect("tree_exited", Callable(self, "_on_modal_closed"))
	
	# Añadir al viewport raíz o canvas layer
	var root = get_tree().root
	root.add_child(_active_modal)
	
	if light_3d:
		var tw = create_tween()
		tw.tween_property(light_3d, "light_energy", 2.2, 0.15)
		tw.tween_property(light_3d, "light_energy", 1.2, 0.3)
		
	terminal_opened.emit()

func _on_modal_closed() -> void:
	_active_modal = null
	if _player_ref and is_instance_valid(_player_ref):
		if "can_move" in _player_ref:
			_player_ref.can_move = true
			
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Reaparecer con animación el contador de errores, score y botones 1 al 5
	var hud = _get_hud()
	if hud and hud.has_method("show_gameplay_hud_from_modal"):
		hud.show_gameplay_hud_from_modal(true)
		
	terminal_closed.emit()
