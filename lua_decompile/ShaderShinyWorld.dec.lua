local shader = game.getShader("ShaderShinyWorld")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_extra.glsl")
  shader:setFragmentShaderSource("shaders/frag_shiny_world.glsl")
  shader:addTimeUniform()
  shader:addVec3Uniform("u_Resolution", lua_sys.Vector3(1920, 1280, 0))
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderShinyWorld", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
