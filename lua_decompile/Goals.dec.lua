local OffsetTransition = include("MenuElementPositionOffsetTransition")
local FadeTransition = include("FadeTransition")
local Goals = {
  initialSize = nil,
  initialXOffset = nil,
  initialYOffset = nil,
  fader = nil,
  transitionState = 0,
  useCachedQuests = 0,
  onClosed = nil,
  canShowEmptyMessage = true,
  startTab = nil,
  currentTab = nil,
  TabAll = {},
  TabMain = {}
}
function Goals.TabAll.filterQuest(quest, info)
  if info[quest:getId()] ~= nil then
    return info[quest:getId()].show
  end
  local show = false
  if quest:isVisible(game.playerLevel()) then
    show = true
  end
  info[quest:getId()] = {show = show}
  return show
end
function Goals.TabAll:selectTab()
  self:parent().GoalEntries.questFilter = self.filterQuest
  self:parent().canShowEmptyMessage = true
  self:setOrientationPriority(-2)
  self.Sprite:setColor(1, 1, 1)
  self.Text:setColor(0.31, 0.94, 0.26)
  local goals = self:parent()
  local goalEntries = goals.GoalEntries
  goalEntries.requestedWidth = goalEntries.initialWidth
  goalEntries:V("xOffset"):SetInt(goals.initialXOffset)
end
function Goals.TabAll:deselectTab()
  self:setOrientationPriority(2)
  self.Sprite:setColor(0.9, 0.9, 0.9)
  self.Text:setColor(0.2325, 0.705, 0.195)
end
function Goals.TabAll:hideTab()
  self.Sprite:V("visible"):SetInt(0)
  self.Text:V("visible"):SetInt(0)
  self.Touch:V("enabled"):SetInt(0)
end
function Goals.TabMain.filterQuest(quest, info)
  if info[quest:getId()] ~= nil then
    return info[quest:getId()].show
  end
  local show = false
  if quest:isVisible(game.playerLevel()) then
    if quest:isComplete() then
      show = true
    elseif info.count == nil or info.count < game.maxMainQuests() then
      if info.count == nil then
        info.count = 1
      else
        info.count = info.count + 1
      end
      show = true
    end
  end
  info[quest:getId()] = {show = show}
  return show
end
function Goals.TabMain:selectTab()
  self:parent().GoalEntries.questFilter = self.filterQuest
  self:parent().canShowEmptyMessage = true
  self:setOrientationPriority(-1)
  local palette = include("ColourPalette")
  self.Sprite:setColor(palette:getRGBFloats(palette.TAB_SPRITE_SELECTED))
  self.Text:setColor(palette:getRGBFloats(palette.TAB_TEXT_YELLOW_SELECTED))
  local goals = self:parent()
  local goalEntries = goals.GoalEntries
  goalEntries.requestedWidth = goalEntries.initialWidth
  goalEntries:V("xOffset"):SetInt(goals.initialXOffset)
end
function Goals.TabMain:deselectTab()
  self:setOrientationPriority(1)
  local palette = include("ColourPalette")
  self.Sprite:setColor(palette:getRGBFloats(palette.TAB_SPRITE_DESELECTED))
  self.Text:setColor(palette:getRGBFloats(palette.TAB_TEXT_YELLOW_DESELECTED))
end
function Goals.TabMain:hideTab()
  self.Sprite:V("visible"):SetInt(0)
  self.Text:V("visible"):SetInt(0)
  self.Touch:V("enabled"):SetInt(0)
end
function Goals:onInit()
  self.GoalEntries.Swiper:listenToTouches(self.GoalEntries)
  self.initialXOffset = self.GoalEntries:V("xOffset"):GetInt()
  self.initialYOffset = self.GoalEntries:V("yOffset"):GetInt()
  self.initialSize = self.GoalEntries:size()
  self.transitionState = 0
  local startX = -lua_sys.screenWidth()
  local startY = 0
  OffsetTransition.OnInit(self, {
    duration = 0.333,
    startX = startX,
    startY = startY,
    endX = 0,
    endY = 0
  })
  self.fader = self:E("FadedBG"):C("Sprite")
  self.fader.FadeTransition = FadeTransition:new({
    duration = 0.333,
    maxFade = 0.5,
    onUpdate = function(alpha)
      self.fader:GetVar("alpha"):SetFloat(alpha)
    end
  })
  self("xOffset"):SetFloat(startX)
  self("yOffset"):SetFloat(startY)
  self.startTab = self.TabAll
  game.setLastGoalTab("TabAll")
  self:hideTabs()
  self:deselectTabs()
  self.useCachedQuests = 0
  self:updateClipping()
end
function Goals:updateClipping()
  local TopFadeSprite = self:E("TopFadeSprite")
  local BotFadeSprite = self:E("BotFadeSprite")
  local clipX = TopFadeSprite:absX() * lua_sys.deviceScaleX()
  local clipY = TopFadeSprite:absY() * lua_sys.deviceScaleY() + 1
  local clipWidth = TopFadeSprite:absW() * lua_sys.deviceScaleX()
  local clipHeight = BotFadeSprite:absY() * lua_sys.deviceScaleY() + BotFadeSprite:absH() * lua_sys.deviceScaleY() - TopFadeSprite:absY() * lua_sys.deviceScaleY()
  game.setClipping("Clipping", clipX, clipY, clipWidth, clipHeight)
end
function Goals:onPostInit()
  self.GoalEntries:setupInitialWidth()
  self:selectTab(self.startTab)
  self.transitionState = 1
  OffsetTransition.Show(self)
  self.fader.FadeTransition:Show()
  lua_sys.playSoundFx("audio/sfx/quest_icon_open.wav")
  self:updateScrollbarVisibility()
end
function Goals:updateScrollbarVisibility()
  local numItems = self:E("GoalEntries").questsInTab:getCount()
  local setInvis = true
  if numItems > 0 then
    local firstEntry = self:E("GoalEntries"):E(self:E("GoalEntries"):V("FirstGoal"):GetString())
    if firstEntry ~= nil then
      local itemHeight = firstEntry:absH()
      if numItems * itemHeight > self:E("bg"):absH() - 58 * game.menuScaleY() then
        setInvis = false
      end
    end
  end
  if setInvis then
    self.ScrollBar.Sprite:V("visible"):SetInt(0)
    self.ScrollMarker.Marker:V("visible"):SetInt(0)
  else
    self.ScrollBar.Sprite:V("visible"):SetInt(1)
    self.ScrollMarker.Marker:V("visible"):SetInt(1)
  end
end
function Goals:onTick(dt)
  if self.transitionState ~= 0 then
    OffsetTransition.OnTick(self, dt, {
      onDoneShow = function(e)
        self.transitionState = 0
      end,
      onDoneHide = function(e)
        self.transitionState = 0
        self:root():popPopUp()
        if self.onClosed ~= nil then
          for _, v in ipairs(self.onClosed) do
            v()
          end
        end
      end
    })
    self.fader.FadeTransition:Tick(dt)
    self:updateClipping()
  end
end
function Goals:queuePop()
  self.transitionState = 2
  self.GoalEntries:stopPopulate()
  OffsetTransition.Hide(self)
  self.fader.FadeTransition:Hide()
end
local Tab = {}
function Tab:deselectTab()
end
function Tab:selectTab()
end
function Tab:hideTab()
end
function Goals:selectTab(tab)
  if self.currentTab ~= nil then
    self.currentTab:deselectTab()
  end
  self.currentTab = tab
  if self.currentTab ~= nil then
    game.setLastGoalTab(tab:name())
    self.currentTab:selectTab()
    local goalEntries = self:E("GoalEntries")
    goalEntries.Swiper:resetScrollPos(goalEntries)
    goalEntries:repopulate(goalEntries)
    goalEntries.Swiper:resetScrollPos(goalEntries)
  end
end
function Goals:deselectTabs()
  local elements = self:elements()
  local size = elements:size()
  for i = 0, size - 1 do
    local element = elements[i]
    if startswith(element:name(), "Tab") then
      element:deselectTab()
    end
  end
end
function Goals:hideTabs()
  local elements = self:elements()
  local size = elements:size()
  for i = 0, size - 1 do
    local element = elements[i]
    if startswith(element:name(), "Tab") then
      element:hideTab()
    end
  end
end
function Goals:close()
  game.updateQuestBadges()
  manager:setContext(manager:getDefaultContext())
  game.popPopUp()
end
function Goals:selectStructureInternal(type)
  local firstStructure = game.getFirstStructureOfType(type)
  if firstStructure == 0 then
    return false
  end
  self:close()
  game.selectStructure(firstStructure)
  return true
end
function Goals:selectStructure(typeEnum)
  if type(typeEnum) == "table" then
    for i, v in ipairs(typeEnum) do
      if self:selectStructureInternal(v) then
        return
      end
    end
  else
    self:selectStructureInternal(typeEnum)
  end
end
function Goals:hasStructureInternal(type)
  local firstObstacle = game.getFirstStructureOfType(type)
  return firstObstacle ~= 0
end
function Goals:hasStructure(typeEnum)
  if type(typeEnum) == "table" then
    for i, v in ipairs(typeEnum) do
      if self:hasStructureInternal(v) then
        return true
      end
    end
  else
    return self:hasStructureInternal(typeEnum)
  end
  return
end
function Goals:selectStructureByEntityInternal(id)
  local first = game.getFirstStructureByEntity(id)
  if first == 0 then
    return false
  end
  self:close()
  game.selectStructure(first)
  return true
end
function Goals:selectStructureByEntity(ids)
  if type(ids) == "table" then
    for i, v in ipairs(ids) do
      if self:selectStructureByEntityInternal(v) then
        return
      end
    end
  else
    self:selectStructureByEntityInternal(ids)
  end
end
function Goals:hasStructureByEntityInternal(id)
  local first = game.getFirstStructureByEntity(id)
  return first ~= 0
end
function Goals:hasEntityByEntityInternal(id)
  local first = game.getFirstEntityByEntity(id)
  return first ~= 0
end
function Goals:hasEntityByEntity(ids)
  if type(ids) == "table" then
    for i, v in ipairs(ids) do
      if self:hasEntityByEntityInternal(v) then
        return true
      end
    end
  else
    return self:hasEntityByEntityInternal(ids)
  end
  return false
end
function Goals:hasStructureByEntity(ids)
  if type(ids) == "table" then
    for i, v in ipairs(ids) do
      if self:hasStructureByEntityInternal(v) then
        return true
      end
    end
  else
    return self:hasStructureByEntityInternal(ids)
  end
  return false
end
function Goals:selectObstacle()
  self:selectStructure(6)
end
function Goals:selectEntity(id)
  if id <= 0 then
    return
  end
  self:close()
  game.selectStructure(id)
end
function Goals:isEntityAvailableOnCurrentIsland(id)
  if type(id) == "integer" or type(id) == "number" then
    return game.isEntityAvailableOnCurrentIsland(id)
  elseif type(id) == "userdata" then
    if swig_type(id) == "std::vector< int > *" then
      local numItems = id:size()
      for i = 0, numItems - 1 do
        if game.isEntityAvailableOnCurrentIsland(id[i]) then
          return true
        end
      end
    end
  elseif type(id) == "table" then
    for _, v in ipairs(id) do
      if game.isEntityAvailableOnCurrentIsland(v) then
        return true
      end
    end
  end
  return false
end
function Goals:viewInMarket(id, filter)
  if type(id) == "integer" or type(id) == "number" then
    if game.isEntityAvailableOnCurrentIsland(id) then
      game.showInMarket(id, filter)
    end
  elseif type(id) == "userdata" and swig_type(id) == "std::vector< int > *" then
    local numItems = id:size()
    for i = 0, numItems - 1 do
      if game.isEntityAvailableOnCurrentIsland(id[i]) then
        game.showInMarket(id[i], filter)
        return
      end
    end
  end
end
function Goals:viewMonsterInMarket(monsterId)
  if type(monsterId) == "integer" or type(monsterId) == "number" then
    local entityId = game.getMonsterData(monsterId).entityId_
    print("Entity ID:", entityId)
    if game.isEntityAvailableOnCurrentIsland(entityId) then
      game.showInMarket(entityId, "")
    end
  elseif type(monsterId) == "userdata" and swig_type(monsterId) == "std::vector< int > *" then
    local numItems = monsterId:size()
    for i = 0, numItems - 1 do
      local entityId = game.getMonsterData(monsterId[i]).entityId_
      print("Entity ID:", entityId)
      if game.isEntityAvailableOnCurrentIsland(entityId) then
        game.showInMarket(entityId, "")
        return
      end
    end
  end
end
function Goals:hasMonster(typeEnum)
  if type(typeEnum) == "table" then
    for i, v in ipairs(typeEnum) do
      if self:hasMonsterInternal(v) then
        return true
      end
    end
  else
    return self:hasMonsterInternal(typeEnum)
  end
  return false
end
function Goals:hasMonsterInternal(type)
  local islandMonsters = game.player():getActiveIsland():monsters()
  for i = 0, islandMonsters:size() - 1 do
    local monsterData = game.getMonsterDataFromUniqueId(islandMonsters[i])
    if monsterData:monsterId() == type then
      return true
    end
  end
  return false
end
function Goals:selectMonster(typeEnum)
  if type(typeEnum) == "table" then
    for i, v in ipairs(typeEnum) do
      if self:selectMonsterInternal(v) then
        return
      end
    end
  else
    self:selectMonsterInternal(typeEnum)
  end
end
function Goals:selectMonsterInternal(type)
  local islandMonsters = game.player():getActiveIsland():monsters()
  for i = 0, islandMonsters:size() - 1 do
    local monsterData = game.getMonsterDataFromUniqueId(islandMonsters[i])
    if monsterData:monsterId() == type then
      self:close()
      game.selectMonster(islandMonsters[i])
      return true
    end
  end
  return false
end
return Goals
