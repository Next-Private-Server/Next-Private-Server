local shader = game.getShader("ShaderDesaturateAndFade")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_normal.glsl")
  shader:setFragmentShaderSource("shaders/frag_desaturateAndFade.glsl")
  shader:addFloatUniform("blackIntensity", 0)
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderDesaturateAndFade", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
