local shader = game.getShader("ShaderCostumeA3")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_additive.glsl")
  shader:setFragmentShaderSource("shaders/frag_costume_a3.glsl")
  shader:addTimeUniform()
  shader:addSamplerUniform("u_TextureSequence", 2, "gfx/costumes/monster_A_costume_03_sequence")
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderCostumeA3", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
