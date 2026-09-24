local template_MultipackEntry = {
  Sprite = {},
  Animation = {
    Spotlight = {},
    Sprite = {}
  },
  BuyButton = {
    Touch = {},
    Text = {}
  },
  CostumeText = {
    Text = {}
  },
  CostumeIcon = {},
  ItemDesc = {},
  NumCurrencies = 0,
  storeId = 0,
  lastCurrencyTemplate = nil
}
function template_MultipackEntry:onInit()
end
function template_MultipackEntry:onPostInit()
end
function template_MultipackEntry:disable()
  if self.Sprite("visible"):GetInt() == 1 then
    self.Animation.Spotlight:setColor(0.5, 0.5, 0.5)
    self.Animation.Sprite:setColor(0.5, 0.5, 0.5)
    self.BuyButton:disable()
    for i = 0, self.NumCurrencies - 1 do
      local currencyItem = self:GetElement("currencyItem" .. i)
      if currencyItem ~= nil then
        currencyItem:disable()
      end
    end
  end
end
function template_MultipackEntry:addCurrency(_currencyType, _amount, _layer)
  local vars = {
    currencyType = _currencyType,
    amount = _amount,
    layer = _layer
  }
  local currencyItem = menu:addTemplateElementEx("template_currency", "currencyItem" .. self.NumCurrencies, self, vars)
  if self.lastCurrencyTemplate == nil then
    currencyItem:relativeTo(self.BuyButton)
    currencyItem:setOrientation(lua_sys.MenuOrientation(0, -2 * game.menuScaleX(), -1, lua_sys.HCENTER, lua_sys.BOTTOM))
    currencyItem:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
  else
    currencyItem:relativeTo(self.lastCurrencyTemplate)
    currencyItem:setOrientation(lua_sys.MenuOrientation(0, 0, 0, lua_sys.HCENTER, lua_sys.BOTTOM))
    currencyItem:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
  end
  self.lastCurrencyTemplate = currencyItem
  local costumeText = self.ItemDesc
  costumeText:relativeTo(self.lastCurrencyTemplate)
  costumeText:setOrientation(lua_sys.MenuOrientation(costumeText("xOffset"):GetInt(), costumeText("yOffset"):GetInt(), 0, lua_sys.HCENTER, lua_sys.BOTTOM))
  costumeText:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
  currencyItem:init()
  currencyItem:setPositionBroadcast(true)
  currencyItem:postInit()
  self.NumCurrencies = self.NumCurrencies + 1
end
function template_MultipackEntry:initStoreId(storeId)
  self.storeId = storeId
end
function template_MultipackEntry:populatePrice(priceStr)
  self.BuyButton.Text("text"):SetString(priceStr)
end
function template_MultipackEntry:populateDesc(priceText)
  self.ItemDesc.Text("text"):SetString(priceText)
end
function template_MultipackEntry:populateCostume(costumeId)
  self.Animation:populateCostume(costumeId)
  self.CostumeIcon("visible"):SetInt(1)
end
function template_MultipackEntry.Animation:populateCostume(costumeId)
  self.Sprite:populateCostume(costumeId, self)
end
function template_MultipackEntry.Animation.Sprite:populateCostume(costumeId, element)
  self:setScale(Vector2(1, 1))
  local monsterId = game.getCostumeData(costumeId).monsterId
  self("animationName"):SetString("xml_bin/" .. game.getMonsterAnimationFileFromType(monsterId))
  local entityId = game.monsterTypeEntityId(monsterId)
  self("animation"):SetString(game.getEntityData(entityId):animationCostumeMenuName())
  game.applyCostumeToAnimComponent(self, costumeId)
  local scale = 80 * game.menuScaleY() / self:size().y
  self:setScale(Vector2(scale, scale))
  self("yOffset"):SetFloat(0 * game.hudScale())
end
function template_MultipackEntry.BuyButton.Touch:onTouchDown(element)
  self:super_onTouchDown(element)
end
function template_MultipackEntry.BuyButton.Touch:onTouchUp(element)
  self:super_onTouchUp(element)
  manager:setContext(manager:reserveState())
  self:root():popPopUp()
  game.buyItem(element:parent().storeId)
end
function template_MultipackEntry.BuyButton.Touch:onTouchRelease(element)
  self:super_onTouchRelease(element)
end
return template_MultipackEntry
