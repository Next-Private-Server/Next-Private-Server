local PromoCenterItem = {
  Button = {
    UpSprite = {},
    Text = {},
    Touch = {}
  }
}
local initialButtonScale = 0.15 * game.hudScale()
function PromoCenterItem:Init(promo)
  self.promo = promo
  if self.promo then
    self.secs = promo:timeRemainingSec()
    self.Button.UpSprite:GetVar("sheetName"):SetString("xml_resources/" .. self.promo:iconSheet())
    self.Button.UpSprite:GetVar("spriteName"):SetString(self.promo:iconImage())
  else
    self:Hide()
  end
end
function PromoCenterItem:onTick(dt)
  if self.promo then
    local max = self.promo:getMaxActivations()
    if max > 0 and max <= self.promo:getActivationCount() then
      self:Hide()
      return
    end
    local newVal = self.promo:timeRemainingSec()
    if self.secs ~= newVal then
      self.secs = newVal
      self.Button.Text:GetVar("size"):SetFloat(initialButtonScale)
      self.Button.Text:GetVar("text"):SetString(game.timeToString(newVal, true))
      if newVal <= 0 then
        self:Hide()
      end
    end
  end
end
local canShowPromo = function(promo)
  if not promo then
    return false
  end
  if promo:promoType() == game.PromotionType_SideBySidePack then
    return false
  end
  local max = promo:getMaxActivations()
  if max > 0 and max <= promo:getActivationCount() then
    return false
  end
  if 0 >= promo:timeRemainingSec() then
    return false
  end
  return true
end
function PromoCenterItem:isActive()
  return self.promo and canShowPromo(self.promo)
end
function PromoCenterItem:Hide()
  self.Button.UpSprite:GetVar("visible"):SetInt(0)
  self.Button.Text:GetVar("visible"):SetInt(0)
  self.Button.Touch:GetVar("enabled"):SetInt(0)
end
function PromoCenterItem:Show()
  self.Button.UpSprite:GetVar("visible"):SetInt(1)
  self.Button.Text:GetVar("visible"):SetInt(1)
  self.Button.Touch:GetVar("enabled"):SetInt(1)
end
function PromoCenterItem:SetAlpha(alpha)
  self.Button.UpSprite:GetVar("alpha"):SetFloat(alpha)
  self.Button.Text:GetVar("alpha"):SetFloat(alpha)
end
function PromoCenterItem.Button.Touch:onTouchUp(element, x, y)
  self:super_onTouchUp(element, x, y)
  local getPromoMenu = function(promo)
    if promo:getMultipackPack():size() == 4 then
      return "quad_multipack"
    else
      return "combo_pack"
    end
  end
  if game.popUpLevel() <= 1 and manager:isIdle() then
    local promo = element:parent().promo
    if promo then
      local placement = promo:placement()
      local hasNativePlacement = false
      if placement ~= "" then
        local nativePlacement = game.nativePlacement(placement)
        hasNativePlacement = nativePlacement and nativePlacement:allImagesLoaded()
        if hasNativePlacement and placement == "combo_pack" and promo:promoId() ~= 11 then
          hasNativePlacement = false
        end
      end
      if hasNativePlacement then
        game.pushPopUp("newsflash")
        game.topPopUp():GetVar("placement"):SetString(placement)
        game.topPopUp():GetVar("index"):SetInt(0)
        game.topPopUp():DoStoredScript("setUpElements")
      else
        game.logEvent("promo_show", "level", tostring(game.playerLevel()), "island_id", tostring(game.currentIsland()), "origin", "promo_no_placement", "placement", placement)
        local promoMenu = getPromoMenu(promo)
        local popup = game.pushPopUp(promoMenu)
        if popup and popup.Init then
          popup:Init(promo)
        end
      end
    end
  end
end
return PromoCenterItem
