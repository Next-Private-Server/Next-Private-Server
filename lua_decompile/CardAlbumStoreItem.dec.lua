local CardAlbumStoreItem = {
  BuyButton = {
    CurrencyAmount = {
      Text = {},
      Sprite = {}
    },
    Touch = {}
  },
  Touch = {}
}
function CardAlbumStoreItem:onPostInit()
  local storeItemData = game.getCardAlbumStoreItemData(self:templateVars().storeItemId)
  self.BuyButton.CurrencyAmount.Text:V("text"):SetString(storeItemData.cost)
end
function CardAlbumStoreItem.Touch:onTouchUp(element, x, y)
  self:parent():parent():selectStoreItem(element:templateVars().storeItemId)
end
return CardAlbumStoreItem
