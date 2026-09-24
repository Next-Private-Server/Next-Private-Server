local Toggle = {
  Sprite = {},
  Text = {},
  ToggleArea = {
    Sprite = {},
    Touch = {},
    Handle = {
      Sprite = {}
    }
  }
}
function Toggle:onInit()
  self.toggled = false
end
function Toggle:onPostInit()
  self:UpdateAppearance()
end
function Toggle:IsToggled()
  return self.toggled
end
function Toggle:SetToggled(toggled)
  if self.toggled ~= toggled then
    self.toggled = toggled
    self:UpdateAppearance()
    if self.OnToggled then
      self:OnToggled()
    end
  end
end
function Toggle:UpdateAppearance()
  local spacing = 16 * game.menuScaleX()
  self.Text:setSize(lua_sys.Vector2(self:absW() - self.ToggleArea:absW() - spacing, self:absH()))
  local handle = self.ToggleArea.Handle
  if not self.toggled then
    self.ToggleArea.Sprite:GetVar("spriteName"):SetString("gfx/menu/menu_text_field")
    handle:GetVar("xOffset"):SetFloat(0)
  else
    self.ToggleArea.Sprite:GetVar("spriteName"):SetString("gfx/menu/menu_text_field_on")
    local w = self.ToggleArea:absW()
    handle:GetVar("xOffset"):SetFloat(w - handle:absW())
  end
end
function Toggle.ToggleArea.Touch:onTouchUp(element)
  local topElement = element:parent()
  if topElement then
    topElement:SetToggled(not topElement:IsToggled())
  end
end
function Toggle:SetVisible(visible)
  self.Sprite("visible"):SetInt(visible and self.showBG and 1 or 0)
  self.Text("visible"):SetInt(visible and 1 or 0)
  self.ToggleArea.Sprite("visible"):SetInt(visible and 1 or 0)
  self.ToggleArea.Handle.Sprite("visible"):SetInt(visible and 1 or 0)
  self.ToggleArea.Touch("enabled"):SetInt(visible and 1 or 0)
  if visible then
    self:UpdateAppearance()
  end
end
return Toggle
