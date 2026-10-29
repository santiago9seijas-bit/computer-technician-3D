extends Node

# Señales de estado global
signal score_updated(new_score: int, delta: int)
signal time_updated(time_left: float, delta: float)
signal error_occurred(new_errors: int, delta: int)
signal backpack_updated(items: Array)
signal tool_selected(tool_id: int)
signal game_over_triggered(reason: String)
signal level_completed(stars: int, final_score: int)
signal spares_repopulated()
signal pause_state_changed(is_paused: bool)

# Variables de juego
var current_level_id: int = 1
var time_left: float = 120.0
var timer_active: bool = false
var score: int = 0
var errors: int = 0
var computers_fixed: int = 0
var total_computers: int = 3

# Mochila / Inventario
const MAX_BACKPACK_SLOTS: int = 3
var backpack: Array[Dictionary] = []
var selected_backpack_index: int = -1

# Herramienta activa (0 = Ninguna, 1 = Estrella, 2 = Pala, 3 = Cautín, 4 = Voltímetro, 5 = Limpiador)
var equipped_tool: int = 0

# Stock de repuestos disponible en la caja
var spares_stock: Dictionary = {
	"RAM": 3,
	"Disco Duro": 3,
	"Fan Cooler": 3,
	"Fuente": 2,
	"Grafica": 2,
	"Placa Madre": 2
}

# Estado de pausa
var is_game_paused: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if timer_active and not is_game_paused:
		time_left -= delta
		if time_left <= 0.0:
			time_left = 0.0
			timer_active = false
			time_updated.emit(time_left, 0.0)
			trigger_game_over("¡Tiempo agotado! El cliente canceló el pedido.")
		else:
			time_updated.emit(time_left, -delta)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		match event.keycode:
			KEY_1, KEY_KP_1:
				select_tool(1)
			KEY_2, KEY_KP_2:
				select_tool(2)
			KEY_3, KEY_KP_3:
				select_tool(3)
			KEY_4, KEY_KP_4:
				select_tool(4)
			KEY_5, KEY_KP_5:
				select_tool(5)

func select_tool(tool_id: int) -> void:
	equipped_tool = tool_id
	tool_selected.emit(equipped_tool)

func start_level(initial_time: float = 120.0) -> void:
	time_left = initial_time
	score = 0
	errors = 0
	computers_fixed = 0
	backpack.clear()
	equipped_tool = 0
	is_game_paused = false
	timer_active = true
	
	spares_stock = {
		"RAM": 3,
		"Disco Duro": 3,
		"Fan Cooler": 3,
		"Fuente": 2,
		"Grafica": 2,
		"Placa Madre": 2
	}
	
	score_updated.emit(score, 0)
	time_updated.emit(time_left, 0.0)
	error_occurred.emit(errors, 0)
	backpack_updated.emit(backpack)
	tool_selected.emit(equipped_tool)

func register_repair(points: int = 100, time_bonus: float = 10.0) -> void:
	if not timer_active:
		return
	score += points
	time_left += time_bonus
	score_updated.emit(score, points)
	time_updated.emit(time_left, time_bonus)

func register_error(time_penalty: float = 5.0) -> void:
	if not timer_active:
		return
	errors += 1
	time_left = max(0.0, time_left - time_penalty)
	error_occurred.emit(errors, 1)
	time_updated.emit(time_left, -time_penalty)
	
	if errors >= 20:
		trigger_game_over("¡Demasiados errores acumulados (20)! El equipo sufrió daños irreparables.")

func add_item_to_backpack(item: Dictionary) -> bool:
	if backpack.size() >= MAX_BACKPACK_SLOTS:
		return false
	backpack.append(item)
	backpack_updated.emit(backpack)
	return true

func remove_item_from_backpack(index: int) -> Dictionary:
	if index >= 0 and index < backpack.size():
		var item = backpack[index]
		backpack.remove_at(index)
		backpack_updated.emit(backpack)
		return item
	return {}

func trash_selected_item() -> bool:
	if selected_backpack_index >= 0 and selected_backpack_index < backpack.size():
		var item = backpack[selected_backpack_index]
		backpack.remove_at(selected_backpack_index)
		selected_backpack_index = -1
		backpack_updated.emit(backpack)
		return true
	elif backpack.size() > 0:
		backpack.remove_at(backpack.size() - 1)
		backpack_updated.emit(backpack)
		return true
	return false

func request_spares_refill() -> void:
	spares_stock = {
		"RAM": 3,
		"Disco Duro": 3,
		"Fan Cooler": 3,
		"Fuente": 2,
		"Grafica": 2,
		"Placa Madre": 2
	}
	spares_repopulated.emit()

func calculate_stars() -> int:
	if errors <= 5:
		return 3
	elif errors <= 12:
		return 2
	elif errors < 20:
		return 1
	return 0

func win_level() -> void:
	timer_active = false
	var final_stars = calculate_stars()
	level_completed.emit(final_stars, score)

func trigger_game_over(reason: String) -> void:
	timer_active = false
	game_over_triggered.emit(reason)

func toggle_pause() -> void:
	is_game_paused = !is_game_paused
	get_tree().paused = is_game_paused
	pause_state_changed.emit(is_game_paused)
