local shader = game.getShader("ShaderClubboxLightspeed")
if shader == nil then
  print("=== Creating Clubbox Lightspeed Shader")
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_normal.glsl")
  shader:setFragmentShaderSource("shaders/frag_clubbox_lightspeed.glsl")
  shader:addResolutionUniform()
  shader:addTimeUniform()
  shader:addFloatUniform("u_Offset", 0)
  shader:addFloatUniform("u_Speed", 0)
  shader:addFloatUniform("u_Brightness", 0)
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderClubboxLightspeed", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
