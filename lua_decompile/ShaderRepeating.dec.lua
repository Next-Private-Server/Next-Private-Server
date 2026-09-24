local shader = game.getShader("ShaderRepeating")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_additive.glsl")
  shader:setFragmentShaderSource("shaders/frag_pattern.glsl")
  shader:addFloatUniform("u_dX", 0.25)
  shader:addFloatUniform("u_dY", 0.25)
  shader:addVec4Uniform("u_TexParams", lua_sys.Vector4(1, 1, 4 * (lua_sys.screenWidth() / lua_sys.screenHeight()), 4))
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderRepeating", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
