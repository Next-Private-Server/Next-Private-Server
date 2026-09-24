local UserProfile = {}
UserProfile.friendObject = nil
function UserProfile.onInit(element)
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgGameFriendsSynced", "gotMsgGameFriendsSynced")
end
function UserProfile:gotMsgGameFriendsSynced(msg)
  game.popPopUp()
  manager:setContext("FRIENDS")
  game.setPlayerProfileReturningMenu("")
end
function UserProfile.onPostInitLua(element)
  local friendUserId = game.getSelectedFriendUserId()
  if friendUserId > 0 then
    local friendObject
    local isActualFriend = false
    local friends = game.getFriends()
    for i = 0, friends:size() - 1 do
      local friend = friends[i]
      if friend:userId() == friendUserId then
        friendObject = friend
        isActualFriend = true
        break
      end
    end
    if friendObject == nil then
      friends = game.getFriendRequests()
      for i = 0, friends:size() - 1 do
        local friend = friends[i]
        if friend:userId() == friendUserId then
          friendObject = friend
          isActualFriend = false
          break
        end
      end
    end
    if friendObject == nil then
      friends = game.getFriendDiscover()
      for i = 0, friends:size() - 1 do
        local friend = friends[i]
        if friend:userId() == friendUserId then
          friendObject = friend
          isActualFriend = false
          break
        end
      end
    end
    if friendObject == nil then
      game.popPopUp()
      manager:setContext("FRIENDS")
    else
      UserProfile.SetToFriend(element, friendObject)
      if not isActualFriend then
        element:E("DeleteButton"):DoStoredScript("setInvisible")
        element:E("Card"):SetView("DISCOVER_PROFILE_VIEW", true)
        UserProfile.HideStat(element, 4)
        UserProfile.HideStat(element, 5)
      end
    end
    game.selectFriend(0)
  else
    UserProfile.SetToPlayer(element)
  end
end
function UserProfile:gotMsgPlayerUpdated(msg)
  local moniker = game.playerLevelTitle()
  local monikerE = self:E("Moniker")
  monikerE:C("Text")("text"):SetString(moniker)
end
function UserProfile:gotMsgPlayerProfileUpdated(msg)
  local cardE = self:E("Card")
  cardE:SetView("PLAYER_PROFILE_VIEW", true)
  cardE:SetPlayerProfile(game.playerProfile(), game.playerDisplayName())
  UserProfile.SetPlayerProfile(self, game.playerProfile())
end
function UserProfile:formatTime(totalTime)
  local totalDays = math.floor(totalTime / 86400000)
  local timeText = ""
  local weeksInAMonth = 4.345
  if totalDays < 14 then
    timeText = select(1, game.getLocalizedText("JOINED_DAYS"):gsub("XXX", totalDays))
  else
    local totalWeeks = math.floor(totalDays / 7)
    if totalWeeks < weeksInAMonth * 2 then
      timeText = select(1, game.getLocalizedText("JOINED_WEEKS"):gsub("XXX", totalWeeks))
    else
      local totalMonths = math.floor(totalWeeks / weeksInAMonth)
      if totalMonths < 24 then
        timeText = select(1, game.getLocalizedText("JOINED_MONTHS"):gsub("XXX", totalMonths))
      else
        timeText = select(1, game.getLocalizedText("JOINED_YEARS"):gsub("XXX", math.floor(totalDays / 365)))
      end
    end
  end
  return timeText
end
function UserProfile.SetToPlayer(element)
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlayerUpdated", "gotMsgPlayerUpdated")
  element:SetupGenericListener(game.engineReceiver(), "game::msg::MsgPlayerProfileUpdated", "gotMsgPlayerProfileUpdated")
  local playerProfile = game.playerProfile()
  local cardE = element:E("Card")
  cardE:SetView("PLAYER_PROFILE_VIEW", true)
  cardE:SetPlayerProfile(playerProfile, game.playerDisplayName(), false)
  UserProfile.SetPlayerProfile(element, playerProfile)
  local level = game.playerLevel()
  if level >= 30 then
    element:E("Moniker"):DoStoredScript("setVisible")
  end
  local playerStatsE = element:E("PlayerStats")
  if game.isBattleIsland() then
    UserProfile.SetStatToBattleLevel(element, 1, playerProfile)
    local battleLevel = game.getBattlePlayerData().level
    if battleLevel >= game.maxPlayerBattleLevel() then
      playerStatsE:C("Stat1Value")("text"):SetString("-")
    else
      playerStatsE:C("Stat1Value")("text"):SetString(game.commaizeNumber(game.playerCurrentBattleXp()) .. "/" .. game.commaizeNumber(game.playerBattleXpForLevel()))
    end
  else
    UserProfile.SetStatToLevel(element, 1, playerProfile)
    if level >= game.maxPlayerLevel() then
      playerStatsE:C("Stat1Value")("text"):SetString("-")
    else
      playerStatsE:C("Stat1Value")("text"):SetString(game.commaizeNumber(game.playerCurrentXp()) .. "/" .. game.commaizeNumber(game.playerXpForLevel()))
    end
  end
  UserProfile.SetStatToStarPower(element, 2)
  playerStatsE:C("Stat2Value")("text"):SetString(game.totalStarpowerEarned())
  UserProfile.SetStatToCreated(element, 3)
  local timeText = UserProfile:formatTime(game.playerTimeSinceCreated() * -1)
  playerStatsE:C("Stat3Value")("text"):SetString(timeText)
  UserProfile.SetStatToTorchesLit(element, 4)
  playerStatsE:C("Stat4Value")("text"):SetString(playerProfile:getTotalTorchesLit())
  UserProfile.HideStat(element, 5)
  element:E("DeleteButton"):DoStoredScript("setInvisible")
end
function UserProfile.SetToFriend(element, friendObject)
  UserProfile.friendObject = friendObject
  local cardE = element:E("Card")
  cardE:SetView("FRIEND_PROFILE_VIEW", true)
  cardE:SetFriendObject(friendObject)
  local friendProfile = friendObject:getProfile()
  UserProfile.SetPlayerProfile(element, friendProfile)
  local playerStatsE = element:E("PlayerStats")
  if friendProfile:getLevel() >= game.maxPlayerLevel() then
    playerStatsE:C("Stat1Value")("text"):SetString("-")
  else
    playerStatsE:C("Stat1Value")("text"):SetString(game.commaizeNumber(friendObject:xp()) .. "/" .. game.commaizeNumber(game.xpForLevel(friendProfile:getLevel())))
  end
  UserProfile.SetStatToStarPower(element, 1)
  playerStatsE:C("Stat1Value")("text"):SetString(friendObject:totalStarpowerEarned())
  UserProfile.SetStatToCreated(element, 2)
  local timeText = UserProfile:formatTime(friendObject:timeSinceCreated() * -1)
  playerStatsE:C("Stat2Value")("text"):SetString(timeText)
  UserProfile.SetStatToTorchesLit(element, 3)
  playerStatsE:C("Stat3Value")("text"):SetString(math.max(friendProfile:getTotalTorchesLit(), friendObject:numTorchesLitByFriend()))
  UserProfile.SetStatToTorchesLit(element, 4)
  playerStatsE:C("Stat4Icon")("spriteName"):SetString("button_friendme")
  playerStatsE:C("Stat4Icon")("sheetName"):SetString("xml_resources/buttons01.xml")
  playerStatsE:C("Stat4Title")("text"):SetString("PROFILE_I_LIT_TORCHES")
  local text = select(1, game.getLocalizedText("PROFILE_TORCH_LIGHT_TIMES"):gsub("${AMOUNT}", friendObject:numTorchesLitByMe()))
  playerStatsE:C("Stat4Value")("text"):SetString(text)
  UserProfile.SetStatToTorchesLit(element, 5)
  playerStatsE:C("Stat5Icon")("spriteName"):SetString("button_friendthem")
  playerStatsE:C("Stat5Icon")("sheetName"):SetString("xml_resources/buttons01.xml")
  playerStatsE:C("Stat5Title")("text"):SetString("PROFILE_THEY_LIT_TORCHES")
  text = select(1, game.getLocalizedText("PROFILE_TORCH_LIGHT_TIMES"):gsub("${AMOUNT}", friendObject:numTorchesLitByFriend()))
  playerStatsE:C("Stat5Value")("text"):SetString(text)
  element:E("DeleteButton"):DoStoredScript("setVisible")
  element:E("FriendCode"):DoStoredScript("setInvisible")
end
function UserProfile.SetPlayerProfile(element, playerProfile)
  local favoritesE = element:E("Favorites")
  local MonsterPortraits = include("MonsterPortraits")
  local favId = playerProfile:getFavMon1Id()
  local image = ""
  if favId <= 0 then
    image = "gfx/breeding/monster_portrait_blank"
  else
    image = MonsterPortraits:getDefaultMonsterPortrait(favId)
  end
  favoritesE:E("Monster1"):C("Sprite")("spriteName"):SetString(image)
  favId = playerProfile:getFavMon2Id()
  if favId <= 0 then
    image = "gfx/breeding/monster_portrait_blank"
  else
    image = MonsterPortraits:getDefaultMonsterPortrait(favId)
  end
  favoritesE:E("Monster2"):C("Sprite")("spriteName"):SetString(image)
  favId = playerProfile:getFavMon3Id()
  if favId <= 0 then
    image = "gfx/breeding/monster_portrait_blank"
  else
    image = MonsterPortraits:getDefaultMonsterPortrait(favId)
  end
  favoritesE:E("Monster3"):C("Sprite")("spriteName"):SetString(image)
  favId = playerProfile:getFavIslandId()
  local sheet = ""
  if favId <= 0 then
    image = "islands_button_isl01"
    sheet = "xml_resources/island_buttons01.xml"
  else
    image = game.islandIconSpriteForId(favId)
    sheet = "xml_resources/" .. game.islandIconSheetForId(favId)
  end
  favoritesE:E("Island"):C("Sprite")("spriteName"):SetString(image)
  favoritesE:E("Island"):C("Sprite")("sheetName"):SetString(sheet)
  local monikerE = element:E("Moniker")
  if playerProfile:getLevel() < 30 then
    monikerE:DoStoredScript("setInvisible")
  else
    monikerE:DoStoredScript("setVisible")
    monikerE:C("Text")("text"):SetString(playerProfile:playerTitle())
  end
  element:E("FriendCode"):C("Text")("text"):SetString(game.getLocalizedText("FRIEND_CODE_INPUT_LABEL") .. " " .. playerProfile:getFriendCode())
end
function UserProfile.SetStatToLevel(element, statNumber, playerProfile)
  local playerStatsE = element:E("PlayerStats")
  playerStatsE:C("Stat" .. statNumber .. "Icon")("spriteName"):SetString("PlayerLevel_Star")
  playerStatsE:C("Stat" .. statNumber .. "Icon")("sheetName"):SetString("xml_resources/hud03.xml")
  local level = playerProfile:getLevel()
  if level >= game.maxPlayerLevel() then
    playerStatsE:C("Stat" .. statNumber .. "Title")("text"):SetString("MAXED")
  else
    local levelText = LOC("LEVEL_UP_TITLE")
    levelText = levelText:gsub("XXX", level)
    playerStatsE:C("Stat" .. statNumber .. "Title")("text"):SetString(levelText)
  end
  local palette = include("ColourPalette")
  playerStatsE:C("Stat" .. statNumber .. "Value"):setColor(palette:getRGBFloats(palette.XP_COLOUR))
end
function UserProfile.SetStatToBattleLevel(element, statNumber, playerProfile)
  local playerStatsE = element:E("PlayerStats")
  playerStatsE:C("Stat" .. statNumber .. "Icon")("spriteName"):SetString("BattleLevel_Star")
  playerStatsE:C("Stat" .. statNumber .. "Icon")("sheetName"):SetString("xml_resources/hud03.xml")
  local level = game.getBattlePlayerData().level
  if level >= game.maxPlayerBattleLevel() then
    playerStatsE:C("Stat" .. statNumber .. "Title")("text"):SetString("BATTLE_MAXED")
  else
    local levelText = LOC("BATTLE_LEVEL")
    playerStatsE:C("Stat" .. statNumber .. "Title")("text"):SetString(levelText .. " " .. level)
  end
  local palette = include("ColourPalette")
  playerStatsE:C("Stat" .. statNumber .. "Value"):setColor(palette:getRGBFloats(palette.BATTLE_XP_COLOUR))
end
function UserProfile.SetStatToStarPower(element, statNumber)
  local playerStatsE = element:E("PlayerStats")
  playerStatsE:C("Stat" .. statNumber .. "Icon")("spriteName"):SetString(game.StoreContext_SPRITE_STARPOWER)
  playerStatsE:C("Stat" .. statNumber .. "Icon")("sheetName"):SetString(game.StoreContext_CURRENCY_SPRITESHEET)
  playerStatsE:C("Stat" .. statNumber .. "Title")("text"):SetString("TRIBAL_STARPOWER")
  local palette = include("ColourPalette")
  playerStatsE:C("Stat" .. statNumber .. "Value"):setColor(palette:getRGBFloats(palette.STARPOWER_COLOUR))
end
function UserProfile.SetStatToCreated(element, statNumber)
  local playerStatsE = element:E("PlayerStats")
  playerStatsE:C("Stat" .. statNumber .. "Icon")("spriteName"):SetString("activefriends_icon")
  playerStatsE:C("Stat" .. statNumber .. "Icon")("sheetName"):SetString("xml_resources/buttons01.xml")
  playerStatsE:C("Stat" .. statNumber .. "Title")("text"):SetString("JOINED_LABEL")
  local palette = include("ColourPalette")
  playerStatsE:C("Stat" .. statNumber .. "Value"):setColor(palette:getRGBFloats(palette.DEFAULT_PROFILE_STAT_COLOUR))
end
function UserProfile.SetStatToTorchesLit(element, statNumber)
  local playerStatsE = element:E("PlayerStats")
  playerStatsE:C("Stat" .. statNumber .. "Icon")("spriteName"):SetString("button_light_torch")
  playerStatsE:C("Stat" .. statNumber .. "Icon")("sheetName"):SetString("xml_resources/context_buttons.xml")
  playerStatsE:C("Stat" .. statNumber .. "Title")("text"):SetString("TORCHES_LIT")
  local palette = include("ColourPalette")
  playerStatsE:C("Stat" .. statNumber .. "Value"):setColor(palette:getRGBFloats(palette.DEFAULT_PROFILE_STAT_COLOUR))
end
function UserProfile.HideStat(element, statNumber)
  local playerStatsE = element:E("PlayerStats")
  playerStatsE:C("Stat" .. statNumber .. "Icon")("visible"):SetInt(0)
  playerStatsE:C("Stat" .. statNumber .. "Icon")("visible"):SetInt(0)
  playerStatsE:C("Stat" .. statNumber .. "Title")("visible"):SetInt(0)
  playerStatsE:C("Stat" .. statNumber .. "Value")("visible"):SetInt(0)
end
function UserProfile.OnDeleteButton(element)
  if UserProfile.friendObject ~= nil then
    game.removeFriend(UserProfile.friendObject:bbbIdStr())
  end
end
return UserProfile
