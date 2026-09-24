local MenuHelpers = include("MenuHelpers")
local ScrollingListHelperV2 = include("ScrollingListHelperV2")
local BuffWidget = {}
function BuffWidget:onInit()
  self.buffs = {}
  self.entries = {}
  self.layer = "MidFrontPopUps"
  self.spacing = 4 * game.hudScale()
  self.populated = false
  self.visible = true
end
function BuffWidget:onPostInit()
  if not self.populated then
    self:populate()
  end
end
function BuffWidget:onTick(dt)
  if self.scrollingList then
    self.scrollingList:Tick(dt)
    for _, v in ipairs(self.entries) do
      v:SetClipRect(self:absX(), self:absY(), self:absW(), self:absH())
    end
    if self.Less then
      local hasLess = self.visible and self.scrollingList:GetCurrentOffset() < 0
      self.Less("visible"):SetInt(hasLess and 1 or 0)
    end
    if self.More then
      local hasMore = self.visible and self.scrollingList:GetCurrentOffset() + self.scrollingList:GetContentSize() > self.scrollingList:GetViewSize() + 1
      self.More("visible"):SetInt(hasMore and 1 or 0)
    end
  end
end
local appendTimeRemaining = function(txt, timeRemaining)
  return txt .. [[


]] .. game.timeToString(timeRemaining)
end
local BuffData = {}
table.insert(BuffData, {
  name = "Nursery Time Reduction",
  sprite = "buff_incubreduc",
  sheet = "xml_resources/buffs_sheet.xml",
  size = 0.125 * game.menuScaleX(),
  isActive = function()
    local buff = game.GetNurseryTimeReductionEvent()
    return buff and buff:currentlyActive()
  end,
  description = function()
    local buff = game.GetNurseryTimeReductionEvent()
    local timeRemaining = buff and buff:timeRemainingSec() or 0
    return appendTimeRemaining(LOC("BUFF_NURSERY_TIME_REDUCTION"), timeRemaining)
  end
})
table.insert(BuffData, {
  name = "Breeding Time Reduction Calendar",
  sprite = "buff_breedreduc",
  sheet = "xml_resources/buffs_sheet.xml",
  size = 0.125 * game.menuScaleX(),
  isActive = function()
    local buff = game.GetBreedingTimeReductionEvent()
    return buff and buff:currentlyActive()
  end,
  description = function()
    local buff = game.GetBreedingTimeReductionEvent()
    local timeRemaining = buff and buff:timeRemainingSec() or 0
    return appendTimeRemaining(LOC("BUFF_BREEDING_TIME_REDUCTION"), timeRemaining)
  end
})
table.insert(BuffData, {
  name = "Breeding Chance Increase Calendar",
  sprite = "buff_breedincr",
  sheet = "xml_resources/buffs_sheet.xml",
  size = 0.125 * game.menuScaleX(),
  isActive = function()
    local buff = game.GetBreedingChanceIncreaseEvent()
    return buff and buff:currentlyActive()
  end,
  description = function()
    local buff = game.GetBreedingChanceIncreaseEvent()
    local timeRemaining = buff and buff:timeRemainingSec() or 0
    return appendTimeRemaining(LOC("BUFF_BREEDING_CHANCE_INCREASE"), timeRemaining)
  end
})
table.insert(BuffData, {
  name = "Costume Chance Increase Calendar",
  sprite = "buff_costumeincr",
  sheet = "xml_resources/buffs_sheet.xml",
  size = 0.125 * game.menuScaleX(),
  isActive = function()
    local buff = game.GetCostumeChanceIncreaseEvent()
    return buff and buff:currentlyActive()
  end,
  description = function()
    local buff = game.GetCostumeChanceIncreaseEvent()
    local timeRemaining = buff and buff:timeRemainingSec() or 0
    return appendTimeRemaining(LOC("BUFF_COSTUME_CHANCE_INCREASE"), timeRemaining)
  end
})
table.insert(BuffData, {
  name = "Currency Collection Bonus",
  sprite = "buff_currencyincr",
  sheet = "xml_resources/buffs_sheet.xml",
  size = 0.125 * game.menuScaleX(),
  isActive = function()
    local buff = game.GetCurrencyCollectionBonusEvent()
    return buff and buff:currentlyActive()
  end,
  description = function()
    local buff = game.GetCurrencyCollectionBonusEvent()
    local timeRemaining = buff and buff:timeRemainingSec() or 0
    return appendTimeRemaining(LOC("BUFF_CURRENCY_COLLECTION_BONUS"), timeRemaining)
  end
})
table.insert(BuffData, {
  name = "Baking Time Reduction",
  sprite = "buff_bakingreduc",
  sheet = "xml_resources/buffs_sheet.xml",
  size = 0.125 * game.menuScaleX(),
  isActive = function()
    local buff = game.GetBakeryTimeReductionEvent()
    return buff and buff:currentlyActive()
  end,
  description = function()
    local buff = game.GetBakeryTimeReductionEvent()
    local timeRemaining = buff and buff:timeRemainingSec() or 0
    return appendTimeRemaining(LOC("BUFF_BAKING_TIME_REDUCTION"), timeRemaining)
  end
})
table.insert(BuffData, {
  name = "Welcome Back Bonus",
  sprite = "buff_welcomeback",
  sheet = "xml_resources/buffs_sheet.xml",
  size = 0.125 * game.menuScaleX(),
  isActive = function()
    local buff = game.GetReturningUserBonusEvent()
    return buff and buff:currentlyActive()
  end,
  description = function()
    local buff = game.GetReturningUserBonusEvent()
    local timeRemaining = buff and buff:timeRemainingSec() or 0
    return appendTimeRemaining(LOC("BUFF_WELCOMEBACK"), timeRemaining)
  end
})
table.insert(BuffData, {
  name = "Breed Diamond Speedup Boost",
  sprite = "buff_breeding_supercharge",
  sheet = "xml_resources/buffs_sheet.xml",
  size = 0.125 * game.menuScaleX(),
  isActive = function()
    local buff = game.GetBreedDiamondSpeedUpBoostEvent()
    return buff and buff:currentlyActive()
  end,
  description = function()
    local buff = game.GetBreedDiamondSpeedUpBoostEvent()
    local timeRemaining = buff and buff:timeRemainingSec() or 0
    return appendTimeRemaining(LOC("BUFF_BREED_DIAMOND_SPEEDUP_BOOST"), timeRemaining)
  end
})
table.insert(BuffData, {
  name = "Nursery Diamond Speedup Boost",
  sprite = "buff_incubation_supercharge",
  sheet = "xml_resources/buffs_sheet.xml",
  size = 0.125 * game.menuScaleX(),
  isActive = function()
    local buff = game.GetNurseryDiamondSpeedUpBoostEvent()
    return buff and buff:currentlyActive()
  end,
  description = function()
    local buff = game.GetNurseryDiamondSpeedUpBoostEvent()
    local timeRemaining = buff and buff:timeRemainingSec() or 0
    return appendTimeRemaining(LOC("BUFF_NURSERY_DIAMOND_SPEEDUP_BOOST"), timeRemaining)
  end
})
table.insert(BuffData, {
  name = "Baking Diamond Speedup Boost",
  sprite = "buff_baking_supercharge",
  sheet = "xml_resources/buffs_sheet.xml",
  size = 0.125 * game.menuScaleX(),
  isActive = function()
    local buff = game.GetBakingDiamondSpeedUpBoostEvent()
    return buff and buff:currentlyActive()
  end,
  description = function()
    local buff = game.GetBakingDiamondSpeedUpBoostEvent()
    local timeRemaining = buff and buff:timeRemainingSec() or 0
    return appendTimeRemaining(LOC("BUFF_BAKING_DIAMOND_SPEEDUP_BOOST"), timeRemaining)
  end
})
local getIslandTheme = function()
  local ids = game.getIslandThemeIds(game.currentIsland(), false, true)
  for i = 0, ids:size() - 1 do
    local id = ids[i]
    if not game.islandThemeIsSeasonal(id) then
      return id
    end
  end
  return nil
end
local function isIslandThemeBuffActive()
  local themeId = getIslandTheme()
  if themeId then
    return game.isIslandThemeOwnedById(themeId)
  end
  return false
end
table.insert(BuffData, {
  name = "Permanent Availability Island Theme Modifier",
  sprite = "buff_skinincr",
  sheet = "xml_resources/buffs_sheet.xml",
  size = 0.125 * game.menuScaleX(),
  isActive = isIslandThemeBuffActive,
  description = function()
    local description = LOC("BUFF_ISLAND_SKIN")
    local themeId = getIslandTheme()
    if themeId then
      description = description .. [[


]] .. game.islandThemeModifiers(themeId)
    end
    return description
  end
})
local getIslandSeasonalTheme = function()
  local ids = game.getIslandThemeIds(game.currentIsland(), false, true)
  for i = 0, ids:size() - 1 do
    local id = ids[i]
    if game.islandThemeIsSeasonal(id) then
      return id
    end
  end
  return nil
end
local function isIslandSeasonalThemeBuffActive()
  local themeId = getIslandSeasonalTheme()
  if themeId then
    return (game.isIslandThemeOwnedById(themeId) or game.isTimedIslandThemeAvail(themeId)) and game.islandThemeModifiers(themeId) ~= ""
  end
  return false
end
table.insert(BuffData, {
  name = "Timed Availability Island Theme Modifier",
  sprite = "buff_seasonincr",
  sheet = "xml_resources/buffs_sheet.xml",
  size = 0.125 * game.menuScaleX(),
  isActive = isIslandSeasonalThemeBuffActive,
  description = function()
    local description = LOC("BUFF_ISLAND_SEASONAL_SKIN")
    local themeId = getIslandSeasonalTheme()
    if themeId then
      if game.isTimedIslandThemeAvail(themeId) then
        local timeRemaining = game.timedAvailIslandThemeTimeRemaining(themeId)
        description = description .. [[


]] .. appendTimeRemaining(game.islandThemeModifiers(themeId), timeRemaining)
      else
        description = description .. [[


]] .. game.islandThemeModifiers(themeId)
      end
    end
    return description
  end
})
local function GetActiveBuffs()
  local activeBuffs = {}
  for _, buff in ipairs(BuffData) do
    print(">>>>>>>>>>>>>>>>>>>>>>> IS ACTIVE BUFF?", buff.name, buff:isActive())
    if buff:isActive() then
      table.insert(activeBuffs, buff)
    end
  end
  return activeBuffs
end
function BuffWidget:populate()
  print("Populate Buffs")
  self.buffs = GetActiveBuffs()
  self.entries = {}
  local offsetX = 0
  local offsetY = 0
  local priority = -1
  local height = 0
  local i = 0
  if #self.buffs > 0 then
    for _, v in ipairs(self.buffs) do
      local item = menu:addTemplateElement("template_buff", "entry" .. i, self)
      item.buff = v
      if i > 0 then
        offsetX = offsetX + self.spacing
      end
      item:setOrientation(lua_sys.MenuOrientation(offsetX, offsetY, priority, lua_sys.LEFT, lua_sys.VCENTER))
      item:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.VCENTER)
      item:init()
      item:setPositionBroadcast(true)
      item:postInit()
      offsetX = offsetX + item:absW()
      height = item:absH()
      i = i + 1
      table.insert(self.entries, item)
    end
  end
  if not self.Touch or not self.Swiper then
    self:setSize(lua_sys.Vector2(offsetX, height))
    self:GetVar("xOffset"):SetInt(self:GetVar("xOffset"):GetInt())
  end
  self.populated = true
  if not self.visible then
    self:Hide()
  end
  if self.alpha then
    MenuHelpers.ForEachEntry(self, function(entry)
      entry.Sprite:GetVar("alpha"):SetFloat(self.alpha)
    end)
  end
  if self.clipX then
    self:updateClipping()
  end
  if self.Touch and self.Swiper then
    self.scrollingList = ScrollingListHelperV2:new({
      direction = lua_sys.MenuSwipeComponent_SwipeDirectionHorizontal,
      Element = self,
      entries = self.entries
    })
  end
end
function BuffWidget:repopulate()
  MenuHelpers.ForEachEntry(self, function(entry)
    self:RemoveElement(entry)
  end)
  self:populate()
end
function BuffWidget:Show()
  print("== Show Buff Widget")
  self.visible = true
  MenuHelpers.ForEachEntry(self, function(entry)
    entry.Sprite:GetVar("visible"):SetInt(1)
    entry.Touch:GetVar("enabled"):SetInt(1)
  end)
end
function BuffWidget:setVisible()
  print("== Set Buffs Visible")
  self:Show()
end
function BuffWidget:Hide()
  print("== Hide Buff Widget")
  self.visible = false
  MenuHelpers.ForEachEntry(self, function(entry)
    entry.Sprite:GetVar("visible"):SetInt(0)
    entry.Touch:GetVar("enabled"):SetInt(0)
  end)
end
function BuffWidget:setInvisible()
  print("== Set Buffs Invisible")
  self:Hide()
end
function BuffWidget:update()
  MenuHelpers.ForEachEntry(self, function(entry)
    entry.Sprite:GetVar("alpha"):SetFloat(self.alpha)
  end)
end
function BuffWidget:enable()
  MenuHelpers.ForEachEntry(self, function(entry)
    entry.Sprite:setColor(1, 1, 1)
  end)
end
function BuffWidget:disable()
  MenuHelpers.ForEachEntry(self, function(entry)
    entry.Sprite:setColor(0.5, 0.5, 0.5)
  end)
end
function BuffWidget:updateClipping()
  MenuHelpers.ForEachEntry(self, function(entry)
    MenuHelpers.SetClipFrom(entry.Sprite, self)
  end)
end
return BuffWidget
