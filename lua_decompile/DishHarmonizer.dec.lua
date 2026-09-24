local MenuHelpers = include("MenuHelpers")
local MenuElementPositionOffsetTransition = include("MenuElementPositionOffsetTransition")
local sort = include("sort")
local ScrollingListHelper = include("ScrollingListHelper")
local DishHarmonizer = {
  MonsterSelect = {
    List = {
      SelectedEntry = "",
      SelectedEnntryId = 0,
      Swiper = {}
    },
    ScrollBar = {},
    ScrollMarker = {
      Touch = {}
    }
  },
  GeneCounters = {},
  DishHarmonizerPanel = {
    StructureAnim = {
      Sprite = {}
    },
    MonsterAnim = {
      Sprite = {}
    }
  }
}
function DishHarmonizer:onPostInit()
  self.monsterAnimShowDelay = 0
  self.MonsterSelect:V("Refresh"):SetInt(1)
  self:populateGeneCounters()
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgDishHarmonizerDataUpdated", "gotMsgDishHarmonizerDataUpdated")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgConfirmationSubmission", "gotMsgConfirmationSubmission")
  local targetSheet = "dishharmonizer_" .. game.GetIsletPrimaryGeneName(game.currentIsland()) .. "_sheet.xml"
  game.remapMenuAnim(self.DishHarmonizerPanel.StructureAnim.Sprite, "dishharmonizer_plasma_sheet.xml", targetSheet)
end
function DishHarmonizer:MonsterSelected(monsterId)
  local monsterType = game.monsterTypeId(monsterId)
  local genes = game.monsterTypeGenes(monsterType)
  local dishHarmonizer = game.SelectedObject()
  local cost = dishHarmonizer:getCost(#genes)
  self:E("Cost"):C("Text"):V("text"):SetString(cost)
  self.cost = cost
  local monsterAnim = self.DishHarmonizerPanel.MonsterAnim.Sprite
  local currentGfx = monsterAnim:V("animationName"):GetString()
  local selectedGfx = "xml_bin/" .. game.getMonsterAnimationFileFromType(monsterType)
  if currentGfx ~= selectedGfx then
    monsterAnim:V("animationName"):SetString(selectedGfx)
    monsterAnim:V("animation"):SetString(game.getMonsterAnimationNameFromType(monsterType))
    monsterAnim:V("visible"):SetInt(0)
    self.monsterAnimShowDelay = 1
  end
  lua_sys.playSoundFx("audio/sfx/structure_dishharmonizer_menu_selectmonster.ogg")
end
function DishHarmonizer:startDishHarmonizing()
  local selectedMonsterID = self:getSelectedMonster()
  if selectedMonsterID == 0 then
    game.displayNotification("NOTIFICATION_DISH_HARMONIZER_SELECT_MONSTER")
  else
    local monster = game.GetMonster(selectedMonsterID)
    local monsterData = monster:data()
    local isRareMonster = monsterData:isRareMonster()
    local hasAvailableRare = false
    if isRareMonster then
      local rareMonsters = game.getAllUniqueMonsterIdsForIslandTypeByRarity(game.currentIslandType(), 0, 1)
      for i = 0, rareMonsters:size() - 1 do
        local monsterType = rareMonsters[i]
        local isAvailable = game.monsterIsAvail(monsterType, false)
        if isAvailable then
          hasAvailableRare = true
          break
        end
      end
      if hasAvailableRare then
        self:dishHarmonizeMonster()
      else
        game.displayConfirmation("NO_RARES_AVAILABLE", "CONFIRMATION_DISH_HARMONIZER_NO_RARES_AVAILABLE")
      end
    else
      self:dishHarmonizeMonster()
    end
  end
end
function DishHarmonizer:gotMsgConfirmationSubmission(msg)
  if msg.messageID == "NO_RARES_AVAILABLE" and msg.choice == true then
    self:dishHarmonizeMonster()
  end
end
function DishHarmonizer:dishHarmonizeMonster()
  local selectedMonsterID = self:getSelectedMonster()
  if game.clearPurchase(game.CurrencyType_Shards, self.cost, game.PurchaseType_DISHHARMONIZING, game.monsterEntityId(selectedMonsterID)) and game.SelectedObject():isDishHarmonizer() then
    game.SelectedObject():startDishHarmonizing(selectedMonsterID)
    manager:setContext(manager:getDefaultContext())
    game.deselectSelectedObject()
    self:Hide()
  end
end
function DishHarmonizer:getSelectedMonster()
  return self.MonsterSelect.List:V("NewSelectedEntryID"):GetInt()
end
function DishHarmonizer:testDishHarmonizing()
  local selectedMonsterID = self.MonsterSelect.List:V("NewSelectedEntryID"):GetInt()
  if selectedMonsterID == 0 then
    game.displayNotification("NOTIFICATION_DISH_HARMONIZER_SELECT_MONSTER")
  elseif game.SelectedObject():isDishHarmonizer() then
    game.SelectedObject():testDishHarmonizing(selectedMonsterID)
  end
end
function DishHarmonizer:ShowTargets()
  self.showTargets = true
  manager:setContext("BLANK")
  self:Hide()
end
function DishHarmonizer:onInit()
  self.cost = 0
  self.showTargets = false
  MenuElementPositionOffsetTransition.OnInit(self:E("bg"), {
    startY = lua_sys.screenHeight() * 2,
    endY = -6 * game.hudScale(),
    duration = 0.66
  })
  self:Show()
end
function DishHarmonizer:onTick(dt)
  local options = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
      e:root():popPopUp()
      if self.showTargets then
        manager:setContext("DISH_HARMONIZER_TARGETS")
      end
    end
  }
  MenuElementPositionOffsetTransition.OnTick(self:E("bg"), dt, options)
  if self.monsterAnimShowDelay > 0 then
    self.monsterAnimShowDelay = self.monsterAnimShowDelay - 1
    if self.monsterAnimShowDelay == 0 then
      self.DishHarmonizerPanel.MonsterAnim.Sprite:V("visible"):SetInt(1)
    end
  end
end
function DishHarmonizer:Show()
  MenuElementPositionOffsetTransition.Show(self:E("bg"))
  lua_sys.playSoundFx("audio/sfx/structure_dishharmonizer_menu_open.ogg")
end
function DishHarmonizer:Hide()
  MenuElementPositionOffsetTransition.Hide(self:E("bg"))
  self:E("Fade"):DoStoredScript("Hide")
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function DishHarmonizer:queuePop()
  self:Hide()
end
function DishHarmonizer.MonsterSelect:onInit()
  self:V("IsShowing"):SetInt(0)
  self:V("Refresh"):SetInt(0)
  self.List:V("scrollOffset"):SetFloat(0)
end
function DishHarmonizer.MonsterSelect:onTick(dt)
  if self:V("Refresh"):GetInt() == 1 then
    self.List:DoStoredScript("populate")
    self:V("Refresh"):SetInt(0)
  end
end
function DishHarmonizer.MonsterSelect.List:onInit()
  self("NewSelectedEntry"):SetString("")
  self("NewSelectedEntryID"):SetInt(0)
  ScrollingListHelper.ListInit(self, {
    direction = lua_sys.MenuSwipeComponent_SwipeDirectionVertical,
    spacing = 10 * game.menuScaleX(),
    padding = 0
  })
end
function DishHarmonizer.MonsterSelect:ListPopulate(element)
  ScrollingListHelper.ListClear(element)
  local availableMonsters = game.worldContext():availableDishHarmonizerMonsters()
  local numMonsters = availableMonsters:size()
  local monstersTable = {}
  for i = 0, numMonsters - 1 do
    local monster = availableMonsters[i]
    monstersTable[#monstersTable + 1] = monster
  end
  local monsterCompare = function(m1, m2)
    local monsterType1 = game.monsterTypeId(m1)
    local genes1 = game.monsterTypeGenes(monsterType1)
    local monsterType2 = game.monsterTypeId(m2)
    local genes2 = game.monsterTypeGenes(monsterType2)
    if string.len(genes1) == string.len(genes2) then
      if genes1 == genes2 then
        return game.monsterEntityId(m1) < game.monsterEntityId(m2)
      else
        return genes1 < genes2
      end
    end
    return string.len(genes1) > string.len(genes2)
  end
  sort.stable_sort(monstersTable, monsterCompare)
  local function createFunc(idx, itemName)
    local monsterId = monstersTable[idx + 1]
    local entryName = ScrollingListHelper.ListCreateEntryName(element)
    monsterEntry = menu:addTemplateElement("template_monster_dish_harmonizer_entry", entryName, element)
    monsterEntry("MonsterID"):SetInt(monsterId)
    monsterEntry("List"):SetString("List")
    monsterEntry("Layer"):SetString("MidPopUps")
    monsterEntry:init()
    monsterEntry("selected"):SetInt(0)
    return monsterEntry
  end
  ScrollingListHelper.ListPopulate(element, numMonsters, createFunc)
  if element:GetVar("totalSize"):GetFloat() < element:absH() then
    local parent = element:parent()
    parent.ScrollBar.Sprite:GetVar("visible"):SetInt(0)
    parent.ScrollMarker.Marker:GetVar("visible"):SetInt(0)
    parent.ScrollMarker.Touch:GetVar("enabled"):SetInt(0)
  end
end
function DishHarmonizer.MonsterSelect.List:onTick(dt)
  ScrollingListHelper.ListTick(self, dt)
  MenuHelpers.ForEachEntry(self, function(entry)
    entry("clipX"):SetFloat(self:absX())
    entry("clipY"):SetFloat(self:absY())
    entry("clipW"):SetFloat(self:absW())
    entry("clipH"):SetFloat(self:absH())
    entry:DoStoredScript("updateClipping")
  end)
end
function DishHarmonizer.MonsterSelect.List:ListSelectNewEntry(element)
  local selectedMonsterID = element("NewSelectedEntryID"):GetInt()
  self:parent():parent():MonsterSelected(selectedMonsterID)
  local oldEntryName = self.SelectedEntry
  local newEntryName = self("NewSelectedEntry"):GetString()
  if oldEntryName ~= "" and oldEntryName ~= newEntryName then
    local oldEntry = self:parent():E(oldEntryName)
    oldEntry:DoStoredScript("deselect")
  end
  if oldEntryName ~= newEntryName then
    local newEntry = self:parent():E(newEntryName)
    newEntry:DoStoredScript("select")
    self:V("SelectedEntry"):SetString(newEntryName)
    self:V("SelectedEntryID"):SetInt(newEntry:V("MonsterID"):GetInt())
  end
  self.SelectedEntry = self("NewSelectedEntry"):GetString()
end
function DishHarmonizer.MonsterSelect.List:ListSelectDisabledEntry(element)
end
function DishHarmonizer.MonsterSelect.List.Swiper:onInit(element)
  self("smoothMode"):SetInt(1)
end
function DishHarmonizer.MonsterSelect.List.Swiper:onTick(element, dt)
  ScrollingListHelper.SwiperTick(self, element, dt)
  local scrollOffset = element("scrollOffset"):GetFloat()
  local scrollMarker = element:parent().ScrollMarker
  local originalYOffset = scrollMarker("originalYOffset"):GetInt()
  local markerMovementHeight = element:parent().ScrollBar:absH() - 2 * originalYOffset - scrollMarker:absH()
  local scrollMarkerYOffset = 0
  if self:scrollSize() ~= 0 then
    scrollMarkerYOffset = -(scrollOffset / self:scrollSize()) * markerMovementHeight
  end
  scrollMarkerYOffset = lua_sys.clamp(scrollMarkerYOffset, 0, markerMovementHeight)
  scrollMarker("yOffset"):SetInt(originalYOffset + scrollMarkerYOffset)
end
function DishHarmonizer.MonsterSelect.List.Swiper:refresh(element)
  ScrollingListHelper.SwiperRefresh(self, element)
end
function DishHarmonizer.MonsterSelect.List.Swiper:setSwiperScrollOffset()
  local scrollmarker = self:parent():parent().ScrollMarker
  local offset = scrollmarker:V("scrollOffset"):GetFloat()
  self:setScrollOffset(offset)
end
function DishHarmonizer.MonsterSelect.List.Swiper:setScrollOffsetToMarker()
  local scrollmarker = self:parent():parent().ScrollMarker
  self:setScrollOffset(scrollmarker("scrollOffset"):GetFloat())
end
function DishHarmonizer.MonsterSelect.ScrollMarker:onInit()
  self("scrollOffset"):SetFloat(0)
  self("originalYOffset"):SetInt(self("yOffset"):GetInt())
end
function DishHarmonizer.MonsterSelect.ScrollMarker.Touch:onTouchDrag(element, x, y)
  local listElement = element:parent().List
  local scrollBarElement = element:parent().ScrollBar
  local originalYOffset = element("originalYOffset"):GetInt()
  local fromTopOfMarkerRange = y - scrollBarElement:absY() - originalYOffset
  local scrollSize = listElement("totalSize"):GetFloat() - (listElement:absH() - listElement("padding"):GetFloat())
  local scrollOffset = scrollSize * (-(fromTopOfMarkerRange - originalYOffset) / (scrollBarElement:absH() - 2 * originalYOffset - element:absH()))
  scrollOffset = lua_sys.clamp(scrollOffset, -scrollSize, 0)
  element("scrollOffset"):SetFloat(scrollOffset)
  listElement.Swiper:setScrollOffsetToMarker()
end
function DishHarmonizer:populateGeneCounters()
  local dishHarmonizer = game.SelectedObject()
  local genes = dishHarmonizer:getBaseGenes() .. dishHarmonizer:getMissingGene() .. dishHarmonizer:getPrimaryGene()
  local root = self.GeneCounters
  local entries = {}
  for i = 1, #genes do
    local gene = genes:sub(i, i)
    local vars = {
      spriteName = game.critterSprite(gene),
      scale = game.menuScaleX()
    }
    local entry = menu:addTemplateElementEx("template_dish_harmonizer_gene_counter", "counter_" .. gene, root, vars)
    table.insert(entries, entry)
    entry:relativeTo(root)
    entry:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.VCENTER)
    entry:setOrientation(lua_sys.MenuOrientation(0, 0, -1, lua_sys.LEFT, lua_sys.TOP))
    entry:init()
    entry.gene = gene
    if gene == dishHarmonizer:getPrimaryGene() then
      entry:setInfinite()
    else
      if game.isQABuild() then
        entry:enableTestUI()
      end
      entry:setCounter(game.SelectedObject():getNumGenes(gene))
    end
    entry:setPositionBroadcast(true)
    entry:postInit()
  end
  MenuHelpers.CenterVertically(entries)
end
function DishHarmonizer:gotMsgDishHarmonizerDataUpdated(msg)
  if game.isQABuild() then
    local dishHarmonizer = game.SelectedObject()
    if dishHarmonizer then
      local genes = dishHarmonizer:getBaseGenes() .. dishHarmonizer:getMissingGene() .. dishHarmonizer:getPrimaryGene()
      for i = 1, #genes do
        local gene = genes:sub(i, i)
        local entry = self.GeneCounters:E("counter_" .. gene)
        if gene ~= dishHarmonizer:getPrimaryGene() then
          entry:setCounter(game.SelectedObject():getNumGenes(gene))
        end
      end
    end
  end
end
return DishHarmonizer
