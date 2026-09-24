local SuggestedPromptPurchaseTypes = {
  supportedPurchaseTypes = {
    [game.PurchaseType_AWAKEN] = {},
    [game.PurchaseType_AWAKEN_EARLY] = {},
    [game.PurchaseType_BAKE_FOOD] = {},
    [game.PurchaseType_BIGGIFY_PERMA] = {},
    [game.PurchaseType_CLEAR_OBSTACLE] = {},
    [game.PurchaseType_COSTUME_PURCHASE] = {},
    [game.PurchaseType_COSTUMED_MONSTER_PURCHASE] = {},
    [game.PurchaseType_DECO_PURCHASE] = {},
    [game.PurchaseType_FEED_MONSTER] = {},
    [game.PurchaseType_FEED_MONSTER_breed_menu] = {},
    [game.PurchaseType_FILL_INVENTORY] = {},
    [game.PurchaseType_ISLAND_PURCHASE] = {},
    [game.PurchaseType_ISLAND_THEME_PURCHASE] = {},
    [game.PurchaseType_MONSTER_PURCHASE] = {},
    [game.PurchaseType_SPEEDUP_amber_evolve] = {},
    [game.PurchaseType_SPEEDUP_attuner] = {},
    [game.PurchaseType_SPEEDUP_bakery] = {},
    [game.PurchaseType_SPEEDUP_battle_train] = {},
    [game.PurchaseType_SPEEDUP_breeding] = {},
    [game.PurchaseType_SPEEDUP_build_obj] = {},
    [game.PurchaseType_SPEEDUP_destroy_obs] = {},
    [game.PurchaseType_SPEEDUP_dish_harm] = {},
    [game.PurchaseType_SPEEDUP_fuze] = {},
    [game.PurchaseType_SPEEDUP_fugue] = {},
    [game.PurchaseType_SPEEDUP_getitnow_attuner] = {},
    [game.PurchaseType_SPEEDUP_getitnow_breed] = {},
    [game.PurchaseType_SPEEDUP_getitnow_eggcup] = {},
    [game.PurchaseType_SPEEDUP_getitnow_incubate] = {},
    [game.PurchaseType_SPEEDUP_getitnow_synthesizer] = {},
    [game.PurchaseType_SPEEDUP_getitnow_fugue] = {},
    [game.PurchaseType_SPEEDUP_nursery] = {},
    [game.PurchaseType_SPEEDUP_synthesizer] = {},
    [game.PurchaseType_STRUCTURE_PURCHASE] = {},
    [game.PurchaseType_STARSTORE_PURCHASE] = {},
    [game.PurchaseType_TORCH_LIGHT_PERMA] = {},
    [game.PurchaseType_TRIBAL_FEED_MONSTER] = {},
    [game.PurchaseType_UPGRADE_OBJECT] = {},
    [game.PurchaseType_CLUBBOX_TOKENS_NOT_ENOUGH] = {groupOverride = 2},
    [game.PurchaseType_MINIGAME_TOKENS_NOT_ENOUGH] = {groupOverride = 2},
    [game.PurchaseType_MINIGAME_BONUS_DIAMONDS_NOT_ENOUGH] = {}
  },
  supportedCurrencyTypes = {
    [game.CurrencyType_Diamonds] = {},
    [game.CurrencyType_Coins] = {},
    [game.CurrencyType_Food] = {},
    [game.CurrencyType_ClubboxTokens] = {},
    [game.CurrencyType_MinigameTokens] = {}
  }
}
function SuggestedPromptPurchaseTypes:SuggestedCurrencyPackSupported(purchaseType, currencyType, amountNeeded)
  local data = self.supportedPurchaseTypes[purchaseType]
  local groupOverride = data and data.groupOverride or -1
  local isSupported = self:IsSuggestedPackPurchase(purchaseType) and self:IsSupportedCurrency(currencyType)
  return isSupported, groupOverride
end
function SuggestedPromptPurchaseTypes:IsSuggestedPackPurchase(purchaseType)
  return self.supportedPurchaseTypes[purchaseType] ~= nil
end
function SuggestedPromptPurchaseTypes:IsSupportedCurrency(currencyType)
  return self.supportedCurrencyTypes[currencyType] ~= nil
end
return SuggestedPromptPurchaseTypes
