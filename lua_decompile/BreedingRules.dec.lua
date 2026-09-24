local BreedingRules = {}
local MIN_MONSTER_LEVEL = 4
local SHUGABUSH_ZERO_M_ID = 67
function BreedingRules.BreedableOnLeft(monster)
  if game.isLegendaryShuggaIsland() then
    return BreedingRules.IsBreedableOnShuggabushLeft(monster)
  elseif game.isMythicalIsland() then
    return BreedingRules.IsBreedableOnMythicalLeft(monster)
  else
    return BreedingRules.MonsterValidForBreeding(monster, false)
  end
end
function BreedingRules.BreedableOnRight(monster)
  if game.isLegendaryShuggaIsland() then
    return BreedingRules.IsBreedableOnShuggabushRight(monster)
  elseif game.isMythicalIsland() then
    return BreedingRules.IsBreedableOnMythicalRight(monster)
  else
    return BreedingRules.MonsterValidForBreeding(monster, false)
  end
end
function BreedingRules.IsBreedableOnShuggabushLeft(monster)
  local monsterData = monster:data()
  return monsterData and monsterData:monsterId() == SHUGABUSH_ZERO_M_ID
end
function BreedingRules.IsBreedableOnShuggabushRight(monster)
  local monsterData = monster:data()
  return monsterData and not monsterData:isShugaType() and #monsterData:unsortedGenes() > 0 and not monsterData:isEpicMonster()
end
function BreedingRules.IsBreedableOnMythicalLeft(monster)
  local monsterData = monster:data()
  return monsterData and monsterData:isMythicalCatalyst() and not monsterData:isEpicMonster()
end
function BreedingRules.IsBreedableOnMythicalRight(monster)
  local monsterData = monster:data()
  return monsterData and not monsterData:isMythicalCatalyst() and monsterData:isMythicalType() and not monsterData:isEpicMonster()
end
function BreedingRules.MonsterValidForBreeding(monster, rejectOnLevel)
  if BreedingRules.SatisfiesBasicRequirements(monster, rejectOnLevel) then
    return BreedingRules.SatisfiesIslandRequirements(monster) or BreedingRules.IsMagicalEthereal(monster) or BreedingRules.IsSeasonalIsland(monster)
  end
  return false
end
function BreedingRules.SatisfiesBasicRequirements(monster, rejectOnLevel)
  local monsterData = monster:data()
  if not monsterData then
    return false
  end
  if rejectOnLevel and monster:level() < MIN_MONSTER_LEVEL then
    return false
  end
  if monsterData:isSeasonal() and not game.isSeasonalIsland() or monsterData:isTitansoul() or monsterData:isMythicalType() and not game.isMythicalIsland() or monsterData:isWubbox() or monsterData:isUnderling() or monsterData:isPaironormal() and not monsterData:isModal() then
    return false
  end
  if monsterData:isLyrikcal() then
    return false
  end
  if monsterData:isLegendaryBB() or monsterData:isLegendaryTPain() or monsterData:isLegendaryAl() then
    return false
  end
  if monsterData:isEpicMonster() or monsterData:isDipster() then
    return false
  end
  if monsterData:hasKeyword("fireExp") then
    return false
  end
  return true
end
function BreedingRules.SatisfiesIslandRequirements(monster)
  local monsterData = monster:data()
  if not monsterData then
    return false
  end
  if game.isLegendaryShuggaIsland() or game.isMythicalIsland() then
    return BreedingRules.BreedableOnRight(monster) or BreedingRules.BreedableOnLeft(monster)
  elseif game.isEtherealIsland() then
    return true
  else
    return not monsterData:isEthereal() and not monsterData:isShugaType()
  end
end
function BreedingRules.IsMagicalEthereal(monster)
  local monsterData = monster:data()
  if monsterData and monsterData:isMagical() then
    local numGenes = #monsterData:unsortedGenes()
    if not game.isEtherealIsland() and numGenes == 1 then
      return true
    end
  end
  return false
end
function BreedingRules.IsSeasonalIsland(monster)
  local monsterData = monster:data()
  if monsterData and monsterData:isSeasonal() then
    local numGenes = #monsterData:unsortedGenes()
    if game.isSeasonalIsland() and numGenes == 0 then
      return true
    end
  end
  return false
end
function BreedingRules.ValidLeftSideExists(breedingVec)
  if game.isLegendaryShuggaIsland() then
    return BreedingRules.BreedableShugaMonsterExists(breedingVec)
  elseif game.isMythicalIsland() then
    return BreedingRules.BreedableMythicalMonsterExists(breedingVec)
  else
    return true
  end
end
function BreedingRules.ValidRightSideExists(breedingVec)
  if game.isLegendaryShuggaIsland() then
    return BreedingRules.BreedableNonShugaMonsterExists(breedingVec)
  elseif game.isMythicalIsland() then
    return BreedingRules.BreedableNonMythicalMonsterExists(breedingVec)
  else
    return true
  end
end
function BreedingRules.BreedableShugaMonsterExists(breedingVec)
  for i = 0, breedingVec:size() - 1 do
    local monster = breedingVec[i]
    if BreedingRules.SatisfiesBasicRequirements(monster, true) then
      local monsterData = monster:data()
      if monsterData and monsterData:monsterId() == SHUGABUSH_ZERO_M_ID then
        return true
      end
    end
  end
  return false
end
function BreedingRules.BreedableNonShugaMonsterExists(breedingVec)
  for i = 0, breedingVec:size() - 1 do
    local monster = breedingVec[i]
    if BreedingRules.SatisfiesBasicRequirements(monster, true) then
      local monsterData = monster:data()
      if monsterData ~= nil and monsterData:monsterId() ~= SHUGABUSH_ZERO_M_ID then
        return true
      end
    end
  end
  return false
end
function BreedingRules.BreedableMythicalMonsterExists(breedingVec)
  for i = 0, breedingVec:size() - 1 do
    local monster = breedingVec[i]
    if BreedingRules.SatisfiesBasicRequirements(monster, true) and monster:data():isMythicalCatalyst() then
      return true
    end
  end
  return false
end
function BreedingRules.BreedableNonMythicalMonsterExists(breedingVec)
  for i = 0, breedingVec:size() - 1 do
    local monster = breedingVec[i]
    if BreedingRules.SatisfiesBasicRequirements(monster, true) and not monster:data():isMythicalCatalyst() then
      return true
    end
  end
  return false
end
function BreedingRules.AtLeastTwoBreedable(breedingVec)
  local numBreedable = 0
  for i = 0, breedingVec:size() - 1 do
    local monster = breedingVec[i]
    if BreedingRules.SatisfiesBasicRequirements(monster, true) then
      numBreedable = numBreedable + 1
    end
  end
  return numBreedable > 1
end
function BreedingRules.Filter(monsterList, rule)
  local filteredList = {}
  for i = 0, monsterList:size() - 1 do
    local monster = monsterList[i]
    if rule(monster) then
      table.insert(filteredList, monster)
    end
  end
  return filteredList
end
return BreedingRules
