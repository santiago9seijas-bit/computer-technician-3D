shader_type canvas_item;

// Holographic Cyberpunk Decoration Shader (Rojo, Negro y Morado)
// Transforma el sprite de decoración en una placa holográfica translúcida con bordes de neón

uniform float base_alpha : hint_range(0.0, 1.0) = 0.35;
uniform float edge_alpha : hint_range(0.0, 1.0) = 0.95;
uniform float scanline_speed = 2.5;
uniform float scanline_density = 40.0;
uniform float pulse_speed = 3.0;
uniform vec4 top_color : source_color = vec4(0.48, 0.04, 0.78, 1.0);     // Morado profundo
uniform vec4 bottom_color : source_color = vec4(0.88, 0.02, 0.16, 1.0);  // Rojo carmesí
uniform vec4 edge_color : source_color = vec4(1.0, 0.08, 0.22, 1.0);     // Rojo neón brillante

void fragment() {
	vec2 uv = UV;
	vec4 tex = texture(TEXTURE, uv);
	
	if (tex.a < 0.01) {
		discard;
	}
	
	// Detección de bordes mediante muestreo de vecinos
	vec2 px = TEXTURE_PIXEL_SIZE * 2.0;
	float a_up    = texture(TEXTURE, uv + vec2(0.0, -px.y)).a;
	float a_down  = texture(TEXTURE, uv + vec2(0.0, px.y)).a;
	float a_left  = texture(TEXTURE, uv + vec2(-px.x, 0.0)).a;
	float a_right = texture(TEXTURE, uv + vec2(px.x, 0.0)).a;
	
	float edge = clamp((4.0 * tex.a - (a_up + a_down + a_left + a_right)) * 2.0, 0.0, 1.0);
	
	// Gradiente base vertical: Morado arriba a Rojo carmesí abajo
	vec3 body_grad = mix(top_color.rgb, bottom_color.rgb, uv.y);
	
	// Escaneo holográfico animado en tonos violeta
	float scan = sin(uv.y * scanline_density - TIME * scanline_speed) * 0.5 + 0.5;
	
	// Barrido de onda diagonal interactiva en rojo
	float wave = sin((uv.x * 2.0 + uv.y * 3.0) * 3.0 - TIME * 4.0) * 0.5 + 0.5;
	
	// Brillo del cuerpo interno (Morado y Rojo sobre base oscura)
	vec3 body_col = body_grad + vec3(0.5, 0.02, 0.6) * (scan * 0.25) + vec3(0.65, 0.0, 0.15) * (wave * 0.25);
	
	// Borde de neón con pulso rítmico (oscilación Rojo Neón <-> Morado Neón)
	float pulse = 0.85 + 0.15 * sin(TIME * pulse_speed);
	vec3 neon_purple = vec3(0.78, 0.05, 0.98);
	vec3 neon_edge = mix(edge_color.rgb, neon_purple, sin(TIME * 2.5 + uv.y * 4.0) * 0.5 + 0.5) * pulse;
	
	// Combinación de borde y cuerpo translúcido
	vec3 final_color = mix(body_col, neon_edge, edge);
	float final_alpha = mix(tex.a * base_alpha, tex.a * edge_alpha, edge);
	
	COLOR = vec4(final_color, final_alpha);
}
