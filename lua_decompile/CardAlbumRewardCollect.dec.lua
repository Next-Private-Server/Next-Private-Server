local FadeTransition = include("FadeTransition")
local CardAlbumRewardCollect = {
  TitleFrame = {},
  CardsLeft = {},
  CardsRight = {},
  TitleText = {
    Text = {}
  },
  Anim = {},
  Text = {},
  CollectButton = {
    Touch = {}
  }
}
local TRANSITION_TIME = 0.33
function CardAlbumRewardCollect:onPostInit()
  self.cardAlbumEvent = game.getCurrentCardAlbumEvent()
  self.playerCardAlbum = game.player():currentlyActiveCardAlbum()
  self.cardAlbum = game.getCardAlbumData(self.cardAlbumEvent:getCardAlbumId())
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgCardAbumRewardCollected", "gotMsgCardAbumRewardCollected")
  self:SetupGenericListener(self.Anim:GetReceiver(), "sys::msg::MsgAnimationFinished", "gotMsgAnimationFinished")
  self.fadeTransition = FadeTransition:new({
    duration = TRANSITION_TIME,
    onUpdate = function(alpha)
      self.TitleText.Text:V("alpha"):SetFloat(alpha)
      self.TitleFrame.Sprite:V("alpha"):SetFloat(alpha)
      self.CardsLeft:V("alpha"):SetFloat(alpha)
      self.CardsRight:V("alpha"):SetFloat(alpha)
      self.CollectButton:setAlpha(alpha)
    end,
    onDoneShow = function()
      self.CollectButton.Touch:V("enabled"):SetInt(1)
    end,
    onHide = function()
      self.CollectButton.Touch:V("enabled"):SetInt(0)
    end
  })
  self.fadeTransition:SetAlpha(0)
  self.showingIntro = true
  self.fadeDelay = 1.8
  lua_sys.playSoundFx("audio/sfx/menu_stickerbook_bookcomplete.wav")
end
function CardAlbumRewardCollect:onTick(dt)
  if self.showingIntro then
    self.fadeDelay = math.max(self.fadeDelay - dt, 0)
    if self.fadeDelay == 0 then
      self.fadeTransition:Show()
      self.showingIntro = false
    end
  end
  self.fadeTransition:Tick(dt)
end
function CardAlbumRewardCollect:collectReward()
  if game.getCurrentCardAlbumEvent() ~= nil then
    game.collectCardAlbumRewards(game.getCurrentCardAlbumEvent():getCardAlbumId())
  else
    self:root():removePopUp(self:name())
  end
end
function CardAlbumRewardCollect:gotMsgCardAbumRewardCollected(msg)
  self:root():removePopUp(self:name())
  local popup = game.pushPopUp("popup_store_bundle_rewards")
  popup:Setup(msg:rewards())
end
function CardAlbumRewardCollect:gotMsgAnimationFinished(msg)
end
return CardAlbumRewardCollect
