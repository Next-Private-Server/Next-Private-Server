local OffsetTransition = include("MenuElementPositionOffsetTransition")
local FadeTransition = include("FadeTransition")
local ScrollingListHelper = include("ScrollingListHelper")
local MenuHelpers = include("MenuHelpers")
local sort = include("sort")
local SynthesizingMonsterSelectUI = {
  Fade = {
    Touch = {}
  },
  Panel = {
    CloseButton = {},
    List = {
      Swiper = {}
    },
    ScrollBar = {},
    ScrollMarker = {
      Touch = {}
    }
  }
}
function SynthesizingMonsterSelectUI:onInit()
  self:V("IsShowing"):SetInt(0)
  self:V("Refresh"):SetInt(0)
  self.Panel.List:V("scrollOffset"):SetFloat(0)
  local fadeTouch = self.Fade.Touch
  fadeTouch:V("enabled"):SetInt(0)
  local fadeTarget = self.Fade.Sprite
  self.FadeTransition = FadeTransition:new({
    duration = 0.66,
    maxFade = 0.5,
    onDoneHide = function()
      fadeTouch:V("enabled"):SetInt(0)
    end,
    onUpdate = function(alpha)
      fadeTarget:V("alpha"):SetFloat(alpha)
    end
  })
  self.FadeTransition:SetAlpha(0)
  OffsetTransition.OnInit(self.Panel, {
    startY = lua_sys.screenHeight() * 2,
    endY = 6 * game.hudScale(),
    duration = 0.66
  })
end
function SynthesizingMonsterSelectUI:onTick(dt)
  self.FadeTransition:Tick(dt)
  OffsetTransition.OnTick(self.Panel, dt)
  if self:V("Refresh"):GetInt() == 1 then
    self.Panel.List:DoStoredScript("populate")
    self:V("Refresh"):SetInt(0)
  end
end
function SynthesizingMonsterSelectUI:Show()
  self:V("IsShowing"):SetInt(1)
  local fadeTouch = self.Fade.Touch
  fadeTouch("enabled"):SetInt(1)
  manager:setButtonEnabled("btn_close", false)
  self.FadeTransition:Show()
  self.Panel.List:V("scrollOffset"):SetFloat(0)
  self.Panel.ScrollMarker:V("scrollOffset"):SetFloat(0)
  self.Panel.List.Swiper:setSwiperScrollOffset()
  OffsetTransition.Show(self.Panel)
  self.Panel.CloseButton.Touch:V("enabled"):SetInt(1)
end
function SynthesizingMonsterSelectUI:Hide()
  if self:V("IsShowing"):GetInt() == 1 then
    self:V("IsShowing"):SetInt(0)
    self.FadeTransition:Hide()
    OffsetTransition.Hide(self.Panel)
    manager:setButtonEnabled("btn_close", true)
  end
end
function SynthesizingMonsterSelectUI.Panel.List:onInit()
  self("NewSelectedEntry"):SetString("")
  self("NewSelectedEntryID"):SetInt(0)
  ScrollingListHelper.ListInit(self, {
    direction = lua_sys.MenuSwipeComponent_SwipeDirectionVertical,
    spacing = 12 * game.menuScaleY()
  })
end
function SynthesizingMonsterSelectUI:ListPopulate(element, numGenes)
  print("Populating Select Monsters Popup List!")
  ScrollingListHelper.ListClear(element)
  local requiredGenes = numGenes + 1
  element("RequiredMonsterGenes"):SetInt(requiredGenes)
  local availableMonsters = game.monstersWithNumGenes(numGenes)
  local monstersTable = {}
  local attuner = game.FindAttuner()
  for i = 0, availableMonsters:size() - 1 do
    local monster = availableMonsters[i]
    if attuner:isReattuningMonster(monster) == false then
      monstersTable[#monstersTable + 1] = monster
    end
  end
  local function monsterCompare(m1, m2)
    local hasStableCombo1 = self:hasStableCombo(m1, requiredGenes)
    local hasStableCombo2 = self:hasStableCombo(m2, requiredGenes)
    if hasStableCombo1 ~= hasStableCombo2 then
      if hasStableCombo1 then
        return true
      end
      if hasStableCombo2 then
        return false
      end
    end
    local monsterType1 = game.monsterTypeId(m1)
    local genes1 = game.monsterTypeGenes(monsterType1)
    local canCreate1 = game.canCreateMonsterWithGenes(genes1, requiredGenes)
    local monsterType2 = game.monsterTypeId(m2)
    local genes2 = game.monsterTypeGenes(monsterType2)
    local canCreate2 = game.canCreateMonsterWithGenes(genes2, requiredGenes)
    if canCreate1 ~= canCreate2 then
      if canCreate1 then
        return true
      end
      if canCreate2 then
        return false
      end
    end
    return monsterType1 < monsterType2
  end
  sort.stable_sort(monstersTable, monsterCompare)
  local function createFunc(idx, itemName)
    local monsterId = monstersTable[idx + 1]
    local entryName = ScrollingListHelper.ListCreateEntryName(element)
    local monsterEntry = menu:addTemplateElement("template_monster_synthesizing_entry", entryName, element)
    monsterEntry("MonsterID"):SetInt(monsterId)
    monsterEntry("List"):SetString("List")
    monsterEntry("Layer"):SetString("MidFrontPopUps")
    monsterEntry:init()
    local monsterType = game.monsterTypeId(monsterId)
    local genes = game.monsterTypeGenes(monsterType)
    if game.canCreateMonsterWithGenes(genes, numGenes + 1) == false or self:hasStableCombo(monsterId, requiredGenes) == false then
      monsterEntry:setDisabled()
    end
    monsterEntry("selected"):SetInt(0)
    return monsterEntry
  end
  ScrollingListHelper.ListPopulate(element, #monstersTable, createFunc)
end
function SynthesizingMonsterSelectUI:hasStableCombo(monsterId, requiredGenes)
  local monsterType = game.monsterTypeId(monsterId)
  local monsterGenes = game.monsterTypeGenes(monsterType)
  local monsters = game.creatableMonstersWithGenes(monsterGenes, requiredGenes)
  for j = 0, monsters:size() - 1 do
    local genes = game.monsterTypeGenes(monsters[j])
    local instability = 1
    for i = 1, #genes do
      local gene = genes:sub(i, i)
      local data = game.attunerGeneData(gene)
      instability = instability * data.instability
    end
    if instability <= game.synthesizerMaxInstability() then
      return true
    end
  end
  return false
end
function SynthesizingMonsterSelectUI.Panel.List:onTick(dt)
  ScrollingListHelper.ListTick(self, dt)
  MenuHelpers.ForEachEntry(self, function(entry)
    entry("clipX"):SetFloat(self:absX())
    entry("clipY"):SetFloat(self:absY())
    entry("clipW"):SetFloat(self:absW())
    entry("clipH"):SetFloat(self:absH())
    entry:DoStoredScript("updateClipping")
  end)
end
function SynthesizingMonsterSelectUI.Panel.List:ListSelectNewEntry(element)
  local selectedMonsterID = element("NewSelectedEntryID"):GetInt()
  element:parent():parent():parent():MonsterSelected(selectedMonsterID)
  element:root().MonsterSelectPopup:DoStoredScript("hide")
end
function SynthesizingMonsterSelectUI.Panel.List:ListSelectDisabledEntry(element)
  local requiredMonsterGenes = element("RequiredMonsterGenes"):GetInt()
  local monsterId = element("NewDisabledEntryID"):GetInt()
  local monsterType = game.monsterTypeId(monsterId)
  local monsterGenes = game.monsterTypeGenes(monsterType)
  if game.canCreateMonsterWithGenes(monsterGenes, requiredMonsterGenes) == false then
    game.displayNotification("NOTIFICATION_NO_MONSTER_SYNTHESIZER_COMBO")
  elseif self:hasStableCombo(monsterId, requiredMonsterGenes) == false then
    game.displayNotification("NOTIFICATION_NO_STABLE_SYNTHESIZER_COMBO")
  end
end
function SynthesizingMonsterSelectUI.Panel.List.Swiper:onInit(element)
  self("smoothMode"):SetInt(1)
end
function SynthesizingMonsterSelectUI.Panel.List.Swiper:onTick(element, dt)
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
function SynthesizingMonsterSelectUI.Panel.List.Swiper:refresh(element)
  ScrollingListHelper.SwiperRefresh(self, element)
end
function SynthesizingMonsterSelectUI.Panel.List.Swiper:setSwiperScrollOffset()
  local scrollmarker = self:parent():parent().ScrollMarker
  local offset = scrollmarker:V("scrollOffset"):GetFloat()
  self:setScrollOffset(offset)
end
function SynthesizingMonsterSelectUI.Panel.List.Swiper:setScrollOffsetToMarker()
  local scrollmarker = self:parent():parent().ScrollMarker
  self:setScrollOffset(scrollmarker("scrollOffset"):GetFloat())
end
function SynthesizingMonsterSelectUI.Panel.ScrollMarker:onInit()
  self("scrollOffset"):SetFloat(0)
  self("originalYOffset"):SetInt(self("yOffset"):GetInt())
end
function SynthesizingMonsterSelectUI.Panel.ScrollMarker.Touch:onTouchDrag(element, x, y)
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
return SynthesizingMonsterSelectUI
