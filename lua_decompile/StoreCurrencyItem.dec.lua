local ElementFader = require("ElementFader")
local StoreCurrencyItem = {
  Sprite = {
    Sprite = {}
  },
  MonsterAnim = {
    Sprite = {}
  },
  NewLabel = {
    Sprite = {},
    Text = {}
  },
  CurrencyAmount = {
    Sprite = {},
    Text = {}
  },
  TempAvailText = {
    TimerText = {}
  },
  CostBackground = {
    Sprite = {}
  },
  IAPCost = {
    Text = {}
  },
  AnyCost = {
    Sprite = {},
    Text = {}
  },
  LevelReq = {},
  ExchangeRateResetText = {
    TitleText = {},
    TimerText = {}
  },
  Touch = {}
}
function StoreCurrencyItem:onInit()
  self:GetVar("isLocked"):SetInt(0)
  self:enableAndPopulateCosts()
  local i = self:GetVar("ID"):GetInt()
  local maxAmount = store:maxAmount(i)
  self:GetVar("maxAmount"):SetInt(maxAmount)
  self:GetVar("currentAmount"):SetInt(store:currentAmount(i))
  if i >= store:NumCategoryItems() - store:NumLockedItems() or store:canBuyAnotherRightNow(i) == false or maxAmount > 0 and maxAmount <= store:currentAmount(i) then
    self:setLocked()
  end
  if store:SaleAmount(i) ~= 0 and self:GetVar("Cost"):GetString() ~= "OWNED" then
    local saleTag = menu:addTemplateElement("template_saletag", "saleTag", self)
    saleTag:setSize(self:size())
    saleTag:makeSizeDependent(self)
    saleTag:setOrientation(lua_sys.MenuOrientation(0, 0, -3, lua_sys.HCENTER, lua_sys.VCENTER))
    if self:GetVar("TimedAvailabilityOn"):GetInt() ~= 0 then
      self.IAPCost.Text:GetVar("alpha"):SetFloat(0.5)
    end
    saleTag:setParent(self)
    saleTag:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    saleTag("SaleDesc"):SetString(self:GetVar("SaleDesc"):GetString())
    saleTag("SaleAmount"):SetInt(self:GetVar("SaleAmount"):GetInt())
    saleTag("CurrencyType"):SetString(self:GetVar("Type"):GetString())
    saleTag:init()
    saleTag:setPositionBroadcast(true)
  end
  self:GetVar("displayTempAvailText"):SetInt(0)
  self:initFrameSprite()
  self:initMonsterAnim()
  self:initNewLabel()
  self:initBestValue()
  self:initMostPopular()
  self:initCurrencyAmount()
  self:initTempAvail()
  self:initIAPCost()
  self:initAnyCost()
  self:initExchangeRateResetText()
  self:initFader()
end
function StoreCurrencyItem:initFrameSprite()
  local sheetName = "xml_resources/store_elements_01.xml"
  local spriteName = "menu_market_frame"
  local isPromo = self("IsPromoItem"):GetInt() == 1
  if isPromo then
    local itemName = self("ItemName"):GetString()
    local promo = game.getPromoByName(itemName)
    if promo:promoId() == 52 or promo:promoId() == 53 then
      spriteName = "menu_market_frame_gold"
    elseif promo and promo:promoType() == game.PromotionType_DoyPromo then
      spriteName = "menu_market_frame_candycane"
    else
      spriteName = "menu_market_frame_gold"
    end
  elseif self("1LeftIAP"):GetInt() == 1 or self("CurrencyType"):GetString() == game.StoreContext_TYPE_BUNDLE then
    spriteName = "menu_market_frame_gold"
  end
  local frameSprite = self:E("Sprite"):C("Sprite")
  frameSprite:GetVar("spriteName"):SetString(spriteName)
  frameSprite:GetVar("sheetName"):SetString(sheetName)
end
function StoreCurrencyItem:initMonsterAnim()
  local animComponent = self.MonsterAnim.Sprite
  local animationFile = "xml_bin/" .. self("AnimationFile"):GetString()
  animComponent("animationName"):SetString(animationFile)
  local animationName = self("AnimationName"):GetString()
  if self("1LeftIAP"):GetInt() ~= 0 or self("IsPromoItem"):GetInt() ~= 0 then
    local altAnim = store:AltAnimForPromoItem(self("ID"):GetInt())
    if altAnim ~= "" then
      animationName = altAnim
    end
  end
  animComponent("animation"):SetString(animationName)
  if store:IsTorch(self("ID"):GetInt()) == 1 then
    animComponent:AddRemap("gfx/structures/tiki_plant01.png", "gfx/structures/" .. store:torchGfxForThisIsland())
  end
  if self:name() == "freeDiamonds" then
    animComponent:setScale(Vector2(1.4 * game.menuScaleX(), 1.4 * game.menuScaleX()))
    animComponent("yOffset"):SetFloat(30)
    animComponent("xOffset"):SetFloat(-6)
  end
end
function StoreCurrencyItem:initNewLabel()
  local sprite = self:E("NewLabel"):C("Sprite")
  local text = self:E("NewLabel"):C("Text")
  if self("1LeftIAP"):GetInt() == 1 then
    text("text"):SetString(store:StickerTextForPromoItem(self("ID"):GetInt()))
    sprite("visible"):SetInt(1)
    text("visible"):SetInt(1)
  end
end
function StoreCurrencyItem:initBestValue()
  local sprite = self:E("BestValue"):C("Sprite")
  local text = self:E("BestValue"):C("Text")
  if self("IsBestValue"):GetInt() == 1 then
    sprite("visible"):SetInt(1)
    text("visible"):SetInt(1)
  end
end
function StoreCurrencyItem:initMostPopular()
  local sprite = self:E("MostPopular"):C("Sprite")
  local text = self:E("MostPopular"):C("Text")
  if self("IsMostPopular"):GetInt() == 1 then
    sprite("visible"):SetInt(1)
    text("visible"):SetInt(1)
  end
end
function StoreCurrencyItem:initCurrencyAmount()
  local sprite = self:E("CurrencyAmount"):C("Sprite")
  local text = self:E("CurrencyAmount"):C("Text")
  if self:name() == "freeDiamonds" then
    sprite("visible"):SetInt(0)
    text("visible"):SetInt(0)
  end
  local typeStr = self("CurrencyType"):GetString()
  local currencyType = game.StoreContext_StoreTypeToCurrency(typeStr)
  local currencyProps = require("Currencies"):getProps(currencyType)
  currencyProps:applyToSpriteSheet(sprite)
  currencyProps:normalizeSizeH(sprite, 0.5 * game.hudScale())
  currencyProps:applyToText(text)
  if typeStr == game.StoreContext_TYPE_BUNDLE or self("IsPromoItem"):GetInt() == 1 then
    text("multiline"):SetInt(1)
    text("size"):SetFloat(0.5 * game.menuScaleX())
    text("text"):SetString(self("ItemTitle"):GetString())
    text("yOffset"):SetFloat(-7 * game.menuScaleX())
    sprite("visible"):SetInt(0)
  else
    text("multiline"):SetInt(0)
    text("size"):SetFloat(0.5 * game.menuScaleX())
    text("text"):SetString(self("CurrencyGained"):GetString())
    local size = text("size"):GetFloat()
    currencyProps:normalizeSizeH(sprite, 0.5 * game.hudScale())
    local textWidth = text:absW()
    local totalWidth = textWidth + sprite:absW()
    text("xOffset"):SetFloat(-textWidth / 2 + totalWidth / 2)
    sprite("xOffset"):SetFloat(-text("xOffset"):GetFloat())
  end
end
function StoreCurrencyItem:initTempAvail()
  local textComponent = self:E("TempAvailText"):C("TimerText")
  local palette = require("ColourPalette")
  textComponent:setColor(palette:getRGBFloats(palette.AVAILABILITY_TIMER_COLOUR))
  textComponent("alignment"):SetInt(MenuTextComponent_TEXT_HCENTER_ALIGNED)
  local index = self("ID"):GetInt()
  if self("1LeftIAP"):GetInt() == 1 then
    local text = game.getLocalizedText("LIMITED_REMAINING_TEXT")
    local storeItemName = self("ItemName"):GetString()
    local promo = game.getPromoByName(storeItemName)
    if promo then
      text = text:gsub("%${REMAINING}", promo:getMaxActivations() - promo:getActivationCount())
    else
      text = text:gsub("%${REMAINING}", 1)
    end
    textComponent("text"):SetString(text)
  else
    local secondsRemaining = 0
    if self("TimedAvailabilityOn"):GetInt() == 1 then
      secondsRemaining = store:RemainingAvailTime(index)
    elseif self("TimedSaleOn"):GetInt() == 1 then
      secondsRemaining = store:RemainingSaleTime(index)
    end
    textComponent("text"):SetString("" .. game.timeToString(secondsRemaining, true))
  end
end
function StoreCurrencyItem:tickTempAvail(dt)
  local secondsRemaining = 0
  if self("1LeftIAP"):GetInt() == 0 then
    local itemId = self("ID"):GetInt()
    local saleTagElement = self:E("saleTag")
    local timerText = self:E("TempAvailText"):C("TimerText")
    local availabilityEvent = self("TimedAvailabilityOn"):GetInt()
    if availabilityEvent == 1 then
      secondsRemaining = store:RemainingAvailTime(itemId)
    elseif self("TimedSaleOn"):GetInt() == 1 then
      secondsRemaining = store:RemainingSaleTime(itemId)
    end
    if secondsRemaining > 0 then
      timerText("text"):SetString(game.timeToString(secondsRemaining, true))
      if saleTagElement then
        local newSale = store:SaleAmount(itemId)
        if newSale ~= self("SaleAmount"):GetInt() then
          if self("TimedAvailabilityOn"):GetInt() == 1 then
            saleTagElement.SaleIAPAmount.Text("text"):SetString(game.commaizeNumber(newSale))
            saleTagElement.SaleIAPAmount.Text("visible"):SetInt(1)
            saleTagElement.SaleCurrencyAmount:DoStoredScript("setInvisible")
          else
            saleTagElement.SaleCurrencyAmount.Text("text"):SetString(game.commaizeNumber(newSale))
            saleTagElement.SaleCurrencyAmount:DoStoredScript("setVisible")
            saleTagElement.SaleIAPAmount.Text("visible"):SetInt(0)
          end
          saleTagElement:C("Text")("text"):SetString("+" .. store:SaleDesc(itemId) .. "%")
        end
      end
    elseif availabilityEvent == 1 then
      if self:C("Touch"):GetVar("enabled"):GetInt() == 1 then
        store:AnAvailabilityExpiryOccurred(self:name())
        timerText("text"):SetString("TIMED_EVENT_EXPIRED")
        self:DoStoredScript("setDisabled")
      end
    elseif timerText("visible"):GetInt() == 1 and self("1LeftIAP"):GetInt() ~= 1 then
      if saleTagElement then
        saleTagElement:DoStoredScript("hide")
      end
      timerText("visible"):SetInt(0)
    end
  end
end
function StoreCurrencyItem:initIAPCost()
  local textComponent = self:E("IAPCost"):C("Text")
  if self:name() == "currencyExchange" or self:name() == "coinsToEthCurrencyExchange" or self:name() == "diamondsToEthCurrencyExchange" or self:name() == "ethToDiamondsCurrencyExchange" or self:name() == "diamondsToRelicsCurrencyExchange" then
    textComponent:GetVar("visible"):SetInt(0)
  else
    local itemPriceText = self("ItemPriceAsStr"):GetString()
    textComponent("text"):SetString(itemPriceText)
  end
end
function StoreCurrencyItem:initAnyCost()
  local textComponent = self:E("AnyCost"):C("Text")
  local spriteComponent = self:E("AnyCost"):C("Sprite")
  self:disableAllCosts()
  if self:GetVar("Type"):GetString() == "none" then
    return
  end
  textComponent("text"):SetString(self("Cost"):GetString())
  self.currencyProps:applyToText(textComponent)
  self.currencyProps:applyToSpriteSheet(spriteComponent)
  if self:name() == "currencyExchange" or self:name() == "diamondsToEthCurrencyExchange" or self:name() == "diamondsToRelicsCurrencyExchange" then
    textComponent("visible"):SetInt(1)
    spriteComponent("visible"):SetInt(1)
  end
  if self("isLocked"):GetInt() == 1 then
    textComponent:setColor(textComponent("red"):GetFloat() * 0.5, textComponent("green"):GetFloat() * 0.5, textComponent("blue"):GetFloat() * 0.5)
  end
  textComponent("text"):SetString(self("Cost"):GetString())
  local size = textComponent("size"):GetFloat()
  self.currencyProps:normalizeSizeH(spriteComponent, size)
  local textWidth = textComponent:absW()
  local totalWidth = textWidth + spriteComponent:absW()
  local textOffset = -textWidth * 0.5 + totalWidth * 0.5
  textComponent("xOffset"):SetFloat(textOffset)
  spriteComponent("xOffset"):SetFloat(-textOffset)
end
function StoreCurrencyItem:initExchangeRateResetText()
  local element = self:E("ExchangeRateResetText")
  element("relicExchangeItem"):SetInt(0)
  local textComponent = element:C("TimerText")
  local palette = require("ColourPalette")
  textComponent:setColor(palette:getRGBFloats(palette.RESET_TIME_TIMER_COLOUR))
end
function StoreCurrencyItem:tickExchangeRateResetText(dt)
  local element = self:E("ExchangeRateResetText")
  local titleText = element:C("TitleText")
  if element("relicExchangeItem"):GetInt() == 1 and titleText("visible"):GetInt() == 1 then
    local secondsRemaining = store:timeRemainingOnRelicRateReset()
    if secondsRemaining > 0 then
      local timerText = element:C("TimerText")
      timerText("text"):SetString(game.timeToString(secondsRemaining, true))
      timerText("visible"):SetInt(1)
    end
  end
end
function StoreCurrencyItem:initFader()
  local faderOptions = {
    onUpdateComponent = function(component)
      if component.colorChange then
        component:colorChange()
      end
    end,
    duration = 0.2
  }
  self.fader = ElementFader.New(self, faderOptions)
  self.fader:Show()
end
function StoreCurrencyItem:enableAndPopulateCosts()
  local storeItemType = self:GetVar("Type"):GetString()
  self.currencyType = game.StoreContext_StoreTypeToCurrency(storeItemType)
  self.currencyProps = require("Currencies"):getProps(self.currencyType)
end
function StoreCurrencyItem:disableAllCosts()
  self.AnyCost.Text:GetVar("visible"):SetInt(0)
  self.AnyCost.Sprite:GetVar("visible"):SetInt(0)
end
function StoreCurrencyItem:onPostInit()
  if self:GetVar("SaleDesc"):GetString() ~= "" then
    self:showSale()
  else
    self:hideSale()
  end
  if self:GetVar("Premium"):GetInt() == 1 and not game.premiumPlayer() then
    self:setDisabled()
    local premiumLock = menu:addTemplateElement("template_premiumlock", "PremiumLock", self)
    premiumLock:relativeTo(self)
    premiumLock:setOrientation(lua_sys.MenuOrientation(0, 15 * game.menuScaleX(), -2, lua_sys.HCENTER, lua_sys.VCENTER))
    premiumLock:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    premiumLock:init()
    premiumLock:setPositionBroadcast(true)
    premiumLock:postInit()
  end
  local displayTempAvailText = 0
  if (self:GetVar("TimedAvailabilityOn"):GetInt() == 1 or self:GetVar("TimedSaleOn"):GetInt() == 1 or self:GetVar("1LeftIAP"):GetInt() == 1 or self:GetVar("IsPromoItem"):GetInt() == 1) and self:GetVar("Cost"):GetString() ~= "OWNED" then
    displayTempAvailText = 1
  end
  self.TempAvailText.TimerText:GetVar("visible"):SetInt(displayTempAvailText)
  self:GetVar("displayTempAvailText"):SetInt(displayTempAvailText)
  local isPromo = self:GetVar("IsPromoItem"):GetInt() == 1
  local isQuadMultiPack = self:HasVar("IsQuadMultiPack") and self:GetVar("IsQuadMultiPack"):GetInt() == 1
  if isPromo then
    self:hideSale()
    self.TempAvailText.TimerText:GetVar("visible"):SetInt(displayTempAvailText)
    self.TempAvailText:relativeTo(self.Sprite)
    self.TempAvailText:setOrientation(lua_sys.MenuOrientation(0, 32 * game.menuScaleX(), -1, lua_sys.HCENTER, lua_sys.BOTTOM))
    self.TempAvailText:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.BOTTOM)
  end
  if isQuadMultiPack then
    self.CurrencyAmount.Sprite:GetVar("visible"):SetInt(0)
    self.IAPCost.Text:GetVar("text"):SetString("Pick a Pack!")
  end
  if isPromo then
    local storeItemName = self("ItemName"):GetString()
    local promo = game.getPromoByName(storeItemName)
    if promo then
      if promo:promoId() == 53 then
        local garnish = menu:addTemplateElement("template_spritesheet", "DoYGarnish", self)
        garnish:relativeTo(self)
        garnish:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
        garnish:setOrientation(lua_sys.MenuOrientation(0 * game.menuScaleX(), -2 * game.menuScaleX(), -1, lua_sys.HCENTER, lua_sys.VCENTER))
        garnish:init()
        garnish:setPositionBroadcast(true)
        garnish:postInit()
        garnish.Sprite("sheetName"):SetString("xml_resources/multipack_sheet.xml")
        garnish.Sprite("spriteName"):SetString("Love_sticker1")
        garnish.Sprite("size"):SetFloat(0.3 * game.menuScaleX())
        garnish.Sprite("layer"):SetString("HUD")
      elseif promo:promoType() == game.PromotionType_DoyPromo then
        local garnish = menu:addTemplateElement("template_spritesheet", "DoYGarnish", self)
        garnish:relativeTo(self)
        garnish:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
        garnish:setOrientation(lua_sys.MenuOrientation(0 * game.menuScaleX(), 0 * game.menuScaleX(), -1, lua_sys.HCENTER, lua_sys.VCENTER))
        garnish:init()
        garnish:setPositionBroadcast(true)
        garnish:postInit()
        garnish.Sprite("sheetName"):SetString("xml_resources/multipack_sheet.xml")
        garnish.Sprite("spriteName"):SetString("Yay_sticker1")
        garnish.Sprite("size"):SetFloat(0.45 * game.menuScaleX())
        garnish.Sprite("layer"):SetString("HUD")
      end
    end
  end
end
function StoreCurrencyItem:onTick(dt)
  self.fader:tick(dt)
  self:tickTempAvail(dt)
  self:tickExchangeRateResetText(dt)
end
function StoreCurrencyItem:setLocked()
  self:GetVar("isLocked"):SetInt(1)
  local showLevelReqText = false
  if game.playerLevel() < self:GetVar("RequiresLevel"):GetInt() then
    showLevelReqText = true
  end
  if showLevelReqText then
    self.LevelReq:GetVar("visible"):SetInt(1)
    self.AnyCost.Text:GetVar("text"):SetString("?")
    local remixButton = self:GetElement("RemixButton")
    if remixButton ~= nil then
      remixButton.button:DoStoredScript("setInvisible")
    end
  end
  self.TempAvailText.TimerText:GetVar("visible"):SetInt(0)
  self:setDisabled()
end
function StoreCurrencyItem:setDisabled()
  if self.Touch:GetVar("enabled"):GetInt() == 1 then
    self.Sprite.Sprite:setColor(0.5, 0.5, 0.5)
    self.MonsterAnim.Sprite:setColor(0.2, 0.2, 0.2)
    local text = self.AnyCost.Text
    text:setColor(text:GetVar("red"):GetFloat() * 0.5, text:GetVar("green"):GetFloat() * 0.5, text:GetVar("blue"):GetFloat() * 0.5)
    self.AnyCost.Sprite:setColor(0.5, 0.5, 0.5)
    self.NewLabel.Sprite:setColor(0.5, 0.5, 0.5)
    text = self.NewLabel.Text
    text:setColor(text:GetVar("red"):GetFloat() * 0.5, text:GetVar("green"):GetFloat() * 0.5, text:GetVar("blue"):GetFloat() * 0.5)
    self.Touch:GetVar("enabled"):SetInt(0)
  end
end
function StoreCurrencyItem:hideItem()
  self.Sprite.Sprite:GetVar("visible"):SetInt(0)
  self.MonsterAnim.Sprite:GetVar("visible"):SetInt(0)
  self.ExchangeRateResetText.TitleText:GetVar("visible"):SetInt(0)
  self.ExchangeRateResetText.TimerText:GetVar("visible"):SetInt(0)
  self.AnyCost.Text:GetVar("alpha"):SetFloat(0)
  self.AnyCost.Sprite:GetVar("alpha"):SetFloat(0)
  self.CurrencyAmount.Sprite:GetVar("alpha"):SetFloat(0)
  self.CurrencyAmount.Text:GetVar("alpha"):SetFloat(0)
  self.IAPCost.Text:GetVar("alpha"):SetFloat(0)
  self.NewLabel.Sprite:GetVar("alpha"):SetFloat(0)
  self.NewLabel.Text:GetVar("alpha"):SetFloat(0)
  self.LevelReq:GetVar("visible"):SetInt(0)
  self.Touch:GetVar("enabled"):SetInt(0)
  if self:GetVar("SaleDesc"):GetString() ~= "" then
    self:hideSale()
  end
  self.TempAvailText.TimerText:GetVar("visible"):SetInt(0)
  self.fader:Hide(true)
end
function StoreCurrencyItem:showItem()
  self.Sprite.Sprite:GetVar("visible"):SetInt(1)
  self.MonsterAnim.Sprite:GetVar("visible"):SetInt(1)
  if self:name() == "currencyExchange" or self:name() == "diamondsToEthCurrencyExchange" or self:name() == "diamondsToRelicsCurrencyExchange" then
    self.AnyCost.Text:GetVar("alpha"):SetFloat(1)
    self.AnyCost.Sprite:GetVar("alpha"):SetFloat(1)
  else
    self.IAPCost.Text:GetVar("alpha"):SetFloat(1)
  end
  self.CurrencyAmount.Sprite:GetVar("alpha"):SetFloat(1)
  self.CurrencyAmount.Text:GetVar("alpha"):SetFloat(1)
  self.NewLabel.Sprite:GetVar("alpha"):SetFloat(1)
  self.NewLabel.Text:GetVar("alpha"):SetFloat(1)
  self.Touch:GetVar("enabled"):SetInt(1)
  if self:GetVar("SaleDesc"):GetString() ~= "" then
    self:showSale()
  end
  if self:GetVar("TimedAvailabilityOn"):GetInt() == 1 or self:GetVar("1LeftIAP"):GetInt() == 1 or self:GetVar("IsPromoItem"):GetInt() == 1 then
    self.TempAvailText.TimerText:GetVar("visible"):SetInt(1)
  end
  if self:GetVar("isLocked"):GetInt() == 1 then
    self:setLocked()
  end
  self.fader.delayOnShow = 0
  self.fader:Show()
end
function StoreCurrencyItem:hideSale()
  if self:GetVar("isLocked"):GetInt() == 0 and (store:SaleAmount(self:GetVar("ID"):GetInt()) ~= 0 or self:GetVar("TimedSaleOn"):GetInt() == 1) then
    if self:GetElement("saleTag") ~= nil then
      self.saleTag:DoStoredScript("hide")
    end
    self.TempAvailText.TimerText:GetVar("visible"):SetInt(0)
  end
end
function StoreCurrencyItem:showSale()
  if store:SaleAmount(self:GetVar("ID"):GetInt()) ~= 0 or self:GetVar("TimedSaleOn"):GetInt() == 1 or self:GetVar("1LeftIAP"):GetInt() == 1 then
    if self:GetVar("isLocked"):GetInt() == 0 then
      if self:GetElement("saleTag") ~= nil then
        self.saleTag:DoStoredScript("show")
      end
      self.TempAvailText.TimerText:GetVar("visible"):SetInt(self:GetVar("displayTempAvailText"):GetInt())
    else
      if self:GetElement("saleTag") ~= nil then
        self.saleTag:DoStoredScript("showDisabled")
      end
      local timerText = self.TempAvailText.TimerText
      timerText:GetVar("visible"):SetInt(self:GetVar("displayTempAvailText"):GetInt())
      timerText:setColor(timerText:GetVar("red"):GetFloat() * 0.5, timerText:GetVar("green"):GetFloat() * 0.5, timerText:GetVar("blue"):GetFloat() * 0.5)
    end
  end
end
function StoreCurrencyItem.Touch:onInit(element)
  self.dragging = 0
  self.touchStart = 0
  self.realStart = 0
end
function StoreCurrencyItem.Touch:onTouchDown(element, x, y)
  self.touchStart = x
  self.realStart = x
end
function StoreCurrencyItem.Touch:onTouchDrag(element, x, y)
  self.dragging = self.dragging + math.abs(x - self.touchStart)
  self.touchStart = x
end
function StoreCurrencyItem.Touch:onTouchUp(element, x, y)
  if math.abs(self.touchStart - self.realStart) < 10 then
    if element:name() == "freeDiamonds" then
      game.displayNotification("NO_ADS_STOREITEM_DESC")
    else
      store:SelectItem(element:name())
    end
    self.dragging = 0
    self.touchStart = 0
    self.realStart = 0
  end
end
function StoreCurrencyItem.Touch:onTouchRelease(element, x, y)
  self.dragging = 0
  self.touchStart = 0
  self.realStart = 0
end
return StoreCurrencyItem
