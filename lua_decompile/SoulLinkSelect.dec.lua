local OffsetTransition = include("MenuElementPositionOffsetTransition")
local FadeTransition = include("FadeTransition")
local ScrollingListHelper = include("ScrollingListHelper")
local MenuHelpers = include("MenuHelpers")
local sort = include("sort")
local SoulLinkSelect = {
  Fade = {
    Touch = {}
  },
  Panel = {
    Title = {},
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
function SoulLinkSelect:onInit()
  self:V("numMonsters"):SetInt(0)
  self:V("entryHeight"):SetFloat(0)
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
function SoulLinkSelect:onTick(dt)
  self.FadeTransition:Tick(dt)
  OffsetTransition.OnTick(self.Panel, dt)
  if self:V("Refresh"):GetInt() == 1 then
    self.Panel.List:DoStoredScript("populate")
    self:V("Refresh"):SetInt(0)
  end
end
function SoulLinkSelect:Show()
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
  local height = self:V("numMonsters"):GetInt() * (self:V("entryHeight"):GetFloat() + 12 * game.menuScaleX())
  if height <= self.Panel.List:absH() then
    self.Panel.ScrollBar:setInvisible()
    self.Panel.ScrollMarker:setInvisible()
  else
    self.Panel.ScrollBar:setVisible()
    self.Panel.ScrollMarker:setVisible()
  end
end
function SoulLinkSelect:Hide()
  if self:V("IsShowing"):GetInt() == 1 then
    self:V("IsShowing"):SetInt(0)
    self.FadeTransition:Hide()
    OffsetTransition.Hide(self.Panel)
    manager:setButtonEnabled("btn_close", true)
  end
end
function SoulLinkSelect.Panel.List:onInit()
  self("NewSelectedEntry"):SetString("")
  self("NewSelectedEntryID"):SetInt(0)
  ScrollingListHelper.ListInit(self, {
    direction = lua_sys.MenuSwipeComponent_SwipeDirectionVertical,
    spacing = 12 * game.menuScaleX(),
    padding = 5 * game.menuScaleX()
  })
end
function SoulLinkSelect:ListPopulate(element, rarity)
  print("Populating Select Monsters Popup List!")
  local text = "COMMON_SOUL_LINK_SELECT_TITLE"
  if rarity == game.MonsterRarity_Rare then
    text = "RARE_SOUL_LINK_SELECT_TITLE"
  elseif rarity == game.MonsterRarity_Epic then
    text = "EPIC_SOUL_LINK_SELECT_TITLE"
  end
  self.Panel.Title:C("Text"):V("text"):SetString(text)
  ScrollingListHelper.ListClear(element)
  element("RequiredMonsterRarity"):SetInt(rarity)
  local availableMonsters = game.availableSoulLinkMonsters(rarity)
  local numMonsters = availableMonsters:size()
  local monstersTable = {}
  for i = 0, numMonsters - 1 do
    local monster = availableMonsters[i]
    monstersTable[#monstersTable + 1] = monster
  end
  local monsterCompare = function(m1, m2)
    return game.effectiveResourceRate(m1) > game.effectiveResourceRate(m2)
  end
  sort.stable_sort(monstersTable, monsterCompare)
  local function createFunc(idx, itemName)
    local monsterId = monstersTable[idx + 1]
    local entryName = ScrollingListHelper.ListCreateEntryName(element)
    local monsterEntry = menu:addTemplateElement("template_soul_link_select_entry", entryName, element)
    monsterEntry("MonsterID"):SetInt(monsterId)
    monsterEntry("List"):SetString("List")
    monsterEntry("Layer"):SetString("MidFrontPopUps")
    monsterEntry:init()
    monsterEntry("selected"):SetInt(0)
    self:V("entryHeight"):SetFloat(monsterEntry:absH())
    return monsterEntry
  end
  ScrollingListHelper.ListPopulate(element, numMonsters, createFunc)
  self:V("numMonsters"):SetInt(numMonsters)
end
function SoulLinkSelect.Panel.List:onTick(dt)
  ScrollingListHelper.ListTick(self, dt)
  MenuHelpers.ForEachEntry(self, function(entry)
    entry("clipX"):SetFloat(self:absX())
    entry("clipY"):SetFloat(self:absY())
    entry("clipW"):SetFloat(self:absW())
    entry("clipH"):SetFloat(self:absH())
    entry:DoStoredScript("updateClipping")
  end)
end
function SoulLinkSelect.Panel.List:ListSelectNewEntry(element)
  local selectedMonsterID = element("NewSelectedEntryID"):GetInt()
  element:parent():parent():parent():MonsterSelected(selectedMonsterID)
  element:root().MonsterSelectPopup:DoStoredScript("hide")
end
function SoulLinkSelect.Panel.List:ListSelectDisabledEntry(element)
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
function SoulLinkSelect.Panel.List.Swiper:onInit(element)
  self("smoothMode"):SetInt(1)
end
function SoulLinkSelect.Panel.List.Swiper:onTick(element, dt)
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
function SoulLinkSelect.Panel.List.Swiper:refresh(element)
  ScrollingListHelper.SwiperRefresh(self, element)
end
function SoulLinkSelect.Panel.List.Swiper:setSwiperScrollOffset()
  local scrollmarker = self:parent():parent().ScrollMarker
  local offset = scrollmarker:V("scrollOffset"):GetFloat()
  self:setScrollOffset(offset)
end
function SoulLinkSelect.Panel.List.Swiper:setScrollOffsetToMarker()
  local scrollmarker = self:parent():parent().ScrollMarker
  self:setScrollOffset(scrollmarker("scrollOffset"):GetFloat())
end
function SoulLinkSelect.Panel.ScrollMarker:onInit()
  self("scrollOffset"):SetFloat(0)
  self("originalYOffset"):SetInt(self("yOffset"):GetInt())
end
function SoulLinkSelect.Panel.ScrollMarker.Touch:onTouchDrag(element, x, y)
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
return SoulLinkSelect
