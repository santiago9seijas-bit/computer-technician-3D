shader_type canvas_item;

// =============================================================================
// SHADER HOLOGRÁFICO SUTIL PARA PANELES Y FONDOS DE MENÚ
// DISEÑADO PARA SER ELEGANTE Y DE ALTA DEFINICIÓN SIN PROVOCAR MAREOS NI FATIGA
// =============================================================================

uniform vec4 holo_tint : source_color = vec4(0.9, 0.1, 0.5, 1.0); // Tinte Cyberpunk (Rojo Carmesí / Púrpura)
uniform vec4 edge_tint : source_color = vec4(0.4, 0.1, 0.9, 1.0); // Púrpura Eléctrico
uniform float scanline_density : hint_range(50.0, 400.0) = 140.0;
uniform float scanline_strength : hint_range(0.0, 0.25) = 0.06;   // Muy tenue para no fatigar la vista
uniform float pulse_speed : hint_range(0.2, 3.0) = 1.0;            // Respiración lenta y suave
uniform float pulse_amount : hint_range(0.0, 0.3) = 0.06;
uniform float scan_bar_speed : hint_range(0.05, 1.0) = 0.20;       // Haz láser que barre lentamente
uniform float scan_bar_intensity : hint_range(0.0, 0.3) = 0.08;
uniform float corner_glow : hint_range(0.0, 0.5) = 0.12;

void fragment() {
    vec4 base_color = texture(TEXTURE, UV);
    
    // Si el pixel es transparente en los bordes del marco, mantener transparencia
    if (base_color.a < 0.01) {
        discard;
    }
    
    vec3 col = base_color.rgb;
    
    // 1. Líneas de escaneo horizontales estáticas muy suaves (sin parpadeo brusco)
    float scanline = sin(UV.y * scanline_density * 6.28318) * 0.5 + 0.5;
    col -= vec3(scanline * scanline_strength);
    
    // 2. Haz de escaneo holográfico descendente suave
    float bar_pos = fract(TIME * scan_bar_speed);
    float bar_dist = abs(UV.y - bar_pos);
    float bar = smoothstep(0.06, 0.0, bar_dist) * scan_bar_intensity;
    col += mix(holo_tint.rgb, edge_tint.rgb, UV.y) * bar;
    
    // 3. Respiración holográfica sutil del marco
    float pulse = (sin(TIME * pulse_speed) * 0.5 + 0.5) * pulse_amount;
    col += holo_tint.rgb * pulse * (1.0 - base_color.r * 0.5);
    
    // 4. Resplandor sutil en las esquinas para sensación de holograma acristalado
    vec2 center_dist = abs(UV - vec2(0.5)) * 2.0;
    float vignette = pow(length(center_dist) * 0.65, 2.0) * corner_glow;
    col += edge_tint.rgb * vignette;

    COLOR = vec4(col, base_color.a);
}
