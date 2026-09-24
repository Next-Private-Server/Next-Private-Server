local HudButtonStickerbook = {
  Button = {
    Overlay = {},
    Label = {},
    StarBar = {
      BG = {},
      Icon = {},
      Text = {}
    },
    Touch = {},
    Indicator = {}
  }
}
local getStickerStars = function()
  local playerCardAlbum = game.player():currentlyActiveCardAlbum()
  return playerCardAlbum and playerCardAlbum:cardCurrency() or 0
end
function HudButtonStickerbook:onInit()
  self:setSearchChildren(false)
  self.showIndicator = false
  self.Button.Indicator:Hide()
  self.availabilityTimer = 0.1
  self.shouldShowButton = false
  self.isVisibleOnHUD = nil
end
function HudButtonStickerbook:onPostInit()
  local h = self.Button:absH() + self.Button.Label:absH() * 0.5
  self:setSize(lua_sys.Vector2(self.Button:absW(), h))
  self:updateTimer()
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgUpdatedViewedCards", "RefreshCardAlbumAlert")
end
function HudButtonStickerbook:updateTimer()
  local event = game.getCurrentCardAlbumEvent()
  local secsRemaining = event and event:timeRemainingSec() or 0
  if secsRemaining > 0 then
    local needUpdate = secsRemaining ~= self.secsRemaining
    self.secsRemaining = secsRemaining
    if needUpdate then
      local initialButtonScale = 0.24 * game.hudScale()
      local c = self.Button.Label
      c:GetVar("size"):SetFloat(initialButtonScale)
      c:V("text"):SetString(game.timeToString(secsRemaining, true))
      c:V("autoScale"):SetInt(1)
      self:RefreshStickerCount()
    end
  end
  return secsRemaining
end
function HudButtonStickerbook:onTick(dt)
  self.availabilityTimer = self.availabilityTimer - dt
  if self.availabilityTimer < 0 then
    availabilityTimer = 1
    local secsRemaining = self:updateTimer()
    if secsRemaining == 0 then
      self:Hide()
    end
  end
end
function HudButtonStickerbook:SetVisibility(visible)
  local isVisibleOnHUD = not self.isVisibleOnHUD or self.isVisibleOnHUD()
  if visible then
    if self.shouldShowButton and isVisibleOnHUD then
      self.Button:setVisible()
      self.Button.Overlay("visible"):SetInt(1)
      self.Button.Label("visible"):SetInt(1)
      if getStickerStars() > 0 then
        self.Button.StarBar.BG("visible"):SetInt(1)
        self.Button.StarBar.Icon("visible"):SetInt(1)
        self.Button.StarBar.Text("visible"):SetInt(1)
      end
      if self.showIndicator then
        self.Button.Indicator:Show()
      end
    end
  else
    self.Button:setInvisible()
    self.Button.Overlay("visible"):SetInt(0)
    self.Button.Label("visible"):SetInt(0)
    self.Button.Indicator:Hide()
    self.Button.StarBar.BG("visible"):SetInt(0)
    self.Button.StarBar.Icon("visible"):SetInt(0)
    self.Button.StarBar.Text("visible"):SetInt(0)
  end
  self.hidden = not self.shouldShowButton
end
function HudButtonStickerbook:hide()
  self:SetVisibility(false)
end
function HudButtonStickerbook:Hide()
  self:SetVisibility(false)
end
function HudButtonStickerbook:show()
  self:SetVisibility(true)
end
function HudButtonStickerbook:Show()
  self:SetVisibility(true)
end
function HudButtonStickerbook:SetClipRect(x, y, w, h)
  self.Button:SetClipRect(x, y, w, h)
  self.Button.Overlay:setClipRect(x, y, w, h)
  self.Button.Label:setClipRect(x, y, w, h)
  self.Button.Touch:setClipRect(x, y, w, h)
  self.Button.Indicator.Sprite:setClipRect(x, y, w, h)
  self.Button.StarBar.BG:setClipRect(x, y, w, h)
  self.Button.StarBar.Icon:setClipRect(x, y, w, h)
  self.Button.StarBar.Text:setClipRect(x, y, w, h)
end
function HudButtonStickerbook:RefreshCardAlbumStatus()
  local cardAlbumEvent = game.getCurrentCardAlbumEvent()
  if cardAlbumEvent and game.player():currentlyActiveCardAlbum() then
    local playerCardAlbum = game.player():currentlyActiveCardAlbum()
    if playerCardAlbum:numCardsCollected() > 0 then
      self.shouldShowButton = true
      self:RefreshCardAlbumAlert()
      self:Show()
    else
      self.shouldShowButton = false
      self:Hide()
    end
  else
    self.shouldShowButton = false
    self:Hide()
  end
end
function HudButtonStickerbook:RefreshCardAlbumAlert()
  local showIndicator = false
  local cardAlbumEvent = game.getCurrentCardAlbumEvent()
  local cardAlbum = game.getCardAlbumData(cardAlbumEvent:getCardAlbumId())
  local playerCardAlbum = game.player():currentlyActiveCardAlbum()
  local pages = cardAlbum:getPages()
  for i = 0, pages:size() - 1 do
    local cards = pages[i]:getCards()
    for j = 0, cards:size() - 1 do
      if playerCardAlbum:hasCard(cards[j]) and game.player():hasViewedCard(cards[j]) == false then
        showIndicator = true
        break
      end
    end
    if playerCardAlbum:isPageComplete(pages[i]:getId()) and playerCardAlbum:hasCollectedPageRewards(pages[i]:getId()) == false then
      showIndicator = true
      break
    end
  end
  if playerCardAlbum:isAlbumComplete() and playerCardAlbum:hasCollectedAlbumRewards() == false then
    showIndicator = true
  end
  if showIndicator and not self.hidden then
    self.Button.Indicator:Show()
  else
    self.Button.Indicator:Hide()
  end
  self.showIndicator = showIndicator
end
function HudButtonStickerbook:RefreshStickerCount()
  local numStickers = getStickerStars()
  local isVisibleOnHUD = not self.isVisibleOnHUD or self.isVisibleOnHUD()
  local visInt = isVisibleOnHUD and self.shouldShowButton and numStickers > 0 and 1 or 0
  self.Button.StarBar.BG("visible"):SetInt(visInt)
  self.Button.StarBar.Icon("visible"):SetInt(visInt)
  self.Button.StarBar.Text("visible"):SetInt(visInt)
  self.Button.StarBar.Text("text"):SetString(tostring(getStickerStars()))
end
return HudButtonStickerbook
