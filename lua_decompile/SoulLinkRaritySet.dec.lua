local SoulLinkRaritySet = {}
function SoulLinkRaritySet:onInit()
end
function SoulLinkRaritySet:onPostInit()
  local titansoul = game.SelectedObject()
  if titansoul:isRarityUnlocked(tonumber(self:templateVars().setRarity)) then
    self:setUnlocked()
    for i = 1, 4 do
      local entry = self:E("Link" .. i)
      entry:removeMonster()
    end
    local soulLinks = titansoul:getSoulLinks(tonumber(self:templateVars().setRarity))
    for i = 0, soulLinks:size() - 1 do
      local link = soulLinks[i]
      local monsterRarity = game.monsterRarity(link)
      if monsterRarity == tonumber(self:templateVars().setRarity) then
        local entry = self:E("Link" .. i + 1)
        entry:addMonster(link)
      end
    end
  else
    self:setLocked()
  end
end
function SoulLinkRaritySet:refresh()
  local titansoul = game.SelectedObject()
  if titansoul:isRarityUnlocked(self:templateVars().setRarity) and self.isLocked then
    self:setUnlocked()
  end
end
function SoulLinkRaritySet:setLocked()
  for i = 1, 4 do
    local entry = self:E("Link" .. i)
    entry:setLocked()
  end
  self.isLocked = true
end
function SoulLinkRaritySet:setUnlocked()
  for i = 1, 4 do
    local entry = self:E("Link" .. i)
    entry:setUnlocked()
  end
  self.isLocked = false
end
function SoulLinkRaritySet:Enable()
  for i = 1, 4 do
    local entry = self:E("Link" .. i)
    entry:Enable()
  end
end
function SoulLinkRaritySet:Disable()
  for i = 1, 4 do
    local entry = self:E("Link" .. i)
    entry:Disable()
  end
end
return SoulLinkRaritySet
