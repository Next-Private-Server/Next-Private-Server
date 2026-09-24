local StoreCategoryButton = {
  Sprite = {},
  Text = {},
  Touch = {},
  visible = true
}
function StoreCategoryButton.Touch:onTouchDown(element)
  if element.buttonEnabled then
    element.Sprite:setColor(0.5, 0.5, 0.5)
    element.Text:setColor(0.5, 0.5, 0.5)
  end
end
function StoreCategoryButton.Touch:onTouchUp(element)
  if not element.buttonEnabled then
    if element.buttonActionDisabled then
      element.buttonActionDisabled()
    end
  else
    element.Sprite:setColor(1, 1, 1)
    element.Text:setColor(1, 1, 1)
    if element.buttonActionEnabled then
      element.buttonActionEnabled()
    end
  end
end
function StoreCategoryButton.Touch:onTouchRelease(element)
  if element.buttonEnabled then
    element.Sprite:setColor(1, 1, 1)
    element.Text:setColor(1, 1, 1)
  end
end
function StoreCategoryButton.Sprite:onInit(element)
  self:GetVar("size"):SetFloat(0.45 * game.windowScaleMin())
  self:GetVar("layer"):SetString("FrontPopUps")
end
function StoreCategoryButton.Text:onInit(element)
  self:GetVar("multiline"):SetInt(0)
  self:GetVar("autoScaleFactor"):SetFloat(0.01)
  self:GetVar("autoScale"):SetInt(1)
  self:GetVar("font"):Set(game.getTextFont())
  self:GetVar("size"):SetFloat(0.23 * game.windowScaleMin())
  self:GetVar("alignment"):SetInt(MenuTextComponent_TEXT_HCENTER_ALIGNED)
  self:GetVar("layer"):SetString("FrontPopUps")
end
function StoreCategoryButton:attachSaleIndicator()
  if self.visible == true and self.canAttachTemplate and self.canAttachTemplate() and self:GetElement("attachedTemplate") == nil then
    local attachedTemplate = menu:addTemplateElement("template_saleindicator", "attachedTemplate", self)
    attachedTemplate:setParent(self)
    attachedTemplate:setOrientation(MenuOrientation(0, -6 * game.windowScaleMin(), -3, HCENTER, VCENTER))
    attachedTemplate:setRelativeObjectAnchors(HCENTER, BOTTOM)
    attachedTemplate:init()
    attachedTemplate("setNewScale"):SetFloat(game.windowScaleMin())
    attachedTemplate.Text("layer"):SetString("FrontPopUps")
    attachedTemplate.Tag("layer"):SetString("FrontPopUps")
    attachedTemplate:setPositionBroadcast(true)
  end
end
function StoreCategoryButton:detachSaleIndicator()
  if self:GetElement("attachedTemplate") ~= nil then
    self:RemoveElement(self:GetElement("attachedTemplate"))
  end
end
function StoreCategoryButton:enable(enableTouch)
  if enableTouch == nil or enableTouch ~= false then
    self.Touch:GetVar("enabled"):SetInt(1)
  end
  self.Sprite:setColor(1, 1, 1)
  self.Text:setColor(1, 1, 1)
end
function StoreCategoryButton:disable(disableTouch)
  if disableTouch == nil or disableTouch ~= false then
    self.Touch:GetVar("enabled"):SetInt(0)
  end
  self.Sprite:setColor(0.5, 0.5, 0.5)
  self.Text:setColor(0.5, 0.5, 0.5)
end
function StoreCategoryButton:setVisible()
  self.Sprite:GetVar("visible"):SetInt(1)
  self.Touch:GetVar("enabled"):SetInt(1)
  self.Text:GetVar("visible"):SetInt(1)
  if self:GetElement("attachedTemplate") ~= nil then
    self:GetElement("attachedTemplate"):SetVisible()
  end
  self.visible = true
end
function StoreCategoryButton:setInvisible()
  self.Sprite:GetVar("visible"):SetInt(0)
  self.Touch:GetVar("enabled"):SetInt(0)
  self.Text:GetVar("visible"):SetInt(0)
  if self:GetElement("attachedTemplate") ~= nil then
    self:GetElement("attachedTemplate"):SetInvisible()
  end
  self.visible = false
end
return StoreCategoryButton
