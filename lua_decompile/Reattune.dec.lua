local MenuHelpers = include("MenuHelpers")
local MenuElementPositionOffsetTransition = include("MenuElementPositionOffsetTransition")
local sort = include("sort")
local ScrollingListHelper = include("ScrollingListHelper")
local MonsterProperties = include("MonsterProperties")
local Reattune = {
  bg = {},
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
  RightPanel = {
    StructureAnim = {
      Sprite = {}
    },
    MonsterAnim = {
      Sprite = {}
    },
    Spotlight = {
      Sprite = {}
    },
    MonsterSilhouette = {
      Sprite = {}
    },
    TunableGenes = {
      Sprite = {},
      Text = {},
      NoneAvailableText = {},
      Genes = {}
    },
    AvailableForText = {
      Text = {}
    },
    TimerText = {
      Text = {}
    }
  }
}
function Reattune:onPostInit()
  self.MonsterSelect:V("Refresh"):SetInt(1)
  self.attunedIsland = game.attunedIslandId()
  self:populateGenes()
end
function Reattune:MonsterSelected(monsterId)
  local monsterType = game.monsterTypeId(monsterId)
  local monsterAnim = self.RightPanel.MonsterAnim.Sprite
  local monsterSilhouette = self.RightPanel.MonsterSilhouette.Sprite
  local selectedGfx = "xml_bin/" .. game.getMonsterAnimationFileFromType(monsterType)
  monsterAnim:V("visible"):SetInt(1)
  monsterSilhouette:V("visible"):SetInt(1)
  monsterAnim:V("animationName"):SetString(selectedGfx)
  monsterAnim:V("animation"):SetString(game.getMonsterAnimationNameFromType(monsterType))
  local monster = game.GetMonster(monsterId)
  local costumeId = monster:getEquippedCostume()
  if costumeId > 0 then
    game.applyCostumeToAnimComponent(monsterAnim, costumeId)
  end
  local facing = MonsterProperties.getFacing(monsterType)
  monsterAnim:GetVar("hFlip"):SetInt(facing)
  monsterAnim:GetVar("offsetCenter"):SetInt(1)
  local monsterReattuned = game.getMonsterByEntityId(game.getMonsterData(monsterType):evolvesInto()):monsterId()
  if monsterReattuned == 0 then
    monsterReattuned = monsterType
  end
  local reattunedGfx = "xml_bin/" .. game.getMonsterAnimationFileFromType(monsterReattuned)
  monsterSilhouette:V("animationName"):SetString(reattunedGfx)
  monsterSilhouette:V("animation"):SetString(game.getMonsterAnimationNameFromType(monsterReattuned))
  local reattunedFacing = 1 - MonsterProperties.getFacing(monsterReattuned)
  monsterSilhouette:GetVar("hFlip"):SetInt(reattunedFacing)
  monsterSilhouette:GetVar("offsetCenter"):SetInt(1)
  self.RightPanel.StructureAnim.Sprite:V("animation"):SetString("working")
  lua_sys.playSoundFx("audio/sfx/item_select.wav")
end
function Reattune:updateMonster()
  local selectedMonsterID = self:getSelectedMonster()
  if game.SelectedObject():isAttuner() then
    if self.initialReattuningMonster ~= selectedMonsterID then
      game.SelectedObject():updateReattuneMonster(selectedMonsterID, self.monsterRarity)
    end
    lua_sys.playSoundFx("audio/sfx/structure_attunement_tune.ogg")
    if game.getContextBar() then
      game.getContextBar():setContext("ATTUNER")
    end
    self:Hide()
  end
end
function Reattune:getSelectedMonster()
  return self.MonsterSelect.List.SelectedEntryID
end
function Reattune:onInit()
  self.monsterRarity = game.MonsterRarity_Common
  local attuner = game.FindAttuner()
  self.initialReattuningMonster = attuner:reattuningMonster()
  MenuElementPositionOffsetTransition.OnInit(self.bg, {
    startY = lua_sys.screenHeight() * 2,
    endY = -20 * game.menuScaleX(),
    duration = 0.66
  })
  self:Show()
end
function Reattune:onTick(dt)
  local options = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
      e:root():popPopUp()
    end
  }
  MenuElementPositionOffsetTransition.OnTick(self.bg, dt, options)
  local secondsRemaining = game.timeUntilAttunedIslandSwitch()
  self.RightPanel.TimerText.Text:GetVar("text"):SetString(game.timeToString(secondsRemaining))
  if self.attunedIsland ~= game.attunedIslandId() then
    self.attunedIsland = game.attunedIslandId()
    self:populateGenes()
  end
end
function Reattune:Show()
  MenuElementPositionOffsetTransition.Show(self.bg)
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function Reattune:Hide()
  MenuElementPositionOffsetTransition.Hide(self.bg)
  self.Fade:Hide()
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function Reattune:queuePop()
  self:Hide()
end
function Reattune.MonsterSelect:onInit()
  self:V("IsShowing"):SetInt(0)
  self:V("Refresh"):SetInt(0)
  self.List:V("scrollOffset"):SetFloat(0)
end
function Reattune.MonsterSelect:onTick(dt)
  if self:V("Refresh"):GetInt() == 1 then
    self.List:populate()
    self:V("Refresh"):SetInt(0)
  end
end
function Reattune.MonsterSelect.List:onInit()
  self("NewSelectedEntry"):SetString("")
  self("NewSelectedEntryID"):SetInt(0)
  ScrollingListHelper.ListInit(self, {
    direction = lua_sys.MenuSwipeComponent_SwipeDirectionVertical,
    spacing = 10 * game.menuScaleX(),
    padding = 0
  })
end
function Reattune.MonsterSelect:ListPopulate(element)
  local attuner = game.FindAttuner()
  local reattuningMonster = attuner:reattuningMonster()
  local selectedEntry
  ScrollingListHelper.ListClear(element)
  local parent = self:parent()
  local availableMonsters = game.worldContext():availableReattuneMonsters(parent.monsterRarity)
  local monstersTable = {}
  for i = 0, availableMonsters:size() - 1 do
    local monster = availableMonsters[i]
    local monsterData = game.getMonsterDataFromUniqueId(monster)
    local evolvesIntoMonsterData = game.getMonsterByEntityId(monsterData:evolvesInto())
    if evolvesIntoMonsterData:monsterId() ~= 0 then
      monstersTable[#monstersTable + 1] = monster
    end
  end
  local monsterCompare = function(m1, m2)
    local monsterType1 = game.monsterTypeId(m1)
    local genes1 = game.monsterTypeGenes(monsterType1)
    local monsterType2 = game.monsterTypeId(m2)
    local genes2 = game.monsterTypeGenes(monsterType2)
    if string.len(genes1) == string.len(genes2) then
      return monsterType1 < monsterType2
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
    if monsterId == reattuningMonster then
      selectedEntry = monsterEntry
    end
    return monsterEntry
  end
  ScrollingListHelper.ListPopulate(element, #monstersTable, createFunc)
  if selectedEntry ~= nil then
    self.List("NewSelectedEntry"):SetString(selectedEntry:name())
    self.List("NewSelectedEntryID"):SetString(selectedEntry("MonsterID"):GetInt())
    self.List:selectNewEntry()
  end
  if element:GetVar("totalSize"):GetFloat() < element:absH() then
    self.ScrollBar.Sprite:GetVar("visible"):SetInt(0)
    self.ScrollMarker.Marker:GetVar("visible"):SetInt(0)
    self.ScrollMarker.Touch:GetVar("enabled"):SetInt(0)
  end
end
function Reattune.MonsterSelect.List:onTick(dt)
  ScrollingListHelper.ListTick(self, dt)
  MenuHelpers.ForEachEntry(self, function(entry)
    entry("clipX"):SetFloat(self:absX())
    entry("clipY"):SetFloat(self:absY())
    entry("clipW"):SetFloat(self:absW())
    entry("clipH"):SetFloat(self:absH())
    entry:updateClipping()
  end)
end
function Reattune.MonsterSelect.List:ListSelectNewEntry(element)
  local selectedMonsterID = element("NewSelectedEntryID"):GetInt()
  self:parent():parent():MonsterSelected(selectedMonsterID)
  local oldEntryName = self.SelectedEntry
  local newEntryName = self("NewSelectedEntry"):GetString()
  if oldEntryName ~= "" then
    local oldEntry = self:parent():E(oldEntryName)
    oldEntry:deselect()
  end
  if oldEntryName == newEntryName then
    self:parent():parent().RightPanel.MonsterAnim.Sprite:V("visible"):SetInt(0)
    self:parent():parent().RightPanel.MonsterSilhouette.Sprite:V("visible"):SetInt(0)
    self:parent():parent().RightPanel.Spotlight.Sprite:V("visible"):SetInt(0)
    self.SelectedEntryID = 0
    self.SelectedEntry = ""
    self:parent():parent().RightPanel.StructureAnim.Sprite:V("animation"):SetString("idle")
  else
    local newEntry = self:parent():E(newEntryName)
    newEntry:select()
    self.SelectedEntry = newEntryName
    self.SelectedEntryID = newEntry:V("MonsterID"):GetInt()
    self:parent():parent().RightPanel.MonsterAnim.Sprite:V("visible"):SetInt(1)
    self:parent():parent().RightPanel.MonsterSilhouette.Sprite:V("visible"):SetInt(1)
    self:parent():parent().RightPanel.Spotlight.Sprite:V("visible"):SetInt(1)
    self:parent():parent().RightPanel.StructureAnim.Sprite:V("animation"):SetString("working")
  end
end
function Reattune.MonsterSelect.List:ListSelectDisabledEntry(element)
end
function Reattune.MonsterSelect.List.Swiper:onInit(element)
  self("smoothMode"):SetInt(1)
end
function Reattune.MonsterSelect.List.Swiper:onTick(element, dt)
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
function Reattune.MonsterSelect.List.Swiper:refresh(element)
  ScrollingListHelper.SwiperRefresh(self, element)
end
function Reattune.MonsterSelect.List.Swiper:setSwiperScrollOffset()
  local scrollmarker = self:parent():parent().ScrollMarker
  local offset = scrollmarker:V("scrollOffset"):GetFloat()
  self:setScrollOffset(offset)
end
function Reattune.MonsterSelect.List.Swiper:setScrollOffsetToMarker()
  local scrollmarker = self:parent():parent().ScrollMarker
  self:setScrollOffset(scrollmarker("scrollOffset"):GetFloat())
end
function Reattune.MonsterSelect.ScrollMarker:onInit()
  self("scrollOffset"):SetFloat(0)
  self("originalYOffset"):SetInt(self("yOffset"):GetInt())
end
function Reattune.MonsterSelect.ScrollMarker.Touch:onTouchDrag(element, x, y)
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
function Reattune:populateGenes()
  local parent = self.RightPanel.TunableGenes.Genes
  MenuHelpers.ForEachEntry(parent, function(entry)
    parent:RemoveElement(entry)
  end)
  local items = {}
  local width = 0
  local height = 0
  local genes = game.attunerGeneDatas()
  for i = 0, genes:size() - 1 do
    local geneData = genes[i]
    local canReattune = game.Attuner_canReattuneRare(geneData.geneLetter)
    if canReattune then
      local entry = menu:addTemplateElement("template_gene", "entry" .. i, self)
      entry:V("SpriteName"):SetString(game.geneFilename(geneData.geneLetter))
      entry:V("SheetName"):SetString("xml_resources/hud02.xml")
      entry:V("Size"):SetFloat(0.25 * game.menuScaleX())
      entry:V("Layer"):SetString("MidPopUps")
      entry:relativeTo(parent)
      entry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
      entry:setOrientation(lua_sys.MenuOrientation(0, 0 * game.menuScaleX(), -1, lua_sys.LEFT, lua_sys.VCENTER))
      entry:init()
      entry:setPositionBroadcast(true)
      entry:postInit()
      width = width + entry:absW()
      local itemHeight = entry:absH()
      if height < itemHeight then
        height = itemHeight
      end
      table.insert(items, entry)
    end
  end
  parent:setSize(Vector2(width, height))
  MenuHelpers.CenterHorizontally(items)
end
return Reattune
