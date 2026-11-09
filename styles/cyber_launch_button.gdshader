shader_type canvas_item;

// Shader Ultra Cyberpunk de Alto Impacto para el Botón "INICIAR NIVEL"
uniform vec4 border_color : source_color = vec4(1.0, 0.08, 0.28, 1.0);  // Rojo Carmesí Neón
uniform vec4 hover_color : source_color = vec4(0.0, 0.95, 1.0, 1.0);    // Cian Láser
uniform vec4 glass_tint : source_color = vec4(0.08, 0.01, 0.16, 0.85);  // Cristal oscuro cyberpunk
uniform float is_hovered : hint_range(0.0, 1.0) = 0.0;
uniform float shine_speed : hint_range(0.5, 6.0) = 2.4;
uniform float pulse_speed : hint_range(0.5, 8.0) = 4.0;
uniform float chromatic_shift : hint_range(0.0, 5.0) = 1.8;

void fragment() {
	vec2 uv = UV;
	
	// Aberración cromática en los bordes
	vec2 shift = vec2((chromatic_shift + is_hovered * 1.5) * TEXTURE_PIXEL_SIZE.x, 0.0);
	float r = texture(TEXTURE, uv + shift).r;
	float g = texture(TEXTURE, uv).g;
	float b = texture(TEXTURE, uv - shift).b;
	float a = texture(TEXTURE, uv).a;
	
	if (a < 0.01) {
		discard;
	}
	
	// Detección de contornos para halo exterior
	vec2 px = TEXTURE_PIXEL_SIZE * 2.2;
	float a_up    = texture(TEXTURE, uv + vec2(0.0, -px.y)).a;
	float a_down  = texture(TEXTURE, uv + vec2(0.0, px.y)).a;
	float a_left  = texture(TEXTURE, uv + vec2(-px.x, 0.0)).a;
	float a_right = texture(TEXTURE, uv + vec2(px.x, 0.0)).a;
	float edge = clamp((4.0 * a - (a_up + a_down + a_left + a_right)) * 2.5, 0.0, 1.0);
	
	// Scanlines horizontales tipo monitor militar HUD
	float scanline = sin(uv.y * 70.0 - TIME * 4.0) * 0.5 + 0.5;
	
	// Haz de luz diagonal holográfico intenso
	float shine_phase = fract(TIME * (shine_speed * 0.28 + is_hovered * 0.2));
	float diag = uv.x * 0.72 + uv.y * 0.28;
	float dist_shine = abs(diag - (shine_phase * 1.7 - 0.35));
	float shine = smoothstep(0.12, 0.0, dist_shine);
	
	// Onda de energía cruzada continua
	float wave = sin((uv.x * 3.0 - uv.y * 2.0) * 3.5 - TIME * 5.0) * 0.5 + 0.5;
	
	// Pulso de energía en el borde
	float pulse = 0.85 + 0.25 * sin(TIME * pulse_speed);
	
	// Color base con tinte de cristal holográfico
	vec3 base_col = vec3(r, g, b);
	vec3 body = mix(base_col, glass_tint.rgb, 0.35);
	body += vec3(0.1, 0.7, 1.0) * (scanline * 0.12);
	body += vec3(1.0, 0.2, 0.4) * (wave * 0.15);
	
	// Color activo adaptativo (Carmesí en reposo, Cian vibrante en hover)
	vec3 active_neon = mix(border_color.rgb, hover_color.rgb, is_hovered);
	
	// Aumento general de luminosidad en hover
	body *= (1.0 + is_hovered * 0.4);
	
	// Aplicar el haz de luz brillante (núcleo blanco con halo neón)
	vec3 flare_col = mix(vec3(1.0), active_neon, 0.2);
	body += flare_col * (shine * (0.55 + is_hovered * 0.45));
	
	// Borde ultra brillante con aura neón
	vec3 final_edge = active_neon * (2.2 * pulse);
	vec3 final_rgb = mix(body, final_edge, edge);
	
	COLOR = vec4(final_rgb, a);
}
