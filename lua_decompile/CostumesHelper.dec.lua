local CostumesHelper = {}
function CostumesHelper.GetFilteredCostumes(uniqueMonsterId)
  return game.getCostumeIdsForMonster(uniqueMonsterId)
end
function CostumesHelper.GetPurchaseType(costumeId)
  local costumeData = game.getCostumeData(costumeId)
  if game.isBattleIsland() then
    if costumeData.diamondCost > 0 then
      return game.StoreContext_TYPE_DIAMOND
    end
    return game.StoreContext_TYPE_MEDALS
  end
  if costumeData.diamondCost > 0 or 0 < costumeData.action then
    return game.StoreContext_TYPE_DIAMOND
  end
  if game.isEtherealIsland() then
    return game.StoreContext_TYPE_ETH_CURRENCY
  end
  return game.StoreContext_TYPE_COINS
end
function CostumesHelper.GetItemCost(costumeId)
  local costumeData = game.getCostumeData(costumeId)
  if game.isBattleIsland() then
    if costumeData.diamondCost > 0 then
      return costumeData.diamondCost
    else
      return costumeData.medalCost
    end
  else
    local isUnlocked = game.isCostumeUnlocked(costumeId)
    if costumeData.diamondCost > 0 then
      if isUnlocked then
        return costumeData.diamondCost
      else
        return math.floor(costumeData.diamondCost * game.costumeBuyNowMultiplier())
      end
    elseif 0 < costumeData.action then
      if isUnlocked then
        return game.costumeMedalsToDiamonds(costumeData.medalCost)
      else
        return math.floor(game.costumeMedalsToDiamonds(costumeData.medalCost) * game.costumeBuyNowMultiplier())
      end
    else
      local secondaryCurrencyCost = 0
      if game.isEtherealIsland() then
        if game.costumeMedalsToShards then
          secondaryCurrencyCost = game.costumeMedalsToShards(costumeData.medalCost)
        else
          secondaryCurrencyCost = math.floor(costumeData.medalCost * 0.25)
        end
      else
        secondaryCurrencyCost = game.costumeMedalsToCoins(costumeData.medalCost)
      end
      if isUnlocked then
        return secondaryCurrencyCost
      else
        return math.floor(secondaryCurrencyCost * game.costumeBuyNowMultiplier())
      end
    end
  end
end
return CostumesHelper
