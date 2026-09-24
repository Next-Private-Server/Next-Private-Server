local IslandData = {}
local islandData = {
  {
    islandId = 1,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/01_intro_plant_island",
      particles = {
        psi = "particles/particle_motes.psi",
        image = "gfx/particles/particle_mote"
      }
    }
  },
  {
    islandId = 2,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/02_intro_cold_island",
      particles = {
        psi = "particles/particle_snow.psi",
        image = "gfx/particles/particle_snowflake"
      }
    }
  },
  {
    islandId = 3,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/03_intro_air_island"
    }
  },
  {
    islandId = 4,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/04_intro_water_island"
    }
  },
  {
    islandId = 5,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/05_intro_earth_island"
    }
  },
  {
    islandId = 6,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/06_intro_gold_island"
    }
  },
  {
    islandId = 7,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/07_intro_ethereal_island"
    }
  },
  {
    islandId = 8,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/08_intro_shugabush_island"
    }
  },
  {
    islandId = 9,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/09_intro_tribal_island"
    }
  },
  {
    islandId = 10,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/10_intro_wublin_island"
    }
  },
  {
    islandId = 11,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/11_intro_composer_island"
    }
  },
  {
    islandId = 12,
    scale = 1,
    intro = {
      titleSprite = "gfx/island_titles/12_intro_celestial_island"
    }
  },
  {
    islandId = 13,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/13_intro_fire_haven"
    }
  },
  {
    islandId = 14,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/14_intro_fire_oasis"
    }
  },
  {
    islandId = 15,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/15_intro_psychic_island"
    }
  },
  {
    islandId = 16,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/16_intro_faerie_island"
    }
  },
  {
    islandId = 17,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/17_intro_bone_island"
    }
  },
  {
    islandId = 18,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/18_intro_light_island"
    }
  },
  {
    islandId = 19,
    scale = 1,
    intro = {
      titleSprite = "gfx/island_titles/19_intro_magical_sanctum"
    }
  },
  {
    islandId = 20,
    scale = 1,
    intro = {
      titleSprite = "gfx/island_titles/20_intro_colossingum"
    }
  },
  {
    islandId = 21,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/21_intro_seasonal_shanty"
    }
  },
  {
    islandId = 22,
    scale = 1,
    intro = {
      titleSprite = "gfx/island_titles/22_intro_amber_island"
    }
  },
  {
    islandId = 23,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/23_intro_mythical_island"
    }
  },
  {
    islandId = 24,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/24_intro_ethereal_workshop"
    }
  },
  {
    islandId = 25,
    scale = 1,
    intro = {
      titleSprite = "gfx/island_titles/25_intro_magical_nexus"
    }
  },
  {
    islandId = 26,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/26_intro_plasma_islet"
    }
  },
  {
    islandId = 27,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/27_intro_mech_islet"
    }
  },
  {
    islandId = 28,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/28_intro_shadow_islet"
    }
  },
  {
    islandId = 29,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/29_intro_crystal_islet"
    }
  },
  {
    islandId = 31,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/31_intro_paironormal_carnival"
    }
  },
  {
    islandId = 101,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/101_intro_mirror_plant_island"
    }
  },
  {
    islandId = 102,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/102_intro_mirror_cold_island"
    }
  },
  {
    islandId = 103,
    scale = 1,
    intro = {
      titleSprite = "gfx/island_titles/103_intro_mirror_air_island"
    }
  },
  {
    islandId = 104,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/104_intro_mirror_water_island"
    }
  },
  {
    islandId = 105,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/105_intro_mirror_earth_island"
    }
  },
  {
    islandId = 106,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/11_intro_composer_island",
      noStart = true
    }
  },
  {
    islandId = 107,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/11_intro_composer_island",
      noStart = true
    }
  },
  {
    islandId = 108,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/11_intro_composer_island",
      noStart = true
    }
  },
  {
    islandId = 109,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/11_intro_composer_island",
      noStart = true
    }
  },
  {
    islandId = 115,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/115_intro_mirror_psychic_island"
    }
  },
  {
    islandId = 116,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/116_intro_mirror_faerie_island"
    }
  },
  {
    islandId = 117,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/117_intro_mirror_bone_island"
    }
  },
  {
    islandId = 118,
    scale = 2,
    intro = {
      titleSprite = "gfx/island_titles/118_intro_mirror_light_island"
    }
  }
}
local defaultEggs = {
  "gfx/spore_A",
  "gfx/spore_AB",
  "gfx/spore_ABD",
  "gfx/spore_ABDE",
  "gfx/spore_ABE",
  "gfx/spore_AD",
  "gfx/spore_ADE",
  "gfx/spore_AE",
  "gfx/spore_B",
  "gfx/spore_BD",
  "gfx/spore_BDE",
  "gfx/spore_BE",
  "gfx/spore_D",
  "gfx/spore_E"
}
local randomShuffle = function(table)
  for i = #table, 2, -1 do
    local j = math.random(i)
    local tmp = table[i]
    table[i] = table[j]
    table[j] = tmp
  end
end
local function getIslandEggs(island)
  if island >= 100 then
    island = island - 100
  end
  local availableMonstersIds = game.getAllMonstersForBookOfMonstersIsland(island)
  local availableMonsters = {}
  for i = 0, availableMonstersIds:size() - 1 do
    local monster = game.getMonsterData(availableMonstersIds[i])
    if not monster:isBoxMonster() and not monster:isDipster() then
      table.insert(availableMonsters, monster)
    end
  end
  randomShuffle(availableMonsters)
  local spores = {}
  if #availableMonsters > 0 then
    local i = 1
    while #spores < #defaultEggs do
      local randomMonster = availableMonsters[i]
      i = i % #availableMonsters + 1
      local sporeGfx = "gfx/" .. randomMonster:spore()
      table.insert(spores, sporeGfx)
    end
  end
  local i = 1
  while #spores < #defaultEggs do
    table.insert(spores, defaultEggs[i])
    i = i + 1
  end
  return spores
end
IslandData.GetIntroCutsceneEggs = getIslandEggs
local function getData(islandId)
  for _, v in pairs(islandData) do
    if v.islandId == islandId then
      return v
    end
  end
  return nil
end
IslandData.Get = getData
function IslandData.GetScale(islandId)
  local islandData = IslandData.Get(islandId)
  if islandData then
    return islandData.scale
  end
  return 1
end
return IslandData
