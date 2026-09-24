local CardAlbumCardPopup = {
  FadedBG = {
    Touch = {}
  },
  Card = {}
}
function CardAlbumCardPopup:onInit()
  lua_sys.playSoundFx(string.format("audio/sfx/sticker_flip_generic_%02d.wav", math.random(1, 4)))
  self.Card.Sprite:setScale(Vector2(0.55 * game.windowScaleY(), 0.55 * game.windowScaleY()))
end
function CardAlbumCardPopup:onPostInit()
  local w = self.Card.Sprite:absW()
  local h = self.Card.Sprite:absH()
  self.Card.Sprite:setPosition(Vector2((screenWidth() - w) * 0.5, (screenHeight() - h) * 0.5 - 20 * game.windowScaleY()))
end
function CardAlbumCardPopup:Setup(cardData)
  self.Card:Setup(cardData, false, false)
end
function CardAlbumCardPopup.FadedBG.Touch:onTouchUp(element, x, y)
  lua_sys.playSoundFx(string.format("audio/sfx/sticker_flip_generic_%02d.wav", math.random(1, 4)))
  element:root():popPopUp()
end
return CardAlbumCardPopup
