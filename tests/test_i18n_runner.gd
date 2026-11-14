extends Node

func _ready() -> void:
	print("--- INICIANDO TEST DE LOCALIZACIÓN (RUNNER) ---")

	var loc = get_node_or_null("/root/LocalizationManager")
	assert(loc != null, "LocalizationManager debe ser un Autoload activo")

	var gm = get_node_or_null("/root/GameManager")
	assert(gm != null, "GameManager debe ser un Autoload activo")

	print("[1] Verificando idiomas disponibles...")
	var locales = loc.get_locales()
	print("  Locales:", locales)
	assert(locales.size() == 4, "Debe haber 4 idiomas")

	print("[2] Instanciando MainMenu...")
	var main_scene = load("res://scenes/menus/MainMenu.tscn")
	var main_menu = main_scene.instantiate()
	add_child(main_menu)

	var btn_prev = main_menu.get_node_or_null("ConfigPanel/Margin/VBox/OptionsVBox/LanguageRow/ControlsHBox/BtnPrevLang")
	var btn_lang = main_menu.get_node_or_null("ConfigPanel/Margin/VBox/OptionsVBox/LanguageRow/ControlsHBox/BtnLang")
	var btn_next = main_menu.get_node_or_null("ConfigPanel/Margin/VBox/OptionsVBox/LanguageRow/ControlsHBox/BtnNextLang")

	assert(btn_prev != null, "BtnPrevLang debe existir")
	assert(btn_lang != null, "BtnLang debe existir")
	assert(btn_next != null, "BtnNextLang debe existir")

	var lbl_jugar = main_menu.get_node("VBoxContainer/BtnJugar/Label")
	var lbl_config = main_menu.get_node("VBoxContainer/BtnConfiguracion/Label")
	var lbl_controles = main_menu.get_node("VBoxContainer/BtnControles/Label")
	var lbl_salir = main_menu.get_node("VBoxContainer/BtnSalir/Label")

	print("  Inicial (ES):", lbl_jugar.text, "|", lbl_config.text, "|", btn_lang.text)
	assert(lbl_jugar.text == "JUGAR", "Debe ser JUGAR")
	assert(btn_lang.text == "[ ESPAÑOL ]", "Debe ser [ ESPAÑOL ]")
	var cfg_title = main_menu.get_node("ConfigPanel/Margin/VBox/HeaderVBox/Title")
	var cfg_master = main_menu.get_node("ConfigPanel/Margin/VBox/OptionsVBox/MasterVolRow/Lbl")
	var cfg_lang_lbl = main_menu.get_node("ConfigPanel/Margin/VBox/OptionsVBox/LanguageRow/Lbl")
	var cfg_volver = main_menu.get_node("ConfigPanel/Margin/VBox/Footer/BtnVolverConfig")
	assert(cfg_title.text == "CONFIGURACIÓN DEL SISTEMA", "Título de config en español")
	assert(cfg_master.text == "VOLUMEN MAESTRO", "Volumen maestro en español")
	assert(cfg_lang_lbl.text == "IDIOMA", "Idioma en español")
	assert(cfg_volver.text == "VOLVER", "Volver en español")

	print("[3] Flecha siguiente -> ENGLISH...")
	btn_next.pressed.emit()
	print("  (EN):", lbl_jugar.text, "|", lbl_config.text, "|", btn_lang.text)
	assert(lbl_jugar.text == "PLAY", "Debe ser PLAY")
	assert(lbl_config.text == "SETTINGS", "Debe ser SETTINGS")
	assert(btn_lang.text == "[ ENGLISH ]", "Debe ser [ ENGLISH ]")
	assert(cfg_title.text == "SYSTEM SETTINGS", "Título de config en inglés")
	assert(cfg_master.text == "MASTER VOLUME", "Master volume en inglés")
	assert(cfg_lang_lbl.text == "LANGUAGE", "Language en inglés")
	assert(cfg_volver.text == "BACK", "Back en inglés")

	print("[4] Flecha siguiente -> ITALIANO...")
	btn_next.pressed.emit()
	print("  (IT):", lbl_jugar.text, "|", lbl_config.text, "|", btn_lang.text)
	assert(lbl_jugar.text == "GIOCA", "Debe ser GIOCA")
	assert(lbl_config.text == "CONFIGURAZIONE", "Debe ser CONFIGURAZIONE")
	assert(btn_lang.text == "[ ITALIANO ]", "Debe ser [ ITALIANO ]")

	print("[5] Flecha siguiente -> PORTUGUÊS...")
	btn_next.pressed.emit()
	print("  (PT):", lbl_jugar.text, "|", lbl_config.text, "|", btn_lang.text)
	assert(lbl_jugar.text == "JOGAR", "Debe ser JOGAR")
	assert(lbl_config.text == "CONFIGURAÇÃO", "Debe ser CONFIGURAÇÃO")
	assert(btn_lang.text == "[ PORTUGUÊS ]", "Debe ser [ PORTUGUÊS ]")

	print("[6] Flecha siguiente -> ESPAÑOL...")
	btn_next.pressed.emit()
	print("  (ES):", lbl_jugar.text, "|", lbl_config.text, "|", btn_lang.text)
	assert(lbl_jugar.text == "JUGAR", "Debe ser JUGAR")
	assert(btn_lang.text == "[ ESPAÑOL ]", "Debe ser [ ESPAÑOL ]")
	assert(cfg_title.text == "CONFIGURACIÓN DEL SISTEMA", "Título de config en español tras ciclar")
	assert(cfg_master.text == "VOLUMEN MAESTRO", "Volumen maestro en español tras ciclar")
	assert(cfg_lang_lbl.text == "IDIOMA", "Idioma en español tras ciclar")
	assert(cfg_volver.text == "VOLVER", "Volver en español tras ciclar")

	print("[7] Flecha anterior -> PORTUGUÊS...")
	btn_prev.pressed.emit()
	print("  (PT):", lbl_jugar.text, "|", lbl_config.text, "|", btn_lang.text)
	assert(lbl_jugar.text == "JOGAR", "Debe ser JOGAR")
	assert(btn_lang.text == "[ PORTUGUÊS ]", "Debe ser [ PORTUGUÊS ]")

	print("[8] Instanciando PauseMenu en tiempo real...")
	var pause_scene = load("res://scenes/menus/PauseMenu.tscn")
	var pause_menu = pause_scene.instantiate()
	add_child(pause_menu)

	var p_prev = pause_menu.get_node_or_null("OptionsPanel/Margin/VBox/SettingsList/LanguageSection/ControlsHBox/BtnPrevLang")
	var p_lang = pause_menu.get_node_or_null("OptionsPanel/Margin/VBox/SettingsList/LanguageSection/ControlsHBox/BtnLang")
	var p_next = pause_menu.get_node_or_null("OptionsPanel/Margin/VBox/SettingsList/LanguageSection/ControlsHBox/BtnNextLang")
	var p_lbl_val = pause_menu.get_node_or_null("OptionsPanel/Margin/VBox/SettingsList/LanguageSection/HBox/LblVal")

	assert(p_prev != null and p_lang != null and p_next != null, "Controles de PauseMenu deben existir")

	var lbl_reanudar = pause_menu.get_node("ButtonsStaircase/BtnReanudar/Label")
	var lbl_opciones = pause_menu.get_node("ButtonsStaircase/BtnConfiguracion/Label")
	var lbl_reiniciar = pause_menu.get_node("ButtonsStaircase/BtnReiniciar/Label")
	var lbl_volver = pause_menu.get_node("ButtonsStaircase/BtnVolver/Label")

	print("  PauseMenu en PT -> Reanudar:", lbl_reanudar.text, "| Opciones:", lbl_opciones.text, "| Salir:", lbl_volver.text)
	assert(lbl_reanudar.text == "RETOMAR", "Debe ser RETOMAR")
	assert(lbl_opciones.text == "OPÇÕES", "Debe ser OPÇÕES")
	assert(lbl_reiniciar.text == "REINICIAR", "Debe ser REINICIAR")
	assert(lbl_volver.text == "SAIR PARA SELETOR", "Debe ser SAIR PARA SELETOR")

	print("[9] Cambiando idioma desde PauseMenu a ENGLISH...")
	loc.set_locale("en")
	print("  PauseMenu en EN -> Reanudar:", lbl_reanudar.text, "| Opciones:", lbl_opciones.text, "| Salir:", lbl_volver.text)
	assert(lbl_reanudar.text == "RESUME", "Debe ser RESUME")
	assert(lbl_opciones.text == "OPTIONS", "Debe ser OPTIONS")
	assert(lbl_reiniciar.text == "RESTART", "Debe ser RESTART")
	assert(lbl_volver.text == "EXIT TO SELECTOR", "Debe ser EXIT TO SELECTOR")

	print("[10] Probando SaveSlotsMenu en español y en inglés...")
	loc.set_locale("es")
	var save_scene = load("res://scenes/menus/SaveSlotsMenu.tscn")
	var save_menu = save_scene.instantiate()
	add_child(save_menu)
	var btn_entrar_save = save_menu.get_node("Margin/VBox/Footer/BtnEntrar")
	var prompt_hint = save_menu.get_node("Margin/VBox/Footer/PromptHint")
	var title_save = save_menu.get_node("Margin/VBox/Header/Title")

	# Ranura 1 (Con partida):
	print("  SaveSlots Slot 1 en ES -> Título:", title_save.text, " | Entrar:", btn_entrar_save.text)
	assert(title_save.text == "PARTIDAS", "Título debe ser PARTIDAS")
	assert(btn_entrar_save.text == "▶ ENTRAR A LA PARTIDA (ENTER)", "Botón con partida debe ser ▶ ENTRAR A LA PARTIDA (ENTER)")
	assert(prompt_hint.text == "[ ENTER ] o [ CLIC ] para entrar en ese set de partida", "Prompt hint en español")

	# Ranura 2 (Vacía - Partida nueva):
	save_menu._select_slot(2, false)
	print("  SaveSlots Slot 2 en ES -> Entrar:", btn_entrar_save.text)
	assert(btn_entrar_save.text == "▶ PARTIDA NUEVA (ENTER)", "Botón ranura vacía debe ser ▶ PARTIDA NUEVA (ENTER)")

	# Cambiar a EN
	loc.set_locale("en")
	print("  SaveSlots Slot 2 en EN -> Título:", title_save.text, " | Entrar:", btn_entrar_save.text)
	assert(title_save.text == "SAVED GAMES", "Título debe ser SAVED GAMES")
	assert(btn_entrar_save.text == "▶ NEW GAME (ENTER)", "Botón ranura vacía en EN debe ser ▶ NEW GAME (ENTER)")
	assert(prompt_hint.text == "[ ENTER ] or [ CLICK ] to enter this save set", "Prompt hint en inglés")

	# Ranura 1 en EN
	save_menu._select_slot(1, false)
	assert(btn_entrar_save.text == "▶ ENTER GAME (ENTER)", "Botón con partida en EN debe ser ▶ ENTER GAME (ENTER)")
	save_menu.queue_free()

	print("[11] Probando guardado y carga en ConfigFile...")
	var test_cfg = ConfigFile.new()
	test_cfg.set_value("general", "language", loc.get_locale())
	var test_path = "res://tests/test_settings_temp.cfg"
	var save_err = test_cfg.save(test_path)
	assert(save_err == OK, "Debe poder guardarse el archivo de configuración temporal")
	var load_cfg = ConfigFile.new()
	var load_err = load_cfg.load(test_path)
	assert(load_err == OK, "Debe poder cargarse el archivo de configuración")
	var lang_loaded = load_cfg.get_value("general", "language", "")
	assert(lang_loaded == "en", "El idioma guardado debe ser 'en'")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	print("  ConfigFile guardó y cargó correctamente el idioma:", lang_loaded)

	print("[12] Restaurando idioma predeterminado a ESPAÑOL...")
	loc.set_locale("es", true)
	assert(loc.get_locale() == "es", "El idioma final debe ser 'es'")

	print(">>> ¡TODOS LOS TESTS DE LOCALIZACIÓN PASARON SATISFACTORIAMENTE! <<<")
	get_tree().quit(0)
