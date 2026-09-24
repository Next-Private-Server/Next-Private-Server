local Currencies = require("Currencies")
local PopupCollectAll = {
  messageID = "COLLECT_ALL",
  transitionState = 1,
  transitionTime = 0,
  choice = "none",
  FadedBG = {
    Sprite = {}
  },
  bg = {},
  TitleFrame = {},
  TitleLabel = {
    Text = {}
  },
  Sprite = {},
  Notification = {
    Text = {}
  },
  CoinAmount = {
    Icon = {},
    AnimatedIcon = {},
    Text = {}
  },
  PlusBonus = {
    Text = {},
    PlusText = {}
  },
  FoodAmount = {
    Icon = {},
    Text = {}
  },
  EthAmount = {
    Icon = {},
    Text = {}
  },
  DiamondsAmount = {
    Icon = {},
    Text = {}
  },
  KeysAmount = {
    Icon = {},
    Text = {}
  },
  MysteryCoinAmount = {
    Icon = {},
    Text = {}
  },
  YesButton = {},
  NoButton = {}
}
function PopupCollectAll:onInit()
  self.transitionState = 1
  self.transitionTime = 0
  self.choice = "none"
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function PopupCollectAll:onPostInit()
  self.CoinAmount.Text("text"):SetString(game.commaizeNumber(game.approxCollectAllAmt()))
  local isMinorPaironormal = false
  local islandCollectType = game.CurrencyType_Coins
  if game.isEtherealIsland() then
    islandCollectType = game.CurrencyType_Shards
  elseif game.isAmberIsland() then
    islandCollectType = game.CurrencyType_Relics
  elseif game.isPaironormalIsland() then
    local island = game.player():getActiveIsland()
    if island then
      if island:islandMode() == 0 then
        islandCollectType = game.CurrencyType_Starpower
      else
        isMinorPaironormal = true
        islandCollectType = game.CurrencyType_EggWildcards
      end
    end
  end
  local currencyProps = Currencies:getProps(islandCollectType)
  currencyProps:applyToText(self.CoinAmount.Text)
  currencyProps:applyToSpriteSheet(self.CoinAmount.Icon)
  currencyProps:normalizeSizeW(self.CoinAmount.Icon, 0.35 * game.hudScale())
  if isMinorPaironormal then
    self.CoinAmount.AnimatedIcon("animationName"):SetString("xml_bin/Relic_confetti01.bin")
    self.CoinAmount.AnimatedIcon("animation"):SetString("wild card rotation")
  end
  local function initCurrency(e, currencyType)
    local currencyProps = Currencies:getProps(currencyType)
    local spriteSheet = e:C("Icon")
    currencyProps:applyToSpriteSheet(spriteSheet)
    currencyProps:normalizeSizeW(spriteSheet, 0.35 * game.hudScale())
    currencyProps:applyToText(e:C("Text"))
  end
  initCurrency(self.FoodAmount, game.CurrencyType_Food)
  initCurrency(self.EthAmount, game.CurrencyType_Shards)
  initCurrency(self.DiamondsAmount, game.CurrencyType_Diamonds)
  initCurrency(self.KeysAmount, game.CurrencyType_Keys)
  initCurrency(self.MysteryCoinAmount, game.CurrencyType_Coins)
end
function PopupCollectAll:onTick(dt)
  if self.transitionState ~= 0 then
    self:TickTransition()
    if self.transitionState == 1 then
      self.transitionTime = self.transitionTime + dt * 3
    elseif self.transitionState == 2 then
      self.transitionTime = self.transitionTime - dt * 3
    end
    self.transitionTime = clamp(self.transitionTime, 0, 1)
    if 1 <= self.transitionTime then
      self.transitionState = 0
      self.transitionTime = 1
      self:TickTransition()
    elseif 0 >= self.transitionTime then
      if self.choice == "true" then
        self:root():popPopUp()
        game.submitConfirmation(self.messageID, true)
      else
        self:root():popPopUp()
        game.submitConfirmation(self.messageID, false)
      end
    end
  end
end
function PopupCollectAll:TickTransition()
  self.bg:V("xOffset"):SetFloat(lua_sys.screenWidth() * 0.5 + -0.5 * lua_sys.screenWidth() * (1 / math.max(0.001, self.transitionTime)))
  self.FadedBG.Sprite:V("alpha"):SetFloat(self.transitionTime * 0.5)
end
function PopupCollectAll:queuePop()
  self.transitionState = 2
end
local currencyOffset = 20 * game.hudScale()
function PopupCollectAll:setCoinOnly()
  print("run setCoinOnly")
  self.CoinAmount.Text:V("visible"):SetInt(1)
  self.CoinAmount.Icon:V("visible"):SetInt(1)
  self.CoinAmount:setParent(self)
  self.CoinAmount:relativeTo(self.Notification)
  self.CoinAmount:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.BOTTOM)
  self.CoinAmount:setOrientation(lua_sys.MenuOrientation(0, currencyOffset, 0, lua_sys.HCENTER, lua_sys.TOP))
end
function PopupCollectAll:setCoinAndBonus()
  print("run setCoinAndBonus")
  self.PlusBonus:V("yOffset"):SetInt(currencyOffset)
  self.PlusBonus.PlusText:V("visible"):SetInt(1)
  self.PlusBonus.Text:V("visible"):SetInt(1)
  self.CoinAmount.Text:V("visible"):SetInt(1)
  self.CoinAmount.Icon:V("visible"):SetInt(1)
  self.CoinAmount:setParent(self)
  self.CoinAmount:relativeTo(self.PlusBonus)
  self.CoinAmount:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.VCENTER)
  self.CoinAmount:setOrientation(lua_sys.MenuOrientation(16 * game.hudScale(), 0, 0, lua_sys.RIGHT, lua_sys.VCENTER))
end
function PopupCollectAll:setAnimatedCoinOnly()
  print("run setAnimatedCoinOnly")
  self.CoinAmount.Text:V("visible"):SetInt(1)
  self.CoinAmount.AnimatedIcon:V("visible"):SetInt(1)
  self.CoinAmount:setParent(self)
  self.CoinAmount:relativeTo(self.Notification)
  self.CoinAmount:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.BOTTOM)
  self.CoinAmount:setOrientation(lua_sys.MenuOrientation(0, currencyOffset, 0, lua_sys.HCENTER, lua_sys.TOP))
end
function PopupCollectAll:setRandomCurrencyUnderling()
  print("run setRandomCurrencyUnderling")
  self.CoinAmount:V("yOffset"):SetInt(currencyOffset)
  self.FoodAmount:V("yOffset"):SetInt(currencyOffset)
  self.FoodAmount.Text:V("visible"):SetInt(1)
  self.FoodAmount.Icon:V("visible"):SetInt(1)
  self.EthAmount.Text:V("visible"):SetInt(1)
  self.EthAmount.Icon:V("visible"):SetInt(1)
  self.DiamondsAmount.Text:V("visible"):SetInt(1)
  self.DiamondsAmount.Icon:V("visible"):SetInt(1)
  self.MysteryCoinAmount.Text:V("visible"):SetInt(1)
  self.MysteryCoinAmount.Icon:V("visible"):SetInt(1)
end
function PopupCollectAll:setRandomCurrencyCelestial()
  print("run setRandomCurrencyCelestial")
  self.CoinAmount:V("yOffset"):SetInt(currencyOffset)
  self.FoodAmount.Text:V("visible"):SetInt(1)
  self.FoodAmount.Icon:V("visible"):SetInt(1)
  self.EthAmount.Text:V("visible"):SetInt(1)
  self.EthAmount.Icon:V("visible"):SetInt(1)
  self.DiamondsAmount.Text:V("visible"):SetInt(1)
  self.DiamondsAmount.Icon:V("visible"):SetInt(1)
  self.KeysAmount.Text:V("visible"):SetInt(1)
  self.KeysAmount.Icon:V("visible"):SetInt(1)
  self.MysteryCoinAmount.Text:V("visible"):SetInt(1)
  self.MysteryCoinAmount.Icon:V("visible"):SetInt(1)
  self.FoodAmount:V("yOffset"):SetInt(currencyOffset)
  self.FoodAmount:V("xOffset"):SetInt((self.KeysAmount:V("xOffset"):GetInt() + self.KeysAmount.Icon:size().x + self.KeysAmount.Text:size().x) / 2)
end
return PopupCollectAll
