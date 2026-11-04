shader_type canvas_item;

// =============================================================================
// SHADER HOLOGRÁFICO ROJIZO CYBERPUNK PARA CÍRCULO DE OBJETO (SLOTS DE MODO/HERRAMIENTA)
// Estética: Rojo Carmesí Neón, Morado Eléctrico, Cristal Oscuro Translúcido y Escaneo Láser
// =============================================================================

uniform vec4 primary_color : source_color = vec4(1.0, 0.08, 0.22, 1.0);    // Rojo Carmesí Neón
uniform vec4 secondary_color : source_color = vec4(0.70, 0.03, 0.85, 1.0); // Púrpura Synthwave
uniform vec4 core_dark_tint : source_color = vec4(0.07, 0.01, 0.12, 0.82); // Fondo cristalino oscuro
uniform vec4 active_glow_color : source_color = vec4(1.0, 0.28, 0.42, 1.0);// Resplandor activo brillante

uniform float is_active : hint_range(0.0, 1.0) = 0.0;                      // 1.0 = Herramienta seleccionada
uniform float is_hover : hint_range(0.0, 1.0) = 0.0;                       // 1.0 = Mouse encima
uniform float scanline_density : hint_range(10.0, 120.0) = 52.0;
uniform float scanline_speed = 2.4;
uniform float sweep_speed = 2.8;
uniform float pulse_speed = 3.2;
uniform float chromatic_shift : hint_range(0.0, 4.0) = 1.5;
uniform float base_alpha : hint_range(0.0, 1.0) = 0.90;

void fragment() {
	vec2 uv = UV;
	
	// Aberración cromática en los bordes para estilo de holograma digital
	float shift = (chromatic_shift + is_active * 1.2) / 400.0;
	float r_tex = texture(TEXTURE, uv + vec2(shift, 0.0)).r;
	float g_tex = texture(TEXTURE, uv).g;
	float b_tex = texture(TEXTURE, uv - vec2(shift, 0.0)).b;
	float a_tex = texture(TEXTURE, uv).a;
	
	if (a_tex < 0.02) {
		discard;
	}
	
	// Detección de borde exterior del círculo muestreando píxeles adyacentes
	vec2 px = TEXTURE_PIXEL_SIZE * 2.0;
	float a_up    = texture(TEXTURE, uv + vec2(0.0, -px.y)).a;
	float a_down  = texture(TEXTURE, uv + vec2(0.0, px.y)).a;
	float a_left  = texture(TEXTURE, uv + vec2(-px.x, 0.0)).a;
	float a_right = texture(TEXTURE, uv + vec2(px.x, 0.0)).a;
	float edge = clamp((4.0 * a_tex - (a_up + a_down + a_left + a_right)) * 2.2, 0.0, 1.0);
	
	// Luminosidad del píxel original del sprite pixel art
	float base_lum = dot(vec3(r_tex, g_tex, b_tex), vec3(0.299, 0.587, 0.114));
	
	// Coordenadas relativas al centro del círculo para efectos radiales
	vec2 center_uv = uv - vec2(0.5, 0.5);
	float dist_from_center = length(center_uv);
	float angle = atan(center_uv.y, center_uv.x);
	
	// Barrido holográfico rotatorio (efecto radar cibernético)
	float radar_speed = sweep_speed * (1.0 + is_active * 0.6);
	float sweep = sin(angle * 2.0 - TIME * radar_speed) * 0.5 + 0.5;
	sweep = pow(sweep, 2.2);
	
	// Líneas de escaneo horizontales holográficas
	float scanline = sin(uv.y * scanline_density - TIME * scanline_speed) * 0.5 + 0.5;
	
	// Pulso de energía rítmico
	float p_speed = pulse_speed * (1.0 + is_active * 0.8);
	float pulse = 0.85 + 0.20 * sin(TIME * p_speed);
	
	// Color base: Gradiente vertical de púrpura a rojo carmesí con modulado por luminancia original
	vec3 cyber_grad = mix(secondary_color.rgb, primary_color.rgb, uv.y);
	
	// Si el píxel está en el borde exterior o bisel del círculo:
	// Lo iluminamos con rojo neón brillante y púrpura
	vec3 rim_color = mix(primary_color.rgb, secondary_color.rgb, sin(TIME * 2.0 + angle) * 0.5 + 0.5);
	rim_color = mix(rim_color, active_glow_color.rgb, is_active);
	rim_color *= (1.2 + 0.4 * pulse + (is_active * 0.4) + (is_hover * 0.3));
	
	// Núcleo interno del círculo: cristal oscuro con textura de interferencia holográfica
	vec3 core_color = mix(core_dark_tint.rgb, cyber_grad, 0.25 + 0.15 * base_lum);
	core_color += primary_color.rgb * (scanline * 0.18 + sweep * 0.22);
	
	// Anillo de retícula holográfica interna sutil
	float reticle_ring = smoothstep(0.04, 0.0, abs(dist_from_center - 0.28));
	core_color += primary_color.rgb * reticle_ring * 0.45 * pulse;
	
	// Mezcla entre borde neón y núcleo según detección de borde y luminancia del bisel
	float is_rim = max(edge, smoothstep(0.35, 0.8, base_lum));
	vec3 final_rgb = mix(core_color, rim_color, is_rim);
	
	// Resaltado extra en estado activo / hover
	if (is_active > 0.01) {
		float active_pulse = 0.5 + 0.5 * sin(TIME * 6.0);
		final_rgb += active_glow_color.rgb * (0.28 + 0.22 * active_pulse);
	}
	if (is_hover > 0.01) {
		final_rgb += primary_color.rgb * 0.25;
	}
	
	float final_a = a_tex * base_alpha;
	if (is_rim > 0.3 || is_active > 0.01) {
		final_a = a_tex * 0.98;
	}
	
	COLOR = vec4(final_rgb, final_a);
}
