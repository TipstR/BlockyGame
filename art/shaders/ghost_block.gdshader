shader_type spatial;

void fragment() {
	ALPHA = abs(0.3 * sin(TIME));
}
