local shader = game.getShader("ShaderCostumeAB3")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_additive.glsl")
  shader:setFragmentShaderSource("shaders/frag_wavy.glsl")
  shader:addTimeUniform()
  shader:addFloatUniform("u_Speed", 0.25)
  shader:addFloatUniform("u_Frequency", 24)
  shader:addFloatUniform("u_Power", 0.01)
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderCostumeAB3", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
