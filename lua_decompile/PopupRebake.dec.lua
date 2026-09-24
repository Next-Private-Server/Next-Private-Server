local PopupRebake = {
  messageID = "REBAKERY_PURCHASE",
  transitionState = 1,
  transitionTime = 0,
  choice = "none",
  FadedBG = {
    Sprite = {}
  },
  bg = {},
  TitleFrame = {},
  TitleLabel = {
    Text = {}
  },
  Notification = {
    Text = {}
  },
  YesButton = {},
  NoButton = {},
  Warning = {}
}
function PopupRebake:onInit()
  self.transitionState = 1
  self.transitionTime = 0
  self.choice = "none"
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function PopupRebake:onPostInit()
  local msg = game.getLocalizedText("REBAKE_CONFIRMATION")
  msg = select(1, msg:gsub("XXX", game.getNumAvailableRebakeBakeries()))
  msg = select(1, msg:gsub("YYY", game.commaizeNumber(game.getRebakeAllCost())))
  self.Notification.Text:GetVar("text"):SetString(msg)
  if not game.hasLastBakedAnniversarySnack() then
    self.Warning:DoStoredScript("Hide")
  end
end
function PopupRebake:onTick(dt)
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
      if self.choice == "true" then
        self:root():popPopUp()
        game.submitConfirmation(self.messageID, true)
      else
        self:root():popPopUp()
        game.submitConfirmation(self.messageID, false)
      end
    end
  end
end
function PopupRebake:TickTransition()
  self.bg:V("xOffset"):SetFloat(lua_sys.screenWidth() * 0.5 + -0.5 * lua_sys.screenWidth() * (1 / math.max(0.001, self.transitionTime)))
  self.FadedBG.Sprite:V("alpha"):SetFloat(self.transitionTime * 0.5)
end
function PopupRebake:queuePop()
  self.transitionState = 2
end
return PopupRebake
