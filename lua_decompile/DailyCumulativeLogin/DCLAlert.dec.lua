local DCLAlert = {
  Sprite = {}
}
function DCLAlert:onInit()
  self.transitionTime = 1
  self.transitionState = 1
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgUpdatePlayerDailyCumulativeLogin", "gotMsgUpdatePlayerDailyCumulativeLogin")
end
function DCLAlert:onPostInit()
  self:Refresh()
end
function DCLAlert:gotMsgUpdatePlayerDailyCumulativeLogin(msg)
  self:Refresh()
end
function DCLAlert:Refresh()
  local calendarId = 0
  local awakener = game.FindAwakener()
  if awakener then
    calendarId = awakener:getCalendarId()
  end
  local playerState = game.player():getDailyCumulativeLogin()
  local calendar = game.getDailyCumulativeLoginData(calendarId)
  if calendar.id == 0 or calendar.id ~= playerState:calendar() or game.serverTime() <= playerState:nextCollect() and playerState:catchUpDaysTotal() == playerState:catchUpDaysUsed() then
    self.transitionState = 0
    self.Sprite:GetVar("visible"):SetInt(0)
  else
    self.transitionState = 1
    self.Sprite:GetVar("visible"):SetInt(1)
  end
end
return DCLAlert
