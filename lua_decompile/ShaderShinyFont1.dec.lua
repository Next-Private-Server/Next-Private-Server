local shader = game.getShader("ShaderShinyFont1")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vert_sdf.glsl")
  shader:setFragmentShaderSource("shaders/frag_shiny_sdf.glsl")
  shader:addTimeUniform()
  shader:addVec3Uniform("u_Resolution", lua_sys.Vector3(1920, 1280, 0))
  shader:addFloatUniform("u_Dilate", 0.66)
  shader:addFloatUniform("u_Softness", 0.15)
  shader:addVec3Uniform("u_FaceColor", lua_sys.Vector3(1, 1, 1))
  shader:addFloatUniform("u_OutlineThickness", 0.52)
  shader:addVec3Uniform("u_OutlineColor", lua_sys.Vector3(0, 0, 0))
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderShinyFont1", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
