local shader = game.getShader("ShaderColorizeSimple")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_additive.glsl")
  shader:setFragmentShaderSource("shaders/frag_colorize_simple.glsl")
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderColorizeSimple", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader or false
