local shader = game.getShader("ShaderScrollingPattern")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_additive.glsl")
  shader:setFragmentShaderSource("shaders/frag_pattern.glsl")
  shader:addTimeUniform()
  shader:addFloatUniform("u_dX", 0.25)
  shader:addFloatUniform("u_dY", 0.25)
  shader:addVec4Uniform("u_TexParams", lua_sys.Vector4(128 * game.hudScale() / lua_sys.screenWidth(), 128 * game.hudScale() / lua_sys.screenHeight(), 3, 3))
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderScrollingPattern", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
