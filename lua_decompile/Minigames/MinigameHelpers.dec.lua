MinigameHelpers = {}
function MinigameHelpers:toJson(obj)
  local json = {}
  for key, value in pairs(obj) do
    table.insert(json, string.format("\"%s\":%s", key, value))
  end
  return "{" .. table.concat(json, ",") .. "}"
end
function MinigameHelpers:showLevelCompleteReward(reward, isTopReward)
  local menu = game.pushPopUp("minigame_level_complete_reward")
  menu:Setup(reward, isTopReward)
end
return MinigameHelpers
