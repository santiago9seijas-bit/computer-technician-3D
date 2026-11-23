shader_type canvas_item;

// Linux Terminal Recuadro Button Shader (Neutral Glass Frame, NO harsh red/blue/yellow border)
uniform vec4 term_color : source_color = vec4(0.0, 0.95, 1.0, 1.0);
uniform vec4 bg_color : source_color = vec4(0.02, 0.03, 0.06, 0.52);
uniform bool is_selected = false;
uniform float pulse_speed : hint_range(0.5, 5.0) = 2.2;

void fragment() {
	vec2 uv = UV;
	
	// Diagonal corner chamfer (tech aesthetic)
	float corner = 0.06;
	float d_tl = uv.x + uv.y;
	float d_tr = (1.0 - uv.x) + uv.y;
	float d_bl = uv.x + (1.0 - uv.y);
	float d_br = (1.0 - uv.x) + (1.0 - uv.y);
	if (d_tl < corner || d_tr < corner || d_bl < corner || d_br < corner) {
		discard;
	}
	
	// Outer border
	float b_thick = 0.032;
	float edge_l = smoothstep(0.0, b_thick, uv.x);
	float edge_r = smoothstep(0.0, b_thick, 1.0 - uv.x);
	float edge_t = smoothstep(0.0, b_thick, uv.y);
	float edge_b = smoothstep(0.0, b_thick, 1.0 - uv.y);
	float border = 1.0 - (edge_l * edge_r * edge_t * edge_b);
	
	// Chamfer border highlight
	border += smoothstep(corner + b_thick * 1.5, corner, d_tl) * 0.8;
	border += smoothstep(corner + b_thick * 1.5, corner, d_tr) * 0.8;
	border += smoothstep(corner + b_thick * 1.5, corner, d_bl) * 0.8;
	border += smoothstep(corner + b_thick * 1.5, corner, d_br) * 0.8;
	border = clamp(border, 0.0, 1.0);
	
	// Top Linux Terminal window titlebar separator line
	float header_line = smoothstep(0.012, 0.0, abs(uv.y - 0.28));
	
	// 3 Linux Terminal dots in header (red, yellow, green) with aspect ratio correction (~185x46 => aspect ~ 4.0)
	float aspect = 4.0;
	vec2 dot_uv = vec2((uv.x - 0.04) * aspect, uv.y - 0.14);
	float dot1 = smoothstep(0.075, 0.05, length(dot_uv - vec2(0.00, 0.0)));
	float dot2 = smoothstep(0.075, 0.05, length(dot_uv - vec2(0.18, 0.0)));
	float dot3 = smoothstep(0.075, 0.05, length(dot_uv - vec2(0.36, 0.0)));
	
	// Subtle CRT scanlines
	float scanline = sin(uv.y * 120.0 + TIME * 2.5) * 0.07 + 0.93;
	
	// Breathing neon pulse on active selection
	float pulse = is_selected ? (0.85 + 0.15 * sin(TIME * pulse_speed)) : 0.55;
	
	vec3 base = bg_color.rgb;
	// Window dots colors (Red, Yellow, Green)
	vec3 dots_col = vec3(0.0);
	dots_col += vec3(1.0, 0.25, 0.3) * dot1;
	dots_col += vec3(1.0, 0.85, 0.2) * dot2;
	dots_col += vec3(0.2, 1.0, 0.4) * dot3;
	
	base += dots_col * 1.6;
	base += vec3(0.35, 0.42, 0.52) * header_line * 0.35;
	
	// Bisel metálico oscuro del terminal (sin marcos blancos, rojos, azules o amarillos)
	vec3 metal_bezel = is_selected ? vec3(0.20, 0.25, 0.32) : vec3(0.10, 0.13, 0.17);
	base += metal_bezel * border * (is_selected ? 1.0 : 0.6);
	
	// Semi-transparent glass background
	float alpha = (bg_color.a + border * 0.40 + (dot1 + dot2 + dot3) * 0.55) * scanline;
	if (is_selected) {
		alpha = clamp(alpha + 0.15, 0.0, 0.92);
	}
	COLOR = vec4(base * scanline, clamp(alpha, 0.0, 1.0));
}
