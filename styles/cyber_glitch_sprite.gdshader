shader_type canvas_item;

// Cyberpunk Holographic Glitch Shader (Paleta: Rojo Neón, Púrpura y Negro)
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.25;
uniform float speed = 4.0;
uniform vec4 tint_color : source_color = vec4(1.0, 0.15, 0.45, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = UV;
	
	// Tiempo escalonado para saltos tipo glitch digital
	float t = floor(TIME * speed * 2.0);
	
	// Bandas horizontales de distorsión
	float slice_y = floor(uv.y * 22.0);
	float noise_slice = hash(vec2(slice_y, t));
	
	float x_offset = 0.0;
	if (noise_slice > 0.80) {
		x_offset = (noise_slice - 0.80) * 0.08 * (hash(vec2(t, 9.1)) > 0.5 ? 1.0 : -1.0) * glitch_intensity;
	}
	
	vec2 glitch_uv = vec2(uv.x + x_offset, uv.y);
	
	// Separación cromática (Aberración roja y morada)
	float split = 0.007 * glitch_intensity * (sin(TIME * 6.0) * 0.5 + 0.5);
	if (noise_slice > 0.88) {
		split *= 3.0;
	}
	
	vec4 col_r = texture(TEXTURE, glitch_uv + vec2(split, 0.0));
	vec4 col_g = texture(TEXTURE, glitch_uv);
	vec4 col_b = texture(TEXTURE, glitch_uv - vec2(split, 0.0));
	
	float alpha = max(col_g.a, max(col_r.a, col_b.a));
	if (alpha < 0.02) {
		discard;
	}
	
	vec4 final_col = vec4(col_r.r, col_g.g, col_b.b, alpha);
	
	// Scanlines de alta definición
	float scan = sin(uv.y * 140.0 + TIME * 2.5) * 0.5 + 0.5;
	final_col.rgb = mix(final_col.rgb, final_col.rgb * (0.82 + 0.18 * scan), scanline_strength);
	
	// Tinte rítmico cyberpunk (Rojo Neón y Púrpura)
	float pulse = sin(TIME * 2.5) * 0.5 + 0.5;
	vec3 cyber_tint = mix(vec3(0.95, 0.05, 0.3), vec3(0.65, 0.1, 0.95), pulse);
	final_col.rgb = mix(final_col.rgb, final_col.rgb + cyber_tint * 0.22, glitch_intensity * 0.6);
	
	COLOR = final_col;
}
