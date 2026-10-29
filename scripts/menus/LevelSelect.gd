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
@onready var level_card_modal: Control = $LevelCardModal

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

# --- Variables de Estado ---
var current_tab: String = "niveles"
var current_mode: String = "reparacion"
var node_buttons: Array[Button] = []
var current_minigame_instance: Node = null
var active_card_data: Dictionary = {}
var _card_slots: Array[Button] = []

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
			"title": "NIVEL 1 · ORDEN DE ARRANQUE BIOS",
			"stage": "ETAPA I: BIOS & BOOT",
			"mode_name": "SISTEMA",
			"color_accent": Color(1.0, 0.15, 0.45),
			"description": "Error 'No bootable device found'. Ingresa a la interfaz UEFI y reordena la secuencia para priorizar el SSD NVMe principal.",
			"requirements": "TECLADO INDUSTRIAL · LÍMITE: 120s · RECOMPENSA: 100 PTS",
			"can_play": false
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
		"pasos": "1. Desconecta el cable de alimentación o retira los tornillos en el orden que prefieras.\n2. Identifica la cabeza de cada tornillo: Cruz (+) -> Tecla [1] o Pala (-) -> Tecla [2].\n3. Retira los 4 tornillos de sujeción.\n4. Al quedar totalmente libre, haz clic para levantar el disipador.",
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
		"pasos": "1. Arrastra las trabas laterales de seguridad hacia ARRIBA para desbloquear el slot.\n2. Retira la memoria averiada del zócalo.\n3. Arrastra la nueva memoria RAM alineando la muesca de polaridad central.\n4. Presiona las trabas laterales hacia ABAJO para fijar y asegurar el módulo.",
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
		"pasos": "1. Retira el tornillo de la bahía con Destornillador Cruz [1] o Pala [2].\n2. Arrastra la unidad averiada hacia arriba para extraerla.\n3. Coloca un disco funcional desde la mochila técnica en la bahía vacía.\n4. Fija y ajusta firmemente el tornillo de sujeción.",
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
		"color_accent": Color(0.65, 0.08, 0.9, 0.6),
		"que_es": "Unidad de procesamiento gráfico de alto rendimiento montada en el puerto PCIe x16.",
		"importancia": "ALTA: Sin GPU operativa no hay aceleración gráfica ni procesamiento 3D.",
		"que_hace": "Renderiza fotogramas y texturas a resoluciones nativas a través del bus PCIe.",
		"pasos": "Próximamente disponible en el módulo de Reparación.",
		"is_ready": false,
		"handler": ""
	},
	{
		"division": "reparacion",
		"id": "psu",
		"title": "FUENTE DE PODER",
		"subtitle": "SUMINISTRO CONMUTADO ATX",
		"category": "ENERGÍA",
		"texture_path": "",
		"color_accent": Color(0.75, 0.1, 0.85, 0.6),
		"que_es": "Convertidor de tensión de corriente alterna (110V/220V) a corriente continua estable (+12V, +5V, +3.3V).",
		"importancia": "CRÍTICA: Una fuente inestable daña la placa madre, CPU y discos duros por sobretensiones.",
		"que_hace": "Distribuye líneas limpias de energía a través de los arneses de 24 pines y EPS de 8 pines.",
		"pasos": "Próximamente disponible en el módulo de Reparación.",
		"is_ready": false,
		"handler": ""
	},
	{
		"division": "reparacion",
		"id": "motherboard",
		"title": "PLACA MADRE",
		"subtitle": "CIRCUITO IMPRESO PRINCIPAL",
		"category": "ARQUITECTURA",
		"texture_path": "",
		"color_accent": Color(0.85, 0.12, 0.7, 0.6),
		"que_es": "Placa de circuito multicapa que interconecta microprocesador, memorias, almacenamiento y buses de expansión.",
		"importancia": "VITAL: Un fallo en las pistas de cobre o fases VRM inutiliza todos los componentes instalados.",
		"que_hace": "Sincroniza los buses de comunicación y administra el paso de energía a través del chipset.",
		"pasos": "Próximamente disponible en el módulo de Reparación.",
		"is_ready": false,
		"handler": ""
	},

	# --- DIVISIÓN SISTEMA (SOFTWARE & CIBERSEGURIDAD) ---
	{
		"division": "sistema",
		"id": "bios_setup",
		"title": "CONFIGURACIÓN BIOS",
		"subtitle": "INTERFAZ UEFI & HARDWARE BASE",
		"category": "FIRMWARE",
		"texture_path": "",
		"color_accent": Color(1.0, 0.15, 0.4, 1.0),
		"que_es": "Firmware grabado en un chip EEPROM de la placa madre que inicializa el hardware y carga el gestor de arranque.",
		"importancia": "CRÍTICA: Sin una BIOS correctamente calibrada, el procesador y periféricos no se comunican y el equipo no bootea.",
		"que_hace": "Ejecuta el POST (Power-On Self-Test), asigna direcciones de memoria y cede el control al sistema operativo.",
		"pasos": "1. Pulsa la tecla de acceso (DEL / F2) durante el encendido.\n2. Navega al menú 'Boot Priority' y selecciona la unidad principal.\n3. Ajusta el perfil XMP / EXPO de memoria si está disponible.\n4. Guarda los cambios con F10 y reinicia el equipo.",
		"is_ready": false,
		"handler": ""
	},
	{
		"division": "sistema",
		"id": "driver_install",
		"title": "INSTALACIÓN DE DRIVERS",
		"subtitle": "CONTROLADORES DE DISPOSITIVO",
		"category": "CONTROLADORES",
		"texture_path": "",
		"color_accent": Color(0.85, 0.1, 0.9, 1.0),
		"que_es": "Software puente de bajo nivel que permite al sistema operativo comunicarse eficazmente con componentes de hardware específicos.",
		"importancia": "ALTA: Sin controladores dedicados (GPU, chipset, red), el hardware opera en modo compatibilidad con rendimiento mínimo.",
		"que_hace": "Traduce instrucciones de alto nivel del sistema a comandos binarios interpretables por los chips de la placa madre.",
		"pasos": "1. Identifica el modelo exacto del componente o tarjeta.\n2. Descarga el paquete firmado digitalmente por el fabricante.\n3. Realiza una instalación limpia eliminando restos previos con DDU.",
		"is_ready": false,
		"handler": ""
	},
	{
		"division": "sistema",
		"id": "malware_scan",
		"title": "LIMPIEZA DE MALWARE",
		"subtitle": "ANÁLISIS HEURÍSTICO & DESINFECCIÓN",
		"category": "CIBERSEGURIDAD",
		"texture_path": "",
		"color_accent": Color(0.95, 0.05, 0.25, 1.0),
		"que_es": "Protocolo técnico de aislamiento y erradicación de virus, spyware, troyanos y código malicioso persistente.",
		"importancia": "VITAL: El malware satura ciclos de procesador, compromete datos sensibles del usuario y puede secuestrar archivos (ransomware).",
		"que_hace": "Inspecciona procesos en RAM, analiza firmas hash de ejecutables y restaura llaves de registro alteradas.",
		"pasos": "Próximamente disponible en el módulo de Sistema.",
		"is_ready": false,
		"handler": ""
	},
	{
		"division": "sistema",
		"id": "disk_partition",
		"title": "PARTICIONADO DE DISCOS",
		"subtitle": "TABLAS GPT / MBR & SISTEMAS DE ARCHIVO",
		"category": "ALMACENAMIENTO LÓGICO",
		"texture_path": "",
		"color_accent": Color(0.75, 0.2, 0.95, 1.0),
		"que_es": "Segmentación lógica de bloques de un disco duro o SSD en volúmenes independientes.",
		"importancia": "ALTA: Permite separar el sistema operativo de la partición de datos, facilitando formateos limpios sin pérdida de archivos.",
		"que_hace": "Escribe la tabla de particiones GUID (GPT) y estructura clústeres en formatos como NTFS, EXT4 o BTRFS.",
		"pasos": "Próximamente disponible en el módulo de Sistema.",
		"is_ready": false,
		"handler": ""
	},
	{
		"division": "sistema",
		"id": "system_opt",
		"title": "OPTIMIZACIÓN DE SERVICIOS",
		"subtitle": "GESTIÓN DE INICIO & RECURSOS",
		"category": "RENDIMIENTO",
		"texture_path": "",
		"color_accent": Color(0.85, 0.1, 0.7, 1.0),
		"que_es": "Depuración y ajuste fino de servicios en segundo plano, telemetría y programas residentes en memoria.",
		"importancia": "MEDIA-ALTA: Reduce significativamente el tiempo de booteo y evita el estrangulamiento de memoria en equipos con pocos recursos.",
		"que_hace": "Deshabilita tareas automáticas redundantes y prioriza los hilos de ejecución de las aplicaciones del usuario.",
		"pasos": "Próximamente disponible en el módulo de Sistema.",
		"is_ready": false,
		"handler": ""
	},
	{
		"division": "sistema",
		"id": "data_backup",
		"title": "RESPALDO & RESTAURACIÓN",
		"subtitle": "COPIAS FORENSES Y BACKUP SEGURO",
		"category": "INTEGRIDAD",
		"texture_path": "",
		"color_accent": Color(1.0, 0.25, 0.5, 1.0),
		"que_es": "Creación y verificación de imágenes completas o diferenciales de particiones de datos.",
		"importancia": "CRÍTICA: Es la única garantía real de recuperación ante una falla de hardware catastrófica o borrado accidental.",
		"que_hace": "Copia bloque a bloque los sectores con compresión de datos hacia un almacenamiento seguro externo o NAS.",
		"pasos": "Próximamente disponible en el módulo de Sistema.",
		"is_ready": false,
		"handler": ""
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
	btn_sistema.pressed.connect(func(): _switch_mode("sistema"))
	btn_servidor.pressed.connect(func(): _switch_mode("servidor"))
	
	# Modales
	if level_card_modal:
		level_card_modal.visible = false
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
	current_tab = tab_name
	_update_tab_buttons_visuals()
	_update_mode_buttons()

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
	if current_mode == mode_name:
		return
		
	current_mode = mode_name
	_update_mode_buttons()
	
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
		{"btn": btn_sistema, "name": "sistema"},
		{"btn": btn_servidor, "name": "servidor"}
	]
	
	var count_suffix = " (12)" if current_tab == "niveles" else " (6)"
	btn_reparacion.text = "REPARACIÓN" + count_suffix
	btn_sistema.text = "SISTEMA" + count_suffix
	btn_servidor.text = "SERVIDOR" + count_suffix
	
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
		btn.custom_minimum_size = Vector2(56, 56)
		btn.flat = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
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
		btn.position = np - Vector2(28, 28)

func _on_node_clicked(index: int) -> void:
	var list = LEVELS_DATA.get(current_mode, [])
	if index < list.size() and level_card_modal:
		var data = list[index]
		if level_card_modal.has_method("setup_level"):
			level_card_modal.setup_level(data)
		else:
			level_card_modal.visible = true

# =============================================================================
# CONSTRUCCIÓN Y FILTRADO INSTANTÁNEO DE TARJETAS (REUTILIZACIÓN DE SLOTS, 0 MS)
# =============================================================================
func _filter_tutorial_cards() -> void:
	# Asegurar que existan los 6 slots fijos en cards_grid (construidos una única vez)
	if _card_slots.is_empty():
		for i in range(6):
			var slot = _create_card_slot()
			cards_grid.add_child(slot)
			_card_slots.append(slot)
			
	var mode_cards: Array[Dictionary] = []
	for c in ALL_TUTORIAL_CARDS:
		if c.get("division", "") == current_mode:
			mode_cards.append(c)
			
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
		var div_label = "MÓDULO DE SISTEMA" if data["division"] == "sistema" else ("INFRAESTRUCTURA SERVIDOR" if data["division"] == "servidor" else "EN CALIBRACIÓN")
		lock_lbl.text = "[ %s ]\n🔒" % div_label
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
