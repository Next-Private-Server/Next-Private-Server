local OffsetTransition = include("OffsetTransition")
local PromoCenter = {
  Tray = {
    BG = {}
  },
  ToggleButton = {
    Touch = {},
    Arrow = {}
  },
  TouchBlocker = {},
  isTrayOpen = false
}
local NUM_ROWS = 1
local marginTop = 4 * game.menuScaleX()
local marginLeft = 4 * game.menuScaleX()
local spacing = 4 * game.menuScaleX()
local itemSize = 56 * game.hudScale()
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
local root
local function initTray(self)
  local startX = 0
  self.Tray:setOrientation(lua_sys.MenuOrientation(0, 0, -1, lua_sys.LEFT, lua_sys.TOP))
  self.Tray.offsetTransition = OffsetTransition:new({
    startX = startX,
    endX = -self.Tray:absW() + self:absW(),
    onUpdate = function(x, y)
      self.Tray:GetVar("xOffset"):SetFloat(x)
      local endX = -self.Tray:absW() + self:absW()
      local alpha = 1 - (x - endX) / (startX - endX)
      self.Tray.BG("alpha"):SetFloat(alpha)
      local arrow = self.ToggleButton.Arrow
      if arrow.openAngle and arrow.closeAngle then
        local angleRange = arrow.closeAngle - arrow.openAngle
        arrow:V("rotation"):SetFloat((arrow.openAngle + angleRange * (1 - alpha)) * math.pi / 180)
      end
      if self.promos and #self.promos > NUM_ROWS + 1 then
        for i = NUM_ROWS + 1, #self.promos do
          local item = self.promos[i].entry
          if item then
            item:SetAlpha(alpha)
          end
        end
      end
    end
  })
  table.insert(self.tickables, self.Tray.offsetTransition)
  self.isTrayOpen = false
  self.Tray.offsetTransition:SetOffset(0, 0)
  self.Tray.TrayTouchBlocker("enabled"):SetInt(0)
  self.TouchBlocker("enabled"):SetInt(0)
  function self.TouchBlocker.onTouchUp()
    self:closeTray()
  end
end
function PromoCenter:onInit()
  root = self
  self.initialized = false
  self.tickables = {}
  self.Tray.BG("visible"):SetInt(0)
  self:hideToggleButton()
  self.TouchBlocker("enabled"):SetInt(0)
  self:SetupGenericListener(game.engineReceiver(), "game::msg::MsgContextBarStateChange", "gotMsgContextBarStateChange")
end
function PromoCenter:initialize()
  if not self.initialized then
    local contextBarHeight = manager:getHeight()
    local availableHeight = lua_sys.screenHeight() - self:absY() - contextBarHeight - 24 * game.menuScaleX()
    print("PromoCenter: HUD available height:", availableHeight)
    if availableHeight >= itemSize * 3 + spacing * 4 then
      NUM_ROWS = 2
    else
      NUM_ROWS = 1
    end
    self:populate()
    self.Tray.BG("visible"):SetInt(1)
    initTray(self)
    self:showToggleButton()
    self:SetupGenericListener(game.engineReceiver(), "store::msg::MsgPurchaseComplete", "gotMsgPurchaseComplete")
    self:SetupGenericListener(game.engineReceiver(), "sys::msg::MsgPushPopUpGlobal", "gotMsgPushPopUpGlobal")
    self.initialized = true
  end
end
function PromoCenter:gotMsgContextBarStateChange(msg)
  if not self.initialized then
    self:initialize()
  end
end
function PromoCenter:populate()
  local offsetX = marginLeft
  local offsetY = marginTop
  local row = 0
  local totalPromos = 0
  local promos = game.getPromos()
  for i = 0, promos:size() - 1 do
    local promo = promos[i]
    if promo and canShowPromo(promo) then
      totalPromos = totalPromos + 1
    end
  end
  local function updateItemCursor()
    row = row + 1
    if row < NUM_ROWS or totalPromos <= NUM_ROWS + 1 then
      offsetY = offsetY + itemSize
    else
      offsetY = marginTop
      offsetX = offsetX + itemSize + spacing
      row = 0
    end
  end
  self.promos = {}
  local function createPromoItem(promoData, entryName)
    local entry = menu:addTemplateElement("template_promo_center_item", entryName, self.Tray)
    if entry then
      local priority = -1
      entry:setOrientation(lua_sys.MenuOrientation(offsetX, offsetY, priority, lua_sys.LEFT, lua_sys.TOP))
      entry:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
      entry:init()
      entry:setPositionBroadcast(true)
      entry:Init(promoData)
      entry:postInit()
      updateItemCursor()
    end
    return entry
  end
  for i = 0, promos:size() - 1 do
    local promo = promos[i]
    if promo and canShowPromo(promo) then
      local entry = createPromoItem(promo, "PromoCenterItem_" .. tostring(promo:promoId()))
      if entry then
        table.insert(self.promos, {entry = entry, promo = promo})
      end
    end
  end
  local numColumns = math.ceil(#self.promos / NUM_ROWS)
  local trayW = marginLeft * 2 + (itemSize * numColumns + spacing * (numColumns - 1))
  local trayH = marginTop * 2 + (itemSize * NUM_ROWS + spacing * (NUM_ROWS - 1))
  self.Tray:setSize(lua_sys.Vector2(trayW, trayH))
  self:setPositionBroadcast(true)
  local promoCenterHeight = itemSize * (NUM_ROWS + 1) + spacing * (NUM_ROWS + 2)
  self:setSize(lua_sys.Vector2(self:absW(), promoCenterHeight))
end
function PromoCenter:refresh()
  local offsetX = marginLeft
  local offsetY = marginTop
  local row = 0
  local numPromos = #self.promos
  local validPromos = {}
  for i = 1, #self.promos do
    local promoData = self.promos[i].promo
    local entry = self.promos[i].entry
    if entry:isActive() then
      table.insert(validPromos, {entry = entry, promo = promoData})
    else
      entry:Hide()
    end
  end
  local function updateItemCursor()
    row = row + 1
    if row < NUM_ROWS or #validPromos <= NUM_ROWS + 1 then
      offsetY = offsetY + itemSize
    else
      offsetY = marginTop
      offsetX = offsetX + itemSize + spacing
      row = 0
    end
  end
  for k, v in ipairs(validPromos) do
    v.entry:setOrientation(lua_sys.MenuOrientation(offsetX, offsetY, -1, lua_sys.LEFT, lua_sys.TOP))
    v.entry:setRelativeObjectAnchors(lua_sys.LEFT, lua_sys.TOP)
    updateItemCursor()
  end
  if numPromos ~= #validPromos then
    self.promos = validPromos
    local numColumns = math.ceil(#self.promos / NUM_ROWS)
    local trayW = marginLeft * 2 + (itemSize * numColumns + spacing * (numColumns - 1))
    local trayH = marginTop * 2 + (itemSize * NUM_ROWS + spacing * (NUM_ROWS - 1))
    self.Tray:setSize(lua_sys.Vector2(trayW, trayH))
    if self.Tray.offsetTransition then
      self.Tray.offsetTransition.endX = -trayW + self:absW()
    end
    if not self.isTrayOpen then
      for i = 1, #self.promos do
        local item = self.promos[i].entry
        if item then
          if #validPromos <= NUM_ROWS + 1 then
            item:SetAlpha(1)
          else
            item:SetAlpha(i > NUM_ROWS and 0 or 1)
          end
        end
      end
    end
    self:showToggleButton()
  end
end
function PromoCenter:onTick(dt)
  for i = 1, #self.tickables do
    self.tickables[i]:Tick(dt)
  end
  self.refreshTime = (self.refreshTime or 0) + dt
  if self.refreshTime > 5 then
    self.refreshTime = 0
    self:refresh()
  end
end
function PromoCenter:openTray()
  if not self.initialized then
    return
  end
  if not self.isTrayOpen then
    self.Tray.offsetTransition:Show()
    self.isTrayOpen = true
    self.TouchBlocker("enabled"):SetInt(1)
  end
end
function PromoCenter:closeTray()
  if not self.initialized then
    return
  end
  if self.isTrayOpen then
    self.Tray.offsetTransition:Hide()
    self.isTrayOpen = false
    self.TouchBlocker("enabled"):SetInt(0)
  end
end
function PromoCenter:toggle()
  if self.isTrayOpen then
    self:closeTray()
  else
    self:openTray()
  end
end
function PromoCenter:Show()
  if not self.initialized then
    return
  end
  self.Tray.BG("visible"):SetInt(1)
  if self.promos then
    for i = 1, #self.promos do
      self.promos[i].entry:Show()
    end
  end
  self:showToggleButton()
end
function PromoCenter:Hide()
  self.Tray.BG("visible"):SetInt(0)
  if self.promos then
    for i = 1, #self.promos do
      self.promos[i].entry:Hide()
    end
  end
  self:hideToggleButton()
  self.TouchBlocker("enabled"):SetInt(0)
end
function PromoCenter:DebugPrintAllPromoInfo()
  print("Promos:")
  print("====================================")
  local promos = game.getPromos()
  for i = 0, promos:size() - 1 do
    local promo = promos[i]
    if promo then
      print("Promo ID:", promo:promoId())
      print("Promo Type:", promo:promoType())
      print("Promo Placement:", promo:placement())
      print("Promo Max Activations:", promo:getMaxActivations())
      print("Promo Activation Count:", promo:getActivationCount())
      print("Promo StoreItem Name:", promo:storeItemName())
      print("Promo FullPriceText:", promo:fullPriceText())
      print("Promo DiscountText:", promo:discountText())
      print("Promo Anim:", promo:anim())
      print("Promo StoreItemTitle:", promo:storeItemTitle())
      print("Promo StoreItemDescription:", promo:storeItemDescription())
      print("Promo Currently Active:", promo:currentlyActive())
      print("Promo Time Remaining:", promo:timeRemainingSec(), "seconds")
      print("====================================")
    end
  end
end
function PromoCenter:gotMsgPurchaseComplete(msg)
  if msg.success_ then
    self:refresh()
  end
end
function PromoCenter:gotMsgPushPopUpGlobal(msg)
  if msg.menuName ~= self:name() and self.isTrayOpen then
    self:closeTray()
  end
end
function PromoCenter:showToggleButton()
  if self.promos and #self.promos > NUM_ROWS + 1 then
    self.ToggleButton:setVisible()
    self.ToggleButton.Arrow("visible"):SetInt(1)
    self.ToggleButton.ButtonLabel("visible"):SetInt(1)
    self.ToggleButton.Overlay("visible"):SetInt(1)
  else
    self:hideToggleButton()
  end
end
function PromoCenter:hideToggleButton()
  self.ToggleButton:setInvisible()
  self.ToggleButton.Arrow("visible"):SetInt(0)
  self.ToggleButton.ButtonLabel("visible"):SetInt(0)
  self.ToggleButton.Overlay("visible"):SetInt(0)
end
function PromoCenter.ToggleButton.Touch:onTouchUp(element, x, y)
  self:super_onTouchUp(element, x, y)
  element:parent():toggle()
end
return PromoCenter
