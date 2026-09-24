local BreedingRules = include("BreedingRules")
local BreedingMenu = {}
local MonsterList = {NewSelectedEntry = "", NumBreedable = 0}
function MonsterList:new(obj)
  local obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end
function MonsterList:populateBreedingEntries(entryPrefix, listString, breedableRuleFn)
  local breedingMonsters = game.worldContext():getAvailableBreedingMonsters()
  local previous
  local numBreedable = 0
  for i = 0, breedingMonsters:size() - 1 do
    local breedingMonster = breedingMonsters[i]
    if breedableRuleFn(breedingMonster) then
      local breedingEntry = menu:addTemplateElement("template_breedingentry", entryPrefix .. numBreedable, self)
      breedingEntry:V("List"):SetString(listString)
      breedingEntry:V("MonsterID"):SetInt(breedingMonster:uniqueId())
      breedingEntry:V("EntryNum"):SetInt(numBreedable)
      if previous == nil then
        breedingEntry:setParent(self)
        breedingEntry:setOrientation(lua_sys.MenuOrientation(16, 0, 4, lua_sys.HCENTER, lua_sys.TOP))
        breedingEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
      else
        breedingEntry:setParent(previous)
        breedingEntry:setOrientation(lua_sys.MenuOrientation(0, 14, 0, lua_sys.HCENTER, lua_sys.TOP))
        breedingEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.BOTTOM)
      end
      previous = breedingEntry
      numBreedable = numBreedable + 1
      breedingEntry:init()
      breedingEntry:setPositionBroadcast(true)
    end
  end
  self.NumBreedable = numBreedable
end
function MonsterList:super_selectNewEntry(otherEntryPrefix)
  local oldEntryName = self:V("SelectedEntry"):GetString()
  local newEntryName = self.NewSelectedEntry
  local numBreedable = self.NumBreedable - 1
  if oldEntryName ~= "" and oldEntryName ~= newEntryName then
    local oldEntry = self:parent():E(oldEntryName)
    oldEntry:E("bg"):C("GreySprite"):V("visible"):SetInt(1)
    oldEntry:E("bg"):C("YellowSprite"):V("visible"):SetInt(0)
    for i = 0, numBreedable do
      local otherEntry = self:parent():E(otherEntryPrefix .. i)
      if otherEntry ~= nil and game.monsterType(oldEntry:V("MonsterID"):GetInt()) == game.monsterType(otherEntry:V("MonsterID"):GetInt()) and game.monsterLevel(otherEntry:V("MonsterID"):GetInt()) > 3 then
        otherEntry:enableEntry()
      end
    end
  end
  if oldEntryName ~= newEntryName then
    local newEntry = self:parent():E(newEntryName)
    self:V("SelectedEntry"):SetString(newEntryName)
    self:V("SelectedEntryID"):SetInt(newEntry:V("MonsterID"):GetInt())
    if not game.isLegendaryShuggaIsland() then
      for i = 0, numBreedable do
        local otherEntry = self:parent():E(otherEntryPrefix .. i)
        if otherEntry ~= nil and game.monsterType(newEntry:V("MonsterID"):GetInt()) == game.monsterType(otherEntry:V("MonsterID"):GetInt()) then
          otherEntry:disableEntry()
        end
      end
    end
  end
end
local BreedingMenu = {
  LeftMonsterList = {},
  RightMonsterList = {},
  transitionState = 1,
  transitionTime = 0,
  lFrameEndX = 2 * game.menuScaleX(),
  rFrameEndX = 2 * game.menuScaleX(),
  torchFrameEndX = lua_sys.deviceMarginX(),
  executeBreedLeft = 0,
  executeBreedRight = 0
}
BreedingMenu.LeftMonsterList = MonsterList:new()
BreedingMenu.RightMonsterList = MonsterList:new()
function BreedingMenu:onInit()
  executeBreedLeft = 0
  executeBreedRight = 0
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgConfirmationSubmission", "gotMsgConfirmationSubmission")
end
function BreedingMenu:onPostInit()
  if game.playerLevel() < game.torchUnlockLevel() then
    self.BottomTorchFrame:C("Sprite"):V("visible"):SetInt(0)
    self.TorchAnim:C("Sprite"):V("visible"):SetInt(0)
    self.TorchText:C("Text"):V("visible"):SetInt(0)
  end
  self:setLeftListActive()
  if game.showBreedingPromoDesc() then
    game.displayNotification(game.breedingPromoDescription())
    game.setShowedBreedingPromoDesc()
  end
end
function BreedingMenu:onTick(dt)
  if self.transitionState ~= 0 then
    self:TickTransition()
    if self.transitionState == 1 then
      self.transitionTime = self.transitionTime + dt * 3
    elseif self.transitionState == 2 then
      self.transitionTime = self.transitionTime - dt * 3
    end
    if 1 < self.transitionTime then
      self.transitionState = 0
      self.transitionTime = 1
      self:TickTransition()
    elseif 0 > self.transitionTime then
      if executeBreedLeft ~= 0 and executeBreedRight ~= 0 then
        game.breed(executeBreedLeft, executeBreedRight)
      end
      self:root():popPopUp()
      game.setClipping("Clipping", 0, 0, lua_sys.screenWidth() * lua_sys.deviceScaleX(), lua_sys.screenHeight() * lua_sys.deviceScaleY())
    end
  end
end
function BreedingMenu:TickTransition()
  local frameL = self:GetElement("LeftMonsterBg")
  frameL("xOffset"):SetFloat(-(lua_sys.screenWidth() * 0.5 + -0.5 * lua_sys.screenWidth() * (1 / math.max(0.001, self.transitionTime))) + self.lFrameEndX)
  self:GetElement("RightMonsterBg")("xOffset"):SetFloat(lua_sys.screenWidth() * 0.5 + -0.5 * lua_sys.screenWidth() * (1 / math.max(0.001, self.transitionTime)) + self.rFrameEndX)
  self:GetElement("BottomTorchFrame")("xOffset"):SetFloat(lua_sys.screenWidth() * 0.5 + -0.5 * lua_sys.screenWidth() * (1 / math.max(0.001, self.transitionTime)) + self.torchFrameEndX)
  self:GetElement("SelectMonstersFrame")("xOffset"):SetFloat(lua_sys.screenWidth() * 0.5 + -0.5 * lua_sys.screenWidth() * (1 / math.max(0.001, self.transitionTime)))
  self.FadedBG.Sprite("alpha"):SetFloat(self.transitionTime * 0.5)
  game.setClipping("Clipping", 0, (frameL:absY() + frameL:parent():E("LeftTitleFrame"):absH()) * lua_sys.deviceScaleY(), lua_sys.screenWidth() * lua_sys.deviceScaleX(), (frameL:absH() - 60) * lua_sys.deviceScaleY())
end
function BreedingMenu:setLeftListActive()
  self.LeftMonsterList:C("Swiper"):enableScrolling()
  self.RightMonsterList:C("Swiper"):disableScrolling()
end
function BreedingMenu:setRightListActive()
  self.RightMonsterList:C("Swiper"):enableScrolling()
  self.LeftMonsterList:C("Swiper"):disableScrolling()
end
local getOverlappingGenes = function(monsterA, monsterB)
  local genesA = monsterA:sortedGenes()
  local overlappingGenes = {}
  for i = 1, #genesA do
    if monsterB:hasGene(genesA:sub(i, i)) then
      table.insert(overlappingGenes, genesA:sub(i, i))
    end
  end
  return overlappingGenes
end
local function hasOverlappingGenes(monsterA, monsterB)
  return #getOverlappingGenes(monsterA, monsterB) > 0
end
local hasAllCombinations = function(monsterA, monsterB)
  local monsterAId = monsterA:monsterId()
  local monsterBId = monsterB:monsterId()
  local possibleResults = game.getPossibleBreedResults(monsterAId, monsterBId)
  local hasAllCombos = true
  for i = 0, possibleResults:size() - 1 do
    local result = possibleResults[i]
    if (result ~= monsterAId or result ~= monsterBId) and not game.hasOrHasEverHadMonsterOnActiveIsland(result) then
      hasAllCombos = false
      break
    end
  end
  return hasAllCombos
end
local getIslandMonsters = function()
  local islandMonsters = {}
  local monsters = game.player():getActiveIsland():monsters()
  for i = 0, monsters:size() - 1 do
    table.insert(islandMonsters, {
      id = monsters[i],
      type = game.monsterTypeId(monsters[i]),
      level = game.monsterLevel(monsters[i]),
      data = game.getMonsterDataFromUniqueId(monsters[i])
    })
  end
  return islandMonsters
end
local function getBreedingOpportunities()
  local generateKey = function(monsterTypeA, monsterTypeB, resultType)
    if monsterTypeA < monsterTypeB then
      return monsterTypeA .. "_" .. monsterTypeB .. "_" .. resultType
    else
      return monsterTypeB .. "_" .. monsterTypeA .. "_" .. resultType
    end
  end
  local count = 0
  local breedingOpportunities = {}
  local islandMonsters = getIslandMonsters()
  local checkedMonsterTypes = {}
  for i = 1, #islandMonsters do
    local monster = islandMonsters[i]
    local monsterType = monster.type
    if not checkedMonsterTypes[monsterType] then
      checkedMonsterTypes[monsterType] = true
      for j = 1, #islandMonsters do
        local otherMonster = islandMonsters[j]
        if monsterType ~= otherMonster.type then
          local possibleResults = game.getPossibleBreedResults(monster.type, otherMonster.type)
          for k = 0, possibleResults:size() - 1 do
            if not game.hasOrHasEverHadMonsterOnActiveIsland(possibleResults[k]) then
              local key = generateKey(monster.type, otherMonster.type, possibleResults[k])
              if breedingOpportunities[key] == nil then
                breedingOpportunities[key] = {
                  monsterA = monster,
                  monsterB = otherMonster,
                  result = possibleResults[k]
                }
                count = count + 1
              end
            end
          end
        end
      end
    end
  end
  return breedingOpportunities, count
end
local hasAllPurchaseableSingles = function()
  local island = game.player():getActiveIsland()
  local commonMonsters = game.getAllMonstersForBookOfMonstersIslandByRarity(island:id()):get(0)
  for i = 0, commonMonsters:size() - 1 do
    local monsterId = commonMonsters[i]
    local monster = game.getMonsterData(monsterId)
    if #monster:unsortedGenes() == 1 and island:monsterTypeCount(monsterId) == 0 and game.monsterIsAvail(monsterId, false) then
      return false
    else
    end
  end
  return true
end
local function checkBreeding(monsterUidA, monsterUidB)
  if game.playerLevel() > 10 then
    return true
  end
  local monsterA = game.getMonsterDataFromUniqueId(monsterUidA)
  local monsterB = game.getMonsterDataFromUniqueId(monsterUidB)
  if monsterA and monsterB then
    local overlappingGenes = getOverlappingGenes(monsterA, monsterB)
    if #overlappingGenes > 0 then
      local warningPopup = game.pushPopUp("popup_breed_warning")
      warningPopup:setup("NOTIFICATION_OVERLAPPING_GENES", monsterA, monsterB, overlappingGenes)
      return false
    end
    if hasAllCombinations(monsterA, monsterB) then
      local breedingOpportunities, total = getBreedingOpportunities()
      if total > 0 then
        local canBreed = false
        for _, breedingOpportunity in pairs(breedingOpportunities) do
          if breedingOpportunity.monsterA.level >= 4 and 4 <= breedingOpportunity.monsterB.level then
            canBreed = true
            break
          end
        end
        if canBreed then
          local warningPopup = game.pushPopUp("popup_breed_warning")
          warningPopup:setup("NOTIFICATION_REPEATED_BREEDING", monsterA, monsterB)
        else
          local warningPopup = game.pushPopUp("popup_breed_warning")
          warningPopup:setup("NOTIFICATION_REPEATED_BREEDING_SHOULD_FEED", monsterA, monsterB)
        end
        return false
      else
      end
      if not hasAllPurchaseableSingles() then
        local warningPopup = game.pushPopUp("popup_breed_warning")
        warningPopup:setup("NOTIFICATION_REPEATED_BREEDING", monsterA, monsterB)
        return false
      end
    else
    end
  else
  end
  return true
end
function BreedingMenu:breed()
  executeBreedLeft = self.LeftMonsterList:V("SelectedEntryID"):GetInt()
  executeBreedRight = self.RightMonsterList:V("SelectedEntryID"):GetInt()
  if checkBreeding(executeBreedLeft, executeBreedRight) then
    if executeBreedLeft ~= 0 and executeBreedRight ~= 0 then
      game.popPopUp()
      manager:setContext(manager:getDefaultContext())
    else
      game.displayNotification("BREED_ERROR_SELECT_TWO_MONSTERS")
      executeBreedLeft = 0
      executeBreedRight = 0
    end
  end
end
function BreedingMenu:queuePop()
  if game.topPopUp() == self then
    self.transitionState = 2
  end
end
function BreedingMenu:gotMsgConfirmationSubmission(msg)
  if msg.messageID == "BREED_WARNING" then
    if msg.choice == true then
      game.popPopUp()
      manager:setContext(manager:getDefaultContext())
    else
      executeBreedLeft = 0
      executeBreedRight = 0
    end
  end
end
function BreedingMenu.LeftMonsterList:onInit()
  self:V("SelectedEntry"):SetString("")
  self:V("SelectedEntryID"):SetInt(0)
  self.NewSelectedEntry = ""
  self:populateBreedingEntries("leftBreedingEntry", "LeftMonsterList", BreedingRules.BreedableOnLeft)
end
function BreedingMenu.LeftMonsterList:selectNewEntry()
  self:super_selectNewEntry("rightBreedingEntry")
end
function BreedingMenu.LeftMonsterList:entryTouched()
  self:parent():setLeftListActive()
end
function BreedingMenu.RightMonsterList:onInit()
  self:V("SelectedEntry"):SetString("")
  self:V("SelectedEntryID"):SetInt(0)
  self.NewSelectedEntry = ""
  self:populateBreedingEntries("rightBreedingEntry", "RightMonsterList", BreedingRules.BreedableOnRight)
end
function BreedingMenu.RightMonsterList:selectNewEntry()
  self:super_selectNewEntry("leftBreedingEntry")
end
function BreedingMenu.RightMonsterList:entryTouched()
  self:parent():setRightListActive()
end
return BreedingMenu
