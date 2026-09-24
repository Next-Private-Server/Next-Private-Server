local ClubboxPropData = {}
local clubboxPropDataSrc = {
  [1] = "ClubboxActs/ClubboxAct1",
  [2] = "ClubboxActs/ClubboxAct2",
  [3] = "ClubboxActs/ClubboxAct3",
  [4] = "ClubboxActs/ClubboxAct4"
}
local function getPropData(actId)
  local clubboxPropDataSrc = clubboxPropDataSrc[actId]
  if clubboxPropDataSrc then
    return include(clubboxPropDataSrc)
  end
  return nil
end
function ClubboxPropData:GetProps(actId, propList)
  local propData = getPropData(actId)
  if propData then
    for k, v in pairs(propData.props) do
      local prop = game.ClubboxPropData()
      prop.name = k
      prop.displayName = v.displayName or ""
      prop.propType = v.propType or game.ClubboxPropData_PROP_ANIM
      prop.animFile = v.animFile
      prop.costumeId = v.costumeId or 0
      prop.costumeFile = v.costumeFile or ""
      prop.attach = v.attach or ""
      prop.layer = v.layer or ""
      prop.priority = v.priority or -0.001
      prop.unlockId = v.unlockId or 0
      prop.maxUnlockId = v.maxUnlockId or 0
      prop.volume = v.volume or 1
      prop.instrument = v.instrument or ""
      prop.customizeIcon = v.customizeIcon or ""
      prop.customizeSheet = v.customizeSheet or ""
      prop.isMonster = v.isMonster or 0
      prop.inMemoryMode = v.inMemoryMode == nil and true or v.inMemoryMode
      if v.instruments then
        for unlockId, instrument in pairs(v.instruments) do
          prop:addInstrument(unlockId, instrument)
        end
      end
      if v.variants then
        for index, variant in pairs(v.variants) do
          local name = variant.name or ""
          local animFile = variant.animFile or ""
          local costumeFile = variant.costumeFile or ""
          local unlockId = variant.unlockId or 0
          local volume = variant.volume or 1
          local displayName = variant.displayName or ""
          local costumeId = variant.costumeId or 0
          local variantInstrument = variant.instrument or ""
          prop:addVariant(index, name, animFile, costumeFile, unlockId, volume, displayName, costumeId, variantInstrument)
        end
      end
      if v.onSetup then
        prop:setOnSetup(v.onSetup)
      end
      if v.onPick then
        prop:setOnPick(v.onPick)
      end
      if v.onTrigger then
        prop:setOnTrigger(v.onTrigger)
      end
      prop:finalize()
      propList.props:push_back(prop)
    end
    propList:finalize()
    return true
  end
  return false
end
function ClubboxPropData:AllPropInstruments(actId, instrumentList)
  instrumentList:clear()
  local instrumentSet = {}
  local propData = getPropData(actId)
  if propData then
    local props = propData.props
    for _, v2 in pairs(props) do
      if v2.instrument and v2.instrument ~= "" then
        instrumentSet[v2.instrument] = true
      end
      if v2.instruments then
        for power, instrument in pairs(v2.instruments) do
          if instrument and instrument ~= "" then
            instrumentSet[instrument] = true
          end
        end
      end
      if v2.variants then
        for kV, variant in pairs(v2.variants) do
          if variant.instrument and variant.instrument ~= "" then
            instrumentSet[variant.instrument] = true
          end
        end
      end
    end
  end
  for k, v in pairs(instrumentSet) do
    instrumentList:push_back(k)
  end
  return true
end
function ClubboxPropData:GetUnlockedProps(actId, oldHype, newHype, maxDelta)
  local actData = game.getClubboxActData(actId)
  oldHype = math.max(oldHype, actData:mixerUnlocksAt())
  local rewardTrackId = actData:rewardTrackId()
  local rewardTrackData = game.getRewardTrackData(rewardTrackId)
  local unlockedProps = {}
  local unlockedPerformers = {}
  local propData = getPropData(actId)
  if rewardTrackData and propData then
    for k, v in pairs(propData.props) do
      local isMonster = v.isMonster or 0
      local unlockId = v.unlockId or 0
      local minPower = rewardTrackData:getHypeForClubboxUnlockId(unlockId)
      local customizeIcon = v.customizeIcon or ""
      if customizeIcon ~= "" then
        if oldHype < minPower and newHype >= minPower then
          table.insert(isMonster > 0 and unlockedPerformers or unlockedProps, {
            name = k,
            variant = -1,
            monsterId = isMonster,
            customizeIcon = customizeIcon
          })
        end
        if v.variants then
          for k2, v2 in pairs(v.variants) do
            local variantUnlockId = v2.unlockId or 0
            local variantMinPower = rewardTrackData:getHypeForClubboxUnlockId(variantUnlockId)
            if oldHype < variantMinPower and newHype >= variantMinPower then
              table.insert(isMonster > 0 and unlockedPerformers or unlockedProps, {
                name = k,
                variant = k2,
                monsterId = isMonster,
                customizeIcon = customizeIcon
              })
            end
          end
        end
      end
    end
  end
  return unlockedProps, unlockedPerformers
end
function ClubboxPropData:GetPropsByUnlockId(actId)
  local actPropData = getPropData(actId)
  if actPropData then
    local maxUnlockId = 0
    local unlocks = {}
    for key, value in pairs(actPropData.props) do
      local id = value.unlockId or 0
      maxUnlockId = math.max(id, maxUnlockId)
      unlocks[id] = unlocks[id] or {}
      table.insert(unlocks[id], {name = key, variant = -1})
      if value.variants then
        for key2, value2 in pairs(value.variants) do
          local id2 = value2.unlockId or 0
          unlocks[id2] = unlocks[id2] or {}
          table.insert(unlocks[id2], {name = key, variant = key2})
        end
      end
    end
    for i = 0, maxUnlockId do
      unlocks[i] = unlocks[i] or {}
    end
    return unlocks
  end
  return nil
end
return ClubboxPropData
