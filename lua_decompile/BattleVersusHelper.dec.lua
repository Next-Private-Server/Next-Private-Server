local BattleVersusHelper = {}
function BattleVersusHelper.GetSeasonTiers(campaignId)
  local campaignData = game.getBattleCampaignData(campaignId)
  local seasonTiers = {}
  for idx = campaignData.tiers:size() - 1, 0, -1 do
    local tier = campaignData.tiers[idx]
    if not tier:isChampionTier() then
      table.insert(seasonTiers, idx)
    end
  end
  local seasonTitleText = LOC("BATTLE_VERSUS_SEASON_TIER")
  local data = {}
  data[0] = {
    name = seasonTitleText:gsub("%${TIER}", tostring(1)),
    tierId = #seasonTiers
  }
  for idx = 1, #seasonTiers do
    data[idx] = {
      name = seasonTitleText:gsub("%${TIER}", tostring(idx + 1)),
      tierId = seasonTiers[idx],
      data = campaignData.tiers[idx - 1]
    }
  end
  return data
end
function BattleVersusHelper.GetUserDisplayableTier(seasonTiers, dbTier)
  for idx = 1, #seasonTiers do
    if seasonTiers[idx].tierId == dbTier then
      return idx + 1
    end
  end
  return -1
end
return BattleVersusHelper
