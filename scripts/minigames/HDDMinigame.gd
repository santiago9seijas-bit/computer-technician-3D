extends Control

signal minigame_finished(success: bool)

enum State {
	UNSCREW_4,
	DISCONNECT_SATA,
	REMOVE_OLD_HDD,
	INSERT_NEW_HDD,
	CONNECT_SATA_NEW,
	SCREW_4,
	COMPLETED
}

var current_state: State = State.UNSCREW_4
var screws_left: int = 4
var screws_tightened: int = 0
var sata_connected: bool = true

@onready var status_label: Label = $Panel/StatusLabel
@onready var btn_sata: Button = $Panel/DiskArea/BtnSATA
@onready var disk_panel: Panel = $Panel/DiskArea/DiskPanel
@onready var btn_cancel: Button = $Panel/BtnCancel
@onready var btn_action: Button = $Panel/BtnAction

@onready var screws: Array[Button] = [
	$Panel/DiskArea/Screw1,
	$Panel/DiskArea/Screw2,
	$Panel/DiskArea/Screw3,
	$Panel/DiskArea/Screw4
]

func _ready() -> void:
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	btn_sata.pressed.connect(_on_sata_pressed)
	btn_action.pressed.connect(_on_action_pressed)
	btn_action.visible = false
	
	for i in range(screws.size()):
		var s = screws[i]
		s.pressed.connect(func(): _on_screw_pressed(s))
		
	_update_ui_state()

func _update_ui_state() -> void:
	match current_state:
		State.UNSCREW_4:
			status_label.text = "Paso 1: Equipa la Tecla 1 (Destornillador Estrella) y quita los 4 tornillos."
		State.DISCONNECT_SATA:
			status_label.text = "Paso 2: Desconecta el cable SATA de datos y energía."
		State.REMOVE_OLD_HDD:
			status_label.text = "Paso 3: Extrae el Disco Duro dañado hacia la mochila."
			btn_action.visible = true
			btn_action.text = "Extraer Disco Duro Dañado"
		State.INSERT_NEW_HDD:
			status_label.text = "Paso 4: Coloca el Disco Duro nuevo desde la mochila."
			btn_action.visible = true
			btn_action.text = "Colocar Disco Duro Nuevo"
		State.CONNECT_SATA_NEW:
			status_label.text = "Paso 5: Vuelve a conectar el cable SATA."
			btn_action.visible = false
		State.SCREW_4:
			status_label.text = "Paso 6: Con la Tecla 1, vuelve a ajustar los 4 tornillos de seguridad."
		State.COMPLETED:
			status_label.text = "¡Disco Duro reemplazado y asegurado con éxito!"
			status_label.modulate = Color(0, 1, 0.4, 1)

func _on_screw_pressed(btn: Button) -> void:
	# Verificar si tiene equipada la herramienta 1 (Estrella)
	if GameManager.equipped_tool != 1:
		GameManager.register_error(2.0)
		status_label.text = "¡Herramienta incorrecta! Presiona la TECLA 1 (Destornillador Estrella)."
		return
		
	if current_state == State.UNSCREW_4:
		btn.visible = false
		screws_left -= 1
		if screws_left <= 0:
			current_state = State.DISCONNECT_SATA
			_update_ui_state()
	elif current_state == State.SCREW_4:
		btn.modulate = Color(0, 1, 0.5, 1) # Asegurado
		btn.disabled = true
		screws_tightened += 1
		if screws_tightened >= 4:
			current_state = State.COMPLETED
			_update_ui_state()
			await get_tree().create_timer(0.8).timeout
			minigame_finished.emit(true)

func _on_sata_pressed() -> void:
	if current_state == State.DISCONNECT_SATA:
		sata_connected = false
		btn_sata.text = "Cable SATA: [DESCONECTADO]"
		btn_sata.modulate = Color(1, 0.3, 0.3, 1)
		current_state = State.REMOVE_OLD_HDD
		_update_ui_state()
	elif current_state == State.CONNECT_SATA_NEW:
		sata_connected = true
		btn_sata.text = "Cable SATA: [CONECTADO]"
		btn_sata.modulate = Color(0, 1, 0.5, 1)
		# Mostrar tornillos para volver a ajustar
		for s in screws:
			s.visible = true
			s.disabled = false
			s.modulate = Color(1, 1, 1, 1)
		current_state = State.SCREW_4
		_update_ui_state()

func _on_action_pressed() -> void:
	if current_state == State.REMOVE_OLD_HDD:
		GameManager.add_item_to_backpack({"name": "Disco Duro", "broken": true})
		disk_panel.visible = false
		current_state = State.INSERT_NEW_HDD
		_update_ui_state()
	elif current_state == State.INSERT_NEW_HDD:
		# Buscar si tiene repuesto de disco
		var idx = -1
		for i in range(GameManager.backpack.size()):
			var item = GameManager.backpack[i]
			if item.get("name") == "Disco Duro" and not item.get("broken", true):
				idx = i
				break
				
		if idx == -1:
			GameManager.register_error(3.0)
			status_label.text = "¡No tienes un Disco Duro nuevo en la mochila! Ve a repuestos."
			return
			
		GameManager.remove_item_from_backpack(idx)
		disk_panel.visible = true
		disk_panel.modulate = Color(0, 0.9, 1, 1)
		current_state = State.CONNECT_SATA_NEW
		_update_ui_state()
