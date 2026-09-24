local Coroutines = include("Coroutines")
local camStartX, camStartY, camStartZoom
local BORDER_HEIGHT = lua_sys.screenHeight() * 0.25
local CAM_IN_DURATION = 2
local CAM_OUT_DURATION = 1
local ENTITY_ZOOM = 0.7
local function PlaySleepingCutsceneCo(cutsceneData)
  if not coroutine.running() then
    print("need to run as a coroutine!")
    return
  end
  local cm = game.cutsceneManager()
  local iac = game.islandAwakeningController()
  Coroutines.WaitForSeconds(0.1)
  manager:setContextImmediate(manager:getDefaultContext())
  local hud = game.getHUD()
  if hud then
    hud.ViewButton:GetVar("auto"):SetInt(0)
    hud.ViewButton:DoStoredScript("hide")
  end
  print("Playing Sleeping Cutscene!")
  cm:StartCutscene()
  local camera = game.camera()
  camStartX = camera:X()
  camStartY = camera:Y()
  camStartZoom = camera:getZoom()
  iac:SetLocked(true)
  iac:SetIslandEyeState(game.IslandEyeState_OPENED)
  cm:ShowBorders(true, 2, BORDER_HEIGHT)
  game.deselectSelectedObject()
  local targetEntity = game.FindAwakener()
  if targetEntity then
    cm:MoveCameraToEntity(targetEntity, ENTITY_ZOOM, CAM_IN_DURATION)
    Coroutines.WaitForSeconds(4)
  else
    targetEntity = game.FindTitansoul()
  end
  local islandType = game.currentIslandType()
  local island = cm:IslandOverlay()
  local viewHeight = 2400
  local eyeViewWidth = cutsceneData.eyeViewWidth or 2000
  local zoom = lua_sys.screenWidth() / eyeViewWidth
  local xPos = island:X() - lua_sys.screenWidth() * 0.5
  local yPos = island:Y() - lua_sys.screenHeight() * 0.5 + viewHeight * 0.5 - (lua_sys.screenHeight() * 0.5 - BORDER_HEIGHT) * (1 / zoom)
  cm:MoveCameraTo(lua_sys.Vector3(xPos, yPos, 0), zoom, CAM_IN_DURATION)
  Coroutines.WaitForSeconds(CAM_IN_DURATION)
  Coroutines.WaitForSeconds(0.25)
  iac:SetIslandEyeState(game.IslandEyeState_CLOSING)
  local sleepSound = cutsceneData.sleepSound or "world_01_colossal_sleep.wav"
  lua_sys.playSoundFx("audio/sfx/" .. sleepSound)
  if islandType == game.IslandType_PSYCHIC then
    Coroutines.WaitForSeconds(0.85)
    cm:ShakeCamera(8, 0.2, 1)
    Coroutines.WaitForSeconds(2)
  else
    cm:ShakeCamera(4, 0.1, 4)
    Coroutines.WaitForSeconds(4)
    cm:ShakeCamera(8, 0.2, 2)
    Coroutines.WaitForSeconds(2)
  end
  iac:SetIslandEyeState(game.IslandEyeState_CLOSED)
  if targetEntity then
    cm:MoveCameraToEntity(targetEntity, ENTITY_ZOOM, CAM_OUT_DURATION)
  else
    cm:MoveCameraTo(lua_sys.Vector3(camStartX, camStartY, 0), camStartZoom, CAM_OUT_DURATION)
  end
  cm:ShowBorders(false, CAM_OUT_DURATION)
  Coroutines.WaitForSeconds(CAM_OUT_DURATION)
  if hud then
    hud.ViewButton:GetVar("auto"):SetInt(1)
  end
  cm:EndCutscene()
end
local function PlayAwakenCutsceneCo(cutsceneData)
  if not coroutine.running() then
    print("need to run as a coroutine!")
    return
  end
  local cm = game.cutsceneManager()
  local iac = game.islandAwakeningController()
  Coroutines.WaitForSeconds(0.1)
  manager:setContextImmediate(manager:getDefaultContext())
  local hud = game.getHUD()
  if hud then
    hud.ViewButton:GetVar("auto"):SetInt(0)
    hud.ViewButton:DoStoredScript("hide")
  end
  print("Playing Awaken Cutscene!")
  cm:StartCutscene()
  local camera = game.camera()
  camStartX = camera:X()
  camStartY = camera:Y()
  camStartZoom = camera:getZoom()
  iac:SetLocked(true)
  cm:ShowBorders(true, 2, BORDER_HEIGHT)
  game.deselectSelectedObject()
  local targetEntity = game.FindAwakener()
  if targetEntity then
    cm:MoveCameraToEntity(targetEntity, ENTITY_ZOOM, CAM_IN_DURATION)
    Coroutines.WaitForSeconds(4)
  else
    targetEntity = game.FindTitansoul()
  end
  local islandType = game.currentIslandType()
  local island = cm:IslandOverlay()
  local viewHeight = 2400
  local eyeViewWidth = cutsceneData.eyeViewWidth or 2000
  local zoom = lua_sys.screenWidth() / eyeViewWidth
  local xPos = island:X() - lua_sys.screenWidth() * 0.5
  local yPos = island:Y() - lua_sys.screenHeight() * 0.5 + viewHeight * 0.5 - (lua_sys.screenHeight() * 0.5 - BORDER_HEIGHT) * (1 / zoom)
  cm:MoveCameraTo(lua_sys.Vector3(xPos, yPos, 0), zoom, CAM_IN_DURATION)
  Coroutines.WaitForSeconds(CAM_IN_DURATION)
  Coroutines.WaitForSeconds(0.25)
  iac:SetIslandEyeState(game.IslandEyeState_OPENING)
  local awakenSound = cutsceneData.awakenSound or "world_01_colossal_awaken.wav"
  lua_sys.playSoundFx("audio/sfx/" .. awakenSound)
  if islandType == game.IslandType_PSYCHIC then
    Coroutines.WaitForSeconds(1.75)
    cm:ShakeCamera(16, 0.5, 2)
    Coroutines.WaitForSeconds(2)
  else
    cm:ShakeCamera(16, 0.3, 4)
    Coroutines.WaitForSeconds(4.5)
  end
  iac:SetIslandEyeState(game.IslandEyeState_OPENED_BLINKING)
  iac:SetLocked(false)
  if targetEntity then
    cm:MoveCameraToEntity(targetEntity, ENTITY_ZOOM, CAM_OUT_DURATION)
  else
    cm:MoveCameraTo(lua_sys.Vector3(camStartX, camStartY, 0), camStartZoom, CAM_OUT_DURATION)
  end
  cm:ShowBorders(false, CAM_OUT_DURATION)
  Coroutines.WaitForSeconds(CAM_OUT_DURATION)
  if hud then
    hud.ViewButton:GetVar("auto"):SetInt(1)
  end
  cm:EndCutscene()
end
local CutsceneData = include("IslandAwakeningData")
local function getCutsceneData(islandId, activeTheme)
  for k, v in pairs(CutsceneData) do
    if v.islandId == islandId and v.islandTheme == activeTheme then
      return v
    end
  end
  return nil
end
IslandAwakeningCutscenes = {}
function IslandAwakeningCutscenes.HasCutscene(islandId, activeTheme)
  local cutsceneData = getCutsceneData(islandId, activeTheme)
  return cutsceneData ~= nil
end
function IslandAwakeningCutscenes.GetIslandSettings(islandId, activeTheme, settings)
  local cutsceneData = getCutsceneData(islandId, activeTheme)
  if cutsceneData then
    for _, v in ipairs(cutsceneData.Eyes) do
      local eyeSettings = game.IslandAwakeningEyeSettings()
      eyeSettings.targetLayerName = v.targetLayer
      eyeSettings.insertLayerName = v.insertLayer
      eyeSettings.clipLayerName = v.clipLayerName or ""
      eyeSettings.insertLayerOffset = v.insertLayerOffset or 0
      eyeSettings.offset = v.offset or lua_sys.Vector2(0, 0)
      if v.clipping then
        eyeSettings.clipping = v.clipping
      end
      eyeSettings.sheet = v.sheet
      eyeSettings.sprite = v.sprite
      eyeSettings.maxRadius = v.maxRadius
      eyeSettings.speed = v.speed
      eyeSettings.maxScale = v.maxScale or 1
      eyeSettings.scaleAmount = v.scaleAmount or lua_sys.Vector2(0.2, 0.2)
      eyeSettings.alwaysAwake = v.alwaysAwake or false
      settings.eyes:push_back(eyeSettings)
    end
    settings.eyeAnim = cutsceneData.EyeAnim
    settings.eyeAnimAttachLayer = cutsceneData.EyeAnimAttachLayer
    settings.eyeLayerOffset = cutsceneData.EyeLayerOffset or -0.001
    settings.stateAnims:push_back(cutsceneData.EyeStateAnims.CLOSED)
    settings.stateAnims:push_back(cutsceneData.EyeStateAnims.CLOSING)
    settings.stateAnims:push_back(cutsceneData.EyeStateAnims.OPENING)
    settings.stateAnims:push_back(cutsceneData.EyeStateAnims.OPENED)
    settings.stateAnims:push_back(cutsceneData.EyeStateAnims.OPENED_BLINKING)
    settings.version = cutsceneData.version or 0
    return true
  end
  return false
end
function IslandAwakeningCutscenes.PlayShowCutscene(islandId, activeTheme)
  local cutsceneData = getCutsceneData(islandId, activeTheme)
  if cutsceneData then
    RunIndyCoroutine(PlayAwakenCutsceneCo, cutsceneData)
  end
end
function IslandAwakeningCutscenes.PlayHideCutscene(islandId, activeTheme)
  local cutsceneData = getCutsceneData(islandId, activeTheme)
  if cutsceneData then
    RunIndyCoroutine(PlaySleepingCutsceneCo, cutsceneData)
  end
end
return IslandAwakeningCutscenes
