local MenuHelpers = include("MenuHelpers")
local MenuElementPositionOffsetTransition = include("MenuElementPositionOffsetTransition")
local sort = include("sort")
local ScrollingListHelper = include("ScrollingListHelper")
local MonsterProperties = include("MonsterProperties")
local Fugue = {
  startFuguing = false,
  MonsterSelect = {
    List = {
      SelectedEntry = "",
      SelectedEntryID = 0,
      Swiper = {}
    },
    ScrollBar = {},
    ScrollMarker = {
      Touch = {}
    }
  },
  Cost = {
    Text = {}
  },
  RightPanel = {
    MonsterAnim = {
      Sprite = {}
    },
    Mirror = {
      Sprite = {}
    }
  }
}
function Fugue:onPostInit()
  self.MonsterSelect:V("Refresh"):SetInt(1)
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgConfirmationSubmission", "gotMsgConfirmationSubmission")
end
function Fugue:MonsterSelected(monsterId)
  local monster = game.GetMultiMonster(monsterId)
  self.selectedMonster = monsterId
  local monsterData = monster:data()
  local currentMode = game.player():getActiveIsland():islandMode()
  local multiMonsterData = game.getModalMonsterData(monsterData, currentMode)
  local monsterType = multiMonsterData:monsterId()
  local monsterAnim = self.RightPanel.MonsterAnim.Sprite
  monsterAnim:V("visible"):SetInt(1)
  local animFile = multiMonsterData:animationFile()
  monsterAnim:V("animationName"):SetString("xml_bin/" .. animFile)
  monsterAnim:V("animation"):SetString(game.getMonsterAnimationNameFromType(monsterType))
  local monster = game.GetMonster(monsterId)
  local costumeId = monster:getEquippedCostume()
  if costumeId > 0 then
    game.applyCostumeToAnimComponent(monsterAnim, costumeId)
  end
  local facing = MonsterProperties.getFacing(monsterType)
  monsterAnim:GetVar("hFlip"):SetInt(facing)
  monsterAnim:GetVar("offsetCenter"):SetInt(1)
  local monster = game.getMonsterByEntityId(game.getMonsterData(monsterType):evolvesInto()):monsterId()
  if monster == 0 then
    monster = monsterType
  end
  self.currentCost = game.Fugue_fuguingCost(monsterData:unsortedGenes():len())
  self.Cost.Text:V("text"):SetString(self.currentCost)
  lua_sys.playSoundFx("audio/sfx/item_select.wav")
end
function Fugue:fugueMonster()
  local selectedMonsterID = self:getSelectedMonster()
  if game.SelectedObject():isFugue() then
    if selectedMonsterID == 0 then
      game.displayNotification("NOTIFICATION_FUGUE_SELECT_MONSTER")
    else
      local confirmMenu = game.pushPopUp("fugue_confirmation")
      confirmMenu:setCost(self.currentCost)
    end
  end
end
function Fugue:getSelectedMonster()
  return self.MonsterSelect.List.SelectedEntryID
end
function Fugue:onInit()
  self.monsterRarity = game.MonsterRarity_Common
  MenuElementPositionOffsetTransition.OnInit(self:E("bg"), {
    startY = lua_sys.screenHeight() * 1,
    endY = -20 * game.menuScaleX(),
    duration = 0.33
  })
  MenuElementPositionOffsetTransition.OnInit(self:E("StarCounter"), {
    startX = 10 * game.menuScaleX(),
    endX = 10 * game.menuScaleX(),
    startY = lua_sys.screenHeight() * -1,
    endY = 10 * game.menuScaleX(),
    duration = 0.33
  })
  self:Show()
end
function Fugue:onTick(dt)
  local options = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
      if self.startFuguing then
        game.SelectedObject():startFuguing(self:getSelectedMonster())
      end
      e:root():popPopUp()
    end
  }
  MenuElementPositionOffsetTransition.OnTick(self:E("bg"), dt, options)
  local starCounterOptions = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
    end
  }
  MenuElementPositionOffsetTransition.OnTick(self:E("StarCounter"), dt, starCounterOptions)
end
function Fugue:Show()
  MenuElementPositionOffsetTransition.Show(self:E("bg"))
  MenuElementPositionOffsetTransition.Show(self:E("StarCounter"))
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function Fugue:Hide()
  MenuElementPositionOffsetTransition.Hide(self:E("bg"))
  MenuElementPositionOffsetTransition.Hide(self:E("StarCounter"))
  self:E("Fade"):DoStoredScript("Hide")
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function Fugue:queuePop()
  self:Hide()
end
function Fugue.MonsterSelect:onInit()
  self:V("IsShowing"):SetInt(0)
  self:V("Refresh"):SetInt(0)
  self.List:V("scrollOffset"):SetFloat(0)
end
function Fugue.MonsterSelect:onTick(dt)
  if self:V("Refresh"):GetInt() == 1 then
    self.List:DoStoredScript("populate")
    self:V("Refresh"):SetInt(0)
  end
end
function Fugue.MonsterSelect.List:onInit()
  self("NewSelectedEntry"):SetString("")
  self("NewSelectedEntryID"):SetInt(0)
  ScrollingListHelper.ListInit(self, {
    direction = lua_sys.MenuSwipeComponent_SwipeDirectionVertical,
    spacing = 10 * game.menuScaleX(),
    padding = 0
  })
end
function Fugue.MonsterSelect:ListPopulate(element)
  ScrollingListHelper.ListClear(element)
  local availableMonsters = game.worldContext():availableFugueMonsters()
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
      local monster1 = game.GetMonster(m1)
      local monster2 = game.GetMonster(m2)
      return monster1:level() > monster2:level()
    end
    return string.len(genes1) > string.len(genes2)
  end
  sort.stable_sort(monstersTable, monsterCompare)
  local function createFunc(idx, itemName)
    local monsterId = monstersTable[idx + 1]
    local entryName = ScrollingListHelper.ListCreateEntryName(element)
    monsterEntry = menu:addTemplateElement("template_monster_synthesizing_entry", entryName, element)
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
function Fugue:gotMsgConfirmationSubmission(msg)
  if msg.messageID == "START_FUGUE" and msg.choice == true then
    manager:setContext("BLANK")
    self.startFuguing = true
    self:Hide()
  end
end
function Fugue:testFugueChance()
  local selectedMonsterID = self.MonsterSelect.List:V("NewSelectedEntryID"):GetInt()
  if selectedMonsterID == 0 then
    game.displayNotification("NOTIFICATION_FUGUE_SELECT_MONSTER")
  else
    game.testFugueChance(game.FindFugue():uniqueId(), self:getSelectedMonster())
  end
end
function Fugue.MonsterSelect.List:onTick(dt)
  ScrollingListHelper.ListTick(self, dt)
  MenuHelpers.ForEachEntry(self, function(entry)
    entry("clipX"):SetFloat(self:absX())
    entry("clipY"):SetFloat(self:absY())
    entry("clipW"):SetFloat(self:absW())
    entry("clipH"):SetFloat(self:absH())
    entry:DoStoredScript("updateClipping")
  end)
end
function Fugue.MonsterSelect.List:ListSelectNewEntry(element)
  local selectedMonsterID = element("NewSelectedEntryID"):GetInt()
  self:parent():parent():MonsterSelected(selectedMonsterID)
  local oldEntryName = self.SelectedEntry
  local newEntryName = self("NewSelectedEntry"):GetString()
  if oldEntryName ~= "" then
    local oldEntry = self:parent():E(oldEntryName)
    oldEntry:DoStoredScript("deselect")
  end
  if oldEntryName == newEntryName then
    self:parent():parent().RightPanel.MonsterAnim.Sprite:V("visible"):SetInt(0)
    self.SelectedEntryID = 0
    self.SelectedEntry = ""
  else
    local newEntry = self:parent():E(newEntryName)
    newEntry:DoStoredScript("select")
    self.SelectedEntry = newEntryName
    self.SelectedEntryID = newEntry:V("MonsterID"):GetInt()
    self:parent():parent().RightPanel.MonsterAnim.Sprite:V("visible"):SetInt(1)
  end
end
function Fugue.MonsterSelect.List:ListSelectDisabledEntry(element)
end
function Fugue.MonsterSelect.List.Swiper:onInit(element)
  self("smoothMode"):SetInt(1)
end
function Fugue.MonsterSelect.List.Swiper:onTick(element, dt)
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
function Fugue.MonsterSelect.List.Swiper:refresh(element)
  ScrollingListHelper.SwiperRefresh(self, element)
end
function Fugue.MonsterSelect.List.Swiper:setSwiperScrollOffset()
  local scrollmarker = self:parent():parent().ScrollMarker
  local offset = scrollmarker:V("scrollOffset"):GetFloat()
  self:setScrollOffset(offset)
end
function Fugue.MonsterSelect.List.Swiper:setScrollOffsetToMarker()
  local scrollmarker = self:parent():parent().ScrollMarker
  self:setScrollOffset(scrollmarker("scrollOffset"):GetFloat())
end
function Fugue.MonsterSelect.ScrollMarker:onInit()
  self("scrollOffset"):SetFloat(0)
  self("originalYOffset"):SetInt(self("yOffset"):GetInt())
end
function Fugue.MonsterSelect.ScrollMarker.Touch:onTouchDrag(element, x, y)
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
return Fugue
