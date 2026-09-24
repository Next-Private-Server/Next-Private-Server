local MapButton = {
  Touch = {},
  Overlay = {},
  Text = {}
}
function MapButton.Touch:onTouchDown(element)
  self:super_onTouchDown(element)
  element.Text:setColor(1, 1, 1)
  element.Overlay:setColor(0.5, 0.5, 0.5)
end
function MapButton.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  element.Overlay:setColor(1, 1, 1)
  if element.buttonAction then
    element.buttonAction()
  end
end
function MapButton.Touch:onTouchRelease(element)
  self:super_onTouchRelease(element)
  element.Overlay:setColor(1, 1, 1)
end
function MapButton.Overlay:onInit(element)
  self:GetVar("spriteName"):SetString("button_mirror_in")
  self:GetVar("sheetName"):SetString("xml_resources/hud03.xml")
  self:GetVar("size"):SetFloat(0.75 * game.hudScale())
  self:GetVar("layer"):SetString(self:parent().BoundsSprite:GetVar("layer"):GetString())
end
function MapButton.Text:onInit(element)
  self:GetVar("autoScaleFactor"):SetFloat(0.01)
  self:GetVar("autoScale"):SetInt(1)
  self:GetVar("multiline"):SetInt(0)
  self:GetVar("font"):Set(game.getTitleFont())
  self:GetVar("size"):SetFloat(0.5 * game.hudScale())
  self:GetVar("alignment"):SetInt(lua_sys.MenuTextComponent_TEXT_HCENTER_ALIGNED)
  self:GetVar("text"):SetString("CONTEXTBAR_MIRROR_LABEL")
  self:GetVar("layer"):SetString(self:parent().BoundsSprite:GetVar("layer"):GetString())
end
function MapButton:onTick(dt)
  self:super_onTick(dt)
  local upSize = self.UpSprite:GetVar("size"):GetFloat()
  local overlaySize = self.Overlay:GetVar("size"):GetFloat()
  if upSize ~= overlaySize then
    self.Overlay:GetVar("size"):SetFloat(upSize)
  end
end
function MapButton:enable()
  self:super_enable()
  self.Overlay:setColor(1, 1, 1)
end
function MapButton:disable()
  self:super_disable()
  self.Overlay:setColor(0.5, 0.5, 0.5)
end
function MapButton:setVisible()
  self:super_setVisible()
  self.Overlay:GetVar("visible"):SetInt(1)
end
function MapButton:setInvisible()
  self:super_setInvisible()
  self.Overlay:GetVar("visible"):SetInt(0)
end
return MapButton
