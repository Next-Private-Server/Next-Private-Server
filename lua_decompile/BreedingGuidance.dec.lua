local BreedingGuidance = {}
local getOverlappingGenes = function(monsterA, monsterB)
  local genesA = monsterA:sortedGenes()
  local overlappingGenes = {}
  for i = 1, #genesA do
    if monsterB:hasGene(genesA:sub(i, i)) then
      table.insert(overlappingGenes, genesA:sub(i, i))
    end
  end
  return overlappingGenes
end
local hasAllCombinations = function(monsterA, monsterB)
  local monsterAId = monsterA:monsterId()
  local monsterBId = monsterB:monsterId()
  local possibleResults = game.getPossibleBreedResults(monsterAId, monsterBId)
  local hasAllCombos = true
  for i = 0, possibleResults:size() - 1 do
    local result = possibleResults[i]
    if (result ~= monsterAId or result ~= monsterBId) and not game.hasOrHasEverHadMonsterOnActiveIsland(result) then
      hasAllCombos = false
      break
    end
  end
  return hasAllCombos
end
local getIslandMonsters = function()
  local islandMonsters = {}
  local monsters = game.player():getActiveIsland():monsters()
  for i = 0, monsters:size() - 1 do
    table.insert(islandMonsters, {
      id = monsters[i],
      type = game.monsterTypeId(monsters[i]),
      level = game.monsterLevel(monsters[i]),
      data = game.getMonsterDataFromUniqueId(monsters[i])
    })
  end
  return islandMonsters
end
local function getBreedingOpportunities()
  local generateKey = function(monsterTypeA, monsterTypeB, resultType)
    if monsterTypeA < monsterTypeB then
      return monsterTypeA .. "_" .. monsterTypeB .. "_" .. resultType
    else
      return monsterTypeB .. "_" .. monsterTypeA .. "_" .. resultType
    end
  end
  local count = 0
  local breedingOpportunities = {}
  local islandMonsters = getIslandMonsters()
  local checkedMonsterTypes = {}
  for i = 1, #islandMonsters do
    local monster = islandMonsters[i]
    local monsterType = monster.type
    if not checkedMonsterTypes[monsterType] then
      checkedMonsterTypes[monsterType] = true
      for j = 1, #islandMonsters do
        local otherMonster = islandMonsters[j]
        if monsterType ~= otherMonster.type then
          local possibleResults = game.getPossibleBreedResults(monster.type, otherMonster.type)
          for k = 0, possibleResults:size() - 1 do
            if not game.hasOrHasEverHadMonsterOnActiveIsland(possibleResults[k]) then
              local key = generateKey(monster.type, otherMonster.type, possibleResults[k])
              if breedingOpportunities[key] == nil then
                breedingOpportunities[key] = {
                  monsterA = monster,
                  monsterB = otherMonster,
                  result = possibleResults[k]
                }
                count = count + 1
              end
            end
          end
        end
      end
    end
  end
  return breedingOpportunities, count
end
local hasAllPurchaseableSingles = function()
  local island = game.player():getActiveIsland()
  local commonMonsters = game.getAllMonstersForBookOfMonstersIslandByRarity(island:id()):get(0)
  for i = 0, commonMonsters:size() - 1 do
    local monsterId = commonMonsters[i]
    local monster = game.getMonsterData(monsterId)
    if #monster:unsortedGenes() == 1 and island:monsterTypeCount(monsterId) == 0 and game.monsterIsAvail(monsterId, false) then
      return false
    else
    end
  end
  return true
end
function BreedingGuidance:CheckBreeding(monsterUidA, monsterUidB)
  if game.playerLevel() > 10 then
    return true
  end
  local monsterA = game.getMonsterDataFromUniqueId(monsterUidA)
  local monsterB = game.getMonsterDataFromUniqueId(monsterUidB)
  if monsterA and monsterB then
    local overlappingGenes = getOverlappingGenes(monsterA, monsterB)
    if #overlappingGenes > 0 then
      local warningPopup = game.pushPopUp("popup_breed_warning")
      warningPopup:setup("NOTIFICATION_OVERLAPPING_GENES", monsterA, monsterB, overlappingGenes)
      return false
    end
    if hasAllCombinations(monsterA, monsterB) then
      local breedingOpportunities, total = getBreedingOpportunities()
      if total > 0 then
        local canBreed = false
        for _, breedingOpportunity in pairs(breedingOpportunities) do
          if breedingOpportunity.monsterA.level >= 4 and 4 <= breedingOpportunity.monsterB.level then
            canBreed = true
            break
          end
        end
        if canBreed then
          local warningPopup = game.pushPopUp("popup_breed_warning")
          warningPopup:setup("NOTIFICATION_REPEATED_BREEDING", monsterA, monsterB)
        else
          local warningPopup = game.pushPopUp("popup_breed_warning")
          warningPopup:setup("NOTIFICATION_REPEATED_BREEDING_SHOULD_FEED", monsterA, monsterB)
        end
        return false
      else
      end
      if not hasAllPurchaseableSingles() then
        local warningPopup = game.pushPopUp("popup_breed_warning")
        warningPopup:setup("NOTIFICATION_REPEATED_BREEDING", monsterA, monsterB)
        return false
      end
    else
    end
  else
  end
  return true
end
return BreedingGuidance
