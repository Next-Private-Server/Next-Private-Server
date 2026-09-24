local OffsetTransition = include("MenuElementPositionOffsetTransition")
local BattleLoading = {}
function BattleLoading.OnInit(element)
  element("IsWaiting"):SetInt(1)
  local left = element:GetElement("LeftBG")
  OffsetTransition.OnInit(left, {
    startX = lua_sys.screenWidth() * 0.5,
    endX = 0,
    duration = 0.66
  })
  local right = element:GetElement("RightBG")
  OffsetTransition.OnInit(right, {
    startX = lua_sys.screenWidth() * 0.5,
    endX = 0,
    duration = 0.66
  })
  local topper = element:GetElement("Topper")
  OffsetTransition.OnInit(topper, {
    startY = lua_sys.screenHeight() * 0.75,
    endY = lua_sys.screenHeight() * 0.25,
    duration = 0.33,
    delay = 0.17
  })
  local infoStartX = lua_sys.screenWidth() * 0.5
  local infoEndX = 16 * game.menuScaleX()
  local infoStartY = -8 * game.menuScaleY()
  local infoOptions = {
    startX = infoStartX,
    endX = infoEndX,
    startY = infoStartY,
    endY = infoStartY,
    duration = 0.33,
    delay = 0.66
  }
  local slotStartX = lua_sys.screenWidth() * 0.5
  local slotEndX = 0
  local slotStartY = 80 * game.menuScaleY()
  local slotOptions = {
    startX = slotStartX,
    endX = slotEndX,
    startY = slotStartY,
    endY = slotStartY,
    duration = 0.33
  }
  local playerInfo = element:GetElement("PlayerInfo")
  playerInfo("xOffset"):SetFloat(infoStartX)
  playerInfo("yOffset"):SetFloat(infoStartY)
  OffsetTransition.OnInit(playerInfo, infoOptions)
  local playerSlots = element:GetElement("PlayerSlots")
  OffsetTransition.OnInit(playerSlots, slotOptions)
  local opponentInfo = element:GetElement("OpponentInfo")
  opponentInfo("xOffset"):SetFloat(infoStartX)
  opponentInfo("yOffset"):SetFloat(infoStartY)
  OffsetTransition.OnInit(opponentInfo, infoOptions)
  local opponentSlots = element:GetElement("OpponentSlots")
  OffsetTransition.OnInit(opponentSlots, slotOptions)
  local ScheduledEvent = include("ScheduledEvent")
  ScheduledEvent.OnInit(element, {duration = 4})
end
function BattleLoading.OnTick(element, dt)
  local options = {
    ease = lua_sys.Quadratic_EaseIn
  }
  OffsetTransition.OnTick(element:GetElement("LeftBG"), dt, options)
  OffsetTransition.OnTick(element:GetElement("RightBG"), dt, options)
  OffsetTransition.OnTick(element:GetElement("PlayerInfo"), dt, options)
  OffsetTransition.OnTick(element:GetElement("PlayerSlots"), dt, options)
  OffsetTransition.OnTick(element:GetElement("OpponentInfo"), dt, options)
  OffsetTransition.OnTick(element:GetElement("OpponentSlots"), dt, options)
  function options.onDoneHide(e)
    element:root():popPopUp()
  end
  function options.onDoneShow(e)
    game.loadBattleContext()
  end
  OffsetTransition.OnTick(element:GetElement("Topper"), dt, options)
  local ScheduledEvent = include("ScheduledEvent")
  ScheduledEvent.OnTick(element, dt, {
    onComplete = function(e)
      element:DoStoredScript("hide")
    end
  })
  local waiting = element("IsWaiting"):GetInt() == 1
  if waiting and game.getBattleClientData():getBattleStartStatus() == game.BattleClientData_BattleStart_OK then
    local battleCreateSettings = game.getBattleClientData():getBattleCreateSettings()
    element.PlayerInfo.Text("size"):SetFloat(0.24 * game.menuScaleY())
    element.PlayerInfo.Text("text"):SetString(game.playerDisplayName())
    element.PlayerInfo.Text("autoScale"):SetInt(1)
    element.PlayerInfo.TierText("visible"):SetInt(0)
    local profile = game.playerProfile()
    element.PlayerProfileImg:DoStoredScript("show")
    element.PlayerProfileImg:E("Level"):DoStoredScript("hide")
    element.PlayerProfileImg:SetAvatarData(profile:getPlayerAvatar())
    if battleCreateSettings.isPVP then
      element.OpponentInfo.Text("size"):SetFloat(0.24 * game.menuScaleY())
      element.OpponentInfo.Text("text"):SetString(battleCreateSettings.opponentName)
      element.OpponentInfo.Text("autoScale"):SetInt(1)
      element.OpponentInfo.TierText("visible"):SetInt(0)
      local opponentAvatar = battleCreateSettings.opponentAvatar
      element.OpponentProfileImg:DoStoredScript("show")
      element.OpponentProfileImg:E("Level"):DoStoredScript("hide")
      element.OpponentProfileImg:SetAvatarData(opponentAvatar)
    else
      element.OpponentInfo.Text("visible"):SetInt(0)
      element.OpponentInfo.TierText("visible"):SetInt(0)
      element.OpponentProfileImg:DoStoredScript("hide")
    end
    for i = 0, 2 do
      local slotElement = element.PlayerSlots["Slot" .. i]
      if i < battleCreateSettings.playerTeam:size() then
        local playerData = battleCreateSettings.playerTeam[i]
        if playerData.monsterId == 0 then
          slotElement.Text("visible"):SetInt(0)
          slotElement:DoStoredScript("hide")
        else
          local MonsterPortraits = include("MonsterPortraits")
          local img = MonsterPortraits:getDefaultMonsterPortrait(playerData.monsterId)
          slotElement.CharacterImage.Sprite("spriteName"):SetString(img)
          slotElement.CharacterLevel("level"):SetInt(playerData.level)
          slotElement.CharacterLevel:DoStoredScript("refresh")
          slotElement.Text("text"):SetString(playerData:name())
        end
      else
        slotElement.Text("visible"):SetInt(0)
        slotElement:DoStoredScript("hide")
      end
    end
    for i = 0, 2 do
      local slotElement = element.OpponentSlots["Slot" .. i]
      if i < battleCreateSettings.opponentTeam:size() then
        local opponentData = battleCreateSettings.opponentTeam[i]
        if opponentData.monsterId == 0 then
          slotElement.Text("visible"):SetInt(0)
          slotElement:DoStoredScript("hide")
        else
          local MonsterPortraits = include("MonsterPortraits")
          local img = MonsterPortraits:getDefaultMonsterPortrait(opponentData.monsterId)
          slotElement.CharacterImage.Sprite("spriteName"):SetString(img)
          slotElement.CharacterImage.Sprite("hFlip"):SetInt(1)
          slotElement.CharacterLevel("level"):SetInt(opponentData.level)
          slotElement.CharacterLevel:DoStoredScript("refresh")
          slotElement.Text("text"):SetString(opponentData:name())
        end
      else
        slotElement.Text("visible"):SetInt(0)
        slotElement:DoStoredScript("hide")
      end
    end
    OffsetTransition.Show(element:GetElement("PlayerInfo"))
    element:GetElement("PlayerSlots"):DoStoredScript("show")
    OffsetTransition.Show(element:GetElement("OpponentInfo"))
    element:GetElement("OpponentSlots"):DoStoredScript("show")
    ScheduledEvent.Start(element)
    element("IsWaiting"):SetInt(0)
  end
end
function BattleLoading.Show(element)
  OffsetTransition.Show(element:GetElement("LeftBG"))
  OffsetTransition.Show(element:GetElement("RightBG"))
  OffsetTransition.Show(element:GetElement("Topper"))
end
function BattleLoading.Hide(element)
  OffsetTransition.Hide(element:GetElement("LeftBG"))
  OffsetTransition.Hide(element:GetElement("RightBG"))
  OffsetTransition.Hide(element:GetElement("Topper"))
  local infoStartX = lua_sys.screenWidth() * 0.5
  local infoEndX = 16 * game.menuScaleX()
  local infoStartY = -8 * game.menuScaleY()
  local infoOptions = {
    startX = infoStartX,
    endX = infoEndX,
    startY = infoStartY,
    endY = infoStartY,
    duration = 0.33
  }
  local playerInfo = element:GetElement("PlayerInfo")
  OffsetTransition.OnInit(playerInfo, infoOptions)
  OffsetTransition.Hide(playerInfo)
  local opponentInfo = element:GetElement("OpponentInfo")
  OffsetTransition.OnInit(opponentInfo, infoOptions)
  OffsetTransition.Hide(opponentInfo)
  OffsetTransition.Hide(element:GetElement("PlayerSlots"))
  OffsetTransition.Hide(element:GetElement("OpponentSlots"))
end
function BattleLoading.SlotsOnInit(element)
  local transitionDuration = 0.33
  local initialDelay = 1
  local slotOptions = {
    startX = -lua_sys.screenWidth() * 0.5,
    endX = 0,
    duration = transitionDuration
  }
  for i = 0, 2 do
    local slot = element:GetElement("Slot" .. i)
    slotOptions.startY = i * 40 * game.menuScaleY()
    slotOptions.endY = slotOptions.startY
    slotOptions.delay = initialDelay + i * 0.17
    slot("xOffset"):SetFloat(slotOptions.startX)
    slot("yOffset"):SetFloat(slotOptions.startY)
    OffsetTransition.OnInit(slot, slotOptions)
  end
end
function BattleLoading.SlotsOnTick(element, dt)
  local options = {
    ease = lua_sys.Quadratic_EaseIn
  }
  for i = 0, 2 do
    local slot = element:GetElement("Slot" .. i)
    OffsetTransition.OnTick(slot, dt, options)
  end
end
function BattleLoading.SlotsShow(element)
  for i = 0, 2 do
    local slot = element:GetElement("Slot" .. i)
    OffsetTransition.Show(slot)
  end
end
function BattleLoading.SlotsHide(element)
  for i = 0, 2 do
    local slot = element:GetElement("Slot" .. i)
    OffsetTransition.Hide(slot)
  end
end
return BattleLoading
