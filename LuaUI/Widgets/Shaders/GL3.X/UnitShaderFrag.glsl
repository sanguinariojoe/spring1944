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

#ifdef use_normalmapping
    varying mat3 tbnMatrix;
    uniform sampler2D normalMap;
#else
    varying vec3 normalv;
#endif

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


%%PBR_INCLUDE%%


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
        color += getIBLContribution(pbrInputs, n, r, specularTex, reflectTex);

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
