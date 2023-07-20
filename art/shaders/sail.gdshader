shader_type spatial;

render_mode cull_disabled, depth_prepass_alpha;

uniform vec4 color : source_color;

uniform sampler2D sail_texture : source_color;
uniform sampler2D normalmap_texture : hint_normal;
uniform sampler2D noise_texture : hint_default_black;

uniform float speed = 0.1;
uniform float noiseStrength = 0.2;
uniform float windStrength = 1.0;
uniform float sail_size_x = 1.0;
uniform float sail_size_y = 1.0;

void vertex() {
	vec2 scaled_uv = UV * vec2(0.5);
	float noise = texture(noise_texture, scaled_uv + vec2(TIME * speed, 0.0)).r; 
	
	float displacement = (noise * 2.0 - 1.0) * noiseStrength;
	displacement *= UV.x;
	
	
	VERTEX.z = windStrength * cos((VERTEX.x * (PI / sail_size_x))) + windStrength * cos((VERTEX.y * (PI / sail_size_y)));
	VERTEX += vec3(0.0, 0.0, displacement);
}

void fragment() {
	// Place fragment code here.
}
