local shader = game.getShader("ShaderClubboxMemory")
if shader == nil then
  print("=== Creating Clubbox Memory Shader")
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_normal.glsl")
  shader:setFragmentShaderSource("shaders/frag_clubbox_memory.glsl")
  shader:addVec2Uniform("u_MaxUV", game.displayMaxUV())
  shader:addFloatUniform("u_Intensity", 0.75)
  shader:addFloatUniform("u_Random", 1)
  shader:addTimeUniform()
  shader:addResolutionUniform()
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderClubboxMemory", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
