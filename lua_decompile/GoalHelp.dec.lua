local GoalHelp = {}
function GoalHelp.makeContext(quest, goalMenu)
  local context = {goals = goalMenu, quest = quest}
  setmetatable(context, {__index = _G})
  return context
end
function GoalHelp.getHelp(quest, goalMenu)
  local questTable = quest:GetLuaTable()
  if questTable == nil then
    return
  end
  if questTable.getHelp == nil then
    return
  end
  setfenv(questTable.getHelp, GoalHelp.makeContext(quest, goalMenu))
  questTable:getHelp()
end
function GoalHelp.canHelp(quest, goalMenu)
  if game.tutorialDisableExtraFeatures() then
    return false
  end
  if quest:isComplete() then
    return false
  end
  local questTable = quest:GetLuaTable()
  if questTable == nil then
    return false
  end
  if questTable.canHelp == nil then
    return false
  end
  setfenv(questTable.canHelp, GoalHelp.makeContext(quest, goalMenu))
  local canHelp = questTable:canHelp()
  if canHelp == nil then
    return false
  end
  return canHelp
end
return GoalHelp
