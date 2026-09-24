local MenuElementPositionOffsetTransition = include("MenuElementPositionOffsetTransition")
local CardAlbumStore = {
  ExitButton = {
    Touch = {}
  },
  bg = {},
  CurrencyCounter = {}
}
function CardAlbumStore:onPostInit()
  self.eventOver = false
  self.exiting = false
  self.cardAlbumEvent = game.getCurrentCardAlbumEvent()
  self:refresh()
  MenuElementPositionOffsetTransition.OnInit(self.bg, {
    startY = lua_sys.screenHeight() * 1,
    endY = -20 * game.menuScaleX(),
    duration = 0.33
  })
  MenuElementPositionOffsetTransition.Show(self.bg)
  MenuElementPositionOffsetTransition.OnInit(self.CurrencyCounter, {
    startY = lua_sys.screenHeight() * -1,
    endY = 0,
    duration = 0.33
  })
  MenuElementPositionOffsetTransition.Show(self.CurrencyCounter)
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgConfirmationSubmission", "gotMsgConfirmationSubmission")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgBuyCardAlbumStoreItemComplete", "gotMsgBuyCardAlbumStoreItemComplete")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgCardAlbumUpdated", "gotMsgCardAlbumUpdated")
end
function CardAlbumStore:refresh()
  local playerCardAlbum = game.player():currentlyActiveCardAlbum()
  if playerCardAlbum ~= nil then
    self.CurrencyCounter:C("Text"):V("text"):SetString(game.commaizeNumber(playerCardAlbum:cardCurrency()))
  end
end
function CardAlbumStore:queuePop()
  if self.exiting == false then
    self.exiting = true
    self:close()
  end
end
function CardAlbumStore:onTick(dt)
  local options = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
      e:root():removePopUp(self:name())
    end
  }
  MenuElementPositionOffsetTransition.OnTick(self.bg, dt, options)
  MenuElementPositionOffsetTransition.OnTick(self.CurrencyCounter, dt, {
    ease = lua_sys.Quadratic_EaseIn
  })
  local secsRemaining = self.cardAlbumEvent:timeRemainingSec()
  if secsRemaining <= 0 then
    if game.popUpManagerTopPopUp():name() == "card_album_store_confirmation" then
      game.popTopPopUp()
    elseif game.topPopUp() == self and self.eventOver == false and game.popUpManagerTopPopUp():name() == "MenuReduxElement_Root" then
      self.eventOver = true
      self:close()
    end
  end
end
function CardAlbumStore:selectStoreItem(storeItemId)
  self.currentStoreItemId = storeItemId
  local storeItemData = game.getCardAlbumStoreItemData(storeItemId)
  local menu = game.pushPopUp("card_album_store_confirmation")
  menu:SetStoreItem(storeItemData)
end
function CardAlbumStore.ExitButton.Touch:onTouchUp(element, x, y)
  self:super_onTouchUp(element)
  self:parent():parent():queuePop()
end
function CardAlbumStore:close()
  self.ExitButton:C("Overlay"):setColor(1, 1, 1)
  MenuElementPositionOffsetTransition.Hide(self.bg)
  MenuElementPositionOffsetTransition.Hide(self.CurrencyCounter)
  self.ExitButton:Disable()
end
function CardAlbumStore:gotMsgConfirmationSubmission(msg)
  if msg.messageID == "BUY_CARD_ALBUM_ITEM" and msg.choice == true then
    local playerCardAlbum = game.player():currentlyActiveCardAlbum()
    if playerCardAlbum ~= nil then
      local storeItemData = game.getCardAlbumStoreItemData(self.currentStoreItemId)
      if playerCardAlbum:cardCurrency() >= storeItemData.cost then
        game.buyCardAlbumStoreItem(self.currentStoreItemId)
      else
        game.displayNotification("NOTIFICATION_NOT_ENOUGH_CARD_CURRENCY")
      end
    end
  end
end
function CardAlbumStore:gotMsgBuyCardAlbumStoreItemComplete(msg)
  local pendingRewards = {}
  local rewards = msg:rewards()
  if rewards:size() > 0 then
    for i = 0, rewards:size() - 1 do
      local reward = rewards[i]
      table.insert(pendingRewards, {
        id = reward.id,
        type = reward.type,
        amount = reward.amount
      })
    end
  end
  local popup = game.pushPopUp("open_card_box")
  popup:Setup(pendingRewards)
end
function CardAlbumStore:gotMsgCardAlbumUpdated(msg)
  self:refresh()
end
return CardAlbumStore
