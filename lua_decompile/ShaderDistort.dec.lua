local shader = game.getShader("ShaderDistort")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_additive.glsl")
  shader:setFragmentShaderSource("shaders/frag_wavy.glsl")
  shader:addTimeUniform()
  shader:addFloatUniform("u_Speed", 0.15)
  shader:addFloatUniform("u_Frequency", 12)
  shader:addFloatUniform("u_Power", 0.005)
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderDistort", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
