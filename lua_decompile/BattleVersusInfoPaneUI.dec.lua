local FadeTransition = include("FadeTransition")
local MenuHelpers = include("MenuHelpers")
local BattleVersusInfoPaneUI = {}
function BattleVersusInfoPaneUI.onInit(element)
  element.FadeTransition = FadeTransition:new({
    duration = 0.66,
    onUpdate = function(alpha)
      element("alpha"):SetFloat(alpha)
      element.BG.Sprite("alpha"):SetFloat(alpha)
      element.TeamView("alpha"):SetFloat(alpha)
      element.TeamTab("alpha"):SetFloat(alpha)
    end
  })
end
function BattleVersusInfoPaneUI.onPostInit(element)
  element.FadeTransition:SetAlpha(0)
  element("selectedTabId"):SetInt(1)
  element:DoStoredScript("selectNewTab")
end
function BattleVersusInfoPaneUI.onTick(element, dt)
  element.FadeTransition:Tick(dt)
  element.TeamTab:DoStoredScript("update")
end
function BattleVersusInfoPaneUI.show(element)
  element.FadeTransition:Show()
  element.StartBattleButton:DoStoredScript("show")
  element.ProgressInfo:DoStoredScript("show")
end
function BattleVersusInfoPaneUI.hide(element)
  element.FadeTransition:Hide()
  element.StartBattleButton:DoStoredScript("hide")
  element.ProgressInfo:DoStoredScript("hide")
end
function BattleVersusInfoPaneUI.refresh(element)
  element.TeamView:DoStoredScript("repopulate")
  element("selectedTabId"):SetInt(1)
  element:DoStoredScript("selectNewTab")
end
function BattleVersusInfoPaneUI.TeamViewOnInit(element)
  element("alpha"):SetFloat(1)
  element("isActive"):SetInt(1)
  element("SelectedEntry"):SetInt(-1)
  element:setSearchChildren(false)
end
function BattleVersusInfoPaneUI.TeamViewRepopulate(element)
  MenuHelpers.ForEachEntry(element, function(entry)
    element:RemoveElement(entry)
  end)
  element:DoStoredScript("populate")
end
function BattleVersusInfoPaneUI.TeamViewPopulate(element)
  local campaignId = game.getBattleVersusCampaignId()
  local campaignData = game.getBattleCampaignData(campaignId)
  local currentTier = game.getBattleVersusPlayerData(campaignId):tier()
  if currentTier < 0 then
    currentTier = 0
  end
  local tierData = campaignData.tiers[currentTier]
  local maxTeamSize = tierData.maxTeamSize
  local loadout = game.getBattleVersusLoadout(campaignId)
  local maxTeamSizeText = LOC("BATTLE_VERSUS_MAX_TEAM_SIZE")
  maxTeamSizeText = maxTeamSizeText:gsub("%${MAX_SIZE}", maxTeamSize)
  element:parent().TeamTab.TeamInfo.Required("text"):SetString(maxTeamSizeText)
  local currentBeds = 0
  local totalWidth = 0
  for i = 0, maxTeamSize - 1 do
    local uniqueMonsterId = loadout[i]
    local entry = menu:addTemplateElement("template_battle_campaign_infopane_entry", "entry" .. i, element)
    entry("Id"):SetInt(i)
    if i < tierData:numRequirements() then
      entry("HasRequirement"):SetInt(1)
    else
      entry("HasRequirement"):SetInt(0)
    end
    entry("UniqueMonsterId"):SetInt(uniqueMonsterId)
    if uniqueMonsterId > 0 then
      local monsterTypeId = game.monsterTypeId(uniqueMonsterId)
      entry("MonsterId"):SetInt(monsterTypeId)
      entry("NameText"):SetString(game.getMonsterName(uniqueMonsterId))
      entry("LevelText"):SetString(LOC("LEVEL") .. " " .. game.monsterLevel(uniqueMonsterId))
      entry("AnimationFile"):SetString(game.getMonsterAnimationFileFromType(monsterTypeId))
      entry("AnimationName"):SetString("Store")
      if game.isBattleMonsterFlipped(monsterTypeId) then
        entry("AnimationFlipped"):SetInt(0)
      else
        entry("AnimationFlipped"):SetInt(1)
      end
      entry("CostumeId"):SetInt(game.getEquippedCostumeForMonster(uniqueMonsterId))
      currentBeds = currentBeds + game.monsterTypeBeds(monsterTypeId)
    else
      entry("MonsterId"):SetInt(0)
      entry("NameText"):SetString(LOC("BATTLE_SLOT_EMPTY"))
      entry("LevelText"):SetString("BATTLE_SLOT_EMPTY2")
      entry("AnimationFile"):SetString("battle_slot_empty.bin")
      entry("AnimationName"):SetString("base")
      entry("AnimationFlipped"):SetInt(0)
      entry("CostumeId"):SetInt(0)
    end
    entry:relativeTo(element)
    entry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    entry:calculatePosition()
    entry:init()
    entry:postInit()
    totalWidth = totalWidth + entry:absW()
    entry:setPositionBroadcast(true)
  end
  local spacing = 0
  local step = totalWidth / maxTeamSize
  totalWidth = totalWidth + spacing * (maxTeamSize - 1)
  local offsetX = -(totalWidth * 0.5)
  for i = 0, maxTeamSize - 1 do
    local entry = element:GetElement("entry" .. i)
    entry:setOrientation(lua_sys.MenuOrientation(offsetX, 0, -2, lua_sys.LEFT, lua_sys.VCENTER))
    offsetX = offsetX + step
  end
  element:parent().TeamTab.Beds.Current("text"):SetString(currentBeds)
  element:parent().TeamTab.Beds.Max("text"):SetString("/" .. tierData.maxBeds)
  if currentBeds > tierData.maxBeds then
    element:parent().TeamTab.Beds.Current:setColor(1, 0, 0)
  else
    element:parent().TeamTab.Beds.Current:setColor(1, 1, 1)
  end
  element:parent().TeamTab.Beds:DoStoredScript("center")
end
function BattleVersusInfoPaneUI.TeamViewOnTick(element, dt)
  local isActive = element("isActive"):GetInt() == 1
  if isActive then
    do
      local alpha = element("alpha"):GetFloat()
      MenuHelpers.ForEachEntry(element, function(entry)
        entry("alpha"):SetFloat(alpha)
        local touch = entry.Touch
        if touch then
          if alpha < 0.9 then
            entry.Touch("enabled"):SetInt(0)
          else
            entry.Touch("enabled"):SetInt(1)
          end
        end
      end)
    end
  end
end
function BattleVersusInfoPaneUI.TeamViewShow(element)
  element("isActive"):SetInt(1)
  MenuHelpers.ForEachEntry(element, function(entry)
    entry:DoStoredScript("show")
  end)
end
function BattleVersusInfoPaneUI.TeamViewHide(element)
  element("isActive"):SetInt(0)
  MenuHelpers.ForEachEntry(element, function(entry)
    entry:DoStoredScript("hide")
  end)
end
function BattleVersusInfoPaneUI.TeamViewOnEntrySelected(element)
  local selectedEntry = element("SelectedEntry"):GetInt()
  print("Selected entry:", selectedEntry)
  local campaignId = game.getBattleVersusCampaignId()
  local campaignData = game.getBattleCampaignData(campaignId)
  local progress = game.getBattlePlayerData():getCampaignProgress(campaignId)
  local tierData = campaignData.tiers[progress]
  local slotRequirements = tierData:getRequirementsForSlotId(selectedEntry)
  local availableMonsters = game.availableBattleMonsters()
  local usableMonsters = 0
  for i = 0, availableMonsters:size() - 1 do
    if game.checkCampaignAndSlotRequirements(availableMonsters[i], campaignData, slotRequirements) then
      usableMonsters = usableMonsters + 1
    end
  end
  if usableMonsters == 0 then
    game.displayNotification("NOTIFICATION_BATTLE_NO_AVAILABLE_MONSTERS")
  else
    element:root().SelectMonstersPopup("Refresh"):SetInt(1)
    element:root().SelectMonstersPopup:DoStoredScript("show")
  end
end
function BattleVersusInfoPaneUI.StartButtonOnPostInit(element)
  element.FadeTransition = FadeTransition:new({
    duration = 0.66,
    onDoneShow = function(e)
      element:DoStoredScript("refresh")
    end,
    onDoneHide = function(e)
      element.Label("visible"):SetInt(0)
    end,
    onUpdate = function(alpha)
      element:GetVar("alpha"):SetFloat(alpha)
      element:DoStoredScript("updateComponents")
      element.Label("alpha"):SetFloat(alpha)
    end
  })
  element("canStart"):SetInt(0)
  element:DoStoredScript("disable")
  element.FadeTransition:SetAlpha(0)
end
function BattleVersusInfoPaneUI.StartButtonOnTick(element, dt)
  element.FadeTransition:Tick(dt)
end
function BattleVersusInfoPaneUI.StartButtonEnable(element)
  element.Touch("enabled"):SetInt(1)
  element.Label:setColor(1, 1, 1)
end
function BattleVersusInfoPaneUI.StartButtonDisable(element)
  element.Touch("enabled"):SetInt(0)
  element.Label:setColor(0.5, 0.5, 0.5)
end
function BattleVersusInfoPaneUI.StartButtonShow(element)
  element.Label("visible"):SetInt(1)
  element.FadeTransition:Show()
end
function BattleVersusInfoPaneUI.StartButtonHide(element)
  element("canStart"):SetInt(0)
  element:DoStoredScript("disable")
  element:DoStoredScript("updateComponents")
  element.FadeTransition:Hide()
end
function BattleVersusInfoPaneUI.StartButtonRefresh(element)
  print("BattleVersusInfoPaneUI : Refreshing Start Button")
  local campaignId = game.getBattleVersusCampaignId()
  local campaignData = game.getBattleCampaignData(campaignId)
  local currentTier = game.getBattleVersusPlayerData(campaignId):tier()
  if currentTier < 0 then
    currentTier = 0
  end
  local tierData = campaignData.tiers[currentTier]
  local teamSize = tierData.maxTeamSize
  local currentBeds = 0
  local numSlotsSet = 0
  local meetsRequirements = true
  for i = 0, teamSize - 1 do
    local slot = element:parent().TeamView["entry" .. i]("UniqueMonsterId"):GetInt()
    if slot > 0 then
      game.setCurrentCampaignBattleLoadout(i, slot)
      numSlotsSet = numSlotsSet + 1
      local monsterTypeId = game.monsterTypeId(slot)
      currentBeds = currentBeds + game.monsterTypeBeds(monsterTypeId)
    elseif i < tierData:numRequirements() then
      meetsRequirements = false
    end
  end
  if meetsRequirements and numSlotsSet > 0 and currentBeds <= tierData.maxBeds then
    element("canStart"):SetInt(1)
    element:DoStoredScript("enable")
  else
    element("canStart"):SetInt(0)
    element:DoStoredScript("disable")
    element.Touch("enabled"):SetInt(1)
  end
end
function BattleVersusInfoPaneUI.StartButtonOnTouchUp(component, element)
  if element("canStart"):GetInt() == 0 then
    if not game.tutorialDisableStartBattleButton() then
      game.displayNotification("NOTIFICATION_BATTLE_LOADOUT")
    end
    element.UpSprite:setColor(0.5, 0.5, 0.5)
  else
    element.Label:setColor(1, 1, 1)
    local campaignId = game.getBattleVersusCampaignId()
    local campaignData = game.getBattleCampaignData(campaignId)
    if campaignData then
      local playerData = game.getBattleVersusPlayerData(campaignId)
      if playerData then
        local attempts = playerData:attempts()
        if attempts == 0 then
          game.pushPopUp("battle_versus_refill_confirmation")
        else
          local currentTier = playerData:tier()
          if currentTier < 0 then
            currentTier = 0
          end
          local battleData = campaignData.tiers[currentTier]
          local teamSize = battleData.maxTeamSize
          for i = 0, teamSize - 1 do
            local slot = element:parent().TeamView["entry" .. i]("UniqueMonsterId"):GetInt()
            game.setCurrentCampaignBattleLoadout(i, slot)
          end
          game.startVersusBattle(campaignId)
        end
      end
    end
  end
end
return BattleVersusInfoPaneUI
