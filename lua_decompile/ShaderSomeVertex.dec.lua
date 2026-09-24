local shader = game.getShader("ShaderSomeVertex")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_additive.glsl")
  shader:setFragmentShaderSource("shaders/frag_some_vertex_color.glsl")
  shader:addFloatUniform("u_Brightness", 1)
  shader:addVec3Uniform("u_ColorMask", lua_sys.Vector3(0, 0, 1))
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderSomeVertex", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
