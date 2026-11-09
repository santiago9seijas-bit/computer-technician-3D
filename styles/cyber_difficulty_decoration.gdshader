shader_type canvas_item;

// Shader holográfico cyberpunk carmesí puro para "decoracion para selector de dificultad"
// Paleta: Rojo Carmesí Neón, Rojo Sangre Profundo y Negro (Sin amarillos)

uniform vec4 red_neon_color : source_color = vec4(1.0, 0.02, 0.12, 1.0);  // Rojo Neón Láser
uniform vec4 red_deep_color : source_color = vec4(0.45, 0.01, 0.05, 1.0); // Rojo Profundo Táctico
uniform float scanline_speed : hint_range(0.5, 6.0) = 2.2;
uniform float scanline_density : hint_range(10.0, 80.0) = 40.0;
uniform float pulse_speed : hint_range(0.5, 8.0) = 3.2;
uniform float glow_intensity : hint_range(0.5, 4.0) = 2.0;
uniform float chromatic_shift : hint_range(0.0, 4.0) = 1.5;

void fragment() {
	vec2 uv = UV;
	vec2 shift = vec2(chromatic_shift * TEXTURE_PIXEL_SIZE.x, 0.0);
	
	float r = texture(TEXTURE, uv + shift).r;
	float g = texture(TEXTURE, uv).g;
	float b = texture(TEXTURE, uv - shift).b;
	float a = texture(TEXTURE, uv).a;
	
	if (a < 0.01) {
		discard;
	}
	
	// Detección de contornos para halo exterior rojo brillante
	vec2 px = TEXTURE_PIXEL_SIZE * 2.2;
	float a_up    = texture(TEXTURE, uv + vec2(0.0, -px.y)).a;
	float a_down  = texture(TEXTURE, uv + vec2(0.0, px.y)).a;
	float a_left  = texture(TEXTURE, uv + vec2(-px.x, 0.0)).a;
	float a_right = texture(TEXTURE, uv + vec2(px.x, 0.0)).a;
	float edge = clamp((4.0 * a - (a_up + a_down + a_left + a_right)) * 2.5, 0.0, 1.0);
	
	// Scanlines sutiles verticales en rojo oscuro
	float scan = sin(uv.y * scanline_density - TIME * scanline_speed) * 0.5 + 0.5;
	
	// Pulso de respiración neón
	float pulse = 0.88 + 0.22 * sin(TIME * pulse_speed);
	
	// Gradiente vertical base de rojo oscuro a rojo carmesí
	vec3 body = mix(red_deep_color.rgb, red_neon_color.rgb * 0.75, uv.y);
	body += red_neon_color.rgb * (scan * 0.15);
	
	// Barrido diagonal de haz de luz roja
	float sweep = sin((uv.x * 2.0 + uv.y * 2.5) * 4.0 - TIME * 3.5) * 0.5 + 0.5;
	body += red_neon_color.rgb * (sweep * 0.22);
	
	// Borde ultra brillante en rojo carmesí neón
	vec3 final_rgb = mix(body, red_neon_color.rgb * glow_intensity * pulse, edge);
	
	COLOR = vec4(final_rgb, a);
}
