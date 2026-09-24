local StoreBundlePopupUI = {
  Fade = {},
  MainPanel = {},
  TitleText = {
    Text = {}
  },
  DescriptionText = {
    Text = {}
  },
  Contents = {},
  FooterFrame = {
    Sprite = {},
    TagSprite = {
      Sprite = {}
    },
    TagValue = {
      Text = {}
    },
    OldValue = {
      Text = {}
    },
    RedStrip = {
      Sprite = {}
    },
    PercentageLabel = {
      Text = {},
      Sprite = {}
    }
  },
  OfferTime = {
    Text = {}
  }
}
function StoreBundlePopupUI:onInit()
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function StoreBundlePopupUI:onPostInit()
  self.items = {}
  local selected = store:getSelected()
  self.storeItemID = selected:GetVar("ItemId"):GetInt()
  self.storeItemData = game.getStoreItemData(self.storeItemID)
  local titleVariationRefID = self.storeItemData:title() .. "_VARIATION"
  local titleStr = LOC(titleVariationRefID)
  if titleStr == titleVariationRefID then
    titleStr = LOC(self.storeItemData:title())
  end
  print("Setting Title:", titleStr)
  self.TitleText.Text:GetVar("text"):SetString(titleStr)
  print("Setting Description:", self.storeItemData:description())
  self.DescriptionText.Text:GetVar("text"):SetString(self.storeItemData:description())
  local promo
  if selected("IsPromoItem"):GetInt() == 1 then
    promo = game.getPromoByName(self.storeItemData:name())
  end
  local originalItem = self.storeItemData:getOriginalItem()
  if originalItem:isValid() then
    self.FooterFrame.OldValue.Text:GetVar("text"):SetString(originalItem:priceStr())
    self.FooterFrame.TagValue.Text:GetVar("text"):SetString(self.storeItemData:priceStr())
    self.FooterFrame.PercentageLabel.Text:GetVar("text"):SetString("WOW!")
  elseif promo then
    self.FooterFrame.TagValue.Text:GetVar("text"):SetString(self.storeItemData:priceStr())
    local replacesText = LOC("WARM_UP_PACK_PERCENTAGE")
    replacesText = replacesText:gsub("XXX", promo:discountText())
    self.FooterFrame.PercentageLabel.Text:GetVar("text"):SetString(replacesText)
    self.FooterFrame.Sprite:GetVar("visible"):SetInt(0)
    self.FooterFrame.OldValue.Text:GetVar("visible"):SetInt(0)
    self.FooterFrame.RedStrip.Sprite:GetVar("visible"):SetInt(0)
    self.FooterFrame.TagSprite:setOrientation(lua_sys.MenuOrientation(0, 0, -1, lua_sys.HCENTER, lua_sys.VCENTER))
    self.FooterFrame.TagSprite:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    self.FooterFrame.TagValue:GetVar("xOffset"):SetFloat(0)
    self.FooterFrame.TagValue.Text:GetVar("size"):SetFloat(0.37 * game.windowScaleY())
    self.FooterFrame.PercentageLabel:relativeTo(self.FooterFrame.TagSprite)
    self.FooterFrame.PercentageLabel:setRelativeObjectAnchors(lua_sys.RIGHT, lua_sys.VCENTER)
    self.FooterFrame.PercentageLabel:setOrientation(lua_sys.MenuOrientation(5 * game.windowScaleY(), -5 * game.windowScaleY(), -1, lua_sys.HCENTER, lua_sys.VCENTER))
  else
    self.FooterFrame.Sprite:GetVar("visible"):SetInt(0)
    self.FooterFrame.OldValue.Text:GetVar("visible"):SetInt(0)
    self.FooterFrame.RedStrip.Sprite:GetVar("visible"):SetInt(0)
    self.FooterFrame.PercentageLabel.Text:GetVar("visible"):SetInt(0)
    self.FooterFrame.PercentageLabel.Sprite:GetVar("visible"):SetInt(0)
    self.FooterFrame.TagValue.Text:GetVar("text"):SetString(self.storeItemData:priceStr())
    self.FooterFrame.TagSprite:setOrientation(lua_sys.MenuOrientation(0, 0, -1, lua_sys.HCENTER, lua_sys.VCENTER))
    self.FooterFrame.TagSprite:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    self.FooterFrame.TagValue:GetVar("xOffset"):SetFloat(0)
    self.FooterFrame.TagValue.Text:GetVar("size"):SetFloat(0.37 * game.windowScaleY())
  end
  local availabilityEvent = self.storeItemData:getAvailabilityEvent()
  if availabilityEvent then
    if originalItem:isValid() then
      self.OfferTime.Text:GetVar("text"):SetString(LOC("ONSALE_UNTIL") .. " " .. game.timeToString(availabilityEvent:timeRemainingSec(), true))
    else
      self.OfferTime.Text:GetVar("text"):SetString(LOC("AVAILABLE_UNTIL") .. " " .. game.timeToString(availabilityEvent:timeRemainingSec(), true))
    end
  elseif promo then
    local timeRemaining = promo:timeRemainingSec()
    self.OfferTime.Text:GetVar("text"):SetString(LOC("WARM_UP_PACK_TIME") .. " " .. game.timeToString(timeRemaining, true))
  else
    self.OfferTime.Text:GetVar("visible"):SetInt(0)
    local yOffset = 24 * game.menuScaleY()
    self.Contents:GetVar("yOffset"):SetFloat(self.Contents:GetVar("yOffset"):GetFloat() + yOffset)
    self.FooterFrame:GetVar("yOffset"):SetFloat(self.FooterFrame:GetVar("yOffset"):GetFloat() + yOffset)
  end
  self.Contents:populate(self.storeItemData:contents(), {variation = 1})
  if promo and promo:promoType() == game.PromotionType_DoyPromo then
    self:SetupAsDoY()
  end
  self:Show()
end
function StoreBundlePopupUI:SetupAsDoY()
  local garnish = menu:addTemplateElement("template_spritesheet", "DoYGarnish1", self.MainPanel)
  garnish:relativeTo(self.MainPanel)
  garnish:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
  garnish:setOrientation(lua_sys.MenuOrientation(-16 * game.menuScaleX(), -30 * game.menuScaleX(), -1, lua_sys.LEFT, lua_sys.TOP))
  garnish:init()
  garnish:setPositionBroadcast(true)
  garnish:postInit()
  garnish.Sprite("sheetName"):SetString("xml_resources/multipack_sheet.xml")
  garnish.Sprite("spriteName"):SetString("Yay_sticker2")
  garnish.Sprite("size"):SetFloat(0.45 * game.menuScaleX())
  garnish.Sprite("layer"):SetString("Tutorial")
  garnish = menu:addTemplateElement("template_spritesheet", "DoYGarnish2", self.MainPanel)
  garnish:relativeTo(self.MainPanel)
  garnish:setRelativeObjectAnchors(lua_sys.RIGHT, lua_sys.TOP)
  garnish:setOrientation(lua_sys.MenuOrientation(-16 * game.menuScaleX(), -30 * game.menuScaleX(), -1, lua_sys.RIGHT, lua_sys.TOP))
  garnish:init()
  garnish:setPositionBroadcast(true)
  garnish:postInit()
  garnish.Sprite("sheetName"):SetString("xml_resources/multipack_sheet.xml")
  garnish.Sprite("spriteName"):SetString("Yay_sticker2")
  garnish.Sprite("hFlip"):SetInt(1)
  garnish.Sprite("size"):SetFloat(0.45 * game.menuScaleX())
  garnish.Sprite("layer"):SetString("Tutorial")
end
function StoreBundlePopupUI:queuePop()
  self:Hide()
end
function StoreBundlePopupUI:purchaseItem()
  self:root():popPopUp()
  print("Buying Store Bundle:", self.storeItemData:name())
  game.showSpinner()
  game.buyItem(self.storeItemID)
end
function StoreBundlePopupUI:Show()
  self.Fade:Show()
  self.MainPanel:Show()
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function StoreBundlePopupUI:Hide()
  self.Fade:Hide()
  self.MainPanel:Hide()
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
return StoreBundlePopupUI
