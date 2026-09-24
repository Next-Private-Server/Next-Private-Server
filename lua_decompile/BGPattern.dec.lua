local BGPattern = {}
function BGPattern.onPostInit(element)
  print("on post init!")
  local component = element:GetComponent("Sprite")
  component("spriteName"):SetString("gfx/menu/pattern01")
  component:setScale(lua_sys.Vector2(element:absW() / 128, element:absH() / 128))
  component:setColor(1, 1, 1)
  component("layer"):SetString("FrontPopUps")
  component("alpha"):SetFloat(1)
  component("visible"):SetInt(1)
  local shader = game.getShader("bg_pattern01")
  if shader == nil then
    shader = game.createShader()
    shader:setVertexShaderSource("shaders/vertex_normal.glsl")
    shader:setFragmentShaderSource("shaders/frag_pattern.glsl")
    shader:addTimeUniform()
    shader:addFloatUniform("u_Speed", 0.5)
    shader:addVec4Uniform("u_TexParams", lua_sys.Vector4(128 / element:absW(), 128 / element:absH(), 5, 5))
    shader:link()
    if shader:isLinked() then
      game.putShader("bg_pattern01", shader)
    else
      print("Error linking shader!")
      game.destroyShader(shader)
      shader = nil
    end
  end
  component:setShader(shader)
end
return BGPattern
