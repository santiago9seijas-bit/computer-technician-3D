shader_type canvas_item;

// Shader Cyberpunk de Alta Visibilidad y Resplandor Neón
// Diseñado para hacer iconos y flechas sumamente llamativos, luminosos y con halo exterior
uniform vec4 glow_color : source_color = vec4(0.0, 0.95, 1.0, 1.0); // Cian Neón
uniform vec4 inner_tint : source_color = vec4(1.0, 0.25, 0.65, 1.0); // Magenta Neón
uniform float glow_intensity : hint_range(0.5, 3.0) = 1.7;
uniform float pulse_speed : hint_range(0.5, 10.0) = 3.2;
uniform float outline_width : hint_range(0.0, 10.0) = 2.2;

void fragment() {
	vec2 uv = UV;
	vec4 base_col = texture(TEXTURE, uv);
	
	// Detección y muestreo de contorno para halo exterior brillante
	vec2 ps = TEXTURE_PIXEL_SIZE * outline_width;
	float a_up    = texture(TEXTURE, uv + vec2(0.0, -ps.y)).a;
	float a_down  = texture(TEXTURE, uv + vec2(0.0, ps.y)).a;
	float a_left  = texture(TEXTURE, uv + vec2(-ps.x, 0.0)).a;
	float a_right = texture(TEXTURE, uv + vec2(ps.x, 0.0)).a;
	float a_d1    = texture(TEXTURE, uv + vec2(-ps.x, -ps.y)).a;
	float a_d2    = texture(TEXTURE, uv + vec2(ps.x, -ps.y)).a;
	float a_d3    = texture(TEXTURE, uv + vec2(-ps.x, ps.y)).a;
	float a_d4    = texture(TEXTURE, uv + vec2(ps.x, ps.y)).a;
	
	float max_neighbor_a = max(max(max(a_up, a_down), max(a_left, a_right)), max(max(a_d1, a_d2), max(a_d3, a_d4)));
	float outline = clamp(max_neighbor_a - base_col.a, 0.0, 1.0);
	
	// Pulso rítmico de luminosidad
	float pulse = 0.9 + 0.3 * sin(TIME * pulse_speed);
	
	// Brillo de barrido diagonal continuo
	float sweep = sin((uv.x * 2.0 - uv.y) * 4.0 - TIME * 4.0) * 0.5 + 0.5;
	
	// Color del sprite amplificado en brillo
	vec3 boosted_rgb = base_col.rgb * (1.35 + 0.45 * sweep) * pulse;
	boosted_rgb = mix(boosted_rgb, inner_tint.rgb, 0.22 * sweep);
	
	// Halo exterior de neón cian super brillante
	vec3 final_rgb = mix(boosted_rgb, glow_color.rgb * glow_intensity * pulse, outline);
	float final_a = max(base_col.a, outline * 0.95);
	
	if (final_a < 0.02) {
		discard;
	}
	
	COLOR = vec4(final_rgb, final_a) * COLOR;
}
