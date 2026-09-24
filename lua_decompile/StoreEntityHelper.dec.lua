local ColourPalette = include("ColourPalette")
local Currencies = include("Currencies")
local StoreEntityHelper = {}
local currencyProperties = {}
local defaultWhiteColor = function(component)
  component:setColor(1, 1, 1)
end
local defaultProps = {
  spriteName = "empty",
  spriteSheet = "xml_resources/empty.xml",
  setColorFn = defaultWhiteColor
}
local function makeSetColor(color)
  local r, g, b = ColourPalette:getRGBFloats(color)
  return function(component)
    component:setColor(r, g, b)
  end
end
local function makeProps(currencyType)
  local props = Currencies:getProps(currencyType)
  return {
    spriteName = props.sprite,
    spriteSheet = props.sheet,
    setColorFn = makeSetColor(props.color)
  }
end
currencyProperties[game.StoreContext_TYPE_DIAMOND] = makeProps(game.CurrencyType_Diamonds)
currencyProperties[game.StoreContext_TYPE_ETH_CURRENCY] = makeProps(game.CurrencyType_Shards)
currencyProperties[game.StoreContext_TYPE_COINS] = makeProps(game.CurrencyType_Coins)
currencyProperties[game.StoreContext_TYPE_FOOD] = makeProps(game.CurrencyType_Food)
currencyProperties[game.StoreContext_TYPE_STARPOWER] = makeProps(game.CurrencyType_Starpower)
currencyProperties[game.StoreContext_TYPE_KEYS] = makeProps(game.CurrencyType_Keys)
currencyProperties[game.StoreContext_TYPE_RELICS] = makeProps(game.CurrencyType_Relics)
currencyProperties[game.StoreContext_TYPE_MEDALS] = makeProps(game.CurrencyType_Medals)
currencyProperties[game.StoreContext_TYPE_XP] = makeProps(game.CurrencyType_Xp)
currencyProperties[game.StoreContext_TYPE_BATTLE_XP] = makeProps(game.CurrencyType_BattleXp)
currencyProperties[game.StoreContext_TYPE_EGG_WILDCARD] = makeProps(game.CurrencyType_EggWildcards)
currencyProperties[game.StoreContext_TYPE_CLUBBOX_TOKENS] = makeProps(game.CurrencyType_ClubboxTokens)
currencyProperties[game.StoreContext_TYPE_MINIGAME_TOKENS] = makeProps(game.CurrencyType_MinigameTokens)
currencyProperties.COSTUME_CREDITS = defaultProps
currencyProperties.INVENTORY = defaultProps
function StoreEntityHelper.GetCurrencyProperties(currencyType)
  return currencyProperties[currencyType]
end
function StoreEntityHelper.GetCurrencySprite(currencyType)
  return currencyProperties[currencyType].spriteName
end
function StoreEntityHelper.GetCurrencyColorSetter(currencyType)
  return currencyProperties[currencyType].setColorFn
end
function StoreEntityHelper.GetStoreEntityInfo(entityId, inStarMarket)
  local storeInfo = {}
  local function setPrice(price, currencyType)
    storeInfo.price = price
    storeInfo.currency = currencyType
    storeInfo.currencyProperties = currencyProperties[currencyType]
  end
  local inventoryAmount = game.getInventoryAmount(entityId)
  if inventoryAmount > 0 then
    setPrice(inventoryAmount, "INVENTORY")
    return storeInfo
  end
  if inStarMarket then
    setPrice(game.entityStarCost(entityId), game.StoreContext_TYPE_STARPOWER)
    return storeInfo
  end
  local relicCost = game.entityRelicCost(entityId)
  if relicCost > 0 then
    setPrice(relicCost, game.StoreContext_TYPE_RELICS)
    return storeInfo
  end
  local keyCost = game.entityKeyCost(entityId)
  if keyCost > 0 then
    setPrice(keyCost, game.StoreContext_TYPE_KEYS)
    return storeInfo
  end
  local medalCost = game.entityMedalCost(entityId)
  if medalCost > 0 then
    setPrice(medalCost, game.StoreContext_TYPE_MEDALS)
    return storeInfo
  end
  local diamondCost = game.entityDiamondCost(entityId)
  if diamondCost > 0 then
    setPrice(diamondCost, game.StoreContext_TYPE_DIAMOND)
    return storeInfo
  end
  local secondaryCurrencyCost = game.entitySecondaryCurrencyCost(entityId)
  if game.isEtherealIsland() then
    setPrice(secondaryCurrencyCost, game.StoreContext_TYPE_ETH_CURRENCY)
  else
    setPrice(secondaryCurrencyCost, game.StoreContext_TYPE_COINS)
  end
  return storeInfo
end
function StoreEntityHelper.GetStoreMonsterInfo(monsterId)
  local entityId = game.monsterTypeEntityId(monsterId)
  return StoreEntityHelper.GetStoreEntityInfo(entityId)
end
function StoreEntityHelper.UpdatePriceUI(element, info, extra)
  extra = extra or {}
  local spriteComponent = element:GetComponent(extra.sprite or "Sprite")
  local textComponent = element:GetComponent(extra.text or "Text")
  StoreEntityHelper.UpdatePriceUIComponents(spriteComponent, textComponent, info)
end
function StoreEntityHelper.UpdatePriceUIComponents(spriteComponent, textComponent, info)
  spriteComponent("spriteName"):SetString(info.currencyProperties.spriteName)
  spriteComponent("sheetName"):SetString(info.currencyProperties.spriteSheet)
  if info.currency == "COSTUME_CREDITS" or info.currency == "INVENTORY" then
    local text = LOC("COSTUME_FREE_CREDITS")
    text = text:gsub("%${CREDITS}", info.price)
    textComponent("text"):SetString(text)
  else
    textComponent("text"):SetString(game.commaizeNumber(info.price))
  end
  info.currencyProperties.setColorFn(textComponent)
end
function StoreEntityHelper.GetCostumeStoreInfo(costumeId)
  local priceInfo = {}
  local function setPrice(price, currencyType, table)
    table.price = price
    table.currency = currencyType
    table.currencyProperties = currencyProperties[currencyType]
  end
  local function setBasePrice(price, currencyType)
    local basePrice = {}
    setPrice(price, currencyType, basePrice)
    priceInfo.basePrice = basePrice
  end
  local function setSalePrice(price, currencyType)
    local salePrice = {}
    setPrice(price, currencyType, salePrice)
    priceInfo.salePrice = salePrice
  end
  local isUnlocked = game.isCostumeUnlocked(costumeId)
  if isUnlocked or not game.isBattleIsland() then
    local credits = game.getCostumeCredit(costumeId)
    if credits > 0 then
      setBasePrice(credits, "COSTUME_CREDITS")
      return priceInfo
    end
    priceInfo.locked = 0
    local isSaleOn = game.hasCostumeSaleActive(costumeId)
    if isSaleOn then
      local saleTime = game.timedSaleCostumeTimeRemaining(costumeId, 0)
      if saleTime == 0 then
        isSaleOn = false
      end
    end
    local costumeData = game.getCostumeData(costumeId)
    if game.isBattleIsland() then
      local diamondCost = costumeData.diamondCost
      if diamondCost > 0 then
        setBasePrice(diamondCost, game.StoreContext_TYPE_DIAMOND)
        if isSaleOn then
          setSalePrice(game.getCostumePriceDiamonds(costumeId), game.StoreContext_TYPE_DIAMOND)
        end
      else
        setBasePrice(costumeData.medalCost, game.StoreContext_TYPE_MEDALS)
        if isSaleOn then
          setSalePrice(game.getCostumePriceMedals(costumeId), game.StoreContext_TYPE_MEDALS)
        end
      end
    elseif 0 < costumeData.diamondCost then
      local diamondCost = costumeData.diamondCost
      if costumeData.ignoreLocks == 0 and costumeData.isPurchaseLocked == false then
        diamondCost = math.floor(diamondCost * game.costumeBuyNowMultiplier())
      end
      setBasePrice(diamondCost, game.StoreContext_TYPE_DIAMOND)
      if isSaleOn or isUnlocked and costumeData.ignoreLocks == 0 and costumeData.isPurchaseLocked == false then
        local salePrice = game.getCostumePriceDiamonds(costumeId)
        if not isUnlocked then
          salePrice = math.floor(salePrice * game.costumeBuyNowMultiplier())
        end
        setSalePrice(salePrice, game.StoreContext_TYPE_DIAMOND)
      end
    elseif 0 < costumeData.action then
      local diamondCost = game.costumeMedalsToDiamonds(costumeData.medalCost)
      if costumeData.ignoreLocks == 0 and costumeData.isPurchaseLocked == false then
        diamondCost = math.floor(diamondCost * game.costumeBuyNowMultiplier())
      end
      setBasePrice(diamondCost, game.StoreContext_TYPE_DIAMOND)
      if isSaleOn or isUnlocked and costumeData.ignoreLocks == 0 and costumeData.isPurchaseLocked == false then
        local salePrice = game.costumeMedalsToDiamonds(game.getCostumePriceMedals(costumeId))
        if not isUnlocked then
          salePrice = math.floor(salePrice * game.costumeBuyNowMultiplier())
        end
        setSalePrice(salePrice, game.StoreContext_TYPE_DIAMOND)
      end
    else
      local secondaryCurrencyType = game.StoreContext_TYPE_COINS
      if game.isEtherealIsland() then
        secondaryCurrencyType = game.StoreContext_TYPE_ETH_CURRENCY
      end
      local secondaryCurrencyCost = game.costumeMedalsToCoins(costumeData.medalCost)
      if game.isEtherealIsland() then
        if game.costumeMedalsToShards then
          secondaryCurrencyCost = game.costumeMedalsToShards(costumeData.medalCost)
        else
          secondaryCurrencyCost = math.floor(costumeData.medalCost * 0.25)
        end
      end
      if costumeData.ignoreLocks == 0 and costumeData.isPurchaseLocked == false then
        secondaryCurrencyCost = math.floor(secondaryCurrencyCost * game.costumeBuyNowMultiplier())
      end
      setBasePrice(secondaryCurrencyCost, secondaryCurrencyType)
      if isSaleOn or isUnlocked and costumeData.ignoreLocks == 0 and costumeData.isPurchaseLocked == false then
        local salePriceMedals = game.getCostumePriceMedals(costumeId)
        local salePrice = game.costumeMedalsToCoins(salePriceMedals)
        if game.isEtherealIsland() then
          if game.costumeMedalsToShards then
            salePrice = game.costumeMedalsToShards(salePriceMedals)
          else
            salePrice = math.floor(salePriceMedals * 0.25)
          end
        end
        if not isUnlocked then
          salePrice = math.floor(salePrice * game.costumeBuyNowMultiplier())
        end
        setSalePrice(salePrice, secondaryCurrencyType)
      end
    end
  else
    priceInfo.locked = 1
    print("Costume is locked:", costumeId)
  end
  return priceInfo
end
return StoreEntityHelper
