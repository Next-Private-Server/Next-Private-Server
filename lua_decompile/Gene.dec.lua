local MenuHelpers = require("MenuHelpers")
local Gene = {
  Sprite = {}
}
function Gene:Show()
  self.Sprite("visible"):SetInt(1)
end
function Gene:Hide()
  self.Sprite("visible"):SetInt(0)
end
function Gene:SetAlpha(alpha)
  self.Sprite("alpha"):SetFloat(alpha)
end
function Gene:SetColor(r, g, b)
  self.Sprite:setColor(r, g, b)
end
function Gene:UpdateClipping(fromScriptable)
  MenuHelpers.SetClipFrom(self.Sprite, fromScriptable)
end
return Gene
