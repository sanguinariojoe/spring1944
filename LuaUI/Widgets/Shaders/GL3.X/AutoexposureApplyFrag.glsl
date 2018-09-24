uniform sampler2D scene;
uniform sampler2D exposure;

void main()
{
	// Get the scene color
	vec2 uv = gl_TexCoord[0].st;
	vec4 color = texture2D(scene, uv);

	// Get the average brighness
	float exposureVal = 0.5 / texture2D(exposure, vec2(0.5, 0.5)).r;

	gl_FragColor = vec4(exposureVal * color.rgb, color.w);
}
