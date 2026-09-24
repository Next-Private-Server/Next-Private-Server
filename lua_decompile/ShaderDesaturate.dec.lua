local shader = game.getShader("ShaderDesaturate")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_normal.glsl")
  shader:setFragmentShaderSource("shaders/frag_desaturate.glsl")
  shader:addFloatUniform("blackIntensity", 0)
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderDesaturate", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
