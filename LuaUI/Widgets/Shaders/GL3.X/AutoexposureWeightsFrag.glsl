uniform sampler2D scene;
uniform sampler2D weights;

uniform vec2 scale;

void main()
{
	// Get the weight
	vec2 uv = gl_TexCoord[0].st;
	float w = texture2D(weights, uv).r;

	// Get the pixel brighness
	vec2 UV = scale * (uv - vec2(0.5)) + vec2(0.5);
	vec3 color = texture2D(scene, UV).rgb;
	float l = 0.33 * (color.r + color.g + color.b);

	gl_FragColor = vec4(vec3(l * w), 1.0);
}
