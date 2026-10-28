
### 📊 Rúbrica de Evaluación Actualizada (Escala de $1$ a $4$ puntos)

| Criterio | Puntuación | Diagnóstico Breve |
| :--- | :---: | :--- |
| **1. Identidad Visual y Dirección de Arte** | $4 / 4$ | Paleta, microinteracciones de UI, shaders de holograma/glitch y perspectiva 3D en primera persona. |
| **2. Claridad del Bucle Principal (Hardware y Software)** | $4 / 4$ | Herramientas ($1$ al $5$) en Reparación, botón dispensador de repuestos y Tecla $1$ (Pendrive + conexión manual) en Sistemas. |
| **3. Consistencia de Sistemas y Reglas (HUD y Tiempo)** | $4 / 4$ | Resuelto: Sistema de Cuenta Regresiva ($T \to 0$), penalizaciones escalonadas de estrellas y límite estricto de errores ($20$). |
| **4. Simetría y Profundidad en Modo Servidor** | $4 / 4$ | Resuelto: Navegación 3D en primera persona entre las $3$ plantas mediante desplazamiento físico y tendido de cable continuo. |

---

### 🔍 Estado de Puntos de Control de Calidad

* ✅ **1. Resuelto — Lógica de Cuenta Regresiva y Errores (Sección 5 - HUD):** Cuenta regresiva hacia $0$. Acertar suma $+t$ y puntos a la derecha del cursor; fallar drena $-t$ con números rojos a la izquierda del cursor. Se fijaron los umbrales de errores: $>5$ resta $1$ estrella, $>12$ resta $2$ estrellas, y a los $20$ errores se produce **Game Over automático**.
* ✅ **2. Resuelto — Controles de Sistemas y Minijuego USB (Sección 4.B):** Tecla $1$ equipa el Pendrive Virtual. Minijuego 3D de precisión para alinear y conectar físicamente el pendrive al puerto de la PC antes de pasar al software.
* ✅ **3. Resuelto — Perspectiva y Navegación en Modo Servidor (Secciones 1 y 4.C):** Juego planteado en **3D en primera persona**. En el complejo de 3 plantas el jugador se mueve físicamente (escaleras/accesos) mientras tiende el cable de red a través de ductos y bandejas, sin saltos abruptos de UI.
* ✅ **4. Resuelto — Rotura de Piezas y Botón de Repuestos (Sección 4.A):** Equivocarse reiteradamente daña físicamente el componente. Los repuestos se solicitan pulsando un botón en la pared del taller que reabastece el stock sin costo de puntos (penaliza tiempo de traslado).

---
---

# 🖥️ Documento de Diseño del Juego (GDD) — Versión de Producción

## 1. Visión General y Estética Visual

* **Perspectiva y Cámara:** **3D en primera persona** (*First-Person 3D*). El jugador se mueve físicamente por el entorno (taller, oficina, edificio de servidores) e interactúa directamente con mesas de trabajo, herramientas y racks.
* **Identidad Visual:** Estética *cyberpunk* con interfaz de sistema operativo futurista de alto contraste.
* **Paleta de Colores Dominante:**
  * **Primarios de Alerta / Acción:** Rojos intensos (`#FF003C`) y naranjas neón (`#FF6B00`).
  * **Fondos y Profundidad:** Morados profundos (`#1A0526` a `#2D0A4E`).
  * **Estado de Interacción (Hover):** Blanco puro (`#FFFFFF`) para máximo contraste.
* **Efectos Visuales (VFX y Shaders de UI):**
  * **Fondo Dinámico:** Movimiento sutil a base de "micromovimientos" orgánicos que dan vida a la pantalla sin generar fatiga visual ni mareo.
  * **Transiciones y Menús:** Animaciones tipo holograma y efectos de *glitch* al entrar o salir de los niveles y al activar la pausa.
  * **Menú de Pausa:** Desenfoca la cámara del nivel (*Gaussian Blur*), superpone una cuadrícula roja translúcida y despliega las opciones secuencialmente de izquierda a derecha.

---

## 2. Arquitectura del Menú Principal

* **Disposición Espacial (Layout):** Botones ubicados en el margen izquierdo, ordenados en **forma de escalera descendente** (uno debajo del otro, donde cada botón inferior es visualmente más pequeño que el inmediatamente superior).
* **Reglas de Interacción (UI/UX):**
  * **Estado Base (Idle):** Animación sutil continua en el marco de cada botón.
  * **Al pasar el cursor (Hover):** El botón cambia instantáneamente a color blanco.
  * **Al hacer clic (OnClick):** Se ejecuta una animación de holograma que reorganiza la pantalla como la interfaz de un sistema operativo y transporta al jugador al submenú correspondiente.
  * **Navegación:** Opciones de desplazamiento vertical (Arriba / Debajo) mediante cursor o teclado.
* **Jerarquía de Botones del Menú Principal:**
  1. **Play (Jugar):** Acceso al Selector de Niveles (Modo Constelaciones).
  2. **Tutoriales:** Acceso directo a la pestaña de entrenamiento práctico.
  3. **Configuración:** Ajustes de audio, video y efectos de pantalla.
  4. **Controles:** Mapa de asignación de teclas y ratón.
  5. **Salir:** Cierre del sistema operativo / juego.

---

## 3. Selector de Niveles: Modo Constelaciones

* **Estructura Visual:** Mapa estelar de constelaciones compuesto por nodos (puntos rojos distribuidos en el espacio). Al superar un nivel con éxito, se ilumina una **línea láser** que lo conecta con el siguiente nodo disponible.
* **Progresión Lineal por Fases:** El jugador debe completar las ramas en orden estricto de complejidad tecnológica:
  $$\text{Fase 1: Reparación (Hardware)} \longrightarrow \text{Fase 2: Sistemas (Software)} \longrightarrow \text{Fase 3: Servidor (Redes)}$$
* **Niveles de Dificultad:** Cada modo cuenta con nodos divididos en tres rangos: **Fácil**, **Medium** y **Difícil**.
* **Flujo de Selección:**
  * **Al hacer clic en un nodo:** La cámara realiza un *zoom-in* fluido hacia el círculo de la constelación y despliega una **micro-descripción** con las mecánicas específicas que se utilizarán en ese encargo.
  * **Requisitos de Desbloqueo:** Sistema de bloqueo por progreso que exige acumular **puntos y estrellas** obtenidos mediante buen desempeño en niveles previos.

---

## 4. Modos de Juego y Mecánicas Principales

### A. Modo Reparación (Hardware)
* **Fase de Preparación:** El jugador arrastra las PCs o componentes desde su ubicación hasta la mesa de trabajo principal.
* **Barra de Herramientas Rápidas (Teclas $1$ al $5$):**

| Tecla | Herramienta | Función Mecánica |
| :---: | :--- | :--- |
| **$1$** | **Destornillador de estrella** | Desmontaje y fijación de tornillería estándar de chasis y placas. |
| **$2$** | **Destornillador de pala** | Extracción de anclajes planos y seguros específicos. |
| **$3$** | **Cautín** | Microsoldadura y conexión de circuitos nuevos. |
| **$4$** | **Medidor de voltaje** | Diagnóstico eléctrico apoyado en una tabla de referencia de voltajes buenos y malos. |
| **$5$** | **Limpiador de pelusa** | Eliminación de obstrucciones físicas y polvo acumulado. |

* **Gestión de Piezas, Roturas e Inventario (La Mochila):**
  * **Extracción por Gestos:** Al quitar una pieza (como la memoria RAM), se realiza un minijuego de deslizamiento (*swipe*) o tracción física.
  * **Daño por Fallos:** Si el jugador se equivoca reiteradamente al manipular una pieza o herramienta, **el componente se daña o rompe físicamente**, quedando inservible.
  * **Capacidad de la Mochila:** Almacena un máximo estricto de **$3$ piezas en total** (buenas o malas).
  * **Inventario Flotante Contextual:** Si la mochila está vacía ($0$ ítems), no se muestra en pantalla; si tiene objetos ($1$ a $3$), aparece un cuadro a la derecha con una animación de salida.
  * **Ciclo de Reciclaje y Repuestos:**
    * Las piezas rotas se desechan en **cajas de reciclaje**.
    * **Dispensador de Pared:** Para reabastecer repuestos nuevos, el jugador debe caminar e interactuar con un **botón físico en la pared**. No gasta puntos de juego, pero exige tiempo de desplazamiento del jugador para reponer el stock disponible en la mesa.
* **Minijuegos Especializados de Hardware:**
  * Limpieza de pelusa y polvo.
  * Mover discos duros y reemplazarlos.
  * **Refrigeración líquida:** Instalación y mantenimiento de circuitos de líquido refrigerante.
  * **Uso del microscopio:** Para reparaciones microscópicas de circuitos y soldadura de precisión.

---

### B. Modo Sistemas (Software)
* **Herramienta Única de Acceso (Tecla $1$):**
  * En este modo no hay herramientas de la $2$ a la $5$; únicamente está habilitada la **Tecla $1$: Pendrive Virtual**.
  * **Fase de Conexión Física (USB en 3D):** Al presionar la tecla $1$, el jugador equipa el pendrive en primera persona y debe **alinearlo y acercarlo con precisión al puerto USB de la PC** para insertarlo correctamente. Fallar la alineación suma errores y resta tiempo.
* **Mecánicas Internas de Software (tras conectar el Pendrive):**
  * **Instalación de SO:** Instalación de nuevos sistemas operativos desde el pendrive conectado.
  * **Desinfección:** Borrado de virus y cierre de anuncios invasivos.
  * **Código y Rendimiento:** Minijuegos de programación lógica y optimización del sistema.

---

### C. Modo Servidor (Redes y Complejos)
* **Escenario:** Un mundo unificado con **$3$ plantas** en 3D que contiene servidores masivos y múltiples PCs conectadas.
* **Navegación Vertical:** El jugador se desplaza en primera persona entre pisos utilizando escaleras de servicio o montacargas del edificio.
* **Mecánicas Principales:**
  * **Activación Central:** Activar el servidor central del complejo.
  * **Cableado Físico de Red:** Tender y conectar cables de red físicos en tiempo real, transportando el rollo/cable y guiándolo por bandejas portacables y ductos entre las plantas hasta comprobar la conectividad en todas las terminales.
  * **Enfriamiento Industrial:** Sistemas de refrigeración líquida a escala de servidor.

---

## 5. HUD y Sistema de Puntuación (Estilo *Black Ops 2*)

* **Distribución en Pantalla:**
  * **Contador de Errores:** Ubicado arriba a la izquierda.
  * **Contador de Tiempo (Cuenta Regresiva):** Ubicado arriba al centro.
  * **Contador de Puntos:** Ubicado abajo a la izquierda.
* **Dinámica de la Cuenta Regresiva y Feedback en el Cursor:**
  * **Si lo haces bien (Acierto):** Se te **suma tiempo a favor** ($+t\text{ seg}$) en la cuenta regresiva y **suman puntos** ($+\text{Pts}$), mostrando una animación de suma de números flotando cerca del cursor (**a la derecha**).
  * **Si te equivocas (Acción Incorrecta):** Se te **resta tiempo en contra** ($-t\text{ seg}$ acercándote a cero), aumenta el Contador de Errores y aparece una resta de números rojos flotando cerca del cursor (**a la izquierda**).
* **Escala de Errores y Penalización de Estrellas:**
  * **$0$ a $5$ errores:** Desempeño óptimo (mantiene las $3$ estrellas, según puntuación/tiempo).
  * **Más de $5$ errores ($6$ a $12$):** Penalización de **$-1$ estrella** (máximo $2$ estrellas alcanzables).
  * **Más de $12$ errores ($13$ a $19$):** Penalización de **$-2$ estrellas** (máximo $1$ estrella alcanzable).
  * **$20$ errores acumulados:** **Derrota automática instantánea (Game Over)** por daño crítico del equipo.
* **Condiciones de Derrota:**
  1. Si el temporizador de cuenta regresiva llega a cero ($T = 0$).
  2. Si el Contador de Errores alcanza los **$20$ errores**.

---

## 6. Sistema de Tutoriales

* **Ubicación:** Pestaña independiente dentro del selector de niveles.
* **Interacción Previa:** Al pasar el mouse (*hover*) sobre un tutorial, se despliega una descripción detallada al lado.
* **Formato Práctico:** Cada tutorial sitúa al jugador frente a una **PC de prueba** donde debe cumplir objetivos específicos (desde cómo quitar una pieza correctamente hasta cómo medir corriente con el multímetro o conectar el pendrive con la tecla $1$). Al completarlo, salta la animación de victoria.
