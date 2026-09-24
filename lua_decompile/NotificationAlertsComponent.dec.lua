local NotificationAlertsComponent = {}
local ALERT_PADDING = 2
local alerts = {}
function NotificationAlertsComponent:onInit()
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgShowLootResultNotificationAlert", "gotMsgShowLootResultNotificationAlert")
  self.alertId = 0
  local growDirection = self:templateVars().growDirection:lower()
  if growDirection == "down" then
    self.anchorY = lua_sys.TOP
  else
    self.anchorY = lua_sys.BOTTOM
  end
end
function NotificationAlertsComponent:gotMsgShowLootResultNotificationAlert(msg)
  self:createLootResultAlert(msg.reward)
end
function NotificationAlertsComponent:onTick(dt)
  local i = 1
  local visibleIndex = 1
  while i <= #alerts do
    local alert = alerts[i]
    if alert.TTL < 0 then
      table.remove(alerts, i)
      self:RemoveElement(alert)
    else
      local targetPosY = (visibleIndex - 1) * (ALERT_PADDING + alert:absH())
      local currentPosY = alert:GetVar("yOffset"):GetFloat()
      if targetPosY < currentPosY then
        local diff = currentPosY - targetPosY
        if diff > 20 then
          diff = diff * 0.333
        end
        alert:GetVar("yOffset"):SetFloat(currentPosY - diff)
      end
      i = i + 1
      if not alert:isAlmostDoneFadeOut() then
        visibleIndex = visibleIndex + 1
      end
    end
  end
end
function NotificationAlertsComponent:createAlert()
  local alert = menu:addTemplateElement("template_notification_alert", "alert" .. self.alertId, self)
  self.alertId = self.alertId + 1
  alert:relativeTo(self)
  alert:setRelativeObjectAnchors(lua_sys.LEFT, self.anchorY)
  alert:templateVars().layer = "FrontClipping"
  alert:init()
  alert:setPositionBroadcast(true)
  alert:postInit()
  alert:setTTL(2.5 + 0.3 * #alerts, 0.1 * #alerts)
  alert:setOrientation(lua_sys.MenuOrientation(0, #alerts * (ALERT_PADDING + alert:absH()), 0, lua_sys.LEFT, self.anchorY))
  table.insert(alerts, alert)
  return alert
end
function NotificationAlertsComponent:createLootResultAlert(lootResult)
  local alert = self:createAlert()
  alert:fromLootResult(lootResult)
  return alert
end
return NotificationAlertsComponent
