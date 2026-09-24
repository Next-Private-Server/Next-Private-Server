local Currencies = require("Currencies")
local CurrencyCounter = {
  BackingSprite = {},
  Icon = {},
  Plus = {},
  Text = {},
  Touch = {}
}
local ICON_SIZE = 26 * game.hudScale()
function CurrencyCounter:onPostInit()
  self.currencyType = game.CurrencyType_Diamonds
  self.currentAmount = 0
  self.targetAmount = 0
  self.alpha = 1
  self.rate = 0
  self:setCurrencyType(tonumber(self:templateVars().currencyType))
  self.autoHide = tonumber(self:templateVars().autoHide) == 1
  if tonumber(self:templateVars().flyingIconMode) == 0 then
    self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlayerUpdated", "gotMsgPlayerUpdated")
  else
    self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgFlyingIconLanded", "gotMsgFlyingIconLanded")
  end
  if self.currencyType == game.CurrencyType_MinigameTokens then
    self:SetupGenericListener(game.engineReceiver(), "game::msg::minigame::MsgMinigameRefreshTokens", "gotMsgMinigameRefreshTokens")
    self:SetupGenericListener(game.engineReceiver(), "game::msg::minigame::MsgMinigameRefreshState", "gotMsgMinigameRefreshState")
  elseif self.currencyType == game.CurrencyType_CardPack then
    self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgCardPackOpened", "gotMsgCardPackOpened")
  end
  self:refreshCurrencyAmount(true)
  if self.onClick then
    self.Plus("visible"):SetInt(1)
    self.Touch("enabled"):SetInt(1)
  else
    self.Plus("visible"):SetInt(0)
    self.Touch("enabled"):SetInt(0)
  end
end
function CurrencyCounter:setCurrencyType(currency_type)
  self.currencyType = currency_type
  local currencyProps = Currencies:getProps(self.currencyType)
  currencyProps:applyToSpriteSheet(self.Icon)
  currencyProps:applyToText(self.Text)
  self.Icon("size"):SetFloat(1)
  local scaleW = ICON_SIZE / self.Icon:absW()
  local scaleH = ICON_SIZE / self.Icon:absH()
  self.Icon("size"):SetFloat(math.min(scaleW, scaleH))
end
function CurrencyCounter:onTick(dt)
  if self.currentAmount ~= self.targetAmount then
    local diff = self.targetAmount - self.currentAmount
    if self.rate == 0 then
      self.rate = math.max(20, math.abs(diff) / 2)
    end
    if math.abs(diff) < self.rate * 0.1 then
      self:setAmount(self.targetAmount, false)
      self.rate = 0
      if self.onDoneCounting then
        self:onDoneCounting()
      end
    else
      self:setAmount(self.currentAmount + self.rate * dt * diff / math.abs(diff), false)
    end
  end
end
function CurrencyCounter:refreshCurrencyAmount(instant)
  local newAmount = self.targetAmount
  if self.currencyType == game.CurrencyType_Coins then
    newAmount = game.playerCoins()
  elseif self.currencyType == game.CurrencyType_Diamonds then
    newAmount = game.playerDiamonds()
  elseif self.currencyType == game.CurrencyType_Food then
    newAmount = game.playerFood()
  elseif self.currencyType == game.CurrencyType_Shards then
    newAmount = game.playerEtherealCurrency()
  elseif self.currencyType == game.CurrencyType_Starpower then
    newAmount = game.playerStarpower()
  elseif self.currencyType == game.CurrencyType_Keys then
    newAmount = game.playerKeys()
  elseif self.currencyType == game.CurrencyType_Relics then
    newAmount = game.playerRelics()
  elseif self.currencyType == game.CurrencyType_Medals then
    newAmount = game.playerMedals()
  elseif self.currencyType == game.CurrencyType_EggWildcards then
    newAmount = game.playerEggWildcards()
  elseif self.currencyType == game.CurrencyType_ClubboxTokens then
    newAmount = game.playerClubboxTokens()
  elseif self.currencyType == game.CurrencyType_CardPack then
    self:refreshCardPacks(instant)
    return
  elseif self.currencyType == game.CurrencyType_MinigameTokens then
    self:refreshMinigameTokens(instant)
    return
  end
  if newAmount ~= self.targetAmount then
    self.targetAmount = newAmount
    self.rate = 0
  end
  if instant then
    self:setAmount(self.targetAmount, true)
  end
end
function CurrencyCounter:refreshCardPacks(instant)
  newAmount = 0
  local playerCardAlbum = game.player():currentlyActiveCardAlbum()
  if playerCardAlbum ~= nil then
    newAmount = playerCardAlbum:getUncollectedCardPacks():size()
  end
  if newAmount ~= self.targetAmount then
    self.targetAmount = newAmount
    self.rate = 0
  end
  if instant then
    self:setAmount(self.targetAmount, true)
  end
end
function CurrencyCounter:refreshMinigameTokens(instant)
  newAmount = game.playerMinigameTokens()
  local minigameContext = game.minigameContext()
  if minigameContext then
    local playerMinigame = minigameContext:getCurrentPlayerMinigame()
    if playerMinigame then
      newAmount = playerMinigame:availableTokens()
    end
  end
  if newAmount ~= self.targetAmount then
    self.targetAmount = newAmount
    self.rate = 0
  end
  if instant then
    self:setAmount(self.targetAmount, true)
  end
end
function CurrencyCounter:setAmount(amount, scale)
  self.currentAmount = amount
  if scale then
    self.Text("size"):SetFloat(0.3 * game.hudScale())
  end
  self.Text("text"):SetString(game.commaizeNumber(math.floor(self.currentAmount)))
  self.Text("autoScale"):SetInt(1)
  if amount == 0 and self.autoHide then
    self:Hide()
  else
    self:Show()
  end
end
function CurrencyCounter:setAlpha(value)
  if self.alpha ~= value then
    self.alpha = value
    self.BackingSprite("alpha"):SetFloat(value)
    self.Icon("alpha"):SetFloat(value)
    self.Plus("alpha"):SetFloat(value)
    self.Text("alpha"):SetFloat(value)
  end
end
function CurrencyCounter:setLayer(layer)
  self.BackingSprite("layer"):SetString(layer)
  self.Icon("layer"):SetString(layer)
  self.Plus("layer"):SetString(layer)
  self.Text("layer"):SetString(layer)
end
function CurrencyCounter:atTargetValue()
  return self.currentAmount == self.targetAmount
end
function CurrencyCounter.Touch:onTouchDown(element)
  if game.popUpLevel() <= 1 then
    local currencyCounter = self:parent()
    currencyCounter.Plus:setColor(0.5, 0.5, 0.5)
  end
end
function CurrencyCounter.Touch:onTouchUp(element)
  if game.popUpLevel() <= 1 then
    local currencyCounter = self:parent()
    currencyCounter.Plus:setColor(1, 1, 1)
    playSoundFx("audio/sfx/menu_click_small.wav")
    if currencyCounter.onClick then
      currencyCounter:onClick()
    end
  end
end
function CurrencyCounter.Touch:onTouchRelease(element)
  if game.popUpLevel() <= 1 then
    local currencyCounter = self:parent()
    currencyCounter.Plus:setColor(1, 1, 1)
  end
end
function CurrencyCounter:Hide()
  self:setAlpha(0)
end
function CurrencyCounter:Show()
  self:setAlpha(1)
end
function CurrencyCounter:gotMsgPlayerUpdated(msg)
  self:refreshCurrencyAmount(false)
end
function CurrencyCounter:gotMsgFlyingIconLanded(msg)
  local currencyType = game.Currencies_LootTypeToCurrencyType(msg.type)
  if currencyType == self.currencyType then
    self:refreshCurrencyAmount(false)
  end
end
function CurrencyCounter:gotMsgCardPackOpened(msg)
  self:refreshCardPacks(false)
end
function CurrencyCounter:gotMsgMinigameRefreshTokens(msg)
  self:refreshMinigameTokens(false)
end
function CurrencyCounter:gotMsgMinigameRefreshState(msg)
  self:refreshMinigameTokens(true)
end
return CurrencyCounter
