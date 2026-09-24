local shader = game.getShader("ShaderShiny")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_additive.glsl")
  shader:setFragmentShaderSource("shaders/frag_shiny.glsl")
  shader:addTimeUniform()
  shader:addVec3Uniform("u_Resolution", lua_sys.Vector3(480 * game.menuScaleX(), 320 * game.menuScaleY(), 0))
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderShiny", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
