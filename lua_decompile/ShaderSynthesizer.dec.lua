local shader = game.getShader("ShaderSynthesizer")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_normal.glsl")
  shader:setFragmentShaderSource("shaders/frag_synthesizer.glsl")
  shader:addFloatUniform("u_percent", 0)
  shader:addSamplerUniform("u_gradient", 2, "gfx/menu/synth_gradient")
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderSynthesizer", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
