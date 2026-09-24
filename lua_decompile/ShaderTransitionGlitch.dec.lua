local shader = game.getShader("ShaderTransitionGlitch")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_additive.glsl")
  shader:setFragmentShaderSource("shaders/frag_transition_glitch.glsl")
  shader:addSamplerUniform("u_GlitchTex", 2, "gfx/distort")
  shader:addFloatUniform("u_Progress", 0)
  shader:addFloatUniform("u_Steps", 5)
  shader:addTimeUniform("u_Time")
  shader:addFloatUniform("u_Strength", 0)
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderTransitionGlitch", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
