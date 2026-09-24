local FadeTransition = include("FadeTransition")
local HypeGamePrestige = {
  TitleFrame = {
    Text = {}
  },
  Anim = {},
  Text = {},
  ReturnButton = {
    Touch = {}
  }
}
local TRANSITION_TIME = 0.33
function HypeGamePrestige:onPostInit()
  self.fadeTransition = FadeTransition:new({
    duration = TRANSITION_TIME,
    onUpdate = function(alpha)
      self.TitleFrame:setAlpha(alpha)
      self.ReturnButton:setAlpha(alpha)
    end,
    onDoneShow = function()
      self.ReturnButton.Touch:V("enabled"):SetInt(1)
    end,
    onHide = function()
      self.ReturnButton.Touch:V("enabled"):SetInt(0)
    end
  })
  lua_sys.playSoundFx("audio/sfx/clubbox_prestige_intro.wav")
  self.fadeTransition:SetAlpha(0)
  self.showingIntro = true
  self.fadeDelay = 1.8
  self.showOutro = false
  self.readyToShowOutro = false
  self.showingOutro = false
  self:SetupGenericListener(self.Anim:GetReceiver(), "sys::msg::MsgAnimationFinished", "gotMsgAnimationFinished")
end
function HypeGamePrestige:onTick(dt)
  if self.showingIntro then
    self.fadeDelay = math.max(self.fadeDelay - dt, 0)
    if self.fadeDelay == 0 then
      self.fadeTransition:Show()
      self.showingIntro = false
    end
  elseif self.showOutro and self.readyToShowOutro and not self.showingOutro then
    self.showingOutro = true
    lua_sys.playSoundFx("audio/sfx/clubbox_prestige_outro.wav")
    self.Anim("animation"):SetString("clubbox_complete_outro")
  end
  self.fadeTransition:Tick(dt)
end
function HypeGamePrestige:onClick()
  self.showOutro = true
  self.ReturnButton:DoStoredScript("disable")
  self.fadeTransition:Hide()
end
function HypeGamePrestige:gotMsgAnimationFinished(msg)
  if self.showOutro and not self.readyToShowOutro then
    self.readyToShowOutro = true
  end
  if self.showingOutro then
    self:root():removePopUp(self:name())
  end
end
return HypeGamePrestige
