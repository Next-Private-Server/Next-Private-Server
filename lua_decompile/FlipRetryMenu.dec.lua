local FlipRetryMenu = {}
FlipRetryMenu.transitionState = 1
FlipRetryMenu.transitionTime = 0
FlipRetryMenu.choice = "none"
FlipRetryMenu.eFadedBgSprite = nil
FlipRetryMenu.eBg = nil
FlipRetryMenu.eNotification = nil
FlipRetryMenu.ePrizesRemainingFirstRow = nil
function FlipRetryMenu:onInit()
  self.eFadedBgSprite = self:E("FadedBG")
  self.eBg = self:E("bg")
  self.eNotification = self:E("Notification")
  self.ePrizesRemainingFirstRow = self:E("PrizesRemainingFirstRow")
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function FlipRetryMenu:TickTransition()
  self.eBg:V("xOffset"):SetFloat(lua_sys.screenWidth() * 0.5 + -0.5 * lua_sys.screenWidth() * (1 / math.max(0.001, self.transitionTime)))
  self.eFadedBgSprite:C("Sprite"):V("alpha"):SetFloat(self.transitionTime * 0.5)
end
function FlipRetryMenu:queuePop()
  self.transitionState = 2
end
function FlipRetryMenu:onTick(dt)
  if self.transitionState ~= 0 then
    self:TickTransition()
    if self.transitionState == 1 then
      self.transitionTime = self.transitionTime + dt * 3
    elseif self.transitionState == 2 then
      self.transitionTime = self.transitionTime - dt * 3
    end
    self.transitionTime = lua_sys.clamp(self.transitionTime, 0, 1)
    if 1 <= self.transitionTime then
      self.transitionState = 0
      self.transitionTime = 1
      self:TickTransition()
    elseif 0 >= self.transitionTime then
      local textID = self.eNotification:C("Text"):V("text"):GetString()
      if string.match(textID, " ") then
        textID = ""
      end
      if self.choice == "true" then
        self:root():popPopUp()
        game.submitConfirmation(self:V("messageID"):GetString(), true, textID)
      else
        self:root():popPopUp()
        game.submitConfirmation(self:V("messageID"):GetString(), false, textID)
      end
    end
  end
end
return FlipRetryMenu
