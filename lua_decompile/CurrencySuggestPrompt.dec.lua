local Currencies = require("Currencies")
local CurrencySuggestPrompt = {
  FadedBG = {},
  bg = {},
  CloseButton = {
    Touch = {}
  },
  TitleFrame = {},
  TitleLabel = {},
  NotificationTop = {
    Text = {}
  },
  CurrencyAnim = {
    Sprite = {}
  },
  ValueSticker = {},
  NotificationBottom = {
    Text = {}
  },
  Timer = {
    Text = {}
  },
  BuyButton = {
    Text = {},
    Touch = {}
  },
  StoreButton = {
    Touch = {}
  },
  transitionState = 1,
  transitionTime = 0,
  choice = 0,
  showStoreButton = 1,
  storeId = 0,
  currencyType = game.CurrencyType_MAX_NUM_CURRENCIES,
  promo = nil,
  sale = nil,
  timedAvailability = nil,
  bundleLootTypeId = -1,
  lastTimeRemainingVal = -1,
  metricID = "",
  showCloseBtn = false,
  delayCloseTime = 2
}
function CurrencySuggestPrompt:onInit()
  self.CloseButton:disable()
  self.CloseButton:setInvisible()
  self.delayCloseTime = tonumber(os.time() + self.delayCloseTime)
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function CurrencySuggestPrompt:populate()
  self.storeId = self("storeId"):GetInt()
  self.currencyType = self("currencyType"):GetInt()
  self.showStoreButton = self("showStoreButton"):GetInt()
  self.metricID = self("metricID"):GetString()
  self.promo = game.getPromoFromStoreItemId(self.storeId)
  self.sale = game.getCurrencySaleFromStoreItemId(self.storeId)
  self.timedAvailability = game.getCurrencyAvailabilityFromStoreItemId(self.storeId)
  self.isBundle = game.isStoreItemBundle(self.storeId)
  self.bundleLootTypeId = self("bundleLootTypeId"):GetInt()
  self:initValues()
  self:initPositioning()
end
function CurrencySuggestPrompt:initButtons()
  self.BuyButton.Text("text"):SetString(game.priceStr(self.storeId))
  if self.showStoreButton == 0 then
    self.StoreButton:setInvisible()
    self.BuyButton("xOffset"):SetInt(0)
  end
end
function CurrencySuggestPrompt:initValues()
  local currencyProps = Currencies:getProps(self.currencyType)
  currencyProps:applyToText(self.CurrencyAmount.Text)
  currencyProps:applyToText(self.OldCurrencyAmount.Text)
  self:initButtons()
  local currencyTypeStrId = currencyProps:getTextId()
  local topText, bottomText
  if self.showStoreButton == 1 then
    topText = "CURRENCY_SUGGESTION_PLUS_DESC_TOP"
    bottomText = "CURRENCY_SUGGESTION_PLUS_DESC_BOTTOM"
  else
    topText = "CURRENCY_SUGGESTION_ONLY_DESC_TOP"
    bottomText = "CURRENCY_SUGGESTION_ONLY_DESC_BOTTOM"
  end
  local topTextLoc = LOC(topText)
  topTextLoc = topTextLoc:gsub("%${COLOR}", currencyProps.color)
  topTextLoc = topTextLoc:gsub("%${CURRENCY}", LOC(currencyTypeStrId))
  self.NotificationTop.Text("text"):SetString(topTextLoc)
  self.NotificationTop.Text("size"):SetFloat(0.3 * game.windowScaleY())
  self.NotificationTop.Text("autoScale"):SetInt(1)
  local bottomTextLoc = LOC(bottomText)
  bottomTextLoc = bottomTextLoc:gsub("%${COLOR}", currencyProps.color)
  bottomTextLoc = bottomTextLoc:gsub("%${CURRENCY}", LOC(currencyTypeStrId))
  self.NotificationBottom.Text("text"):SetString(bottomTextLoc)
  self.NotificationBottom.Text("size"):SetFloat(0.3 * game.windowScaleY())
  self.NotificationBottom.Text("autoScale"):SetInt(1)
  self.CurrencyAnim.Sprite("animationName"):SetString("xml_bin/" .. game.StoreContext_CurrencyItemAnimationFile(self.storeId))
  if self.promo == nil then
    self.CurrencyAnim.Sprite("animation"):SetString(game.StoreContext_CurrencyItemAnimationName(self.storeId))
  else
    local altAnim = game.StoreContext_AltAnimForPromoItemByStoreId(self.storeId)
    if altAnim ~= "" then
      self.CurrencyAnim.Sprite("animation"):SetString(altAnim)
    else
      self.CurrencyAnim.Sprite("animation"):SetString(game.StoreContext_CurrencyItemAnimationName(self.storeId))
    end
  end
  self.CurrencyAmount.Text("text"):SetString(game.commaizeNumber(game.storeValue(self.storeId)))
  currencyProps:applyToSpriteSheet(self.CurrencySprite.Sprite)
  currencyProps:normalizeSizeH(self.CurrencySprite.Sprite, 0.3 * game.windowScaleY())
  if self.sale or self.timedAvailability then
    self.Timer:setVisible()
    if self.sale then
      self.lastTimeRemainingVal = self.sale:timeRemainingSec()
    elseif self.timedAvailability then
      self.lastTimeRemainingVal = self.timedAvailability:timeRemainingSec()
    end
    self.Timer.Text("text"):SetString(game.timeToString(self.lastTimeRemainingVal))
  else
    self.Timer:setInvisible()
  end
  if self.isBundle then
    self.CurrencyAmount.Text("text"):SetString(game.getBundleValue(self.storeId, self.bundleLootTypeId))
    self.OldCurrencyAmount:setInvisible()
  elseif self.promo then
    self.OldCurrencyAmount:setVisible()
    self.OldCurrencyAmount.Text("text"):SetString(game.get1LeftPromoOrigAmount(self.storeId))
  elseif self.sale then
    self.OldCurrencyAmount:setVisible()
    self.CurrencyAmount.Text("text"):SetString(self.sale:getSaleAmount())
    self.OldCurrencyAmount.Text("text"):SetString(game.commaizeNumber(game.storeValue(self.storeId)))
  else
    self.OldCurrencyAmount:setInvisible()
  end
  if game.IsBestValueStoreItem(self.storeId) == true then
    self.ValueSticker:setVisible()
    self.ValueSticker:setBestValue()
  elseif self.timedAvailability then
    self.ValueSticker:setVisible()
    self.ValueSticker:setCurrencyDiscount()
  elseif self.promo then
    self.ValueSticker:setVisible()
    self.ValueSticker:set1Left()
  elseif game.IsMostPopularStoreItem(self.storeId) == true then
    self.ValueSticker:setVisible()
    self.ValueSticker:setMostPopular()
  else
    self.ValueSticker:setInvisible()
  end
  self.metricID = game.serverTime()
  game.logEvent("not_enough_currency_suggest_menu", "action", "init", "metric_id", self.metricID, "store_id", self.storeId, "has_store_button", self.showStoreButton)
end
function CurrencySuggestPrompt:initPositioning()
  local currencyProps = Currencies:getProps(self.currencyType)
  local size = self.CurrencyAmount.Text("size"):GetFloat()
  currencyProps:normalizeSizeH(self.CurrencySprite.Sprite, size)
  local textWidth = self.CurrencyAmount:GetComponent("Text"):absW()
  local totalWidth = textWidth + self.CurrencySprite.Sprite:absW()
  self.CurrencyAmount.Text("xOffset"):SetFloat(-textWidth / 2 + totalWidth / 2)
  self.CurrencySprite.Sprite("xOffset"):SetFloat(-self.CurrencyAmount.Text("xOffset"):GetFloat())
  if self.OldCurrencyAmount.Text("visible"):GetInt() == 1 then
    self.OldCurrencyAmount("xOffset"):SetFloat(self.CurrencyAmount.Text("xOffset"):GetFloat())
    self.OldCurrencyAmount.Text("size"):SetFloat(self.CurrencyAmount.Text("size"):GetFloat() * 0.8)
    local width = self.OldCurrencyAmount.Text:absW()
    self.OldCurrencyAmount.Strikeout.Sprite:setSize(Vector2(width, self.OldCurrencyAmount.Strikeout.Sprite:absH()))
    self.OldCurrencyAmount.Strikeout.Sprite:calculatePosition()
  end
end
function CurrencySuggestPrompt:setExpired()
  self.StarburstAnim.Sprite:setColor(0.5, 0.5, 0.5)
  self.CurrencyAnim.Sprite:setColor(0.5, 0.5, 0.5)
  self.ValueSticker:disable()
  self.CurrencyAmount.Text:setColor(0.5, 0.5, 0.5)
  self.CurrencySprite.Sprite:setColor(0.5, 0.5, 0.5)
  self.OldCurrencyAmount:disable()
  self.Timer.Text("text"):SetString("TIMED_EVENT_EXPIRED")
  self.BuyButton:disable()
end
function CurrencySuggestPrompt:hideTopText()
  self.NotificationTop.Text("text"):SetString("")
  self.NotificationTop.Text("size"):SetFloat(0)
  self.StarburstAnim("yOffset"):SetInt(-40 * game.windowScaleY())
  self.CurrencyAnim("yOffset"):SetInt(-40 * game.windowScaleY())
end
function CurrencySuggestPrompt:onTick(dt)
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
      local textID = self.NotificationTop.Text("text"):GetString()
      if string.match(textID, " ") then
        textID = ""
      end
      if self.choice == 1 then
        self:root():popPopUp()
        game.buyItem(self.storeId)
        game.logEvent("not_enough_currency_suggest_menu", "action", "click_buy", "metric_id", self.metricID, "store_id", self.storeId, "has_store_button", self.showStoreButton)
      elseif self.choice == 2 then
        self:root():popPopUp()
        game.submitConfirmation(self("messageID"):GetString(), true, textID)
        game.logEvent("not_enough_currency_suggest_menu", "action", "click_vist_market", "metric_id", self.metricID, "store_id", self.storeId, "has_store_button", self.showStoreButton)
      else
        self:root():popPopUp()
        game.submitConfirmation(self("messageID"):GetString(), false, textID)
        game.logEvent("not_enough_currency_suggest_menu", "action", "click_cancel", "metric_id", self.metricID, "store_id", self.storeId, "has_store_button", self.showStoreButton)
      end
    end
  else
    if os.time() >= self.delayCloseTime and not self.showCloseBtn then
      self.CloseButton:enable()
      self.CloseButton:setVisible()
      self.showCloseBtn = true
    end
    if self.Timer.Text("visible"):GetInt() == 1 then
      local newVal = 0
      if self.sale then
        newVal = self.sale:timeRemainingSec()
      elseif self.timedAvailability then
        newVal = self.timedAvailability:timeRemainingSec()
      end
      if newVal ~= self.lastTimeRemainingVal then
        self.lastTimeRemainingVal = newVal
        self.Timer.Text("text"):SetString(game.timeToString(self.lastTimeRemainingVal))
        if newVal == 0 then
          self:setExpired()
        end
      end
    end
  end
end
function CurrencySuggestPrompt:TickTransition()
  self.bg("xOffset"):SetFloat(lua_sys.screenWidth() * 0.5 + -0.5 * lua_sys.screenWidth() * (1 / math.max(0.001, self.transitionTime)))
  self.FadedBG.Sprite("alpha"):SetFloat(self.transitionTime * 0.5)
end
function CurrencySuggestPrompt:queuePop()
  self.transitionState = 2
end
function CurrencySuggestPrompt.ValueSticker:setInvisible()
  self.Text("visible"):SetInt(0)
  self.Sprite("visible"):SetInt(0)
end
function CurrencySuggestPrompt.ValueSticker:setVisible()
  self.Text("visible"):SetInt(1)
  self.Sprite("visible"):SetInt(1)
end
function CurrencySuggestPrompt.ValueSticker:setBestValue()
  self.Sprite("spriteName"):SetString("menu_value_sticker_green")
  self.Sprite("sheetName"):SetString("xml_resources/store_elements_01.xml")
  self.Text("text"):SetString("BEST_VALUE")
end
function CurrencySuggestPrompt.ValueSticker:setMostPopular()
  self.Sprite("spriteName"):SetString("menu_value_sticker_purple")
  self.Sprite("sheetName"):SetString("xml_resources/store_elements_01.xml")
  self.Text("text"):SetString("MOST_POPULAR")
end
function CurrencySuggestPrompt.ValueSticker:setCurrencyDiscount()
  self.Sprite("spriteName"):SetString("menu_value_sticker_red")
  self.Sprite("sheetName"):SetString("xml_resources/store_elements_01.xml")
  local txt = game.getLocalizedText("WARM_UP_PACK_PERCENTAGE")
  txt = select(1, txt:gsub("XXX", game.StoreContext_SaleDescCurrencyStoreItem(self:parent().storeId)))
  self.Text("text"):SetString(txt)
end
function CurrencySuggestPrompt.ValueSticker:set1Left()
  self.Sprite("spriteName"):SetString("menu_value_sticker")
  self.Sprite("sheetName"):SetString("xml_resources/store_elements_01.xml")
  if self:parent().promo:stickerText() ~= "" then
    self.Text("text"):SetString(self:parent().promo:stickerText())
  else
    local replacesText = LOC("WARM_UP_PACK_PERCENTAGE")
    replacesText = replacesText:gsub("XXX", self:parent().promo:discountText())
    self.Text("text"):SetString(replacesText)
  end
end
function CurrencySuggestPrompt.Timer:setInvisible()
  self.Text("visible"):SetInt(0)
end
function CurrencySuggestPrompt.Timer:setVisible()
  self.Text("visible"):SetInt(1)
end
function CurrencySuggestPrompt.BuyButton.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  element:parent().transitionState = 2
  element:parent().choice = 1
end
function CurrencySuggestPrompt.StoreButton.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  element:parent().transitionState = 2
  element:parent().choice = 2
end
function CurrencySuggestPrompt.CloseButton.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  element:parent().transitionState = 2
  element:parent().choice = 3
end
return CurrencySuggestPrompt
