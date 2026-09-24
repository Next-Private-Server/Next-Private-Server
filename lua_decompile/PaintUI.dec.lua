local ITEMS_PER_PAGE = 10
local PaintUI = {}
PaintUI.currentMarketTab = ""
PaintUI.currentMode = ""
PaintUI.currentPage = 1
PaintUI.totalPages = 1
PaintUI.selectedStructureId = 0
PaintUI.allTiles = nil
PaintUI.storageAdjustments = {}
PaintUI.coinsAdjusted = 0
PaintUI.diamondsAdjusted = 0
PaintUI.applyButton = nil
PaintUI.marketArrow = nil
PaintUI.isEtherealIsland = false
PaintUI.isAnimating = false
PaintUI.isVisible = false
function PaintUI.onInit(element)
  PaintUI.applyButton = element.ApplyButton
  PaintUI.marketArrow = element.Panel.ShowHide.Arrow
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPaintCurrencyAdjust", "gotMsgPaintCurrencyAdjust")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPaintInventoryAdjust", "gotMsgPaintInventoryAdjust")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPaintCancelPrompt", "gotMsgPaintCancelPrompt")
  PaintUI.isEtherealIsland = game.isEtherealIsland()
  local panelElement = element.Panel
  local tileScale = 0.6
  for i = 0, ITEMS_PER_PAGE - 1 do
    local tileItem = menu:addTemplateElement("template_paint_tile_item", "paintTileItem" .. i + 1, panelElement)
    tileItem:relativeTo(panelElement)
    tileItem:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
    tileItem:setOrientation(lua_sys.MenuOrientation(i % 2 * (84 * tileScale * game.menuScaleY()) - 12 * tileScale * game.menuScaleY() + 50 * game.menuScaleY(), math.floor(i / 2) * (64 * tileScale * game.menuScaleY()) + 60 * tileScale * game.menuScaleY(), -3, lua_sys.HCENTER, lua_sys.VCENTER))
    tileItem:init()
    tileItem:setPositionBroadcast(true)
    tileItem:postInit()
  end
  PaintUI.selectedStructureId = game.getPaintSelectedStructureId()
  if PaintUI.selectedStructureId == 0 then
    element.PlaceButton:DoStoredScript("disable")
  else
    element.PlaceButton:DoStoredScript("enable")
  end
  PaintUI.allTiles = game.getAvailableIslandTiles()
end
function PaintUI.onPostInit(element)
  game.updatePaintCurrencyCounters()
  PaintUI.marketVisibleXOffset = element.Panel:V("xOffset"):GetFloat()
  PaintUI.marketHiddenXOffset = PaintUI.marketVisibleXOffset - 145 * game.menuScaleY()
  element.Panel:V("xOffset"):SetFloat(PaintUI.marketHiddenXOffset)
  element.PathText("text"):SetString(game.structureTypeName(PaintUI.selectedStructureId))
  PaintUI.marketTransitionTime = 0.25
  PaintUI.isMarketVisible = true
  PaintUI.isMarketAnimating = true
end
function PaintUI.onTick(element, dt)
  if PaintUI.isMarketAnimating then
    dt = math.min(dt, 0.033)
    PaintUI.marketTransitionTime = math.max(0, PaintUI.marketTransitionTime - dt)
    local easedTime = 1 - lua_sys.Quadratic_EaseIn(PaintUI.marketTransitionTime, 0, 1, 0.25)
    if PaintUI.isMarketVisible then
      marketXOffset = lerp(PaintUI.marketHiddenXOffset, PaintUI.marketVisibleXOffset, easedTime)
      arrowAngle = lerp(PaintUI.marketArrow.closeAngle, PaintUI.marketArrow.openAngle, easedTime)
      arrowXOffset = lerp(0, -20 * game.menuScaleY(), easedTime)
    else
      marketXOffset = lerp(PaintUI.marketVisibleXOffset, PaintUI.marketHiddenXOffset, easedTime)
      arrowAngle = lerp(PaintUI.marketArrow.openAngle, PaintUI.marketArrow.closeAngle, easedTime)
      arrowXOffset = lerp(-20 * game.menuScaleY(), 0, easedTime)
    end
    element.Panel:V("xOffset"):SetFloat(marketXOffset)
    PaintUI.marketArrow:parent():V("xOffset"):SetFloat(arrowXOffset)
    PaintUI.marketArrow:V("rotation"):SetFloat(arrowAngle * math.pi / 180)
    if PaintUI.marketTransitionTime <= 0 then
      PaintUI.isMarketAnimating = false
    end
  end
end
function PaintUI.getMarketTab(element)
  return PaintUI.currentMarketTab
end
function PaintUI.toggleMarket(element)
  if PaintUI.isMarketAnimating then
    return
  end
  PaintUI.marketTransitionTime = 0.25
  PaintUI.isMarketVisible = not PaintUI.isMarketVisible
  PaintUI.isMarketAnimating = true
end
function PaintUI.selectMarketTab(element, tab)
  if PaintUI.currentMarketTab ~= tab then
    PaintUI.currentMarketTab = tab
    PaintUI.currentPage = -1
    PaintUI.refreshMarket(element)
  end
  element.TabPathNative:DoStoredScript("deselectTab")
  element.TabPathFilters:DoStoredScript("deselectTab")
  element[PaintUI.currentMarketTab]:DoStoredScript("selectTab")
  if not PaintUI.isMarketVisible then
    PaintUI.toggleMarket(element)
  end
end
function PaintUI.refreshMarket(element)
  if PaintUI.currentMarketTab == "TabPathFilters" then
    PaintUI.totalPages = 1
    element.ShowMonstersBox:DoStoredScript("setVisible")
    element.ShowDecorationsBox:DoStoredScript("setVisible")
    element.ShowStructuresBox:DoStoredScript("setVisible")
    element.ShowObstaclesBox:DoStoredScript("setVisible")
    element.ShowGridBox:DoStoredScript("setVisible")
    for i = 1, ITEMS_PER_PAGE do
      element["paintTileItem" .. i]:DoStoredScript("hide")
      element["paintTileItem" .. i].Cost:DoStoredScript("hide")
    end
  else
    element.ShowMonstersBox:DoStoredScript("setInvisible")
    element.ShowDecorationsBox:DoStoredScript("setInvisible")
    element.ShowStructuresBox:DoStoredScript("setInvisible")
    element.ShowObstaclesBox:DoStoredScript("setInvisible")
    element.ShowGridBox:DoStoredScript("setInvisible")
    PaintUI.refreshMarketItems(element)
  end
  PaintUI.updatePageNav(element)
end
function PaintUI:gotMsgPaintCurrencyAdjust(msg)
  PaintUI.coinsAdjusted = msg.coins
  PaintUI.diamondsAdjusted = msg.diamonds
  if PaintUI.coinsAdjusted < 0 or PaintUI.diamondsAdjusted < 0 then
    if PaintUI.applyButton.Overlay("spriteName"):GetString() ~= "button_no_save" then
      PaintUI.applyButton.Overlay("spriteName"):SetString("button_no_save")
    end
  elseif PaintUI.applyButton.Overlay("spriteName"):GetString() ~= "button_save" then
    PaintUI.applyButton.Overlay("spriteName"):SetString("button_save")
  end
end
function PaintUI:gotMsgPaintInventoryAdjust(msg)
  PaintUI.storageAdjustments[msg.structureId] = msg.storedAmount
  PaintUI.refreshMarketItems(self)
end
function PaintUI:gotMsgPaintCancelPrompt(msg)
  PaintUI.cancel()
end
function PaintUI.refreshMarketItems(element)
  local items = PaintUI.getFilteredItems()
  local numItems = #items
  if PaintUI.currentPage == -1 then
    PaintUI.currentPage = 1
    for i = 1, numItems do
      local tileInfo = items[i]
      if tileInfo.structureId == PaintUI.selectedStructureId then
        PaintUI.currentPage = math.floor((i - 1) / ITEMS_PER_PAGE) + 1
        break
      end
    end
  end
  PaintUI.totalPages = math.ceil(numItems / ITEMS_PER_PAGE)
  if PaintUI.currentPage > PaintUI.totalPages then
    PaintUI.currentPage = PaintUI.totalPages
  end
  local startItemIndex = (PaintUI.currentPage - 1) * ITEMS_PER_PAGE
  for i = 1, ITEMS_PER_PAGE do
    local itemIndex = startItemIndex + i
    local ele = element["paintTileItem" .. i]
    if itemIndex > 0 and numItems >= itemIndex then
      local hasEnoughCurrency = false
      local tileInfo = items[itemIndex]
      local storedAmount = tileInfo.storedAmount
      if PaintUI.storageAdjustments[tileInfo.structureId] ~= nil then
        storedAmount = tileInfo.originalStoredAmount + PaintUI.storageAdjustments[tileInfo.structureId]
      end
      ele:DoStoredScript("enable")
      if PaintUI.currentMode == "sell" then
        ele.Cost.Text("text"):SetString(tileInfo.salePrice)
        ele.Cost.Icon("spriteName"):SetString(game.coinsSpriteImgForThisIsland())
        ele.Cost.Text:setColor(0, 1, 0)
        ele.Cost:DoStoredScript("show")
        ele.Stored("text"):SetString("")
      elseif storedAmount > 0 then
        ele.Stored("text"):SetString("x" .. storedAmount)
        ele.Cost:DoStoredScript("hide")
      else
        ele.Cost:DoStoredScript("show")
        ele.Stored("text"):SetString("")
        if 0 < tileInfo.diamondPrice then
          hasEnoughCurrency = PaintUI.diamondsAdjusted < tileInfo.diamondPrice
          ele.Cost.Text("text"):SetString(tileInfo.diamondPrice)
          ele.Cost.Icon("spriteName"):SetString(game.StoreContext_SPRITE_DIAMOND)
          game.StoreContext_setCurrencyTypeColour(game.CurrencyType_Diamonds, ele.Cost.Text)
        else
          hasEnoughCurrency = PaintUI.coinsAdjusted < tileInfo.coinPrice
          ele.Cost.Text("text"):SetString(tileInfo.coinPrice)
          ele.Cost.Icon("spriteName"):SetString(game.coinsSpriteImgForThisIsland())
          if PaintUI.isEtherealIsland then
            game.StoreContext_setCurrencyTypeColour(game.CurrencyType_Shards, ele.Cost.Text)
          else
            game.StoreContext_setCurrencyTypeColour(game.CurrencyType_Coins, ele.Cost.Text)
          end
        end
      end
      local gfxPath = "xml_bin/" .. tileInfo.gfx
      if ele.tile("animationName"):GetString() ~= gfxPath then
        ele.tile("animationName"):SetString(gfxPath)
        ele:DoStoredScript("hide")
        ele:DoStoredScript("showDelay")
      else
        ele:DoStoredScript("show")
      end
      if game.playerLevel() < tileInfo.level then
        ele:DoStoredScript("disable")
        ele.Cost.Text("text"):SetString("?")
        ele.Stored("text"):SetString("")
        local txt = game.getLocalizedText("NOTIFICATION_REQUIRES_LEVEL")
        txt = select(1, txt:gsub("XXX", tileInfo.level))
        ele.Locked("text"):SetString(txt)
        ele.Locked:DoStoredScript("show")
      end
      ele("StructureId"):SetInt(tileInfo.structureId)
      if tileInfo.structureId == PaintUI.selectedStructureId then
        ele:DoStoredScript("select")
      else
        ele:DoStoredScript("deselect")
      end
    else
      ele:DoStoredScript("hide")
      ele.Cost:DoStoredScript("hide")
    end
  end
end
function PaintUI.getFilteredItems()
  local onlyNative = PaintUI.currentMarketTab == "TabPathNative"
  local onlyNonNative = PaintUI.currentMarketTab == "TabPathCrossIsland"
  local onlyStored = PaintUI.currentMarketTab == "TabPathStored"
  local items = {}
  for i = 0, PaintUI.allTiles:size() - 1 do
    local tileInfo = PaintUI.allTiles[i]
    if onlyStored then
      local storedAmount = tileInfo.storedAmount
      if PaintUI.storageAdjustments[tileInfo.structureId] ~= nil then
        storedAmount = tileInfo.originalStoredAmount + PaintUI.storageAdjustments[tileInfo.structureId]
      end
      if storedAmount > 0 then
        table.insert(items, tileInfo)
      end
    elseif onlyNative and tileInfo.isNative or onlyNonNative and not tileInfo.isNative then
      table.insert(items, tileInfo)
    end
  end
  if #items > 1 then
    table.sort(items, function(a, b)
      if onlyStored then
        local aStoredAmount = a.storedAmount
        if PaintUI.storageAdjustments[a.structureId] ~= nil then
          aStoredAmount = a.originalStoredAmount + PaintUI.storageAdjustments[a.structureId]
        end
        local bStoredAmount = b.storedAmount
        if PaintUI.storageAdjustments[b.structureId] ~= nil then
          bStoredAmount = b.originalStoredAmount + PaintUI.storageAdjustments[b.structureId]
        end
        if aStoredAmount ~= bStoredAmount then
          return aStoredAmount > bStoredAmount
        end
      end
      if a.diamondPrice ~= b.diamondPrice then
        return a.diamondPrice < b.diamondPrice
      elseif a.coinPrice ~= b.coinPrice then
        return a.coinPrice < b.coinPrice
      else
        return a.structureId < b.structureId
      end
    end)
  end
  return items
end
function PaintUI.updatePageNav(element)
  element.Panel.PageLabel("text"):SetString(PaintUI.currentPage .. "/" .. PaintUI.totalPages)
  if PaintUI.totalPages > 1 then
    element.Panel.PreviousButton:DoStoredScript("show")
    element.Panel.PageLabel:DoStoredScript("show")
    element.Panel.NextButton:DoStoredScript("show")
  else
    element.Panel.PreviousButton:DoStoredScript("hide")
    element.Panel.PageLabel:DoStoredScript("hide")
    element.Panel.NextButton:DoStoredScript("hide")
    return
  end
  if PaintUI.currentPage <= 1 then
    element.Panel.PreviousButton:DoStoredScript("disable")
    element.Panel.PreviousButton.Arrow:setColor(0.5, 0.5, 0.5)
  else
    element.Panel.PreviousButton:DoStoredScript("enable")
    element.Panel.PreviousButton.Arrow:setColor(1, 1, 1)
  end
  if PaintUI.currentPage >= PaintUI.totalPages then
    element.Panel.NextButton:DoStoredScript("disable")
    element.Panel.NextButton.Arrow:setColor(0.5, 0.5, 0.5)
  else
    element.Panel.NextButton:DoStoredScript("enable")
    element.Panel.NextButton.Arrow:setColor(1, 1, 1)
  end
end
function PaintUI.previousPage(element)
  if PaintUI.currentPage <= 1 then
    return
  end
  PaintUI.currentPage = PaintUI.currentPage - 1
  PaintUI.updatePageNav(element)
  PaintUI.refreshMarketItems(element)
end
function PaintUI.nextPage(element)
  if PaintUI.currentPage >= PaintUI.totalPages then
    return
  end
  PaintUI.currentPage = PaintUI.currentPage + 1
  PaintUI.updatePageNav(element)
  PaintUI.refreshMarketItems(element)
end
function PaintUI.selectTileOption(element, selectedElement, structureId)
  for i = 1, ITEMS_PER_PAGE do
    element["paintTileItem" .. i]:DoStoredScript("deselect")
  end
  selectedElement:DoStoredScript("select")
  PaintUI.selectedStructureId = structureId
  game.setPaintSelectedStructureId(structureId)
  element.PathText("text"):SetString(game.structureTypeName(structureId))
  if PaintUI.selectedStructureId == 0 then
    element.PlaceButton:DoStoredScript("disable")
  else
    element.PlaceButton:DoStoredScript("enable")
  end
end
function PaintUI.deselectAll(element)
  element.ResizeButton:DoStoredScript("deselect")
  element.StoreButton:DoStoredScript("deselect")
  element.PlaceButton:DoStoredScript("deselect")
  element.MoveButton:DoStoredScript("deselect")
  element.SellButton:DoStoredScript("deselect")
  element.FlipButton:DoStoredScript("deselect")
end
function PaintUI.getMode(element)
  return PaintUI.currentMode
end
function PaintUI.setMode(element, mode)
  if PaintUI.currentMode ~= mode then
    PaintUI.currentMode = mode
    game.setPaintState(PaintUI.currentMode)
    PaintUI.refreshMarketItems(element)
  end
end
function PaintUI.apply(element)
  if PaintUI.coinsAdjusted < 0 or 0 > PaintUI.diamondsAdjusted then
    if game.getPopUp() ~= "popup_paint_apply_store_confirm" then
      game.pushPopUp("popup_paint_apply_store_confirm")
    end
  elseif game.getPopUp() ~= "popup_paint_apply_confirm" then
    game.pushPopUp("popup_paint_apply_confirm")
  end
end
function PaintUI.cancel(element)
  if game.getPopUp() ~= "popup_paint_cancel_confirm" then
    game.pushPopUp("popup_paint_cancel_confirm")
  end
end
return PaintUI
