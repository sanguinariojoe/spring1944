#version 410 core

#define GBUFFER_NORMTEX_IDX 0
#define GBUFFER_DIFFTEX_IDX 1
#define GBUFFER_SPECTEX_IDX 2
#define GBUFFER_EMITTEX_IDX 3
#define GBUFFER_MISCTEX_IDX 4
#define SMF_FRAGDATA_COUNT 6

#ifdef DEFERRED_MODE
layout(location = 0) out vec4 fragData[SMF_FRAGDATA_COUNT];
#else
layout(location = 0) out vec4 fragColor;
#endif

void main() {
    #ifdef DEFERRED_MODE
    fragData[GBUFFER_NORMTEX_IDX] = vec4(1.0);
    fragData[GBUFFER_DIFFTEX_IDX] = vec4(1.0);
    fragData[GBUFFER_SPECTEX_IDX] = vec4(1.0);
    fragData[GBUFFER_EMITTEX_IDX] = vec4(1.0);
    fragData[GBUFFER_MISCTEX_IDX] = vec4(1.0);
    #else
    fragColor = vec4(1.0);
    #endif
}

