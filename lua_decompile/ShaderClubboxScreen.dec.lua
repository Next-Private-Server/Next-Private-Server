local clubbox = game.clubboxContext()
if not clubbox then
  return nil
end
game.putShader("ShaderClubboxScreen", nil)
local shader = game.getShader("ShaderClubboxScreen")
local sheetW, sheetH = 512, 256
local quadW, quadH = 412, 140
local offsetX, offsetY = 0, 0
local function getSpriteBounds()
  return lua_sys.Vector4(offsetX / sheetW, offsetY / sheetH, quadW / sheetW, (offsetY + quadH) / sheetH)
end
local function getAspectCorrection()
  local quadAR = quadW / quadH
  local gameAR = lua_sys.screenWidth() / lua_sys.screenHeight()
  local scaleX, scaleY = 1, 1
  if quadAR < gameAR then
    scaleX = quadAR / gameAR
  else
    scaleY = gameAR / quadAR
  end
  return scaleX, scaleY
end
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_additive.glsl")
  shader:setFragmentShaderSource("shaders/frag_clubbox_screen.glsl")
  clubbox:InitWubCam()
  local wubCam = clubbox:GetWubCam()
  wubCam:addRenderTargetToShader(shader, "u_RenderTexture", 2)
  shader:addVec2Uniform("u_MaxUV", game.displayMaxUV())
  shader:addVec4Uniform("u_SpriteBounds", getSpriteBounds())
  local sX, sY = getAspectCorrection()
  shader:addVec4Uniform("u_AspectCorrection", lua_sys.Vector4(sX, sY, 0.5, 0.5))
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderClubboxScreen", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
else
  shader:getUniform("u_SpriteBounds"):setVec4(getSpriteBounds())
  local sX, sY = getAspectCorrection()
  shader:getUniform("u_AspectCorrection"):setVec4(lua_sys.Vector4(sX, sY, 0.5, 0.5))
end
return shader
