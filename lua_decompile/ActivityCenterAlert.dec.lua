local ActivityCenterAlert = {
  Sprite = {}
}
local ALERT_SPIN_VIEWED = "ALERT_SPIN_VIEWED"
local ALERT_SCRATCH_VIEWED = "ALERT_SCRATCH_VIEWED"
local ALERT_MEMORY_VIEWED = "ALERT_MEMORY_VIEWED"
local ALERT_BATTLE_VIEWED = "ALERT_BATTLE_VIEWED"
local ALERT_CALENDAR_VIEWED = "ALERT_CALENDAR_VIEWED"
local ALERT_DAILY_LOGIN_VIEWED = "ALERT_DAILY_LOGIN_VIEWED"
local getFlag = function(flag)
  local setting = game.getLocalSettings():get(flag)
  if setting == "true" then
    return true
  end
  return false
end
local setFlag = function(flag, val)
  game.getLocalSettings():set(flag, val and "true" or "false")
end
function ActivityCenterAlert:onInit()
  self.isHidden = false
  self.transitionTime = 1
  self.transitionState = 1
  self.showSpinGameAlert = getFlag(ALERT_SPIN_VIEWED)
  self.showScratchGameAlert = getFlag(ALERT_SCRATCH_VIEWED)
  self.showMemoryGameAlert = getFlag(ALERT_MEMORY_VIEWED)
  self.showCalendarAlert = getFlag(ALERT_CALENDAR_VIEWED)
  self.showBattleAlert = getFlag(ALERT_BATTLE_VIEWED)
  self.activityCenterIsOpen = false
  self.refreshTimer = 0
  self.refreshDelay = 10
end
function ActivityCenterAlert:hasSpinGameAlert()
  if self.activityCenter and self.activityCenter.Panel.CurrencyScratch.hidden then
    return false
  end
  if getFlag(ALERT_SPIN_VIEWED) then
    return false
  end
  return self.showSpinGameAlert
end
function ActivityCenterAlert:gotMsgUpdateCurrencyScratchIndicator(msg)
  if not self.showSpinGameAlert and msg.visible then
    setFlag(ALERT_SPIN_VIEWED, false)
  end
  self.showSpinGameAlert = msg.visible
  self:refresh()
end
function ActivityCenterAlert:hasScratchGameAlert()
  if self.activityCenter and self.activityCenter.Panel.BreedingScratch.hidden then
    return false
  end
  if getFlag(ALERT_SCRATCH_VIEWED) then
    return false
  end
  return self.showScratchGameAlert
end
function ActivityCenterAlert:gotMsgUpdateMonsterScratchIndicator(msg)
  if not self.showScratchGameAlert and msg.visible then
    setFlag(ALERT_SCRATCH_VIEWED, false)
  end
  self.showScratchGameAlert = msg.visible
  self:refresh()
end
local checkMemoryGameAlert = function()
  return game.showFreeFlipIndicator()
end
function ActivityCenterAlert:hasMemoryGameAlert()
  if self.activityCenter and self.activityCenter.Panel.MemoryGame.hidden then
    return false
  end
  if getFlag(ALERT_MEMORY_VIEWED) then
    return false
  end
  return self.showMemoryGameAlert
end
local checkBattleAlert = function()
  local versusCampaignId = game.getBattleVersusCampaignId()
  return not game.showNewCampaignNotification() and versusCampaignId > 0 and versusCampaignId == game.getLastSeenVersusCampaignId() and game.hasBattleVersusPlayerData(versusCampaignId)
end
function ActivityCenterAlert:hasBattleAlert()
  if self.activityCenter and self.activityCenter.Panel.BattleButton.hidden then
    return false
  end
  if getFlag(ALERT_BATTLE_VIEWED) then
    return false
  end
  return self.showBattleAlert
end
local checkCalendarAlert = function()
  local playerState = game.player():getDailyCumulativeLogin()
  local calendar = game.getDailyCumulativeLoginData(playerState:calendar())
  return calendar.id > 0 and (game.serverTime() > playerState:nextCollect() or playerState:catchUpDaysUsed() < playerState:catchUpDaysTotal())
end
function ActivityCenterAlert:hasCalendarAlert()
  if self.activityCenter and self.activityCenter.Panel.CalendarButton.hidden then
    return false
  end
  if getFlag(ALERT_CALENDAR_VIEWED) then
    return false
  end
  return self.showCalendarAlert
end
function ActivityCenterAlert:hasAlert()
  return self:hasSpinGameAlert() or self:hasScratchGameAlert() or self:hasMemoryGameAlert() or self:hasCalendarAlert() or self:hasBattleAlert()
end
function ActivityCenterAlert:onPostInit()
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgUpdateCurrencyScratchIndicator", "gotMsgUpdateCurrencyScratchIndicator")
  game.updateCurrencyScratchIndicator()
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgUpdateMonsterScratchIndicator", "gotMsgUpdateMonsterScratchIndicator")
  game.updateMonsterScratchIndicator()
  self.showMemoryGameAlert = checkMemoryGameAlert()
  self.showBattleAlert = checkBattleAlert()
  self.showCalendarAlert = checkCalendarAlert()
  self:refresh()
end
function ActivityCenterAlert:refresh()
  local showAlert = self:hasAlert()
  if self.isHidden or not showAlert then
    self.transitionState = 0
    self.Sprite:GetVar("visible"):SetInt(0)
  else
    self.transitionState = 1
    self.Sprite:GetVar("visible"):SetInt(1)
  end
end
function ActivityCenterAlert:onTick(dt)
  if self.transitionState ~= 0 and dt <= 0.5 then
    self.Sprite:GetVar("size"):SetFloat(0.6 * game.hudScale() * self.transitionTime)
    if self.transitionTime <= 1 then
      self.transitionState = 1
    elseif self.transitionTime >= 1.25 then
      self.transitionState = 2
    end
    if self.transitionState == 1 then
      self.transitionTime = self.transitionTime + dt
    else
      self.transitionTime = self.transitionTime - dt
    end
  end
  self.refreshTimer = self.refreshTimer + dt
  if self.refreshTimer > self.refreshDelay then
    local alertStatus = checkMemoryGameAlert()
    if not self.showMemoryGameAlert and alertStatus then
      setFlag(ALERT_MEMORY_VIEWED, false)
    end
    self.showMemoryGameAlert = alertStatus
    alertStatus = checkBattleAlert()
    if not self.showBattleAlert and alertStatus then
      setFlag(ALERT_BATTLE_VIEWED, false)
    end
    self.showBattleAlert = alertStatus
    alertStatus = checkCalendarAlert()
    if not self.showCalendarAlert and alertStatus then
      setFlag(ALERT_CALENDAR_VIEWED, false)
    end
    self.showCalendarAlert = alertStatus
    self.refreshTimer = 0
    self:refresh()
  end
  if self.activityCenter then
    if self.activityCenterIsOpen and self.activityCenter:GetVar("IsOpen"):GetInt() == 0 then
      self.activityCenterIsOpen = false
      self:ViewedAlerts()
    elseif not self.activityCenterIsOpen and self.activityCenter:GetVar("IsOpen"):GetInt() == 1 then
      self.activityCenterIsOpen = true
    end
  end
end
function ActivityCenterAlert:setActivityCenter(activityCenter)
  self.activityCenter = activityCenter
  self:refresh()
end
function ActivityCenterAlert:Show()
  self.isHidden = false
  self:refresh()
end
function ActivityCenterAlert:Hide()
  self.isHidden = true
  self:refresh()
end
function ActivityCenterAlert:ViewedAlerts()
  setFlag(ALERT_SPIN_VIEWED, self.showSpinGameAlert)
  setFlag(ALERT_SCRATCH_VIEWED, self.showScratchGameAlert)
  setFlag(ALERT_MEMORY_VIEWED, self.showMemoryGameAlert)
  setFlag(ALERT_BATTLE_VIEWED, self.showBattleAlert)
  setFlag(ALERT_CALENDAR_VIEWED, self.showCalendarAlert)
  self:refresh()
end
return ActivityCenterAlert
