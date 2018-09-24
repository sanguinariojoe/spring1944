uniform sampler2D sample;

uniform float sizeinv;

void main()
{
	vec2 uv = gl_TexCoord[0].st;

	float l = 0.0;
	for (unsigned int i = 0; i < 2; i++) {
		for (unsigned int j = 0; j < 2; j++) {
			l += texture2D(sample, uv + vec2(((float)(i) - 0.5) * sizeinv,
			                                 ((float)(i) - 0.5) * sizeinv)).r;
		}
	}

	gl_FragColor = vec4(vec3(0.25 * l), 1.0);
}
