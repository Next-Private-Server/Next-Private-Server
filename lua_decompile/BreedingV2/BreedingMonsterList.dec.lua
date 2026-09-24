local ScrollingListHelper = include("ScrollingListHelper")
local MenuHelpers = include("MenuHelpers")
local Genes = include("Genes")
local BreedingMonsterList = {
  Bg = {
    Sprite = {},
    Touch = {}
  },
  Title = {
    Text = {}
  },
  List = {
    Touch = {},
    Swiper = {}
  },
  Filter = {}
}
function BreedingMonsterList:onInit()
  ScrollingListHelper.ListInit(self.List, {
    direction = lua_sys.MenuSwipeComponent_SwipeDirectionVertical,
    spacing = 0 * BreedingMenuScaleX(),
    padding = 56 * BreedingMenuScaleX()
  })
end
function BreedingMonsterList:Setup(controller, monsters, flipped)
  self.controller = controller
  self.flipped = flipped or false
  local geneSet = {}
  for _, monster in ipairs(monsters) do
    local fullGenes = Genes.GetFullGenesForMonster(monster)
    for _, fullGene in ipairs(fullGenes) do
      if not geneSet[fullGene] then
        geneSet[fullGene] = true
      end
    end
  end
  local availableGenes = {}
  if not game.tutorialActive() then
    for geneName, _ in pairs(geneSet) do
      table.insert(availableGenes, geneName)
    end
  end
  self.Filter:Setup(self, availableGenes, flipped)
  if #availableGenes <= 1 then
    self.List:GetVar("padding"):SetFloat(36 * BreedingMenuScaleX())
  end
  self:populateBreedingEntries(monsters)
end
function BreedingMonsterList:onPostInit()
  self:ApplyFilter()
end
function BreedingMonsterList:onTick(dt)
  ScrollingListHelper.ListTick(self.List, dt)
  self:updateClipping()
end
function BreedingMonsterList:updateClipping()
  local clipX = self:absX()
  local clipY = self:absY() + 9 * BreedingMenuScaleX()
  local clipW = self:absW()
  local clipH = self:absH() - 18 * BreedingMenuScaleX()
  if self.clipX ~= clipX or self.clipY ~= clipY or self.clipW ~= clipW or self.clipH ~= clipH then
    self.clipX = clipX
    self.clipY = clipY
    self.clipW = clipW
    self.clipH = clipH
    MenuHelpers.ForEachEntry(self.List, function(entry)
      entry:SetClipping(clipX, clipY, clipW, clipH)
    end)
  end
end
function BreedingMonsterList.List.Swiper:refresh(element)
  ScrollingListHelper.SwiperRefresh(self, element)
end
function BreedingMonsterList.List.Swiper:onTick(element, dt)
  ScrollingListHelper.SwiperTick(self, element, dt)
end
function BreedingMonsterList:SetUniqueFilter(uniqueOn)
  self.isUniqueFilterEnabled = uniqueOn or false
  self:ApplyFilter()
end
function BreedingMonsterList:ApplyFilter()
  print("enabled filters:")
  for _, filter in ipairs(self.Filter.enabledFilters) do
    print(filter)
  end
  local uniqueMonsters = {}
  if self.isUniqueFilterEnabled then
    for _, monster in ipairs(self.monsters) do
      local monsterId = monster:data():monsterId()
      if not uniqueMonsters[monsterId] or uniqueMonsters[monsterId]:level() < monster:level() then
        uniqueMonsters[monsterId] = monster
      end
    end
  end
  local function IsPassFilter(monster)
    if #self.Filter.enabledFilters == 0 then
      return true
    end
    local monsterGenes = Genes.GetFullGenesForMonster(monster)
    local monsterGeneSet = {}
    for _, gene in ipairs(monsterGenes) do
      monsterGeneSet[gene] = true
    end
    for _, requiredGene in ipairs(self.Filter.enabledFilters) do
      if not monsterGeneSet[requiredGene] then
        return false
      end
    end
    return true
  end
  local padding = self.List:GetVar("padding"):GetFloat()
  local spacing = self.List:GetVar("spacing"):GetFloat()
  local totalSize = padding + spacing
  local numEntries = 0
  MenuHelpers.ForEachEntry(self.List, function(entry)
    local passes = IsPassFilter(entry.monster)
    if self.isUniqueFilterEnabled then
      local monsterId = entry.monster:data():monsterId()
      passes = passes and uniqueMonsters[monsterId] == entry.monster
    end
    entry:SetVisible(passes)
    if passes then
      if numEntries > 0 then
        totalSize = totalSize + spacing
      end
      entry("listOffset"):SetFloat(totalSize)
      totalSize = totalSize + entry:absH()
      numEntries = numEntries + 1
    end
  end)
  self.List:GetVar("totalSize"):SetFloat(totalSize)
  self.List:GetVar("numEntries"):SetInt(numEntries + 1)
  local scrollOffset = self.List:GetVar("scrollOffset"):GetFloat()
  if totalSize < scrollOffset then
    scrollOffset = totalSize
  end
  self.List:GetVar("scrollOffset"):SetFloat(scrollOffset)
  self.List.Swiper:refresh(self.List)
end
function BreedingMonsterList:populateBreedingEntries(monsters)
  self.monsters = monsters
  ScrollingListHelper.ListClear(self.List)
  local function OnEntryTouched(entry)
    if entry.monster:level() < 4 then
      game.displayNotification("NOTIFICATION_MONSTER_UNDERLEVELED")
    elseif entry.enabled then
      self:SelectNewEntry(entry)
    end
  end
  local function createFunc(idx, itemName)
    local monster = monsters[idx + 1]
    local item = menu:addTemplateElement("template_breeding_monsterlist_entry", itemName, self.List)
    item:Setup(monster, idx, self.controller, self)
    item.monster = monster
    item.idx = idx
    item.OnEntryTouched = OnEntryTouched
    return item
  end
  ScrollingListHelper.ListPopulate(self.List, #monsters, createFunc)
end
function BreedingMonsterList:SelectNewEntry(entry)
  if self.SelectedEntry ~= entry then
    if self.SelectedEntry then
      self.SelectedEntry:SetSelected(false)
      self.controller:OnEntryDeselected(self.SelectedEntry, self)
    end
    self.SelectedEntry = entry
    if self.SelectedEntry then
      self.SelectedEntry:SetSelected(true)
      self.controller:OnEntrySelected(self.SelectedEntry, self)
    end
  elseif self.SelectedEntry then
    self.SelectedEntry:SetSelected(false)
    self.controller:OnEntryDeselected(self.SelectedEntry, self)
    self.SelectedEntry = nil
    self.controller:OnEntrySelected(self.SelectedEntry, self)
  end
end
function BreedingMonsterList:SetMonstersEnabled(monsterId, enabled)
  MenuHelpers.ForEachEntry(self.List, function(entry)
    if entry.monster and entry.monster:data() and entry.monster:data():monsterId() == monsterId then
      entry:SetEnabled(enabled)
    end
  end)
end
function BreedingMonsterList:SetActive(active)
  self.List.Swiper:GetVar("enableMouseScroll"):SetInt(active and 1 or 0)
end
function BreedingMonsterList.Bg.Touch:onTouchDown(element, x, y)
  element:parent().controller:OnListSelected(element:parent())
end
function BreedingMonsterList:GetSelectedMonsterId()
  if self.SelectedEntry and self.SelectedEntry.monster then
    return self.SelectedEntry.monster:data():monsterId()
  end
  return 0
end
function BreedingMonsterList:SelectMonsterByUId(uid)
  MenuHelpers.ForEachEntry(self.List, function(entry)
    if entry.monster and entry.monster:uniqueId() == uid then
      self:SelectNewEntry(entry)
      return
    end
  end)
end
return BreedingMonsterList
