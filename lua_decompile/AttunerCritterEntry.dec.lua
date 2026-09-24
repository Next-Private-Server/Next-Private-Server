local ShaderColorize = include("ShaderColorize")
local AttunerCritterEntry = {
  Bg = {},
  Sprite = {},
  SelectedSprite = {},
  DisabledSprite = {},
  Text = {},
  UpArrow = {
    Sprite = {}
  },
  DownArrow = {
    Sprite = {}
  }
}
function AttunerCritterEntry:onInit()
  self.isSelected = false
  self.isDisabled = false
  self.time = 0
  self.textR = 1
  self.textG = 1
  self.textB = 1
end
function AttunerCritterEntry:onPostInit()
  if game.isQABuild() and self.gene ~= "" then
    self.UpArrow.Sprite:V("visible"):SetInt(1)
    self.DownArrow.Sprite:V("visible"):SetInt(1)
  else
    self.UpArrow.Touch:V("enabled"):SetInt(0)
    self.DownArrow.Touch:V("enabled"):SetInt(0)
  end
end
function AttunerCritterEntry:setSelected(selected)
  self.isSelected = selected
  self.time = 0
  self.SelectedSprite("visible"):SetInt(selected and 1 or 0)
end
function AttunerCritterEntry:setDisabled(disabled)
  self.isDisabled = disabled
  if disabled then
    self:grey()
  else
    self:unGrey()
  end
end
function AttunerCritterEntry:setInvisible()
  self.Sprite("visible"):SetInt(0)
  self.SelectedSprite("visible"):SetInt(0)
  self.Text("visible"):SetInt(0)
end
function AttunerCritterEntry:setVisible()
  self.Sprite("visible"):SetInt(1)
  self.SelectedSprite("visible"):SetInt(self.isSelected and 1 or 0)
  self.DisabledSprite("visible"):SetInt(self.isDisabled and 1 or 0)
  self.Text("visible"):SetInt(1)
end
function AttunerCritterEntry:hideText()
  self.Text("visible"):SetInt(0)
end
function AttunerCritterEntry:grey()
  self.Sprite:setColor(0.5, 0.5, 0.5)
  self.Bg:setColor(0.5, 0.5, 0.5)
  self.Text:setColor(self.textR * 0.5, self.textG * 0.5, self.textB * 0.5)
end
function AttunerCritterEntry:unGrey()
  self.Sprite:setColor(1, 1, 1)
  self.Bg:setColor(1, 1, 1)
  self.Text:setColor(self.textR, self.textG, self.textB)
end
function AttunerCritterEntry:onTick(dt)
  if self.isSelected then
    self.time = self.time + dt
    local factor = math.sin(self.time * 4) * 0.5 + 0.5
    if ShaderColorize then
      ShaderColorize:getUniform("u_Factor"):setFloat(factor)
    end
  end
end
function AttunerCritterEntry:setNum(num)
  self.num = num
  self.Text("text"):SetString(num)
end
function AttunerCritterEntry:setAddCritterDisabled(disabled)
  self.UpArrow.isDisabled = disabled
  if self.UpArrow.isDisabled then
    self.UpArrow.Sprite:setColor(0.5, 0.5, 0.5)
  else
    self.UpArrow.Sprite:setColor(1, 1, 1)
  end
end
function AttunerCritterEntry:setRemoveCritterDisabled(disabled)
  self.DownArrow.isDisabled = disabled
  if self.DownArrow.isDisabled then
    self.DownArrow.Sprite:setColor(0.5, 0.5, 0.5)
  else
    self.DownArrow.Sprite:setColor(1, 1, 1)
  end
end
return AttunerCritterEntry
