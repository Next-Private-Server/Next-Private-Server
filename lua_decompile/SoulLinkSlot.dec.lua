local SoulLinkSlot = {}
function SoulLinkSlot:onInit()
  self.touchDisabled = false
  self.monsterId = 0
end
function SoulLinkSlot:onPostInit()
end
function SoulLinkSlot:setLocked()
  self.touchDisabled = true
  self:C("LockedIcon"):V("visible"):SetInt(1)
  self:C("Sprite"):V("visible"):SetInt(0)
end
function SoulLinkSlot:setUnlocked()
  self.touchDisabled = false
  self:C("LockedIcon"):V("visible"):SetInt(0)
  self:C("Sprite"):V("visible"):SetInt(1)
end
function SoulLinkSlot:addMonster(monsterId)
  self.monsterId = monsterId
  self:C("MonsterImage"):V("spriteName"):SetString("gfx/breeding/" .. game.getPortraitName(monsterId))
  self:C("MonsterImage"):V("visible"):SetInt(1)
  local rateUnit = LOC(game.objectRateUnit())
  self:C("Rate"):V("text"):SetString(game.commaizeNumber(game.effectiveResourceRate(monsterId)) .. rateUnit)
end
function SoulLinkSlot:removeMonster()
  self.monsterId = 0
  self:C("MonsterImage"):V("visible"):SetInt(0)
  self:C("Rate"):V("text"):SetString("")
end
function SoulLinkSlot:Enable()
  self.touchDisabled = false
end
function SoulLinkSlot:Disable()
  self.touchDisabled = true
end
return SoulLinkSlot
