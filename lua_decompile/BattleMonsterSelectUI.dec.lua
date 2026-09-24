local OffsetTransition = include("MenuElementPositionOffsetTransition")
local FadeTransition = include("FadeTransition")
local ScrollingListHelper = include("ScrollingListHelper")
local MenuHelpers = include("MenuHelpers")
local BattleMonsterSelectUI = {}
function BattleMonsterSelectUI.OnInit(element, isPVP, isFriend)
  element("IsShowing"):SetInt(0)
  element("Refresh"):SetInt(0)
  local fadeTouch = element.SMP_FADE.SMP_FADE_TOUCH
  fadeTouch("enabled"):SetInt(0)
  local fadeTarget = element:GetElement("SMP_FADE"):GetComponent("SMP_FADE_SPRITE")
  element.FadeTransition = FadeTransition:new({
    duration = 0.66,
    maxFade = 0.5,
    onDoneHide = function()
      fadeTouch("enabled"):SetInt(0)
      if isPVP == 1 then
        if manager:getContext() ~= "BATTLE_VERSUS_MENU" then
          manager:setContext("BATTLE_VERSUS_MENU")
        end
      elseif isFriend == 1 then
        if manager:getContext() ~= "BATTLE_VERSUS_FRIENDS_MENU" then
          manager:setContext("BATTLE_VERSUS_FRIENDS_MENU")
        end
      elseif manager:getContext() ~= "BATTLE_CAMPAIGN_MENU" then
        manager:setContext("BATTLE_CAMPAIGN_MENU")
      end
    end,
    onUpdate = function(alpha)
      fadeTarget:GetVar("alpha"):SetFloat(alpha)
    end
  })
  element.FadeTransition:SetAlpha(0)
  OffsetTransition.OnInit(element:GetElement("SMP_PANEL"), {
    startY = lua_sys.screenHeight() * 2,
    endY = 6 * game.hudScale(),
    duration = 0.66
  })
end
function BattleMonsterSelectUI.OnTick(element, dt)
  element.FadeTransition:Tick(dt)
  OffsetTransition.OnTick(element:GetElement("SMP_PANEL"), dt, {
    onDoneShow = function()
      element.SMP_PANEL.SMP_CLOSE.Touch("enabled"):SetInt(1)
    end
  })
  if element("Refresh"):GetInt() == 1 then
    element.SMP_LIST:DoStoredScript("populate")
    element("Refresh"):SetInt(0)
  end
end
function BattleMonsterSelectUI.Show(element)
  element("IsShowing"):SetInt(1)
  local fadeTouch = element.SMP_FADE.SMP_FADE_TOUCH
  fadeTouch("enabled"):SetInt(1)
  manager:setButtonEnabled("btn_close", false)
  element.FadeTransition:Show()
  element.SMP_LIST("scrollOffset"):SetFloat(0)
  element.SMP_LIST.Swiper:DoStoredScript("setScrollOffsetX")
  OffsetTransition.Show(element:GetElement("SMP_PANEL"))
end
function BattleMonsterSelectUI.Hide(element)
  if element("IsShowing"):GetInt() == 1 then
    element("IsShowing"):SetInt(0)
    element.FadeTransition:Hide()
    OffsetTransition.Hide(element:GetElement("SMP_PANEL"))
    manager:setButtonEnabled("btn_close", true)
  end
end
function BattleMonsterSelectUI.ListOnInit(element)
  element("NewSelectedEntry"):SetString("")
  element("NewSelectedEntryID"):SetInt(0)
  ScrollingListHelper.ListInit(element, {
    direction = lua_sys.MenuSwipeComponent_SwipeDirectionVertical,
    spacing = 12 * game.menuScaleY()
  })
end
function BattleMonsterSelectUI.ListPopulate(element, isPVP, isFriend)
  print("Populating Select Monsters Popup List!", isPVP)
  ScrollingListHelper.ListClear(element)
  local campaignId = (isPVP == 1 or isFriend == 1) and game.getBattleVersusCampaignId() or game.getBattleClientData():getSelectedCampaignId()
  print("campaignId:", campaignId)
  local progress = game.getBattlePlayerData():getCampaignProgress(campaignId)
  local campaignData = game.getBattleCampaignData(campaignId)
  local battleData = (isPVP == 1 or isFriend == 1) and campaignData.tiers[progress] or campaignData.battles[progress]
  print("battleData:", battleData)
  local selectedSlot = element:root().TeamView("SelectedEntry"):GetInt()
  local slotRequirements = battleData:getRequirementsForSlotId(selectedSlot)
  local selectedMonsterId = element:root().TeamView["entry" .. selectedSlot]("UniqueMonsterId"):GetInt()
  local monsterIds = game.availableBattleMonsters()
  local numMonsters = monsterIds:size()
  if (isPVP == 1 or isFriend == 1) and game.checkSlotRequirements(0, slotRequirements) then
    local entryName = ScrollingListHelper.ListCreateEntryName(element)
    local entry = menu:addTemplateElement("template_battle_monster_list_entry", entryName, element)
    entry("List"):SetString("SMP_LIST")
    entry("MonsterID"):SetInt(0)
    entry("Layer"):SetString("FrontPopUps")
    if selectedMonsterId == 0 then
      entry("selected"):SetInt(1)
    else
      entry("selected"):SetInt(0)
    end
    entry("disabled"):SetInt(0)
    local padding = element("padding"):GetFloat()
    local panelSpacing = element("spacing"):GetFloat()
    element("totalSize"):SetFloat(panelSpacing + padding)
    ScrollingListHelper.ListAddEntry(element, entry)
  end
  local function createFunc(idx, itemName)
    local monsterId = monsterIds[idx]
    if game.checkCampaignAndSlotRequirements(monsterId, campaignData, slotRequirements) then
      local entry = menu:addTemplateElement("template_battle_monster_list_entry", itemName, element)
      entry("List"):SetString("SMP_LIST")
      entry("MonsterID"):SetInt(monsterId)
      entry("Layer"):SetString("FrontPopUps")
      if monsterId == selectedMonsterId then
        entry("selected"):SetInt(1)
      else
        entry("selected"):SetInt(0)
      end
      if game.isMonsterTraining(monsterId) then
        entry("disabled"):SetInt(1)
      else
        entry("disabled"):SetInt(0)
      end
      return entry
    end
  end
  ScrollingListHelper.ListPopulate(element, numMonsters, createFunc)
end
function BattleMonsterSelectUI.ListOnTick(element, dt)
  ScrollingListHelper.ListTick(element, dt)
  MenuHelpers.ForEachEntry(element, function(entry)
    entry("clipX"):SetFloat(element:absX())
    entry("clipY"):SetFloat(element:absY())
    entry("clipW"):SetFloat(element:absW())
    entry("clipH"):SetFloat(element:absH())
    entry:DoStoredScript("updateClipping")
  end)
end
function BattleMonsterSelectUI.ListSelectNewEntry(element, isPVP, isFriend)
  local campaignId = (isPVP == 1 or isFriend == 1) and game.getBattleVersusCampaignId() or game.getBattleClientData():getSelectedCampaignId()
  local progress = game.getBattlePlayerData():getCampaignProgress(campaignId)
  local campaignData = game.getBattleCampaignData(campaignId)
  local battleData = (isPVP == 1 or isFriend == 1) and campaignData.tiers[progress] or campaignData.battles[progress]
  local selectedMonsterID = element("NewSelectedEntryID"):GetInt()
  local selectTeam = element:root():GetElement("TeamView")
  if not selectTeam then
    print("Couldn't find TeamView!")
    return
  end
  local slotID = selectTeam("SelectedEntry"):GetInt()
  if slotID == -1 then
    return
  end
  print("Selecting new entry for slot " .. slotID)
  print("Selected Monster: " .. selectedMonsterID)
  for i = 0, 2 do
    if i ~= slotID then
      local iSlot = selectTeam["entry" .. i]
      if iSlot then
        local id = iSlot("UniqueMonsterId"):GetInt()
        if id > 0 and selectedMonsterID == id then
          print("Selected monster already in slot " .. i)
          local targetEntry = selectTeam["entry" .. slotID]
          local swapId = targetEntry("UniqueMonsterId"):GetInt()
          local slotRequirements = battleData:getRequirementsForSlotId(i)
          if game.checkCampaignAndSlotRequirements(swapId, campaignData, slotRequirements) then
            iSlot("UniqueMonsterId"):SetInt(swapId)
            iSlot:DoStoredScript("refreshTeamSlot")
            print("Setting slot " .. i .. " to monster " .. swapId)
            if isPVP == 0 then
              game.setPreferredCampaignBattleLoadout(i, swapId)
              break
            end
            game.setPreferredVersusBattleLoadout(i, swapId)
            break
          end
          iSlot("UniqueMonsterId"):SetInt(0)
          iSlot:DoStoredScript("refreshTeamSlot")
          print("Setting slot " .. i .. " to empty")
          if isPVP == 0 and isFriend == 0 then
            game.setPreferredCampaignBattleLoadout(i, 0)
            break
          end
          game.setPreferredVersusBattleLoadout(i, 0)
          break
        end
      end
    end
  end
  print("Setting slot " .. slotID .. " to monster " .. selectedMonsterID)
  if isPVP == 0 and isFriend == 0 then
    game.setPreferredCampaignBattleLoadout(slotID, selectedMonsterID)
  else
    game.setPreferredVersusBattleLoadout(slotID, selectedMonsterID)
  end
  local targetSlot = selectTeam:GetElement("entry" .. slotID)
  targetSlot("UniqueMonsterId"):SetInt(selectedMonsterID)
  targetSlot:DoStoredScript("refreshTeamSlot")
  element:root():GetElement("TeamTab"):DoStoredScript("refresh")
  element:root():GetElement("StartBattleButton"):DoStoredScript("refresh")
  element:root().SelectMonstersPopup:DoStoredScript("hide")
  selectTeam("SelectedEntry"):SetInt(-1)
end
function BattleMonsterSelectUI.SwiperOnInit(component, element)
  component("smoothMode"):SetInt(1)
end
function BattleMonsterSelectUI.SwiperOnTick(component, element, dt)
  ScrollingListHelper.SwiperTick(component, element, dt)
  local scrollOffset = element("scrollOffset"):GetFloat()
  local scrollMarker = element:parent():GetElement("SMP_SCROLLMARKER")
  local originalYOffset = scrollMarker("originalYOffset"):GetInt()
  local markerMovementHeight = element:parent():GetElement("SMP_SCROLLBAR"):absH() - 2 * originalYOffset - scrollMarker:absH()
  local scrollMarkerYOffset = -(scrollOffset / component:scrollSize()) * markerMovementHeight
  scrollMarkerYOffset = lua_sys.clamp(scrollMarkerYOffset, 0, markerMovementHeight)
  scrollMarker("yOffset"):SetInt(originalYOffset + scrollMarkerYOffset)
end
function BattleMonsterSelectUI.SwiperRefresh(component, element)
  ScrollingListHelper.SwiperRefresh(component, element)
end
function BattleMonsterSelectUI.SwiperSetScrollOffset(component, element)
  local offset = element("scrollOffset"):GetFloat()
  component:setScrollOffset(offset)
end
function BattleMonsterSelectUI.SwiperSetScrollOffsetToMarker(component, element)
  local scrollmarker = element:parent():GetElement("SMP_SCROLLMARKER")
  component:setScrollOffset(scrollmarker("scrollOffset"):GetFloat())
end
function BattleMonsterSelectUI.ScrollMarkerOnInit(element)
  element("scrollOffset"):SetFloat(0)
  element("originalYOffset"):SetInt(element("yOffset"):GetInt())
end
function BattleMonsterSelectUI.ScrollMarkerOnTouchDrag(component, element, x, y)
  local listElement = element:parent():GetElement("SMP_LIST")
  local scrollBarElement = element:parent():GetElement("SMP_SCROLLBAR")
  local originalYOffset = element("originalYOffset"):GetInt()
  local fromTopOfMarkerRange = y - scrollBarElement:absY() - originalYOffset
  local scrollSize = listElement("totalSize"):GetFloat() - (listElement:absH() - listElement("padding"):GetFloat())
  local scrollOffset = scrollSize * (-(fromTopOfMarkerRange - originalYOffset) / (scrollBarElement:absH() - 2 * originalYOffset - element:absH()))
  scrollOffset = lua_sys.clamp(scrollOffset, -scrollSize, 0)
  element("scrollOffset"):SetFloat(scrollOffset)
  listElement.Swiper:DoStoredScript("setScrollOffsetToMarker")
end
return BattleMonsterSelectUI
