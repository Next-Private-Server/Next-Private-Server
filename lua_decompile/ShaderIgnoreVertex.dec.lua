local shader = game.getShader("ShaderIgnoreVertex")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_additive.glsl")
  shader:setFragmentShaderSource("shaders/frag_no_vertex_color.glsl")
  shader:addFloatUniform("u_Brightness", 1)
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderIgnoreVertex", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
