extends CanvasLayer

signal minigame_finished(success: bool)

# =============================================================================
# MINIJUEGO: INSTALADOR ANDROMEDA LINUX (ARCH STYLE CLI TERMINAL)
# Control exclusivo por teclado - Sin necesidad de ratón.
# Enseña:
# 1. Particionado GPT de unidades NVMe de servidor.
# 2. Creación de sistemas de archivos (mkfs.vfat y mkfs.ext4).
# 3. Montaje de volúmenes en /mnt.
# 4. Despliegue de paquetes base mediante pacstrap.
# 5. Generación de fstab mediante UUIDs.
# 6. Despliegue de bootloader systemd-boot y demonios en chroot.
# =============================================================================

@onready var modal_control: Control = $ModalControl
@onready var terminal_text: RichTextLabel = $ModalControl/Panel/VBox/TermPanel/Margin/VBox/TermScroll/TerminalText
@onready var prompt_label: Label = $ModalControl/Panel/VBox/TermPanel/Margin/VBox/PromptHBox/PromptLabel
@onready var input_label: Label = $ModalControl/Panel/VBox/TermPanel/Margin/VBox/PromptHBox/InputLabel
@onready var cursor_rect: ColorRect = $ModalControl/Panel/VBox/TermPanel/Margin/VBox/PromptHBox/CursorRect

@onready var step_title_lbl: Label = $ModalControl/Panel/VBox/GuidePanel/Margin/VBox/StepTitle
@onready var step_desc_lbl: Label = $ModalControl/Panel/VBox/GuidePanel/Margin/VBox/StepDesc
@onready var target_cmd_lbl: Label = $ModalControl/Panel/VBox/GuidePanel/Margin/VBox/TargetCmd
@onready var progress_bar: ProgressBar = $ModalControl/Panel/VBox/Header/Metrics/ProgressBar
@onready var step_counter_lbl: Label = $ModalControl/Panel/VBox/Header/Metrics/StepCounter
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel

var current_step: int = 0
var current_input: String = ""
var is_busy_executing: bool = false
var cursor_timer: float = 0.0

const STEPS = [
	{
		"title": "PASO 1 / 8: TABLA DE PARTICIONES GPT",
		"desc": "Crea la tabla GPT en el arreglo NVMe de alta velocidad (/dev/nvme0n1) con sectores EFI y Root.",
		"cmd": "fdisk /dev/nvme0n1",
		"output": "Dispositivo /dev/nvme0n1: 11.52 TB (3x 3.84TB RAID 0)\nCreando tabla GPT nueva...\n  /dev/nvme0n1p1 : 512M [EFI System Partition]\n  /dev/nvme0n1p2 : 11.51 TB [Linux Root Filesystem x86_64]\n¡Tabla de particiones escrita en sectores NVMe con éxito!"
	},
	{
		"title": "PASO 2 / 8: FORMATEO DE PARTICIÓN EFI",
		"desc": "Formatea la partición de arranque /dev/nvme0n1p1 en FAT32 requerido por la especificación UEFI.",
		"cmd": "mkfs.vfat -F32 /dev/nvme0n1p1",
		"output": "mkfs.fat 4.2 (2026-01-20)\nCreando sistema de archivos FAT32 en /dev/nvme0n1p1...\nSectores de 512 bytes, cluster de 4096 bytes. UUID: A4B1-99F2.\n✓ Partición EFI lista para el gestor de arranque."
	},
	{
		"title": "PASO 3 / 8: FORMATEO DEL SISTEMA RAIZ (EXT4)",
		"desc": "Formatea el volumen principal /dev/nvme0n1p2 con el sistema de archivos ext4 y journaling de servidor.",
		"cmd": "mkfs.ext4 -F -L andromeda_root /dev/nvme0n1p2",
		"output": "mke2fs 1.47.0 (2026-02-05)\nDescartando bloques del dispositivo... Hecho.\nCreando sistema de ficheros con 3019898880 bloques de 4k y 188743680 nodos-i.\nUUID del sistema de ficheros: 8f21cb44-771a-4d22-b010-andromeda01.\nAsignando tablas de grupo... Hecho. Escribiendo tablas de nodos-i... Hecho.\nCreando el registro de transacciones (journal)... Hecho.\n✓ Sistema de archivos ext4 montable creado con éxito."
	},
	{
		"title": "PASO 4 / 8: MONTAJE DE VOLÚMENES EN /mnt",
		"desc": "Monta la partición raíz en /mnt y el directorio /mnt/boot para comenzar el despliegue del software.",
		"cmd": "mount /dev/nvme0n1p2 /mnt && mkdir -p /mnt/boot && mount /dev/nvme0n1p1 /mnt/boot",
		"output": "Montando /dev/nvme0n1p2 en /mnt (rw,relatime,data=ordered)...\nCreando árbol /mnt/boot...\nMontando partición EFI en /mnt/boot (vfat,rw,fmask=0077,dmask=0077)...\n✓ Árbol de directorios de servidor montado y listo."
	},
	{
		"title": "PASO 5 / 8: DESPLIEGUE PACSTRAP (ANDROMEDA BASE)",
		"desc": "Instala el kernel corporativo de Andromeda Linux, firmware de red y paquetes base en /mnt.",
		"cmd": "pacstrap /mnt base andromeda-enterprise linux-firmware systemd",
		"output": ":: Sincronizando repositorios de Andromeda Enterprise...\n   core [####################################] 100%   142.5 KiB   2.8 MiB/s\n   extra [####################################] 100%     8.9 MiB  42.1 MiB/s\n:: Instalando paquetes en /mnt (48 paquetes seleccionados)...\n(48/48) instalando andromeda-kernel-6.13-enterprise ... [################] 100%\n(48/48) instalando systemd-init ... [################] 100%\n(48/48) instalando linux-firmware-enterprise ... [################] 100%\n✓ Despliegue de paquetes base completado sin errores."
	},
	{
		"title": "PASO 6 / 8: GENERACIÓN DE FSTAB (UUIDs)",
		"desc": "Genera el archivo fstab persistente para el montaje automático de discos durante el booteo.",
		"cmd": "genfstab -U /mnt >> /mnt/etc/fstab",
		"output": "# /etc/fstab: static file system information.\n# <file system>             <mount point>  <type>  <options>  <dump> <pass>\nUUID=8f21cb44...            /              ext4    rw,relatime 0      1\nUUID=A4B1-99F2              /boot          vfat    rw,relatime 0      2\n✓ Archivo /mnt/etc/fstab generado correctamente."
	},
	{
		"title": "PASO 7 / 8: CHROOT & BOOTLOADER SYSTEMD-BOOT",
		"desc": "Ingresa al nuevo entorno del servidor e instala el gestor de arranque systemd-boot en el sector UEFI.",
		"cmd": "arch-chroot /mnt bootctl install",
		"output": "Ingresando a chroot en /mnt...\nCreated \"/boot/EFI/systemd\".\nCreated \"/boot/EFI/BOOT\".\nCreated \"/boot/loader/entries\".\nCopied \"/usr/lib/systemd/boot/efi/systemd-bootx64.efi\" to \"/boot/EFI/systemd/systemd-bootx64.efi\".\nCreated EFI boot entry \"Andromeda Linux Enterprise Bootloader\".\n✓ Gestor de arranque instalado y verificado."
	},
	{
		"title": "PASO 8 / 8: ACTIVACIÓN DE DEMONIOS & REINICIO",
		"desc": "Habilita los servicios de red, cluster-sync y reinicia la torre para arrancar en Andromeda Linux.",
		"cmd": "systemctl enable network-manager cluster-sync && reboot",
		"output": "Created symlink /etc/systemd/system/multi-user.target.wants/NetworkManager.service.\nCreated symlink /etc/systemd/system/multi-user.target.wants/cluster-sync.service.\nSincronizando buffers de disco...\nReiniciando servidor...\n[  OK  ] Started Andromeda Enterprise Datacenter Node.\n[  OK  ] Reached target Multi-User System.\n[  OK  ] Cluster synchronization active on 100 GbE SmartNIC.\n\n========================================================================\n󰣇 ¡ANDROMEDA LINUX ENTERPRISE INSTALADO Y OPERATIVO EN EL SERVIDOR! ✓\n========================================================================"
	}
]

func _ready() -> void:
	layer = 12
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	_init_terminal_text()
	_load_step(0)

func _process(delta: float) -> void:
	cursor_timer += delta
	if cursor_timer >= 0.4:
		cursor_timer = 0.0
		if cursor_rect:
			cursor_rect.visible = not cursor_rect.visible

func _init_terminal_text() -> void:
	terminal_text.text = "[color=#00d2ff]󰣇 Andromeda Linux Enterprise Server ISO (Kernel 6.13.0-andromeda)[/color]\n"
	terminal_text.text += "[color=#5599bb]Terminal de instalación interactiva por teclado. Escribe el comando indicado o pulsa [TAB] / [ENTER].[/color]\n\n"

func _load_step(idx: int) -> void:
	current_step = idx
	current_input = ""
	is_busy_executing = false
	
	if current_step >= STEPS.size():
		_finish_installation_victory()
		return
		
	var data = STEPS[current_step]
	step_title_lbl.text = data["title"]
	step_desc_lbl.text = data["desc"]
	target_cmd_lbl.text = "$ " + data["cmd"]
	step_counter_lbl.text = "PASO %d / %d" % [current_step + 1, STEPS.size()]
	progress_bar.value = float(current_step) / float(STEPS.size()) * 100.0
	
	input_label.text = ""
	prompt_label.text = "root@andromeda-iso ~ # " if current_step < 6 else "[root@andromeda-server /]# "

func _unhandled_input(event: InputEvent) -> void:
	if is_busy_executing or current_step >= STEPS.size():
		return
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			minigame_finished.emit(false)
			return
			
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			get_viewport().set_input_as_handled()
			_execute_current_or_autocomplete()
			return
			
		if event.keycode == KEY_TAB:
			get_viewport().set_input_as_handled()
			_autocomplete_target_cmd()
			return
			
		if event.keycode == KEY_BACKSPACE:
			get_viewport().set_input_as_handled()
			if current_input.length() > 0:
				current_input = current_input.substr(0, current_input.length() - 1)
				input_label.text = current_input
			return
			
		# Si presiona una tecla válida, avanzar la escritura del comando de forma fluida
		if event.unicode > 31 and event.unicode < 127:
			get_viewport().set_input_as_handled()
			_handle_character_input(char(event.unicode))

func _handle_character_input(c: String) -> void:
	if current_step >= STEPS.size():
		return
	var target = STEPS[current_step]["cmd"]
	# Si coincide con la siguiente letra esperada, o si escribe directamente, ir completando
	if current_input.length() < target.length():
		var next_expected_char = target[current_input.length()]
		# Autocorregir amigablemente para que coincida exactamente con el comando de Linux
		current_input += next_expected_char
		input_label.text = current_input
	else:
		# Ya está completo el comando, si presiona cualquier tecla lo ejecuta
		_execute_current_or_autocomplete()

func _autocomplete_target_cmd() -> void:
	if current_step >= STEPS.size():
		return
	var target = STEPS[current_step]["cmd"]
	current_input = target
	input_label.text = current_input

func _execute_current_or_autocomplete() -> void:
	if current_step >= STEPS.size():
		return
	var target = STEPS[current_step]["cmd"]
	if current_input != target:
		# Si aún no lo completó todo, [Enter] lo autocompleta primero
		_autocomplete_target_cmd()
		return
		
	# Ejecutar el comando actual
	is_busy_executing = true
	var p = prompt_label.text
	terminal_text.text += "[color=#00e5ff]%s[/color][color=#ffffff]%s[/color]\n" % [p, target]
	
	# Simular salida del comando
	var output = STEPS[current_step]["output"]
	terminal_text.text += "[color=#a0d8ef]%s[/color]\n\n" % output
	
	# Scroll automático abajo
	await get_tree().process_frame
	var v_scroll = terminal_text.get_v_scroll_bar()
	if v_scroll:
		v_scroll.value = v_scroll.max_value
		
	await get_tree().create_timer(0.4).timeout
	_load_step(current_step + 1)

func _finish_installation_victory() -> void:
	progress_bar.value = 100.0
	step_title_lbl.text = "¡INSTALACIÓN COMPLETADA CON ÉXITO!"
	step_desc_lbl.text = "El servidor ha booteado en Andromeda Linux Enterprise. El clúster está 100% operativo."
	target_cmd_lbl.text = "✓ HOST ONLINE - SERVIDOR ACTIVADO"
	target_cmd_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("add_score"):
		gm.add_score(300, 20.0)
		
	await get_tree().create_timer(2.2).timeout
	minigame_finished.emit(true)
