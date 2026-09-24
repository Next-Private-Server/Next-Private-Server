local BreedingPossibilities = {}
local sortResults = function(a, b)
  local aAvail = game.monsterIsAvail(a, false)
  local bAvail = game.monsterIsAvail(b, false)
  if aAvail ~= bAvail then
    return aAvail
  end
  local aLimited = game.monsterLimitedAvailability(a, false)
  local bLimited = game.monsterLimitedAvailability(b, false)
  if aLimited ~= bLimited then
    return aLimited
  end
  local aDiscovered = game.hasOrHasEverHadMonsterOnActiveIsland(a)
  local bDiscovered = game.hasOrHasEverHadMonsterOnActiveIsland(b)
  if aDiscovered ~= bDiscovered then
    return not aDiscovered
  end
  return a < b
end
function BreedingPossibilities:getPossibleResults(leftMonster, rightMonster, includeUnavailable)
  local leftMonsterType = leftMonster:monsterId()
  local leftBaseMonster = leftMonsterType
  if leftMonster:isRareMonster() then
    leftBaseMonster = game.commonMonster(leftMonsterType)
  end
  local leftRareMonster = game.rareMonster(leftBaseMonster)
  local rightMonsterType = rightMonster:monsterId()
  local rightBaseMonster = rightMonsterType
  if rightMonster:isRareMonster() then
    rightBaseMonster = game.commonMonster(rightMonsterType)
  end
  local rightRareMonster = game.rareMonster(rightBaseMonster)
  local possibleResults = game.getPossibleBreedResults(leftBaseMonster, rightBaseMonster)
  local allPossibleResults = {}
  for i = 0, possibleResults:size() - 1 do
    table.insert(allPossibleResults, possibleResults[i])
  end
  local resultsMap = {}
  local function addIfAvailable(monsterType)
    local monsterData = game.getMonsterData(monsterType)
    if monsterData then
      local isAvailableInRegularMarket = game.monsterIsAvail(monsterType, false)
      if isAvailableInRegularMarket then
        resultsMap[monsterType] = true
      end
    end
  end
  local function addResult(monsterType)
    local hasMonsterType = game.Island_HasMonsterType(game.currentIsland(), monsterType)
    if hasMonsterType then
      if includeUnavailable then
        resultsMap[monsterType] = true
      else
        addIfAvailable(monsterType)
      end
    end
  end
  if leftBaseMonster == rightBaseMonster then
    local leftBaseMonsterData = game.getMonsterData(leftBaseMonster)
    if leftBaseMonsterData:canRarify() then
      if leftRareMonster > 0 then
        addResult(leftRareMonster)
      end
      if rightRareMonster > 0 then
        addResult(rightRareMonster)
      end
    end
    addResult(leftBaseMonster)
  end
  for i = 1, #allPossibleResults do
    local possibleMonsterType = allPossibleResults[i]
    addResult(possibleMonsterType)
    local possibleMonsterData = game.getMonsterData(possibleMonsterType)
    if possibleMonsterData:canRarify() then
      local possibleRareMonster = game.rareMonster(possibleMonsterType)
      if possibleRareMonster > 0 then
        addResult(possibleRareMonster)
      end
    end
  end
  local allPossibleResults = {}
  for resultType, _ in pairs(resultsMap) do
    table.insert(allPossibleResults, resultType)
  end
  if #allPossibleResults == 0 then
    print("Warning: No possible results found for", leftMonster:name(), "and", rightMonster:name())
  end
  for i = 1, #allPossibleResults do
    local resultType = allPossibleResults[i]
    local resultData = game.getMonsterData(resultType)
    print("Possible Result:", resultData:name(), resultType, resultData:spore())
  end
  table.sort(allPossibleResults, sortResults)
  return allPossibleResults
end
return BreedingPossibilities
