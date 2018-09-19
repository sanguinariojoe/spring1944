-- $Id$
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local SHADER_DIR = "ModelMaterials/Shaders/"

local materials = {
    normalMapped = {
        shaderDefinitions = {
            "#define use_perspective_correct_shadows",
            "#define use_normalmapping",
            "#define deferred_mode 0",
            "#define SPECULARMULT 1.0",
            --"#define flip_normalmap",
        },
        deferredDefinitions = {
            "#define use_perspective_correct_shadows",
            "#define use_normalmapping",
            "#define deferred_mode 1",
            "#define SPECULARMULT 1.0",
        },
        shaderPlugins = {
            PBR_INCLUDE = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\GL3.X\\pbr.inc.glsl", VFS.ZIP),
        },
        deferredPlugins = {
            PBR_INCLUDE = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\GL3.X\\pbr.inc.glsl", VFS.ZIP),
        },
        shader    = include(SHADER_DIR .. "default.lua"),
        deferred  = include(SHADER_DIR .. "default.lua"), 
        usecamera = false,
        culling   = GL.BACK,
        predl  = nil,
        postdl = nil,
        feature = true,
        texunits  = {
            [0] = '%%FEATUREDEFID:0',
            [1] = '%%FEATUREDEFID:1',
            [2] = '$shadow',
            [3] = '$specular',
            [4] = '$reflection',
            [5] = 'unittextures/brdfLUT.png',
            [6] = '%NORMALTEX',
        },
    },
    normalModelled = {
        shaderDefinitions = {
            "#define use_perspective_correct_shadows",
            --"#define use_normalmapping",
            "#define deferred_mode 0",
            "#define SPECULARMULT 1.0",
            --"#define flip_normalmap",
        },
        deferredDefinitions = {
            "#define use_perspective_correct_shadows",
            --"#define use_normalmapping",
            "#define deferred_mode 1",
            "#define SPECULARMULT 1.0",
        },
        shaderPlugins = {
            PBR_INCLUDE = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\GL3.X\\pbr.inc.glsl", VFS.ZIP),
        },
        deferredPlugins = {
            PBR_INCLUDE = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\GL3.X\\pbr.inc.glsl", VFS.ZIP),
        },
        shader    = include(SHADER_DIR .. "default.lua"),
        deferred  = include(SHADER_DIR .. "default.lua"), 
        usecamera = false,
        culling   = GL.BACK,
        predl  = nil,
        postdl = nil,
        feature = true,
        texunits  = {
            [0] = '%%FEATUREDEFID:0',
            [1] = '%%FEATUREDEFID:1',
            [2] = '$shadow',
            [3] = '$specular',
            [4] = '$reflection',
            [5] = 'unittextures/brdfLUT.png',
        },
    },
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local unitMaterials = {}

for i, udef in pairs(FeatureDefs) do
  local modeltype = udef.modeltype or udef.model.type
  if (udef.customParams.normaltex and VFS.FileExists(udef.customParams.normaltex)) then
    unitMaterials[udef.name] = {"normalMapped", NORMALTEX = udef.customParams.normaltex}
  else
    unitMaterials[udef.name] = {"normalModelled"}
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return materials, unitMaterials

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
