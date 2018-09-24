uniform sampler2D brighness;
uniform sampler2D prevExposure;

uniform float changeRate;

void main()
{
	float avgBrightness = clamp(texture2D(brighness, vec2(0.5, 0.5)).r, 0.3, 0.7);
	float exposure = texture2D(prevExposure, vec2(0.5, 0.5)).r;
	gl_FragColor = vec4(vec3(lerp(exposure, avgBrightness, changeRate)), 1.0);
}
