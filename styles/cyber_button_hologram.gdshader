shader_type canvas_item;

// Holographic Synthwave Cyber Button Shader (Rojo, Negro y Morado)
// Integra perfectamente los botones pixel art con la paleta Rojo, Negro y Morado

uniform float idle_glass_alpha : hint_range(0.0, 1.0) = 0.42;
uniform float hover_glass_alpha : hint_range(0.0, 1.0) = 0.65;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.20;
uniform float border_pulse_speed : hint_range(0.1, 10.0) = 3.0;
uniform float chromatic_shift : hint_range(0.0, 5.0) = 1.8;
uniform vec4 top_tint : source_color = vec4(0.08, 0.01, 0.15, 0.85);   // Negro/Morado oscuro
uniform vec4 bottom_tint : source_color = vec4(0.35, 0.02, 0.14, 0.85); // Rojo/Morado profundo

void fragment() {
	vec2 uv = UV;
	
	// Aberración cromática en los canales
	vec2 offset = vec2(chromatic_shift / 400.0, 0.0);
	float r = texture(TEXTURE, uv + offset).r;
	float g = texture(TEXTURE, uv).g;
	float b = texture(TEXTURE, uv - offset).b;
	float a = texture(TEXTURE, uv).a;
	
	if (a < 0.01) {
		discard;
	}
	
	vec3 base_color = vec3(r, g, b);
	float lum = dot(base_color, vec3(0.299, 0.587, 0.114));
	
	// Determinar si es borde neón o interior del botón:
	// El borde pixel art original tiene alta saturación roja/magenta (r > 0.6 y g < 0.4)
	bool is_border = (base_color.r > 0.6 && base_color.g < 0.4);
	// El interior del botón puede ser oscuro (estado reposo) o blanco (estado hover)
	bool is_hover_body = (!is_border && lum > 0.5);
	bool is_idle_body = (!is_border && lum <= 0.5);
	
	vec3 final_color = base_color;
	float final_alpha = a;
	
	if (is_idle_body) {
		// --- CUERPO EN REPOSO: Cristal translúcido negro/morado/rojo ---
		vec3 glass_grad = mix(top_tint.rgb, bottom_tint.rgb, uv.y);
		final_color = mix(glass_grad, vec3(0.65, 0.05, 0.85), 0.08); // Toque morado
		final_alpha = a * idle_glass_alpha;
		
		// Líneas de escaneo holográfico tenues en rojo/morado
		float scanline = sin(uv.y * 55.0 - TIME * 3.5) * 0.5 + 0.5;
		final_color += vec3(0.9, 0.05, 0.4) * scanline * scanline_intensity * 0.4;
	} 
	else if (is_hover_body) {
		// --- CUERPO EN HOVER: Plasma energizado rojo carmesí y morado neón ---
		float sweep = sin((uv.x * 2.5 - uv.y * 1.5) * 4.0 - TIME * 6.0) * 0.5 + 0.5;
		vec3 plasma = mix(vec3(0.12, 0.0, 0.22), vec3(0.95, 0.02, 0.18), sweep * 0.75);
		plasma = mix(plasma, vec3(0.85, 0.1, 0.95), (1.0 - uv.y) * 0.45 + sweep * 0.3);
		
		final_color = plasma;
		final_alpha = a * hover_glass_alpha;
		
		// Escaneo láser rápido en rojo
		float fast_scan = sin(uv.y * 70.0 - TIME * 7.0) * 0.5 + 0.5;
		final_color += vec3(1.0, 0.2, 0.4) * fast_scan * 0.25;
	}
	else {
		// --- BORDES NEÓN (Pixel Art) ---
		// Pulso vivo de neón entre Rojo Neón y Morado Neón
		float pulse = 0.92 + 0.18 * sin(TIME * border_pulse_speed);
		vec3 neon_accent = mix(vec3(1.0, 0.05, 0.2), vec3(0.8, 0.05, 0.95), sin(TIME * 2.0) * 0.5 + 0.5);
		final_color = mix(base_color, neon_accent, 0.35) * pulse;
		
		// Resplandor en las esquinas y extremos
		float edge_glow = (abs(uv.x - 0.5) * 2.0) * 0.15;
		final_color += vec3(0.5, 0.0, 0.3) * edge_glow;
		final_alpha = a;
	}
	
	COLOR = vec4(final_color, final_alpha);
}
