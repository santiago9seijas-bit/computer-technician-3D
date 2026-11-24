extends Node3D

# =============================================================================
# NIVEL DE PRÁCTICA 3D - RETO CRONOMETRADO CON 3 MESAS Y 3 PCS
# CADA COMPUTADORA PRESENTA UNA FALLA DE HARDWARE DIFERENTE
# =============================================================================

const LevelCountdown = preload("res://scripts/ui/LevelCountdown.gd")
const INTRO_SCENE: PackedScene = preload("res://scenes/ui/LevelIntroModal.tscn")
const DIALOG_SCENE: PackedScene = preload("res://scenes/ui/DialogBox.tscn")

static var practice_zone: String = "maestra"

@onready var player: CharacterBody3D = $Player
@onready var hud: Control = $CanvasLayerHUD/HUD

var dialog_box: Control = null
var current_zone: String = "maestra"
var total_challenge_time: float = 480.0
var is_victory_shown: bool = false

# UI de Desafíos Extra
var extra_challenges_panel: PanelContainer = null
var lbl_status_errors: Label = null
var lbl_status_time: Label = null
var lbl_status_pcs: Label = null

# UI de Cuenta Regresiva
var countdown_overlay: CanvasLayer = null

# UI de Victoria con "¡FELICIDADES!"
var victory_overlay: CanvasLayer = null

const PRACTICE_ZONE_CONFIG: Dictionary = {
	"cooler": {
		"challenge_time": 240.0,
		"joa_speech": "¡Desafío de Fan Coolers y Temperatura!\nLas 3 computadoras se están sobrecalentando críticamente porque sus ventiladores y disipadores están atascados o rotos.\n¡Cambia los disipadores dañados en las 3 estaciones antes de que el reloj llegue a 00:00!",
		"title": "RETO DE PRÁCTICA // FAN COOLER & REFRIGERACIÓN",
		"sub": "3 ESTACIONES DE TRABAJO · LÍMITE DE TIEMPO: 4 MINUTOS",
		"desc": "¡Reto de refrigeración térmica!\n3 computadoras sobre la mesa con distintas fallas críticas de disipación y hardware.\nRepara los 3 equipos antes de que el cronómetro llegue a 00:00.",
		"pc1": {
			"question": "PC #1: El Fan Cooler está completamente detenido y el microprocesador alcanza 98°C apagándose repentinamente. ¿Qué componente debes reemplazar?",
			"parts": ["Fan Cooler"],
			"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "broken", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc2": {
			"question": "PC #2: La máquina enciende con sobrecalentamiento y la turbina de disipación está atascada con polvo. ¿Qué componente debes reemplazar?",
			"parts": ["Fan Cooler"],
			"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "broken", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc3": {
			"question": "PC #3: El cooler hace un chirrido agudo insoportable y el rodamiento del ventilador se partió. ¿Qué componente falló?",
			"parts": ["Fan Cooler"],
			"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "broken", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		}
	},
	"ram": {
		"challenge_time": 240.0,
		"joa_speech": "¡Desafío de Bancos de Memoria RAM!\nLas 3 computadoras sufren pantallas azules continuas y pitidos en el arranque por módulos de memoria defectuosos.\n¡Reemplaza las memorias RAM averiadas en las 3 mesas antes de que se agote el tiempo!",
		"title": "RETO DE PRÁCTICA // BANCO DE MEMORIAS RAM",
		"sub": "3 ESTACIONES DE TRABAJO · LÍMITE DE TIEMPO: 4 MINUTOS",
		"desc": "¡Reto de memoria y buses!\n3 computadoras con pantallas azules y códigos POST de memoria.\nSustituye los módulos defectuosos en las 3 mesas antes de los 4 minutos.",
		"pc1": {
			"question": "PC #1: Pitidos intermitentes continuos al encender y la pantalla se queda sin señal de video. ¿Qué pieza falló?",
			"parts": ["RAM"],
			"components": {"RAM": "broken", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc2": {
			"question": "PC #2: Pantalla azul 'MEMORY_MANAGEMENT' recurrente por sectores de memoria corruptos en el zócalo DIMM. ¿Qué pieza presenta falla?",
			"parts": ["RAM"],
			"components": {"RAM": "broken", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc3": {
			"question": "PC #3: Módulo sulfatado que impide el arranque y no completa la prueba POST de memoria. ¿Qué componente debes sustituir?",
			"parts": ["RAM"],
			"components": {"RAM": "broken", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		}
	},
	"hdd": {
		"challenge_time": 240.0,
		"joa_speech": "¡Desafío de Almacenamiento HDD y SSD!\nLas terminales no detectan sus unidades o tienen sectores dañados con el error 'No Boot Device'.\n¡Instala nuevos discos en las 3 computadoras antes de que finalice el tiempo!",
		"title": "RETO DE PRÁCTICA // ALMACENAMIENTO HDD & SSD",
		"sub": "3 ESTACIONES DE TRABAJO · LÍMITE DE TIEMPO: 4 MINUTOS",
		"desc": "¡Reto de almacenamiento masivo!\n3 equipos con fallas en bahías SATA y discos NVMe.\nCambia los discos y fija la tornillería antes de que finalicen los 4 minutos.",
		"pc1": {
			"question": "PC #1: El equipo muestra 'Reboot and Select proper Boot device' y el disco mecánico hace chasquidos internos. ¿Qué pieza falló?",
			"parts": ["Disco Duro"],
			"components": {"RAM": "ok", "Disco Duro": "broken", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc2": {
			"question": "PC #2: Unidad SSD M.2 no responde tras una sobretensión y la partición principal no es reconocida. ¿Qué pieza requiere cambio?",
			"parts": ["Disco Duro"],
			"components": {"RAM": "ok", "Disco Duro": "broken", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc3": {
			"question": "PC #3: Bloqueo de arranque en la partición del sistema y sectores dañados irrecuperables en el disco. ¿Qué componente falló?",
			"parts": ["Disco Duro"],
			"components": {"RAM": "ok", "Disco Duro": "broken", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		}
	},
	"gpu": {
		"challenge_time": 480.0,
		"joa_speech": "¡Desafío de Tarjetas Gráficas GPU!\nLas estaciones presentan artefactos visuales, glitches en pantalla y pérdida de señal por placas de video defectuosas.\n¡Sustituye las tarjetas gráficas en las 3 estaciones de trabajo antes de que se acabe el tiempo!",
		"title": "RETO DE PRÁCTICA // TARJETAS GRÁFICAS GPU",
		"sub": "3 ESTACIONES DE TRABAJO · LÍMITE DE TIEMPO: 8 MINUTOS",
		"desc": "¡Reto de procesamiento gráfico!\n3 estaciones con fallas de video, artefactos y controladores PCIe.\nRepara las 3 computadoras dentro del límite de 8 minutos.",
		"pc1": {
			"question": "PC #1: Artefactos visuales (glitches verdes) y cuelgues constantes en carga gráfica 3D. ¿Qué componente presenta la avería?",
			"parts": ["Grafica"],
			"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "broken", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc2": {
			"question": "PC #2: Ausencia total de señal de monitor y líneas verticales rojas por memoria VRAM dañada en la GPU. ¿Qué componente debes sustituir?",
			"parts": ["Grafica"],
			"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "broken", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc3": {
			"question": "PC #3: Ventiladores de GPU frenados por sobretensión y fallo crítico en el chip de video PCIe. ¿Qué componente debes sustituir?",
			"parts": ["Grafica"],
			"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "broken", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		}
	},
	"psu": {
		"challenge_time": 480.0,
		"joa_speech": "¡Desafío de Fuentes de Poder ATX!\nHay apagones repentinos por sobrecarga, fuentes quemadas e inestabilidad de voltaje en las 3 estaciones.\n¡Reemplaza las fuentes de poder defectuosas en las 3 mesas a tiempo!",
		"title": "RETO DE PRÁCTICA // FUENTES DE PODER ATX",
		"sub": "3 ESTACIONES DE TRABAJO · LÍMITE DE TIEMPO: 8 MINUTOS",
		"desc": "¡Reto de rieles de alimentación!\n3 equipos afectados por inestabilidad eléctrica y arneses defectuosos.\nReemplaza las fuentes y deja los 3 PCs funcionales en 8 minutos.",
		"pc1": {
			"question": "PC #1: La máquina no reacciona al botón de encendido y se percibe olor a plástico quemado en la fuente. ¿Qué pieza falló?",
			"parts": ["Fuente"],
			"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "broken", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc2": {
			"question": "PC #2: Apagones repentinos bajo consumo y chisporroteo en el conector ATX principal de la fuente. ¿Qué pieza está averiada?",
			"parts": ["Fuente"],
			"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "broken", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc3": {
			"question": "PC #3: Rieles de 12V con caída de voltaje severa impidiendo que la máquina mantenga el encendido. ¿Qué componente requiere sustitución?",
			"parts": ["Fuente"],
			"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "broken", "CPU": "ok", "Placa Madre": "ok"}
		}
	},
	"cpu": {
		"challenge_time": 480.0,
		"joa_speech": "¡Desafío de Microprocesadores CPU!\nLos equipos sufren congelamientos críticos por pines dañados y fallas de reloj en el zócalo.\n¡Cambia los procesadores averiados en las 3 mesas con total precisión antes de que acabe el tiempo!",
		"title": "RETO DE PRÁCTICA // PROCESADORES & SOCKET",
		"sub": "3 ESTACIONES DE TRABAJO · LÍMITE DE TIEMPO: 8 MINUTOS",
		"desc": "¡Reto de microarquitectura central!\n3 computadoras con fallas de procesador y sobrecalentamiento crítico.\nCompleta las 3 estaciones en menos de 8 minutos.",
		"pc1": {
			"question": "PC #1: El equipo sufre pantallas azules 'CLOCK_WATCHDOG_TIMEOUT' y el zócalo presenta pines de contacto dañados. ¿Qué componente falló?",
			"parts": ["CPU"],
			"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "broken", "Placa Madre": "ok"}
		},
		"pc2": {
			"question": "PC #2: Procesador con sobrecalentamiento súbito en el núcleo de silicio y fallo de cálculo aritmético. ¿Qué pieza debes sustituir?",
			"parts": ["CPU"],
			"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "broken", "Placa Madre": "ok"}
		},
		"pc3": {
			"question": "PC #3: Falla de cómputo en arranque POST y zócalo LGA bloqueado con microprocesador defectuoso. ¿Qué pieza debes reparar?",
			"parts": ["CPU"],
			"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "broken", "Placa Madre": "ok"}
		}
	},
	"maestra": {
		"challenge_time": 480.0,
		"joa_speech": "¡Desafío Técnico Integral de Taller!\nCada una de las 3 estaciones sufre una avería de hardware distinta: memoria RAM, gráfica y disco de almacenamiento.\n¡Diagnostica con exactitud y repara las 3 mesas antes de que el cronómetro llegue a 00:00!",
		"title": "RETO CRONOMETRADO // SALA DE PRÁCTICA INTEGRAL",
		"sub": "3 ESTACIONES CON FALLAS DIFERENTES · LÍMITE: 8 MINUTOS",
		"desc": "¡Reto de diagnóstico técnico completo!\n3 computadoras en las mesas, cada una con un componente averiado distinto.\nTienes exactamente 8 minutos para reparar los 3 equipos y superar el reto.",
		"pc1": {
			"question": "PC #1: El equipo enciende pero emite 3 pitidos largos continuos de BIOS y no envía señal de video. ¿Qué pieza está defectuosa?",
			"parts": ["RAM"],
			"components": {"RAM": "broken", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc2": {
			"question": "PC #2: Aparecen líneas verdes y artefactos gráficos en pantalla tras lo cual se congela la imagen. ¿Qué componente falló?",
			"parts": ["Grafica"],
			"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "broken", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc3": {
			"question": "PC #3: Al encender aparece el mensaje 'Reboot and Select proper Boot device' y no se reconoce el disco. ¿Qué pieza debes reemplazar?",
			"parts": ["Disco Duro"],
			"components": {"RAM": "ok", "Disco Duro": "broken", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		}
	},
	# --- RETOS DE PRÁCTICA DEL ÁREA DE SISTEMAS ---
	"systems_intro": {
		"challenge_time": 480.0,
		"joa_speech": "¡Desafío de Terminales de Sistemas!\nLas 3 estaciones tienen fallas críticas simultáneas: particiones GPT corruptas, malware en memoria y controladores obsoletos.\n¡Restaura y desinfecta las 3 terminales antes de que expire el tiempo!",
		"title": "RETO DE PRÁCTICA // 3 TERMINALES DE SISTEMAS",
		"sub": "ESTACIONES ALFA, BETA Y GAMMA · LÍMITE: 8 MINUTOS",
		"desc": "¡Reto cronometrado de software y ciberseguridad!\n3 terminales de sistemas con fallas simultáneas en las 3 mesas.\nRepara las 3 estaciones antes de que el reloj llegue a 00:00.",
		"pc1": {
			"question": "Terminal #1: El equipo muestra 'Boot device not found' y el sector de arranque está destruido. ¿Qué módulo requiere reinstalación?",
			"parts": ["Disco Duro"],
			"components": {"RAM": "ok", "Disco Duro": "broken", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc2": {
			"question": "Terminal #2: Múltiples gusanos y troyanos consumiendo 100% de CPU y memoria. ¿Qué módulo debes desinfectar?",
			"parts": ["RAM"],
			"components": {"RAM": "broken", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc3": {
			"question": "Terminal #3: Controladores de pantalla desactualizados y artefactos en entorno gráfico. ¿Qué subsistema requiere calibración?",
			"parts": ["Grafica"],
			"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "broken", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		}
	},
	"os_install": {
		"challenge_time": 240.0,
		"joa_speech": "¡Desafío de Despliegue de Sistema Operativo!\nLas 3 terminales tienen tablas de particiones corruptas y sectores EFI dañados.\n¡Monta las nuevas particiones y restaura el sistema en las 3 mesas a tiempo!",
		"title": "RETO DE PRÁCTICA // DESPLIEGUE MASIVO DE SO & GPT",
		"sub": "3 ESTACIONES DE TRABAJO · LÍMITE DE TIEMPO: 4 MINUTOS",
		"desc": "¡Despliegue rápido de sistemas!\n3 terminales con tablas de particiones dañadas.\nConfigura particiones GPT y monta el sistema en las 3 mesas en 4 minutos.",
		"pc1": {
			"question": "Terminal #1: Partición EFI corrupta que impide el arranque. ¿Qué unidad debe reconstruirse?",
			"parts": ["Disco Duro"],
			"components": {"RAM": "ok", "Disco Duro": "broken", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc2": {
			"question": "Terminal #2: Tabla GPT inválida y memoria RAM con errores de direccionamiento. ¿Qué piezas debes intervenir?",
			"parts": ["Disco Duro", "RAM"],
			"components": {"RAM": "broken", "Disco Duro": "broken", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc3": {
			"question": "Terminal #3: Fallo de arranque de SO y ventilador detenido por firmware. ¿Qué componentes presentan falla?",
			"parts": ["Disco Duro", "Fan Cooler"],
			"components": {"RAM": "ok", "Disco Duro": "broken", "Grafica": "ok", "Fan Cooler": "broken", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		}
	},
	"malware_scan": {
		"challenge_time": 480.0,
		"joa_speech": "¡Desafío de Detección y Purga de Malware!\nHay procesos sospechosos, troyanos y spyware secuestrando la memoria en las terminales.\n¡Aísla y elimina el malware en las 3 estaciones antes de que el reloj llegue a 00:00!",
		"title": "RETO DE PRÁCTICA // PURGA HEURÍSTICA DE MALWARE",
		"sub": "3 ESTACIONES DE TRABAJO · LÍMITE DE TIEMPO: 8 MINUTOS",
		"desc": "¡Ataque coordinado de malware!\n3 terminales infectadas por troyanos y spyware en memoria.\nAísla y purga los procesos en las 3 mesas en menos de 8 minutos.",
		"pc1": {
			"question": "Terminal #1: Inyección de código malicioso en el spooler de memoria. ¿Qué componente requiere purga?",
			"parts": ["RAM"],
			"components": {"RAM": "broken", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc2": {
			"question": "Terminal #2: Rootkit oculto en sector MBR y desvío de video en pantalla. ¿Qué módulos están comprometidos?",
			"parts": ["RAM", "Grafica"],
			"components": {"RAM": "broken", "Disco Duro": "ok", "Grafica": "broken", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc3": {
			"question": "Terminal #3: Ransomware cifrando archivos en disco y proceso de minería que colapsa la CPU. ¿Qué piezas debes atender?",
			"parts": ["RAM", "Disco Duro"],
			"components": {"RAM": "broken", "Disco Duro": "broken", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		}
	},
	"driver_install": {
		"challenge_time": 240.0,
		"joa_speech": "¡Desafío de Controladores y Drivers WHQL!\nLas 3 estaciones sufren pantallas azules constantes por drivers de GPU incompatibles o corruptos.\n¡Instala los controladores correctos en las 3 mesas antes de agotar el tiempo!",
		"title": "RETO DE PRÁCTICA // CONTROLADORES WHQL & DRIVERS",
		"sub": "3 ESTACIONES DE TRABAJO · LÍMITE DE TIEMPO: 4 MINUTOS",
		"desc": "¡Inestabilidad de controladores!\n3 terminales con pantallas azules continuas por drivers de GPU y buses DMA desactualizados.\nActualiza los paquetes oficiales en las 3 estaciones en 4 minutos.",
		"pc1": {
			"question": "Terminal #1: Controlador gráfico no firmado que provoca cuelgues al renderizar 3D. ¿Qué subsistema requiere actualización?",
			"parts": ["Grafica"],
			"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "broken", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc2": {
			"question": "Terminal #2: Conflicto IRQ entre la GPU y el almacenamiento SATA. ¿Qué componentes debes intervenir?",
			"parts": ["Grafica", "Disco Duro"],
			"components": {"RAM": "ok", "Disco Duro": "broken", "Grafica": "broken", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc3": {
			"question": "Terminal #3: Pérdida de señal HDMI y módulo de memoria que arroja fallas BSOD de controlador. ¿Qué piezas requieren cambio?",
			"parts": ["Grafica", "RAM"],
			"components": {"RAM": "broken", "Disco Duro": "ok", "Grafica": "broken", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		}
	},
	"adware_cleaner": {
		"challenge_time": 240.0,
		"joa_speech": "¡Desafío de Limpieza de Adware y Spam!\nVentanas emergentes falsas y secuestradores de navegador están colapsando las 3 computadoras.\n¡Purga el software basura y protege las 3 estaciones antes de que termine el tiempo!",
		"title": "RETO DE PRÁCTICA // FILTRADO DEFENSIVO DE ADWARE",
		"sub": "3 ESTACIONES DE TRABAJO · LÍMITE DE TIEMPO: 4 MINUTOS",
		"desc": "¡Saturación por spam y adware!\n3 terminales secuestradas por ventanas emergentes engañosas.\nDesactiva trampas y despliega el Ad-Blocker en las 3 mesas antes de los 4 minutos.",
		"pc1": {
			"question": "Terminal #1: Pop-ups fraudulentos de falsos antivirus colapsando el navegador. ¿Qué componente requiere desinfección?",
			"parts": ["RAM"],
			"components": {"RAM": "broken", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc2": {
			"question": "Terminal #2: Extensiones maliciosas inyectadas en la partición y pantalla con spam continuo. ¿Qué piezas debes purgar?",
			"parts": ["RAM", "Disco Duro"],
			"components": {"RAM": "broken", "Disco Duro": "broken", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc3": {
			"question": "Terminal #3: Miner web oculto en pestañas que eleva la temperatura del Fan Cooler al máximo. ¿Qué componentes debes estabilizar?",
			"parts": ["RAM", "Fan Cooler"],
			"components": {"RAM": "broken", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "broken", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		}
	},
	"code_debugger": {
		"challenge_time": 480.0,
		"joa_speech": "¡Desafío de Kernel y Debugging de Scripts!\nBucles infinitos y fallas de sintaxis en el arranque están bloqueando las terminales.\n¡Depura los scripts y valida el código en las 3 estaciones antes de que finalice el tiempo!",
		"title": "RETO DE PRÁCTICA // PARCHEO DE KERNEL & DEBUGGING",
		"sub": "3 ESTACIONES DE TRABAJO · LÍMITE DE TIEMPO: 8 MINUTOS",
		"desc": "¡Errores críticos de scripts de sistema!\n3 terminales con bucles infinitos y sintaxis rota impidiendo el booteo.\nAplica parches y valida tests unitarios en las 3 mesas en 8 minutos.",
		"pc1": {
			"question": "Terminal #1: Script de inicialización congelado por bucle infinito en el procesador. ¿Qué componente presenta la falla?",
			"parts": ["CPU"],
			"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "broken", "Placa Madre": "ok"}
		},
		"pc2": {
			"question": "Terminal #2: Fallo de compilación en módulos de memoria y kernel panic. ¿Qué piezas requieren depuración?",
			"parts": ["CPU", "RAM"],
			"components": {"RAM": "broken", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "broken", "Placa Madre": "ok"}
		},
		"pc3": {
			"question": "Terminal #3: Error de sintaxis en lectura de disco de arranque y sobrecarga térmica. ¿Qué piezas debes solucionar?",
			"parts": ["CPU", "Disco Duro"],
			"components": {"RAM": "ok", "Disco Duro": "broken", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "broken", "Placa Madre": "ok"}
		}
	},
	"usb_backup": {
		"challenge_time": 240.0,
		"joa_speech": "¡Desafío de Clonación y Respaldo USB!\nUnidades booteables corruptas y fallas de suma de verificación en medios externos.\n¡Flashea los respaldos y restaura las unidades USB en las 3 mesas a tiempo!",
		"title": "RETO DE PRÁCTICA // CLONACIÓN Y PENDRIVES BOOTEABLES",
		"sub": "3 ESTACIONES DE TRABAJO · LÍMITE DE TIEMPO: 4 MINUTOS",
		"desc": "¡Respaldo y clonación de emergencia!\n3 terminales que requieren flasheo urgente de medios booteables USB.\nPrepara las 3 unidades en las mesas dentro del límite de 4 minutos.",
		"pc1": {
			"question": "Terminal #1: Unidad de rescate booteable no reconocida por la BIOS. ¿Qué almacenamiento requiere flasheo?",
			"parts": ["Disco Duro"],
			"components": {"RAM": "ok", "Disco Duro": "broken", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc2": {
			"question": "Terminal #2: Fallo de suma de verificación al escribir la ISO en la memoria del pendrive. ¿Qué piezas debes restaurar?",
			"parts": ["Disco Duro", "RAM"],
			"components": {"RAM": "broken", "Disco Duro": "broken", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc3": {
			"question": "Terminal #3: Corrupción de bloques de datos durante la clonación y suministro inestable. ¿Qué módulos debes solucionar?",
			"parts": ["Disco Duro", "Fuente"],
			"components": {"RAM": "ok", "Disco Duro": "broken", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "broken", "CPU": "ok", "Placa Madre": "ok"}
		}
	}
}

func _ready() -> void:
	if player and hud:
		player.hud_node = hud
		
	var btn_reintentar = hud.get_node_or_null("GameOverPanel/VBox/BtnReiniciarGO") as Button
	if btn_reintentar:
		btn_reintentar.pressed.connect(_on_reintentar)
		
	var btn_siguiente = hud.get_node_or_null("WinPanel/VBox/BtnSiguiente") as Button
	if btn_siguiente:
		btn_siguiente.pressed.connect(_on_siguiente)

	# Determinar zona de práctica activa
	var gm = get_node_or_null("/root/GameManager")
	if gm and "practice_target_mode" in gm and str(gm.practice_target_mode) != "":
		current_zone = str(gm.practice_target_mode).to_lower()
	elif practice_zone != "":
		current_zone = practice_zone.to_lower()
	else:
		current_zone = "maestra"

	if not PRACTICE_ZONE_CONFIG.has(current_zone):
		current_zone = "maestra"

	var cfg = PRACTICE_ZONE_CONFIG[current_zone]

	# TIEMPO DINÁMICO: 4 MINUTOS (240s) o 8 MINUTOS (480s) SEGÚN LA DIFICULTAD
	total_challenge_time = float(cfg.get("challenge_time", 480.0))
	GameManager.start_level(total_challenge_time)
	GameManager.timer_active = false
	if hud and hud.has_method("set_infinite_time"):
		hud.set_infinite_time(false)

	# Configurar las 3 computadoras de las 3 mesas con fallas distintas
	_setup_computer("WorkBench1/Computer1", 1, cfg["pc1"])
	_setup_computer("WorkBench2/Computer2", 2, cfg["pc2"])
	_setup_computer("WorkBench3/Computer3", 3, cfg["pc3"])

	# Filtrar cajas de repuestos: en zonas de práctica solo las cajas con las piezas necesarias
	var active_parts: Array[String] = []
	for p_key in ["pc1", "pc2", "pc3"]:
		if cfg.has(p_key) and cfg[p_key].has("parts"):
			for part_name in cfg[p_key]["parts"]:
				if not active_parts.has(part_name):
					active_parts.append(part_name)

	for child in get_children():
		if child.name.begins_with("Spares"):
			var st = child.get("spare_type") if "spare_type" in child else ""
			var is_needed = (st in active_parts)
			child.visible = is_needed
			var col = child.get_node_or_null("CollisionShape3D")
			if col:
				col.disabled = not is_needed

	# Construir el panel de desafíos extra (inicialmente oculto hasta que comience el juego)
	_create_extra_challenges_panel()

	# Conectar señales del GameManager para actualizar desafíos extra
	if gm:
		if gm.has_signal("error_occurred"):
			gm.error_occurred.connect(_on_gm_error_occurred)
		if gm.has_signal("time_updated"):
			gm.time_updated.connect(_on_gm_time_updated)

	# Diálogo de bienvenida al modo de práctica con Joa
	dialog_box = DIALOG_SCENE.instantiate()
	$CanvasLayerHUD.add_child(dialog_box)

	if player and player.has_method("play_intro_cinematic"):
		player.play_intro_cinematic(func():
			_show_initial_dialog()
		)
	else:
		_show_initial_dialog()

func _setup_computer(node_path: String, id: int, data: Dictionary) -> void:
	var pc = get_node_or_null(node_path)
	if pc:
		pc.pc_id = id
		pc.set_meta("is_tutorial_pc", false)
		pc.set_meta("is_practice_pc", true)
		pc.diagnostic_question = data["question"]
		pc.diagnostic_faulty_parts.assign(data["parts"])
		pc.components = data["components"].duplicate()
		if pc.has_method("update_3d_state"):
			pc.update_3d_state()

# -----------------------------------------------------------------------------
# DIÁLOGO DE JOA HABLANDO ÚNICAMENTE DEL DESAFÍO
# -----------------------------------------------------------------------------
func _show_initial_dialog() -> void:
	GameManager.timer_active = false
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var cfg = PRACTICE_ZONE_CONFIG.get(current_zone, PRACTICE_ZONE_CONFIG["maestra"])
	var dialog_text: String = cfg.get("joa_speech", "¡Bienvenido al Desafío de Práctica!")

	if dialog_box and dialog_box.has_method("show_message"):
		dialog_box.show_message(
			"JOA",
			dialog_text,
			func():
				_start_countdown()
		)
	else:
		_start_countdown()

# -----------------------------------------------------------------------------
# CUENTA REGRESIVA 3... 2... 1... ¡YA!
# -----------------------------------------------------------------------------
func _start_countdown() -> void:
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameManager.timer_active = false

	if countdown_overlay:
		countdown_overlay.queue_free()
		countdown_overlay = null

	var gm = get_node_or_null("/root/GameManager")
	var m = gm.current_mode if gm and "current_mode" in gm and gm.current_mode != "" else "reparacion"

	countdown_overlay = LevelCountdown.start_countdown(get_tree(), self, m, func():
		countdown_overlay = null
		# Arrancar cronómetro y habilitar al jugador
		GameManager.timer_active = true
		if player and player.has_method("set_movement_enabled"):
			player.set_movement_enabled(true)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		# Mostrar y animar panel de desafíos extra
		if extra_challenges_panel:
			extra_challenges_panel.visible = true
			_animate_panel_entrance(extra_challenges_panel)
			_update_extra_challenges_ui()
	)

# -----------------------------------------------------------------------------
# PANEL DE DESAFÍOS EXTRA (LADO DERECHO)
# -----------------------------------------------------------------------------
func _create_extra_challenges_panel() -> void:
	var canvas_hud = get_node_or_null("CanvasLayerHUD")
	if not canvas_hud:
		return

	extra_challenges_panel = PanelContainer.new()
	extra_challenges_panel.name = "ExtraChallengesPanel"
	extra_challenges_panel.anchor_left = 1.0
	extra_challenges_panel.anchor_right = 1.0
	extra_challenges_panel.offset_left = -315.0
	extra_challenges_panel.offset_right = -15.0
	extra_challenges_panel.offset_top = 215.0
	extra_challenges_panel.offset_bottom = 445.0
	extra_challenges_panel.visible = false

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.07, 0.14, 0.92)
	sb.border_color = Color(0.0, 0.85, 1.0, 0.75)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	extra_challenges_panel.add_theme_stylebox_override("panel", sb)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	extra_challenges_panel.add_child(vbox)

	# Encabezado
	var title_lbl = Label.new()
	title_lbl.text = "🎯 DESAFÍOS EXTRA"
	title_lbl.add_theme_font_size_override("font_size", 15)
	title_lbl.modulate = Color(1.0, 0.85, 0.2)
	vbox.add_child(title_lbl)

	var sub_lbl = Label.new()
	sub_lbl.text = "Bonificaciones de Puntos"
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.modulate = Color(0.6, 0.8, 1.0, 0.7)
	vbox.add_child(sub_lbl)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Desafío 1: Cero Errores
	var box1 = VBoxContainer.new()
	var d1_title = Label.new()
	d1_title.text = "⚡ Cero Errores de Diagnóstico"
	d1_title.add_theme_font_size_override("font_size", 13)
	d1_title.modulate = Color(0.9, 0.9, 0.95)
	box1.add_child(d1_title)

	lbl_status_errors = Label.new()
	lbl_status_errors.text = "[ ✓ ACTIVO ]  +200 PTS"
	lbl_status_errors.add_theme_font_size_override("font_size", 12)
	lbl_status_errors.modulate = Color(0.2, 1.0, 0.4)
	box1.add_child(lbl_status_errors)
	vbox.add_child(box1)

	# Desafío 2: Velocidad
	var box2 = VBoxContainer.new()
	var d2_title = Label.new()
	d2_title.text = "⏱️ Tiempo Récord (>30% restante)"
	d2_title.add_theme_font_size_override("font_size", 13)
	d2_title.modulate = Color(0.9, 0.9, 0.95)
	box2.add_child(d2_title)

	lbl_status_time = Label.new()
	lbl_status_time.text = "[ ✓ POSIBLE ]  +150 PTS"
	lbl_status_time.add_theme_font_size_override("font_size", 12)
	lbl_status_time.modulate = Color(0.2, 1.0, 0.4)
	box2.add_child(lbl_status_time)
	vbox.add_child(box2)

	# Desafío 3: 3 Estaciones
	var box3 = VBoxContainer.new()
	var d3_title = Label.new()
	d3_title.text = "🛠️ Reparar las 3 Estaciones"
	d3_title.add_theme_font_size_override("font_size", 13)
	d3_title.modulate = Color(0.9, 0.9, 0.95)
	box3.add_child(d3_title)

	lbl_status_pcs = Label.new()
	lbl_status_pcs.text = "Progreso: [ 0 / 3 ]  +250 PTS"
	lbl_status_pcs.add_theme_font_size_override("font_size", 12)
	lbl_status_pcs.modulate = Color(0.0, 0.9, 1.0)
	box3.add_child(lbl_status_pcs)
	vbox.add_child(box3)

	canvas_hud.add_child(extra_challenges_panel)

func _animate_panel_entrance(panel: Control) -> void:
	panel.modulate.a = 0.0
	panel.offset_left += 40.0
	panel.offset_right += 40.0
	var tw = create_tween().set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, 0.3)
	tw.tween_property(panel, "offset_left", panel.offset_left - 40.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "offset_right", panel.offset_right - 40.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _update_extra_challenges_ui() -> void:
	if not extra_challenges_panel or not extra_challenges_panel.visible:
		return

	# Estado Cero Errores
	if lbl_status_errors:
		if GameManager.errors == 0:
			lbl_status_errors.text = "[ ✓ ACTIVO ]  +200 PTS"
			lbl_status_errors.modulate = Color(0.2, 1.0, 0.4)
		else:
			lbl_status_errors.text = "[ ✗ FALLIDO ]  0 PTS"
			lbl_status_errors.modulate = Color(1.0, 0.3, 0.3)

	# Estado Tiempo Récord
	if lbl_status_time:
		var has_time_bonus = (GameManager.time_left >= total_challenge_time * 0.30)
		if has_time_bonus:
			lbl_status_time.text = "[ ✓ LOGRABLE ]  +150 PTS"
			lbl_status_time.modulate = Color(0.2, 1.0, 0.4)
		else:
			lbl_status_time.text = "[ ✗ AGOTADO ]  0 PTS"
			lbl_status_time.modulate = Color(1.0, 0.4, 0.2)

	# Estado 3 Estaciones
	if lbl_status_pcs:
		var count = get_repaired_pcs_count()
		if count >= 3:
			lbl_status_pcs.text = "[ ✓ COMPLETADO 3/3 ]  +250 PTS"
			lbl_status_pcs.modulate = Color(0.2, 1.0, 0.4)
		else:
			lbl_status_pcs.text = "Progreso: [ %d / 3 ]  +250 PTS" % count
			lbl_status_pcs.modulate = Color(0.0, 0.9, 1.0)

func _on_gm_error_occurred(_new_errors: int, _delta: int) -> void:
	_update_extra_challenges_ui()

func _on_gm_time_updated(_time_left: float) -> void:
	_update_extra_challenges_ui()

func get_repaired_pcs_count() -> int:
	var count = 0
	for path in ["WorkBench1/Computer1", "WorkBench2/Computer2", "WorkBench3/Computer3"]:
		var pc = get_node_or_null(path)
		if is_instance_valid(pc) and pc.has_method("is_fully_repaired") and pc.is_fully_repaired():
			count += 1
	return count

# -----------------------------------------------------------------------------
# DETECCIÓN DE AVANCE Y FINALIZACIÓN
# -----------------------------------------------------------------------------
func _advance_to_completed() -> void:
	_update_extra_challenges_ui()
	var rep_count = get_repaired_pcs_count()
	if rep_count >= 3 and not is_victory_shown:
		is_victory_shown = true
		_on_all_pcs_repaired()

func _on_all_pcs_repaired() -> void:
	GameManager.timer_active = false

	# Ocultar paneles estándar del HUD para mostrar nuestra pantalla de celebración
	if hud:
		var win_p = hud.get_node_or_null("WinPanel")
		if win_p:
			win_p.visible = false
		var sol_hud = hud.get_node_or_null("FallaSolucionadaHUD")
		if sol_hud:
			sol_hud.visible = false

	# Ocultar panel de desafíos extra durante la victoria
	if extra_challenges_panel:
		extra_challenges_panel.visible = false

	# Mapear qué nodo de práctica se completó y registrar en SaveManager
	var zone_to_practice_node: Dictionary = {
		"maestra": 25,
		"cooler": 19,
		"ram": 20,
		"hdd": 21,
		"gpu": 22,
		"psu": 23,
		"cpu": 24,
		"systems_intro": 25,
		"os_install": 19,
		"malware_scan": 20,
		"driver_install": 21,
		"adware_cleaner": 22,
		"code_debugger": 23,
		"usb_backup": 24
	}
	var current_node_idx = zone_to_practice_node.get(current_zone, 25)

	var gm = get_node_or_null("/root/GameManager")
	var effective_mode = "reparacion"
	if current_zone in ["systems_intro", "os_install", "malware_scan", "driver_install", "adware_cleaner", "code_debugger", "usb_backup"]:
		effective_mode = "sistema"
	elif gm and "current_mode" in gm and gm.current_mode in ["reparacion", "sistema", "servidor"]:
		effective_mode = gm.current_mode

	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		sm.mark_node_completed(effective_mode, current_node_idx)
		var next_unlock: Dictionary = {
			25: 1,
			19: 2,
			20: 3,
			21: 4,
			22: 5,
			23: 6,
			24: 7
		}
		if next_unlock.has(current_node_idx):
			var next_node = next_unlock[current_node_idx]
			sm.unlock_node(effective_mode, next_node)
			SaveManager.just_unlocked_node = next_node
		sm.unlock_achievement("multitasker")
		if GameManager.errors == 0:
			sm.unlock_achievement("zero_errors")
		if GameManager.time_left >= total_challenge_time * 0.50:
			sm.unlock_achievement("speed_demon")

	# Cálculo de puntos ganados y desafíos completados
	var base_pts: int = 500
	var error_pts: int = 200 if (GameManager.errors == 0) else 0
	var time_pts: int = 150 if (GameManager.time_left >= total_challenge_time * 0.30) else 0
	var stations_pts: int = 250
	var total_earned_pts: int = base_pts + error_pts + time_pts + stations_pts

	GameManager.add_score(total_earned_pts)

	# Mostrar la pantalla de victoria con animación de "¡FELICIDADES!"
	_show_victory_screen(base_pts, error_pts, time_pts, stations_pts, total_earned_pts)

# -----------------------------------------------------------------------------
# PANTALLA ANIMADA DE "¡FELICIDADES!" CON CONTEO DE PUNTOS Y BOTONES
# -----------------------------------------------------------------------------
func _show_victory_screen(base_pts: int, error_pts: int, time_pts: int, stations_pts: int, total_pts: int) -> void:
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if victory_overlay:
		victory_overlay.queue_free()

	victory_overlay = CanvasLayer.new()
	victory_overlay.layer = 150
	add_child(victory_overlay)

	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	victory_overlay.add_child(root)

	# Fondo oscuro cyberpunk con viñeta
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.04, 0.09, 0.93)
	root.add_child(bg)

	# Marco central
	var center_box = VBoxContainer.new()
	center_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_box.alignment = BoxContainer.ALIGNMENT_CENTER
	center_box.add_theme_constant_override("separation", 20)
	root.add_child(center_box)

	# 1. ANIMACIÓN DE LETRAS "¡ F E L I C I D A D E S !"
	var letters_box = HBoxContainer.new()
	letters_box.alignment = BoxContainer.ALIGNMENT_CENTER
	letters_box.add_theme_constant_override("separation", 10)
	center_box.add_child(letters_box)

	var letters_str = ["¡", "F", "E", "L", "I", "C", "I", "D", "A", "D", "E", "S", "!"]
	var letter_labels: Array[Label] = []

	for i in range(letters_str.size()):
		var char_lbl = Label.new()
		char_lbl.text = letters_str[i]
		char_lbl.add_theme_font_size_override("font_size", 58)
		char_lbl.modulate = Color(1.0, 0.85, 0.2)
		char_lbl.pivot_offset = Vector2(20, 35)
		char_lbl.scale = Vector2(0.1, 0.1)
		char_lbl.modulate.a = 0.0
		letters_box.add_child(char_lbl)
		letter_labels.append(char_lbl)

	# Animar letras una por una con rebote elástico
	for i in range(letter_labels.size()):
		var lbl = letter_labels[i]
		var delay = i * 0.055
		get_tree().create_timer(delay).timeout.connect(func():
			if not is_instance_valid(lbl):
				return
			_play_sfx(1.0 + (i * 0.04), false)
			var tw = create_tween().set_parallel(true)
			tw.tween_property(lbl, "scale", Vector2(1.2, 1.2), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(lbl, "modulate:a", 1.0, 0.15)
			tw.chain().tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE)
		)

	# Subtítulo de desafío completado
	var sub_congrats = Label.new()
	sub_congrats.text = "★ DESAFÍO DE PRÁCTICA SUPERADO EXITOSAMENTE ★"
	sub_congrats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_congrats.add_theme_font_size_override("font_size", 18)
	sub_congrats.modulate = Color(0.0, 0.95, 1.0, 0.0)
	center_box.add_child(sub_congrats)

	var tw_sub = create_tween()
	tw_sub.tween_interval(0.7)
	tw_sub.tween_property(sub_congrats, "modulate:a", 1.0, 0.4)

	# 2. CUADRO DE DESAFÍOS Y CONTEO DE PUNTOS GANADOS
	var card_center = CenterContainer.new()
	center_box.add_child(card_center)

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(460, 200)
	var card_sb = StyleBoxFlat.new()
	card_sb.bg_color = Color(0.04, 0.07, 0.14, 0.96)
	card_sb.border_color = Color(0.0, 0.85, 1.0, 0.85)
	card_sb.set_border_width_all(2)
	card_sb.set_corner_radius_all(10)
	card_sb.content_margin_left = 24
	card_sb.content_margin_right = 24
	card_sb.content_margin_top = 16
	card_sb.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", card_sb)
	card.modulate.a = 0.0
	card_center.add_child(card)

	var card_vbox = VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 8)
	card.add_child(card_vbox)

	var card_header = Label.new()
	card_header.text = "DESGLOSE DE PUNTOS Y DESAFÍOS"
	card_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_header.add_theme_font_size_override("font_size", 14)
	card_header.modulate = Color(0.7, 0.85, 1.0)
	card_vbox.add_child(card_header)

	var sep_card = HSeparator.new()
	card_vbox.add_child(sep_card)

	_add_breakdown_row(card_vbox, "🎯 Desafío Base Superado:", "+%d PTS" % base_pts, Color(0.2, 1.0, 0.4))
	_add_breakdown_row(
		card_vbox,
		"⚡ Cero Errores de Diagnóstico:",
		("+%d PTS" % error_pts) if error_pts > 0 else "0 PTS (Fallido)",
		Color(0.2, 1.0, 0.4) if error_pts > 0 else Color(1.0, 0.35, 0.35)
	)
	_add_breakdown_row(
		card_vbox,
		"⏱️ Eficiencia de Tiempo (>30%):",
		("+%d PTS" % time_pts) if time_pts > 0 else "0 PTS (Agotado)",
		Color(0.2, 1.0, 0.4) if time_pts > 0 else Color(1.0, 0.4, 0.2)
	)
	_add_breakdown_row(card_vbox, "🛠️ 3 Estaciones Operativas:", "+%d PTS" % stations_pts, Color(0.0, 0.9, 1.0))

	var sep_total = HSeparator.new()
	card_vbox.add_child(sep_total)

	# Conteo animado de puntos ganados
	var total_lbl = Label.new()
	total_lbl.text = "PUNTOS GANADOS: +0 PTS"
	total_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total_lbl.add_theme_font_size_override("font_size", 22)
	total_lbl.modulate = Color(1.0, 0.85, 0.2)
	card_vbox.add_child(total_lbl)

	# Aparición de la tarjeta y conteo numérico progresivo
	var tw_card = create_tween()
	tw_card.tween_interval(0.85)
	tw_card.tween_property(card, "modulate:a", 1.0, 0.3)
	tw_card.chain().tween_callback(func():
		_animate_points_counter(total_lbl, total_pts)
	)

	# 3. BOTONES ABAJO: REPETIR Y SALIR
	var buttons_box = HBoxContainer.new()
	buttons_box.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_box.add_theme_constant_override("separation", 24)
	center_box.add_child(buttons_box)

	var btn_repetir = Button.new()
	btn_repetir.text = "🔄 REPETIR"
	btn_repetir.custom_minimum_size = Vector2(210, 52)
	btn_repetir.add_theme_font_size_override("font_size", 16)
	_style_victory_button(btn_repetir, Color(0.0, 0.8, 0.9), Color(0.05, 0.12, 0.22, 0.95))
	buttons_box.add_child(btn_repetir)

	var btn_salir = Button.new()
	btn_salir.text = "🚪 SALIR"
	btn_salir.custom_minimum_size = Vector2(210, 52)
	btn_salir.add_theme_font_size_override("font_size", 16)
	_style_victory_button(btn_salir, Color(1.0, 0.5, 0.1), Color(0.18, 0.08, 0.14, 0.95))
	buttons_box.add_child(btn_salir)

	btn_repetir.pressed.connect(func():
		_play_sfx(1.1, true)
		get_tree().reload_current_scene()
	)

	btn_salir.pressed.connect(func():
		_play_sfx(1.0, true)
		_on_siguiente()
	)

func _add_breakdown_row(parent: VBoxContainer, label_text: String, value_text: String, val_color: Color) -> void:
	var hbox = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.modulate = Color(0.9, 0.9, 0.95)
	hbox.add_child(lbl)

	var val = Label.new()
	val.text = value_text
	val.add_theme_font_size_override("font_size", 13)
	val.modulate = val_color
	hbox.add_child(val)
	parent.add_child(hbox)

func _animate_points_counter(label: Label, target_points: int) -> void:
	var roll_time = 1.35
	var steps_count = 25
	var step_delay = roll_time / float(steps_count)

	for s in range(1, steps_count + 1):
		var frac = float(s) / float(steps_count)
		var current_val = int(target_points * frac)
		get_tree().create_timer(s * step_delay).timeout.connect(func():
			if not is_instance_valid(label):
				return
			label.text = "PUNTOS GANADOS: +%d PTS" % current_val
			_play_sfx(1.0 + (frac * 0.6), false)
			if s == steps_count:
				# Destello final al llegar a los puntos completos
				label.text = "¡PUNTOS GANADOS: +%d PTS!" % target_points
				_play_sfx(1.8, true)
				var pop_tw = create_tween()
				pop_tw.tween_property(label, "scale", Vector2(1.15, 1.15), 0.15)
				pop_tw.chain().tween_property(label, "scale", Vector2(1.0, 1.0), 0.15)
		)

func _style_victory_button(btn: Button, border_col: Color, bg_col: Color) -> void:
	btn.focus_mode = Control.FOCUS_NONE

	var sb_normal = StyleBoxFlat.new()
	sb_normal.bg_color = bg_col
	sb_normal.border_color = border_col
	sb_normal.set_border_width_all(2)
	sb_normal.set_corner_radius_all(8)

	var sb_hover = StyleBoxFlat.new()
	sb_hover.bg_color = bg_col.lightened(0.15)
	sb_hover.border_color = Color(1.0, 1.0, 1.0, 0.95)
	sb_hover.set_border_width_all(3)
	sb_hover.set_corner_radius_all(8)

	var sb_pressed = StyleBoxFlat.new()
	sb_pressed.bg_color = bg_col.darkened(0.2)
	sb_pressed.border_color = border_col
	sb_pressed.set_border_width_all(2)
	sb_pressed.set_corner_radius_all(8)

	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_pressed)

func _play_sfx(pitch: float = 1.0, is_confirm: bool = false) -> void:
	var asp = AudioStreamPlayer.new()
	asp.bus = "Master"
	if is_confirm:
		asp.stream = load("res://efectos/sonido de entrada.ogg")
	else:
		asp.stream = load("res://efectos/teclado_click.wav")
	asp.pitch_scale = pitch
	add_child(asp)
	asp.play()
	asp.finished.connect(asp.queue_free)

func _on_reintentar() -> void:
	get_tree().reload_current_scene()

func _on_siguiente() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var gm = get_node_or_null("/root/GameManager")
	var m = gm.current_mode if gm and "current_mode" in gm else "reparacion"
	LevelSelect.initial_tab = "niveles"
	LevelSelect.initial_mode = m
	CyberPlayTransition.play_exit(
		get_tree(),
		m,
		"res://scenes/menus/LevelSelect.tscn",
		"RETO COMPLETADO",
		"// 3 ESTACIONES REPARADAS EXITOSAMENTE //"
	)
