local Genes = require("Genes")
local ElementFader = require("ElementFader")
local StoreItem = {}
local c_Sprite, e_TitleFrame, e_MonsterAnim, e_NewLabel, e_CurrencyAmount, e_IAPCost, e_AnyCost, c_LevelReq, c_MaxAmount, c_MonsterCount, e_TempAvailText, e_ExchangeRateResetText, c_Touch, e_QuestSticker, e_SaleTag, numGenes, maxAmount
local initTitleFrameText = function(component, element)
  local itemTitle
  if store:Category() == game.StoreCategories_TYPE_STRUCTURE and element:parent()("ItemTitle"):GetString() == "STRUCTURE_AWAKENER" then
    local id = element:parent()("ID"):GetInt()
    local entityId = store:EntityIdFromItemNum(id)
    local structureData = game.getStructureByEntityId(entityId)
    local structureCalendar = structureData:getExtraInt("calendar")
    local calendarId = game.player():getDailyCumulativeLogin():calendar()
    if structureCalendar >= calendarId then
      itemTitle = "STRUCTURE_AWAKENER_DEACTIVATED"
      component("noTranslate"):SetInt(0)
    else
      itemTitle = element:parent()("ItemTitle"):GetString()
      component("noTranslate"):SetInt(0)
    end
  elseif store:Category() == game.StoreCategories_TYPE_DECORATION and element:parent()("ItemTitle"):GetString() == "DECORATION_TROPHY" then
    local id = element:parent()("ID"):GetInt()
    local entityId = store:EntityIdFromItemNum(id)
    local structureData = game.getStructureByEntityId(entityId)
    local campaignTitle = LOC(structureData:getExtraString("trophy"))
    itemTitle = LOC(element:parent()("ItemTitle"):GetString())
    itemTitle = itemTitle:gsub("%${CAMPAIGN}", campaignTitle)
  elseif store:TranslateItemName(element:parent()("ID"):GetInt()) then
    itemTitle = game.getLocalizedText(element:parent()("ItemTitle"):GetString())
    component("noTranslate"):SetInt(0)
  else
    itemTitle = element:parent()("ItemTitle"):GetString()
    component("noTranslate"):SetInt(1)
  end
  component("textPadding"):SetInt(3 * game.menuScaleX())
  if store:Category() == game.StoreCategories_TYPE_CURRENCY and element:parent():name() ~= "freeDiamonds" then
    component("size"):SetFloat(0.25 * game.menuScaleY())
    component("yOffset"):SetInt(-6 * game.menuScaleY())
  else
    component("size"):SetFloat(0.3 * game.menuScaleY())
  end
  component:V("originalSize"):SetFloat(component("size"):GetFloat())
  component("autoScale"):SetInt(1)
  component("autoScaleFactor"):SetFloat(0.01)
  if string.match(itemTitle, "%s") == nil or store:Category() == game.StoreCategories_TYPE_CURRENCY then
    component("multiline"):SetInt(0)
  else
    component("multiline"):SetInt(1)
  end
  component("font"):Set(game.getTextFont())
  component("alignment"):SetInt(lua_sys.MenuTextComponent_TEXT_HCENTER_ALIGNED)
  component("text"):SetString(itemTitle)
  component("layer"):SetString("HUD")
end
local initMonsterAnim = function(component, element)
  component("animationName"):SetString("xml_bin/" .. element:parent()("AnimationFile"):GetString())
  component("animation"):SetString(element:parent()("AnimationName"):GetString())
  component:setScale(lua_sys.Vector2(0.7 * game.menuScaleX(), 0.7 * game.menuScaleX()))
  component("layer"):SetString("HUD")
  if store:Category() == game.StoreCategories_TYPE_STRUCTURE and element:parent()("ItemTitle"):GetString() == "STRUCTURE_AWAKENER" then
    local id = element:parent()("ID"):GetInt()
    local entityId = store:EntityIdFromItemNum(id)
    local structureData = game.getStructureByEntityId(entityId)
    local calendarId = game.player():getDailyCumulativeLogin():calendar()
    local rewardIdx = game.player():getDailyCumulativeLogin():reward()
    component("animation"):SetString(game.Awakener_GetClosedAnim(structureData, calendarId, rewardIdx))
    component:setScale(lua_sys.Vector2(0.5 * game.menuScaleX(), 0.5 * game.menuScaleX()))
    local parentHeight = element:parent().Sprite:absH()
    component("yOffset"):SetInt(parentHeight * (0.5 / game.menuScaleX()))
  end
  if store:IsTorch(element:parent()("ID"):GetInt()) == 1 then
    component:AddRemap("gfx/structures/tiki_plant01.png", "gfx/structures/" .. store:torchGfxForThisIsland())
  end
  if element:parent():name() == "freeDiamonds" then
    component:setScale(lua_sys.Vector2(1.4 * game.menuScaleX(), 1.4 * game.menuScaleX()))
    component("yOffset"):SetInt(30)
    component("xOffset"):SetInt(-6)
  end
  local costume = element:parent()("Costume"):GetInt()
  if costume > 0 then
    game.applyCostumeToAnimComponent(component, costume)
  end
end
local initNewLabel = function(element)
  local spriteComponent = element:GetComponent("Sprite")
  local textComponent = element:GetComponent("Text")
  textComponent("visible"):SetInt(0)
  spriteComponent("visible"):SetInt(0)
  textComponent("text"):SetString("NEW")
  if element:parent()("Premium"):GetInt() == 0 and store:IsNewItem(element:parent()("ID"):GetInt()) then
    spriteComponent("visible"):SetInt(1)
    textComponent("visible"):SetInt(1)
  end
end
local initCurrencyAmount = function(element)
  if store:Category() ~= game.StoreCategories_TYPE_CURRENCY or element:parent():name() == "freeDiamonds" then
    element.Text("visible"):SetInt(0)
    element.Sprite("visible"):SetInt(0)
  end
end
local initCurrencyAmountText = function(component, element)
  component("multiline"):SetInt(0)
  component("font"):Set(game.getTextFont())
  component("size"):SetFloat(0.25 * game.menuScaleX())
  component("alignment"):SetInt(lua_sys.MenuTextComponent_TEXT_HCENTER_ALIGNED)
  component("text"):SetString(element:parent()("CurrencyGained"):GetString())
  component("autoScale"):SetInt(1)
  component("layer"):SetString("HUD")
  game.StoreContext_setCurrencyTypeColour(element:parent()("CurrencyType"):GetString(), component)
end
local initCurrencyAmountSprite = function(component, element)
  local type = element:parent()("CurrencyType"):GetString()
  local sprite = game.StoreContext_getSpriteFromCurrencyTypeStr(type)
  if store:Category() ~= game.StoreCategories_TYPE_CURRENCY and store:Category() ~= game.StoreCategories_TYPE_ISLAND and type == game.StoreContext_TYPE_COINS then
    sprite = store:coinsSpriteImgForThisIsland()
  end
  component("spriteName"):SetString(sprite)
  component("sheetName"):SetString(game.StoreContext_CURRENCY_SPRITESHEET)
  component("size"):SetFloat(0.3 * game.hudScale())
  component("layer"):SetString("HUD")
end
local initIAPCostText = function(component, element)
  component("multiline"):SetInt(0)
  component("font"):Set(game.getTextFont())
  component("size"):SetFloat(0.2 * game.menuScaleX())
  component("alignment"):SetInt(lua_sys.MenuTextComponent_TEXT_LEFT_ALIGNED)
  component("text"):SetString(element:parent()("ItemPriceAsStr"):GetString())
  component("autoScale"):SetInt(1)
  component("layer"):SetString("HUD")
  local parentName = element:parent():name()
  if store:Category() ~= game.StoreCategories_TYPE_CURRENCY or parentName == "currencyExchange" or parentName == "coinsToEthCurrencyExchange" or parentName == "diamondsToEthCurrencyExchange" or parentName == "ethToDiamondsCurrencyExchange" or parentName == "diamondsToRelicsCurrencyExchange" then
    component("visible"):SetInt(0)
  end
end
local initAnyCost = function(element)
  element("currencyType"):SetString("none")
end
local setAnyCostCurrency = function(element)
  local textComponent = element:GetComponent("Text")
  local spriteComponent = element:GetComponent("Sprite")
  textComponent("visible"):SetInt(0)
  spriteComponent("visible"):SetInt(0)
  local id = element:parent()("ID"):GetInt()
  local itemId = store:ItemId(id)
  local cost = element:parent()("Cost"):GetInt()
  if cost == 0 then
    return
  end
  if store:Category() == game.StoreCategories_TYPE_COSTUMES then
    local credits = game.getCostumeCredit(itemId)
    if credits > 0 then
      local text = LOC("COSTUME_FREE_CREDITS")
      text = text:gsub("%${CREDITS}", credits)
      textComponent("text"):SetString(text)
      textComponent("visible"):SetInt(1)
      element("xOffset"):SetInt(element("ownedTextXOffset"):GetInt())
      return
    end
  else
    local inventoryAmount = game.getInventoryAmount(store:EntityIdFromItemNum(id))
    if inventoryAmount > 0 then
      local text = LOC("COSTUME_FREE_CREDITS")
      text = text:gsub("%${CREDITS}", inventoryAmount)
      textComponent("text"):SetString(text)
      textComponent("visible"):SetInt(1)
      element("xOffset"):SetInt(element("ownedTextXOffset"):GetInt())
      return
    end
  end
  element("xOffset"):SetInt(element("currencyXOffset"):GetInt())
  local currencyType = element("currencyType"):GetString()
  textComponent("text"):SetString(element:parent()("Cost"):GetString())
  spriteComponent("spriteName"):SetString(game.StoreContext_getSpriteFromCurrencyTypeStr(currencyType))
  spriteComponent("sheetName"):SetString(game.StoreContext_CURRENCY_SPRITESHEET)
  local parentName = element:parent():name()
  if store:Category() ~= game.StoreCategories_TYPE_CURRENCY then
    game.StoreContext_setCurrencyTypeColour(currencyType, textComponent)
    if currencyType == game.StoreContext_TYPE_DIAMOND then
      textComponent("visible"):SetInt(1)
      spriteComponent("visible"):SetInt(1)
    elseif currencyType == game.StoreContext_TYPE_STARPOWER then
      textComponent("visible"):SetInt(1)
      spriteComponent("visible"):SetInt(1)
    elseif currencyType == game.StoreContext_TYPE_KEYS then
      textComponent("visible"):SetInt(1)
      spriteComponent("visible"):SetInt(1)
    elseif currencyType == game.StoreContext_TYPE_RELICS then
      textComponent("visible"):SetInt(1)
      spriteComponent("visible"):SetInt(1)
    elseif currencyType == game.StoreContext_TYPE_MEDALS then
      textComponent("visible"):SetInt(1)
      spriteComponent("visible"):SetInt(1)
    elseif currencyType == game.StoreContext_TYPE_COINS or currencyType == game.StoreContext_TYPE_ETH_CURRENCY then
      local currencyOverride = currencyType
      if store:Category() ~= game.StoreCategories_TYPE_ISLAND then
        if game.isEtherealIsland() then
          currencyOverride = game.StoreContext_TYPE_ETH_CURRENCY
        else
          currencyOverride = game.StoreContext_TYPE_COINS
        end
      end
      if currencyOverride ~= currencyType then
        game.StoreContext_setCurrencyTypeColour(currencyOverride, textComponent)
        spriteComponent("spriteName"):SetString(game.StoreContext_getSpriteFromCurrencyTypeStr(currencyOverride))
        spriteComponent("sheetName"):SetString(game.StoreContext_CURRENCY_SPRITESHEET)
      end
      textComponent("visible"):SetInt(1)
      spriteComponent("visible"):SetInt(1)
    end
  elseif parentName == "currencyExchange" or parentName == "diamondsToEthCurrencyExchange" or parentName == "diamondsToRelicsCurrencyExchange" then
    if currencyType == game.StoreContext_TYPE_DIAMOND then
      game.StoreContext_setCurrencyTypeColour(game.CurrencyType_Diamonds, textComponent)
      textComponent("visible"):SetInt(1)
      spriteComponent("visible"):SetInt(1)
    end
  elseif parentName == "ethToDiamondsCurrencyExchange" then
    if currencyType == game.StoreContext_TYPE_COINS or currencyType == game.StoreContext_TYPE_ETH_CURRENCY then
      game.StoreContext_setCurrencyTypeColour(game.CurrencyType_Shards, textComponent)
      spriteComponent("spriteName"):SetString(game.StoreContext_SPRITE_ETH_CURRENCY)
      spriteComponent("sheetName"):SetString(game.StoreContext_CURRENCY_SPRITESHEET)
      textComponent("visible"):SetInt(1)
      spriteComponent("visible"):SetInt(1)
    end
  elseif parentName == "coinsToEthCurrencyExchange" and (currencyType == game.StoreContext_TYPE_COINS or currencyType == game.StoreContext_TYPE_ETH_CURRENCY) then
    game.StoreContext_setCurrencyTypeColour(game.CurrencyType_Coins, textComponent)
    spriteComponent("spriteName"):SetString(game.StoreContext_SPRITE_COINS)
    spriteComponent("sheetName"):SetString(game.StoreContext_CURRENCY_SPRITESHEET)
    textComponent("visible"):SetInt(1)
    spriteComponent("visible"):SetInt(1)
  end
  if element:parent()("isLocked"):GetInt() == 1 then
    textComponent:setColor(textComponent("red"):GetFloat() * 0.5, textComponent("green"):GetFloat() * 0.5, textComponent("blue"):GetFloat() * 0.5)
  end
end
local initLevelReq = function(component, element)
  local txt = ""
  if store:Category() == game.StoreCategories_TYPE_COSTUMES then
    local id = element("ID"):GetInt()
    local costumeId = store:ItemId(id)
    local costumeData = game.getCostumeData(costumeId)
    if game.playerBattleLevel() < costumeData.unlockLevel then
      txt = game.getLocalizedText("NOTIFICATION_REQUIRES_BATTLE_LEVEL")
      txt = select(1, txt:gsub("XXX", element("RequiresBattleLevel"):GetInt()))
    elseif costumeData.unlockTeleport == 1 then
      txt = game.getLocalizedText("REQUIRES_TELEPORT_TO_BATTLE")
    else
      txt = game.getLocalizedText("REQUIRES_COMPLETING_QUEST")
    end
  elseif store:Category() == game.StoreCategories_TYPE_ISLAND and element("ID"):GetInt() > 0 then
    if game.playerLevel() < element("RequiresLevel"):GetInt() then
      txt = game.getLocalizedText("NOTIFICATION_REQUIRES_LEVEL")
      txt = select(1, txt:gsub("XXX", element("RequiresLevel"):GetInt()))
    elseif element("RequiresIsland"):GetInt() ~= -1 then
      txt = game.getLocalizedText("NOTIFICATION_REQUIRES_ITEM")
      txt = select(1, txt:gsub("XXX", game.getLocalizedText(game.islandName(element("RequiresIsland"):GetInt()))))
    elseif store:islandIdByItemNum(element("ID"):GetInt()) == game.IslandType_BATTLE and not store:canUnlockIslandByItemNum(element("ID"):GetInt()) then
      txt = game.getLocalizedText("BATTLE_ISLAND_LOCKED")
      txt = select(1, txt:gsub("XXX", game.islandUnlockLevel(store:islandIdByItemNum(element("ID"):GetInt()))))
    end
  elseif store:Category() == game.StoreCategories_TYPE_DECORATION then
    if game.playerBattleLevel() < element("RequiresBattleLevel"):GetInt() then
      txt = game.getLocalizedText("NOTIFICATION_REQUIRES_BATTLE_LEVEL")
      txt = select(1, txt:gsub("XXX", element("RequiresBattleLevel"):GetInt()))
    else
      txt = game.getLocalizedText("NOTIFICATION_REQUIRES_LEVEL")
      txt = select(1, txt:gsub("XXX", element("RequiresLevel"):GetInt()))
    end
  else
    txt = game.getLocalizedText("NOTIFICATION_REQUIRES_LEVEL")
    txt = select(1, txt:gsub("XXX", element("RequiresLevel"):GetInt()))
  end
  component("text"):SetString(txt)
end
local initMaxAmount = function(component, element)
  local max = element("maxAmount"):GetInt()
  if max == 0 then
    component("visible"):SetInt(0)
  else
    local num = element("currentAmount"):GetInt()
    local txt = num .. "/" .. max
    component("font"):Set(game.getTextFont())
    component("size"):SetFloat(0.3 * game.hudScale())
    component("alignment"):SetInt(lua_sys.MenuTextComponent_TEXT_HCENTER_ALIGNED)
    component("text"):SetString(txt)
    component("layer"):SetString("HUD")
  end
end
local function initMonsterCount(component, element)
  local showCount = store:Category() == game.StoreCategories_TYPE_MONSTER and game.currentIsland() ~= game.IslandType_PAIRONORMAL or store:Category() == game.StoreCategories_TYPE_DECORATION or store:Category() == game.StoreCategories_TYPE_COSTUMES and game.currentIsland() ~= game.IslandType_PAIRONORMAL or store:Category() == game.StoreCategories_TYPE_STARPOWER and store:showStarpowerPossessedCount(element("ID"):GetInt())
  if showCount then
    if e_SaleTag then
      component("yOffset"):SetFloat(72 * game.menuScaleY())
    end
    component("font"):Set(game.getTextFont())
    component("size"):SetFloat(0.3 * game.hudScale())
    component("alignment"):SetInt(lua_sys.MenuTextComponent_TEXT_RIGHT_ALIGNED)
    component("text"):SetString(element("currentAmount"):GetInt())
    component("layer"):SetString("HUD")
  else
    component("visible"):SetInt(0)
  end
end
local initTempAvailTextTimerText = function(component, element)
  local index = element:parent()("ID"):GetInt()
  local secondsRemaining = 0
  if element:parent()("TimedAvailabilityOn"):GetInt() == 1 then
    secondsRemaining = store:RemainingAvailTime(index)
  elseif element:parent()("TimedUnavailabilityOn"):GetInt() == 1 then
    secondsRemaining = store:RemainingUnavailTime(index)
  elseif element:parent()("TimedSaleOn"):GetInt() == 1 then
    secondsRemaining = store:RemainingSaleTime(index)
  end
  component("text"):SetString("" .. game.timeToString(secondsRemaining, true))
end
local initTempAvailTextAvailableUntil = function(component, element)
  component("multiline"):SetInt(1)
  component("font"):Set(game.getTextFont())
  component("size"):SetFloat(0.3 * game.hudScale())
  component("alignment"):SetInt(lua_sys.MenuTextComponent_TEXT_HCENTER_ALIGNED)
  component("text"):SetString("AVAILABLE_LIMITED_TIME")
  component("layer"):SetString("HUD")
  component("autoScaleFactor"):SetFloat(0.01)
  component("autoScale"):SetInt(1)
  component("visible"):SetInt(0)
  if element:parent()("TimedAvailabilityOn"):GetInt() == 1 then
    component("multiline"):SetInt(0)
    component("autoScale"):SetInt(0)
    component("size"):SetFloat(0.3 * game.hudScale())
    component("text"):SetString("AVAILABLE_UNTIL")
    component("visible"):SetInt(1)
    component("autoScale"):SetInt(1)
  elseif element:parent()("TimedUnavailabilityOn"):GetInt() == 1 then
    component("multiline"):SetInt(0)
    component("autoScale"):SetInt(0)
    component("size"):SetFloat(0.3 * game.hudScale())
    component("text"):SetString("UNAVAILABLE_UNTIL")
    component("visible"):SetInt(1)
    component("autoScale"):SetInt(1)
  elseif element:parent()("TimedSaleOn"):GetInt() == 1 then
    component("multiline"):SetInt(0)
    component("autoScale"):SetInt(0)
    component("size"):SetFloat(0.3 * game.hudScale())
    component("text"):SetString("ONSALE_UNTIL")
    component("visible"):SetInt(1)
    component("autoScale"):SetInt(1)
  end
  if game.playerLevel() >= element:parent()("RequiresLevel"):GetInt() and store:Category() == game.StoreCategories_TYPE_MONSTER and element:parent()("numGenes"):GetInt() == 0 and element:parent()("BoxMonster"):GetInt() == 0 then
    component("visible"):SetInt(1)
  end
end
local postInitTempAvailTextAvailableUntil = function(component, element)
  if element:parent()("ItemTitle"):GetString() == "MINE_01_01" then
    component("yOffset"):SetInt(30 * game.menuScaleY())
  end
end
function StoreItem:revertTimeAvail(dt)
  local secondsRemaining = 0
  if store:Category() == game.StoreCategories_TYPE_CURRENCY then
    local availabilityEvent = self("TimedAvailabilityOn"):GetInt()
    if availabilityEvent == 1 then
      secondsRemaining = store:RemainingAvailTime(self("ID"):GetInt())
    elseif self("TimedSaleOn"):GetInt() == 1 then
      secondsRemaining = store:RemainingSaleTime(self("ID"):GetInt())
    end
    if secondsRemaining > 0 then
      e_TempAvailText.TimerText("visible"):SetInt(1)
      e_TempAvailText.TimerText("text"):SetString(game.timeToString(secondsRemaining, true))
      if e_SaleTag then
        local newSale = store:SaleAmount(self("ID"):GetInt())
        if newSale ~= self("SaleAmount"):GetInt() then
          e_SaleTag.SaleAmount.Text("visible"):SetInt(1)
          e_SaleTag.SaleAmount.Text("text"):SetString(game.commaizeNumber(newSale))
          e_SaleTag.Text("visible"):SetInt(1)
          e_SaleTag.Text("text"):SetString("+" .. store:SaleDesc(self("ID"):GetInt()) .. "%")
        end
      end
    elseif availabilityEvent == 1 then
      store:AnAvailabilityExpiryOccurred(self:name())
      e_TempAvailText.TimerText("visible"):SetInt(0)
      e_TempAvailText.AvailableUntil("visible"):SetInt(1)
      e_TempAvailText.AvailableUntil("text"):SetString("TIMED_EVENT_EXPIRED")
      StoreItem.setDisabled(self)
    else
      if e_SaleTag then
        e_SaleTag:DoStoredScript("hide")
        e_SaleTag = nil
      end
      e_TempAvailText.TimerText("visible"):SetInt(0)
      e_TempAvailText.AvailableUntil("visible"):SetInt(0)
    end
  else
    local hideSaleTag = true
    if store:Category() == game.StoreCategories_TYPE_COSTUMES then
      local costumeId = store:ItemId(self("ID"):GetInt())
      local costumeData = game.getCostumeData(costumeId)
      if not game.isBattleIsland() and game.isCostumeUnlocked(costumeId) and game.getCostumeCredit(costumeId) == 0 and costumeData.ignoreLocks == 0 and costumeData.isPurchaseLocked == false then
        hideSaleTag = false
      end
    end
    local availabilityEvent = self("TimedAvailabilityOn"):GetInt()
    if availabilityEvent == 1 then
      secondsRemaining = store:RemainingAvailTime(self("ID"):GetInt())
    elseif self("TimedSaleOn"):GetInt() == 1 then
      secondsRemaining = store:RemainingSaleTime(self("ID"):GetInt())
    end
    if secondsRemaining > 0 then
      e_TempAvailText.TimerText("text"):SetString(game.timeToString(secondsRemaining, true))
    elseif availabilityEvent == 1 then
      store:AnAvailabilityExpiryOccurred(self:name())
      e_TempAvailText.TimerText("visible"):SetInt(0)
      e_TempAvailText.AvailableUntil("text"):SetString("TIMED_EVENT_EXPIRED")
      StoreItem.setDisabled(self)
    else
      if e_SaleTag and hideSaleTag then
        e_SaleTag:DoStoredScript("hide")
        e_SaleTag = nil
        StoreItem.enableAndPopulateCosts(self)
      end
      e_TempAvailText.TimerText("visible"):SetInt(0)
      e_TempAvailText.AvailableUntil("visible"):SetInt(0)
    end
  end
end
local function tickTempAvail(element, dt)
  local secondsRemaining = 0
  local parent = element:parent()
  if store:Category() == game.StoreCategories_TYPE_CURRENCY then
    local availabilityEvent = parent("TimedAvailabilityOn"):GetInt()
    if availabilityEvent == 1 then
      secondsRemaining = store:RemainingAvailTime(parent("ID"):GetInt())
    elseif parent("TimedSaleOn"):GetInt() == 1 then
      secondsRemaining = store:RemainingSaleTime(parent("ID"):GetInt())
    end
    if secondsRemaining > 0 then
      element.TimerText("text"):SetString(game.timeToString(secondsRemaining, true))
      if e_SaleTag then
        local newSale = store:SaleAmount(parent("ID"):GetInt())
        if newSale ~= parent("SaleAmount"):GetInt() then
          e_SaleTag.SaleAmount.Text("text"):SetString(game.commaizeNumber(newSale))
          e_SaleTag.Text("text"):SetString("+" .. store:SaleDesc(parent("ID"):GetInt()) .. "%")
        end
      end
    elseif availabilityEvent == 1 then
      if parent.Touch("enabled"):GetInt() == 1 then
        store:AnAvailabilityExpiryOccurred(parent:name())
        element.TimerText("visible"):SetInt(0)
        element.AvailableUntil("text"):SetString("TIMED_EVENT_EXPIRED")
        StoreItem.setDisabled(parent)
      end
    elseif element.TimerText("visible"):GetInt() == 1 then
      if e_SaleTag then
        e_SaleTag:DoStoredScript("hide")
        e_SaleTag = nil
      end
      element.TimerText("visible"):SetInt(0)
      element.AvailableUntil("visible"):SetInt(0)
    end
  else
    local availabilityEvent = parent("TimedAvailabilityOn"):GetInt()
    local unavailabilityEvent = parent("TimedUnavailabilityOn"):GetInt()
    if availabilityEvent == 1 then
      secondsRemaining = store:RemainingAvailTime(parent("ID"):GetInt())
    elseif unavailabilityEvent == 1 then
      secondsRemaining = store:RemainingUnavailTime(parent("ID"):GetInt())
    elseif parent("TimedSaleOn"):GetInt() == 1 then
      secondsRemaining = store:RemainingSaleTime(parent("ID"):GetInt())
    end
    if secondsRemaining > 0 then
      element.TimerText("text"):SetString(game.timeToString(secondsRemaining, true))
      if unavailabilityEvent == 1 and parent.Touch("enabled"):GetInt() == 1 then
        StoreItem.setDisabled(parent)
      end
    elseif availabilityEvent == 1 then
      if parent.Touch("enabled"):GetInt() == 1 then
        store:AnAvailabilityExpiryOccurred(parent:name())
        element.TimerText("visible"):SetInt(0)
        element.AvailableUntil("text"):SetString("TIMED_EVENT_EXPIRED")
        StoreItem.setDisabled(parent)
      end
    elseif unavailabilityEvent == 1 then
      if parent.Touch("enabled"):GetInt() == 0 then
        store:AnAvailabilityExpiryOccurred(parent:name())
        element.TimerText("visible"):SetInt(0)
        element.AvailableUntil("visible"):SetInt(0)
        StoreItem.setEnabled(parent)
      end
    elseif element.TimerText("visible"):GetInt() == 1 then
      if e_SaleTag then
        e_SaleTag:DoStoredScript("hide")
        e_SaleTag = nil
        StoreItem.enableAndPopulateCosts(parent)
      end
      element.TimerText("visible"):SetInt(0)
      element.AvailableUntil("visible"):SetInt(0)
    end
  end
end
local onTouchUp = function(component, element, x, y)
  if math.abs(component("touchStart"):GetInt() - component("realStart"):GetInt()) < 10 then
    if element:name() == "freeDiamonds" then
      game.displayNotification("NO_ADS_STOREITEM_DESC")
    elseif store:Category() == game.StoreCategories_TYPE_DECORATION then
      if game.isComposerIsland() then
        game.displayNotification("COMPOSER_DECORATION_CATEGORY_LOCKED")
      elseif game.onGoldIsland() then
        game.displayNotification("GOLD_DECORATION_CATEGORY_LOCKED")
      elseif game.isTribalIsland() then
        game.displayNotification("TRIBAL_DECORATION_CATEGORY_LOCKED")
      else
        store:SelectItem(element:name())
      end
    elseif store:Category() == game.StoreCategories_TYPE_STRUCTURE then
      if game.isComposerIsland() then
        game.displayNotification("COMPOSER_STRUCTURE_CATEGORY_LOCKED")
      elseif game.onGoldIsland() then
        game.displayNotification("GOLD_STRUCTURE_CATEGORY_LOCKED")
      elseif game.onTribalIsland() then
        game.displayNotification("TRIBAL_STRUCTURE_CATEGORY_LOCKED")
      else
        store:SelectItem(element:name())
      end
    elseif store:Category() == game.StoreCategories_TYPE_STARPOWER then
      if game.isComposerIsland() then
        game.displayNotification("COMPOSER_STARPOWER_CATEGORY_LOCKED")
      elseif game.onGoldIsland() then
        game.displayNotification("GOLD_STARPOWER_CATEGORY_LOCKED")
      elseif game.onTribalIsland() then
        game.displayNotification("TRIBAL_STARPOWER_CATEGORY_LOCKED")
      elseif not store:canBuyAnotherRightNow(element("ID"):GetInt()) and store:IsBoxMonster(element("ID"):GetInt()) == 1 then
        game.displayNotification("NOTIFICATION_ALREADY_INACTIVE_BOX")
      else
        store:SelectItem(element:name())
      end
    elseif store:Category() == game.StoreCategories_TYPE_MONSTER then
      if game.onGoldIsland() then
        game.displayNotification("GOLD_MONSTER_CATEGORY_LOCKED")
      elseif game.onTribalIsland() then
        game.displayNotification("TRIBAL_MONSTER_CATEGORY_LOCKED")
      elseif not store:canBuyAnotherRightNow(element("ID"):GetInt()) and store:IsBoxMonster(element("ID"):GetInt()) == 1 then
        game.displayNotification("NOTIFICATION_ALREADY_INACTIVE_BOX")
      else
        store:SelectItem(element:name())
      end
    else
      store:SelectItem(element:name())
    end
    component("dragging"):SetInt(0)
    component("touchStart"):SetInt(0)
    component("realStart"):SetInt(0)
  end
end
local function initializeChildren(element)
  c_Sprite = element:GetComponent("Sprite")
  e_TitleFrame = element:GetElement("TitleFrame")
  e_TitleFrame:GetComponent("Text"):addLuaFunction("onInit", initTitleFrameText)
  e_MonsterAnim = element:GetElement("MonsterAnim")
  e_MonsterAnim:GetComponent("Sprite"):addLuaFunction("onInit", initMonsterAnim)
  e_NewLabel = element:GetElement("NewLabel")
  e_NewLabel:addLuaFunction("onInit", initNewLabel)
  e_CurrencyAmount = element:GetElement("CurrencyAmount")
  e_CurrencyAmount:addLuaFunction("onInit", initCurrencyAmount)
  e_CurrencyAmount:GetComponent("Text"):addLuaFunction("onInit", initCurrencyAmountText)
  e_CurrencyAmount:GetComponent("Sprite"):addLuaFunction("onInit", initCurrencyAmountSprite)
  e_IAPCost = element:GetElement("IAPCost")
  e_IAPCost:GetComponent("Text"):addLuaFunction("onInit", initIAPCostText)
  e_AnyCost = element:GetElement("AnyCost")
  e_AnyCost:addLuaFunction("onInit", initAnyCost)
  e_AnyCost:addLuaFunction("setCurrency", setAnyCostCurrency)
  c_LevelReq = element:GetComponent("LevelReq")
  c_LevelReq:addLuaFunction("initLevelReq", initLevelReq)
  c_MaxAmount = element:GetComponent("maxAmount")
  c_MaxAmount:addLuaFunction("onInit", initMaxAmount)
  c_MonsterCount = element:GetComponent("monsterCount")
  c_MonsterCount:addLuaFunction("onInit", initMonsterCount)
  e_TempAvailText = element:GetElement("TempAvailText")
  e_TempAvailText:GetComponent("AvailableUntil"):addLuaFunction("onInit", initTempAvailTextAvailableUntil)
  e_TempAvailText:GetComponent("AvailableUntil"):addLuaFunction("onPostInit", postInitTempAvailTextAvailableUntil)
  e_TempAvailText:addLuaFunction("onTick", tickTempAvail)
  e_ExchangeRateResetText = element:GetElement("ExchangeRateResetText")
  e_ExchangeRateResetText("relicExchangeItem"):SetInt(0)
  c_Touch = element:GetComponent("Touch")
  c_Touch:addLuaFunction("onTouchUp", onTouchUp)
end
function StoreItem:onInit()
  initializeChildren(self)
  self.enabled = true
  self.touchEnabled = true
  self("isLocked"):SetInt(0)
  e_AnyCost("currencyXOffset"):SetInt(32 * game.menuScaleX())
  e_AnyCost("ownedTextXOffset"):SetInt(20 * game.menuScaleX())
  StoreItem.enableAndPopulateCosts(self)
  local i = self("ID"):GetInt()
  maxAmount = store:maxAmount(i)
  numGenes = store:NumGenes(i)
  self("numGenes"):SetInt(numGenes)
  self("maxAmount"):SetInt(maxAmount)
  self("currentAmount"):SetInt(store:currentAmount(i))
  if i >= store:NumCategoryItems() - store:NumLockedItems() or not store:canBuyAnotherRightNow(i) or maxAmount > 0 and store:currentAmount(i) >= maxAmount then
    StoreItem.setLocked(self)
  end
  if store:SaleAmount(i) ~= 0 and self("Cost"):GetString() ~= "OWNED" then
    local category = store:Category()
    if category == game.StoreCategories_TYPE_COSTUMES and 0 < game.getCostumeCredit(store:ItemId(i)) then
    elseif category == game.StoreCategories_TYPE_COSTUMES and not game.isBattleIsland() then
      local costumeId = store:ItemId(i)
      e_SaleTag = menu:addTemplateElement("template_itemsaletag", "saleTag", self)
      e_SaleTag("CostumeId"):SetInt(costumeId)
    else
      local hasFreeItem = false
      if category == game.StoreCategories_TYPE_MONSTER or category == game.StoreCategories_TYPE_STRUCTURE or category == game.StoreCategories_TYPE_DECORATION or category == game.StoreCategories_TYPE_STARPOWER then
        hasFreeItem = 0 < game.getInventoryAmount(store:EntityIdFromItemNum(i))
      end
      if not hasFreeItem then
        e_SaleTag = menu:addTemplateElement("template_itemsaletag", "saleTag", self)
      end
    end
    if e_SaleTag then
      e_SaleTag:setOrientation(lua_sys.MenuOrientation(-4 * game.menuScaleX(), 60 * game.menuScaleX(), -3, lua_sys.HCENTER, lua_sys.TOP))
      e_SaleTag("SaleCurrencyType"):SetString(store:PurchaseTypeOfSaleItem(i))
      e_SaleTag:setParent(self)
      e_SaleTag:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
      e_SaleTag("SaleDesc"):SetString(self("SaleDesc"):GetString())
      e_SaleTag("SaleAmount"):SetInt(self("SaleAmount"):GetInt())
      e_SaleTag("CurrencyType"):SetString(self("Type"):GetString())
      e_SaleTag:init()
      e_SaleTag:setPositionBroadcast(true)
      if store:Category() == game.StoreCategories_TYPE_MONSTER then
        c_MonsterCount("yOffset"):SetInt(60 * game.menuScaleY())
      end
      if self("TimedSaleOn"):GetInt() == 1 then
        if self("TimedAvailabilityOn"):GetInt() == 1 then
          e_SaleTag:DoStoredScript("SetPositionForTimedSaleLimitedAvailMonster")
        else
          e_SaleTag:DoStoredScript("SetPositionForTimedSaleNormalMonster")
        end
      end
    end
  elseif store:Category() == game.StoreCategories_TYPE_COSTUMES then
    local costumeId = store:ItemId(i)
    local costumeData = game.getCostumeData(costumeId)
    if not game.isBattleIsland() and game.isCostumeUnlocked(costumeId) and game.getCostumeCredit(costumeId) == 0 and costumeData.ignoreLocks == 0 and costumeData.isPurchaseLocked == false then
      e_SaleTag = menu:addTemplateElement("template_costume_store_tag", "saleTag", self)
      e_SaleTag:setOrientation(lua_sys.MenuOrientation(-4 * game.menuScaleX(), 60 * game.menuScaleX(), -3, lua_sys.HCENTER, lua_sys.TOP))
      e_SaleTag("CostumeId"):SetInt(costumeId)
      e_SaleTag:setParent(self)
      e_SaleTag:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
      e_SaleTag:init()
      e_SaleTag:setPositionBroadcast(true)
      c_MonsterCount("yOffset"):SetInt(60 * game.menuScaleY())
    end
  end
  self("displayWhiteGreenTextAtBottom"):SetInt(0)
  if lua_sys.getSubPlatformName() ~= "amazon" and store:Category() == game.StoreCategories_TYPE_ISLAND and store:getRemixByIndex(i) ~= "" and store:canUnlockIslandByItemNum(i) and game.amazonStreamBox() ~= 1 then
    local remixButton = menu:addTemplateElement("template_remixbutton", "RemixButton", self)
    remixButton:setParent(self)
    remixButton:init()
    remixButton:setPositionBroadcast(true)
  end
  local function addSticker(spriteName, sheetName)
    e_QuestSticker = menu:addTemplateElement("template_spritesheet", "questSticker", self)
    e_QuestSticker:setParent(self)
    e_QuestSticker:relativeTo(self)
    e_QuestSticker:setOrientation(lua_sys.MenuOrientation(-12 * game.menuScaleX(), 12 * game.menuScaleX(), -1, lua_sys.HCENTER, lua_sys.VCENTER))
    e_QuestSticker:setRelativeObjectAnchors(lua_sys.RIGHT, lua_sys.TOP)
    local sprite = e_QuestSticker:GetComponent("Sprite")
    sprite("spriteName"):SetString(spriteName)
    sprite("sheetName"):SetString(sheetName)
    sprite("size"):SetFloat(0.25 * game.menuScaleX())
    sprite("layer"):SetString("HUD")
  end
  if store:Category() == game.StoreCategories_TYPE_COSTUMES then
    local costumeId = store:ItemId(i)
    local costumeData = game.getCostumeData(costumeId)
    if costumeData.ignoreLocks == 1 then
      if costumeData.altSheet ~= "" then
        addSticker(costumeData.altIcon, "xml_resources/" .. costumeData.altSheet)
      end
    elseif not game.isBattleIsland() and not costumeData.isPurchaseLocked and game.isCostumeUnlocked(costumeId) then
      addSticker("button_battle_complete", "xml_resources/hud03.xml")
    end
  end
  if store:Category() == game.StoreCategories_TYPE_MONSTER then
    local id = self("ID"):GetInt()
    local entityId = store:EntityIdFromItemNum(id)
    local monsterData = game.getMonsterByEntityId(entityId)
    if monsterData:isPaironormal() then
      local activeIsland = game.player():getActiveIsland()
      if activeIsland:type() == game.IslandType_PAIRONORMAL then
        if activeIsland:islandMode() == 1 then
          addSticker("button_paironormal_MIN", "xml_resources/hud03.xml")
        else
          addSticker("button_paironormal_MAJ", "xml_resources/hud03.xml")
        end
      else
        addSticker("button_paironormal", "xml_resources/hud03.xml")
      end
    end
  end
  initLevelReq(c_LevelReq, self)
  initTempAvailTextTimerText(e_TempAvailText:GetComponent("TimerText"), e_TempAvailText)
  self.fader = ElementFader.New(self, {
    onUpdateComponent = function(component)
      if component.colorChange then
        component:colorChange()
      end
    end,
    duration = 0.2
  })
  self.fader:Show()
end
function StoreItem:onTick(dt)
  self.fader:tick(dt)
end
function StoreItem.enableAndPopulateCosts(element)
  local purchaseType = element("Type"):GetString()
  e_AnyCost("currencyType"):SetString(purchaseType)
  if purchaseType == "none" and store:Category() == game.StoreCategories_TYPE_ISLAND then
    e_AnyCost("xOffset"):SetInt(e_AnyCost("ownedTextXOffset"):GetInt())
    e_AnyCost.Text("visible"):SetInt(1)
  else
    e_AnyCost:DoStoredScript("setCurrency")
  end
end
function StoreItem:addLock()
  local lock = menu:addTemplateElement("template_storeitemlock", "ItemLock", self)
  lock.layer = "HUD"
  lock:relativeTo(self)
  lock:setOrientation(lua_sys.MenuOrientation(0, 15 * game.menuScaleX(), -3, lua_sys.HCENTER, lua_sys.VCENTER))
  lock:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
  lock:init()
  lock:setPositionBroadcast(true)
  lock:postInit()
end
function StoreItem:removeLock()
  self:RemoveElement(self:GetElement("ItemLock"))
end
local function initGenes(element)
  local i = element("ID"):GetInt()
  if store:Category() == game.StoreCategories_TYPE_COSTUMES then
    local costumeId = store:ItemId(i)
    local costumeData = game.getCostumeData(costumeId)
    if costumeData.action > 0 then
      local action = game.getBattleMonsterActionData(costumeData.action)
      local actionItem = menu:addTemplateElement("template_elementicon", element:name() .. "-gene0", element)
      actionItem("SpriteName"):SetString(action:getIconSprite())
      actionItem("SheetName"):SetString(action:getIconSpriteSheet())
      actionItem("Size"):SetFloat(0.3 * game.hudScale())
      actionItem("Layer"):SetString("HUD")
      actionItem:setParent(element)
      actionItem:setOrientation(lua_sys.MenuOrientation(-3 * game.menuScaleX(), -10 / game.hudScale(), -3, lua_sys.HCENTER, lua_sys.VCENTER))
      actionItem:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.BOTTOM)
      actionItem:init()
      actionItem:setPositionBroadcast(true)
      numGenes = 1
      element("numGenes"):SetInt(1)
    end
  else
    local entityData = store:EntityDataFromItemNum(i)
    if entityData and entityData:isMonster() then
      local id = store:ItemId(i)
      if store:Category() == game.StoreCategories_TYPE_STARPOWER then
        id = game.getMonsterByEntityId(id):monsterId()
      end
      Genes.InitForMonsterId(id, element, {
        layer = "HUD",
        spacing = -2 * game.hudScale(),
        prefix = element:name() .. "-gene",
        priority = -3,
        vAnchor = lua_sys.BOTTOM,
        offsetY = -8 * game.hudScale()
      })
    end
  end
  if not element.enabled then
    for i = 0, numGenes - 1 do
      local geneElement = element:GetElement(element:name() .. "-gene" .. i)
      if geneElement then
        geneElement.Sprite:setColor(0.5, 0.5, 0.5)
      end
    end
  end
end
function StoreItem.onPostInit(element)
  initGenes(element)
  if store:Category() == game.StoreCategories_TYPE_ISLAND and not store:canUnlockIslandByItemNum(element("ID"):GetInt()) then
    StoreItem.setLocked(element)
  end
  if element("Premium"):GetInt() == 1 and not game.premiumPlayer() then
    StoreItem.setDisabled(element)
    local premiumLock = menu:addTemplateElement("template_premiumlock", "PremiumLock", element)
    premiumLock:relativeTo(element)
    premiumLock:setOrientation(lua_sys.MenuOrientation(0, 15 * game.menuScaleX(), -3, lua_sys.HCENTER, lua_sys.VCENTER))
    premiumLock:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    premiumLock:init()
    premiumLock:setPositionBroadcast(true)
    premiumLock:postInit()
  end
  local displayWhiteGreenTextAtBottom = 0
  if (element("TimedAvailabilityOn"):GetInt() == 1 or element("TimedUnavailabilityOn"):GetInt() == 1 or element("TimedSaleOn"):GetInt() == 1) and element("Cost"):GetString() ~= "OWNED" then
    displayWhiteGreenTextAtBottom = 1
  end
  e_TempAvailText.AvailableUntil("visible"):SetInt(displayWhiteGreenTextAtBottom)
  e_TempAvailText.TimerText("visible"):SetInt(displayWhiteGreenTextAtBottom)
  element("displayWhiteGreenTextAtBottom"):SetInt(displayWhiteGreenTextAtBottom)
  if game.isComposerIsland() or game.onGoldIsland() or game.onTribalIsland() then
    if (game.onGoldIsland() or game.onTribalIsland()) and store:Category() == game.StoreCategories_TYPE_MONSTER then
      StoreItem.setDisabled(element)
      element.Touch("enabled"):SetInt(1)
      element.touchEnabled = true
    end
    if store:Category() == game.StoreCategories_TYPE_DECORATION or store:Category() == game.StoreCategories_TYPE_STRUCTURE or store:Category() == game.StoreCategories_TYPE_STARPOWER then
      StoreItem.setDisabled(element)
      element.Touch("enabled"):SetInt(1)
      element.touchEnabled = true
    end
  end
end
function StoreItem.setLocked(element)
  element("isLocked"):SetInt(1)
  if store:Category() == game.StoreCategories_TYPE_COSTUMES then
    c_MaxAmount("visible"):SetInt(0)
    c_LevelReq("visible"):SetInt(1)
    e_TempAvailText.AvailableUntil("visible"):SetInt(0)
    e_TempAvailText.TimerText("visible"):SetInt(0)
    StoreItem.setDisabled(element)
    return
  end
  local showLevelReqText = false
  if game.playerLevel() < element("RequiresLevel"):GetInt() then
    showLevelReqText = true
  elseif game.playerBattleLevel() < element("RequiresBattleLevel"):GetInt() then
    showLevelReqText = true
  elseif store:Category() == game.StoreCategories_TYPE_ISLAND and 0 < element("ID"):GetInt() then
    showLevelReqText = true
  end
  local hasLock = element:GetElement("ItemLock") ~= nil
  if store:Category() == game.StoreCategories_TYPE_STRUCTURE and element("ItemTitle"):GetString() == "STRUCTURE_AWAKENER" then
    do
      local id = element("ID"):GetInt()
      local entityId = store:EntityIdFromItemNum(id)
      local structureData = game.getStructureByEntityId(entityId)
      local calendarId = structureData:getExtraInt("calendar")
      local placedAmount = element("currentAmount"):GetInt()
      if calendarId > 1 and calendarId > game.player():getDailyCumulativeLogin():calendar() and placedAmount == 0 then
        if not hasLock then
          local lock = menu:addTemplateElement("template_awakenerlock", "ItemLock", element)
          lock:relativeTo(element)
          lock:setOrientation(lua_sys.MenuOrientation(0, 15 * game.menuScaleX(), -3, lua_sys.HCENTER, lua_sys.VCENTER))
          lock:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
          lock:init()
          lock:setPositionBroadcast(true)
          lock:postInit()
          function lock.ShowNotification()
            local previousCalendarId = calendarId - 1
            local previousCalendar = game.getDailyCumulativeLoginData(previousCalendarId)
            local text = game.getLocalizedText("NOTIFICATION_REQUIRES_PREVIOUS_CONUNDRUM")
            text = text:gsub("%${ISLAND}", LOC(previousCalendar:name()))
            game.displayNotification(text)
          end
        end
        e_TitleFrame.Text("size"):SetFloat(0.3 * game.menuScaleY())
        e_TitleFrame.Text("text"):SetString("?")
        e_TitleFrame.Text("autoScale"):SetInt(1)
        c_LevelReq("visible"):SetInt(1)
        c_LevelReq("text"):SetString(LOC("REQUIRES_COMPLETING_CONUNDRUM"))
        c_MaxAmount("visible"):SetInt(0)
      end
    end
  end
  if store:Category() == game.StoreCategories_TYPE_MONSTER then
    local id = element("ID"):GetInt()
    local entityId = store:EntityIdFromItemNum(id)
    local monsterData = game.getMonsterByEntityId(entityId)
    if monsterData:isTitansoul() then
      local placedAmount = element("currentAmount"):GetInt()
      local islandId = monsterData:requiredAwakenedIsland()
      local island = game.player():getIslandWithId(islandId)
      print("Needs:", islandId, island)
      if game.player():canAwakenAnyIslandWithType(island:type()) == false and placedAmount == 0 then
        if not hasLock then
          local lock = menu:addTemplateElement("template_awakenerlock", "ItemLock", element)
          lock:relativeTo(element)
          lock:setOrientation(lua_sys.MenuOrientation(0, 15 * game.menuScaleX(), -3, lua_sys.HCENTER, lua_sys.VCENTER))
          lock:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
          lock:init()
          lock:setPositionBroadcast(true)
          lock:postInit()
          function lock.ShowNotification()
            game.displayNotification("NOTIFICATION_TITANSOUL_REQUIRES_CONUNDRUM")
          end
        end
        e_TitleFrame.Text("size"):SetFloat(0.3 * game.menuScaleY())
        e_TitleFrame.Text("text"):SetString("?")
        e_TitleFrame.Text("autoScale"):SetInt(1)
        c_LevelReq("visible"):SetInt(1)
        c_LevelReq("text"):SetString(LOC("REQUIRES_COMPLETING_CONUNDRUM"))
        c_MaxAmount("visible"):SetInt(0)
      end
    end
  end
  if showLevelReqText then
    c_LevelReq("visible"):SetInt(1)
    e_TitleFrame.Text("size"):SetFloat(0.3 * game.menuScaleY())
    e_TitleFrame.Text("text"):SetString("?")
    e_TitleFrame.Text("autoScale"):SetInt(1)
    e_AnyCost.Text("text"):SetString("?")
    c_MaxAmount("visible"):SetInt(0)
    local remixButton = element:GetElement("RemixButton")
    if remixButton ~= nil then
      remixButton.button:DoStoredScript("setInvisible")
    end
  end
  if e_TempAvailText.TimerText("visible"):GetInt() == 1 then
    if e_SaleTag then
      e_SaleTag:DoStoredScript("hide")
      e_SaleTag = nil
    end
    e_TempAvailText.TimerText("visible"):SetInt(0)
    e_TempAvailText.AvailableUntil("visible"):SetInt(0)
  end
  e_TempAvailText.AvailableUntil("visible"):SetInt(0)
  e_TempAvailText.TimerText("visible"):SetInt(0)
  StoreItem.setDisabled(element)
  if not store:canBuyAnotherRightNow(element("ID"):GetInt()) and store:IsBoxMonster(element("ID"):GetInt()) == 1 then
    c_Touch("enabled"):SetInt(1)
    element.touchEnabled = true
  end
end
function StoreItem.setEnabled(element)
  if not element.enabled then
    c_Sprite:setColor(1, 1, 1)
    e_TitleFrame.Text:setColor(1, 1, 1)
    e_MonsterAnim.Sprite:setColor(1, 1, 1)
    e_AnyCost.Text:setColor(e_AnyCost.Text("red"):GetFloat() * 2, e_AnyCost.Text("green"):GetFloat() * 2, e_AnyCost.Text("blue"):GetFloat() * 2)
    e_AnyCost.Sprite:setColor(1, 1, 1)
    for i = 0, numGenes - 1 do
      local geneElement = element:GetElement(element:name() .. "-gene" .. i)
      if geneElement then
        geneElement.Sprite:setColor(1, 1, 1)
      end
    end
    e_NewLabel.Sprite:setColor(1, 1, 1)
    e_NewLabel.Text:setColor(e_NewLabel.Text("red"):GetFloat() * 2, e_NewLabel.Text("green"):GetFloat() * 2, e_NewLabel.Text("blue"):GetFloat() * 2)
    c_MonsterCount("visible"):SetInt(1)
    if e_SaleTag then
      e_SaleTag:DoStoredScript("show")
    end
    c_Touch("enabled"):SetInt(1)
    element.enabled = true
    element.touchEnabled = true
  end
end
function StoreItem.setDisabled(element)
  if element.enabled then
    c_Sprite:setColor(0.5, 0.5, 0.5)
    e_TitleFrame.Text:setColor(0.5, 0.5, 0.5)
    e_MonsterAnim.Sprite:setColor(0.2, 0.2, 0.2)
    e_AnyCost.Text:setColor(e_AnyCost.Text("red"):GetFloat() * 0.5, e_AnyCost.Text("green"):GetFloat() * 0.5, e_AnyCost.Text("blue"):GetFloat() * 0.5)
    e_AnyCost.Sprite:setColor(0.5, 0.5, 0.5)
    for i = 0, numGenes - 1 do
      local geneElement = element:GetElement(element:name() .. "-gene" .. i)
      if geneElement then
        geneElement.Sprite:setColor(0.5, 0.5, 0.5)
      end
    end
    e_NewLabel.Sprite:setColor(0.5, 0.5, 0.5)
    e_NewLabel.Text:setColor(e_NewLabel.Text("red"):GetFloat() * 0.5, e_NewLabel.Text("green"):GetFloat() * 0.5, e_NewLabel.Text("blue"):GetFloat() * 0.5)
    c_MonsterCount("visible"):SetInt(0)
    if e_SaleTag then
      e_SaleTag:DoStoredScript("showDisabled")
    end
    c_Touch("enabled"):SetInt(0)
    element.enabled = false
    element.touchEnabled = false
  end
end
function StoreItem.hideItem(element)
  c_Sprite("visible"):SetInt(0)
  e_TitleFrame.Text("visible"):SetInt(0)
  e_MonsterAnim.Sprite("visible"):SetInt(0)
  c_MaxAmount("visible"):SetInt(0)
  e_ExchangeRateResetText.TitleText("visible"):SetInt(0)
  e_ExchangeRateResetText.TimerText("visible"):SetInt(0)
  e_AnyCost.Text("alpha"):SetFloat(0)
  e_AnyCost.Sprite("alpha"):SetFloat(0)
  e_CurrencyAmount.Sprite("alpha"):SetFloat(0)
  e_CurrencyAmount.Text("alpha"):SetFloat(0)
  e_IAPCost.Text("alpha"):SetFloat(0)
  for i = 0, numGenes - 1 do
    local geneElement = element:GetElement(element:name() .. "-gene" .. i)
    if geneElement then
      geneElement.Sprite("visible"):SetInt(0)
    end
  end
  e_NewLabel.Sprite("alpha"):SetFloat(0)
  e_NewLabel.Text("alpha"):SetFloat(0)
  c_LevelReq("visible"):SetInt(0)
  c_MonsterCount("visible"):SetInt(0)
  c_Touch("enabled"):SetInt(0)
  StoreItem.hideSale(element)
  e_TempAvailText.AvailableUntil("visible"):SetInt(0)
  e_TempAvailText.TimerText("visible"):SetInt(0)
  if e_QuestSticker then
    e_QuestSticker:GetComponent("Sprite")("visible"):SetInt(0)
  end
  local lock = element:GetElement("ItemLock")
  if lock then
    element:RemoveElement(lock)
  end
  element.fader:Hide()
end
function StoreItem.showItem(element)
  c_Sprite("visible"):SetInt(1)
  e_TitleFrame.Text("visible"):SetInt(1)
  e_MonsterAnim.Sprite("visible"):SetInt(1)
  if element("maxAmount"):GetInt() ~= 0 then
    c_MaxAmount("visible"):SetInt(1)
  end
  if store:Category() ~= game.StoreCategories_TYPE_CURRENCY or element:name() == "currencyExchange" or element:name() == "diamondsToEthCurrencyExchange" or element:name() == "diamondsToRelicsCurrencyExchange" then
    e_AnyCost.Text("alpha"):SetFloat(1)
    e_AnyCost.Sprite("alpha"):SetFloat(1)
  else
    e_IAPCost.Text("alpha"):SetFloat(1)
  end
  element.CurrencyAmount.Sprite("alpha"):SetFloat(1)
  element.CurrencyAmount.Text("alpha"):SetFloat(1)
  for i = 0, numGenes - 1 do
    local geneElement = element:GetElement(element:name() .. "-gene" .. i)
    if geneElement then
      geneElement.Sprite("visible"):SetInt(1)
    end
  end
  e_NewLabel.Sprite("alpha"):SetFloat(1)
  e_NewLabel.Text("alpha"):SetFloat(1)
  element.monsterCount("visible"):SetInt(1)
  if element.touchEnabled then
    element.Touch("enabled"):SetInt(1)
  end
  StoreItem.showSale(element)
  if element("TimedAvailabilityOn"):GetInt() == 1 or element("TimedUnavailabilityOn"):GetInt() == 1 then
    e_TempAvailText.AvailableUntil("visible"):SetInt(1)
    e_TempAvailText.TimerText("visible"):SetInt(1)
  end
  if element("isLocked"):GetInt() == 1 then
    StoreItem.setLocked(element)
  end
  if e_QuestSticker then
    e_QuestSticker:GetComponent("Sprite")("visible"):SetInt(1)
  end
  element.fader.delayOnShow = 0
  element.fader:Show()
end
function StoreItem.hideSale(element)
  local isLocked = element("isLocked"):GetInt() == 1
  if not isLocked and (store:SaleAmount(element("ID"):GetInt()) ~= 0 or element("TimedSaleOn"):GetInt() == 1) then
    e_TempAvailText.AvailableUntil("visible"):SetInt(0)
    e_TempAvailText.TimerText("visible"):SetInt(0)
  end
  if e_SaleTag then
    e_SaleTag:DoStoredScript("hide")
  end
end
function StoreItem.showSale(element)
  local isLocked = element("isLocked"):GetInt() == 1
  if store:SaleAmount(element("ID"):GetInt()) ~= 0 or element("TimedSaleOn"):GetInt() == 1 or element("1LeftIAP"):GetInt() == 1 then
    if not isLocked then
      e_TempAvailText.AvailableUntil("visible"):SetInt(element("displayWhiteGreenTextAtBottom"):GetInt())
      e_TempAvailText.TimerText("visible"):SetInt(element("displayWhiteGreenTextAtBottom"):GetInt())
    else
      local availUntil = e_TempAvailText.AvailableUntil
      availUntil("visible"):SetInt(element("displayWhiteGreenTextAtBottom"):GetInt())
      availUntil:setColor(availUntil("red"):GetFloat() * 0.5, availUntil("green"):GetFloat() * 0.5, availUntil("blue"):GetFloat() * 0.5)
      local timerText = e_TempAvailText.TimerText
      timerText("visible"):SetInt(element("displayWhiteGreenTextAtBottom"):GetInt())
      timerText:setColor(timerText("red"):GetFloat() * 0.5, timerText("green"):GetFloat() * 0.5, timerText("blue"):GetFloat() * 0.5)
    end
  end
  if e_SaleTag then
    if not isLocked then
      e_SaleTag:DoStoredScript("show")
    else
      e_SaleTag:DoStoredScript("showDisabled")
    end
  end
end
return StoreItem
