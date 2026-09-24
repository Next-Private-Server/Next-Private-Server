local BattleCampaignPopupUI = {}
local OffsetTransition = include("MenuElementPositionOffsetTransition")
local FadeTransition = include("FadeTransition")
local MenuHelpers = include("MenuHelpers")
local ScrollingListHelper = include("ScrollingListHelper")
local TRANSITION_DURATION = 0.66
function BattleCampaignPopupUI.onInit(element)
  element("showingInfo"):SetInt(0)
  element("showingExpiredInfo"):SetInt(0)
  element("transitioning"):SetInt(0)
  OffsetTransition.OnInit(element:GetElement("Frame"), {
    startY = lua_sys.screenHeight() * 2,
    endY = 0 * game.hudScale(),
    duration = TRANSITION_DURATION
  })
  OffsetTransition.Show(element:GetElement("Frame"))
  game.logEvent("battle_menu", "menu", "battle_campaign_popup", "action", "init")
end
function BattleCampaignPopupUI.onPostInit(element)
  element.ItemList:DoStoredScript("populate")
end
function BattleCampaignPopupUI.onTick(element, dt)
  local options = {
    ease = lua_sys.Quadratic_EaseIn,
    onDoneHide = function(e)
      e:root():popPopUp()
    end
  }
  OffsetTransition.OnTick(element:GetElement("Frame"), dt, options)
end
function BattleCampaignPopupUI.queuePop(element)
  element.ItemList:DoStoredScript("clear")
  OffsetTransition.Hide(element:GetElement("Frame"))
end
function BattleCampaignPopupUI.SwiperScrollToFirstEntry(component, element)
  local targetEntry
  MenuHelpers.ForEachEntry(element, function(entry)
    if entry("completed"):GetInt() == 0 and targetEntry == nil then
      targetEntry = entry
    end
  end)
  if targetEntry ~= nil then
    local offsetX = targetEntry("xOffset"):GetFloat()
    local scrollSize = component:scrollSize()
    component:setScrollOffset(math.max(-scrollSize, math.min(-offsetX + (element:absW() - targetEntry:absW()) * 0.5, 0)))
  end
end
function BattleCampaignPopupUI.ItemListOnInit(element)
  ScrollingListHelper.ListInit(element)
  element("selectedCardName"):SetString("")
  element("selectedCampaignId"):SetInt(-1)
end
function BattleCampaignPopupUI.ItemListPopulate(element)
  print("populating!")
  element.origXOffset = element:V("xOffset"):GetInt()
  game.getBattlePlayerData():refreshCampaignStatus()
  local campaignDataList = game.getSortedBattleCampaignData()
  local function createFunc(idx, itemName)
    local campaignData = campaignDataList[idx]
    local item = menu:addTemplateElement("template_battle_campaign_card", itemName, element)
    item("campaignId"):SetInt(campaignData.id)
    item("campaignName"):SetString(campaignData.name)
    item("animFile"):SetString(campaignData.animFile)
    item("animName"):SetString(campaignData.anim)
    item("bgAnimFile"):SetString(campaignData.bgAnimFile)
    item("bgAnimName"):SetString(campaignData.bgAnim)
    item("costumeId"):SetInt(campaignData.costumeId)
    item("frame"):SetString(campaignData.frame)
    item("frameSheet"):SetString(campaignData.frameSheet)
    item("icon"):SetString(campaignData.icon)
    item("iconSheet"):SetString(campaignData.iconSheet)
    item("displayId"):SetString(campaignData.displayId)
    if campaignData.reward.costumeId ~= 0 then
      local costumeData = game.getCostumeData(campaignData.reward.costumeId)
      item("reward"):SetString(costumeData.name)
    else
      item("reward"):SetString("???")
    end
    item("requirements"):SetString(campaignData.requirements.description)
    item("totalBattles"):SetInt(campaignData.battles:size())
    item("completedBattles"):SetInt(game.getBattlePlayerData():getCampaignProgress(campaignData.id))
    item("completed"):SetInt(0)
    local isLocked = game.isBattleCampaignLocked(campaignData.id)
    local isTimed = game.isBattleCampaignTimed(campaignData.id)
    if isTimed then
      item("frame"):SetString("menu_quest_frame_timed")
      item("timed"):SetInt(1)
    else
      item("timed"):SetInt(0)
    end
    if isLocked then
      item("locked"):SetInt(1)
      item("status"):SetString("BATTLE_CAMPAIGN_STATUS_LOCKED")
    else
      item("locked"):SetInt(0)
      if game.getBattlePlayerData():hasCompletedCampaign(campaignData.id) then
        item("status"):SetString("BATTLE_CAMPAIGN_STATUS_COMPLETED")
        item("completed"):SetInt(1)
      elseif isTimed then
        item("status"):SetString("BATTLE_CAMPAIGN_STATUS_EVENT")
      else
        item("status"):SetString("BATTLE_CAMPAIGN_STATUS_IN_PROGRESS")
      end
    end
    item("clipX"):SetFloat(8 * game.hudScale())
    item("clipY"):SetFloat(0)
    item("clipW"):SetFloat(lua_sys.screenWidth() - 16 * game.hudScale())
    item("clipH"):SetFloat(lua_sys.screenHeight())
    return item
  end
  ScrollingListHelper.ListPopulate(element, campaignDataList:size(), createFunc)
  element.numEntries = campaignDataList:size()
  element.Swiper:DoStoredScript("scrollToFirstEntry")
  game.setNoNewCampaignNotification()
end
function BattleCampaignPopupUI.ItemListOnTick(element, dt)
  local updateScrolling = ScrollingListHelper.ListTick(element, dt)
  if not updateScrolling then
    local fadeLayerSprite = element:parent():GetElement("FadeLayer"):GetComponent("Sprite")
    fadeLayerSprite.FadeTransition:Tick(dt)
    local selectedItem = element:GetElement(element("selectedCardName"):GetString())
    if selectedItem then
      local options = {
        ease = lua_sys.Quadratic_EaseIn,
        onDoneHide = function(e)
          e:setOrientation(lua_sys.MenuOrientation(e("xOffset"):GetFloat(), e("yOffset"):GetFloat(), -1, lua_sys.LEFT, lua_sys.VCENTER))
          local itemList = e:root().ItemList
          if itemList then
            itemList("updateScrolling"):SetInt(1)
            itemList.Touch("enabled"):SetInt(0)
            MenuHelpers.ForEachEntry(itemList, function(entry)
              entry.Touch("enabled"):SetInt(1)
            end)
            element:parent()("transitioning"):SetInt(0)
          end
        end
      }
      OffsetTransition.OnTick(selectedItem, dt, options)
    end
  end
end
function BattleCampaignPopupUI.ItemListOnCardSelected(element)
  if element:parent()("showingInfo"):GetInt() == 1 then
    return
  end
  if element:parent()("showingExpiredInfo"):GetInt() == 1 then
    return
  end
  local selectedCampaignId = element("selectedCampaignId"):GetInt()
  game.getBattleClientData():setSelectedCampaignId(selectedCampaignId)
  element.Touch("enabled"):SetInt(0)
  element("updateScrolling"):SetInt(0)
  MenuHelpers.ForEachEntry(element, function(entry)
    entry.Touch("enabled"):SetInt(0)
  end)
  local fadeLayerSprite = element:parent():GetElement("FadeLayer"):GetComponent("Sprite")
  fadeLayerSprite.FadeTransition = FadeTransition:new({
    duration = TRANSITION_DURATION,
    onUpdate = function(alpha)
      fadeLayerSprite:GetVar("alpha"):SetFloat(alpha)
    end
  })
  fadeLayerSprite.FadeTransition:Show()
  if game.isBattleCampaignPostActive(selectedCampaignId) then
    local infoPaneExpired = element:parent():GetElement("InfoPane_Expired")
    infoPaneExpired:DoStoredScript("refresh")
    infoPaneExpired:DoStoredScript("show")
    element:parent()("showingExpiredInfo"):SetInt(1)
  else
    local infoPane = element:parent():GetElement("InfoPane")
    infoPane:DoStoredScript("refresh")
    infoPane:DoStoredScript("show")
    element:parent()("showingInfo"):SetInt(1)
    element:parent().ItemList.Swiper:GetVar("enableMouseScroll"):SetInt(0)
  end
  local selectedItem = element:GetElement(element("selectedCardName"):GetString())
  selectedItem:setOrientation(lua_sys.MenuOrientation(selectedItem("xOffset"):GetFloat(), selectedItem("yOffset"):GetFloat(), -17, lua_sys.LEFT, lua_sys.VCENTER))
  local infoPaneBG = element:parent():GetElement("InfoPane"):GetElement("BG")
  local offsetX = infoPaneBG:absX() - selectedItem:absW()
  local options = {
    duration = TRANSITION_DURATION,
    startX = selectedItem("xOffset"):GetFloat(),
    startY = selectedItem("yOffset"):GetFloat(),
    endX = offsetX,
    endY = 0
  }
  OffsetTransition.OnInit(selectedItem, options)
  OffsetTransition.Show(selectedItem)
  element:parent()("transitioning"):SetInt(1)
  manager:setButtonImg("btn_close", "button_back")
  manager:setButtonLabel("btn_close", "BACK")
  manager:setButtonFunction("btn_close", "back_campaign_menu")
  game.logEvent("battle_menu", "menu", "battle_campaign_popup", "action", "select_campaign", "campaign_id", selectedCampaignId)
end
function BattleCampaignPopupUI.ItemListOnCardUnselected(element)
  local fadeLayerSprite = element:parent():GetElement("FadeLayer"):GetComponent("Sprite")
  fadeLayerSprite.FadeTransition:Hide()
  if element:parent()("showingInfo"):GetInt() == 1 then
    element:parent():GetElement("InfoPane"):DoStoredScript("hide")
  end
  if element:parent()("showingExpiredInfo"):GetInt() == 1 then
    element:parent():GetElement("InfoPane_Expired"):DoStoredScript("hide")
  end
  local selectedItem = element:GetElement(element("selectedCardName"):GetString())
  local targetOffsetX = element("scrollOffset"):GetFloat() + selectedItem("listOffset"):GetFloat()
  local options = {
    duration = TRANSITION_DURATION,
    startX = targetOffsetX,
    startY = 0,
    endX = selectedItem("xOffset"):GetFloat(),
    endY = selectedItem("yOffset"):GetFloat()
  }
  OffsetTransition.OnInit(selectedItem, options)
  OffsetTransition.Hide(selectedItem)
  element:parent()("transitioning"):SetInt(1)
  manager:setButtonImg("btn_close", "button_no")
  manager:setButtonLabel("btn_close", "CONTEXTBAR_CLOSE_LABEL")
  manager:setButtonFunction("btn_close", "close_campaign_menu")
end
return BattleCampaignPopupUI
