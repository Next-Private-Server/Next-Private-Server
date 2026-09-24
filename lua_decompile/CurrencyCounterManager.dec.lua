local CurrencyCounterManager = {}
local PADDING = 1 * game.hudScale()
local FADE_OUT_DELAY = 1
local FADE_OUT_TIME = 0.5
local FADE_IN_TIME = 0.25
CurrencyCounterManager.VIEW_STATE = {
  NONE = 0,
  ALERT = 1,
  ALWAYS = 2,
  ALWAYS_NO_BUY_MORE = 3
}
local UPDATE_STATE = {
  NONE = 0,
  WAITING_FOR_ICON = 1,
  ACTIVE = 2
}
CurrencyCounterManager.CurrencyCounterOptions = {
  Sorting = 1,
  ViewState = CurrencyCounterManager.VIEW_STATE.NONE,
  FlyingIconMode = false,
  AutoHide = false
}
function CurrencyCounterManager:onInit()
  self.currencyOptions = {}
  self.currencyOptions[game.CurrencyType_Food] = {Sorting = 1}
  self.currencyOptions[game.CurrencyType_Diamonds] = {Sorting = 2}
  self.currencyOptions[game.CurrencyType_Coins] = {Sorting = 3}
  self.currencyOptions[game.CurrencyType_Shards] = {Sorting = 4}
  self.currencyOptions[game.CurrencyType_Starpower] = {Sorting = 5}
  self.currencyOptions[game.CurrencyType_EggWildcards] = {Sorting = 6}
  self.currencyOptions[game.CurrencyType_Relics] = {Sorting = 7}
  self.currencyOptions[game.CurrencyType_ClubboxTokens] = {Sorting = 8}
  self.currencyOptions[game.CurrencyType_MinigameTokens] = {Sorting = 9}
  self.currencyOptions[game.CurrencyType_CardPack] = {Sorting = 10}
  self.currencyOptions[game.CurrencyType_Keys] = {Sorting = 11}
  self.currencyOptions[game.CurrencyType_Medals] = {Sorting = 12}
  self.currentAmounts = {}
  self:refreshCurrencyAmounts(self.currentAmounts)
  self.targetAmounts = {}
  self:refreshCurrencyAmounts(self.targetAmounts)
  self.currencyCounterId = 0
  self.currencyCounters = {}
  self.updateStates = {}
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlayerUpdated", "gotMsgPlayerUpdated")
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgFlyingIconLanded", "gotMsgFlyingIconLanded")
end
function CurrencyCounterManager:onPostInit()
  keys = {}
  for key, _ in pairs(self.currencyOptions) do
    table.insert(keys, key)
  end
  table.sort(keys, function(a, b)
    return self.currencyOptions[a].Sorting < self.currencyOptions[b].Sorting
  end)
  local playerLevel = game.playerLevel()
  if playerLevel < 10 then
    self.currencyOptions[game.CurrencyType_Keys].ViewState = CurrencyCounterManager.VIEW_STATE.NONE
    self.currencyOptions[game.CurrencyType_Medals].ViewState = CurrencyCounterManager.VIEW_STATE.NONE
    if playerLevel < 8 then
      self.currencyOptions[game.CurrencyType_ClubboxTokens].ViewState = CurrencyCounterManager.VIEW_STATE.NONE
      self.currencyOptions[game.CurrencyType_MinigameTokens].ViewState = CurrencyCounterManager.VIEW_STATE.NONE
      self.currencyOptions[game.CurrencyType_CardPack].ViewState = CurrencyCounterManager.VIEW_STATE.NONE
      if playerLevel < 4 then
        self.currencyOptions[game.CurrencyType_Relics].ViewState = CurrencyCounterManager.VIEW_STATE.NONE
      end
    end
  end
  for _, key in ipairs(keys) do
    if self.currencyOptions[key].ViewState == CurrencyCounterManager.VIEW_STATE.ALWAYS or self.currencyOptions[key].ViewState == CurrencyCounterManager.VIEW_STATE.ALWAYS_NO_BUY_MORE then
      local currencyCounter = self:createCurrencyCounter(key)
      if self.currencyOptions[key].ViewState == CurrencyCounterManager.VIEW_STATE.ALWAYS then
        if key == game.CurrencyType_Coins then
          function currencyCounter.onClick(e)
            game.logEvent("enter_iap_store", "source", "COIN_HUD", "context", "HUD")
            game.loadStoreContext(game.StoreCategories_TYPE_CURRENCY, game.StoreContext_TYPE_COINS)
          end
        elseif key == game.CurrencyType_Diamonds then
          function currencyCounter.onClick(e)
            game.logEvent("enter_iap_store", "source", "DIAMOND_HUD", "context", "HUD")
            game.loadStoreContext(game.StoreCategories_TYPE_CURRENCY, game.StoreContext_TYPE_DIAMOND)
          end
        elseif key == game.CurrencyType_Food then
          function currencyCounter.onClick(e)
            game.logEvent("enter_iap_store", "source", "FOOD_HUD", "context", "HUD")
            game.loadStoreContext(game.StoreCategories_TYPE_CURRENCY, game.StoreContext_TYPE_FOOD)
          end
        elseif key == game.CurrencyType_Shards then
          function currencyCounter.onClick(e)
            game.logEvent("enter_iap_store", "source", "CURRENCY_EXCHANGE_HUD", "context", "HUD")
            game.loadStoreContext(game.StoreCategories_TYPE_CURRENCY, game.StoreContext_TYPE_CURRENCY_EXCHANGE)
          end
        elseif key == game.CurrencyType_Keys then
          function currencyCounter.onClick(e)
            game.logEvent("enter_iap_store", "source", "KEYS_HUD", "context", "HUD")
            game.loadStoreContext(game.StoreCategories_TYPE_CURRENCY, game.StoreContext_TYPE_KEYS)
          end
        elseif key == game.CurrencyType_Relics then
          function currencyCounter.onClick(e)
            game.logEvent("enter_iap_store", "source", "RELICS_HUD", "context", "HUD")
            game.loadStoreContext(game.StoreCategories_TYPE_CURRENCY, game.StoreContext_TYPE_CURRENCY_EXCHANGE)
          end
        elseif key == game.CurrencyType_ClubboxTokens then
          function currencyCounter.onClick(e)
            game.showNotEnoughCurrencyPrompt(game.PurchaseType_CLUBBOX_TOKENS_NOT_ENOUGH, 0, game.CurrencyType_ClubboxTokens, 0, "")
          end
        elseif key == game.CurrencyType_MinigameTokens then
          function currencyCounter.onClick(e)
            game.showNotEnoughCurrencyPrompt(game.PurchaseType_MINIGAME_TOKENS_NOT_ENOUGH, 0, game.CurrencyType_MinigameTokens, 0, "")
          end
        end
        if currencyCounter.onClick then
          currencyCounter.Plus("visible"):SetInt(1)
          currencyCounter.Touch("enabled"):SetInt(1)
        else
          currencyCounter.Plus("visible"):SetInt(0)
          currencyCounter.Touch("enabled"):SetInt(0)
        end
      end
    end
  end
end
function CurrencyCounterManager:onTick(dt)
  local i = 1
  local visibleIndex = 1
  while i <= #self.currencyCounters do
    local currencyCounter = self.currencyCounters[i]
    if self.currencyOptions[currencyCounter.currencyType].ViewState == CurrencyCounterManager.VIEW_STATE.ALERT then
      local alpha = currencyCounter.alpha
      if currencyCounter:atTargetValue() then
        alpha = math.max(0, currencyCounter.alpha - dt / FADE_OUT_TIME)
      else
        alpha = math.min(1.5, currencyCounter.alpha + dt / FADE_IN_TIME)
      end
      currencyCounter:setAlpha(alpha)
      if currencyCounter.alpha == 0 then
        table.remove(self.currencyCounters, i)
        self:RemoveElement(currencyCounter)
      else
        local targetPosX = (visibleIndex - 2 + math.min(1, alpha)) * (PADDING + currencyCounter:absW())
        local currentPosX = currencyCounter:GetVar("xOffset"):GetFloat()
        if targetPosX ~= currentPosX then
          local diff = currentPosX - targetPosX
          if math.abs(diff) > 20 then
            diff = diff * 0.333
          end
          currencyCounter:GetVar("xOffset"):SetFloat(currentPosX - diff)
        end
        i = i + 1
        if currencyCounter.alpha > 0.3 then
          visibleIndex = visibleIndex + 1
        end
      end
    else
      i = i + 1
      visibleIndex = visibleIndex + 1
    end
  end
end
function CurrencyCounterManager:gotMsgPlayerUpdated(msg)
  self:refreshCurrencyAmounts(self.targetAmounts)
  self:checkForDifferences()
end
function CurrencyCounterManager:gotMsgFlyingIconLanded(msg)
  local currencyType = game.Currencies_LootTypeToCurrencyType(msg.type)
  if currencyType ~= game.currencyType_MAX_NUM_CURRENCIES and self.currencyOptions[currencyType] ~= nil and self.currencyOptions[currencyType].ViewState == CurrencyCounterManager.VIEW_STATE.ALERT and self.updateStates[currencyType] == UPDATE_STATE.WAITING_FOR_ICON then
    self.updateStates[currencyType] = UPDATE_STATE.ACTIVE
    self:showCurrencyCounterAlert(currencyType)
  end
end
function CurrencyCounterManager:refreshCurrencyAmounts(amounts)
  if self.currencyOptions[game.CurrencyType_Coins] ~= CurrencyCounterManager.VIEW_STATE.NONE then
    amounts[game.CurrencyType_Coins] = game.playerCoins()
  end
  if self.currencyOptions[game.CurrencyType_Diamonds] ~= CurrencyCounterManager.VIEW_STATE.NONE then
    amounts[game.CurrencyType_Diamonds] = game.playerDiamonds()
  end
  if self.currencyOptions[game.CurrencyType_Food] ~= CurrencyCounterManager.VIEW_STATE.NONE then
    amounts[game.CurrencyType_Food] = game.playerFood()
  end
  if self.currencyOptions[game.CurrencyType_Shards] ~= CurrencyCounterManager.VIEW_STATE.NONE then
    amounts[game.CurrencyType_Shards] = game.playerEtherealCurrency()
  end
  if self.currencyOptions[game.CurrencyType_Starpower] ~= CurrencyCounterManager.VIEW_STATE.NONE then
    amounts[game.CurrencyType_Starpower] = game.playerStarpower()
  end
  if self.currencyOptions[game.CurrencyType_Keys] ~= CurrencyCounterManager.VIEW_STATE.NONE then
    amounts[game.CurrencyType_Keys] = game.playerKeys()
  end
  if self.currencyOptions[game.CurrencyType_Relics] ~= CurrencyCounterManager.VIEW_STATE.NONE then
    amounts[game.CurrencyType_Relics] = game.playerRelics()
  end
  if self.currencyOptions[game.CurrencyType_Medals] ~= CurrencyCounterManager.VIEW_STATE.NONE then
    amounts[game.CurrencyType_Medals] = game.playerMedals()
  end
  if self.currencyOptions[game.CurrencyType_EggWildcards] ~= CurrencyCounterManager.VIEW_STATE.NONE then
    amounts[game.CurrencyType_EggWildcards] = game.playerEggWildcards()
  end
  if self.currencyOptions[game.CurrencyType_ClubboxTokens] ~= CurrencyCounterManager.VIEW_STATE.NONE then
    amounts[game.CurrencyType_ClubboxTokens] = game.playerClubboxTokens()
  end
  if self.currencyOptions[game.CurrencyType_CardPack] ~= CurrencyCounterManager.VIEW_STATE.NONE then
    amounts[game.CurrencyType_CardPack] = game.playerClubboxTokens()
    local playerCardAlbum = game.player():currentlyActiveCardAlbum()
    if playerCardAlbum ~= nil then
      amounts[game.CurrencyType_CardPack] = playerCardAlbum:getUncollectedCardPacks():size()
    end
  end
  if self.currencyOptions[game.CurrencyType_MinigameTokens] ~= CurrencyCounterManager.VIEW_STATE.NONE then
    amounts[game.CurrencyType_MinigameTokens] = game.playerMinigameTokens()
    local minigameContext = game.minigameContext()
    if minigameContext then
      local playerMinigame = minigameContext:getCurrentPlayerMinigame()
      if playerMinigame then
        amounts[game.CurrencyType_MinigameTokens] = playerMinigame:availableTokens()
      end
    end
  end
end
function CurrencyCounterManager:checkForDifferences()
  for key, value in pairs(self.currentAmounts) do
    if self.currencyOptions[key] ~= CurrencyCounterManager.VIEW_STATE.NONE and self.targetAmounts[key] ~= nil and self.targetAmounts[key] ~= value then
      local hasActiveCounter = false
      for _, currencyCounter in ipairs(self.currencyCounters) do
        if currencyCounter.currencyType == key and not currencyCounter:atTargetValue() then
          hasActiveCounter = true
          break
        end
      end
      if not hasActiveCounter then
        self.updateStates[key] = UPDATE_STATE.WAITING_FOR_ICON
      end
    end
  end
end
function CurrencyCounterManager:showCurrencyCounterAlert(currencyType)
  if self.currencyOptions[currencyType].ViewState == CurrencyCounterManager.VIEW_STATE.ALERT then
    local currencyCounter
    for _, existingCurrencyCounter in ipairs(self.currencyCounters) do
      if existingCurrencyCounter.currencyType == currencyType then
        currencyCounter = existingCurrencyCounter
      end
    end
    if currencyCounter == nil then
      currencyCounter = self:createCurrencyCounter(currencyType)
      currencyCounter:setAmount(self.currentAmounts[currencyType], true)
      currencyCounter:setAlpha(0)
      currencyCounter:setOrientation(lua_sys.MenuOrientation((#self.currencyCounters - 2) * (PADDING + currencyCounter:absW()), 0, 0, lua_sys.RIGHT, lua_sys.VCENTER))
      function currencyCounter.onDoneCounting(e)
        self.currentAmounts[e.currencyType] = self.targetAmounts[e.currencyType]
        e:setAlpha(1 + FADE_OUT_DELAY / FADE_OUT_TIME)
      end
    end
    currencyCounter.targetAmount = self.targetAmounts[currencyType]
    currencyCounter.rate = 0
  end
end
function CurrencyCounterManager:createCurrencyCounter(currencyType)
  local vars = {
    currencyType = currencyType,
    layer = self:templateVars().layer,
    flyingIconMode = self.currencyOptions[currencyType].FlyingIconMode and 1 or 0,
    autoHide = self.currencyOptions[currencyType].AutoHide and 1 or 0
  }
  local currencyCounter = menu:addTemplateElementEx("template_currency_counter", "currency_counter" .. self.currencyCounterId, self, vars)
  self.currencyCounterId = self.currencyCounterId + 1
  currencyCounter:relativeTo(self)
  currencyCounter:setRelativeObjectAnchors(lua_sys.RIGHT, lua_sys.VCENTER)
  currencyCounter:setOrientation(lua_sys.MenuOrientation(#self.currencyCounters * (PADDING + currencyCounter:absW()), 0, 0, lua_sys.RIGHT, lua_sys.VCENTER))
  currencyCounter:calculatePosition()
  currencyCounter:init()
  currencyCounter:setPositionBroadcast(true)
  currencyCounter:postInit()
  currencyCounter:setLayer(self:templateVars().layer)
  currencyCounter:setAmount(self.currentAmounts[currencyType], true)
  table.insert(self.currencyCounters, currencyCounter)
  return currencyCounter
end
function CurrencyCounterManager:Hide()
  for _, currencyCounter in ipairs(self.currencyCounters) do
    currencyCounter:Hide()
  end
end
function CurrencyCounterManager:Show()
  for _, currencyCounter in ipairs(self.currencyCounters) do
    currencyCounter:Show()
  end
end
return CurrencyCounterManager
