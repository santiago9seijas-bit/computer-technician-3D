shader_type canvas_item;

// Holographic Cyber Card Shader
uniform vec4 holo_color : source_color = vec4(0.0, 0.9, 1.0, 1.0);
uniform vec4 bg_color : source_color = vec4(0.015, 0.04, 0.09, 0.50);
uniform float scanline_speed : hint_range(0.1, 5.0) = 1.2;
uniform float scanline_density : hint_range(20.0, 200.0) = 80.0;
uniform float corner_cut : hint_range(0.01, 0.2) = 0.08;
uniform float border_thickness : hint_range(0.01, 0.1) = 0.035;
uniform float pulse_speed : hint_range(0.1, 5.0) = 1.8;

void fragment() {
	vec2 uv = UV;
	
	// Diagonal corner chamfer cuts
	float d_tl = uv.x + uv.y;
	float d_tr = (1.0 - uv.x) + uv.y;
	float d_bl = uv.x + (1.0 - uv.y);
	float d_br = (1.0 - uv.x) + (1.0 - uv.y);
	
	if (d_tl < corner_cut || d_tr < corner_cut || d_bl < corner_cut || d_br < corner_cut) {
		discard;
	}
	
	// Edge detection for glowing border
	float edge_l = smoothstep(0.0, border_thickness, uv.x);
	float edge_r = smoothstep(0.0, border_thickness, 1.0 - uv.x);
	float edge_t = smoothstep(0.0, border_thickness, uv.y);
	float edge_b = smoothstep(0.0, border_thickness, 1.0 - uv.y);
	float inner_box = edge_l * edge_r * edge_t * edge_b;
	float border = 1.0 - inner_box;
	
	// Chamfer border lines
	float chamfer_border = 0.0;
	chamfer_border += smoothstep(corner_cut + border_thickness * 1.4, corner_cut, d_tl);
	chamfer_border += smoothstep(corner_cut + border_thickness * 1.4, corner_cut, d_tr);
	chamfer_border += smoothstep(corner_cut + border_thickness * 1.4, corner_cut, d_bl);
	chamfer_border += smoothstep(corner_cut + border_thickness * 1.4, corner_cut, d_br);
	border = clamp(border + chamfer_border, 0.0, 1.0);
	
	// Subtle animated horizontal scanlines
	float scanline = sin(uv.y * scanline_density - TIME * scanline_speed * 4.0) * 0.12 + 0.88;
	
	// Technical micro-grid dots
	vec2 grid_uv = fract(uv * vec2(24.0, 14.0));
	float grid_dots = smoothstep(0.12, 0.0, length(grid_uv - vec2(0.5))) * 0.18;
	
	// Breathing neon pulse
	float pulse = 0.88 + 0.12 * sin(TIME * pulse_speed);
	
	// Top and bottom technical bracket accents
	float top_bracket = step(abs(uv.x - 0.5), 0.35) * step(uv.y, border_thickness * 1.5);
	float bottom_bracket = step(abs(uv.x - 0.5), 0.25) * step(1.0 - uv.y, border_thickness * 1.5);
	float brackets = (top_bracket + bottom_bracket) * 0.4;
	
	// Assemble holographic composition (bisel oscuro metálico, sin marco blanco o colores estridentes)
	vec3 base = bg_color.rgb;
	vec3 border_metal = vec3(0.18, 0.22, 0.28);
	base += border_metal * grid_dots;
	base += border_metal * (border * 0.85 + brackets) * pulse;
	base += holo_color.rgb * (1.0 - inner_box) * 0.35;
	
	float final_alpha = (bg_color.a + border * 0.45 + grid_dots * 0.2) * scanline;
	COLOR = vec4(base * scanline, clamp(final_alpha, 0.0, 1.0));
}
