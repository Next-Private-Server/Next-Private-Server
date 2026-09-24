local shader = game.getShader("ShaderCostumeABE3Rare")
if shader == nil then
  shader = game.createShader()
  shader:setVertexShaderSource("shaders/vertex_additive.glsl")
  shader:setFragmentShaderSource("shaders/frag_costume_abe3_rare.glsl")
  shader:addSamplerUniform("u_TextureFlippyOrange", 2, "gfx/costumes/monster_ABE_RARE_costume_03_orange_sheet")
  shader:addSamplerAlphaUniform("u_TextureFlippyAlphaOrange", 3, "gfx/costumes/monster_ABE_RARE_costume_03_orange_sheet")
  shader:addSamplerUniform("u_TextureFlippyYellow", 4, "gfx/costumes/monster_ABE_RARE_costume_03_yellow_sheet")
  shader:addSamplerAlphaUniform("u_TextureFlippyAlphaYellow", 5, "gfx/costumes/monster_ABE_RARE_costume_03_yellow_sheet")
  shader:addIntUniform("u_isOrange", 0)
  shader:link()
  if shader:isLinked() then
    game.putShader("ShaderCostumeABE3Rare", shader)
  else
    print("Error linking shader!")
    game.destroyShader(shader)
    shader = nil
  end
end
return shader
