//#define use_normalmapping
//#define flip_normalmap
//#define use_shadows
%%VERTEX_GLOBAL_NAMESPACE%%

uniform mat4 camera;   //ViewMatrix (gl_ModelViewMatrix is ModelMatrix!)
uniform vec3 cameraPos;
uniform vec3 sunPos;
uniform vec3 sunDiffuse;
uniform vec3 sunAmbient;
uniform vec3 etcLoc;
uniform int simFrame;
#ifdef flashlights
	varying float selfIllumMod;
#endif
//uniform float frameLoc;

#ifdef use_treadoffset
	uniform float treadOffset;
#endif

//The api_custom_unit_shaders supplies this definition:
#ifdef use_shadows  
	uniform mat4 shadowMatrix;
	uniform vec4 shadowParams;
#endif

varying vec3 cameraDir;

#ifdef use_normalmapping
	varying mat3 tbnMatrix;
#else
	varying vec3 normalv;
#endif

void main(void)
{
	vec4 vertex = gl_Vertex;
	vec3 normal = gl_Normal;
	
	%%VERTEX_PRE_TRANSFORM%%

	#ifdef use_normalmapping
		vec3 tangent   = gl_MultiTexCoord5.xyz;
		vec3 bitangent = gl_MultiTexCoord6.xyz;
		tbnMatrix = gl_NormalMatrix * mat3(tangent, bitangent, normal);
	#else
		normalv = gl_NormalMatrix * normal;
	#endif

	vec4 worldPos = gl_ModelViewMatrix * vertex;
	gl_Position   = gl_ProjectionMatrix * (camera * worldPos);
	cameraDir     = worldPos.xyz - cameraPos;

	#ifdef use_shadows
		gl_TexCoord[1] =shadowMatrix *gl_ModelViewMatrix*gl_Vertex;
		gl_TexCoord[1].st = gl_TexCoord[1].st * (inversesqrt( abs(gl_TexCoord[1].st) + shadowParams.z) + shadowParams.w) + shadowParams.xy;
	#endif
	#ifdef use_treadoffset
		gl_TexCoord[0].st = gl_MultiTexCoord0.st;
		if (gl_MultiTexCoord0.s < 0.74951171875 && gl_MultiTexCoord0.s > 0.6279296875 && gl_MultiTexCoord0.t > 0.5702890625 && gl_MultiTexCoord0.t <0.6220703125){
			gl_TexCoord[0].s = gl_MultiTexCoord0.s + etcLoc.z;
		}
	#endif

	#ifndef use_treadoffset
		gl_TexCoord[0].st = gl_MultiTexCoord0.st;
	#endif
	
	#ifdef flashlights
		//float unique_value = sin((gl_ModelViewMatrix[3][0]+gl_ModelViewMatrix[3][2])));
		selfIllumMod = max(-0.2,sin(simFrame *0.063 + (gl_ModelViewMatrix[3][0]+gl_ModelViewMatrix[3][2])*0.1))+0.2;
	#endif
	//float fogCoord = length(gl_Position.xyz); // maybe fog should be readded?
	//fogFactor = (gl_Fog.end - fogCoord) * gl_Fog.scale; //gl_Fog.scale := 1.0 / (gl_Fog.end - gl_Fog.start)
	//fogFactor = clamp(fogFactor, 0.0, 1.0);

	%%VERTEX_POST_TRANSFORM%%
}
