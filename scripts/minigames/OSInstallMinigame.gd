extends CanvasLayer

# =============================================================================
# MINIJUEGO: INSTALACIÓN DE SISTEMAS OPERATIVOS Y PARTICIONADO
# Enseña:
# 1. Elegir entre esquemas de partición MBR (Legacy) y GPT (UEFI Moderno).
# 2. Asignar particiones esenciales: EFI System Partition (ESP), Raíz del SO y Swap.
# 3. Formatear sistemas de archivos (FAT32, EXT4) y asignar puntos de montaje.
# 4. Desplegar el kernel, controladores base y gestor de arranque GRUB.
# =============================================================================

signal minigame_finished(success: bool)

# Nodos Principales
@onready var modal_control: Control = $ModalControl
@onready var status_label: Label = $ModalControl/Panel/VBox/Header/StatusLabel
@onready var step_label: Label = $ModalControl/Panel/VBox/Header/StepLabel
@onready var btn_cancel: Button = $ModalControl/Panel/VBox/Footer/BtnCancel

# Contenedor de Pasos
@onready var step1_container: Control = $ModalControl/Panel/VBox/WorkArea/Step1_PartitionTable
@onready var btn_mbr: Button = $ModalControl/Panel/VBox/WorkArea/Step1_PartitionTable/HBox/BtnMBR
@onready var btn_gpt: Button = $ModalControl/Panel/VBox/WorkArea/Step1_PartitionTable/HBox/BtnGPT

@onready var step2_container: Control = $ModalControl/Panel/VBox/WorkArea/Step2_Partitions
@onready var disk_visual_bar: HBoxContainer = $ModalControl/Panel/VBox/WorkArea/Step2_Partitions/DiskBarContainer/DiskVisualBar
@onready var btn_add_efi: Button = $ModalControl/Panel/VBox/WorkArea/Step2_Partitions/ButtonsHBox/BtnAddEFI
@onready var btn_add_root: Button = $ModalControl/Panel/VBox/WorkArea/Step2_Partitions/ButtonsHBox/BtnAddRoot
@onready var btn_add_swap: Button = $ModalControl/Panel/VBox/WorkArea/Step2_Partitions/ButtonsHBox/BtnAddSwap
@onready var btn_next_to_install: Button = $ModalControl/Panel/VBox/WorkArea/Step2_Partitions/BtnNextToInstall

@onready var step3_container: Control = $ModalControl/Panel/VBox/WorkArea/Step3_Deployment
@onready var install_progress: ProgressBar = $ModalControl/Panel/VBox/WorkArea/Step3_Deployment/ProgressBar
@onready var log_console: Label = $ModalControl/Panel/VBox/WorkArea/Step3_Deployment/LogConsole
@onready var btn_start_install: Button = $ModalControl/Panel/VBox/WorkArea/Step3_Deployment/BtnStartInstall
@onready var victory_banner: PanelContainer = $ModalControl/Panel/VBox/WorkArea/Step3_Deployment/VictoryBanner

@onready var toast_label: Label = $ModalControl/Panel/VBox/ToastLabel

# Estado
enum InstallStep {
	SELECT_TABLE,
	CREATE_PARTITIONS,
	DEPLOY_OS,
	COMPLETED
}

var current_step: InstallStep = InstallStep.SELECT_TABLE
var has_efi: bool = false
var has_root: bool = false
var has_swap: bool = false
var is_installing: bool = false

func _ready() -> void:
	layer = 12
	btn_cancel.pressed.connect(func(): minigame_finished.emit(false))
	toast_label.visible = false
	
	# Conexiones Paso 1
	btn_mbr.pressed.connect(_on_mbr_pressed)
	btn_gpt.pressed.connect(_on_gpt_pressed)
	
	# Conexiones Paso 2
	btn_add_efi.pressed.connect(_on_add_efi_pressed)
	btn_add_root.pressed.connect(_on_add_root_pressed)
	btn_add_swap.pressed.connect(_on_add_swap_pressed)
	btn_next_to_install.pressed.connect(_on_next_to_install_pressed)
	btn_next_to_install.disabled = true
	
	# Conexiones Paso 3
	btn_start_install.pressed.connect(_on_start_install_pressed)
	victory_banner.visible = false
	
	_show_step(InstallStep.SELECT_TABLE)

func _show_step(step: InstallStep) -> void:
	current_step = step
	step1_container.visible = (step == InstallStep.SELECT_TABLE)
	step2_container.visible = (step == InstallStep.CREATE_PARTITIONS)
	step3_container.visible = (step == InstallStep.DEPLOY_OS or step == InstallStep.COMPLETED)
	
	match step:
		InstallStep.SELECT_TABLE:
			step_label.text = "PASO 1 / 3: TABLA DE PARTICIONES"
			status_label.text = "Selecciona el esquema de partición para la unidad NVMe SSD de 512 GB."
		InstallStep.CREATE_PARTITIONS:
			step_label.text = "PASO 2 / 3: ASIGNACIÓN DE VOLÚMENES LÓGICOS"
			status_label.text = "Crea la partición EFI (/boot/efi), la partición Raíz (/) y el área Swap."
		InstallStep.DEPLOY_OS:
			step_label.text = "PASO 3 / 3: DESPLIEGUE DEL KERNEL & PAQUETES"
			status_label.text = "Presiona 'INICIAR DESPLIEGUE DE CYBER-OS' para compilar e instalar los binarios."
		InstallStep.COMPLETED:
			step_label.text = "INSTALACIÓN COMPLETADA EXITOSAMENTE"
			status_label.text = "El sistema operativo está listo para su primer arranque UEFI."

func _on_mbr_pressed() -> void:
	_show_toast("⚠️ MBR está limitado a 2TB y carece de soporte nativo UEFI. Se recomienda GPT.")
	var tw = create_tween()
	tw.tween_property(btn_mbr, "scale", Vector2(1.05, 1.05), 0.1)
	tw.tween_property(btn_mbr, "scale", Vector2(1.0, 1.0), 0.1)

func _on_gpt_pressed() -> void:
	_show_toast("✓ ¡Excelente! GPT (GUID Partition Table) es el estándar seguro para UEFI y NVMe.")
	await get_tree().create_timer(0.6).timeout
	_show_step(InstallStep.CREATE_PARTITIONS)

func _on_add_efi_pressed() -> void:
	if has_efi:
		return
	has_efi = true
	btn_add_efi.disabled = true
	_add_partition_block("EFI [FAT32] (512 MB)", Color(0.2, 0.7, 1.0), 0.12)
	_show_toast("✓ Creada partición /boot/efi requerida por el gestor de arranque UEFI.")
	_check_step2_progress()

func _on_add_root_pressed() -> void:
	if has_root:
		return
	has_root = true
	btn_add_root.disabled = true
	_add_partition_block("RAÍZ / [EXT4] (480 GB)", Color(0.85, 0.15, 0.6), 0.70)
	_show_toast("✓ Creada partición principal del sistema montada en '/'.")
	_check_step2_progress()

func _on_add_swap_pressed() -> void:
	if has_swap:
		return
	has_swap = true
	btn_add_swap.disabled = true
	_add_partition_block("SWAP (16 GB)", Color(1.0, 0.75, 0.2), 0.18)
	_show_toast("✓ Creado espacio de memoria virtual Swap para hibernación y respaldo.")
	_check_step2_progress()

func _add_partition_block(title: String, col: Color, stretch_ratio: float) -> void:
	var p = PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_stretch_ratio = stretch_ratio
	
	var style = StyleBoxFlat.new()
	style.bg_color = col * Color(1, 1, 1, 0.85)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 1, 1, 0.8)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	p.add_theme_stylebox_override("panel", style)
	
	var lbl = Label.new()
	lbl.text = title
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	p.add_child(lbl)
	
	disk_visual_bar.add_child(p)
	
	# Animación de aparición del bloque en el disco
	p.scale = Vector2(0.8, 0.8)
	var tw = create_tween()
	tw.tween_property(p, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _check_step2_progress() -> void:
	if has_efi and has_root and has_swap:
		btn_next_to_install.disabled = false
		btn_next_to_install.text = "CONTINUAR A INSTALACIÓN ➔"
		btn_next_to_install.modulate = Color(0.2, 1.0, 0.5)
		_show_toast("✓ Tabla de particiones completa y lista para formateo.")

func _on_next_to_install_pressed() -> void:
	_show_step(InstallStep.DEPLOY_OS)

func _on_start_install_pressed() -> void:
	if is_installing:
		return
	is_installing = true
	btn_start_install.disabled = true
	
	var logs = [
		"▶ Formateando /dev/nvme0n1p1 como FAT32 para UEFI ESP...",
		"▶ Creando sistema de archivos EXT4 con journaling en /dev/nvme0n1p2...",
		"▶ Inicializando área de memoria virtual swap en /dev/nvme0n1p3...",
		"▶ Desempaquetando imagen base del Kernel Linux 6.8 LTS...",
		"▶ Generando configuración de módulos initramfs...",
		"▶ Instalando mesa-drivers, soporte Vulkan y aceleración gráfica...",
		"▶ Desplegando gestor de arranque GRUB 2.12 en partición EFI...",
		"▶ Verificando sumas de verificación SHA-256 de binarios críticos...",
		"✓ INSTALACIÓN COMPLETADA: 0 errores detectados."
	]
	
	install_progress.value = 0.0
	for i in range(logs.size()):
		log_console.text += logs[i] + "\n"
		var target_val = float(i + 1) / float(logs.size()) * 100.0
		var tw = create_tween()
		tw.tween_property(install_progress, "value", target_val, 0.3)
		await tw.finished
		await get_tree().create_timer(0.2).timeout
		
	_on_install_completed()

func _on_install_completed() -> void:
	_show_step(InstallStep.COMPLETED)
	victory_banner.visible = true
	victory_banner.scale = Vector2(0.6, 0.6)
	victory_banner.modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(victory_banner, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(victory_banner, "modulate:a", 1.0, 0.25)
	
	await get_tree().create_timer(2.4).timeout
	minigame_finished.emit(true)

func _show_toast(msg: String) -> void:
	toast_label.text = msg
	toast_label.visible = true
	toast_label.modulate.a = 1.0
	var tw = create_tween()
	tw.tween_property(toast_label, "modulate:a", 0.0, 2.0).set_delay(1.0)
	tw.chain().tween_callback(func(): toast_label.visible = false)
