local ScrollingListHelper = include("ScrollingListHelper")
local BattleVersusHelper = include("BattleVersusHelper")
local MenuHelpers = include("MenuHelpers")
local BattleVersusProgressUI = {}
function BattleVersusProgressUI.Populate(element)
  print("Populating Versus Progress Info!")
  ScrollingListHelper.ListClear(element)
  local campaignId = game.getBattleVersusCampaignId()
  local campaignData = game.getBattleCampaignData(campaignId)
  local battleVersusPlayerData = game.getBattleVersusPlayerData(campaignId)
  local completed = battleVersusPlayerData:hasCompletedSeason()
  if completed then
    do
      local championTiers = {}
      local numChampionTiers = 0
      for idx = campaignData.tiers:size() - 1, 0, -1 do
        local tier = campaignData.tiers[idx]
        if tier:isChampionTier() then
          championTiers[numChampionTiers] = idx
          numChampionTiers = numChampionTiers + 1
        end
      end
      local function createFunc(idx, itemName)
        local entry = menu:addTemplateElement("template_battle_versus_progressinfo_entry", itemName, element)
        entry("CampaignId"):SetInt(campaignId)
        entry("TierId"):SetInt(championTiers[idx])
        local tierName = LOC("BATTLE_VERSUS_CHAMPION_TIER")
        tierName = tierName:gsub("%${TIER}", idx + 1)
        entry("TierName"):SetString(tierName)
        entry("ChampionMode"):SetInt(1)
        entry("Layer"):SetString("MidPopUps")
        return entry
      end
      ScrollingListHelper.ListPopulate(element, numChampionTiers, createFunc)
    end
  else
    do
      local seasonTiers = BattleVersusHelper.GetSeasonTiers(campaignId)
      local function createFunc(idx, itemName)
        local seasonTierData = seasonTiers[idx]
        local entry = menu:addTemplateElement("template_battle_versus_progressinfo_entry", itemName, element)
        entry("CampaignId"):SetInt(campaignId)
        entry("TierId"):SetInt(seasonTierData.tierId)
        entry("TierName"):SetString(seasonTierData.name)
        entry("ChampionMode"):SetInt(0)
        entry("Layer"):SetString("MidPopUps")
        return entry
      end
      ScrollingListHelper.ListPopulate(element, #seasonTiers + 1, createFunc)
    end
  end
end
function BattleVersusProgressUI.InitEntry(element)
  local campaignId = element("CampaignId"):GetInt()
  local campaignData = game.getBattleCampaignData(campaignId)
  local tierId = element("TierId"):GetInt()
  local tierData = campaignData.tiers[tierId]
  local showChampionMode = element("ChampionMode"):GetInt() == 1
  if showChampionMode then
    element.Description.Text("text"):SetString("Top Champions: " .. tierData.numChamps)
    local tierLabelText = element("TierName"):GetString()
    element.Tier("tierName"):SetString(tierLabelText)
    element.Tier("currentStars"):SetInt(0)
    element.Tier("totalStars"):SetInt(0)
    element.SelectedBG:DoStoredScript("hide")
    element.Rewards("yOffset"):SetFloat(26 * game.menuScaleY())
  else
    if tierData:isChampionTier() and 0 < campaignData.reward.costumeId then
      local costumeData = game.getCostumeData(campaignData.reward.costumeId)
      element.Description.Text("text"):SetString(costumeData.name)
      element.Rewards("yOffset"):SetFloat(40 * game.menuScaleY())
    else
      element.Description.Text("visible"):SetInt(0)
      element.Rewards("yOffset"):SetFloat(20 * game.menuScaleY())
    end
    local battleVersusPlayerData = game.getBattleVersusPlayerData(campaignId)
    local currentTier = battleVersusPlayerData:tier()
    if tierId <= currentTier then
      element.SelectedBG:DoStoredScript("show")
    else
      element.SelectedBG:DoStoredScript("hide")
    end
    local tierLabelText = element("TierName"):GetString()
    element.Tier("tierName"):SetString(tierLabelText)
    if tierId < currentTier then
      element.Tier("currentStars"):SetInt(tierData.stars)
    elseif currentTier == tierId then
      element.Tier("currentStars"):SetInt(battleVersusPlayerData:stars())
    else
      element.Tier("currentStars"):SetInt(0)
    end
    element.Tier("totalStars"):SetInt(tierData.stars)
  end
end
function BattleVersusProgressUI.InitEntryRewards(element)
  local campaignId = element("CampaignId"):GetInt()
  local tierId = element("TierId"):GetInt()
  if tierId < 0 then
    tierId = 0
  end
  local campaignData = game.getBattleCampaignData(campaignId)
  local tierData = campaignData.tiers[tierId]
  local showChampionMode = element:parent()("ChampionMode"):GetInt() == 1
  local rewardData = tierData.reward
  if not showChampionMode and tierData:isChampionTier() then
    print("showing camapign reward")
    rewardData = campaignData.reward
  end
  if not rewardData then
    print("No Reward Data!")
    return
  end
  local rewardCount = 0
  local offsetY = 0
  local rewardsPerRow = 2
  local rowSpacing = 20 * game.menuScaleX()
  local row = {}
  local function createReward(icon, amount, currencyType, iconSheet)
    local rewardItem = menu:addTemplateElement("template_battle_progress_reward", "reward" .. rewardCount, element)
    rewardItem("Icon"):SetString(icon)
    rewardItem("Amount"):SetInt(amount)
    rewardItem("CurrencyType"):SetString(currencyType)
    if iconSheet then
      rewardItem("IconSheet"):SetString(iconSheet)
    end
    rewardItem:setOrientation(lua_sys.MenuOrientation(0, offsetY, -1, lua_sys.LEFT, lua_sys.TOP))
    rewardItem:setRelativeObjectAnchors(lua_sys.HCENTER, lua_sys.TOP)
    rewardItem:init()
    rewardItem:setPositionBroadcast(true)
    rewardItem:postInit()
    table.insert(row, rewardItem)
    rewardCount = rewardCount + 1
    if rewardCount % rewardsPerRow == 0 then
      MenuHelpers.CenterHorizontally(row)
      offsetY = offsetY + rowSpacing
      row = {}
    end
  end
  if 0 < rewardData.costumeId then
    createReward("button_costume", 1, "", "xml_resources/buttons01.xml")
  end
  if 0 < rewardData.diamonds then
    createReward("diamond", rewardData.diamonds, "diamond")
  end
  if 0 < rewardData.coins then
    createReward("coin", rewardData.coins, "coins")
  end
  if 0 < rewardData.medals then
    createReward("medal", rewardData.medals, "medals")
  end
  if 0 < rewardData.xp then
    createReward("battle_xp", rewardData.xp, "battle_xp")
  end
  if 0 < rewardData.food then
    createReward("food", rewardData.food, "food")
  end
  if 0 < rewardData.starpower then
    createReward("starpower", rewardData.starpower, "starpower")
  end
  if 0 < rewardData.relics then
    createReward("relic", rewardData.relics, "relics")
  end
  if 0 < rewardData.keys then
    createReward("keys", rewardData.keys, "key")
  end
  MenuHelpers.CenterHorizontally(row)
end
return BattleVersusProgressUI
