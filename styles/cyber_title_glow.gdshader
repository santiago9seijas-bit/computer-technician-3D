shader_type canvas_item;

// Holographic Cyber Title Shader con Borde Negro Nítido
// Mantiene las animaciones de brillo láser y pulso con máxima legibilidad

uniform vec4 top_color : source_color = vec4(1.0, 0.18, 0.28, 1.0);     // Rojo carmesí
uniform vec4 mid_color : source_color = vec4(1.0, 0.45, 0.75, 1.0);     // Fucsia brillante
uniform vec4 bottom_color : source_color = vec4(0.75, 0.08, 0.95, 1.0);  // Morado neón
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);    // Borde negro profundo
uniform float outline_thickness = 1.8;
uniform float shine_speed = 0.55;
uniform float glitch_intensity = 0.6;

void fragment() {
	vec2 uv = UV;
	
	// Glitch periódico sutil cada ~3.5 segundos
	float t = TIME;
	float glitch_trigger = step(0.94, sin(t * 1.8) * sin(t * 0.7));
	float glitch_offset = sin(uv.y * 60.0 + t * 40.0) * 0.005 * glitch_trigger * glitch_intensity;
	vec2 glitched_uv = uv + vec2(glitch_offset, 0.0);
	
	// Textura base de la fuente
	float a = texture(TEXTURE, glitched_uv).a;
	if (a < 0.01) {
		discard;
	}
	
	// Detección de silueta interna vs borde:
	// Muestreamos en 8 direcciones alrededor para determinar si estamos cerca del borde exterior
	vec2 px = TEXTURE_PIXEL_SIZE * outline_thickness;
	float a_min = a;
	a_min = min(a_min, texture(TEXTURE, glitched_uv + vec2( px.x, 0.0)).a);
	a_min = min(a_min, texture(TEXTURE, glitched_uv + vec2(-px.x, 0.0)).a);
	a_min = min(a_min, texture(TEXTURE, glitched_uv + vec2(0.0,  px.y)).a);
	a_min = min(a_min, texture(TEXTURE, glitched_uv + vec2(0.0, -px.y)).a);
	a_min = min(a_min, texture(TEXTURE, glitched_uv + vec2( px.x,  px.y)).a);
	a_min = min(a_min, texture(TEXTURE, glitched_uv + vec2(-px.x,  px.y)).a);
	a_min = min(a_min, texture(TEXTURE, glitched_uv + vec2( px.x, -px.y)).a);
	a_min = min(a_min, texture(TEXTURE, glitched_uv + vec2(-px.x, -px.y)).a);
	
	// a_min será cercano a 0 en el contorno exterior del texto y 1 en el interior
	float is_interior = smoothstep(0.2, 0.8, a_min);
	
	// Separación cromática sutil en los canales para el interior
	float r = texture(TEXTURE, glitched_uv + vec2(0.002 * glitch_trigger, 0.0)).r;
	float g = texture(TEXTURE, glitched_uv).g;
	float b = texture(TEXTURE, glitched_uv - vec2(0.002 * glitch_trigger, 0.0)).b;
	
	// Gradiente tricromático vertical para el interior (Rojo -> Fucsia -> Morado)
	vec3 grad = mix(top_color.rgb, mid_color.rgb, smoothstep(0.0, 0.45, uv.y));
	grad = mix(grad, bottom_color.rgb, smoothstep(0.45, 1.0, uv.y));
	
	// Barrido de brillo láser que recorre el texto
	float shine_pos = mod(t * shine_speed, 1.5) - 0.25;
	float shine_dist = abs((uv.x * 0.7 + uv.y * 0.3) - shine_pos);
	float shine = smoothstep(0.12, 0.0, shine_dist) * 0.75;
	
	vec3 body_color = (grad * vec3(r, g, b) + vec3(1.0, 0.4, 0.7) * (shine * 0.85));
	
	// Pulso de respiración en el cuerpo
	float pulse = 0.95 + 0.05 * sin(t * 3.0);
	body_color *= pulse;
	
	// Mezcla perfecta: Borde negro azabache exterior (outline_color) y cuerpo holográfico interior
	vec3 final_color = mix(outline_color.rgb, body_color, is_interior);
	
	COLOR = vec4(final_color, a);
}
