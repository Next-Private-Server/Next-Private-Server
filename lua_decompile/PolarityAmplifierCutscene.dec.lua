local Coroutines = include("Coroutines")
local BORDER_HEIGHT = lua_sys.screenHeight() * 0.15
local CAM_IN_DURATION = 2
local CAM_OUT_DURATION = 1
local function PlayUpgradeCo()
  if not coroutine.running() then
    print("need to run as a coroutine!")
    return
  end
  local cm = game.cutsceneManager()
  Coroutines.WaitForSeconds(0.1)
  manager:setContextImmediate(manager:getDefaultContext())
  local hud = game.getHUD()
  if hud then
    hud.ViewButton:GetVar("auto"):SetInt(0)
    hud.ViewButton:DoStoredScript("hide")
  end
  print("Playing Polarity Amplifier Cutscene!")
  cm:StartCutscene()
  game.deselectSelectedObject()
  local polarityAmplifier = game.getPolarityAmplifier()
  local camera = game.camera()
  local camStartX = camera:X()
  local camStartY = camera:Y()
  local camStartZoom = camera:getZoom()
  local island = cm:IslandOverlay()
  local zoom = lua_sys.screenWidth() / island:width()
  local xPos = island:X() - lua_sys.screenWidth() * 0.5
  local yPos = island:Y() - lua_sys.screenHeight() * 0.5 - island:height() + (lua_sys.screenHeight() * 0.5 - BORDER_HEIGHT) * (1 / zoom)
  cm:MoveCameraTo(lua_sys.Vector3(xPos, yPos, 0), zoom, CAM_IN_DURATION)
  cm:ShowBorders(true, CAM_IN_DURATION, BORDER_HEIGHT)
  Coroutines.WaitForSeconds(CAM_IN_DURATION)
  polarityAmplifier:setUpdatePropCheck()
  Coroutines.WaitForSeconds(3)
  cm:MoveCameraTo(lua_sys.Vector3(camStartX, camStartY, 0), camStartZoom, CAM_OUT_DURATION)
  cm:ShowBorders(false, CAM_OUT_DURATION)
  if hud then
    hud.ViewButton:GetVar("auto"):SetInt(1)
  end
  cm:EndCutscene()
end
PolarityAmplifierCutscene = {}
function PolarityAmplifierCutscene.PlayUpgrade()
  RunIndyCoroutine(PlayUpgradeCo)
end
return PolarityAmplifierCutscene
