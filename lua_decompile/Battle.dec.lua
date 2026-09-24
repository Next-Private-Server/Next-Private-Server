local Battle = {}
function Battle.Quit(element)
  local campaignId = game.battleSystem():campaignId()
  local campaignData = game.getBattleCampaignData(campaignId)
  if not campaignData.isPVP then
    local battleIndex = game.getBattlePlayerData():getCampaignProgress(campaignId)
    game.logEvent("battle_quit", "campaign_id", tostring(campaignId), "battle_id", tostring(battleIndex))
  else
    game.battleSystem():finishBattle(false)
  end
  game.loadWorldContext()
end
return Battle
