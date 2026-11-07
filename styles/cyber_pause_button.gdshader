shader_type canvas_item;

// Shader cibernético carmesí táctico para los botones del Menú de Pausa
uniform float idle_alpha : hint_range(0.0, 1.0) = 0.55;
uniform float hover_alpha : hint_range(0.0, 1.0) = 0.85;
uniform float scanline_speed : hint_range(0.1, 10.0) = 3.5;
uniform float chromatic_shift : hint_range(0.0, 5.0) = 2.0;
uniform vec4 border_glow_color : source_color = vec4(1.0, 0.12, 0.25, 1.0);
uniform vec4 inner_gradient_top : source_color = vec4(0.20, 0.01, 0.06, 0.90);
uniform vec4 inner_gradient_bottom : source_color = vec4(0.05, 0.005, 0.02, 0.95);

void fragment() {
	vec2 uv = UV;
	
	// Aberración cromática en los canales
	vec2 offset = vec2(chromatic_shift / 380.0, 0.0);
	float r = texture(TEXTURE, uv + offset).r;
	float g = texture(TEXTURE, uv).g;
	float b = texture(TEXTURE, uv - offset).b;
	float a = texture(TEXTURE, uv).a;
	
	if (a < 0.01) {
		discard;
	}
	
	vec3 base_color = vec3(r, g, b);
	float lum = dot(base_color, vec3(0.299, 0.587, 0.114));
	
	// Detectar borde del botón pixel art
	bool is_border = (base_color.r > 0.55 && base_color.g < 0.45);
	bool is_hover_body = (!is_border && lum > 0.5);
	bool is_idle_body = (!is_border && lum <= 0.5);
	
	vec3 final_color = base_color;
	float final_alpha = a;
	
	if (is_idle_body) {
		// Degradado cristalino carmesí oscuro
		vec3 body_grad = mix(inner_gradient_top.rgb, inner_gradient_bottom.rgb, uv.y);
		// Scanlines horizontales tácticas
		float scan = sin(uv.y * 60.0 - TIME * scanline_speed) * 0.5 + 0.5;
		body_grad += vec3(0.9, 0.1, 0.2) * scan * 0.18;
		
		// Franjas diagonales cibernéticas sutiles
		float diag = sin((uv.x + uv.y) * 25.0 - TIME * 1.5) * 0.5 + 0.5;
		body_grad += vec3(0.4, 0.02, 0.08) * diag * 0.15;
		
		final_color = body_grad;
		final_alpha = a * idle_alpha;
	}
	else if (is_hover_body) {
		// Estado Hover: plasma carmesí ardiente con barrido de luz
		float sweep = sin((uv.x * 2.0 - uv.y) * 3.5 - TIME * 5.0) * 0.5 + 0.5;
		vec3 plasma = mix(vec3(0.5, 0.02, 0.12), vec3(1.0, 0.15, 0.35), sweep);
		plasma = mix(plasma, vec3(1.0, 0.5, 0.6), (1.0 - uv.y) * 0.35 + sweep * 0.25);
		
		final_color = plasma;
		final_alpha = a * hover_alpha;
	}
	else if (is_border) {
		// Borde exterior: pulso de neón rojo vivo
		float pulse = sin(TIME * 4.0) * 0.5 + 0.5;
		final_color = mix(border_glow_color.rgb, vec3(1.0, 0.4, 0.5), pulse * 0.4);
		final_alpha = a * (0.85 + pulse * 0.15);
	}
	
	COLOR = vec4(final_color, final_alpha);
}
