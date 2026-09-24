local FadeTransition = include("FadeTransition")
local OffsetTransition = include("MenuElementPositionOffsetTransition")
local MenuHelpers = include("MenuHelpers")
local ViewGroup = include("ViewGroup")
local Pulser = include("Pulser")
local Tweener = include("Tweener")
local MonsterEvolveFanfare = {}
local mainElement, colorizeShader, colorizeShaderFactor
local monsterId = 0
local monsterData
local costumeId = 0
local userStructureId = 0
local structure, newFlag, flashSprite, monsterElement, monsterAnim, flagAe
local viewGroupA = ViewGroup.new()
local mainPanel, amberElement, amberSprite, amberTouch, amberGlow, amberGlowTween, tapParticles
local viewGroupB = ViewGroup.new()
local postNotificationTop, postNotificationMonsterName, postNotificationClass, postNotificationElements
local viewGroupC = ViewGroup.new()
local labelPulser
local viewGroupD = ViewGroup.new()
local gradientBG, scrollingBG, barTop, barBottom, continueLabel
local soundTimer = 0
local tapCounter = 0
local isPostReveal = false
local amberAnimationTimer = 0
local function onAmberRefresh(component, element)
  if monsterData == nil or not structure or not monsterData:isEpicMonster() or structure:isAttuner() then
  elseif structure:isCrucible() then
    component:AddRemap("amber_rare.png", "gfx/amber_epic")
  end
end
local amberCrackFrames = {}
amberCrackFrames[1] = "amber_crack_02.png"
amberCrackFrames[2] = "amber_crack_03.png"
amberCrackFrames[3] = "amber_crack_04.png"
amberCrackFrames[4] = "amber_crack_05.png"
amberCrackFrames[5] = "amber_crack_06.png"
amberCrackFrames[6] = "amber_crack_07.png"
local tuneupCrackFrames = {}
tuneupCrackFrames[1] = "tuneup_crack_02"
tuneupCrackFrames[2] = "tuneup_crack_03"
tuneupCrackFrames[3] = "tuneup_crack_04"
tuneupCrackFrames[4] = "tuneup_crack_05"
tuneupCrackFrames[5] = "tuneup_crack_06"
tuneupCrackFrames[6] = "tuneup_crack_07"
local NUM_TAPS = 7
local function onAmberTap(component, element)
  if tapCounter > 0 and tapCounter < NUM_TAPS and structure then
    if structure:isAttuner() then
      game.remapMenuAnim(component, "crack", "tuneup_crack_sheet.xml", tuneupCrackFrames[tapCounter])
    elseif structure:isCrucible() then
      game.remapMenuAnim(component, "crack", "amber_crack_sheet.xml", amberCrackFrames[tapCounter])
    end
  end
  amberSprite("animation"):SetString("tap")
  amberAnimationTimer = 0.5
  lua_sys.playSoundFx("audio/sfx/menu_click_small.wav")
  tapParticles:DoStoredScript("play")
end
local function onTouchedAmber(component, element, x, y)
  tapCounter = tapCounter + 1
  amberSprite:DoStoredScript("Tap")
  if tapCounter == NUM_TAPS then
    component("enabled"):SetInt(0)
    amberElement.FadeTransition:Show()
    amberGlowTween:activate()
  end
end
local function loadNextMenu()
  if monsterData ~= nil then
    local activeIslandType = game.currentIslandType()
    game.setBookOfMonstersIslandId(game.currentIsland())
    game.logEvent("book_o_monsters", "island", tostring(activeIslandType), "source", "evolve_fanfare")
    manager:setContext("BLANK")
    game.setSpotlightMonsterId(monsterId)
    monsterId = game.getSpotlightMonsterId()
    game.pushPopUp("book_o_monsters")
    local top = game.topPopUp()
    top("FromWorld"):SetInt(1)
    top("SpotlightMonster"):SetInt(monsterId)
    top("SpotlightCostume"):SetInt(costumeId)
    top("SpotlightStartX"):SetFloat(monsterElement:absX() + monsterElement:absW() * 0.5)
    top("SpotlightStartY"):SetFloat(monsterElement:absY() + monsterElement:absH() * 0.5)
    top("isCrucibleEvolve"):SetInt(1)
    top.MonsterList.Touch("enabled"):SetInt(0)
    top.MonsterList.Camera("enabled"):SetInt(0)
    top("WasFugued"):SetInt(0)
  else
    game.finishFlagFanfare()
  end
end
local function doMonsterReveal()
  viewGroupA:hide()
  viewGroupD:show()
  OffsetTransition.Show(barTop)
  OffsetTransition.Show(barBottom)
  monsterAnim("visible"):SetInt(1)
  monsterAnim("alpha"):SetInt(1)
  MenuHelpers.DoCelebrateEffect(mainElement, {playSound = false})
end
local initScrollingBG = function(component, element)
  component:setScale(lua_sys.Vector2(lua_sys.screenWidth() / 128, lua_sys.screenHeight() / 128))
  component("layer"):SetString("FrontPopUps")
  component("alpha"):SetFloat(1)
  component("repeating"):SetInt(1)
  component:setShader(include("ShaderScrollingPattern"))
end
local function finishSequence()
  if isPostReveal and flashSprite("visible"):GetInt() == 0 then
    flashSprite.FadeTransition:Show()
    flashSprite("visible"):SetInt(1)
    lua_sys.playSoundFx("audio/sfx/menu_click.wav")
  end
end
local function centerElements()
  local textComponent = postNotificationElements:GetComponent("Text")
  local genesElement = postNotificationElements:GetElement("Genes")
  local size = postNotificationElements:size()
  postNotificationElements:setSize(lua_sys.Vector2(textComponent:absW() + genesElement:absW(), size.y))
  MenuHelpers.CenterHorizontally({
    textComponent,
    MenuHelpers.CreateSpacer(8 * game.menuScaleX(), size.y),
    genesElement
  })
end
local function playMonsterSound()
  if monsterData ~= nil and soundTimer <= 0 then
    game.playMonsterSelectSound(monsterId, 0)
    soundTimer = 1
  end
end
local function setupStructureSpecific(element)
  if structure and structure:isAttuner() then
    element:E("PreNotification"):C("Text"):V("text"):SetString("EVOLVE_FANFARE_TAP_REATTUNED")
    element:E("AmberImage"):C("Sprite"):V("animationName"):SetString("xml_bin/tuneup_crack.bin")
    element:E("AmberImage"):C("Sprite"):setScale(Vector2(game.hudScale() / 2, game.hudScale() / 2))
    element:E("AmberImage"):C("TapParticles"):V("animationName"):SetString("xml_bin/tuneup_crack.bin")
    element:E("AmberImage"):C("TapParticles"):V("animation"):SetString("tap")
    element:E("AmberImage"):C("TapParticles"):setScale(Vector2(game.hudScale() / 2, game.hudScale() / 2))
    element:E("AmberImage"):C("Sprite"):GetVar("offsetCenter"):SetInt(0)
    element:E("AmberImage"):C("TapParticles"):GetVar("offsetCenter"):SetInt(0)
  end
end
local function setupMonster(element)
  monsterData = game.getMonsterData(monsterId)
  if monsterData ~= nil then
    costumeId = element("CostumeID"):GetInt()
    amberSprite:DoStoredScript("Refresh")
    monsterAnim("animationName"):SetString("xml_bin/" .. monsterData:animationFile())
    if monsterData:isBoxMonster() then
      monsterAnim("animation"):SetString("Idle")
      local scale = math.min(game.hudScale(), 150 * game.menuScaleX() / monsterData:height())
      monsterAnim:setScale(lua_sys.Vector2(scale, scale))
      monsterAnim("yOffset"):SetFloat(monsterData:height() * 0.75)
    else
      monsterAnim("animation"):SetString("Store")
    end
    if costumeId > 0 then
      game.applyCostumeToAnimComponent(monsterAnim, costumeId)
    end
    monsterAnim("visible"):SetInt(0)
    local monsterNameText = LOC("HATCH_FANFARE_MONSTER_NAME")
    monsterNameText = monsterNameText:gsub("%${MONSTER}", LOC(monsterData:name()))
    local palette = include("ColourPalette")
    if monsterData:isSeasonal() then
      monsterNameText = monsterNameText:gsub("%${COLOR}", palette.MONSTER_SEASONAL)
    elseif monsterData:isEpicMonster() then
      monsterNameText = monsterNameText:gsub("%${COLOR}", palette.MONSTER_EPIC)
    elseif monsterData:isRareMonster() then
      monsterNameText = monsterNameText:gsub("%${COLOR}", palette.MONSTER_RARE)
    else
      monsterNameText = monsterNameText:gsub("%${COLOR}", palette.MONSTER_COMMON)
    end
    postNotificationMonsterName("visible"):SetInt(1)
    postNotificationMonsterName("size"):SetFloat(0.6 * game.hudScale())
    postNotificationMonsterName("autoScale"):SetInt(1)
    postNotificationMonsterName("text"):SetString(monsterNameText)
    postNotificationMonsterName("visible"):SetInt(0)
    local classText = LOC("HATCH_FANFARE_CLASS")
    classText = classText:gsub("%${CLASS}", LOC(monsterData:monsterClassStr()))
    postNotificationClass("text"):SetString(classText)
    local genes = postNotificationElements:GetElement("Genes")
    genes("GeneString"):SetString(element("GeneString"):GetString())
    genes("monsterId"):SetInt(monsterId)
    genes("useFlags"):SetInt(0)
    genes:DoStoredScript("populate")
    if monsterData:isCelestial() and not monsterData:isYouth() then
      postNotificationTop("text"):SetString(LOC("NOTIFICATION_ASCENDED_MONSTER"))
    end
    local gradient, pattern
    if monsterData:isSeasonal() then
      gradient = "gfx/menu/gradient_bg_seasonal"
      pattern = "gfx/menu/" .. game.monsterFanfareBg(monsterId)
    elseif monsterData:isCelestial() then
      gradient = "gfx/menu/gradient_bg_breeding"
      pattern = "gfx/menu/bg_symbols_celestial"
    elseif monsterData:isEpicMonster() then
      gradient = "gfx/menu/gradient_bg_epic"
      pattern = "gfx/menu/bg_symbols_epic"
    elseif monsterData:isRareMonster() then
      gradient = "gfx/menu/gradient_bg_rare"
      pattern = "gfx/menu/bg_symbols_rare"
    else
      gradient = "gfx/menu/gradient_bg_common"
      pattern = "gfx/menu/bg_symbols_common"
    end
    gradientBG("spriteName"):SetString(gradient)
    scrollingBG("spriteName"):SetString(pattern)
  end
end
local function setupFlags(element)
  amberSprite:DoStoredScript("Refresh")
  monsterElement("offsetTransitionEndX"):SetFloat(110 * game.hudScale())
  monsterAnim("animationName"):SetString("xml_bin/" .. game.getCrucibleAnimFile())
  monsterAnim("animation"):SetString(game.getCrucibleUnlockedAnim())
  local height = game.crucibleHeight()
  local scale = math.min(game.hudScale(), 100 * game.menuScaleX() / height)
  monsterAnim:setScale(lua_sys.Vector2(scale, scale))
  monsterAnim("yOffset"):SetFloat(height * 0.75)
  flagAe = game.attachCurFlagsToCrucible(monsterAnim, element("FlagInd"):GetInt())
  monsterAnim("visible"):SetInt(0)
  postNotificationTop("text"):SetString("FLAG_FANFARE_TITLE")
  local monsterNameText = LOC("HATCH_FANFARE_MONSTER_NAME")
  monsterNameText = monsterNameText:gsub("%${MONSTER}", LOC("FLAG_NAME"))
  local palette = include("ColourPalette")
  monsterNameText = monsterNameText:gsub("%${COLOR}", palette.MONSTER_COMMON)
  postNotificationMonsterName("visible"):SetInt(1)
  postNotificationMonsterName("size"):SetFloat(0.6 * game.hudScale())
  postNotificationMonsterName("autoScale"):SetInt(1)
  postNotificationMonsterName("text"):SetString(monsterNameText)
  postNotificationMonsterName("visible"):SetInt(0)
  postNotificationClass("visible"):SetInt(1)
  postNotificationClass("multiline"):SetInt(1)
  postNotificationClass("size"):SetFloat(0.25 * game.hudScale())
  postNotificationClass("autoScale"):SetInt(1)
  postNotificationClass("text"):SetString("FLAG_FANFARE_DESC")
  postNotificationClass("visible"):SetInt(0)
  local elementsText = postNotificationElements:GetComponent("Text")
  elementsText("text"):SetString("EVOLVE_FANFARE_FLAGS_UNLOCKED")
  local genes = postNotificationElements:GetElement("Genes")
  genes("GeneString"):SetString(element("GeneString"):GetString())
  genes("useFlags"):SetInt(1)
  genes:DoStoredScript("populate")
  gradientBG("spriteName"):SetString("gfx/menu/gradient_bg_common")
  scrollingBG("spriteName"):SetString("gfx/menu/bg_symbols_common")
  viewGroupA:hide()
  amberTouch("enabled"):SetInt(0)
  amberElement.FadeTransition:Show()
  amberGlowTween:activate()
end
function MonsterEvolveFanfare.onInit(element)
  mainElement = element
  mainPanel = element:GetElement("MainPanel")
  element:GetElement("Fade"):GetComponent("Touch"):addLuaFunction("onTouchUp", finishSequence)
  element:addLuaFunction("SetupStructureSpecific", setupStructureSpecific)
  element:addLuaFunction("SetupMonster", setupMonster)
  element:addLuaFunction("SetupFlags", setupFlags)
  colorizeShader = include("ShaderColorize")
  if colorizeShader then
    colorizeShaderFactor = colorizeShader:getUniform("u_Factor")
    colorizeShaderFactor:setFloat(0)
  end
  amberElement = element:GetElement("AmberImage")
  amberElement.FadeTransition = FadeTransition:new({
    duration = 1,
    maxFade = 1,
    onDoneShow = function(e)
      flashSprite.FadeTransition:SetAlpha(0)
      flashSprite("visible"):SetInt(1)
      flashSprite.FadeTransition:Show()
      lua_sys.playSoundFx("audio/sfx/monster_level_up.wav")
    end,
    onUpdate = function(alpha)
      amberElement("alpha"):SetFloat(alpha)
      colorizeShaderFactor:setFloat(alpha)
    end
  })
  amberElement.FadeTransition:SetAlpha(0)
  amberSprite = amberElement:GetComponent("Sprite")
  amberSprite:setShader(colorizeShader)
  amberSprite:addLuaFunction("Refresh", onAmberRefresh)
  amberSprite:addLuaFunction("Tap", onAmberTap)
  amberTouch = amberElement:GetComponent("Touch")
  amberTouch:addLuaFunction("onTouchUp", onTouchedAmber)
  amberGlow = amberElement:GetComponent("Glow")
  amberGlowTween = Tweener:new({
    delay = 0.8,
    duration = 0.33,
    targetValue = 20 * game.menuScaleX(),
    onUpdate = function(value)
      amberGlow:setScale(lua_sys.Vector2(value, value))
      amberGlow("alpha"):SetFloat(value / 20)
    end,
    onPostDelay = function()
      amberGlow("visible"):SetInt(1)
    end
  })
  amberGlow("visible"):SetInt(0)
  tapParticles = amberElement:GetComponent("TapParticles")
  tapParticles:addLuaFunction("play", function(component)
    component("animation"):SetString("tap effcts 0" .. math.random(4))
    component:Play()
  end)
  monsterElement = element:GetElement("MonsterAnim")
  monsterElement.FadeTransition = FadeTransition:new({
    duration = 2,
    maxFade = 1,
    onDoneShow = function()
      if monsterData ~= nil then
        viewGroupC:show()
        labelPulser:activate()
      end
      if flagAe == nil then
        playMonsterSound()
        lua_sys.playSoundFx("audio/sfx/happy_hearts.wav")
      end
      if structure then
        if structure:isAttuner() then
          game.viewedReattunedMonster(userStructureId)
        elseif structure:isCrucible() then
          game.viewMonsterInCrucible()
        end
      end
      continueLabel.FadeTransition:Show()
      isPostReveal = true
      if flagAe ~= nil then
        lua_sys.playSoundFx("audio/sfx/flag_unfurl.wav")
        game.playCrucibleFlagOpening(flagAe, element("FlagInd"):GetInt())
      end
    end,
    onUpdate = function(alpha)
      colorizeShaderFactor:setFloat(1 - alpha)
      viewGroupB:setAlpha(alpha)
    end
  })
  monsterElement.FadeTransition:SetAlpha(1)
  monsterAnim = monsterElement:GetComponent("Sprite")
  monsterAnim:setShader(colorizeShader)
  flashSprite = element:GetComponent("flash")
  flashSprite.FadeTransition = FadeTransition:new({
    duration = 0.33,
    maxFade = 1,
    onUpdate = function(alpha)
      flashSprite:GetVar("alpha"):SetFloat(alpha)
    end,
    onDoneShow = function()
      if isPostReveal then
        viewGroupB:hide()
        viewGroupC:hide()
        viewGroupD:hide()
        monsterAnim("visible"):SetInt(0)
        continueLabel("visible"):SetInt(0)
        loadNextMenu()
      else
        amberGlow("visible"):SetInt(0)
        doMonsterReveal()
      end
      flashSprite.FadeTransition:Hide()
    end,
    onDoneHide = function()
      if isPostReveal then
        mainElement:root():popPopUp()
      else
        lua_sys.playSoundFx("audio/sfx/SFX_JackPotWin_01.wav")
        flashSprite("visible"):SetInt(0)
        monsterElement.FadeTransition:Show()
        OffsetTransition.Show(monsterElement)
        viewGroupB:show()
        viewGroupB:setAlpha(0)
        centerElements()
      end
    end
  })
  viewGroupA:add(amberSprite)
  viewGroupA:add(amberTouch)
  viewGroupA:add(tapParticles)
  viewGroupA:add(element:GetElement("Arrow"):GetComponent("Sprite"))
  viewGroupA:add(element:GetElement("PreNotification"):GetComponent("Text"))
  viewGroupA:add(mainPanel)
  postNotificationTop = element:GetElement("PostNotificationTop"):GetComponent("Text")
  postNotificationMonsterName = element:GetElement("PostNotificationMonsterName"):GetComponent("Text")
  postNotificationClass = element:GetElement("PostNotificationClass"):GetComponent("Text")
  postNotificationElements = element:GetElement("PostNotificationElements")
  viewGroupB:add(postNotificationTop)
  viewGroupB:add(postNotificationMonsterName)
  viewGroupB:add(postNotificationClass)
  viewGroupB:add(postNotificationElements)
  viewGroupB:add(monsterElement:GetComponent("Particles"))
  local newLabel = element:GetElement("NewLabel")
  labelPulser = Pulser.new({
    duration = 1,
    onUpdate = function(scale)
      newLabel:GetComponent("Text"):setScale(lua_sys.Vector2(scale, scale))
    end
  })
  newLabel:GetComponent("Touch"):addLuaFunction("onTouchUp", function()
    if not labelPulser:isActive() then
      lua_sys.playSoundFx("audio/sfx/happy_hearts.wav")
      labelPulser:activate()
    end
  end)
  viewGroupC:add(newLabel:GetComponent("Sprite"))
  viewGroupC:add(newLabel:GetComponent("Text"))
  viewGroupC:add(newLabel:GetComponent("Touch"))
  continueLabel = element:GetElement("ContinueLabel"):GetComponent("Text")
  continueLabel.FadeTransition = FadeTransition:new({
    delayOnShow = 4,
    duration = 1,
    maxFade = 1,
    onUpdate = function(alpha)
      continueLabel:GetVar("alpha"):SetFloat(alpha)
    end
  })
  continueLabel.FadeTransition:SetAlpha(0)
  gradientBG = element:GetElement("BGGradient"):GetComponent("Sprite")
  scrollingBG = element:GetElement("BGPattern"):GetComponent("Sprite")
  scrollingBG:addLuaFunction("onPostInit", initScrollingBG)
  gradientBG:setScale(lua_sys.Vector2(lua_sys.screenWidth() / 1024, lua_sys.screenHeight() / 4))
  gradientBG("layer"):SetString("FrontPopUps")
  barTop = element:GetElement("BorderTop")
  OffsetTransition.OnInit(barTop, {
    startY = -128 * game.hudScale(),
    endY = 0,
    duration = 2
  })
  barBottom = element:GetElement("BorderBottom")
  OffsetTransition.OnInit(barBottom, {
    startY = 128 * game.hudScale(),
    endY = 0,
    duration = 2
  })
  viewGroupD:add(gradientBG)
  viewGroupD:add(scrollingBG)
  viewGroupD:add(barTop:GetComponent("Sprite"))
  viewGroupD:add(barBottom:GetComponent("Sprite"))
  viewGroupD:hide()
end
function MonsterEvolveFanfare.onPostInit(element)
  monsterAnim("visible"):SetInt(0)
  local duration = 4
  local particleDurationPercent = 0.45
  local timePassed = 0
  monsterElement.transitionOptions = {
    startX = monsterElement("xOffset"):GetFloat(),
    startY = monsterElement("yOffset"):GetFloat(),
    endX = 80 * game.hudScale(),
    endY = monsterElement("yOffset"):GetFloat(),
    duration = duration,
    onUpdate = function(e, dt)
      local previousPercent = 0
      if timePassed > 0 then
        previousPercent = timePassed / duration
      end
      timePassed = timePassed + dt
      local currentPercent = 0
      if timePassed > 0 then
        currentPercent = timePassed / duration
      end
      if previousPercent < particleDurationPercent and currentPercent >= particleDurationPercent then
        local component = monsterElement:C("Sprite")
        game.playEffect("particles/FX_MonsterRevealPopup.efkefc", monsterElement:absX() + monsterElement:absW() / 2, monsterElement:absY() + monsterElement:absH() / 2, component("layer"):GetString(), 0.001, 12 * game.menuScaleX())
      end
    end
  }
  OffsetTransition.OnInit(monsterElement, monsterElement.transitionOptions)
  viewGroupB:hide()
  viewGroupC:hide()
  element.MainPanel:DoStoredScript("Show")
end
function MonsterEvolveFanfare.onTick(element, dt)
  if soundTimer > 0 then
    soundTimer = soundTimer - dt
  end
  amberElement.FadeTransition:Tick(dt)
  monsterElement.FadeTransition:Tick(dt)
  OffsetTransition.OnTick(monsterElement, dt, monsterElement.transitionOptions)
  if flashSprite("visible"):GetInt() == 1 then
    flashSprite.FadeTransition:Tick(dt)
  end
  OffsetTransition.OnTick(barTop, dt)
  OffsetTransition.OnTick(barBottom, dt)
  labelPulser:tick(dt)
  amberGlowTween:Tick(dt)
  if amberAnimationTimer > 0 then
    amberAnimationTimer = amberAnimationTimer - dt
    if amberAnimationTimer <= 0 then
      amberSprite("animation"):SetString("idle")
    end
  end
  continueLabel.FadeTransition:Tick(dt)
end
function MonsterEvolveFanfare.queuePop(element)
  element:root():popPopUp()
end
function MonsterEvolveFanfare.setupEvolve(element)
  userStructureId = element("UserStructureId"):GetInt()
  structure = game.GetStructure(userStructureId)
  element:DoStoredScript("SetupStructureSpecific")
  monsterId = element("MonsterID"):GetInt()
  if monsterId ~= 0 then
    element:DoStoredScript("SetupMonster")
  else
    element:DoStoredScript("SetupFlags")
  end
end
return MonsterEvolveFanfare
