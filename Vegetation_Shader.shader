shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_alpha_prepass, specular_disabled;

uniform bool debug = false;
uniform bool transparent = true;
uniform bool texture_rotation = true;
uniform sampler2D albedo : hint_albedo;
uniform vec4 albedo_color : hint_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float wind_strength : hint_range(0.0, 5.0)= 0.5;
uniform float wind_speed = 1.0;
uniform float wind_scale : hint_range(1.0, 20.0) = 1.0;
uniform float wind_density = 3.0;
uniform float transmission_strength : hint_range(0.0, 1.0) = 0.2;
uniform float alpha_scissors : hint_range(0.0, 1.0) = 0.5;
uniform vec4 highlight : hint_color = vec4(0.5, 0.5, 0.5,  1.0);

varying float offset;

void vertex()
{
	vec3 v = VERTEX; 
	vec3 world_pos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;	//Generates world coordinates for vertecies
	
	offset = fract((-world_pos.x + world_pos.z) * (1.0 / wind_scale) + (TIME * wind_speed));	//Generates linear curve that slides along vertecies in world space
	offset = min(1.0 - offset, offset);														//Makes generated curve a smooth gradient
	offset = (1.0 - offset) * offset * 2.0;													//Smoothes gradient further
	
	float t = TIME + sin(TIME + offset + cos(TIME + offset * wind_strength * 2.0) * wind_strength); //Generates noise in world space value
	
	float mask = fract(v.y * wind_density) * v.y;	//Generates vertical mask, so leaves on top move further than leaves on bottom
	mask = clamp(mask, 0.0, 1.0);					//Clamps mask
	
	float si = sin(t) / 20.0 * wind_strength * offset;	//Generates clamped noise, adds strength, applies gradient mask
	float csi = cos(t)/ 20.0 * wind_strength * offset;	//Generates clamped noise with offset, adds strength, applies gradient mask
	
	VERTEX += vec3(v.x * si * mask, v.y * si * mask, v.z * csi * mask);
	COLOR = vec4(fract(t));
}

void fragment()
{
	vec2 altUV = UV;
	
	float strength = mix(60.0, 80.0, 1.0 - wind_strength);
	float rot = 3.14159 / strength * sin(TIME + offset * wind_strength * 2.0);
	
	altUV -= 0.5;
	mat2 m = mat2(vec2(cos(rot), -sin(rot)), vec2(sin(rot), cos(rot)));
	
	altUV = m * altUV;
	altUV += 0.5;
	
	vec4 diff = texture(albedo, UV);
	
	if(texture_rotation)
		diff = texture(albedo, altUV);
	
	ALBEDO = diff.rgb * albedo_color.rgb;
	if(transparent)
		ALPHA = diff.a;
		ALPHA_SCISSOR = alpha_scissors;
	TRANSMISSION = ALBEDO * transmission_strength;
	EMISSION = highlight.rgb * highlight.a;
	
	if(debug)
		ALBEDO = COLOR.rgb;
}