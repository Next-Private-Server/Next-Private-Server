local shader = game.getShader("ShaderOutline")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_normal.glsl")
  shader:setFragmentShaderSource("shaders/frag_outline.glsl")
  shader:addColorUniform("tintA")
  shader:addColorUniform("tintB")
  shader:addTimeUniform()
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderOutline", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
