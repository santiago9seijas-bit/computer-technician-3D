class_name LevelSelect
extends Control

# =============================================================================
# LEVEL SELECT & CENTRO DE ENTRENAMIENTO // SISTEMA UNIFICADO DE NIVELES Y TUTORIALES
# CAMBIO INSTANTÁNEO DE PESTAÑAS (0 MS RETRASO, SIN RECARGA DE ESCENA)
# =============================================================================

static var initial_tab: String = "niveles"

# --- Nodos Principales ---
@onready var btn_volver: Button = $TopBar/BtnVolver
@onready var btn_niveles: Button = $TopBar/Tabs/BtnNiveles
@onready var btn_tutoriales: Button = $TopBar/Tabs/BtnTutoriales
@onready var top_bar: HBoxContainer = $TopBar
@onready var mode_selector: HBoxContainer = $ModeSelector
@onready var btn_reparacion: Button = $ModeSelector/BtnReparacion
@onready var btn_fondo: Button = $ModeSelector/BtnFondo
@onready var btn_sistema: Button = $ModeSelector/BtnSistema
@onready var btn_servidor: Button = $ModeSelector/BtnServidor
@onready var section_banner: PanelContainer = $SectionBanner
@onready var banner_label: Label = $SectionBanner/BannerLabel
@onready var column_headers: HBoxContainer = $ColumnHeaders
@onready var col1_label: Label = $ColumnHeaders/Col1
@onready var col2_label: Label = $ColumnHeaders/Col2
@onready var col3_label: Label = $ColumnHeaders/Col3
@onready var footer_hint: Label = $FooterHint

# --- Área de Constelación (Niveles) ---
@onready var constellation_area: Control = $ConstellationArea
@onready var graph_lines: Control = $ConstellationArea/GraphLines
@onready var card_dim_overlay: ColorRect = $CardDimOverlay
@onready var btn_play_level1: Button = $BtnPlayLevel1

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
@onready var lbl_que_es: Label = $DeployedModal/DeployedCard/Margin/VBox/ContentHBox/RightCol/Margin/Scroll/TextVBox/LblQueEs
@onready var lbl_importancia: Label = $DeployedModal/DeployedCard/Margin/VBox/ContentHBox/RightCol/Margin/Scroll/TextVBox/LblImportancia
@onready var lbl_que_hace: Label = $DeployedModal/DeployedCard/Margin/VBox/ContentHBox/RightCol/Margin/Scroll/TextVBox/LblQueHace
@onready var lbl_pasos: Label = $DeployedModal/DeployedCard/Margin/VBox/ContentHBox/RightCol/Margin/Scroll/TextVBox/LblPasos
@onready var minigame_container: Control = $MinigameContainer

# --- Recursos Pre-cargados ---
var glitch_material = preload("res://styles/cyber_glitch_sprite.tres")
var title_font = preload("res://assets/fonts/Bungee-Regular.ttf")

var PRELOADED_TEXTURES = {
	"res://pixel art/fancooler conectado.png": preload("res://pixel art/fancooler conectado.png"),
	"res://pixel art/ram.png": preload("res://pixel art/ram.png"),
	"res://pixel art/hdd.png": preload("res://pixel art/hdd.png"),
	"res://pixel art/fondos de menus.png": preload("res://pixel art/fondos de menus.png")
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

# =============================================================================
# BASE DE DATOS DE LOS 12 NIVELES POR MODO (TODOS BLOQUEADOS CON INSPECCIÓN ACTIVA)
# =============================================================================
var LEVELS_DATA: Dictionary = {
	"reparacion": [
		{
			"number": 1,
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
			"title": "NIVEL 3 · UNIDAD SATA Y TORNILLOS",
			"stage": "ETAPA I: TALLER BÁSICO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(1.0, 0.2, 0.45),
			"description": "Equipos que no detectan disco duro en bahías frontales.\nRetira tornillo de seguridad, desconecta bus de datos SATA e instala disco funcional desde la mochila técnica.",
			"requirements": "HERRAMIENTAS: Destornilladores y repuestos · LÍMITE: 100s · RECOMPENSA: 150 PTS",
			"can_play": false
		},
		{
			"number": 4,
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
			"title": "NIVEL 5 · TARJETA GRÁFICA PCIE",
			"stage": "ETAPA II: HARDWARE AVANZADO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.9, 0.1, 0.7),
			"description": "Artefactos visuales y pérdida de señal HDMI/DP bajo carga 3D.\nDesacopla traba PCIe x16, desconecta arnés de 8 pines y sustituye por GPU operativa.",
			"requirements": "HERRAMIENTAS: Extractor PCIe · LÍMITE: 90s · RECOMPENSA: 220 PTS",
			"can_play": false
		},
		{
			"number": 6,
			"title": "NIVEL 6 · FUENTE DE PODER ATX",
			"stage": "ETAPA II: HARDWARE AVANZADO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.9, 0.1, 0.7),
			"description": "Cortocircuito en rieles de 12V. La máquina se apaga a los 2 segundos.\nComprueba continuidad con multímetro e instala fuente conmutada 80 Plus Gold.",
			"requirements": "HERRAMIENTAS: Multímetro digital · LÍMITE: 85s · RECOMPENSA: 250 PTS",
			"can_play": false
		},
		{
			"number": 7,
			"title": "NIVEL 7 · PLACA MADRE VRM",
			"stage": "ETAPA II: HARDWARE AVANZADO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.85, 0.05, 0.85),
			"description": "Fase de alimentación VRM con condensadores sólidos en corto.\nDesmontaje completo del chasis y sustitución modular con torque controlado.",
			"requirements": "HERRAMIENTAS: Llaves hexagonales · LÍMITE: 80s · RECOMPENSA: 300 PTS",
			"can_play": false
		},
		{
			"number": 8,
			"title": "NIVEL 8 · PUERTOS FRONTALES Y CORTO",
			"stage": "ETAPA II: HARDWARE AVANZADO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.85, 0.05, 0.85),
			"description": "Pines doblados en cabezal USB 3.2 interno que disparan protección por sobrecorriente en chipset.",
			"requirements": "HERRAMIENTAS: Lupa técnica · LÍMITE: 75s · RECOMPENSA: 350 PTS",
			"can_play": false
		},
		{
			"number": 9,
			"title": "NIVEL 9 · REFRIGERACIÓN LÍQUIDA AIO",
			"stage": "ETAPA III: MAESTRÍA DE DIAGNÓSTICO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.75, 0.05, 0.95),
			"description": "Bomba AIO bloqueada con burbujas de aire y obstrucción de microcanales.\nPurga de refrigerante dieléctrico y recalibración de bomba en cabezal AIO_PUMP.",
			"requirements": "HERRAMIENTAS: Kit purga y refrigerante · LÍMITE: 70s · RECOMPENSA: 400 PTS",
			"can_play": false
		},
		{
			"number": 10,
			"title": "NIVEL 10 · BACKPLATE CPU & ANCLAJES",
			"stage": "ETAPA III: MAESTRÍA DE DIAGNÓSTICO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.75, 0.05, 0.95),
			"description": "Placa trasera deformada por torsión térmica causando falso contacto en pines del socket LGA.",
			"requirements": "HERRAMIENTAS: Dinamómetro de precisión · LÍMITE: 65s · RECOMPENSA: 450 PTS",
			"can_play": false
		},
		{
			"number": 11,
			"title": "NIVEL 11 · BANCO DE MEMORIAS QUAD-CHANNEL",
			"stage": "ETAPA III: MAESTRÍA DE DIAGNÓSTICO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(0.65, 0.05, 1.0),
			"description": "Configuración de 4 módulos en bus entrelazado. Errores intermitentes a 6400 MT/s bajo perfil XMP.",
			"requirements": "HERRAMIENTAS: Analizador de bus DDR · LÍMITE: 60s · RECOMPENSA: 500 PTS",
			"can_play": false
		},
		{
			"number": 12,
			"title": "NIVEL 12 · MASTER DE RESTAURACIÓN",
			"stage": "ETAPA III: MAESTRÍA DE DIAGNÓSTICO",
			"mode_name": "REPARACIÓN",
			"color_accent": Color(1.0, 0.1, 0.4),
			"description": "Estación de trabajo de ingeniería completamente inerte. Diagnóstico holístico de 7 fallas simultáneas en cadena.",
			"requirements": "EQUIPO COMPLETO DE LABORATORIO · LÍMITE: 150s · RECOMPENSA: 1000 PTS ★",
			"can_play": false
		}
	],
	"sistema": [
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
		}
	],
	"servidor": [
		{
			"number": 1,
			"title": "NIVEL 1 · BASTIDORES & RIELES 2U",
			"stage": "ETAPA I: INFRAESTRUCTURA RACK",
			"mode_name": "SERVIDOR",
			"color_accent": Color(1.0, 0.1, 0.35),
			"description": "Instalación de chasis de servidor de doble unidad (2U) en gabinete estándar de 19 pulgadas con rieles telescópicos.",
			"requirements": "TUERCAS ENJAULADAS M6 · LÍMITE: 120s · RECOMPENSA: 100 PTS",
			"can_play": false
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
		"texture_path": "res://pixel art/fancooler conectado.png",
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
		"texture_path": "res://pixel art/ram.png",
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
		"texture_path": "res://pixel art/hdd.png",
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
		"subtitle": "DESMONTAJE MAESTRO DEL CHASIS",
		"category": "ARQUITECTURA & DESARME",
		"texture_path": "",
		"color_accent": Color(0.9, 0.15, 0.6, 1.0),
		"que_es": "Circuito impreso principal que interconecta todos los módulos. Su extracción requiere retirar primero todos los componentes anclados a sus ranuras y los cables de alimentación.",
		"importancia": "CRÍTICA: Jamás intentes desatornillar la placa madre con la GPU, el cooler o la fuente conectados; el peso y la tensión de los cables pueden quebrar las pistas de cobre internas.",
		"que_hace": "Desafío maestro de taller: sintetiza la secuencia lógica completa para desensamblar una computadora desde cero hasta dejar el gabinete vacío.",
		"pasos": "🔻 FASE 1: DESMONTAJE (QUITAR):\n1. Desmonta las piezas instaladas (Cables ATX/EPS, GPU, Cooler, M.2, RAM).\n2. Desatornilla los 6 tornillos Standoff del chasis con [1] Cruz o [2] Pala.\n3. Desencastra del I/O Shield y levanta la placa madre.\n\n🔺 FASE 2: MONTAJE INVERSO (PONER):\n1. Posiciona la placa madre nueva alineándola con el I/O Shield.\n2. Ajusta los 6 tornillos Standoff con Cruz [1] o Pala [2].\n3. Conecta los arneses de alimentación ATX 24P y EPS 8P.",
		"is_ready": true,
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
		"pasos": "1. Selecciona el paño con alcohol isopropílico [2].\n2. Realiza movimientos suaves o clic sobre la mancha de pasta vieja.\n3. Frota continuamente hasta alcanzar el 100% de limpieza y evaporación del compuesto.",
		"is_ready": true,
		"handler": "launch_thermal_paste"
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
		"pasos": "1. Inspecciona la matriz de 8x10 pines bajo el microscopio óptico.\n2. Identifica los pines con desvío angular resaltados en advertencia naranja.\n3. Haz clic cuidadosamente sobre cada pin doblado para enderezarlo a 90°.\n4. Completa la corrección del 100% de los pines averiados.",
		"is_ready": true,
		"handler": "launch_cpu_pins"
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
		"que_es": "Instalación física estandarizada de servidores de alta densidad en cabinas tipo rack mediante rieles telescópicos.",
		"importancia": "ALTA: Maximiza la utilización del espacio físico en el datacenter y garantiza una estructura sismorresistente con flujo de aire canalizado.",
		"que_hace": "Permite deslizar el chasis del servidor hacia afuera para realizar mantenimiento y cambio de partes sin desconectar el resto del rack.",
		"pasos": "1. Identifica las unidades de rack (U) asignadas en el bastidor.\n2. Fija las guías telescópicas con tuercas enjauladas M6.\n3. Desliza el chasis hasta escuchar el bloqueo mecánico de seguridad.",
		"is_ready": false,
		"handler": ""
	},
	{
		"division": "servidor",
		"id": "raid_array",
		"title": "CONFIGURACIÓN RAID",
		"subtitle": "RED DE DISCOS REDUNDANTES (0/1/5/10)",
		"category": "ALMACENAMIENTO EMPRESARIAL",
		"texture_path": "",
		"color_accent": Color(0.95, 0.18, 0.45, 1.0),
		"que_es": "Agrupación lógica de múltiples discos SAS/SATA para proporcionar tolerancia a fallos y alto rendimiento de lectura/escritura.",
		"importancia": "CRÍTICA: En un servidor empresarial, la caída de un disco duro no debe interrumpir el servicio ni provocar pérdida de bases de datos.",
		"que_hace": "Calcula bloques de paridad matemática y los distribuye entre los discos para reconstruir la información si uno falla.",
		"pasos": "1. Ingresa a la controladora RAID (MegaRAID / Smart Array).\n2. Selecciona el nivel de redundancia deseado (RAID 1 para SO, RAID 5/10 para BD).\n3. Inicializa el arreglo y asigna discos Hot Spare.",
		"is_ready": false,
		"handler": ""
	},
	{
		"division": "servidor",
		"id": "patch_panel",
		"title": "PATCH PANEL & CABLEADO",
		"subtitle": "ESTRUCTURADO CATEGORÍA 6A / FIBRA",
		"category": "CABLEADO ESTRUCTURADO",
		"texture_path": "",
		"color_accent": Color(0.7, 0.1, 0.95, 1.0),
		"que_es": "Panel de terminación de red donde convergen todos los enlaces de red de cobre o fibra óptica del datacenter.",
		"importancia": "ALTA: Mantiene la organización del cableado, previene interferencias cruzadas (crosstalk) y agiliza cambios de parcheo.",
		"que_hace": "Interconecta los servidores y estaciones de trabajo con los switches centrales mediante latiguillos organizados.",
		"pasos": "Próximamente disponible en el módulo de Servidores.",
		"is_ready": false,
		"handler": ""
	},
	{
		"division": "servidor",
		"id": "vlan_switch",
		"title": "SWITCHES & VLANS",
		"subtitle": "SEGMENTACIÓN DE RED CAPA 2/3",
		"category": "REDES DATACENTER",
		"texture_path": "",
		"color_accent": Color(0.85, 0.1, 0.9, 1.0),
		"que_es": "Conmutadores de paquetes de alta velocidad con enlaces 10G/40G/100G y soporte de redes virtuales (VLAN).",
		"importancia": "CRÍTICA: Aísla el tráfico de servidores de base de datos, servidores web y gestión administrativa para evitar ataques laterales.",
		"que_hace": "Encamina tramas con etiquetas 802.1Q a velocidad de cable y aplica listas de control de acceso (ACL).",
		"pasos": "Próximamente disponible en el módulo de Servidores.",
		"is_ready": false,
		"handler": ""
	},
	{
		"division": "servidor",
		"id": "cold_aisle",
		"title": "PASILLO FRÍO / CALOR",
		"subtitle": "GESTIÓN TÉRMICA DE DATACENTER",
		"category": "CLIMATIZACIÓN",
		"texture_path": "",
		"color_accent": Color(1.0, 0.1, 0.35, 1.0),
		"que_es": "Confinamiento físico del flujo de aire acondicionado para servidores de alta densidad.",
		"importancia": "VITAL: Evita la recirculación de aire caliente que causa sobrecalentamiento masivo y reduce drásticamente el consumo eléctrico.",
		"que_hace": "Inyecta aire frío a 20°C por la parte frontal de los gabinetes y extrae el aire caliente por el pasillo posterior sellado.",
		"pasos": "Próximamente disponible en el módulo de Servidores.",
		"is_ready": false,
		"handler": ""
	},
	{
		"division": "servidor",
		"id": "hypervisor_cluster",
		"title": "CLUSTER DE VIRTUALIZACIÓN",
		"subtitle": "HYPERVISOR KVM / ESXI DE ALTA DISPONIBILIDAD",
		"category": "VIRTUALIZACIÓN",
		"texture_path": "",
		"color_accent": Color(0.8, 0.05, 0.85, 1.0),
		"que_es": "Grupo de servidores físicos interconectados que ejecutan máquinas virtuales y contenedores con migración en caliente.",
		"importancia": "ALTA: Si un nodo físico colapsa, las máquinas virtuales se reinician en segundos en los nodos sobrevivientes.",
		"que_hace": "Virtualiza CPU, memoria y almacenamiento distribuyéndolo equitativamente entre las instancias del centro de datos.",
		"pasos": "Próximamente disponible en el módulo de Servidores.",
		"is_ready": false,
		"handler": ""
	}
]

# =============================================================================
# INICIALIZACIÓN
# =============================================================================
func _ready() -> void:
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
				# Si hace clic en el círculo ampliado del nivel 1 (radio 85px desde Vector2(260, 390)), iniciar el nivel
				if is_level_zoomed and active_zoomed_index == 0 and (current_mode == "reparacion" or current_mode == "sistema"):
					var dist = event.position.distance_to(Vector2(260, 390))
					if dist <= 85.0:
						_play_level_1()
						return
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
	if btn_play_level1:
		btn_play_level1.pressed.connect(_play_level_1)
	
	if graph_lines and graph_lines.has_signal("mode_transition_completed"):
		graph_lines.mode_transition_completed.connect(_update_node_hitboxes_positions)
		
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
	
	if is_niv:
		btn_niveles.modulate = Color(1.3, 1.3, 1.3, 1.0)
		if "border_color" in btn_niveles:
			btn_niveles.border_color = Color(1.0, 0.1, 0.4, 1.0)
		btn_tutoriales.modulate = Color(0.65, 0.65, 0.72, 0.75)
		if "border_color" in btn_tutoriales:
			btn_tutoriales.border_color = Color(0.45, 0.15, 0.6, 0.6)
	else:
		btn_tutoriales.modulate = Color(1.3, 1.3, 1.3, 1.0)
		if "border_color" in btn_tutoriales:
			btn_tutoriales.border_color = Color(1.0, 0.1, 0.4, 1.0)
		btn_niveles.modulate = Color(0.65, 0.65, 0.72, 0.75)
		if "border_color" in btn_niveles:
			btn_niveles.border_color = Color(0.45, 0.15, 0.6, 0.6)
			
	if btn_niveles.has_method("queue_redraw"):
		btn_niveles.queue_redraw()
	if btn_tutoriales.has_method("queue_redraw"):
		btn_tutoriales.queue_redraw()

# =============================================================================
# CONMUTACIÓN DE MODO / DIVISIÓN (REPARACIÓN, SISTEMA, SERVIDOR)
# =============================================================================
func _switch_mode(mode_name: String) -> void:
	if is_level_zoomed:
		_unzoom_camera()
	if current_mode == mode_name:
		return
		
	current_mode = mode_name
	_update_mode_buttons()
	_update_btn_play_level1_visibility()
	
	if current_tab == "niveles":
		_update_headers_for_mode()
		if graph_lines and graph_lines.has_method("transition_to_mode"):
			graph_lines.transition_to_mode(current_mode)
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
			banner_label.text = "SECCIÓN DE REPARACIÓN // MAPA DE HARDWARE"
			col1_label.text = "ETAPA 1: TALLER BÁSICO [1-4]"
			col2_label.text = "ETAPA 2: HARDWARE AVANZADO [5-8]"
			col3_label.text = "ETAPA 3: MAESTRÍA DE DIAGNÓSTICO [9-12]"
		"reparacion_fondo":
			banner_label.text = "SECCIÓN: REPARACIÓN A FONDO // MANTENIMIENTO AVANZADO DE CPU"
			col1_label.text = "PASTA TÉRMICA"
			col2_label.text = "ALINEACIÓN DE PINES"
			col3_label.text = "CALIBRACIÓN"
		"sistema":
			banner_label.text = "SECCIÓN DE SISTEMA // SOFTWARE, BIOS & SO"
			col1_label.text = "ETAPA 1: BIOS & BOOT [1-4]"
			col2_label.text = "ETAPA 2: KERNEL & DRIVERS [5-8]"
			col3_label.text = "ETAPA 3: CIBERSEGURIDAD & RESCATE [9-12]"
		"servidor":
			banner_label.text = "SECCIÓN DE SERVIDOR // INFRAESTRUCTURA & RACKS"
			col1_label.text = "ETAPA 1: BASTIDORES RACK [1-4]"
			col2_label.text = "ETAPA 2: ALMACENAMIENTO RAID [5-8]"
			col3_label.text = "ETAPA 3: DATACENTER & CLOUD [9-12]"

# =============================================================================
# HITBOXES DE NODOS (MODO NIVELES)
# =============================================================================
func _create_node_hitboxes() -> void:
	for b in node_buttons:
		b.queue_free()
	node_buttons.clear()
	
	for i in range(12):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(60, 60)
		btn.flat = true
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
	
	# Si ya está en zoom sobre el nivel 1 y hacen clic sobre el nodo 1, lanzar el nivel inmediatamente
	if is_level_zoomed and active_zoomed_index == 0 and index == 0 and (current_mode == "reparacion" or current_mode == "sistema"):
		_play_level_1()
		return
		
	is_level_zoomed = true
	active_zoomed_index = index
	
	if graph_lines and graph_lines.has_method("trigger_node_click_zoom"):
		graph_lines.trigger_node_click_zoom(index)
		
	# ZOOM DE CÁMARA AL CÍRCULO CLICKEADO:
	# El mapa hace zoom y encuadra el círculo ampliado en el lado izquierdo (X=260, Y=390)
	var node_pos = graph_lines.nodes[index] if (graph_lines and index < graph_lines.nodes.size()) else Vector2(120, 440)
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
		
	# Mostrar el botón "DALE CLIC PARA INICIAR" bajo el círculo ampliado SOLO cuando se da clic al nivel 1
	if btn_play_level1:
		if index == 0 and (current_mode == "reparacion" or current_mode == "sistema"):
			btn_play_level1.visible = true
			btn_play_level1.text = "▶ DALE CLIC PARA INICIAR"
			btn_play_level1.modulate.a = 0.0
			btn_play_level1.position = Vector2(140, 460)
			btn_play_level1.size = Vector2(240, 40)
			camera_zoom_tween.tween_property(btn_play_level1, "position:y", 475.0, 0.42)\
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			camera_zoom_tween.tween_property(btn_play_level1, "modulate:a", 1.0, 0.32)
		else:
			btn_play_level1.visible = false
		
	# Habilitar el overlay invisible de captura de clics fuera de la tarjeta
	if card_dim_overlay:
		card_dim_overlay.visible = true
		card_dim_overlay.color = Color(0, 0, 0, 0)

func _unzoom_camera() -> void:
	if not is_level_zoomed:
		return
	is_level_zoomed = false
	active_zoomed_index = -1
	
	if card_dim_overlay:
		card_dim_overlay.visible = false
			
	if camera_zoom_tween and camera_zoom_tween.is_valid():
		camera_zoom_tween.kill()
		
	camera_zoom_tween = create_tween().set_parallel(true)
	if constellation_area:
		camera_zoom_tween.tween_property(constellation_area, "position", Vector2.ZERO, 0.38)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		camera_zoom_tween.tween_property(constellation_area, "scale", Vector2.ONE, 0.38)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
	if btn_play_level1 and btn_play_level1.visible:
		camera_zoom_tween.tween_property(btn_play_level1, "modulate:a", 0.0, 0.22)
		camera_zoom_tween.chain().tween_callback(func():
			if btn_play_level1 and not is_level_zoomed:
				btn_play_level1.visible = false
		)

func _update_btn_play_level1_visibility() -> void:
	if not btn_play_level1:
		return
	btn_play_level1.visible = (is_level_zoomed and active_zoomed_index == 0 and (current_mode == "reparacion" or current_mode == "sistema") and current_tab == "niveles")

func _play_level_1() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("start_level"):
		gm.start_level(900.0)
	if current_mode == "sistema":
		get_tree().change_scene_to_file("res://scenes/gameplay/LevelSystems1.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/gameplay/Level1.tscn")

func _close_level_card() -> void:
	_unzoom_camera()

# =============================================================================
# CONSTRUCCIÓN Y FILTRADO INSTANTÁNEO DE TARJETAS (REUTILIZACIÓN DE SLOTS, 0 MS)
# =============================================================================
func _filter_tutorial_cards() -> void:
	var mode_cards: Array[Dictionary] = []
	for c in ALL_TUTORIAL_CARDS:
		if c.get("division", "") == current_mode:
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
	btn.custom_minimum_size = Vector2(340, 230)
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
	bg_frame.texture = PRELOADED_TEXTURES.get("res://pixel art/fondos de menus.png")
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
	vbox.add_child(title_lbl)
	
	var hint_lbl = Label.new()
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_font_size_override("font_size", 10)
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
	
	btn.pivot_offset = Vector2(170, 115)
	btn.mouse_entered.connect(func():
		var tw = create_tween().set_parallel(true)
		tw.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		sb.border_width_right = 6
		sb.border_width_bottom = 6
		sb.border_color = Color(1.0, 1.0, 1.0, 1.0)
	)
	btn.mouse_exited.connect(func():
		var tw = create_tween().set_parallel(true)
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
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
		deployed_btn_play.text = "▶ PROBAR MINIJUEGO"
		deployed_btn_play.disabled = false
		deployed_btn_play.modulate = Color(1, 1, 1, 1)
	else:
		deployed_btn_play.text = "🔒 SIMULADOR EN CALIBRACIÓN"
		deployed_btn_play.disabled = true
		deployed_btn_play.modulate = Color(0.6, 0.6, 0.6, 0.7)
		
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
		"launch_cpu_pins":
			if not _cpu_pins_scene:
				_cpu_pins_scene = load("res://scenes/minigames/CPUPinsMinigame.tscn")
			_launch_minigame(_cpu_pins_scene)
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
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")
