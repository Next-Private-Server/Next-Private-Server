local QuadMultipack = {
  FadedBG = {},
  TitleFrame = {},
  TitleLabel = {},
  NotificationTop = {
    Text = {}
  },
  FirstPackBg = {
    IcingR = {},
    IcingL = {}
  },
  SecondPackBg = {
    IcingR = {},
    IcingL = {}
  },
  ThirdPackBg = {
    IcingR = {},
    IcingL = {}
  },
  BuyAllPackButton = {
    Text = {},
    Touch = {},
    storeId = 0
  },
  ValueSticker = {
    Sprite = {},
    Text = {}
  },
  Timer = {
    Sprite = {},
    Text = {},
    Hourglass = {}
  },
  CloseButton = {
    Touch = {}
  },
  promoEvent = nil,
  timeRemaining = -1,
  enabled = true
}
function QuadMultipack:onInit()
  self("transitionState"):SetInt(1)
  self("transitionTime"):SetFloat(0)
  playSoundFx("audio/sfx/menu_slide.wav")
  local contextBar = game.getContextBar()
  if contextBar then
    contextBar:setContext("MAP")
    self.CloseButton:Hide()
  else
    self.CloseButton:Show()
  end
  game.logEvent("promo_menu_init", "promo", "jampack_multipack")
  self:SetupGenericListener(game.engineReceiver(), "store::msg::MsgPurchaseComplete", "gotMsgPurchaseComplete")
end
function QuadMultipack:SetupAsDoY()
  self.FirstPackBg.IcingL("spriteName"):SetString("Yay_sticker2")
  self.FirstPackBg.IcingL("size"):SetFloat(0.45 * game.menuScaleX())
  self.FirstPackBg.IcingL:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
  self.FirstPackBg.IcingL:setOrientation(lua_sys.MenuOrientation(-10 * game.menuScaleX(), -30 * game.menuScaleX(), -1, lua_sys.LEFT, lua_sys.TOP))
  self.FirstPackBg.IcingR("visible"):SetInt(0)
  self.SecondPackBg.IcingL("spriteName"):SetString("Yay_sticker1")
  self.SecondPackBg.IcingL("size"):SetFloat(0.45 * game.menuScaleX())
  self.SecondPackBg.IcingL:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
  self.SecondPackBg.IcingL:setOrientation(lua_sys.MenuOrientation(0 * game.menuScaleX(), 0 * game.menuScaleX(), -1, lua_sys.HCENTER, lua_sys.VCENTER))
  self.SecondPackBg.IcingR("visible"):SetInt(0)
  self.ThirdPackBg.IcingL("visible"):SetInt(0)
  self.ThirdPackBg.IcingR("spriteName"):SetString("Yay_sticker2")
  self.ThirdPackBg.IcingR("hFlip"):SetInt(1)
  self.ThirdPackBg.IcingR("size"):SetFloat(0.45 * game.menuScaleX())
  self.ThirdPackBg.IcingR:setRelativeObjectAnchors(lua_sys.RIGHT, lua_sys.TOP)
  self.ThirdPackBg.IcingR:setOrientation(lua_sys.MenuOrientation(-8 * game.menuScaleX(), -30 * game.menuScaleX(), -1, lua_sys.RIGHT, lua_sys.TOP))
end
function QuadMultipack:SetupAsSeasonOfLove()
  self.FirstPackBg.IcingL("spriteName"):SetString("Love_sticker2")
  self.FirstPackBg.IcingL("size"):SetFloat(0.3 * game.menuScaleX())
  self.FirstPackBg.IcingL:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
  self.FirstPackBg.IcingL:setOrientation(lua_sys.MenuOrientation(-2 * game.menuScaleX(), -18 * game.menuScaleX(), -1, lua_sys.LEFT, lua_sys.TOP))
  self.FirstPackBg.IcingR("visible"):SetInt(0)
  self.SecondPackBg.IcingL("spriteName"):SetString("Love_sticker1")
  self.SecondPackBg.IcingL("size"):SetFloat(0.3 * game.menuScaleX())
  self.SecondPackBg.IcingL:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
  self.SecondPackBg.IcingL:setOrientation(lua_sys.MenuOrientation(0 * game.menuScaleX(), -5 * game.menuScaleX(), -1, lua_sys.HCENTER, lua_sys.VCENTER))
  self.SecondPackBg.IcingR("visible"):SetInt(0)
  self.ThirdPackBg.IcingL("visible"):SetInt(0)
  self.ThirdPackBg.IcingR("spriteName"):SetString("Love_sticker2")
  self.ThirdPackBg.IcingR("hFlip"):SetInt(1)
  self.ThirdPackBg.IcingR("size"):SetFloat(0.3 * game.menuScaleX())
  self.ThirdPackBg.IcingR:setRelativeObjectAnchors(lua_sys.RIGHT, lua_sys.TOP)
  self.ThirdPackBg.IcingR:setOrientation(lua_sys.MenuOrientation(2 * game.menuScaleX(), -18 * game.menuScaleX(), -1, lua_sys.RIGHT, lua_sys.TOP))
end
function QuadMultipack:SetupAsEggstravaganza()
  self.FirstPackBg.IcingL("spriteName"):SetString("left_01")
  self.FirstPackBg.IcingL("sheetName"):SetString("xml_resources/multipack_eggstravaganza_sheet.xml")
  self.FirstPackBg.IcingL("size"):SetFloat(0.3 * game.menuScaleX())
  self.FirstPackBg.IcingL:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
  self.FirstPackBg.IcingL:setOrientation(lua_sys.MenuOrientation(-8 * game.menuScaleX(), -30 * game.menuScaleX(), -1, lua_sys.LEFT, lua_sys.TOP))
  self.FirstPackBg.IcingR("visible"):SetInt(0)
  self.SecondPackBg.IcingL("spriteName"):SetString("middle_01")
  self.SecondPackBg.IcingL("sheetName"):SetString("xml_resources/multipack_eggstravaganza_sheet.xml")
  self.SecondPackBg.IcingL("size"):SetFloat(0.3 * game.menuScaleX())
  self.SecondPackBg.IcingL:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
  self.SecondPackBg.IcingL:setOrientation(lua_sys.MenuOrientation(0 * game.menuScaleX(), -5 * game.menuScaleX(), -1, lua_sys.HCENTER, lua_sys.VCENTER))
  self.SecondPackBg.IcingR("visible"):SetInt(0)
  self.ThirdPackBg.IcingL("visible"):SetInt(0)
  self.ThirdPackBg.IcingR("spriteName"):SetString("left_01")
  self.ThirdPackBg.IcingR("sheetName"):SetString("xml_resources/multipack_eggstravaganza_sheet.xml")
  self.ThirdPackBg.IcingR("hFlip"):SetInt(1)
  self.ThirdPackBg.IcingR("size"):SetFloat(0.3 * game.menuScaleX())
  self.ThirdPackBg.IcingR:setRelativeObjectAnchors(lua_sys.RIGHT, lua_sys.TOP)
  self.ThirdPackBg.IcingR:setOrientation(lua_sys.MenuOrientation(-2 * game.menuScaleX(), -30 * game.menuScaleX(), -1, lua_sys.RIGHT, lua_sys.TOP))
end
function QuadMultipack:SetupAsSummersong()
  print("Set up Summersong Miltipack")
  self.FirstPackBg.IcingL("spriteName"):SetString("left_01")
  self.FirstPackBg.IcingL("sheetName"):SetString("xml_resources/multipack_summersong_sheet.xml")
  self.FirstPackBg.IcingL("size"):SetFloat(0.3 * game.menuScaleX())
  self.FirstPackBg.IcingL:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
  self.FirstPackBg.IcingL:setOrientation(lua_sys.MenuOrientation(-8 * game.menuScaleX(), -30 * game.menuScaleX(), -1, lua_sys.LEFT, lua_sys.TOP))
  self.FirstPackBg.IcingR("visible"):SetInt(0)
  self.SecondPackBg.IcingL("spriteName"):SetString("middle_01")
  self.SecondPackBg.IcingL("sheetName"):SetString("xml_resources/multipack_summersong_sheet.xml")
  self.SecondPackBg.IcingL("size"):SetFloat(0.3 * game.menuScaleX())
  self.SecondPackBg.IcingL:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
  self.SecondPackBg.IcingL:setOrientation(lua_sys.MenuOrientation(0 * game.menuScaleX(), -5 * game.menuScaleX(), -1, lua_sys.HCENTER, lua_sys.VCENTER))
  self.SecondPackBg.IcingR("visible"):SetInt(0)
  self.ThirdPackBg.IcingL("visible"):SetInt(0)
  self.ThirdPackBg.IcingR("spriteName"):SetString("left_01")
  self.ThirdPackBg.IcingR("sheetName"):SetString("xml_resources/multipack_summersong_sheet.xml")
  self.ThirdPackBg.IcingR("hFlip"):SetInt(1)
  self.ThirdPackBg.IcingR("size"):SetFloat(0.3 * game.menuScaleX())
  self.ThirdPackBg.IcingR:setRelativeObjectAnchors(lua_sys.RIGHT, lua_sys.TOP)
  self.ThirdPackBg.IcingR:setOrientation(lua_sys.MenuOrientation(-2 * game.menuScaleX(), -30 * game.menuScaleX(), -1, lua_sys.RIGHT, lua_sys.TOP))
end
function QuadMultipack:Init(promo)
  self.promoEvent = promo
  if self.promoEvent then
    print("Initializing QuadMultipack for promo event:", self.promoEvent:promoId(), self.promoEvent:promoType())
    local multipacks = self.promoEvent:getMultipackPack()
    for i = 0, multipacks:size() - 1 do
      local result = multipacks[i]
      local currentPackElement
      if i == 0 then
        currentPackElement = self.FirstPackBg
      elseif i == 1 then
        currentPackElement = self.SecondPackBg
      elseif i == 2 then
        currentPackElement = self.ThirdPackBg
      elseif i == 3 then
        currentPackElement = self.BuyAllPackButton
      else
        print("WARNING IN QUADMULTIPACK: more packs than expected")
      end
      local storeItemData = game.getStoreItemData(result)
      if storeItemData and currentPackElement then
        print("Populating QuadMultipack element ", currentPackElement:name(), " for store item:", storeItemData:name())
        currentPackElement:initStoreId(storeItemData:id())
        currentPackElement:populatePrice(storeItemData:priceStr())
        currentPackElement:populateDesc(storeItemData:description())
        local contents = storeItemData:contents()
        for j = 0, contents:size() - 1 do
          local contentItem = contents[j]
          local lootType = contentItem.type
          print("  with content item:", contentItem.id, " type:", lootType, " amount:", contentItem.amount)
          if lootType == game.LootType_Costume then
            currentPackElement:populateCostume(contentItem.id)
          else
            local currencyType = game.Currencies_LootTypeToCurrencyType(lootType)
            if currencyType ~= game.currencyType_MAX_NUM_CURRENCIES then
              currentPackElement:addCurrency(currencyType, contentItem.amount, "MidPopUps")
            else
              print("WARNING IN QUADMULTIPACK: pack contains unhandled content: lootType " .. lootType)
            end
          end
        end
      end
    end
    if self.promoEvent:promoId() == 53 then
      self:SetupAsSeasonOfLove()
    elseif self.promoEvent:promoId() == 62 then
      self:SetupAsEggstravaganza()
    elseif self.promoEvent:promoId() == 74 then
      self:SetupAsSummersong()
    elseif self.promoEvent:promoType() == game.PromotionType_DoyPromo then
      self:SetupAsDoY()
    end
  else
    local contextBar = game.getContextBar()
    if contextBar then
      contextBar:setContext(contextBar:reserveState())
    end
    self:root():popPopUp()
  end
end
function QuadMultipack:onTick(dt)
  local newVal = self.promoEvent:timeRemainingSec()
  if newVal ~= self.timeRemaining then
    self.timeRemaining = newVal
    if self.enabled then
      if self.timeRemaining > 0 then
        self.Timer.Text("text"):SetString(game.timeToString(self.promoEvent:timeRemainingSec(), true))
      else
        self.enabled = false
        self:disable()
      end
    end
  end
end
function QuadMultipack:disable()
  self.enabled = false
  self.Timer.Text("text"):SetString("TIMED_EVENT_EXPIRED")
  self.Timer.Text:setColor(1, 0, 0)
  self.FirstPackBg:disable()
  self.SecondPackBg:disable()
  self.ThirdPackBg:disable()
  self.ValueSticker:disable()
  self.BuyAllPackButton:disable()
end
function QuadMultipack:queuePop()
  local contextBar = game.getContextBar()
  if contextBar then
    contextBar:setContext(contextBar:reserveState())
  end
  self:root():popPopUp()
end
function QuadMultipack:gotMsgPurchaseComplete(msg)
  if msg.success_ and self.promoEvent then
    local multipack = self.promoEvent:getMultipackPack()
    for i = 0, multipack:size() - 1 do
      local storeItemId = multipack[i]
      if storeItemId then
        local storeItemData = game.getStoreItemData(storeItemId)
        if storeItemData and storeItemData:name() == msg._itemName then
          self:disable()
          break
        end
      end
    end
  else
    self:disable()
  end
end
function QuadMultipack.BuyAllPackButton:initStoreId(storeId)
  self.storeId = storeId
end
function QuadMultipack.BuyAllPackButton:populateCostume(costumeId)
end
function QuadMultipack.BuyAllPackButton:addCurrency(currencyType, amount, layer)
end
function QuadMultipack.BuyAllPackButton:populatePrice(priceStr)
  local titleText = LOC("JAMBOREE_MULTIPACK_BUY_BUTTON_PREFIX")
  titleText = titleText:gsub("%${PRICE}", priceStr)
  self.Text("text"):SetString(titleText)
  local textWidth = self.Text:absW() + 32 * game.menuScaleX()
  self:templateVars().width = textWidth
  self.BoundsSprite("width"):SetFloat(textWidth)
  self.UpSprite("width"):SetFloat(textWidth)
  self.DownSprite("width"):SetFloat(textWidth)
end
function QuadMultipack.BuyAllPackButton:populateDesc(priceText)
end
function QuadMultipack.BuyAllPackButton.Touch:onTouchDown(element)
  self:super_onTouchDown(element)
end
function QuadMultipack.BuyAllPackButton.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  local contextBar = game.getContextBar()
  if contextBar then
    contextBar:setContext(contextBar:reserveState())
  end
  self:root():popPopUp()
  if game.storeContext() then
    game.showSpinner()
  end
  game.buyItem(element.storeId)
end
function QuadMultipack.BuyAllPackButton.Touch:onTouchRelease(element)
  self:super_onTouchRelease(element)
end
function QuadMultipack.CloseButton.Touch:onTouchUp(element, x, y)
  self:super_onTouchUp(element, x, y)
  element.Overlay:setColor(1, 1, 1)
  if not self.activated then
    self.activated = true
    print("Closing combo pack popup")
    game.popPopUp()
  end
end
return QuadMultipack
