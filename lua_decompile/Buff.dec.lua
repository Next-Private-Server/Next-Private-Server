local Buff = {
  Sprite = {},
  Touch = {},
  Tooltip = {}
}
function Buff:onInit()
end
function Buff:onTick(dt)
  self.Tooltip.Text:GetVar("text"):SetString(self.buff.description())
end
function Buff:SetClipRect(x, y, w, h)
  self.Sprite:setClipRect(x, y, w, h)
  self.Touch:setClipRect(x, y, w, h)
end
function Buff.Sprite:onInit(element)
  self:GetVar("spriteName"):SetString(element.buff.sprite)
  self:GetVar("sheetName"):SetString(element.buff.sheet)
  self:GetVar("size"):SetFloat(element.buff.size)
  self:GetVar("layer"):SetString(element:parent().layer or "MidPopUps")
end
function Buff.Touch:onTouchDown(element, x, y)
  element.Tooltip:Show()
end
function Buff.Touch:onTouchUp(element, x, y)
  element.Tooltip:Hide()
end
function Buff.Touch:onTouchRelease(element, x, y)
  element.Tooltip:Hide()
end
return Buff
