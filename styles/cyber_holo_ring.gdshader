shader_type canvas_item;

// Holographic Cyber Terminal & Orbital Mode Ring Shader
// Displays a technical Andromeda CLI Terminal Console in the center
// with blinking prompt cursor, hex data cascades, CRT scanlines and orbital ring
uniform vec4 primary_color : source_color = vec4(1.0, 0.2, 0.45, 1.0);
uniform vec4 secondary_color : source_color = vec4(0.0, 0.85, 1.0, 1.0);
uniform vec4 ring_glow_color : source_color = vec4(1.0, 0.15, 0.5, 0.65);
uniform float speed : hint_range(0.1, 10.0) = 1.6;
uniform float ring_angle = 0.0;
uniform float pulse_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float tilt : hint_range(0.1, 1.0) = 0.52;

void fragment() {
	vec2 uv = UV - vec2(0.5, 0.5);
	vec2 p = vec2(uv.x, uv.y / tilt);
	float dist = length(p);
	float base_angle = atan(p.y, p.x);
	float orbit_angle = base_angle + TIME * speed * 0.35 + ring_angle;

	// =========================================================================
	// 1. ANILLO ORBITAL EXTERIOR (DONDE ORBITAN LOS SPRITES DE CADA MODO)
	// =========================================================================
	float ring1 = smoothstep(0.016, 0.0, abs(dist - 0.42));
	float ring2 = smoothstep(0.010, 0.0, abs(dist - 0.37));
	float ring3 = smoothstep(0.008, 0.0, abs(dist - 0.31));
	float outer_border = smoothstep(0.012, 0.0, abs(dist - 0.47));

	// Marcas técnicas y graduaciones radiales del bus de datos
	float ticks = step(0.60, sin(orbit_angle * 28.0)) * smoothstep(0.022, 0.0, abs(dist - 0.445));
	float major_ticks = step(0.85, sin(orbit_angle * 6.0)) * smoothstep(0.035, 0.0, abs(dist - 0.445));

	// Arcos de energía en traslación orbital
	float energy_arc = pow(max(0.0, sin(orbit_angle - TIME * speed)), 7.0) * smoothstep(0.045, 0.0, abs(dist - 0.40));
	float counter_arc = pow(max(0.0, sin(-orbit_angle - TIME * speed * 0.6)), 9.0) * smoothstep(0.035, 0.0, abs(dist - 0.37));

	// =========================================================================
	// 2. CONSOLA TERMINAL CENTRAL // ANDROMEDA OS CLI
	// =========================================================================
	// Pantalla de terminal octagonal con bordes biselados
	vec2 term_p = abs(p);
	float term_box = max(term_p.x, term_p.y);
	float term_oct = term_p.x + term_p.y;
	float is_inside_term = step(term_box, 0.24) * step(term_oct, 0.34);
	
	// Marco perimetral de la ventana de la terminal
	float term_border = smoothstep(0.008, 0.0, abs(term_box - 0.24)) * step(term_oct, 0.34);
	term_border += smoothstep(0.008, 0.0, abs(term_oct - 0.34)) * step(term_box, 0.24);

	// Barra superior de la ventana de terminal (Header bar)
	float header_line = smoothstep(0.006, 0.0, abs(p.y - (-0.17))) * is_inside_term;
	// LEDs / Botones de control de ventana de terminal [ x ] [ - ] [ + ]
	float led1 = smoothstep(0.012, 0.0, length(p - vec2(-0.16, -0.20)));
	float led2 = smoothstep(0.012, 0.0, length(p - vec2(-0.12, -0.20)));
	float led3 = smoothstep(0.012, 0.0, length(p - vec2(-0.08, -0.20)));
	float term_leds = (led1 + led2 + led3) * 1.5;

	// Texto procedimental de terminal: Título del prompt ">_ CLI"
	// Símbolo '>' (chevron)
	float ch_y = p.y - (-0.10);
	float ch_x = p.x - (-0.17);
	float chevron = smoothstep(0.007, 0.0, abs(abs(ch_y) - ch_x * 0.9)) * step(-0.01, ch_x) * step(ch_x, 0.035) * step(abs(ch_y), 0.025);

	// Cursor parpadeante de terminal '█' (3.5 Hz)
	float cursor_blink = step(0.5, sin(TIME * 7.0));
	float cursor_block = step(abs(p.x - 0.12), 0.018) * step(abs(p.y - (-0.10)), 0.022) * cursor_blink * is_inside_term;

	// Línea activa de comando en ejecución (prompt line bar)
	float prompt_line = smoothstep(0.005, 0.0, abs(p.y - (-0.065))) * step(-0.18, p.x) * step(p.x, 0.15) * 0.45;

	// =========================================================================
	// 3. CASCADA DE DATOS HEXADECIMALES / MATRIZ DE TELEMETRÍA DE TERMINAL
	// =========================================================================
	// Líneas de volcado de memoria (Memory dump) fluyendo con el giro y el tiempo
	float scroll_y = p.y * 36.0 + TIME * speed * 4.5 + ring_angle * 8.0;
	float line_idx = floor(scroll_y);
	float char_x = floor((p.x + 0.18) * 38.0);
	
	// Caracteres pseudo-hexadecimales generados por funciones hash/sinusoidales
	float hex_pattern = step(0.48, sin(line_idx * 17.13 + char_x * 9.87)) * step(0.35, cos(line_idx * 3.41 + char_x * 5.23));
	float line_mask = step(-0.16, p.x) * step(p.x, 0.16) * step(-0.04, p.y) * step(p.y, 0.20);
	float data_stream = hex_pattern * line_mask * (sin(scroll_y * 3.14159) * 0.35 + 0.65) * 1.25;

	// Barras de estado tipo búfer en la parte inferior de la terminal
	float buffer_bar_y = p.y - 0.17;
	float buffer_bar = smoothstep(0.008, 0.0, abs(buffer_bar_y)) * step(-0.18, p.x) * step(p.x, 0.18);
	float buffer_segments = step(0.5, sin((p.x + 0.18) * 65.0)) * buffer_bar * 1.2;

	// Haz de escáner / radar de terminal (rotación reactiva al cambio de modo)
	float radar_angle = base_angle - TIME * speed * 2.0 - ring_angle * 1.5;
	float radar_sweep = pow(max(0.0, sin(radar_angle)), 14.0) * is_inside_term * 1.6;

	// =========================================================================
	// 4. LÍNEAS DE ESCANEO CRT & RESPLANDOR FOSFÓRICO
	// =========================================================================
	float scanline = sin(UV.y * 125.0 + TIME * 3.5) * 0.14 + 0.86;
	float inner_glow = exp(-pow((dist - 0.40) * 4.5, 2.0)) * 0.38 * pulse_intensity;
	float term_crt_glow = is_inside_term * 0.22 * pulse_intensity;

	// Composición final de elementos
	float outer_elements = (ring1 * 1.3 + ring2 * 0.85 + ring3 * 0.6 + outer_border * 0.95 + ticks * 1.6 + major_ticks * 2.2 + energy_arc * 3.2 + counter_arc * 2.2);
	float term_elements = (term_border * 1.6 + header_line * 1.1 + term_leds + chevron * 2.0 + cursor_block * 2.5 + prompt_line + data_stream + buffer_segments + radar_sweep);
	float total_graphics = (outer_elements + term_elements) * scanline;

	// Color del fósforo de la terminal adaptativo según el modo activo
	vec3 col = mix(primary_color.rgb, secondary_color.rgb, sin(orbit_angle * 2.0 + TIME * 0.8) * 0.5 + 0.5);
	// El interior de la pantalla terminal brilla con el tono de comando neón
	col = mix(col, primary_color.rgb * 1.25, is_inside_term * 0.85);
	col += ring_glow_color.rgb * (inner_glow + term_crt_glow);

	float alpha = clamp(total_graphics + (inner_glow + term_crt_glow) * 0.85, 0.0, 1.0);
	
	// Atenuación de perspectiva 3D
	float depth_factor = clamp(uv.y * 1.35 + 0.78, 0.38, 1.0);
	COLOR = vec4(col, alpha * primary_color.a * depth_factor);
}
