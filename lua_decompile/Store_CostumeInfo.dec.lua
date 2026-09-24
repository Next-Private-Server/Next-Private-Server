local MenuHelpers = include("MenuHelpers")
local ScrollingListHelper = include("ScrollingListHelper")
local StoreEntityHelper = include("StoreEntityHelper")
local StoreCostumeInfo = {}
local scrollListElement, scrollBarElement, scrollMarkerElement, actionPlaceholderElement, purchaseSporeElement, additionalBuyPriceElement
local selectedEntry = ""
local selectedEntryID = 0
local scrollingEnabled = 0
local costumeId, costumeData, costumeStoreInfo, baseMonsterType, monsterStoreInfo, availableMonsters
function StoreCostumeInfo:onPostInit()
  self:setSearchChildren(true)
end
local function costumeInfoListSelectNewEntry(element)
  if selectedEntryID > 0 then
    element:GetElement(selectedEntry):DoStoredScript("deselect")
  end
  selectedEntry = element("NewSelectedEntry"):GetString()
  selectedEntryID = element("NewSelectedEntryID"):GetInt()
  element:GetElement(selectedEntry):DoStoredScript("select")
end
local function costumeInfoScrollMarkerOnTouchDrag(component, element, x, y)
  local originalYOffset = element("originalYOffset"):GetInt()
  local fromTopOfMarkerRange = y - scrollBarElement:absY() - originalYOffset
  local scrollSize = scrollListElement("totalSize"):GetFloat() - (scrollListElement:absH() - scrollListElement("padding"):GetFloat())
  local scrollOffset = scrollSize * (-(fromTopOfMarkerRange - originalYOffset) / (scrollBarElement:absH() - 2 * originalYOffset - element:absH()))
  scrollOffset = lua_sys.clamp(scrollOffset, -scrollSize, 0)
  element("scrollOffset"):SetFloat(scrollOffset)
  scrollListElement.Swiper:DoStoredScript("setScrollOffsetToMarker")
end
function StoreCostumeInfo.onInit(element)
  scrollListElement = element:GetElement("CostumeInfoList")
  scrollBarElement = element:GetElement("CostumeInfoScrollBar")
  scrollMarkerElement = element:GetElement("CostumeInfoScrollMarker")
  actionPlaceholderElement = element:GetElement("ActionPlaceholder")
  purchaseSporeElement = element:GetElement("PurchaseSporeAndCostume")
  additionalBuyPriceElement = element:parent():GetElement("AdditionalBuyPrice")
  scrollListElement("NewSelectedEntry"):SetString("")
  scrollListElement("NewSelectedEntryID"):SetInt(0)
  ScrollingListHelper.ListInit(scrollListElement, {
    direction = lua_sys.MenuSwipeComponent_SwipeDirectionVertical,
    spacing = 12 * game.menuScaleY(),
    alwaysBounce = 0
  })
  scrollMarkerElement("scrollOffset"):SetFloat(0)
  scrollMarkerElement("originalYOffset"):SetInt(scrollMarkerElement("yOffset"):GetInt())
  scrollListElement:addLuaFunction("selectNewEntry", costumeInfoListSelectNewEntry)
  scrollMarkerElement:GetComponent("Touch"):addLuaFunction("onTouchDrag", costumeInfoScrollMarkerOnTouchDrag)
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgConfirmationSubmission", "gotMsgConfirmationSubmission")
end
function StoreCostumeInfo.gotMsgConfirmationSubmission(element, msg)
  if msg.choice and msg.messageID == "PURCHASE_COSTUME_CONFIRMATION" then
    StoreCostumeInfo.purchase(element, true)
  end
end
function StoreCostumeInfo.onTick(element, dt)
  ScrollingListHelper.ListTick(scrollListElement, dt)
  MenuHelpers.ForEachEntry(scrollListElement, function(entry)
    entry("clipX"):SetFloat(scrollListElement:absX())
    entry("clipY"):SetFloat(scrollListElement:absY())
    entry("clipW"):SetFloat(scrollListElement:absW())
    entry("clipH"):SetFloat(scrollListElement:absH())
    entry:DoStoredScript("updateClipping")
  end)
end
local function populateList(element)
  ScrollingListHelper.ListClear(scrollListElement)
  selectedEntry = ""
  selectedEntryID = 0
  scrollListElement("NewSelectedEntry"):SetString("")
  scrollListElement("NewSelectedEntryID"):SetInt(0)
  costumeStoreInfo = StoreEntityHelper.GetCostumeStoreInfo(costumeId)
  local monsters = game.getUniqueMonstersOfBaseMonsterType(baseMonsterType)
  if game.currentIslandType() == game.IslandType_PAIRONORMAL then
    monsters = game.getActiveModeMonstersIdsOfBaseMonsterType(baseMonsterType)
  end
  availableMonsters = 0
  local function createFunc(idx, itemName)
    local uniqueMonsterId = monsters[idx]
    if not game.isInactiveBoxMonster(uniqueMonsterId) and not game.isCostumePurchasedForMonster(costumeId, uniqueMonsterId) then
      availableMonsters = availableMonsters + 1
      local entry = menu:addTemplateElement("template_battle_monster_list_entry", itemName, scrollListElement)
      entry("List"):SetString("CostumeInfoList")
      entry("MonsterID"):SetInt(uniqueMonsterId)
      entry("Layer"):SetString("HUD")
      entry("disabled"):SetInt(0)
      if selectedEntryID == 0 then
        selectedEntry = entry:name()
        selectedEntryID = uniqueMonsterId
        entry("selected"):SetInt(1)
      else
        entry("selected"):SetInt(0)
      end
      return entry
    end
  end
  ScrollingListHelper.ListPopulate(scrollListElement, monsters:size(), createFunc)
  scrollingEnabled = scrollListElement.Touch("enabled"):GetInt()
  scrollBarElement.Sprite("visible"):SetInt(scrollingEnabled)
  scrollMarkerElement.Marker("visible"):SetInt(scrollingEnabled)
  scrollMarkerElement.Touch("enabled"):SetInt(scrollingEnabled)
  scrollListElement("scrollOffset"):SetFloat(0)
  scrollListElement.Swiper:DoStoredScript("setScrollOffset")
  local showActionPlaceholder = (0 < costumeData.action or costumeData.altText ~= "") and 1 or 0
  if showActionPlaceholder == 1 then
    if 0 < costumeData.action then
      local text = LOC("COSTUME_ACTION_PLACEHOLDER")
      text = text:gsub("\n", " ")
      actionPlaceholderElement.Text("text"):SetString(text)
      actionPlaceholderElement.Icon("sheetName"):SetString("xml_resources/context_buttons.xml")
      actionPlaceholderElement.Icon("spriteName"):SetString("button_battle")
    else
      actionPlaceholderElement.Text("text"):SetString(costumeData.altText)
      actionPlaceholderElement.Icon("sheetName"):SetString("xml_resources/" .. costumeData.altSheet)
      actionPlaceholderElement.Icon("spriteName"):SetString(costumeData.altIcon)
    end
  end
  actionPlaceholderElement.Frame("visible"):SetInt(showActionPlaceholder)
  actionPlaceholderElement.Icon("visible"):SetInt(showActionPlaceholder)
  actionPlaceholderElement.Text("visible"):SetInt(showActionPlaceholder)
  local showPurchaseSpore = availableMonsters == 0 and 1 or 0
  purchaseSporeElement.Text("visible"):SetInt(showPurchaseSpore)
  purchaseSporeElement.SparkleAnim("visible"):SetInt(showPurchaseSpore)
  purchaseSporeElement.BreedingAnim("visible"):SetInt(showPurchaseSpore)
  purchaseSporeElement.BreedingAnim("spore"):SetString("gfx/" .. game.getSporeGraphic(baseMonsterType))
  purchaseSporeElement.BreedingAnim:DoStoredScript("refresh")
  purchaseSporeElement.Motes.Particles("visible"):SetInt(showPurchaseSpore)
  local buyPriceElement = element:parent():GetElement("BuyPrice")
  StoreEntityHelper.UpdatePriceUI(buyPriceElement, costumeStoreInfo.salePrice or costumeStoreInfo.basePrice, {
    sprite = "CurrencySprite"
  })
  buyPriceElement:DoStoredScript("setVisible")
  local buyButton = element:parent():GetElement("BuyButton")
  buyButton:GetComponent("Text"):GetVar("text"):SetString("BUY_BUTTON")
  buyButton:DoStoredScript("setVisible")
  if showPurchaseSpore == 1 then
    buyPriceElement.ContextSprite("spriteName"):SetString("button_costume")
    buyPriceElement.ContextSprite("sheetName"):SetString("xml_resources/buttons01.xml")
    buyPriceElement:DoStoredScript("showContext")
    additionalBuyPriceElement.ContextSprite("spriteName"):SetString("button_buy_spore")
    additionalBuyPriceElement.ContextSprite("sheetName"):SetString("xml_resources/context_buttons.xml")
    additionalBuyPriceElement:DoStoredScript("showContext")
    StoreEntityHelper.UpdatePriceUI(additionalBuyPriceElement, monsterStoreInfo, {
      sprite = "CurrencySprite"
    })
    additionalBuyPriceElement:DoStoredScript("setVisible")
  else
    buyPriceElement:DoStoredScript("hideContext")
  end
  StoreCostumeInfo.updateAlpha(element)
  StoreCostumeInfo.onTick(element, 0)
end
function StoreCostumeInfo.show(element)
  costumeId = element("costumeId"):GetInt()
  costumeData = game.getCostumeData(costumeId)
  baseMonsterType = costumeData.monsterId
  local actualMonsterId = game.monsterIdForCurrentIsland(baseMonsterType)
  monsterStoreInfo = StoreEntityHelper.GetStoreMonsterInfo(actualMonsterId)
  populateList(element)
end
function StoreCostumeInfo.hide(element)
  MenuHelpers.ForEachEntry(scrollListElement, function(entry)
    entry:DoStoredScript("hide")
  end)
  scrollListElement.Touch("enabled"):SetInt(0)
  scrollBarElement.Sprite("visible"):SetInt(0)
  scrollMarkerElement.Marker("visible"):SetInt(0)
  scrollMarkerElement.Touch("enabled"):SetInt(0)
  actionPlaceholderElement.Frame("visible"):SetInt(0)
  actionPlaceholderElement.Icon("visible"):SetInt(0)
  actionPlaceholderElement.Text("visible"):SetInt(0)
  purchaseSporeElement.Text("visible"):SetInt(0)
  purchaseSporeElement.BreedingAnim("visible"):SetInt(0)
  purchaseSporeElement.SparkleAnim("visible"):SetInt(0)
  purchaseSporeElement.Motes.Particles("visible"):SetInt(0)
  additionalBuyPriceElement:DoStoredScript("setInvisible")
end
function StoreCostumeInfo.updateAlpha(element)
  local alpha = element("alpha"):GetFloat()
  MenuHelpers.ForEachEntry(scrollListElement, function(entry)
    entry("alpha"):SetFloat(alpha)
    entry:DoStoredScript("updateAlpha")
  end)
  scrollBarElement.Sprite("alpha"):SetFloat(alpha)
  scrollMarkerElement.Marker("alpha"):SetFloat(alpha)
  actionPlaceholderElement.Frame("alpha"):SetFloat(alpha)
  actionPlaceholderElement.Icon("alpha"):SetFloat(alpha)
  actionPlaceholderElement.Text("alpha"):SetFloat(alpha)
  scrollListElement.Touch("enabled"):SetInt(alpha > 0.1 and scrollingEnabled or 0)
  scrollMarkerElement.Touch("enabled"):SetInt(alpha > 0.1 and scrollingEnabled or 0)
  purchaseSporeElement.Text("alpha"):SetFloat(alpha)
  purchaseSporeElement.BreedingAnim("alpha"):SetFloat(alpha)
  purchaseSporeElement.BreedingAnim:setColor(alpha, alpha, alpha)
  purchaseSporeElement.SparkleAnim("alpha"):SetFloat(alpha)
  purchaseSporeElement.SparkleAnim:setColor(alpha, alpha, alpha)
  purchaseSporeElement.Motes.Particles("alpha"):SetFloat(alpha)
  purchaseSporeElement.Motes.Particles:setColor(alpha, alpha, alpha)
end
function StoreCostumeInfo.purchase(element, confirmed)
  print("========== Purchasing Costume: " .. costumeId .. " ==================== confirmed?", confirmed)
  if availableMonsters == 0 then
    local costumePriceToCheck = costumeStoreInfo.salePrice or costumeStoreInfo.basePrice
    if monsterStoreInfo.currency == costumePriceToCheck.currency then
      local combinedPrice = costumePriceToCheck.price + monsterStoreInfo.price
      if not store:checkBuyCurrency(combinedPrice, monsterStoreInfo.currency, game.PurchaseType_COSTUMED_MONSTER_PURCHASE, costumeId) then
        return
      end
    else
      if monsterStoreInfo.currency ~= "INVENTORY" and not store:checkBuyCurrency(monsterStoreInfo.price, monsterStoreInfo.currency, game.PurchaseType_COSTUMED_MONSTER_PURCHASE, costumeId) then
        return
      end
      if costumePriceToCheck.currency == "COSTUME_CREDITS" then
        if game.getCostumeCredit(costumeId) < 1 then
          return
        end
      elseif not store:checkBuyCurrency(costumePriceToCheck.price, costumePriceToCheck.currency, game.PurchaseType_COSTUMED_MONSTER_PURCHASE, costumeId) then
        return
      end
    end
    local actualMonsterType = game.monsterIdForCurrentIsland(baseMonsterType)
    if not game.monsterIsAvail(actualMonsterType, false) then
      local unavailableForSecs = game.getMonsterData(actualMonsterType):unavailableForSecs()
      if unavailableForSecs > 0 then
        local palette = include("ColourPalette")
        local msg = LOC("UNAVAILABLE_UNTIL") .. [[

<c=]] .. palette.AVAILABILITY_TIMER_COLOUR .. ">" .. game.timeToString(unavailableForSecs) .. "</c>"
        game.displayNotification(msg)
      else
        game.displayNotification("MISSING_MONSTER_TITLE")
      end
      return
    end
    if game.isUnderlingIsland() or game.isCelestialIsland() or game.isComposerIsland() or game.getMonsterData(actualMonsterType):isDipster() then
      if game.isComposerIsland() and game.getMonsterData(actualMonsterType):beds() > game.activeIslandAvailableBeds() then
        game.displayNotification("NOTIFICATION_NOT_ENOUGH_BEDS")
        return
      end
    elseif not store:passesEggCheck() then
      game.displayNotification("NOTIFICATION_NOT_ENOUGH_ROOM_IN_NURSERY")
      return
    end
    if monsterStoreInfo.currency == game.StoreContext_TYPE_DIAMOND and costumePriceToCheck.currency == "COSTUME_CREDITS" and not confirmed then
      local txt = LOC("CONFIRMATION_PURCHASE_MONSTER_WITH_COSTUME")
      txt = txt:gsub("%${MONSTER}", LOC(game.monsterTypeName(baseMonsterType)))
      txt = txt:gsub("%${AMOUNT}", monsterStoreInfo.price)
      txt = txt:gsub("%${COSTUME}", LOC(costumeData.name))
      game.displayConfirmation("PURCHASE_COSTUME_CONFIRMATION", txt)
    elseif monsterStoreInfo.currency == "INVENTORY" and costumePriceToCheck.currency == game.StoreContext_TYPE_DIAMOND and not confirmed then
      local txt = LOC("CONFIRMATION_FREE_MONSTER_WITH_PURCHASE_COSTUME")
      txt = txt:gsub("%${MONSTER}", LOC(game.monsterTypeName(baseMonsterType)))
      txt = txt:gsub("%${COSTUME}", LOC(costumeData.name))
      txt = txt:gsub("%${AMOUNT}", costumePriceToCheck.price)
      game.displayConfirmation("PURCHASE_COSTUME_CONFIRMATION", txt)
    elseif monsterStoreInfo.currency == game.StoreContext_TYPE_DIAMOND and costumePriceToCheck.currency == game.StoreContext_TYPE_DIAMOND and not confirmed then
      local txt = LOC("CONFIRMATION_PURCHASE_MONSTER_AND_COSTUME")
      txt = txt:gsub("%${MONSTER}", LOC(game.monsterTypeName(baseMonsterType)))
      txt = txt:gsub("%${MONSTER_AMOUNT}", monsterStoreInfo.price)
      txt = txt:gsub("%${COSTUME}", LOC(costumeData.name))
      txt = txt:gsub("%${COSTUME_AMOUNT}", costumePriceToCheck.price)
      game.displayConfirmation("PURCHASE_COSTUME_CONFIRMATION", txt)
    else
      playSoundFx("audio/sfx/market_bought_item.wav")
      game.purchaseMonsterWithCostume(actualMonsterType, costumeId)
      game.logEvent("costume_purchase", "menu", "market_costume_menu", "action", "costume_and_monster", "monster_id", actualMonsterType, "costume_id", costumeId)
      game.loadWorldContext()
    end
    return
  end
  if selectedEntryID == 0 then
    game.displayNotification("NOTIFICATION_COSTUME_STORE_SELECT_MONSTER")
    return
  end
  local costumePriceToCheck = costumeStoreInfo.salePrice or costumeStoreInfo.basePrice
  if costumePriceToCheck.currency == "COSTUME_CREDITS" then
    if game.getCostumeCredit(costumeId) < 1 then
      print("Insufficient Credits!")
      return
    end
  elseif not store:checkBuyCurrency(costumePriceToCheck.price, costumePriceToCheck.currency, game.PurchaseType_COSTUME_PURCHASE, costumeId) then
    print("Insufficient " .. costumePriceToCheck.currency)
    return
  end
  playSoundFx("audio/sfx/market_bought_item.wav")
  game.purchaseCostumeForMonster(costumeId, selectedEntryID, true)
  game.logEvent("costume_purchase", "menu", "market_costume_menu", "action", "costume", "costume_id", costumeId)
  game.loadWorldAndFocusOnMonster(selectedEntryID)
end
return StoreCostumeInfo
