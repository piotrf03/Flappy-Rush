shader_type canvas_item;

// Prosty pionowy gradient nieba (od ciemniejszego u góry do jaśniejszego przy horyzoncie)
void fragment() {
	float y = UV.y;
	vec3 top = vec3(0.20, 0.45, 0.85);
	vec3 mid = vec3(0.36, 0.62, 0.96);
	vec3 bot = vec3(0.70, 0.88, 1.0);
	vec3 col;
	if (y < 0.6) {
		col = mix(top, mid, y / 0.6);
	} else {
		col = mix(mid, bot, (y - 0.6) / 0.4);
	}
	COLOR = vec4(col, 1.0);
}
