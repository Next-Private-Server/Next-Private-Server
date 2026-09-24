local BattleRewardListHelper = include("BattleRewardListHelper")
local BattleVersusResultsUI = {}
function BattleVersusResultsUI.ListPopulate(element)
  local battleClientData = game.getBattleClientData()
  local result = battleClientData:dequeueVersusRewardPopup()
  local status = result:status()
  if status == game.BattleVersusRewardPopupData_FinalResult then
    do
      local rewardsTitle = LOC("BATTLE_VERSUS_REWARDS_TITLE_FINAL")
      element:parent().Title.Text("text"):SetString(rewardsTitle)
      element:parent().ChampionInfo.Sprite("visible"):SetInt(0)
      element:parent().ChampionInfo.Text("visible"):SetInt(0)
      local campaignId = result:campaignId()
      local campaignData = game.getBattleCampaignData(campaignId)
      local rewards = {}
      local function addReward(source)
        rewards.coins = (rewards.coins or 0) + (source.coins or 0)
        rewards.diamonds = (rewards.diamonds or 0) + (source.diamonds or 0)
        rewards.xp = (rewards.xp or 0) + (source.xp or 0)
        rewards.medals = (rewards.medals or 0) + (source.medals or 0)
        rewards.food = (rewards.food or 0) + (source.food or 0)
        rewards.starpower = (rewards.starpower or 0) + (source.starpower or 0)
        rewards.relics = (rewards.relics or 0) + (source.relics or 0)
        rewards.keys = (rewards.keys or 0) + (source.keys or 0)
        rewards.costumeId = 0 < source.costumeId and source.costumeId or rewards.costumeId or 0
        rewards.trophy = 0 < source.trophy and source.trophy or rewards.trophy or 0
      end
      if result:seasonCompleted() then
        local rank = result:rank()
        local rewardsText = LOC("BATTLE_VERSUS_REWARDS_RANK")
        rewardsText = rewardsText:gsub("%${RANK}", rank)
        element:parent().RewardsText.Text("text"):SetString(rewardsText)
      else
        local tier = result:tier()
        local rewardsText = LOC("BATTLE_VERSUS_REWARDS_TIER")
        rewardsText = rewardsText:gsub("%${TIER}", campaignData.numSeasonTiers - tier + 1)
        element:parent().RewardsText.Text("text"):SetString(rewardsText)
      end
      addReward(result:seasonReward())
      addReward(result:campaignReward())
      addReward(result:championReward())
      BattleRewardListHelper.Populate(element, rewards)
    end
  elseif status == game.BattleVersusRewardPopupData_CompletedSeason then
    element:parent().Title.Text("text"):SetString("BATTLE_VERSUS_REWARDS_TITLE_COMPLETED")
  else
    element:parent().Title.Text("text"):SetString("VOIDCORN WUZ HEER")
  end
end
return BattleVersusResultsUI
