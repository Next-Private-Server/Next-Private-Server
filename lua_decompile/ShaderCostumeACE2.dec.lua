local shader = game.getShader("ShaderCostumeACE2")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_additive.glsl")
  shader:setFragmentShaderSource("shaders/frag_costume_ace2.glsl")
  shader:addTimeUniform()
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderCostumeACE2", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
