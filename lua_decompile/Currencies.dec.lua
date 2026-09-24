local Colors = include("ColourPalette")
local Currencies = {}
local CurrencyProps = {
  type = game.CurrencyType_MAX_NUM_CURRENCIES,
  refId = "",
  sprite = "",
  sheet = "xml_resources/hud01.xml",
  color = Colors.WHITE,
  scaleW = 1,
  scaleH = 1
}
function CurrencyProps:new(obj)
  local obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end
function CurrencyProps:getTextId()
  return self.refId
end
function CurrencyProps:applyToSpriteSheet(spriteSheetComponent)
  spriteSheetComponent("spriteName"):SetString(self.sprite)
  spriteSheetComponent("sheetName"):SetString(self.sheet)
end
function CurrencyProps:applyToText(textComponent)
  local r, g, b = Colors:getRGBFloats(self.color)
  textComponent:setColor(r, g, b)
end
function CurrencyProps:normalizeSizeW(component, scale)
  component("size"):SetFloat(scale * self.scaleW)
end
function CurrencyProps:normalizeSizeH(component, scale)
  component("size"):SetFloat(scale * self.scaleH)
end
local defaultProps = CurrencyProps:new({
  sprite = "empty",
  sheet = "xml_resources/empty.xml"
})
local propsData = {
  [game.CurrencyType_Coins] = {
    type = game.CurrencyType_Coins,
    sprite = "coin",
    color = Colors.COIN_COLOUR,
    refId = "CODE_REWARD_COINS",
    scaleW = 1.03,
    scaleH = 1.03
  },
  [game.CurrencyType_Diamonds] = {
    type = game.CurrencyType_Diamonds,
    sprite = "diamond",
    color = Colors.DIAMOND_COLOUR,
    refId = "CODE_REWARD_DIAMONDS",
    scaleH = 1.03
  },
  [game.CurrencyType_Food] = {
    type = game.CurrencyType_Food,
    sprite = "food",
    color = Colors.FOOD_COLOUR,
    refId = "CODE_REWARD_FOOD"
  },
  [game.CurrencyType_Shards] = {
    type = game.CurrencyType_Shards,
    sprite = "shard",
    color = Colors.SHARD_COLOUR,
    refId = "CODE_REWARD_SHARDS",
    scaleW = 1.03,
    scaleH = 1.03
  },
  [game.CurrencyType_Starpower] = {
    type = game.CurrencyType_Starpower,
    sprite = "starpower",
    color = Colors.STARPOWER_COLOUR,
    refId = "CODE_REWARD_STARPOWER"
  },
  [game.CurrencyType_Keys] = {
    type = game.CurrencyType_Keys,
    sprite = "keys",
    color = Colors.KEY_COLOUR,
    refId = "CODE_REWARD_KEYS"
  },
  [game.CurrencyType_Relics] = {
    type = game.CurrencyType_Relics,
    sprite = "relic",
    color = Colors.RELIC_COLOUR,
    refId = "CODE_REWARD_RELICS",
    scaleH = 1.03
  },
  [game.CurrencyType_Medals] = {
    type = game.CurrencyType_Medals,
    sprite = "medal",
    color = Colors.MEDAL_COLOUR,
    refId = "CODE_REWARD_MEDALS",
    scaleH = 1.03
  },
  [game.CurrencyType_Xp] = {
    type = game.CurrencyType_Xp,
    sprite = "xp",
    color = Colors.XP_COLOUR,
    refId = "CODE_REWARD_XP",
    scaleH = 1.03
  },
  [game.CurrencyType_BattleXp] = {
    type = game.CurrencyType_BattleXp,
    sprite = "battle_xp",
    color = Colors.BATTLE_XP_COLOUR,
    refId = "CODE_REWARD_BATTLE_XP",
    scaleH = 1.03
  },
  [game.CurrencyType_EggWildcards] = {
    type = game.CurrencyType_EggWildcards,
    sprite = "wildcard",
    color = Colors.EGGWILDCARD_COLOUR,
    refId = "CODE_REWARD_WILDCARDS",
    scaleW = 1.03,
    scaleH = 1.03
  },
  [game.CurrencyType_ClubboxTokens] = {
    type = game.CurrencyType_ClubboxTokens,
    sprite = "clubbox_token",
    color = Colors.CLUBBOX_TOKEN_COLOUR,
    refId = "CLUBBOX_TOKENS"
  },
  [game.CurrencyType_ClubboxUnlock] = {
    type = game.CurrencyType_ClubboxUnlock,
    refId = "CODE_REWARD_CLUBBOX_UNLOCK"
  },
  [game.CurrencyType_CardPack] = {
    type = game.CurrencyType_CardPack,
    sprite = "button_sticker",
    sheet = "xml_resources/context_buttons.xml",
    refId = "CODE_REWARD_CARD_PACK"
  },
  [game.CurrencyType_MinigameTokens] = {
    type = game.CurrencyType_MinigameTokens,
    sprite = "mini_game_token",
    sheet = "xml_resources/hud03.xml",
    color = Colors.MINIGAME_TOKEN_COLOUR,
    refId = "MINIGAME_TOKENS"
  }
}
local properties = {}
for currencyType, data in pairs(propsData) do
  properties[currencyType] = CurrencyProps:new(data)
end
function Currencies:getProps(currencyType)
  return properties[currencyType] or defaultProps
end
function Currencies:applySheetProps(spriteSheetComponent, currencyType)
  local props = properties[currencyType]
  if not props then
    assert(false, "CurrencyProps not found for", currencyType)
    props = defaultProps
  end
  props:applyToSpriteSheet(spriteSheetComponent)
end
function Currencies:applyTextProps(textComponent, currencyType)
  local props = properties[currencyType]
  if not props then
    assert(false, "CurrencyProps not found for", currencyType)
    props = defaultProps
  end
  props:applyToText(textComponent)
end
return Currencies
