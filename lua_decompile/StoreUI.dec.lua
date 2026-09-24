local ElementFader = include("ElementFader")
local CostumesHelper = include("CostumesHelper")
local StoreUI = {}
function StoreUI.onInit(element)
  element.StoreItems:DoStoredScript("populate")
end
function StoreUI.onPostInit(element)
  element:DoStoredScript("disableCurrencyFiltering")
  element:DoStoredScript("disableDecorationFiltering")
  element:DoStoredScript("disableStarpowerFiltering")
  element:DoStoredScript("disableIslandFiltering")
  element:DoStoredScript("disableMonsterFiltering")
  element:DoStoredScript("disableCostumeFiltering")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgStoreCategoryChanged", "gotMsgStoreCategoryChanged")
  element:DoStoredScript("hideScrollBar")
  element:E("CurrencyCountersTop"):Hide()
  element:E("CurrencyCountersMiddle"):Hide()
  element:E("CurrencyCountersBottom"):Hide()
end
function StoreUI.gotMsgStoreCategoryChanged(element)
  element:DoStoredScript("disableCurrencyFiltering")
  element:DoStoredScript("disableDecorationFiltering")
  element:DoStoredScript("disableStarpowerFiltering")
  element:DoStoredScript("disableIslandFiltering")
  element:DoStoredScript("disableMonsterFiltering")
  element:DoStoredScript("disableCostumeFiltering")
  element:E("CurrencyCountersTop"):Show()
  element:E("CurrencyCountersMiddle"):Show()
  element:E("CurrencyCountersBottom"):Show()
  if store:getSelected() == nil then
    if store:Category() == game.StoreCategories_TYPE_CURRENCY then
      element:DoStoredScript("enableCurrencyFiltering")
    elseif store:Category() == game.StoreCategories_TYPE_DECORATION then
      element:DoStoredScript("enableDecorationFiltering")
    elseif store:Category() == game.StoreCategories_TYPE_STARPOWER then
      element:DoStoredScript("enableStarpowerFiltering")
    elseif store:Category() == game.StoreCategories_TYPE_ISLAND then
      element:DoStoredScript("enableIslandFiltering")
    elseif store:Category() == game.StoreCategories_TYPE_MONSTER then
      element:DoStoredScript("enableMonsterFiltering")
    elseif store:Category() == game.StoreCategories_TYPE_COSTUMES then
      element:DoStoredScript("enableCostumeFiltering")
    elseif store:Category() == game.StoreCategories_TYPE_NONE then
      element:E("CurrencyCountersTop"):Hide()
      element:E("CurrencyCountersMiddle"):Hide()
      element:E("CurrencyCountersBottom"):Hide()
    end
  end
end
function StoreUI.enableCurrencyFiltering(element)
  element.CoinsFilter:DoStoredScript("setVisible")
  element.DiamondFilter:DoStoredScript("setVisible")
  element.FoodFilter:DoStoredScript("setVisible")
  element.MinigameTokensFilter:DoStoredScript("setVisible")
  element.KeysFilter:DoStoredScript("setVisible")
  element.CurrencyExchangeFilter:DoStoredScript("setVisible")
  if store:getFilter() == game.StoreContext_TYPE_COINS then
    element.CoinsFilter:DoStoredScript("select")
  end
  if store:getFilter() == game.StoreContext_TYPE_DIAMOND then
    element.DiamondFilter:DoStoredScript("select")
  end
  if store:getFilter() == game.StoreContext_TYPE_FOOD then
    element.FoodFilter:DoStoredScript("select")
  end
  if store:getFilter() == game.StoreContext_TYPE_MINIGAME_TICKETS then
    element.MinigameTokensFilter:DoStoredScript("select")
  end
  if store:getFilter() == game.StoreContext_TYPE_KEYS then
    element.KeysFilter:DoStoredScript("select")
  end
  if store:getFilter() == game.StoreContext_TYPE_CURRENCY_EXCHANGE then
    element.CurrencyExchangeFilter:DoStoredScript("select")
  end
end
function StoreUI.disableCurrencyFiltering(element)
  element.CoinsFilter:DoStoredScript("setInvisible")
  element.DiamondFilter:DoStoredScript("setInvisible")
  element.FoodFilter:DoStoredScript("setInvisible")
  element.MinigameTokensFilter:DoStoredScript("setInvisible")
  element.KeysFilter:DoStoredScript("setInvisible")
  element.CurrencyExchangeFilter:DoStoredScript("setInvisible")
end
function StoreUI.enableDecorationFiltering(element)
  if not game.isBattleIsland() then
    element.TreeFilter:DoStoredScript("setVisible")
    element.StatueFilter:DoStoredScript("setVisible")
    element.MusicalFilter:DoStoredScript("setVisible")
    element.TileFilter:DoStoredScript("setVisible")
    element.RelicFilter:DoStoredScript("setVisible")
    element.ObstacleFilter:DoStoredScript("setVisible")
    element.SpecialFilter:DoStoredScript("setVisible")
  end
end
function StoreUI.disableDecorationFiltering(element)
  element.TreeFilter:DoStoredScript("setInvisible")
  element.StatueFilter:DoStoredScript("setInvisible")
  element.MusicalFilter:DoStoredScript("setInvisible")
  element.TileFilter:DoStoredScript("setInvisible")
  element.RelicFilter:DoStoredScript("setInvisible")
  element.ObstacleFilter:DoStoredScript("setInvisible")
  element.SpecialFilter:DoStoredScript("setInvisible")
end
function StoreUI.enableStarpowerFiltering(element)
  element.MonsterFilter:DoStoredScript("setVisible")
  element.DecorationFilter:DoStoredScript("setVisible")
end
function StoreUI.disableStarpowerFiltering(element)
  element.DecorationFilter:DoStoredScript("setInvisible")
  element.MonsterFilter:DoStoredScript("setInvisible")
end
function StoreUI.enableIslandFiltering(element)
end
function StoreUI.disableIslandFiltering(element)
end
function StoreUI.enableMonsterFiltering(element)
  element.MonsterSingleGeneFilter:DoStoredScript("setVisible")
  element.MonsterDoubleGeneFilter:DoStoredScript("setVisible")
  element.MonsterTripleGeneFilter:DoStoredScript("setVisible")
  element.MonsterQuadGeneFilter:DoStoredScript("setVisible")
  element.MonsterFiveGeneFilter:DoStoredScript("setVisible")
  element.MonsterSpecialGeneFilter:DoStoredScript("setVisible")
end
function StoreUI.disableMonsterFiltering(element)
  element.MonsterSingleGeneFilter:DoStoredScript("setInvisible")
  element.MonsterDoubleGeneFilter:DoStoredScript("setInvisible")
  element.MonsterTripleGeneFilter:DoStoredScript("setInvisible")
  element.MonsterQuadGeneFilter:DoStoredScript("setInvisible")
  element.MonsterFiveGeneFilter:DoStoredScript("setInvisible")
  element.MonsterSpecialGeneFilter:DoStoredScript("setInvisible")
end
function StoreUI.onMonsterFilterSelected(element, buttonElement, filterName)
  if store:getFilter() == filterName then
    store:setFilter("")
    buttonElement:DoStoredScript("deselect")
  else
    store:setFilter(filterName)
    element:deselectAllMonsters()
    buttonElement:DoStoredScript("select")
  end
end
function StoreUI.enableCostumeFiltering(element)
  element.CostumeBattleFilter:DoStoredScript("setVisible")
  element.CostumeSeasonalFilter:DoStoredScript("setVisible")
end
function StoreUI.disableCostumeFiltering(element)
  element.CostumeBattleFilter:DoStoredScript("setInvisible")
  element.CostumeSeasonalFilter:DoStoredScript("setInvisible")
end
function StoreUI.deselectAllCurrency(element)
  element.CoinsFilter:DoStoredScript("deselect")
  element.DiamondFilter:DoStoredScript("deselect")
  element.FoodFilter:DoStoredScript("deselect")
  element.MinigameTokensFilter:DoStoredScript("deselect")
  element.KeysFilter:DoStoredScript("deselect")
  element.CurrencyExchangeFilter:DoStoredScript("deselect")
end
function StoreUI.deselectAllDecorations(element)
  element.TreeFilter:DoStoredScript("deselect")
  element.StatueFilter:DoStoredScript("deselect")
  element.MusicalFilter:DoStoredScript("deselect")
  element.TileFilter:DoStoredScript("deselect")
  element.RelicFilter:DoStoredScript("deselect")
  element.ObstacleFilter:DoStoredScript("deselect")
  element.SpecialFilter:DoStoredScript("deselect")
  element.DecorationFilter:DoStoredScript("deselect")
  element.MonsterFilter:DoStoredScript("deselect")
end
function StoreUI.deselectAllMonsters(element)
  element.MonsterSingleGeneFilter:DoStoredScript("deselect")
  element.MonsterDoubleGeneFilter:DoStoredScript("deselect")
  element.MonsterTripleGeneFilter:DoStoredScript("deselect")
  element.MonsterQuadGeneFilter:DoStoredScript("deselect")
  element.MonsterFiveGeneFilter:DoStoredScript("deselect")
  element.MonsterSpecialGeneFilter:DoStoredScript("deselect")
end
function StoreUI.deselectAllCostumes(element)
  print("deselect all costumes")
  element.CostumeBattleFilter:DoStoredScript("deselect")
  element.CostumeSeasonalFilter:DoStoredScript("deselect")
end
function StoreUI.disableBackButtons(element)
  element.QuitButton:DoStoredScript("disable")
  element.BackButton:DoStoredScript("disable")
end
function StoreUI.disableBackButtonOnly(element)
  element.BackButton:DoStoredScript("disable")
end
function StoreUI.hideScrollBar(element)
  element.ScrollBar.Sprite("visible"):SetInt(0)
  element.ScrollMarker.Marker("visible"):SetInt(0)
end
function StoreUI.showScrollBar(element)
  element.ScrollBar.Sprite("visible"):SetInt(1)
  element.ScrollMarker.Marker("visible"):SetInt(1)
end
function StoreUI:fadeInStoreItem(storeItem, index)
  if index == nil then
    index = 0
  end
  local faderOptions = {
    onUpdateComponent = function(component)
      if component.colorChange then
        component:colorChange()
      end
    end,
    duration = 0.2
  }
  local fader = ElementFader.New(storeItem, faderOptions)
  function storeItem.onTick(e, dt)
    fader:tick(dt)
  end
  storeItem:setHasOnTick(true)
  local oldShowItem = storeItem.showItem
  function storeItem.showItem(e)
    oldShowItem(e)
    fader.delayOnShow = 0
    fader:Show()
  end
  local oldHideItem = storeItem.hideItem
  function storeItem.hideItem(e)
    oldHideItem(e)
    fader:Hide(true)
  end
  fader:Show()
end
function StoreUI:populateItemsAsCO(element)
  return coroutine.create(function()
    local previous
    local numItems = store:NumCategoryItems()
    local lockedIndex = numItems - store:NumLockedItems()
    if store:Category() == game.StoreCategories_TYPE_CURRENCY and game.hasAds() and not game.premiumPlayer() then
      element:parent().RemoveAdsText.Text("alignment"):SetInt(lua_sys.MenuTextComponent_TEXT_HCENTER_ALIGNED)
      element:parent().RemoveAdsText.Text("visible"):SetInt(1)
    else
      element:parent().RemoveAdsText.Text("visible"):SetInt(0)
    end
    local lastFilterType = ""
    element("numItems"):SetInt(numItems)
    local currentTime = game.getCurrentTimeMillis()
    local showingLoadBar = false
    for i = 0, numItems - 1 do
      local storeItem
      if store:Category() == game.StoreCategories_TYPE_CURRENCY then
        storeItem = menu:addTemplateElement("template_storecurrencyitem", "storeItem" .. i, element)
      elseif store:Category() == game.StoreCategories_TYPE_CROSSPROMO then
        local template = store:CustomTemplate(i)
        if template == "" then
          template = "template_storecrosspitem"
        end
        storeItem = menu:addTemplateElement(template, "storeItem" .. i, element)
      else
        storeItem = menu:addTemplateElement("template_storeitem", "storeItem" .. i, element)
      end
      local cost
      local type = ""
      local name, group, premium
      if store:Category() == game.StoreCategories_TYPE_ISLAND and store:isIslandOwnedByIndex(i) then
        cost = "OWNED"
        type = "none"
      elseif store:Category() == game.StoreCategories_TYPE_COSTUMES then
        cost = game.localizeInt(CostumesHelper.GetItemCost(store:ItemId(i)))
        type = CostumesHelper.GetPurchaseType(store:ItemId(i))
      else
        cost = game.localizeInt(store:ItemCost(i))
        type = store:PurchaseTypeOfItem(i)
      end
      if store:Category() == game.StoreCategories_TYPE_CURRENCY then
        name = store:ItemName(i)
        group = store:ItemGroup(i)
      else
        name = ""
        group = ""
      end
      if store:IsItemPremium(i) then
        premium = 1
      else
        premium = 0
      end
      storeItem("ItemId"):SetInt(store:ItemId(i))
      local hasFreeItem = false
      if store:Category() == game.StoreCategories_TYPE_MONSTER or store:Category() == game.StoreCategories_TYPE_STRUCTURE or store:Category() == game.StoreCategories_TYPE_DECORATION or store:Category() == game.StoreCategories_TYPE_STARPOWER then
        hasFreeItem = 0 < game.getInventoryAmount(store:EntityIdFromItemNum(i))
      end
      local saleDesc = store:SaleDesc(i)
      if not hasFreeItem or not 0 then
      end
      storeItem("SaleAmount"):SetInt((store:SaleAmount(i)))
      storeItem("BoxMonster"):SetInt(store:IsBoxMonster(i))
      if storeItem("SaleAmount"):GetInt() ~= 0 and saleDesc == "" then
        saleDesc = "Bob"
      end
      local isPromoItem = store:IsPromoItem(i) ~= 0
      local isQuadMultiPack = store:isQuadMultiPack(i)
      storeItem("SpriteName"):SetString("portrait_frame")
      storeItem("SheetName"):SetString("xml_resources/hud01.xml")
      storeItem("ItemTitle"):SetString(store:ItemTitle(i))
      storeItem("Action"):SetString(store:ItemAction(i))
      storeItem("Cost"):SetString(cost)
      storeItem("Type"):SetString(type)
      storeItem("Filter"):SetString(type)
      storeItem("AnimationFile"):SetString(store:AnimationFile(i))
      storeItem("AnimationName"):SetString(store:AnimationName(i))
      storeItem("RequiresLevel"):SetInt(store:RequiresLevel(i))
      storeItem("RequiresBattleLevel"):SetInt(store:RequiresBattleLevel(i))
      storeItem("RequiresIsland"):SetInt(store:RequiresIsland(i))
      storeItem("SaleDesc"):SetString(hasFreeItem and "" or saleDesc)
      storeItem("Premium"):SetInt(premium)
      storeItem("ID"):SetInt(i)
      storeItem("CurrencyType"):SetString(store:PurchaseTypeOfItem(i))
      storeItem("CurrencyGained"):SetString(game.localizeInt(store:CurrencyGained(i)))
      if isQuadMultiPack then
        storeItem("ItemPriceAsStr"):SetString(LOC("MULTIPACK_CTA"))
      else
        storeItem("ItemPriceAsStr"):SetString(store:ItemPriceAsStr(i))
      end
      if not hasFreeItem or not "" then
      end
      storeItem("SaleItemPriceAsStr"):SetString((store:SaleItemPriceAsStr(i)))
      storeItem("ItemName"):SetString(name)
      storeItem("ItemGroup"):SetString(group)
      if not hasFreeItem or not 0 then
      end
      storeItem("TimedSaleOn"):SetInt((store:IsTimedSale(i)))
      if not hasFreeItem or not 0 then
      end
      storeItem("TimedAvailabilityOn"):SetInt((store:IsTimedAvailability(i)))
      if not hasFreeItem or not 0 then
      end
      storeItem("TimedUnavailabilityOn"):SetInt((store:IsTimedUnavailability(i)))
      storeItem("1LeftIAP"):SetInt(store:CurrencyItemHas1LeftIAP(i))
      storeItem("IsPromoItem"):SetInt(isPromoItem and 1 or 0)
      storeItem("isQuadMultiPack"):SetInt(isQuadMultiPack and 1 or 0)
      storeItem("IsBestValue"):SetInt(store:IsBestValue(i))
      storeItem("IsMostPopular"):SetInt(store:IsMostPopular(i))
      if store:Category() == game.StoreCategories_TYPE_COSTUMES then
        storeItem("Costume"):SetInt(store:ItemId(i))
      else
        storeItem("Costume"):SetInt(0)
      end
      storeItem:relativeTo(element)
      storeItem:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.VCENTER)
      if previous ~= nil then
        storeItem:setOrientation(lua_sys.MenuOrientation(previous("xOffset"):GetFloat() + previous:absW() + store:panelXOffset(), 0, game.StoreContext_DESELECTED_ITEM_PRIORITY, lua_sys.LEFT, lua_sys.VCENTER))
      else
        storeItem:setOrientation(lua_sys.MenuOrientation(store:panelStartXOffset(), 0, game.StoreContext_DESELECTED_ITEM_PRIORITY, lua_sys.LEFT, lua_sys.VCENTER))
      end
      if store:Category() == game.StoreCategories_TYPE_CURRENCY and type ~= lastFilterType then
        store:setFilterPosition(type, storeItem("xOffset"):GetFloat())
        lastFilterType = type
      end
      if storeItem.AnyCost ~= nil then
        storeItem.AnyCost.Text:init()
      end
      storeItem:init()
      storeItem:setPositionBroadcast(true)
      storeItem:postInit()
      previous = storeItem
      if i >= lockedIndex then
        storeItem:DoStoredScript("setLocked")
      end
      if i == numItems - 1 then
        element("width"):SetFloat(storeItem:absX() + storeItem:absW())
      end
      local loadTime = game.getCurrentTimeMillis() - currentTime
      if not showingLoadBar and loadTime >= 500 then
        local timePerItem = loadTime / (i + 1)
        local timeRemaining = (numItems - i) * timePerItem
        if timeRemaining > 500 then
          showingLoadBar = true
          self.LoadingBar:setVisible(true, true)
          self.LoadingBar:updateLoader(i * 1 / numItems)
          coroutine.yield()
        end
        currentTime = game.getCurrentTimeMillis()
      elseif showingLoadBar and loadTime >= 50 then
        self.LoadingBar:updateLoader(i * 1 / numItems)
        coroutine.yield()
        currentTime = game.getCurrentTimeMillis()
      end
    end
    local realNumItems = numItems
    if store:Category() == game.StoreCategories_TYPE_MONSTER and store:hasBuyback() == true then
      local storeItem = menu:addTemplateElement("template_buybackitem", "buyback", element)
      storeItem:relativeTo(element)
      storeItem:setOrientation(lua_sys.MenuOrientation(previous("xOffset"):GetFloat() + previous:absW() + store:panelXOffset(), 0, game.StoreContext_DESELECTED_ITEM_PRIORITY, lua_sys.LEFT, lua_sys.VCENTER))
      storeItem:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.VCENTER)
      storeItem:init()
      storeItem:setPositionBroadcast(true)
      storeItem:postInit()
      previous = storeItem
      realNumItems = realNumItems + 1
      self:fadeInStoreItem(storeItem, realNumItems)
    end
    if store:Category() == game.StoreCategories_TYPE_CURRENCY then
      local function initStoreItem(item, title, cost, type, filter, animName, currencyType, currencyGained, name)
        item:V("SpriteName"):SetString("portrait_frame")
        item:V("SheetName"):SetString("xml_resources/hud01.xml")
        item:V("ItemTitle"):SetString(title)
        item:V("Cost"):SetString(cost)
        item:V("Type"):SetString(type)
        item:V("Filter"):SetString(filter)
        item:V("AnimationFile"):SetString("currency.bin")
        item:V("AnimationName"):SetString(animName)
        item:V("RequiresLevel"):SetInt(0)
        item:V("RequiresBattleLevel"):SetInt(0)
        item:V("RequiresIsland"):SetInt(-1)
        item:V("SaleDesc"):SetString("")
        item:V("Premium"):SetInt(0)
        item:V("ID"):SetInt(-1)
        item:V("CurrencyType"):SetString(currencyType)
        item:V("CurrencyGained"):SetString(currencyGained)
        item:V("ItemPriceAsStr"):SetString("0")
        item:V("SaleItemPriceAsStr"):SetString("0")
        item:V("ItemName"):SetString(name)
        item:V("ItemGroup"):SetString("")
        item:V("TimedSaleOn"):SetInt(0)
        item:V("TimedAvailabilityOn"):SetInt(0)
        item:V("TimedUnavailabilityOn"):SetInt(0)
        item:V("1LeftIAP"):SetInt(0)
        item:V("IsPromoItem"):SetInt(0)
        item:V("IsBestValue"):SetInt(0)
        item:V("IsMostPopular"):SetInt(0)
        item:relativeTo(element)
        if previous ~= nil then
          item:setOrientation(lua_sys.MenuOrientation(previous:V("xOffset"):GetFloat() + previous:absW() + store:panelXOffset(), 0, 18, lua_sys.LEFT, lua_sys.VCENTER))
        else
          item:setOrientation(lua_sys.MenuOrientation(store:panelStartXOffset(), 0, 18, lua_sys.LEFT, lua_sys.VCENTER))
        end
        item.AnyCost.Text:init()
        item:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.VCENTER)
        item:init()
        item:setPositionBroadcast(true)
        item:postInit()
        if filter ~= lastFilterType then
          store:setFilterPosition(filter, item:V("xOffset"):GetFloat())
          lastFilterType = filter
        end
        previous = item
      end
      local storeItem = menu:addTemplateElement("template_storecurrencyitem", "currencyExchange", element)
      initStoreItem(storeItem, "CURRENCY_EXCHANGE", store:currencyExchangeDiamonds(), game.StoreContext_TYPE_DIAMOND, "currency_exchange", "currency_swap", game.StoreContext_TYPE_COINS, game.localizeInt(store:currencyExchangeCoins()), "currencyExchange")
      realNumItems = realNumItems + 1
      storeItem = menu:addTemplateElement("template_storecurrencyitem", "diamondsToRelicsCurrencyExchange", element)
      initStoreItem(storeItem, "DIAMONDS_TO_RELICS", store:curRelicDiamondCost(), game.StoreContext_TYPE_DIAMOND, "currency_exchange", "diamonds_to_relics", game.StoreContext_TYPE_RELICS, 1, "diamondsToRelicsCurrencyExchange")
      realNumItems = realNumItems + 1
      if 0 < store:numRelicsBoughtToday() then
        storeItem.ExchangeRateResetText("relicExchangeItem"):SetInt(1)
        storeItem.ExchangeRateResetText.TitleText("visible"):SetInt(1)
        storeItem.ExchangeRateResetText.TimerText("visible"):SetInt(1)
      end
      if game.isEtherealIsland() or game.onTribalIsland() then
        storeItem = menu:addTemplateElement("template_storecurrencyitem", "coinsToEthCurrencyExchange", element)
        initStoreItem(storeItem, "COINS_TO_ETH", store:currencyCoinEthExchangeCoins(), game.StoreContext_TYPE_COINS, "currency_exchange", "coins_to_shards", game.StoreContext_TYPE_ETH_CURRENCY, game.localizeInt(store:currencyCoinEthExchangeEth()), "coinsToEthCurrencyExchange")
        realNumItems = realNumItems + 1
        storeItem = menu:addTemplateElement("template_storecurrencyitem", "diamondsToEthCurrencyExchange", element)
        initStoreItem(storeItem, "DIAMONDS_TO_ETH", store:currencyDiamondEthExchangeDiamonds(), game.StoreContext_TYPE_DIAMOND, "currency_exchange", "diamonds_to_shards", game.StoreContext_TYPE_ETH_CURRENCY, game.localizeInt(store:currencyDiamondEthExchangeEth()), "diamondsToEthCurrencyExchange")
        realNumItems = realNumItems + 1
        element("width"):SetFloat(storeItem:absX() + storeItem:absW())
      end
    end
    local yOffset = 0
    if previous ~= nil then
      local contextBarHeight = self:E("QuitButton"):absH() + 10 * game.windowScaleMin() + lua_sys.deviceMarginY()
      local availableSpace = lua_sys.screenHeight() - contextBarHeight - contextBarHeight
      local storeItemHeight = previous:absH()
      local diff = availableSpace - storeItemHeight
      if diff < 0 then
        yOffset = diff / 2
      end
    end
    element("numItems"):SetInt(numItems)
    element("xOffset"):SetInt(0)
    element("yOffset"):SetInt(yOffset)
    element:setPositionBroadcast(true)
    element("realNumItems"):SetInt(realNumItems)
    element:updateScrollSize()
    store:finishItems()
    if showingLoadBar then
      self.LoadingBar:setVisible(false, true)
    end
  end)
end
function StoreUI:populate(storeItemsElement)
  self.populateCO = self:populateItemsAsCO(storeItemsElement)
  local result, errorMessage = coroutine.resume(self.populateCO)
  if errorMessage then
    error(errorMessage)
  end
  if not result then
    self.populateCO = nil
  end
end
function StoreUI:stopPopulate(fade)
  self.LoadingBar:setVisible(false, fade)
  self.populateCO = nil
end
function StoreUI:onDestroy()
  self:stopPopulate()
end
function StoreUI:onTick(dt)
  local co = self.populateCO
  if self.populateCO ~= nil and not coroutine.resume(co) then
    self.populateCO = nil
  end
end
return StoreUI
