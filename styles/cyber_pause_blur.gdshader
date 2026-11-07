shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 2.6;
uniform vec4 dim_color : source_color = vec4(0.03, 0.01, 0.07, 0.76);

void fragment() {
	vec4 col = textureLod(screen_texture, SCREEN_UV, blur_amount);
	// Aberración cromática sutil en los bordes
	vec2 offset = vec2(0.0018, 0.0);
	float r = textureLod(screen_texture, SCREEN_UV + offset, blur_amount).r;
	float b = textureLod(screen_texture, SCREEN_UV - offset, blur_amount).b;
	col.r = r;
	col.b = b;
	// Mezcla con el oscurecimiento
	COLOR = mix(col, dim_color, dim_color.a);
}
