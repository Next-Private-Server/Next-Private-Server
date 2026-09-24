local IslandMapData = {}
local data = {
  id = 0,
  node = "default",
  tag = "map_tag_island01",
  tag_sheet = "xml_resources/map_tags_sheet_01.xml",
  pin = "map_pin_island01",
  pin_sheet = "map_pins_sheet_01.xml",
  location = "map_icon_sketch_island01",
  location_sheet = "map_locations_sheet_01.xml",
  on_mirror_map = false
}
function data:new(obj)
  local obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end
function data:getActiveIslandTheme()
  local activeThemeId = 0
  if game.mapContext():isFriendMode() then
    activeThemeId = game.getFriendActiveIslandTheme(self.id)
  else
    activeThemeId = game.getActiveIslandTheme(self.id)
  end
  return activeThemeId
end
function data:getSelectedIslandIconSheet()
  local activeThemeId = self:getActiveIslandTheme()
  if activeThemeId > 0 then
    return "xml_resources/" .. game.islandThemeIconSheetForId(activeThemeId)
  end
  return "xml_resources/" .. game.islandIconSheetForId(self.id)
end
function data:getSelectedIslandIconSprite()
  local activeThemeId = self:getActiveIslandTheme()
  if activeThemeId > 0 then
    return game.islandThemeIconForId(activeThemeId)
  end
  return game.islandIconSpriteForId(self.id)
end
function data:getLocationSprite()
  return self.location
end
function data:getLocationSheet()
  return self.location_sheet
end
local skinTags = {}
skinTags[1] = "map_tag_island01_skin01"
skinTags[2] = "map_tag_island02_skin01"
skinTags[3] = "map_tag_island05_skin01"
skinTags[4] = "map_tag_island04_skin01"
skinTags[5] = "map_tag_island03_skin01"
skinTags[6] = "map_tag_island01_halloween"
skinTags[7] = "map_tag_island02_christmas"
skinTags[8] = "map_tag_island03_valentines"
skinTags[9] = "map_tag_island04_easter"
skinTags[10] = "map_tag_island05_summersong"
skinTags[11] = "map_tag_island06_anniversary"
skinTags[12] = "map_tag_island13_thanksgiving"
skinTags[13] = "map_tag_island17_dayofthedead"
skinTags[14] = "map_tag_island19_newyears"
skinTags[15] = "map_tag_island16_stpatricks"
skinTags[16] = "map_tag_island22_arbor"
skinTags[17] = "map_tag_island14_perplexplore"
skinTags[18] = "map_tag_island07_lifeformula"
skinTags[19] = "map_tag_island18_skypainting"
skinTags[20] = "map_tag_island15_mindboggle"
function data:getTagSprite()
  local activeThemeId = self:getActiveIslandTheme()
  if activeThemeId > 0 then
    return skinTags[activeThemeId]
  end
  return self.tag
end
function data:getTagSheet()
  return self.tag_sheet
end
local skinPins = {}
skinPins[1] = "map_pin_island01_skin01"
skinPins[2] = "map_pin_island02_skin01"
skinPins[3] = "map_pin_island05_skin01"
skinPins[4] = "map_pin_island04_skin01"
skinPins[5] = "map_pin_island03_skin01"
skinPins[6] = "map_pin_island01_halloween"
skinPins[7] = "map_pin_island02_christmas"
skinPins[8] = "map_pin_island03_valentines"
skinPins[9] = "map_pin_island04_easter"
skinPins[10] = "map_pin_island05_summersong"
skinPins[11] = "map_pin_island06_anniversary"
skinPins[12] = "map_pin_island13_feastember"
skinPins[13] = "map_pin_island17_beathereafter"
skinPins[14] = "map_pin_island19_crecendomoon"
skinPins[15] = "map_pin_island16_cloverspell"
skinPins[16] = "map_pin_island22_echosofeco"
skinPins[17] = "map_pin_island14_perplexore"
skinPins[18] = "map_pin_island07_lifeformula"
skinPins[19] = "map_pin_island18_skypainting"
skinPins[20] = "map_pin_island15_mindboggle"
function data:getPinSprite()
  local activeThemeId = self:getActiveIslandTheme()
  if activeThemeId > 0 then
    return skinPins[activeThemeId]
  end
  return self.pin
end
function data:getPinSheet()
  local activeThemeId = self:getActiveIslandTheme()
  if activeThemeId > 0 then
    return "map_pins_skins_sheet_01.xml"
  end
  return self.pin_sheet
end
function data:getPinAnim()
  return self.pin_anim or "pin_idle"
end
local seasonalData = {}
seasonalData[6] = {
  id = 6,
  icon = "gene_halloween",
  titleCard = "gfx/menu/map/seasonal/seasonal_text_spooktacle"
}
seasonalData[7] = {
  id = 7,
  icon = "gene_xmas",
  titleCard = "gfx/menu/map/seasonal/seasonal_text_festival_of_yay"
}
seasonalData[8] = {
  id = 8,
  icon = "gene_valentines",
  titleCard = "gfx/menu/map/seasonal/seasonal_text_season_of_love"
}
seasonalData[9] = {
  id = 9,
  icon = "gene_easter",
  titleCard = "gfx/menu/map/seasonal/seasonal_text_eggstravaganza"
}
seasonalData[10] = {
  id = 10,
  icon = "gene_summer",
  titleCard = "gfx/menu/map/seasonal/seasonal_text_summer_song"
}
seasonalData[11] = {
  id = 11,
  icon = "gene_anniversary",
  titleCard = "gfx/menu/map/seasonal/seasonal_text_ann_month"
}
seasonalData[12] = {
  id = 12,
  icon = "gene_thanksgiving",
  titleCard = "gfx/menu/map/seasonal/seasonal_text_feast_ember"
}
seasonalData[13] = {
  id = 13,
  icon = "gene_day_of_the_dead",
  titleCard = "gfx/menu/map/seasonal/seasonal_text_beat_hereafter"
}
seasonalData[14] = {
  id = 14,
  icon = "gene_newyears",
  titleCard = "gfx/menu/map/seasonal/seasonal_text_crescendo_moon"
}
seasonalData[15] = {
  id = 15,
  icon = "gene_stpatrick",
  titleCard = "gfx/menu/map/seasonal/seasonal_text_cloverspell"
}
seasonalData[16] = {
  id = 16,
  icon = "gene_arbour",
  titleCard = "gfx/menu/map/seasonal/seasonal_text_echoes_of_eco"
}
seasonalData[17] = {
  id = 17,
  icon = "gene_explore",
  titleCard = "gfx/menu/map/seasonal/seasonal_text_perplexplore"
}
seasonalData[18] = {
  id = 18,
  icon = "gene_creation",
  titleCard = "gfx/menu/map/seasonal/seasonal_text_life_formula"
}
seasonalData[19] = {
  id = 19,
  icon = "gene_fireworks",
  titleCard = "gfx/menu/map/seasonal/seasonal_text_sky_painting"
}
seasonalData[20] = {
  id = 20,
  icon = "gene_backtoschool",
  titleCard = "gfx/menu/map/seasonal/seasonal_text_mind_boggle"
}
function data:getAvailableSeasonalThemeData()
  local themeId = game.timedAvailIslandThemeId(self.id)
  if themeId > 0 and game.islandThemeIsSeasonal(themeId) then
    return seasonalData[themeId]
  end
  return nil
end
local mapData = {}
mapData[1] = data:new({
  id = 1,
  node = "plant",
  location_node = "map_location_plant",
  tag = "map_tag_island01",
  pin = "map_pin_island01",
  location = "map_icon_sketch_island01"
})
mapData[2] = data:new({
  id = 2,
  node = "cold",
  location_node = "map_location_cold",
  tag = "map_tag_island02",
  pin = "map_pin_island02",
  location = "map_icon_sketch_island02"
})
mapData[3] = data:new({
  id = 3,
  node = "air",
  location_node = "map_location_air",
  tag = "map_tag_island03",
  pin = "map_pin_island03",
  location = "map_icon_sketch_island03"
})
mapData[4] = data:new({
  id = 4,
  node = "water",
  location_node = "map_location_water",
  tag = "map_tag_island04",
  pin = "map_pin_island04",
  location = "map_icon_sketch_island04"
})
mapData[5] = data:new({
  id = 5,
  node = "earth",
  location_node = "map_location_earth",
  tag = "map_tag_island05",
  pin = "map_pin_island05",
  location = "map_icon_sketch_island05"
})
mapData[6] = data:new({
  id = 6,
  node = "gold",
  location_node = "map_location_gold",
  tag = "map_tag_island06",
  pin = "map_pin_island06",
  location = "map_icon_sketch_island06"
})
mapData[7] = data:new({
  id = 7,
  node = "ethereal",
  location_node = "map_location_ethereal",
  tag = "map_tag_island07",
  pin = "map_pin_island07",
  location = "map_icon_sketch_island07"
})
mapData[8] = data:new({
  id = 8,
  node = "shugabush",
  location_node = "map_location_shugabush",
  tag = "map_tag_island08",
  pin = "map_pin_island08",
  location = "map_icon_sketch_island08"
})
mapData[9] = data:new({
  id = 9,
  node = "tribal",
  location_node = "map_location_tribal",
  tag = "map_tag_island09",
  pin = "map_pin_island09",
  location = "map_icon_sketch_island09"
})
mapData[10] = data:new({
  id = 10,
  node = "wublin",
  location_node = "map_location_wublin",
  tag = "map_tag_island10",
  pin = "map_pin_island10",
  location = "map_icon_sketch_island10"
})
mapData[11] = data:new({
  id = 11,
  node = "composer",
  location_node = "map_location_composer",
  tag = "map_tag_island11",
  pin = "map_pin_island11",
  location = "map_icon_sketch_island11"
})
mapData[12] = data:new({
  id = 12,
  node = "celestial",
  location_node = "map_location_celestial",
  tag = "map_tag_island12",
  pin = "map_pin_island12",
  location = "map_icon_sketch_island12"
})
mapData[13] = data:new({
  id = 13,
  node = "fire_haven",
  location_node = "map_location_fire_haven",
  tag = "map_tag_island13",
  pin = "map_pin_island13",
  location = "map_icon_sketch_island13"
})
mapData[14] = data:new({
  id = 14,
  node = "fire_oasis",
  location_node = "map_location_fire_oasis",
  tag = "map_tag_island14",
  pin = "map_pin_island14",
  location = "map_icon_sketch_island14"
})
mapData[15] = data:new({
  id = 15,
  node = "psychic",
  location_node = "map_location_psychic",
  tag = "map_tag_island15",
  pin = "map_pin_island15",
  location = "map_icon_sketch_island15"
})
mapData[16] = data:new({
  id = 16,
  node = "faerie",
  location_node = "map_location_faerie",
  tag = "map_tag_island16",
  pin = "map_pin_island16",
  location = "map_icon_sketch_island16"
})
mapData[17] = data:new({
  id = 17,
  node = "bone",
  location_node = "map_location_bone",
  tag = "map_tag_island17",
  pin = "map_pin_island17",
  location = "map_icon_sketch_island17"
})
mapData[18] = data:new({
  id = 18,
  node = "light",
  location_node = "map_location_light",
  tag = "map_tag_island18",
  pin = "map_pin_island18",
  location = "map_icon_sketch_island18"
})
mapData[19] = data:new({
  id = 19,
  node = "magical",
  location_node = "map_location_magical",
  tag = "map_tag_island19",
  pin = "map_pin_island19",
  location = "map_icon_sketch_island19"
})
mapData[20] = data:new({
  id = 20,
  node = "battle",
  location_node = "map_location_battle",
  tag = "map_tag_island20",
  pin = "map_pin_island20",
  location = "map_icon_sketch_island20"
})
mapData[21] = data:new({
  id = 21,
  node = "seasonal",
  location_node = "map_location_seasonal",
  tag = "map_tag_island21",
  pin = "map_pin_island21",
  location = "map_icon_sketch_island21"
})
mapData[22] = data:new({
  id = 22,
  node = "amber",
  location_node = "map_location_amber",
  tag = "map_tag_island22",
  pin = "map_pin_island22",
  location = "map_icon_sketch_island22"
})
mapData[23] = data:new({
  id = 23,
  node = "mythical",
  location_node = "map_location_mythical",
  tag = "map_tag_island23",
  pin = "map_pin_island23",
  location = "map_icon_sketch_island23"
})
mapData[24] = data:new({
  id = 24,
  node = "ethereal_workshop",
  location_node = "map_location_ethereal_workshop",
  tag = "map_tag_island24",
  pin = "map_pin_island24",
  location = "map_icon_sketch_island24"
})
mapData[25] = data:new({
  id = 25,
  node = "magical_nexus",
  location_node = "map_location_magical_nexus",
  tag = "map_tag_island25",
  pin = "map_pin_island25",
  location = "map_icon_sketch_island25"
})
mapData[26] = data:new({
  id = 26,
  node = "plasma",
  location_node = "map_location_plasma",
  tag = "map_tag_island26",
  pin = "map_pin_island26",
  pin_sheet = "map_pins_skins_sheet_01.xml",
  location = "map_icon_sketch_island26",
  on_mirror_map = true
})
mapData[27] = data:new({
  id = 27,
  node = "mech",
  location_node = "map_location_mech",
  tag = "map_tag_island27",
  pin = "map_pin_island27",
  pin_sheet = "map_pins_skins_sheet_01.xml",
  location = "map_icon_sketch_island27",
  on_mirror_map = true
})
mapData[28] = data:new({
  id = 28,
  node = "shadow",
  location_node = "map_location_shadow",
  tag = "map_tag_island28",
  pin = "map_pin_island28",
  pin_sheet = "map_pins_skins_sheet_01.xml",
  pin_anim = "pin_idle_shadow",
  location = "map_icon_sketch_island28",
  on_mirror_map = true
})
mapData[29] = data:new({
  id = 29,
  node = "crystal",
  location_node = "map_location_crystal",
  location_sheet = "map_locations_sheet_02.xml",
  tag = "map_tag_island29",
  pin = "map_pin_island29",
  pin_sheet = "map_pins_skins_sheet_01.xml",
  location = "map_icon_sketch_island29",
  on_mirror_map = true
})
mapData[31] = data:new({
  id = 31,
  node = "paironormal_MAJ",
  location_node = "map_location_paironormal",
  tag = "map_tag_island31",
  tag_sheet = "xml_resources/map_tags_sheet_01.xml",
  pin = "map_pin_island31",
  location = "map_icon_sketch_island31"
})
mapData[131] = data:new({
  id = 31,
  node = "paironormal_MIN",
  location_node = "map_location_paironormal_MIN",
  tag = "map_tag_island31_MIN",
  tag_sheet = "xml_resources/map_tags_sheet_02.xml",
  pin = "map_pin_island31_MIN",
  pin_sheet = "map_pins_skins_sheet_01.xml",
  location = "map_icon_sketch_island31",
  on_mirror_map = true
})
mapData[31].modes = {}
mapData[31].modes[1] = mapData[131]
mapData[101] = data:new({
  id = 101,
  node = "plant",
  location_node = "map_location_plant_mirror",
  tag = "map_tag_island01_mirror",
  tag_sheet = "xml_resources/map_tags_sheet_02.xml",
  pin = "map_pin_island01_mirror",
  pin_sheet = "map_pins_skins_sheet_01.xml",
  location = "map_icon_sketch_island01_mirror",
  on_mirror_map = true
})
mapData[102] = data:new({
  id = 102,
  node = "cold",
  location_node = "map_location_cold_mirror",
  tag = "map_tag_island02_mirror",
  tag_sheet = "xml_resources/map_tags_sheet_02.xml",
  pin = "map_pin_island02_mirror",
  pin_sheet = "map_pins_skins_sheet_01.xml",
  location = "map_icon_sketch_island02_mirror",
  on_mirror_map = true
})
mapData[103] = data:new({
  id = 103,
  node = "air",
  location_node = "map_location_air_mirror",
  tag = "map_tag_island03_mirror",
  tag_sheet = "xml_resources/map_tags_sheet_02.xml",
  pin = "map_pin_island03_mirror",
  pin_sheet = "map_pins_skins_sheet_01.xml",
  location = "map_icon_sketch_island03_mirror",
  on_mirror_map = true
})
mapData[104] = data:new({
  id = 104,
  node = "water",
  location_node = "map_location_water_mirror",
  tag = "map_tag_island04_mirror",
  tag_sheet = "xml_resources/map_tags_sheet_02.xml",
  pin = "map_pin_island04_mirror",
  pin_sheet = "map_pins_skins_sheet_01.xml",
  location = "map_icon_sketch_island04_mirror",
  on_mirror_map = true
})
mapData[105] = data:new({
  id = 105,
  node = "earth",
  location_node = "map_location_earth_mirror",
  tag = "map_tag_island05_mirror",
  tag_sheet = "xml_resources/map_tags_sheet_02.xml",
  pin = "map_pin_island05_mirror",
  pin_sheet = "map_pins_skins_sheet_01.xml",
  location = "map_icon_sketch_island05_mirror",
  on_mirror_map = true
})
mapData[115] = data:new({
  id = 115,
  node = "psychic",
  location_node = "map_location_psychic_mirror",
  tag = "map_tag_island15_mirror",
  tag_sheet = "xml_resources/map_tags_sheet_02.xml",
  pin = "map_pin_island15_mirror",
  pin_sheet = "map_pins_skins_sheet_01.xml",
  location = "map_icon_sketch_island15_mirror",
  on_mirror_map = true
})
mapData[116] = data:new({
  id = 116,
  node = "faerie",
  location_node = "map_location_faerie_mirror",
  tag = "map_tag_island16_mirror",
  tag_sheet = "xml_resources/map_tags_sheet_02.xml",
  pin = "map_pin_island16_mirror",
  pin_sheet = "map_pins_skins_sheet_01.xml",
  location = "map_icon_sketch_island16_mirror",
  on_mirror_map = true
})
mapData[117] = data:new({
  id = 117,
  node = "bone",
  location_node = "map_location_bone_mirror",
  tag = "map_tag_island17_mirror",
  tag_sheet = "xml_resources/map_tags_sheet_02.xml",
  pin = "map_pin_island17_mirror",
  pin_sheet = "map_pins_skins_sheet_01.xml",
  location = "map_icon_sketch_island17_mirror",
  on_mirror_map = true
})
mapData[118] = data:new({
  id = 118,
  node = "light",
  location_node = "map_location_light_mirror",
  tag = "map_tag_island18_mirror",
  tag_sheet = "xml_resources/map_tags_sheet_02.xml",
  pin = "map_pin_island18_mirror",
  pin_sheet = "map_pins_skins_sheet_01.xml",
  location = "map_icon_sketch_island18_mirror",
  on_mirror_map = true
})
mapData[106] = mapData[11]
mapData[107] = mapData[11]
mapData[108] = mapData[11]
mapData[109] = mapData[11]
local CLUBBOX_MEMORY_ID = 1000000
mapData[1000000] = data:new({
  id = CLUBBOX_MEMORY_ID,
  node = "special_memory",
  location_node = "special_memory",
  tag = "map_tag_clubbox",
  tag_sheet = "xml_resources/map_tags_sheet_01.xml",
  on_mirror_map = false
})
function IslandMapData:GetIslandData(islandId, mode)
  mode = mode or 0
  local data = mapData[islandId] or data:new()
  if data.modes and data.modes[mode] then
    return data.modes[mode]
  end
  return data
end
function IslandMapData:GetIslandIdByNodeName(nodeName, isMirrorMode)
  for k, v in pairs(mapData) do
    if v.node == nodeName and v.on_mirror_map == isMirrorMode then
      return k
    end
  end
  return 0
end
return IslandMapData
