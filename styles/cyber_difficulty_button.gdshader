shader_type canvas_item;

// Shader cyberpunk holográfico para botones de selección de dificultad
uniform vec4 accent_color : source_color = vec4(1.0, 0.1, 0.4, 1.0);
uniform float is_hovered : hint_range(0.0, 1.0) = 0.0;
uniform float is_selected : hint_range(0.0, 1.0) = 0.0;
uniform float shine_speed : hint_range(0.5, 6.0) = 2.2;
uniform float pulse_speed : hint_range(0.5, 8.0) = 3.5;

void fragment() {
	vec2 uv = UV;
	vec4 tex = texture(TEXTURE, uv);
	
	if (tex.a < 0.01) {
		discard;
	}
	
	// Detección de bordes
	vec2 px = TEXTURE_PIXEL_SIZE * 2.0;
	float a_up    = texture(TEXTURE, uv + vec2(0.0, -px.y)).a;
	float a_down  = texture(TEXTURE, uv + vec2(0.0, px.y)).a;
	float a_left  = texture(TEXTURE, uv + vec2(-px.x, 0.0)).a;
	float a_right = texture(TEXTURE, uv + vec2(px.x, 0.0)).a;
	float edge = clamp((4.0 * tex.a - (a_up + a_down + a_left + a_right)) * 2.0, 0.0, 1.0);
	
	// Barrido de destello diagonal holográfico
	float shine_phase = fract(TIME * (shine_speed * 0.25 + is_hovered * 0.15));
	float diag = uv.x * 0.75 + uv.y * 0.25;
	float dist_to_shine = abs(diag - (shine_phase * 1.5 - 0.25));
	float shine = smoothstep(0.12, 0.0, dist_to_shine);
	
	// Pulso de selección y hover
	float pulse = 0.88 + 0.22 * sin(TIME * pulse_speed);
	
	// Color base con ligero realce
	vec3 col = tex.rgb;
	
	// Si está seleccionado o en hover, amplificar brillo y saturación
	float boost = 1.0 + is_hovered * 0.25 + is_selected * 0.45;
	col *= boost;
	
	// Efecto de barrido de luz blanca/neón
	vec3 shine_col = mix(vec3(1.0), accent_color.rgb, 0.35);
	col += shine_col * (shine * (0.35 + is_hovered * 0.25 + is_selected * 0.4));
	
	// Borde brillante con pulso si está seleccionado o en hover
	float edge_intensity = mix(0.2, 1.0, max(is_hovered, is_selected));
	vec3 edge_glow = mix(col, accent_color.rgb * 1.6 * pulse, edge * edge_intensity);
	
	col = mix(col, edge_glow, edge);
	
	// Tinte sutil cuando está seleccionado
	if (is_selected > 0.5) {
		col = mix(col, accent_color.rgb, 0.18 + 0.1 * sin(TIME * 4.0));
	}
	
	COLOR = vec4(col, tex.a) * COLOR;
}
