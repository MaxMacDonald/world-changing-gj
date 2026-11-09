shader_type canvas_item;

uniform vec3 shock_color : source_color = vec3(1.0, 0.0, 0.0);
uniform float amplitude = 30.0;
uniform float frequency = 10.0;
uniform float duration = 3.0;
uniform float start_time = -100.0;

void vertex() {
	float t = clamp(TIME - start_time, 0.0, duration);
	VERTEX.x += amplitude * exp(-3.0 * t) * cos(frequency * t);
}

void fragment() {
	float t = clamp(TIME - start_time, 0.0, duration);
	vec3 normal_color = texture(TEXTURE, UV).rgb;
	COLOR.rgb = normal_color + shock_color * exp(-3.0 * t);
}