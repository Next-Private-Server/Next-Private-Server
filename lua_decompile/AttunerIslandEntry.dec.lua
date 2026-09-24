local ShaderColorize = include("ShaderColorize")
local AttunerIslandEntry = {
  Sprite = {},
  SelectedSprite = {},
  ShadowSprite = {},
  DisabledSprite = {},
  Text = {},
  Gene = {},
  CurrencyAmount = {
    Sprite = {},
    Text = {}
  },
  ReattunementSprites = {
    Rare = {
      Sprite = {}
    },
    Epic = {
      Sprite = {}
    }
  }
}
function AttunerIslandEntry:onInit()
  self.isSelected = false
  self.isDisabled = false
  self.time = 0
  self.textR = 1
  self.textG = 1
  self.textB = 1
  self.isSelectedIsland = false
end
function AttunerIslandEntry:onPostInit()
  self.CurrencyAmount("yOffset"):SetInt(self:templateVars().scale * -3 * game.menuScaleX())
end
function AttunerIslandEntry:setSelected(selected)
  self.isSelected = selected
  self.time = 0
  self.SelectedSprite("visible"):SetInt(selected and 1 or 0)
  self.ShadowSprite("visible"):SetInt(selected and 1 or 0)
end
function AttunerIslandEntry:setDisabled(disabled)
  self.isDisabled = disabled
  self.DisabledSprite("visible"):SetInt(disabled and 1 or 0)
end
function AttunerIslandEntry:setInvisible()
  self.Sprite("visible"):SetInt(0)
  self.SelectedSprite("visible"):SetInt(0)
  self.ShadowSprite("visible"):SetInt(0)
  self.DisabledSprite("visible"):SetInt(0)
  self.Text("visible"):SetInt(0)
  self.Gene("visible"):SetInt(0)
  self.CurrencyAmount.Sprite("visible"):SetInt(0)
  self.CurrencyAmount.Text("visible"):SetInt(0)
  self.ReattunementSprites.Rare.Sprite("visible"):SetInt(0)
end
function AttunerIslandEntry:setVisible()
  self.Sprite("visible"):SetInt(1)
  self.SelectedSprite("visible"):SetInt(self.isSelected and 1 or 0)
  self.ShadowSprite("visible"):SetInt(self.isSelected and 1 or 0)
  self.DisabledSprite("visible"):SetInt(self.isDisabled and 1 or 0)
  self.Text("visible"):SetInt(1)
  self.Gene("visible"):SetInt(1)
  self.CurrencyAmount.Sprite("visible"):SetInt(1)
  self.CurrencyAmount.Text("visible"):SetInt(1)
  self.ReattunementSprites.Rare.Sprite("visible"):SetInt(1)
end
function AttunerIslandEntry:hideText()
  self.Text("visible"):SetInt(0)
end
function AttunerIslandEntry:grey()
  self.Sprite:setColor(0.5, 0.5, 0.5)
  self.Text:setColor(self.textR * 0.5, self.textG * 0.5, self.textB * 0.5)
  self.Gene:setColor(0.5, 0.5, 0.5)
  self.CurrencyAmount.Sprite:setColor(0.5, 0.5, 0.5)
  self.CurrencyAmount.Text:setColor(0.5, 0.5, 0.5)
  self.ReattunementSprites.Rare.Sprite:setColor(0.5, 0.5, 0.5)
end
function AttunerIslandEntry:unGrey()
  self.Sprite:setColor(1, 1, 1)
  self.Text:setColor(self.textR, self.textG, self.textB)
  self.Gene:setColor(1, 1, 1)
  self.CurrencyAmount.Sprite:setColor(1, 1, 1)
  self.CurrencyAmount.Text:setColor(1, 1, 1)
  self.ReattunementSprites.Rare.Sprite:setColor(1, 1, 1)
end
function AttunerIslandEntry:onTick(dt)
  if self.isSelected then
    self.time = self.time + dt
    local factor = math.sin(self.time * 4) * 0.5 + 0.5
    if ShaderColorize then
      ShaderColorize:getUniform("u_Factor"):setFloat(factor)
    end
  end
end
return AttunerIslandEntry
