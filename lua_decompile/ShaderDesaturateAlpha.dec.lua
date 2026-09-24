local shader = game.getShader("ShaderDesaturateAlpha")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_normal.glsl")
  shader:setFragmentShaderSource("shaders/frag_desaturate_alpha.glsl")
  shader:addFloatUniform("blackIntensity", 0)
  shader:addFloatUniform("alpha", 1)
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderDesaturateAlpha", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
