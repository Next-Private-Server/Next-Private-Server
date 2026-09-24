local CostumesHelper = include("CostumesHelper")
local ScrollingListHelper = include("ScrollingListHelper")
local CostumesPopupUI = {costDiamonds = false}
local GetSelectedMonsterId = function()
  local selectedMonster = game.selectedMonster()
  local selectedMonsterId = selectedMonster:uniqueId()
  if selectedMonster:data():isModal() then
    local multiMonster = game.GetMultiMonster(selectedMonsterId)
    local mode = game.player():getActiveIsland():islandMode()
    local modeMonster = multiMonster:getModeMonster(mode)
    if modeMonster then
      selectedMonsterId = modeMonster:uniqueId()
    end
  end
  return selectedMonsterId
end
function CostumesPopupUI.Populate(element)
  element("SelectedEntry"):SetString("")
  element("SelectedEntryID"):SetInt(0)
  element("NewSelectedEntry"):SetString("")
  element("NewSelectedEntryID"):SetInt(0)
  element("EquippedEntry"):SetString("")
  local selectedMonsterId = GetSelectedMonsterId()
  local costumesIds = CostumesHelper.GetFilteredCostumes(selectedMonsterId)
  local equippedCostume = game.getEquippedCostumeForMonster(selectedMonsterId)
  local function createFunc(idx, entryName)
    local entry = menu:addTemplateElement("template_battle_monster_costume_entry", entryName, element)
    entry("Container"):SetString(element:name())
    local costumeId = costumesIds[idx]
    local costumeData = game.getCostumeData(costumeId)
    local isPurchased = game.isCostumePurchasedForMonster(costumeId, selectedMonsterId)
    local isUnlocked = game.isCostumeUnlocked(costumeId) or isPurchased or not game.isBattleIsland()
    entry("costumeId"):SetInt(costumeId)
    entry("costumeName"):SetString(LOC(costumeData.name))
    entry("monsterUid"):SetInt(selectedMonsterId)
    entry("timedAvail"):SetInt(0)
    entry("timedSale"):SetInt(0)
    if isUnlocked then
      entry("locked"):SetInt(0)
      if game.hasTimedSaleOnCostume(costumeId, selectedMonsterId) then
        entry("timedSale"):SetInt(1)
      end
    else
      entry("locked"):SetInt(1)
    end
    if not isPurchased and (costumeData:isHidden() or not game.isBattleIsland() and not game.isCostumeUnlocked(costumeId) and not costumeData:isAlwaysVisible()) and game.hasTimedAvailabilityOnCostume(costumeId, selectedMonsterId) then
      entry("timedAvail"):SetInt(1)
    end
    entry("purchased"):SetInt(isPurchased and 1 or 0)
    if costumeId == equippedCostume then
      game.applyCostumeToAnimComponent(element:root().MonsterAvatar:GetComponent("Anim"), costumeId)
      element("SelectedEntry"):SetString(entryName)
      element("SelectedEntryID"):SetInt(costumeId)
      element("EquippedEntry"):SetString(entryName)
      entry("selected"):SetInt(1)
      entry("equipped"):SetInt(1)
      element:parent().Action("costumeId"):SetInt(costumeId)
      if not game.isBattleIsland() then
        if 0 < costumeData.action then
          element:parent().ActionPlaceholder:DoStoredScript("show")
        else
          element:parent().ActionPlaceholder:DoStoredScript("hide")
        end
      end
      local additionalInfo = element:parent().AdditionalInfo
      if costumeData.action == 0 and costumeData.altText ~= "" then
        additionalInfo.Text("text"):SetString(costumeData.altText)
        additionalInfo.Icon("sheetName"):SetString("xml_resources/" .. costumeData.altSheet)
        additionalInfo.Icon("spriteName"):SetString(costumeData.altIcon)
        additionalInfo:DoStoredScript("show")
      else
        additionalInfo:DoStoredScript("hide")
      end
    else
      entry("selected"):SetInt(0)
      entry("equipped"):SetInt(0)
    end
    return entry
  end
  ScrollingListHelper.ListPopulate(element, costumesIds:size(), createFunc)
  if game.isBattleIsland() then
    element:parent().Action:DoStoredScript("refresh")
  end
  CostumesPopupUI.RefreshButtons(element:parent())
end
function CostumesPopupUI.SelectNewEntry(element)
  local selectedCostumeID = element("NewSelectedEntryID"):GetInt()
  if selectedCostumeID ~= element("SelectedEntryID"):GetInt() then
    game.applyCostumeToAnimComponent(element:root().MonsterAvatar:GetComponent("Anim"), selectedCostumeID)
    local costumeData = game.getCostumeData(selectedCostumeID)
    if game.isBattleIsland() then
      element:parent().Action("costumeId"):SetInt(selectedCostumeID)
      element:parent().Action:DoStoredScript("refresh")
    elseif costumeData.action > 0 then
      element:parent().ActionPlaceholder:DoStoredScript("show")
    else
      element:parent().ActionPlaceholder:DoStoredScript("hide")
    end
    local additionalInfo = element:parent().AdditionalInfo
    if costumeData.action == 0 and costumeData.altText ~= "" then
      additionalInfo.Text("text"):SetString(costumeData.altText)
      additionalInfo.Icon("sheetName"):SetString("xml_resources/" .. costumeData.altSheet)
      additionalInfo.Icon("spriteName"):SetString(costumeData.altIcon)
      additionalInfo:DoStoredScript("show")
    else
      additionalInfo:DoStoredScript("hide")
    end
    local lastSelectedEntry = element("SelectedEntry"):GetString()
    if 0 < string.len(lastSelectedEntry) then
      element[lastSelectedEntry]:DoStoredScript("deselect")
    end
    element("SelectedEntry"):SetString(element("NewSelectedEntry"):GetString())
    element("SelectedEntryID"):SetInt(selectedCostumeID)
    CostumesPopupUI.RefreshButtons(element:parent())
  end
end
function CostumesPopupUI.RefreshButtons(element)
  costDiamonds = false
  local costumeId = element.CostumeList("SelectedEntryID"):GetInt()
  local costumeData = game.getCostumeData(costumeId)
  local buyPriceElement = element:GetElement("BuyPrice")
  local isPurchased = game.isCostumePurchasedForMonster(costumeId, GetSelectedMonsterId())
  if isPurchased then
    element.EquipButton:DoStoredScript("setVisible")
    element.BuyButton:DoStoredScript("setInvisible")
    local entry = element.CostumeList("SelectedEntry"):GetString()
    element.CostumeList:GetElement(entry)("locked"):SetInt(0)
    element.CostumeList:GetElement(entry)("purchased"):SetInt(1)
    element.CostumeList:GetElement(entry):DoStoredScript("refresh")
    buyPriceElement:DoStoredScript("setInvisible")
    local equippedCostume = game.getEquippedCostumeForMonster(GetSelectedMonsterId())
    if equippedCostume == costumeId then
      element.EquipButton:DoStoredScript("disable")
    else
      element.EquipButton:DoStoredScript("enable")
    end
    buyPriceElement.SaleTag.Sprite("visible"):SetInt(0)
    buyPriceElement.Strikeout.Sprite("visible"):SetInt(0)
    buyPriceElement.BuyNowPrice.CurrencySprite("visible"):SetInt(0)
    buyPriceElement.BuyNowPrice.Text("visible"):SetInt(0)
  else
    element.EquipButton:DoStoredScript("setInvisible")
    element.BuyButton:DoStoredScript("setVisible")
    element.BuyButton.Text("text"):SetString("BUY_BUTTON")
    buyPriceElement:DoStoredScript("setVisible")
    local isUnlocked = game.isCostumeUnlocked(costumeId)
    if isUnlocked or not game.isBattleIsland() then
      local salePriceElement = buyPriceElement:GetElement("BuyNowPrice")
      salePriceElement.CurrencySprite("visible"):SetInt(0)
      local isSaleOn = game.hasCostumeSaleActive(costumeId)
      if isSaleOn then
        local saleTime = game.timedSaleCostumeTimeRemaining(costumeId, GetSelectedMonsterId())
        if saleTime == 0 then
          isSaleOn = false
        end
      end
      if game.isBattleIsland() and isSaleOn or not game.isBattleIsland() and (isSaleOn or isUnlocked and costumeData.ignoreLocks == 0 and costumeData.isPurchaseLocked == false) then
        salePriceElement.Text("visible"):SetInt(1)
        buyPriceElement.Strikeout.Sprite("visible"):SetInt(1)
        buyPriceElement.SaleTag.Sprite("visible"):SetInt(1)
        if isSaleOn then
          buyPriceElement.SaleTag.Sprite("spriteName"):SetString("sale_tag_updated_taller")
        else
          buyPriceElement.SaleTag.Sprite("spriteName"):SetString("saletag_battle")
        end
      else
        salePriceElement.Text("visible"):SetInt(0)
        buyPriceElement.Strikeout.Sprite("visible"):SetInt(0)
        buyPriceElement.SaleTag.Sprite("visible"):SetInt(0)
      end
      element.BuyButton:DoStoredScript("setEnable")
      local credits = game.getCostumeCredit(costumeId)
      if credits > 0 then
        buyPriceElement.CurrencySprite("visible"):SetInt(0)
        buyPriceElement.Text("text"):SetString("FREE" .. " x" .. credits)
        buyPriceElement.Text:setColor(1, 1, 1)
        salePriceElement.Text("visible"):SetInt(0)
        buyPriceElement.Strikeout.Sprite("visible"):SetInt(0)
        buyPriceElement.SaleTag.Sprite("visible"):SetInt(0)
      elseif game.isBattleIsland() then
        local diamondCost = costumeData.diamondCost
        if diamondCost > 0 then
          costDiamonds = true
          buyPriceElement.CurrencySprite("spriteName"):SetString(game.StoreContext_SPRITE_DIAMOND)
          buyPriceElement.CurrencySprite("sheetName"):SetString(game.StoreContext_CURRENCY_SPRITESHEET)
          buyPriceElement.CurrencySprite("size"):SetFloat(0.5 * game.menuScaleX())
          buyPriceElement.Text("text"):SetString(game.localizeInt(diamondCost))
          buyPriceElement.Text:setColor(RGB(game.StoreContext_diamondColour))
          if isSaleOn then
            salePriceElement.Text("text"):SetString(game.localizeInt(game.getCostumePriceDiamonds(costumeId)))
            buyPriceElement.Strikeout.Sprite:DoStoredScript("refresh")
          end
        else
          local medalCost = costumeData.medalCost
          buyPriceElement.CurrencySprite("spriteName"):SetString(game.StoreContext_SPRITE_MEDAL)
          buyPriceElement.CurrencySprite("sheetName"):SetString(game.StoreContext_CURRENCY_SPRITESHEET)
          buyPriceElement.CurrencySprite("size"):SetFloat(0.5 * game.menuScaleX())
          buyPriceElement.Text("text"):SetString(game.localizeInt(medalCost))
          buyPriceElement.Text:setColor(RGB(game.StoreContext_medalColour))
          if isSaleOn then
            salePriceElement.Text("text"):SetString(game.localizeInt(game.getCostumePriceMedals(costumeId)))
            buyPriceElement.Strikeout.Sprite:DoStoredScript("refresh")
          end
        end
      elseif 0 < costumeData.diamondCost then
        local diamondCost = costumeData.diamondCost
        if costumeData.ignoreLocks == 0 and costumeData.isPurchaseLocked == false then
          diamondCost = math.floor(diamondCost * game.costumeBuyNowMultiplier())
        end
        costDiamonds = true
        buyPriceElement.CurrencySprite("spriteName"):SetString(game.StoreContext_SPRITE_DIAMOND)
        buyPriceElement.CurrencySprite("sheetName"):SetString(game.StoreContext_CURRENCY_SPRITESHEET)
        buyPriceElement.CurrencySprite("size"):SetFloat(0.5 * game.menuScaleX())
        buyPriceElement.Text("text"):SetString(game.localizeInt(diamondCost))
        buyPriceElement.Text:setColor(RGB(game.StoreContext_diamondColour))
        if isSaleOn or isUnlocked and costumeData.ignoreLocks == 0 and costumeData.isPurchaseLocked == false then
          local salePrice = game.getCostumePriceDiamonds(costumeId)
          if not isUnlocked then
            salePrice = math.floor(salePrice * game.costumeBuyNowMultiplier())
          end
          salePriceElement.Text("text"):SetString(game.localizeInt(salePrice))
          buyPriceElement.Strikeout.Sprite:DoStoredScript("refresh")
        end
      elseif 0 < costumeData.action then
        local diamondCost = game.costumeMedalsToDiamonds(costumeData.medalCost)
        if costumeData.ignoreLocks == 0 and costumeData.isPurchaseLocked == false then
          diamondCost = math.floor(diamondCost * game.costumeBuyNowMultiplier())
        end
        costDiamonds = true
        buyPriceElement.CurrencySprite("spriteName"):SetString(game.StoreContext_SPRITE_DIAMOND)
        buyPriceElement.CurrencySprite("sheetName"):SetString(game.StoreContext_CURRENCY_SPRITESHEET)
        buyPriceElement.CurrencySprite("size"):SetFloat(0.5 * game.menuScaleX())
        buyPriceElement.Text("text"):SetString(game.localizeInt(diamondCost))
        buyPriceElement.Text:setColor(RGB(game.StoreContext_diamondColour))
        if isSaleOn or isUnlocked and costumeData.ignoreLocks == 0 and costumeData.isPurchaseLocked == false then
          local salePrice = game.costumeMedalsToDiamonds(game.getCostumePriceMedals(costumeId))
          if not isUnlocked then
            salePrice = math.floor(salePrice * game.costumeBuyNowMultiplier())
          end
          salePriceElement.Text("text"):SetString(game.localizeInt(salePrice))
          buyPriceElement.Strikeout.Sprite:DoStoredScript("refresh")
        end
      else
        costDiamonds = false
        local secondaryCurrencyCost = game.costumeMedalsToCoins(costumeData.medalCost)
        if game.isEtherealIsland() then
          if game.costumeMedalsToShards then
            secondaryCurrencyCost = game.costumeMedalsToShards(costumeData.medalCost)
          else
            secondaryCurrencyCost = math.floor(costumeData.medalCost * 0.25)
          end
        end
        if costumeData.ignoreLocks == 0 and costumeData.isPurchaseLocked == false then
          secondaryCurrencyCost = math.floor(secondaryCurrencyCost * game.costumeBuyNowMultiplier())
        end
        buyPriceElement.CurrencySprite("spriteName"):SetString(game.StoreContext_SPRITE_COINS)
        buyPriceElement.CurrencySprite("sheetName"):SetString(game.StoreContext_CURRENCY_SPRITESHEET)
        buyPriceElement.CurrencySprite("size"):SetFloat(0.5 * game.menuScaleX())
        buyPriceElement.Text("text"):SetString(game.localizeInt(secondaryCurrencyCost))
        buyPriceElement.Text:setColor(RGB(game.StoreContext_coinColour))
        if game.isEtherealIsland() then
          buyPriceElement.CurrencySprite("spriteName"):SetString(game.StoreContext_SPRITE_ETH_CURRENCY)
          buyPriceElement.Text:setColor(RGB(game.StoreContext_etherealColour))
        end
        if isSaleOn or isUnlocked and costumeData.ignoreLocks == 0 and costumeData.isPurchaseLocked == false then
          local salePriceMedals = game.getCostumePriceMedals(costumeId)
          local salePrice = game.costumeMedalsToCoins(salePriceMedals)
          if game.isEtherealIsland() then
            if game.costumeMedalsToShards then
              salePrice = game.costumeMedalsToShards(salePriceMedals)
            else
              salePrice = math.floor(salePriceMedals * 0.25)
            end
          end
          if not isUnlocked then
            salePrice = math.floor(salePrice * game.costumeBuyNowMultiplier())
          end
          salePriceElement.Text("text"):SetString(game.localizeInt(salePrice))
          buyPriceElement.Strikeout.Sprite:DoStoredScript("refresh")
        end
      end
    else
      buyPriceElement.SaleTag.Sprite("visible"):SetInt(0)
      buyPriceElement.Strikeout.Sprite("visible"):SetInt(0)
      buyPriceElement.BuyNowPrice.CurrencySprite("visible"):SetInt(0)
      buyPriceElement.BuyNowPrice.Text("visible"):SetInt(0)
      buyPriceElement.CurrencySprite("spriteName"):SetString("button_lock")
      buyPriceElement.CurrencySprite("sheetName"):SetString("xml_resources/buttons01.xml")
      buyPriceElement.CurrencySprite("size"):SetFloat(0.25 * game.menuScaleX())
      if game.isBattleIsland() then
        element.BuyButton:DoStoredScript("setDisable")
        buyPriceElement.Text("text"):SetString("LOCKED")
        buyPriceElement.Text:setColor(1, 1, 1)
      end
    end
  end
end
function CostumesPopupUI.Equip(element)
  local costumeList = element:parent().CostumeList
  local costumeId = costumeList("SelectedEntryID"):GetInt()
  game.equipCostumeOnMonster(costumeId, GetSelectedMonsterId())
  element:DoStoredScript("disable")
  local entry = costumeList("SelectedEntry"):GetString()
  local equippedEntry = costumeList("EquippedEntry"):GetString()
  costumeList:GetElement(entry):DoStoredScript("equip")
  costumeList:GetElement(equippedEntry):DoStoredScript("unEquip")
  costumeList("EquippedEntry"):SetString(entry)
end
function CostumesPopupUI.Purchase(element)
  local costumeId = element:parent().CostumeList("SelectedEntryID"):GetInt()
  local costumeData = game.getCostumeData(costumeId)
  if element("enabled"):GetInt() == 0 then
    local campaignDataList = game.getSortedBattleCampaignData(true)
    local itemFound = false
    local isVersus = false
    for i = 0, campaignDataList:size() - 1 do
      local campaignData = campaignDataList[i]
      if campaignData.reward.costumeId == costumeId then
        itemFound = true
        isVersus = campaignData.isPVP
      end
    end
    if itemFound == true then
      if isVersus == true then
        game.displayNotification("NOTIFICATION_COSTUME_UNLOCKED_IN_AVAILABLE_PVP_304")
      else
        game.displayNotification("NOTIFICATION_COSTUME_UNLOCKED_IN_AVAILABLE_EVENT_304")
      end
    elseif costumeData.unlockTeleport == 1 then
      game.displayNotification("NOTIFICATION_COSTUME_UNLOCKED_BY_TELEPORT_TO_BATTLE")
    elseif costumeData.unlockLevel > game.playerBattleLevel() then
      game.displayNotification("NOTIFICATION_COSTUME_UNLOCKED_BY_LEVEL_304")
    else
      game.displayNotification("NOTIFICATION_COSTUME_UNLOCKED_IN_EVENT_304")
    end
  else
    local buyPriceElement = element:parent().BuyPrice
    local txt = game.getLocalizedText("CONFIRMATION_BUY_MONSTER_COSTUME")
    txt = select(1, txt:gsub("XXX", LOC(costumeData.name)))
    local isDiscount = CostumesPopupUI.DiscountedPrice(costumeId)
    if isDiscount then
      txt = select(1, txt:gsub("YYY", buyPriceElement.BuyNowPrice.Text("text"):GetString()))
    else
      txt = select(1, txt:gsub("YYY", buyPriceElement.Text("text"):GetString()))
    end
    if costDiamonds then
      game.displayConfirmation("BUY_MONSTER_COSTUME", txt)
    else
      CostumesPopupUI.CompletePurchase(element)
    end
  end
end
function CostumesPopupUI.GotMsgConfirmationSubmission(element, msg)
  if msg.messageID == "EQUIP_COSTUME" and msg.choice == true then
    CostumesPopupUI.Equip(element:parent():GetElement("EquipButton"))
    CostumesPopupUI.RefreshButtons(element:parent())
  elseif msg.messageID == "BUY_MONSTER_COSTUME" and msg.choice == true then
    CostumesPopupUI.CompletePurchase(element)
  end
end
function CostumesPopupUI.CompletePurchase(element)
  local costumeId = element:parent().CostumeList:GetVar("SelectedEntryID"):GetInt()
  lua_sys.playSoundFx("audio/sfx/market_bought_item.wav")
  game.purchaseCostumeForMonster(costumeId, GetSelectedMonsterId())
  game.logEvent("costume_purchase", "menu", "monster_costume_menu", "action", "costume", "costume_id", tostring(costumeId), "user_monster_id", tostring(GetSelectedMonsterId()))
  local buyButton = element.BuyButton
  if buyButton.Touch("enabled"):GetInt() == 1 then
    buyButton:DoStoredScript("setDisable")
  end
end
function CostumesPopupUI.GotMsgNotificationDismissed(element, msg)
end
function CostumesPopupUI.AvailabilityDuration_OnTick(element, dt)
  local parent = element:parent()
  local isTimedAvailable = parent("timedAvail"):GetInt() == 1
  local isTimedSale = parent("timedSale"):GetInt() == 1
  if isTimedAvailable or isTimedSale then
    local availableSecondsRemaining = 0
    local saleSecondsRemaining = 0
    if isTimedAvailable then
      availableSecondsRemaining = game.timedAvailCostumeTimeRemaining(parent("costumeId"):GetInt(), parent("monsterUid"):GetInt())
    end
    if isTimedSale then
      saleSecondsRemaining = game.timedSaleCostumeTimeRemaining(parent("costumeId"):GetInt(), parent("monsterUid"):GetInt())
    end
    local isSelected = parent("selected"):GetInt() == 1
    local isPurchased = parent("purchased"):GetInt() == 1
    if isPurchased then
      parent.Hourglass.Sprite("visible"):SetInt(0)
      parent.SaleTag.Sprite("visible"):SetInt(0)
      parent.bg.GreySprite("spriteName"):SetString("selectable_bar_grey")
      parent.bg.YellowSprite("spriteName"):SetString("selectable_bar_yellow")
      parent:GetElement("costumeName"):setOrientation(lua_sys.MenuOrientation(0, 0, -1, lua_sys.HCENTER, lua_sys.VCENTER))
      parent:GetElement("costumeName"):setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
      element.Text("visible"):SetInt(0)
      parent("timedSale"):SetInt(0)
      parent("timedAvail"):SetInt(0)
      return
    end
    if availableSecondsRemaining > 0 then
      element.Text("text"):SetString(game.timeToString(availableSecondsRemaining))
    elseif not isTimedAvailable and saleSecondsRemaining > 0 then
      element.Text("text"):SetString(game.timeToString(saleSecondsRemaining))
    else
      local costumeList = parent:parent()
      local costumePopup = costumeList:parent()
      if isTimedAvailable then
        if parent.Hourglass.Sprite("visible"):GetInt() == 1 then
          parent.bg.GreySprite("spriteName"):SetString("selectable_bar_grey")
          parent.bg.YellowSprite("spriteName"):SetString("selectable_bar_yellow")
          parent.bg.GreySprite:setColor(0.5, 0.5, 0.5)
          parent.bg.YellowSprite:setColor(0.5, 0.5, 0.5)
          parent.Hourglass.Sprite("visible"):SetInt(0)
          element.Text("text"):SetString("TIMED_EVENT_EXPIRED")
          CostumesPopupUI.RefreshButtons(costumePopup)
        end
        local buyButton = costumePopup.BuyButton
        if isSelected and buyButton.Touch("enabled"):GetInt() == 1 then
          buyButton:DoStoredScript("setDisable")
        end
      elseif element.Text("visible"):GetInt() == 1 then
        element.Text("visible"):SetInt(0)
        parent:GetElement("costumeName"):setOrientation(lua_sys.MenuOrientation(0, 0, -1, lua_sys.HCENTER, lua_sys.VCENTER))
        parent:GetElement("costumeName"):setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
      end
      if isTimedSale then
        if parent.SaleTag.Sprite("visible"):GetInt() == 1 then
          parent.SaleTag.Sprite("visible"):SetInt(0)
          CostumesPopupUI.RefreshButtons(costumePopup)
        end
        if not isTimedAvailable then
          parent.bg.GreySprite("spriteName"):SetString("selectable_bar_grey")
          parent.bg.YellowSprite("spriteName"):SetString("selectable_bar_yellow")
        end
      end
    end
  end
end
function CostumesPopupUI.DiscountedPrice(costumeId)
  local isUnlocked = game.isCostumeUnlocked(costumeId)
  local costumeData = game.getCostumeData(costumeId)
  local isSaleOn = game.hasCostumeSaleActive(costumeId)
  if isSaleOn then
    local saleTime = game.timedSaleCostumeTimeRemaining(costumeId, GetSelectedMonsterId())
    if saleTime == 0 then
      isSaleOn = false
    end
  end
  return game.isBattleIsland() and isSaleOn or not game.isBattleIsland() and (isSaleOn or isUnlocked and costumeData.ignoreLocks == 0 and costumeData.isPurchaseLocked == false)
end
CostumesPopupUI.GetSelectedMonsterId = GetSelectedMonsterId
return CostumesPopupUI
