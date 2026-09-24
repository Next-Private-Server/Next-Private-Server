local LevelupMenu = {
  FadedBG = {},
  bg = {},
  TitleFrame = {},
  FadeSprite = {},
  BotFadeSprite = {},
  Title = {},
  MonikerText = {},
  UnlockedEntities = {
    numItems = 0,
    FirstItem = nil,
    LastItem = nil,
    ENTITY_HEIGHT = 168.3,
    ENTITY_WIDTH = 168.3,
    X_SPACER = -40,
    Y_SPACER = -63,
    MONIKER_OFFSET = -4 * game.menuScaleY(),
    startYPos = -10 * game.menuScaleY(),
    relativeStartXPos = 0,
    relativeStartYPos = 0,
    nextYPos = 0,
    ADVANCE_STEP_SIZE = 0,
    currentEntryXPos = 0,
    currentEntryYPos = 0,
    numEntriesPerRow = 3,
    Swiper = {}
  },
  ScrollBar = {
    Sprite = {}
  },
  ScrollMarker = {
    Marker = {},
    Touch = {}
  },
  OkayButton = {
    Touch = {}
  },
  ContinueLabel = {},
  transitionTime = 0,
  transitionState = 1,
  unlockElement = 0,
  particlePauseTime = 0.3,
  secondsElapsedSinceParticle = 0,
  easeForwardTime = 0.3,
  secondsElapsedDuringEaseForward = 0,
  easebackTime = 0.5,
  secondsElapsedDuringEaseback = 0,
  spedUp = 0,
  scrollYPos = 0,
  START_SCROLL_IND = 6
}
LevelupMenu.secondsElapsedSinceParticle = LevelupMenu.particlePauseTime
LevelupMenu.UnlockedEntities.ADVANCE_STEP_SIZE = -((LevelupMenu.UnlockedEntities.Y_SPACER + LevelupMenu.UnlockedEntities.ENTITY_HEIGHT) * game.menuScaleX())
LevelupMenu.UnlockedEntities.nextYPos = LevelupMenu.UnlockedEntities.startYPos
LevelupMenu.scrollYPos = LevelupMenu.UnlockedEntities.startYPos
function LevelupMenu:onInit()
  manager:setContext("BLANK")
end
function LevelupMenu:onPostInit()
  self.ScrollMarker:setInvisible()
  self.ScrollBar:setInvisible()
  self.transitionState = 1
end
function LevelupMenu:buildEntries()
  self.UnlockedEntities:populate()
end
function LevelupMenu:onTick(dt)
  if self.transitionState ~= 0 then
    self:TickTransition()
    if self.transitionState == 1 then
      self.transitionTime = self.transitionTime + dt * 3
    elseif self.transitionState == 2 then
      self.transitionTime = self.transitionTime - dt * 3
    end
    self.transitionTime = clamp(self.transitionTime, 0, 1)
    if 1 <= self.transitionTime then
      self.transitionState = 0
      self.transitionTime = 1
      self:TickTransition()
      self:playParticles()
    elseif 0 >= self.transitionTime then
      self.UnlockedEntities:deleteEntries()
      self:root():popPopUp()
      manager:setContext(manager:getDefaultContext())
    end
  else
    self.secondsElapsedSinceParticle = self.secondsElapsedSinceParticle + dt
    if self.secondsElapsedSinceParticle >= self.particlePauseTime then
      if self.unlockElement < self.UnlockedEntities.numItems then
        if self.unlockElement < self.START_SCROLL_IND or (self.unlockElement - self.START_SCROLL_IND) % self.UnlockedEntities.numEntriesPerRow ~= 0 then
          self.secondsElapsedDuringEaseForward = self.secondsElapsedDuringEaseForward + dt
          if self.secondsElapsedDuringEaseForward >= self.easeForwardTime then
            local storedItem = self:E("unlock" .. self.unlockElement)
            self.unlockElement = self.unlockElement + 1
            self.secondsElapsedDuringEaseForward = 0
            storedItem:setVisible()
            self.secondsElapsedSinceParticle = 0
          end
        elseif self.secondsElapsedDuringEaseForward < self.easeForwardTime then
          local storedItem = self:E("unlock" .. self.unlockElement)
          local beginY = math.ceil(self.scrollYPos)
          local endY = math.ceil(self.UnlockedEntities.nextYPos)
          if endY == beginY then
            endY = math.ceil(self.scrollYPos + self.UnlockedEntities.ADVANCE_STEP_SIZE)
            self.UnlockedEntities.nextYPos = endY
          end
          local delta = endY - beginY
          local ease = lua_sys.Sinusoidal_EaseInOut(self.secondsElapsedDuringEaseForward, beginY, delta, self.easeForwardTime)
          self.scrollYPos = math.ceil(ease)
          self.UnlockedEntities.Swiper:onTick(self.UnlockedEntities, dt)
          self.secondsElapsedDuringEaseForward = self.secondsElapsedDuringEaseForward + dt
        else
          self.scrollYPos = self.UnlockedEntities.nextYPos
          local storedItem = self:E("unlock" .. self.unlockElement)
          self.unlockElement = self.unlockElement + 1
          self.secondsElapsedDuringEaseForward = 0
          self.UnlockedEntities.Swiper:onTick(self.UnlockedEntities, dt)
          storedItem:setVisible()
          self.secondsElapsedSinceParticle = 0
        end
      elseif self.unlockElement == self.UnlockedEntities.numItems then
        if self.secondsElapsedDuringEaseback < self.easebackTime then
          local beginY = math.ceil(self.scrollYPos)
          local delta = self.UnlockedEntities.startYPos - beginY
          local ease = lua_sys.Sinusoidal_EaseInOut(self.secondsElapsedDuringEaseback, beginY, delta, self.easebackTime)
          self.scrollYPos = math.ceil(ease)
          self.secondsElapsedDuringEaseback = self.secondsElapsedDuringEaseback + dt
        else
          self.scrollYPos = self.UnlockedEntities.startYPos
          self.unlockElement = self.unlockElement + 1
          for i = 0, self.UnlockedEntities.numItems - 1 do
            local storedItem = self:E("unlock" .. i)
            if storedItem ~= nil then
              storedItem:reenableTouch()
            end
          end
          self.bg.Touch("enabled"):SetInt(0)
          self.ScrollMarker:setVisible()
          self.ScrollBar:setVisible()
        end
      end
    end
  end
end
function LevelupMenu:playParticles()
  local midX = lua_sys.screenWidth() / 2
  local midY = lua_sys.screenHeight() / 2
  self:E("EffectElement"):C("Effect"):start()
end
function LevelupMenu:TickTransition()
  local bgframe = self.bg
  bgframe("xOffset"):SetFloat(lua_sys.screenWidth() * 0.5 + -0.5 * lua_sys.screenWidth() * (1 / math.max(0.001, self.transitionTime)))
  local topSprite = self.FadeSprite
  local botSprite = self.BotFadeSprite
  game.setClipping("Clipping", topSprite:absX() * lua_sys.deviceScaleX(), topSprite:absY() * lua_sys.deviceScaleY(), topSprite:absW() * lua_sys.deviceScaleX(), (botSprite:absY() + botSprite:absH() - topSprite:absY()) * lua_sys.deviceScaleY())
end
function LevelupMenu:queuePop()
  self.transitionState = 2
end
function LevelupMenu.UnlockedEntities:onInit()
  self.numItems = 0
end
LevelupMenu.UnlockedEntities.previous = nil
local originalFirstItemYOffset = 0
function LevelupMenu.UnlockedEntities:setNewEntryPos()
  self.currentEntryXPos = 0
  self.currentEntryYPos = 0
  if self.numItems == 0 then
    if self:parent()("moniker"):GetString() == "" then
      self.currentEntryXPos = (self.UnlockedEntities.numEntriesPerRow - 1) * -((LevelupMenu.UnlockedEntities.X_SPACER + LevelupMenu.UnlockedEntities.ENTITY_WIDTH) * game.menuScaleX() / 2)
    else
      self.currentEntryXPos = 0
    end
    self.currentEntryYPos = originalFirstItemYOffset
  elseif self.FirstItem.IsMoniker == 0 then
    local rowNum = math.floor(self.numItems / self.numEntriesPerRow)
    local column = self.numItems % self.numEntriesPerRow
    self.currentEntryXPos = column * ((LevelupMenu.UnlockedEntities.X_SPACER + LevelupMenu.UnlockedEntities.ENTITY_WIDTH) * game.menuScaleX())
    self.currentEntryYPos = rowNum * ((LevelupMenu.UnlockedEntities.Y_SPACER + LevelupMenu.UnlockedEntities.ENTITY_HEIGHT) * game.menuScaleX())
  else
    local adjustedNumItems = self.numItems - 1
    local rowNum = math.floor(adjustedNumItems / self.numEntriesPerRow) + 1
    local column = adjustedNumItems % self.numEntriesPerRow
    self.currentEntryXPos = column * ((LevelupMenu.UnlockedEntities.X_SPACER + LevelupMenu.UnlockedEntities.ENTITY_WIDTH) * game.menuScaleX())
    self.currentEntryXPos = self.currentEntryXPos - (LevelupMenu.UnlockedEntities.X_SPACER + LevelupMenu.UnlockedEntities.ENTITY_WIDTH) * game.menuScaleX()
    self.currentEntryYPos = rowNum * ((LevelupMenu.UnlockedEntities.Y_SPACER + LevelupMenu.UnlockedEntities.ENTITY_HEIGHT + LevelupMenu.UnlockedEntities.MONIKER_OFFSET) * game.menuScaleX())
  end
end
function LevelupMenu.UnlockedEntities:createEntry(entryId, xPos, yPos, itemTitle, animationFile, animationName, costumeId, isMonster, isStructure, isMoniker, isPortrait)
  local entry
  if isMoniker == 0 and isPortrait == 0 then
    entry = menu:addTemplateElement("template_levelupUnlock", "unlock" .. self.numItems, self)
  elseif isMoniker == 0 then
    entry = menu:addTemplateElement("template_levelupUnlockPortrait", "unlock" .. self.numItems, self)
  else
    entry = menu:addTemplateElement("template_levelupUnlockMoniker", "unlock" .. self.numItems, self)
  end
  self.numItems = self.numItems + 1
  entry.ItemTitle = itemTitle
  entry.AnimationFile = animationFile
  entry.AnimationName = animationName
  entry.CostumeId = costumeId
  entry.IsMonster = isMonster
  entry.IsStructure = isStructure
  entry.IsMoniker = isMoniker
  entry.ID = entryId
  if self.previous == nil then
    entry:relativeTo(self)
    entry:setOrientation(lua_sys.MenuOrientation(xPos, yPos, 18, lua_sys.HCENTER, lua_sys.TOP))
    entry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
    self.FirstItem = entry
  else
    entry:relativeTo(self.FirstItem)
    entry:setOrientation(lua_sys.MenuOrientation(xPos, yPos, 0, lua_sys.HCENTER, lua_sys.TOP))
    entry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
  end
  self.LastItem = entry
  self.previous = entry
  entry:init()
  entry:setPositionBroadcast(true)
  entry:postInit()
  self:parent():TickTransition()
end
function LevelupMenu.UnlockedEntities:deleteEntries()
  for i = 0, self.numItems - 1 do
    local entry = self:GetElement("unlock" .. i)
    if entry ~= nil then
      self:RemoveElement(entry)
    end
  end
  self.FirstItem = nil
  self.LastItem = nil
  self.previous = nil
  self.numItems = 0
end
function LevelupMenu.UnlockedEntities:populate()
  self.previous = nil
  self.numItems = 0
  if self:parent()("moniker"):GetString() ~= "" then
    self:parent().START_SCROLL_IND = 1
    self:setNewEntryPos()
    local portrait = self:parent()("portrait"):GetString()
    self:createEntry(0, self.currentEntryXPos, self.currentEntryYPos, self:parent()("moniker"):GetString(), "", portrait, 0, 0, 0, 1, 0)
  end
  local islands = game.getIslandsUnlocked()
  for i = 0, islands:size() - 1 do
    local entryId = islands[i]
    self:setNewEntryPos()
    self:createEntry(entryId, self.currentEntryXPos, self.currentEntryYPos, game.islandName(entryId), "islands.bin", "island" .. entryId, 0, 0, 0, 0, 0)
  end
  local monsters = game.getMonstersUnlockedOnThisIsland()
  for i = 0, monsters:size() - 1 do
    local entryId = monsters[i]
    self:setNewEntryPos()
    self:createEntry(entryId, self.currentEntryXPos, self.currentEntryYPos, game.monsterTypeName(entryId), game.getMonsterAnimationFileFromType(entryId), game.getMonsterAnimationNameFromType(entryId), 0, 1, 0, 0, 0)
  end
  local structures = game.getStructuresUnlocked()
  for i = 0, structures:size() - 1 do
    local entryId = structures[i]
    self:setNewEntryPos()
    self:createEntry(entryId, self.currentEntryXPos, self.currentEntryYPos, game.structureTypeName(entryId), game.getStructureAnimationFileFromType(entryId), game.getStructureAnimationNameFromType(entryId), 0, 0, 1, 0, 0)
  end
  local decorations = game.getDecorationsUnlocked()
  for i = 0, decorations:size() - 1 do
    local entryId = decorations[i]
    self:setNewEntryPos()
    self:createEntry(entryId, self.currentEntryXPos, self.currentEntryYPos, game.structureTypeName(entryId), game.getStructureAnimationFileFromType(entryId), game.getStructureAnimationNameFromType(entryId), 0, 0, 0, 0, 0)
  end
  if self.FirstItem ~= nil then
    if self.FirstItem.IsMoniker == 0 then
      if self.numItems <= 3 then
        if self.numItems == 1 then
          self.FirstItem("xOffset"):SetInt(0)
        elseif self.numItems == 2 then
          self.FirstItem("xOffset"):SetInt((self.UnlockedEntities.numEntriesPerRow - 1) * -((LevelupMenu.UnlockedEntities.X_SPACER + LevelupMenu.UnlockedEntities.ENTITY_WIDTH) * game.menuScaleX() / 2) / 2)
        end
        originalFirstItemYOffset = (LevelupMenu.UnlockedEntities.Y_SPACER + LevelupMenu.UnlockedEntities.ENTITY_HEIGHT) * game.menuScaleX() / 2
        self.FirstItem("yOffset"):SetInt(originalFirstItemYOffset)
      end
    else
      LevelupMenu.UnlockedEntities.ADVANCE_STEP_SIZE = -((LevelupMenu.UnlockedEntities.Y_SPACER + LevelupMenu.UnlockedEntities.ENTITY_HEIGHT + LevelupMenu.UnlockedEntities.MONIKER_OFFSET) * game.menuScaleX())
      if self.numItems > 1 and self.numItems <= 4 then
        for i = 1, self.UnlockedEntities.numItems - 1 do
          local nonMonikerEntry = self:E("unlock" .. i)
          if nonMonikerEntry ~= nil then
            local adjustedNumItems = i - 1
            local column = adjustedNumItems % self.numEntriesPerRow
            local xPos = column * ((LevelupMenu.UnlockedEntities.X_SPACER + LevelupMenu.UnlockedEntities.ENTITY_WIDTH) * game.menuScaleX())
            xPos = xPos - (LevelupMenu.UnlockedEntities.X_SPACER + LevelupMenu.UnlockedEntities.ENTITY_WIDTH) * game.menuScaleX()
            if self.numItems == 2 then
              xPos = 0
            elseif self.numItems == 3 then
              xPos = xPos - (self.UnlockedEntities.numEntriesPerRow - 1) * -((LevelupMenu.UnlockedEntities.X_SPACER + LevelupMenu.UnlockedEntities.ENTITY_WIDTH) * game.menuScaleX() / 2) / 2
            end
            nonMonikerEntry("xOffset"):SetInt(xPos)
          end
        end
      end
    end
  end
  self.Swiper:refresh(self)
end
function LevelupMenu.UnlockedEntities.Swiper:onPostInit(element)
  self:V("direction"):SetInt(lua_sys.MenuSwipeComponent_SwipeDirectionVertical)
  self:V("mode"):SetInt(lua_sys.MenuSwipeComponent_SwipeModeFree)
  self:V("tSteps"):SetFloat(25)
  self:listenToTouches(element)
  self:refresh(element)
end
function LevelupMenu.UnlockedEntities.Swiper:refresh(element)
  self:listenToTouches(element)
  if element.FirstItem and element.LastItem then
    if element.LastItem.NameFrame:absY() - element.FirstItem:absY() - element.FirstItem:absH() / 2 - self:parent().ADVANCE_STEP_SIZE > element:absH() then
      self:setScrollSize(element.LastItem:absY() - element.FirstItem:absY() + element.FirstItem:absH() - element:absH())
    else
      self:setScrollSize(0)
      self:V("mode"):SetInt(lua_sys.MenuSwipeComponent_SwipeModeDisabled)
    end
  end
  element.scrollSize = self:scrollSize()
end
function LevelupMenu.UnlockedEntities.Swiper:onTick(element, dt)
  local first = element.FirstItem
  if first then
    local scrollOffset = self:scrollOffset()
    local offset = scrollOffset + element:parent().scrollYPos + originalFirstItemYOffset
    if first:getOrientationPosition().y ~= offset then
      first:setOrientationPosition(Vector2(first("xOffset"):GetInt(), offset))
      local scrollMarker = element:parent().ScrollMarker
      local markerBookend = scrollMarker.originalYOffset
      local markerMovementHeight = element:parent().ScrollBar:absH() - 2 * markerBookend - scrollMarker:absH()
      local scrollMarkerYOffset = 0
      if self:scrollSize() ~= 0 then
        scrollMarkerYOffset = -(scrollOffset / self:scrollSize()) * markerMovementHeight
      end
      scrollMarkerYOffset = clamp(scrollMarkerYOffset, 0, markerMovementHeight)
      scrollMarker("yOffset"):SetInt(markerBookend + scrollMarkerYOffset)
    end
  end
end
function LevelupMenu.UnlockedEntities.Swiper:setScrollOffsetToMarker(element)
  self:setScrollOffset(element:parent().ScrollMarker.scrollOffset)
end
function LevelupMenu.ScrollBar:setVisible()
  if self:parent().UnlockedEntities.Swiper("mode"):GetInt() == lua_sys.MenuSwipeComponent_SwipeModeFree then
    self.Sprite("visible"):SetInt(1)
  end
end
function LevelupMenu.ScrollBar:setInvisible()
  self.Sprite("visible"):SetInt(0)
end
function LevelupMenu.ScrollMarker:setVisible()
  if self:parent().UnlockedEntities.Swiper("mode"):GetInt() == lua_sys.MenuSwipeComponent_SwipeModeFree then
    self.Marker("visible"):SetInt(1)
    self.Touch("enabled"):SetInt(1)
    self:parent().UnlockedEntities.Swiper("enableMouseScroll"):SetInt(1)
  end
end
function LevelupMenu.ScrollMarker:setInvisible()
  self.Marker("visible"):SetInt(0)
  self.Touch("enabled"):SetInt(0)
  self:parent().UnlockedEntities.Swiper("enableMouseScroll"):SetInt(0)
end
function LevelupMenu.ScrollMarker.Marker:onInit(element)
  self("useOffsets"):SetInt(1)
  self("spriteName"):SetString("scroll_bar_dot")
  self("sheetName"):SetString("xml_resources/buttons01.xml")
  self("size"):SetFloat(0.3 * game.menuScaleY())
  self("layer"):SetString("ContextBar")
  element.originalYOffset = element("yOffset"):GetInt()
end
function LevelupMenu.ScrollMarker.Touch:onTouchDrag(element, x, y)
  local scrollBar = element:parent().ScrollBar
  local fromTopOfMarkerRange = y - scrollBar:absY() - element.originalYOffset
  local markerBookend = element.originalYOffset
  local scrollSize = 0
  if element:parent().UnlockedEntities.scrollSize ~= nil then
    scrollSize = element:parent().UnlockedEntities.scrollSize
  end
  local scrollOffset = -(fromTopOfMarkerRange - markerBookend) / (scrollBar:absH() - 2 * markerBookend - element:absH()) * scrollSize
  scrollOffset = clamp(scrollOffset, -scrollSize, 0)
  element.scrollOffset = scrollOffset
  element:parent().UnlockedEntities.Swiper:setScrollOffsetToMarker(element)
end
function LevelupMenu.OkayButton.Touch:onTouchDown(element)
  self:super_onTouchDown(element)
  element:parent().ContinueLabel.Text:setColor(0.5, 0.5, 0.5)
end
function LevelupMenu.OkayButton.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  element:parent().ContinueLabel.Text:setColor(1, 1, 1)
  element:parent().transitionState = 2
end
function LevelupMenu.OkayButton.Touch:onTouchRelease(element)
  self:super_onTouchRelease(element)
  element:parent().ContinueLabel.Text:setColor(1, 1, 1)
end
return LevelupMenu
