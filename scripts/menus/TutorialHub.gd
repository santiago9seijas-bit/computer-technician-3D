extends Control

# =============================================================================
# CENTRO DE ENTRENAMIENTO // PACK DE TARJETAS POR DIVISIONES:
# REPARACIÓN | SISTEMA | SERVIDOR
# =============================================================================

@onready var btn_volver: Button = $TopBar/BtnVolver
@onready var btn_reparacion: Button = $ModeSelector/BtnReparacion
@onready var btn_sistema: Button = $ModeSelector/BtnSistema
@onready var btn_servidor: Button = $ModeSelector/BtnServidor

@onready var cards_scroll: ScrollContainer = $CardsScroll
@onready var cards_grid: GridContainer = $CardsScroll/CardsGrid
@onready var deployed_modal: Control = $DeployedModal
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

var glitch_material = preload("res://styles/cyber_glitch_sprite.tres")
var CyberButtonScript = preload("res://scripts/menus/CyberButton.gd")
var title_font = preload("res://assets/fonts/Bungee-Regular.ttf")

var FanCoolerScene = preload("res://scenes/minigames/FanCoolerMinigame.tscn")
var RAMScene = preload("res://scenes/minigames/RAMMinigame.tscn")
var HDDScene = preload("res://scenes/minigames/HDDMinigame.tscn")
var GPUScene = preload("res://scenes/minigames/GPUMinigame.tscn")
var CPUScene = preload("res://scenes/minigames/CPUMinigame.tscn")
var M2Scene = preload("res://scenes/minigames/M2Minigame.tscn")
var PSUScene = preload("res://scenes/minigames/PSUMinigame.tscn")
var MotherboardScene = preload("res://scenes/minigames/MotherboardMinigame.tscn")
var LiquidCoolingScene = preload("res://scenes/minigames/LiquidCoolingMinigame.tscn")

var current_minigame_instance: Node = null
var active_card_data: Dictionary = {}
var current_division: String = "reparacion"

var ALL_CARDS: Array[Dictionary] = [
	# =========================================================================
	# DIVISIÓN 1: REPARACIÓN (HARDWARE)
	# =========================================================================
	{
		"division": "reparacion",
		"id": "cooler",
		"title": "FAN COOLER",
		"subtitle": "DISIPADOR TÉRMICO ACTIVO PWM",
		"category": "REFRIGERACIÓN",
		"texture_path": "res://pixel art/fancooler conectado.png",
		"color_accent": Color(1.0, 0.15, 0.35, 1.0), # Rojo Carmesí
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
		"color_accent": Color(0.85, 0.1, 0.95, 1.0), # Púrpura Eléctrico
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
		"color_accent": Color(1.0, 0.2, 0.45, 1.0), # Neón Rojo-Púrpura
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
		"color_accent": Color(1.0, 0.15, 0.45, 1.0),
		"que_es": "Unidad de procesamiento gráfico de alto rendimiento montada en el puerto PCIe x16 con alimentación dedicada de 8 pines.",
		"importancia": "CRÍTICA: Es la pieza más propensa a roturas si se tira sin liberar el pestillo plástico del zócalo PCIe de la placa madre.",
		"que_hace": "Procesa y renderiza gráficos 3D en tiempo real, conectada al bus de datos de alta velocidad PCIe y a la salida de pantalla.",
		"pasos": "1. Desconecta el conector PCIe de 8 pines presionando el clip de seguridad.\n2. Retira los 2 tornillos del bracket metálico con [1] Cruz o [2] Pala.\n3. Presiona el pestillo de retención plástico al final de la ranura PCIe x16.\n4. Extrae la tarjeta gráfica verticalmente sin torsionar el zócalo.",
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
		"que_es": "Unidad central de procesamiento montada sobre la matriz de pines del zócalo con cubierta metálica IHS.",
		"importancia": "MÁXIMA: La pasta térmica seca causa sobrecalentamiento. Manipular la palanca y esquinas previene doblar pines irreversibles.",
		"que_hace": "Ejecuta todas las operaciones del computador coordinando reloj y memoria a miles de millones de ciclos por segundo.",
		"pasos": "1. Con [2] Paño Isopropílico, frota y disuelve los residuos de pasta térmica vieja del IHS.\n2. Desengancha la palanca de tensión del socket hacia el lateral y levántala a 90°.\n3. Abre la placa de presión metálica.\n4. Sujeta el procesador por las esquinas y levántalo con cuidado.",
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
		"pasos": "1. Desconecta el conector principal ATX de 24 pines presionando su traba de seguridad.\n2. Desconecta el conector auxiliar EPS de 8 pines de la CPU.\n3. Retira los 4 tornillos hexagonales traseros del chasis con [1] Cruz o [2] Pala.\n4. Desliza la fuente de alimentación fuera del túnel inferior del chasis.",
		"is_ready": true,
		"handler": "launch_psu"
	},
	{
		"division": "reparacion",
		"id": "mobo",
		"title": "PLACA MADRE",
		"subtitle": "DESMONTAJE MAESTRO DEL CHASIS",
		"category": "ARQUITECTURA & DESARME",
		"texture_path": "",
		"color_accent": Color(0.9, 0.15, 0.6, 1.0),
		"que_es": "Circuito impreso principal que interconecta todos los módulos. Su extracción requiere retirar primero todos los componentes anclados a sus ranuras y los cables de alimentación.",
		"importancia": "CRÍTICA: Jamás intentes desatornillar la placa madre con la GPU, el cooler o la fuente conectados; el peso y la tensión de los cables pueden quebrar las pistas de cobre internas.",
		"que_hace": "Desafío maestro de taller: sintetiza la secuencia lógica completa para desensamblar una computadora desde cero hasta dejar el gabinete vacío.",
		"pasos": "1. Desmonta las piezas instaladas en el orden que prefieras: Cables ATX/EPS, Tarjeta Gráfica GPU, Fan Cooler, SSD M.2 y RAM.\n2. Al despejar la placa madre, desatornilla los 6 tornillos Standoff del chasis con Cruz [1] o Pala [2].\n3. Desencastra del I/O Shield trasero y levanta la placa madre limpia.",
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

	# =========================================================================
	# DIVISIÓN 2: SISTEMA (SOFTWARE / BIOS / S.O.)
	# =========================================================================
	{
		"division": "sistema",
		"id": "os_install",
		"title": "INSTALACIÓN DE S.O.",
		"subtitle": "CONFIGURACIÓN BOOT USB & KERNEL",
		"category": "SOFTWARE BASE",
		"texture_path": "",
		"color_accent": Color(0.85, 0.15, 0.95, 1.0),
		"que_es": "Despliegue e instalación de un sistema operativo moderno (Linux/Windows) desde una unidad flash UEFI.",
		"importancia": "CRÍTICA: Sin sistema operativo el procesador y hardware carecen de interfaz para ejecutar programas o interactuar con el usuario.",
		"que_hace": "Escribe el gestor de arranque (GRUB/BCD), inicializa los controladores de dispositivos y formatea las particiones del sistema.",
		"pasos": "1. Conecta la unidad USB bootable con la imagen del SO.\n2. Ingresa al Boot Menu de la placa madre y selecciona el medio UEFI.\n3. Selecciona la partición de destino y completa la configuración de usuario.",
		"is_ready": false,
		"handler": ""
	},
	{
		"division": "sistema",
		"id": "bios_setup",
		"title": "CONFIGURACIÓN BIOS/UEFI",
		"subtitle": "FIRMWARE, XMP/EXPO & BOOT ORDER",
		"category": "FIRMWARE",
		"texture_path": "",
		"color_accent": Color(1.0, 0.1, 0.35, 1.0),
		"que_es": "Firmware básico de bajo nivel almacenado en el chip de memoria flash ROM de la placa madre.",
		"importancia": "ESENCIAL: Controla los voltajes base, frecuencias de reloj, inicialización de puertos y orden de arranque de discos.",
		"que_hace": "Ejecuta el autodiagnóstico POST (Power-On Self-Test), activa perfiles de alto rendimiento de memoria y transfiere el control al bootloader.",
		"pasos": "1. Presiona SUPR o F2 durante el encendido para ingresar al setup.\n2. Navega a Memory Settings y habilita XMP / EXPO.\n3. Ajusta la prioridad en la pestaña Boot y guarda los cambios con F10.",
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

	# =========================================================================
	# DIVISIÓN 3: SERVIDOR (INFRAESTRUCTURA & RACKS)
	# =========================================================================
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
		"title": "ARREGLOS RAID",
		"subtitle": "REDUNDANCIA HARDWARE (RAID 1, 5, 10)",
		"category": "ALMACENAMIENTO ENTERPRISE",
		"texture_path": "",
		"color_accent": Color(0.9, 0.15, 0.8, 1.0),
		"que_es": "Agrupación de múltiples discos SAS o NVMe gestionados por una tarjeta controladora RAID con memoria caché dedicada.",
		"importancia": "CRÍTICA: En servidores de producción no puede haber tiempo de inactividad; permite que 1 o 2 discos mueran sin perder ni un byte.",
		"que_hace": "Distribuye datos en bandas (striping) y almacena paridad XOR para reconstruir el contenido sobre un disco de repuesto (Hot Spare).",
		"pasos": "Próximamente disponible en el módulo de Servidores.",
		"is_ready": false,
		"handler": ""
	},
	{
		"division": "servidor",
		"id": "redundant_psu",
		"title": "FUENTES REDUNDANTES",
		"subtitle": "MÓDULOS HOT-SWAP DUALES",
		"category": "ENERGÍA CRÍTICA",
		"texture_path": "",
		"color_accent": Color(1.0, 0.2, 0.4, 1.0),
		"que_es": "Sistema de dos o más fuentes de alimentación conectadas a circuitos eléctricos independientes.",
		"importancia": "VITAL: Si una línea de alimentación o fuente se quema, la segunda asume la carga al instante sin apagar el servidor.",
		"que_hace": "Equilibra la corriente en tiempo real y permite extraer la fuente dañada en caliente sin apagar la máquina.",
		"pasos": "Próximamente disponible en el módulo de Servidores.",
		"is_ready": false,
		"handler": ""
	},
	{
		"division": "servidor",
		"id": "patch_panels",
		"title": "PATCH PANELS & CABLEADO",
		"subtitle": "CABLEADO ESTRUCTURADO CAT6A / FIBRA",
		"category": "CONECTIVIDAD",
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
	}
]

var PRELOADED_TEXTURES = {
	"res://pixel art/fancooler conectado.png": preload("res://pixel art/fancooler conectado.png"),
	"res://pixel art/ram.png": preload("res://pixel art/ram.png"),
	"res://pixel art/hdd.png": preload("res://pixel art/hdd.png")
}

var LevelSelectScript = preload("res://scripts/menus/LevelSelect.gd")

func _ready() -> void:
	call_deferred("_redirect_to_level_select")

func _redirect_to_level_select() -> void:
	LevelSelectScript.initial_tab = "tutoriales"
	get_tree().change_scene_to_file("res://scenes/menus/LevelSelect.tscn")

func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")

func _set_division(div_name: String) -> void:
	if current_division == div_name:
		return
		
	current_division = div_name
	_update_division_buttons()
	_filter_visible_cards()
	cards_scroll.scroll_vertical = 0
	
	# Animación instantánea fluida sin pausas ni reconstrucción
	cards_grid.modulate.a = 0.65
	var tw = create_tween()
	tw.tween_property(cards_grid, "modulate:a", 1.0, 0.08).set_trans(Tween.TRANS_QUAD)

func _filter_visible_cards() -> void:
	for child in cards_grid.get_children():
		var div = child.get_meta("division", "")
		child.visible = (div == current_division)

func _update_division_buttons() -> void:
	var rep_count = 0
	var sis_count = 0
	var srv_count = 0
	for c in ALL_CARDS:
		match c.get("division", ""):
			"reparacion": rep_count += 1
			"sistema": sis_count += 1
			"servidor": srv_count += 1
			
	btn_reparacion.text = "REPARACIÓN (%d)" % rep_count
	btn_sistema.text = "SISTEMA (%d)" % sis_count
	btn_servidor.text = "SERVIDOR (%d)" % srv_count

	var tabs = [
		{"btn": btn_reparacion, "name": "reparacion"},
		{"btn": btn_sistema, "name": "sistema"},
		{"btn": btn_servidor, "name": "servidor"}
	]
	
	for t in tabs:
		var is_active = (t["name"] == current_division)
		if is_active:
			t["btn"].modulate = Color(1.25, 1.25, 1.25, 1.0)
			if "border_color" in t["btn"]:
				t["btn"].border_color = Color(1.0, 0.1, 0.4, 1.0)
		else:
			t["btn"].modulate = Color(0.65, 0.65, 0.72, 0.8)
			if "border_color" in t["btn"]:
				t["btn"].border_color = Color(0.5, 0.15, 0.6, 0.6)

func _prebuild_all_cards() -> void:
	for child in cards_grid.get_children():
		child.queue_free()
		
	for data in ALL_CARDS:
		var card_btn = _create_mini_card(data)
		cards_grid.add_child(card_btn)

func _create_mini_card(data: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(340, 235)
	btn.flat = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.set_meta("division", data["division"])
	
	# Contenedor visual tipo naipe cyberpunk
	var panel = PanelContainer.new()
	panel.name = "CardPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(panel)
	
	# Marco cyberpunk
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.02, 0.14, 0.95)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 4
	sb.border_width_bottom = 4
	sb.border_color = data["color_accent"]
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
	
	# Header: Categoría y estado
	var header_hbox = HBoxContainer.new()
	header_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(header_hbox)
	
	var cat_lbl = Label.new()
	cat_lbl.text = "[ %s ]" % data["category"]
	cat_lbl.add_theme_color_override("font_color", data["color_accent"])
	cat_lbl.add_theme_font_size_override("font_size", 10)
	header_hbox.add_child(cat_lbl)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_hbox.add_child(spacer)
	
	var status_tag = Label.new()
	status_tag.text = "DISPONIBLE" if data["is_ready"] else "BLOQUEADO 🔒"
	status_tag.add_theme_color_override("font_color", Color(0.2, 1.0, 0.6) if data["is_ready"] else Color(0.7, 0.7, 0.75, 0.6))
	status_tag.add_theme_font_size_override("font_size", 10)
	header_hbox.add_child(status_tag)
	
	# Preview central con shader glitch
	var preview_box = PanelContainer.new()
	preview_box.custom_minimum_size = Vector2(0, 110)
	preview_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb_inner = StyleBoxFlat.new()
	sb_inner.bg_color = Color(0.04, 0.01, 0.08, 0.8)
	sb_inner.border_width_left = 1
	sb_inner.border_width_top = 1
	sb_inner.border_width_right = 1
	sb_inner.border_width_bottom = 1
	sb_inner.border_color = Color(data["color_accent"].r, data["color_accent"].g, data["color_accent"].b, 0.4)
	preview_box.add_theme_stylebox_override("panel", sb_inner)
	vbox.add_child(preview_box)
	
	if data["texture_path"] != "" and PRELOADED_TEXTURES.has(data["texture_path"]):
		var tex_rect = TextureRect.new()
		tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tex_rect.texture = PRELOADED_TEXTURES[data["texture_path"]]
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex_rect.material = glitch_material
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview_box.add_child(tex_rect)
	else:
		var lock_lbl = Label.new()
		lock_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if data["is_ready"]:
			lock_lbl.text = "⚡\n[ SIMULADOR DISPONIBLE ]"
			lock_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.6, 0.95))
		else:
			var div_label = "MÓDULO DE SISTEMA" if data["division"] == "sistema" else ("INFRAESTRUCTURA SERVIDOR" if data["division"] == "servidor" else "EN CALIBRACIÓN")
			lock_lbl.text = "[ %s ]\n🔒" % div_label
			lock_lbl.add_theme_color_override("font_color", Color(0.65, 0.5, 0.75, 0.65))
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock_lbl.add_theme_font_size_override("font_size", 11)
		lock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview_box.add_child(lock_lbl)
		
	# Footer: Título e indicación de clic
	var title_lbl = Label.new()
	title_lbl.text = data["title"]
	title_lbl.add_theme_font_override("font", title_font)
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	title_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	title_lbl.add_theme_constant_override("outline_size", 6)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)
	
	var hint_lbl = Label.new()
	hint_lbl.text = "▶ CLIC PARA DESPLEGAR FICHA" if data["is_ready"] else "▶ CLIC PARA LEER ESPECIFICACIONES"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_color_override("font_color", Color(0.85, 0.4, 0.95, 0.85) if data["is_ready"] else Color(0.6, 0.5, 0.7, 0.6))
	hint_lbl.add_theme_font_size_override("font_size", 10)
	vbox.add_child(hint_lbl)
	
	# Animación al posar el mouse
	btn.pivot_offset = Vector2(170, 117)
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
		sb.border_color = data["color_accent"]
	)
	
	# Clic: Desplegar la ficha técnica completa
	btn.pressed.connect(func(): _open_deployed_card(data))
	
	return btn

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
	tw.tween_property(deployed_card, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(deployed_card, "modulate:a", 1.0, 0.2)

func _close_deployed_card() -> void:
	var tw = create_tween().set_parallel(true)
	tw.tween_property(deployed_card, "scale", Vector2(0.85, 0.85), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(deployed_card, "modulate:a", 0.0, 0.15)
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
			_launch_minigame(FanCoolerScene)
		"launch_ram":
			_launch_minigame(RAMScene)
		"launch_hdd":
			_launch_hdd_with_spares()
		"launch_gpu":
			_launch_minigame(GPUScene)
		"launch_cpu":
			_launch_minigame(CPUScene)
		"launch_m2":
			_launch_minigame(M2Scene)
		"launch_psu":
			_launch_minigame(PSUScene)
		"launch_mobo":
			_launch_minigame(MotherboardScene)
		"launch_liquid_cooling":
			_launch_minigame(LiquidCoolingScene)

func _launch_minigame(scene: PackedScene) -> void:
	if is_instance_valid(current_minigame_instance):
		current_minigame_instance.queue_free()
		
	var inst = scene.instantiate()
	inst.set("is_tutorial_mode", true)
	current_minigame_instance = inst
	minigame_container.add_child(inst)
	
	if inst.has_signal("minigame_finished"):
		inst.minigame_finished.connect(_on_minigame_finished)

func _launch_hdd_with_spares() -> void:
	# Asegurar que la mochila tenga un repuesto de HDD para la práctica
	var has_hdd = false
	for item in GameManager.backpack:
		if item.get("type", "") == "Disco Duro":
			has_hdd = true
			break
	if not has_hdd and GameManager.backpack.size() < GameManager.MAX_BACKPACK_SLOTS:
		GameManager.backpack.append({"type": "Disco Duro", "functional": true})
		GameManager.backpack_updated.emit(GameManager.backpack)
		
	_launch_minigame(HDDScene)

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
