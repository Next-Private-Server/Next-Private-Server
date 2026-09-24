local MenuHelpers = require("MenuHelpers")
local ReattunedGene = {
  Sprite = {},
  Rarity = {},
  Anim = {},
  Effect = {}
}
function ReattunedGene:Show()
  self.Sprite("visible"):SetInt(1)
  self.Rarity("visible"):SetInt(1)
end
function ReattunedGene:Hide()
  self.Sprite("visible"):SetInt(0)
  self.Rarity("visible"):SetInt(0)
end
function ReattunedGene:SetAlpha(alpha)
  self.Sprite("alpha"):SetFloat(alpha)
  self.Rarity("alpha"):SetFloat(alpha)
end
function ReattunedGene:SetColor(r, g, b)
  self.Sprite:setColor(r, g, b)
  self.Rarity:setColor(r, g, b)
end
function ReattunedGene:UpdateClipping(fromScriptable)
  MenuHelpers.SetClipFrom(self.Sprite, fromScriptable)
  MenuHelpers.SetClipFrom(self.Rarity, fromScriptable)
end
function ReattunedGene:ShowRarity()
  self.Rarity("visible"):SetInt(1)
end
function ReattunedGene:HideRarity()
  self.Rarity("visible"):SetInt(0)
end
function ReattunedGene:ShowRarityReveal()
  self:ShowRarity()
  self:C("Anim"):V("visible"):SetInt(1)
  self:C("Anim"):V("animation"):SetString("sigil_burst")
  self:C("Effect"):start()
end
return ReattunedGene
