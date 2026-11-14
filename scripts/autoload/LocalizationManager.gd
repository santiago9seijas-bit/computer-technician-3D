extends Node

# =============================================================================
# LOCALIZATION MANAGER - GESTOR GLOBAL DE IDIOMAS
# Soporta: Español (es), Inglés (en), Italiano (it), Portugués (pt)
# Cambia automáticamente todos los textos del árbol de escenas y registra
# las traducciones nativas en TranslationServer de Godot.
# =============================================================================

signal locale_changed(new_locale: String)

const LOCALES: Array[Dictionary] = [
	{"code": "es", "name": "ESPAÑOL"},
	{"code": "en", "name": "ENGLISH"},
	{"code": "it", "name": "ITALIANO"},
	{"code": "pt", "name": "PORTUGUÊS"}
]

var current_locale: String = "es"
var _locale_index: int = 0

# Diccionario integral de traducciones
const TRANSLATIONS: Dictionary = {
	"en": {
		# Menús Principales y Navegación
		"TERMINAL DE PEDIDOS": "ORDERS TERMINAL",
		"[ E ] ACCEDER": "[ E ] ACCESS",
		"Terminal de Pedidos: Gestión de Clientes": "Orders Terminal: Customer Management",
		"🖥️ [ TERMINAL // CLIENTES Y ENCARGOS TÉCNICOS ]": "🖥️ [ TERMINAL // CUSTOMERS & TECH WORK ORDERS ]",
		"FILTRAR PEDIDOS:": "FILTER ORDERS:",
		"TODOS": "ALL",
		"⏳ EN ESPERA": "⏳ PENDING",
		"🛠️ EN TALLER": "🛠️ IN WORKSHOP",
		"✅ LISTOS": "✅ READY",
		"LISTADO DE ÓRDENES ACTIVAS": "ACTIVE ORDERS LIST",
		"DETALLES TÉCNICOS DEL ENCARGO": "WORK ORDER TECHNICAL DETAILS",
		"ACEPTAR PEDIDO": "ACCEPT ORDER",
		"ACEPTAR PEDIDO Y ENVIAR AL TALLER": "ACCEPT ORDER & SEND TO WORKSHOP",
		"COMPLETAR Y ENTREGAR A CLIENTE": "COMPLETE & DELIVER TO CUSTOMER",
		"ORDEN FINALIZADA CON ÉXITO": "ORDER SUCCESSFULLY COMPLETED",
		"ESTADO: EN ESPERA DE ASIGNACIÓN": "STATUS: WAITING FOR ASSIGNMENT",
		"ESTADO: EN REPARACIÓN EN TALLER": "STATUS: IN REPAIR AT WORKSHOP",
		"ESTADO: ENTREGADO Y COBRADO": "STATUS: DELIVERED & PAID",
		"Equipo": "Device",
		"Síntoma Reportado": "Reported Symptom",
		"Diagnóstico / Tarea": "Diagnosis / Task",
		"Recompensa": "Reward",
		"En Espera": "Pending",
		"En Taller": "In Workshop",
		"Completados": "Completed",
		"ESPERA": "PENDING",
		"TALLER": "WORKSHOP",
		"LISTO": "READY",
		"No hay pedidos en esta categoría": "No orders in this category",
		"JUGAR": "PLAY",
		"PARTIDAS": "SAVED GAMES",
		"[ SISTEMA // GESTOR DE ALMACENAMIENTO ]": "[ SYSTEM // STORAGE MANAGER ]",
		"Selecciona un set de guardado para continuar o iniciar tu trayectoria técnica": "Select a save set to continue or start your technical career",
		"[ ENTER ] o [ CLIC ] para entrar en ese set de partida": "[ ENTER ] or [ CLICK ] to enter this save set",
		"enter or click to enter": "[ ENTER ] or [ CLICK ] to enter this save set",
		"[ ENTER ] o [ CLIC ] para entrar": "[ ENTER ] or [ CLICK ] to enter",
		"◀ VOLVER": "◀ BACK",
		"🗑️ REINICIAR SET": "🗑️ RESET SET",
		"▶ ENTRAR A LA PARTIDA (ENTER)": "▶ ENTER GAME (ENTER)",
		"▶ PARTIDA NUEVA (ENTER)": "▶ NEW GAME (ENTER)",
		"PARTIDA NUEVA": "NEW GAME",
		"▶ NUEVA PARTIDA (ENTER)": "▶ NEW GAME (ENTER)",
		"NUEVA PARTIDA": "NEW GAME",
		"🛠️ HERRAMIENTAS DESBLOQUEADAS:": "🛠️ UNLOCKED TOOLS:",
		"🎖️ MEDALLAS DE DIVISIÓN (3 MODOS):": "🎖️ DIVISION MEDALS (3 MODES):",
		"📊 REGISTRO DE AVANCE:": "📊 PROGRESS RECORD:",
		"COMPLETO": "COMPLETE",
		"DESBLOQUEADAS": "UNLOCKED",
		"OBTENIDAS": "OBTAINED",
		"SET": "SET",
		"Partida": "Game",
		"Última sesión:": "Last session:",
		"PTS": "PTS",
		"[ RANURA VACÍA - PARTIDA NUEVA ]": "[ EMPTY SLOT - NEW GAME ]",
		"[ RANURA VACÍA - NUEVA PARTIDA ]": "[ EMPTY SLOT - NEW GAME ]",
		"Pinzas": "Pliers",
		"Tester": "Multimeter / Tester",
		"Cautín": "Soldering Iron",
		"Reparación": "Repair",
		"Sistema": "System",
		"Servidor": "Server",
		"[ ⚠️ SYSTEM ERROR // EXCEPCIÓN DE MEMORIA ]": "[ ⚠️ SYSTEM ERROR // MEMORY EXCEPTION ]",
		"// REDIRIGIENDO AL GESTOR DE PARTIDAS... //": "// REDIRECTING TO SAVE SLOTS MANAGER... //",
		"[ ✓ CÓDIGO FUNCIONAL // SISTEMA REPARADO ]": "[ ✓ FUNCTIONAL CODE // SYSTEM RESTORED ]",
		"// KERNEL COMPILADO SIN ERRORES // RETORNANDO AL MENÚ //": "// KERNEL COMPILED WITHOUT ERRORS // RETURNING TO MENU //",
		"🪙 Puntos:": "🪙 Score:",
		"⭐ Estrellas:": "⭐ Stars:",
		"📚 Tutoriales:": "📚 Tutorials:",
		"🏆 Niveles:": "🏆 Levels:",
		"🔧 Prácticas:": "🔧 Practice:",
		"👾 Secretos:": "👾 Secrets:",
		"👤 Personajes:": "👤 Characters:",
		"CONFIGURACION": "SETTINGS",
		"CONFIGURACIÓN": "SETTINGS",
		"CONTROLES": "CONTROLS",
		"TUTORIALES": "TUTORIALS",
		"SALIR": "QUIT",
		"VOLVER": "BACK",
		"HARDWARE WORKSHOP // REPAIR OS v2.0": "HARDWARE WORKSHOP // REPAIR OS v2.0",
		"Version 0.0.9 Alpha": "Version 0.0.9 Alpha",
		"[ SISTEMA // GUÍA RÁPIDA ]": "[ SYSTEM // QUICK GUIDE ]",
		"MAPA DE CONTROLES": "CONTROLS MAP",
		"Comandos esenciales para el taller y minijuegos": "Essential commands for workshop and minigames",
		"── MOVIMIENTO ──": "── MOVEMENT ──",
		"Desplazarse": "Move",
		"Mirar / Cursor": "Look / Cursor",
		"Correr / Sprint": "Sprint / Run",
		"Saltar": "Jump",
		"Pausa / Ajustes": "Pause / Settings",
		"── HERRAMIENTAS ──": "── TOOLS ──",
		"Interactuar / Usar": "Interact / Use",
		"Destornillador Cruz (+)": "Phillips Screwdriver (+)",
		"Destornillador Pala (-)": "Flathead Screwdriver (-)",
		"Cautín, Pinzas, Tester": "Soldering Iron, Pliers, Tester",
		"💡 TIP: Pulsa [1] o [2] para alternar destornilladores en minijuegos.": "💡 TIP: Press [1] or [2] to switch screwdrivers in minigames.",
		"[ SISTEMA // PANEL DE CONFIGURACIÓN ]": "[ SYSTEM // SETTINGS PANEL ]",
		"CONFIGURACIÓN DEL SISTEMA": "SYSTEM SETTINGS",
		"Ajustes de audio, pantalla completa y calibración de periféricos": "Audio, fullscreen settings and peripheral calibration",
		"VOLUMEN MAESTRO": "MASTER VOLUME",
		"EFECTOS DE SONIDO (SFX)": "SOUND EFFECTS (SFX)",
		"MODO DE PANTALLA": "DISPLAY MODE",
		"PANTALLA: [ COMPLETA ]": "DISPLAY: [ FULLSCREEN ]",
		"PANTALLA: [ MODO VENTANA ]": "DISPLAY: [ WINDOWED ]",
		"SENSIBILIDAD DE CÁMARA": "CAMERA SENSITIVITY",
		"SHADERS HOLOGRÁFICOS": "HOLOGRAPHIC SHADERS",
		"ESTADO: [ ALTA DEFINICIÓN ]": "STATUS: [ HIGH DEFINITION ]",
		"ESTADO: [ SUAVE / RENDIMIENTO ]": "STATUS: [ SMOOTH / PERFORMANCE ]",
		"CONSUMO": "HARDWARE CONSUMPTION",
		"FOTOSENSIBILIDAD": "PHOTOSENSITIVITY",
		"ESTADO: [ ON ]": "STATUS: [ ON ]",
		"ESTADO: [ OFF ]": "STATUS: [ OFF ]",
		"IDIOMA": "LANGUAGE",
		"IDIOMA:": "LANGUAGE:",

		# Menú de Pausa
		"PAUSA": "PAUSE",
		"// SIMULACIÓN DETENIDA · TALLER EN ESPERA //": "// SIMULATION PAUSED · WORKSHOP ON STANDBY //",
		"CRONÓMETRO DE REPARACIÓN": "REPAIR TIMER",
		"TIEMPO:": "TIME:",
		"Presiona [ ESC ] para reanudar la partida.": "Press [ ESC ] to resume match.",
		"REANUDAR": "RESUME",
		"OPCIONES": "OPTIONS",
		"REINICIAR": "RESTART",
		"SALIR AL SELECTOR": "EXIT TO SELECTOR",
		"⚙ OPCIONES": "⚙ OPTIONS",
		"// CONFIGURACIÓN DEL SISTEMA //": "// SYSTEM SETTINGS //",
		"VOLUMEN AUDIO:": "AUDIO VOLUME:",
		"SENSIBILIDAD MOUSE:": "MOUSE SENSITIVITY:",
		"CONSUMO (FPS / HARDWARE):": "CONSUMPTION (FPS / HARDWARE):",
		"MODO FOTOSENSIBLE:": "PHOTOSENSITIVE MODE:",

		# Selector de Niveles
		"NIVELES": "LEVELS",
		"REPARACIÓN": "REPAIR",
		"REPARACIÓN (12)": "REPAIR (12)",
		"REPARACIÓN A FONDO": "DEEP REPAIR",
		"REPARACIÓN A FONDO (2)": "DEEP REPAIR (2)",
		"SISTEMA": "SYSTEM",
		"SISTEMA (12)": "SYSTEM (12)",
		"SERVIDOR": "SERVER",
		"SERVIDOR (12)": "SERVER (12)",
		"SECCIÓN DE REPARACIÓN // MAPA DE HARDWARE": "REPAIR SECTION // HARDWARE MAP",
		"SECCIÓN DE SISTEMAS // REDES Y TERMINALES": "SYSTEMS SECTION // NETWORKS & TERMINALS",
		"SECCIÓN DE SERVIDORES // RACKS Y TELEMETRÍA": "SERVERS SECTION // RACKS & TELEMETRY",
		"CENTRO DE ENTRENAMIENTO // GUÍA TÉCNICA Y SIMULADORES": "TRAINING CENTER // TECHNICAL GUIDE & SIMULATORS",
		"SECCIÓN DE REPARACIÓN // TELARAÑA DE HARDWARE": "REPAIR SECTION // HARDWARE WEB",
		"NÚCLEO TUTORIAL & ETAPA 1 [1-4]": "TUTORIAL CORE & STAGE 1 [1-4]",
		"SECCIÓN: REPARACIÓN A FONDO // MANTENIMIENTO AVANZADO DE CPU": "SECTION: DEEP REPAIR // ADVANCED CPU MAINTENANCE",
		"PASTA TÉRMICA": "THERMAL PASTE",
		"ALINEACIÓN DE PINES": "PIN ALIGNMENT",
		"CALIBRACIÓN": "CALIBRATION",
		"SECCIÓN DE SISTEMA // TELARAÑA DE RED LÓGICA": "SYSTEM SECTION // LOGICAL NETWORK WEB",
		"ETAPA 2: KERNEL & DRIVERS [5-8]": "STAGE 2: KERNEL & DRIVERS [5-8]",
		"ETAPA 3: CIBERSEGURIDAD & RESCATE [9-12]": "STAGE 3: CYBERSECURITY & RESCUE [9-12]",
		"SECCIÓN DE SERVIDOR // TELARAÑA DE DATACENTER": "SERVER SECTION // DATACENTER WEB",
		"ETAPA 2: ALMACENAMIENTO RAID [5-8]": "STAGE 2: RAID STORAGE [5-8]",
		"ETAPA 3: DATACENTER & CLOUD [9-12]": "STAGE 3: DATACENTER & CLOUD [9-12]",
		"ETAPA 1: TALLER BÁSICO [1-4]": "STAGE 1: BASIC WORKSHOP [1-4]",
		"ETAPA 2: HARDWARE AVANZADO [5-8]": "STAGE 2: ADVANCED HARDWARE [5-8]",
		"ETAPA 3: MAESTRÍA DE DIAGNÓSTICO [9-12]": "STAGE 3: DIAGNOSTIC MASTERY [9-12]",
		"⌜  CLIC EN CUALQUIER NODO PARA INSPECCIONAR SUS DATOS TÉCNICOS  ⌟": "⌜  CLICK ANY NODE TO INSPECT TECHNICAL DATA  ⌟",
		"▶ DALE CLIC PARA INICIAR": "▶ CLICK TO START",
		"[ DIVISIÓN: REPARACIÓN ]": "[ DIVISION: REPAIR ]",
		"[ DIVISIÓN: SISTEMA ]": "[ DIVISION: SYSTEM ]",
		"[ DIVISIÓN: SERVIDOR ]": "[ DIVISION: SERVER ]",
		"PUNTOS": "POINTS",

		# Selector de Dificultad
		"// PROTOCOLO DE DESAFÍO TÉCNICO //": "// TECHNICAL CHALLENGE PROTOCOL //",
		"SELECTOR DE DIFICULTAD": "DIFFICULTY SELECTOR",
		"MODO:": "MODE:",
		"TIEMPO LÍMITE:": "TIME LIMIT:",
		"MODO: [ NORMAL ] · 20 MINUTOS": "MODE: [ NORMAL ] · 20 MINUTES",
		"EQUILIBRIO TÁCTICO (20 MIN) · TIEMPO ESTÁNDAR DE TALLER": "TACTICAL BALANCE (20 MIN) · STANDARD WORKSHOP TIME",
		"TIEMPO EXTREMO (10 MIN) · EXIGENCIA MÁXIMA SIN MARGEN DE ERROR": "EXTREME TIME (10 MIN) · MAXIMUM DEMAND WITHOUT ERROR MARGIN",
		"RITMO VELOZ (15 MIN) · PRESIÓN CONSTANTE EN CADA REPARACIÓN": "FAST PACED (15 MIN) · CONSTANT PRESSURE ON EVERY REPAIR",
		"PRÁCTICA HOLGADA (25 MIN) · APRENDE Y EXPLORA CON TRANQUILIDAD": "RELAXED PRACTICE (25 MIN) · LEARN AND EXPLORE WITH TRANQUILITY",
		"10 MINUTOS": "10 MINUTES",
		"15 MINUTOS": "15 MINUTES",
		"20 MINUTOS": "20 MINUTES",
		"25 MINUTOS": "25 MINUTES",
		"BRUTAL   //   10 MIN": "BRUTAL   //   10 MIN",
		"DIFÍCIL   //   15 MIN": "HARD   //   15 MIN",
		"NORMAL   //   20 MIN": "NORMAL   //   20 MIN",
		"FÁCIL   //   25 MIN": "EASY   //   25 MIN",
		"▶  INICIAR NIVEL  ◀": "▶  START LEVEL  ◀",
		"[ PROTOCOLO: NORMAL · 20 MINUTOS ]": "[ PROTOCOL: NORMAL · 20 MINUTES ]",
		"[ PROTOCOLO: BRUTAL · 10 MINUTOS ]": "[ PROTOCOL: BRUTAL · 10 MINUTES ]",
		"[ PROTOCOLO: DIFÍCIL · 15 MINUTOS ]": "[ PROTOCOL: HARD · 15 MINUTES ]",
		"[ PROTOCOLO: FÁCIL · 25 MINUTOS ]": "[ PROTOCOL: EASY · 25 MINUTES ]",
		"BRUTAL": "BRUTAL",
		"DIFÍCIL": "HARD",
		"NORMAL": "NORMAL",
		"FÁCIL": "EASY",

		# Advertencia Fotosensible
		"[ ⚠️ AVISO DE SALUD Y ACCESIBILIDAD // SEGURIDAD VISUAL ]": "[ ⚠️ HEALTH & ACCESSIBILITY NOTICE // VISUAL SAFETY ]",
		"ADVERTENCIA DE FOTOSENSIBILIDAD": "PHOTOSENSITIVITY WARNING",
		"// PREVENCIÓN CONTRA LUCES CONTINUAS Y CONTRASTES //": "// PREVENTION AGAINST CONTINUOUS LIGHTS & CONTRASTS //",
		"MODO FOTOSENSIBLE: [ DESACTIVADO (Por defecto) ]": "PHOTOSENSITIVE MODE: [ DISABLED (Default) ]",
		"MODO FOTOSENSIBLE: [ ACTIVADO ]": "PHOTOSENSITIVE MODE: [ ENABLED ]",
		"Efectos visuales e iluminación originales activos": "Original visual effects and lighting active",
		"Efectos de brillo y parpadeos intensos atenuados para confort visual": "Bright effects and intense flashing dimmed for visual comfort",
		"✓ [ ENTENDIDO · CONTINUAR ]": "✓ [ UNDERSTOOD · CONTINUE ]",

		# HUD y Notificaciones
		"Errores:": "Errors:",
		"Tiempo:": "Time:",
		"Puntaje:": "Score:",
		"Errores: 0 / 20": "Errors: 0 / 20",
		"Tiempo: 02:00": "Time: 02:00",
		"Puntaje: 0": "Score: 0",
		"Tiempo: Infinito": "Time: Infinite",
		"(Dañada)": "(Damaged)",
		"(Nueva)": "(New)",
		"Pieza": "Part",
		"★ ¡FALLA SOLUCIONADA! ★": "★ FAULT RESOLVED! ★",
		"MOCHILA (3 slots)": "BACKPACK (3 slots)",
		"MISIÓN FALLIDA": "MISSION FAILED",
		"Tiempo agotado": "Time ran out",
		"REINTENTAR": "RETRY",
		"¡TRABAJO COMPLETADO!": "WORK COMPLETED!",
		"Puntaje Final: 300": "Final Score: 300",
		"Puntaje Final:": "Final Score:",
		"CONTINUAR": "CONTINUE",

		# Repuestos
		"RAM": "RAM",
		"Disco Duro": "Hard Drive",
		"Fan Cooler": "Fan Cooler",
		"Fuente": "Power Supply",
		"Grafica": "Graphics Card",
		"Placa Madre": "Motherboard",
		"CPU": "CPU",
		"Refrigeracion Liquida": "Liquid Cooling",

		# Tutoriales
		"// PROTOCOLO DE APRENDIZAJE TÉCNICO // MODO SEGURO //": "// TECHNICAL LEARNING PROTOCOL // SAFE MODE //",
		"TUTORIAL: REPARACIÓN BÁSICA": "TUTORIAL: BASIC REPAIR",
		"// EXTRACCIÓN Y DIAGNÓSTICO DE PIEZAS CLAVE //": "// EXTRACTION & DIAGNOSIS OF KEY PARTS //",
		"⚡ MEMORIA RAM (DDR4 / DDR5)": "⚡ RAM MEMORY (DDR4 / DDR5)",
		"Liberación de clips laterales del zócalo DIMM y extracción perpendicular segura sin dañar los pines dorados.": "Release DIMM socket side clips and extract safely perpendicular to avoid damaging golden pins.",
		"🔌 FUENTE DE PODER (ATX 850W)": "🔌 POWER SUPPLY (ATX 850W)",
		"Desacople seguro de arneses principales de 24 pines y CPU, liberando el cajón de alimentación del chasis.": "Safely disconnect 24-pin and CPU harnesses, freeing the power supply from the chassis.",
		"💾 MEMORIA SSD (M.2 NVMe / SATA)": "💾 SSD STORAGE (M.2 NVMe / SATA)",
		"Retiro del tornillo de fijación micrométrico y desacople térmico de almacenamiento de estado sólido.": "Remove micrometer screw and thermal detachment of solid-state storage.",
		"💽 DISCO DURO (HDD MECÁNICO 3.5\")": "💽 HARD DRIVE (3.5\" MECHANICAL HDD)",
		"[ MODO INDUCCIÓN ]": "[ INDUCTION MODE ]",
		"⏱ TIEMPO: INFINITO": "⏱ TIME: INFINITE",
		"▶ INICIAR TUTORIAL": "▶ START TUTORIAL",
		"[ // CERTIFICACIÓN TÉCNICA // ENTRENAMIENTO COMPLETADO // ]": "[ // TECHNICAL CERTIFICATION // TRAINING COMPLETED // ]",
		"¡FELICIDADES COMPLETASTE EL TUTORIAL!": "CONGRATULATIONS, YOU COMPLETED THE TUTORIAL!",
		"Desbloqueo & Montaje OK": "Unlock & Assembly OK",
		"Pines, Tornillo & Ranura OK": "Pins, Screw & Slot OK",
		"Arnés ATX & CPU OK": "ATX Harness & CPU OK",
		"¡Excelente desempeño, técnico! Has dominado las bases del taller y tu equipo está 100% operativo. Estás listo para avanzar a los retos del taller oficial.": "Excellent performance, technician! You have mastered workshop fundamentals and your PC is 100% operational. You are ready for official workshop challenges.",
		"🔄 REPETIR TUTORIAL": "🔄 REPEAT TUTORIAL",
		"🏁 FINALIZAR ▶": "🏁 FINISH ▶",
		"SALA DE ENTRENAMIENTO // TUTORIAL 3D": "TRAINING ROOM // 3D TUTORIAL",
		"[E] INTERACTUAR CON LA PC DE PRUEBA": "[E] INTERACT WITH TEST PC",
		"SALA DE ENTRENAMIENTO // MODO PRÁCTICA 3D": "TRAINING ROOM // 3D PRACTICE MODE",
		"[E] BANCO DE TRABAJO Y PC DE PRÁCTICA": "[E] WORKBENCH AND PRACTICE PC",

		# Taller y Modales de Inspección
		"📦 CAJA DE REPUESTOS\n[ PRESIONA E ]": "📦 SPARES BOX\n[ PRESS E ]",
		"PAPELERA": "TRASH BIN",
		"REABASTECER REPUESTOS": "RESTOCK SPARES",
		"BANCO DE REPARACIÓN Y DIAGNÓSTICO // HARDWARE PC": "REPAIR & DIAGNOSTIC BENCH // PC HARDWARE",
		"🔲 SOCKET PROCESADOR (CPU)": "🔲 PROCESSOR SOCKET (CPU)",
		"⬇ SACAR": "⬇ REMOVE",
		"🔍 EXAMINAR": "🔍 EXAMINE",
		"🧼 LIMPIAR [5]": "🧼 CLEAN [5]",
		"📍 PINES [3]": "📍 PINS [3]",
		"🌀 DISIPADOR / COOLER": "🌀 HEATSINK / COOLER",
		"🧠 BANCOS RAM DDR5": "🧠 DDR5 RAM BANKS",
		"🎮 RANURA PCIE 16X · TARJETA GRÁFICA": "🎮 PCIE 16X SLOT · GRAPHICS CARD",
		"💾 ALMACENAMIENTO M.2/SATA": "💾 M.2/SATA STORAGE",
		"⚡ PLACA BASE · CHIPSET & VRM": "⚡ MOTHERBOARD · CHIPSET & VRM",
		"🔌 BAHÍA FUENTE DE PODER (PSU)": "🔌 POWER SUPPLY BAY (PSU)",
		"[ VACÍO ]": "[ EMPTY ]",
		"🔍 PUNTOS DE EXAMINACIÓN:": "🔍 EXAMINATION POINTS:",
		"[ 4 / 4 DISPONIBLES ]": "[ 4 / 4 AVAILABLE ]",
		"◄ SALIR AL TALLER (CAMINAR / BUSCAR REPUESTOS)": "◄ RETURN TO WORKSHOP (WALK / FIND SPARES)",
		"🛠️ TOOLS": "🛠️ TOOLS",
		"📦 CAJA DE REPUESTOS DEL TALLER": "📦 WORKSHOP SPARES BOX",
		"// SELECCIONA EL COMPONENTE DE REEMPLAZO · ALMACÉN TÉCNICO //": "// SELECT REPLACEMENT COMPONENT · TECHNICAL STORAGE //",
		"MOCHILA DEL TÉCNICO: 0 / 3 ESPACIOS OCUPADOS": "TECHNICIAN BACKPACK: 0 / 3 SLOTS OCCUPIED",
		"[ESC] o [E] para Cerrar": "[ESC] or [E] to Close",
		"[ ⌨ PRESIONA 'E' PARA CONTINUAR ▶ ]": "[ ⌨ PRESS 'E' TO CONTINUE ▶ ]"
	},

	"it": {
		# Menús Principales y Navegación
		"TERMINAL DE PEDIDOS": "TERMINALE ORDINI",
		"[ E ] ACCEDER": "[ E ] ACCEDI",
		"Terminal de Pedidos: Gestión de Clientes": "Terminale Ordini: Gestione Clienti",
		"🖥️ [ TERMINAL // CLIENTES Y ENCARGOS TÉCNICOS ]": "🖥️ [ TERMINALE // CLIENTI E ORDINI TECNICI ]",
		"FILTRAR PEDIDOS:": "FILTRA ORDINI:",
		"TODOS": "TUTTI",
		"⏳ EN ESPERA": "⏳ IN ATTESA",
		"🛠️ EN TALLER": "🛠️ IN LABORATORIO",
		"✅ LISTOS": "✅ PRONTI",
		"LISTADO DE ÓRDENES ACTIVAS": "ELENCO ORDINI ATTIVI",
		"DETALLES TÉCNICOS DEL ENCARGO": "DETTAGLI TECNICI DELL'ORDINE",
		"ACEPTAR PEDIDO": "ACCETTA ORDINE",
		"ACEPTAR PEDIDO Y ENVIAR AL TALLER": "ACCETTA ORDINE E INVIA AL LABORATORIO",
		"COMPLETAR Y ENTREGAR A CLIENTE": "COMPLETA E CONSEGNA AL CLIENTE",
		"ORDEN FINALIZADA CON ÉXITO": "ORDINE COMPLETATO CON SUCCESSO",
		"ESTADO: EN ESPERA DE ASIGNACIÓN": "STATO: IN ATTESA DI ASSEGNAZIONE",
		"ESTADO: EN REPARACIÓN EN TALLER": "STATO: IN RIPARAZIONE IN LABORATORIO",
		"ESTADO: ENTREGADO Y COBRADO": "STATO: CONSEGNATO E PAGATO",
		"Equipo": "Dispositivo",
		"Síntoma Reportado": "Sintomo Segnalato",
		"Diagnóstico / Tarea": "Diagnosi / Attività",
		"Recompensa": "Ricompensa",
		"En Espera": "In Attesa",
		"En Taller": "In Laboratorio",
		"Completados": "Completati",
		"ESPERA": "ATTESA",
		"TALLER": "LAB",
		"LISTO": "PRONTO",
		"No hay pedidos en esta categoría": "Nessun ordine in questa categoria",
		"JUGAR": "GIOCA",
		"PARTIDAS": "SALVATAGGI",
		"[ SISTEMA // GESTOR DE ALMACENAMIENTO ]": "[ SISTEMA // GESTORE ARCHIVIAZIONE ]",
		"Selecciona un set de guardado para continuar o iniciar tu trayectoria técnica": "Seleziona uno slot di salvataggio per continuare o iniziare la carriera tecnica",
		"[ ENTER ] o [ CLIC ] para entrar en ese set de partida": "[ INVIO ] o [ CLIC ] per accedere a questo salvataggio",
		"enter or click to enter": "[ INVIO ] o [ CLIC ] per accedere a questo salvataggio",
		"[ ENTER ] o [ CLIC ] para entrar": "[ INVIO ] o [ CLIC ] per accedere",
		"◀ VOLVER": "◀ INDIETRO",
		"🗑️ REINICIAR SET": "🗑️ RESETTA SLOT",
		"▶ ENTRAR A LA PARTIDA (ENTER)": "▶ AVVIA PARTITA (INVIO)",
		"▶ PARTIDA NUEVA (ENTER)": "▶ NUOVA PARTITA (INVIO)",
		"PARTIDA NUEVA": "NUOVA PARTITA",
		"▶ NUEVA PARTIDA (ENTER)": "▶ NUOVA PARTITA (INVIO)",
		"NUEVA PARTIDA": "NUOVA PARTITA",
		"🛠️ HERRAMIENTAS DESBLOQUEADAS:": "🛠️ STRUMENTI SBLOCCATI:",
		"🎖️ MEDALLAS DE DIVISIÓN (3 MODOS):": "🎖️ MEDAGLIE DI DIVISIONE (3 MODI):",
		"📊 REGISTRO DE AVANCE:": "📊 REGISTRO AVANZAMENTO:",
		"COMPLETO": "COMPLETO",
		"DESBLOQUEADAS": "SBLOCCATE",
		"OBTENIDAS": "OTTENUTE",
		"SET": "SET",
		"Partida": "Partita",
		"Última sesión:": "Ultima sessione:",
		"PTS": "PTS",
		"[ RANURA VACÍA - PARTIDA NUEVA ]": "[ SLOT VUOTO - NUOVA PARTITA ]",
		"[ RANURA VACÍA - NUEVA PARTIDA ]": "[ SLOT VUOTO - NUOVA PARTITA ]",
		"Pinzas": "Pinzette",
		"Tester": "Tester Digitale",
		"Cautín": "Saldatore",
		"Reparación": "Riparazione",
		"Sistema": "Sistema",
		"Servidor": "Server",
		"[ ⚠️ SYSTEM ERROR // EXCEPCIÓN DE MEMORIA ]": "[ ⚠️ SYSTEM ERROR // ECCEZIONE DI MEMORIA ]",
		"// REDIRIGIENDO AL GESTOR DE PARTIDAS... //": "// REINDIRIZZAMENTO AL GESTORE SALVATAGGI... //",
		"[ ✓ CÓDIGO FUNCIONAL // SISTEMA REPARADO ]": "[ ✓ CODICE FUNZIONANTE // SISTEMA RIPARATO ]",
		"// KERNEL COMPILADO SIN ERRORES // RETORNANDO AL MENÚ //": "// KERNEL COMPILATO SENZA ERRORI // RITORNO AL MENU //",
		"🪙 Puntos:": "🪙 Punteggio:",
		"⭐ Estrellas:": "⭐ Stelle:",
		"📚 Tutoriales:": "📚 Tutorial:",
		"🏆 Niveles:": "🏆 Livelli:",
		"🔧 Prácticas:": "🔧 Pratica:",
		"👾 Secretos:": "👾 Segreti:",
		"👤 Personajes:": "👤 Personaggi:",
		"CONFIGURACION": "CONFIGURAZIONE",
		"CONFIGURACIÓN": "CONFIGURAZIONE",
		"CONTROLES": "CONTROLLI",
		"TUTORIALES": "TUTORIAL",
		"SALIR": "ESCI",
		"VOLVER": "INDIETRO",
		"HARDWARE WORKSHOP // REPAIR OS v2.0": "OFFICINA HARDWARE // REPAIR OS v2.0",
		"Version 0.0.9 Alpha": "Versione 0.0.9 Alpha",
		"[ SISTEMA // GUÍA RÁPIDA ]": "[ SISTEMA // GUIDA RAPIDA ]",
		"MAPA DE CONTROLES": "MAPPATURA CONTROLLI",
		"Comandos esenciales para el taller y minijuegos": "Comandi essenziali per l'officina e i minigiochi",
		"── MOVIMIENTO ──": "── MOVIMENTO ──",
		"Desplazarse": "Muoviti",
		"Mirar / Cursor": "Guarda / Cursore",
		"Correr / Sprint": "Corri / Scatto",
		"Saltar": "Salta",
		"Pausa / Ajustes": "Pausa / Impostazioni",
		"── HERRAMIENTAS ──": "── STRUMENTI ──",
		"Interactuar / Usar": "Interagisci / Usa",
		"Destornillador Cruz (+)": "Cacciavite a croce (+)",
		"Destornillador Pala (-)": "Cacciavite a taglio (-)",
		"Cautín, Pinzas, Tester": "Saldatore, Pinze, Tester",
		"💡 TIP: Pulsa [1] o [2] para alternar destornilladores en minijuegos.": "💡 CONSIGLIO: Premi [1] o [2] per alternare i cacciaviti nei minigiochi.",
		"[ SISTEMA // PANEL DE CONFIGURACIÓN ]": "[ SISTEMA // PANNELLO DI CONFIGURAZIONE ]",
		"CONFIGURACIÓN DEL SISTEMA": "CONFIGURAZIONE DI SISTEMA",
		"Ajustes de audio, pantalla completa y calibración de periféricos": "Regolazioni audio, schermo intero e calibrazione periferiche",
		"VOLUMEN MAESTRO": "VOLUME GENERALE",
		"EFECTOS DE SONIDO (SFX)": "EFFETTI SONORI (SFX)",
		"MODO DE PANTALLA": "MODALITÀ SCHERMO",
		"PANTALLA: [ COMPLETA ]": "SCHERMO: [ A TUTTO SCHERMO ]",
		"PANTALLA: [ MODO VENTANA ]": "SCHERMO: [ FINESTRA ]",
		"SENSIBILIDAD DE CÁMARA": "SENSIBILITÀ TELECAMERA",
		"SHADERS HOLOGRÁFICOS": "SHADERS OLOGRAFICI",
		"ESTADO: [ ALTA DEFINICIÓN ]": "STATO: [ ALTA DEFINIZIONE ]",
		"ESTADO: [ SUAVE / RENDIMIENTO ]": "STATO: [ FLUIDO / PRESTAZIONI ]",
		"CONSUMO": "CONSUMO HARDWARE",
		"FOTOSENSIBILIDAD": "FOTOSENSIBILITÀ",
		"ESTADO: [ ON ]": "STATO: [ ON ]",
		"ESTADO: [ OFF ]": "STATO: [ OFF ]",
		"IDIOMA": "LINGUA",
		"IDIOMA:": "LINGUA:",

		# Menú de Pausa
		"PAUSA": "PAUSA",
		"// SIMULACIÓN DETENIDA · TALLER EN ESPERA //": "// SIMULAZIONE SOSPESA · OFFICINA IN ATTESA //",
		"CRONÓMETRO DE REPARACIÓN": "CRONOMETRO RIPARAZIONE",
		"TIEMPO:": "TEMPO:",
		"Presiona [ ESC ] para reanudar la partida.": "Premi [ ESC ] per riprendere la partita.",
		"REANUDAR": "RIPRENDI",
		"OPCIONES": "OPZIONI",
		"REINICIAR": "RIAVVIA",
		"SALIR AL SELECTOR": "ESCI AL SELETTORE",
		"⚙ OPCIONES": "⚙ OPZIONI",
		"// CONFIGURACIÓN DEL SISTEMA //": "// CONFIGURAZIONE DI SISTEMA //",
		"VOLUMEN AUDIO:": "VOLUME AUDIO:",
		"SENSIBILIDAD MOUSE:": "SENSIBILITÀ MOUSE:",
		"CONSUMO (FPS / HARDWARE):": "CONSUMO (FPS / HARDWARE):",
		"MODO FOTOSENSIBLE:": "MODALITÀ FOTOSENSIBILE:",

		# Selector de Niveles
		"NIVELES": "LIVELLI",
		"REPARACIÓN": "RIPARAZIONE",
		"REPARACIÓN (12)": "RIPARAZIONE (12)",
		"REPARACIÓN A FONDO": "RIPARAZIONE APPROFONDITA",
		"REPARACIÓN A FONDO (2)": "RIPARAZIONE APPROFONDITA (2)",
		"SISTEMA": "SISTEMA",
		"SISTEMA (12)": "SISTEMA (12)",
		"SERVIDOR": "SERVER",
		"SERVIDOR (12)": "SERVER (12)",
		"SECCIÓN DE REPARACIÓN // MAPA DE HARDWARE": "SEZIONE RIPARAZIONI // MAPPA HARDWARE",
		"SECCIÓN DE SISTEMAS // REDES Y TERMINALES": "SEZIONE SISTEMI // RETI E TERMINALI",
		"SECCIÓN DE SERVIDORES // RACKS Y TELEMETRÍA": "SEZIONE SERVER // RACK E TELEMETRIA",
		"CENTRO DE ENTRENAMIENTO // GUÍA TÉCNICA Y SIMULADORES": "CENTRO DI ADDESTRAMENTO // GUIDA TECNICA E SIMULATORI",
		"SECCIÓN DE REPARACIÓN // TELARAÑA DE HARDWARE": "SEZIONE RIPARAZIONI // RETE HARDWARE",
		"NÚCLEO TUTORIAL & ETAPA 1 [1-4]": "NUCLEO TUTORIAL & FASE 1 [1-4]",
		"SECCIÓN: REPARACIÓN A FONDO // MANTENIMIENTO AVANZADO DE CPU": "SEZIONE: RIPARAZIONE APPROFONDITA // MANUTENZIONE AVANZATA CPU",
		"PASTA TÉRMICA": "PASTA TERMICA",
		"ALINEACIÓN DE PINES": "ALLINEAMENTO PIN",
		"CALIBRACIÓN": "CALIBRAZIONE",
		"SECCIÓN DE SISTEMA // TELARAÑA DE RED LÓGICA": "SEZIONE SISTEMA // RETE LOGICA",
		"ETAPA 2: KERNEL & DRIVERS [5-8]": "FASE 2: KERNEL & DRIVER [5-8]",
		"ETAPA 3: CIBERSEGURIDAD & RESCATE [9-12]": "FASE 3: CYBERSECURITY & SOCCORSO [9-12]",
		"SECCIÓN DE SERVIDOR // TELARAÑA DE DATACENTER": "SEZIONE SERVER // RETE DATACENTER",
		"ETAPA 2: ALMACENAMIENTO RAID [5-8]": "FASE 2: ARCHIVIAZIONE RAID [5-8]",
		"ETAPA 3: DATACENTER & CLOUD [9-12]": "FASE 3: DATACENTER & CLOUD [9-12]",
		"ETAPA 1: TALLER BÁSICO [1-4]": "FASE 1: OFFICINA BASE [1-4]",
		"ETAPA 2: HARDWARE AVANZADO [5-8]": "FASE 2: HARDWARE AVANZATO [5-8]",
		"ETAPA 3: MAESTRÍA DE DIAGNÓSTICO [9-12]": "FASE 3: MAESTRIA DIAGNOSTICA [9-12]",
		"⌜  CLIC EN CUALQUIER NODO PARA INSPECCIONAR SUS DATOS TÉCNICOS  ⌟": "⌜  CLIC SU QUALSIASI NODO PER ISPEZIONARE I DATI TECNICI  ⌟",
		"▶ DALE CLIC PARA INICIAR": "▶ CLICCA PER INIZIARE",
		"[ DIVISIÓN: REPARACIÓN ]": "[ DIVISIONE: RIPARAZIONE ]",
		"[ DIVISIÓN: SISTEMA ]": "[ DIVISIONE: SISTEMA ]",
		"[ DIVISIÓN: SERVIDOR ]": "[ DIVISIONE: SERVER ]",
		"PUNTOS": "PUNTI",

		# Selector de Dificultad
		"// PROTOCOLO DE DESAFÍO TÉCNICO //": "// PROTOCOLLO DI SFIDA TECNICA //",
		"SELECTOR DE DIFICULTAD": "SELETTORE DI DIFFICOLTÀ",
		"MODO:": "MODO:",
		"TIEMPO LÍMITE:": "LIMITE DI TEMPO:",
		"MODO: [ NORMAL ] · 20 MINUTOS": "MODO: [ NORMALE ] · 20 MINUTI",
		"EQUILIBRIO TÁCTICO (20 MIN) · TIEMPO ESTÁNDAR DE TALLER": "EQUILIBRIO TATTICO (20 MIN) · TEMPO STANDARD OFFICINA",
		"TIEMPO EXTREMO (10 MIN) · EXIGENCIA MÁXIMA SIN MARGEN DE ERROR": "TEMPO ESTREMO (10 MIN) · MASSIMA ESIGENZA SENZA MARGINE DI ERRORE",
		"RITMO VELOZ (15 MIN) · PRESIÓN CONSTANTE EN CADA REPARACIÓN": "RITMO VELOCE (15 MIN) · PRESSIONE COSTANTE IN OGNI RIPARAZIONE",
		"PRÁCTICA HOLGADA (25 MIN) · APRENDE Y EXPLORA CON TRANQUILIDAD": "PRATICA RILASSATA (25 MIN) · IMPARA ED ESPLORA CON CALMA",
		"10 MINUTOS": "10 MINUTI",
		"15 MINUTOS": "15 MINUTI",
		"20 MINUTOS": "20 MINUTI",
		"25 MINUTOS": "25 MINUTI",
		"BRUTAL   //   10 MIN": "BRUTALE   //   10 MIN",
		"DIFÍCIL   //   15 MIN": "DIFFICILE   //   15 MIN",
		"NORMAL   //   20 MIN": "NORMALE   //   20 MIN",
		"FÁCIL   //   25 MIN": "FACILE   //   25 MIN",
		"▶  INICIAR NIVEL  ◀": "▶  AVVIA LIVELLO  ◀",
		"[ PROTOCOLO: NORMAL · 20 MINUTOS ]": "[ PROTOCOLLO: NORMALE · 20 MINUTI ]",
		"[ PROTOCOLO: BRUTAL · 10 MINUTOS ]": "[ PROTOCOLLO: BRUTALE · 10 MINUTI ]",
		"[ PROTOCOLO: DIFÍCIL · 15 MINUTOS ]": "[ PROTOCOLLO: DIFFICILE · 15 MINUTI ]",
		"[ PROTOCOLO: FÁCIL · 25 MINUTOS ]": "[ PROTOCOLLO: FACILE · 25 MINUTI ]",
		"BRUTAL": "BRUTALE",
		"DIFÍCIL": "DIFFICILE",
		"NORMAL": "NORMALE",
		"FÁCIL": "FACILE",

		# Advertencia Fotosensible
		"[ ⚠️ AVISO DE SALUD Y ACCESIBILIDAD // SEGURIDAD VISUAL ]": "[ ⚠️ AVVISO DI SALUTE E ACCESSIBILITÀ // SICUREZZA VISIVA ]",
		"ADVERTENCIA DE FOTOSENSIBILIDAD": "AVVISO DI FOTOSENSIBILITÀ",
		"// PREVENCIÓN CONTRA LUCES CONTINUAS Y CONTRASTES //": "// PREVENZIONE CONTRO LUCI CONTINUE E CONTRASTI //",
		"MODO FOTOSENSIBLE: [ DESACTIVADO (Por defecto) ]": "MODO FOTOSENSIBILE: [ DISATTIVATO (Predefinito) ]",
		"MODO FOTOSENSIBLE: [ ACTIVADO ]": "MODO FOTOSENSIBILE: [ ATTIVATO ]",
		"Efectos visuales e iluminación originales activos": "Effetti visivi e illuminazione originali attivi",
		"Efectos de brillo y parpadeos intensos atenuados para confort visual": "Effetti luminosi e sfarfallii attenuati per comfort visivo",
		"✓ [ ENTENDIDO · CONTINUAR ]": "✓ [ HO CAPITO · CONTINUA ]",

		# HUD y Notificaciones
		"Errores:": "Errori:",
		"Tiempo:": "Tempo:",
		"Puntaje:": "Punteggio:",
		"Errores: 0 / 20": "Errori: 0 / 20",
		"Tiempo: 02:00": "Tempo: 02:00",
		"Puntaje: 0": "Punteggio: 0",
		"Tiempo: Infinito": "Tempo: Infinito",
		"(Dañada)": "(Danneggiata)",
		"(Nueva)": "(Nuova)",
		"Pieza": "Pezzo",
		"★ ¡FALLA SOLUCIONADA! ★": "★ GUASTO RISOLTO! ★",
		"MOCHILA (3 slots)": "ZAINO (3 slot)",
		"MISIÓN FALLIDA": "MISSIONE FALLITA",
		"Tiempo agotado": "Tempo scaduto",
		"REINTENTAR": "RIPROVA",
		"¡TRABAJO COMPLETADO!": "LAVORO COMPLETATO!",
		"Puntaje Final: 300": "Punteggio Finale: 300",
		"Puntaje Final:": "Punteggio Finale:",
		"CONTINUAR": "CONTINUA",

		# Repuestos
		"RAM": "RAM",
		"Disco Duro": "Disco Rigido",
		"Fan Cooler": "Dissipatore Ventola",
		"Fuente": "Alimentatore",
		"Grafica": "Scheda Grafica",
		"Placa Madre": "Scheda Madre",
		"CPU": "CPU",
		"Refrigeracion Liquida": "Raffreddamento a Liquido",

		# Tutoriales
		"// PROTOCOLO DE APRENDIZAJE TÉCNICO // MODO SEGURO //": "// PROTOCOLLO DI APPRENDIMENTO TECNICO // MODO SICURO //",
		"TUTORIAL: REPARACIÓN BÁSICA": "TUTORIAL: RIPARAZIONE BASE",
		"// EXTRACCIÓN Y DIAGNÓSTICO DE PIEZAS CLAVE //": "// ESTRAZIONE E DIAGNOSI DEI COMPONENTI CHIAVE //",
		"⚡ MEMORIA RAM (DDR4 / DDR5)": "⚡ MEMORIA RAM (DDR4 / DDR5)",
		"Liberación de clips laterales del zócalo DIMM y extracción perpendicular segura sin dañar los pines dorados.": "Rilascio delle levette laterali del socket DIMM ed estrazione perpendicolare sicura per proteggere i contatti dorati.",
		"🔌 FUENTE DE PODER (ATX 850W)": "🔌 ALIMENTATORE (ATX 850W)",
		"Desacople seguro de arneses principales de 24 pines y CPU, liberando el cajón de alimentación del chasis.": "Scollegamento sicuro dei cablaggi principali a 24 pin e CPU, liberando l'alimentatore dal telaio.",
		"💾 MEMORIA SSD (M.2 NVMe / SATA)": "💾 MEMORIA SSD (M.2 NVMe / SATA)",
		"Retiro del tornillo de fijación micrométrico y desacople térmico de almacenamiento de estado sólido.": "Rimozione della vite micrometrica e distacco termico dell'unità a stato solido.",
		"💽 DISCO DURO (HDD MECÁNICO 3.5\")": "💽 DISCO RIGIDO (HDD MECCANICO 3.5\")",
		"[ MODO INDUCCIÓN ]": "[ MODALITÀ GUIDATA ]",
		"⏱ TIEMPO: INFINITO": "⏱ TEMPO: INFINITO",
		"▶ INICIAR TUTORIAL": "▶ AVVIA TUTORIAL",
		"[ // CERTIFICACIÓN TÉCNICA // ENTRENAMIENTO COMPLETADO // ]": "[ // CERTIFICAZIONE TECNICA // ADDESTRAMENTO COMPLETATO // ]",
		"¡FELICIDADES COMPLETASTE EL TUTORIAL!": "CONGRATULAZIONI, HAI COMPLETATO IL TUTORIAL!",
		"Desbloqueo & Montaje OK": "Sblocco & Montaggio OK",
		"Pines, Tornillo & Ranura OK": "Pin, Vite & Slot OK",
		"Arnés ATX & CPU OK": "Cavi ATX & CPU OK",
		"¡Excelente desempeño, técnico! Has dominado las bases del taller y tu equipo está 100% operativo. Estás listo para avanzar a los retos del taller oficial.": "Ottimo lavoro, tecnico! Hai padroneggiato le basi dell'officina e il PC è operativo al 100%. Sei pronto per le sfide ufficiali.",
		"🔄 REPETIR TUTORIAL": "🔄 RIPETI TUTORIAL",
		"🏁 FINALIZAR ▶": "🏁 TERMINA ▶",
		"SALA DE ENTRENAMIENTO // TUTORIAL 3D": "SALA DI ADDESTRAMENTO // TUTORIAL 3D",
		"[E] INTERACTUAR CON LA PC DE PRUEBA": "[E] INTERAGISCI CON IL PC DI TEST",
		"SALA DE ENTRENAMIENTO // MODO PRÁCTICA 3D": "SALA DI ADDESTRAMENTO // MODO PRATICA 3D",
		"[E] BANCO DE TRABAJO Y PC DE PRÁCTICA": "[E] BANCO DA LAVORO E PC DI PRATICA",

		# Taller y Modales de Inspección
		"📦 CAJA DE REPUESTOS\n[ PRESIONA E ]": "📦 CASSETTA RICAMBI\n[ PREMI E ]",
		"PAPELERA": "CESTINO",
		"REABASTECER REPUESTOS": "RIFORNISCI RICAMBI",
		"BANCO DE REPARACIÓN Y DIAGNÓSTICO // HARDWARE PC": "BANCO DI RIPARAZIONE E DIAGNOSI // HARDWARE PC",
		"🔲 SOCKET PROCESADOR (CPU)": "🔲 SOCKET PROCESSORE (CPU)",
		"⬇ SACAR": "⬇ RIMUOVI",
		"🔍 EXAMINAR": "🔍 ESAMINA",
		"🧼 LIMPIAR [5]": "🧼 PULISCI [5]",
		"📍 PINES [3]": "📍 PIN [3]",
		"🌀 DISIPADOR / COOLER": "🌀 DISSIPATORE / COOLER",
		"🧠 BANCOS RAM DDR5": "🧠 BANCHI RAM DDR5",
		"🎮 RANURA PCIE 16X · TARJETA GRÁFICA": "🎮 SLOT PCIE 16X · SCHEDA GRAFICA",
		"💾 ALMACENAMIENTO M.2/SATA": "💾 ARCHIVIAZIONE M.2/SATA",
		"⚡ PLACA BASE · CHIPSET & VRM": "⚡ SCHEDA MADRE · CHIPSET & VRM",
		"🔌 BAHÍA FUENTE DE PODER (PSU)": "🔌 VANO ALIMENTATORE (PSU)",
		"[ VACÍO ]": "[ VUOTO ]",
		"🔍 PUNTOS DE EXAMINACIÓN:": "🔍 PUNTI DI ESAME:",
		"[ 4 / 4 DISPONIBLES ]": "[ 4 / 4 DISPONIBILI ]",
		"◄ SALIR AL TALLER (CAMINAR / BUSCAR REPUESTOS)": "◄ TORNA ALL'OFFICINA (CAMMINA / CERCA RICAMBI)",
		"🛠️ TOOLS": "🛠️ STRUMENTI",
		"📦 CAJA DE REPUESTOS DEL TALLER": "📦 CASSETTA RICAMBI OFFICINA",
		"// SELECCIONA EL COMPONENTE DE REEMPLAZO · ALMACÉN TÉCNICO //": "// SELEZIONA IL COMPONENTE DI RICAMBIO · MAGAZZINO TECNICO //",
		"MOCHILA DEL TÉCNICO: 0 / 3 ESPACIOS OCUPADOS": "ZAINO DEL TECNICO: 0 / 3 SPAZI OCCUPATI",
		"[ESC] o [E] para Cerrar": "[ESC] o [E] per Chiudere",
		"[ ⌨ PRESIONA 'E' PARA CONTINUAR ▶ ]": "[ ⌨ PREMI 'E' PER CONTINUARE ▶ ]"
	},

	"pt": {
		# Menús Principales y Navegación
		"TERMINAL DE PEDIDOS": "TERMINAL DE PEDIDOS",
		"[ E ] ACCEDER": "[ E ] ACESSAR",
		"Terminal de Pedidos: Gestión de Clientes": "Terminal de Pedidos: Gestão de Clientes",
		"🖥️ [ TERMINAL // CLIENTES Y ENCARGOS TÉCNICOS ]": "🖥️ [ TERMINAL // CLIENTES E ORDENS TÉCNICAS ]",
		"FILTRAR PEDIDOS:": "FILTRAR PEDIDOS:",
		"TODOS": "TODOS",
		"⏳ EN ESPERA": "⏳ EM ESPERA",
		"🛠️ EN TALLER": "🛠️ NA OFICINA",
		"✅ LISTOS": "✅ PRONTOS",
		"LISTADO DE ÓRDENES ACTIVAS": "LISTA DE ORDENS ATIVAS",
		"DETALLES TÉCNICOS DEL ENCARGO": "DETALHES TÉCNICOS DA ORDEM",
		"ACEPTAR PEDIDO": "ACEITAR PEDIDO",
		"ACEPTAR PEDIDO Y ENVIAR AL TALLER": "ACEITAR PEDIDO E ENVIAR À OFICINA",
		"COMPLETAR Y ENTREGAR A CLIENTE": "CONCLUIR E ENTREGAR AO CLIENTE",
		"ORDEN FINALIZADA CON ÉXITO": "ORDEM CONCLUÍDA COM SUCESSO",
		"ESTADO: EN ESPERA DE ASIGNACIÓN": "STATUS: AGUARDANDO ATRIBUIÇÃO",
		"ESTADO: EN REPARACIÓN EN TALLER": "STATUS: EM REPARO NA OFICINA",
		"ESTADO: ENTREGADO Y COBRADO": "STATUS: ENTREGUE E PAGO",
		"Equipo": "Equipamento",
		"Síntoma Reportado": "Sintoma Relatado",
		"Diagnóstico / Tarea": "Diagnóstico / Tarefa",
		"Recompensa": "Recompensa",
		"En Espera": "Em Espera",
		"En Taller": "Na Oficina",
		"Completados": "Concluídos",
		"ESPERA": "ESPERA",
		"TALLER": "OFICINA",
		"LISTO": "PRONTO",
		"No hay pedidos en esta categoría": "Nenhum pedido nesta categoria",
		"JUGAR": "JOGAR",
		"PARTIDAS": "PARTIDAS SALVAS",
		"[ SISTEMA // GESTOR DE ALMACENAMIENTO ]": "[ SISTEMA // GERENCIADOR DE ARMAZENAMENTO ]",
		"Selecciona un set de guardado para continuar o iniciar tu trayectoria técnica": "Selecione um conjunto de salvamento para continuar ou iniciar sua carreira técnica",
		"[ ENTER ] o [ CLIC ] para entrar en ese set de partida": "[ ENTER ] ou [ CLIQUE ] para entrar neste conjunto de partida",
		"enter or click to enter": "[ ENTER ] ou [ CLIQUE ] para entrar neste conjunto de partida",
		"[ ENTER ] o [ CLIC ] para entrar": "[ ENTER ] ou [ CLIQUE ] para entrar",
		"◀ VOLVER": "◀ VOLTAR",
		"🗑️ REINICIAR SET": "🗑️ REINICIAR CONJUNTO",
		"▶ ENTRAR A LA PARTIDA (ENTER)": "▶ ENTRAR NA PARTIDA (ENTER)",
		"▶ PARTIDA NUEVA (ENTER)": "▶ NOVO JOGO (ENTER)",
		"PARTIDA NUEVA": "NOVO JOGO",
		"▶ NUEVA PARTIDA (ENTER)": "▶ NOVO JOGO (ENTER)",
		"NUEVA PARTIDA": "NOVO JOGO",
		"🛠️ HERRAMIENTAS DESBLOQUEADAS:": "🛠️ FERRAMENTAS DESBLOQUEADAS:",
		"🎖️ MEDALLAS DE DIVISIÓN (3 MODOS):": "🎖️ MEDALHAS DE DIVISÃO (3 MODOS):",
		"📊 REGISTRO DE AVANCE:": "📊 REGISTRO DE PROGRESSO:",
		"COMPLETO": "COMPLETO",
		"DESBLOQUEADAS": "DESBLOQUEADAS",
		"OBTENIDAS": "OBTIDAS",
		"SET": "SET",
		"Partida": "Partida",
		"Última sesión:": "Última sessão:",
		"PTS": "PTS",
		"[ RANURA VACÍA - PARTIDA NUEVA ]": "[ SLOT VAZIO - NOVO JOGO ]",
		"[ RANURA VACÍA - NUEVA PARTIDA ]": "[ SLOT VAZIO - NOVO JOGO ]",
		"Pinzas": "Pinças",
		"Tester": "Multímetro / Tester",
		"Cautín": "Ferro de Solda",
		"Reparación": "Reparação",
		"Sistema": "Sistema",
		"Servidor": "Servidor",
		"[ ⚠️ SYSTEM ERROR // EXCEPCIÓN DE MEMORIA ]": "[ ⚠️ SYSTEM ERROR // EXCEÇÃO DE MEMÓRIA ]",
		"// REDIRIGIENDO AL GESTOR DE PARTIDAS... //": "// REDIRECIONANDO AO GERENCIADOR DE SALVAMENTOS... //",
		"[ ✓ CÓDIGO FUNCIONAL // SISTEMA REPARADO ]": "[ ✓ CÓDIGO FUNCIONAL // SISTEMA REPARADO ]",
		"// KERNEL COMPILADO SIN ERRORES // RETORNANDO AL MENÚ //": "// KERNEL COMPILADO SEM ERROS // RETORNANDO AO MENU //",
		"🪙 Puntos:": "🪙 Pontos:",
		"⭐ Estrellas:": "⭐ Estrelas:",
		"📚 Tutoriales:": "📚 Tutoriais:",
		"🏆 Niveles:": "🏆 Níveis:",
		"🔧 Prácticas:": "🔧 Práticas:",
		"👾 Secretos:": "👾 Segredos:",
		"👤 Personajes:": "👤 Personagens:",
		"CONFIGURACION": "CONFIGURAÇÃO",
		"CONFIGURACIÓN": "CONFIGURAÇÃO",
		"CONTROLES": "CONTROLES",
		"TUTORIALES": "TUTORIAIS",
		"SALIR": "SAIR",
		"VOLVER": "VOLTAR",
		"HARDWARE WORKSHOP // REPAIR OS v2.0": "OFICINA DE HARDWARE // REPAIR OS v2.0",
		"Version 0.0.9 Alpha": "Versão 0.0.9 Alpha",
		"[ SISTEMA // GUÍA RÁPIDA ]": "[ SISTEMA // GUIA RÁPIDO ]",
		"MAPA DE CONTROLES": "MAPA DE CONTROLES",
		"Comandos esenciales para el taller y minijuegos": "Comandos essenciais para a oficina e minijogos",
		"── MOVIMIENTO ──": "── MOVIMENTO ──",
		"Desplazarse": "Mover-se",
		"Mirar / Cursor": "Olhar / Cursor",
		"Correr / Sprint": "Correr / Sprint",
		"Saltar": "Pular",
		"Pausa / Ajustes": "Pausa / Ajustes",
		"── HERRAMIENTAS ──": "── FERRAMENTAS ──",
		"Interactuar / Usar": "Interagir / Usar",
		"Destornillador Cruz (+)": "Chave Phillips (+)",
		"Destornillador Pala (-)": "Chave de fenda (-)",
		"Cautín, Pinzas, Tester": "Ferro de solda, Alicate, Multímetro",
		"💡 TIP: Pulsa [1] o [2] para alternar destornilladores en minijuegos.": "💡 DICA: Pressione [1] ou [2] para alternar chaves de fenda nos minijogos.",
		"[ SISTEMA // PANEL DE CONFIGURACIÓN ]": "[ SISTEMA // PAINEL DE CONFIGURAÇÕES ]",
		"CONFIGURACIÓN DEL SISTEMA": "CONFIGURAÇÃO DO SISTEMA",
		"Ajustes de audio, pantalla completa y calibración de periféricos": "Ajustes de áudio, tela cheia e calibração de periféricos",
		"VOLUMEN MAESTRO": "VOLUME PRINCIPAL",
		"EFECTOS DE SONIDO (SFX)": "EFEITOS SONOROS (SFX)",
		"MODO DE PANTALLA": "MODO DE TELA",
		"PANTALLA: [ COMPLETA ]": "TELA: [ TELA CHEIA ]",
		"PANTALLA: [ MODO VENTANA ]": "TELA: [ MODO JANELA ]",
		"SENSIBILIDAD DE CÁMARA": "SENSIBILIDADE DA CÂMERA",
		"SHADERS HOLOGRÁFICOS": "SHADERS HOLOGRÁFICOS",
		"ESTADO: [ ALTA DEFINICIÓN ]": "STATUS: [ ALTA DEFINIÇÃO ]",
		"ESTADO: [ SUAVE / RENDIMIENTO ]": "STATUS: [ SUAVE / DESEMPENHO ]",
		"CONSUMO": "CONSUMO DE HARDWARE",
		"FOTOSENSIBILIDAD": "FOTOSENSIBILIDADE",
		"ESTADO: [ ON ]": "STATUS: [ ON ]",
		"ESTADO: [ OFF ]": "STATUS: [ OFF ]",
		"IDIOMA": "IDIOMA",
		"IDIOMA:": "IDIOMA:",

		# Menú de Pausa
		"PAUSA": "PAUSA",
		"// SIMULACIÓN DETENIDA · TALLER EN ESPERA //": "// SIMULAÇÃO EM PAUSA · OFICINA EM ESPERA //",
		"CRONÓMETRO DE REPARACIÓN": "CRONÔMETRO DE REPARO",
		"TIEMPO:": "TEMPO:",
		"Presiona [ ESC ] para reanudar la partida.": "Pressione [ ESC ] para retomar o jogo.",
		"REANUDAR": "RETOMAR",
		"OPCIONES": "OPÇÕES",
		"REINICIAR": "REINICIAR",
		"SALIR AL SELECTOR": "SAIR PARA SELETOR",
		"⚙ OPCIONES": "⚙ OPÇÕES",
		"// CONFIGURACIÓN DEL SISTEMA //": "// CONFIGURAÇÃO DO SISTEMA //",
		"VOLUMEN AUDIO:": "VOLUME DE ÁUDIO:",
		"SENSIBILIDAD MOUSE:": "SENSIBILIDADE DO MOUSE:",
		"CONSUMO (FPS / HARDWARE):": "CONSUMO (FPS / HARDWARE):",
		"MODO FOTOSENSIBLE:": "MODO FOTOSSENSÍVEL:",

		# Selector de Niveles
		"NIVELES": "NÍVEIS",
		"REPARACIÓN": "REPARO",
		"REPARACIÓN (12)": "REPARO (12)",
		"REPARACIÓN A FONDO": "REPARO COMPLETO",
		"REPARACIÓN A FONDO (2)": "REPARO COMPLETO (2)",
		"SISTEMA": "SISTEMA",
		"SISTEMA (12)": "SISTEMA (12)",
		"SERVIDOR": "SERVIDOR",
		"SERVIDOR (12)": "SERVIDOR (12)",
		"SECCIÓN DE REPARACIÓN // MAPA DE HARDWARE": "SEÇÃO DE REPARO // MAPA DE HARDWARE",
		"SECCIÓN DE SISTEMAS // REDES Y TERMINALES": "SEÇÃO DE SISTEMAS // REDES E TERMINAIS",
		"SECCIÓN DE SERVIDORES // RACKS Y TELEMETRÍA": "SEÇÃO DE SERVIDORES // RACKS E TELEMETRIA",
		"CENTRO DE ENTRENAMIENTO // GUÍA TÉCNICA Y SIMULADORES": "CENTRO DE TREINAMENTO // GUIA TÉCNICO E SIMULADORES",
		"SECCIÓN DE REPARACIÓN // TELARAÑA DE HARDWARE": "SEÇÃO DE REPARO // REDE DE HARDWARE",
		"NÚCLEO TUTORIAL & ETAPA 1 [1-4]": "NÚCLEO TUTORIAL & ETAPA 1 [1-4]",
		"SECCIÓN: REPARACIÓN A FONDO // MANTENIMIENTO AVANZADO DE CPU": "SEÇÃO: REPARO COMPLETO // MANUTENÇÃO AVANÇADA DE CPU",
		"PASTA TÉRMICA": "PASTA TÉRMICA",
		"ALINEACIÓN DE PINES": "ALINHAMENTO DE PINOS",
		"CALIBRACIÓN": "CALIBRAÇÃO",
		"SECCIÓN DE SISTEMA // TELARAÑA DE RED LÓGICA": "SEÇÃO DE SISTEMA // REDE LÓGICA",
		"ETAPA 2: KERNEL & DRIVERS [5-8]": "ETAPA 2: KERNEL & DRIVERS [5-8]",
		"ETAPA 3: CIBERSEGURIDAD & RESCATE [9-12]": "ETAPA 3: CIBERSEGURANÇA & RESGATE [9-12]",
		"SECCIÓN DE SERVIDOR // TELARAÑA DE DATACENTER": "SEÇÃO DE SERVIDOR // REDE DE DATACENTER",
		"ETAPA 2: ALMACENAMIENTO RAID [5-8]": "ETAPA 2: ARMAZENAMENTO RAID [5-8]",
		"ETAPA 3: DATACENTER & CLOUD [9-12]": "ETAPA 3: DATACENTER & NUVEM [9-12]",
		"ETAPA 1: TALLER BÁSICO [1-4]": "ETAPA 1: OFICINA BÁSICA [1-4]",
		"ETAPA 2: HARDWARE AVANZADO [5-8]": "ETAPA 2: HARDWARE AVANÇADO [5-8]",
		"ETAPA 3: MAESTRÍA DE DIAGNÓSTICO [9-12]": "ETAPA 3: DOMÍNIO DE DIAGNÓSTICO [9-12]",
		"⌜  CLIC EN CUALQUIER NODO PARA INSPECCIONAR SUS DATOS TÉCNICOS  ⌟": "⌜  CLIQUE EM QUALQUER NÓ PARA INSPECIONAR SEUS DADOS TÉCNICOS  ⌟",
		"▶ DALE CLIC PARA INICIAR": "▶ CLIQUE PARA INICIAR",
		"[ DIVISIÓN: REPARACIÓN ]": "[ DIVISÃO: REPARO ]",
		"[ DIVISIÓN: SISTEMA ]": "[ DIVISÃO: SISTEMA ]",
		"[ DIVISIÓN: SERVIDOR ]": "[ DIVISÃO: SERVIDOR ]",
		"PUNTOS": "PONTOS",

		# Selector de Dificultad
		"// PROTOCOLO DE DESAFÍO TÉCNICO //": "// PROTOCOLO DE DESAFIO TÉCNICO //",
		"SELECTOR DE DIFICULTAD": "SELETOR DE DIFICULDADE",
		"MODO:": "MODO:",
		"TIEMPO LÍMITE:": "LIMITE DE TEMPO:",
		"MODO: [ NORMAL ] · 20 MINUTOS": "MODO: [ NORMAL ] · 20 MINUTOS",
		"EQUILIBRIO TÁCTICO (20 MIN) · TIEMPO ESTÁNDAR DE TALLER": "EQUILÍBRIO TÁTICO (20 MIN) · TEMPO PADRÃO DE OFICINA",
		"TIEMPO EXTREMO (10 MIN) · EXIGENCIA MÁXIMA SIN MARGEN DE ERROR": "TEMPO EXTREMO (10 MIN) · EXIGÊNCIA MÁXIMA SEM MARGEM DE ERRO",
		"RITMO VELOZ (15 MIN) · PRESIÓN CONSTANTE EN CADA REPARACIÓN": "RITMO VELOZ (15 MIN) · PRESSÃO CONSTANTE A CADA REPARO",
		"PRÁCTICA HOLGADA (25 MIN) · APRENDE Y EXPLORA CON TRANQUILIDAD": "PRÁTICA TRANQUILA (25 MIN) · APRENDA E EXPLORE COM CALMA",
		"10 MINUTOS": "10 MINUTOS",
		"15 MINUTOS": "15 MINUTOS",
		"20 MINUTOS": "20 MINUTOS",
		"25 MINUTOS": "25 MINUTOS",
		"BRUTAL   //   10 MIN": "BRUTAL   //   10 MIN",
		"DIFÍCIL   //   15 MIN": "DIFÍCIL   //   15 MIN",
		"NORMAL   //   20 MIN": "NORMAL   //   20 MIN",
		"FÁCIL   //   25 MIN": "FÁCIL   //   25 MIN",
		"▶  INICIAR NIVEL  ◀": "▶  INICIAR NÍVEL  ◀",
		"[ PROTOCOLO: NORMAL · 20 MINUTOS ]": "[ PROTOCOLO: NORMAL · 20 MINUTOS ]",
		"[ PROTOCOLO: BRUTAL · 10 MINUTOS ]": "[ PROTOCOLO: BRUTAL · 10 MINUTOS ]",
		"[ PROTOCOLO: DIFÍCIL · 15 MINUTOS ]": "[ PROTOCOLO: DIFÍCIL · 15 MINUTOS ]",
		"[ PROTOCOLO: FÁCIL · 25 MINUTOS ]": "[ PROTOCOLO: FÁCIL · 25 MINUTOS ]",
		"BRUTAL": "BRUTAL",
		"DIFÍCIL": "DIFÍCIL",
		"NORMAL": "NORMAL",
		"FÁCIL": "FÁCIL",

		# Advertencia Fotosensible
		"[ ⚠️ AVISO DE SALUD Y ACCESIBILIDAD // SEGURIDAD VISUAL ]": "[ ⚠️ AVISO DE SAÚDE E ACESSIBILIDADE // SEGURANÇA VISUAL ]",
		"ADVERTENCIA DE FOTOSENSIBILIDAD": "AVISO DE FOTOSSENSIBILIDADE",
		"// PREVENCIÓN CONTRA LUCES CONTINUAS Y CONTRASTES //": "// PREVENÇÃO CONTRA LUZES CONTÍNUAS E CONTRASTES //",
		"MODO FOTOSENSIBLE: [ DESACTIVADO (Por defecto) ]": "MODO FOTOSSENSÍVEL: [ DESATIVADO (Padrão) ]",
		"MODO FOTOSENSIBLE: [ ACTIVADO ]": "MODO FOTOSSENSÍVEL: [ ATIVADO ]",
		"Efectos visuales e iluminación originales activos": "Efeitos visuais e iluminação originais ativos",
		"Efectos de brillo y parpadeos intensos atenuados para confort visual": "Efeitos de brilho e piscadas atenuados para conforto visual",
		"✓ [ ENTENDIDO · CONTINUAR ]": "✓ [ ENTENDIDO · CONTINUAR ]",

		# HUD y Notificaciones
		"Errores:": "Erros:",
		"Tiempo:": "Tempo:",
		"Puntaje:": "Pontuação:",
		"Errores: 0 / 20": "Erros: 0 / 20",
		"Tiempo: 02:00": "Tempo: 02:00",
		"Puntaje: 0": "Pontuação: 0",
		"Tiempo: Infinito": "Tempo: Infinito",
		"(Dañada)": "(Danificada)",
		"(Nueva)": "(Nova)",
		"Pieza": "Peça",
		"★ ¡FALLA SOLUCIONADA! ★": "★ FALHA RESOLVIDA! ★",
		"MOCHILA (3 slots)": "MOCHILA (3 slots)",
		"MISIÓN FALLIDA": "MISSÃO FALHOU",
		"Tiempo agotado": "Tempo esgotado",
		"REINTENTAR": "TENTAR NOVAMENTE",
		"¡TRABAJO COMPLETADO!": "TRABALHO CONCLUÍDO!",
		"Puntaje Final: 300": "Pontuação Final: 300",
		"Puntaje Final:": "Pontuação Final:",
		"CONTINUAR": "CONTINUAR",

		# Repuestos
		"RAM": "RAM",
		"Disco Duro": "Disco Rígido",
		"Fan Cooler": "Cooler da CPU",
		"Fuente": "Fonte de Alimentação",
		"Grafica": "Placa de Vídeo",
		"Placa Madre": "Placa-Mãe",
		"CPU": "CPU",
		"Refrigeracion Liquida": "Water Cooler",

		# Tutoriales
		"// PROTOCOLO DE APRENDIZAJE TÉCNICO // MODO SEGURO //": "// PROTOCOLO DE APRENDIZAGEM TÉCNICA // MODO SEGURO //",
		"TUTORIAL: REPARACIÓN BÁSICA": "TUTORIAL: REPARO BÁSICO",
		"// EXTRACCIÓN Y DIAGNÓSTICO DE PIEZAS CLAVE //": "// EXTRAÇÃO E DIAGNÓSTICO DE PEÇAS PRINCIPAIS //",
		"⚡ MEMORIA RAM (DDR4 / DDR5)": "⚡ MEMÓRIA RAM (DDR4 / DDR5)",
		"Liberación de clips laterales del zócalo DIMM y extracción perpendicular segura sin dañar los pines dorados.": "Liberação das travas laterais do soquete DIMM e extração perpendicular segura sem danificar os pinos dourados.",
		"🔌 FUENTE DE PODER (ATX 850W)": "🔌 FONTE DE ALIMENTAÇÃO (ATX 850W)",
		"Desacople seguro de arneses principales de 24 pines y CPU, liberando el cajón de alimentación del chasis.": "Desconexão segura dos cabos principais de 24 pinos e CPU, liberando a fonte do gabinete.",
		"💾 MEMORIA SSD (M.2 NVMe / SATA)": "💾 ARMAZENAMENTO SSD (M.2 NVMe / SATA)",
		"Retiro del tornillo de fijación micrométrico y desacople térmico de almacenamiento de estado sólido.": "Remoção do parafuso micrométrico e desencaixe térmico do armazenamento de estado sólido.",
		"💽 DISCO DURO (HDD MECÁNICO 3.5\")": "💽 DISCO RÍGIDO (HDD MECÂNICO 3.5\")",
		"[ MODO INDUCCIÓN ]": "[ MODO INDUÇÃO ]",
		"⏱ TIEMPO: INFINITO": "⏱ TEMPO: INFINITO",
		"▶ INICIAR TUTORIAL": "▶ INICIAR TUTORIAL",
		"[ // CERTIFICACIÓN TÉCNICA // ENTRENAMIENTO COMPLETADO // ]": "[ // CERTIFICAÇÃO TÉCNICA // TREINAMENTO CONCLUÍDO // ]",
		"¡FELICIDADES COMPLETASTE EL TUTORIAL!": "PARABÉNS, VOCÊ COMPLETOU O TUTORIAL!",
		"Desbloqueo & Montaje OK": "Destravamento & Montagem OK",
		"Pines, Tornillo & Ranura OK": "Pinos, Parafuso & Slot OK",
		"Arnés ATX & CPU OK": "Cabos ATX & CPU OK",
		"¡Excelente desempeño, técnico! Has dominado las bases del taller y tu equipo está 100% operativo. Estás listo para avanzar a los retos del taller oficial.": "Excelente desempenho, técnico! Você dominou a oficina básica e seu PC está 100% operacional. Pronto para os desafios oficiais.",
		"🔄 REPETIR TUTORIAL": "🔄 REPETIR TUTORIAL",
		"🏁 FINALIZAR ▶": "🏁 FINALIZAR ▶",
		"SALA DE ENTRENAMIENTO // TUTORIAL 3D": "SALA DE TREINAMENTO // TUTORIAL 3D",
		"[E] INTERACTUAR CON LA PC DE PRUEBA": "[E] INTERAGIR COM O PC DE TESTE",
		"SALA DE ENTRENAMIENTO // MODO PRÁCTICA 3D": "SALA DE TREINAMENTO // MODO PRÁTICA 3D",
		"[E] BANCO DE TRABAJO Y PC DE PRÁCTICA": "[E] BANCADA DE TRABALHO E PC DE PRÁTICA",

		# Taller y Modales de Inspección
		"📦 CAJA DE REPUESTOS\n[ PRESIONA E ]": "📦 CAIXA DE PEÇAS\n[ PRESSIONE E ]",
		"PAPELERA": "LIXEIRA",
		"REABASTECER REPUESTOS": "REABASTECER PEÇAS",
		"BANCO DE REPARACIÓN Y DIAGNÓSTICO // HARDWARE PC": "BANCADA DE REPARO E DIAGNÓSTICO // HARDWARE PC",
		"🔲 SOCKET PROCESADOR (CPU)": "🔲 SOQUETE PROCESSADOR (CPU)",
		"⬇ SACAR": "⬇ REMOVER",
		"🔍 EXAMINAR": "🔍 EXAMINAR",
		"🧼 LIMPIAR [5]": "🧼 LIMPAR [5]",
		"📍 PINES [3]": "📍 PINOS [3]",
		"🌀 DISIPADOR / COOLER": "🌀 DISSIPADOR / COOLER",
		"🧠 BANCOS RAM DDR5": "🧠 BANCOS RAM DDR5",
		"🎮 RANURA PCIE 16X · TARJETA GRÁFICA": "🎮 SLOT PCIE 16X · PLACA DE VÍDEO",
		"💾 ALMACENAMIENTO M.2/SATA": "💾 ARMAZENAMENTO M.2/SATA",
		"⚡ PLACA BASE · CHIPSET & VRM": "⚡ PLACA-MÃE · CHIPSET & VRM",
		"🔌 BAHÍA FUENTE DE PODER (PSU)": "🔌 BAIA FONTE DE ALIMENTAÇÃO (PSU)",
		"[ VACÍO ]": "[ VAZIO ]",
		"🔍 PUNTOS DE EXAMINACIÓN:": "🔍 PONTOS DE EXAME:",
		"[ 4 / 4 DISPONIBLES ]": "[ 4 / 4 DISPONÍVEIS ]",
		"◄ SALIR AL TALLER (CAMINAR / BUSCAR REPUESTOS)": "◄ VOLTAR PARA OFICINA (CAMINHAR / BUSCAR PEÇAS)",
		"🛠️ TOOLS": "🛠️ FERRAMENTAS",
		"📦 CAJA DE REPUESTOS DEL TALLER": "📦 CAIXA DE PEÇAS DA OFICINA",
		"// SELECCIONA EL COMPONENTE DE REEMPLAZO · ALMACÉN TÉCNICO //": "// SELECIONE O COMPONENTE DE REPOSIÇÃO · ALMOXARIFADO TÉCNICO //",
		"MOCHILA DEL TÉCNICO: 0 / 3 ESPACIOS OCUPADOS": "MOCHILA DO TÉCNICO: 0 / 3 ESPAÇOS OCUPADOS",
		"[ESC] o [E] para Cerrar": "[ESC] ou [E] para Fechar",
		"[ ⌨ PRESIONA 'E' PARA CONTINUAR ▶ ]": "[ ⌨ PRESSIONE 'E' PARA CONTINUAR ▶ ]"
	}
}

var _reverse_to_es: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_reverse_map()
	_setup_godot_translations()
	set_locale("es", false)
	get_tree().node_added.connect(_on_node_added)

func _init_reverse_map() -> void:
	_reverse_to_es.clear()
	for lang in ["en", "it", "pt"]:
		var d: Dictionary = TRANSLATIONS.get(lang, {})
		for orig_key in d.keys():
			var foreign = str(d[orig_key])
			_reverse_to_es[foreign] = orig_key
			_reverse_to_es[foreign.strip_edges()] = orig_key

	# Aliases y normalización
	_reverse_to_es["PLAY"] = "JUGAR"
	_reverse_to_es["GIOCA"] = "JUGAR"
	_reverse_to_es["JOGAR"] = "JUGAR"
	_reverse_to_es["SETTINGS"] = "CONFIGURACIÓN"
	_reverse_to_es["CONFIGURACION"] = "CONFIGURACIÓN"
	_reverse_to_es["IMPOSTAZIONI"] = "CONFIGURACIÓN"
	_reverse_to_es["CONFIGURAÇÕES"] = "CONFIGURACIÓN"
	_reverse_to_es["CONTROLS"] = "CONTROLES"
	_reverse_to_es["CONTROLLI"] = "CONTROLES"
	_reverse_to_es["TUTORIALS"] = "TUTORIALES"
	_reverse_to_es["TUTORIAL"] = "TUTORIALES"
	_reverse_to_es["TUTORIAIS"] = "TUTORIALES"
	_reverse_to_es["QUIT"] = "SALIR"
	_reverse_to_es["ESCI"] = "SALIR"
	_reverse_to_es["SAIR"] = "SALIR"
	_reverse_to_es["BACK"] = "VOLVER"
	_reverse_to_es["◀ BACK"] = "◀ VOLVER"
	_reverse_to_es["◀ INDIETRO"] = "◀ VOLVER"
	_reverse_to_es["◀ VOLTAR"] = "◀ VOLVER"
	_reverse_to_es["enter or click to enter"] = "[ ENTER ] o [ CLIC ] para entrar en ese set de partida"
	_reverse_to_es["enter or click to enter this save set"] = "[ ENTER ] o [ CLIC ] para entrar en ese set de partida"
	_reverse_to_es["[ ENTER ] or [ CLICK ] to enter this save set"] = "[ ENTER ] o [ CLIC ] para entrar en ese set de partida"
	_reverse_to_es["[ INVIO ] o [ CLIC ] per accedere a questo salvataggio"] = "[ ENTER ] o [ CLIC ] para entrar en ese set de partida"
	_reverse_to_es["[ ENTER ] ou [ CLIQUE ] para entrar neste conjunto de partida"] = "[ ENTER ] o [ CLIC ] para entrar en ese set de partida"
	_reverse_to_es["[ ENTER ] or [ CLICK ] to enter"] = "[ ENTER ] o [ CLIC ] para entrar"
	_reverse_to_es["NEW GAME"] = "PARTIDA NUEVA"
	_reverse_to_es["▶ NEW GAME (ENTER)"] = "▶ PARTIDA NUEVA (ENTER)"
	_reverse_to_es["[ EMPTY SLOT - NEW GAME ]"] = "[ RANURA VACÍA - PARTIDA NUEVA ]"
	_reverse_to_es["NUOVA PARTITA"] = "PARTIDA NUEVA"
	_reverse_to_es["▶ NUOVA PARTITA (INVIO)"] = "▶ PARTIDA NUEVA (ENTER)"
	_reverse_to_es["[ SLOT VUOTO - NUOVA PARTITA ]"] = "[ RANURA VACÍA - PARTIDA NUEVA ]"
	_reverse_to_es["NOVO JOGO"] = "PARTIDA NUEVA"
	_reverse_to_es["▶ NOVO JOGO (ENTER)"] = "▶ PARTIDA NUEVA (ENTER)"
	_reverse_to_es["[ SLOT VAZIO - NOVO JOGO ]"] = "[ RANURA VACÍA - PARTIDA NUEVA ]"
	_reverse_to_es["NUEVA PARTIDA"] = "PARTIDA NUEVA"
	_reverse_to_es["▶ NUEVA PARTIDA (ENTER)"] = "▶ PARTIDA NUEVA (ENTER)"
	_reverse_to_es["[ RANURA VACÍA - NUEVA PARTIDA ]"] = "[ RANURA VACÍA - PARTIDA NUEVA ]"
	_reverse_to_es["LANGUAGE"] = "IDIOMA"
	_reverse_to_es["LENGUAJE"] = "IDIOMA"
	_reverse_to_es["LINGUA"] = "IDIOMA"

func _setup_godot_translations() -> void:
	for loc_code in ["en", "it", "pt"]:
		var tr_obj = Translation.new()
		tr_obj.locale = loc_code
		var dict: Dictionary = TRANSLATIONS.get(loc_code, {})
		for orig_key in dict.keys():
			tr_obj.add_message(orig_key, dict[orig_key])
		TranslationServer.add_translation(tr_obj)

func get_locales() -> Array[Dictionary]:
	return LOCALES

func get_locale() -> String:
	return current_locale

func get_locale_name() -> String:
	for item in LOCALES:
		if item.code == current_locale:
			return item.name
	return "ESPAÑOL"

func get_locale_display(code: String = "") -> String:
	var target = code if code != "" else current_locale
	for item in LOCALES:
		if item.code == target:
			return item.name
	return "ESPAÑOL"

func translate_text(text_key: String) -> String:
	if text_key == "":
		return ""
	var clean = text_key.strip_edges()
	var spanish_key = clean
	if _reverse_to_es.has(clean):
		spanish_key = _reverse_to_es[clean]
	elif _reverse_to_es.has(text_key):
		spanish_key = _reverse_to_es[text_key]

	if current_locale == "es":
		return spanish_key

	var dict: Dictionary = TRANSLATIONS.get(current_locale, {})
	if dict.has(spanish_key):
		return dict[spanish_key]
	if dict.has(clean):
		return dict[clean]
	if dict.has(text_key):
		return dict[text_key]

	return super.tr(spanish_key)

func set_locale(code: String, save: bool = true) -> void:
	var found = false
	for i in range(LOCALES.size()):
		if LOCALES[i].code == code:
			_locale_index = i
			found = true
			break
	if not found:
		_locale_index = 0
		code = "es"

	current_locale = code
	TranslationServer.set_locale(code)

	# Actualizar todos los nodos del árbol de escenas
	var tree = get_tree()
	if tree and tree.root:
		update_tree_translations(tree.root)

	if save:
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("save_settings"):
			gm.save_settings()

	locale_changed.emit(current_locale)

func next_locale() -> String:
	_locale_index = (_locale_index + 1) % LOCALES.size()
	set_locale(LOCALES[_locale_index].code, true)
	return get_locale_name()

func prev_locale() -> String:
	_locale_index = (_locale_index - 1 + LOCALES.size()) % LOCALES.size()
	set_locale(LOCALES[_locale_index].code, true)
	return get_locale_name()

func update_tree_translations(node: Node) -> void:
	if not is_instance_valid(node):
		return
	_translate_node(node)
	for child in node.get_children():
		update_tree_translations(child)

func _translate_node(node: Node) -> void:
	if not is_instance_valid(node):
		return

	# Si es un nodo de control con texto (Label, Button, etc.)
	if "text" in node and typeof(node.text) == TYPE_STRING and node.text != "":
		# Asegurar que la clave original sea la base en español
		if not node.has_meta("i18n_orig"):
			var base_key = node.text.strip_edges()
			if _reverse_to_es.has(base_key):
				base_key = _reverse_to_es[base_key]
			elif _reverse_to_es.has(node.text):
				base_key = _reverse_to_es[node.text]
			node.set_meta("i18n_orig", base_key)
		var orig_text = str(node.get_meta("i18n_orig"))
		if orig_text != "":
			var translated = translate_text(orig_text)
			if node.text != translated:
				node.text = translated
				if node.has_method("queue_redraw"):
					node.queue_redraw()

	# Tooltip
	if "tooltip_text" in node and typeof(node.tooltip_text) == TYPE_STRING and node.tooltip_text != "":
		if not node.has_meta("i18n_tooltip_orig"):
			var base_tip = node.tooltip_text.strip_edges()
			if _reverse_to_es.has(base_tip):
				base_tip = _reverse_to_es[base_tip]
			node.set_meta("i18n_tooltip_orig", base_tip)
		var orig_tooltip = str(node.get_meta("i18n_tooltip_orig"))
		if orig_tooltip != "":
			var translated_tooltip = translate_text(orig_tooltip)
			if node.tooltip_text != translated_tooltip:
				node.tooltip_text = translated_tooltip

func _on_node_added(node: Node) -> void:
	if is_instance_valid(node):
		_translate_node(node)
