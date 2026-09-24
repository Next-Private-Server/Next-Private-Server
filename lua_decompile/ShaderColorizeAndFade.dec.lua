local shader = game.getShader("ShaderColorizeAndFade")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_additive.glsl")
  shader:setFragmentShaderSource("shaders/frag_colorizeAndFade.glsl")
  shader:addFloatUniform("u_Factor", 0)
  shader:addVec3Uniform("u_TargetColor", lua_sys.Vector3(1, 1, 1))
  shader:addFloatUniform("u_Fade", 0.5)
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderColorizeAndFade", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader or false
