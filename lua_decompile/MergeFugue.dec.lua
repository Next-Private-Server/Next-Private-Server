local MenuHelpers = include("MenuHelpers")
local MenuElementPositionOffsetTransition = include("MenuElementPositionOffsetTransition")
local sort = include("sort")
local ScrollingListHelper = include("ScrollingListHelper")
local MergeFugue = {
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
  TitleFrame = {
    Text = {}
  },
  MonsterAnim = {
    Sprite = {}
  },
  LevelSprite = {
    Sprite = {}
  }
}
function MergeFugue:onPostInit()
  local monsterId = game.selectedMonsterId()
  self.startMonster = monsterId
  local text = game.getLocalizedText("MERGE_FUGUE_DESC")
  local monsterText = game.getMonsterName(monsterId)
  if string.len(monsterText) > 9 then
    monsterText = string.sub(monsterText, 0, 8) .. "..."
  end
  text = text:gsub("%${MONSTER}", monsterText)
  self.Description:C("Text"):V("text"):SetString(text)
  local titleText = self.TitleFrame.Text
  titleText:V("size"):SetFloat(0.3 * game.menuScaleX())
  titleText:V("textPadding"):SetInt(3 * game.menuScaleX())
  titleText:V("font"):Set(game.getTextFont())
  titleText:V("alignment"):SetInt(lua_sys.MenuTextComponent_TEXT_HCENTER_ALIGNED)
  titleText:V("layer"):SetString("MidPopUps")
  titleText:V("text"):SetString(monsterText)
  self.MonsterSelect:V("Refresh"):SetInt(1)
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgConfirmationSubmission", "gotMsgConfirmationSubmission")
  local monster = game.GetMultiMonster(monsterId)
  local monsterData = monster:data()
  local currentMode = game.player():getActiveIsland():islandMode()
  local otherMode = 1 - currentMode
  local otherMonsterData = game.getModalMonsterData(monsterData, otherMode)
  local monsterType = otherMonsterData:monsterId()
  local monsterAnim = self.MonsterAnim.Sprite
  local animFile = otherMonsterData:animationFile()
  monsterAnim:V("animationName"):SetString("xml_bin/" .. animFile)
  monsterAnim:V("animation"):SetString(game.getMonsterAnimationNameFromType(monsterType))
  monsterAnim:setScale(lua_sys.Vector2(0.7 * game.menuScaleX(), 0.7 * game.menuScaleX()))
  monsterAnim:V("layer"):SetString("MidPopUps")
  local otherMonster = monster:getModeMonster(otherMode)
  local costumeId = otherMonster:getEquippedCostume()
  if costumeId > 0 then
    game.applyCostumeToAnimComponent(monsterAnim, costumeId)
  end
  local spriteString = "monster_level_numbers_"
  local level = game.monsterLevel(monsterId)
  if level < 10 then
    spriteString = spriteString .. "0"
  end
  self.LevelSprite.Sprite:V("spriteName"):SetString(spriteString .. level)
end
function MergeFugue:MonsterSelected(monsterId)
  self.selectedMonster = monsterId
end
function MergeFugue:fugueMonster()
  local selectedMonsterID = self:getSelectedMonster()
  if selectedMonsterID == 0 then
    game.displayNotification("NOTIFICATION_MERGE_FUGUE_SELECT_MONSTER")
  else
    game.mergeFugue(self.startMonster, self.selectedMonster)
    self:Hide()
  end
end
function MergeFugue:getSelectedMonster()
  return self.MonsterSelect.List.SelectedEntryID
end
function MergeFugue:onInit()
  self.monsterRarity = game.MonsterRarity_Common
  MenuElementPositionOffsetTransition.OnInit(self:E("bg"), {
    startX = -30 * game.menuScaleX(),
    endX = -30 * game.menuScaleX(),
    startY = lua_sys.screenHeight() * 2,
    endY = -20 * game.menuScaleX(),
    duration = 0.66
  })
  self:Show()
end
function MergeFugue:onTick(dt)
  local options = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
      e:root():popPopUp()
    end
  }
  MenuElementPositionOffsetTransition.OnTick(self:E("bg"), dt, options)
end
function MergeFugue:Show()
  MenuElementPositionOffsetTransition.Show(self:E("bg"))
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function MergeFugue:Hide()
  MenuElementPositionOffsetTransition.Hide(self:E("bg"))
  self:E("Fade"):DoStoredScript("Hide")
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function MergeFugue:queuePop()
  self:Hide()
end
function MergeFugue.MonsterSelect:onInit()
  self:V("IsShowing"):SetInt(0)
  self:V("Refresh"):SetInt(0)
  self.List:V("scrollOffset"):SetFloat(0)
end
function MergeFugue.MonsterSelect:onTick(dt)
  if self:V("Refresh"):GetInt() == 1 then
    self.List:DoStoredScript("populate")
    self:V("Refresh"):SetInt(0)
  end
end
function MergeFugue.MonsterSelect.List:onInit()
  self("NewSelectedEntry"):SetString("")
  self("NewSelectedEntryID"):SetInt(0)
  ScrollingListHelper.ListInit(self, {
    direction = lua_sys.MenuSwipeComponent_SwipeDirectionVertical,
    spacing = 10 * game.menuScaleX(),
    padding = 0
  })
end
function MergeFugue.MonsterSelect:ListPopulate(element)
  ScrollingListHelper.ListClear(element)
  local uniqueMonsterId = game.selectedMonsterId()
  local availableMonsters = game.worldContext():availableMergeFugueMonsters(uniqueMonsterId)
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
function MergeFugue:gotMsgConfirmationSubmission(msg)
  if msg.messageID == "START_MergeFugue" and msg.choice == true then
    manager:setContext("BLANK")
    self:Hide()
  end
end
function MergeFugue.MonsterSelect.List:onTick(dt)
  ScrollingListHelper.ListTick(self, dt)
  MenuHelpers.ForEachEntry(self, function(entry)
    entry("clipX"):SetFloat(self:absX())
    entry("clipY"):SetFloat(self:absY())
    entry("clipW"):SetFloat(self:absW())
    entry("clipH"):SetFloat(self:absH())
    entry:DoStoredScript("updateClipping")
  end)
end
function MergeFugue.MonsterSelect.List:ListSelectNewEntry(element)
  local selectedMonsterID = element("NewSelectedEntryID"):GetInt()
  self:parent():parent():MonsterSelected(selectedMonsterID)
  local oldEntryName = self.SelectedEntry
  local newEntryName = self("NewSelectedEntry"):GetString()
  if oldEntryName ~= "" then
    local oldEntry = self:parent():E(oldEntryName)
    oldEntry:DoStoredScript("deselect")
  end
  if oldEntryName == newEntryName then
    self.SelectedEntryID = 0
    self.SelectedEntry = ""
  else
    local newEntry = self:parent():E(newEntryName)
    newEntry:DoStoredScript("select")
    self.SelectedEntry = newEntryName
    self.SelectedEntryID = newEntry:V("MonsterID"):GetInt()
  end
end
function MergeFugue.MonsterSelect.List:ListSelectDisabledEntry(element)
end
function MergeFugue.MonsterSelect.List.Swiper:onInit(element)
  self("smoothMode"):SetInt(1)
end
function MergeFugue.MonsterSelect.List.Swiper:onTick(element, dt)
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
function MergeFugue.MonsterSelect.List.Swiper:refresh(element)
  ScrollingListHelper.SwiperRefresh(self, element)
end
function MergeFugue.MonsterSelect.List.Swiper:setSwiperScrollOffset()
  local scrollmarker = self:parent():parent().ScrollMarker
  local offset = scrollmarker:V("scrollOffset"):GetFloat()
  self:setScrollOffset(offset)
end
function MergeFugue.MonsterSelect.List.Swiper:setScrollOffsetToMarker()
  local scrollmarker = self:parent():parent().ScrollMarker
  self:setScrollOffset(scrollmarker("scrollOffset"):GetFloat())
end
function MergeFugue.MonsterSelect.ScrollMarker:onInit()
  self("scrollOffset"):SetFloat(0)
  self("originalYOffset"):SetInt(self("yOffset"):GetInt())
end
function MergeFugue.MonsterSelect.ScrollMarker.Touch:onTouchDrag(element, x, y)
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
return MergeFugue
