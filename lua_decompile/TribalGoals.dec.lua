local TribalGoals = {}
TribalGoals.transitionTime = 0
TribalGoals.transitionState = 1
function TribalGoals:onInit()
  self.transitionTime = 0
end
function TribalGoals:onPostInit()
  self.transitionState = 1
  lua_sys.playSoundFx("audio/sfx/quest_icon_open.wav")
end
function TribalGoals:onTick(dt)
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
    elseif 0 >= self.transitionTime then
      self:root():popPopUp()
    end
  end
end
function TribalGoals:TickTransition()
  local bg = self:E("bg")
  bg:V("xOffset"):SetFloat(lua_sys.screenWidth() * 0.5 + -0.5 * lua_sys.screenWidth() * (1 / math.max(0.001, self.transitionTime)))
  self:E("FadedBG"):C("Sprite"):V("alpha"):SetFloat(self.transitionTime * 0.5)
  local titleFrameHeight = 50 * game.hudScale()
  local clippingWidth = (bg:absW() - 20) * lua_sys.deviceScaleX()
  local clippingHeight = (bg:absH() - titleFrameHeight) * lua_sys.deviceScaleY()
  game.setClipping("Clipping", (bg:absX() + 10) * lua_sys.deviceScaleX(), (bg:absY() + titleFrameHeight) * lua_sys.deviceScaleY(), clippingWidth, clippingHeight)
end
function TribalGoals:queuePop()
  self.transitionState = 2
end
local TimeRemaining = {}
TribalGoals.TimeRemaining = TimeRemaining
local Text = {}
function Text:onInit(element)
  self:V("font"):Set(game.getTextFont())
  self:V("size"):SetFloat(0.38 * game.hudScale())
  self:V("alignment"):SetInt(lua_sys.MenuTextComponent_TEXT_HCENTER_ALIGNED)
  if game.tribalTimeRemaining() >= 0 then
    self.timeString = game.timeToString(game.tribalTimeRemaining())
  else
    self.timeString = game.timeToString(0)
  end
  self:V("text"):SetString(game.getLocalizedText("LABEL_DIAMOND_TIME") .. " - " .. self.timeString)
  self:V("autoScale"):SetInt(1)
  self:V("layer"):SetString("MidFrontPopUps")
end
function Text:onTick(element)
  local oldString = self.timeString
  if game.tribalTimeRemaining() >= 0 then
    self.timeString = game.timeToString(game.tribalTimeRemaining())
  else
    self.timeString = game.timeToString(0)
  end
  if oldString ~= self.timeString then
    self:V("text"):SetString(game.getLocalizedText("LABEL_DIAMOND_TIME") .. " - " .. self.timeString)
  end
end
TimeRemaining.Text = Text
local GoalEntries = {NumGoals = 0, FirstGoal = ""}
function GoalEntries:onInit()
  self.NumGoals = 0
  self.FirstGoal = ""
  self:populate()
end
function GoalEntries:populate()
  local previous
  local quests = game.tribalQuests()
  local numGoals = quests:size()
  for i = 0, numGoals - 1 do
    local quest = quests[i]
    local goalEntry = menu:addTemplateElement("template_tribalgoalentry", "" .. quest:getId(), self)
    goalEntry:V("GoalDesc"):SetString(quest:getDescription())
    goalEntry:V("GoalSheet"):SetString(quest:getSheet())
    goalEntry:V("GoalIcon"):SetString(quest:getImage())
    goalEntry:V("RewardCoins"):SetInt(quest:getRewardCoins())
    goalEntry:V("RewardDiamonds"):SetInt(quest:getRewardDiamonds())
    goalEntry:V("RewardXp"):SetInt(quest:getRewardXp())
    goalEntry:V("RewardFood"):SetInt(quest:getRewardFood())
    goalEntry:V("RewardShards"):SetInt(quest:getRewardShards())
    goalEntry:V("RewardEntity"):SetInt(quest:getRewardEntity())
    if quest:isComplete() == true then
      goalEntry:V("Complete"):SetInt(1)
    else
      goalEntry:V("Complete"):SetInt(0)
    end
    if previous == nil then
      goalEntry:relativeTo(self)
      goalEntry:setOrientation(lua_sys.MenuOrientation(-5, 0, -1, lua_sys.HCENTER, lua_sys.TOP))
      goalEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
      self.FirstGoal = goalEntry:name()
    else
      goalEntry:relativeTo(previous)
      goalEntry:setOrientation(lua_sys.MenuOrientation(0, 0, 0, lua_sys.HCENTER, lua_sys.TOP))
      goalEntry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.BOTTOM)
    end
    previous = goalEntry
    goalEntry:init()
    goalEntry:setPositionBroadcast(true)
    self:parent():TickTransition()
  end
  self.NumGoals = numGoals
  local first = self:E(self.FirstGoal)
  if first then
    first:setOrientationPosition(Vector2(first:V("xOffset"):GetInt(), first:V("yOffset"):GetInt() + 1))
  end
end
TribalGoals.GoalEntries = GoalEntries
local Swiper = {}
function Swiper:onPostInit(element)
  self:V("direction"):SetInt(lua_sys.MenuSwipeComponent_SwipeDirectionVertical)
  self:V("mode"):SetInt(lua_sys.MenuSwipeComponent_SwipeModeFree)
  self:V("tSteps"):SetFloat(25)
  self:listenToTouches(element)
  local first = element:E(element.FirstGoal)
  if first then
    local totalHeight = element.NumGoals * first:absH()
    if totalHeight > element:absH() then
      self:setScrollSize(totalHeight - element:absH() + 30 * game.hudScale())
    else
      self:setScrollSize(0)
    end
  end
  if game.hudScale() == 1 then
    element:V("yOffset"):SetInt(10)
  end
end
function Swiper:onTick(element, dt)
  local first = element:E(element.FirstGoal)
  if first then
    local offset = self:scrollOffset()
    if first:getOrientationPosition().y ~= offset then
      first:setOrientationPosition(Vector2(first:V("xOffset"):GetInt(), offset))
    end
  end
end
GoalEntries.Swiper = Swiper
return TribalGoals
