local shader = game.getShader("ShaderColorHole")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_extra.glsl")
  shader:setFragmentShaderSource("shaders/frag_color_hole.glsl")
  shader:addResolutionUniform()
  shader:addVec2Uniform("u_HolePos", lua_sys.Vector2(0.5, 0.5))
  shader:addFloatUniform("u_HoleRadius", 0.5)
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderColorHole", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
