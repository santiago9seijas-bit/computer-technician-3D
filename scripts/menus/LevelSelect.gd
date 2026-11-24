class_name LevelSelect
extends Control

# =============================================================================
# LEVEL SELECT & CENTRO DE ENTRENAMIENTO // SISTEMA UNIFICADO DE NIVELES Y TUTORIALES
# CAMBIO INSTANTÁNEO DE PESTAÑAS (0 MS RETRASO, SIN RECARGA DE ESCENA)
# =============================================================================

static var initial_tab: String = "niveles"
static var initial_mode: String = "reparacion"
static var pending_glitch_purge_node: int = -1

# --- Nodos Principales ---
@onready var background_rect: ColorRect = $Background
@onready var btn_volver: Button = $TopBar/BtnVolver
@onready var mode_header: VBoxContainer = get_node_or_null("TopBar/ModeHeader")
@onready var lbl_mode_title: Label = get_node_or_null("TopBar/ModeHeader/LblModeTitle")
@onready var lbl_mode_director: Label = get_node_or_null("TopBar/ModeHeader/LblModeDirector")
@onready var btn_niveles: Button = get_node_or_null("TopBar/Tabs/BtnNiveles")
@onready var btn_tutoriales: Button = get_node_or_null("TopBar/Tabs/BtnTutoriales")
@onready var btn_reparacion: Button = $ModeSelector/BtnReparacion
@onready var btn_fondo: Button = $ModeSelector/BtnFondo
@onready var btn_sistema: Button = $ModeSelector/BtnSistema
@onready var btn_servidor: Button = $ModeSelector/BtnServidor
@onready var banner_label: Label = get_node_or_null("SectionBanner/BannerLabel")
@onready var section_banner: Control = get_node_or_null("SectionBanner")
@onready var column_headers: HBoxContainer = $ColumnHeaders
@onready var col1_label: Label = $ColumnHeaders/Col1
@onready var col2_label: Label = $ColumnHeaders/Col2
@onready var col3_label: Label = $ColumnHeaders/Col3
@onready var footer_hint: Label = $FooterHint

# --- HUD de Estadísticas del Jugador (Abajo a la Izquierda) ---
@onready var player_stats_hud: HBoxContainer = get_node_or_null("PlayerStatsHUD")
@onready var lbl_points_val: Label = (
	get_node_or_null("PlayerStatsHUD/CardPoints/HBox/LblPointsVal")
	if get_node_or_null("PlayerStatsHUD/CardPoints/HBox/LblPointsVal")
	else get_node_or_null("PlayerStatsHUD/CardPoints/VBox/LblPointsVal")
)
@onready var lbl_stars_val: Label = (
	get_node_or_null("PlayerStatsHUD/CardStars/HBox/LblStarsVal")
	if get_node_or_null("PlayerStatsHUD/CardStars/HBox/LblStarsVal")
	else get_node_or_null("PlayerStatsHUD/CardStars/VBox/LblStarsVal")
)
@onready var lbl_dollars_val: Label = (
	get_node_or_null("PlayerStatsHUD/CardDollars/HBox/LblDollarsVal")
	if get_node_or_null("PlayerStatsHUD/CardDollars/HBox/LblDollarsVal")
	else get_node_or_null("PlayerStatsHUD/CardDollars/VBox/LblDollarsVal")
)

# --- Selector de Modo Terminal Linux (Lateral Derecho) ---
@onready var circular_mode_selector: Control = get_node_or_null("CircularModeSelector")
@onready var btn_up_arrow: Button = get_node_or_null("CircularModeSelector/BtnUpArrow")
@onready var btn_down_arrow: Button = get_node_or_null("CircularModeSelector/BtnDownArrow")
@onready var terminal_buttons: Control = get_node_or_null("CircularModeSelector/TerminalButtons")
@onready var term_btn_reparacion: PanelContainer = get_node_or_null("CircularModeSelector/TerminalButtons/TermBtnReparacion")
@onready var term_btn_sistema: PanelContainer = get_node_or_null("CircularModeSelector/TerminalButtons/TermBtnSistema")
@onready var term_btn_servidor: PanelContainer = get_node_or_null("CircularModeSelector/TerminalButtons/TermBtnServidor")

const MODE_ORDER: Array[String] = ["reparacion", "sistema", "servidor"]
var _color_tween: Tween = null
var _mode_selector_idle_timer: float = 0.0
var _is_selector_faded: bool = false
var _cursor_blink_timer: float = 0.0

const MODE_PALETTES: Dictionary = {
	"reparacion": {
		"bg_color": Color(0.05, 0.02, 0.1, 1.0),
		"accent": Color(1.0, 0.1, 0.35, 1.0),
		"accent_dim": Color(0.65, 0.05, 0.45, 0.55),
		"banner_font": Color(1.0, 0.1, 0.25, 1.0),
		"banner_shadow": Color(0.65, 0.0, 0.85, 0.8),
		"holo_ring_pri": Color(1.0, 0.15, 0.45, 1.0),
		"holo_ring_sec": Color(0.0, 0.85, 1.0, 1.0),
		"holo_ring_glow": Color(1.0, 0.1, 0.45, 0.75)
	},
	"sistema": {
		"bg_color": Color(0.015, 0.035, 0.12, 1.0),
		"accent": Color(0.18, 0.55, 1.0, 1.0),
		"accent_dim": Color(0.04, 0.22, 0.65, 0.55),
		"banner_font": Color(0.2, 0.7, 1.0, 1.0),
		"banner_shadow": Color(0.04, 0.2, 0.65, 0.8),
		"holo_ring_pri": Color(0.0, 0.88, 1.0, 1.0),
		"holo_ring_sec": Color(0.0, 0.45, 1.0, 1.0),
		"holo_ring_glow": Color(0.0, 0.85, 1.0, 0.75)
	},
	"servidor": {
		"bg_color": Color(0.08, 0.035, 0.01, 1.0),
		"accent": Color(1.0, 0.55, 0.08, 1.0),
		"accent_dim": Color(0.7, 0.25, 0.02, 0.55),
		"banner_font": Color(1.0, 0.6, 0.1, 1.0),
		"banner_shadow": Color(0.75, 0.25, 0.02, 0.8),
		"holo_ring_pri": Color(1.0, 0.55, 0.08, 1.0),
		"holo_ring_sec": Color(1.0, 0.2, 0.02, 1.0),
		"holo_ring_glow": Color(1.0, 0.55, 0.1, 0.75)
	}
}

# --- Área de Constelación (Niveles) ---
@onready var constellation_area: Control = $ConstellationArea
@onready var graph_lines: Control = $ConstellationArea/GraphLines
@onready var card_dim_overlay: ColorRect = $CardDimOverlay
@onready var btn_play_level1: Button = $BtnPlayLevel1
@onready var difficulty_selector: Control = $DifficultySelector
@onready var tutorial_info_panel: Control = get_node_or_null("TutorialInfoPanel")
@onready var level_nav_controls: HBoxContainer = get_node_or_null("LevelNavControls")
@onready var btn_nav_prev: Button = get_node_or_null("LevelNavControls/BtnNavPrev")
@onready var btn_nav_next: Button = get_node_or_null("LevelNavControls/BtnNavNext")
@onready var map_zoom_controls: Control = get_node_or_null("MapZoomControls")
@onready var btn_zoom_out: Button = get_node_or_null("MapZoomControls/Margin/HBox/BtnZoomOut")
@onready var btn_zoom_in: Button = get_node_or_null("MapZoomControls/Margin/HBox/BtnZoomIn")
@onready var zoom_slider: HSlider = get_node_or_null("MapZoomControls/Margin/HBox/ZoomSlider")
@onready var zoom_label: Label = get_node_or_null("MapZoomControls/Margin/HBox/ZoomLabel")

var current_map_zoom: float = 1.0
const MIN_MAP_ZOOM: float = 0.45
const MAX_MAP_ZOOM: float = 1.6

# --- Arrastre y desplazamiento libre del mapa (Mouse Pan Drag) ---
var is_panning_map: bool = false
var pan_start_mouse: Vector2 = Vector2.ZERO
var pan_start_area_pos: Vector2 = Vector2.ZERO

# --- Consola de Desarrollador Andromeda OS (Ctrl + Shift + R) ---
var dev_console_overlay: Control = null
var dev_console_input: LineEdit = null
var dev_console_output: RichTextLabel = null
var dev_console_body_vbox: VBoxContainer = null
var dev_console_margin_body: MarginContainer = null
var terminal_pacman_instance: Control = null
var terminal_tetris_instance: Control = null

# --- Área de Tutoriales (Centro de Entrenamiento) ---
@onready var tutorial_area: Control = get_node_or_null("TutorialArea")
@onready var cards_scroll: ScrollContainer = get_node_or_null("TutorialArea/CardsScroll")
@onready var cards_grid: GridContainer = get_node_or_null("TutorialArea/CardsScroll/CardsGrid")
@onready var left_scroll_controls: Control = get_node_or_null("TutorialArea/LeftScrollControls")
@onready var btn_scroll_up: Button = get_node_or_null("TutorialArea/LeftScrollControls/BtnScrollUp")
@onready var btn_scroll_down: Button = get_node_or_null("TutorialArea/LeftScrollControls/BtnScrollDown")

# --- Modal Desplegado de Tutorial & Simulador (Capa Superior) ---
@onready var deployed_modal: Control = $DeployedModal
@onready var dim_overlay: ColorRect = $DeployedModal/DimOverlay
@onready var deployed_card: PanelContainer = $DeployedModal/DeployedCard
@onready var btn_close_deployed: Button = $DeployedModal/DeployedCard/Margin/VBox/Header/BtnCloseDeployed
@onready var deployed_title: Label = $DeployedModal/DeployedCard/Margin/VBox/Header/TitleVBox/Title
@onready var deployed_sub: Label = $DeployedModal/DeployedCard/Margin/VBox/Header/TitleVBox/Subtitle
@onready var deployed_badge: Label = $DeployedModal/DeployedCard/Margin/VBox/Header/TitleVBox/Badge
@onready var deployed_preview: TextureRect = $DeployedModal/DeployedCard/Margin/VBox/ContentHBox/LeftCol/PreviewBox/Preview
@onready var deployed_btn_play: Button = $DeployedModal/DeployedCard/Margin/VBox/ContentHBox/LeftCol/BtnPlayMinigame
@onready var deployed_btn_tutorial_3d: Button = get_node_or_null("DeployedModal/DeployedCard/Margin/VBox/ContentHBox/LeftCol/BtnPlayTutorial3D")
@onready var lbl_que_es: Label = $DeployedModal/DeployedCard/Margin/VBox/ContentHBox/RightCol/Margin/Scroll/TextVBox/LblQueEs
@onready var lbl_importancia: Label = $DeployedModal/DeployedCard/Margin/VBox/ContentHBox/RightCol/Margin/Scroll/TextVBox/LblImportancia
@onready var lbl_que_hace: Label = $DeployedModal/DeployedCard/Margin/VBox/ContentHBox/RightCol/Margin/Scroll/TextVBox/LblQueHace
@onready var lbl_pasos: Label = $DeployedModal/DeployedCard/Margin/VBox/ContentHBox/RightCol/Margin/Scroll/TextVBox/LblPasos
@onready var minigame_container: Control = $MinigameContainer

# --- Recursos Pre-cargados ---
var glitch_material = preload("res://styles/cyber_glitch_sprite.tres")
var title_font = preload("res://assets/fonts/Bungee-Regular.ttf")

var PRELOADED_TEXTURES = {
	"res://pixel art minijuegos/fancooler/fancooler.png": preload("res://pixel art minijuegos/fancooler/fancooler.png"),
	"res://pixel art minijuegos/ramstipos/ram ddr.png": preload("res://pixel art minijuegos/ramstipos/ram ddr.png"),
	"res://pixel art minijuegos/memoriastipos/m.2/memoria M.2.png": preload("res://pixel art minijuegos/memoriastipos/m.2/memoria M.2.png"),
	"res://pixel art minijuegos/pelusa/pelusa grande.png": preload("res://pixel art minijuegos/pelusa/pelusa grande.png"),
	"res://pixel art menus/menus/fondos de menus.png": preload("res://pixel art menus/menus/fondos de menus.png"),
	"res://pixel art minijuegos/limpiezaprofunda/ramprofunda/destornillador de pala.png": preload("res://pixel art minijuegos/limpiezaprofunda/ramprofunda/destornillador de pala.png")
}

# Carga bajo demanda de escenas de minijuegos para garantizar 0 ms al alternar pestañas
var _fancooler_scene = null
var _ram_scene = null
var _ram_static_scene = null
var _hdd_scene = null
var _gpu_scene = null
var _cpu_scene = null
var _m2_scene = null
var _psu_scene = null
var _mobo_scene = null
var _liquid_cooling_scene = null
var _adware_cleaner_scene = null
var _malware_scanner_scene = null
var _os_install_scene = null
var _driver_updater_scene = null
var _code_debugger_scene = null
var _malware_invaders_scene = null
var _usb_pendrive_scene = null
var _cpu_paste_scene = null
var _cpu_pins_scene = null
var _dust_cleaner_scene = null
var _voltimeter_scene = null

const TUTORIAL_SCENES: Dictionary = {
	"cooler": "res://scenes/gameplay/LevelTutorialCooler.tscn",
	"ram": "res://scenes/gameplay/LevelTutorialRAM.tscn",
	"hdd": "res://scenes/gameplay/LevelTutorialHDD.tscn",
	"m2": "res://scenes/gameplay/LevelTutorialHDD.tscn",
	"gpu": "res://scenes/gameplay/LevelTutorialGPU.tscn",
	"psu": "res://scenes/gameplay/LevelTutorialPSU.tscn",
	"cpu": "res://scenes/gameplay/LevelTutorialCPU.tscn",
	"general": "res://scenes/gameplay/LevelTutorial.tscn"
}

# --- Variables de Estado ---
var current_tab: String = "niveles"
var current_mode: String = "reparacion"
var node_buttons: Array[Button] = []
var current_minigame_instance: Node = null
var active_card_data: Dictionary = {}
var _card_slots: Array[Button] = []
var is_level_zoomed: bool = false
var active_zoomed_index: int = -1
var camera_zoom_tween: Tween = null
var is_launching_level: bool = false
var is_exiting_scene: bool = false

# =============================================================================
# BASE DE DATOS DE LOS 12 NIVELES POR MODO (TODOS BLOQUEADOS CON INSPECCIÓN ACTIVA)
# =============================================================================
var LEVELS_DATA: Dictionary = {
	"reparacion": [
		# --- TUTORIALES 3D (BURBUJAS AZULES NEÓN 🎓) [0 - 6] ---
		{
			"number": 0,
			"is_tutorial": true,
			"tutorial_component": "general",
			"target_scene": "res://scenes/gameplay/LevelTutorial.tscn",
			"title": "NÚCLEO TUTORIAL · INDUCCIÓN AL HARDWARE",
			"stage": "CENTRO NEURONAL // TUTORIAL",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.0, 0.88, 1.0),
			"description": "Simulación interactiva holográfica de inducción.\nAprende el protocolo de seguridad, tipos de tornillos (Cruz / Pala), desacople seguro de conectores PWM y disipación térmica antes de iniciar en el taller.",
			"requirements": "HERRAMIENTAS: Acceso Total · MODO GUIADO · ACCESO LIBRE",
			"can_play": true
		},
		{
			"number": 1,
			"is_tutorial": true,
			"tutorial_component": "cooler",
			"target_scene": "res://scenes/gameplay/LevelTutorialCooler.tscn",
			"title": "TUTORIAL 3D · DISIPACIÓN TÉRMICA & FAN COOLER",
			"stage": "TUTORIAL DE HARDWARE // GUIADO POR JOA",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.0, 0.88, 1.0),
			"description": "Taller guiado paso a paso con Joa.\nAprende a desconectar el conector PWM de 4 pines, desatornillar en patrón en cruz y retirar el bloque del disipador de forma segura.",
			"requirements": "HERRAMIENTAS: Destornillador Cruz · MODO TUTORIAL GUIADO",
			"can_play": false
		},
		{
			"number": 2,
			"is_tutorial": true,
			"tutorial_component": "ram",
			"target_scene": "res://scenes/gameplay/LevelTutorialRAM.tscn",
			"title": "TUTORIAL 3D · BANCO DE MEMORIA RAM",
			"stage": "TUTORIAL DE HARDWARE // GUIADO POR JOA",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.0, 0.88, 1.0),
			"description": "Taller guiado paso a paso con Joa.\nAbre los seguros laterales del slot DIMM, alinea la muesca de la memoria RAM con el zócalo y presiona con firmeza en ambos extremos hasta escuchar el clic.",
			"requirements": "HERRAMIENTAS: Manos libres y pulsera antiestática · MODO TUTORIAL GUIADO",
			"can_play": false
		},
		{
			"number": 3,
			"is_tutorial": true,
			"tutorial_component": "hdd",
			"target_scene": "res://scenes/gameplay/LevelTutorialHDD.tscn",
			"title": "TUTORIAL 3D · ALMACENAMIENTO HDD / SSD & SATA",
			"stage": "TUTORIAL DE HARDWARE // GUIADO POR JOA",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.0, 0.88, 1.0),
			"description": "Taller guiado paso a paso con Joa.\nRetira los 4 tornillos de las esquinas del soporte, desconecta el cable SATA de datos y desliza suavemente el disco hacia la derecha.",
			"requirements": "HERRAMIENTAS: Destornillador de precisión · MODO TUTORIAL GUIADO",
			"can_play": false
		},
		{
			"number": 4,
			"is_tutorial": true,
			"tutorial_component": "gpu",
			"target_scene": "res://scenes/gameplay/LevelTutorialGPU.tscn",
			"title": "TUTORIAL 3D · TARJETA GRÁFICA GPU PCIE",
			"stage": "TUTORIAL DE HARDWARE // GUIADO POR JOA",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.0, 0.88, 1.0),
			"description": "Taller guiado paso a paso con Joa.\nDesconecta la alimentación PCIe para detener ventiladores, retira los tornillos del soporte HDMI y levanta la tarjeta manteniendo el soporte en su sitio.",
			"requirements": "HERRAMIENTAS: Destornillador Cruz y extractor PCIe · MODO TUTORIAL GUIADO",
			"can_play": false
		},
		{
			"number": 5,
			"is_tutorial": true,
			"tutorial_component": "psu",
			"target_scene": "res://scenes/gameplay/LevelTutorialPSU.tscn",
			"title": "TUTORIAL 3D · FUENTE DE PODER ATX & ARNESES",
			"stage": "TUTORIAL DE HARDWARE // GUIADO POR JOA",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.0, 0.88, 1.0),
			"description": "Taller guiado paso a paso con Joa.\nIdentifica el conector ATX principal de 24 pines y la toma auxiliar EPS de CPU, liberando las pestañas plásticas sin forzar la placa.",
			"requirements": "HERRAMIENTAS: Manos libres y extractor de cables · MODO TUTORIAL GUIADO",
			"can_play": false
		},
		{
			"number": 6,
			"is_tutorial": true,
			"tutorial_component": "cpu",
			"target_scene": "res://scenes/gameplay/LevelTutorialCPU.tscn",
			"title": "TUTORIAL 3D · ZÓCALO & PROCESADOR CPU",
			"stage": "TUTORIAL DE HARDWARE // GUIADO POR JOA",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.0, 0.88, 1.0),
			"description": "Taller guiado paso a paso con Joa.\nLevanta la palanca de retención metálica del socket, retira el procesador con máxima suavidad respetando las esquinas doradas y monta el nuevo CPU.",
			"requirements": "HERRAMIENTAS: Pinzas de precisión · MODO TUTORIAL GUIADO",
			"can_play": false
		},

		# --- NIVELES DE JUEGO DEL TALLER (1 AL 12) [7 - 18] ---
		{
			"number": 1,
			"is_level": true,
			"level_number": 1,
			"title": "NIVEL 1 · MONTAJE FAN COOLER",
			"stage": "ETAPA I: TALLER BÁSICO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(1.0, 0.15, 0.35),
			"description": "3 computadoras contra reloj con sobrecalentamiento térmico severo.\nIdentifica el conector PWM de 4 pines y desacopla la tornillería Cruz (+) o Pala (-).\nEl procesador no debe sobrepasar los 95°C durante la prueba.",
			"requirements": "HERRAMIENTAS: Destornillador Cruz [1] / Pala [2] · LÍMITE: 120s · RECOMPENSA: 100 PTS",
			"can_play": false
		},
		{
			"number": 2,
			"is_level": true,
			"level_number": 2,
			"title": "NIVEL 2 · DIAGNÓSTICO BANCO RAM",
			"stage": "ETAPA I: TALLER BÁSICO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(1.0, 0.2, 0.45),
			"description": "Equipos con pitidos continuos de BIOS y pantallas azules (BSOD).\nRevisa las trabas de seguridad, extrae módulos sulfatados e instala DDR5 de repuesto con muesca alineada.",
			"requirements": "HERRAMIENTAS: Pinzas antiestáticas · LÍMITE: 110s · RECOMPENSA: 120 PTS",
			"can_play": false
		},
		{
			"number": 3,
			"is_level": true,
			"level_number": 3,
			"title": "NIVEL 3 · UNIDAD SATA Y TORNILLOS (HDD / SSD)",
			"stage": "ETAPA I: TALLER BÁSICO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(1.0, 0.2, 0.45),
			"description": "Equipos que no detectan disco duro en bahías frontales.\nRetira los 4 tornillos de retención, desconecta el cable SATA e instala un nuevo disco HDD o SSD.",
			"requirements": "HERRAMIENTAS: Destornilladores y repuestos · LÍMITE: 100s · RECOMPENSA: 150 PTS",
			"can_play": false
		},
		{
			"number": 4,
			"is_level": true,
			"level_number": 4,
			"title": "NIVEL 4 · PASTA TÉRMICA Y CONTACTO",
			"stage": "ETAPA I: TALLER BÁSICO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(1.0, 0.25, 0.5),
			"description": "Limpieza de compuesto térmico solidificado en die de CPU.\nAplica compuesto de plata con espátula y equilibra la presión de los 4 anclajes.",
			"requirements": "HERRAMIENTAS: Alcohol isopropílico · LÍMITE: 95s · RECOMPENSA: 180 PTS",
			"can_play": false
		},
		{
			"number": 5,
			"is_level": true,
			"level_number": 5,
			"title": "NIVEL 5 · TARJETA GRÁFICA PCIE",
			"stage": "ETAPA II: HARDWARE AVANZADO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.9, 0.1, 0.7),
			"description": "Artefactos visuales y pérdida de señal HDMI/DP bajo carga 3D.\nDesconecta alimentación PCIe para frenar ventiladores, retira tornillos HDMI y sustituye por GPU operativa.",
			"requirements": "HERRAMIENTAS: Destornilladores y extractor PCIe · LÍMITE: 90s · RECOMPENSA: 220 PTS",
			"can_play": false
		},
		{
			"number": 6,
			"is_level": true,
			"level_number": 6,
			"title": "NIVEL 6 · FUENTE DE PODER ATX",
			"stage": "ETAPA II: HARDWARE AVANZADO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.9, 0.1, 0.7),
			"description": "Cortocircuito en rieles de 12V. La máquina se apaga a los 2 segundos.\nDesconecta conector ATX 24 pines y CPU auxiliar, sustituyendo por fuente 80 Plus.",
			"requirements": "HERRAMIENTAS: Multímetro digital y destornillador · LÍMITE: 85s · RECOMPENSA: 250 PTS",
			"can_play": false
		},
		{
			"number": 7,
			"is_level": true,
			"level_number": 7,
			"title": "NIVEL 7 · ZÓCALO DE PROCESADOR (CPU)",
			"stage": "ETAPA II: HARDWARE AVANZADO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.85, 0.05, 0.85),
			"description": "Zócalo LGA con palanca de retención metálica. Desbloquea la compuerta de carga y monta el procesador con muescas alineadas sin doblar pines.",
			"requirements": "HERRAMIENTAS: Acceso Total · LÍMITE: 80s · RECOMPENSA: 300 PTS",
			"can_play": false
		},
		{
			"number": 8,
			"is_level": true,
			"level_number": 8,
			"title": "NIVEL 8 · ARQUITECTURA TÉRMICA COMPLETA",
			"stage": "ETAPA II: HARDWARE AVANZADO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.8, 0.05, 0.85),
			"description": "Optimización del flujo de aire positivo en chasis gaming.\nConfigura curvas de ventiladores y sustituye pads térmicos degradados en VRMs.",
			"requirements": "HERRAMIENTAS: Sonda térmica · LÍMITE: 75s · RECOMPENSA: 350 PTS",
			"can_play": false
		},
		{
			"number": 9,
			"is_level": true,
			"level_number": 9,
			"title": "NIVEL 9 · DIAGNÓSTICO INTEGRADO",
			"stage": "ETAPA III: LABORATORIO FORENSE",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.75, 0.05, 0.85),
			"description": "Fallas intermitentes y reinicios espontáneos.\nAísla componentes defectuosos en banco de pruebas utilizando tarjeta POST con display de códigos hexadecimales.",
			"requirements": "HERRAMIENTAS: Tarjeta POST PCI-e · LÍMITE: 70s · RECOMPENSA: 400 PTS",
			"can_play": false
		},
		{
			"number": 10,
			"is_level": true,
			"level_number": 10,
			"title": "NIVEL 10 · WORKSTATION GAMING & RENDER",
			"stage": "ETAPA III: LABORATORIO FORENSE",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.7, 0.05, 0.9),
			"description": "Ensamble y validación de plataforma multi-GPU y almacenamiento NVMe RAID 0.\nComprueba estabilidad térmica bajo estrés sostenido.",
			"requirements": "HERRAMIENTAS: Medidor de consumo y banco de carga · LÍMITE: 65s · RECOMPENSA: 450 PTS",
			"can_play": false
		},
		{
			"number": 11,
			"is_level": true,
			"level_number": 11,
			"title": "NIVEL 11 · OVERCLOCKING & CALIBRACIÓN",
			"stage": "ETAPA III: LABORATORIO FORENSE",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.65, 0.05, 0.95),
			"description": "Ajuste fino de voltajes LLC y frecuencias de bus sin inducir inestabilidad en silicio.\nMonitorea temperaturas de die en tiempo real.",
			"requirements": "HERRAMIENTAS: Osciloscopio y multímetro true-RMS · LÍMITE: 60s · RECOMPENSA: 500 PTS",
			"can_play": false
		},
		{
			"number": 12,
			"is_level": true,
			"level_number": 12,
			"title": "NIVEL 12 · CERTIFICACIÓN TÉCNICA MAESTRA",
			"stage": "ETAPA III: LABORATORIO FORENSE",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.6, 0.05, 1.0),
			"description": "Prueba final de maestría de hardware integral.\nDiagnostica, desensambla, repara y calibra 5 equipos de alta gama en una sola sesión contra el cronómetro.",
			"requirements": "HERRAMIENTAS: Acceso Total y banco de estrés · LÍMITE: 180s · RECOMPENSA: 1000 PTS",
			"can_play": false
		},

		# --- RETOS DE PRÁCTICA CRONOMETRADOS (3 MESAS CON FALLAS DISTINTAS / 8 MINUTOS) [19 - 25] ---
		{
			"number": 19,
			"is_practice": true,
			"practice_id": "cooler",
			"title": "RETO DE PRÁCTICA // FAN COOLER & REFRIGERACIÓN",
			"stage": "ZONA DE PRÁCTICA // RETO CRONOMETRADO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(1.0, 0.55, 0.05),
			"description": "3 estaciones de trabajo simultáneas con problemas térmicos y de hardware.\nRepara los 3 equipos en las mesas antes de los 8 minutos.",
			"requirements": "HERRAMIENTAS: Acceso Total · 3 COMPUTADORAS · LÍMITE: 8 MINUTOS",
			"can_play": false
		},
		{
			"number": 20,
			"is_practice": true,
			"practice_id": "ram",
			"title": "RETO DE PRÁCTICA // BANCO DE MEMORIAS RAM",
			"stage": "ZONA DE PRÁCTICA // RETO CRONOMETRADO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(1.0, 0.55, 0.05),
			"description": "3 estaciones con pitidos de BIOS y pantallas azules de memoria.\nSustituye los módulos defectuosos antes de agotar los 8 minutos.",
			"requirements": "HERRAMIENTAS: Acceso Total · 3 COMPUTADORAS · LÍMITE: 8 MINUTOS",
			"can_play": false
		},
		{
			"number": 21,
			"is_practice": true,
			"practice_id": "hdd",
			"title": "RETO DE PRÁCTICA // ALMACENAMIENTO HDD & SSD",
			"stage": "ZONA DE PRÁCTICA // RETO CRONOMETRADO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(1.0, 0.55, 0.05),
			"description": "3 estaciones con discos mecánicos dañados y SSDs corruptos.\nInstala las unidades de reemplazo y fija tornillos en 8 minutos.",
			"requirements": "HERRAMIENTAS: Acceso Total · 3 COMPUTADORAS · LÍMITE: 8 MINUTOS",
			"can_play": false
		},
		{
			"number": 22,
			"is_practice": true,
			"practice_id": "gpu",
			"title": "RETO DE PRÁCTICA // TARJETAS GRÁFICAS GPU",
			"stage": "ZONA DE PRÁCTICA // RETO CRONOMETRADO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(1.0, 0.55, 0.05),
			"description": "3 estaciones con fallas de video, artefactos y controladores PCIe.\nDiagnostica y soluciona las 3 mesas en menos de 8 minutos.",
			"requirements": "HERRAMIENTAS: Acceso Total · 3 COMPUTADORAS · LÍMITE: 8 MINUTOS",
			"can_play": false
		},
		{
			"number": 23,
			"is_practice": true,
			"practice_id": "psu",
			"title": "RETO DE PRÁCTICA // FUENTES DE PODER ATX",
			"stage": "ZONA DE PRÁCTICA // RETO CRONOMETRADO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(1.0, 0.55, 0.05),
			"description": "3 estaciones con caídas de tensión y fuentes sin encendido.\nReemplaza arneses y fuentes de poder antes de que acaben los 8 minutos.",
			"requirements": "HERRAMIENTAS: Acceso Total · 3 COMPUTADORAS · LÍMITE: 8 MINUTOS",
			"can_play": false
		},
		{
			"number": 24,
			"is_practice": true,
			"practice_id": "cpu",
			"title": "RETO DE PRÁCTICA // PROCESADORES & SOCKET",
			"stage": "ZONA DE PRÁCTICA // RETO CRONOMETRADO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(1.0, 0.55, 0.05),
			"description": "3 estaciones con fallas críticas de socket LGA y sobrecalentamiento.\nSustituye CPUs y alinea pines dentro del límite de 8 minutos.",
			"requirements": "HERRAMIENTAS: Acceso Total · 3 COMPUTADORAS · LÍMITE: 8 MINUTOS",
			"can_play": false
		},
		{
			"number": 25,
			"is_practice": true,
			"practice_id": "maestra",
			"title": "RETO CRONOMETRADO // SALA DE PRÁCTICA INICIAL (3 MESAS)",
			"stage": "LABORATORIO PRÁCTICO // RETO CRONOMETRADO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(1.0, 0.55, 0.05),
			"description": "Primer reto cronometrado de hardware.\n3 computadoras con 3 fallas diferentes (RAM, GPU, HDD).\nRepara los 3 equipos en las mesas antes de los 8 minutos.",
			"requirements": "HERRAMIENTAS: Acceso Total · 3 COMPUTADORAS · LÍMITE: 8 MINUTOS",
			"can_play": false
		},

		# --- MICRO-TALLERES MORADOS DE INSPECCIÓN Y LUPA [26 - 29] ---
		{
			"number": 26,
			"is_inspection": true,
			"is_purple": true,
			"inspection_id": "dust_ram",
			"target_scene": "res://scenes/minigames/DustCleanerMinigame.tscn",
			"title": "TALLER LUPA · LIMPIEZA DE POLVO EN RAM",
			"stage": "ZONA DE INSPECCIÓN // LUPA TÉCNICA",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.85, 0.25, 1.0),
			"description": "Micro-taller de precisión con lupa técnica.\nUsa el soplador y cepillo para remover el polvo acumulado y residuos en los contactos dorados de la memoria RAM.",
			"requirements": "HERRAMIENTAS: Lupa técnica y soplador · OBJETIVO: 100% LIMPIEZA",
			"joa_speech": "¡Atento aquí! Los contactos dorados y ranuras de la memoria RAM suelen acumular polvo y pelusa que impiden el arranque del sistema. Usa la lupa técnica para ubicar los cúmulos de suciedad y límpialos hasta dejar los pines impecables.",
			"can_play": false
		},
		{
			"number": 27,
			"is_inspection": true,
			"is_purple": true,
			"inspection_id": "ram_static",
			"target_scene": "res://scenes/minigames/RAMStaticMinigame.tscn",
			"title": "TALLER LUPA · DESCARGA ELECTROSTÁTICA RAM",
			"stage": "ZONA DE INSPECCIÓN // LUPA TÉCNICA",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.85, 0.25, 1.0),
			"description": "Micro-taller de precisión con lupa técnica.\nFrota la memoria RAM contra el destornillador metálico aterrizado a tierra (GND) para drenar la carga estática acumulada antes de manipularla.",
			"requirements": "HERRAMIENTAS: Destornillador a tierra · OBJETIVO: ESTÁTICA A CERO",
			"joa_speech": "¡Cuidado con la estática! Una descarga electrostática imperceptible puede freír un chip de memoria. Frota la RAM con firmeza contra el destornillador metálico aterrizado a tierra hasta que la barra de estática llegue a cero.",
			"can_play": false
		},
		{
			"number": 28,
			"is_inspection": true,
			"is_purple": true,
			"inspection_id": "paste_cpu",
			"target_scene": "res://scenes/minigames/CPUPasteMinigame.tscn",
			"title": "TALLER LUPA · RENOVACIÓN PASTA TÉRMICA CPU",
			"stage": "ZONA DE INSPECCIÓN // LUPA TÉCNICA",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.85, 0.25, 1.0),
			"description": "Micro-taller de precisión con lupa técnica.\nRemueve el compuesto térmico solidificado con el pañuelo y aplica una nueva gota uniforme sobre el procesador.",
			"requirements": "HERRAMIENTAS: Pañuelo y jeringa térmica · OBJETIVO: 100% COBERTURA",
			"joa_speech": "El compuesto térmico degradado se seca y pierde conductividad, disparando la temperatura del procesador. Usa el pañuelo para limpiar la pasta vieja y luego aplica la nueva dosis con la jeringa con máxima precisión.",
			"can_play": false
		},
		{
			"number": 29,
			"is_inspection": true,
			"is_purple": true,
			"inspection_id": "pins_cpu",
			"target_scene": "res://scenes/minigames/CPUPinsMinigame.tscn",
			"title": "TALLER LUPA · ALINEACIÓN DE PINES CPU",
			"stage": "ZONA DE INSPECCIÓN // LUPA TÉCNICA",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.85, 0.25, 1.0),
			"description": "Micro-taller de precisión con microscopio 100x.\nInspecciona la matriz de pines del socket o procesador y endereza cada pin doblado a 90° con la pinza.",
			"requirements": "HERRAMIENTAS: Microscopio 100x y pinza de precisión · ALINEACIÓN TOTAL",
			"joa_speech": "¡Máxima concentración técnica! Un pin torcido o desalineado provocará un cortocircuito o impedirá que el equipo inicie. Ajusta el enfoque del microscopio y endereza cada pin con mucho cuidado.",
			"can_play": false
		},
		{
			"number": 30,
			"is_inspection": true,
			"is_purple": true,
			"inspection_id": "voltimeter",
			"target_scene": "res://scenes/minigames/VoltimeterMinigame.tscn",
			"title": "TALLER LUPA · MEDICIÓN DE VOLTAJE Y MULTÍMETRO",
			"stage": "ZONA DE INSPECCIÓN // MULTÍMETRO DIGITAL",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.85, 0.25, 1.0),
			"description": "Diagnóstico de rieles de potencia y detección de cortocircuitos con multímetro digital.\nMide líneas DC (12V, 5VSB, 3.3V), filtra ruido AC y localiza componentes quemados en modo Ohmios (Ω).",
			"requirements": "HERRAMIENTAS: Multímetro digital y dial analógico · CALIBRACIÓN COMPLETA",
			"joa_speech": "¡Hora de medir voltajes! Un riel caído o un cortocircuito a tierra impedirá que la computadora encienda. Usa el multímetro para verificar los voltajes nominales y calibra la aguja en el dial cuando coincida con el objetivo.",
			"can_play": false
		},
		{
			"number": 31,
			"is_inspection": true,
			"is_purple": true,
			"inspection_id": "dust_psu",
			"target_scene": "res://scenes/minigames/DustCleanerMinigame.tscn",
			"target_component": "PSU",
			"title": "TALLER LUPA · LIMPIEZA INTERNA FUENTE DE PODER",
			"stage": "ZONA DE INSPECCIÓN // LUPA TÉCNICA",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.85, 0.25, 1.0),
			"description": "Limpieza profunda de componentes internos de la fuente ATX.\nDesliza la tapa metálica superior de la fuente de poder y remueve toda la pelusa acumulada en bobinas y disipadores.",
			"requirements": "HERRAMIENTAS: Lupa técnica y brocha antiestática · LIMPIEZA AL 100%",
			"joa_speech": "¡Cuidado al abrir la fuente de poder! Desliza la cubierta metálica hacia la derecha para acceder al interior. La acumulación de pelusa y polvo en los disipadores de los transistores de potencia puede provocar un sobrecalentamiento crítico.",
			"can_play": false
		}
	],
	"sistema": [
		# --- NÚCLEO TUTORIAL CENTRAL [0] ---
		{
			"number": 0,
			"is_tutorial": true,
			"tutorial_component": "general",
			"title": "NÚCLEO TUTORIAL · PROTOCOLO DE BOOT & BIOS // ANDROMEDA OS",
			"stage": "CENTRO NEURONAL // TUTORIAL CON JEREMÍAS",
			"mode_name": "SISTEMA",
			"color_accent": Color(0.0, 0.88, 1.0),
			"description": "Inducción completa al diagnóstico y rescate de sistemas con Jeremías.\nAprende a particionar en GPT, desplegar Andromeda OS, purgar malware con ClamAV y actualizar módulos de controladores WHQL.",
			"requirements": "HERRAMIENTAS: Teclado y Mouse · MODO GUIADO CON JEREMÍAS · ACCESO LIBRE",
			"can_play": true
		},

		# --- TUTORIALES ESPECÍFICOS DE SISTEMAS [1 - 6] ---
		{
			"number": 1,
			"is_tutorial": true,
			"tutorial_component": "os_install",
			"handler": "launch_os_install",
			"title": "TUTORIAL // INSTALACIÓN DE SISTEMA OPERATIVO & GPT",
			"stage": "TUTORIAL DE SOFTWARE // GUIADO POR JEREMÍAS",
			"mode_name": "SISTEMA",
			"color_accent": Color(0.0, 0.88, 1.0),
			"description": "Taller guiado paso a paso con Jeremías.\nPrepara la tabla de particiones GPT, asigna partición EFI FAT32, volumen raíz ext4 y swap antes de instalar el gestor de arranque.",
			"requirements": "CONSOLA DE PARTICIONADO · MODO GUIADO",
			"can_play": false
		},
		{
			"number": 2,
			"is_tutorial": true,
			"tutorial_component": "malware_scan",
			"handler": "launch_malware_scan",
			"title": "TUTORIAL // CIBERDEFENSA & ESCANEO DE MALWARE",
			"stage": "TUTORIAL DE SOFTWARE // GUIADO POR JEREMÍAS",
			"mode_name": "SISTEMA",
			"color_accent": Color(0.0, 0.88, 1.0),
			"description": "Taller guiado paso a paso con Jeremías.\nInspecciona procesos en tiempo real, verifica firmas SHA-256 de archivos sospechosos, aísla en Sandbox y purga troyanos activos.",
			"requirements": "CLAMAV & SANDBOX LIVE · MODO GUIADO",
			"can_play": false
		},
		{
			"number": 3,
			"is_tutorial": true,
			"tutorial_component": "driver_install",
			"handler": "launch_driver_install",
			"title": "TUTORIAL // CONTROLADORES WHQL & MÓDULOS DE KERNEL",
			"stage": "TUTORIAL DE SOFTWARE // GUIADO POR JEREMÍAS",
			"mode_name": "SISTEMA",
			"color_accent": Color(0.0, 0.88, 1.0),
			"description": "Taller guiado paso a paso con Jeremías.\nDetecta dispositivos con conflicto o sin firmar, descarga paquetes oficiales WHQL y compila módulos de kernel sin pantallas azules.",
			"requirements": "GESTOR DE PAQUETES DE CONTROLADORES · MODO GUIADO",
			"can_play": false
		},
		{
			"number": 4,
			"is_tutorial": true,
			"tutorial_component": "adware_cleaner",
			"handler": "launch_adware_cleaner",
			"title": "TUTORIAL // DESINFECCIÓN DE ADWARE & POP-UPS",
			"stage": "TUTORIAL DE SOFTWARE // GUIADO POR JEREMÍAS",
			"mode_name": "SISTEMA",
			"color_accent": Color(0.0, 0.88, 1.0),
			"description": "Taller guiado paso a paso con Jeremías.\nIdentifica falsas alertas de virus en el navegador, cierra pop-ups engañosos y activa el pulso electromagnético del Ad-Blocker.",
			"requirements": "ESCUDO DEFENSIVO AD-BLOCKER · MODO GUIADO",
			"can_play": false
		},
		{
			"number": 5,
			"is_tutorial": true,
			"tutorial_component": "code_debugger",
			"handler": "launch_code_debugger",
			"title": "TUTORIAL // PROGRAMACIÓN & DEPURADOR DE CÓDIGO",
			"stage": "TUTORIAL DE SOFTWARE // GUIADO POR JEREMÍAS",
			"mode_name": "SISTEMA",
			"color_accent": Color(0.0, 0.88, 1.0),
			"description": "Taller guiado paso a paso con Jeremías.\nExamina scripts rotos de inicio de sistema, diagnostica errores de sintaxis y aplica parches en tiempo real validando suites de pruebas.",
			"requirements": "IDE DE DEPURACIÓN EN TERMINAL · MODO GUIADO",
			"can_play": false
		},
		{
			"number": 6,
			"is_tutorial": true,
			"tutorial_component": "usb_backup",
			"handler": "launch_usb_backup",
			"title": "TUTORIAL // UNIDADES BOOTEABLES USB & RESPALDO",
			"stage": "TUTORIAL DE SOFTWARE // GUIADO POR JEREMÍAS",
			"mode_name": "SISTEMA",
			"color_accent": Color(0.0, 0.88, 1.0),
			"description": "Taller guiado paso a paso con Jeremías.\nPrepara pendrives de rescate booteables con dd/Ventoy, respalda configuraciones críticas del sistema y restaura imágenes ISO.",
			"requirements": "PENDRIVE DE SERVICIO LIVE · MODO GUIADO",
			"can_play": false
		},

		# --- NIVELES DE JUEGO DE CAMPAÑA (1 AL 12) [7 - 18] ---
		{
			"number": 1,
			"is_level": true,
			"level_number": 1,
			"title": "NIVEL 1 · TERMINAL DE SISTEMAS Y SOFTWARE",
			"stage": "ETAPA I: SISTEMAS & CIBERSEGURIDAD",
			"mode_name": "SISTEMA",
			"color_accent": Color(0.0, 0.95, 1.0),
			"description": "Estación de trabajo con fallas críticas de software.\nAccede a la PC y restaura los 7 módulos (Instalación de SO, Drivers, Malware, Adware, Debugger, USB Booteable y Ciberdefensa Arcade).",
			"requirements": "CONSOLA DE SISTEMAS · LÍMITE: 900s · RECOMPENSA: 100 PTS",
			"can_play": false
		},
		{
			"number": 2,
			"is_level": true,
			"level_number": 2,
			"title": "NIVEL 2 · FLASH DE FIRMWARE BIOS",
			"stage": "ETAPA I: BIOS & BOOT",
			"mode_name": "SISTEMA",
			"color_accent": Color(1.0, 0.2, 0.5),
			"description": "Incompatibilidad de microcódigo con CPU de última generación.\nActualiza el chip SPI Flash mediante puerto USB Flashback sin apagar el suministro.",
			"requirements": "PENDRIVE FAT32 DE SERVICIO · LÍMITE: 110s · RECOMPENSA: 120 PTS",
			"can_play": false
		},
		{
			"number": 3,
			"is_level": true,
			"level_number": 3,
			"title": "NIVEL 3 · SECTORES MBR & GPT CORRUPTOS",
			"stage": "ETAPA I: BIOS & BOOT",
			"mode_name": "SISTEMA",
			"color_accent": Color(1.0, 0.2, 0.5),
			"description": "Tabla de particiones destruida por apagado intempestivo.\nReconstruye el BCD y los punteros EFI desde consola de rescate.",
			"requirements": "CONSOLA DE RECUPERACIÓN · LÍMITE: 100s · RECOMPENSA: 150 PTS",
			"can_play": false
		},
		{
			"number": 4,
			"is_level": true,
			"level_number": 4,
			"title": "NIVEL 4 · CONFIGURACIÓN RESIZABLE-BAR",
			"stage": "ETAPA I: BIOS & BOOT",
			"mode_name": "SISTEMA",
			"color_accent": Color(0.95, 0.15, 0.6),
			"description": "Habilita direccionamiento de memoria de video de 64 bits en BIOS para desbloquear el rendimiento gráfico completo.",
			"requirements": "UEFI SETUP · LÍMITE: 95s · RECOMPENSA: 180 PTS",
			"can_play": false
		},
		{
			"number": 5,
			"is_level": true,
			"level_number": 5,
			"title": "NIVEL 5 · DESINFECCIÓN DE ROOTKIT",
			"stage": "ETAPA II: KERNEL & DRIVERS",
			"mode_name": "SISTEMA",
			"color_accent": Color(0.85, 0.1, 0.8),
			"description": "Código malicioso con privilegios Ring 0 ocultando procesos.\nInicia entorno Live PE e inmuniza las librerías del kernel.",
			"requirements": "ANTIVIRUS HEURÍSTICO LIVE · LÍMITE: 90s · RECOMPENSA: 220 PTS",
			"can_play": false
		},
		{
			"number": 6,
			"is_level": true,
			"level_number": 6,
			"title": "NIVEL 6 · CONFLICTO DE CONTROLADORES IRQ",
			"stage": "ETAPA II: KERNEL & DRIVERS",
			"mode_name": "SISTEMA",
			"color_accent": Color(0.85, 0.1, 0.8),
			"description": "Conflicto entre controlador de audio ASIO y tarjeta de captura.\nReasigna canales DMA en el administrador de dispositivos.",
			"requirements": "DEPURADOR DE DISPOSITIVOS · LÍMITE: 85s · RECOMPENSA: 250 PTS",
			"can_play": false
		},
		{
			"number": 7,
			"is_level": true,
			"level_number": 7,
			"title": "NIVEL 7 · PURGA DE REGISTRO DAÑADO",
			"stage": "ETAPA II: KERNEL & DRIVERS",
			"mode_name": "SISTEMA",
			"color_accent": Color(0.8, 0.05, 0.9),
			"description": "Colmenas SYSTEM y SOFTWARE con sumas de verificación erróneas impidiendo el inicio de sesión del usuario.",
			"requirements": "EDITOR DE REGISTRO OFF-LINE · LÍMITE: 80s · RECOMPENSA: 300 PTS",
			"can_play": false
		},
		{
			"number": 8,
			"is_level": true,
			"level_number": 8,
			"title": "NIVEL 8 · RECUPERACIÓN VOLUMEN BITLOCKER",
			"stage": "ETAPA II: KERNEL & DRIVERS",
			"mode_name": "SISTEMA",
			"color_accent": Color(0.8, 0.05, 0.9),
			"description": "Cambio de placa disparó el bloqueo TPM 2.0.\nValida llave de 48 dígitos y restaura el sellado criptográfico.",
			"requirements": "CLAVE FORENSE DE AUDITORÍA · LÍMITE: 75s · RECOMPENSA: 350 PTS",
			"can_play": false
		},
		{
			"number": 9,
			"is_level": true,
			"level_number": 9,
			"title": "NIVEL 9 · CLONACIÓN FORENSE SECTOR A SECTOR",
			"stage": "ETAPA III: CIBERSEGURIDAD & RESCATE",
			"mode_name": "SISTEMA",
			"color_accent": Color(0.7, 0.05, 0.95),
			"description": "Unidad con degradación magnética rápida.\nCopia sectores críticos saltando bloques dañados antes del fallo definitivo.",
			"requirements": "CLONADORA POR HARDWARE · LÍMITE: 70s · RECOMPENSA: 400 PTS",
			"can_play": false
		},
		{
			"number": 10,
			"is_level": true,
			"level_number": 10,
			"title": "NIVEL 10 · ANÁLISIS DE VOLCADO MEMORY.DMP",
			"stage": "ETAPA III: CIBERSEGURIDAD & RESCATE",
			"mode_name": "SISTEMA",
			"color_accent": Color(0.7, 0.05, 0.95),
			"description": "Pantallas azules de código KERNEL_SECURITY_CHECK_FAILURE.\nAbre WinDbg y rastrea el puntero de instrucción exacto.",
			"requirements": "WINDBG KERNEL SUITE · LÍMITE: 65s · RECOMPENSA: 450 PTS",
			"can_play": false
		},
		{
			"number": 11,
			"is_level": true,
			"level_number": 11,
			"title": "NIVEL 11 · AISLAMIENTO DE RANSOMWARE",
			"stage": "ETAPA III: CIBERSEGURIDAD & RESCATE",
			"mode_name": "SISTEMA",
			"color_accent": Color(0.65, 0.05, 1.0),
			"description": "Ataque activo cifrando archivos.\nCorta interfaces de red, extrae llave de memoria y frena hilos maliciosos.",
			"requirements": "SANDBOX Y DUMP DE PROCESOS · LÍMITE: 60s · RECOMPENSA: 500 PTS",
			"can_play": false
		},
		{
			"number": 12,
			"is_level": true,
			"level_number": 12,
			"title": "NIVEL 12 · ARQUITECTO SUPREMO DE SO",
			"stage": "ETAPA III: CIBERSEGURIDAD & RESCATE",
			"mode_name": "SISTEMA",
			"color_accent": Color(1.0, 0.15, 0.4),
			"description": "Despliegue automatizado de imagen corporativa con endurecimiento de seguridad, directivas de grupo y parches de kernel.",
			"requirements": "MASTER SYSTEM ADMINISTRATOR · LÍMITE: 150s · RECOMPENSA: 1000 PTS ★",
			"can_play": false
		},

		# --- RETOS DE PRÁCTICA CRONOMETRADOS (3 TERMINALES CON FALLAS / 8 MINUTOS) [19 - 25] ---
		{
			"number": 19,
			"is_practice": true,
			"practice_id": "os_install",
			"title": "RETO DE PRÁCTICA // DESPLIEGUE MASIVO DE SO & GPT",
			"stage": "ZONA DE PRÁCTICA // RETO CRONOMETRADO",
			"mode_name": "SISTEMA",
			"color_accent": Color(1.0, 0.55, 0.05),
			"description": "3 terminales con particiones dañadas y arranques destruidos.\nParticiona e instala el sistema en las 3 estaciones antes de los 8 minutos.",
			"requirements": "CONSOLA DE SISTEMAS · 3 TERMINALES · LÍMITE: 8 MINUTOS",
			"can_play": false
		},
		{
			"number": 20,
			"is_practice": true,
			"practice_id": "malware_scan",
			"title": "RETO DE PRÁCTICA // PURGA HEURÍSTICA DE MALWARE",
			"stage": "ZONA DE PRÁCTICA // RETO CRONOMETRADO",
			"mode_name": "SISTEMA",
			"color_accent": Color(1.0, 0.55, 0.05),
			"description": "3 terminales bajo infección masiva de troyanos y spyware.\nAísla y purga los procesos infecciosos en las 3 estaciones en 8 minutos.",
			"requirements": "CLAMAV LIVE · 3 TERMINALES · LÍMITE: 8 MINUTOS",
			"can_play": false
		},
		{
			"number": 21,
			"is_practice": true,
			"practice_id": "driver_install",
			"title": "RETO DE PRÁCTICA // CONTROLADORES WHQL & DRIVERS",
			"stage": "ZONA DE PRÁCTICA // RETO CRONOMETRADO",
			"mode_name": "SISTEMA",
			"color_accent": Color(1.0, 0.55, 0.05),
			"description": "3 terminales con pantallas azules por fallas de controladores gráficos y de red.\nActualiza a controladores WHQL en las 3 mesas antes de 8 minutos.",
			"requirements": "CONTROLADORES WHQL · 3 TERMINALES · LÍMITE: 8 MINUTOS",
			"can_play": false
		},
		{
			"number": 22,
			"is_practice": true,
			"practice_id": "adware_cleaner",
			"title": "RETO DE PRÁCTICA // FILTRADO DEFENSIVO DE ADWARE",
			"stage": "ZONA DE PRÁCTICA // RETO CRONOMETRADO",
			"mode_name": "SISTEMA",
			"color_accent": Color(1.0, 0.55, 0.05),
			"description": "3 terminales saturadas de pop-ups engañosos y mineros web.\nDesactiva trampas y activa el escudo Ad-Blocker en menos de 8 minutos.",
			"requirements": "ESCUDO AD-BLOCKER · 3 TERMINALES · LÍMITE: 8 MINUTOS",
			"can_play": false
		},
		{
			"number": 23,
			"is_practice": true,
			"practice_id": "code_debugger",
			"title": "RETO DE PRÁCTICA // PARCHEO DE KERNEL & DEBUGGING",
			"stage": "ZONA DE PRÁCTICA // RETO CRONOMETRADO",
			"mode_name": "SISTEMA",
			"color_accent": Color(1.0, 0.55, 0.05),
			"description": "3 terminales con scripts de seguridad rotos y bucles infinitos.\nCorrige la sintaxis y valida los tests unitarios dentro del límite de 8 minutos.",
			"requirements": "DEBUGGER IDE · 3 TERMINALES · LÍMITE: 8 MINUTOS",
			"can_play": false
		},
		{
			"number": 24,
			"is_practice": true,
			"practice_id": "usb_backup",
			"title": "RETO DE PRÁCTICA // CLONACIÓN Y PENDRIVES BOOTEABLES",
			"stage": "ZONA DE PRÁCTICA // RETO CRONOMETRADO",
			"mode_name": "SISTEMA",
			"color_accent": Color(1.0, 0.55, 0.05),
			"description": "3 terminales que requieren flasheo urgente de medios booteables y copia de seguridad.\nCompleta las 3 unidades USB en menos de 8 minutos.",
			"requirements": "HERRAMIENTA USB · 3 TERMINALES · LÍMITE: 8 MINUTOS",
			"can_play": false
		},
		{
			"number": 25,
			"is_practice": true,
			"practice_id": "systems_intro",
			"title": "RETO CRONOMETRADO // SALA DE PRÁCTICA DE SISTEMAS (3 TERMINALES)",
			"stage": "LABORATORIO PRÁCTICO // RETO CRONOMETRADO CON JEREMÍAS",
			"mode_name": "SISTEMA",
			"color_accent": Color(1.0, 0.55, 0.05),
			"description": "Primer reto cronometrado de software y ciberseguridad.\n3 terminales con fallas simultáneas de partición GPT, malware y drivers.\nRepara las 3 estaciones de trabajo antes de que se agoten los 8 minutos.",
			"requirements": "CONSOLA DE SISTEMAS · 3 TERMINALES · LÍMITE: 8 MINUTOS",
			"can_play": false
		},

		# --- NIVELES AMARILLOS DE ANOMALÍAS GLITCH // HACKEO NIE-R AUTOMATA [26 - 31] ---
		{
			"number": 26,
			"is_inspection": true,
			"is_purple": true,
			"is_yellow": true,
			"stage_index": 0,
			"inspection_id": "glitch_vram",
			"target_scene": "res://scenes/minigames/CyberHackingMinigame.tscn",
			"title": "HACKEO // INDUCCIÓN & PROTOCOLO NIE-R",
			"stage": "ZONA DE ENTRENAMIENTO // INDUCCIÓN CON JEREMÍAS",
			"mode_name": "SISTEMA",
			"color_accent": Color(1.0, 0.88, 0.15),
			"description": "Nivel introductorio de hackeo ciberespacial guiado paso a paso por Jeremías.\nAprende los controles de la nave, destrucción de paquetes de datos, relays de seguridad y purga de núcleos anómalos.",
			"requirements": "INSTRUCTOR: Jeremías · NAVE: Ciberespacial · PROTOCOLO: Inducción",
			"jeremias_speech": "¡Atento, técnico! He configurado este sector de entrenamiento para enseñarte las bases del hackeo ciberespacial. Te explicaré los controles, cómo romper las defensas y cómo derribar el Núcleo Rojo.",
			"can_play": false
		},
		{
			"number": 27,
			"is_inspection": true,
			"is_purple": true,
			"is_yellow": true,
			"stage_index": 1,
			"inspection_id": "buffer_overflow",
			"target_scene": "res://scenes/minigames/CyberHackingMinigame.tscn",
			"title": "HACKEO // OVERFLOW & CADENA EXPLOSIVA",
			"stage": "ZONA DE ANOMALÍAS // KERNEL STACK",
			"mode_name": "SISTEMA",
			"color_accent": Color(1.0, 0.88, 0.15),
			"description": "Exploit en el Call Stack con drones patrulleros.\nDetona bloques volátiles en reacción en cadena para abrir paso al interruptor y purgar el Núcleo.",
			"requirements": "PROTOCOLO: Reacción en Cadena · TIEMPO: Libre",
			"jeremias_speech": "¡Alerta en la pila! Un proceso anómalo levantó drones patrulleros para blindar el Núcleo. Aprovecha los bloques explosivos para detonar las defensas en cadena y destruye las balas enemigas con tus disparos.",
			"can_play": false
		},
		{
			"number": 28,
			"is_inspection": true,
			"is_purple": true,
			"is_yellow": true,
			"stage_index": 2,
			"inspection_id": "adware_miner",
			"target_scene": "res://scenes/minigames/CyberHackingMinigame.tscn",
			"title": "HACKEO // CRIPTOMINERO RESIDUAL",
			"stage": "ZONA DE ANOMALÍAS // MINERO EN CUARENTENA",
			"mode_name": "SISTEMA",
			"color_accent": Color(1.0, 0.88, 0.15),
			"description": "Proceso oculto consumiendo recursos con doble cierre de seguridad.\nActiva los interruptores Alpha y Beta simultáneos para neutralizar la jaula de fuerza.",
			"requirements": "PROTOCOLO: Doble Interruptor Alpha/Beta",
			"jeremias_speech": "El script minero ha cerrado el Núcleo bajo una jaula electromagnética dual. Debes llegar a ambos interruptores en los flancos para bajar las barreras antes de atacar el núcleo.",
			"can_play": false
		},
		{
			"number": 29,
			"is_inspection": true,
			"is_purple": true,
			"is_yellow": true,
			"stage_index": 3,
			"inspection_id": "driver_corrupt",
			"target_scene": "res://scenes/minigames/CyberHackingMinigame.tscn",
			"title": "HACKEO // TRÍADA WHQL CORRUPTA",
			"stage": "ZONA DE ANOMALÍAS // CONTROLADOR GPU",
			"mode_name": "SISTEMA",
			"color_accent": Color(1.0, 0.88, 0.15),
			"description": "Firma digital rota protegida por 3 torretas de defensa.\nSobrecarga los 3 relays de seguridad para retirar las capas del escudo del Núcleo.",
			"requirements": "PROTOCOLO: Tríada de Seguridad WHQL",
			"jeremias_speech": "El controlador gráfico no pasa la comprobación criptográfica y sus subprocesos defienden el sector con fuego cruzado. Neutraliza los 3 nodos de la tríada para dejar al descubierto el núcleo dañado.",
			"can_play": false
		},
		{
			"number": 30,
			"is_inspection": true,
			"is_purple": true,
			"is_yellow": true,
			"stage_index": 4,
			"inspection_id": "gpt_salvage",
			"target_scene": "res://scenes/minigames/CyberHackingMinigame.tscn",
			"title": "HACKEO // LABERINTO GPT & RESCATE EFI",
			"stage": "ZONA DE ANOMALÍAS // GPT SALVAGE",
			"mode_name": "SISTEMA",
			"color_accent": Color(1.0, 0.88, 0.15),
			"description": "Sectores de arranque primarios infectados organizados en un laberinto fortificado.\nNavega entre torretas y compuertas secuenciales hasta la raíz.",
			"requirements": "PROTOCOLO: Infiltración de Laberinto EFI",
			"jeremias_speech": "La cabecera de partición GPT fue secuestrada dentro de un laberinto de cortafuegos. Ábrete paso disparando a través de las compuertas y purga el Núcleo corrupto para restaurar la tabla de arranque.",
			"can_play": false
		},
		{
			"number": 31,
			"is_inspection": true,
			"is_purple": true,
			"is_yellow": true,
			"stage_index": 5,
			"inspection_id": "alien_invasion",
			"target_scene": "res://scenes/minigames/CyberHackingMinigame.tscn",
			"title": "HACKEO // PURGA FINAL DEL NÚCLEO MAESTRO",
			"stage": "ZONA DE ANOMALÍAS // NÚCLEO JEFE RAÍZ",
			"mode_name": "SISTEMA",
			"color_accent": Color(1.0, 0.88, 0.15),
			"description": "Enjambre de malware militar protegiendo el Núcleo Anómalo Maestro.\nSatélites rotatorios blindados y torretas de asedio en patrón bullet-hell.",
			"requirements": "PROTOCOLO: Purga Total de Raíz ★★★",
			"jeremias_speech": "¡Infección crítica en el corazón del sistema! El Núcleo Maestro ha desplegado satélites giratorios impenetrables. Sobrecarga los interruptores maestros para desactivar temporalmente los satélites y concentra todo tu fuego en el Núcleo.",
			"can_play": false
		}
	],
	"servidor": [
		{
			"number": 0,
			"is_tutorial": true,
			"title": "NÚCLEO TUTORIAL · ARQUITECTURA DE RACK Y FIBRA",
			"stage": "CENTRO NEURONAL // TUTORIAL",
			"mode_name": "SERVIDOR",
			"color_accent": Color(0.0, 0.88, 1.0),
			"description": "Inducción a la infraestructura empresarial en Datacenter.\nAprende la instalación en bastidores 1U/2U, conmutación redundante de fuentes y cableado de alta velocidad para cabinas SAS.",
			"requirements": "HERRAMIENTAS: Tester / Crimpadora · MODO GUIADO · ACCESO LIBRE",
			"can_play": true
		},
		{
			"number": 1,
			"title": "NIVEL 1 · BASTIDORES & RIELES 2U",
			"stage": "ETAPA I: INFRAESTRUCTURA RACK",
			"mode_name": "SERVIDOR",
			"color_accent": Color(1.0, 0.1, 0.35),
			"description": "Torre de servidor 3D en el Datacenter con 9 subsistemas de montaje exclusivos (Bastidores 2U, Fuentes 1+1, 3 Discos SAS, Fan Wall, Loop Líquido, 3 Bancos RAM ECC, Dual CPU, SmartNIC y Scripting de red). Solo colocación de piezas.",
			"requirements": "CONSOLA DE TORRE RACK · LÍMITE: 900s · RECOMPENSA: 100 PTS",
			"can_play": true
		},
		{
			"number": 2,
			"title": "NIVEL 2 · FUENTES REDUNDANTES HOT-SWAP",
			"stage": "ETAPA I: INFRAESTRUCTURA RACK",
			"mode_name": "SERVIDOR",
			"color_accent": Color(1.0, 0.1, 0.35),
			"description": "Sustitución en caliente de módulo de potencia conmutado sin interrumpir la operación de los servicios en línea.",
			"requirements": "MÓDULOS DE PODER 1200W · LÍMITE: 110s · RECOMPENSA: 120 PTS",
			"can_play": false
		},
		{
			"number": 3,
			"title": "NIVEL 3 · CADDIES DE DISCO SAS",
			"stage": "ETAPA I: INFRAESTRUCTURA RACK",
			"mode_name": "SERVIDOR",
			"color_accent": Color(1.0, 0.1, 0.35),
			"description": "Montaje de discos SAS de 15.000 RPM en bandejas extraíbles de 3.5 pulgadas con bloqueo frontal.",
			"requirements": "BANDEJAS HOT-PLUG · LÍMITE: 100s · RECOMPENSA: 150 PTS",
			"can_play": false
		},
		{
			"number": 4,
			"title": "NIVEL 4 · CREACIÓN DE RAID 1 ESPEJO",
			"stage": "ETAPA I: INFRAESTRUCTURA RACK",
			"mode_name": "SERVIDOR",
			"color_accent": Color(0.95, 0.15, 0.5),
			"description": "Configuración de la controladora RAID para duplicación en espejo del volumen del hipervisor.",
			"requirements": "BIOS CONTROLADORA RAID · LÍMITE: 95s · RECOMPENSA: 180 PTS",
			"can_play": false
		},
		{
			"number": 5,
			"title": "NIVEL 5 · ARREGLO MASIVO RAID 5/10",
			"stage": "ETAPA II: ALMACENAMIENTO & REDES",
			"mode_name": "SERVIDOR",
			"color_accent": Color(0.85, 0.1, 0.8),
			"description": "Arreglo de 8 unidades con striping y bloques de paridad distribuida.\nAsigna un disco como reserva en caliente (Hot Spare).",
			"requirements": "STORAGE MANAGER ENTERPRISE · LÍMITE: 90s · RECOMPENSA: 220 PTS",
			"can_play": false
		},
		{
			"number": 6,
			"title": "NIVEL 6 · ENLACES DE FIBRA 10GBE",
			"stage": "ETAPA II: ALMACENAMIENTO & REDES",
			"mode_name": "SERVIDOR",
			"color_accent": Color(0.85, 0.1, 0.8),
			"description": "Inserción de transceptores ópticos SFP+ y cableado de fibra multimodo OM4 hacia el switch core.",
			"requirements": "KIT DE FIBRA ÓPTICA · LÍMITE: 85s · RECOMPENSA: 250 PTS",
			"can_play": false
		},
		{
			"number": 7,
			"title": "NIVEL 7 · CRIMPEO EN PATCH PANEL",
			"stage": "ETAPA II: ALMACENAMIENTO & REDES",
			"mode_name": "SERVIDOR",
			"color_accent": Color(0.8, 0.05, 0.9),
			"description": "Terminación de 24 enlaces de par trenzado Cat6A en panel de parcheo según norma T568B con herramienta de impacto.",
			"requirements": "HERRAMIENTA PUNCH-DOWN · LÍMITE: 80s · RECOMPENSA: 300 PTS",
			"can_play": false
		},
		{
			"number": 8,
			"title": "NIVEL 8 · CONFIGURACIÓN DE TRUNK VLAN",
			"stage": "ETAPA II: ALMACENAMIENTO & REDES",
			"mode_name": "SERVIDOR",
			"color_accent": Color(0.8, 0.05, 0.9),
			"description": "Segmentación del tráfico de servidores web, base de datos y red iSCSI mediante etiquetado 802.1Q en switches administrables.",
			"requirements": "CONSOLA SERIAL DE SWITCH · LÍMITE: 75s · RECOMPENSA: 350 PTS",
			"can_play": false
		},
		{
			"number": 9,
			"title": "NIVEL 9 · GESTIÓN TÉRMICA Y PASILLO FRÍO",
			"stage": "ETAPA III: DATACENTER & CLOUD",
			"mode_name": "SERVIDOR",
			"color_accent": Color(0.7, 0.05, 0.95),
			"description": "Sellado de pasillo con paneles de contención y equilibrio de presión estática para evitar puntos calientes.",
			"requirements": "ANEMÓMETRO Y TERMOGRAFÍA · LÍMITE: 70s · RECOMPENSA: 400 PTS",
			"can_play": false
		},
		{
			"number": 10,
			"title": "NIVEL 10 · MIGRACIÓN VIRTUAL EN VIVO",
			"stage": "ETAPA III: DATACENTER & CLOUD",
			"mode_name": "SERVIDOR",
			"color_accent": Color(0.7, 0.05, 0.95),
			"description": "Traspaso de 15 máquinas virtuales en ejecución hacia un nodo de reserva sin pérdida de paquetes ni latencia.",
			"requirements": "CLUSTER MANAGER · LÍMITE: 65s · RECOMPENSA: 450 PTS",
			"can_play": false
		},
		{
			"number": 11,
			"title": "NIVEL 11 · RECONSTRUCCIÓN RAID EN CALIENTE",
			"stage": "ETAPA III: DATACENTER & CLOUD",
			"mode_name": "SERVIDOR",
			"color_accent": Color(0.65, 0.05, 1.0),
			"description": "Falla de disco en producción.\nExtracción del disco defectuoso, inserción de repuesto y monitorización de la sincronización de paridad.",
			"requirements": "MONITOR DE RAID EN CALIENTE · LÍMITE: 60s · RECOMPENSA: 500 PTS",
			"can_play": false
		},
		{
			"number": 12,
			"title": "NIVEL 12 · ARQUITECTO DE DATACENTER",
			"stage": "ETAPA III: DATACENTER & CLOUD",
			"mode_name": "SERVIDOR",
			"color_accent": Color(1.0, 0.15, 0.4),
			"description": "Puesta en marcha completa de una fila de servidores rack con balanceo de carga, enlace troncal y energía redundante.",
			"requirements": "CERTIFICACIÓN SUPREMA DE SERVIDORES · LÍMITE: 150s · RECOMPENSA: 1000 PTS ★",
			"can_play": false
		},
		{
			"number": 13,
			"is_practice": true,
			"title": "SALA DE PRÁCTICA 3D",
			"stage": "LABORATORIO PRÁCTICO // ENTRENAMIENTO",
			"mode_name": "SERVIDOR",
			"color_accent": Color(1.0, 0.55, 0.05),
			"description": "Entorno libre de pruebas sin presión de tiempo.\nManipulación y montaje de componentes de servidor en bastidores a tu propio ritmo.",
			"requirements": "HERRAMIENTAS: Acceso Total · MODO PRÁCTICA LIBRE · SIN TIEMPO",
			"can_play": true
		}
	]
}

# =============================================================================
# BASE DE DATOS DE TARJETAS TÉCNICAS (PACK DE TUTORIALES)
# =============================================================================
var ALL_TUTORIAL_CARDS: Array[Dictionary] = []

const MODE_DIRECTORS: Dictionary = {
	"reparacion": {
		"title": "MODO REPARACIÓN",
		"director": "DIRECTOR DEL MODO: JOA",
		"title_color": Color(1.0, 0.22, 0.42, 1.0),
		"director_color": Color(1.0, 0.75, 0.85, 0.95),
		"shadow_color": Color(0.8, 0.05, 0.25, 0.8)
	},
	"reparacion_fondo": {
		"title": "MODO REPARACIÓN",
		"director": "DIRECTOR DEL MODO: JOA",
		"title_color": Color(1.0, 0.22, 0.42, 1.0),
		"director_color": Color(1.0, 0.75, 0.85, 0.95),
		"shadow_color": Color(0.8, 0.05, 0.25, 0.8)
	},
	"sistema": {
		"title": "MODO SISTEMAS",
		"director": "DIRECTOR DEL MODO: JEREMÍAS",
		"title_color": Color(0.0, 0.92, 1.0, 1.0),
		"director_color": Color(0.7, 0.92, 1.0, 0.95),
		"shadow_color": Color(0.0, 0.45, 0.85, 0.8)
	},
	"servidor": {
		"title": "MODO SERVIDORES",
		"director": "DIRECTOR DEL MODO: SANTIGO",
		"title_color": Color(1.0, 0.65, 0.12, 1.0),
		"director_color": Color(1.0, 0.88, 0.72, 0.95),
		"shadow_color": Color(0.8, 0.35, 0.05, 0.8)
	}
}

func _update_mode_header_display() -> void:
	if not lbl_mode_title or not lbl_mode_director:
		return
	var info = MODE_DIRECTORS.get(current_mode, MODE_DIRECTORS["reparacion"])
	lbl_mode_title.text = info["title"]
	lbl_mode_director.text = info["director"]
	lbl_mode_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_mode_director.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_mode_title.add_theme_color_override("font_color", info["title_color"])
	lbl_mode_title.add_theme_color_override("font_shadow_color", info["shadow_color"])
	lbl_mode_director.add_theme_color_override("font_color", info["director_color"])

# =============================================================================
# INICIALIZACIÓN
# =============================================================================
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	modulate = Color.WHITE
	btn_volver.pressed.connect(_on_volver_pressed)
	
	# Pestañas principales (Niveles) - Conexión instantánea
	if btn_niveles:
		btn_niveles.pressed.connect(func(): _switch_main_tab("niveles"))
	if btn_tutoriales:
		btn_tutoriales.pressed.connect(func(): _switch_main_tab("tutoriales"))
	_update_mode_header_display()
	
	# Selectores de modo/división
	btn_reparacion.pressed.connect(func(): _switch_mode("reparacion"))
	btn_fondo.pressed.connect(func(): _switch_mode("reparacion_fondo"))
	btn_sistema.pressed.connect(func(): _switch_mode("sistema"))
	btn_servidor.pressed.connect(func(): _switch_mode("servidor"))
	
	# Modales
	if card_dim_overlay:
		card_dim_overlay.visible = false
		card_dim_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		card_dim_overlay.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				# Clic fuera des-zoomea la cámara y restaura la interfaz; no entra al nivel
				_unzoom_camera()
		)
	if deployed_modal:
		deployed_modal.visible = false
	if dim_overlay:
		dim_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		dim_overlay.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_close_deployed_card()
		)
		
	btn_close_deployed.pressed.connect(_close_deployed_card)
	deployed_btn_play.pressed.connect(_on_deployed_play_pressed)
	if deployed_btn_tutorial_3d:
		deployed_btn_tutorial_3d.pressed.connect(_on_deployed_tutorial_3d_pressed)
	if btn_play_level1:
		btn_play_level1.pressed.connect(_on_btn_play_level_pressed)
	if difficulty_selector:
		difficulty_selector.visible = false
		difficulty_selector.launch_requested.connect(_on_btn_play_level_pressed)
		difficulty_selector.unlock_requested.connect(_on_level_unlock_requested)
	if tutorial_info_panel:
		tutorial_info_panel.visible = false
		tutorial_info_panel.launch_requested.connect(_on_btn_play_level_pressed)
		tutorial_info_panel.unlock_requested.connect(_on_level_unlock_requested)
	if btn_nav_prev:
		btn_nav_prev.focus_mode = Control.FOCUS_NONE
		btn_nav_prev.pressed.connect(func(): _navigate_level_camera(-1))
	if btn_nav_next:
		btn_nav_next.focus_mode = Control.FOCUS_NONE
		btn_nav_next.pressed.connect(func(): _navigate_level_camera(1))
		
	# Inicialización de controles de navegación y zoom de mapa
	if level_nav_controls:
		level_nav_controls.visible = false
	if map_zoom_controls:
		map_zoom_controls.visible = true
	if zoom_slider:
		zoom_slider.min_value = MIN_MAP_ZOOM
		zoom_slider.max_value = MAX_MAP_ZOOM
		zoom_slider.value = current_map_zoom
		zoom_slider.value_changed.connect(_on_zoom_slider_changed)
	if btn_zoom_out:
		btn_zoom_out.pressed.connect(func(): _adjust_map_zoom(-0.15))
	if btn_zoom_in:
		btn_zoom_in.pressed.connect(func(): _adjust_map_zoom(0.15))
	
	if graph_lines and graph_lines.has_signal("mode_transition_completed"):
		graph_lines.mode_transition_completed.connect(_update_node_hitboxes_positions)
		
	if constellation_area:
		constellation_area.mouse_filter = Control.MOUSE_FILTER_PASS
		constellation_area.gui_input.connect(_on_constellation_gui_input)
		
	# Selector de Modo Terminal Linux
	if term_btn_reparacion and term_btn_reparacion.material:
		term_btn_reparacion.material = term_btn_reparacion.material.duplicate()
	if term_btn_sistema and term_btn_sistema.material:
		term_btn_sistema.material = term_btn_sistema.material.duplicate()
	if term_btn_servidor and term_btn_servidor.material:
		term_btn_servidor.material = term_btn_servidor.material.duplicate()
		
	if btn_up_arrow:
		btn_up_arrow.pressed.connect(func(): _cycle_mode(-1); _wake_mode_selector())
	if btn_down_arrow:
		btn_down_arrow.pressed.connect(func(): _cycle_mode(1); _wake_mode_selector())
		
	if term_btn_reparacion:
		var hit = term_btn_reparacion.get_node_or_null("Hitbox")
		if hit: hit.pressed.connect(func(): _switch_mode("reparacion"); _wake_mode_selector())
	if term_btn_sistema:
		var hit = term_btn_sistema.get_node_or_null("Hitbox")
		if hit: hit.pressed.connect(func(): _switch_mode("sistema"); _wake_mode_selector())
	if term_btn_servidor:
		var hit = term_btn_servidor.get_node_or_null("Hitbox")
		if hit: hit.pressed.connect(func(): _switch_mode("servidor"); _wake_mode_selector())
		
	if circular_mode_selector:
		circular_mode_selector.mouse_entered.connect(_wake_mode_selector)
		
	if initial_mode != "" and (initial_mode == "reparacion" or initial_mode == "sistema" or initial_mode == "servidor"):
		current_mode = initial_mode
		
	# Ocultar banner de texto de área
	if section_banner:
		section_banner.visible = false
	if banner_label:
		banner_label.text = ""

	_update_terminal_buttons()
	_apply_mode_palette(current_mode, true)
	if graph_lines and graph_lines.has_method("transition_to_mode") and current_mode != "reparacion":
		graph_lines.transition_to_mode(current_mode)
		
	_create_node_hitboxes()
	_sync_progression_from_save()
	_update_player_stats()
	var sm_inst = get_node_or_null("/root/SaveManager")
	if sm_inst and sm_inst.has_signal("slot_saved"):
		sm_inst.slot_saved.connect(func(_slot_idx): _update_player_stats())
	_check_and_play_pending_unlock()
	_setup_tutorial_scroll()
	
	var sm_gl = get_node_or_null("/root/SaveManager")
	if sm_gl and sm_gl.has_method("trigger_pending_glossary_notification"):
		sm_gl.trigger_pending_glossary_notification()
	
	# Configurar pestaña inicial solicitada
	var start_tab = initial_tab
	initial_tab = "niveles" # Reiniciar por defecto
	
	if start_tab == "tutoriales":
		_switch_main_tab("tutoriales", true)
	else:
		_switch_main_tab("niveles", true)

	if pending_glitch_purge_node >= 0:
		var purge_node = pending_glitch_purge_node
		pending_glitch_purge_node = -1
		get_tree().create_timer(0.4).timeout.connect(func():
			if is_instance_valid(graph_lines) and graph_lines.has_method("play_glitch_purge_animation"):
				graph_lines.play_glitch_purge_animation(purge_node)
				var gm = get_node_or_null("/root/GameManager")
				if gm and gm.has_method("play_sfx"):
					gm.play_sfx("success")
		)

func _setup_tutorial_scroll() -> void:
	if btn_scroll_up:
		btn_scroll_up.pressed.connect(func(): _scroll_tutorial_cards(-260.0))
	if btn_scroll_down:
		btn_scroll_down.pressed.connect(func(): _scroll_tutorial_cards(260.0))
		
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.08, 0.05, 0.18, 0.9)
	btn_style.border_color = Color(0.0, 0.85, 1.0, 0.8)
	btn_style.border_width_left = 2
	btn_style.border_width_top = 2
	btn_style.border_width_right = 2
	btn_style.border_width_bottom = 2
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_right = 6
	btn_style.corner_radius_bottom_left = 6
	
	if btn_scroll_up:
		btn_scroll_up.add_theme_stylebox_override("normal", btn_style)
		btn_scroll_up.add_theme_stylebox_override("hover", btn_style)
		btn_scroll_up.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if btn_scroll_down:
		btn_scroll_down.add_theme_stylebox_override("normal", btn_style)
		btn_scroll_down.add_theme_stylebox_override("hover", btn_style)
		btn_scroll_down.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
	if cards_scroll:
		var v_bar = cards_scroll.get_v_scroll_bar()
		if v_bar:
			v_bar.custom_minimum_size = Vector2(16, 0)
			
			var sb_grabber = StyleBoxFlat.new()
			sb_grabber.bg_color = Color(0.0, 0.9, 1.0, 0.95)
			sb_grabber.corner_radius_top_left = 6
			sb_grabber.corner_radius_top_right = 6
			sb_grabber.corner_radius_bottom_right = 6
			sb_grabber.corner_radius_bottom_left = 6
			v_bar.add_theme_stylebox_override("grabber", sb_grabber)
			
			var sb_grabber_hl = StyleBoxFlat.new()
			sb_grabber_hl.bg_color = Color(1.0, 0.88, 0.2, 1.0)
			sb_grabber_hl.corner_radius_top_left = 6
			sb_grabber_hl.corner_radius_top_right = 6
			sb_grabber_hl.corner_radius_bottom_right = 6
			sb_grabber_hl.corner_radius_bottom_left = 6
			v_bar.add_theme_stylebox_override("grabber_highlight", sb_grabber_hl)
			
			var sb_grabber_pr = StyleBoxFlat.new()
			sb_grabber_pr.bg_color = Color(0.2, 1.0, 0.6, 1.0)
			sb_grabber_pr.corner_radius_top_left = 6
			sb_grabber_pr.corner_radius_top_right = 6
			sb_grabber_pr.corner_radius_bottom_right = 6
			sb_grabber_pr.corner_radius_bottom_left = 6
			v_bar.add_theme_stylebox_override("grabber_pressed", sb_grabber_pr)
			
			var sb_scroll = StyleBoxFlat.new()
			sb_scroll.bg_color = Color(0.04, 0.03, 0.1, 0.8)
			sb_scroll.border_color = Color(0.0, 0.8, 1.0, 0.4)
			sb_scroll.border_width_left = 1
			sb_scroll.border_width_right = 1
			sb_scroll.corner_radius_top_left = 6
			sb_scroll.corner_radius_top_right = 6
			sb_scroll.corner_radius_bottom_right = 6
			sb_scroll.corner_radius_bottom_left = 6
			v_bar.add_theme_stylebox_override("scroll", sb_scroll)

func _scroll_tutorial_cards(amount: float) -> void:
	if not cards_scroll:
		return
	var v_bar = cards_scroll.get_v_scroll_bar()
	var max_v = v_bar.max_value if v_bar else 1000.0
	var current = float(cards_scroll.scroll_vertical)
	var target = clampf(current + amount, 0.0, max_v)
	var tw = create_tween()
	tw.tween_property(cards_scroll, "scroll_vertical", int(target), 0.18)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	if current_tab == "niveles" and graph_lines and "is_transitioning" in graph_lines and graph_lines.is_transitioning:
		_update_node_hitboxes_positions()

	# Cursor parpadeante estilo terminal de Linux
	_cursor_blink_timer += delta
	var cursor_visible: bool = fmod(_cursor_blink_timer, 0.8) < 0.45
	_update_terminal_cursor_blink(cursor_visible)

	# Desvanecimiento por inactividad de los botones terminal y flechas
	if current_tab == "niveles" and not is_level_zoomed and not is_panning_map:
		_mode_selector_idle_timer += delta
		if _mode_selector_idle_timer >= 4.0 and not _is_selector_faded and circular_mode_selector:
			_is_selector_faded = true
			var tw = create_tween()
			tw.tween_property(circular_mode_selector, "modulate:a", 0.0, 0.55)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)



# =============================================================================
# CONMUTACIÓN INSTANTÁNEA DE PESTAÑAS (0 MS RETRASO, FLUIDEZ ABSOLUTA)
# =============================================================================
func _switch_main_tab(tab_name: String, instant: bool = false) -> void:
	if is_level_zoomed:
		_unzoom_camera()
	current_tab = tab_name
	_update_tab_buttons_visuals()
	_update_mode_buttons()
	_update_btn_play_level1_visibility()
	if level_nav_controls:
		level_nav_controls.visible = is_level_zoomed and (current_tab == "niveles")
	if map_zoom_controls:
		map_zoom_controls.visible = not is_level_zoomed and (current_tab == "niveles")

	if current_tab == "niveles":
		if has_node("/root/MusicManager"):
			get_node("/root/MusicManager").stop_music(0.8)
		if tutorial_area:
			tutorial_area.visible = false
		if constellation_area:
			constellation_area.visible = true
		if column_headers:
			column_headers.visible = true
		_update_headers_for_mode()
		footer_hint.text = "⌜  CLIC EN CUALQUIER NODO PARA INSPECCIONAR SUS DATOS TÉCNICOS  ⌟"
		
		if not instant and constellation_area:
			constellation_area.modulate.a = 0.5
			var tw = create_tween()
			tw.tween_property(constellation_area, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_QUAD)
	else:
		if has_node("/root/MusicManager"):
			get_node("/root/MusicManager").play_tutorial()
		if constellation_area:
			constellation_area.visible = false
		if column_headers:
			column_headers.visible = false
		if tutorial_area:
			tutorial_area.visible = true
		if banner_label and section_banner and section_banner.visible:
			banner_label.text = "CENTRO DE ENTRENAMIENTO // GUÍA TÉCNICA Y SIMULADORES"
		footer_hint.text = "⌜  SELECCIONA UNA TARJETA PARA VER DETALLES O PRACTICAR EN EL SIMULADOR  ⌟"
		_filter_tutorial_cards()
		
		if not instant and tutorial_area:
			tutorial_area.modulate.a = 0.5
			var tw = create_tween()
			tw.tween_property(tutorial_area, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_QUAD)

func _update_tab_buttons_visuals() -> void:
	var is_niv = (current_tab == "niveles")
	var pal = MODE_PALETTES.get(current_mode, MODE_PALETTES["reparacion"])
	
	if is_niv:
		if btn_niveles:
			btn_niveles.modulate = Color(1.3, 1.3, 1.3, 1.0)
			if "border_color" in btn_niveles:
				btn_niveles.border_color = pal.accent
		if btn_tutoriales:
			btn_tutoriales.modulate = Color(0.65, 0.65, 0.72, 0.75)
			if "border_color" in btn_tutoriales:
				btn_tutoriales.border_color = Color(0.45, 0.15, 0.6, 0.6)
	else:
		if btn_tutoriales:
			btn_tutoriales.modulate = Color(1.3, 1.3, 1.3, 1.0)
			if "border_color" in btn_tutoriales:
				btn_tutoriales.border_color = pal.accent
		if btn_niveles:
			btn_niveles.modulate = Color(0.65, 0.65, 0.72, 0.75)
			if "border_color" in btn_niveles:
				btn_niveles.border_color = Color(0.45, 0.15, 0.6, 0.6)
			
	if btn_niveles and btn_niveles.has_method("queue_redraw"):
		btn_niveles.queue_redraw()
	if btn_tutoriales and btn_tutoriales.has_method("queue_redraw"):
		btn_tutoriales.queue_redraw()

# =============================================================================
# SELECTOR DE MODO TERMINAL LINUX (LATERAL DERECHO)
# =============================================================================
func _cycle_mode(direction: int) -> void:
	_wake_mode_selector()
	if is_level_zoomed:
		return
	var cur_idx = MODE_ORDER.find(current_mode)
	if cur_idx == -1:
		cur_idx = 0
	var next_idx = posmod(cur_idx + direction, MODE_ORDER.size())
	_switch_mode(MODE_ORDER[next_idx], direction)

func _wake_mode_selector() -> void:
	_mode_selector_idle_timer = 0.0
	if not circular_mode_selector:
		return
	if _is_selector_faded or circular_mode_selector.modulate.a < 0.95:
		_is_selector_faded = false
		var tw = create_tween()
		tw.tween_property(circular_mode_selector, "modulate:a", 1.0, 0.20)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# Configuración de posiciones en arco circular y desplazamiento sobresaliente al seleccionar
const ARC_BUTTON_CONFIG = {
	"reparacion": {
		"base_pos": Vector2(25.0, 16.0),
		"selected_offset_x": -45.0
	},
	"sistema": {
		"base_pos": Vector2(-16.0, 100.0),
		"selected_offset_x": -45.0
	},
	"servidor": {
		"base_pos": Vector2(25.0, 184.0),
		"selected_offset_x": -45.0
	}
}

func _update_terminal_buttons() -> void:
	var buttons = {
		"reparacion": term_btn_reparacion,
		"sistema": term_btn_sistema,
		"servidor": term_btn_servidor
	}
	var colors = {
		"reparacion": Color(1.0, 0.25, 0.45, 1.0),
		"sistema": Color(0.0, 0.95, 1.0, 1.0),
		"servidor": Color(1.0, 0.65, 0.15, 1.0)
	}
	
	for mode_key in buttons.keys():
		var btn = buttons[mode_key]
		if not btn:
			continue
		var is_active = (mode_key == current_mode)
		var col: Color = colors[mode_key]
		var cfg = ARC_BUTTON_CONFIG.get(mode_key, {"base_pos": Vector2.ZERO, "selected_offset_x": -45.0})
		
		# Posición en arco circular: el botón seleccionado sobresale fuertemente hacia la izquierda (-45px)
		var target_pos: Vector2 = cfg.base_pos
		if is_active:
			target_pos.x += cfg.selected_offset_x
			btn.z_index = 5
		else:
			btn.z_index = 0
			
		var target_scale = Vector2(1.18, 1.18) if is_active else Vector2(0.88, 0.88)
		var target_modulate = Color(1.0, 1.0, 1.0, 1.0) if is_active else Color(0.70, 0.72, 0.78, 0.50)
		
		var tw = create_tween().set_parallel(true)
		tw.tween_property(btn, "position", target_pos, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", target_scale, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "modulate", target_modulate, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		# Shader de terminal con marco neutro
		if btn.material is ShaderMaterial:
			var smat = btn.material as ShaderMaterial
			smat.set_shader_parameter("is_selected", is_active)
			smat.set_shader_parameter("term_color", col)
		
		var cursor = btn.get_node_or_null("Margin/HBox/LblCursor")
		if cursor:
			cursor.visible = is_active
			cursor.modulate = col
		var prompt = btn.get_node_or_null("Margin/HBox/LblPrompt")
		if prompt:
			prompt.modulate = col if is_active else Color(0.75, 0.75, 0.8, 0.7)

func _update_terminal_cursor_blink(cursor_visible: bool) -> void:
	var buttons = {
		"reparacion": term_btn_reparacion,
		"sistema": term_btn_sistema,
		"servidor": term_btn_servidor
	}
	var active_btn = buttons.get(current_mode, null)
	if active_btn:
		var cursor = active_btn.get_node_or_null("Margin/HBox/LblCursor")
		if cursor:
			cursor.visible = cursor_visible

func _apply_mode_palette(mode_name: String, instant: bool = false) -> void:
	var pal = MODE_PALETTES.get(mode_name, MODE_PALETTES["reparacion"])

	if instant:
		if background_rect:
			background_rect.color = pal.bg_color
		return

	if _color_tween and _color_tween.is_valid():
		_color_tween.kill()
	_color_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if background_rect:
		_color_tween.tween_property(background_rect, "color", pal.bg_color, 0.20)

func _update_player_stats() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if not sm:
		return
	var data = sm.get_slot(sm.current_slot)
	var pts: int = int(data.get("score", 0))
	var stars: int = int(data.get("stars", 0))
	var dollars: int = int(data.get("dollars", 500 if sm.current_slot == 1 else 0))

	if lbl_points_val:
		lbl_points_val.text = _format_thousands(pts)
	if lbl_stars_val:
		lbl_stars_val.text = str(stars)
	if lbl_dollars_val:
		var has_logo = lbl_dollars_val.get_parent().get_node_or_null("DollarLogo") != null
		if has_logo:
			lbl_dollars_val.text = _format_thousands(dollars)
		else:
			lbl_dollars_val.text = "$ %s" % [_format_thousands(dollars)]

func _format_thousands(val: int) -> String:
	var s = str(val)
	var res = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = "," + res
	return res

# =============================================================================
# CONMUTACIÓN DE MODO / DIVISIÓN (REPARACIÓN, SISTEMA, SERVIDOR)
# =============================================================================
func _switch_mode(mode_name: String, spin_dir: int = 0) -> void:
	_wake_mode_selector()
	is_panning_map = false
	if is_level_zoomed:
		_unzoom_camera()
	elif constellation_area:
		constellation_area.position = Vector2.ZERO
	if current_mode == mode_name and spin_dir == 0:
		return
		
	current_mode = mode_name

	if btn_up_arrow and spin_dir < 0:
		var tw_arr = create_tween()
		tw_arr.tween_property(btn_up_arrow, "scale", Vector2(1.2, 1.2), 0.08)
		tw_arr.tween_property(btn_up_arrow, "scale", Vector2.ONE, 0.12)
	elif btn_down_arrow and spin_dir > 0:
		var tw_arr = create_tween()
		tw_arr.tween_property(btn_down_arrow, "scale", Vector2(1.2, 1.2), 0.08)
		tw_arr.tween_property(btn_down_arrow, "scale", Vector2.ONE, 0.12)

	_update_terminal_buttons()

	_apply_mode_palette(current_mode, false)
	_play_mode_switch_animation(current_mode)
	_update_mode_buttons()
	_update_tab_buttons_visuals()
	_update_mode_header_display()
	_update_btn_play_level1_visibility()
	
	if current_tab == "niveles":
		_update_headers_for_mode()
		if graph_lines and graph_lines.has_method("transition_to_mode"):
			graph_lines.transition_to_mode(current_mode)
		_create_node_hitboxes()
		_update_node_hitboxes_positions()
		_sync_progression_from_save()
	else:
		_filter_tutorial_cards()
		cards_scroll.scroll_vertical = 0
		cards_grid.modulate.a = 0.5
		var tw = create_tween()
		tw.tween_property(cards_grid, "modulate:a", 1.0, 0.1)

func _play_mode_switch_animation(mode_name: String) -> void:
	if constellation_area:
		var tw = create_tween()
		constellation_area.modulate = Color(1.8, 1.8, 2.3, 1.0)
		tw.tween_property(constellation_area, "modulate", Color.WHITE, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if mode_header:
		mode_header.pivot_offset = mode_header.size * 0.5
		var tw_h = create_tween()
		mode_header.scale = Vector2(1.06, 1.06)
		tw_h.tween_property(mode_header, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if banner_label and section_banner and section_banner.visible:
		banner_label.pivot_offset = banner_label.size * 0.5
		var tw_b = create_tween()
		banner_label.scale = Vector2(1.06, 1.06)
		tw_b.tween_property(banner_label, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	if mode_name == "sistema":
		_show_toast("⚡ [SISTEMAS] ACCEDIENDO A KERNEL & MATRIZ DE SOFTWARE")
	elif mode_name == "reparacion":
		_show_toast("🛠️ [REPARACIÓN] ACCEDIENDO A TALLER & BANCO DE HARDWARE")
	elif mode_name == "servidor":
		_show_toast("🌐 [SERVIDOR] ACCEDIENDO A DATACENTER & FIBRA ÓPTICA")

func _update_mode_buttons() -> void:
	var tabs = [
		{"btn": btn_reparacion, "name": "reparacion"},
		{"btn": btn_fondo, "name": "reparacion_fondo"},
		{"btn": btn_sistema, "name": "sistema"},
		{"btn": btn_servidor, "name": "servidor"}
	]
	
	var rep_count = 0
	var sis_count = 0
	var srv_count = 0
	var fondo_count = 0
	for c in ALL_TUTORIAL_CARDS:
		match c.get("division", ""):
			"reparacion": rep_count += 1
			"sistema": sis_count += 1
			"servidor": srv_count += 1
			"reparacion_fondo": fondo_count += 1
			
	if current_tab == "niveles":
		btn_reparacion.text = "REPARACIÓN (12)"
		btn_fondo.visible = false
		btn_sistema.text = "SISTEMA (12)"
		btn_servidor.text = "SERVIDOR (12)"
	else:
		btn_reparacion.text = "REPARACIÓN (%d)" % rep_count
		btn_fondo.visible = true
		btn_fondo.text = "REPARACIÓN A FONDO (%d)" % fondo_count
		btn_sistema.text = "SISTEMA (%d)" % sis_count
		btn_servidor.text = "SERVIDOR (%d)" % srv_count
	
	for t in tabs:
		var is_active = (t["name"] == current_mode)
		if is_active:
			t["btn"].modulate = Color(1.3, 1.3, 1.3, 1.0)
			if "border_color" in t["btn"]:
				t["btn"].border_color = Color(1.0, 0.1, 0.4, 1.0)
		else:
			t["btn"].modulate = Color(0.65, 0.65, 0.72, 0.8)
			if "border_color" in t["btn"]:
				t["btn"].border_color = Color(0.45, 0.15, 0.6, 0.6)
		if t["btn"].has_method("queue_redraw"):
			t["btn"].queue_redraw()

func _update_headers_for_mode() -> void:
	if section_banner:
		section_banner.visible = false
	if banner_label:
		banner_label.text = ""
	match current_mode:
		"reparacion":
			col1_label.text = "NÚCLEO TUTORIAL & ETAPA 1 [1-4]"
			col2_label.text = "ETAPA 2: HARDWARE AVANZADO [5-8]"
			col3_label.text = "ETAPA 3: MAESTRÍA DE DIAGNÓSTICO [9-12]"
		"reparacion_fondo":
			col1_label.text = "PASTA TÉRMICA"
			col2_label.text = "ALINEACIÓN DE PINES"
			col3_label.text = "CALIBRACIÓN"
		"sistema":
			col1_label.text = "NÚCLEO TUTORIAL & ETAPA 1 [1-4]"
			col2_label.text = "ETAPA 2: KERNEL & DRIVERS [5-8]"
			col3_label.text = "ETAPA 3: CIBERSEGURIDAD & RESCATE [9-12]"
		"servidor":
			col1_label.text = "NÚCLEO TUTORIAL & ETAPA 1 [1-4]"
			col2_label.text = "ETAPA 2: ALMACENAMIENTO RAID [5-8]"
			col3_label.text = "ETAPA 3: DATACENTER & CLOUD [9-12]"

# =============================================================================
# HITBOXES DE NODOS (MODO NIVELES - 13 NODOS DE TELARAÑA)
# =============================================================================
func _create_node_hitboxes() -> void:
	for b in node_buttons:
		b.queue_free()
	node_buttons.clear()
	
	var count = graph_lines.nodes.size() if (graph_lines and not graph_lines.nodes.is_empty()) else 13
	for i in range(count):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(60, 60)
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.button_down.connect(_on_node_pressed.bind(i))
		btn.pressed.connect(_on_node_clicked.bind(i))
		constellation_area.add_child(btn)
		node_buttons.append(btn)
		
	_update_node_hitboxes_positions()

func _update_node_hitboxes_positions() -> void:
	if not graph_lines:
		return
	var pts = graph_lines.nodes
	for i in range(min(node_buttons.size(), pts.size())):
		var btn = node_buttons[i]
		var np = pts[i]
		btn.position = np - Vector2(30, 30)

func _on_node_pressed(index: int) -> void:
	if graph_lines and graph_lines.has_method("trigger_node_click_zoom"):
		graph_lines.trigger_node_click_zoom(index)

func _on_node_clicked(index: int) -> void:
	var list = LEVELS_DATA.get(current_mode, [])
	if index >= list.size():
		return
		
	var data = list[index]
	
	# Si ya está en zoom sobre el nodo y vuelven a presionar: no accionar entrada, permanecer enfocado
	if is_level_zoomed and active_zoomed_index == index:
		return
		
	is_level_zoomed = true
	active_zoomed_index = index
	
	# Ocultar barra de zoom del mapa y mostrar flechas de navegación de nivel
	if map_zoom_controls:
		map_zoom_controls.visible = false
	if level_nav_controls:
		level_nav_controls.visible = true
	
	# Desvanecer todos los demás botones de la interfaz para dejar limpio el nivel y selector
	_fade_menu_chrome(false)
	
	if graph_lines and graph_lines.has_method("trigger_node_click_zoom"):
		graph_lines.trigger_node_click_zoom(index)
		
	# ZOOM DE CÁMARA AL CÍRCULO CLICKEADO:
	var node_pos = graph_lines.nodes[index] if (graph_lines and index < graph_lines.nodes.size()) else _get_mode_center()
	var zoom_factor: float = 2.1
	var target_screen_pos = Vector2(260, 390)
	var target_area_pos = target_screen_pos - node_pos * zoom_factor
	
	if constellation_area:
		constellation_area.pivot_offset = Vector2.ZERO
	
	if camera_zoom_tween and camera_zoom_tween.is_valid():
		camera_zoom_tween.kill()
		
	camera_zoom_tween = create_tween().set_parallel(true)
	if constellation_area:
		camera_zoom_tween.tween_property(constellation_area, "position", target_area_pos, 0.42)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		camera_zoom_tween.tween_property(constellation_area, "scale", Vector2(zoom_factor, zoom_factor), 0.42)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
	# Ocultar botón antiguo bajo el círculo
	if btn_play_level1:
		btn_play_level1.visible = false
		
	# Paneles laterales según el tipo de nodo (Tutorial o Nivel)
	data["node_index"] = index
	var req_points = get_node_required_points(current_mode, index)
	var player_points = get_player_points()
	var prev_completed = is_previous_level_completed(current_mode, index)

	if data.get("is_tutorial", false):
		# BURBUJA AZUL TUTORIAL - Mostrar Panel de Información del Tutorial
		if difficulty_selector and difficulty_selector.visible:
			difficulty_selector.play_exit_animation()
		if tutorial_info_panel:
			tutorial_info_panel.open_for_tutorial_node(data, req_points, player_points, prev_completed)
	elif data.get("is_practice", false):
		# SALA DE PRÁCTICA - Mostrar Panel en modo práctica libre
		if difficulty_selector and difficulty_selector.visible:
			difficulty_selector.play_exit_animation()
		if tutorial_info_panel:
			tutorial_info_panel.open_for_practice(data, req_points, player_points, prev_completed)
	elif data.get("is_inspection", false):
		# MICRO-TALLER MORADO (LUPA TÉCNICA)
		if difficulty_selector and difficulty_selector.visible:
			difficulty_selector.play_exit_animation()
		if tutorial_info_panel:
			tutorial_info_panel.open_for_inspection_node(data, req_points, player_points, prev_completed)
	else:
		# NIVEL JUGABLE (Nivel 1 al 12)
		if tutorial_info_panel and tutorial_info_panel.visible:
			tutorial_info_panel.play_exit_animation()
		if difficulty_selector:
			difficulty_selector.open_for_level(data, req_points, player_points, prev_completed)
		
	# Habilitar el overlay invisible de captura de clics fuera de la tarjeta
	if card_dim_overlay:
		card_dim_overlay.visible = true
		card_dim_overlay.color = Color(0, 0, 0, 0)

func _get_mode_center() -> Vector2:
	if graph_lines and not graph_lines.nodes.is_empty():
		return graph_lines.nodes[0]
	return Vector2(640, 360)

func _unzoom_camera() -> void:
	is_launching_level = false
	if not is_level_zoomed:
		return
	is_level_zoomed = false
	active_zoomed_index = -1
	
	# Ocultar flechas de navegación de nivel
	if level_nav_controls:
		level_nav_controls.visible = false
	# Reaparecer barra de zoom del mapa en la vista general
	if map_zoom_controls:
		map_zoom_controls.visible = (current_tab == "niveles")
	
	if card_dim_overlay:
		card_dim_overlay.visible = false
			
	if camera_zoom_tween and camera_zoom_tween.is_valid():
		camera_zoom_tween.kill()
		
	camera_zoom_tween = create_tween().set_parallel(true)
	if constellation_area:
		constellation_area.pivot_offset = _get_mode_center()
		camera_zoom_tween.tween_property(constellation_area, "position", Vector2.ZERO, 0.38)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		camera_zoom_tween.tween_property(constellation_area, "scale", Vector2(current_map_zoom, current_map_zoom), 0.38)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
	if btn_play_level1 and btn_play_level1.visible:
		btn_play_level1.visible = false
	
	if difficulty_selector and difficulty_selector.visible:
		difficulty_selector.play_exit_animation()
	if tutorial_info_panel and tutorial_info_panel.visible:
		tutorial_info_panel.play_exit_animation()
		
	# Restaurar todos los botones de la interfaz
	_fade_menu_chrome(true)

func _navigate_level_camera(direction: int) -> void:
	var list = LEVELS_DATA.get(current_mode, [])
	if list.is_empty():
		return
		
	var total = list.size()
	var new_index = active_zoomed_index + direction
	if active_zoomed_index < 0:
		new_index = 0 if direction >= 0 else total - 1
	elif new_index < 0:
		new_index = total - 1
	elif new_index >= total:
		new_index = 0
			
	# Micro punch animado en el botón presionado
	var target_btn = btn_nav_next if direction > 0 else btn_nav_prev
	if target_btn:
		var tw = create_tween()
		tw.tween_property(target_btn, "scale", Vector2(1.14, 1.14), 0.08).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(target_btn, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_QUAD)
		
	# Mover suavemente la cámara al nivel indicado sin entrar a jugar
	_on_node_clicked(new_index)

func _adjust_map_zoom(delta_val: float) -> void:
	if is_level_zoomed or current_tab != "niveles":
		return
	var new_zoom = clampf(current_map_zoom + delta_val, MIN_MAP_ZOOM, MAX_MAP_ZOOM)
	_apply_map_zoom(new_zoom)

func _on_zoom_slider_changed(val: float) -> void:
	if is_level_zoomed or current_tab != "niveles":
		return
	_apply_map_zoom(val)

func _apply_map_zoom(target_zoom: float) -> void:
	current_map_zoom = target_zoom
	if zoom_slider and abs(zoom_slider.value - current_map_zoom) > 0.01:
		zoom_slider.value = current_map_zoom
	if zoom_label:
		zoom_label.text = "%d%%" % int(round(current_map_zoom * 100.0))
		
	if constellation_area:
		constellation_area.pivot_offset = _get_mode_center()
		if camera_zoom_tween and camera_zoom_tween.is_valid():
			camera_zoom_tween.kill()
		camera_zoom_tween = create_tween().set_parallel(true)
		camera_zoom_tween.tween_property(constellation_area, "scale", Vector2(current_map_zoom, current_map_zoom), 0.18)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		camera_zoom_tween.tween_property(constellation_area, "position", Vector2.ZERO, 0.18)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _fade_menu_chrome(visible_state: bool) -> void:
	var target_alpha = 1.0 if visible_state else 0.0
	var target_mouse = Control.MOUSE_FILTER_PASS if visible_state else Control.MOUSE_FILTER_IGNORE
	var chrome_nodes = [
		get_node_or_null("TopBar"),
		get_node_or_null("ModeSelector"),
		get_node_or_null("SectionBanner"),
		get_node_or_null("ColumnHeaders"),
		get_node_or_null("FooterHint"),
		player_stats_hud,
		circular_mode_selector
	]
	for node in chrome_nodes:
		if node:
			node.mouse_filter = target_mouse
			var tw = create_tween()
			tw.tween_property(node, "modulate:a", target_alpha, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _update_btn_play_level1_visibility() -> void:
	if btn_play_level1:
		btn_play_level1.visible = false
	var list = LEVELS_DATA.get(current_mode, [])
	var node_data: Dictionary = {}
	if active_zoomed_index >= 0 and active_zoomed_index < list.size():
		node_data = list[active_zoomed_index]
	var is_tut = node_data.get("is_tutorial", false)
	var is_prac = node_data.get("is_practice", false)
	var is_insp = node_data.get("is_inspection", false)

	if difficulty_selector and not (is_level_zoomed and not is_tut and not is_prac and not is_insp and current_tab == "niveles"):
		difficulty_selector.visible = false
	if tutorial_info_panel and not (is_level_zoomed and (is_tut or is_prac or is_insp) and current_tab == "niveles"):
		tutorial_info_panel.visible = false

func _on_btn_play_level_pressed() -> void:
	var list = LEVELS_DATA.get(current_mode, [])
	var node_data: Dictionary = {}
	if active_zoomed_index >= 0 and active_zoomed_index < list.size():
		node_data = list[active_zoomed_index]

	# REQUISITO EXPRESO: Todos los niveles, tutoriales y retos bloqueados no se pueden iniciar
	if not node_data.get("can_play", false):
		is_launching_level = false
		_show_toast("🔒 Este módulo está bloqueado. Supera la etapa anterior para desbloquearlo.")
		return

	if node_data.get("is_tutorial", false):
		var target_comp = node_data.get("tutorial_component", "general")
		var target_scene = node_data.get("target_scene", "")
		if target_scene == "" and TUTORIAL_SCENES.has(target_comp):
			target_scene = TUTORIAL_SCENES[target_comp]
		elif target_scene == "":
			target_scene = "res://scenes/gameplay/LevelTutorial.tscn"
		_play_tutorial_level(target_comp, target_scene, node_data.get("title", ""))
	elif node_data.get("is_practice", false):
		var practice_id = node_data.get("practice_id", "maestra")
		_play_practice_level(practice_id)
	elif node_data.get("is_inspection", false):
		_play_inspection_level(node_data)
	else:
		# NIVEL DE JUEGO (Nivel 1 al 12)
		_play_level_1()

func _play_inspection_level(node_data: Dictionary) -> void:
	if is_launching_level:
		return
	is_launching_level = true
	
	if btn_play_level1:
		btn_play_level1.visible = false
		
	var target_scene = node_data.get("target_scene", "")
	if target_scene == "":
		_show_toast("⚠ Módulo en calibración técnica. Próximamente.")
		is_launching_level = false
		return
		
	var title_text = node_data.get("title", "MICROTALLER DE PRECISIÓN")
	var sub_text = "// TALLER TÉCNICO CON LUPA //"
	var target_comp = node_data.get("target_component", "")
	
	CyberPlayTransition.play(
		get_tree(),
		target_scene,
		title_text,
		sub_text,
		func():
			var cur_scene = get_tree().current_scene
			if cur_scene:
				if cur_scene.has_method("setup_component") and target_comp != "":
					cur_scene.setup_component(target_comp)
				if cur_scene.has_method("setup_hacking"):
					cur_scene.setup_hacking(node_data),
		false,
		false,
		current_mode
	)

func _play_practice_level(practice_id: String = "") -> void:
	if is_launching_level:
		return
	is_launching_level = true
	
	if btn_play_level1:
		btn_play_level1.visible = false
		
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("start_level"):
		gm.start_level(999.0)
		gm.timer_active = false

	var chosen_zone = practice_id
	var list = LEVELS_DATA.get(current_mode, [])
	if chosen_zone == "" and active_zoomed_index >= 0 and active_zoomed_index < list.size():
		chosen_zone = list[active_zoomed_index].get("practice_id", "maestra")
	if chosen_zone == "":
		chosen_zone = "maestra"

	var LevelPracticeScript = load("res://scripts/gameplay/LevelPractice.gd")
	if LevelPracticeScript:
		LevelPracticeScript.practice_zone = chosen_zone
	if gm:
		gm.practice_target_mode = chosen_zone
		gm.current_mode = current_mode

	var zone_titles: Dictionary = {
		"ram": "BANCO DE PRÁCTICA: MEMORIAS RAM",
		"hdd": "BANCO DE PRÁCTICA: DISCOS HDD/SSD",
		"gpu": "BANCO DE PRÁCTICA: TARJETAS GPU",
		"cooler": "BANCO DE PRÁCTICA: FAN COOLER",
		"psu": "BANCO DE PRÁCTICA: FUENTES Y CPU",
		"cpu": "BANCO DE PRÁCTICA: PROCESADOR CPU",
		"maestra": "SALA DE PRÁCTICA 3D MAESTRA"
	}
	var title_text = zone_titles.get(chosen_zone, "SALA DE PRÁCTICA 3D")
		
	CyberPlayTransition.play(
		get_tree(),
		"res://scenes/gameplay/LevelPractice.tscn",
		title_text,
		"// ENTRENAMIENTO TÉCNICO · BANCO DE TRABAJO LIBRE //",
		Callable(),
		false,
		false,
		current_mode
	)

func _play_tutorial_level(target_component: String = "general", scene_path: String = "", custom_title: String = "") -> void:
	if is_launching_level:
		return
	is_launching_level = true
	
	if btn_play_level1:
		btn_play_level1.visible = false
		
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.current_mode = current_mode
		gm.tutorial_target_component = target_component
		if gm.has_method("start_level"):
			gm.start_level(999.0)

	var LevelTutorialScript = load("res://scripts/gameplay/LevelTutorial.gd")
	if LevelTutorialScript:
		LevelTutorialScript.target_component = target_component

	var final_scene = scene_path
	if final_scene == "":
		if TUTORIAL_SCENES.has(target_component):
			final_scene = TUTORIAL_SCENES[target_component]
		else:
			final_scene = "res://scenes/gameplay/LevelTutorial.tscn"
		
	var tut_title = custom_title if custom_title != "" else "NÚCLEO TUTORIAL: REPARACIÓN 3D"
	var tut_sub = "// APRENDIZAJE TÉCNICO GUIADO CON JOA //"
	if custom_title == "":
		if target_component != "general" and target_component != "":
			tut_title = "TUTORIAL 3D: %s" % target_component.to_upper()
		elif current_mode == "sistema":
			tut_title = "NÚCLEO TUTORIAL: SISTEMAS 3D"
			tut_sub = "// INDUCCIÓN TÉCNICA · KERNEL & SOFTWARE //"
		elif current_mode == "servidor":
			tut_title = "NÚCLEO TUTORIAL: SERVIDOR 3D"
			tut_sub = "// INDUCCIÓN TÉCNICA · INFRAESTRUCTURA DATACENTER //"

	CyberPlayTransition.play(
		get_tree(),
		final_scene,
		tut_title,
		tut_sub,
		Callable(),
		true,
		false,
		current_mode
	)

func _open_tutorial_from_hub() -> void:
	var mode_tutorials: Array[Dictionary] = []
	for c in ALL_TUTORIAL_CARDS:
		if c.get("division", "") == current_mode:
			mode_tutorials.append(c)
	_unzoom_camera()
	if not mode_tutorials.is_empty():
		_open_deployed_card(mode_tutorials[0])
	else:
		_switch_main_tab("tutoriales")

func _play_level_1() -> void:
	if is_launching_level:
		return
	is_launching_level = true
	
	if btn_play_level1:
		btn_play_level1.pivot_offset = btn_play_level1.size * 0.5
		var punch_tw = create_tween()
		punch_tw.tween_property(btn_play_level1, "scale", Vector2(1.12, 1.12), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		punch_tw.parallel().tween_property(btn_play_level1, "modulate", Color(1.8, 1.8, 2.5, 1.0), 0.12)
		
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("start_level"):
		gm.start_level(gm.get_difficulty_time())
		
	var target_scene = "res://scenes/gameplay/Level1.tscn"
	var mode_title = "TALLER DE HARDWARE 3D"
	var enter_title = "ENTRANDO AL TALLER 3D"
	if current_mode == "sistema":
		target_scene = "res://scenes/gameplay/LevelSystems1.tscn"
		mode_title = "ESTACIÓN DE SISTEMAS"
		enter_title = "ENTRANDO A SISTEMAS 3D"
	elif current_mode == "servidor":
		target_scene = "res://scenes/gameplay/LevelServer1.tscn"
		mode_title = "DATACENTER CORPORATIVO"
		enter_title = "ENTRANDO AL DATACENTER 3D"
	
	CyberPlayTransition.play(
		get_tree(),
		target_scene,
		enter_title,
		"// ACCEDIENDO A EQUIPO #1 · %s //" % mode_title,
		Callable(),
		false,
		false,
		current_mode
	)

# =============================================================================
# CONSTRUCCIÓN Y FILTRADO INSTANTÁNEO DE TARJETAS (REUTILIZACIÓN DE SLOTS, 0 MS)
# =============================================================================
func _filter_tutorial_cards() -> void:
	if not cards_grid:
		return
	var mode_cards: Array[Dictionary] = []
	for c in ALL_TUTORIAL_CARDS:
		var d = c.get("division", "")
		if d == current_mode or (current_mode == "reparacion" and d == "reparacion_fondo"):
			mode_cards.append(c)
			
	# Asegurar que existan suficientes slots para todas las tarjetas del modo
	while _card_slots.size() < mode_cards.size():
		var slot = _create_card_slot()
		cards_grid.add_child(slot)
		_card_slots.append(slot)
			
	for i in range(_card_slots.size()):
		var slot = _card_slots[i]
		if i < mode_cards.size():
			slot.visible = true
			_populate_mini_card(slot, mode_cards[i])
		else:
			slot.visible = false

func _create_card_slot() -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(340, 245)
	btn.flat = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var panel = PanelContainer.new()
	panel.name = "CardPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(panel)
	
	var bg_frame = NinePatchRect.new()
	bg_frame.name = "CyberBg"
	bg_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_frame.texture = PRELOADED_TEXTURES.get("res://pixel art menus/menus/fondos de menus.png")
	bg_frame.material = preload("res://styles/cyber_panel_hologram.tres")
	bg_frame.patch_margin_left = 32
	bg_frame.patch_margin_top = 32
	bg_frame.patch_margin_right = 32
	bg_frame.patch_margin_bottom = 32
	bg_frame.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	bg_frame.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	panel.add_child(bg_frame)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.015, 0.12, 0.55)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 4
	sb.border_width_bottom = 4
	sb.border_color = Color(1.0, 0.15, 0.35, 1.0)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_right = 10
	sb.corner_radius_bottom_left = 4
	panel.add_theme_stylebox_override("panel", sb)
	
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	
	var header_hbox = HBoxContainer.new()
	header_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(header_hbox)
	
	var cat_lbl = Label.new()
	cat_lbl.text = "[ CATEGORÍA ]"
	cat_lbl.add_theme_font_size_override("font_size", 10)
	header_hbox.add_child(cat_lbl)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_hbox.add_child(spacer)
	
	var status_tag = Label.new()
	status_tag.text = "DISPONIBLE"
	status_tag.add_theme_font_size_override("font_size", 10)
	header_hbox.add_child(status_tag)
	
	var preview_box = PanelContainer.new()
	preview_box.custom_minimum_size = Vector2(0, 105)
	preview_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb_inner = StyleBoxFlat.new()
	sb_inner.bg_color = Color(0.04, 0.01, 0.08, 0.8)
	sb_inner.border_width_left = 1
	sb_inner.border_width_top = 1
	sb_inner.border_width_right = 1
	sb_inner.border_width_bottom = 1
	sb_inner.border_color = Color(1.0, 0.15, 0.35, 0.4)
	preview_box.add_theme_stylebox_override("panel", sb_inner)
	vbox.add_child(preview_box)
	
	var tex_rect = TextureRect.new()
	tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tex_rect.material = glitch_material
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_box.add_child(tex_rect)
	
	var lock_lbl = Label.new()
	lock_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lock_lbl.add_theme_color_override("font_color", Color(0.65, 0.5, 0.75, 0.65))
	lock_lbl.add_theme_font_size_override("font_size", 11)
	lock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_box.add_child(lock_lbl)
	
	var title_lbl = Label.new()
	title_lbl.add_theme_font_override("font", title_font)
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	title_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	title_lbl.add_theme_constant_override("outline_size", 6)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(title_lbl)
	
	var hint_lbl = Label.new()
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_font_size_override("font_size", 10)
	hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(hint_lbl)
	
	# Guardar referencias de subnodos para actualización en 0.03 ms
	btn.set_meta("cat_lbl", cat_lbl)
	btn.set_meta("status_tag", status_tag)
	btn.set_meta("sb", sb)
	btn.set_meta("sb_inner", sb_inner)
	btn.set_meta("tex_rect", tex_rect)
	btn.set_meta("lock_lbl", lock_lbl)
	btn.set_meta("title_lbl", title_lbl)
	btn.set_meta("hint_lbl", hint_lbl)
	
	btn.scale = Vector2.ONE
	btn.mouse_entered.connect(func():
		var old_tw = btn.get_meta("hover_tw", null)
		if old_tw and old_tw.is_valid():
			old_tw.kill()
		var tw = create_tween().set_parallel(true)
		btn.set_meta("hover_tw", tw)
		tw.tween_property(panel, "modulate", Color(1.2, 1.25, 1.35, 1.0), 0.12)
		sb.border_width_right = 6
		sb.border_width_bottom = 6
		sb.border_color = Color(1.0, 1.0, 1.0, 1.0)
	)
	btn.mouse_exited.connect(func():
		var old_tw = btn.get_meta("hover_tw", null)
		if old_tw and old_tw.is_valid():
			old_tw.kill()
		var tw = create_tween().set_parallel(true)
		btn.set_meta("hover_tw", tw)
		tw.tween_property(panel, "modulate", Color.WHITE, 0.15)
		sb.border_width_right = 4
		sb.border_width_bottom = 4
		if btn.has_meta("card_data"):
			var d = btn.get_meta("card_data")
			sb.border_color = d.get("color_accent", Color(1, 1, 1))
	)
	
	btn.pressed.connect(func():
		if btn.has_meta("card_data"):
			_open_deployed_card(btn.get_meta("card_data"))
	)
	
	return btn

func _populate_mini_card(btn: Button, data: Dictionary) -> void:
	btn.scale = Vector2.ONE
	var panel = btn.get_node_or_null("CardPanel")
	if panel:
		panel.modulate = Color.WHITE
	btn.set_meta("card_data", data)
	btn.set_meta("division", data["division"])
	
	var cat_lbl: Label = btn.get_meta("cat_lbl")
	cat_lbl.text = "[ %s ]" % data["category"]
	cat_lbl.add_theme_color_override("font_color", data["color_accent"])
	
	var status_tag: Label = btn.get_meta("status_tag")
	status_tag.text = "DISPONIBLE" if data["is_ready"] else "BLOQUEADO 🔒"
	status_tag.add_theme_color_override("font_color", Color(0.2, 1.0, 0.6) if data["is_ready"] else Color(0.7, 0.7, 0.75, 0.6))
	
	var sb: StyleBoxFlat = btn.get_meta("sb")
	sb.border_color = data["color_accent"]
	
	var sb_inner: StyleBoxFlat = btn.get_meta("sb_inner")
	sb_inner.border_color = Color(data["color_accent"].r, data["color_accent"].g, data["color_accent"].b, 0.4)
	
	var tex_rect: TextureRect = btn.get_meta("tex_rect")
	var lock_lbl: Label = btn.get_meta("lock_lbl")
	if data["texture_path"] != "" and PRELOADED_TEXTURES.has(data["texture_path"]):
		tex_rect.texture = PRELOADED_TEXTURES[data["texture_path"]]
		tex_rect.visible = true
		lock_lbl.visible = false
	else:
		tex_rect.visible = false
		if data["is_ready"]:
			lock_lbl.text = "⚡\n[ SIMULADOR DISPONIBLE ]"
			lock_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.6, 0.95))
		else:
			var div_label = "MÓDULO DE SISTEMA" if data["division"] == "sistema" else ("INFRAESTRUCTURA SERVIDOR" if data["division"] == "servidor" else "EN CALIBRACIÓN")
			lock_lbl.text = "[ %s ]\n🔒" % div_label
			lock_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 0.6))
		lock_lbl.visible = true
		
	var title_lbl: Label = btn.get_meta("title_lbl")
	title_lbl.text = data["title"]
	
	var hint_lbl: Label = btn.get_meta("hint_lbl")
	hint_lbl.text = "▶ CLIC PARA DESPLEGAR FICHA" if data["is_ready"] else "▶ CLIC PARA LEER ESPECIFICACIONES"
	hint_lbl.add_theme_color_override("font_color", Color(0.85, 0.4, 0.95, 0.85) if data["is_ready"] else Color(0.6, 0.5, 0.7, 0.6))

# =============================================================================
# MODAL DE TARJETA DESPLEGADA & SIMULADOR
# =============================================================================
func _open_deployed_card(data: Dictionary) -> void:
	active_card_data = data
	
	deployed_title.text = data["title"]
	deployed_title.add_theme_color_override("font_color", data["color_accent"])
	deployed_sub.text = data["subtitle"]
	deployed_badge.text = "[ DIVISIÓN: %s · CATEGORÍA: %s ]" % [data["division"].to_upper(), data["category"]]
	deployed_badge.add_theme_color_override("font_color", data["color_accent"])
	
	if data["texture_path"] != "" and PRELOADED_TEXTURES.has(data["texture_path"]):
		deployed_preview.texture = PRELOADED_TEXTURES[data["texture_path"]]
		deployed_preview.material = glitch_material
		deployed_preview.visible = true
	else:
		deployed_preview.visible = false
		
	lbl_que_es.text = "⚡ ¿QUÉ ES?: %s" % data["que_es"]
	lbl_importancia.text = "🔥 IMPORTANCIA: %s" % data["importancia"]
	lbl_que_hace.text = "⚙️ ¿QUÉ HACE?: %s" % data["que_hace"]
	lbl_pasos.text = "🛠️ MECÁNICA DE SERVICIO / PROCEDIMIENTO:\n%s" % data["pasos"]
	
	if data["is_ready"]:
		deployed_btn_play.text = "⚡ SIMULADOR 2D"
		deployed_btn_play.disabled = false
		deployed_btn_play.modulate = Color(1, 1, 1, 1)
	else:
		deployed_btn_play.text = "🔒 SIMULADOR EN CALIBRACIÓN"
		deployed_btn_play.disabled = true
		deployed_btn_play.modulate = Color(0.6, 0.6, 0.6, 0.7)

	if deployed_btn_tutorial_3d:
		var is_hardware = data.get("division", "") in ["reparacion", "reparacion_fondo"]
		var can_tut_3d = is_hardware and data.get("is_ready", false) and data.get("id", "") != "motherboard"
		deployed_btn_tutorial_3d.visible = can_tut_3d
		if data.get("id", "") == "ram_static":
			deployed_btn_tutorial_3d.text = "🎓 TUTORIAL CON JOA"
		else:
			deployed_btn_tutorial_3d.text = "🎓 TUTORIAL 3D CON JOA"
		
	deployed_modal.visible = true
	deployed_card.scale = Vector2(0.85, 0.85)
	deployed_card.modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(deployed_card, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(deployed_card, "modulate:a", 1.0, 0.18)

func _close_deployed_card() -> void:
	var tw = create_tween().set_parallel(true)
	tw.tween_property(deployed_card, "scale", Vector2(0.85, 0.85), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(deployed_card, "modulate:a", 0.0, 0.12)
	tw.chain().tween_callback(func():
		deployed_modal.visible = false
		active_card_data = {}
	)

func _on_deployed_tutorial_3d_pressed() -> void:
	if active_card_data.is_empty():
		return
	var comp_id = active_card_data.get("id", "general")
	if comp_id == "ram_static":
		_close_deployed_card()
		_play_tutorial_level("ram", "res://scenes/minigames/RAMStaticMinigame.tscn", "TUTORIAL · DESCARGA DE ESTÁTICA RAM")
		return
	_close_deployed_card()
	_play_tutorial_level(comp_id)

func _on_deployed_play_pressed() -> void:
	if active_card_data.is_empty():
		return
		
	if not active_card_data.get("is_ready", false):
		_show_toast("Este simulador estará disponible en la próxima actualización.")
		return
		
	match active_card_data.get("handler", ""):
		"launch_ram_static":
			if not _ram_static_scene:
				_ram_static_scene = load("res://scenes/minigames/RAMStaticMinigame.tscn")
			_launch_minigame(_ram_static_scene)
		"launch_cooler":
			if not _fancooler_scene:
				_fancooler_scene = load("res://scenes/minigames/FanCoolerMinigame.tscn")
			_launch_minigame(_fancooler_scene)
		"launch_ram":
			if not _ram_scene:
				_ram_scene = load("res://scenes/minigames/RAMMinigame.tscn")
			_launch_minigame(_ram_scene)
		"launch_hdd":
			_launch_hdd_with_spares()
		"launch_gpu":
			if not _gpu_scene:
				_gpu_scene = load("res://scenes/minigames/GPUMinigame.tscn")
			_launch_minigame(_gpu_scene)
		"launch_cpu":
			if not _cpu_scene:
				_cpu_scene = load("res://scenes/minigames/CPUMinigame.tscn")
			_launch_minigame(_cpu_scene)
		"launch_thermal_paste":
			if not _cpu_paste_scene:
				_cpu_paste_scene = load("res://scenes/minigames/CPUPasteMinigame.tscn")
			_launch_minigame(_cpu_paste_scene)
		"launch_voltimeter":
			if not _voltimeter_scene:
				_voltimeter_scene = load("res://scenes/minigames/VoltimeterMinigame.tscn")
			_launch_minigame(_voltimeter_scene)
		"launch_cpu_pins":
			if not _cpu_pins_scene:
				_cpu_pins_scene = load("res://scenes/minigames/CPUPinsMinigame.tscn")
			_launch_minigame(_cpu_pins_scene)
		"launch_ram_cleaner":
			_launch_dust_cleaner_component("RAM")
		"launch_dust_cleaner":
			_launch_dust_cleaner_component("Disipador")
		"launch_m2":
			if not _m2_scene:
				_m2_scene = load("res://scenes/minigames/M2Minigame.tscn")
			_launch_minigame(_m2_scene)
		"launch_psu":
			if not _psu_scene:
				_psu_scene = load("res://scenes/minigames/PSUMinigame.tscn")
			_launch_minigame(_psu_scene)
		"launch_mobo":
			if not _mobo_scene:
				_mobo_scene = load("res://scenes/minigames/MotherboardMinigame.tscn")
			_launch_minigame(_mobo_scene)
		"launch_liquid_cooling":
			if not _liquid_cooling_scene:
				_liquid_cooling_scene = load("res://scenes/minigames/LiquidCoolingMinigame.tscn")
			_launch_minigame(_liquid_cooling_scene)
		"launch_adware_cleaner":
			if not _adware_cleaner_scene:
				_adware_cleaner_scene = load("res://scenes/minigames/AdwareCleanerMinigame.tscn")
			_launch_minigame(_adware_cleaner_scene)
		"launch_malware_scan":
			if not _malware_scanner_scene:
				_malware_scanner_scene = load("res://scenes/minigames/MalwareScannerMinigame.tscn")
			_launch_minigame(_malware_scanner_scene)
		"launch_os_install":
			if not _os_install_scene:
				_os_install_scene = load("res://scenes/minigames/OSInstallMinigame.tscn")
			_launch_minigame(_os_install_scene)
		"launch_driver_install":
			if not _driver_updater_scene:
				_driver_updater_scene = load("res://scenes/minigames/DriverUpdaterMinigame.tscn")
			_launch_minigame(_driver_updater_scene)
		"launch_code_debugger":
			if not _code_debugger_scene:
				_code_debugger_scene = load("res://scenes/minigames/CodeDebuggerMinigame.tscn")
			_launch_minigame(_code_debugger_scene)
		"launch_malware_invaders":
			if not _malware_invaders_scene:
				_malware_invaders_scene = load("res://scenes/minigames/MalwareInvadersMinigame.tscn")
			_launch_minigame(_malware_invaders_scene)
		"launch_usb_backup":
			if not _usb_pendrive_scene:
				_usb_pendrive_scene = load("res://scenes/minigames/UsbPendriveMinigame.tscn")
			_launch_minigame(_usb_pendrive_scene)
		"launch_system_connection":
			var conn_scene = load("res://scenes/minigames/SystemConnectionMinigame.tscn")
			_launch_minigame(conn_scene)

func _launch_minigame(scene: PackedScene) -> void:
	if not scene:
		return
	if is_instance_valid(current_minigame_instance):
		current_minigame_instance.queue_free()
		
	var inst = scene.instantiate()
	current_minigame_instance = inst
	minigame_container.add_child(inst)
	
	if has_node("/root/MusicManager"):
		get_node("/root/MusicManager").play_tutorial()
	
	if inst.has_signal("minigame_finished"):
		inst.minigame_finished.connect(_on_minigame_finished)

func _launch_dust_cleaner_component(comp: String) -> void:
	if not _dust_cleaner_scene:
		_dust_cleaner_scene = load("res://scenes/minigames/DustCleanerMinigame.tscn")
	if is_instance_valid(current_minigame_instance):
		current_minigame_instance.queue_free()
		
	var inst = _dust_cleaner_scene.instantiate()
	inst.setup_component(comp)
	current_minigame_instance = inst
	minigame_container.add_child(inst)
	
	if inst.has_signal("minigame_finished"):
		inst.minigame_finished.connect(_on_minigame_finished)

func _launch_hdd_with_spares() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		var has_hdd = false
		for item in gm.backpack:
			if item.get("type", "") == "Disco Duro":
				has_hdd = true
				break
		if not has_hdd and gm.backpack.size() < gm.MAX_BACKPACK_SLOTS:
			gm.backpack.append({"type": "Disco Duro", "functional": true})
			gm.backpack_updated.emit(gm.backpack)
		
	if not _hdd_scene:
		_hdd_scene = load("res://scenes/minigames/HDDMinigame.tscn")
	_launch_minigame(_hdd_scene)

func _on_minigame_finished(_success: bool) -> void:
	if is_instance_valid(current_minigame_instance):
		current_minigame_instance.queue_free()
		current_minigame_instance = null
	if has_node("/root/MusicManager"):
		get_node("/root/MusicManager").stop_music(0.8)
	is_launching_level = false
	_sync_progression_from_save()

func _show_toast(msg: String) -> void:
	var lbl = Label.new()
	lbl.text = msg
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	lbl.add_theme_constant_override("shadow_outline_size", 6)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(size.x * 0.5 - 200, size.y * 0.5 - 20)
	lbl.size = Vector2(400, 40)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 30.0, 0.8).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.8).set_delay(0.4)
	tw.chain().tween_callback(lbl.queue_free)

func _on_volver_pressed() -> void:
	if is_exiting_scene or is_launching_level:
		return
	is_exiting_scene = true
	_play_exit_animation()

func _play_exit_sfx() -> void:
	if not ResourceLoader.exists("res://efectos/sonido de entrada.ogg"):
		return
	var stream = load("res://efectos/sonido de entrada.ogg")
	if stream is AudioStreamOggVorbis:
		stream.loop = false
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = -2.0
	player.pitch_scale = 0.82 # Modulación grave sci-fi de desconexión
	player.bus = "Master"
	if get_tree() and get_tree().root:
		get_tree().root.add_child(player)
	else:
		add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func _play_exit_animation() -> void:
	# 1. Overlay bloqueador interno (hijo directo de self, NUNCA en root para evitar congelamiento)
	var local_blocker = ColorRect.new()
	local_blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	local_blocker.color = Color(0, 0, 0, 0)
	local_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	local_blocker.z_index = 100
	add_child(local_blocker)

	# 2. SFX de desconexión
	_play_exit_sfx()

	# 3. Micro punch en el botón volver
	if btn_volver:
		btn_volver.pivot_offset = btn_volver.size * 0.5
		var tw_btn = create_tween()
		tw_btn.tween_property(btn_volver, "scale", Vector2(0.85, 0.85), 0.08).set_trans(Tween.TRANS_QUAD)
		tw_btn.tween_property(btn_volver, "scale", Vector2.ONE, 0.12)
		tw_btn.parallel().tween_property(btn_volver, "modulate", Color(2.2, 0.3, 0.7, 1.0), 0.08)

	# 4. Coreografía de salida de los elementos de interfaz (animación reactiva)
	var tw_ui = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	# Fade a negro suave del bloqueador
	tw_ui.tween_property(local_blocker, "color", Color(0.02, 0.015, 0.04, 1.0), 0.28)

	# TopBar sube hacia arriba fuera de pantalla
	var top_bar = get_node_or_null("TopBar")
	if top_bar:
		tw_ui.tween_property(top_bar, "position:y", top_bar.position.y - 95.0, 0.28)
		tw_ui.tween_property(top_bar, "modulate:a", 0.0, 0.25)

	# Banner y cabeceras suben
	var banner = get_node_or_null("SectionBanner")
	if banner:
		tw_ui.tween_property(banner, "position:y", banner.position.y - 50.0, 0.26)
		tw_ui.tween_property(banner, "modulate:a", 0.0, 0.24)
	if column_headers:
		tw_ui.tween_property(column_headers, "position:y", column_headers.position.y - 40.0, 0.25)
		tw_ui.tween_property(column_headers, "modulate:a", 0.0, 0.22)

	# FooterHint cae hacia abajo
	if footer_hint:
		tw_ui.tween_property(footer_hint, "position:y", footer_hint.position.y + 55.0, 0.24)
		tw_ui.tween_property(footer_hint, "modulate:a", 0.0, 0.22)

	# HUD de estadísticas abajo a la izquierda se desliza
	if player_stats_hud:
		tw_ui.tween_property(player_stats_hud, "position:y", player_stats_hud.position.y + 60.0, 0.24)
		tw_ui.tween_property(player_stats_hud, "modulate:a", 0.0, 0.22)
	if circular_mode_selector:
		tw_ui.tween_property(circular_mode_selector, "position:x", circular_mode_selector.position.x + 220.0, 0.30)
		tw_ui.tween_property(circular_mode_selector, "modulate:a", 0.0, 0.26)

	# Constelación de niveles: Implosión hacia el centro con rotación
	if constellation_area:
		constellation_area.pivot_offset = _get_mode_center()
		tw_ui.tween_property(constellation_area, "scale", Vector2(0.08, 0.08), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw_ui.tween_property(constellation_area, "rotation", 0.30, 0.28)
		tw_ui.tween_property(constellation_area, "modulate:a", 0.0, 0.25)

	if tutorial_area and tutorial_area.visible:
		tw_ui.tween_property(tutorial_area, "position:y", tutorial_area.position.y + 60.0, 0.28)
		tw_ui.tween_property(tutorial_area, "modulate:a", 0.0, 0.24)

	if map_zoom_controls:
		tw_ui.tween_property(map_zoom_controls, "modulate:a", 0.0, 0.20)

	# 5. Cambio limpio y seguro a MainMenu al completar la transición (sin residuos en root)
	tw_ui.chain().tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")
	)

func _on_constellation_gui_input(event: InputEvent) -> void:
	if is_level_zoomed or current_tab != "niveles" or (deployed_modal and deployed_modal.visible):
		return
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			if event.pressed:
				is_panning_map = true
				pan_start_mouse = get_viewport().get_mouse_position()
				pan_start_area_pos = constellation_area.position if constellation_area else Vector2.ZERO
				accept_event()
			else:
				is_panning_map = false
				accept_event()

func _input(event: InputEvent) -> void:
	if is_exiting_scene or is_launching_level:
		get_viewport().set_input_as_handled()
		return

	# REQUISITO EXPRESO: Ctrl + Shift + R abre la Consola de Comandos de Desarrollador
	if event is InputEventKey and event.pressed and not event.echo:
		if event.ctrl_pressed and event.shift_pressed and (event.keycode == KEY_R or event.physical_keycode == KEY_R):
			get_viewport().set_input_as_handled()
			_toggle_dev_console()
			return

	if dev_console_overlay and dev_console_overlay.visible:
		if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
			if terminal_pacman_instance and terminal_pacman_instance.visible:
				get_viewport().set_input_as_handled()
				terminal_pacman_instance.exit_to_terminal()
				return
			if terminal_tetris_instance and terminal_tetris_instance.visible:
				get_viewport().set_input_as_handled()
				terminal_tetris_instance.exit_to_terminal()
				return
			get_viewport().set_input_as_handled()
			_close_dev_console()
			return
		return
		
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		if deployed_modal and deployed_modal.visible:
			get_viewport().set_input_as_handled()
			_close_deployed_card()
			return
		if is_level_zoomed:
			get_viewport().set_input_as_handled()
			_unzoom_camera()
			return
		get_viewport().set_input_as_handled()
		_on_volver_pressed()
		return
		
	# Navegación entre los 3 modos de juego (Arriba/Abajo o W/S) en la vista general
	if not is_level_zoomed and not (deployed_modal and deployed_modal.visible):
		var is_up: bool = (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_UP or event.physical_keycode == KEY_UP or event.keycode == KEY_W or event.physical_keycode == KEY_W)) \
			or event.is_action_pressed("ui_up")
		var is_down: bool = (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_DOWN or event.physical_keycode == KEY_DOWN or event.keycode == KEY_S or event.physical_keycode == KEY_S)) \
			or event.is_action_pressed("ui_down")
		if is_up:
			get_viewport().set_input_as_handled()
			_cycle_mode(-1)
			return
		elif is_down:
			get_viewport().set_input_as_handled()
			_cycle_mode(1)
			return

	# 1. Rueda del ratón para alejar y acercar la vista del mapa en vista general
	if not is_level_zoomed and current_tab == "niveles" and not (deployed_modal and deployed_modal.visible):
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				get_viewport().set_input_as_handled()
				_adjust_map_zoom(0.08)
				return
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				get_viewport().set_input_as_handled()
				_adjust_map_zoom(-0.08)
				return

	# Atajos de teclado para Zoom: Ctrl + '-' (alejar) y Ctrl + '+' (acercar)
	if not is_level_zoomed and current_tab == "niveles" and not (deployed_modal and deployed_modal.visible):
		if event is InputEventKey and event.pressed and not event.echo and event.ctrl_pressed:
			if event.keycode in [KEY_MINUS, KEY_KP_SUBTRACT] or event.physical_keycode in [KEY_MINUS, KEY_KP_SUBTRACT]:
				get_viewport().set_input_as_handled()
				_adjust_map_zoom(-0.08)
				return
			elif event.keycode in [KEY_PLUS, KEY_EQUAL, KEY_KP_ADD] or event.physical_keycode in [KEY_PLUS, KEY_EQUAL, KEY_KP_ADD]:
				get_viewport().set_input_as_handled()
				_adjust_map_zoom(0.08)
				return

	# 2. Arrastre de mapa libre (Pan) con clic izquierdo (en zona vacía), derecho o central del ratón
	if not is_level_zoomed and current_tab == "niveles" and not (deployed_modal and deployed_modal.visible):
		if event is InputEventMouseButton:
			if not event.pressed and (event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]):
				if is_panning_map:
					is_panning_map = false
					get_viewport().set_input_as_handled()
					return
			elif event.pressed and (event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE):
				is_panning_map = true
				pan_start_mouse = get_viewport().get_mouse_position()
				pan_start_area_pos = constellation_area.position if constellation_area else Vector2.ZERO
				get_viewport().set_input_as_handled()
				return
		elif event is InputEventMouseMotion and is_panning_map:
			if constellation_area:
				var cur_m = get_viewport().get_mouse_position()
				constellation_area.position = pan_start_area_pos + (cur_m - pan_start_mouse)
				_update_node_hitboxes_positions()
				get_viewport().set_input_as_handled()
				return

	# 3. Navegación entre niveles con flechas de teclado o teclas A / D
	if current_tab == "niveles" and not (deployed_modal and deployed_modal.visible):
		var is_left: bool = (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_LEFT or event.physical_keycode == KEY_LEFT or event.keycode == KEY_A or event.physical_keycode == KEY_A)) \
			or event.is_action_pressed("ui_left")
		var is_right: bool = (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_RIGHT or event.physical_keycode == KEY_RIGHT or event.keycode == KEY_D or event.physical_keycode == KEY_D)) \
			or event.is_action_pressed("ui_right")
		if is_left:
			get_viewport().set_input_as_handled()
			if is_level_zoomed:
				_navigate_level_camera(-1)
			else:
				var target_idx = active_zoomed_index if active_zoomed_index >= 0 else 0
				_on_node_clicked(target_idx)
			return
		elif is_right:
			get_viewport().set_input_as_handled()
			if is_level_zoomed:
				_navigate_level_camera(1)
			else:
				var target_idx = active_zoomed_index if active_zoomed_index >= 0 else 0
				_on_node_clicked(target_idx)
			return

# =============================================================================
# SISTEMA DE PROGRESIÓN Y DESBLOQUEO SECUENCIAL (TUTORIAL -> PRÁCTICA -> NIVEL 1)
# =============================================================================
func _sync_progression_from_save() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	var list = LEVELS_DATA.get(current_mode, [])
	for i in range(list.size()):
		var is_unl = false
		if i == 0:
			is_unl = true # Nivel de inducción siempre disponible
		elif sm and sm.has_method("is_node_unlocked"):
			is_unl = sm.is_node_unlocked(current_mode, i)
		else:
			is_unl = (i == 0)
		list[i]["can_play"] = is_unl
		if graph_lines and graph_lines.has_method("set_node_unlocked"):
			graph_lines.set_node_unlocked(i, is_unl)
		var is_comp = false
		if sm and sm.has_method("is_node_completed"):
			is_comp = sm.is_node_completed(current_mode, i)
		if graph_lines and graph_lines.has_method("set_node_completed"):
			graph_lines.set_node_completed(i, is_comp)
	if graph_lines:
		graph_lines.queue_redraw()

func _check_and_play_pending_unlock() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	var just_unl = -1
	if sm and "just_unlocked_node" in sm:
		just_unl = sm.just_unlocked_node
		sm.just_unlocked_node = -1
		
	if just_unl != -1:
		var list = LEVELS_DATA.get(current_mode, [])
		if just_unl < list.size():
			list[just_unl]["can_play"] = true
			if sm and sm.has_method("unlock_node"):
				sm.unlock_node(current_mode, just_unl)
			if graph_lines and graph_lines.has_method("play_unlock_animation"):
				graph_lines.play_unlock_animation(just_unl)
			if just_unl == 7:
				if current_mode == "sistema":
					_show_toast("🏆 ¡ENTRENAMIENTO DE SISTEMAS COMPLETADO! NIVEL 1 DESBLOQUEADO · COMIENZA LA CAMPAÑA")
				else:
					_show_toast("🏆 ¡ENTRENAMIENTO DE HARDWARE COMPLETADO! NIVEL 1 DESBLOQUEADO · COMIENZA LA CAMPAÑA")
			elif just_unl == 25:
				if current_mode == "sistema":
					_show_toast("⚡ ¡TUTORIAL DE BOOT & BIOS SUPERADO! RETO DE PRÁCTICA DESBLOQUEADO")
				else:
					_show_toast("⚡ ¡TUTORIAL DE INDUCCIÓN SUPERADO! RETO DE PRÁCTICA DESBLOQUEADO")
			else:
				_show_toast("⚡ ¡NUEVO RETO DESBLOQUEADO EN EL MAPA!")

func get_player_points() -> int:
	var gm = get_node_or_null("/root/GameManager")
	if gm and "score" in gm:
		return int(gm.score)
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.has_method("get_slot"):
		var slot_data = sm.get_slot(sm.current_slot)
		return int(slot_data.get("score", 0))
	return 0

func get_node_required_points(mode: String, node_idx: int) -> int:
	if node_idx <= 0:
		return 0
	var list = LEVELS_DATA.get(mode, [])
	if node_idx >= list.size():
		return 100 * node_idx
	var data = list[node_idx]
	if data.get("is_tutorial", false):
		var num = data.get("number", node_idx)
		return 50 * max(1, num)
	elif data.get("is_practice", false):
		var num = data.get("number", node_idx)
		return 200 + max(0, (num - 19)) * 50
	elif data.get("is_inspection", false):
		return 100
	else:
		var lvl = data.get("level_number", data.get("number", 1))
		return 100 * max(1, lvl)

func get_previous_node_index(mode: String, node_idx: int) -> int:
	if node_idx <= 0:
		return -1
	var sm = get_node_or_null("/root/SaveManager")
	if mode == "servidor":
		if node_idx in [1, 14]:
			return 0
		elif node_idx == 15:
			return 1
		elif node_idx == 16:
			return 6
		elif node_idx == 17:
			return 5
		return node_idx - 1
	# Modo reparacion y sistema:
	if node_idx in [26, 27]:
		return 7 # Depende del Nivel 1 de campaña
	elif node_idx == 28:
		return 10 # Depende del Nivel 4 de campaña
	elif node_idx == 29:
		return 13 # Depende del Nivel 7 de campaña
	elif node_idx in [30, 31]:
		return 12 # Depende del Nivel 6 de campaña
	elif node_idx == 7: # Nivel 1 de campaña
		if sm and sm.is_node_completed(mode, 6):
			return 6
		return 0
	elif node_idx == 19: # Práctica 1
		if sm and sm.is_node_completed(mode, 25):
			return 25
		elif sm and sm.is_node_completed(mode, 1):
			return 1
		return 0
	elif node_idx == 25: # Práctica Intro
		return 0
	else:
		return node_idx - 1

func is_previous_level_completed(mode: String, node_idx: int) -> bool:
	if node_idx <= 0:
		return true
	var sm = get_node_or_null("/root/SaveManager")
	if not sm or not sm.has_method("is_node_completed"):
		return true
	if mode == "servidor":
		if node_idx in [1, 14]:
			return true
		elif node_idx == 15:
			return sm.is_node_completed(mode, 1) or sm.is_node_completed(mode, 14)
		elif node_idx == 16:
			return sm.is_node_completed(mode, 4) or sm.is_node_completed(mode, 6) or sm.is_node_completed(mode, 15)
		elif node_idx == 17:
			return sm.is_node_completed(mode, 5) or sm.is_node_completed(mode, 8) or sm.is_node_completed(mode, 16)
		return sm.is_node_completed(mode, node_idx - 1)
	if node_idx in [26, 27]:
		return sm.is_node_completed(mode, 7) # Nivel 1 completado
	elif node_idx == 28:
		return sm.is_node_completed(mode, 10) # Nivel 4 completado
	elif node_idx == 29:
		return sm.is_node_completed(mode, 13) # Nivel 7 completado
	elif node_idx in [30, 31]:
		return sm.is_node_completed(mode, 12) # Nivel 6 completado
	elif node_idx == 7:
		return sm.is_node_completed(mode, 0) or sm.is_node_completed(mode, 6)
	elif node_idx == 19:
		return sm.is_node_completed(mode, 25) or sm.is_node_completed(mode, 1) or sm.is_node_completed(mode, 0)
	elif node_idx == 25:
		return sm.is_node_completed(mode, 0)
	else:
		return sm.is_node_completed(mode, node_idx - 1)

func _on_level_unlock_requested(node_data: Dictionary) -> void:
	var node_idx = node_data.get("node_index", active_zoomed_index)
	if node_idx < 0:
		return
	
	if not is_previous_level_completed(current_mode, node_idx):
		_show_toast("🔒 Debes completar el nivel anterior para desbloquear.")
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("play_sfx"):
			gm.play_sfx("error")
		return
		
	var req_points = get_node_required_points(current_mode, node_idx)
	var player_points = get_player_points()
	if player_points < req_points:
		_show_toast("⚠️ Puntos insuficientes (%d / %d)." % [player_points, req_points])
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("play_sfx"):
			gm.play_sfx("error")
		return
		
	# REQUISITO CLAVE: Los puntos NO se gastan pero el nivel sí se desbloquea
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.has_method("unlock_node"):
		sm.unlock_node(current_mode, node_idx)
		
	var list = LEVELS_DATA.get(current_mode, [])
	if node_idx < list.size():
		list[node_idx]["can_play"] = true
		node_data["can_play"] = true
		
	if graph_lines and graph_lines.has_method("play_unlock_animation"):
		graph_lines.play_unlock_animation(node_idx)
		
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("play_sfx"):
		gm.play_sfx("success")
		
	_show_toast("🔓 ¡Nivel desbloqueado con éxito! Tus puntos se conservan intactos.")
	
	# Refrescar el panel abierto de inmediato para pasar al botón de iniciar nivel
	if node_data.get("is_practice", false):
		if tutorial_info_panel:
			tutorial_info_panel.open_for_practice(node_data, req_points, player_points, true)
	elif node_data.get("is_tutorial", false):
		if tutorial_info_panel:
			tutorial_info_panel.open_for_tutorial_node(node_data, req_points, player_points, true)
		if tutorial_info_panel:
			tutorial_info_panel.open_for_practice(node_data, req_points, player_points, true)
	else:
		if difficulty_selector:
			difficulty_selector.open_for_level(node_data, req_points, player_points, true)

# =============================================================================
# CONSOLA DE DESARROLLADOR // ANDROMEDA OS TERMINAL (CTRL + SHIFT + R & /levels)
# =============================================================================
const ANDROMEDA_BANNER_TEXT: String = """[color=#00e5ff]       /\\         [/color]  [color=#00e5ff][b]user@andromeda[/b][/color]
[color=#00e5ff]      /  \\        [/color]  [color=#6272a4]-------------------------[/color]
[color=#00e5ff]     / /\\ \\       [/color]  [color=#00e5ff]OS:[/color] Andromeda OS v2.5 (Cyber Linux)
[color=#00e5ff]    / ____ \\      [/color]  [color=#00e5ff]Host:[/color] Computer Technician 3D Workstation
[color=#00e5ff]   /_/    \\_\\     [/color]  [color=#00e5ff]Kernel:[/color] 2.5.0-andromeda-core
                    [color=#00e5ff]Uptime:[/color] 42 mins
                    [color=#00e5ff]Packages:[/color] 1337 (andromeda-pkg)
                    [color=#00e5ff]Shell:[/color] andromeda-sh / zsh
                    [color=#00e5ff]Terminal:[/color] Andromeda CyberTerminal
                    [color=#00e5ff]CPU:[/color] Andromeda Quantum Core (32) @ 5.70GHz
                    [color=#00e5ff]GPU:[/color] NVIDIA GeForce RTX 4090 24GB
                    [color=#00e5ff]Memory:[/color] 32768MiB / 65536MiB

[color=#50fa7b]user@andromeda[/color]:[color=#00e5ff]~[/color]$ [color=#f8f8f2]systemctl status andromeda-kernel.service[/color]
[color=#50fa7b]● andromeda-kernel.service - Andromeda OS Core Engine[/color]
   Loaded: loaded (/etc/systemd/system/andromeda-kernel.service; enabled)
   Active: [color=#50fa7b]active (running)[/color] since Mon 2026-11-17 02:30:00 UTC

[color=#f1fa8c]💡 Comandos disponibles en Andromeda OS:[/color]
  [color=#bd93f9]magnifying glass- skip[/color]               : Desbloquea todos los niveles morados de micro-taller y lupa
  [color=#f1fa8c]andro install pacman[/color]                 : Instala y ejecuta el clásico arcade retro Pac-Man en la terminal
  [color=#f1fa8c]andro install tetris[/color]                 : Instala y ejecuta el clásico arcade retro Tetris en la terminal
  [color=#00e5ff]/tutorials-skip[/color]                      : Completa y desbloquea todos los tutoriales en los 3 modos
  [color=#00e5ff]/practice-skip[/color]                       : Completa y desbloquea todas las prácticas en los 3 modos
  [color=#00e5ff]/actuallylevelskip-nextlevelunlocked[/color] : Desbloquea el siguiente nivel con animación en los 3 modos
  [color=#00e5ff]/levels[/color]   (o [color=#50fa7b]andromeda unlock[/color] / [color=#50fa7b]pacman -S levels[/color]) : Desbloquea todos los niveles y modos
  [color=#00e5ff]/reset[/color]    (o [color=#ff5555]andromeda reset[/color] / [color=#ff5555]pacman -R all[/color])     : Restablece progreso al estado inicial
  [color=#00e5ff]/neofetch[/color] (o [color=#50fa7b]fastfetch[/color])                                : Muestra el logo y specs de Andromeda OS
  [color=#00e5ff]/clear[/color]    (o [color=#50fa7b]clear[/color])                                    : Limpia la terminal
  [color=#00e5ff]/help[/color]     (o [color=#50fa7b]man[/color])                                      : Manual de comandos
  [color=#00e5ff]/exit[/color]     (o [color=#ff5555]exit[/color])                                     : Cerrar terminal
"""

func _close_dev_console() -> void:
	if is_instance_valid(terminal_tetris_instance):
		terminal_tetris_instance.exit_to_terminal()
		terminal_tetris_instance.queue_free()
		terminal_tetris_instance = null
	if is_instance_valid(terminal_pacman_instance):
		terminal_pacman_instance.exit_to_terminal()
		terminal_pacman_instance.queue_free()
		terminal_pacman_instance = null
	if dev_console_body_vbox:
		dev_console_body_vbox.visible = true
	if dev_console_overlay:
		dev_console_overlay.visible = false
	if dev_console_input:
		dev_console_input.release_focus()
	var cur_f = get_viewport().gui_get_focus_owner()
	if cur_f:
		cur_f.release_focus()
	if not is_level_zoomed:
		_fade_menu_chrome(true)

func _toggle_dev_console() -> void:
	if not dev_console_overlay:
		_build_dev_console()
	if dev_console_overlay.visible:
		_close_dev_console()
	else:
		dev_console_overlay.visible = true
		var sm = get_node_or_null("/root/SaveManager")
		if sm:
			sm.unlock_achievement("terminal")
		if dev_console_input:
			dev_console_input.text = ""
			dev_console_input.grab_focus()

func _build_dev_console() -> void:
	dev_console_overlay = Control.new()
	dev_console_overlay.name = "DevConsoleOverlay"
	dev_console_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	dev_console_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	dev_console_overlay.z_index = 100
	dev_console_overlay.visible = false
	
	# Fondo oscurecido con leve traslúcido
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.06, 0.85)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dev_console_overlay.add_child(dim)
	
	# Ventana principal Andromeda CyberTerminal
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(780, 480)
	panel.position = Vector2((1280 - 780) * 0.5, (720 - 480) * 0.5)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.08, 0.13, 0.97) # Andromeda Dark Slate
	sb.border_color = Color(0.0, 0.88, 1.0, 0.95) # Andromeda Cyan (#00e5ff)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.shadow_color = Color(0.0, 0.88, 1.0, 0.28)
	sb.shadow_size = 24
	panel.add_theme_stylebox_override("panel", sb)
	dev_console_overlay.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)
	
	# Barra de título de ventana de Linux/Unix
	var titlebar = PanelContainer.new()
	var sb_tb = StyleBoxFlat.new()
	sb_tb.bg_color = Color(0.03, 0.05, 0.09, 1.0)
	sb_tb.corner_radius_top_left = 6
	sb_tb.corner_radius_top_right = 6
	titlebar.add_theme_stylebox_override("panel", sb_tb)
	
	var tb_margin = MarginContainer.new()
	tb_margin.add_theme_constant_override("margin_left", 12)
	tb_margin.add_theme_constant_override("margin_top", 8)
	tb_margin.add_theme_constant_override("margin_right", 12)
	tb_margin.add_theme_constant_override("margin_bottom", 8)
	titlebar.add_child(tb_margin)
	
	var hbox_tb = HBoxContainer.new()
	hbox_tb.add_theme_constant_override("separation", 8)
	tb_margin.add_child(hbox_tb)
	
	# Botones redondos de ventana: Rojo, Amarillo, Verde
	var dot_red = ColorRect.new()
	dot_red.custom_minimum_size = Vector2(12, 12)
	dot_red.color = Color(1.0, 0.35, 0.35)
	hbox_tb.add_child(dot_red)
	
	var dot_yellow = ColorRect.new()
	dot_yellow.custom_minimum_size = Vector2(12, 12)
	dot_yellow.color = Color(1.0, 0.75, 0.2)
	hbox_tb.add_child(dot_yellow)
	
	var dot_green = ColorRect.new()
	dot_green.custom_minimum_size = Vector2(12, 12)
	dot_green.color = Color(0.3, 0.85, 0.4)
	hbox_tb.add_child(dot_green)
	
	var title_spacer = Control.new()
	title_spacer.custom_minimum_size = Vector2(14, 0)
	hbox_tb.add_child(title_spacer)
	
	var lbl_title = Label.new()
	lbl_title.text = "⚡ andromeda-os: ~/kernel (terminal - 80x24)"
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.add_theme_color_override("font_color", Color(0.0, 0.88, 1.0)) # Andromeda Cyan
	lbl_title.add_theme_font_size_override("font_size", 12)
	hbox_tb.add_child(lbl_title)
	
	var btn_close = Button.new()
	btn_close.text = " [ ✕ ] "
	btn_close.flat = true
	btn_close.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
	btn_close.pressed.connect(func(): _close_dev_console())
	hbox_tb.add_child(btn_close)
	vbox.add_child(titlebar)
	
	# Contenido de la terminal
	var margin_body = MarginContainer.new()
	margin_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin_body.add_theme_constant_override("margin_left", 14)
	margin_body.add_theme_constant_override("margin_top", 10)
	margin_body.add_theme_constant_override("margin_right", 14)
	margin_body.add_theme_constant_override("margin_bottom", 12)
	vbox.add_child(margin_body)
	dev_console_margin_body = margin_body
	
	var body_vbox = VBoxContainer.new()
	body_vbox.add_theme_constant_override("separation", 8)
	margin_body.add_child(body_vbox)
	dev_console_body_vbox = body_vbox
	
	dev_console_output = RichTextLabel.new()
	dev_console_output.bbcode_enabled = true
	dev_console_output.scroll_following = true
	dev_console_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dev_console_output.add_theme_color_override("default_color", Color(0.9, 0.92, 0.95))
	dev_console_output.add_theme_font_size_override("normal_font_size", 11)
	dev_console_output.text = ANDROMEDA_BANNER_TEXT
	body_vbox.add_child(dev_console_output)
	
	var hbox_in = HBoxContainer.new()
	hbox_in.add_theme_constant_override("separation", 6)
	
	var prompt_user = Label.new()
	prompt_user.text = "user@andromeda:"
	prompt_user.add_theme_color_override("font_color", Color(0.31, 0.98, 0.48)) # Green
	prompt_user.add_theme_font_size_override("font_size", 12)
	hbox_in.add_child(prompt_user)
	
	var prompt_dir = Label.new()
	prompt_dir.text = "~$ "
	prompt_dir.add_theme_color_override("font_color", Color(0.0, 0.88, 1.0)) # Andromeda Cyan
	prompt_dir.add_theme_font_size_override("font_size", 12)
	hbox_in.add_child(prompt_dir)
	
	dev_console_input = LineEdit.new()
	dev_console_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dev_console_input.placeholder_text = "andromeda unlock (o escribe /levels)..."
	dev_console_input.text_submitted.connect(_on_dev_command_submitted)
	dev_console_input.caret_blink = true
	var sb_input = StyleBoxFlat.new()
	sb_input.bg_color = Color(0.03, 0.05, 0.08, 0.85)
	sb_input.border_color = Color(0.0, 0.88, 1.0, 0.6)
	sb_input.border_width_left = 1
	sb_input.border_width_top = 1
	sb_input.border_width_right = 1
	sb_input.border_width_bottom = 1
	sb_input.corner_radius_top_left = 4
	sb_input.corner_radius_top_right = 4
	sb_input.corner_radius_bottom_left = 4
	sb_input.corner_radius_bottom_right = 4
	dev_console_input.add_theme_stylebox_override("normal", sb_input)
	dev_console_input.add_theme_stylebox_override("focus", sb_input)
	dev_console_input.add_theme_color_override("font_color", Color(0.97, 0.97, 0.95))
	hbox_in.add_child(dev_console_input)
	
	var btn_exec = Button.new()
	btn_exec.text = " EJECUTAR "
	btn_exec.pressed.connect(func(): _on_dev_command_submitted(dev_console_input.text))
	var sb_btn = StyleBoxFlat.new()
	sb_btn.bg_color = Color(0.0, 0.55, 0.75, 0.9)
	sb_btn.corner_radius_top_left = 4
	sb_btn.corner_radius_top_right = 4
	sb_btn.corner_radius_bottom_left = 4
	sb_btn.corner_radius_bottom_right = 4
	btn_exec.add_theme_stylebox_override("normal", sb_btn)
	hbox_in.add_child(btn_exec)
	body_vbox.add_child(hbox_in)
	
	add_child(dev_console_overlay)

func _on_dev_command_submitted(cmd: String) -> void:
	if not dev_console_overlay:
		_build_dev_console()
	var text_in = cmd.strip_edges()
	if dev_console_input:
		dev_console_input.text = ""
	if text_in == "":
		return
	
	_print_dev_console("\n[color=#50fa7b]user@andromeda[/color]:[color=#00e5ff]~[/color]$ [color=#f8f8f2]" + text_in + "[/color]")
	var lower = text_in.to_lower()
	
	if lower in ["magnifying glass- skip", "magnifying glass - skip", "magnifying-glass-skip", "magnifying glass skip", "/magnifying-glass-skip", "/magnifying glass- skip", "/magnifying-glass", "magnifying-glass", "magnifying glass"]:
		_cmd_magnifying_glass_skip()
	elif lower in ["andro install pacman", "andromeda install pacman", "pacman -s pacman", "sudo pacman -s pacman", "pacman", "./pacman"]:
		_cmd_andro_install_pacman()
	elif lower in ["andro install tetris", "andromeda install tetris", "pacman -s tetris", "sudo pacman -s tetris", "tetris", "./tetris"]:
		_cmd_andro_install_tetris()
	elif lower in ["/tutorials-skip", "tutorials-skip", "/tutorial-skip", "tutorial-skip"]:
		_cmd_tutorials_skip()
	elif lower in ["/practice-skip", "practice-skip", "/practices-skip", "practices-skip"]:
		_cmd_practice_skip()
	elif lower in ["/actuallylevelskip-nextlevelunlocked", "actuallylevelskip-nextlevelunlocked", "/level-skip", "/levelskip"]:
		_cmd_actually_level_skip()
	elif lower in ["/levels", "/desbloquear", "levels", "andromeda unlock", "pacman -s levels", "pacman -s all-levels", "pacman -syu"]:
		_cmd_unlock_all_levels()
	elif lower in ["/reset", "reset", "andromeda reset", "pacman -r progression", "pacman -r all"]:
		_cmd_reset_locks()
	elif lower in ["/neofetch", "neofetch", "fastfetch"]:
		_print_dev_console(ANDROMEDA_BANNER_TEXT)
	elif lower in ["/help", "help", "man"]:
		_print_dev_console("""[color=#00e5ff]ANDROMEDA OS UTILITY MANUAL (8)[/color]
[color=#6272a4]==============================[/color]
[b]NOMBRE[/b]
  levels - Desbloqueador de progresión y utilidades de Computer Technician 3D

[b]SINOPSIS[/b]
  [color=#bd93f9]magnifying glass- skip[/color]               Desbloquea todos los niveles morados de inspección y micro-taller (26 al 31).
  [color=#f1fa8c]andro install pacman[/color]                 Instala y ejecuta el clásico arcade Pac-Man (1980) en la terminal.
  [color=#f1fa8c]andro install tetris[/color]                 Instala y ejecuta el clásico arcade Tetris (1984) en la terminal.
  [color=#00e5ff]/tutorials-skip[/color]                      Completa y desbloquea todos los tutoriales en los 3 modos.
  [color=#00e5ff]/practice-skip[/color]                       Completa y desbloquea todas las prácticas en los 3 modos.
  [color=#00e5ff]/actuallylevelskip-nextlevelunlocked[/color]  Desbloquea el siguiente nivel de campaña con animación
                                         en los 3 modos (Reparación, Sistemas y Servidor).
  [color=#00e5ff]/levels[/color]                               Desbloquea instantáneamente todos los niveles.
  [color=#00e5ff]/reset[/color]                                Restaura la progresión al estado inicial.
  [color=#00e5ff]/neofetch[/color]                             Muestra información del sistema Andromeda OS.
  [color=#00e5ff]/clear[/color]                                Limpia el búfer de la terminal.
  [color=#00e5ff]/exit[/color]                                 Cierra la ventana de la terminal.

[b]COMANDOS ALTERNATIVOS[/b]
  [color=#50fa7b]andromeda unlock[/color]   (o pacman -S levels)
  [color=#ff5555]andromeda reset[/color]    (o pacman -R all)
  [color=#f1fa8c]pacman[/color]             (ejecuta directamente el minijuego instalado)
  [color=#f1fa8c]tetris[/color]             (ejecuta directamente Tetris arcade instalado)""")
	elif lower in ["/clear", "clear"]:
		if dev_console_output:
			dev_console_output.text = ""
	elif lower in ["/exit", "exit", "quit", ":q"]:
		_close_dev_console()
	else:
		_print_dev_console("[color=#ff5555]andromeda-sh: command not found: " + text_in + "[/color]\n[color=#aaaaaa]Escribe [b]/levels[/b] o [b]/help[/b] para ver las opciones disponibles.[/color]")

func _print_dev_console(msg: String) -> void:
	if dev_console_output:
		dev_console_output.append_text(msg + "\n")

func _cmd_magnifying_glass_skip() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	var purple_nodes = [26, 27, 28, 29, 30, 31]
	for idx in purple_nodes:
		if sm and sm.has_method("unlock_node"):
			sm.unlock_node("reparacion", idx)
			sm.unlock_node("sistema", idx)
		if idx < LEVELS_DATA["reparacion"].size():
			LEVELS_DATA["reparacion"][idx]["can_play"] = true
		if idx < LEVELS_DATA["sistema"].size():
			LEVELS_DATA["sistema"][idx]["can_play"] = true
			
	if sm:
		sm.just_unlocked_node = 26
	_sync_progression_from_save()
	
	# Cambiar a modo reparación si estábamos en otro para mostrar los satélites morados
	if current_mode != "reparacion":
		_switch_mode("reparacion", 0)
	
	# Cerrar terminal para mostrar animación en la constelación
	_close_dev_console()
		
	if graph_lines and graph_lines.has_method("play_unlock_animation"):
		graph_lines.play_unlock_animation(26)
		
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("play_sfx"):
		gm.play_sfx("success")
		
	_show_toast("🔍 [MAGNIFYING GLASS] ¡Niveles morados de inspección y micro-taller desbloqueados!")
	_print_dev_console("""[color=#bd93f9]:: MÓDULO MICRO-INSPECCIÓN TÉCNICA ACTIVADO[/color]
[color=#bd93f9]✓ [MAGNIFYING GLASS] Niveles morados (26 al 31: Lupa y Micro-Taller) desbloqueados exitosamente.[/color]
  [26] Limpieza de Polvo en RAM
  [27] Descarga de Estática en RAM
  [28] Renovación Pasta Térmica CPU
  [29] Alineación de Pines CPU
  [30] Medición de Voltaje y Multímetro
  [31] Limpieza Profunda Fuente de Poder PSU""")

func _cmd_andro_install_pacman() -> void:
	_print_dev_console("""[color=#00e5ff]:: Sincronizando repositorios de Andromeda OS...[/color]
[color=#50fa7b]andromeda-core[/color]        [####################################] 100% (14.2 MiB/s)
[color=#50fa7b]andromeda-extra[/color]       [####################################] 100% ( 9.8 MiB/s)
[color=#50fa7b]andromeda-arcade[/color]      [####################################] 100% ( 6.4 MiB/s)
[color=#00e5ff]:: Resolviendo dependencias para 'pacman-arcade-1980'...[/color]
   Dependencias: libncurses-dev, retro-crt-vga, chiptune-synth
[color=#00e5ff]:: Procediendo con la instalación de paquetes (1):[/color]
   pacman-arcade-1980-1.0.4-1-x86_64  [color=#50fa7b]512.4 KiB[/color]
(1/1) Verificando integridad de paquetes     [####################] 100%
(1/1) Desempaquetando archivos en /usr/bin/pacman [################] 100%
(1/1) Configurando emulador VT100 / ANSI Arcade   [################] 100%
[color=#50fa7b]✓ ¡PAC-MAN (Namco 1980 Arcade Terminal Edition) instalado y listo![/color]
[color=#f1fa8c]:: Iniciando emulador arcade en el búfer de la terminal...[/color]""")

	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("play_sfx"):
		gm.play_sfx("success")
		
	get_tree().create_timer(0.8).timeout.connect(func():
		_launch_terminal_pacman()
	)

func _launch_terminal_pacman() -> void:
	if not dev_console_margin_body:
		return
	if not terminal_pacman_instance:
		var PacmanScript = load("res://scripts/minigames/TerminalPacman.gd")
		if PacmanScript:
			terminal_pacman_instance = PacmanScript.new()
			terminal_pacman_instance.name = "TerminalPacmanGame"
			terminal_pacman_instance.closed.connect(_on_terminal_pacman_closed)
			dev_console_margin_body.add_child(terminal_pacman_instance)
	
	if dev_console_body_vbox:
		dev_console_body_vbox.visible = false
	if terminal_pacman_instance:
		terminal_pacman_instance.visible = true
		terminal_pacman_instance._reset_game_full()

func _on_terminal_pacman_closed(final_score: int) -> void:
	if is_instance_valid(terminal_pacman_instance):
		terminal_pacman_instance.visible = false
		terminal_pacman_instance.set_process(false)
		terminal_pacman_instance.set_process_input(false)
		terminal_pacman_instance.queue_free()
		terminal_pacman_instance = null
	if dev_console_body_vbox:
		dev_console_body_vbox.visible = true
	_print_dev_console("[color=#50fa7b]user@andromeda[/color]:[color=#00e5ff]~[/color]$ [color=#aaaaaa]# Sesión arcade de Pacman finalizada.[/color]")
	_print_dev_console("[color=#f1fa8c]🕹️ Puntuación obtenida: [b]%d[/b] puntos. Escribe [b]pacman[/b] o [b]andro install pacman[/b] para jugar de nuevo.[/color]" % final_score)
	if dev_console_input:
		dev_console_input.grab_focus()

func _cmd_andro_install_tetris() -> void:
	_print_dev_console("""[color=#00e5ff]:: Sincronizando repositorios de Andromeda OS...[/color]
[color=#50fa7b]andromeda-core[/color]        [####################################] 100% (14.2 MiB/s)
[color=#50fa7b]andromeda-extra[/color]       [####################################] 100% ( 9.8 MiB/s)
[color=#50fa7b]andromeda-arcade[/color]      [####################################] 100% ( 6.4 MiB/s)
[color=#00e5ff]:: Resolviendo dependencias para 'tetris-arcade-1984'...[/color]
   Dependencias: libncurses-dev, retro-crt-vga, chiptune-synth
[color=#00e5ff]:: Procediendo con la instalación de paquetes (1):[/color]
   tetris-arcade-1984-2.1.0-1-x86_64  [color=#50fa7b]628.0 KiB[/color]
(1/1) Verificando integridad de paquetes     [####################] 100%
(1/1) Desempaquetando archivos en /usr/bin/tetris [################] 100%
(1/1) Configurando emulador VT100 / ANSI Arcade   [################] 100%
[color=#50fa7b]✓ ¡TETRIS (Alexey Pajitnov 1984 Arcade Terminal Edition) instalado y listo![/color]
[color=#f1fa8c]:: Iniciando emulador arcade en el búfer de la terminal...[/color]""")

	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("play_sfx"):
		gm.play_sfx("success")
		
	get_tree().create_timer(0.8).timeout.connect(func():
		_launch_terminal_tetris()
	)

func _launch_terminal_tetris() -> void:
	if not dev_console_margin_body:
		return
	if is_instance_valid(terminal_tetris_instance):
		terminal_tetris_instance.queue_free()
		terminal_tetris_instance = null
	var TetrisScript = load("res://scripts/minigames/TerminalTetris.gd")
	if TetrisScript:
		terminal_tetris_instance = TetrisScript.new()
		terminal_tetris_instance.name = "TerminalTetrisGame"
		terminal_tetris_instance.closed.connect(_on_terminal_tetris_closed)
		dev_console_margin_body.add_child(terminal_tetris_instance)
	
	if dev_console_body_vbox:
		dev_console_body_vbox.visible = false
	if terminal_tetris_instance:
		terminal_tetris_instance.visible = true
		terminal_tetris_instance._reset_game_full()

func _on_terminal_tetris_closed(final_score: int) -> void:
	if is_instance_valid(terminal_tetris_instance):
		terminal_tetris_instance.visible = false
		terminal_tetris_instance.set_process(false)
		terminal_tetris_instance.set_process_input(false)
		terminal_tetris_instance.queue_free()
		terminal_tetris_instance = null
	if dev_console_body_vbox:
		dev_console_body_vbox.visible = true
	_print_dev_console("[color=#50fa7b]user@andromeda[/color]:[color=#00e5ff]~[/color]$ [color=#aaaaaa]# Sesión arcade de Tetris finalizada.[/color]")
	_print_dev_console("[color=#f1fa8c]🕹️ Puntuación obtenida: [b]%d[/b] puntos. Escribe [b]tetris[/b] o [b]andro install tetris[/b] para jugar de nuevo.[/color]" % final_score)
	if dev_console_input:
		dev_console_input.grab_focus()

func _cmd_tutorials_skip() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if not sm:
		return
	
	# 1. Modo Reparación: Nodos 0 a 6 (Tutoriales)
	for i in range(7):
		sm.mark_node_completed("reparacion", i)
		sm.unlock_node("reparacion", i)
		if i < LEVELS_DATA["reparacion"].size():
			LEVELS_DATA["reparacion"][i]["can_play"] = true
			
	# Desbloquear automáticamente el primer nivel de práctica (Nodo 25 y 19)
	sm.unlock_node("reparacion", 25)
	if 25 < LEVELS_DATA["reparacion"].size():
		LEVELS_DATA["reparacion"][25]["can_play"] = true
	sm.unlock_node("reparacion", 19)
	if 19 < LEVELS_DATA["reparacion"].size():
		LEVELS_DATA["reparacion"][19]["can_play"] = true
			
	# 2. Modo Sistema: Nodos 0 a 6 (Tutoriales)
	for i in range(7):
		sm.mark_node_completed("sistema", i)
		sm.unlock_node("sistema", i)
		if i < LEVELS_DATA["sistema"].size():
			LEVELS_DATA["sistema"][i]["can_play"] = true
			
	# Desbloquear automáticamente el primer nivel de práctica en Sistemas
	sm.unlock_node("sistema", 25)
	if 25 < LEVELS_DATA["sistema"].size():
		LEVELS_DATA["sistema"][25]["can_play"] = true
	sm.unlock_node("sistema", 19)
	if 19 < LEVELS_DATA["sistema"].size():
		LEVELS_DATA["sistema"][19]["can_play"] = true
			
	# 3. Modo Servidor: Nodo 0 (Tutorial)
	sm.mark_node_completed("servidor", 0)
	sm.unlock_node("servidor", 0)
	if 0 < LEVELS_DATA["servidor"].size():
		LEVELS_DATA["servidor"][0]["can_play"] = true
		
	# Desbloquear automáticamente el primer nivel de práctica en Servidor (Nodo 13)
	sm.unlock_node("servidor", 13)
	if 13 < LEVELS_DATA["servidor"].size():
		LEVELS_DATA["servidor"][13]["can_play"] = true
		
	if sm:
		sm.just_unlocked_node = 25
	_sync_progression_from_save()
	
	# Cerrar terminal para mostrar animación en la constelación
	_close_dev_console()
		
	var anim_node = 25 if current_mode != "servidor" else 13
	if graph_lines and graph_lines.has_method("play_unlock_animation"):
		graph_lines.play_unlock_animation(anim_node)
		
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("play_sfx"):
		gm.play_sfx("success")
		
	_show_toast("🎓 [TUTORIALS SKIP] ¡Tutoriales completados! Primer nivel de práctica desbloqueado automáticamente.")
	_print_dev_console("[color=#50fa7b]✓ [TUTORIALS SKIP] Todos los tutoriales completados y primer nivel de práctica desbloqueado con animación en los 3 modos.[/color]")

func _cmd_practice_skip() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if not sm:
		return
		
	# CONDICIÓN 1: Todos los tutoriales deben de haberse terminado primero
	var tuts_ok = true
	for i in range(7):
		if not sm.is_node_completed("reparacion", i) or not sm.is_node_completed("sistema", i):
			tuts_ok = false
			break
	if not sm.is_node_completed("servidor", 0):
		tuts_ok = false
		
	if not tuts_ok:
		_show_toast("⚠️ Debes completar todos los tutoriales antes de usar /practice-skip.")
		_print_dev_console("[color=#ff5555]Error: No se puede ejecutar /practice-skip. Todos los tutoriales deben haberse completado primero (usa /tutorials-skip o juégalos primero).[/color]")
		var gm_err = get_node_or_null("/root/GameManager")
		if gm_err and gm_err.has_method("play_sfx"):
			gm_err.play_sfx("error")
		return
		
	# Completar y desbloquear todas las prácticas en los 3 modos
	var practice_rep_sis = [25, 19, 20, 21, 22, 23, 24]
	for idx in practice_rep_sis:
		# Reparación
		sm.mark_node_completed("reparacion", idx)
		sm.unlock_node("reparacion", idx)
		if idx < LEVELS_DATA["reparacion"].size():
			LEVELS_DATA["reparacion"][idx]["can_play"] = true
		# Sistema
		sm.mark_node_completed("sistema", idx)
		sm.unlock_node("sistema", idx)
		if idx < LEVELS_DATA["sistema"].size():
			LEVELS_DATA["sistema"][idx]["can_play"] = true
			
	# Servidor: Nodo 13
	sm.mark_node_completed("servidor", 13)
	sm.unlock_node("servidor", 13)
	if 13 < LEVELS_DATA["servidor"].size():
		LEVELS_DATA["servidor"][13]["can_play"] = true
		
	# CONDICIÓN 2: El primer nivel (Nivel 1) se desbloquea automáticamente en los 3 modos
	sm.unlock_node("reparacion", 7)
	if 7 < LEVELS_DATA["reparacion"].size():
		LEVELS_DATA["reparacion"][7]["can_play"] = true
		
	sm.unlock_node("sistema", 7)
	if 7 < LEVELS_DATA["sistema"].size():
		LEVELS_DATA["sistema"][7]["can_play"] = true
		
	sm.unlock_node("servidor", 1)
	if 1 < LEVELS_DATA["servidor"].size():
		LEVELS_DATA["servidor"][1]["can_play"] = true
		
	_sync_progression_from_save()
	
	# Cerrar terminal para mostrar animación en la constelación
	_close_dev_console()
		
	# Animación de desbloqueo en el Nivel 1 del modo actual
	var anim_node = 1 if current_mode == "servidor" else 7
	if graph_lines and graph_lines.has_method("play_unlock_animation"):
		graph_lines.play_unlock_animation(anim_node)
		
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("play_sfx"):
		gm.play_sfx("success")
		
	_show_toast("⚡ [PRACTICE SKIP] ¡Prácticas completadas y Nivel 1 desbloqueado automáticamente en los 3 modos!")
	_print_dev_console("[color=#50fa7b]✓ [PRACTICE SKIP] Prácticas completadas y Nivel 1 desbloqueado automáticamente con animación en Reparación, Sistemas y Servidor.[/color]")

func _cmd_actually_level_skip() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if not sm:
		return
		
	var campaign_rep_sis = [7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18]
	var campaign_srv = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
	
	var unlocked_in_current: int = -1
	var current_lvl_number: int = 1
	
	for mode_key in ["reparacion", "sistema", "servidor"]:
		var camp_list = campaign_srv if mode_key == "servidor" else campaign_rep_sis
		var next_locked_node: int = -1
		var prev_node: int = -1
		
		for idx in range(camp_list.size()):
			var node_idx = camp_list[idx]
			if not sm.is_node_unlocked(mode_key, node_idx):
				next_locked_node = node_idx
				if idx == 0:
					prev_node = 0
				else:
					prev_node = camp_list[idx - 1]
				break
				
		if next_locked_node != -1:
			# Marcar anterior como completado
			if prev_node >= 0:
				sm.mark_node_completed(mode_key, prev_node)
				if mode_key in ["reparacion", "sistema"] and prev_node == 0:
					sm.mark_node_completed(mode_key, 6)
			
			# Desbloquear directamente el siguiente nivel
			sm.unlock_node(mode_key, next_locked_node)
			if next_locked_node < LEVELS_DATA[mode_key].size():
				LEVELS_DATA[mode_key][next_locked_node]["can_play"] = true
				
			if mode_key == current_mode:
				unlocked_in_current = next_locked_node
				current_lvl_number = next_locked_node if mode_key == "servidor" else (next_locked_node - 6)
				
	# Asegurar puntos
	var gm = get_node_or_null("/root/GameManager")
	if gm and "score" in gm:
		var req_p = 100 * max(1, current_lvl_number)
		if gm.score < req_p:
			gm.score = req_p + 300
			if sm and sm.has_method("get_slot"):
				var sdata = sm.get_slot(sm.current_slot)
				sdata["score"] = gm.score
				sm.save_slot(sm.current_slot, sdata)
				
	_sync_progression_from_save()
	
	# Cerrar terminal para que el jugador vea la animación en la constelación
	_close_dev_console()
		
	if unlocked_in_current != -1:
		if graph_lines and graph_lines.has_method("play_unlock_animation"):
			graph_lines.play_unlock_animation(unlocked_in_current)
			
		# Si estaba abierta una tarjeta, refrescarla de inmediato
		if is_level_zoomed and active_zoomed_index >= 0:
			_on_node_clicked(unlocked_in_current)
			
		if gm and gm.has_method("play_sfx"):
			gm.play_sfx("success")
			
		_show_toast("🔓 ¡Nivel %d desbloqueado en los 3 modos!" % current_lvl_number)
		_print_dev_console("""[color=#50fa7b]✓ [ACTUALLY LEVEL SKIP] Nivel %d desbloqueado con animación en los 3 modos.[/color]""" % current_lvl_number)
	else:
		_show_toast("✓ Todos los niveles de campaña ya están desbloqueados.")
		_print_dev_console("[color=#f1fa8c]:: Todos los niveles de campaña ya están desbloqueados en los 3 modos.[/color]")

func _cmd_unlock_all_levels() -> void:
	for m in LEVELS_DATA.keys():
		for item in LEVELS_DATA[m]:
			item["can_play"] = true
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.has_method("unlock_all_levels"):
		sm.unlock_all_levels()
	if graph_lines and graph_lines.has_method("set_all_unlocked"):
		graph_lines.set_all_unlocked(true)
	_print_dev_console("""[color=#00e5ff]:: Sincronizando repositorios de Andromeda OS...[/color]
 andromeda-core                         154.2 KiB   420 KiB/s 00:00 [####################################] 100%
 andromeda-hardware                       8.9 MiB  12.4 MiB/s 00:01 [####################################] 100%
 andromeda-enterprise                   142.0 KiB   510 KiB/s 00:00 [####################################] 100%
[color=#00e5ff]:: Desplegando módulos del sistema...[/color]
resolviendo dependencias...
verificando integridad de kernel...

Paquetes (3) [color=#50fa7b]reparacion-master-1.0[/color]  [color=#50fa7b]sistema-master-1.0[/color]  [color=#50fa7b]servidor-master-1.0[/color]

(1/3) Desbloqueando Modo Reparación   [####################################] 100%
(2/3) Desbloqueando Modo Sistemas     [####################################] 100%
(3/3) Desbloqueando Modo Servidores   [####################################] 100%
[color=#50fa7b]✓ ¡Éxito! Todos los 26 niveles de reparación, 26 de sistemas y 14 de servidor han sido desbloqueados.[/color]""")
	_show_toast("✓ [DEV CHEAT] ¡Todos los niveles desbloqueados con éxito!")
	if graph_lines and graph_lines.has_method("play_unlock_animation"):
		graph_lines.play_unlock_animation(7)

func _cmd_reset_locks() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.has_method("reset_progression_lock"):
		sm.reset_progression_lock()
	_sync_progression_from_save()
	_print_dev_console("""[color=#ff5555]:: Restableciendo bloqueos de progresión a estado inicial...[/color]
(1/3) Área de Reparación: Tutorial 0 activo (25 bloqueados) [####################################] 100%
(2/3) Área de Sistemas:   Tutorial 0 activo (25 bloqueados) [####################################] 100%
(3/3) Área de Servidor:   Tutorial 0 activo (13 bloqueados) [####################################] 100%
[color=#ffaa00]✓ Progreso restablecido: Los niveles de introducción de Reparación, Sistemas y Servidor están desbloqueados.[/color]""")
	_show_toast("Progreso restablecido.")
