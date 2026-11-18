extends Node3D

# =============================================================================
# NIVEL DE PRÁCTICA 3D - RETO CRONOMETRADO CON 3 MESAS Y 3 PCS (8 MINUTOS)
# CADA COMPUTADORA PRESENTA UNA FALLA DE HARDWARE DIFERENTE
# =============================================================================

const INTRO_SCENE: PackedScene = preload("res://scenes/ui/LevelIntroModal.tscn")
const DIALOG_SCENE: PackedScene = preload("res://scenes/ui/DialogBox.tscn")

static var practice_zone: String = "maestra"

@onready var player: CharacterBody3D = $Player
@onready var hud: Control = $CanvasLayerHUD/HUD

var dialog_box: Control = null
var current_zone: String = "maestra"

const PRACTICE_ZONE_CONFIG: Dictionary = {
	"cooler": {
		"title": "RETO DE PRÁCTICA // FAN COOLER & REFRIGERACIÓN",
		"sub": "3 ESTACIONES DE TRABAJO · LÍMITE DE TIEMPO: 8 MINUTOS",
		"desc": "¡Reto de refrigeración térmica!\n3 computadoras sobre la mesa con distintas fallas críticas de disipación y hardware.\nRepara los 3 equipos antes de que el cronómetro llegue a 00:00.",
		"pc1": {
			"question": "PC #1: El Fan Cooler está completamente detenido y el microprocesador alcanza 98°C apagándose repentinamente. ¿Qué componente debes reemplazar?",
			"parts": ["Fan Cooler"],
			"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "broken", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc2": {
			"question": "PC #2: La máquina enciende con sobrecalentamiento y la memoria emite 3 pitidos largos de advertencia en la BIOS. ¿Qué piezas están averiadas?",
			"parts": ["Fan Cooler", "RAM"],
			"components": {"RAM": "broken", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "broken", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc3": {
			"question": "PC #3: El cooler hace un chirrido agudo insoportable y el sistema no detecta el disco SATA principal. ¿Qué componentes fallaron?",
			"parts": ["Fan Cooler", "Disco Duro"],
			"components": {"RAM": "ok", "Disco Duro": "broken", "Grafica": "ok", "Fan Cooler": "broken", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		}
	},
	"ram": {
		"title": "RETO DE PRÁCTICA // BANCO DE MEMORIAS RAM",
		"sub": "3 ESTACIONES DE TRABAJO · LÍMITE DE TIEMPO: 8 MINUTOS",
		"desc": "¡Reto de memoria y buses!\n3 computadoras con pantallas azules y códigos POST de memoria.\nSustituye los módulos defectuosos en las 3 mesas antes de los 8 minutos.",
		"pc1": {
			"question": "PC #1: Pitidos intermitentes continuos al encender y la pantalla se queda sin señal de video. ¿Qué pieza falló?",
			"parts": ["RAM"],
			"components": {"RAM": "broken", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc2": {
			"question": "PC #2: Pantalla azul 'MEMORY_MANAGEMENT' recurrente y el ventilador del CPU vibra desequilibrado. ¿Qué piezas presentan falla?",
			"parts": ["RAM", "Fan Cooler"],
			"components": {"RAM": "broken", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "broken", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc3": {
			"question": "PC #3: Módulo sulfatado que impide el arranque y la tarjeta gráfica no da salida por HDMI. ¿Qué componentes debes sustituir?",
			"parts": ["RAM", "Grafica"],
			"components": {"RAM": "broken", "Disco Duro": "ok", "Grafica": "broken", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		}
	},
	"hdd": {
		"title": "RETO DE PRÁCTICA // ALMACENAMIENTO HDD & SSD",
		"sub": "3 ESTACIONES DE TRABAJO · LÍMITE DE TIEMPO: 8 MINUTOS",
		"desc": "¡Reto de almacenamiento masivo!\n3 equipos con fallas en bahías SATA y discos NVMe.\nCambia los discos y fija la tornillería antes de que finalicen los 8 minutos.",
		"pc1": {
			"question": "PC #1: El equipo muestra 'Reboot and Select proper Boot device' y el disco mecánico hace chasquidos internos. ¿Qué pieza falló?",
			"parts": ["Disco Duro"],
			"components": {"RAM": "ok", "Disco Duro": "broken", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc2": {
			"question": "PC #2: Unidad SSD no responde tras una sobretensión y la memoria RAM presenta errores de paridad. ¿Qué piezas requieren cambio?",
			"parts": ["Disco Duro", "RAM"],
			"components": {"RAM": "broken", "Disco Duro": "broken", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc3": {
			"question": "PC #3: Bloqueo de arranque en la partición del sistema y el Fan Cooler no gira para refrigerar el disipador. ¿Qué componentes fallaron?",
			"parts": ["Disco Duro", "Fan Cooler"],
			"components": {"RAM": "ok", "Disco Duro": "broken", "Grafica": "ok", "Fan Cooler": "broken", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		}
	},
	"gpu": {
		"title": "RETO DE PRÁCTICA // TARJETAS GRÁFICAS GPU",
		"sub": "3 ESTACIONES DE TRABAJO · LÍMITE DE TIEMPO: 8 MINUTOS",
		"desc": "¡Reto de procesamiento gráfico!\n3 estaciones con fallas de video, artefactos y controladores PCIe.\nRepara las 3 computadoras dentro del límite de 8 minutos.",
		"pc1": {
			"question": "PC #1: Artefactos visuales (glitches verdes) y cuelgues constantes en carga gráfica 3D. ¿Qué componente presenta la avería?",
			"parts": ["Grafica"],
			"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "broken", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc2": {
			"question": "PC #2: Ausencia total de señal de monitor y módulo RAM descalzado que genera pitidos. ¿Qué componentes debes intervenir?",
			"parts": ["Grafica", "RAM"],
			"components": {"RAM": "broken", "Disco Duro": "ok", "Grafica": "broken", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc3": {
			"question": "PC #3: Ventiladores de GPU frenados por sobretensión y el Fan Cooler del CPU atascado con polvo. ¿Qué piezas debes sustituir?",
			"parts": ["Grafica", "Fan Cooler"],
			"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "broken", "Fan Cooler": "broken", "Fuente": "ok", "CPU": "ok", "Placa Madre": "ok"}
		}
	},
	"psu": {
		"title": "RETO DE PRÁCTICA // FUENTES DE PODER ATX",
		"sub": "3 ESTACIONES DE TRABAJO · LÍMITE DE TIEMPO: 8 MINUTOS",
		"desc": "¡Reto de rieles de alimentación!\n3 equipos afectados por inestabilidad eléctrica y arneses defectuosos.\nReemplaza las fuentes y deja los 3 PCs funcionales en 8 minutos.",
		"pc1": {
			"question": "PC #1: La máquina no reacciona al botón de encendido y se percibe olor a plástico quemado en la fuente. ¿Qué pieza falló?",
			"parts": ["Fuente"],
			"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "broken", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc2": {
			"question": "PC #2: Apagones repentinos bajo consumo y disco de almacenamiento corrupto por cortes bruscos de energía. ¿Qué piezas están averiadas?",
			"parts": ["Fuente", "Disco Duro"],
			"components": {"RAM": "ok", "Disco Duro": "broken", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "broken", "CPU": "ok", "Placa Madre": "ok"}
		},
		"pc3": {
			"question": "PC #3: Rieles de 12V con caída de voltaje severa y la memoria RAM genera reinicios continuos. ¿Qué componentes requieren sustitución?",
			"parts": ["Fuente", "RAM"],
			"components": {"RAM": "broken", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "broken", "CPU": "ok", "Placa Madre": "ok"}
		}
	},
	"cpu": {
		"title": "RETO DE PRÁCTICA // PROCESADORES & SOCKET",
		"sub": "3 ESTACIONES DE TRABAJO · LÍMITE DE TIEMPO: 8 MINUTOS",
		"desc": "¡Reto de microarquitectura central!\n3 computadoras con fallas de procesador y sobrecalentamiento crítico.\nCompleta las 3 estaciones en menos de 8 minutos.",
		"pc1": {
			"question": "PC #1: El equipo sufre pantallas azules 'CLOCK_WATCHDOG_TIMEOUT' y el zócalo presenta pines de contacto dañados. ¿Qué componente falló?",
			"parts": ["CPU"],
			"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "broken", "Placa Madre": "ok"}
		},
		"pc2": {
			"question": "PC #2: Procesador con sobrecalentamiento súbito a 100°C y disipador térmico con aspas rotas. ¿Qué piezas debes sustituir?",
			"parts": ["CPU", "Fan Cooler"],
			"components": {"RAM": "ok", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "broken", "Fuente": "ok", "CPU": "broken", "Placa Madre": "ok"}
		},
		"pc3": {
			"question": "PC #3: Falla de cómputo en arranque POST y la memoria RAM no sincroniza la frecuencia base. ¿Qué piezas debes reparar?",
			"parts": ["CPU", "RAM"],
			"components": {"RAM": "broken", "Disco Duro": "ok", "Grafica": "ok", "Fan Cooler": "ok", "Fuente": "ok", "CPU": "broken", "Placa Madre": "ok"}
		}
	},
	"maestra": {
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
		"title": "RETO DE PRÁCTICA // 3 TERMINALES DE SISTEMAS",
		"sub": "ESTACIONES ALFA, BETA Y GAMMA · LÍMITE: 8 MINUTOS",
		"desc": "¡Reto cronometrado de software y ciberseguridad con Jeremías!\n3 terminales de sistemas con fallas simultáneas en las 3 mesas.\nEstación #1: Partición GPT y booteo EFI corruptos.\nEstación #2: Infección crítica de malware en memoria.\nEstación #3: Controladores obsoletos generando pantallas azules.\nRepara las 3 estaciones antes de que el reloj llegue a 00:00.",
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
		"title": "RETO DE PRÁCTICA // DESPLIEGUE MASIVO DE SO & GPT",
		"sub": "3 ESTACIONES DE TRABAJO · LÍMITE DE TIEMPO: 8 MINUTOS",
		"desc": "¡Despliegue rápido de sistemas!\n3 terminales con tablas de particiones dañadas.\nConfigura particiones GPT y monta el sistema en las 3 mesas en 8 minutos.",
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
		"title": "RETO DE PRÁCTICA // CONTROLADORES WHQL & DRIVERS",
		"sub": "3 ESTACIONES DE TRABAJO · LÍMITE DE TIEMPO: 8 MINUTOS",
		"desc": "¡Inestabilidad de controladores!\n3 terminales con pantallas azules continuas por drivers de GPU y buses DMA desactualizados.\nActualiza los paquetes oficiales en las 3 estaciones en 8 minutos.",
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
		"title": "RETO DE PRÁCTICA // FILTRADO DEFENSIVO DE ADWARE",
		"sub": "3 ESTACIONES DE TRABAJO · LÍMITE DE TIEMPO: 8 MINUTOS",
		"desc": "¡Saturación por spam y adware!\n3 terminales secuestradas por ventanas emergentes engañosas.\nDesactiva trampas y despliega el Ad-Blocker en las 3 mesas antes de los 8 minutos.",
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
		"title": "RETO DE PRÁCTICA // CLONACIÓN Y PENDRIVES BOOTEABLES",
		"sub": "3 ESTACIONES DE TRABAJO · LÍMITE DE TIEMPO: 8 MINUTOS",
		"desc": "¡Respaldo y clonación de emergencia!\n3 terminales que requieren flasheo urgente de medios booteables USB.\nPrepara las 3 unidades en las mesas dentro del límite de 8 minutos.",
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

	# REQUISITO EXPRESO: 8 MINUTOS (480 SEGUNDOS) DE CUENTA REGRESIVA
	GameManager.start_level(480.0)
	GameManager.timer_active = false
	if hud and hud.has_method("set_infinite_time"):
		hud.set_infinite_time(false)

	# Configurar las 3 computadoras de las 3 mesas con fallas distintas
	_setup_computer("WorkBench1/Computer1", 1, cfg["pc1"])
	_setup_computer("WorkBench2/Computer2", 2, cfg["pc2"])
	_setup_computer("WorkBench3/Computer3", 3, cfg["pc3"])

	# Filtrar cajas de repuestos: en zonas de práctica solo las cajas con las piezas que vayamos a arreglar
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

func _show_initial_dialog() -> void:
	GameManager.timer_active = false
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var is_systems = (current_zone in ["systems_intro", "os_install", "malware_scan", "driver_install", "adware_cleaner", "code_debugger", "usb_backup"])
	if not is_systems:
		var gm = get_node_or_null("/root/GameManager")
		if gm and "current_mode" in gm and gm.current_mode == "sistema":
			is_systems = true

	var speaker_name = "JEREMIAS" if is_systems else "JOA"
	var dialog_text = ""
	if is_systems:
		dialog_text = "¡Epaaa, fiera! Bienvenido al Reto Cronometrado de Práctica de Sistemas.\nTienes enfrente 3 terminales en las mesas esperando por ti con fallas críticas de software, particiones y ciberdefensa.\nTienes un límite estricto de 8 minutos para diagnosticar y restaurar las 3 estaciones antes de que colapse la red. ¡A romperla en el teclado!"
	else:
		dialog_text = "¡H-hola!... *(se acomoda las gafas con entusiasmo y una tierna sonrisa)*. ¡Bienvenido al Reto Cronometrado de Práctica!\nTienes enfrente 3 mesas de trabajo, cada una con una computadora que sufre una falla de hardware diferente.\nTienes un límite estricto de 8 minutos para diagnosticar los 3 equipos, buscar los repuestos en las cajas del taller y dejarlas 100% operativos. ¡Sé meticuloso y administra bien tu tiempo!"

	if dialog_box and dialog_box.has_method("show_message"):
		dialog_box.show_message(
			speaker_name,
			dialog_text,
			func():
				_show_practice_briefing()
		)
	else:
		_show_practice_briefing()

func _show_practice_briefing() -> void:
	GameManager.timer_active = false
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var cfg = PRACTICE_ZONE_CONFIG.get(current_zone, PRACTICE_ZONE_CONFIG["maestra"])
	var modal = INTRO_SCENE.instantiate()
	add_child(modal)
	
	var title_lbl = modal.get_node_or_null("Margin/Panel/VBox/TitleVBox/Title") as Label
	if title_lbl:
		title_lbl.text = cfg["title"]
	var sub_lbl = modal.get_node_or_null("Margin/Panel/VBox/TitleVBox/Subtitle") as Label
	if sub_lbl:
		sub_lbl.text = cfg["sub"]
		
	var desc_lbl = modal.get_node_or_null("Margin/Panel/VBox/Content/DescVBox/LblDesc") as Label
	if desc_lbl:
		desc_lbl.text = cfg["desc"]
		
	modal.started.connect(func():
		# Arranca el cronómetro de 8 minutos
		GameManager.timer_active = true
		if player and player.has_method("set_movement_enabled"):
			player.set_movement_enabled(true)
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	)

func _advance_to_completed() -> void:
	var pc1 = get_node_or_null("WorkBench1/Computer1")
	var pc2 = get_node_or_null("WorkBench2/Computer2")
	var pc3 = get_node_or_null("WorkBench3/Computer3")
	
	var all_fixed = true
	for pc in [pc1, pc2, pc3]:
		if is_instance_valid(pc) and pc.has_method("is_fully_repaired"):
			if not pc.is_fully_repaired():
				all_fixed = false
				break
				
	if all_fixed:
		_on_all_pcs_repaired()

func _on_all_pcs_repaired() -> void:
	GameManager.timer_active = false
	
	# Mapear qué nodo de práctica se completó y desbloquear el siguiente paso
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

	# Registrar progreso en SaveManager
	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		sm.mark_node_completed(effective_mode, current_node_idx)
		# Desbloquear siguiente paso según la cadena:
		# 25 (Práctica Intro) -> 1 (Tut 1)
		# 19 (Práctica 1) -> 2 (Tut 2)
		# 20 (Práctica 2) -> 3 (Tut 3)
		# 21 (Práctica 3) -> 4 (Tut 4)
		# 22 (Práctica 4) -> 5 (Tut 5)
		# 23 (Práctica 5) -> 6 (Tut 6)
		# 24 (Práctica 6) -> 7 (NIVEL 1 ¡Desbloqueo de campaña!)
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
			
	GameManager.win_level()

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
