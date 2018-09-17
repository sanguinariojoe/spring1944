return {
  vertex = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\GL3.X\\UnitShaderVert.glsl", VFS.ZIP),
  fragment = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\GL3.X\\UnitShaderFrag.glsl", VFS.ZIP),
  uniformInt = {
    textureS3o1 = 0,
    textureS3o2 = 1,
    shadowTex   = 2,
    specularTex = 3,
    reflectTex  = 4,
    brdfLUT     = 5,
    normalMap   = 6,
    --detailMap   = 6,
  },
  uniform = {
    -- sunPos = {gl.GetSun("pos")}, -- material has sunPosLoc
    sunAmbient = {gl.GetSun("ambient" ,"unit")},
    sunDiffuse = {gl.GetSun("diffuse" ,"unit")},
    shadowDensity = {gl.GetSun("shadowDensity" ,"unit")},
    -- shadowParams  = {gl.GetShadowMapParams()}, -- material has shadowParamsLoc
  },
  uniformMatrix = {
    -- shadowMatrix = {gl.GetMatrixData("shadow")}, -- material has shadow{Matrix}Loc
  },
}
