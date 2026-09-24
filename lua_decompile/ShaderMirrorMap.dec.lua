local shader = game.getShader("ShaderMirrorMap")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_extra.glsl")
  shader:setFragmentShaderSource("shaders/frag_mirror.glsl")
  shader:addTimeUniform()
  shader:addVec3Uniform("u_Resolution", lua_sys.Vector3(1920, 1280, 0))
  shader:addFloatUniform("u_Blend")
  shader:addSamplerUniform("u_Pattern", 2, "gfx/perlin", 9729, 10497)
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderMirrorMap", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
