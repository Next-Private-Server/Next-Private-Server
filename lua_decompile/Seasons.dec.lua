local info = {
  [1] = {
    nativeIsland = 1,
    seasonEventName = "SEASONAL_MISSING_MONSTER_HALLOWEEN",
    monthString = "SEASONAL_MISSING_MONSTER_OCTOBER",
    sigilGraphic = "gene_halloween",
    fanfareGraphic = "bg_symbols_s01",
    monsterClassPostfix = "_HALLOWEEN"
  },
  [2] = {
    nativeIsland = 2,
    seasonEventName = "SEASONAL_MISSING_MONSTER_CHRISTMAS",
    monthString = "SEASONAL_MISSING_MONSTER_DECEMBER",
    sigilGraphic = "gene_xmas",
    fanfareGraphic = "bg_symbols_s02",
    monsterClassPostfix = "_CHRISTMAS"
  },
  [3] = {
    nativeIsland = 3,
    seasonEventName = "SEASONAL_MISSING_MONSTER_VALENTINE",
    monthString = "SEASONAL_MISSING_MONSTER_FEBRUARY",
    sigilGraphic = "gene_valentines",
    fanfareGraphic = "bg_symbols_s03",
    monsterClassPostfix = "_VALENTINE"
  },
  [4] = {
    nativeIsland = 4,
    seasonEventName = "SEASONAL_MISSING_MONSTER_EASTER",
    monthString = "SEASONAL_MISSING_MONSTER_APRIL",
    sigilGraphic = "gene_easter",
    fanfareGraphic = "bg_symbols_s04",
    monsterClassPostfix = "_EASTER"
  },
  [5] = {
    nativeIsland = 5,
    seasonEventName = "SEASONAL_MISSING_MONSTER_SUMMER",
    monthString = "SEASONAL_MISSING_MONSTER_JULY",
    sigilGraphic = "gene_summer",
    fanfareGraphic = "bg_symbols_s05",
    monsterClassPostfix = "_SUMMER"
  },
  [6] = {
    nativeIsland = 13,
    seasonEventName = "SEASONAL_MISSING_MONSTER_THANKSGIVING",
    monthString = "SEASONAL_MISSING_MONSTER_NOVEMBER",
    sigilGraphic = "gene_thanksgiving",
    fanfareGraphic = "bg_symbols_s06",
    monsterClassPostfix = "_THANKSGIVING"
  },
  [7] = {
    nativeIsland = 17,
    seasonEventName = "SEASONAL_MISSING_MONSTER_DAYOFTHEDEAD",
    monthString = "SEASONAL_MISSING_MONSTER_NOVEMBER",
    sigilGraphic = "gene_day_of_the_dead",
    fanfareGraphic = "bg_symbols_s07",
    monsterClassPostfix = "_DAYOFTHEDEAD"
  },
  [8] = {
    nativeIsland = 22,
    seasonEventName = "SEASONAL_MISSING_MONSTER_ECO",
    monthString = "SEASONAL_MISSING_MONSTER_APRIL",
    sigilGraphic = "gene_arbour",
    fanfareGraphic = "bg_symbols_s08",
    monsterClassPostfix = "_ECO"
  },
  [9] = {
    nativeIsland = 6,
    seasonEventName = "SEASONAL_MISSING_MONSTER_ANNIVERSARY",
    monthString = "SEASONAL_MISSING_MONSTER_SEPTEMBER",
    sigilGraphic = "gene_anniversary",
    fanfareGraphic = "bg_symbols_s09",
    monsterClassPostfix = "_ANNIVERSARY"
  },
  [10] = {
    nativeIsland = 19,
    seasonEventName = "SEASONAL_MISSING_MONSTER_NEWYEAR",
    monthString = "SEASONAL_MISSING_MONSTER_JANUARY",
    sigilGraphic = "gene_newyears",
    fanfareGraphic = "bg_symbols_s10",
    monsterClassPostfix = "_NEWYEAR"
  },
  [11] = {
    nativeIsland = 18,
    seasonEventName = "SEASONAL_MISSING_MONSTER_FIREWORKS",
    monthString = "SEASONAL_MISSING_MONSTER_JULY",
    sigilGraphic = "gene_fireworks",
    fanfareGraphic = "bg_symbols_s11",
    monsterClassPostfix = "_FIREWORKS"
  },
  [12] = {
    nativeIsland = 12,
    seasonEventName = "SEASONAL_MISSING_MONSTER_CREATION",
    monthString = "SEASONAL_MISSING_MONSTER_JUNE",
    sigilGraphic = "gene_creation",
    fanfareGraphic = "bg_symbols_s12",
    monsterClassPostfix = "_CREATION"
  },
  [13] = {
    nativeIsland = 16,
    seasonEventName = "SEASONAL_MISSING_MONSTER_STPATRICKS",
    monthString = "SEASONAL_MISSING_MONSTER_MARCH",
    sigilGraphic = "gene_stpatrick",
    fanfareGraphic = "bg_symbols_s13",
    monsterClassPostfix = "_STPATRICKS"
  },
  [14] = {
    nativeIsland = 15,
    seasonEventName = "SEASONAL_MISSING_MONSTER_BACKTOSCHOOL",
    monthString = "SEASONAL_MISSING_MONSTER_AUGUST",
    sigilGraphic = "gene_backtoschool",
    fanfareGraphic = "bg_symbols_s14",
    monsterClassPostfix = "_BACKTOSCHOOL"
  },
  [15] = {
    nativeIsland = 14,
    seasonEventName = "SEASONAL_MISSING_MONSTER_EXPLORE",
    monthString = "SEASONAL_MISSING_MONSTER_MAY",
    sigilGraphic = "gene_explore",
    fanfareGraphic = "bg_symbols_s15",
    monsterClassPostfix = "_EXPLORE"
  }
}
local function getSeasonInfo(seasonId)
  return info[seasonId] or {
    nativeIsland = 0,
    seasonEventName = "",
    monthString = "",
    sigilGraphic = "",
    fanfareGraphic = "",
    monsterClassPostfix = ""
  }
end
local function getSeasonalSigil(seasonId)
  return getSeasonInfo(seasonId).sigilGraphic
end
local function getSeasonName(seasonId)
  return getSeasonInfo(seasonId).seasonEventName
end
local function getSeasonMonth(seasonId)
  return getSeasonInfo(seasonId).monthString
end
local function getSeasonalSigilFromMonster(monsterId)
  return getSeasonalSigil(game.getMonsterData(monsterId):seasonId())
end
local function getSeasonalSigilFromMonsterUid(monsterUid)
  return getSeasonalSigil(game.getMonsterDataFromUniqueId(monsterUid):seasonId())
end
local Seasons = {}
Seasons.GetSeasonInfo = getSeasonInfo
Seasons.GetSeasonalSigil = getSeasonalSigil
Seasons.GetSeasonName = getSeasonName
Seasons.GetSeasonMonth = getSeasonMonth
Seasons.GetSeasonalSigilFromMonster = getSeasonalSigilFromMonster
Seasons.GetSeasonalSigilFromMonsterUid = getSeasonalSigilFromMonsterUid
function Seasons.GetSeasonalSettings(seasonId, seasonalSettings)
  local seasonData = getSeasonInfo(seasonId)
  if seasonData then
    seasonalSettings.nativeIsland = seasonData.nativeIsland or 0
    seasonalSettings.monsterClassPostfix = seasonData.monsterClassPostfix or ""
    return true
  end
  return false
end
return Seasons
