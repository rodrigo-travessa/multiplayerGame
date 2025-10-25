shader_type canvas_item;

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 color = texture(TEXTURE, UV + vec2(.1 * TIME, .2 * TIME));
	//vec4 color = vec4(0.3, 0.2, 0.7, 0.5);
	COLOR = color;
}
