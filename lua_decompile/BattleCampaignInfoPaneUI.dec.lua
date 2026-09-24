local FadeTransition = include("FadeTransition")
local MenuHelpers = include("MenuHelpers")
local BattleCampaignInfoPaneUI = {}
function BattleCampaignInfoPaneUI.onInit(element)
  element.FadeTransition = FadeTransition:new({
    duration = 0.66,
    onUpdate = function(alpha)
      element.BG.Sprite("alpha"):SetFloat(alpha)
      element.TeamView("alpha"):SetFloat(alpha)
      element.OpponentView("alpha"):SetFloat(alpha)
      element.TeamTab("alpha"):SetFloat(alpha)
      element.TeamTab:DoStoredScript("update")
      element.OpponentsTab("alpha"):SetFloat(alpha)
      element.OpponentsTab:DoStoredScript("update")
    end
  })
  element.FadeTransition:SetAlpha(0)
  element.isVisible = false
end
function BattleCampaignInfoPaneUI.onPostInit(element)
  element.BG.Sprite("alpha"):SetFloat(0)
  element("selectedTabId"):SetInt(1)
  element:DoStoredScript("selectNewTab")
end
function BattleCampaignInfoPaneUI.onTick(element, dt)
  element.FadeTransition:Tick(dt)
end
function BattleCampaignInfoPaneUI.show(element)
  element.FadeTransition:Show()
  element.StartBattleButton:DoStoredScript("show")
  element.ProgressInfoButton:DoStoredScript("show")
  element.isVisible = true
end
function BattleCampaignInfoPaneUI.hide(element)
  element.FadeTransition:Hide()
  element.StartBattleButton:DoStoredScript("hide")
  element.ProgressInfoButton:DoStoredScript("hide")
  element.ProgressInfoPanel:DoStoredScript("hide")
  element.isVisible = false
end
function BattleCampaignInfoPaneUI.refresh(element)
  element.TeamView:DoStoredScript("repopulate")
  element.OpponentView:DoStoredScript("repopulate")
  element("selectedTabId"):SetInt(1)
  element:DoStoredScript("selectNewTab")
end
function BattleCampaignInfoPaneUI.selectNewTab(element)
  local selectedTab = element("selectedTabId"):GetInt()
  if selectedTab == 0 then
    element.TeamTab:DoStoredScript("selectTab")
    element.OpponentsTab:DoStoredScript("deselectTab")
    element.TeamView:DoStoredScript("show")
    element.OpponentView:DoStoredScript("hide")
  else
    element.TeamTab:DoStoredScript("deselectTab")
    element.OpponentsTab:DoStoredScript("selectTab")
    element.TeamView:DoStoredScript("hide")
    element.OpponentView:DoStoredScript("show")
  end
end
function BattleCampaignInfoPaneUI.TeamViewOnInit(element)
  element("alpha"):SetFloat(0)
  element("isActive"):SetInt(0)
  element("SelectedEntry"):SetInt(-1)
  element:setSearchChildren(false)
end
function BattleCampaignInfoPaneUI.TeamViewOnTick(element, dt)
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
function BattleCampaignInfoPaneUI.TeamViewRepopulate(element)
  MenuHelpers.ForEachEntry(element, function(entry)
    element:RemoveElement(entry)
  end)
  element:DoStoredScript("populate")
end
function BattleCampaignInfoPaneUI.TeamViewPopulate(element)
  local campaignId = game.getBattleClientData():getSelectedCampaignId()
  print("campaignId:", campaignId)
  local progress = game.getBattlePlayerData():getCampaignProgress(campaignId)
  print("progress:", progress)
  local campaignData = game.getBattleCampaignData(campaignId)
  local battle = campaignData.battles[progress]
  local teamSize = battle.team_size
  local loadout = game.getCampaignBattleLoadout(campaignId)
  local requiredTeamSizeText = LOC("BATTLE_CAMPAIGN_REQUIRED_TEAM_SIZE")
  requiredTeamSizeText = requiredTeamSizeText:gsub("%${TEAM_SIZE}", teamSize)
  element:parent().TeamTab.Required("text"):SetString(requiredTeamSizeText)
  local totalWidth = 0
  for i = 0, teamSize - 1 do
    local uniqueMonsterId = loadout[i]
    local entry = menu:addTemplateElement("template_battle_campaign_infopane_entry", "entry" .. i, element)
    entry("Id"):SetInt(i)
    if i < battle:numRequirements() then
      entry("HasRequirement"):SetInt(1)
    else
      entry("HasRequirement"):SetInt(0)
    end
    entry("UniqueMonsterId"):SetInt(uniqueMonsterId)
    if uniqueMonsterId > 0 then
      local monsterId = game.monsterTypeId(uniqueMonsterId)
      entry:GetVar("MonsterId"):SetInt(monsterId)
      entry:GetVar("NameText"):SetString(game.getMonsterName(uniqueMonsterId))
      entry:GetVar("LevelText"):SetString(LOC("LEVEL") .. " " .. game.monsterLevel(uniqueMonsterId))
      entry:GetVar("AnimationFile"):SetString(game.getMonsterAnimationFileFromType(monsterId))
      entry:GetVar("AnimationName"):SetString("Store")
      if game.isBattleMonsterFlipped(monsterId) then
        entry:GetVar("AnimationFlipped"):SetInt(0)
      else
        entry:GetVar("AnimationFlipped"):SetInt(1)
      end
      entry:GetVar("CostumeId"):SetInt(game.getEquippedCostumeForMonster(uniqueMonsterId))
    else
      entry:GetVar("MonsterId"):SetInt(0)
      entry:GetVar("NameText"):SetString(LOC("BATTLE_SLOT_EMPTY"))
      entry:GetVar("LevelText"):SetString("BATTLE_SLOT_EMPTY2")
      entry:GetVar("AnimationFile"):SetString("battle_slot_empty.bin")
      entry:GetVar("AnimationName"):SetString("base")
      entry:GetVar("AnimationFlipped"):SetInt(0)
      entry:GetVar("CostumeId"):SetInt(0)
    end
    entry:relativeTo(element)
    entry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    entry:init()
    entry:setPositionBroadcast(true)
    entry:postInit()
    entry:calculatePosition()
    totalWidth = totalWidth + entry:absW()
  end
  local spacing = 0
  local step = totalWidth / teamSize
  totalWidth = totalWidth + spacing * (teamSize - 1)
  local offsetX = -(totalWidth * 0.5)
  for i = 0, teamSize - 1 do
    local entry = element:GetElement("entry" .. i)
    entry:setOrientation(lua_sys.MenuOrientation(offsetX, 0, -2, lua_sys.LEFT, lua_sys.VCENTER))
    offsetX = offsetX + step
  end
end
function BattleCampaignInfoPaneUI.TeamViewShow(element)
  element("isActive"):SetInt(1)
  MenuHelpers.ForEachEntry(element, function(entry)
    entry:DoStoredScript("show")
  end)
end
function BattleCampaignInfoPaneUI.TeamViewHide(element)
  element("isActive"):SetInt(0)
  MenuHelpers.ForEachEntry(element, function(entry)
    entry:DoStoredScript("hide")
  end)
end
function BattleCampaignInfoPaneUI.TeamViewOnEntrySelected(element)
  local selectedEntry = element("SelectedEntry"):GetInt()
  print("Selected entry:", selectedEntry)
  local campaignId = game.getBattleClientData():getSelectedCampaignId()
  local campaignData = game.getBattleCampaignData(campaignId)
  local progress = game.getBattlePlayerData():getCampaignProgress(campaignId)
  local battleData = campaignData.battles[progress]
  local availableMonsters = game.availableBattleMonsters()
  local usableMonsters = 0
  for i = 0, availableMonsters:size() - 1 do
    if game.checkCampaignAndSlotRequirements(availableMonsters[i], campaignData, battleData, selectedEntry) then
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
function BattleCampaignInfoPaneUI.OpponentViewOnInit(element)
  element("alpha"):SetFloat(1)
end
function BattleCampaignInfoPaneUI.OpponentViewOnTick(element, dt)
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
function BattleCampaignInfoPaneUI.OpponentViewRepopulate(element)
  MenuHelpers.ForEachEntry(element, function(entry)
    element:RemoveElement(entry)
  end)
  element:DoStoredScript("populate")
end
function BattleCampaignInfoPaneUI.OpponentViewPopulate(element)
  local campaignId = game.getBattleClientData():getSelectedCampaignId()
  local campaignData = game.getBattleCampaignData(campaignId)
  local progress = game.getBattlePlayerData():getCampaignProgress(campaignId)
  local battle = campaignData.battles[progress]
  local numEntries = battle.monsters:size()
  if numEntries <= 0 then
    return
  end
  local totalWidth = 0
  for i = 0, numEntries - 1 do
    local entryData = battle.monsters[i]
    local entry = menu:addTemplateElement("template_battle_campaign_infopane_entry", "entry" .. i, element)
    entry:relativeTo(element)
    entry:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.VCENTER)
    entry("Id"):SetInt(i)
    entry("MonsterId"):SetInt(entryData.monsterId)
    entry("AnimationFile"):SetString(game.getMonsterAnimationFileFromType(entryData.monsterId))
    entry("AnimationName"):SetString("Store")
    if game.isBattleMonsterFlipped(entryData.monsterId) then
      entry("AnimationFlipped"):SetInt(1)
    else
      entry("AnimationFlipped"):SetInt(0)
    end
    entry("NameText"):SetString(entryData:name())
    entry("LevelText"):SetString(LOC("LEVEL") .. " " .. entryData.level)
    entry("CostumeId"):SetInt(entryData.costumeId)
    entry("HasRequirement"):SetInt(0)
    entry:init()
    entry:setPositionBroadcast(true)
    entry:postInit()
    entry:calculatePosition()
    totalWidth = totalWidth + entry:absW()
  end
  local spacing = 0
  local step = totalWidth / numEntries
  totalWidth = totalWidth + spacing * (numEntries - 1)
  local offsetX = -(totalWidth * 0.5)
  for i = 0, numEntries - 1 do
    local entry = element:GetElement("entry" .. i)
    entry:setOrientation(lua_sys.MenuOrientation(offsetX, 0, -2, lua_sys.LEFT, lua_sys.VCENTER))
    offsetX = offsetX + step
  end
end
function BattleCampaignInfoPaneUI.OpponentViewShow(element)
  MenuHelpers.ForEachEntry(element, function(entry)
    entry:DoStoredScript("show")
  end)
end
function BattleCampaignInfoPaneUI.OpponentViewHide(element)
  MenuHelpers.ForEachEntry(element, function(entry)
    entry:DoStoredScript("hide")
  end)
end
function BattleCampaignInfoPaneUI.StartButtonOnTouchUp(component, element)
  if element("canStart"):GetInt() == 0 then
    if not game.tutorialDisableStartBattleButton() then
      game.displayNotification("NOTIFICATION_BATTLE_LOADOUT")
    end
    element.UpSprite:setColor(0.5, 0.5, 0.5)
  else
    element.Label:setColor(1, 1, 1)
    local campaignId = game.getBattleClientData():getSelectedCampaignId()
    local campaignData = game.getBattleCampaignData(campaignId)
    local progress = game.getBattlePlayerData():getCampaignProgress(campaignId)
    local battleData = campaignData.battles[progress]
    local teamSize = battleData.team_size
    for i = 0, teamSize - 1 do
      local slot = element:parent().TeamView["entry" .. i]("UniqueMonsterId"):GetInt()
      game.setCurrentCampaignBattleLoadout(i, slot)
    end
    game.startCampaignBattle(campaignId, progress)
  end
end
function BattleCampaignInfoPaneUI.StartButtonOnTouchRelease(component, element)
  if element("canStart"):GetInt() == 0 then
    element.UpSprite:setColor(0.5, 0.5, 0.5)
  else
    element.Label:setColor(1, 1, 1)
  end
end
function BattleCampaignInfoPaneUI.StartButtonOnPostInit(element)
  element("alpha"):SetFloat(0)
  element.FadeTransition = FadeTransition:new({
    duration = 0.66,
    onUpdate = function(alpha)
      element:GetVar("alpha"):SetFloat(alpha)
      element:DoStoredScript("updateComponents")
      element.Label("alpha"):SetFloat(alpha)
    end,
    onDoneShow = function()
      element:DoStoredScript("refresh")
    end,
    onDoneHide = function()
      element.Label("visible"):SetInt(0)
    end
  })
  element("canStart"):SetInt(0)
  element:DoStoredScript("disable")
  element:DoStoredScript("updateComponents")
end
function BattleCampaignInfoPaneUI.StartButtonOnTick(element, dt)
  element.FadeTransition:Tick(dt)
end
function BattleCampaignInfoPaneUI.StartButtonEnable(element)
  element.Touch("enabled"):SetInt(1)
  element.Label:setColor(1, 1, 1)
end
function BattleCampaignInfoPaneUI.StartButtonDisable(element)
  element.Touch("enabled"):SetInt(0)
  element.Label:setColor(0.5, 0.5, 0.5)
end
function BattleCampaignInfoPaneUI.StartButtonShow(element)
  element.Label("visible"):SetInt(1)
  element.FadeTransition:Show()
end
function BattleCampaignInfoPaneUI.StartButtonHide(element)
  element("canStart"):SetInt(0)
  element:DoStoredScript("disable")
  element:DoStoredScript("updateComponents")
  element.FadeTransition:Hide()
end
function BattleCampaignInfoPaneUI.StartButtonRefresh(element)
  print("Refreshing Start Button")
  local campaignId = game.getBattleClientData():getSelectedCampaignId()
  local campaignData = game.getBattleCampaignData(campaignId)
  local progress = game.getBattlePlayerData():getCampaignProgress(campaignId)
  local battleData = campaignData.battles[progress]
  local teamSize = battleData.team_size
  local allSlotsSet = true
  for i = 0, teamSize - 1 do
    local slot = element:parent().TeamView["entry" .. i]("UniqueMonsterId"):GetInt()
    if slot == 0 then
      allSlotsSet = false
    else
      game.setCurrentCampaignBattleLoadout(i, slot)
    end
  end
  if allSlotsSet and not game.tutorialDisableStartBattleButton() then
    element("canStart"):SetInt(1)
    element:DoStoredScript("enable")
  else
    element("canStart"):SetInt(0)
    element:DoStoredScript("disable")
    element.Touch("enabled"):SetInt(1)
  end
end
function BattleCampaignInfoPaneUI.onProgressPanelShow(element)
  local infoPaneElement = element:parent()
  if not infoPaneElement.isVisible then
    return
  end
  local itemListElement = infoPaneElement:parent():GetElement("ItemList")
  local selectedCard = itemListElement("selectedCardName"):GetString()
  itemListElement:GetElement(selectedCard):DoStoredScript("hide")
end
function BattleCampaignInfoPaneUI.onProgressPanelHide(element)
  local infoPaneElement = element:parent()
  local itemListElement = infoPaneElement:parent():GetElement("ItemList")
  local selectedCard = itemListElement("selectedCardName"):GetString()
  itemListElement:GetElement(selectedCard):DoStoredScript("show")
end
return BattleCampaignInfoPaneUI
