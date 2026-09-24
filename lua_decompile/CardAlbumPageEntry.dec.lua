local CardAlbumPageEntry = {
  Anim = {},
  Text = {},
  Touch = {},
  BarBackingSprite = {},
  BarSprite = {},
  BarText = {}
}
function CardAlbumPageEntry:onInit()
  self.enabled = true
  self.touchEnabled = true
  self.dragging = 0
  self.touchStart = 0
  self.touchStartY = 0
end
function CardAlbumPageEntry:onPostInit()
  self.Text:V("text"):SetString(self.pageData:getName())
  local cardAlbumEvent = game.getCurrentCardAlbumEvent()
  local cardAlbum = game.getCardAlbumData(cardAlbumEvent:getCardAlbumId())
  local animUtil = game.AnimUtil(self.Anim)
  animUtil:addSheetRemap("stickers_album_sheet_01.xml", cardAlbum.assetPath)
  animUtil:addRemap("page_image", cardAlbum.assetPath, "album_page_" .. string.format("%02d", self.pageNum))
  animUtil:resetAnim()
  self:refresh()
end
function CardAlbumPageEntry:refresh()
  local playerCardAlbum = game.player():currentlyActiveCardAlbum()
  if playerCardAlbum:isPageComplete(self.pageData:getId()) then
    self.Anim("animation"):SetString("sticker_album_complete")
  end
  local numCardsCollected = playerCardAlbum:numCardsCollectedOnPage(self.pageData:getId())
  local totalCards = self.pageData:getCards():size()
  self.BarText:V("text"):SetString(numCardsCollected .. "/" .. totalCards)
  local percentage = numCardsCollected / totalCards
  self.BarSprite:V("maskWidth"):SetFloat(self.BarSprite:V("FullMaskW"):GetInt() * clamp(percentage, 0, 1))
  local showNotification = false
  local cards = self.pageData:getCards()
  for i = 0, cards:size() - 1 do
    if playerCardAlbum:hasCard(cards[i]) and game.player():hasViewedCard(cards[i]) == false then
      showNotification = true
      break
    end
  end
  if playerCardAlbum:isPageComplete(self.pageData:getId()) and playerCardAlbum:hasCollectedPageRewards(self.pageData:getId()) == false then
    showNotification = true
  end
  local cardAlbum = game.getCardAlbumData(playerCardAlbum:cardAlbumId())
  local animUtil = game.AnimUtil(self.Anim)
  if showNotification then
    animUtil:addRemap("new_sticker", cardAlbum.assetPath, "new_sticker")
  else
    animUtil:addRemap("new_sticker", "empty.xml", "empty")
  end
  animUtil:resetAnim()
end
function CardAlbumPageEntry.Touch:onTouchUp(element, x, y)
  if element.touchEnabled and element.dragging < 4 * game.windowScaleY() then
    element:parent():parent():parent():selectPage(element)
  end
end
function CardAlbumPageEntry:SetClipping(x, y, w, h)
  self.Anim:setClipRect(x, y, w, h)
  self.Text:setClipRect(x, y, w, h)
  self.Touch:setClipRect(x, y, w, h)
  self.BarBackingSprite:setClipRect(x, y, w, h)
  self.BarSprite:setClipRect(x, y, w, h)
  self.BarText:setClipRect(x, y, w, h)
end
function CardAlbumPageEntry:SetAlpha(alpha)
  self.Anim:V("alpha"):SetFloat(alpha)
  self.Anim.Sprite:setColor(alpha, alpha, alpha)
  self.Text:V("alpha"):SetFloat(alpha)
  self.Touch:V("alpha"):SetFloat(alpha)
  self.BarBackingSprite:V("alpha"):SetFloat(alpha)
  self.BarSprite:V("alpha"):SetFloat(alpha)
  self.BarText:V("alpha"):SetFloat(alpha)
end
function CardAlbumPageEntry:enableTouch()
  self.Touch:V("enable"):SetInt(1)
end
function CardAlbumPageEntry:disableTouch()
  self.Touch:V("enable"):SetInt(0)
end
function CardAlbumPageEntry.Touch:onTouchDown(element, x, y)
  element.dragging = 0
  element.touchStartY = y
end
function CardAlbumPageEntry.Touch:onTouchDrag(element, x, y, dx, dy)
  element.dragging = math.abs(element.touchStartY - y)
end
return CardAlbumPageEntry
