local Coroutines = include("Coroutines")
local OffsetTransition = include("OffsetTransition")
local FadeTransition = include("FadeTransition")
local Tweener = include("Tweener")
local ShaderShinyWorld = include("ShaderShinyWorld")
local IslandData = include("IslandData")
local IslandPurchaseFanfare = {
  TouchBlocker = {
    Touch = {}
  },
  Hole = {},
  Title = {
    Sprite = {}
  },
  WelcomeSign = {
    Text = {}
  },
  Subtitle = {
    Text = {}
  },
  ContinueLabel = {
    Text = {}
  },
  Animation = {
    Sprite = {}
  },
  Motes = {
    Particles = {}
  }
}
local CAM_TARGET_ZOOM = 0.4
local BORDER_HEIGHT = lua_sys.screenHeight() * 0.17
local root, coroutineId
local islandId = 0
local currentThemeId = 0
local tickables = {}
local allowExit, camStartX, camStartY, camStartZoom
local fadedGameObjects = false
local motes
local showHole = function(popup)
  popup.Hole:Setup({
    holeStartSize = 0.01,
    holeEndSize = 2,
    transitionEasing = lua_sys.Quadratic_EaseOut,
    transitionDuration = 3
  })
  popup.Hole:Show(true)
end
local hasSubtitle = function()
  return game.currentLanguage() ~= "en"
end
local function fadeComponent(fadeableComponents, duration, show)
  local fadeTween = FadeTransition:new({
    startAlpha = 0,
    targetAlpha = 1,
    duration = duration or 1,
    onUpdate = function(alpha)
      for _, component in ipairs(fadeableComponents) do
        component:GetVar("alpha"):SetFloat(alpha)
      end
    end,
    onDoneHide = function()
      for _, component in ipairs(fadeableComponents) do
        component:GetVar("visible"):SetInt(0)
      end
    end
  })
  for _, component in ipairs(fadeableComponents) do
    component:GetVar("visible"):SetInt(1)
  end
  if show then
    fadeTween:Show()
  else
    fadeTween.alpha = 1
    fadeTween:Hide()
  end
  fadeTween:Tick(0)
  RunIndyCoroutine(Coroutines.RunTransition, fadeTween)
end
local function scaleComponent(scalableComponents, startScale, endScale, duration)
  local scaleTweener = Tweener:new({
    initialValue = startScale,
    targetValue = endScale,
    duration = duration or 1,
    onUpdate = function(scale)
      for _, component in ipairs(scalableComponents) do
        component:setScale(lua_sys.Vector2(scale, scale))
      end
    end
  })
  scaleTweener:activate()
  scaleTweener:Tick(0)
  RunIndyCoroutine(Coroutines.RunTweener, scaleTweener)
end
local function playCutsceneCo(popup, islandData)
  print("start cutscene intro")
  local cutsceneData = islandData.intro
  allowExit = false
  Coroutines.WaitForSeconds(0.1)
  local cm = game.cutsceneManager()
  manager:setContextImmediate(manager:getDefaultContext())
  local hud = game.getHUD()
  if hud then
    hud.ViewButton:GetVar("auto"):SetInt(0)
    hud.ViewButton:DoStoredScript("hide")
  end
  cm:StartCutscene()
  cm:FadeGameObjects(0)
  fadedGameObjects = true
  local cx = game.getGridViewX() + game.getGridViewWidth() * 0.5 - lua_sys.screenWidth() * 0.5
  local cy = game.getGridViewY()
  cm:MoveCameraTo(lua_sys.Vector3(cx, cy - 2800, 0), CAM_TARGET_ZOOM, 0.01)
  Coroutines.WaitForSeconds(0.1)
  popup.Animation.Sprite:GetVar("visible"):SetInt(1)
  popup.Animation.Sprite:GetVar("animation"):SetString("island_intro")
  popup.Animation.Sprite:Play()
  Coroutines.WaitForSeconds(1.1)
  lua_sys.playSoundFx("audio/sfx/island_intro_seq_01.wav")
  Coroutines.WaitForAnimation(popup.Animation.Sprite:GetReceiver())
  popup.Animation.Sprite:GetVar("visible"):SetInt(0)
  lua_sys.playSoundFx("audio/sfx/island_intro_seq_02.wav")
  motes = game.playEffect("particles/FX_IslandIntroSequence.efkefc", lua_sys.screenWidth() / 2, lua_sys.screenHeight() / 2, "FrontPopUps", 1, 20)
  cm:ShowBorders(true, 2, BORDER_HEIGHT)
  Coroutines.WaitForSeconds(1)
  fadeComponent({
    popup.WelcomeSign.Text
  }, 2, true)
  Coroutines.WaitForSeconds(2.5)
  fadeComponent({
    popup.Title.Sprite
  }, 2, true)
  if hasSubtitle() then
    local islandName = "(" .. game.localizedUpper(game.islandName(islandData.islandId)) .. ")"
    popup.Subtitle.Text:GetVar("text"):SetString(islandName)
    fadeComponent({
      popup.Subtitle.Text
    }, 2, true)
  end
  scaleComponent({
    popup.Title.Sprite
  }, 0.5 * game.menuScaleY(), 0.65 * game.menuScaleY(), 3)
  Coroutines.WaitForSeconds(2)
  lua_sys.playSoundFx("audio/sfx/island_intro_seq_03.wav")
  Coroutines.WaitForSeconds(3)
  allowExit = true
  popup.ContinueLabel.Text:GetVar("text"):SetString("TAP_TO_CONTINUE")
  fadeComponent({
    popup.ContinueLabel.Text
  }, 2, true)
  print("done cutscene intro")
  game.setMidiFade(1, 1)
  game.setMp3Fade(1, 1)
end
local function playAlternateCutsceneCo(popup, islandData)
  print("start alternate cutscene intro")
  local cutsceneData = islandData.intro
  allowExit = false
  Coroutines.WaitForSeconds(0.1)
  local cm = game.cutsceneManager()
  manager:setContextImmediate(manager:getDefaultContext())
  local hud = game.getHUD()
  if hud then
    hud.ViewButton:GetVar("auto"):SetInt(0)
    hud.ViewButton:DoStoredScript("hide")
  end
  cm:StartCutscene()
  cm:FadeGameObjects(0)
  fadedGameObjects = true
  local cx = game.getGridViewX() + game.getGridViewWidth() * 0.5 - lua_sys.screenWidth() * 0.5
  local cy = game.getGridViewY()
  cm:MoveCameraTo(lua_sys.Vector3(cx, cy, 0), 2, 0.01)
  Coroutines.WaitForSeconds(0.1)
  popup.Animation.Sprite:GetVar("visible"):SetInt(1)
  popup.Animation.Sprite:GetVar("animation"):SetString("island_intro")
  popup.Animation.Sprite:Play()
  Coroutines.WaitForSeconds(1.1)
  lua_sys.playSoundFx("audio/sfx/island_intro_seq_01.wav")
  Coroutines.WaitForAnimation(popup.Animation.Sprite:GetReceiver())
  popup.Animation.Sprite:GetVar("visible"):SetInt(0)
  lua_sys.playSoundFx("audio/sfx/island_intro_seq_02.wav")
  motes = game.playEffect("particles/FX_IslandIntroSequence.efkefc", lua_sys.screenWidth() / 2, lua_sys.screenHeight() / 2, "FrontPopUps", 1, 20)
  cm:ShowBorders(true, 2, BORDER_HEIGHT)
  Coroutines.WaitForSeconds(1)
  fadeComponent({
    popup.WelcomeSign.Text
  }, 2, true)
  Coroutines.WaitForSeconds(2.5)
  fadeComponent({
    popup.Title.Sprite
  }, 2, true)
  if hasSubtitle() then
    local islandName = "(" .. game.localizedUpper(game.islandName(islandData.islandId)) .. ")"
    popup.Subtitle.Text:GetVar("text"):SetString(islandName)
    fadeComponent({
      popup.Subtitle.Text
    }, 2, true)
  end
  scaleComponent({
    popup.Title.Sprite
  }, 0.5 * game.menuScaleY(), 0.65 * game.menuScaleY(), 3)
  Coroutines.WaitForSeconds(2)
  lua_sys.playSoundFx("audio/sfx/island_intro_seq_03.wav")
  Coroutines.WaitForSeconds(3)
  allowExit = true
  popup.ContinueLabel.Text:GetVar("text"):SetString("TAP_TO_CONTINUE")
  fadeComponent({
    popup.ContinueLabel.Text
  }, 2, true)
  print("done cutscene intro")
  game.setMidiFade(1, 1)
  game.setMp3Fade(1, 1)
end
local function endCutsceneCo(popup)
  print("end cutscene intro")
  popup.ContinueLabel.Text:GetVar("visible"):SetInt(0)
  local cm = game.cutsceneManager()
  if motes then
    motes:sendTrigger(1)
  end
  cm:ShowBorders(false, 0.33)
  local hud = game.getHUD()
  if hud then
    hud.ViewButton:GetVar("auto"):SetInt(1)
  end
  fadeComponent({
    popup.Title.Sprite,
    popup.WelcomeSign.Text
  }, 1, false)
  if hasSubtitle() then
    fadeComponent({
      popup.Subtitle.Text
    }, 1, false)
  end
  cm:MoveCameraTo(lua_sys.Vector3(camStartX, camStartY, 0), camStartZoom, 2)
  if fadedGameObjects then
    local fadeGameObjectsTween = FadeTransition:new({
      startAlpha = 0,
      targetAlpha = 1,
      duration = 1,
      onUpdate = function(alpha)
        cm:FadeGameObjects(alpha)
      end
    })
    fadeGameObjectsTween:Show()
    Coroutines.RunTransition(fadeGameObjectsTween)
  end
  Coroutines.WaitForSeconds(2)
  cm:EndCutscene()
  popup:queuePop()
end
function IslandPurchaseFanfare:onPostInit()
  game.setMidiFade(0, 0)
  game.setMp3Fade(0, 0)
  root = self
  self.Title.Sprite:GetVar("visible"):SetInt(0)
  self.Title.Sprite:setShader(ShaderShinyWorld)
  self.WelcomeSign.Text:GetVar("visible"):SetInt(0)
  self.ContinueLabel.Text:GetVar("visible"):SetInt(0)
  self.Subtitle.Text:GetVar("visible"):SetInt(0)
  table.insert(tickables, self.Hole)
  islandId = game.currentIsland()
  currentThemeId = game.getActiveIslandTheme(islandId)
  local islandData = IslandData.Get(islandId)
  local cutsceneData
  if islandData then
    cutsceneData = islandData.intro
  end
  if not cutsceneData then
    self:queuePop()
    return
  end
  local titleSpriteName = cutsceneData.titleSprite
  if islandId == game.IslandType_PAIRONORMAL and game.player():getActiveIsland():islandMode() == 1 then
    titleSpriteName = titleSpriteName .. "_minor"
  end
  self.Title.Sprite:GetVar("spriteName"):SetString(titleSpriteName)
  self.Motes.Particles:GetVar("visible"):SetInt(0)
  local anim = self.Animation.Sprite
  local animUtil = game.AnimUtil(anim)
  if islandId == game.IslandType_CELESTIAL then
    local debris = {}
    for i = 1, 14 do
      table.insert(debris, "spore_T" .. string.format("%02d", i))
    end
    for i = 1, 15 do
      animUtil:addRemap("egg_" .. string.format("%02d", i), "gfx/menu/map/celestial_intro/" .. debris[math.random(#debris)], "")
      animUtil:addRemap("white glow " .. string.format("%02d", i), "", "")
    end
  elseif islandId == game.IslandType_UNDERLING then
    local debris = {}
    for i = 1, 20 do
      table.insert(debris, "spore_U" .. string.format("%02d", i))
    end
    local animUtil = game.AnimUtil(anim)
    for i = 1, 15 do
      animUtil:addRemap("egg_" .. string.format("%02d", i), "gfx/menu/map/wublin_intro/" .. debris[math.random(#debris)], "")
      animUtil:addRemap("white glow " .. string.format("%02d", i), "", "")
    end
  else
    local sporeList = cutsceneData.eggs or IslandData.GetIntroCutsceneEggs(islandId)
    for i = 1, #sporeList do
      animUtil:addRemap("egg_" .. string.format("%02d", i), sporeList[i], "")
    end
  end
  animUtil:resetAnim()
  game.setDefaultCameraSettings()
  local camera = game.camera()
  camStartX = camera:X()
  camStartY = camera:Y()
  camStartZoom = camera:getZoom()
  local cutsceneFunc = playCutsceneCo
  local isProblemIsland = function(islandId, islandTheme)
    local problemIslands = {
      game.IslandType_ETHEREAL,
      game.IslandType_SHUGGA,
      game.IslandType_BATTLE,
      game.IslandType_SEASONAL,
      game.IslandType_ETHEREAL_WORKSHOP,
      game.IslandType_UNDERLING,
      game.IslandType_SHADOW_ETHEREAL_ISLET
    }
    for i = 1, #problemIslands do
      if islandId == problemIslands[i] then
        return true
      end
    end
    local problemThemes = {5, 16}
    for i = 1, #problemThemes do
      if islandTheme == problemThemes[i] then
        return true
      end
    end
    return false
  end
  if isProblemIsland(islandId, currentThemeId) then
    cutsceneFunc = playAlternateCutsceneCo
  end
  coroutineId = RunIndyCoroutine(cutsceneFunc, self, islandData)
end
function IslandPurchaseFanfare:onDestroy()
  if motes then
    motes:stop()
    motes = nil
  end
end
function IslandPurchaseFanfare:onTick(dt)
  for _, v in ipairs(tickables) do
    v:Tick(dt)
  end
end
function IslandPurchaseFanfare:queuePop()
  root:root():popPopUp()
  local island = game.player():getIslandWithId(islandId)
  if island:firstVisit() then
    game.worldContext():showFirstTimePopup()
  end
  self:root():GetReceiver():Send(game.MsgNextTutorialStep())
  island:setFirstVisit(false)
end
function IslandPurchaseFanfare.TouchBlocker.Touch:onTouchDown(element, x, y)
  if allowExit then
    RunIndyCoroutine(endCutsceneCo, root)
    allowExit = false
  end
end
function IslandPurchaseFanfare.HasCutscene(islandId)
  local islandData = IslandData.Get(islandId)
  return islandData and islandData.intro ~= nil and islandData.intro.noStart ~= true
end
function IslandPurchaseFanfare.HasReplayCutscene(islandId)
  local islandData = IslandData.Get(islandId)
  return islandData and islandData.intro ~= nil
end
function IslandPurchaseFanfare:Skip()
  if game.isDebugBuild() or game.isQABuild() then
    KillCoroutine(coroutineId)
    local cm = game.cutsceneManager()
    cm:FadeGameObjects(1)
    cm:ShowBorders(false, 0)
    cm:EndCutscene()
    game.setDefaultCameraSettings()
    root:root():popPopUp()
    self:root():GetReceiver():Send(game.MsgNextTutorialStep())
    game.player():getIslandWithId(islandId):setFirstVisit(false)
    game.setMidiFade(1, 1)
    game.setMp3Fade(1, 1)
  end
end
return IslandPurchaseFanfare
