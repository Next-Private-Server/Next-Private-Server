local FillQuestDescription = function(quest, description)
  local pattern = "{%s*([0-9]+)%s*:*s*([A-Za-z0-9]+)%s*}"
  local function replace(index, target)
    if target == "object" then
      local objectId = quest:getPropertyInt(index, target)
      return game.getLocalizedText(game.entityName(objectId))
    elseif target == "num" then
      return "" .. quest:getPropertyInt(index, target)
    end
    return "'" .. target .. " at " .. index .. "'"
  end
  local result, _ = string.gsub(description, pattern, replace)
  return result
end
return FillQuestDescription
