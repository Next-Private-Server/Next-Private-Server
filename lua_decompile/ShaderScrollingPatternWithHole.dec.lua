local shader = game.getShader("ShaderScrollingPatternWithHole")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_additive.glsl")
  shader:setFragmentShaderSource("shaders/frag_pattern_with_hole.glsl")
  shader:addTimeUniform()
  shader:addResolutionUniform()
  shader:addFloatUniform("u_dX", 0.25)
  shader:addFloatUniform("u_dY", 0.25)
  shader:addVec4Uniform("u_TexParams", lua_sys.Vector4(128 * game.hudScale(), 128 * game.hudScale(), 3, 3))
  shader:addVec2Uniform("u_HolePos", lua_sys.Vector2(0.5, 0.5))
  shader:addFloatUniform("u_HoleRadius", 0.5)
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderScrollingPatternWithHole", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
