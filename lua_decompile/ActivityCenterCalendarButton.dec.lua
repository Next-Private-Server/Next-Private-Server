local ActivityCenterCalendarButton = {
  icon = {},
  Label = {},
  NewNotification = {},
  Touch = {}
}
function ActivityCenterCalendarButton:onPostInit(levelChange)
  local calendar = game.getDailyCumulativeLoginDataForIsland(game.currentIsland())
  if not game.tutorialActive() and calendar.id > 0 and game.player():getDailyCumulativeLogin():calendar() >= calendar.id then
    self:setVisible()
    local STRUCTURE_TYPE_AWAKENER = 17
    if 0 >= game.getFirstStructureOfType(STRUCTURE_TYPE_AWAKENER) then
      self:disable()
    else
      self:enable()
    end
  else
    self:setInvisible()
  end
end
function ActivityCenterCalendarButton:setInvisible()
  self:super_setInvisible()
  self.icon:GetVar("visible"):SetInt(0)
  self.Label:GetVar("visible"):SetInt(0)
  self.NewNotification.Sprite:GetVar("visible"):SetInt(0)
  self.hidden = true
end
function ActivityCenterCalendarButton:setVisible()
  self:super_setVisible()
  self.icon:GetVar("visible"):SetInt(1)
  self.Label:GetVar("visible"):SetInt(1)
  self.hidden = false
end
function ActivityCenterCalendarButton:enable()
  self.enabled = true
  self.icon:setColor(1, 1, 1)
  self.UpSprite:setColor(1, 1, 1)
end
function ActivityCenterCalendarButton:disable()
  self.enabled = false
  self.icon:setColor(0.5, 0.5, 0.5)
  self.UpSprite:setColor(1, 1, 1)
end
function ActivityCenterCalendarButton:select()
  game.deselectSelectedObject()
  manager:setContext(manager:getDefaultContext())
  game.logEvent("activity_center", "button", "conundrum", "level", game.playerLevel(), "island_id", game.currentIsland())
  game.pushPopUp("daily_cumulative_login")
  self:parent():parent():Hide()
end
function ActivityCenterCalendarButton.Touch:onTouchDown(element)
  element.icon:setColor(0.5, 0.5, 0.5)
  self:super_onTouchDown(element)
end
function ActivityCenterCalendarButton.Touch:onTouchUp(element)
  if element.enabled then
    element.icon:setColor(1, 1, 1)
    element.UpSprite:setColor(1, 1, 1)
    element:select()
  else
    local text = LOC("NOTIFICATION_NEW_CONUNDRUM_ISLAND")
    local islandName = LOC(game.islandName(game.currentIsland()))
    text = text:gsub("%${ISLAND}", islandName)
    game.displayNotification(text)
    element:parent():parent():Hide()
  end
  element("ButtonState"):SetInt(game.BUTTON_RELEASED)
  element("TickTimer"):SetFloat(0)
end
function ActivityCenterCalendarButton.Touch:onTouchRelease(element)
  if element.enabled then
    element.icon:setColor(1, 1, 1)
    element.UpSprite:setColor(1, 1, 1)
  end
  element("ButtonState"):SetInt(game.BUTTON_RELEASED)
  element("TickTimer"):SetFloat(0)
end
return ActivityCenterCalendarButton
