local MonsterPortraits = {}
if _PortraitData == nil then
  _PortraitData = {}
  _PortraitData[0] = ""
  _PortraitData[-1] = "monster_portrait_plant"
  _PortraitData[-2] = "monster_portrait_cold"
  _PortraitData[-3] = "monster_portrait_air"
  _PortraitData[-4] = "monster_portrait_water"
  _PortraitData[-5] = "monster_portrait_earth"
  _PortraitData[-6] = "monster_portrait_fire"
  _PortraitData[-7] = "monster_portrait_celestial"
  _PortraitData[-8] = "monster_portrait_crystal"
  _PortraitData[-9] = "monster_portrait_electricity"
  _PortraitData[-10] = "monster_portrait_gold"
  _PortraitData[-11] = "monster_portrait_legendary"
  _PortraitData[-12] = "monster_portrait_mech"
  _PortraitData[-13] = "monster_portrait_plasma"
  _PortraitData[-14] = "monster_portrait_poison"
  _PortraitData[-15] = "monster_portrait_shadow"
  _PortraitData[-16] = "monster_portrait_mythical"
  _PortraitData[-17] = "monster_portrait_psychic"
  _PortraitData[-18] = "monster_portrait_halloween"
  _PortraitData[-19] = "monster_portrait_valentine"
  _PortraitData[-20] = "monster_portrait_holiday"
  _PortraitData[-21] = "monster_portrait_easter"
  _PortraitData[-22] = "monster_portrait_summer"
  _PortraitData[-23] = "monster_portrait_thanksgiving"
  _PortraitData[-24] = "monster_portrait_anniversary"
  _PortraitData[-25] = "monster_portrait_newyears"
  _PortraitData[-26] = "monster_portrait_dayofthedead"
  _PortraitData[-27] = "monster_portrait_stpatrick"
  _PortraitData[-28] = "monster_portrait_dipster"
  _PortraitData[-29] = "monster_portrait_bone"
  _PortraitData[-30] = "monster_portrait_faerie"
  _PortraitData[-31] = "monster_portrait_light"
  _PortraitData[-32] = "monster_portrait_rares"
  _PortraitData[-33] = "monster_portrait_epics"
end
local getMonsterPortrait = function(monsterId, mode)
  monsterId = monsterId or 0
  mode = mode or 0
  local portrait = _PortraitData[monsterId]
  if portrait == nil then
    local monsterData = game.getMonsterData(monsterId)
    portrait = monsterData:portrait()
    if monsterData:isModal() then
      monsterData = game.getModalMonsterData(monsterData, mode)
      portrait = monsterData:portrait()
    end
  end
  return portrait
end
local isGoldEpicWubbox = function(monsterId)
  return monsterId == 670 or monsterId == 671 or monsterId == 672 or monsterId == 673 or monsterId == 674
end
function MonsterPortraits:getMonsterPortrait(monsterId, mode)
  local portrait = getMonsterPortrait(monsterId, mode)
  if isGoldEpicWubbox(monsterId) then
    portrait = getMonsterPortrait(game.goldEpicWubboxBaseMonsterId(), mode)
  end
  return portrait
end
function MonsterPortraits:getDefaultMonsterPortrait(monsterId, mode)
  return "gfx/breeding/" .. self:getMonsterPortrait(monsterId, mode)
end
function MonsterPortraits:getMemoryMonsterPortrait(monsterId)
  return self:getDefaultMonsterPortrait(monsterId)
end
function MonsterPortraits:getBookOfMonstersPortraitName(monsterId, mode)
  return getMonsterPortrait(monsterId, mode)
end
function MonsterPortraits:getBookOfMonstersPortrait(monsterId, mode)
  return "gfx/book/" .. getMonsterPortrait(monsterId, mode)
end
function MonsterPortraits:getBookOfMonstersPortraitDark(monsterId, mode)
  return self:getBookOfMonstersPortrait(monsterId, mode) .. "_black"
end
return MonsterPortraits
