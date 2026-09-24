local shader = game.getShader("ShaderFont2")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vert_sdf.glsl")
  shader:setFragmentShaderSource("shaders/frag_sdf.glsl")
  shader:addFloatUniform("u_Dilate", 0.75)
  shader:addFloatUniform("u_Softness", 0.2)
  shader:addVec3Uniform("u_FaceColor", lua_sys.Vector3(1, 1, 1))
  shader:addFloatUniform("u_OutlineThickness", 0.5)
  shader:addVec3Uniform("u_OutlineColor", lua_sys.Vector3(0, 0, 0))
  shader:addFloatUniform("u_RenderSize", 50)
  shader:addFloatUniform("u_PixelSize", 50)
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderFont2", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
