local ColourPalette = {
  WHITE = "#ffffff",
  COIN_COLOUR = "#ffe617",
  SHARD_COLOUR = "#9b4dfc",
  DIAMOND_COLOUR = "#45db99",
  RELIC_COLOUR = "#b47320",
  FOOD_COLOUR = "#ffabf5",
  STARPOWER_COLOUR = "#0cd0f9",
  KEY_COLOUR = "#cbcbcb",
  MEDAL_COLOUR = "#c4eaf0",
  XP_COLOUR = "#4ff042",
  BATTLE_XP_COLOUR = "#fe7a0c",
  EGGWILDCARD_COLOUR = "#fc6868",
  CLUBBOX_TOKEN_COLOUR = "#00aeff",
  MINIGAME_TOKEN_COLOUR = "#4c9aad",
  DEFAULT_CURRENCY_COLOUR = "#ffffff",
  ENCORE_COLOUR = "#ffa400",
  XP_BAR_BACKING_STORE = "#42f542",
  XP_STAR_LEVEL_HUD = "#295B31",
  BATTLE_XP_STAR_LEVEL_HUD = "#6F231C",
  MONSTER_COMMON = "#FFFFFF",
  MONSTER_RARE = "#87E3C1",
  MONSTER_EPIC = "#FBC75F",
  MONSTER_SEASONAL = "#DB877D",
  MONSTER_LEVEL_COLOUR = "#f2ad4d",
  BATTLE_POWER_COLOUR = "#f2ad4d",
  BATTLE_STAMINA_COLOUR = "#f2ad4d",
  BATTLE_LEVELUP_TITLE_COLOUR = "#f2ad4d",
  BATTLE_LEVELUP_SUBTITLE_COLOUR = "#ffe617",
  AVAILABILITY_TIMER_COLOUR = "#95EB30",
  RESET_TIME_TIMER_COLOUR = "#95EB30",
  BATTLE_TIMER_COLOUR = "#8fe02e",
  BATTLE_STATUS_COLOUR = "#8fe02e",
  TRIBAL_ORANGE = "#f0991c",
  TITLE_GREEN = "#6DF905",
  TITLE_GREEN_2 = "#42f542",
  TITLE_GREEN_3 = "#6eff40",
  TITLE_PROMO_TEAL = "#70FAB5",
  TITLE_YELLOW = "#ffe617",
  TITLE_BLUE = "#3dabe6",
  TITLE_ORANGE = "#ed991c",
  TITLE_ORANGE_2 = "#f0a12b",
  TITLE_PURPLE = "#b573f0",
  TITLE_DARK_PURPLE = "#8776c8",
  CLUBBOX_ACT_NAME = "#70F5CB",
  TAB_TEXT_YELLOW_SELECTED = "#ffe617",
  TAB_TEXT_YELLOW_DESELECTED = "#BFAC11",
  TAB_TEXT_WHITE_SELECTED = "#ffffff",
  TAB_TEXT_WHITE_DESELECTED = "#BFBFBF",
  TAB_TEXT_GREEN_SELECTED = "#4ff042",
  TAB_TEXT_GREEN_DESELECTED = "#3bb432",
  TAB_TEXT_LEVEL_SELECTED = "#4ff042",
  TAB_TEXT_LEVEL_DESELECTED = "#3bb432",
  TAB_ICON_SELECTED = "#ffffff",
  TAB_ICON_DESELECTED = "#BFBFBF",
  TAB_SPRITE_SELECTED = "#ffffff",
  TAB_SPRITE_DESELECTED = "#e6e6e6",
  TAB_RANK_MENU_GLOBAL_SELECTED = "#f0991c",
  TAB_RANK_MENU_GLOBAL_DESELECTED = "#b47315",
  TAB_RANK_MENU_FRIENDS_SELECTED = "#b573f0",
  TAB_RANK_MENU_FRIENDS_DESELECTED = "#8856b4",
  MODIFIER_APPLIED_COLOUR = "#4ff042",
  NEW_LABEL_COLOUR = "#4ff042",
  LUCKY_BREED = "#ff7407",
  LUCKY_BREED_INFINITE = "#5bdcfe",
  DEFAULT_PROFILE_STAT_COLOUR = "#ffffff",
  FADED_BG_COLOUR = "#000000",
  LOAD_FADE_COLOUR = "#000000",
  cachedRGBs = {}
}
function ColourPalette:cacheHexRGB(hex)
  local index = hex
  self.cachedRGBs[index] = {
    r = nil,
    g = nil,
    b = nil
  }
  hex = hex:gsub("#", "")
  self.cachedRGBs[index] = {
    r = tonumber("0x" .. hex:sub(1, 2)),
    g = tonumber("0x" .. hex:sub(3, 4)),
    b = tonumber("0x" .. hex:sub(5, 6))
  }
  return self.cachedRGBs[index].r, self.cachedRGBs[index].g, self.cachedRGBs[index].b
end
function ColourPalette:hexToRGB(hex)
  local cachedColour = self.cachedRGBs[hex]
  if cachedColour then
    return cachedColour.r, cachedColour.g, cachedColour.b
  else
    return self:cacheHexRGB(hex)
  end
end
function ColourPalette:getRGBFloats(colour)
  local r, g, b = self:hexToRGB(colour)
  return r / 255, g / 255, b / 255
end
function ColourPalette:getRGBFloatsWithMultiplier(colour, multiplier)
  local r, g, b = self:hexToRGB(colour)
  return r / 255 * multiplier, g / 255 * multiplier, b / 255 * multiplier
end
return ColourPalette
