local MenuHelpers = require("MenuHelpers")
local ComboPack = {
  Frame = {},
  TitleText = {
    Text = {}
  },
  Bundle = {},
  BuyButton = {
    Touch = {}
  },
  CloseButton = {
    Touch = {}
  },
  promo = nil
}
function ComboPack:onInit()
  game.deselectSelectedObject()
  local contextBar = game.getContextBar()
  if contextBar then
    contextBar:setContext("MAP")
    self.CloseButton:Hide()
  else
    self.CloseButton:Show()
  end
  game.logEvent("promo_menu_init", "promo", "combo_pack")
end
function ComboPack:Init(promo)
  self.promo = promo
  local promoName = self.promo:storeItemName()
  if promo:promoType() == game.PromotionType_DoyPromo then
    self:SetupAsDoY()
  end
  self.TitleText.Text:GetVar("text"):SetString(LOC(self.promo:storeItemTitle()))
  self.DescriptionText.Text:GetVar("text"):SetString(LOC(self.promo:storeItemDescription()))
  local comboId = game.storeItem(promoName, "combo")
  if comboId >= 0 then
    self.TagValue.Text:GetVar("text"):SetString(game.priceStr(comboId))
  else
    local bundleId = game.storeItem(promoName, "bundle")
    if bundleId >= 0 then
      self.TagValue.Text:GetVar("text"):SetString(game.priceStr(bundleId))
    end
  end
  self.OldValue.Text:GetVar("text"):SetString(self.promo:fullPriceText())
  self.RedStrip.Sprite:setSize(lua_sys.Vector2(self.OldValue:absW() + 7 * game.windowScaleY(), self.RedStrip.Sprite:absH()))
  local discountText = self.promo:discountText()
  local discountVal = tonumber(discountText) or 0
  if discountVal > 0 then
    local replacesText = LOC("WARM_UP_PACK_PERCENTAGE")
    replacesText = replacesText:gsub("XXX", discountText)
    self.PercentageLabel.Text:GetVar("text"):SetString(replacesText)
  else
    self.PercentageLabel.Sprite("visible"):SetInt(0)
    self.PercentageLabel.Text("visible"):SetInt(0)
  end
  if promoName and string.find(promoName, "anniv") then
    self.TitleText.Text:setColor(0, 0.57, 1)
  end
  self.FooterFrame.Sprite:GetVar("visible"):SetInt(0)
  self.OldValue.Text:GetVar("visible"):SetInt(0)
  self.RedStrip.Sprite:GetVar("visible"):SetInt(0)
  self.TagSprite:setOrientation(lua_sys.MenuOrientation(0, 0, -1, lua_sys.HCENTER, lua_sys.VCENTER))
  self.TagSprite:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
  self.TagValue:GetVar("xOffset"):SetFloat(0)
  self.TagValue.Text:GetVar("size"):SetFloat(0.37 * game.windowScaleY())
  if 0 < game.storeValue(game.storeItem(promoName, "bundle")) then
    local storeItemID = game.storeItem(promoName, "bundle")
    local storeItemData = game.getStoreItemData(storeItemID)
    self.Bundle:populate(storeItemData:contents(), {variation = 1})
  else
    local possibleComboPackItems = {
      {
        name = "diamond",
        type = game.LootType_Diamonds
      },
      {
        name = "coins",
        type = game.LootType_Coins
      },
      {
        name = "food",
        type = game.LootType_Food
      },
      {
        name = "key",
        type = game.LootType_Keys
      },
      {
        name = "relic",
        type = game.LootType_Relics
      }
    }
    local rewards = {}
    for i = 1, #possibleComboPackItems do
      local item = possibleComboPackItems[i]
      local amount = game.storeValue(game.storeItem(promoName, item.name))
      if amount > 0 then
        table.insert(rewards, {
          type = item.type,
          amount = amount
        })
      end
    end
    self.Bundle:populate(rewards, {variation = 1})
  end
  self:Show()
end
function ComboPack:SetupAsDoY()
  self.Frame.IcingL("visible"):SetInt(1)
  self.Frame.IcingL("spriteName"):SetString("Yay_sticker2")
  self.Frame.IcingL("size"):SetFloat(0.4 * game.menuScaleX())
  self.Frame.IcingL:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
  self.Frame.IcingL:setOrientation(lua_sys.MenuOrientation(-16 * game.menuScaleX(), -26 * game.menuScaleX(), -4, lua_sys.LEFT, lua_sys.TOP))
  self.Frame.IcingR("visible"):SetInt(1)
  self.Frame.IcingR("spriteName"):SetString("Yay_sticker2")
  self.Frame.IcingR("hFlip"):SetInt(1)
  self.Frame.IcingR("size"):SetFloat(0.4 * game.menuScaleX())
  self.Frame.IcingR:setRelativeObjectAnchors(lua_sys.RIGHT, lua_sys.TOP)
  self.Frame.IcingR:setOrientation(lua_sys.MenuOrientation(-12 * game.menuScaleX(), -26 * game.menuScaleX(), -4, lua_sys.RIGHT, lua_sys.TOP))
end
function ComboPack:onTick(dt)
  if self.promo then
    local secsRemaining = self.promo:timeRemainingSec()
    self.OfferTime.Text:GetVar("text"):SetString(game.getLocalizedText("WARM_UP_PACK_TIME") .. game.timeToString(secsRemaining, true))
  end
end
function ComboPack:queuePop()
  self:Hide()
end
function ComboPack:Show()
  self.FadedBG:Show()
  self.Frame:Show()
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function ComboPack:Hide()
  self.FadedBG:Hide()
  self.Frame:Hide()
  lua_sys.playSoundFx("audio/sfx/menu_slide.wav")
end
function ComboPack.BuyButton.Touch:onTouchUp(element, x, y)
  self:super_onTouchUp(element, x, y)
  local top = element:parent()
  print("Buying Combo Pack:", top.promo:storeItemName())
  local contextBar = game.getContextBar()
  if contextBar then
    contextBar:setContext(contextBar:reserveState())
  end
  game.logEvent("promo_menu_buy_click", "promo", "combo_pack")
  top:root():popPopUp()
  if game.storeContext() then
    game.showSpinner()
  end
  local comboId = game.storeItem(top.promo:storeItemName(), "combo")
  if comboId >= 0 then
    game.buyItem(comboId)
  else
    local bundleId = game.storeItem(top.promo:storeItemName(), "bundle")
    if bundleId >= 0 then
      game.buyItem(bundleId)
    else
      print("Error: could not find combo or bundle store item for promo " .. top.promo:storeItemName())
    end
  end
  if contextBar then
    contextBar:setContext(contextBar:reserveState())
  end
end
function ComboPack.CloseButton.Touch:onTouchUp(element, x, y)
  self:super_onTouchUp(element, x, y)
  element.Overlay:setColor(1, 1, 1)
  if not self.activated then
    self.activated = true
    print("Closing combo pack popup")
    game.popPopUp()
  end
end
return ComboPack
