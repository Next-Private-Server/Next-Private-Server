local shader = game.getShader("ShaderHole")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_extra.glsl")
  shader:setFragmentShaderSource("shaders/frag_hole.glsl")
  shader:addResolutionUniform()
  shader:addVec2Uniform("u_HolePos", lua_sys.Vector2(0.5, 0.5))
  shader:addFloatUniform("u_HoleRadius", 0.5)
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderHole", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
