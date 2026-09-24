local GoalHelp = include("GoalHelp")
local sort = include("sort")
local QuestTracking = {}
QuestTracking.__index = QuestTracking
function QuestTracking.New()
  return setmetatable({}, QuestTracking)
end
function QuestTracking:getCount()
  if self.count == nil then
    return 0
  end
  return self.count
end
function QuestTracking:track(questId)
  if self:isTracked(questId) then
    return false
  end
  self[questId] = questId
  self.count = self:getCount() + 1
  return true
end
function QuestTracking:untrack(questId)
  if not self:isTracked(questId) then
    return false
  end
  self[questId] = nil
  self.count = self:getCount() - 1
  return true
end
function QuestTracking:isTracked(questId)
  return self[questId] ~= nil
end
local GoalEntries = {
  goalsParent = nil,
  questFilter = nil,
  newNotificationTransitionState = 1,
  newNotificationTransitionTime = 1
}
function GoalEntries:onInit()
  self.goalsParent = self:parent()
  GoalHelp.goals = self.goalsParent
  self:V("origYOffset"):SetInt(self("yOffset"):GetInt())
  self:V("FirstGoal"):SetString("")
  self:V("LastGoal"):SetString("")
  self:V("listeningForEntityCollections"):SetInt(0)
  self:V("clickedQuestName"):SetString("")
  if game.isAdmin() then
    self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgRequestQuestRepopulation", "gotMsgRequestQuestRepopulation")
  end
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgRemoveQuest", "gotMsgRemoveQuest")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgAddQuest", "gotMsgAddQuest")
end
function GoalEntries:setupInitialWidth()
  self.initialWidth = self:parent():E("TopFadeSprite"):absW() - 20 * game.windowScaleY()
  self.requestedWidth = self.initialWidth
end
function GoalEntries:listenForEntityCollections()
  if self("listeningForEntityCollections"):GetInt() == 0 then
    self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgConfirmationSubmission", "gotMsgConfirmationSubmission")
    self("listeningForEntityCollections"):SetInt(1)
  end
end
function GoalEntries:gotMsgConfirmationSubmission(msg)
  if msg.messageID == "CONFIRM_ENTITY_REWARD_ISLAND" and msg.choice == true then
    local questName = self("clickedQuestName"):GetString()
    if questName ~= "" then
      game.completeQuest(game.getQuestId(questName))
    end
  end
end
function questCompare(q1, q2)
  if q1:isComplete() ~= q2:isComplete() then
    if q1:isComplete() then
      return true
    end
    if q2:isComplete() then
      return false
    end
  end
  if q1:isNew() ~= q2:isNew() then
    if q1:isNew() then
      return true
    end
    if q2:isNew() then
      return false
    end
  end
  local q1CanHelp = q1:GetLuaTable().canHelpResult
  local q2CanHelp = q2:GetLuaTable().canHelpResult
  if q1CanHelp ~= q2CanHelp then
    if q1CanHelp then
      return true
    end
    if q2CanHelp then
      return false
    end
  end
  local q1Percent = q1:percentComplete()
  local q2Percent = q2:percentComplete()
  local q1Priority = q1:priority()
  local q2Priority = q2:priority()
  if q1Percent ~= q2Percent then
    return q1Percent > q2Percent
  elseif q1Priority ~= q2Priority then
    if q1Priority == -1 then
      return false
    end
    if q2Priority == -1 then
      return true
    end
    return q1Priority < q2Priority
  end
  return q1:getId() < q2:getId()
end
function getSortedQuests()
  local quests = game.quests(2)
  if quests == nil then
    return {}
  end
  local questsTable = {}
  local numGoals = quests:size()
  for i = 0, numGoals - 1 do
    local quest = quests[i]
    questsTable[#questsTable + 1] = quest
  end
  sort.stable_sort(questsTable, questCompare)
  return questsTable
end
function GoalEntries:repopulate()
  local quests = game.quests(2)
  if not quests then
    return
  end
  self.goalsParent.useCachedQuests = 1
  if self.questsInTab ~= nil then
    for k, v in pairs(self.questsInTab) do
      if type(k) == "number" then
        self:RemoveElement(self:GetElement("" .. v))
      end
    end
  end
  local numGoals = quests:size()
  for i = 0, numGoals - 1 do
    local quest = quests[i]
    if quest:isNew() and has_cvalue(quest:getTags(), "WEEKLY_GROUP") then
      quest:markRead()
    end
  end
  game.updateQuestBadges()
  self.goalsParent.useCachedQuests = 0
  self:populate()
  self.Swiper:refresh(self.Swiper:parent())
end
local function populateAsCO(self)
  return coroutine.create(function()
    local curY = 0
    local quests = game.quests(2)
    if quests == nil then
      return
    end
    local numGoals = quests:size()
    for i = 0, numGoals - 1 do
      local quest = quests[i]
      quest:GetLuaTable().canHelpResult = GoalHelp.canHelp(quest, GoalHelp.goals)
    end
    local knownQuestIds = {}
    for _, quest in ipairs(getSortedQuests()) do
      knownQuestIds[#knownQuestIds + 1] = quest:getId()
    end
    local goalEntriesInfo = {}
    self.questsInTab = QuestTracking.New()
    self:setSize(lua_sys.Vector2(self.requestedWidth, 0))
    local currentTime = game.getCurrentTimeMillis()
    self:V("FirstGoal"):SetString("")
    self:V("LastGoal"):SetString("")
    for _, questId in ipairs(knownQuestIds) do
      local quest = game.getQuest(questId)
      if quest ~= nil and self.questFilter == nil or self.questFilter(quest, goalEntriesInfo) and self.questsInTab:track(quest:getId()) then
        local goalEntry = menu:addTemplateElement("template_goalentry", "" .. quest:getId(), self)
        goalEntry.quest = quest
        goalEntry("GoalName"):SetString(quest:getName())
        goalEntry:setParent(self)
        goalEntry:relativeTo(self)
        goalEntry:setOrientation(lua_sys.MenuOrientation(-5, curY, -1, lua_sys.HCENTER, lua_sys.TOP))
        goalEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
        curY = curY + goalEntry:absH()
        goalEntry:setSize(lua_sys.Vector2(self.requestedWidth, goalEntry:size().y))
        goalEntry:init()
        goalEntry:postInit()
        goalEntry:updateWidth(self.requestedWidth)
        if game.getCurrentTimeMillis() - currentTime >= 12 then
          self.goalsParent:updateClipping()
          self:resetRelativePositions()
          self:parent():updateScrollbarVisibility()
          self.Swiper:refresh(self.Swiper:parent())
          coroutine.yield()
          currentTime = game.getCurrentTimeMillis()
        end
      end
    end
    self:parent():updateScrollbarVisibility()
    self:resetRelativePositions()
    self.Swiper:refresh(self.Swiper:parent())
    self:setPositionBroadcast(true)
  end)
end
function GoalEntries:populate()
  self.populateCO = populateAsCO(self)
  local result, errorMessage = coroutine.resume(self.populateCO)
  if errorMessage then
    error(errorMessage)
  end
  if not result then
    self.populateCO = nil
  end
end
function GoalEntries:stopPopulate()
  self.populateCO = nil
end
function GoalEntries:onDestroy()
  game.commitReadQuests()
  self:stopPopulate()
end
function GoalEntries:onTick(dt)
  local co = self.populateCO
  if self.populateCO ~= nil and not coroutine.resume(co) then
    self.populateCO = nil
  end
  local selfTable = self:GetLuaTable()
  if selfTable.newNotificationTransitionState == nil then
    return
  end
  if selfTable.newNotificationTransitionState ~= 0 and dt <= 0.5 then
    if selfTable.newNotificationTransitionTime <= 1 then
      selfTable.newNotificationTransitionState = 1
    elseif selfTable.newNotificationTransitionTime >= 1.25 then
      selfTable.newNotificationTransitionState = 2
    end
    if selfTable.newNotificationTransitionState == 1 then
      selfTable.newNotificationTransitionTime = selfTable.newNotificationTransitionTime + dt
    else
      selfTable.newNotificationTransitionTime = selfTable.newNotificationTransitionTime - dt
    end
  end
end
function GoalEntries:gotMsgRequestQuestRepopulation()
  self.goalsParent.useCachedQuests = 0
  self:repopulate()
  game.markQuestsRead()
end
function GoalEntries:gotMsgRemoveQuest(msg)
  if not self.questsInTab:isTracked(msg.questId) then
    return
  end
  local removalEntry = self:E("" .. msg.questId)
  if removalEntry ~= nil then
    self:RemoveElement(removalEntry)
    self.questsInTab:untrack(msg.questId)
    self.goalsParent.useCachedQuests = 1
    self:resetRelativePositions()
  end
end
function GoalEntries:gotMsgAddQuest(msg)
  local newQuest = game.getQuest(msg.questId)
  if newQuest == nil then
    return
  end
  local goalEntriesInfo = {}
  local quests = game.quests(2)
  local numGoals = quests:size()
  local addNewQuest = false
  for i = 0, numGoals - 1 do
    local quest = quests[i]
    if (self.questFilter == nil or self.questFilter(quest, goalEntriesInfo)) and quest:getId() == newQuest:getId() then
      addNewQuest = true
      newQuest:GetLuaTable().canHelpResult = GoalHelp.canHelp(newQuest, GoalHelp.goals)
    end
  end
  if addNewQuest and self.questsInTab:track(msg.questId) then
    self.questsInTab:track(newQuest:getId())
    local newQuestEntry = menu:addTemplateElement("template_goalentry", "" .. newQuest:getId(), self)
    newQuestEntry.quest = newQuest
    newQuestEntry:V("GoalName"):SetString(newQuest:getName())
    newQuestEntry:setParent(self)
    newQuestEntry:relativeTo(self)
    newQuestEntry:setOrientation(lua_sys.MenuOrientation(-5, 0, -1, lua_sys.HCENTER, lua_sys.TOP))
    newQuestEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
    newQuestEntry:setSize(lua_sys.Vector2(self.requestedWidth, newQuestEntry:size().y))
    newQuestEntry:init()
    newQuestEntry:postInit()
    newQuestEntry:updateWidth(self.requestedWidth)
    self:resetRelativePositions()
  else
    return
  end
end
function GoalEntries:resetRelativePositions()
  local quests = getSortedQuests()
  local selfTable = self:GetLuaTable()
  selfTable.goalsParent.useCachedQuests = 1
  local previous
  local curY = 0
  self:V("FirstGoal"):SetString("")
  self:V("LastGoal"):SetString("")
  for _, quest in ipairs(quests) do
    local goalEntry = self:E("" .. quest:getId())
    if goalEntry ~= nil then
      if previous == nil then
        self:V("FirstGoal"):SetString(goalEntry:name())
      end
      goalEntry:setOrientation(lua_sys.MenuOrientation(-5, curY, -1, lua_sys.HCENTER, lua_sys.TOP))
      curY = curY + goalEntry:absH()
      previous = goalEntry
      self:V("LastGoal"):SetString(goalEntry:name())
    end
  end
  if selfTable.questsInTab:getCount() == 0 and self:parent():GetLuaTable().canShowEmptyMessage then
    self:parent().Description.Text:V("visible"):SetInt(1)
  else
    self:parent().Description.Text:V("visible"):SetInt(0)
  end
  self.Swiper:refresh(self.Swiper:parent())
  self:setPositionBroadcast(true)
end
local Swiper = {}
function Swiper:onPostInit(element)
  self:refresh(element)
end
function Swiper:refresh(element)
  element("yOffset"):SetInt(element("origYOffset"):GetInt())
  self:GetVar("direction"):SetInt(lua_sys.MenuSwipeComponent_SwipeDirectionVertical)
  self:GetVar("mode"):SetInt(lua_sys.MenuSwipeComponent_SwipeModeFree)
  self:GetVar("tSteps"):SetFloat(25)
  local first = element:GetElement(element("FirstGoal"):GetString())
  local scrollContainerHeight = 0
  local singleHeight = 0
  local itemHeight = 0
  if first then
    scrollContainerHeight = element:parent():GetElement("bg"):absH() - 83 * game.menuScaleY()
    singleHeight = first:absH()
    itemHeight = element.questsInTab:getCount() * first:absH()
    if scrollContainerHeight < itemHeight then
      self:setScrollSize(itemHeight - scrollContainerHeight)
    else
      self:setScrollSize(0)
    end
  end
  local scrollSize = itemHeight - scrollContainerHeight
  local mouseSpeed = 10
  if scrollContainerHeight > 0 and scrollSize > 0 and itemHeight > 0 then
    mouseSpeed = singleHeight / itemHeight * 100 / 2
  end
  self("mouseScrollSpeed"):SetFloat(mouseSpeed)
  element("scrollSize"):SetFloat(self:scrollSize())
end
function Swiper:onTick(element, dt)
  self:correctScrollMarkerPos(element)
end
function Swiper:correctScrollMarkerPos(element)
  local swipeAnchor = element
  if swipeAnchor then
    local scrollOffset = self:scrollOffset()
    if swipeAnchor:getOrientationPosition().y ~= scrollOffset then
      swipeAnchor:setOrientationPosition(lua_sys.Vector2(swipeAnchor("xOffset"):GetInt(), scrollOffset))
      local scrollMarker = element:parent():GetElement("ScrollMarker")
      local markerBookend = scrollMarker("originalYOffset"):GetInt()
      local markerMovementHeight = element:parent():GetElement("ScrollBar"):absH() - 2 * markerBookend - scrollMarker:absH()
      local scrollMarkerYOffset = 0
      if self:scrollSize() ~= 0 then
        scrollMarkerYOffset = -(scrollOffset / self:scrollSize()) * markerMovementHeight
      end
      scrollMarkerYOffset = lua_sys.clamp(scrollMarkerYOffset, 0, markerMovementHeight)
      scrollMarker("yOffset"):SetInt(markerBookend + scrollMarkerYOffset)
    end
  end
end
function Swiper:setScrollOffsetToMarker(element)
  self:setScrollOffset(element:parent():GetElement("ScrollMarker")("scrollOffset"):GetFloat())
end
function Swiper:resetScrollPos(element)
  self:setScrollOffset(0)
  self:correctScrollMarkerPos(element)
end
GoalEntries.Swiper = Swiper
return GoalEntries
