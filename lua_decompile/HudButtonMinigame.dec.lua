local HudButtonMinigame = {
  Button = {
    Overlay = {},
    TimerBar = {
      BG = {},
      Text = {}
    },
    TicketBar = {
      BG = {},
      Icon = {},
      Text = {}
    },
    Touch = {},
    Indicator = {}
  }
}
function HudButtonMinigame:SetVisibility(visible)
  if visible then
    self.Button:setVisible()
    if self.showIndicator then
      self.Button.Indicator:Show()
    end
  else
    self.Button:setInvisible()
    self.Button.Indicator:Hide()
  end
  local val = visible and 1 or 0
  self.Button.Overlay("visible"):SetInt(val)
  self.Button.TimerBar.Text("visible"):SetInt(val)
  self.Button.TicketBar.BG("visible"):SetInt(val)
  self.Button.TicketBar.Icon("visible"):SetInt(val)
  self.Button.TicketBar.Text("visible"):SetInt(val)
  self.Button.hidden = not visible
  self.hidden = not visible
end
function HudButtonMinigame:Setup(minigameId)
  self.MinigameId = minigameId
end
function HudButtonMinigame:onInit()
  self.showIndicator = false
  self.Button.Indicator:Hide()
  self.availabilityTimer = 0.1
  self:setSearchChildren(false)
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlayerUpdated", "gotMsgPlayerUpdated")
end
function HudButtonMinigame:onPostInit()
  self.Button.Overlay("spriteName"):Set(game.getMinigameIcon(self.MinigameId))
  local h = self.Button:absH() + self.Button.TimerBar.BG:absH() * 0.5 + self.Button.TicketBar.BG:absH() * 0.5
  self:setSize(lua_sys.Vector2(self.Button:absW(), h))
  self:onTick(0)
end
function HudButtonMinigame:hide()
  self:SetVisibility(false)
end
function HudButtonMinigame:show()
  self:SetVisibility(true)
end
function HudButtonMinigame:updateTimer(secsRemaining)
  local needUpdate = secsRemaining ~= self.secsRemaining
  self.secsRemaining = secsRemaining
  if needUpdate then
    local initialButtonScale = 0.24 * game.hudScale()
    local c = self.Button.TimerBar.Text
    c:GetVar("size"):SetFloat(initialButtonScale)
    c:GetVar("text"):SetString(game.timeToString(secsRemaining, true))
    c:GetVar("autoScale"):SetInt(1)
  end
end
function HudButtonMinigame:onTick(dt)
  self.availabilityTimer = self.availabilityTimer - dt
  if self.availabilityTimer < 0 then
    availabilityTimer = 1
    local secsRemaining = game.minigameTimeRemaining(self.MinigameId)
    if secsRemaining > 0 then
      self:updateTimer(secsRemaining)
      if game.player():hasMinigameData(self.MinigameId) then
        if self.showIndicator then
          self.showIndicator = false
          self.Button.Indicator:Hide()
        end
      elseif not self.showIndicator then
        self.showIndicator = true
        if not self.hidden then
          self.Button.Indicator:Show()
        end
      end
    else
      self:hide()
    end
  end
end
function HudButtonMinigame:gotMsgPlayerUpdated(msg)
  self.Button.TicketBar.Text:GetVar("text"):SetString(game.playerMinigameTokens())
end
function HudButtonMinigame:SetClipRect(x, y, w, h)
  self.Button:SetClipRect(x, y, w, h)
  self.Button.Overlay:setClipRect(x, y, w, h)
  self.Button.TimerBar.BG:setClipRect(x, y, w, h)
  self.Button.TimerBar.Text:setClipRect(x, y, w, h)
  self.Button.TicketBar.BG:setClipRect(x, y, w, h)
  self.Button.TicketBar.Icon:setClipRect(x, y, w, h)
  self.Button.TicketBar.Text:setClipRect(x, y, w, h)
  self.Button.Touch:setClipRect(x, y, w, h)
  self.Button.Indicator.Sprite:setClipRect(x, y, w, h)
end
function HudButtonMinigame:GotoMinigame()
  game.goToMinigame(self.MinigameId)
end
return HudButtonMinigame
