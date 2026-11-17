class_name LevelSelect
extends Control

# =============================================================================
# LEVEL SELECT & CENTRO DE ENTRENAMIENTO // SISTEMA UNIFICADO DE NIVELES Y TUTORIALES
# CAMBIO INSTANTÁNEO DE PESTAÑAS (0 MS RETRASO, SIN RECARGA DE ESCENA)
# =============================================================================

static var initial_tab: String = "niveles"
static var initial_mode: String = "reparacion"

# --- Nodos Principales ---
@onready var background_rect: ColorRect = $Background
@onready var btn_volver: Button = $TopBar/BtnVolver
@onready var btn_niveles: Button = $TopBar/Tabs/BtnNiveles
@onready var btn_tutoriales: Button = $TopBar/Tabs/BtnTutoriales
@onready var btn_reparacion: Button = $ModeSelector/BtnReparacion
@onready var btn_fondo: Button = $ModeSelector/BtnFondo
@onready var btn_sistema: Button = $ModeSelector/BtnSistema
@onready var btn_servidor: Button = $ModeSelector/BtnServidor
@onready var banner_label: Label = $SectionBanner/BannerLabel
@onready var column_headers: HBoxContainer = $ColumnHeaders
@onready var col1_label: Label = $ColumnHeaders/Col1
@onready var col2_label: Label = $ColumnHeaders/Col2
@onready var col3_label: Label = $ColumnHeaders/Col3
@onready var footer_hint: Label = $FooterHint

# --- Selector Circular de Modo & Decoración Lateral Derecha ---
@onready var decoracion_right: TextureRect = get_node_or_null("DecoracionRight")
@onready var circular_mode_selector: Control = get_node_or_null("CircularModeSelector")
@onready var btn_up_arrow: Button = get_node_or_null("CircularModeSelector/BtnUpArrow")
@onready var btn_down_arrow: Button = get_node_or_null("CircularModeSelector/BtnDownArrow")
@onready var mode_wheel_area: Control = get_node_or_null("CircularModeSelector/ModeWheelArea")
@onready var bubble_reparacion: Control = get_node_or_null("CircularModeSelector/ModeWheelArea/BubbleReparacion")
@onready var bubble_sistema: Control = get_node_or_null("CircularModeSelector/ModeWheelArea/BubbleSistema")
@onready var bubble_servidor: Control = get_node_or_null("CircularModeSelector/ModeWheelArea/BubbleServidor")

const MODE_ORDER: Array[String] = ["reparacion", "sistema", "servidor"]
var _wheel_visual_angle: float = 0.0
var _wheel_target_angle: float = 0.0
var _wheel_tween: Tween = null
var _color_tween: Tween = null

const MODE_PALETTES: Dictionary = {
	"reparacion": {
		"bg_color": Color(0.05, 0.02, 0.1, 1.0),
		"accent": Color(1.0, 0.1, 0.35, 1.0),
		"accent_dim": Color(0.65, 0.05, 0.45, 0.55),
		"banner_font": Color(1.0, 0.1, 0.25, 1.0),
		"banner_shadow": Color(0.65, 0.0, 0.85, 0.8),
		"holo_top": Color(0.48, 0.04, 0.78, 1.0),
		"holo_bottom": Color(0.88, 0.02, 0.16, 1.0),
		"holo_edge": Color(1.0, 0.08, 0.22, 1.0)
	},
	"sistema": {
		"bg_color": Color(0.015, 0.035, 0.12, 1.0),
		"accent": Color(0.18, 0.55, 1.0, 1.0),
		"accent_dim": Color(0.04, 0.22, 0.65, 0.55),
		"banner_font": Color(0.2, 0.7, 1.0, 1.0),
		"banner_shadow": Color(0.04, 0.2, 0.65, 0.8),
		"holo_top": Color(0.02, 0.12, 0.45, 1.0),
		"holo_bottom": Color(0.08, 0.35, 0.85, 1.0),
		"holo_edge": Color(0.25, 0.7, 1.0, 1.0)
	},
	"servidor": {
		"bg_color": Color(0.08, 0.035, 0.01, 1.0),
		"accent": Color(1.0, 0.55, 0.08, 1.0),
		"accent_dim": Color(0.7, 0.25, 0.02, 0.55),
		"banner_font": Color(1.0, 0.6, 0.1, 1.0),
		"banner_shadow": Color(0.75, 0.25, 0.02, 0.8),
		"holo_top": Color(0.45, 0.15, 0.01, 1.0),
		"holo_bottom": Color(0.95, 0.45, 0.05, 1.0),
		"holo_edge": Color(1.0, 0.68, 0.12, 1.0)
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
const MIN_MAP_ZOOM: float = 0.65
const MAX_MAP_ZOOM: float = 1.6

# --- Área de Tutoriales (Centro de Entrenamiento) ---
@onready var tutorial_area: Control = $TutorialArea
@onready var cards_scroll: ScrollContainer = $TutorialArea/CardsScroll
@onready var cards_grid: GridContainer = $TutorialArea/CardsScroll/CardsGrid

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
	"res://pixel art menus/menus/fondos de menus.png": preload("res://pixel art menus/menus/fondos de menus.png")
}

# Carga bajo demanda de escenas de minijuegos para garantizar 0 ms al alternar pestañas
var _fancooler_scene = null
var _ram_scene = null
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
			"can_play": true
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
			"description": "Taller guiado paso a paso con Joa.\nAprende a abrir los seguros laterales (clips) de la ranura DIMM, alinear la muesca y encajar firmemente el módulo DDR.",
			"requirements": "HERRAMIENTAS: Manos libres / Guantes antiestáticos · MODO TUTORIAL GUIADO",
			"can_play": true
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
			"can_play": true
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
			"can_play": true
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
			"can_play": true
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
			"can_play": true
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
			"can_play": true
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

		# --- ZONAS DE PRÁCTICA LIBRE (BURBUJAS NARANJAS 🛠️) [19 - 25] ---
		{
			"number": 19,
			"is_practice": true,
			"practice_id": "cooler",
			"title": "ZONA DE PRÁCTICA: BANCO DE REFRIGERACIÓN (FAN COOLER)",
			"stage": "ZONA DE PRÁCTICA // ENTRENAMIENTO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(1.0, 0.55, 0.05),
			"description": "Banco de trabajo libre sin límite de tiempo.\nPractica la desconexión PWM y aflojado en patrón diagonal de 4 tornillos de cooler con Joa.",
			"requirements": "HERRAMIENTAS: Acceso Total · MODO PRÁCTICA LIBRE · SIN TIEMPO",
			"can_play": true
		},
		{
			"number": 20,
			"is_practice": true,
			"practice_id": "ram",
			"title": "ZONA DE PRÁCTICA: BANCO DE MEMORIAS RAM",
			"stage": "ZONA DE PRÁCTICA // ENTRENAMIENTO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(1.0, 0.55, 0.05),
			"description": "Banco de trabajo libre sin límite de tiempo.\nPractica la apertura de trabas laterales, extracción y montaje de módulos DDR con Joa.",
			"requirements": "HERRAMIENTAS: Acceso Total · MODO PRÁCTICA LIBRE · SIN TIEMPO",
			"can_play": true
		},
		{
			"number": 21,
			"is_practice": true,
			"practice_id": "hdd",
			"title": "ZONA DE PRÁCTICA: BANCO DE ALMACENAMIENTO (HDD / SSD)",
			"stage": "ZONA DE PRÁCTICA // ENTRENAMIENTO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(1.0, 0.55, 0.05),
			"description": "Banco de trabajo libre sin límite de tiempo.\nPractica los 4 tornillos de esquinas, desconexión de cables SATA y extracción a la derecha con Joa.",
			"requirements": "HERRAMIENTAS: Acceso Total · MODO PRÁCTICA LIBRE · SIN TIEMPO",
			"can_play": true
		},
		{
			"number": 22,
			"is_practice": true,
			"practice_id": "gpu",
			"title": "ZONA DE PRÁCTICA: BANCO DE TARJETAS GRÁFICAS (GPU)",
			"stage": "ZONA DE PRÁCTICA // ENTRENAMIENTO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(1.0, 0.55, 0.05),
			"description": "Banco de trabajo libre sin límite de tiempo.\nPractica la desconexión PCIe para frenar ventiladores, tornillos en bracket HDMI y soporte fijo con Joa.",
			"requirements": "HERRAMIENTAS: Acceso Total · MODO PRÁCTICA LIBRE · SIN TIEMPO",
			"can_play": true
		},
		{
			"number": 23,
			"is_practice": true,
			"practice_id": "psu",
			"title": "ZONA DE PRÁCTICA: BANCO DE ENERGÍA (PSU)",
			"stage": "ZONA DE PRÁCTICA // ENTRENAMIENTO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(1.0, 0.55, 0.05),
			"description": "Banco de trabajo libre sin límite de tiempo.\nPractica la desconexión de arneses ATX 24 pines y arneses auxiliares de poder con Joa.",
			"requirements": "HERRAMIENTAS: Acceso Total · MODO PRÁCTICA LIBRE · SIN TIEMPO",
			"can_play": true
		},
		{
			"number": 24,
			"is_practice": true,
			"practice_id": "cpu",
			"title": "ZONA DE PRÁCTICA: BANCO DE PROCESADOR (CPU)",
			"stage": "ZONA DE PRÁCTICA // ENTRENAMIENTO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(1.0, 0.55, 0.05),
			"description": "Banco de trabajo libre sin límite de tiempo.\nPractica la apertura de palanca de retención y alineación de procesador en zócalo sin doblar pines con Joa.",
			"requirements": "HERRAMIENTAS: Acceso Total · MODO PRÁCTICA LIBRE · SIN TIEMPO",
			"can_play": true
		},
		{
			"number": 25,
			"is_practice": true,
			"practice_id": "maestra",
			"title": "SALA DE PRÁCTICA 3D MAESTRA (TODAS LAS PIEZAS)",
			"stage": "LABORATORIO PRÁCTICO // ENTRENAMIENTO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(1.0, 0.55, 0.05),
			"description": "Banco de trabajo libre sin límite de tiempo.\nPractica la extracción, sustitución y ensamblaje de todas las piezas (RAM, Discos HDD/SSD, GPU, Cooler, Fuente y CPU) con Joa.",
			"requirements": "HERRAMIENTAS: Acceso Total · MODO PRÁCTICA LIBRE · SIN TIEMPO",
			"can_play": true
		}
	],
	"sistema": [
		{
			"number": 0,
			"is_tutorial": true,
			"title": "NÚCLEO TUTORIAL · PROTOCOLO DE BOOT & BIOS",
			"stage": "CENTRO NEURONAL // TUTORIAL",
			"mode_name": "SISTEMA",
			"color_accent": Color(0.0, 0.88, 1.0),
			"description": "Inducción al diagnóstico y rescate de sistemas operativos.\nAprende los ciclos POST de firmware, configuración UEFI y aislamiento seguro de amenazas informáticas en entorno sandbox.",
			"requirements": "HERRAMIENTAS: Consola / BIOS · MODO GUIADO · ACCESO LIBRE",
			"can_play": true
		},
		{
			"number": 1,
			"title": "NIVEL 1 · TERMINAL DE SISTEMAS Y SOFTWARE",
			"stage": "ETAPA I: SISTEMAS & CIBERSEGURIDAD",
			"mode_name": "SISTEMA",
			"color_accent": Color(0.0, 0.95, 1.0),
			"description": "Estación de trabajo con fallas críticas de software.\nAccede a la PC y restaura los 7 módulos (Instalación de SO, Drivers, Malware, Adware, Debugger, USB Booteable y Ciberdefensa Arcade).",
			"requirements": "CONSOLA DE SISTEMAS · LÍMITE: 900s · RECOMPENSA: 100 PTS",
			"can_play": true
		},
		{
			"number": 2,
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
			"title": "NIVEL 12 · ARQUITECTO SUPREMO DE SO",
			"stage": "ETAPA III: CIBERSEGURIDAD & RESCATE",
			"mode_name": "SISTEMA",
			"color_accent": Color(1.0, 0.15, 0.4),
			"description": "Despliegue automatizado de imagen corporativa con endurecimiento de seguridad, directivas de grupo y parches de kernel.",
			"requirements": "MASTER SYSTEM ADMINISTRATOR · LÍMITE: 150s · RECOMPENSA: 1000 PTS ★",
			"can_play": false
		},
		{
			"number": 13,
			"is_practice": true,
			"title": "SALA DE PRÁCTICA 3D",
			"stage": "LABORATORIO PRÁCTICO // ENTRENAMIENTO",
			"mode_name": "SISTEMA",
			"color_accent": Color(1.0, 0.55, 0.05),
			"description": "Entorno libre de pruebas sin presión de tiempo.\nPractica la interacción con terminales y software en el banco de trabajo.",
			"requirements": "HERRAMIENTAS: Consola / BIOS · MODO PRÁCTICA LIBRE · SIN TIEMPO",
			"can_play": true
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
var ALL_TUTORIAL_CARDS: Array[Dictionary] = [
	# --- DIVISIÓN REPARACIÓN (HARDWARE) ---
	{
		"division": "reparacion",
		"id": "cooler",
		"title": "FAN COOLER",
		"subtitle": "DISIPADOR TÉRMICO ACTIVO PWM",
		"category": "REFRIGERACIÓN",
		"texture_path": "res://pixel art minijuegos/fancooler/fancooler.png",
		"color_accent": Color(1.0, 0.15, 0.35, 1.0),
		"que_es": "Disipador de aleación metálica (aluminio/cobre) acoplado mecánicamente sobre el microprocesador con ventilador de velocidad regulada.",
		"importancia": "CRÍTICA: Sin disipador activo, la CPU supera los 95°C en segundos, provocando apagados forzados de emergencia o degradación irreversible del silicio.",
		"que_hace": "Transfiere el calor por contacto térmico hacia las aletas y el ventilador expulsa el flujo de aire caliente al exterior según la curva PWM de 4 pines.",
		"pasos": "🔻 FASE 1: DESMONTAJE (QUITAR):\n1. Desconecta el cable de alimentación PWM.\n2. Retira los 4 tornillos con Cruz [1] o Pala [2].\n3. Levanta el disipador.\n\n🔺 FASE 2: MONTAJE INVERSO (PONER):\n1. Coloca el Fan Cooler nuevo sobre el socket de la CPU.\n2. Ajusta los 4 tornillos en cruz con Cruz [1] o Pala [2].\n3. Conecta el cable PWM de 4 pines a la placa madre.",
		"is_ready": true,
		"handler": "launch_cooler"
	},
	{
		"division": "reparacion",
		"id": "ram",
		"title": "MEMORIA RAM",
		"subtitle": "MÓDULOS DE MEMORIA DDR",
		"category": "MEMORIA",
		"texture_path": "res://pixel art minijuegos/ramstipos/ram ddr.png",
		"color_accent": Color(0.85, 0.1, 0.95, 1.0),
		"que_es": "Memoria de acceso aleatorio de ultra alta velocidad y almacenamiento volátil, con conexión directa al controlador de memoria de la CPU.",
		"importancia": "FUNDAMENTAL: Celdas defectuosas o pistas con falso contacto causan cuelgues repentinos, pantallas azules (BSOD) o ausencia de video al encender.",
		"que_hace": "Almacena en tiempo real el código ejecutable y datos temporales del sistema operativo y programas abiertos, permitiendo transferencias a gigabytes por segundo.",
		"pasos": "🔻 FASE 1: DESMONTAJE (QUITAR):\n1. Arrastra las trabas laterales (izq/der) hacia ARRIBA (se levantan un poquitito).\n2. Arrastra el centro de la RAM hacia ARRIBA para retirarla por completo.\n\n🔺 FASE 2: MONTAJE INVERSO (PONER):\n1. Con el zócalo vacío, arrastra hacia ABAJO las flechas superiores (izq y der).\n2. Al tercer jalón hacia ABAJO (flecha central), la RAM desciende y se engancha en la ranura gris.",
		"is_ready": true,
		"handler": "launch_ram"
	},
	{
		"division": "reparacion",
		"id": "hdd",
		"title": "DISCO DURO",
		"subtitle": "UNIDAD DE ALMACENAMIENTO SATA",
		"category": "ALMACENAMIENTO",
		"texture_path": "res://pixel art minijuegos/memoriastipos/m.2/memoria M.2.png",
		"color_accent": Color(1.0, 0.2, 0.45, 1.0),
		"que_es": "Unidad de almacenamiento masivo y persistente del sistema (discos magnéticos o celdas flash de estado sólido SATA/NVMe).",
		"importancia": "VITAL: En él reside el Sistema Operativo, sectores de booteo y archivos del usuario. Errores mecánicos o SMART impiden que la máquina bootee.",
		"que_hace": "Lee y graba permanentemente los datos a través del bus serie SATA de 6 Gb/s, recibiendo energía desde rieles de 12V y 5V de la fuente.",
		"pasos": "🔻 FASE 1: DESMONTAJE (QUITAR):\n1. Retira el tornillo de la bahía con Cruz [1] o Pala [2].\n2. Arrastra la unidad averiada hacia ARRIBA para extraerla.\n\n🔺 FASE 2: MONTAJE INVERSO (PONER):\n1. Coloca el disco nuevo en la bahía vacía.\n2. Arrastra el disco hacia ABAJO para encajar en el puerto SATA.\n3. Fija y ajusta el tornillo de sujeción.",
		"is_ready": true,
		"handler": "launch_hdd"
	},
	{
		"division": "reparacion",
		"id": "gpu",
		"title": "TARJETA GPU",
		"subtitle": "ACELERADORA GRÁFICA PCIE",
		"category": "GRÁFICOS",
		"texture_path": "",
		"color_accent": Color(1.0, 0.15, 0.45, 1.0),
		"que_es": "Unidad de procesamiento gráfico de alto rendimiento montada en el puerto PCIe x16 con alimentación dedicada de 8 pines.",
		"importancia": "CRÍTICA: Es la pieza más propensa a roturas si se tira sin liberar el pestillo plástico del zócalo PCIe de la placa madre.",
		"que_hace": "Procesa y renderiza gráficos 3D en tiempo real, conectada al bus de datos de alta velocidad PCIe y a la salida de pantalla.",
		"pasos": "🔻 FASE 1: DESMONTAJE (QUITAR):\n1. Desconecta el cable PCIe de 8 pines con clip.\n2. Retira los 2 tornillos del bracket metálico con [1]/[2].\n3. Presiona el pestillo de retención plástico PCIe x16.\n4. Extrae la GPU hacia arriba.\n\n🔺 FASE 2: MONTAJE INVERSO (PONER):\n1. Asienta la GPU nueva en la ranura PCIe x16.\n2. Cierra y traba el pestillo plástico PCIe.\n3. Atornilla los 2 tornillos del bracket metálico con [1]/[2].\n4. Conecta el cable PCIe de 8 pines con seguro.",
		"is_ready": true,
		"handler": "launch_gpu"
	},
	{
		"division": "reparacion",
		"id": "cpu",
		"title": "PROCESADOR (CPU)",
		"subtitle": "MICROPROCESADOR & ZÓCALO LGA",
		"category": "PROCESAMIENTO",
		"texture_path": "",
		"color_accent": Color(0.9, 0.15, 0.9, 1.0),
		"que_es": "Unidad central de procesamiento montada sobre la matriz de pines del zócalo con placa de sujeción metálica y palanca de tensión.",
		"importancia": "MÁXIMA: Manipular correctamente la palanca y la placa de carga previene doblar pines o quebrar la matriz del zócalo.",
		"que_hace": "Ejecuta todas las operaciones del computador coordinando reloj y memoria a miles de millones de ciclos por segundo.",
		"pasos": "🔻 FASE 1: DESMONTAJE (SACAR):\n1. Arrastra la palanca lateral hacia abajo para liberar la retención del socket.\n2. La placa de protección metálica se retira automáticamente.\n3. Haz clic sobre el CPU para extraerlo del zócalo.\n\n🔺 FASE 2: MONTAJE INVERSO (PONER):\n1. Con el socket abierto, haz clic en el zócalo para colocar el nuevo procesador.\n2. La protección metálica desciende cubriendo el procesador.\n3. Arrastra la palanca hacia arriba (al lado contrario) para asegurar y bloquear.",
		"is_ready": true,
		"handler": "launch_cpu"
	},
	{
		"division": "reparacion",
		"id": "m2",
		"title": "SSD M.2 NVME",
		"subtitle": "UNIDAD DE ALMACENAMIENTO PCIE",
		"category": "ALMACENAMIENTO",
		"texture_path": "",
		"color_accent": Color(0.2, 0.9, 0.7, 1.0),
		"que_es": "Unidad de almacenamiento en estado sólido formato 2280 conectada directamente a líneas PCIe del chipset/CPU.",
		"importancia": "ALTA: Al quitar el tornillo, los resortes internos del zócalo elevan la unidad a 30°. Retirarla en ángulo previene partir el conector.",
		"que_hace": "Lectura y escritura ultrarrápida de archivos y sistema operativo a través del protocolo NVMe sobre memoria 3D NAND.",
		"pasos": "1. Retira el tornillo de la armadura térmica M.2 con [1] Cruz.\n2. Retira el micro-tornillo de sujeción sobre el standoff.\n3. Observa cómo la unidad se eleva a 30° impulsada por el resorte del socket.\n4. Desliza suavemente la unidad en diagonal para extraerla.",
		"is_ready": true,
		"handler": "launch_m2"
	},
	{
		"division": "reparacion",
		"id": "psu",
		"title": "FUENTE PSU",
		"subtitle": "ALIMENTACIÓN ELÉCTRICA ATX",
		"category": "ENERGÍA",
		"texture_path": "",
		"color_accent": Color(1.0, 0.65, 0.2, 1.0),
		"que_es": "Fuente de alimentación conmutada modular que entrega energía estabilizada a todos los rieles del equipo.",
		"importancia": "CRÍTICA: Tirar de los cables sin presionar los clips de seguridad puede fracturar los puertos de la placa madre.",
		"que_hace": "Distribuye potencia a la placa madre (24 pines), procesador (EPS 8 pines) y componentes periféricos.",
		"pasos": "🔻 FASE 1: DESMONTAJE (QUITAR):\n1. Desconecta el conector principal ATX de 24 pines.\n2. Desconecta el conector auxiliar EPS de 8 pines.\n3. Retira los 4 tornillos hexagonales con [1] Cruz o [2] Pala.\n4. Desliza la fuente hacia afuera del túnel.\n\n🔺 FASE 2: MONTAJE INVERSO (PONER):\n1. Desliza la fuente nueva dentro del túnel del chasis.\n2. Fija los 4 tornillos de chasis con [1] Cruz o [2] Pala.\n3. Conecta el cable EPS auxiliar de 8 pines.\n4. Conecta el conector principal ATX de 24 pines.",
		"is_ready": true,
		"handler": "launch_psu"
	},
	{
		"division": "reparacion",
		"id": "motherboard",
		"title": "PLACA MADRE",
		"subtitle": "EN DESARROLLO (PRÓXIMAMENTE)",
		"category": "ARQUITECTURA & DESARME",
		"texture_path": "",
		"color_accent": Color(0.5, 0.5, 0.6, 0.7),
		"que_es": "Desafío maestro de taller en desarrollo. Este módulo estará disponible en la próxima actualización del taller.",
		"importancia": "AVISO: Módulo en fase de calibración técnica.",
		"que_hace": "Interconecta todos los buses de hardware del sistema.",
		"pasos": "Próximamente disponible.",
		"is_ready": false,
		"handler": "launch_mobo"
	},
	{
		"division": "reparacion",
		"id": "liquid_cooling",
		"title": "REFRIGERACIÓN LÍQUIDA",
		"subtitle": "CIRCUITO CUSTOM LOOP & PURGADO",
		"category": "REFRIGERACIÓN EXTREMA",
		"texture_path": "",
		"color_accent": Color(0.1, 0.9, 1.0, 1.0),
		"que_es": "Sistema de refrigeración líquida personalizada compuesto por bomba D5, bloque de GPU, bloques acrílicos de CPU y RAM, depósito y radiador 360mm.",
		"importancia": "CRÍTICA: Una bomba encendida en seco (Dry-running) se quema en segundos. Siempre debes cerrar el circuito de tubos y llenar el depósito antes de encender la bomba.",
		"que_hace": "Disipa cargas térmicas extremas haciendo circular refrigerante con base glicol a través de microcanales en GPU, CPU y RAM hacia el radiador.",
		"pasos": "1. Arrastra cada tubo rígido desde el rack izquierdo hacia sus racores en el mapa del chasis (Bomba ➔ GPU ➔ CPU ➔ RAM ➔ Radiador ➔ Depósito) hasta cerrar el circuito.\n2. Arrastra el bidón de líquido refrigerante hacia el tapón del depósito hasta alcanzar el 100% de llenado.\n3. Enciende el interruptor de la bomba D5 para purgar burbujas de aire y disipar el calor de GPU, CPU y RAM.",
		"is_ready": true,
		"handler": "launch_liquid_cooling"
	},

	# --- DIVISIÓN REPARACIÓN A FONDO (MICROMECÁNICA Y LIMPIEZA PROFUNDA) ---
	{
		"division": "reparacion_fondo",
		"id": "thermal_paste",
		"title": "LIMPIEZA DE PASTA TÉRMICA",
		"subtitle": "DESINFECCIÓN CON ISOPROPÍLICO",
		"category": "MANTENIMIENTO PROFUNDO",
		"texture_path": "",
		"color_accent": Color(0.1, 0.95, 0.7, 1.0),
		"que_es": "Limpieza y remoción de compuesto térmico degradado, seco o solidificado sobre el dispersor térmico integrado (IHS) de la CPU.",
		"importancia": "CRÍTICA: Una pasta térmica reseca pierde conductividad térmica, elevando la temperatura del procesador y provocando apagados forzados o estrangulamiento térmico.",
		"que_hace": "Disuelve químicamente los silicatos y partículas metálicas secas con alcohol isopropílico al 99% mediante fricción circular sin dejar residuos conductores.",
		"pasos": "1. Selecciona la herramienta Limpiador [5] para acceder a la estación de mantenimiento.\n2. Con el paño isopropílico, frota continuamente sobre el procesador hasta disolver la pasta seca.\n3. Arrastra el dispensador varias veces sobre la CPU para distribuir la nueva pasta térmica al 100%.",
		"is_ready": true,
		"handler": "launch_thermal_paste"
	},
	{
		"division": "reparacion_fondo",
		"id": "voltimeter",
		"title": "DIAGNÓSTICO CON MULTÍMETRO // VOLTÍMETRO",
		"subtitle": "MEDICIÓN DE RIELES Y CONTINUIDAD",
		"category": "ELECTRÓNICA & DIAGNÓSTICO",
		"texture_path": "",
		"color_accent": Color(1.0, 0.85, 0.15, 1.0),
		"que_es": "Multímetro digital de banco para verificación de rieles de alimentación ATX (12V, 5VSB, 3.3V, VCore) y detección de cortocircuitos en condensadores cerámicos y MOSFETs.",
		"importancia": "MÁXIMA: Un componente en cortocircuito en el riel de 12V o VCore tumba la fuente de poder por protección OCP/SCP, dejando la placa madre completamente inerte.",
		"que_hace": "Mide en tiempo real la tensión en los Puntos de Prueba (Test Points). Permite aislar componentes dañados, sustituirlos y comprobar el retorno de la señal POWER_GOOD.",
		"pasos": "1. Conecta la sonda COM a tierra (GND) del chasis.\n2. Haz clic en cada Punto de Prueba (TP) de la placa madre para medir su voltaje con la sonda roja.\n3. Identifica el riel con cortocircuito (0.00V / Alarma acústica continua).\n4. Presiona 'REEMPLAZAR CONDENSADOR SMD C124' para soldar un nuevo componente.\n5. Vuelve a medir para comprobar la estabilización de los rieles y la activación de PWR_GOOD (3.3V).",
		"is_ready": true,
		"handler": "launch_voltimeter"
	},
	{
		"division": "reparacion_fondo",
		"id": "cpu_pins",
		"title": "ALINEACIÓN DE PINES (CPU)",
		"subtitle": "MICROSCOPIA & CALIBRACIÓN A 90°",
		"category": "MICROMECÁNICA AVANZADA",
		"texture_path": "",
		"color_accent": Color(1.0, 0.8, 0.15, 1.0),
		"que_es": "Inspección microscópica y corrección angular de la matriz de pines del procesador o zócalo LGA/PGA dañados por mala inserción.",
		"importancia": "VITAL: Un solo pin doblado que toque un contacto contiguo genera un cortocircuito directo entre rieles de voltaje (VCC) o líneas PCIe/DRAM, impidiendo que la placa encienda.",
		"que_hace": "Restaura la verticalidad ortogonal de 90° de cada pin desviado mediante presión micrométrica guiada hasta garantizar contacto eléctrico óptimo.",
		"pasos": "1. Selecciona la herramienta Lupa [3] para habilitar la micro-inspección.\n2. Inspecciona la matriz de 8x10 pines bajo el microscopio óptico.\n3. Identifica los pines con desvío angular resaltados en advertencia naranja.\n4. Haz clic cuidadosamente sobre cada pin doblado para enderezarlo a 90°.\n5. Completa la corrección del 100% de los pines averiados.",
		"is_ready": true,
		"handler": "launch_cpu_pins"
	},
	{
		"division": "reparacion_fondo",
		"id": "dust_cleaner",
		"title": "DESOBSTRUCCIÓN DE PELUSA",
		"subtitle": "LIMPIEZA DE DISIPADORES & ALETAS",
		"category": "MANTENIMIENTO TÉRMICO",
		"texture_path": "res://pixel art minijuegos/pelusa/pelusa grande.png",
		"color_accent": Color(0.2, 0.95, 0.7, 1.0),
		"que_es": "Limpieza profunda de cúmulos de pelusa, polvo apelmazado y fibras alojadas entre las aletas de disipación y aspas.",
		"importancia": "MÁXIMA: Las aletas de aluminio tupidas por pelusa estrangulan el flujo de aire, provocando sobrecalentamiento crítico de más de 95°C y thermal throttling.",
		"que_hace": "Remueve mecánicamente cada obstrucción de pelusa y polvo con el Limpiador [5] hasta recuperar el 100% del paso de aire frío.",
		"pasos": "1. Selecciona la herramienta Limpiador [5].\n2. Cepilla o haz clic sobre cada cúmulo de pelusa alojado en el disipador.\n3. Desobstruye todas las áreas hasta restaurar el 100% del flujo de aire.",
		"is_ready": true,
		"handler": "launch_dust_cleaner"
	},
	{
		"division": "reparacion_fondo",
		"id": "ram_cleaner",
		"title": "LIMPIEZA DE RAM",
		"subtitle": "DESOBSTRUCCIÓN DE PELUSA Y PINES DDR",
		"category": "MANTENIMIENTO DE MEMORIA",
		"texture_path": "res://pixel art minijuegos/pelusa/pelusa grande.png",
		"color_accent": Color(0.2, 0.95, 0.7, 1.0),
		"que_es": "Limpieza profunda de cúmulos de pelusa, polvo apelmazado y fibras alojadas sobre los chips y contactos dorados de la memoria RAM.",
		"importancia": "MÁXIMA: La pelusa acumulada retiene humedad y estática, provocando falsos contactos en las líneas de datos DDR, errores de paridad, pantallas azules (BSOD) o reinicios inesperados.",
		"que_hace": "Remueve mecánicamente cada cúmulo de pelusa y polvo con el Limpiador [5] pasando la brocha sobre el módulo hasta restaurar el 100% de limpieza de la RAM.",
		"pasos": "1. Selecciona la herramienta Limpiador [5] (Brocha antiestática).\n2. Pasa la brocha o haz clic sobre cada cúmulo de pelusa alojado en la memoria RAM.\n3. Desobstruye todos los cúmulos hasta dejar la superficie y pines al 100% limpios.",
		"is_ready": true,
		"handler": "launch_ram_cleaner"
	},

	# --- DIVISIÓN SISTEMA (SOFTWARE & CIBERSEGURIDAD) ---
	{
		"division": "sistema",
		"id": "adware_cleaner",
		"title": "LIMPIEZA DE ANUNCIOS",
		"subtitle": "POP-UPS, ADWARE & PUPS EN EL NAVEGADOR",
		"category": "CIBERSEGURIDAD",
		"texture_path": "",
		"color_accent": Color(1.0, 0.2, 0.45, 1.0),
		"que_es": "Desinfección de navegadores y escritorios infestados por software publicitario intrusivo (Adware) y programas no deseados (PUPs).",
		"importancia": "CRÍTICA: Los pop-ups fraudulentos engañan al usuario con falsas alertas técnicas e inyectan mineros web que colapsan el uso de CPU.",
		"que_hace": "Identifica los botones trampa de cierre falso, desmarca casillas de instalación oculta y despliega un escudo bloqueador Ad-Blocker.",
		"pasos": "1. Inspecciona cada ventana emergente y ubica el botón de cierre [X] auténtico en la cabecera.\n2. Evita hacer clic en botones verdes llamativos engañosos.\n3. Desmarca casillas de consentimiento que intenten instalar barras de búsqueda espías.\n4. Al cerrar 4 anuncios, activa el Escudo Ad-Blocker para purgar el resto con un pulso defensivo.",
		"is_ready": true,
		"handler": "launch_adware_cleaner"
	},
	{
		"division": "sistema",
		"id": "malware_scan",
		"title": "LIMPIEZA DE MALWARE",
		"subtitle": "ESCÁNER HEURÍSTICO & ANÁLISIS DE FIRMAS",
		"category": "CIBERSEGURIDAD",
		"texture_path": "",
		"color_accent": Color(0.95, 0.15, 0.35, 1.0),
		"que_es": "Monitoreo técnico de procesos en tiempo real para detección heurística de troyanos, keyloggers, gusanos y ransomware.",
		"importancia": "VITAL: El malware activo secuestra credenciales bancarias, encripta archivos personales y degrada irreversiblemente el sistema.",
		"que_hace": "Compara firmas criptográficas hash SHA-256, inspecciona el consumo de RAM/CPU de cada hilo y aísla los procesos infecciosos en Sandbox.",
		"pasos": "1. Selecciona un proceso de la lista activa del sistema.\n2. Presiona 'EJECUTAR ANÁLISIS DE FIRMA' para evaluar el comportamiento del ejecutable.\n3. Si se confirma malware, presiona 'AISLAR EN CUARENTENA' para congelar sus hilos.\n4. Presiona 'PURGAR PROCESO' para triturar el código malicioso de la memoria.",
		"is_ready": true,
		"handler": "launch_malware_scan"
	},
	{
		"division": "sistema",
		"id": "os_install",
		"title": "INSTALACIÓN DE SISTEMAS",
		"subtitle": "PARTICIONADO GPT & DESPLIEGUE UEFI",
		"category": "SISTEMAS OPERATIVOS",
		"texture_path": "",
		"color_accent": Color(0.2, 0.85, 1.0, 1.0),
		"que_es": "Asistente maestro de instalación limpia de Sistema Operativo con preparación de tabla GUID (GPT) y estructura de archivos.",
		"importancia": "FUNDAMENTAL: Sin una tabla de partición GPT y partición EFI formateada en FAT32, las placas madre modernas UEFI no pueden bootear el sistema.",
		"que_hace": "Configura los volúmenes lógicos (ESP, Raíz '/', Swap), formatea con superbloque EXT4 y despliega el kernel con el gestor de arranque GRUB.",
		"pasos": "1. Selecciona el esquema de partición moderno GPT.\n2. Asigna la partición EFI (/boot/efi), la partición de sistema Raíz (/) y el área de memoria virtual Swap.\n3. Presiona 'INICIAR DESPLIEGUE DE CYBER-OS' y verifica el desempaquetado de paquetes del kernel.",
		"is_ready": true,
		"handler": "launch_os_install"
	},
	{
		"division": "sistema",
		"id": "driver_install",
		"title": "ACTUALIZACIÓN DE DRIVERS",
		"subtitle": "CONTROLADORES WHQL & GESTOR DE PAQUETES",
		"category": "CONTROLADORES",
		"texture_path": "",
		"color_accent": Color(0.85, 0.2, 0.95, 1.0),
		"que_es": "Depuración y actualización de controladores de hardware esenciales (GPU, Wi-Fi 6, Audio HD, Chipset PCIe Bus Master).",
		"importancia": "ALTA: Controladores obsoletos provocan microcortes de red, artefactos gráficos, ruidos estáticos y cuellos de botella en buses de datos.",
		"que_hace": "Conecta con los repositorios oficiales y descarga versiones certificadas WHQL, descartando compilaciones experimentales inestables.",
		"pasos": "1. Selecciona un componente desactualizado en la columna izquierda.\n2. Revisa el diagnóstico de falla y evalúa los paquetes disponibles en el repositorio.\n3. Selecciona la versión oficial certificada WHQL (evitando versiones Beta o drivers genéricos).\n4. Aplica la actualización limpia y verifica la calibración del dispositivo.",
		"is_ready": true,
		"handler": "launch_driver_install"
	},
	{
		"division": "sistema",
		"id": "code_debugger",
		"title": "PROGRAMACIÓN Y DEBUGGING",
		"subtitle": "TERMINAL DE CÓDIGO & RESOLUCIÓN DE BUGS",
		"category": "DESARROLLO DE SOFTWARE",
		"texture_path": "",
		"color_accent": Color(0.2, 0.9, 0.6, 1.0),
		"que_es": "Entorno de desarrollo integrado (IDE) con análisis estático de código para scripts de automatización y defensa de red.",
		"importancia": "CRÍTICA: Errores de sintaxis o bucles infinitos en scripts de seguridad congelan los firewalls y dejan el perímetro expuesto.",
		"que_hace": "Permite inspeccionar el árbol sintáctico (AST), aplicar Hot-Patches directos y compilar pasando suites completas de pruebas unitarias.",
		"pasos": "1. Haz clic sobre cada línea de código marcada con errores en rojo.\n2. Analiza el diagnóstico (sintaxis ':', typos de identificadores, bucle infinito, retornos).\n3. Selecciona la corrección técnica correcta para aplicar el parche en tiempo real.\n4. Presiona 'COMPILAR Y EJECUTAR TESTS' para verificar que los 4 tests unitarios pasen.",
		"is_ready": true,
		"handler": "launch_code_debugger"
	},
	{
		"division": "sistema",
		"id": "malware_invaders",
		"title": "ARCADE: INVASIÓN ALIENÍGENA",
		"subtitle": "DEFENSA RETRO CONTRA OLEADAS DE MALWARE",
		"category": "MINIJUEGO ESPECIAL RETRO",
		"texture_path": "",
		"color_accent": Color(0.2, 1.0, 0.55, 1.0),
		"que_es": "Minijuego especial estilo arcade clásico de los 80s: combate la invasión de oleadas alienígenas de malware en el espacio digital.",
		"importancia": "ENTRENAMIENTO: Pon a prueba tus reflejos tácticos, administra coberturas en tus cortafuegos defensivos y elimina la nave nodriza de datos.",
		"que_hace": "Simula la clásica mecánica de Space Invaders con aceleración dinámica de aliens, bunkers destructibles y naves nodrizas OVNI con bonificación.",
		"pasos": "1. Muévete hacia los lados con las teclas [A]/[D] o [←]/[→].\n2. Dispara proyectiles con la barra espaciadora [Espacio] o Clic izquierdo.\n3. Utiliza los escudos defensivos para protegerte de los disparos alienígenas.\n4. Dispara a la nave nodriza roja superior para obtener 100 puntos extra y erradica a los 32 invasores.",
		"is_ready": true,
		"handler": "launch_malware_invaders"
	},
	{
		"division": "sistema",
		"id": "usb_backup",
		"title": "PENDRIVE BOOTEABLE & RESPALDO",
		"subtitle": "HERRAMIENTA USB · TRANSFERENCIA Y FLASHEO",
		"category": "HERRAMIENTA TÉCNICA",
		"texture_path": "",
		"color_accent": Color(0.15, 0.9, 1.0, 1.0),
		"que_es": "Preparación y uso de la herramienta principal de Sistemas: la unidad flash USB booteable para instalación, respaldo de datos y recuperación.",
		"importancia": "CRÍTICA: Es el instrumento físico indispensable del técnico de soporte. La desconexión en caliente sin sincronizar búferes corrompe las particiones.",
		"que_hace": "Conecta la unidad en el puerto USB 3.2, transfiere imágenes ISO y copias de seguridad de clientes, y ejecuta la extracción segura.",
		"pasos": "1. Conecta el pendrive en el puerto USB 3.2 del equipo.\n2. Selecciona y transfiere los 4 archivos críticos (ISO, Backup, Drivers, Kit de Rescate).\n3. Presiona 'INICIAR ESCRITURA Y RESPALDO' para grabar los datos a 185 MB/s.\n4. Presiona 'EXPULSAR Y DESCONECTAR' para retirar el pendrive de forma segura.",
		"is_ready": true,
		"handler": "launch_usb_backup"
	},

	# --- DIVISIÓN SERVIDOR (INFRAESTRUCTURA & RACKS) ---
	{
		"division": "servidor",
		"id": "rack_mount",
		"title": "MONTAJE EN RACK",
		"subtitle": "CHASIS DE 19 PULGADAS (1U - 4U)",
		"category": "INFRAESTRUCTURA",
		"texture_path": "",
		"color_accent": Color(1.0, 0.12, 0.3, 1.0),
		"que_es": "Instalación física estandarizada de servidores de alta densidad en cabinas tipo rack mediante rieles telescópicos y cerrojos Quick-Release.",
		"importancia": "ALTA: Maximiza la densidad física en el datacenter y garantiza una estructura sismorresistente con flujo de aire canalizado.",
		"que_hace": "Permite deslizar el chasis del servidor hacia afuera para realizar mantenimiento y cambio de partes sin desconectar el resto del rack.",
		"pasos": "1. Identifica las unidades de rack (U) asignadas en el bastidor.\n2. Desacopla las trabas de seguridad de los rieles telescópicos.\n3. Desliza el chasis hasta la posición de servicio para inspección de placa.",
		"is_ready": true,
		"handler": "launch_mobo"
	},
	{
		"division": "servidor",
		"id": "raid_array",
		"title": "BAHÍAS SAS CADDIES & RAID",
		"subtitle": "DISCOS HOT-SWAP SAS 15K / U.3 NVME",
		"category": "ALMACENAMIENTO EMPRESARIAL",
		"texture_path": "",
		"color_accent": Color(0.95, 0.18, 0.45, 1.0),
		"que_es": "Bandejas extraíbles frontales con traba mecánica para sustitución de discos en caliente sin apagar el servidor.",
		"importancia": "CRÍTICA: En un entorno de producción 24/7, un disco defectuoso debe sustituirse de inmediato sin interrumpir bases de datos.",
		"que_hace": "Conecta unidades de alta velocidad al backplane SAS a 12 Gb/s con sincronización automática de paridad RAID.",
		"pasos": "1. Presiona el botón de expulsión de la bandeja frontal (Caddy).\n2. Tira de la palanca basculante y extrae la unidad defectuosa.\n3. Inserta el disco SAS funcional y cierra la palanca hasta escuchar el 'clic'.",
		"is_ready": true,
		"handler": "launch_hdd"
	},
	{
		"division": "servidor",
		"id": "server_psu",
		"title": "FUENTES 1+1 HOT-SWAP",
		"subtitle": "REDUNDANCIA DE POTENCIA 1200W PLATINUM",
		"category": "ENERGÍA CRÍTICA",
		"texture_path": "",
		"color_accent": Color(1.0, 0.65, 0.2, 1.0),
		"que_es": "Módulos de potencia redundantes en caliente N+1 que distribuyen corriente continua al busbar del chasis.",
		"importancia": "MÁXIMA: Si una fuente falla por sobretensión, la segunda unidad absorbe instantáneamente la carga sin apagar el sistema.",
		"que_hace": "Suministra energía ininterrumpida y permite extraer el módulo dañado tirando de la manija ergonómica.",
		"pasos": "1. Presiona la palanca de liberación rápida en el frontal del módulo de poder.\n2. Tira de la manija para deslizar la fuente averiada fuera del túnel.\n3. Desliza la nueva fuente Platinum hasta el enganche mecánico del conector ciego.",
		"is_ready": true,
		"handler": "launch_psu"
	},
	{
		"division": "servidor",
		"id": "server_fan",
		"title": "FAN WALL DE TURBINAS",
		"subtitle": "MÓDULOS DE PRESIÓN ESTÁTICA TOOL-LESS",
		"category": "REFRIGERACIÓN RACK",
		"texture_path": "",
		"color_accent": Color(0.2, 0.95, 0.7, 1.0),
		"que_es": "Matriz intermedia de ventiladores contrarrotativos de alta presión con extracción vertical sin herramientas.",
		"importancia": "CRÍTICA: Las toberas deben superar la resistencia del radiador y los bancos de memoria para evitar estrangulamiento térmico.",
		"que_hace": "Fuerza un caudal de aire continuo desde el pasillo frío hacia el pasillo caliente manteniendo los CPUs a menos de 65°C.",
		"pasos": "1. Levanta el seguro del módulo de ventilación correspondiente.\n2. Extrae la turbina defectuosa verticalmente del zócalo ciego.\n3. Inserta la turbina de repuesto asegurando el contacto en la bahía de alimentación.",
		"is_ready": true,
		"handler": "launch_cooler"
	},
	{
		"division": "servidor",
		"id": "server_ram",
		"title": "BANCOS RAM ECC REGISTRADA",
		"subtitle": "OCTA-CHANNEL DDR5 CON PROTECCIÓN DE BIT",
		"category": "MEMORIA EMPRESARIAL",
		"texture_path": "",
		"color_accent": Color(0.85, 0.1, 0.95, 1.0),
		"que_es": "Módulos de memoria con registro de búfer (RDIMM) y circuito integrado para corrección de errores de un solo bit (ECC).",
		"importancia": "VITAL: Previene la corrupción de memoria causada por rayos cósmicos o fluctuaciones de voltaje en servidores de alta densidad.",
		"que_hace": "Mantiene la integridad de datos corporativos procesando accesos paralelos en arquitectura de 8 canales por socket.",
		"pasos": "1. Abre los dos pestillos reforzados de seguridad en los extremos del slot.\n2. Extrae el módulo defectuoso en línea recta hacia arriba.\n3. Alinea la muesca polarizada de la RAM ECC y presiona firmemente hasta trabar los seguros.",
		"is_ready": true,
		"handler": "launch_ram"
	},
	{
		"division": "servidor",
		"id": "server_cpu",
		"title": "DUAL CPU ENTERPRISE",
		"subtitle": "SOCKETS INDUSTRIALES LGA 4189 / SP5",
		"category": "PROCESAMIENTO RACK",
		"texture_path": "",
		"color_accent": Color(0.9, 0.15, 0.9, 1.0),
		"que_es": "Configuración de doble procesador Xeon/EPYC montados sobre matrices de miles de pines con marco portador (Carrier Frame).",
		"importancia": "MÁXIMA: La torsión asimétrica puede destruir los pines microscópicos del zócalo o causar desconexión en buses PCIe.",
		"que_hace": "Coordina cientos de hilos de procesamiento y controladores de memoria dedicados a escala de centros de datos.",
		"pasos": "1. Libera las palancas de tensión mecánica del socket industrial.\n2. Retira la cubierta de carga con cuidado uniforme.\n3. Posiciona el procesador guiándote por el triángulo indicador y bloquea la sujeción.",
		"is_ready": true,
		"handler": "launch_cpu"
	},
	{
		"division": "servidor",
		"id": "server_smartnic",
		"title": "RISER PCIE & SMARTNIC 100G",
		"subtitle": "EXPANSIÓN MODULAR DE RED",
		"category": "CONECTIVIDAD RACK",
		"texture_path": "",
		"color_accent": Color(0.9, 0.15, 0.45, 1.0),
		"que_es": "Tarjeta de red aceleradora SmartNIC de 100 GbE montada sobre ranura Riser de perfil bajo.",
		"importancia": "ALTA: Conecta el chasis al switch Top-of-Rack sin generar cuellos de botella en el tráfico este-oeste.",
		"que_hace": "Descarga procesamiento de red del CPU y encamina paquetes a velocidad de cable.",
		"pasos": "1. Asienta la tarjeta SmartNIC en la ranura Riser PCIe.\n2. Traba el pestillo de seguridad del slot.\n3. Asegura el tornillo del bracket metálico y conecta el enlace.",
		"is_ready": true,
		"handler": "launch_gpu"
	},
	{
		"division": "servidor",
		"id": "vlan_switch",
		"title": "TERMINAL & SCRIPTING DE RED",
		"subtitle": "PROGRAMACIÓN Y DEPURACIÓN DE SERVIDOR",
		"category": "AUTOMATIZACIÓN & SISTEMAS",
		"texture_path": "",
		"color_accent": Color(0.2, 0.9, 0.6, 1.0),
		"que_es": "Terminal de consola para depuración y compilación de scripts de automatización, enrutamiento y cortafuegos del servidor.",
		"importancia": "CRÍTICA: Errores de sintaxis o bucles infinitos en scripts de administración congelan los servicios y tumban la red.",
		"que_hace": "Permite auditar el código fuente en tiempo real, corregir variables y verificar pruebas unitarias de conectividad.",
		"pasos": "1. Abre la terminal de depuración en la estación del servidor.\n2. Corrige los errores de sintaxis y tipografía en el código de auditoría.\n3. Asegura el incremento de bucles de control y compila pasando todos los tests unitarios.",
		"is_ready": true,
		"handler": "launch_code_debugger"
	},
	{
		"division": "servidor",
		"id": "cold_aisle",
		"title": "LOOP LÍQUIDO & GESTIÓN TÉRMICA",
		"subtitle": "DIRECT-TO-CHIP CON RACORES QDC",
		"category": "REFRIGERACIÓN INDUSTRIAL",
		"texture_path": "",
		"color_accent": Color(0.1, 0.9, 1.0, 1.0),
		"que_es": "Circuito de refrigeración líquida industrial con acoples rápidos antigoteo (Quick Disconnect Couplings) y purga de rack.",
		"importancia": "VITAL: Un fallo en la circulación de refrigerante en racks de 30kW provoca daños irreversibles por calor en minutos.",
		"que_hace": "Remueve el calor directamente de los dies de CPUs y aceleradores enviándolo al intercambiador de calor del datacenter.",
		"pasos": "1. Conecta los tubos y racores QDC cerrando el circuito de refrigeración.\n2. Llena el depósito de fluido refrigerante al 100% de capacidad.\n3. Activa la bomba para purgar el aire y estabilizar la presión y temperatura.",
		"is_ready": true,
		"handler": "launch_liquid_cooling"
	}
]

# =============================================================================
# INICIALIZACIÓN
# =============================================================================
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	modulate = Color.WHITE
	btn_volver.pressed.connect(_on_volver_pressed)
	
	# Pestañas principales (Niveles vs Tutoriales) - Conexión instantánea
	btn_niveles.pressed.connect(func(): _switch_main_tab("niveles"))
	btn_tutoriales.pressed.connect(func(): _switch_main_tab("tutoriales"))
	
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
	if tutorial_info_panel:
		tutorial_info_panel.visible = false
		tutorial_info_panel.launch_requested.connect(_on_btn_play_level_pressed)
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
		
	# Selector Circular de Modo & Decoración Flipped en el lateral derecho
	if decoracion_right and decoracion_right.material:
		decoracion_right.material = decoracion_right.material.duplicate()
		
	if btn_up_arrow:
		btn_up_arrow.pressed.connect(func(): _cycle_mode(-1))
	if btn_down_arrow:
		btn_down_arrow.pressed.connect(func(): _cycle_mode(1))
		
	if bubble_reparacion:
		var hit = bubble_reparacion.get_node_or_null("Hitbox")
		if hit: hit.pressed.connect(func(): _switch_mode("reparacion"))
	if bubble_sistema:
		var hit = bubble_sistema.get_node_or_null("Hitbox")
		if hit: hit.pressed.connect(func(): _switch_mode("sistema"))
	if bubble_servidor:
		var hit = bubble_servidor.get_node_or_null("Hitbox")
		if hit: hit.pressed.connect(func(): _switch_mode("servidor"))
		
	if initial_mode != "" and (initial_mode == "reparacion" or initial_mode == "sistema" or initial_mode == "servidor"):
		current_mode = initial_mode
		
	_init_mode_wheel()
	_apply_mode_palette(current_mode, true)
	if graph_lines and graph_lines.has_method("transition_to_mode") and current_mode != "reparacion":
		graph_lines.transition_to_mode(current_mode)
		
	_create_node_hitboxes()
	
	# Configurar pestaña inicial solicitada
	var start_tab = initial_tab
	initial_tab = "niveles" # Reiniciar por defecto
	
	if start_tab == "tutoriales":
		_switch_main_tab("tutoriales", true)
	else:
		_switch_main_tab("niveles", true)

func _process(_delta: float) -> void:
	if current_tab == "niveles" and graph_lines and "is_transitioning" in graph_lines and graph_lines.is_transitioning:
		_update_node_hitboxes_positions()



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
		tutorial_area.visible = false
		constellation_area.visible = true
		column_headers.visible = true
		_update_headers_for_mode()
		footer_hint.text = "⌜  CLIC EN CUALQUIER NODO PARA INSPECCIONAR SUS DATOS TÉCNICOS  ⌟"
		
		if not instant:
			constellation_area.modulate.a = 0.5
			var tw = create_tween()
			tw.tween_property(constellation_area, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_QUAD)
	else:
		constellation_area.visible = false
		column_headers.visible = false
		tutorial_area.visible = true
		banner_label.text = "CENTRO DE ENTRENAMIENTO // GUÍA TÉCNICA Y SIMULADORES"
		footer_hint.text = "⌜  SELECCIONA UNA TARJETA PARA VER DETALLES O PRACTICAR EN EL SIMULADOR  ⌟"
		_filter_tutorial_cards()
		
		if not instant:
			tutorial_area.modulate.a = 0.5
			var tw = create_tween()
			tw.tween_property(tutorial_area, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_QUAD)

func _update_tab_buttons_visuals() -> void:
	var is_niv = (current_tab == "niveles")
	var pal = MODE_PALETTES.get(current_mode, MODE_PALETTES["reparacion"])
	
	if is_niv:
		btn_niveles.modulate = Color(1.3, 1.3, 1.3, 1.0)
		if "border_color" in btn_niveles:
			btn_niveles.border_color = pal.accent
		btn_tutoriales.modulate = Color(0.65, 0.65, 0.72, 0.75)
		if "border_color" in btn_tutoriales:
			btn_tutoriales.border_color = Color(0.45, 0.15, 0.6, 0.6)
	else:
		btn_tutoriales.modulate = Color(1.3, 1.3, 1.3, 1.0)
		if "border_color" in btn_tutoriales:
			btn_tutoriales.border_color = pal.accent
		btn_niveles.modulate = Color(0.65, 0.65, 0.72, 0.75)
		if "border_color" in btn_niveles:
			btn_niveles.border_color = Color(0.45, 0.15, 0.6, 0.6)
			
	if btn_niveles.has_method("queue_redraw"):
		btn_niveles.queue_redraw()
	if btn_tutoriales.has_method("queue_redraw"):
		btn_tutoriales.queue_redraw()

# =============================================================================
# SELECTOR CIRCULAR DE MODO 3D & RUEDA ORBITAL (LATERAL DERECHO)
# =============================================================================
func _init_mode_wheel() -> void:
	var init_idx = MODE_ORDER.find(current_mode)
	if init_idx == -1:
		init_idx = 0
	_wheel_target_angle = -float(init_idx) * (TAU / 3.0)
	_wheel_visual_angle = _wheel_target_angle
	_update_wheel_visuals()

func _cycle_mode(direction: int) -> void:
	if is_level_zoomed:
		return
	var cur_idx = MODE_ORDER.find(current_mode)
	if cur_idx == -1:
		cur_idx = 0
	var next_idx = posmod(cur_idx + direction, MODE_ORDER.size())
	_switch_mode(MODE_ORDER[next_idx], direction)

func _animate_wheel_step(val: float) -> void:
	_wheel_visual_angle = val
	_update_wheel_visuals()

func _update_wheel_visuals() -> void:
	var bubbles = [bubble_reparacion, bubble_sistema, bubble_servidor]
	if not mode_wheel_area or bubbles.any(func(b): return b == null):
		return

	var center = Vector2(mode_wheel_area.size.x * 0.5, mode_wheel_area.size.y * 0.5)
	var rx = 26.0
	var ry = 70.0

	for i in range(bubbles.size()):
		var b = bubbles[i]
		var ang = _wheel_visual_angle + float(i) * (TAU / 3.0)
		var bx = -cos(ang) * rx
		var by = sin(ang) * ry
		var depth = (cos(ang) + 1.0) * 0.5 # 1.0 al frente, 0.0 atrás

		b.position = center + Vector2(bx - 30.0, by - 30.0)
		var sc = lerp(0.74, 1.25, depth)
		b.scale = Vector2(sc, sc)
		b.modulate.a = lerp(0.42, 1.0, depth)
		b.z_index = int(depth * 10)
		b.rotation = sin(ang) * 0.12

		var title_lbl = b.get_node_or_null("TitleLabel")
		var bg_circle = b.get_node_or_null("BgCircle")
		var is_front = (depth > 0.82)

		if title_lbl:
			title_lbl.modulate.a = lerp(0.0, 1.0, clampf((depth - 0.6) / 0.35, 0.0, 1.0))
		if bg_circle:
			var mode_name = MODE_ORDER[i]
			var pal = MODE_PALETTES.get(mode_name, MODE_PALETTES["reparacion"])
			bg_circle.modulate = pal.accent if is_front else pal.accent_dim

func _apply_mode_palette(mode_name: String, instant: bool = false) -> void:
	var pal = MODE_PALETTES.get(mode_name, MODE_PALETTES["reparacion"])

	if instant:
		if background_rect:
			background_rect.color = pal.bg_color
		if decoracion_right and decoracion_right.material is ShaderMaterial:
			var mat: ShaderMaterial = decoracion_right.material
			mat.set_shader_parameter("top_color", pal.holo_top)
			mat.set_shader_parameter("bottom_color", pal.holo_bottom)
			mat.set_shader_parameter("edge_color", pal.holo_edge)
		if banner_label:
			banner_label.add_theme_color_override("font_color", pal.banner_font)
			banner_label.add_theme_color_override("font_shadow_color", pal.banner_shadow)
		return

	if _color_tween and _color_tween.is_valid():
		_color_tween.kill()
	_color_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if background_rect:
		_color_tween.tween_property(background_rect, "color", pal.bg_color, 0.20)

	if decoracion_right and decoracion_right.material is ShaderMaterial:
		var mat: ShaderMaterial = decoracion_right.material
		_color_tween.tween_property(mat, "shader_parameter/top_color", pal.holo_top, 0.20)
		_color_tween.tween_property(mat, "shader_parameter/bottom_color", pal.holo_bottom, 0.20)
		_color_tween.tween_property(mat, "shader_parameter/edge_color", pal.holo_edge, 0.20)

	if banner_label:
		var cur_font_c = banner_label.get_theme_color("font_color")
		var cur_shad_c = banner_label.get_theme_color("font_shadow_color")
		_color_tween.tween_method(func(c: Color): banner_label.add_theme_color_override("font_color", c), cur_font_c, pal.banner_font, 0.20)
		_color_tween.tween_method(func(c: Color): banner_label.add_theme_color_override("font_shadow_color", c), cur_shad_c, pal.banner_shadow, 0.20)

# =============================================================================
# CONMUTACIÓN DE MODO / DIVISIÓN (REPARACIÓN, SISTEMA, SERVIDOR)
# =============================================================================
func _switch_mode(mode_name: String, spin_dir: int = 0) -> void:
	if is_level_zoomed:
		_unzoom_camera()
	if current_mode == mode_name and spin_dir == 0:
		return
		
	current_mode = mode_name
	var cur_idx = MODE_ORDER.find(current_mode)
	if cur_idx == -1:
		cur_idx = 0

	if spin_dir != 0:
		_wheel_target_angle -= float(spin_dir) * (TAU / 3.0)
	else:
		var target_base = -float(cur_idx) * (TAU / 3.0)
		var diff = wrapf(target_base - _wheel_visual_angle, -PI, PI)
		_wheel_target_angle = _wheel_visual_angle + diff

	if _wheel_tween and _wheel_tween.is_valid():
		_wheel_tween.kill()
	_wheel_tween = create_tween().set_parallel(true)
	_wheel_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_wheel_tween.tween_method(_animate_wheel_step, _wheel_visual_angle, _wheel_target_angle, 0.22)

	if btn_up_arrow and spin_dir < 0:
		var tw_arr = create_tween()
		tw_arr.tween_property(btn_up_arrow, "scale", Vector2(1.2, 1.2), 0.08)
		tw_arr.tween_property(btn_up_arrow, "scale", Vector2.ONE, 0.12)
	elif btn_down_arrow and spin_dir > 0:
		var tw_arr = create_tween()
		tw_arr.tween_property(btn_down_arrow, "scale", Vector2(1.2, 1.2), 0.08)
		tw_arr.tween_property(btn_down_arrow, "scale", Vector2.ONE, 0.12)

	_apply_mode_palette(current_mode, false)
	_update_mode_buttons()
	_update_tab_buttons_visuals()
	_update_btn_play_level1_visibility()
	
	if current_tab == "niveles":
		_update_headers_for_mode()
		if graph_lines and graph_lines.has_method("transition_to_mode"):
			graph_lines.transition_to_mode(current_mode)
		_create_node_hitboxes()
		_update_node_hitboxes_positions()
	else:
		_filter_tutorial_cards()
		cards_scroll.scroll_vertical = 0
		cards_grid.modulate.a = 0.5
		var tw = create_tween()
		tw.tween_property(cards_grid, "modulate:a", 1.0, 0.1)

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
	match current_mode:
		"reparacion":
			banner_label.text = "SECCIÓN DE REPARACIÓN // TELARAÑA DE HARDWARE"
			col1_label.text = "NÚCLEO TUTORIAL & ETAPA 1 [1-4]"
			col2_label.text = "ETAPA 2: HARDWARE AVANZADO [5-8]"
			col3_label.text = "ETAPA 3: MAESTRÍA DE DIAGNÓSTICO [9-12]"
		"reparacion_fondo":
			banner_label.text = "SECCIÓN: REPARACIÓN A FONDO // MANTENIMIENTO AVANZADO DE CPU"
			col1_label.text = "PASTA TÉRMICA"
			col2_label.text = "ALINEACIÓN DE PINES"
			col3_label.text = "CALIBRACIÓN"
		"sistema":
			banner_label.text = "SECCIÓN DE SISTEMA // TELARAÑA DE RED LÓGICA"
			col1_label.text = "NÚCLEO TUTORIAL & ETAPA 1 [1-4]"
			col2_label.text = "ETAPA 2: KERNEL & DRIVERS [5-8]"
			col3_label.text = "ETAPA 3: CIBERSEGURIDAD & RESCATE [9-12]"
		"servidor":
			banner_label.text = "SECCIÓN DE SERVIDOR // TELARAÑA DE DATACENTER"
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
	var node_pos = graph_lines.nodes[index] if (graph_lines and index < graph_lines.nodes.size()) else Vector2(580, 410)
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
	if data.get("is_tutorial", false):
		# BURBUJA AZUL TUTORIAL - Mostrar Panel de Información del Tutorial
		if difficulty_selector and difficulty_selector.visible:
			difficulty_selector.play_exit_animation()
		if tutorial_info_panel:
			tutorial_info_panel.open_for_tutorial_node(data)
	elif data.get("is_practice", false):
		# SALA DE PRÁCTICA (NARANJA NEÓN) - Mostrar Panel en modo práctica libre
		if difficulty_selector and difficulty_selector.visible:
			difficulty_selector.play_exit_animation()
		if tutorial_info_panel:
			tutorial_info_panel.open_for_practice(data)
	else:
		# NIVEL JUGABLE (Nivel 1 al 12)
		if tutorial_info_panel and tutorial_info_panel.visible:
			tutorial_info_panel.play_exit_animation()
		if difficulty_selector:
			difficulty_selector.open_for_level()
		
	# Habilitar el overlay invisible de captura de clics fuera de la tarjeta
	if card_dim_overlay:
		card_dim_overlay.visible = true
		card_dim_overlay.color = Color(0, 0, 0, 0)

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
		constellation_area.pivot_offset = Vector2(580, 395)
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
	if not is_level_zoomed:
		return
	var list = LEVELS_DATA.get(current_mode, [])
	if list.is_empty():
		return
		
	var total = list.size()
	var new_index = active_zoomed_index + direction
	if new_index < 0:
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
		constellation_area.pivot_offset = Vector2(580, 395)
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
		decoracion_right,
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

	if difficulty_selector and not (is_level_zoomed and not is_tut and not is_prac and current_tab == "niveles"):
		difficulty_selector.visible = false
	if tutorial_info_panel and not (is_level_zoomed and (is_tut or is_prac) and current_tab == "niveles"):
		tutorial_info_panel.visible = false

func _on_btn_play_level_pressed() -> void:
	var list = LEVELS_DATA.get(current_mode, [])
	var node_data: Dictionary = {}
	if active_zoomed_index >= 0 and active_zoomed_index < list.size():
		node_data = list[active_zoomed_index]

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
	else:
		# NIVEL DE JUEGO (Nivel 1 al 12)
		if node_data.get("can_play", false):
			_play_level_1()
		else:
			is_launching_level = false
			_show_toast("🔒 Este nivel está bloqueado. Supera el nivel anterior para desbloquearlo.")

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
	_close_deployed_card()
	_play_tutorial_level(comp_id)

func _on_deployed_play_pressed() -> void:
	if active_card_data.is_empty():
		return
		
	if not active_card_data.get("is_ready", false):
		_show_toast("Este simulador estará disponible en la próxima actualización.")
		return
		
	match active_card_data.get("handler", ""):
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

func _launch_minigame(scene: PackedScene) -> void:
	if not scene:
		return
	if is_instance_valid(current_minigame_instance):
		current_minigame_instance.queue_free()
		
	var inst = scene.instantiate()
	current_minigame_instance = inst
	minigame_container.add_child(inst)
	
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
	var player = AudioStreamPlayer.new()
	player.stream = load("res://efectos/sonido de entrada.ogg")
	player.volume_db = -2.0
	player.pitch_scale = 0.82 # Modulación grave sci-fi de desconexión
	player.bus = "Master"
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

	# Selector de modo y decoración derecha se deslizan a la derecha
	if decoracion_right:
		tw_ui.tween_property(decoracion_right, "position:x", decoracion_right.position.x + 220.0, 0.30)
		tw_ui.tween_property(decoracion_right, "modulate:a", 0.0, 0.26)
	if circular_mode_selector:
		tw_ui.tween_property(circular_mode_selector, "position:x", circular_mode_selector.position.x + 220.0, 0.30)
		tw_ui.tween_property(circular_mode_selector, "modulate:a", 0.0, 0.26)
		_wheel_target_angle += TAU * 1.5
		if _wheel_tween and _wheel_tween.is_valid():
			_wheel_tween.kill()
		_wheel_tween = create_tween()
		_wheel_tween.tween_method(_animate_wheel_step, _wheel_visual_angle, _wheel_target_angle, 0.30)

	# Constelación de niveles: Implosión hacia el centro con rotación
	if constellation_area:
		constellation_area.pivot_offset = Vector2(580, 395)
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

func _input(event: InputEvent) -> void:
	if is_exiting_scene or is_launching_level:
		get_viewport().set_input_as_handled()
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

	# 2. Navegación de cámara entre niveles con flechas de teclado (activa cuando se está inspeccionando un nivel)
	if is_level_zoomed and current_tab == "niveles" and not (deployed_modal and deployed_modal.visible):
		var is_left: bool = (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_LEFT or event.physical_keycode == KEY_LEFT or event.keycode == KEY_A)) \
			or event.is_action_pressed("ui_left")
		var is_right: bool = (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_RIGHT or event.physical_keycode == KEY_RIGHT or event.keycode == KEY_D)) \
			or event.is_action_pressed("ui_right")
		if is_left:
			get_viewport().set_input_as_handled()
			_navigate_level_camera(-1)
			return
		elif is_right:
			get_viewport().set_input_as_handled()
			_navigate_level_camera(1)
			return
