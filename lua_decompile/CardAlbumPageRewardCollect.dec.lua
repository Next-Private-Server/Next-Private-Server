local FadeTransition = include("FadeTransition")
local CardAlbumPageRewardCollect = {
  TitleFrame = {},
  CardsLeft = {},
  CardsRight = {},
  TitleText = {
    Text = {}
  },
  Anim = {},
  Text = {},
  CollectButton = {}
}
local TRANSITION_TIME = 0.33
function CardAlbumPageRewardCollect:onPostInit()
  self.cardAlbumEvent = game.getCurrentCardAlbumEvent()
  self.playerCardAlbum = game.player():currentlyActiveCardAlbum()
  self.cardAlbum = game.getCardAlbumData(self.cardAlbumEvent:getCardAlbumId())
  self.pages = self.cardAlbum:getPages()
  self.completedPage = nil
  local pageNum = 0
  for i = 0, self.pages:size() - 1 do
    if self.playerCardAlbum:isPageComplete(self.pages[i]:getId()) and self.playerCardAlbum:hasCollectedPageRewards(self.pages[i]:getId()) == false then
      self.completedPage = self.pages[i]
      pageNum = i + 1
      break
    end
  end
  if self.completedPage ~= nil then
    self.Text:V("text"):SetString(self.completedPage:getName())
    local cardAlbumEvent = game.getCurrentCardAlbumEvent()
    local cardAlbum = game.getCardAlbumData(cardAlbumEvent:getCardAlbumId())
    local animUtil = game.AnimUtil(self.Anim)
    animUtil:addSheetRemap("stickers_album_sheet_02.xml", cardAlbum.assetPath)
    animUtil:addRemap("page_image", cardAlbum.assetPath, "album_page_" .. string.format("%02d", pageNum))
    animUtil:resetAnim()
  end
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgCardAbumRewardCollected", "gotMsgCardAbumRewardCollected")
  self.fadeTransition = FadeTransition:new({
    duration = TRANSITION_TIME,
    onUpdate = function(alpha)
      self.TitleText.Text:V("alpha"):SetFloat(alpha)
      self.TitleFrame.Sprite:V("alpha"):SetFloat(alpha)
      self.CardsLeft:V("alpha"):SetFloat(alpha)
      self.CardsRight:V("alpha"):SetFloat(alpha)
      self.Text:V("alpha"):SetFloat(alpha)
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
  self.fadeDelay = 0.33
  lua_sys.playSoundFx("audio/sfx/menu_stickerbook_pagecomplete.wav")
end
function CardAlbumPageRewardCollect:onTick(dt)
  if self.showingIntro then
    self.fadeDelay = math.max(self.fadeDelay - dt, 0)
    if self.fadeDelay == 0 then
      self.fadeTransition:Show()
      self.showingIntro = false
    end
  end
  self.fadeTransition:Tick(dt)
end
function CardAlbumPageRewardCollect:collectReward()
  if game.getCurrentCardAlbumEvent() ~= nil then
    game.collectCardAlbumPageRewards(game.getCurrentCardAlbumEvent():getCardAlbumId(), self.completedPage:getId())
  else
    self:root():removePopUp(self:name())
  end
end
function CardAlbumPageRewardCollect:gotMsgCardAbumRewardCollected(msg)
  self:root():removePopUp(self:name())
  local popup = game.pushPopUp("popup_store_bundle_rewards")
  popup:Setup(msg:rewards())
end
return CardAlbumPageRewardCollect
