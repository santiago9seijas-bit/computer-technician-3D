# 🛠️ Computer Technician 3D (Version 0.0.3 Alpha)

[![Godot Engine](https://img.shields.io/badge/Godot-4.x-blue.svg?logo=godotengine)](https://godotengine.org)
[![Platform](https://img.shields.io/badge/Platforms-Linux%20%7C%20Windows-green.svg)](#descargas--instalaci%C3%B3n)
[![Release](https://img.shields.io/badge/Release-Version%200.0.3%20Alpha-magenta.svg)](https://github.com/santiago9seijas-bit/computer-technician-3D/releases)
[![Versiones](https://img.shields.io/badge/Carpeta-Versiones-orange.svg)](versiones/README.md)

**Computer Technician 3D** es un simulador inmersivo en primera persona desarrollado en Godot 4 con estética cyberpunk/sci-fi. Asume el papel de un técnico informático del futuro en un taller especializado, diagnostica componentes dañados, realiza pruebas de hardware e interactúa con minijuegos dinámicos para reparar PCs y módulos cibernéticos.

📁 Para consultar el repositorio dedicado de versiones organizadas por sistema operativo, visita la carpeta [**versiones/**](versiones/README.md) ([🪟 Windows](versiones/windows/README.md) | [🐧 Linux](versiones/linux/README.md)).

---

## 🎮 Características Principales

- **Exploración 3D del Taller:** Desplázate con fluidez por tu taller técnico interactuando con mesas de trabajo, estanterías, herramientas y torres de computadoras.
- **Inspección de Hardware en Detalle:** Abre e inspecciona componentes internos de PC (memorias RAM, discos de almacenamiento HDD/SSD, sistemas de refrigeración y ventiladores).
- **Minijuegos de Diagnóstico y Desmontaje Realista:**
  - 🧠 **RAM (Memoria DDR):** Apertura de trabas laterales de seguridad, extracción vertical e inserción alineando la muesca polarizada.
  - 💾 **HDD (Disco Duro SATA):** Desatornillado de bahía con Cruz/Pala, extracción por riel y anclaje de unidad funcional.
  - ❄️ **Fan Cooler (Disipador PWM):** Desconexión del cable de 4 pines, desatornillado simétrico y elevación del disipador de calor.
  - 🎮 **GPU (Tarjeta Gráfica PCIe):** Desconexión de clip de poder 8-pines, tornillos de chasis, apertura de pestillo plástico del zócalo PCIe x16 y extracción vertical sin dañar el bus.
  - ⚙️ **CPU (Microprocesador):** Disolución y limpieza de pasta térmica seca con paño de alcohol isopropílico, desenganche de palanca de tensión a 90°, apertura de placa de carga y extracción sujetando por las esquinas.
  - ⚡ **SSD M.2 (NVMe PCIe):** Retiro de armadura térmica M.2 Armor, desatornillado de standoff, elevación a 30° por tensión de resorte y deslizamiento en diagonal sin quebrar pistas.
  - 🔌 **PSU (Fuente de Poder ATX):** Desconexión de arnés principal ATX de 24 pines y CPU EPS de 8 pines con seguro plástico, retiro de 4 tornillos de chasis y deslizamiento por túnel inferior (PSU shroud).
  - 🖥️ **Placa Madre (Desmontaje Maestro Libre):** Retiro de piezas en cualquier orden (cables ATX/EPS, GPU, Cooler, SSD M.2 y RAM), desatornillado de los 6 tornillos standoff del chasis, desacople del I/O Shield y elevación limpia.
  - 🌊 **Refrigeración Líquida (Custom Loop Completo):** Mapeado interactivo de componentes calientes (GPU, CPU, RAM + Radiador 360mm y Bomba D5), montaje de tubos rígidos PETG arrastrando tubo a tubo desde el rack, llenado manual con bidón de refrigerante cian al 100% y encendido de la bomba con purgado de aire y caída térmica en tiempo real.
- **Interfaz Futurista con Shaders:** Menús holográficos interactivos (`cyber_panel_hologram`), transiciones cinemáticas fluidas, selección de niveles y módulos de tutorial interactivos.
- **Configuración y Accesibilidad:** Panel de configuración personalizable, controles compactos y claros en pantalla.

---

## 🕹️ Guía de Controles

| Acción | Tecla / Control | Descripción |
| :--- | :--- | :--- |
| **Moverse** | `W`, `A`, `S`, `D` | Movimiento en 8 direcciones |
| **Mirar / Cámara** | Ratón | Rotación de cámara en 3D |
| **Interactuar** | `E` | Inspeccionar componentes y acceder a terminales |
| **Correr / Sprint** | `Shift Izq` | Acelerar velocidad de desplazamiento |
| **Herramientas Rápidas**| `1`, `2`, `3`, `4`, `5` | Seleccionar herramientas de diagnóstico |
| **Pausa / Volver** | `ESC` | Abrir menú de pausa o cerrar paneles |

---

## 📦 Descargas e Instalación

Puedes descargar los binarios compilados directamente desde la pestaña de **[Releases](https://github.com/santiago9seijas-bit/computer-technician-3D/releases)**.

### 🐧 Linux (x86_64)

1. Descarga el archivo `ComputerTechnician3D-Linux-v0.0.0-alpha.zip`.
2. Descomprime el archivo en la carpeta que desees:
   ```bash
   unzip ComputerTechnician3D-Linux-v0.0.0-alpha.zip -d ComputerTechnician3D-Linux
   cd ComputerTechnician3D-Linux
   ```
3. Otorga permisos de ejecución al ejecutable:
   ```bash
   chmod +x ComputerTechnician3D.x86_64
   ```
4. Ejecuta el juego:
   ```bash
   ./ComputerTechnician3D.x86_64
   ```

*Requisitos Linux:* Distribución moderna (Ubuntu 20.04+, Fedora, Arch, etc.) con controladores compatibles con Vulkan o OpenGL.

---

### 🪟 Windows (x86_64)

1. Descarga el archivo `ComputerTechnician3D-Windows-v0.0.0-alpha.zip`.
2. Haz clic derecho y selecciona **Extraer todo...**.
3. Abre la carpeta resultante y ejecuta `ComputerTechnician3D.exe`.
*(Nota: Asegúrate de mantener el archivo `.pck` en la misma carpeta que el ejecutable).*

*Requisitos Windows:* Windows 10/11 (64-bit) con soporte para DirectX 12 / Vulkan.

---

## 🛠️ Ejecución desde el Código Fuente (Desarrollo)

Si deseas clonar y ejecutar o editar el juego directamente en el motor:

1. **Clona el repositorio:**
   ```bash
   git clone https://github.com/santiago9seijas-bit/computer-technician-3D.git
   cd computer-technician-3D
   ```
2. **Abrir en Godot:**
   - Abre **Godot Engine 4.x** (probado y optimizado en 4.7.2).
   - Haz clic en **Importar** y selecciona el archivo `project.godot`.
   - Presiona `F5` para compilar y ejecutar el proyecto.

---

## 📂 Estructura del Proyecto

```text
├── assets/            # Modelos 3D, texturas, tipografías cyberpunk y fuentes
├── pixel art/         # Sprites y fondos retro / holográficos
├── scenes/
│   ├── menus/         # MainMenu, LevelSelect, TutorialHub, PauseMenu
│   ├── minigames/     # RAMMinigame, HDDMinigame, FanCoolerMinigame
│   ├── ui/            # HUD, PCInspectionModal, marcos holográficos
│   └── world/         # Taller 3D, iluminación y nodos de entorno
├── scripts/           # Lógica en GDScript (menus, jugadores, minijuegos)
├── styles/            # Shaders GLSL (.gdshader) y recursos Theme (.tres)
├── export_presets.cfg # Presets de exportación para Linux y Windows
└── project.godot      # Configuración general del motor Godot
```

---

## 👤 Autor

Desarrollado por **Santiago Seijas** ([@santiago9seijas-bit](https://github.com/santiago9seijas-bit)).  
Distribuido bajo licencia MIT / Open Source.
