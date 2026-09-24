local BOMHelpers = {}
local hasTitansoulInNursery = function()
  local idx = 0
  local nursery = game.FindNursery(idx)
  while nursery do
    local monsterId = nursery:getMonsterInEgg()
    if monsterId > 0 then
      local monsterData = game.getMonsterData(monsterId)
      if monsterData and monsterData:isTitansoul() then
        return true
      end
    end
    idx = idx + 1
    nursery = game.FindNursery(idx)
  end
  return false
end
function BOMHelpers.BuyPriceOnInit(element)
  local monsterId = element:root():GetElement("SelectedMonsterView")("selectedMonst"):GetInt()
  local monsterData = game.getMonsterData(monsterId)
  local entId = game.monsterTypeEntityId(monsterId)
  if game.currentIslandType() ~= game.getBookOfMonstersIslandType() then
    element:parent():DoStoredScript("setBuyInvis")
  elseif game.IsBoxFromEntityId(entId) and game.getBookOfMonstersIslandType() == game.IslandType_AMBER then
    element:parent():DoStoredScript("setBuyInvis")
  elseif game.IsBoxFromEntityId(entId) and not game.monsterTypeIsZapMonster(monsterId) and game.showBoxMonsterContextButton() then
    element:parent():DoStoredScript("setBuyInvis")
  elseif game.IsBoxFromEntityId(entId) and not game.monsterTypeIsZapMonster(monsterId) and not game.hasRoomForBoxMonsterEgg(entId) then
    element:parent():DoStoredScript("setBuyInvis")
  elseif game.getBookOfMonstersIslandType() ~= game.IslandType_ETHEREAL_WORKSHOP and game.monsterIsEvolvedMonster(monsterId) then
    element:parent():DoStoredScript("setBuyInvis")
  elseif game.getBookOfMonstersIslandType() == game.IslandType_ETHEREAL_WORKSHOP and game.monsterIsEvolvedMonster(monsterId) and not game.monsterLimitedAvailability(monsterId, false) and not game.monsterLimitedAvailability(monsterId, true) then
    element:parent():DoStoredScript("setBuyInvis")
  elseif game.isAmberIsland(game.getBookOfMonstersIslandType()) and (game.isRare(monsterId) or game.isEpic(monsterId)) then
    element:parent():DoStoredScript("setBuyInvis")
  elseif game.getBookOfMonstersIslandType() == game.IslandType_GOLD then
    element:parent():DoStoredScript("setBuyInvis")
  elseif game.isMagicalNexus(game.getBookOfMonstersIslandType()) then
    element:parent():DoStoredScript("setBuyInvis")
  elseif monsterData:isTitansoul() and (game.player():getIslandWithId(game.currentIsland()):monsterTypeCount(monsterId) > 0 or hasTitansoulInNursery() or not game.player():canAwakenAnyIslandWithType(monsterData:requiredAwakenedIsland())) then
    element:parent():DoStoredScript("setBuyInvis")
  else
    local finalCost
    local originalCost = 0
    local currencySprite
    local relicCost = game.entityRelicCost(entId)
    local keyCost = game.entityKeyCost(entId)
    local medalCost = game.entityMedalCost(entId)
    local diamondCost = game.entityDiamondCost(entId)
    if game.monsterIsAvail(monsterId, false) then
      if relicCost ~= 0 then
        finalCost = relicCost
        originalCost = game.entityRelicCost(entId, false)
        currencySprite = game.StoreContext_getSpriteFromCurrencyTypeStr("relics")
      elseif keyCost ~= 0 then
        finalCost = keyCost
        originalCost = game.entityKeyCost(entId, false)
        currencySprite = game.StoreContext_getSpriteFromCurrencyTypeStr("key")
      elseif medalCost ~= 0 then
        finalCost = medalCost
        originalCost = game.entityMedalCost(entId, false)
        currencySprite = game.StoreContext_getSpriteFromCurrencyTypeStr("medals")
      elseif diamondCost ~= 0 then
        finalCost = diamondCost
        originalCost = game.entityDiamondCost(entId, false)
        currencySprite = game.StoreContext_getSpriteFromCurrencyTypeStr("diamond")
      else
        finalCost = game.entitySecondaryCurrencyCost(entId)
        originalCost = game.entitySecondaryCurrencyCost(entId, false)
        currencySprite = game.islandCurrencySprite()
      end
    else
      finalCost = game.entityStarCost(entId)
      originalCost = game.entityStarCost(entId, false)
      currencySprite = game.StoreContext_getSpriteFromCurrencyTypeStr("starpower")
    end
    element.CurrencySprite("spriteName"):SetString(currencySprite)
    element.CurrencySprite("sheetName"):SetString(game.StoreContext_CURRENCY_SPRITESHEET)
    if originalCost ~= finalCost then
      element.Text("text"):SetString(game.localizeInt(originalCost))
      element:parent().SaleTag.Text("text"):SetString(finalCost)
      element:parent().SaleTag.Text("visible"):SetInt(1)
      element:parent().Strikeout.Sprite("visible"):SetInt(1)
      element:parent().SaleTag.Sprite("visible"):SetInt(1)
      element:parent().Strikeout.Sprite:DoStoredScript("refresh")
    else
      element.Text("text"):SetString(game.localizeInt(finalCost))
      element:parent().SaleTag.Text("visible"):SetInt(0)
      element:parent().Strikeout.Sprite("visible"):SetInt(0)
      element:parent().SaleTag.Sprite("visible"):SetInt(0)
    end
  end
end
return BOMHelpers
