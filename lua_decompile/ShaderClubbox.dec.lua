local shader = game.getShader("ShaderClubbox")
if shader == nil then
  print("=== Creating Clubbox Shader")
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_normal.glsl")
  shader:setFragmentShaderSource("shaders/frag_desaturate_fb.glsl")
  shader:addVec2Uniform("u_MaxUV", game.displayMaxUV())
  shader:addFloatUniform("blackIntensity", 0)
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderClubbox", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
