/* PBR rendering. See
 * https://github.com/KhronosGroup/glTF-WebGL-PBR/blob/master/shaders/pbr-frag.glsl
 */


//#define use_normalmapping
//#define flip_normalmap
//#define use_shadows

%%FRAGMENT_GLOBAL_NAMESPACE%%

uniform sampler2D textureS3o1;
uniform sampler2D textureS3o2;
uniform samplerCube specularTex;
uniform samplerCube reflectTex;

uniform vec3 sunPos; // is sunDir!
uniform vec3 sunDiffuse;
uniform vec3 sunAmbient;
uniform vec3 etcLoc;
#ifndef SPECULARMULT
    #define SPECULARMULT 1.0
#endif
#ifndef AMBIENTMULT
    #define AMBIENTMULT 0.5
#endif
#ifndef METALMULT
    #define METALMULT 1.0
#endif
#ifndef ROUGHNESSMULT
    #define ROUGHNESSMULT 0.8
#endif
#ifndef MINROUGHNESS
    #define MINROUGHNESS 0.04
#endif
#ifndef M_PI
    #define M_PI 3.141592653589793
#endif

#ifdef use_shadows
    uniform sampler2DShadow shadowTex;
    uniform float shadowDensity;
#endif
uniform vec4 teamColor;
varying vec3 cameraDir;
//varying float fogFactor;

#ifdef flashlights
    varying float selfIllumMod;
#endif

uniform sampler2D brdfLUT;

#ifdef use_normalmapping
    varying mat3 tbnMatrix;
    uniform sampler2D normalMap;
#else
    varying vec3 normalv;
#endif

// Encapsulate the various inputs used by the various functions in the shading equation
// We store values in this struct to simplify the integration of alternative implementations
// of the shading terms, outlined in the Readme.MD Appendix.
struct PBRInfo
{
    float NdotL;                  // cos angle between normal and light direction
    float NdotV;                  // cos angle between normal and view direction
    float NdotH;                  // cos angle between normal and half vector
    float LdotH;                  // cos angle between light direction and half vector
    float VdotH;                  // cos angle between view direction and half vector
    float perceptualRoughness;    // roughness value, as authored by the model creator (input to shader)
    float metalness;              // metallic value at the surface
    vec3 reflectance0;            // full reflectance color (normal incidence angle)
    vec3 reflectance90;           // reflectance color at grazing angle
    float alphaRoughness;         // roughness mapped to a more linear change in the roughness (proposed by [2])
    vec3 diffuseColor;            // color contribution from diffuse lighting
    vec3 specularColor;           // color contribution from specular lighting
};


float GetShadowCoeff(vec4 shadowCoors){
    #ifdef use_shadows
        float coeff = shadow2DProj(shadowTex, shadowCoors+vec4(0.0, 0.0, -0.00005, 0.0)).r;
        coeff  = (1.0 - coeff);
        coeff *= shadowDensity;
        return (1.0 - coeff);
    #else
        return 1.0;
    #endif
}

// Calculation of the lighting contribution from an optional Image Based Light source.
// Precomputed Environment Maps are required uniform inputs and are computed as outlined in [1].
// See our README.md on Environment Maps [3] for additional discussion.
vec3 getIBLContribution(PBRInfo pbrInputs, vec3 n, vec3 reflection)
{
    // retrieve a scale and bias to F0. See [1], Figure 3
    vec3 brdf = texture2D(brdfLUT, vec2(pbrInputs.NdotV, 1.0 - pbrInputs.perceptualRoughness)).rgb;
    vec3 diffuseLight = textureCube(specularTex, n).rgb;

#ifdef USE_TEX_LOD
    float mipCount = 9.0; // resolution of 512x512
    float lod = (pbrInputs.perceptualRoughness * mipCount);
    vec3 specularLight = textureCubeLodEXT(reflectTex, reflection, lod).rgb;
#else
    vec3 specularLight = textureCube(reflectTex, reflection).rgb;
#endif

    vec3 diffuse = diffuseLight * pbrInputs.diffuseColor;
    vec3 specular = specularLight * (pbrInputs.specularColor * brdf.x + brdf.y);

    return diffuse + specular;
}

// Basic Lambertian diffuse
// Implementation from Lambert's Photometria https://archive.org/details/lambertsphotome00lambgoog
// See also [1], Equation 1
vec3 diffuse(PBRInfo pbrInputs)
{
    // return pbrInputs.diffuseColor / M_PI;
    return pbrInputs.diffuseColor;
}

// The following equation models the Fresnel reflectance term of the spec equation (aka F())
// Implementation of fresnel from [4], Equation 15
vec3 specularReflection(PBRInfo pbrInputs)
{
    return pbrInputs.reflectance0 + (pbrInputs.reflectance90 - pbrInputs.reflectance0) * pow(clamp(1.0 - pbrInputs.VdotH, 0.0, 1.0), 5.0);
}

// This calculates the specular geometric attenuation (aka G()),
// where rougher material will reflect less light back to the viewer.
// This implementation is based on [1] Equation 4, and we adopt their modifications to
// alphaRoughness as input as originally proposed in [2].
float geometricOcclusion(PBRInfo pbrInputs)
{
    float NdotL = pbrInputs.NdotL;
    float NdotV = pbrInputs.NdotV;
    float r = pbrInputs.alphaRoughness;

    float attenuationL = 2.0 * NdotL / (NdotL + sqrt(r * r + (1.0 - r * r) * (NdotL * NdotL)));
    float attenuationV = 2.0 * NdotV / (NdotV + sqrt(r * r + (1.0 - r * r) * (NdotV * NdotV)));
    return attenuationL * attenuationV;
}

// The following equation(s) model the distribution of microfacet normals across the area being drawn (aka D())
// Implementation from "Average Irregularity Representation of a Roughened Surface for Ray Reflection" by T. S. Trowbridge, and K. P. Reitz
// Follows the distribution function recommended in the SIGGRAPH 2013 course notes from EPIC Games [1], Equation 3.
float microfacetDistribution(PBRInfo pbrInputs)
{
    float roughnessSq = pbrInputs.alphaRoughness * pbrInputs.alphaRoughness;
    float f = (pbrInputs.NdotH * roughnessSq - pbrInputs.NdotH) * pbrInputs.NdotH + 1.0;
    return roughnessSq / (M_PI * f * f);
}              

float beckmannDistribution(float x, float roughness)
{
    float NdotH = max(x, 0.0001);
    float cos2Alpha = NdotH * NdotH;
    float tan2Alpha = (cos2Alpha - 1.0) / cos2Alpha;
    float roughness2 = roughness * roughness;
    float denom = 3.141592653589793 * roughness2 * cos2Alpha * cos2Alpha;
    return exp(tan2Alpha / roughness2) / denom;
}

float cookTorranceSpecular(vec3 lightDirection,
                            vec3 viewDirection,
                            vec3 surfaceNormal,
                            float roughness,
                            float fresnel)
{
    float VdotN = max(dot(viewDirection, surfaceNormal), 0.0);
    float LdotN = max(dot(lightDirection, surfaceNormal), 0.0);

    //Half angle vector
    vec3 H = normalize(lightDirection + viewDirection);

    //Geometric term
    float NdotH = max(dot(surfaceNormal, H), 0.0);
    float VdotH = max(dot(viewDirection, H), 0.000001);
    float x = 2.0 * NdotH / VdotH;
    float G = min(1.0, min(x * VdotN, x * LdotN));

    //Distribution term
    float D = beckmannDistribution(NdotH, roughness);

    //Fresnel term
    float F = pow(1.0 - VdotN, fresnel);

    //Multiply terms and done
    return  G * F * D / max(3.14159265 * VdotN * LdotN, 0.000001);
}

void main(void){
    %%FRAGMENT_PRE_SHADING%%

    // Extract the data from unit textures
    vec4 baseColor = texture2D(textureS3o1, gl_TexCoord[0].st);
    vec4 extraColor = texture2D(textureS3o2, gl_TexCoord[0].st);
    #ifdef flashlights
        extraColor.r =extraColor.r * selfIllumMod;
    #endif
    #ifdef use_normalmapping
        vec2 tc = gl_TexCoord[0].st;
        #ifdef flip_normalmap
            tc.t = 1.0 - tc.t;
        #endif
        vec4 normaltex=texture2D(normalMap, tc);
        vec3 nvTS   = (normaltex.xyz - 0.5) * 2.0;
        vec3 normal = normalize(tbnMatrix * nvTS);
    #else
        vec3 normal = normalize(normalv);
    #endif

    // Team color
    baseColor.rgb = mix(baseColor.rgb, teamColor.rgb, baseColor.a);
    // The alpha channel is actually stored in extra color
    baseColor.a = extraColor.a;

    // Compute the shadow
    float shadow = GetShadowCoeff(gl_TexCoord[1] + vec4(0.0, 0.0, -0.00005, 0.0));

    #if (deferred_mode == 1)
        vec3 specular   = vec3(shadow * extraColor.g * SPECULARMULT);
        vec3 reflection = vec3(0.0);

        gl_FragData[0] = vec4((normal + 1.0) * 0.5, extraColor.a);
        gl_FragData[1] = baseColor;
        gl_FragData[2] = vec4(specular, extraColor.a);
        gl_FragData[3] = vec4(extraColor.rrr, 1.0);
    #else
        // Get the metal attributes
        float perceptualRoughness = (1.0 - extraColor.g) * ROUGHNESSMULT;
        float metallic = extraColor.b * METALMULT;
        perceptualRoughness = clamp(perceptualRoughness, MINROUGHNESS, 1.0);
        // Roughness is authored as perceptual roughness; as is convention,
        // convert to material roughness by squaring the perceptual roughness [2].
        float alphaRoughness = perceptualRoughness * perceptualRoughness;

        vec3 f0 = vec3(0.04);
        vec3 diffuseColor = baseColor.rgb * (vec3(1.0) - f0);
        diffuseColor *= 1.0 - metallic;
        vec3 specularColor = mix(f0, baseColor.rgb, metallic);

        // Compute reflectance.
        float reflectance = max(max(specularColor.r, specularColor.g), specularColor.b);

        // For typical incident reflectance range (between 4% to 100%) set the grazing reflectance to 100% for typical fresnel effect.
        // For very low reflectance range on highly diffuse objects (below 4%), incrementally reduce grazing reflecance to 0%.
        // float reflectance90 = clamp(reflectance * 25.0, 0.0, 1.0);
        float reflectance90 = reflectance;
        vec3 specularEnvironmentR0 = specularColor.rgb;
        vec3 specularEnvironmentR90 = vec3(1.0) * reflectance90;

        vec3 n = normal;
        vec3 v = -normalize(cameraDir);
        vec3 l = sunPos;
        vec3 h = normalize(l+v);
        vec3 r = -normalize(reflect(v, n));

        float NdotL = clamp(dot(n, l), 0.001, 1.0);
        float NdotV = clamp(abs(dot(n, v)), 0.001, 1.0);
        float NdotH = clamp(dot(n, h), 0.0, 1.0);
        float LdotH = clamp(dot(l, h), 0.0, 1.0);
        float VdotH = clamp(dot(v, h), 0.0, 1.0);

        PBRInfo pbrInputs = PBRInfo(
            NdotL,
            NdotV,
            NdotH,
            LdotH,
            VdotH,
            perceptualRoughness,
            metallic,
            specularEnvironmentR0,
            specularEnvironmentR90,
            alphaRoughness,
            diffuseColor,
            specularColor
        );

        // Calculate the shading terms for the microfacet specular shading model
        vec3 F = specularReflection(pbrInputs);
        float G = geometricOcclusion(pbrInputs);
        float D = microfacetDistribution(pbrInputs);

        // Calculation of analytical lighting contribution
        vec3 diffuseContrib = (1.0 - F) * diffuse(pbrInputs);
        vec3 specContrib = F * G * D / (4.0 * NdotL * NdotV);

        // Obtain final intensity as reflectance (BRDF) scaled by the energy of the light (cosine law)
        vec3 color = NdotL * sunDiffuse * (diffuseContrib + specContrib);

        // Image based Lighting
        color += getIBLContribution(pbrInputs, n, r);

        // Shadows
        color *= shadow;

        // Ambient illumination
        color += baseColor.rgb * sunAmbient * AMBIENTMULT;

        // self-illumination
        color += extraColor.rrr;

        // Final color
        gl_FragColor = vec4(color, baseColor.a);
    #endif

    %%FRAGMENT_POST_SHADING%%
}
