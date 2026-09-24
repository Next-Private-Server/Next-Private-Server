local shader = game.getShader("ShaderCostumeE9")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_additive.glsl")
  shader:setFragmentShaderSource("shaders/frag_costume_e9.glsl")
  shader:addTimeUniform()
  shader:addSamplerUniform("u_TextureSequence", 2, "gfx/costumes/monster_E_costume_09_sequence")
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderCostumeE9", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
