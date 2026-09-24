local NucleusSetProgressMeter = {
  Bg = {},
  Fill = {}
}
function NucleusSetProgressMeter:onInit()
  self.isDisabled = false
  self.isLocked = false
end
function NucleusSetProgressMeter:onPostInit()
  if self.isLocked == false then
    self:setFill()
  end
end
function NucleusSetProgressMeter:setFill()
  local fill = self:C("FillSprite")
  local percent = self:numMonsters(self.numGenes, self.rarity) / game.numNucleusMonstersInSet(self.numGenes)
  if percent < 1 and percent > 0.9 then
    percent = percent - 0.04
  end
  if percent < 1 and percent < 0.1 then
    percent = percent + 0.04
  end
  percent = lua_sys.clamp(percent, 0, 1)
  local maskHeight = fill("maskHeight"):GetFloat()
  local newMaskHeight = maskHeight * percent
  local heightDiff = maskHeight - newMaskHeight
  local maskY = fill("maskY"):GetFloat()
  local newMaskY = maskY + heightDiff
  local size = fill:size()
  fill("maskY"):SetFloat(newMaskY)
  fill("maskHeight"):SetFloat(newMaskHeight)
  fill:setSize(lua_sys.Vector2(size.x, size.y * percent))
  if percent == 1 then
    self:C("Bg"):V("spriteName"):SetString("frame_glow")
  end
end
function NucleusSetProgressMeter:numMonsters(numGenes, rarity)
  if rarity == "common" then
    return game.numNucleusMonster(numGenes, game.MonsterRarity_Common)
  elseif rarity == "rare" then
    return game.numNucleusMonster(numGenes, game.MonsterRarity_Rare)
  elseif rarity == "epic" then
    return game.numNucleusMonster(numGenes, game.MonsterRarity_Epic)
  end
  return 0
end
function NucleusSetProgressMeter:setDisabled()
  self:C("Bg"):V("spriteName"):SetString("frame_black")
  self:C("FillSprite"):V("visible"):SetInt(0)
  self.isDisabled = true
end
function NucleusSetProgressMeter:setLocked()
  self:C("Bg"):V("spriteName"):SetString("frame_black")
  self:C("FillSprite"):V("visible"):SetInt(0)
  self.isLocked = true
  self.isDisabled = true
end
return NucleusSetProgressMeter
